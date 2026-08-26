# Agent-First Development Stack
## For Market of Ash, The Cartographer’s Siege, and Pack the Keep

**Prepared by Manus AI — August 2026**

## Executive recommendation

For a **desktop-first commercial game**, I recommend:

> **Godot 4.x, GDScript-first, GitHub, data-driven content, deterministic simulation, headless tests, and a small model team in which a high-capability model designs and reviews while a cheaper coding model performs routine implementation.**

The default engine should be **Godot**, not Unity or Unreal. Your planned 2D-ish style, compact strategy maps, top-down fort, route network, illustrated portraits, and limited 2.5D effects are all in Godot’s natural territory. Godot has a dedicated 2D renderer and 2D physics engine, and its official documentation explicitly supports command-line operation, scene execution, headless mode, and running scripts without opening the editor.[1]

For an agent-first workflow, this matters more than raw engine feature count. The agent should be able to read a project, change a small number of text files, run a deterministic test, launch a scene, capture evidence, and repair the result. Godot projects are well suited to that loop because the important project logic can live in readable `.gd`, `.tscn`, `.tres`, `.json`, and `.csv` files rather than being hidden entirely inside editor-only state.

If the first product is explicitly **browser-first**, the alternative should be **TypeScript with Babylon.js**, hosted in the existing Manus WebDev game pipeline. That route is useful for rapid playable prototypes and instant sharing, but it is not my first choice for a premium PC game with a long-lived simulation and substantial content pipeline.

## Engine comparison

| Engine | Agent-first strengths | Agent-first weaknesses | Recommendation |
|---|---|---|---|
| **Godot 4.x** | Text-friendly scenes and scripts, excellent 2D support, lightweight editor, easy local iteration, headless CLI, no engine royalty, strong fit for deterministic strategy games. | Smaller commercial ecosystem than Unity, fewer off-the-shelf premium plugins, some editor operations still produce scene-file diffs that need discipline. | **Recommended default.** |
| **Unity 6.x** | Large ecosystem, mature 2D tools, C#, extensive platform support, strong commercial middleware. Unity officially supports command-line launches, batch mode, executed methods, automated builds, and test-related workflows.[2] | More asset/import metadata, more editor-generated state, larger project overhead, more opportunities for an agent to make changes that are difficult to review in a diff. | Use if the team already has deep Unity expertise or needs a specific Unity-only plugin/platform. |
| **Unreal Engine** | Excellent 3D rendering, strong tools, powerful visual presentation. | Excessive for these 2D-ish games, heavier iteration, more hidden editor state, more expensive art and engineering pipeline. | **Do not use for the first versions.** |
| **Defold** | Lightweight, Lua-based, good for 2D, command-line build tool, compact projects. | Smaller ecosystem and less convenient for the kind of simulation/editor/test tooling these games may need. | Viable for a very small 2D game, but second choice behind Godot. |
| **Babylon.js + TypeScript** | Excellent for browser-first deployment, all logic is text, easy web tooling, natural integration with automated browser screenshots, accessible demos. | More custom work for editor-like 2D map tools, save/export packaging, desktop storefront distribution, and content authoring. | **Recommended browser-first alternative**, not default desktop engine. |

Unity is not hostile to agent-first development. Its official documentation confirms that command-line and batch workflows can launch the editor, execute static methods, perform builds, and support automated production tasks.[2] The reason it is second choice here is not lack of capability; it is that Godot is likely to keep more of this particular project’s logic visible, compact, and reviewable.

## Model stack

The best model is not one model doing every task. Use a **role-based model stack**.

The live built-in model catalog checked for this recommendation contains GPT-5 nano, GPT-5 mini, GPT-5, GPT-5.5, Claude Haiku 4.5, Claude Sonnet 4.6, Claude Opus 4.6, Claude Opus 4.7, Gemini 3 Flash Preview, and Gemini 3.1 Pro Preview. All listed models support tools, vision, JSON-schema output, and reasoning in the current catalog; the exact catalog should be rechecked when implementation begins because IDs and pricing can change.

| Role | Recommended model | Why |
|---|---|---|
| Lead designer and technical architect | **Claude Opus 4.7** or **GPT-5.5** | Use for system boundaries, architecture reviews, difficult debugging, economy balance reasoning, and decisions that affect the whole project. |
| Primary coding agent | **Claude Sonnet 4.6** or **GPT-5** | Strong coding and reasoning at a more practical cost. Use for gameplay systems, UI, tools, save systems, and refactors. |
| Routine implementation and content conversion | **GPT-5 mini** | Good default workhorse for straightforward scripts, data conversion, test generation, documentation, and small fixes. |
| High-volume cheap checks | **GPT-5 nano** | Use for naming checks, schema validation, simple tagging, log classification, and bulk content linting. |
| Screenshot and visual review | **Gemini 3.1 Pro Preview** | Use when judging layout, readability, visual hierarchy, sprite errors, map clarity, or whether a feature is visibly complete. |
| Fast visual iteration | **Gemini 3 Flash Preview** | Use for inexpensive screenshot descriptions, asset tagging, and first-pass visual QA. |

