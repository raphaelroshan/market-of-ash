#!/usr/bin/env python3
"""Validate the shared content manifest shape without loading Godot or rendering scenes."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def fail(errors: list[str], message: str) -> None:
    errors.append(message)


def ids(items: Any, label: str, errors: list[str]) -> set[str]:
    if not isinstance(items, list):
        fail(errors, f"{label} must be an array")
        return set()
    seen: set[str] = set()
    for index, item in enumerate(items):
        if not isinstance(item, dict):
            fail(errors, f"{label}[{index}] must be an object")
            continue
        value = item.get("id")
        if not isinstance(value, str) or not value.strip():
            fail(errors, f"{label}[{index}] is missing a non-empty id")
            continue
        if value in seen:
            fail(errors, f"duplicate id in {label}: {value}")
        seen.add(value)
    return seen


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()
    path = Path(args.manifest)
    errors: list[str] = []
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"ERROR: cannot read JSON manifest: {exc}")
        return 1
    if not isinstance(data, dict):
        print("ERROR: manifest root must be an object")
        return 1

    for key in ("schema_version", "game_id", "content_version", "campaign", "events", "progression", "endings"):
        if key not in data:
            fail(errors, f"missing top-level key: {key}")
    if not isinstance(data.get("game_id"), str) or not data.get("game_id"):
        fail(errors, "game_id must be a non-empty string")

    campaign = data.get("campaign", {})
    if not isinstance(campaign, dict):
        fail(errors, "campaign must be an object")
        campaign = {}
    chapter_ids = ids(campaign.get("chapters", []), "campaign.chapters", errors)
    location_key = "rooms" if "rooms" in data else "locations"
    location_ids = ids(data.get(location_key, []), location_key, errors)
    ids(data.get("factions", []), "factions", errors)
    character_key = "commanders" if "commanders" in data else "characters"
    character_ids = ids(data.get(character_key, []), character_key, errors)
    pack_ids = ids(data.get("packs", []), "packs", errors)
    enemy_ids = ids(data.get("enemies", []), "enemies", errors)
    event_ids = ids(data.get("events", []), "events", errors)
    ending_ids = ids(data.get("endings", []), "endings", errors)

    for index, event in enumerate(data.get("events", [])):
        if not isinstance(event, dict):
            continue
        chapter = event.get("chapter")
        if chapter not in chapter_ids:
            fail(errors, f"events[{index}] references unknown chapter: {chapter}")
        references = event.get("locations", [])
        if not isinstance(references, list):
            fail(errors, f"events[{index}].locations must be an array")
        else:
            for location in references:
                if location not in location_ids:
                    fail(errors, f"events[{index}] references unknown {location_key[:-1]}: {location}")
        choices = event.get("choices", [])
        if not isinstance(choices, list) or len(choices) < 2:
            fail(errors, f"events[{index}] must contain at least two choices")
        else:
            choice_ids: set[str] = set()
            for choice_index, choice in enumerate(choices):
                if not isinstance(choice, dict):
                    fail(errors, f"events[{index}].choices[{choice_index}] must be an object")
                    continue
                choice_id = choice.get("id")
                if choice_id in choice_ids:
                    fail(errors, f"duplicate choice id in event {event.get('id')}: {choice_id}")
                choice_ids.add(str(choice_id))
                for key in ("label", "requirements", "effects", "visible_result"):
                    if key not in choice:
                        fail(errors, f"event {event.get('id')} choice {choice_id} missing {key}")

    tracks = data.get("progression", {}).get("tracks", []) if isinstance(data.get("progression"), dict) else []
    track_ids = ids(tracks, "progression.tracks", errors)
    progression_node_ids: set[str] = set()
    for track in tracks if isinstance(tracks, list) else []:
        for node in track.get("nodes", []) if isinstance(track, dict) else []:
            node_id = node.get("id") if isinstance(node, dict) else None
            if not node_id:
                fail(errors, f"progression track {track.get('id') if isinstance(track, dict) else '?'} has a node without id")
            elif node_id in progression_node_ids:
                fail(errors, f"duplicate progression node id: {node_id}")
            else:
                progression_node_ids.add(node_id)

    for index, character in enumerate(data.get(character_key, [])):
        if not isinstance(character, dict):
            continue
        for field in ("motivation", "strength", "fear") if character_key == "characters" else ("public_doctrine", "passive", "ability"):
            if not character.get(field):
                fail(errors, f"{character_key}[{index}] missing {field}")
        for field in ("recruit_location", "home_location"):
            if field in character and character[field] not in location_ids:
                fail(errors, f"{character_key}[{index}] references unknown location: {character[field]}")
        if character_key == "commanders":
            for pack in character.get("favored_packs", []):
                if pack not in pack_ids:
                    fail(errors, f"commander {character.get('id')} references unknown pack: {pack}")

    if "packs" in data and "pieces" not in data:
        fail(errors, "packs are present but the piece catalog is missing")
    if "packs" in data and "pieces" in data:
        piece_ids = ids(data.get("pieces", []), "pieces", errors)
        for pack in data.get("packs", []):
            if not isinstance(pack, dict):
                continue
            for piece in pack.get("pieces", []):
                if piece not in piece_ids:
                    fail(errors, f"pack {pack.get('id')} references unknown piece: {piece}")

    if not event_ids:
        fail(errors, "at least one event is required")
    if not ending_ids:
        fail(errors, "at least one ending is required")
    if not track_ids:
        fail(errors, "at least one progression track is required")

    if errors:
        print(f"repository content manifest: BLOCK ({len(errors)} errors)")
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print(f"repository content manifest: PASS ({data['game_id']}, {len(event_ids)} events, {len(ending_ids)} endings)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
