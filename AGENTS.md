# AGENTS.md — Market of Ash

## Mission

Build a polished single-player trade-and-travel RPG for Windows, targeting Steam and Epic Games Store. Preserve the central promise: routes are economic choices with human and political consequences.

## Read before editing

Read these files in order:

1. `design/design_prompt.md`
2. `README.md`
3. `docs/decision_log.md`
4. The smallest relevant source and test files.

## Rules

Use GDScript and Godot 4.x conventions already present in the repository. Keep the simulation deterministic and independent of rendering. Do not put price calculation, route validation, faction mutation, or save migration inside UI scripts. UI emits commands; core systems validate commands and return structured results.

Make one coherent change at a time. Before editing, state the player-facing behavior that will change. Before adding content, define the data shape and acceptance criteria. Before refactoring, write a decision-log entry explaining why the current structure is insufficient.

Prefer plain data and small functions over clever abstractions. Use stable identifiers rather than display names. Do not hardcode a new settlement, good, route, event, or crew member in multiple scripts. Put content in `data/` once the first system is stable.

Do not add multiplayer, online markets, crafting chains, factories, live-service systems, permadeath, microtransactions, or a second region until the vertical slice passes its quality gates. Do not broaden scope to hide a weak core loop.

## Verification protocol

After changes to simulation, run:

```bash
godot --headless --path . --script res://tests/test_economy.gd
```

After changes to UI or scene files, launch the project and manually verify the main decision path. Check at minimum: buy, sell, depart, blocked departure, route incident, crisis price change, save, reset, window resizing, and controller focus order.

If Godot is unavailable, do not pretend the test passed. Report the exact command that remains to be run and perform static review of the changed GDScript instead.

## Agent response format

Every implementation response must contain:

- **Intent:** the player-facing behavior being changed.
- **Plan:** the smallest files and steps needed.
- **Changes:** files changed and why.
- **Verification:** exact commands run and their output or limitation.
- **Risks:** edge cases, balance concerns, or known missing work.
- **Next task:** one small follow-up task, not a broad backlog.

## Quality rules

A system is not finished because it functions in code. It is finished when a new player can understand it, predict it, use it, and recover from a reasonable mistake. Every important number needs a reason. Every random outcome needs agency or a recovery path. Every new mechanic needs a teaching scenario. Every release build needs mouse, keyboard, controller, scaling, save/load, and storefront smoke tests.

## Art and content rules

Use a 2D illustrated style with strong silhouettes, deliberate palettes, and readable information hierarchy. Temporary art must preserve composition and scale and must be replaceable through stable references. Do not use visual noise to disguise missing design.

Write short, specific text. Settlement descriptions should tell the player what is different and why it matters. Events should make choices and consequences concrete. Avoid lore that does not change a decision.
