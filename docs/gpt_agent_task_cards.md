# Market of Ash — Copy-Paste GPT Agent Task Cards

This file is used with [`gpt_agent_handoff_roadmap.md`](gpt_agent_handoff_roadmap.md). Give the persistent charter from that roadmap to the implementation agent once per new session. Then send **only one task card** at a time. Do not send the next card until its acceptance criteria and review gate pass.

> **Instruction to product lead:** The wording below is intentionally specific. Replace bracketed fields only when the preceding task has passed. Do not append adjacent cards to “save time”; a smaller feedback loop is the quality control system.

## Shared delivery envelope

Append this envelope to every card.

```text
Before editing, read design/design_prompt.md, AGENTS.md, docs/decision_log.md, docs/gpt_agent_handoff_roadmap.md, and the smallest relevant source/test files.

Preserve the current Main Menu → Settlement Shop → Departure Desk / Map → Travel / Event → Arrival Report → Settlement Shop UX. UI reads state and emits commands; it must not own authoritative rules.

Make no unrelated refactors. Do not add new packages, a generic scripting engine, a second region, multiplayer, factories, crafting, live markets, real-time combat, permadeath, microtransactions, or weapons-first progression.

At completion, report exactly: Intent; Plan; Changed files; Verification with exact commands and output; Risks; and one next small task. Do not claim a visual/manual test passed unless you ran it.
```

## Card 0 — Baseline audit before new work

```text
Task: Establish an implementation baseline for the next alpha slice. Do not add gameplay.

Player behavior: None changes. A developer can trust which current contracts are active.

Inspect: current branch and PR, content/runtime_world.json, src/core/economy.gd, src/core/market_command_processor.gd, src/core/world_state.gd, src/ui/main.gd, tests/test_economy.gd, tests/test_map_ui.gd, tools/simulate_trade_policies.gd, and docs/gpt_agent_handoff_roadmap.md.

Deliver:
1. A short baseline note at docs/implementation_status.md with current implemented slices, known intentional gaps, and exact test commands.
2. A list of all command IDs, save-version fields, content validators, test scripts, and UI transitions currently present.
3. A concise mismatch list between the roadmap and current code. Do not silently fix mismatches.

Acceptance criteria:
1. No gameplay/core/content state files change.
2. Run the current economy and map UI suites and report actual output.
3. Run all current content validators and headless project import.
4. Identify the forecast/resolution calibration model and cite the exact functions/fields that differ.

Next task: Card B0a only.
```

## Card B0a — Decide and specify forecast/resolution calibration

```text
Task: Design, but do not yet balance, the route-risk forecast calibration correction.

Player behavior: A future departure forecast will describe the same loss model that travel resolution applies.

Scope: Inspect the current route_profit_preview calculation, departure incident resolution, runtime planning assumptions, and policy-simulation report. Write a decision document at docs/economy/forecast_resolution_contract.md. Do not modify balance values, route risk values, or player-facing UI yet.

The document must compare exactly two viable choices:
A. Preserve one-unit cargo incidents and calculate expected loss from risk × the disclosed lost unit’s value.
B. Preserve value-based expected loss and change resolver incidents to remove an equivalent fraction/value of cargo.

For each choice, define data inputs, player-facing wording, determinism, edge cases for mixed cargo/zero cargo, save/replay impact, and tests. Recommend the smaller choice that keeps risk legible and recoverable.

Acceptance criteria:
1. The contract names a single proposed formula and the source of each variable.
2. It states how forecast and result will use the same model.
3. It includes test cases and a simulation before/after metric.
4. It includes an ADR describing the decision and trade-off.
5. No current game behavior changes.
```

## Card B0b — Implement forecast/resolution calibration

