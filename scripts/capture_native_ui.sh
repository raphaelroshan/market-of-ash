#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="${1:-$ROOT/artifacts/native-render}"
MARKET_GODOT_BIN="${MARKET_GODOT_BIN:-godot}"
CAPTURE_GEOMETRIES="${MARKET_CAPTURE_GEOMETRIES:-960x540 1280x720 1600x900 1920x1080}"

mkdir -p "$OUTPUT_DIR"
validator_args=()
for geometry in $CAPTURE_GEOMETRIES; do
  width="${geometry%x*}"
  height="${geometry#*x}"
  validator_args+=(--viewport "$geometry")
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

python3 "$ROOT/tools/validate_native_captures.py" --output-dir "$OUTPUT_DIR" "${validator_args[@]}"
