#!/usr/bin/env python3
"""Validate Market of Ash tribal-conflict and weapons content."""
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


def refs(values: Any, known: set[str], label: str, errors: list[str]) -> None:
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
        print(f"ERROR: cannot read tribal-conflict JSON: {exc}")
        return 1
    errors: list[str] = []
    if not isinstance(data, dict):
        print("ERROR: tribal-conflict root must be an object")
        return 1
    if data.get("game_id") != "market-of-ash":
        errors.append("game_id must be market-of-ash")

    faction_ids = set(data.get("faction_refs", []))
    axis_ids = collect_ids(data.get("state_axes", []), "state_axes", errors)
    weapon_ids = collect_ids(data.get("weapon_goods", []), "weapon_goods", errors)
    stage_ids = collect_ids(data.get("escalation_stages", []), "escalation_stages", errors)
    relationship_ids = collect_ids(data.get("tribal_relationships", []), "tribal_relationships", errors)
    event_ids = collect_ids(data.get("conflict_events", []), "conflict_events", errors)
    track_ids = collect_ids(data.get("meta_progression", {}).get("tracks", []), "meta_progression.tracks", errors)
    outcome_ids = collect_ids(data.get("major_faction_outcomes", []), "major_faction_outcomes", errors)

    if faction_ids != {"cinder_riders", "salt_crown"}:
        errors.append("faction_refs must contain cinder_riders and salt_crown")
    if len(axis_ids) < 4:
        errors.append("at least four conflict state axes are required")
    if len(weapon_ids) < 4:
        errors.append("at least four weapon goods are required")
    if len(stage_ids) != 6:
        errors.append("exactly six escalation stages are required")
    if len(relationship_ids) < 1:
        errors.append("at least one tribal relationship is required")
    if len(event_ids) < 4:
        errors.append("at least four conflict events are required")
    if len(track_ids) < 2:
        errors.append("at least two meta-progression tracks are required")
    if len(outcome_ids) < 3:
        errors.append("at least three major-faction outcomes are required")

    expected_axis_ids = {"cinder_rider_armed_power", "salt_crown_armed_power", "tribal_conflict", "tribal_legitimacy"}
    if not expected_axis_ids.issubset(axis_ids):
        errors.append("the four required conflict state axes are incomplete")

    for index, weapon in enumerate(data.get("weapon_goods", [])):
        if not isinstance(weapon, dict):
            continue
        for key in ("name", "source", "inputs", "buyers", "trade_value", "bulk", "direct_power_effect", "political_risk", "notes"):
            if key not in weapon:
                errors.append(f"weapon_goods[{index}] missing {key}")
        if len(weapon.get("buyers", [])) < 2:
            errors.append(f"weapon {weapon.get('id')} needs at least two buyer groups")
        if int(weapon.get("political_risk", 0)) < 1:
            errors.append(f"weapon {weapon.get('id')} must have political risk")

    for index, stage in enumerate(data.get("escalation_stages", [])):
        if not isinstance(stage, dict):
            continue
        for key in ("name", "visible_map_changes", "weapon_behavior", "player_options", "failure_cost"):
            if not stage.get(key):
                errors.append(f"escalation_stages[{index}] missing {key}")
        if len(stage.get("player_options", [])) < 3:
            errors.append(f"escalation stage {stage.get('id')} needs at least three player options")

    for index, event in enumerate(data.get("conflict_events", [])):
        if not isinstance(event, dict):
            continue
        for key in ("chapter", "title", "trigger", "setup", "choices"):
            if not event.get(key):
                errors.append(f"conflict_events[{index}] missing {key}")
        choices = event.get("choices", [])
        if len(choices) < 3:
            errors.append(f"conflict event {event.get('id')} needs at least three choices")
        choice_ids: set[str] = set()
        for choice in choices:
            if not isinstance(choice, dict):
                continue
            if choice.get("id") in choice_ids:
                errors.append(f"duplicate choice in conflict event {event.get('id')}: {choice.get('id')}")
            choice_ids.add(str(choice.get("id")))
            for key in ("label", "effects", "visible_result"):
                if not choice.get(key):
                    errors.append(f"conflict event {event.get('id')} choice {choice.get('id')} missing {key}")

    relationship = data.get("tribal_relationships", [{}])[0] if data.get("tribal_relationships") else {}
    if set(relationship.get("sides", [])) != {"cinder_riders", "salt_crown"}:
        errors.append("the primary tribal relationship must connect both tribes")
    if not relationship.get("peace_conditions") or not relationship.get("war_conditions"):
        errors.append("the tribal relationship needs both peace and war conditions")

    meta = data.get("meta_progression", {})
    if not meta.get("principle") or not meta.get("unlock_sources"):
        errors.append("meta_progression needs a principle and unlock sources")
    for index, track in enumerate(meta.get("tracks", [])):
        if not isinstance(track, dict) or len(track.get("nodes", [])) < 3:
            errors.append(f"meta progression track {track.get('id') if isinstance(track, dict) else '?'} needs at least three nodes")

    for index, outcome in enumerate(data.get("major_faction_outcomes", [])):
        if not isinstance(outcome, dict):
            continue
        for key in ("trigger", "market_change", "player_trade_position"):
            if not outcome.get(key):
                errors.append(f"major_faction_outcomes[{index}] missing {key}")

    if errors:
        print(f"Market of Ash tribal conflict: BLOCK ({len(errors)} errors)")
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"Market of Ash tribal conflict: PASS ({len(faction_ids)} tribal factions, {len(weapon_ids)} weapon goods, {len(stage_ids)} escalation stages, {len(event_ids)} conflict events)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
