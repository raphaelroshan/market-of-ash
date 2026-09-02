#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MARKET_GODOT_BIN="${MARKET_GODOT_BIN:-godot}"
EVIDENCE_DIR="${1:-$(mktemp -d "${TMPDIR:-/tmp}/market-of-ash-ma-ea-4.XXXXXX")}" 

if ! command -v "$MARKET_GODOT_BIN" >/dev/null 2>&1; then
  echo "Godot executable not found: $MARKET_GODOT_BIN" >&2
  exit 2
fi

export PATH="$(dirname "$MARKET_GODOT_BIN"):$PATH"
export MARKET_GODOT_BIN

cd "$ROOT"
./scripts/verify.sh
./scripts/capture_native_ui.sh "$EVIDENCE_DIR"

echo "MA-EA-4 acceptance: PASS"
echo "Native evidence: $EVIDENCE_DIR"
