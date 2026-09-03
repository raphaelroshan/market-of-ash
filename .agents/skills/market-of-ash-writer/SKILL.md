---
name: market-of-ash-writer
description: Audit, rewrite, or author Market of Ash player-facing copy for clear trade decisions, restrained ashland voice, distinct places and people, and concise consequence or recovery language. Use for tutorials, Bazaar text, routes, encounters, contracts, receipts, dialogue, and endings. Do not change mechanics, numeric promises, or state semantics without explicit design work.
---

# Market of Ash writer

Write economical game text that helps the player choose what to carry, which road to trust, and what consequence to accept.

Read `design/design_prompt.md` before substantial work. For voice or regional distinctions, read `references/voice-and-copy-contract.md`. For a specific system, inspect its runtime data, presenter, and tests before revising copy.

## Core standard

Every player-facing line should perform at least one job:

- orient the player in a place or journey phase;
- explain a material need, cost, exposure, or prerequisite;
- sharpen anticipation before commitment;
- make an outcome and its cause memorable;
- state a concrete recovery or next action;
- reveal character or faction through a decision-relevant detail.

Prefer concrete nouns and active verbs. Put the decision or changed fact before atmosphere. Keep atmosphere specific to the physical world: ash, brine, glass, reeds, peat, wheels, seals, bells, ledgers, water, cargo, and roads.

## Preserve

- Stable IDs, numeric terms, command meanings, and save compatibility.
- Honest uncertainty and every disclosed cost or risk.
- Ordinary trade as a complete path; contracts and factions remain optional.
- Short, readable copy at 960×540 and with Large Text.
- Frontier-inspired contextual commitment without copying another game's language.

Do not add lore that changes no decision. Do not use generic urgency, heroic destiny, moral labels, modern product language, or unexplained proper nouns. Avoid repeating the same fact in the heading, body, tooltip, and next-action line.

## Modes

### Audit

Inventory the shipped strings in player order: Main Menu, Introduction, Bazaar, Departure, road, encounter, arrival, return market, and ending. Flag copy only when the surrounding screen confirms a player cost. Rank findings as blocker, major, or polish.

### Rewrite

Change one coherent beat at a time. Keep factual fields and thresholds intact. Update assertions only when they test intentionally changed player language, not merely to silence regressions.

### Author

Before adding a new line, name its screen, player question, authoritative facts, and next action. Reject prose that cannot answer one of those needs.

## Verification

Run the smallest content validator and focused Godot test, then the full normal flow for changes spanning more than one screen. Capture normal and Large Text frames when line length or hierarchy changes. Report the original problem, changed player behavior, exact verification, remaining judgment calls, and one next task.