My practical default would be **Claude Sonnet 4.6 as the everyday coding agent, Claude Opus 4.7 as an escalation/reviewer, GPT-5 mini for routine structured tasks, and Gemini 3.1 Pro Preview as the visual QA reviewer**. GPT-5 or GPT-5.5 can replace the Claude roles if the team prefers OpenAI-style coding behavior.

Do not ask the strongest model to generate the entire game in one pass. Give it a narrow task with a contract, tests, affected files, and acceptance criteria. The strongest model should spend more time on architecture, review, and difficult failures than on writing repetitive content.

## Repository architecture

The repository should be readable to both people and agents. Keep the gameplay model separate from engine presentation wherever practical.

```text
project/
  project.godot
  README.md
  PRODUCT.md
  DESIGN_BIBLE.md
  AGENTS.md
  PLAN.md
  MEMORY.md
  CHANGELOG.md
  docs/
    loops/
    systems/
    decisions/
    playtests/
  game/
    core/                 # pure rules and deterministic simulation
    market_of_ash/        # if this repository is for that game
    cartographers_siege/
    pack_the_keep/
  scenes/
    maps/
    ui/
    actors/
    buildings/
  data/
    goods.json
    factions.json
    commanders.json
    packs.json
    enemies.json
    scenarios.json
  art/
    source/
    generated/
    approved/
  audio/
  tools/
  tests/
    unit/
    simulation/
    smoke/
    fixtures/
  scripts/
    test.sh
    run_headless.sh
    export.sh
```

If the three games are developed as separate products, use separate repositories or at least separate top-level product directories. Do not create a shared framework so abstract that all three games inherit unnecessary complexity. Share only proven utilities such as deterministic random seeds, save serialization, input mapping, camera helpers, localization, and test reporting.

Every significant system should have a short design contract. For example:

```text
System: Road construction
Purpose: Let players trade construction cost against defensive quality.
Inputs: Terrain, materials, labor, route endpoints, enemy forecast.
Outputs: Road tiles, travel time, supply capacity, exposure score.
Invariants: Roads cannot create disconnected invalid graphs; costs are deterministic.
Tests: Cheapest valid route, blocked bridge, road deletion, save/load, seeded replay.
Visible proof: The map shows cost, route value, danger, and resulting enemy approach.
```

The agent should never need to infer the project’s design intent solely from code. Store the intent in short documents and keep them current.

## Agent operating loop

The central development loop should be:

> **Specify → implement one slice → run tests → launch a deterministic scenario → inspect screenshot or log → review diff → commit.**

A task should normally modify one system or one vertical slice, not an entire game. Each task should state the files it may touch, the command used to verify it, and the evidence required for completion.

A good `AGENTS.md` should require the agent to preserve deterministic seeds, avoid unrelated refactors, update tests with behavior changes, keep content in data files, and report any visual uncertainty rather than claiming completion. It should also require a short summary of changed files and test results after every task.

The project should use fixed seeds for all procedural tests. A failed scenario should be replayable with a command such as:

```text
godot --headless --path . --script tools/run_scenario.gd -- --scenario=road_breach --seed=18421
```

The exact script is project-specific, but the principle is essential. Without deterministic replay, an agent will spend time chasing failures that cannot be reproduced.

## Testing strategy

Use four layers of testing.

| Layer | Examples | Purpose |
|---|---|---|
| Pure rules tests | Price changes, route cost, damage, morale, pack compatibility, save serialization. | Catch logic errors quickly without launching a scene. |
| Simulation tests | One hundred seeded markets, one hundred fort defenses, repeated road layouts, commander balance checks. | Detect dominant strategies, runaway economies, unwinnable seeds, and progression problems. |
| Smoke tests | Start game, load scenario, place building, complete wave, save, reload, exit. | Catch broken scenes, missing resources, input failures, and save regressions. |
| Visual tests | Fixed screenshots at known states, UI readability checks, map clarity checks, effect and silhouette review. | Ensure the feature is visible and commercially legible, not merely present in code. |

Godot’s command-line documentation supports headless operation, scene selection, and running scripts from the command line, which makes this layered approach practical for continuous checks.[1]

The most valuable automated tests are not only unit tests. They are **small deterministic scenarios**. For *Market of Ash*, create a famine route, embargo route, and crew-conflict route. For *The Cartographer’s Siege*, create a cheap-road failure, bridge chokepoint, and expensive-safe-route scenario. For *Pack the Keep*, create a commander-vs-invasion matrix where every commander faces several enemy doctrines.

Do not over-automate artistic judgment. A screenshot test can confirm that a building exists, but a visual reviewer should still judge whether the fort reads clearly, whether the road danger is obvious, and whether the pack choice is attractive without being confusing.

## Engine and model by game

### Market of Ash

Use **Godot 4.x with GDScript and data-driven resources**. The most important engineering choice is to keep the economy, route events, crew traits, and faction relations deterministic and independent from UI scenes. Use JSON or Godot `Resource` files for goods, towns, factions, and event definitions. A separate simulation layer should be able to run a journey without rendering the map.

