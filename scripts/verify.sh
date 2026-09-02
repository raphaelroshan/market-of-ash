#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 tools/policy_check.py --repo "$ROOT"
python3 -m py_compile tools/*.py tests/*.py
python3 tests/test_policy_check.py
python3 tests/test_windows_export_validation.py
python3 tools/validate_release_contract.py --repo "$ROOT"
python3 tests/test_release_contract.py
python3 tools/validate_content.py --manifest content/content_manifest.json
python3 tools/validate_political_geography.py --data content/political_geography.json
python3 tools/validate_tribal_conflict.py --data content/tribal_conflict.json
python3 tools/validate_economy_and_settlements.py \
  --economy content/economy_framework.json \
  --settlements content/settlement_actions.json
python3 tools/validate_runtime_world.py --data content/runtime_world.json
python3 tests/test_runtime_world_validator.py
python3 tests/test_capture_validation.py

GODOT_BIN="${MARKET_GODOT_BIN:-}"
if [[ -n "$GODOT_BIN" && ! -x "$GODOT_BIN" ]]; then
  echo "MARKET_GODOT_BIN is not executable: $GODOT_BIN"
  exit 2
fi
if [[ -z "$GODOT_BIN" ]] && command -v godot >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot)"
elif [[ -z "$GODOT_BIN" ]] && command -v godot4 >/dev/null 2>&1; then
  GODOT_BIN="$(command -v godot4)"
fi

if [[ -z "$GODOT_BIN" ]]; then
  echo "Godot 4.x is not installed or not on PATH."
  echo "Set MARKET_GODOT_BIN to an executable Godot 4.x binary, or:"
  echo "Run: godot --headless --path . --script res://tests/test_economy.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_map_ui.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_presenters.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_tutorial_flow.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_controller_flow.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_campaign.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_game_quality.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_second_region.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_third_region.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_ma_ea_4.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_ma_ea_5.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_investment_vertical.gd"
	  echo "Then run: godot --headless --path . --script res://tests/test_investment_economy_matrix.gd"
  echo "Then run: godot --headless --path . --script res://tests/test_release_readiness.gd"
  exit 2
fi

for test_script in \
  test_economy.gd \
  test_map_ui.gd \
  test_presenters.gd \
  test_tutorial_flow.gd \
  test_controller_flow.gd \
  test_campaign.gd \
  test_game_quality.gd \
  test_second_region.gd \
  test_third_region.gd \
  test_ma_ea_4.gd \
  test_ma_ea_5.gd \
  test_investment_vertical.gd \
	  test_investment_economy_matrix.gd \
  test_release_readiness.gd; do
  "$GODOT_BIN" --headless --path . --script "res://tests/$test_script"
done