```text
Task: Implement the approved forecast/resolution contract from docs/economy/forecast_resolution_contract.md.

Player behavior: Before departure, the route forecast gives an expected-loss explanation that matches the incident rule used after committing travel.

Scope: Modify only the smallest relevant content assumptions, core economy/resolution code, UI explanation text, tests, simulation harness/report, and ADR. Preserve route fee, route endpoint validation, price behavior, and Shop → Departure Desk UX.

Data contract: Every route forecast must expose a stable loss-model label, risk source, expected loss amount, and relevant cargo/value basis. Do not make UI code infer the formula.

Acceptance criteria:
1. For a single-good cargo, the expected-loss helper and incident result share one documented value basis.
2. Zero cargo, low quantity, capacity-limit, and high-value cargo cases remain valid and legible.
3. A success/failure departure uses the same command boundary and serialization behavior as before.
4. Add unit tests for the formula and UI smoke assertions for the new explanation.
5. Rerun the deterministic 100-seed policy simulation and report mean absolute forecast error before/after.
6. Do not tune prices/routes in the same PR.
```

## Card B1a — Market-memory data contract

```text
Task: Define a bounded market-memory schema and validation seam. Do not change prices in gameplay yet.

Player behavior: None changes in this task. Future deliveries will leave a visible, temporary market memory.

Create/extend content records and a decision document at docs/economy/market_memory_contract.md. Define stable settlement/good keys, pressure bounds, sale impact, daily decay, crisis interaction, visible memory text inputs, and maximum history retained. Add validator rules and invalid fixtures.

Acceptance criteria:
1. Pressure is finite, deterministic, clamped, and serializable.
2. The schema does not embed code or UI strings that calculate rules.
3. The contract answers how a repeated delivery softens a premium, how recovery works, and why a town is never permanently solved.
4. Tests cover valid schema and every new rejected condition.
5. No price calculation or UI behavior changes yet.
```

## Card B1b — Bounded market memory implementation

```text
Task: Apply the approved bounded market-memory model to completed sales and time advance.

Player behavior: A player who sells a material delivery sees the relevant local premium soften, sees why, and can understand how it recovers.

Scope: Add only market pressure/memory state, price composition, sell/day-advance effects, save/replay data, market explanation text, tests, fixtures, and simulation updates. Do not add contracts, crew, events, or new goods.

Command contract: Sell must record a bounded settlement/good pressure effect through the existing command boundary. Day advance must apply documented deterministic decay. Failed sales do not write pressure.

Acceptance criteria:
1. Repeated legal sales are bounded and stop producing a permanent dominant circuit.
2. Decay, crisis modifier, and pressure compose in one named, testable ordering.
3. Shop market text names the last relevant delivery effect and recovery condition.
4. Save/load and equivalent replay preserve pressure and price results.
5. Policy simulation reports current multi-trip loop concentration and recovery time.
6. Existing fresh-start price snapshots remain stable unless the player has changed market state.
```

## Card B2 — Settlement opportunities and visit budget

```text
Task: Add a small, data-driven settlement opportunity shell with a two-slot visit budget. Trade remains free and primary.

Player behavior: At a settlement, the player can identify one local opportunity besides trading, understand its cost and consequence, choose up to two auxiliary actions, and still always buy/sell cargo.

Scope: Add visit-slot state, settlement action data/validation, the smallest command(s), a compact Local Opportunities shop card, and tests. Start with one live action at one settlement and visible disabled examples elsewhere; do not build all services.

Command contract: A successful auxiliary action decrements a slot exactly once. A blocked action changes no state and says whether money, relation, time, capacity, or slot is missing.

Acceptance criteria:
1. Arrival resets visit slots; normal purchase/sale does not consume a slot.
2. Action cost/effect is visible before confirmation.
3. Third auxiliary action is blocked with a recovery explanation.
4. Slot/action state serializes and migrates.
5. Keyboard/controller focus reaches every card and action in a predictable order.
6. No map/route planning controls return to the shop screen.
```

## Card B3 — First delivery contract

