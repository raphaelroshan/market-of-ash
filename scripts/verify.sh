#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 tests/test_runtime_world_validator.py

if command -v godot >/dev/null 2>&1; then
  godot --headless --path . --script res://tests/test_economy.gd
  godot --headless --path . --script res://tests/test_map_ui.gd
  godot --headless --path . --script res://tests/test_campaign.gd
elif command -v godot4 >/dev/null 2>&1; then
  godot4 --headless --path . --script res://tests/test_economy.gd
  godot4 --headless --path . --script res://tests/test_map_ui.gd
  godot4 --headless --path . --script res://tests/test_campaign.gd
else
  echo "Godot 4.x is not installed or not on PATH."
  echo "Run: godot --headless --path . --script res://tests/test_economy.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_map_ui.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_campaign.gd"
  exit 2
fi
