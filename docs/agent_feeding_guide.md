# Agent Feeding Guide — Market of Ash

## How the environment works

The repository is designed around a separation between **product intent**, **implementation**, **simulation**, **presentation**, and **verification**. The product prompt explains what the game should feel like and what the vertical slice contains. `AGENTS.md` explains how an implementation agent must work. Core GDScript owns deterministic game state. UI scripts display state and emit actions. Headless tests protect the simulation. The decision log preserves important trade-offs so future agents do not silently undo them.

The agent should not receive the entire future roadmap as its immediate task. Give it the product prompt as persistent context, then feed it one narrow, verifiable slice at a time. A good task names the player behavior, affected files, constraints, acceptance criteria, and verification command.

## Model roles

Use a strong coding model for architecture, gameplay systems, debugging, and multi-file changes. The current built-in catalog supports models such as `claude-sonnet-4-6`, `claude-opus-4-7`, `gpt-5`, and `gpt-5.5`; verify the live catalog before selecting a model because availability and identifiers can change. In practice, use a balanced model such as Claude Sonnet or GPT-5 for the daily implementation loop, escalate difficult system design or debugging to Claude Opus or GPT-5.5, and use a cheaper model such as GPT-5 mini for repetitive documentation, test-case expansion, content linting, and structured data cleanup.

Do not use a model as the sole judge of visual quality. Have the coding agent launch the game and capture its own verification evidence, then conduct a separate human or visual review of screenshots and gameplay. A model can confirm that a node exists; it cannot reliably decide whether the market screen is pleasant, legible, or emotionally persuasive without seeing the result.

## Active game-quality feed order

Human testing is an optional confidence and calibration layer, not a prerequisite for implementation. Agents should proceed through the deterministic and visual quality sequence below using scripted launches, screenshot inspection, bounds assertions, and replay checks.

1. **Responsive shell repair:** fix Introduction, Bazaar, Departure, event, and arrival/debrief layout at 1280×720, 1600×900, minimum width, large text, and controller focus.
2. **Bazaar decision hierarchy:** make local need, selected cargo, destination value, route risk, cash, capacity, and next action explicit while preserving ordinary buying and selling as a complete path.
3. **Panel extraction:** separate presentation panels from `src/ui/main.gd` without moving simulation ownership or changing commands.
4. **Route comparison:** present fee, days, provisions, value, risk, and uncertainty side by side without auto-selecting a route.
5. **Complete journey beat:** prove Introduction → Bazaar → Departure → road → event/contact → arrival receipt → return Bazaar with save-safe, skippable, reduced-motion-compatible transitions.
6. **Settlement identity:** deepen existing locations through data-driven visual and operational differences before adding new settlements.
7. **Adaptive opportunity:** make ignored or failed scenarios produce replacement traders, factions, shortages, or routes rather than dead ends.
8. **One complete event slice:** take one existing event from data through command, save/load, consequence, debrief, and evidence.
9. **Private-alpha hardening:** run the full suite, capture a complete 1600×900 journey, verify clean install and persistence, and record known limitations.

For every feed, require changed files, acceptance checks, test output, screenshot paths, and a short player-facing explanation. Do not add new goods, factions, currencies, or endings while a required action is clipped or the ordinary trade loop is incomplete.

## The persistent context prompt

Give the main coding agent this context at the start of a project or fresh session:

```text
You are the lead implementation agent for Market of Ash. Read design/design_prompt.md, README.md, AGENTS.md, and docs/decision_log.md before editing. This is a Godot 4.x Windows desktop game for Steam and Epic Games Store. The first milestone is a deterministic 30–60 minute vertical slice: one region, five settlements, three route types, six goods, three crew roles, four events, two factions, a water crisis, and a clear ending. Keep simulation separate from UI. Use small reversible changes, data-driven content, deterministic seeds, headless tests, and explicit acceptance criteria. Never add unrequested scope. After every task, report intent, plan, changed files, verification, risks, and one next task.
```

## The first feed: stabilize the environment

Feed the agent:

```text
Inspect the repository without making speculative changes. Confirm the project entry scene, the current simulation classes, the test runner, and the exact commands needed to launch and test the project. If Godot is unavailable, say so explicitly. Produce a short implementation plan and identify the first failing or missing verification step. Do not add new gameplay yet.
```

The expected output is a repository inspection, not a feature. Require the agent to tell you whether it actually ran Godot. If it claims tests pass, ask for the exact command and output.

## The second feed: move content into data

Feed the agent:

```text
Refactor the existing vertical-slice settlement, route, and goods definitions into one data-driven source of truth under data/. Preserve behavior exactly. Do not add new content. Add validation that every settlement references valid goods and every route has a name, cost, duration, and risk. Update or add headless tests. Acceptance: the prototype behaves the same, duplicate definitions are removed, invalid data produces a clear test failure, and the test command is reported.
```

This establishes a safe boundary before the project grows. Do not allow the agent to introduce a framework or large dependency for a small data migration.

## The third feed: implement commands and results

Feed the agent:

```text
Introduce a small command/result layer for buy_goods, sell_goods, and depart_route. The UI must call commands rather than directly mutating world state. Each command validates preconditions and returns a structured result containing ok, reason, state_changes, and player_message. Preserve the current UI behavior. Add deterministic tests for success and every blocked case. Do not implement events, factions, or new screens in this task.
```

The important review question is whether the command layer makes the game easier to test and debug without becoming ceremony. Reject abstractions that do not improve that boundary.

## The fourth feed: add one event

Feed the agent:

```text
Implement only the Toll Dispute event. It must read the active route, current money, cargo, provisions, crew roles, and faction reputation. Offer two clearly explained choices: pay the toll or take a riskier detour. Resolve deterministically from the world seed and current day. Show the result in the UI, append a concise log entry, and serialize the changed state. Add tests for both outcomes and for a blocked choice. Do not add an event framework beyond what this event needs; document the extension seam for the next event.
```

