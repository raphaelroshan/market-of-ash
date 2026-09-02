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

    invalid_identity = copy.deepcopy(runtime)
    invalid_identity["settlements"]["ashgate"]["identity"] = {
        "scene_id": "",
        "caption": "",
        "market_read": "",
        "landmark": "unknown",
        "tint": "red",
        "sky": "#123456",
        "ground": "#654321",
        "map_cell": [99, -1],
    }
    identity_errors = validate(invalid_identity)
    expected_identity_fragments = (
        "identity.scene_id must be a non-empty string",
        "identity.caption must be a non-empty string",
        "identity.market_read must be a non-empty string",
        "identity.landmark is unsupported",
        "identity.tint must be a six-digit hex color",
        "identity.map_cell must fit the 17x11 route grid",
    )
    missing_identity_errors = [
        fragment for fragment in expected_identity_fragments if not any(fragment in error for error in identity_errors)
    ]
    if missing_identity_errors:
        print("FAIL: invalid settlement identity did not produce expected errors")
        for fragment in missing_identity_errors:
            print(f"- missing: {fragment}")
        return 1

    invalid_reward_assumptions = copy.deepcopy(runtime)
    invalid_reward_assumptions["planning_assumptions"]["reward_fixture_minutes"] = 0
    invalid_reward_assumptions["planning_assumptions"]["contract_expected_net_min_ratio"] = 1.3
    invalid_reward_assumptions["planning_assumptions"]["contract_expected_net_max_ratio"] = 1.1
    reward_errors = validate(invalid_reward_assumptions)
    expected_reward_fragments = (
        "reward_fixture_minutes must be a positive integer",
        "contract reward ratios must form an ordered positive band",
    )
    missing_reward_errors = [
        fragment for fragment in expected_reward_fragments if not any(fragment in error for error in reward_errors)
    ]
    if missing_reward_errors:
        print("FAIL: invalid reward assumptions did not produce expected errors")
        for fragment in missing_reward_errors:
            print(f"- missing: {fragment}")
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
        "producer_decay_multiplier must be greater than 0 and no greater than 2",
        "consumer_decay_multiplier must be greater than 0 and no greater than 2",
        "neutral_decay_multiplier must be greater than 0 and no greater than 2",
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

    invalid_trade_profiles = copy.deepcopy(runtime)
    invalid_trade_profiles["settlements"]["ashgate"]["trade_profile"] = {
        "produces": {"missing_good": "Not a real cargo."},
        "consumes": {"water": ""},
        "ordinary_trade_note": "",
    }
    trade_profile_errors = validate(invalid_trade_profiles)
    expected_trade_profile_fragments = (
        "trade_profile must declare ordinary_trade_note",
        "trade_profile.produces references unknown good missing_good",
        "trade_profile.consumes.water must explain the market role",
        "trade profiles must declare at least one producer for sealed_arms_crate",
    )
    missing_trade_profile_errors = [
        fragment
        for fragment in expected_trade_profile_fragments
        if not any(fragment in error for error in trade_profile_errors)
    ]
    if missing_trade_profile_errors:
        print("FAIL: invalid trade-profile fixture did not produce expected errors")
        for fragment in missing_trade_profile_errors:
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
        "success_reputation must be an object",
        "failure_reputation must be an object",
        "minimum_reputation references unknown faction",
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

    invalid_adaptive = copy.deepcopy(runtime)
    invalid_adaptive["adaptive_scenarios"] = {
        "records": [
            {
                "id": "Bad Scenario",
                "contract_id": "missing_contract",
                "initial_state": "complete",
                "response_day": 1,
                "offered_summary": "",
                "expired_summary": "",
                "failure_response": {
                    "type": "penalty",
                    "faction_id": "",
                    "name": "",
                    "settlement_id": "missing",
                    "material_basis": "",
                    "legitimacy_claim": "",
                    "trade_footprint": "",
                    "resilience_delta": 0,
                    "information_id": "",
                    "market_modifiers": {"missing_good": 3.0},
                    "opportunity": {"title": "", "good_id": "water", "summary": ""},
                },
            }
        ]
    }
    adaptive_errors = validate(invalid_adaptive)
    expected_adaptive_fragments = (
        "must use a lower_snake_case id",
        "must reference a known contract",
        "initial_state must equal offered",
        "response_day must be an integer of at least 2",
        "must declare offered_summary",
        "failure_response.type must equal emergent_faction",
        "failure_response must reference a known settlement",
        "resilience_delta must be an integer from 1 through 10",
        "market modifier missing_good must reference a known good",
        "opportunity must reference a modified known good",
    )
    missing_adaptive = [
        fragment
        for fragment in expected_adaptive_fragments
        if not any(fragment in error for error in adaptive_errors)
    ]
    if missing_adaptive:
        print("FAIL: invalid adaptive-scenario fixture did not produce expected errors")
        for fragment in missing_adaptive:
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
        "references unknown destination",
        "crisis_stage_min must be an integer from 0 through 3",
        "trigger_chance must be between 0 and 1",
        "trigger_roll_salt must be a non-negative integer",
        "minimum_cargo_value must be a non-negative integer",
        "active_contract_relevant must be boolean",
        "references unknown trigger good",
        "minimum_trigger_good_quantity must be a non-negative integer",
        "trade_quantity must be a non-negative integer",
        "premium_per_unit must be a non-negative integer",
        "money_reward must be a non-negative integer",
        "material_quantity must be a non-negative integer",
        "arrival_target must be destination or origin",
        "trade_mode is unsupported",
        "requires_active_contract must be boolean",
        "resilience_delta must be an integer from 0 through 10",
        "cargo_cost must be an object",
        "information_id must use lower_snake_case",
        "requires_assigned_crew_id must use lower_snake_case",
        "reputation_delta must be an object",
        "route_condition must be an object",
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

    invalid_crew = copy.deepcopy(runtime)
    invalid_crew["crew"] = json.loads(
        (ROOT / "tests/fixtures/crew_invalid.json").read_text(encoding="utf-8")
    )
    crew_errors = validate(invalid_crew)
    expected_crew_fragments = (
        "must use a lower_snake_case id",
        "must declare name",
        "recruit_settlement_id must reference a known settlement",
        "recruit_cost must be a non-negative integer",
        "recruit_service_slots must be between 1 and the visit limit",
        "assignment_service_slots must be between 1 and the visit limit",
        "report_valid_days must be a non-negative integer",
        "provision_discount must be an integer from 0 through 3",
        "route_notes must describe old_road",
    )
    missing_crew = [fragment for fragment in expected_crew_fragments if not any(fragment in error for error in crew_errors)]
    if missing_crew:
        print("FAIL: invalid crew fixture did not produce expected errors")
        for fragment in missing_crew:
            print(f"- missing: {fragment}")
        return 1

    invalid_factions = copy.deepcopy(runtime)
    invalid_factions["factions"] = json.loads(
        (ROOT / "tests/fixtures/factions_invalid.json").read_text(encoding="utf-8")
    )
    faction_errors = validate(invalid_factions)
    expected_faction_fragments = (
        "must declare name",
        "bounds and trusted_threshold are invalid",
        "toll_route_id must reference a known route",
        "toll_discount must be a positive integer",
    )
    missing_factions = [fragment for fragment in expected_faction_fragments if not any(fragment in error for error in faction_errors)]
    if missing_factions:
        print("FAIL: invalid faction fixture did not produce expected errors")
        for fragment in missing_factions:
            print(f"- missing: {fragment}")
        return 1

    invalid_regions = copy.deepcopy(runtime)
    invalid_regions["regions"] = {
        "Bad Region": {
            "name": "",
            "summary": "",
            "settlement_ids": ["ashgate", "missing_town"],
            "route_ids": ["missing_road"],
        },
        "overlap": {
            "name": "Overlap",
            "summary": "Duplicates an existing settlement for validation.",
            "settlement_ids": ["ashgate", "brine_cross"],
            "route_ids": ["old_road"],
        },
    }
    region_errors = validate(invalid_regions)
    expected_region_fragments = (
        "region ids must use lower_snake_case",
        "must declare name",
        "must declare summary",
        "references unknown settlement missing_town",
        "references unknown route missing_road",
        "settlement ashgate belongs to more than one region",
        "every settlement must belong to exactly one region",
    )
    missing_region_errors = [
        fragment for fragment in expected_region_fragments if not any(fragment in error for error in region_errors)
    ]
    if missing_region_errors:
        print("FAIL: invalid region fixture did not produce expected errors")
        for fragment in missing_region_errors:
            print(f"- missing: {fragment}")
        return 1

    invalid_arms = copy.deepcopy(runtime)
    invalid_arms["arms_trade"] = json.loads(
        (ROOT / "tests/fixtures/arms_trade_invalid.json").read_text(encoding="utf-8")
    )
    arms_errors = validate(invalid_arms)
    expected_arms_fragments = (
        "bounds or inspection_threshold are invalid",
        "inspection_route_id must reference a known route",
        "inspection_surcharge must be a positive integer",
        "must declare quiet_label",
        "must declare warning",
    )
    missing_arms = [fragment for fragment in expected_arms_fragments if not any(fragment in error for error in arms_errors)]
    if missing_arms:
        print("FAIL: invalid arms-trade fixture did not produce expected errors")
        for fragment in missing_arms:
            print(f"- missing: {fragment}")
        return 1

    invalid_crisis = copy.deepcopy(runtime)
    invalid_crisis["crisis"] = json.loads(
        (ROOT / "tests/fixtures/crisis_invalid.json").read_text(encoding="utf-8")
    )
    crisis_errors = validate(invalid_crisis)
    expected_crisis_fragments = (
        "crisis must declare exactly four stages",
        "must declare title",
        "must declare a non-negative maximum_arms_escalation",
        "open_routes_relief must declare required_contract_id",
        "open_routes_relief must declare a non-negative resilience bound",
        "duplicate crisis ending id",
    )
    missing_crisis = [fragment for fragment in expected_crisis_fragments if not any(fragment in error for error in crisis_errors)]
    if missing_crisis:
        print("FAIL: invalid crisis fixture did not produce expected errors")
        for fragment in missing_crisis:
            print(f"- missing: {fragment}")
        return 1

    invalid_commons_ending = copy.deepcopy(runtime)
    commons_ending = next(ending for ending in invalid_commons_ending["crisis"]["endings"] if ending["id"] == "ending_commons_exchange")
    commons_ending["required_scenario_states"] = ["resolved"]
    commons_ending["minimum_faction_support"] = 0
    commons_ending["required_ordinary_delivery"]["minimum_quantity"] = 0
    commons_ending_errors = validate(invalid_commons_ending)
    expected_commons_ending_fragments = (
        "must require expired or failed scenario states",
        "must require positive faction support",
        "must require a positive ordinary delivery quantity",
    )
    missing_commons_ending = [
        fragment for fragment in expected_commons_ending_fragments if not any(fragment in error for error in commons_ending_errors)
    ]
    if missing_commons_ending:
        print("FAIL: invalid Commons ending did not produce expected errors")
        for fragment in missing_commons_ending:
            print(f"- missing: {fragment}")
        return 1

    # Route-stop validation keeps intermediate settlements reachable without accepting malformed segments.
    invalid_routes = copy.deepcopy(runtime)
    invalid_routes["routes"]["toll_road"]["segments"][0]["endpoints"] = ["ashgate", "missing_town"]
    route_errors = validate(invalid_routes)
    if not any("segment 0 contains an unknown settlement" in error for error in route_errors):
        print("FAIL: invalid route segment did not produce the expected error")
        return 1

    print("PASS: runtime world validator fixtures")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