```text
Task: Implement one Reedwatch relief contract that materially changes a trade plan.

Player behavior: The player can accept a visible water/grain relief commitment, see its delivery requirement and deadline on the departure desk, complete it at arrival, or miss it with a recoverable consequence.

Scope: Implement one authored record, accepted-term snapshot state, accept/complete/fail command behavior, shop/departure/arrival UI, serialization, fixtures, and tests. Do not create a generic quest system or multiple contract archetypes.

Acceptance criteria:
1. Contract card states sponsor, destination, good/quantity, deadline, reward, and practical failure result.
2. Acceptance validates capacity/eligibility without altering cargo unless stated in content.
3. Departure screen pins target/deadline and shows the conflict with normal cargo space.
4. Completion and failure are idempotent, deterministic, logged, and saved.
5. A spot-trade alternative remains legal and visible.
6. Tests cover accept success, failed precondition, partial/late delivery, completion, duplicate completion, save/load, and UI presentation.
```

## Card B4a — Toll Dispute event foundation

```text
Task: Implement only the Toll Dispute as the first state-sensitive travel event.

Read first: docs/events/event_occurrence_catalogue.md, especially E01 — The Gatekeeper’s Chalk, the event-selection principles, and the event-test contract.

Player behavior: On a relevant journey, a player sees an understandable dispute tied to route/cargo/state, chooses pay or detour, and receives a causal outcome that affects the next market decision.

Scope: Add the narrowest pending-event state and resolve_event command necessary for this one event. Event data can declare stable IDs, display text keys, trigger/choice IDs, and numeric parameters; deterministic core code owns resolution. Do not add a generic script interpreter, all four events, combat, or broad narrative content.

Choices: Pay a stated toll; take a stated riskier detour; expose an optional crew/faction choice only when that feature already exists and its precondition is visible.

Acceptance criteria:
1. Trigger inputs and route context are visible before selection.
2. Every choice names immediate cost, uncertainty, and likely consequence.
3. Pending event blocks duplicate departure/resolution safely.
4. Low-money and low-provision blocks leave a recovery option.
5. Event and resolved roll serialize/replay exactly.
6. Tests cover trigger/no trigger, every choice, every block, repeat resolution, save/load mid-event, and deterministic replay.
```

## Card B4b — Remaining event templates

```text
Task: Add Broken Bridge, Desperate Settlement, and Suspicious Escort one at a time, starting with [EVENT_ID].

Player behavior: This route event makes a distinct preparation choice matter and changes the following trade/route/relationship decision.

For the selected event, read its entry in docs/events/event_occurrence_catalogue.md and create docs/events/[EVENT_ID]_truth_table.md with trigger, setup, prerequisites, choices, deltas, result text, follow-up state, recovery, and tests before implementation. Reuse the Toll Dispute seam; do not refactor the event architecture unless an ADR shows why the current seam cannot express this content.

Acceptance criteria:
1. At least two options are intelligible and distinct.
2. At least one option depends on real cargo/route/provisions/crew/faction state.
3. No uncontrolled early campaign-ending random result exists.
4. Full command, serialization, deterministic replay, UI, and content-validation coverage is added.
5. The arrival report names why the event changes the next decision.
```

## Card B5 — First crew member: Nara Vey

```text
Task: Implement Nara Vey, the scout, as the first crew proof.

Player behavior: A player can take a clearly characterized scout and receive better route information before departure, while still facing uncertainty and a meaningful cost or limitation.

Scope: Crew data and state, one recruit/assign action, a single Nara route-forecast hook, shop/departure presentation, save/load, tests, and a teaching scenario. Do not add all crew, morale, combat roles, or a skill tree.

Acceptance criteria:
1. Nara has a stable ID, short role/personality text, cost/limitation, and explicit hook.
2. Forecast visibly distinguishes unavailable, stale, and scout-informed information.
3. Nara never converts uncertainty into guaranteed safety.
4. Hiring/assignment and route forecast remain command-driven and serializable.
5. Tests cover unavailable/recruited/assigned state, cost block, information change, save/load, and no-route behavior.
```

## Card B6 — Faction proof: Ash Wardens

