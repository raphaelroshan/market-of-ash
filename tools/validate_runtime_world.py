#!/usr/bin/env python3
"""Validate the canonical runtime data used by Market of Ash simulation code."""

from __future__ import annotations

import argparse
import json
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
