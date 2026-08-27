# Market of Ash

Market of Ash is an agent-first Godot 4.x prototype for a premium Windows game targeting Steam and Epic Games Store. The project is intentionally small: one regional map, five settlements, three routes, six goods, three crew roles, a water crisis, and a deterministic economy.

## Current state

The repository contains a playable vertical-slice shell and a headless economy foundation. The main scene demonstrates buying cargo, selling cargo, selecting routes, traveling between settlements, saving prototype state, and watching the regional crisis modify prices. The visual layer now includes an intentional procedural Five-Well Basin placeholder: a readable 17x11 grid, settlement footprints, differentiated route corridors, a selectable future placement cell, and a caravan token that visibly traverses a route after departure. These are replaceable presentation layers; the simulation remains authoritative and independent of rendering.

Godot is not installed in the sandbox used to generate this package. Run the commands below on a development machine with Godot 4.x installed. The project is designed to be edited locally by an agent through a bound project folder and committed through Git.

## Run the prototype

From the repository root:

```bash
godot --editor project.godot
godot --path . --editor
```

To launch directly:

```bash
godot --path . --editor
```

The exact direct-launch command may vary slightly by Godot installation; the stable form is:

```bash
godot --path . --editor
```

Then press **F6** for the current scene or **F5** for the project.

## Run tests

The test runner is a headless Godot script:

```bash
godot --headless --path . --script res://tests/test_economy.gd
```

A successful run prints `PASS: Market of Ash economy tests` and exits with code 0. Agents must run this command after every change to `src/core/**`, `data/**`, `tests/**`, or save-state code.

## Repository map

| Path | Purpose |
| --- | --- |
| `design/design_prompt.md` | Full product and implementation prompt. Feed this to the main coding agent as the persistent product brief. |
| `AGENTS.md` | Operating rules for agents working in this repository. |
| `docs/agent_feeding_guide.md` | Recommended prompt sequence and review loop. |
| `src/core/economy.gd` | Pure pricing and trade validation logic. |
| `src/core/world_state.gd` | Serializable vertical-slice world state, routes, settlements, and crisis. |
| `src/ui/main.gd` | Prototype UI and drawn map shell. Keep presentation logic here, not in the simulation. |
| `scenes/Main.tscn` | Main scene entry point. |
| `tests/test_economy.gd` | Headless deterministic tests. |
| `docs/decision_log.md` | Architecture and product decisions; agents append decisions rather than silently reversing them. |
| `data/` | Future JSON or Godot Resource content definitions. |
| `assets/` | Art and audio assets; placeholders must remain replaceable. |

## Agent-first operating model

The agent is given a persistent product brief, a small task, a definition of done, and a command for verification. It edits the repository, runs tests, launches the game when possible, reports what changed, and stops when the acceptance criteria are met. Do not ask the agent to “make the game better” without naming the player-facing behavior to change.

The preferred unit of work is one vertical slice. For example: “Add the toll dispute event. It must read the current route, cargo, provisions, and reputation; offer two understandable choices; modify state deterministically; show a result message; serialize correctly; and include tests.” This is better than “add events.”

## Recommended first implementation sequence

1. Stabilize the current project, test runner, and map-grid presentation.
2. Move settlement and route definitions from `world_state.gd` into data files or typed Resources without changing behavior.
3. Implement a command/result layer for buying, selling, departing, and event resolution.
4. Add the four vertical-slice events and deterministic seeded resolution.
5. Add crew and faction state with tests for each interaction.
6. Replace the procedural map placeholder with finalizable 2D art while preserving grid, route, settlement, and token interfaces.
7. Implement save versioning and migration.
8. Add Steam and Epic adapters behind a platform interface.
9. Build a Windows demo and run usability, controller, scaling, and long-session tests.

## Definition of done for an agent task

A task is complete only when code, tests, player-facing feedback, and documentation agree. The agent must list changed files, the verification command and result, known limitations, and the next smallest task. If a test cannot be run, the agent must say so rather than claim success.
