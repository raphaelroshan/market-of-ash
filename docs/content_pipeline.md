# Content Pipeline

## Purpose

Content is authored as both a human-readable design bible and a machine-readable manifest. The design bible explains the dramatic purpose, player-facing language, and progression logic. `content/content_manifest.json` contains stable identifiers and structured fields that future Godot systems can load without parsing prose.

The content layer is deliberately separate from simulation code. Events describe requirements and intended effects, but runtime code must translate those effects into explicit validated commands. Narrative text must never be used as a hidden scripting language.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `design/content_bible.md` | Narrative premise, tone, locations or rooms, characters or commanders, event rules, progression, endings, and implementation guidance. |
| `content/content_manifest.json` | Stable IDs and structured authored content for campaign chapters, locations, events, progression tracks, and endings. |
| `tools/validate_content.py` | Deterministic JSON/reference validator used by CI. |
| `ci/quality_contract.md` | Game-specific review criteria used by the multi-agent reviewer. |

## Authoring contract

Every authored object receives a stable `id` in `snake_case`. IDs are implementation references and should not be renamed casually after a feature is merged. Display names, descriptions, and dialogue can change without changing the ID.

Every event belongs to a campaign chapter, references only known locations or rooms, and contains at least two choices. Every choice has a label, requirements, effects, and visible result. Requirements and effects are intentionally represented as data for later command mapping; they are not executed by the validator or interpreted directly by the UI.

Progression nodes should unlock a new decision or response rather than only increase a number. Endings should be reachable through multiple reasonable play styles when the simulation supports them. A failure or partial-success outcome must explain what was lost and preserve a meaningful next action.

## Agent workflow

An implementation agent should first read the relevant section of the content bible, then inspect the manifest and current simulation state. It should add or update the smallest content slice: one event card, one location or room report, one choice effect, or one progression milestone. The agent must update the manifest, add or update deterministic validation coverage, and show the player-facing result before expanding the catalog.

When content introduces a new mechanic, the agent should make the command and state change explicit in the simulation layer. When content only changes text or presentation, it should preserve deterministic outcomes. Before merging, run the policy checker, content validator, and Godot headless tests. During review, use the game-specific quality contract to check that the new content strengthens the central decision rather than adding lore without consequence.

## Content quality checklist

A content change is ready for review when a player can identify where it occurs, why it matters, what choices are available, what resources or relationships are at stake, and what visible result follows. The event should not rely on an unexplained random draw, a mandatory counter, or an invisible reputation threshold. The location or room should have a distinct role, visual identity, and strategic consequence. The progression node should create a new option or make a previously weak option viable.