```text
Task: Implement the first practical Ash Warden relationship effect.

Player behavior: The player can see why Warden standing changes an official route/service/contract condition, gain or lose standing from named actions, and understand the trade-off in control or cost.

Scope: One bounded reputation track, one threshold, one official forecast/permit/contract effect, visible status, tests, and save/load. Do not introduce the entire faction matrix in one task.

Acceptance criteria:
1. Reputation mutations occur only through named command/event results.
2. The threshold changes one material commerce/travel condition.
3. The UI states current tier, next threshold, effect, and trade-off.
4. Below/at/above threshold and serialization are tested.
5. The effect does not become a universal best path.
```

## Card B7 — Arms-trade decision document first

```text
Task: Define the alpha arms-trade boundary before implementation. Do not add weapon goods or mechanics yet.

Player behavior: None changes in this task.

Write docs/politics/arms_trade_contract.md and an ADR. Specify the smallest goods/tags, escalation state, visible warnings, Cinder Rider/Salt Crown consequences, non-arms alternatives, recovery/counterplay, content validation, simulations, and success criteria. Show how the system changes commerce/travel rather than introducing combat.

Acceptance criteria:
1. The contract proves non-arms paths can progress at comparable viability.
2. Escalation is visible before delivery and can be countered through named actions.
3. No mandatory combat, army management, or hidden morality meter is introduced.
4. It contains synthetic-policy and human-playtest gate criteria.
5. No gameplay behavior changes.
```

## Card B8 — Crisis arc and one ending proof

```text
Task: Implement the first complete water-crisis progression proof and one reproducible regional ending.

Player behavior: The player sees a regional objective, notices the water crisis alter trade/travel, takes actions that influence it, and can reach one clearly explained ending state.

Scope: A three-stage deterministic crisis state machine, visible state changes in shop/map, one ending predicate/summary, fixtures, and campaign tests. Do not add every ending in this task.

Acceptance criteria:
1. Crisis stage transition depends on documented campaign state and is saved/replayable.
2. Each stage changes at least one price/demand signal, one route/event context, and one settlement/faction opportunity.
3. Ending predicate is pure core logic and is reproducible from a fixture.
4. A player can see what moved the regional objective.
5. Tests cover all stages, transition boundaries, save/load, ending predicate, and at least one recovery scenario.
```

## Card B9 — Alpha hardening audit

```text
Task: Audit the completed campaign for alpha external playtesting. Do not add broad content.

Player behavior: A tester can install/launch, use intended controls, read the main path, save/load safely, complete/recover in a campaign, and submit a useful issue report.

Deliver: a documented Windows build checklist, controller/keyboard/mouse manual test matrix, text-scaling/color/motion checklist, save-migration fixture matrix, crash/log/seed capture plan, and structured playtest feedback form. Implement only the lowest-risk missing test hooks or blockers identified by the audit.

Acceptance criteria:
1. Every main-path action has documented mouse, keyboard, and controller traversal.
2. Every save migration and corrupted-save scenario has a named expected outcome.
3. Every alpha candidate maps to a commit, content version, seed, and test record.
4. The feedback form measures comprehension, not only enjoyment.
5. The task lists unresolved blockers separately from beta/launch polish.
```

## PR review response template

Use this after each GPT-agent delivery.

```text
Review outcome: Approve / Revise / Block

1. Player behavior observed:
2. Architecture ownership verified:
3. Data/validation contract verified:
4. Determinism/save/replay evidence:
5. Positive and negative test evidence:
6. Manual/visual evidence and limitation:
7. Scope discipline check:
8. Product-spirit check: Does this create a better cargo/route/contract/relationship/risk decision?
9. Risks to carry forward:
10. Next permitted task:
```

## Escalation rules

Escalate to a stronger coding/reasoning agent or pause for human product review when a task changes the save schema, affects multiple command families, changes the core forecast/resolution model, introduces a campaign state machine, produces an unexpected simulation result, or requires a visual hierarchy judgment. Use lower-cost models only for schema linting, repetitive test expansion after a contract is approved, fixture preparation, and documentation cleanup. No model should be the sole judge of visual quality or player comprehension.
