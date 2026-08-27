#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --script res://tests/test_economy.gd
  godot --headless --path . --script res://tests/test_map_ui.gd
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --script res://tests/test_economy.gd
  godot4 --headless --path . --script res://tests/test_map_ui.gd
else
  echo "Godot 4.x is not installed or not on PATH."
  echo "Run: godot --headless --path . --script res://tests/test_economy.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_map_ui.gd"
  exit 2
fi
