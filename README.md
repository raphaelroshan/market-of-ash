# Market of Ash

Market of Ash is an agent-first Godot 4.x prototype for a premium Windows game targeting Steam and Epic Games Store. The project is intentionally compact: one regional map, five settlements, three routes, seven goods, three crew members, four route events, two standing factions, one emergent replacement actor, a staged water crisis, four endings, and a deterministic economy.

## Current state

The repository contains a complete, replayable alpha vertical slice presented as a game rather than a scenario selector. New Game opens a three-card illustrated introduction, then an optional two-journey campaign tutorial teaches contracts, buying, route planning, roadside decisions, arrival recovery, return trade, crew, and the regional outlook through the real deterministic systems. The stable Frontier-inspired loop is Bazaar → Departure map → road scene → encounter or approach → arrival → Bazaar. Every settlement now exposes authored production, recurring consumption, and differentiated replenishment; the Bazaar presents the selected source-to-need journey as ordinary trade that requires no contract. If the first relief offer is ignored or runs late, Reedwatch organizes the Well Commons, closes the stale job, stabilizes water, and opens a new charcoal market instead of resetting the intended quest. Developer fixtures and reports remain available in debug builds behind Ctrl+Shift+D instead of occupying the player menu. Players can influence factions and settlement resilience, steer a three-stage water crisis toward four distinct endings, and continue trading afterward. Desktop builds open at 1600×900 while retaining the established 1280×720 logical canvas and 960×540 minimum-window coverage. Versioned autosaves, backup recovery, Pause, accessibility preferences, deterministic diagnostics, and privacy-safe playtest reports support external testing.

The source and CI target Godot 4.4.1. Pull requests test on Linux and Windows, export Windows and Web builds, create and validate a single-file portable Windows ZIP, clean-extract and launch-smoke that executable, and upload GUI evidence, checksums, provenance, and a source snapshot.

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

From the Main Menu, choose **New Game** and advance the introduction to begin the guided campaign, or choose **Start without guidance** to enter the same canonical world without tutorial prompts. Continue validates and restores the safest available save generation. In debug builds, Ctrl+Shift+D reveals reproducible QA scenarios without exposing them in the release-facing menu.

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
| `docs/game_quality_vertical_slice_roadmap.md` | Complete game-quality vertical-slice plan for the basin journey, economy UX, route/map, settlements, events, factions, visual identity, audio, testing, playtesting, and alpha gates. |
| `docs/design/nonlinear_trade_and_adaptive_basin_addendum.md` | Binding design addendum ensuring ordinary trade remains valuable, scenarios remain optional, and missed opportunities create causal replacement factions and alternate endings. |
| `docs/economy/open_trade_foundation.md` | Executable Feed A contract for production, consumption, replenishment, Bazaar trade language, and ordinary-trade balance gates. |
| `docs/scenarios/well_commons_response.md` | Feed B state-machine and replacement-market contract for ignored or failed Reedwatch relief. |
| `docs/implementation_status.md` | Current implementation, verification evidence, and remaining manual gates. |
| `docs/visual_evidence_gallery.md` | Versioned internal screenshots from the `v0.12.0-alpha-quality` visual audit with Kickstarter archive guidance. |
| `src/core/economy.gd` | Pure pricing and trade validation logic. |
| `src/core/world_state.gd` | Serializable campaign state, routes, settlements, crisis, and endings. |
| `src/ui/main.gd` | Prototype UI and actionable procedural route map. Keep presentation logic here, not in the simulation. |
| `scenes/Main.tscn` | Main scene entry point. |
| `tests/` | Headless deterministic content, economy, UI, save, recovery, and campaign tests. |
| `docs/decision_log.md` | Architecture and product decisions; agents append decisions rather than silently reversing them. |
| `content/` | Canonical validated runtime and design-support data. |
| `assets/` | Art and audio assets; placeholders must remain replaceable. |

## Agent-first operating model

The current agent is given a persistent product brief, a small task, a definition of done, and a command for verification. The complete game-quality sequence is in [`docs/game_quality_vertical_slice_roadmap.md`](docs/game_quality_vertical_slice_roadmap.md); use it to prioritize player-facing quality before adding broad new content. It edits the repository, runs tests, launches the game when possible, reports what changed, and stops when the acceptance criteria are met. Do not ask the agent to “make the game better” without naming the player-facing behavior to change.

The preferred unit of work is one vertical slice. For example: “Add the toll dispute event. It must read the current route, cargo, provisions, and reputation; offer two understandable choices; modify state deterministically; show a result message; serialize correctly; and include tests.” This is better than “add events.” Ordinary trade is a first-class path: do not make authored contracts mandatory, and when a player ignores or fails a scenario, implement a causal world response rather than silently restoring the intended quest state. See [`docs/design/nonlinear_trade_and_adaptive_basin_addendum.md`](docs/design/nonlinear_trade_and_adaptive_basin_addendum.md).

## Implemented roadmap sequence

The implementation has completed roadmap slices A0–A1 and B0–B10’s automated scope, the game-facing onboarding and two-journey tutorial slice, and open-trade Feeds A–B from the adaptive-basin addendum. Packaged browser and native-renderer evidence cover the Main Menu, three introduction cards, Bazaar, Departure, road, event, arrival, confirmation, and Large text states at supported viewports. Optional interface cues, keyboard/controller remapping, Web screen-change announcements, and a semantic HTML mirror for primary actions and planning fields are implemented. The next authored gameplay feed gives the emergent Well Commons two cooperation paths and one bypass or opposition path. Remaining external alpha gates include physical-controller coverage, Windows high-DPI and antivirus/reputation review, hands-on browser/assistive-technology checks, moderated player comprehension, and eventual installer/storefront integration. See `docs/implementation_status.md` for exact evidence and current limitations.

## Definition of done for an agent task

A task is complete only when code, tests, player-facing feedback, and documentation agree. The agent must list changed files, the verification command and result, known limitations, and the next smallest task. If a test cannot be run, the agent must say so rather than claim success.
