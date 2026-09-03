#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKET_GODOT_BIN="${MARKET_GODOT_BIN:-godot}"
if [ "$#" -gt 0 ]; then
  OUTPUT_DIR="$1"
  if [ -e "$OUTPUT_DIR" ]; then
    echo "Private-alpha output already exists: $OUTPUT_DIR" >&2
    exit 2
  fi
else
  OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/market-of-ash-gpt56-private-alpha.XXXXXX")"
fi
CAPTURE_DIR="$OUTPUT_DIR/private-alpha-1600"
WINDOWS_EXE="$OUTPUT_DIR/market-of-ash.exe"
WINDOWS_ZIP="$OUTPUT_DIR/market-of-ash-windows.zip"
CAPTURE_ZIP="$OUTPUT_DIR/market-of-ash-1600-capture.zip"
CLEAN_DIR="$OUTPUT_DIR/clean"
RELEASE_MANIFEST="$OUTPUT_DIR/release_manifest.json"
CHECKSUMS="$OUTPUT_DIR/SHA256SUMS.txt"

mkdir -p "$OUTPUT_DIR"
cd "$ROOT"
MARKET_GODOT_BIN="$MARKET_GODOT_BIN" ./scripts/verify.sh
MARKET_GODOT_BIN="$MARKET_GODOT_BIN" MARKET_CAPTURE_GEOMETRIES=1600x900 ./scripts/capture_native_ui.sh "$CAPTURE_DIR"
python3 tools/validate_release_contract.py --repo "$ROOT"
"$MARKET_GODOT_BIN" --headless --path . --editor --quit
"$MARKET_GODOT_BIN" --headless --path . --export-release "Windows Desktop" "$WINDOWS_EXE"
python3 tools/validate_windows_export.py "$WINDOWS_EXE"
python3 tools/package_windows_portable.py \
  --executable "$WINDOWS_EXE" \
  --readme docs/releases/v0.16.1-early-access-rc1.md \
  --archive "$WINDOWS_ZIP" \
  --extract-directory "$CLEAN_DIR"
python3 tools/validate_windows_distribution.py "$WINDOWS_ZIP"
python3 tools/package_capture_evidence.py --source "$CAPTURE_DIR" --output "$CAPTURE_ZIP"
commit="$(git rev-parse HEAD)"
ref="$(git symbolic-ref --quiet --short HEAD || git describe --always --exact-match 2>/dev/null || echo detached)"
python3 tools/create_release_manifest.py --repo "$ROOT" --output "$RELEASE_MANIFEST" --commit "$commit" --ref "$ref"
python3 tools/write_release_checksums.py --output "$CHECKSUMS" "$WINDOWS_EXE" "$WINDOWS_ZIP" "$CAPTURE_ZIP" "$RELEASE_MANIFEST"

echo "MA-GPT56-4 private-alpha acceptance: PASS"
echo "Candidate artifacts: $OUTPUT_DIR"
echo "Authoritative Windows launch/resource stamping runs in tagged CI."
