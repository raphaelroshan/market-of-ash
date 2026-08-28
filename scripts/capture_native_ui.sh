#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT/artifacts/native-render}"
MARKET_GODOT_BIN="${MARKET_GODOT_BIN:-godot}"

mkdir -p "$OUTPUT_DIR"
for geometry in 960x540 1280x720; do
  width="${geometry%x*}"
  height="${geometry#*x}"
  "$MARKET_GODOT_BIN" \
    --path "$ROOT" \
    --rendering-method gl_compatibility \
    --resolution "$geometry" \
    --script res://tools/capture_native_ui.gd \
    -- \
    --output-dir "$OUTPUT_DIR" \
    --width "$width" \
    --height "$height"
done

python3 "$ROOT/tools/validate_native_captures.py" --output-dir "$OUTPUT_DIR"
