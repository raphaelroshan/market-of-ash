#!/usr/bin/env python3
"""Validate the canonical runtime data used by Market of Ash simulation code."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any

REQUIRED_GOODS = ("grain", "water", "scrap", "medicine", "charcoal", "cloth")
REQUIRED_SETTLEMENTS = ("ashgate", "brine_cross", "cinderford", "hollow_market", "reedwatch")
REQUIRED_ROUTES = ("old_road", "toll_road", "dry_cut")


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
        effects = action.get("effects")
        if not isinstance(effects, dict):
            fail(errors, f"settlement action {action_id}.effects must be an object")
        elif action.get("available") is True and action_id == "ashgate_provision_bundle":
            if not isinstance(effects.get("provisions"), int) or effects["provisions"] <= 0:
                fail(errors, "settlement action ashgate_provision_bundle must add provisions")
        if action.get("available") is False and not action.get("unavailable_reason"):
            fail(errors, f"unavailable settlement action {action_id} must declare unavailable_reason")


def validate_contracts(value: Any, visit_slot_limit: Any, errors: list[str]) -> None:
    rules = as_object(value, "contracts", errors)
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
        for field in ("name", "sponsor", "description", "tradeoff", "failure_recovery"):
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

    validate_market_memory(root.get("market_memory"), errors)
    validate_settlement_actions(root.get("settlement_actions"), errors)
    settlement_action_rules = root.get("settlement_actions")
    visit_slot_limit = settlement_action_rules.get("visit_slots_per_arrival") if isinstance(settlement_action_rules, dict) else None
    validate_contracts(root.get("contracts"), visit_slot_limit, errors)
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
    for settlement_id in REQUIRED_SETTLEMENTS:
        settlement = as_object(settlements.get(settlement_id), f"settlement {settlement_id}", errors)
        if not isinstance(settlement.get("name"), str) or not settlement["name"]:
            fail(errors, f"settlement {settlement_id} must have a non-empty name")
        if not isinstance(settlement.get("role"), str) or not settlement["role"]:
            fail(errors, f"settlement {settlement_id} must have a non-empty role")
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

    routes = as_object(root.get("routes"), "routes", errors)
    for route_id in REQUIRED_ROUTES:
        route = as_object(routes.get(route_id), f"route {route_id}", errors)
        if not isinstance(route.get("name"), str) or not route["name"]:
            fail(errors, f"route {route_id} must have a non-empty name")
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
