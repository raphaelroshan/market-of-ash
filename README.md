# Market of Ash

Market of Ash is an agent-first Godot 4.x prototype for a premium Windows game targeting Steam and Epic Games Store. The project is intentionally compact: one regional map, five settlements, three routes, seven goods, three crew members, four route events, two factions, a staged water crisis, four endings, and a deterministic economy.

## Current state

The repository contains a complete, replayable alpha vertical slice. Players can inspect explained prices, trade, accept a relief contract, recruit and assign crew, plan through a clickable regional map, resolve state-sensitive route events, influence factions and settlement resilience, steer a three-stage water crisis toward four distinct endings, and continue trading afterward. Versioned autosaves, backup recovery, Pause, accessibility preferences, deterministic diagnostics, and privacy-safe playtest reports support external testing.

The source and CI target Godot 4.4.1. Pull requests test on Linux and Windows, export Windows and Web builds, launch-smoke the Windows executable, and upload a provenance manifest plus source snapshot.

## Run the prototype

From the repository root:

```bash
godot --editor project.godot
```

To launch directly:

```bash
godot --path .
```

Then press **F6** for the current scene or **F5** for the project.

## Run tests

The single verification entrypoint runs repository policy, every content validator, validator fixtures, and the economy, map UI, and campaign suites:

```bash
bash scripts/verify.sh
```

Godot 4.4.1 must be available as `godot` or `godot4`. A successful run prints a PASS result for every validator and test suite and exits with code 0.

## Repository map

| Path | Purpose |
| --- | --- |
| `design/design_prompt.md` | Full product and implementation prompt. Feed this to the main coding agent as the persistent product brief. |
| `AGENTS.md` | Operating rules for agents working in this repository. |
| `docs/agent_feeding_guide.md` | Recommended prompt sequence and review loop. |
| `docs/gpt_agent_handoff_roadmap.md` | Dependency-ordered development roadmap and quality gates. |
| `docs/implementation_status.md` | Current implementation, verification evidence, and remaining manual gates. |
| `src/core/economy.gd` | Pure pricing and trade validation logic. |
| `src/core/world_state.gd` | Serializable campaign state, routes, settlements, crisis, and endings. |
| `src/ui/main.gd` | Prototype UI and actionable procedural route map. Keep presentation logic here, not in the simulation. |
| `scenes/Main.tscn` | Main scene entry point. |
| `tests/` | Headless deterministic content, economy, UI, save, recovery, and campaign tests. |
| `docs/decision_log.md` | Architecture and product decisions; agents append decisions rather than silently reversing them. |
| `content/` | Canonical validated runtime and design-support data. |
| `assets/` | Art and audio assets; placeholders must remain replaceable. |

## Agent-first operating model

The agent is given a persistent product brief, a small task, a definition of done, and a command for verification. It edits the repository, runs tests, launches the game when possible, reports what changed, and stops when the acceptance criteria are met. Do not ask the agent to “make the game better” without naming the player-facing behavior to change.

The preferred unit of work is one vertical slice. For example: “Add the toll dispute event. It must read the current route, cargo, provisions, and reputation; offer two understandable choices; modify state deterministically; show a result message; serialize correctly; and include tests.” This is better than “add events.”

## Implemented roadmap sequence

The implementation has completed roadmap slices A0–A1 and B0–B10’s automated scope. Packaged Main Menu and initial Shop renders now cover the 960×540 and 1280×720 browser baselines, and optional interface cues plus keyboard/controller remapping are implemented. The remaining alpha gates are inspection of the newly expanded rendered browser states, physical-controller coverage, high-DPI review, screen-reader work, and eventual storefront integration. See `docs/implementation_status.md` for exact evidence and current limitations.

## Definition of done for an agent task

A task is complete only when code, tests, player-facing feedback, and documentation agree. The agent must list changed files, the verification command and result, known limitations, and the next smallest task. If a test cannot be run, the agent must say so rather than claim success.
