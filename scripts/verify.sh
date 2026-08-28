#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 tools/policy_check.py --repo "$ROOT"
python3 -m py_compile tools/*.py tests/test_runtime_world_validator.py
python3 tools/validate_content.py --manifest content/content_manifest.json
python3 tools/validate_political_geography.py --data content/political_geography.json
python3 tools/validate_tribal_conflict.py --data content/tribal_conflict.json
python3 tools/validate_economy_and_settlements.py \
  --economy content/economy_framework.json \
  --settlements content/settlement_actions.json
python3 tools/validate_runtime_world.py --data content/runtime_world.json
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
