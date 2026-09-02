#!/usr/bin/env python3
"""Validate the canonical runtime data used by Market of Ash simulation code."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

REQUIRED_GOODS = ("grain", "water", "scrap", "medicine", "charcoal", "cloth", "sealed_arms_crate", "saltglass", "dune_spice", "lamp_oil")
REQUIRED_SETTLEMENTS = ("ashgate", "brine_cross", "cinderford", "hollow_market", "reedwatch", "sunfall_exchange", "kiln_rest", "mirror_wells", "mothlight_quay", "blackreed_post")
REQUIRED_ROUTES = ("old_road", "toll_road", "dry_cut", "glasswind_trace", "mirror_run", "emberglass_byway", "salt_causeway", "reedline_track")


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def as_object(value: Any, label: str, errors: list[str]) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(errors, f"{label} must be an object")
        return {}
    return value


def validate_modifier_table(
    value: Any, label: str, good_ids: set[str], errors: list[str]
) -> None:
    table = as_object(value, label, errors)
    for good_id in good_ids:
        if good_id not in table:
            fail(errors, f"{label} is missing {good_id}")
            continue
        if not isinstance(table[good_id], (int, float)) or table[good_id] <= 0:
            fail(errors, f"{label}.{good_id} must be a positive number")


def validate_market_memory(value: Any, errors: list[str]) -> None:
    rules = as_object(value, "market_memory", errors)
    pressure_min = rules.get("pressure_min")
    pressure_max = rules.get("pressure_max")
    if not isinstance(pressure_min, (int, float)) or pressure_min != 0:
        fail(errors, "market_memory.pressure_min must equal 0")
    if (
        not isinstance(pressure_max, (int, float))
        or not isinstance(pressure_min, (int, float))
        or pressure_max <= pressure_min
        or pressure_max >= 1
    ):
        fail(errors, "market_memory.pressure_max must be greater than pressure_min and less than 1")

    sale_impact = rules.get("sale_impact_per_unit")
    if (
        not isinstance(sale_impact, (int, float))
        or sale_impact <= 0
        or not isinstance(pressure_max, (int, float))
        or sale_impact > pressure_max
    ):
        fail(errors, "market_memory.sale_impact_per_unit must be greater than 0 and no greater than pressure_max")

    daily_decay = rules.get("daily_decay_per_day")
    if (
        not isinstance(daily_decay, (int, float))
        or daily_decay <= 0
        or not isinstance(pressure_max, (int, float))
        or daily_decay > pressure_max
    ):
        fail(errors, "market_memory.daily_decay_per_day must be greater than 0 and no greater than pressure_max")

    for multiplier_id in (
        "producer_decay_multiplier",
        "consumer_decay_multiplier",
        "neutral_decay_multiplier",
    ):
        multiplier = rules.get(multiplier_id)
        if not isinstance(multiplier, (int, float)) or not 0 < multiplier <= 2:
            fail(errors, f"market_memory.{multiplier_id} must be greater than 0 and no greater than 2")

    effectiveness = as_object(
        rules.get("crisis_effectiveness"),
        "market_memory.crisis_effectiveness",
        errors,
    )
    if set(effectiveness) != {"0", "1", "2", "3"}:
        fail(errors, "market_memory.crisis_effectiveness must contain stages 0, 1, 2, and 3")
    for stage, multiplier in effectiveness.items():
        if not isinstance(multiplier, (int, float)) or not 0 < multiplier <= 1:
            fail(errors, f"market_memory.crisis_effectiveness.{stage} must be greater than 0 and no greater than 1")

    history_limit = rules.get("max_delivery_history")
    if not isinstance(history_limit, int) or not 1 <= history_limit <= 100:
        fail(errors, "market_memory.max_delivery_history must be an integer from 1 through 100")


def validate_trade_profile(
    settlement_id: str,
    value: Any,
    good_ids: set[str],
    source_coverage: set[str],
    consumer_coverage: set[str],
    errors: list[str],
) -> None:
    profile = as_object(value, f"settlement {settlement_id}.trade_profile", errors)
    note = profile.get("ordinary_trade_note")
    if not isinstance(note, str) or not note:
        fail(errors, f"settlement {settlement_id}.trade_profile must declare ordinary_trade_note")
    sides: dict[str, tuple[set[str], dict[str, Any]]] = {}
    for side, coverage in (("produces", source_coverage), ("consumes", consumer_coverage)):
        goods = as_object(
            profile.get(side),
            f"settlement {settlement_id}.trade_profile.{side}",
            errors,
        )
        sides[side] = (coverage, goods)
        if not goods:
            fail(errors, f"settlement {settlement_id}.trade_profile.{side} must name at least one good")
        for good_id, explanation in goods.items():
            if good_id not in good_ids:
                fail(errors, f"settlement {settlement_id}.trade_profile.{side} references unknown good {good_id}")
            elif not isinstance(explanation, str) or not explanation:
                fail(errors, f"settlement {settlement_id}.trade_profile.{side}.{good_id} must explain the market role")
            else:
                coverage.add(good_id)
    for good_id in set(sides["produces"][1]) & set(sides["consumes"][1]):
        fail(errors, f"settlement {settlement_id}.trade_profile cannot both produce and consume {good_id}")


def validate_settlement_actions(value: Any, errors: list[str]) -> None:
    rules = as_object(value, "settlement_actions", errors)
    visit_slots = rules.get("visit_slots_per_arrival")
    if not isinstance(visit_slots, int) or not 1 <= visit_slots <= 5:
        fail(errors, "settlement_actions.visit_slots_per_arrival must be an integer from 1 through 5")
    actions = rules.get("actions")
    if not isinstance(actions, list):
        fail(errors, "settlement_actions.actions must be a list")
        return
    seen_ids: set[str] = set()
    for index, raw_action in enumerate(actions):
        action = as_object(raw_action, f"settlement_actions.actions[{index}]", errors)
        action_id = action.get("id")
        if not isinstance(action_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", action_id):
            fail(errors, f"settlement action at index {index} must use a lower_snake_case id")
            action_id = f"index_{index}"
        elif action_id in seen_ids:
            fail(errors, f"duplicate settlement action id: {action_id}")
        seen_ids.add(action_id)
        if action.get("settlement_id") not in REQUIRED_SETTLEMENTS:
            fail(errors, f"settlement action {action_id} must reference a known settlement")
        for field in ("name", "category", "description", "tradeoff"):
            if not isinstance(action.get(field), str) or not action[field]:
                fail(errors, f"settlement action {action_id} must declare {field}")
        if action.get("available") is True and action.get("category") in ("information", "relief") and (not isinstance(action.get("result"), str) or not action["result"]):
            fail(errors, f"available settlement action {action_id} must declare result")
        if not isinstance(action.get("available"), bool):
            fail(errors, f"settlement action {action_id}.available must be boolean")
        if not isinstance(action.get("cost"), int) or action["cost"] < 0:
            fail(errors, f"settlement action {action_id}.cost must be a non-negative integer")
        service_slots = action.get("service_slots")
        if (
            not isinstance(service_slots, int)
            or service_slots < 1
            or not isinstance(visit_slots, int)
            or service_slots > visit_slots
        ):
            fail(errors, f"settlement action {action_id}.service_slots must be between 1 and the visit limit")
        if not isinstance(action.get("time_cost"), int) or action["time_cost"] < 0:
            fail(errors, f"settlement action {action_id}.time_cost must be a non-negative integer")
        minimum_crisis_stage = action.get("minimum_crisis_stage", 0)
        if not isinstance(minimum_crisis_stage, int) or not 0 <= minimum_crisis_stage <= 3:
            fail(errors, f"settlement action {action_id}.minimum_crisis_stage must be an integer from 0 through 3")
        if not isinstance(action.get("once_per_campaign", False), bool):
            fail(errors, f"settlement action {action_id}.once_per_campaign must be boolean")
        required_contract_id = action.get("requires_completed_contract_id", "")
        if not isinstance(required_contract_id, str):
            fail(errors, f"settlement action {action_id}.requires_completed_contract_id must be a string")
        if not isinstance(action.get("requires_emergent_faction_id", ""), str):
            fail(errors, f"settlement action {action_id}.requires_emergent_faction_id must be a string")
        effects = action.get("effects")
        if not isinstance(effects, dict):
            fail(errors, f"settlement action {action_id}.effects must be an object")
        else:
            cargo_cost = effects.get("cargo_cost", {})
            if not isinstance(cargo_cost, dict):
                fail(errors, f"settlement action {action_id}.cargo_cost must be an object")
            elif cargo_cost and (
                cargo_cost.get("good_id") not in REQUIRED_GOODS
                or not isinstance(cargo_cost.get("quantity"), int)
                or cargo_cost["quantity"] <= 0
            ):
                fail(errors, f"settlement action {action_id}.cargo_cost must name a known good and positive quantity")
            support = effects.get("emergent_faction_support", {})
            if not isinstance(support, dict):
                fail(errors, f"settlement action {action_id}.emergent_faction_support must be an object")
            elif support and (
                not isinstance(support.get("faction_id"), str)
                or not support["faction_id"]
                or not isinstance(support.get("delta"), int)
                or support["delta"] == 0
                or abs(support["delta"]) > 3
            ):
                fail(errors, f"settlement action {action_id}.emergent_faction_support must name a faction and non-zero delta within 3")
        if isinstance(effects, dict) and action.get("category") == "arms_trade":
            arms_sale = effects.get("arms_sale")
            if not isinstance(arms_sale, dict):
                fail(errors, f"settlement action {action_id}.arms_sale must be an object")
            else:
                if arms_sale.get("good_id") != "sealed_arms_crate":
                    fail(errors, f"settlement action {action_id}.arms_sale must use sealed_arms_crate")
                for field in ("quantity", "payout", "escalation_delta"):
                    if not isinstance(arms_sale.get(field), int) or arms_sale[field] <= 0:
                        fail(errors, f"settlement action {action_id}.arms_sale.{field} must be a positive integer")
                if not isinstance(arms_sale.get("alternative_contract_id"), str) or not arms_sale["alternative_contract_id"]:
                    fail(errors, f"settlement action {action_id}.arms_sale must name a non-arms alternative")
        elif action.get("available") is True and action_id == "ashgate_provision_bundle":
            if not isinstance(effects.get("provisions"), int) or effects["provisions"] <= 0:
                fail(errors, "settlement action ashgate_provision_bundle must add provisions")
        elif action.get("available") is True and action_id == "brine_cross_cistern_queue":
            resilience = effects.get("settlement_resilience")
            if not isinstance(effects.get("information_id"), str) or not effects["information_id"]:
                fail(errors, "settlement action brine_cross_cistern_queue must record information")
            if not isinstance(resilience, dict) or resilience.get("settlement_id") != "brine_cross" or not isinstance(resilience.get("delta"), int) or resilience["delta"] <= 0:
                fail(errors, "settlement action brine_cross_cistern_queue must strengthen Brine Cross resilience")
        elif action.get("available") is True and action_id == "hollow_market_route_rumor":
            condition = effects.get("route_condition")
            if not isinstance(effects.get("information_id"), str) or not effects["information_id"]:
                fail(errors, "settlement action hollow_market_route_rumor must record information")
            if not isinstance(condition, dict) or condition.get("route_id") != "dry_cut" or not isinstance(condition.get("risk_delta"), (int, float)) or not -1 <= condition["risk_delta"] < 0:
                fail(errors, "settlement action hollow_market_route_rumor must reduce Dry Cut risk")
        elif action.get("available") is True and action_id == "cinderford_repair_bench":
            condition = effects.get("route_condition")
            if not isinstance(effects.get("information_id"), str) or not effects["information_id"]:
                fail(errors, "settlement action cinderford_repair_bench must record information")
            if not isinstance(condition, dict) or condition.get("route_id") != "toll_road" or not isinstance(condition.get("risk_delta"), (int, float)) or not -1 <= condition["risk_delta"] < 0:
                fail(errors, "settlement action cinderford_repair_bench must reduce Toll Road risk")
        elif action.get("available") is True and action_id == "reedwatch_supply_shelter":
            resilience = effects.get("settlement_resilience")
            if required_contract_id != "reedwatch_water_relief_01":
                fail(errors, "settlement action reedwatch_supply_shelter must require completed water relief")
            if not isinstance(effects.get("information_id"), str) or not effects["information_id"]:
                fail(errors, "settlement action reedwatch_supply_shelter must record information")
            if not isinstance(resilience, dict) or resilience.get("settlement_id") != "reedwatch" or not isinstance(resilience.get("delta"), int) or resilience["delta"] <= 0:
                fail(errors, "settlement action reedwatch_supply_shelter must strengthen Reedwatch resilience")
        if action.get("available") is False and not action.get("unavailable_reason"):
            fail(errors, f"unavailable settlement action {action_id} must declare unavailable_reason")


def validate_contracts(value: Any, factions_value: Any, visit_slot_limit: Any, errors: list[str]) -> None:
    rules = as_object(value, "contracts", errors)
    factions = as_object(factions_value, "factions", errors)
    history_limit = rules.get("max_history")
    if not isinstance(history_limit, int) or not 1 <= history_limit <= 100:
        fail(errors, "contracts.max_history must be an integer from 1 through 100")
    records = rules.get("records")
    if not isinstance(records, list):
        fail(errors, "contracts.records must be a list")
        return
    seen_ids: set[str] = set()
    for index, raw_contract in enumerate(records):
        contract = as_object(raw_contract, f"contracts.records[{index}]", errors)
        contract_id = contract.get("id")
        if not isinstance(contract_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", contract_id):
            fail(errors, f"contract at index {index} must use a lower_snake_case id")
            contract_id = f"index_{index}"
        elif contract_id in seen_ids:
            fail(errors, f"duplicate contract id: {contract_id}")
        seen_ids.add(contract_id)
        for field in ("name", "sponsor", "description", "tradeoff", "decision_summary", "recovery_summary", "failure_recovery"):
            if not isinstance(contract.get(field), str) or not contract[field]:
                fail(errors, f"contract {contract_id} must declare {field}")
        for field in ("origin_id", "destination_id"):
            if contract.get(field) not in REQUIRED_SETTLEMENTS:
                fail(errors, f"contract {contract_id}.{field} must reference a known settlement")
        if contract.get("origin_id") == contract.get("destination_id"):
            fail(errors, f"contract {contract_id} origin and destination must differ")
        if contract.get("good_id") not in REQUIRED_GOODS:
            fail(errors, f"contract {contract_id}.good_id must reference a known good")
        for field in ("quantity", "deadline_days", "reward", "service_slots"):
            if not isinstance(contract.get(field), int) or contract[field] <= 0:
                fail(errors, f"contract {contract_id}.{field} must be a positive integer")
        if (
            isinstance(contract.get("service_slots"), int)
            and isinstance(visit_slot_limit, int)
            and contract["service_slots"] > visit_slot_limit
        ):
            fail(errors, f"contract {contract_id}.service_slots must not exceed the visit limit")
        if not isinstance(contract.get("failure_penalty"), int) or contract["failure_penalty"] < 0:
            fail(errors, f"contract {contract_id}.failure_penalty must be a non-negative integer")
        for field in ("success_reputation", "failure_reputation"):
            effects = contract.get(field)
            if not isinstance(effects, dict):
                fail(errors, f"contract {contract_id}.{field} must be an object")
                continue
            for faction_id, delta in effects.items():
                if faction_id not in factions:
                    fail(errors, f"contract {contract_id}.{field} references unknown faction {faction_id}")
                if not isinstance(delta, int):
                    fail(errors, f"contract {contract_id}.{field}.{faction_id} must be an integer")
        minimum_reputation = contract.get("minimum_reputation", {})
        if not isinstance(minimum_reputation, dict):
            fail(errors, f"contract {contract_id}.minimum_reputation must be an object")
        else:
            for faction_id, minimum in minimum_reputation.items():
                faction = factions.get(faction_id)
                if not isinstance(faction, dict):
                    fail(errors, f"contract {contract_id}.minimum_reputation references unknown faction {faction_id}")
                elif not isinstance(minimum, int) or minimum < faction.get("minimum", -10) or minimum > faction.get("maximum", 10):
                    fail(errors, f"contract {contract_id}.minimum_reputation.{faction_id} must fit the authored faction bounds")


def validate_adaptive_scenarios(
    value: Any, known_contract_ids: set[str], errors: list[str]
) -> None:
    rules = as_object(value, "adaptive_scenarios", errors)
    records = rules.get("records")
    if not isinstance(records, list) or not records:
        fail(errors, "adaptive_scenarios.records must be a non-empty list")
        return
    seen_ids: set[str] = set()
    for index, raw_scenario in enumerate(records):
        scenario = as_object(raw_scenario, f"adaptive_scenarios.records[{index}]", errors)
        scenario_id = scenario.get("id")
        if not isinstance(scenario_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", scenario_id):
            fail(errors, f"adaptive scenario at index {index} must use a lower_snake_case id")
            scenario_id = f"index_{index}"
        elif scenario_id in seen_ids:
            fail(errors, f"duplicate adaptive scenario id: {scenario_id}")
        seen_ids.add(scenario_id)
        if scenario.get("contract_id") not in known_contract_ids:
            fail(errors, f"adaptive scenario {scenario_id} must reference a known contract")
        if scenario.get("initial_state") != "offered":
            fail(errors, f"adaptive scenario {scenario_id}.initial_state must equal offered")
        if not isinstance(scenario.get("response_day"), int) or scenario["response_day"] < 2:
            fail(errors, f"adaptive scenario {scenario_id}.response_day must be an integer of at least 2")
        for field in ("offered_summary", "expired_summary"):
            if not isinstance(scenario.get(field), str) or not scenario[field]:
                fail(errors, f"adaptive scenario {scenario_id} must declare {field}")
        response = as_object(
            scenario.get("failure_response"),
            f"adaptive scenario {scenario_id}.failure_response",
            errors,
        )
        if response.get("type") != "emergent_faction":
            fail(errors, f"adaptive scenario {scenario_id}.failure_response.type must equal emergent_faction")
        for field in ("faction_id", "name", "material_basis", "legitimacy_claim", "trade_footprint", "information_id"):
            if not isinstance(response.get(field), str) or not response[field]:
                fail(errors, f"adaptive scenario {scenario_id}.failure_response must declare {field}")
        if response.get("settlement_id") not in REQUIRED_SETTLEMENTS:
            fail(errors, f"adaptive scenario {scenario_id}.failure_response must reference a known settlement")
        if not isinstance(response.get("resilience_delta"), int) or not 1 <= response["resilience_delta"] <= 10:
            fail(errors, f"adaptive scenario {scenario_id}.resilience_delta must be an integer from 1 through 10")
        modifiers = as_object(
            response.get("market_modifiers"),
            f"adaptive scenario {scenario_id}.market_modifiers",
            errors,
        )
        if not modifiers:
            fail(errors, f"adaptive scenario {scenario_id}.market_modifiers must not be empty")
        for good_id, modifier in modifiers.items():
            if good_id not in REQUIRED_GOODS or not isinstance(modifier, (int, float)) or not 0.5 <= modifier <= 2:
                fail(errors, f"adaptive scenario {scenario_id}.market modifier {good_id} must reference a known good and stay between 0.5 and 2")
        support_steps = as_object(
            response.get("support_market_steps"),
            f"adaptive scenario {scenario_id}.support_market_steps",
            errors,
        )
        for good_id, step in support_steps.items():
            if good_id not in modifiers or not isinstance(step, (int, float)) or not -0.25 <= step <= 0.25:
                fail(errors, f"adaptive scenario {scenario_id}.support step {good_id} must modify an active good and stay between -0.25 and 0.25")
        opportunity = as_object(
            response.get("opportunity"),
            f"adaptive scenario {scenario_id}.opportunity",
            errors,
        )
        if opportunity.get("good_id") not in REQUIRED_GOODS or opportunity.get("good_id") not in modifiers:
            fail(errors, f"adaptive scenario {scenario_id}.opportunity must reference a modified known good")
        for field in ("title", "summary"):
            if not isinstance(opportunity.get(field), str) or not opportunity[field]:
                fail(errors, f"adaptive scenario {scenario_id}.opportunity must declare {field}")


def validate_adaptive_action_links(actions_value: Any, scenarios_value: Any, errors: list[str]) -> None:
    actions = actions_value.get("actions", []) if isinstance(actions_value, dict) else []
    scenarios = scenarios_value.get("records", []) if isinstance(scenarios_value, dict) else []
    faction_ids = {
        scenario.get("failure_response", {}).get("faction_id")
        for scenario in scenarios
        if isinstance(scenario, dict) and isinstance(scenario.get("failure_response"), dict)
    }
    for action in actions:
        if not isinstance(action, dict):
            continue
        required_id = action.get("requires_emergent_faction_id", "")
        if required_id and required_id not in faction_ids:
            fail(errors, f"settlement action {action.get('id', '')} requires unknown emergent faction {required_id}")
        effects = action.get("effects", {})
        support = effects.get("emergent_faction_support", {}) if isinstance(effects, dict) else {}
        support_id = support.get("faction_id", "") if isinstance(support, dict) else ""
        if support_id and (support_id not in faction_ids or support_id != required_id):
            fail(errors, f"settlement action {action.get('id', '')} support must target its required emergent faction")


def validate_events(value: Any, errors: list[str]) -> None:
    rules = as_object(value, "events", errors)
    history_limit = rules.get("max_history")
    if not isinstance(history_limit, int) or not 1 <= history_limit <= 100:
        fail(errors, "events.max_history must be an integer from 1 through 100")
    records = rules.get("records")
    if not isinstance(records, list):
        fail(errors, "events.records must be a list")
        return
    seen_ids: set[str] = set()
    for index, raw_event in enumerate(records):
        event = as_object(raw_event, f"events.records[{index}]", errors)
        event_id = event.get("id")
        if not isinstance(event_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", event_id):
            fail(errors, f"event at index {index} must use a lower_snake_case id")
            event_id = f"index_{index}"
        elif event_id in seen_ids:
            fail(errors, f"duplicate event id: {event_id}")
        seen_ids.add(event_id)
        for field in ("title", "category", "setup", "stakes"):
            if not isinstance(event.get(field), str) or not event[field]:
                fail(errors, f"event {event_id} must declare {field}")
        route_ids = event.get("route_ids")
        if not isinstance(route_ids, list) or not route_ids:
            fail(errors, f"event {event_id}.route_ids must be a non-empty list")
        else:
            for route_id in route_ids:
                if route_id not in REQUIRED_ROUTES:
                    fail(errors, f"event {event_id} references unknown route {route_id}")
        destination_ids = event.get("destination_ids", [])
        if not isinstance(destination_ids, list):
            fail(errors, f"event {event_id}.destination_ids must be a list")
        else:
            for destination_id in destination_ids:
                if destination_id not in REQUIRED_SETTLEMENTS:
                    fail(errors, f"event {event_id} references unknown destination {destination_id}")
        crisis_stage_min = event.get("crisis_stage_min", 0)
        if not isinstance(crisis_stage_min, int) or not 0 <= crisis_stage_min <= 3:
            fail(errors, f"event {event_id}.crisis_stage_min must be an integer from 0 through 3")
        trigger_chance = event.get("trigger_chance")
        if not isinstance(trigger_chance, (int, float)) or not 0 <= trigger_chance <= 1:
            fail(errors, f"event {event_id}.trigger_chance must be between 0 and 1")
        if not isinstance(event.get("trigger_roll_salt"), int) or event["trigger_roll_salt"] < 0:
            fail(errors, f"event {event_id}.trigger_roll_salt must be a non-negative integer")
        if not isinstance(event.get("minimum_cargo_value"), int) or event["minimum_cargo_value"] < 0:
            fail(errors, f"event {event_id}.minimum_cargo_value must be a non-negative integer")
        if not isinstance(event.get("active_contract_relevant"), bool):
            fail(errors, f"event {event_id}.active_contract_relevant must be boolean")
        trigger_good_ids = event.get("trigger_good_ids_any", [])
        if not isinstance(trigger_good_ids, list):
            fail(errors, f"event {event_id}.trigger_good_ids_any must be a list")
            trigger_good_ids = []
        else:
            for good_id in trigger_good_ids:
                if good_id not in REQUIRED_GOODS:
                    fail(errors, f"event {event_id} references unknown trigger good {good_id}")
        minimum_trigger_quantity = event.get("minimum_trigger_good_quantity", 0)
        if not isinstance(minimum_trigger_quantity, int) or minimum_trigger_quantity < 0:
            fail(errors, f"event {event_id}.minimum_trigger_good_quantity must be a non-negative integer")
        elif trigger_good_ids and minimum_trigger_quantity <= 0:
            fail(errors, f"event {event_id} must require a positive trigger-good quantity")
        for field in ("trade_quantity", "premium_per_unit"):
            value = event.get(field, 0)
            if not isinstance(value, int) or value < 0:
                fail(errors, f"event {event_id}.{field} must be a non-negative integer")
        choices = event.get("choices")
        if not isinstance(choices, list) or len(choices) < 2:
            fail(errors, f"event {event_id}.choices must contain at least two choices")
            continue
        seen_choice_ids: set[str] = set()
        for choice_index, raw_choice in enumerate(choices):
            choice = as_object(raw_choice, f"event {event_id}.choices[{choice_index}]", errors)
            choice_id = choice.get("id")
            if not isinstance(choice_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", choice_id):
                fail(errors, f"event {event_id} choice at index {choice_index} must use a lower_snake_case id")
                choice_id = f"index_{choice_index}"
            elif choice_id in seen_choice_ids:
                fail(errors, f"event {event_id} has duplicate choice {choice_id}")
            seen_choice_ids.add(choice_id)
            for field in ("label", "outcome"):
                if not isinstance(choice.get(field), str) or not choice[field]:
                    fail(errors, f"event {event_id} choice {choice_id} must declare {field}")
            for field in ("money_cost", "money_reward", "provision_cost", "material_quantity", "days"):
                value = choice.get(field, 0)
                if not isinstance(value, int) or value < 0:
                    fail(errors, f"event {event_id} choice {choice_id}.{field} must be a non-negative integer")
            cargo_risk = choice.get("cargo_risk")
            if not isinstance(cargo_risk, (int, float)) or not 0 <= cargo_risk <= 1:
                fail(errors, f"event {event_id} choice {choice_id}.cargo_risk must be between 0 and 1")
            arrival_target = choice.get("arrival_target", "destination")
            if arrival_target not in ("destination", "origin"):
                fail(errors, f"event {event_id} choice {choice_id}.arrival_target must be destination or origin")
            if choice.get("trade_mode", "none") not in ("none", "premium_sale", "fair_share"):
                fail(errors, f"event {event_id} choice {choice_id}.trade_mode is unsupported")
            if not isinstance(choice.get("requires_active_contract", False), bool):
                fail(errors, f"event {event_id} choice {choice_id}.requires_active_contract must be boolean")
            resilience_delta = choice.get("resilience_delta", 0)
            if not isinstance(resilience_delta, int) or not 0 <= resilience_delta <= 10:
                fail(errors, f"event {event_id} choice {choice_id}.resilience_delta must be an integer from 0 through 10")
            cargo_cost = choice.get("cargo_cost", {})
            if not isinstance(cargo_cost, dict):
                fail(errors, f"event {event_id} choice {choice_id}.cargo_cost must be an object")
            elif cargo_cost:
                if cargo_cost.get("good_id") not in REQUIRED_GOODS:
                    fail(errors, f"event {event_id} choice {choice_id}.cargo_cost references an unknown good")
                if not isinstance(cargo_cost.get("quantity"), int) or cargo_cost["quantity"] <= 0:
                    fail(errors, f"event {event_id} choice {choice_id}.cargo_cost quantity must be positive")
            information_id = choice.get("information_id", "")
            if not isinstance(information_id, str) or (information_id and not re.fullmatch(r"[a-z][a-z0-9_]*", information_id)):
                fail(errors, f"event {event_id} choice {choice_id}.information_id must use lower_snake_case")
            required_crew_id = choice.get("requires_assigned_crew_id", "")
            if not isinstance(required_crew_id, str) or (required_crew_id and not re.fullmatch(r"[a-z][a-z0-9_]*", required_crew_id)):
                fail(errors, f"event {event_id} choice {choice_id}.requires_assigned_crew_id must use lower_snake_case")
            reputation_delta = choice.get("reputation_delta", {})
            if not isinstance(reputation_delta, dict):
                fail(errors, f"event {event_id} choice {choice_id}.reputation_delta must be an object")
            else:
                for faction_id, delta in reputation_delta.items():
                    if faction_id not in ("wardens", "caravans", "glass_consortium", "bellkeepers") or not isinstance(delta, int) or abs(delta) > 10:
                        fail(errors, f"event {event_id} choice {choice_id}.reputation_delta is invalid")
            condition = choice.get("route_condition", {})
            if not isinstance(condition, dict):
                fail(errors, f"event {event_id} choice {choice_id}.route_condition must be an object")
            elif condition:
                if condition.get("route_id") not in REQUIRED_ROUTES:
                    fail(errors, f"event {event_id} choice {choice_id}.route_condition references an unknown route")
                for field in ("id", "label", "description"):
                    if not isinstance(condition.get(field), str) or not condition[field]:
                        fail(errors, f"event {event_id} choice {choice_id}.route_condition must declare {field}")
                risk_delta = condition.get("risk_delta", 0)
                if not isinstance(risk_delta, (int, float)) or not -1 <= risk_delta <= 1:
                    fail(errors, f"event {event_id} choice {choice_id}.route_condition risk_delta must be between -1 and 1")


def validate_crew(value: Any, visit_slot_limit: Any, errors: list[str]) -> None:
    rules = as_object(value, "crew", errors)
    records = rules.get("records")
    if not isinstance(records, list):
        fail(errors, "crew.records must be a list")
        return
    seen_ids: set[str] = set()
    for index, raw_crew in enumerate(records):
        crew = as_object(raw_crew, f"crew.records[{index}]", errors)
        crew_id = crew.get("id")
        if not isinstance(crew_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", crew_id):
            fail(errors, f"crew at index {index} must use a lower_snake_case id")
            crew_id = f"index_{index}"
        elif crew_id in seen_ids:
            fail(errors, f"duplicate crew id: {crew_id}")
        seen_ids.add(crew_id)
        for field in ("name", "role", "personality", "limitation", "hook"):
            if not isinstance(crew.get(field), str) or not crew[field]:
                fail(errors, f"crew {crew_id} must declare {field}")
        if crew.get("recruit_settlement_id") not in REQUIRED_SETTLEMENTS:
            fail(errors, f"crew {crew_id}.recruit_settlement_id must reference a known settlement")
        if not isinstance(crew.get("recruit_cost"), int) or crew["recruit_cost"] < 0:
            fail(errors, f"crew {crew_id}.recruit_cost must be a non-negative integer")
        for field in ("recruit_service_slots", "assignment_service_slots"):
            value = crew.get(field)
            if not isinstance(value, int) or not isinstance(visit_slot_limit, int) or not 1 <= value <= visit_slot_limit:
                fail(errors, f"crew {crew_id}.{field} must be between 1 and the visit limit")
        if not isinstance(crew.get("report_valid_days"), int) or crew["report_valid_days"] < 0:
            fail(errors, f"crew {crew_id}.report_valid_days must be a non-negative integer")
        if not isinstance(crew.get("provision_discount"), int) or not 0 <= crew["provision_discount"] <= 3:
            fail(errors, f"crew {crew_id}.provision_discount must be an integer from 0 through 3")
        route_notes = as_object(crew.get("route_notes"), f"crew {crew_id}.route_notes", errors)
        for route_id in REQUIRED_ROUTES:
            if not isinstance(route_notes.get(route_id), str) or not route_notes[route_id]:
                fail(errors, f"crew {crew_id}.route_notes must describe {route_id}")


def validate_factions(value: Any, errors: list[str]) -> None:
    factions = as_object(value, "factions", errors)
    for required_faction_id in ("wardens", "caravans", "glass_consortium", "bellkeepers"):
        if required_faction_id not in factions:
            fail(errors, f"factions.{required_faction_id} must be an object")
    for faction_id, raw_faction in factions.items():
        faction = as_object(raw_faction, f"factions.{faction_id}", errors)
        for field in ("name", "below_label", "trusted_label", "effect", "tradeoff"):
            if not isinstance(faction.get(field), str) or not faction[field]:
                fail(errors, f"factions.{faction_id} must declare {field}")
        minimum = faction.get("minimum")
        maximum = faction.get("maximum")
        threshold = faction.get("trusted_threshold")
        if not all(isinstance(item, int) for item in (minimum, maximum, threshold)) or not minimum < threshold <= maximum:
            fail(errors, f"factions.{faction_id} bounds and trusted_threshold are invalid")
        if faction.get("toll_route_id") not in REQUIRED_ROUTES:
            fail(errors, f"factions.{faction_id}.toll_route_id must reference a known route")
        if not isinstance(faction.get("toll_discount"), int) or faction["toll_discount"] <= 0:
            fail(errors, f"factions.{faction_id}.toll_discount must be a positive integer")


def validate_regions(value: Any, settlement_ids: set[str], route_ids: set[str], errors: list[str]) -> None:
    regions = as_object(value, "regions", errors)
    if len(regions) < 2:
        fail(errors, "regions must define at least two playable regions")
    assigned_settlements: set[str] = set()
    for region_id, raw_region in regions.items():
        if not isinstance(region_id, str) or not re.fullmatch(r"[a-z][a-z0-9_]*", region_id):
            fail(errors, "region ids must use lower_snake_case")
        region = as_object(raw_region, f"region {region_id}", errors)
        for field in ("name", "summary"):
            if not isinstance(region.get(field), str) or not region[field]:
                fail(errors, f"region {region_id} must declare {field}")
        member_settlements = region.get("settlement_ids")
        if not isinstance(member_settlements, list) or len(member_settlements) < 2:
            fail(errors, f"region {region_id}.settlement_ids must contain at least two settlements")
            member_settlements = []
        for settlement_id in member_settlements:
            if settlement_id not in settlement_ids:
                fail(errors, f"region {region_id} references unknown settlement {settlement_id}")
            elif settlement_id in assigned_settlements:
                fail(errors, f"settlement {settlement_id} belongs to more than one region")
            assigned_settlements.add(settlement_id)
        member_routes = region.get("route_ids")
        if not isinstance(member_routes, list) or not member_routes:
            fail(errors, f"region {region_id}.route_ids must contain at least one route")
            member_routes = []
        for route_id in member_routes:
            if route_id not in route_ids:
                fail(errors, f"region {region_id} references unknown route {route_id}")
    if assigned_settlements != settlement_ids:
        fail(errors, "every settlement must belong to exactly one region")


def validate_arms_trade(value: Any, errors: list[str]) -> None:
    rules = as_object(value, "arms_trade", errors)
    if rules.get("minimum") != 0 or rules.get("maximum") != 6 or not isinstance(rules.get("inspection_threshold"), int) or not 0 < rules["inspection_threshold"] <= 6:
        fail(errors, "arms_trade bounds or inspection_threshold are invalid")
    if rules.get("inspection_route_id") not in REQUIRED_ROUTES:
        fail(errors, "arms_trade.inspection_route_id must reference a known route")
    if not isinstance(rules.get("inspection_surcharge"), int) or rules["inspection_surcharge"] <= 0:
        fail(errors, "arms_trade.inspection_surcharge must be a positive integer")
    for field in ("quiet_label", "noticed_label", "warning", "recovery"):
        if not isinstance(rules.get(field), str) or not rules[field]:
            fail(errors, f"arms_trade must declare {field}")


def validate_crisis(value: Any, errors: list[str]) -> None:
    rules = as_object(value, "crisis", errors)
    stages = rules.get("stages")
    if not isinstance(stages, list) or len(stages) != 4:
        fail(errors, "crisis must declare exactly four stages")
    else:
        for index, raw_stage in enumerate(stages):
            stage = as_object(raw_stage, f"crisis.stages[{index}]", errors)
            if stage.get("id") != index or not isinstance(stage.get("starts_day"), int) or stage["starts_day"] <= 0 or not isinstance(stage.get("label"), str) or not stage["label"] or not isinstance(stage.get("objective"), str) or not stage["objective"]:
                fail(errors, f"crisis stage {index} is invalid")
            route_effects = stage.get("route_effects")
            if not isinstance(route_effects, dict):
                fail(errors, f"crisis stage {index}.route_effects must be an object")
                continue
            for route_id, effect_value in route_effects.items():
                if route_id not in REQUIRED_ROUTES:
                    fail(errors, f"crisis stage {index} references unknown route {route_id}")
                effect = as_object(effect_value, f"crisis stage {index}.route_effects.{route_id}", errors)
                risk_delta = effect.get("risk_delta")
                cost_delta = effect.get("cost_delta")
                if not isinstance(risk_delta, (int, float)) or not -1 <= risk_delta <= 1:
                    fail(errors, f"crisis stage {index} route {route_id} risk_delta must be between -1 and 1")
                if not isinstance(cost_delta, int) or cost_delta < 0:
                    fail(errors, f"crisis stage {index} route {route_id} cost_delta must be a non-negative integer")
                if not isinstance(effect.get("description"), str) or not effect["description"]:
                    fail(errors, f"crisis stage {index} route {route_id} must declare description")
    endings = rules.get("endings")
    if not isinstance(endings, list) or len(endings) < 4:
        fail(errors, "crisis.endings must contain at least four endings")
        return
    seen_ids: set[str] = set()
    for index, raw_ending in enumerate(endings):
        ending = as_object(raw_ending, f"crisis.endings[{index}]", errors)
        ending_id = ending.get("id")
        for field in ("id", "title", "summary"):
            if not isinstance(ending.get(field), str) or not ending[field]:
                fail(errors, f"crisis ending at index {index} must declare {field}")
        if isinstance(ending_id, str):
            if ending_id in seen_ids:
                fail(errors, f"duplicate crisis ending id: {ending_id}")
            seen_ids.add(ending_id)
        if not isinstance(ending.get("maximum_arms_escalation"), int) or ending["maximum_arms_escalation"] < 0:
            fail(errors, f"crisis ending {ending_id} must declare a non-negative maximum_arms_escalation")
        if isinstance(ending.get("required_scenario_id"), str) and ending.get("required_scenario_id"):
            if not isinstance(ending.get("required_faction_id"), str) or not ending["required_faction_id"]:
                fail(errors, f"adaptive ending {ending_id} must declare its faction requirement")
            scenario_states = ending.get("required_scenario_states")
            if not isinstance(scenario_states, list) or not scenario_states or any(state not in {"expired", "failed"} for state in scenario_states):
                fail(errors, f"adaptive ending {ending_id} must require expired or failed scenario states")
            if not isinstance(ending.get("minimum_faction_support"), int) or ending["minimum_faction_support"] < 1:
                fail(errors, f"adaptive ending {ending_id} must require positive faction support")
            resilience = as_object(ending.get("minimum_settlement_resilience"), f"adaptive ending {ending_id}.minimum_settlement_resilience", errors)
            if resilience.get("settlement_id") not in REQUIRED_SETTLEMENTS or not isinstance(resilience.get("minimum"), int) or not 1 <= resilience["minimum"] <= 10:
                fail(errors, f"adaptive ending {ending_id} must require valid settlement resilience")
            delivery = as_object(ending.get("required_ordinary_delivery"), f"adaptive ending {ending_id}.required_ordinary_delivery", errors)
            if delivery.get("settlement_id") not in REQUIRED_SETTLEMENTS or delivery.get("good_id") not in REQUIRED_GOODS:
                fail(errors, f"adaptive ending {ending_id} ordinary delivery must reference known content")
            if not isinstance(delivery.get("minimum_quantity"), int) or delivery["minimum_quantity"] <= 0 or delivery.get("after_faction_activation") is not True:
                fail(errors, f"adaptive ending {ending_id} must require a positive post-activation ordinary delivery")
            maximum_reputation = as_object(ending.get("maximum_reputation", {}), f"adaptive ending {ending_id}.maximum_reputation", errors)
            for faction_id, maximum in maximum_reputation.items():
                if faction_id not in {"wardens", "caravans", "glass_consortium", "bellkeepers"} or not isinstance(maximum, int) or not -10 <= maximum <= 10:
                    fail(errors, f"adaptive ending {ending_id} maximum_reputation is invalid")
            continue
        if ending_id == "open_routes_relief":
            if not isinstance(ending.get("required_contract_id"), str) or not ending["required_contract_id"]:
                fail(errors, "open_routes_relief must declare required_contract_id")
            if not isinstance(ending.get("minimum_reedwatch_resilience"), int) or ending["minimum_reedwatch_resilience"] < 0:
                fail(errors, "open_routes_relief must declare a non-negative resilience bound")
        elif ending_id == "ending_warden_reserve":
            for field in ("minimum_warden_reputation", "maximum_caravan_reputation"):
                if not isinstance(ending.get(field), int) or ending[field] < 0:
                    fail(errors, f"ending_warden_reserve must declare a non-negative {field}")
        elif ending_id == "ending_free_caravan_routes":
            for field in ("minimum_caravan_reputation", "maximum_warden_reputation"):
                if not isinstance(ending.get(field), int) or ending[field] < 0:
                    fail(errors, f"ending_free_caravan_routes must declare a non-negative {field}")
        elif ending_id == "ending_ash_merchant":
            for field in ("minimum_money", "maximum_reedwatch_resilience"):
                if not isinstance(ending.get(field), int) or ending[field] < 0:
                    fail(errors, f"ending_ash_merchant must declare a non-negative {field}")
        elif isinstance(ending_id, str):
            fail(errors, f"unsupported crisis ending id: {ending_id}")


def validate(data: Any) -> list[str]:
    errors: list[str] = []
    root = as_object(data, "runtime world", errors)
    if root.get("schema_version") != 1:
        fail(errors, "schema_version must equal 1")
    if not isinstance(root.get("content_version"), str) or not root["content_version"]:
        fail(errors, "content_version must be a non-empty string")

    planning = as_object(root.get("planning_assumptions"), "planning_assumptions", errors)
    if not isinstance(planning.get("provision_value"), int) or planning["provision_value"] <= 0:
        fail(errors, "planning_assumptions.provision_value must be a positive integer")
    if (
        not isinstance(planning.get("time_opportunity_cost_per_day"), int)
        or planning["time_opportunity_cost_per_day"] < 0
    ):
        fail(errors, "planning_assumptions.time_opportunity_cost_per_day must be a non-negative integer")
    if not isinstance(planning.get("reward_fixture_minutes"), int) or planning["reward_fixture_minutes"] <= 0:
        fail(errors, "planning_assumptions.reward_fixture_minutes must be a positive integer")
    minimum_ratio = planning.get("contract_expected_net_min_ratio")
    maximum_ratio = planning.get("contract_expected_net_max_ratio")
    if (
        not isinstance(minimum_ratio, (int, float))
        or isinstance(minimum_ratio, bool)
        or not isinstance(maximum_ratio, (int, float))
        or isinstance(maximum_ratio, bool)
        or minimum_ratio <= 0
        or maximum_ratio < minimum_ratio
    ):
        fail(errors, "planning_assumptions contract reward ratios must form an ordered positive band")

    validate_market_memory(root.get("market_memory"), errors)
    validate_settlement_actions(root.get("settlement_actions"), errors)
    settlement_action_rules = root.get("settlement_actions")
    visit_slot_limit = settlement_action_rules.get("visit_slots_per_arrival") if isinstance(settlement_action_rules, dict) else None
    contract_rules = root.get("contracts")
    validate_contracts(contract_rules, root.get("factions"), visit_slot_limit, errors)
    contract_records = contract_rules.get("records", []) if isinstance(contract_rules, dict) else []
    known_contract_ids = {
        contract.get("id")
        for contract in contract_records
        if isinstance(contract, dict)
        and isinstance(contract.get("id"), str)
    }
    validate_adaptive_scenarios(root.get("adaptive_scenarios"), known_contract_ids, errors)
    validate_adaptive_action_links(root.get("settlement_actions"), root.get("adaptive_scenarios"), errors)
    validate_crew(root.get("crew"), visit_slot_limit, errors)
    validate_factions(root.get("factions"), errors)
    validate_arms_trade(root.get("arms_trade"), errors)
    validate_crisis(root.get("crisis"), errors)
    validate_events(root.get("events"), errors)

    goods = root.get("goods")
    if not isinstance(goods, list):
        fail(errors, "goods must be a list")
        goods = []
    good_ids: set[str] = set()
    for index, raw_good in enumerate(goods):
        good = as_object(raw_good, f"goods[{index}]", errors)
        good_id = good.get("id")
        if not isinstance(good_id, str) or not good_id:
            fail(errors, f"goods[{index}].id must be a non-empty string")
            continue
        if good_id in good_ids:
            fail(errors, f"duplicate good id: {good_id}")
        good_ids.add(good_id)
        if not isinstance(good.get("name"), str) or not good["name"]:
            fail(errors, f"good {good_id} must have a non-empty name")
        if not isinstance(good.get("base_price"), int) or good["base_price"] <= 0:
            fail(errors, f"good {good_id} must have a positive integer base_price")
        if not isinstance(good.get("weight"), int) or good["weight"] <= 0:
            fail(errors, f"good {good_id} must have a positive integer weight")
    for good_id in REQUIRED_GOODS:
        if good_id not in good_ids:
            fail(errors, f"missing required good: {good_id}")

    settlements = as_object(root.get("settlements"), "settlements", errors)
    source_coverage: set[str] = set()
    consumer_coverage: set[str] = set()
    occupied_map_cells: dict[tuple[int, int], str] = {}
    for settlement_id in REQUIRED_SETTLEMENTS:
        settlement = as_object(settlements.get(settlement_id), f"settlement {settlement_id}", errors)
        if not isinstance(settlement.get("name"), str) or not settlement["name"]:
            fail(errors, f"settlement {settlement_id} must have a non-empty name")
        if not isinstance(settlement.get("role"), str) or not settlement["role"]:
            fail(errors, f"settlement {settlement_id} must have a non-empty role")
        identity = as_object(settlement.get("identity"), f"settlement {settlement_id}.identity", errors)
        for field in ("scene_id", "caption", "market_read", "landmark"):
            if not isinstance(identity.get(field), str) or not identity[field]:
                fail(errors, f"settlement {settlement_id}.identity.{field} must be a non-empty string")
        map_cell = identity.get("map_cell")
        if (
            not isinstance(map_cell, list)
            or len(map_cell) != 2
            or any(not isinstance(axis, int) for axis in map_cell)
            or not 0 <= map_cell[0] < 17
            or not 0 <= map_cell[1] < 11
        ):
            fail(errors, f"settlement {settlement_id}.identity.map_cell must fit the 17x11 route grid")
        else:
            map_cell_key = (map_cell[0], map_cell[1])
            if map_cell_key in occupied_map_cells:
                fail(errors, f"settlement {settlement_id}.identity.map_cell overlaps {occupied_map_cells[map_cell_key]}")
            occupied_map_cells[map_cell_key] = settlement_id
        if identity.get("landmark") not in {"gate", "brine", "forge", "lanterns", "reeds", "glass", "kiln", "mirrors", "quay", "watchtower"}:
            fail(errors, f"settlement {settlement_id}.identity.landmark is unsupported")
        for field in ("tint", "sky", "ground"):
            color = identity.get(field)
            if not isinstance(color, str) or re.fullmatch(r"#[0-9a-fA-F]{6}", color) is None:
                fail(errors, f"settlement {settlement_id}.identity.{field} must be a six-digit hex color")
        validate_trade_profile(
            settlement_id,
            settlement.get("trade_profile"),
            good_ids,
            source_coverage,
            consumer_coverage,
            errors,
        )
        validate_modifier_table(
            settlement.get("price_modifiers"),
            f"settlement {settlement_id}.price_modifiers",
            good_ids,
            errors,
        )
        validate_modifier_table(
            settlement.get("demand"),
            f"settlement {settlement_id}.demand",
            good_ids,
            errors,
        )
        modifier = settlement.get("faction_price_modifier")
        if not isinstance(modifier, (int, float)) or modifier <= 0:
            fail(errors, f"settlement {settlement_id}.faction_price_modifier must be positive")
    for good_id in REQUIRED_GOODS:
        if good_id not in source_coverage:
            fail(errors, f"trade profiles must declare at least one producer for {good_id}")
        if good_id not in consumer_coverage:
            fail(errors, f"trade profiles must declare at least one consumer for {good_id}")

    routes = as_object(root.get("routes"), "routes", errors)
    for route_id in REQUIRED_ROUTES:
        route = as_object(routes.get(route_id), f"route {route_id}", errors)
        if not isinstance(route.get("name"), str) or not route["name"]:
            fail(errors, f"route {route_id} must have a non-empty name")
        map_label = route.get("map_label")
        if not isinstance(map_label, str) or not 1 <= len(map_label) <= 12:
            fail(errors, f"route {route_id}.map_label must contain 1 through 12 characters")
        endpoints = route.get("endpoints")
        if not isinstance(endpoints, list) or len(endpoints) != 2:
            fail(errors, f"route {route_id}.endpoints must contain exactly two settlement ids")
        elif any(not isinstance(endpoint, str) or not endpoint for endpoint in endpoints):
            fail(errors, f"route {route_id}.endpoints must contain non-empty settlement ids")
        elif endpoints[0] == endpoints[1]:
            fail(errors, f"route {route_id}.endpoints must differ")
        else:
            for endpoint in endpoints:
                if endpoint not in REQUIRED_SETTLEMENTS:
                    fail(errors, f"route {route_id}.endpoints contains unknown settlement {endpoint}")
        if not isinstance(route.get("description"), str) or not route["description"]:
            fail(errors, f"route {route_id} must have a non-empty description")
        if not isinstance(route.get("cost"), int) or route["cost"] < 0:
            fail(errors, f"route {route_id}.cost must be a non-negative integer")
        if not isinstance(route.get("days"), int) or route["days"] <= 0:
            fail(errors, f"route {route_id}.days must be a positive integer")
        risk = route.get("risk")
        if not isinstance(risk, (int, float)) or not 0 <= risk <= 1:
            fail(errors, f"route {route_id}.risk must be a number between 0 and 1")
        segments = route.get("segments", [])
        if not isinstance(segments, list):
            fail(errors, f"route {route_id}.segments must be a list")
        for segment_index, segment_value in enumerate(segments if isinstance(segments, list) else []):
            segment = as_object(segment_value, f"route {route_id}.segments[{segment_index}]", errors)
            segment_endpoints = segment.get("endpoints")
            if not isinstance(segment_endpoints, list) or len(segment_endpoints) != 2 or segment_endpoints[0] == segment_endpoints[1]:
                fail(errors, f"route {route_id} segment {segment_index} must contain two different endpoints")
            elif any(endpoint not in REQUIRED_SETTLEMENTS for endpoint in segment_endpoints):
                fail(errors, f"route {route_id} segment {segment_index} contains an unknown settlement")
            if not isinstance(segment.get("cost"), int) or segment["cost"] < 0:
                fail(errors, f"route {route_id} segment {segment_index}.cost must be a non-negative integer")
            if not isinstance(segment.get("days"), int) or segment["days"] <= 0:
                fail(errors, f"route {route_id} segment {segment_index}.days must be a positive integer")
            segment_risk = segment.get("risk")
            if not isinstance(segment_risk, (int, float)) or not 0 <= segment_risk <= 1:
                fail(errors, f"route {route_id} segment {segment_index}.risk must be between 0 and 1")
    validate_regions(root.get("regions"), set(settlements), set(routes), errors)
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", type=Path, required=True)
    args = parser.parse_args()
    try:
        data = json.loads(args.data.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        print(f"BLOCK: could not read {args.data}: {error}")
        return 1

    errors = validate(data)
    if errors:
        print("BLOCK: runtime world content validation failed")
        for error in errors:
            print(f"- {error}")
        return 1
    print("PASS: runtime world content validation")
    return 0


if __name__ == "__main__":
    sys.exit(main())