The model workflow should use Sonnet or GPT-5 for event authoring tools, economy code, and UI. Use Opus or GPT-5.5 for reviewing whether the economy creates meaningful decisions rather than obvious arbitrage. Use a visual model to review whether prices, causes, rumors, and route risks are readable on one screen.

### The Cartographer’s Siege

Use **Godot 4.x with a grid or graph-based simulation**, not freeform physics as the foundation. Store the map as explicit cells or nodes with terrain, elevation, ownership, road material, path cost, supply value, and danger metadata. Render the map separately from the rules so agents can test road changes without needing a full visual scene.

The model’s first high-risk task is not art. It is finding a satisfying road-cost and defense-cost relationship. Give the agent seeded maps and ask it to report whether cheap routes are consistently too strong, too weak, or strategically interesting. A visual model should judge whether the player can understand the route preview, danger overlay, and enemy approach before committing.

### Pack the Keep

Use **Godot 4.x with a bounded top-down grid, deterministic wave simulator, and explicit commander/pack data**. A pack should be an ordinary data object with clear tags, effects, prerequisites, and a short explanation. Do not bury pack rules in custom code for each card.

The coding agent can generate pack definitions, unit behaviors, and scenario fixtures efficiently. The architecture model should review the combat and progression boundaries. The visual model should review whether units are identifiable at the chosen zoom level and whether pack reveals communicate value without resembling a gambling interface.

## Art pipeline for agent-first development

For the proposed 2D-ish direction, use a strict three-stage asset pipeline:

1. **Reference:** define the visual target with a small art-direction document and a reference board.
2. **Generation or creation:** produce concept assets, textures, portraits, icons, and effects in controlled batches.
3. **Approval:** move only accepted assets into the approved directory and record their intended use, dimensions, palette, and license status.

The agent should not freely replace approved art while fixing code. Asset changes need their own review because a technically correct replacement can damage visual identity or introduce inconsistent scale, lighting, or silhouette language.

Use procedural drawing for repeated geometry such as roads, grid cells, walls, tiles, and basic terrain. Use authored or generated art for the elements players emotionally read: commanders, crew, enemy leaders, market landmarks, banners, pack icons, and major buildings. This is a good balance between production efficiency and commercial identity.

## Final recommendation

Start with **Godot 4.x and GDScript**, build a deterministic test harness before a large content pipeline, and use GitHub as the source of truth. Keep the everyday coding agent on **Claude Sonnet 4.6 or GPT-5**, escalate architecture and hard bugs to **Claude Opus 4.7 or GPT-5.5**, use **GPT-5 mini** for routine structured work, and use **Gemini 3.1 Pro Preview** as the visual QA reviewer.

For the first prototype, I would choose **The Cartographer’s Siege**. Its road-preview, map-cost, and defense loop can be tested in a small Godot project without needing a large narrative or content library. Once that workflow is stable, the same agent-first discipline can be applied to *Pack the Keep* and then the more systemically demanding *Market of Ash*.

The core principle is simple: **the agent should not be asked to be creative in an undocumented vacuum.** Give it a clear design contract, a narrow change, deterministic fixtures, automated checks, and visual evidence. That is what makes agent-first development reliable rather than merely fast.

## References

[1]: <https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html> “Command line tutorial — Godot Engine documentation.”

[2]: <https://docs.unity3d.com/6000.2/Documentation/Manual/EditorCommandLineArguments.html> “Unity Editor command line arguments — Unity 6.2 documentation.”


## Storefront clarification: Steam and Epic Games Store

The target should be treated as a Windows desktop release with two storefront integrations, not a browser release. Steam Cloud can be configured through Steamworks Auto-Cloud or integrated through the Steam Cloud API; Steam recommends keeping save files small and avoiding machine-specific settings in cloud-synced data.[3] Epic Online Services is engine-agnostic and provides platform services including authentication, multiplayer, player and game data, achievements, stats, and cross-platform data synchronization.[4]

This means platform services should be wrapped behind a small internal interface rather than called throughout gameplay code. The game can expose `PlatformService.unlock_achievement()`, `PlatformService.write_cloud_save()`, and `PlatformService.get_user_id()` while separate Steam and EOS adapters implement those operations. This lets the same gameplay build run offline and reduces storefront-specific logic in the simulation.

For the initial release, prioritize Steam integration first because it is the simplest place to validate the product and its community. Add Epic support through an adapter and test it from the beginning, but do not make the core game dependent on EOS login or an always-online service. Offline single-player play should remain available wherever the storefront rules permit it.

[3]: <https://partner.steamgames.com/doc/features/cloud> “Steam Cloud — Steamworks Documentation.”

[4]: <https://dev.epicgames.com/docs/epic-online-services/eos-overview> “Epic Online Services Overview — Epic Developer Resources.”


### Current Steam integration caveat

The original GodotSteam GitHub repository is archived and points to a current Codeberg repository. The Codeberg project lists Godot 4.x support and GodotSteam 4.22, with active commits and releases visible at retrieval.[5] Use the current maintained repository rather than copying the archived GitHub repository into a new project.

[5]: <https://codeberg.org/godotsteam/godotsteam> “godotsteam/godotsteam — Codeberg.”