Once this event works, add the other three events one at a time. The agent should not generate all narrative content in one batch because the first event is also a test of the data and UI model.

## The fifth feed: add crew without stat bloat

Feed the agent:

```text
Add the three vertical-slice crew members: Scout, Quartermaster, and Fixer. Each must have one visible route or event benefit, one limitation, and one short relationship hook. Crew must affect decisions, not only add percentage bonuses. Add hire/assign/remove commands, clear UI explanation, save/load coverage, and tests. Keep the first version deterministic and avoid morale, permadeath, or a large skill tree.
```

Review whether the agent has made crew interchangeable number modifiers. If so, send a correction task before adding more content.

## The sixth feed: visual and interaction polish

Feed the agent:

```text
Audit the current vertical slice as a new player using mouse, keyboard, and controller. Fix only high-impact comprehension and friction problems: unclear route cost, unclear cargo capacity, hidden contract requirements, poor focus order, unreadable text, missing confirmation, abrupt feedback, or confusing failure messages. Do not change economy balance in this pass unless the UI reveals a real rules problem. Provide before/after screenshots or a precise manual test report.
```

The purpose is to make the existing game easier to understand before expanding it. Do not accept “the UI works” as sufficient evidence.

## The seventh feed: simulation and balance review

Feed the agent:

```text
Build a deterministic simulation harness for 100 seeded playthroughs of the vertical slice. Report route profitability, bankruptcy frequency, crisis timing, average cargo utilization, event outcome distribution, and whether any route or good dominates. Do not change balance until the report exists. Then propose the smallest balance changes that preserve multiple viable strategies and avoid early death spirals. Add regression tests for the chosen bounds.
```

Use a stronger model for interpreting the simulation results, but use a cheaper model for generating structured test cases after the desired bounds are agreed.

## The eighth feed: release readiness

Feed the agent:

```text
Prepare a Windows Steam/Epic storefront smoke-test checklist for the current build. Verify launch, first-run setup, save/load, save migration, offline behavior, controller navigation, display scaling, input remapping, pause, autosave messaging, achievements behind a platform adapter, and cloud-save path safety. Do not integrate live credentials. Produce a checklist, identify missing adapters, and implement only the lowest-risk test hooks.
```

The first public demo should not be blocked by missing multiplayer or online infrastructure. Keep platform services optional at the simulation boundary.

## How to review every agent response

Ask five questions. What player behavior changed? Which files own the rule? What test would fail if the feature broke? What did the agent actually run? What remains intentionally incomplete? If any answer is unclear, do not feed the next feature. Ask the agent to clarify or add the missing test/documentation first.

The agent should end each task with exactly one next task. If it produces a broad backlog, narrow it. If it says a system is “polished” without a screenshot, playtest observation, or measurable check, treat that as unverified.

## Compact task template

```text
Task: [one player-facing behavior]
Context: Read design/design_prompt.md and AGENTS.md first.
Constraints: [systems that must not change; non-goals]
Acceptance criteria:
1. [observable behavior]
2. [edge case]
3. [save/load or accessibility requirement]
4. [test requirement]
Verification: [exact command plus manual launch/check]
Report: intent, plan, files changed, commands run and results, risks, one next task.
```

## When to use a separate critique agent

Use a second agent after a vertical slice is playable, not after every trivial edit. Give it the build, screenshots, test logs, design prompt, and a narrow evaluation rubric. Ask it to classify issues as blocker, high, medium, or low. It should not rewrite code directly during critique. This preserves a clean distinction between implementation and evaluation.


## Early Access breadth contract

Before adding broader content, read [`early_access_requirements.md`](early_access_requirements.md). The deterministic Five-Well Basin is the quality anchor, not the complete Early Access game. After M1–M6 presentation and flow gates, issue one complete region slice at a time: three settlements, three goods, two routes, one ordinary-trade pattern, one optional contract, one event chain, one faction pressure, one failure-forward response, save coverage, and visual evidence. Continue until the Early Access floor of three playable regions, nine to ten settlements, ten to twelve goods, seven to nine routes, five to six crew members, eight to ten event families, four factions, two replacement actors, and six to eight composable endings is met.

Do not make human testing a prerequisite. Use automated economy trials, deterministic replay, complete-flow launches, responsive layout checks, controller/scaling checks, save boundaries, screenshots, and known-limitations notes as the active gates. Ordinary buying and selling must remain a complete viable path, and no contract chain may be required for progress or an ending.

The recommended feeds are **MA-EA-1** responsive Basin completion, **MA-EA-2** second-region trade slice, **MA-EA-3** third-region map connection, **MA-EA-4** faction/replacement breadth, **MA-EA-5** crew/events/replay depth, and **MA-EA-6** release hardening.


## Investment-evaluation feed

Read [`investment_evaluation_roadmap.md`](investment_evaluation_roadmap.md) before continuing beyond the current vertical slice. The investment standard requires a complete Frontier-style trade fantasy, not only a scenario shell: first purchase, route comparison, travel consequence, arrival sale or recovery, changed return market, optional black-market pressure, and terminal economic/political receipt.

Issue the feeds in order: **MA-I1** repair the 1280×720 opening shell and deterministic save-round-trip performance budget; **MA-I2** make the first trade fantasy visible in one complete flow; **MA-I3** lock the creative vertical with authored characters, motifs, audio, black-market option, and ending receipt; **MA-I4** add a distinct second region; **MA-I5** connect a third region and basin memory; **MA-I6** harden the Early Access package. Do not add broad content while a required action is clipped or ordinary trade is not visibly viable. Human testing is optional and must not block implementation.
