#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKET_GODOT_BIN="${MARKET_GODOT_BIN:-godot}"
if [ "$#" -gt 0 ]; then
  OUTPUT_DIR="$1"
  if [ -e "$OUTPUT_DIR" ]; then
    echo "Acceptance output already exists: $OUTPUT_DIR" >&2
    exit 2
  fi
else
  OUTPUT_DIR="$(mktemp -d "${TMPDIR:-/tmp}/market-of-ash-ma-ea-6.XXXXXX")"
fi
NATIVE_DIR="$OUTPUT_DIR/native"
WINDOWS_EXE="$OUTPUT_DIR/market-of-ash.exe"
WINDOWS_ZIP="$OUTPUT_DIR/market-of-ash-windows.zip"
CLEAN_DIR="$OUTPUT_DIR/clean"

if ! command -v "$MARKET_GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot executable not found: $MARKET_GODOT_BIN" >&2
  exit 2
fi
mkdir -p "$OUTPUT_DIR"
export PATH="$(dirname "$MARKET_GODOT_BIN"):$PATH"
export MARKET_GODOT_BIN

cd "$ROOT"
./scripts/verify.sh
./scripts/capture_native_ui.sh "$NATIVE_DIR"
python3 tools/validate_release_contract.py --repo "$ROOT"
"$MARKET_GODOT_BIN" --headless --path . --editor --quit
"$MARKET_GODOT_BIN" --headless --path . --export-release "Windows Desktop" "$WINDOWS_EXE"
python3 tools/validate_windows_export.py "$WINDOWS_EXE"
python3 tools/package_windows_portable.py \
  --executable "$WINDOWS_EXE" \
  --readme docs/releases/v0.14.0-early-access-rc1.md \
  --archive "$WINDOWS_ZIP" \
  --extract-directory "$CLEAN_DIR"
python3 tools/validate_windows_distribution.py "$WINDOWS_ZIP"

echo "MA-EA-6 local acceptance: PASS"
echo "Candidate artifacts: $OUTPUT_DIR"
echo "Authoritative Windows launch/resource and browser gates run in CI."
