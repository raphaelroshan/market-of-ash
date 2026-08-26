#!/usr/bin/env python3
"""Validate Market of Ash's political geography content data."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def collect_ids(items: Any, label: str, errors: list[str]) -> set[str]:
    if not isinstance(items, list):
        errors.append(f"{label} must be an array")
        return set()
    result: set[str] = set()
    for index, item in enumerate(items):
        if not isinstance(item, dict) or not isinstance(item.get("id"), str) or not item["id"]:
            errors.append(f"{label}[{index}] requires a non-empty id")
            continue
        item_id = item["id"]
        if item_id in result:
            errors.append(f"duplicate id in {label}: {item_id}")
        result.add(item_id)
    return result


def check_refs(values: Any, known: set[str], label: str, errors: list[str]) -> None:
    if not isinstance(values, list):
        errors.append(f"{label} must be an array")
        return
    for value in values:
        if value not in known:
            errors.append(f"{label} references unknown id: {value}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--data", required=True)
    args = parser.parse_args()
    path = Path(args.data)
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot read political geography JSON: {exc}")
        return 1
    errors: list[str] = []
    if not isinstance(data, dict):
        print("ERROR: political geography root must be an object")
        return 1
    if data.get("game_id") != "market-of-ash":
        errors.append("game_id must be market-of-ash")

    axis_ids = collect_ids(data.get("reputation_axes", []), "reputation_axes", errors)
    group_ids = collect_ids(data.get("political_groups", []), "political_groups", errors)
    tension_ids = collect_ids(data.get("tensions", []), "tensions", errors)
    node_ids = collect_ids(data.get("map_overview", {}).get("nodes", []), "map_overview.nodes", errors)
    corridor_ids = collect_ids(data.get("map_overview", {}).get("corridors", []), "map_overview.corridors", errors)
    obstacle_ids = collect_ids(data.get("obstacles", []), "obstacles", errors)
    goods = data.get("resource_distribution", {}).get("goods", [])
    good_ids = collect_ids(goods, "resource_distribution.goods", errors)

    if len(axis_ids) < 2:
        errors.append("at least two reputation axes are required")
    if len(group_ids) < 4:
        errors.append("at least four political groups are required")
    if len(node_ids) != 5:
        errors.append("the vertical slice must contain exactly five map nodes")
    if len(corridor_ids) < 3:
        errors.append("at least three travel corridors are required")
    if len(good_ids) != 6:
        errors.append("the vertical slice must contain exactly six trade goods")
    if len(tension_ids) < 4:
        errors.append("at least four political tensions are required")
    if len(obstacle_ids) < 5:
        errors.append("at least five obstacles are required")

    for index, group in enumerate(data.get("political_groups", [])):
        if not isinstance(group, dict):
            continue
        if group.get("base") not in node_ids:
            errors.append(f"political_groups[{index}] references unknown base node: {group.get('base')}")
        for key in ("public_goal", "real_need", "power_base", "fear", "mechanical_expression"):
            if not group.get(key):
                errors.append(f"political group {group.get('id')} missing {key}")

    for index, tension in enumerate(data.get("tensions", [])):
        if not isinstance(tension, dict):
            continue
        check_refs(tension.get("sides", []), group_ids, f"tensions[{index}].sides", errors)
        if len(tension.get("player_choices", [])) < 3:
            errors.append(f"tension {tension.get('id')} needs at least three player choices")
        if len(tension.get("resolution_states", [])) < 2:
            errors.append(f"tension {tension.get('id')} needs at least two resolution states")

    for index, good in enumerate(goods if isinstance(goods, list) else []):
        if not isinstance(good, dict):
            continue
        abundance = good.get("abundance", {})
        if not isinstance(abundance, dict):
            errors.append(f"good {good.get('id')} abundance must be an object")
        else:
            unknown_nodes = [node for node in abundance if node not in node_ids]
            if unknown_nodes:
                errors.append(f"good {good.get('id')} references unknown abundance nodes: {unknown_nodes}")
            if len(abundance) < 5:
                errors.append(f"good {good.get('id')} must describe abundance across all five nodes")
        for key in ("production_or_source", "main_demand", "political_control", "crisis_behavior"):
            if not good.get(key):
                errors.append(f"good {good.get('id')} missing {key}")

    for index, corridor in enumerate(data.get("map_overview", {}).get("corridors", [])):
        if not isinstance(corridor, dict):
            continue
        check_refs(corridor.get("connects", []), node_ids, f"map_overview.corridors[{index}].connects", errors)
        if len(corridor.get("connects", [])) < 2:
            errors.append(f"corridor {corridor.get('id')} must connect at least two nodes")
        for key in ("profile", "benefit", "risk", "political_owner"):
            if not corridor.get(key):
                errors.append(f"corridor {corridor.get('id')} missing {key}")

    for index, obstacle in enumerate(data.get("obstacles", [])):
        if not isinstance(obstacle, dict):
            continue
        for key in ("category", "affects", "telegraph", "player_responses", "failure_cost"):
            if not obstacle.get(key):
                errors.append(f"obstacle {obstacle.get('id')} missing {key}")
        if len(obstacle.get("player_responses", [])) < 3:
            errors.append(f"obstacle {obstacle.get('id')} needs at least three player responses")

    stages = data.get("map_state_progression", [])
    if not isinstance(stages, list) or len(stages) != 4:
        errors.append("map_state_progression must contain four stages")

    if errors:
        print(f"Market of Ash political geography: BLOCK ({len(errors)} errors)")
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Market of Ash political geography: PASS ({len(group_ids)} groups, {len(node_ids)} nodes, {len(good_ids)} goods, {len(obstacle_ids)} obstacles)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
