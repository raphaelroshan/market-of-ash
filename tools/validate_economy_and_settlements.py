#!/usr/bin/env python3
"""Validate Market of Ash economy and settlement action content."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any

SETTLEMENTS = {"ashgate", "brine_cross", "cinderford", "hollow_market", "reedwatch"}
GOODS = {"grain", "water", "scrap", "medicine", "charcoal", "cloth"}
REQUIRED_PILLARS = {
    "regional_price_divergence",
    "distant_market_profit",
    "demand_specialization",
    "market_memory",
    "risk_adjusted_margin",
}
REQUIRED_SIGNALS = {
    "local_buy_price",
    "local_sell_price",
    "demand_level",
    "supply_pressure",
    "trend_direction",
    "route_cost",
    "expected_net_profit",
}


def ids(items: Any, label: str, errors: list[str]) -> set[str]:
    if not isinstance(items, list):
        errors.append(f"{label} must be an array")
        return set()
    seen: set[str] = set()
    for index, item in enumerate(items):
        if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not item["id"]:
            errors.append(f"{label}[{index}] requires a non-empty id")
            continue
        if item["id"] in seen:
            errors.append(f"duplicate id in {label}: {item['id']}")
        seen.add(item["id"])
    return seen


def load(path: Path, label: str, errors: list[str]) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"cannot read {label}: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"{label} root must be an object")
        return {}
    return value


def validate_economy(data: dict[str, Any], errors: list[str]) -> tuple[int, int]:
    if data.get("game_id") != "market-of-ash":
        errors.append("economy game_id must be market-of-ash")
    pillar_ids = ids(data.get("frontier_pillars"), "frontier_pillars", errors)
    signal_ids = ids(data.get("market_signals"), "market_signals", errors)
    settlement_ids = {item.get("settlement_id") for item in data.get("settlement_profiles", []) if isinstance(item, dict)}
    goods_ids = {item.get("good_id") for item in data.get("goods_profiles", []) if isinstance(item, dict)}
    trend_ids = ids(data.get("trend_rules"), "trend_rules", errors)
    trade_ids = ids(data.get("trade_decisions"), "trade_decisions", errors)
    if not REQUIRED_PILLARS.issubset(pillar_ids):
        errors.append("Frontier economy pillars are incomplete")
    if not REQUIRED_SIGNALS.issubset(signal_ids):
        errors.append("required price and trend signals are incomplete")
    if settlement_ids != SETTLEMENTS:
        errors.append(f"settlement profiles must cover exactly {sorted(SETTLEMENTS)}")
    if goods_ids != GOODS:
        errors.append(f"goods profiles must cover exactly {sorted(GOODS)}")
    if len(trend_ids) < 5:
        errors.append("at least five market trend rules are required")
    if len(trade_ids) < 5:
        errors.append("at least five trade decisions are required")

    for item in data.get("settlement_profiles", []):
        if not isinstance(item, dict):
            continue
        for key in ("settlement_id", "produces_cheaply", "demands_at_premium", "special_demand", "typical_market_posture", "trend_drivers"):
            if not item.get(key):
                errors.append(f"settlement profile {item.get('settlement_id')} missing {key}")
    for item in data.get("goods_profiles", []):
        if not isinstance(item, dict):
            continue
        for key in ("good_id", "bulk_class", "normal_spread", "demand_pattern", "best_origin_examples", "best_destination_examples", "why_it_moves", "saturation_behavior"):
            if not item.get(key):
                errors.append(f"goods profile {item.get('good_id')} missing {key}")
        if not set(item.get("best_origin_examples", [])).issubset(SETTLEMENTS):
            errors.append(f"goods profile {item.get('good_id')} has an unknown origin settlement")
        if not set(item.get("best_destination_examples", [])).issubset(SETTLEMENTS):
            errors.append(f"goods profile {item.get('good_id')} has an unknown destination settlement")
    route = data.get("route_profitability", {})
    if not route.get("formula") or not route.get("risk_inputs") or len(route.get("distance_bands", [])) != 3:
        errors.append("route_profitability needs formula, risk inputs, and nearby/regional/distant bands")
    else:
        distance_ids = ids(route.get("distance_bands"), "route_profitability.distance_bands", errors)
        if distance_ids != {"nearby", "regional", "distant"}:
            errors.append("distance bands must be nearby, regional, and distant")
        if not route.get("display_breakdown") or "expected_net_profit" not in route.get("display_breakdown", []):
            errors.append("route profitability must display expected_net_profit")
    guardrails = data.get("frontier_guardrails", [])
    if len(guardrails) < 7:
        errors.append("at least seven Frontier economy guardrails are required")
    return len(pillar_ids), len(goods_ids)


def validate_settlements(data: dict[str, Any], errors: list[str]) -> tuple[int, int]:
    if data.get("game_id") != "market-of-ash":
        errors.append("settlement-actions game_id must be market-of-ash")
    visit = data.get("visit_model", {})
    if visit.get("trade_is_always_available") is not True:
        errors.append("trade_is_always_available must be true")
    if int(visit.get("service_slots_per_visit", 0)) < 2:
        errors.append("settlement visits need at least two service slots")
    global_ids = ids(data.get("global_actions"), "global_actions", errors)
    if len(global_ids) < 10:
        errors.append("at least ten global settlement actions are required")
    category_ids = ids(data.get("action_categories"), "action_categories", errors)
    required_categories = {"trade", "people", "information", "logistics", "diplomacy", "relief"}
    if not required_categories.issubset(category_ids):
        errors.append("settlement action categories are incomplete")
    for index, action in enumerate(data.get("global_actions", [])):
        if not isinstance(action, dict):
            continue
        for key in ("id", "category", "name", "time_cost", "service_slots", "requirements", "effects", "visible_preview", "tradeoff"):
            if key not in action or action[key] in (None, "", []):
                errors.append(f"global_actions[{index}] missing {key}")
        if action.get("category") not in required_categories:
            errors.append(f"global action {action.get('id')} has unknown category")
    overrides = data.get("settlement_overrides", {})
    if set(overrides) != SETTLEMENTS:
        errors.append("settlement_overrides must cover all five settlements")
    known_ids = set(global_ids)
    special_count = 0
    for settlement_id, override in overrides.items():
        if not isinstance(override, dict):
            errors.append(f"settlement override {settlement_id} must be an object")
            continue
        if not override.get("arrival_report"):
            errors.append(f"settlement override {settlement_id} needs an arrival_report")
        available = override.get("available_actions", [])
        if len(available) < 6:
            errors.append(f"settlement override {settlement_id} needs at least six available actions")
        for action_id in available:
            if action_id not in global_ids:
                errors.append(f"settlement {settlement_id} references unknown global action {action_id}")
        for action in override.get("special_actions", []):
            special_count += 1
            if not isinstance(action, dict):
                errors.append(f"settlement {settlement_id} has a malformed special action")
                continue
            known_ids.add(str(action.get("id")))
            for key in ("id", "category", "time_cost", "service_slots", "requirements", "effects", "tradeoff"):
                if key not in action or action[key] in (None, "", []):
                    errors.append(f"special action {action.get('id')} at {settlement_id} missing {key}")
            if action.get("category") not in required_categories:
                errors.append(f"special action {action.get('id')} has unknown category")
    interface = data.get("interface_structure", {})
    if interface.get("default_view") != "Market":
        errors.append("default settlement view must be Market")
    if len(interface.get("primary_tabs", [])) < 6:
        errors.append("settlement interface needs at least six primary tabs")
    if len(interface.get("anti_menu_bloat_rules", [])) < 4:
        errors.append("settlement interface needs anti-menu-bloat rules")
    if len(data.get("design_guardrails", [])) < 7:
        errors.append("at least seven settlement design guardrails are required")
    return len(global_ids), special_count


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--economy", required=True)
    parser.add_argument("--settlements", required=True)
    args = parser.parse_args()
    errors: list[str] = []
    economy = load(Path(args.economy), "economy framework", errors)
    settlements = load(Path(args.settlements), "settlement actions", errors)
    pillar_count, goods_count = validate_economy(economy, errors)
    global_count, special_count = validate_settlements(settlements, errors)
    if errors:
        print(f"Market economy and settlements: BLOCK ({len(errors)} errors)")
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Market economy and settlements: PASS ({pillar_count} Frontier pillars, {goods_count} goods, {global_count} global actions, {special_count} settlement-specific actions)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
