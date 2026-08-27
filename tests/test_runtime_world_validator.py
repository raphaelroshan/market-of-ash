#!/usr/bin/env python3
"""Focused fixtures for runtime-world schema validation."""

from __future__ import annotations

import copy
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from tools.validate_runtime_world import validate  # noqa: E402


def main() -> int:
    runtime = json.loads((ROOT / "content/runtime_world.json").read_text(encoding="utf-8"))
    valid_errors = validate(runtime)
    if valid_errors:
        print("FAIL: valid runtime world was rejected")
        for error in valid_errors:
            print(f"- {error}")
        return 1

    invalid = copy.deepcopy(runtime)
    invalid["market_memory"] = json.loads(
        (ROOT / "tests/fixtures/market_memory_invalid.json").read_text(encoding="utf-8")
    )
    invalid_errors = validate(invalid)
    expected_fragments = (
        "pressure_min must equal 0",
        "pressure_max must be greater than pressure_min and less than 1",
        "sale_impact_per_unit must be greater than 0",
        "daily_decay_per_day must be greater than 0",
        "crisis_effectiveness must contain stages 0, 1, 2, and 3",
        "crisis_effectiveness.0 must be greater than 0 and no greater than 1",
        "max_delivery_history must be an integer from 1 through 100",
    )
    missing = [fragment for fragment in expected_fragments if not any(fragment in error for error in invalid_errors)]
    if missing:
        print("FAIL: invalid market-memory fixture did not produce expected errors")
        for fragment in missing:
            print(f"- missing: {fragment}")
        return 1

    invalid_actions = copy.deepcopy(runtime)

    invalid_actions["settlement_actions"] = json.loads(
        (ROOT / "tests/fixtures/settlement_actions_invalid.json").read_text(encoding="utf-8")
    )
    action_errors = validate(invalid_actions)
    expected_action_fragments = (
        "visit_slots_per_arrival must be an integer from 1 through 5",
        "must use a lower_snake_case id",
        "must reference a known settlement",
        "must declare name",
        "cost must be a non-negative integer",
        "service_slots must be between 1 and the visit limit",
        "time_cost must be a non-negative integer",
        "effects must be an object",
    )
    missing_actions = [
        fragment
        for fragment in expected_action_fragments
        if not any(fragment in error for error in action_errors)
    ]
    if missing_actions:
        print("FAIL: invalid settlement-action fixture did not produce expected errors")
        for fragment in missing_actions:
            print(f"- missing: {fragment}")
        return 1

    invalid_contracts = copy.deepcopy(runtime)
    invalid_contracts["contracts"] = json.loads(
        (ROOT / "tests/fixtures/contracts_invalid.json").read_text(encoding="utf-8")
    )
    contract_errors = validate(invalid_contracts)
    expected_contract_fragments = (
        "contracts.max_history must be an integer from 1 through 100",
        "must use a lower_snake_case id",
        "must declare name",
        "origin_id must reference a known settlement",
        "destination_id must reference a known settlement",
        "good_id must reference a known good",
        "quantity must be a positive integer",
        "failure_penalty must be a non-negative integer",
    )
    missing_contracts = [
        fragment
        for fragment in expected_contract_fragments
        if not any(fragment in error for error in contract_errors)
    ]
    if missing_contracts:
        print("FAIL: invalid contract fixture did not produce expected errors")
        for fragment in missing_contracts:
            print(f"- missing: {fragment}")
        return 1

    invalid_events = copy.deepcopy(runtime)
    invalid_events["events"] = json.loads(
        (ROOT / "tests/fixtures/events_invalid.json").read_text(encoding="utf-8")
    )
    event_errors = validate(invalid_events)
    expected_event_fragments = (
        "events.max_history must be an integer from 1 through 100",
        "must use a lower_snake_case id",
        "must declare title",
        "references unknown route",
        "trigger_chance must be between 0 and 1",
        "trigger_roll_salt must be a non-negative integer",
        "minimum_cargo_value must be a non-negative integer",
        "active_contract_relevant must be boolean",
        "choices must contain at least two choices",
    )
    missing_events = [
        fragment
        for fragment in expected_event_fragments
        if not any(fragment in error for error in event_errors)
    ]
    if missing_events:
        print("FAIL: invalid event fixture did not produce expected errors")
        for fragment in missing_events:
            print(f"- missing: {fragment}")
        return 1

    print("PASS: runtime world validator fixtures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
