# Market of Ash — Early Access Requirements

**Status:** Active execution contract; MA-EA-1 through MA-EA-5 complete, MA-EA-6 next
**Current baseline:** Deterministic Five-Well Basin, Glasswind Reach, and Siltfire March form a connected three-region trade map with ordinary trade, authored events, adaptive faction responses, alternate endings, and the game-quality roadmap in progress.

## Product decision

Market of Ash must not enter Early Access as only one polished scenario surrounded by menus. It should enter as a **small but complete trade-and-travel sandbox**: one high-quality opening region plus several thinner, fully playable regions that use the same simulation and presentation rules. Players must be able to trade conventionally, accept optional work, pursue faction relationships, or simply explore profitable routes without following a prescribed story order.

The additional regions may be visually skeletal at first, but they cannot be mechanically fake. Every region must have a functioning economic loop, at least one meaningful risk, a recovery option, a route decision, an authored local identity, save-safe progression, and a complete result/debrief handoff.

## Early Access breadth floor

| System | Early Access floor | Quality expectation |
|---|---:|---|
| Playable regions | 3, including the Five-Well Basin | Basin is the presentation anchor; two neighboring regions may be visually lighter but must be complete loops. |
| Settlements | 9–10 total | Every settlement has a reason to visit, at least two useful actions, a market profile, and a route relationship. |
| Goods | 10–12 | At least four goods support more than one profitable ordinary-trade pattern; scarcity must not make contracts mandatory. |
| Routes | 7–9 | Each route has distance/time, cost or risk, a readable identity, and at least one alternate approach or consequence. |
| Crew | 5–6 | Each crew member changes a decision or trade-off, not only a passive percentage. |
| Event families | 8–10 | Events are deterministic, state-aware, and tied to settlements, routes, factions, or cargo. |
| Major factions | 4 | Each faction changes access, prices, safety, information, or endings. |
| Replacement actors | 2 | Ignored or failed scenarios create new opportunities and pressures rather than a reset. |
| Endings | 6–8 composable outcomes | No single contract chain is required; endings derive from world dimensions and player choices. |
| Playable session | 30–60 minutes | A player can complete a meaningful run, trade freely, and understand the result without debug fixtures. |

These numbers are a floor, not a promise that every asset is bespoke. A smaller set with strong relationships is preferable to a larger list of decorative goods or settlements.

## Required player paths

An Early Access build must support at least four viable approaches:

1. **Ordinary merchant:** buy and sell across multiple settlements without accepting a named contract.
2. **Contract broker:** accept optional delivery or relief work for a modest premium and non-cash consequences.
3. **Faction operator:** build or oppose a faction relationship through trade, information, or political choices.
4. **Adaptive survivor:** ignore or fail an opening scenario and continue through the replacement market or altered route network.

The ordinary merchant path must be profitable often enough to be enjoyable, but not risk-free. Contracts may change the risk/reward profile; they must not be the only source of meaningful progress.

## Region contract

Each new region is accepted only when it has:

- A source/consumer economy with at least three goods and two ordinary-trade patterns.
- One distinctive route hazard and one recovery or mitigation option.
- Two settlements with visibly different reasons to visit.
- One event chain with at least two deterministic branches.
- One local faction pressure and one failure-forward response.
- A complete save/resume and debrief path.
- A screenshot set at 1280×720 and 1600×900 proving that the region is readable without debug panels.

The two follow-on regions may reuse the shared temporary asset kit and existing UI components. Their visual identity should be conveyed through palette, signage, route names, silhouettes, settlement framing, and audio cues before more expensive bespoke art is commissioned.

## Quality gates before Early Access

The current Five-Well Basin must first pass the game-quality gates already identified in the execution plan, especially responsive shell repair and a complete no-debug journey. The Early Access candidate must additionally pass:

- A fresh-save ordinary-trade run, a contract run, a faction run, and a failed-scenario run.
- Deterministic replay for each route and event branch.
- Save/load at settlement, departure, road event, arrival, and debrief boundaries.
- 1280×720, 1600×900, large-text, reduced-motion, keyboard, and controller coverage.
- No negative money, provisions, capacity, or impossible settlement state after any supported command.
- No soft-lock when a contract is declined, a route becomes unavailable, or a faction replaces an expired scenario.
- A clean exported Windows artifact with version, provenance, checksums, and rollback instructions.
- A known-limitations document that labels skeletal region art honestly.

Human playtesting can be added later for calibration. It is not a prerequisite for agents to implement or verify this contract.

## Content production rule

New content must be data-driven and use stable IDs. An agent may add one region, settlement, route, event family, faction, or crew member per slice. The slice must include runtime data, presentation copy, tests, save coverage, visual evidence, and documentation. Agents must not add a large generic catalog while the existing Bazaar, Introduction, or route shell is clipped or unclear.

## Recommended order

**MA-EA-1 — complete:** repair the 1280×720 shell and complete the polished Basin journey. The acceptance gate now exercises the real player-facing trade path, rejects visible developer surfaces in every native frame, and covers the full responsive matrix plus deterministic journey, input, save, and campaign suites.
**MA-EA-2 — complete:** Glasswind Reach adds Sunfall Exchange, Kiln Rest, and Mirror Wells; saltglass, dune spice, and lamp oil; the Glasswind Trace and Mirror Run; the Shardwind Tithe event; an optional beacon-oil contract; and the failure-forward Night Market. Its save-safe flow and four-resolution native evidence are enforced by `scripts/verify_ma_ea_2.sh`.
**MA-EA-3 — complete:** Siltfire March adds Mothlight Quay and Blackreed Post; profitable ordinary medicine/cloth and grain/charcoal patterns; the Salt Causeway and Reedline Track; persistent bell-chart and reed-skid preparations; and the three-branch `Bells in the Whiteout` recovery event. The seven-road graph reaches all ten settlements through player-legal segments, and native evidence covers both March bazaars, roads, services, event, and arrival handoffs.
**MA-EA-4 — complete:** Causeway Bellkeepers become the fourth standing faction and alter Salt Causeway fees through visible trust. The existing second replacement actor, the Night Market, now supports cooperation, opposition, reconciliation, and a sixth ending earned through post-activation ordinary saltglass trade. Both replacement endings use one generic authored requirement evaluator.
**MA-EA-5 — complete:** Mara Voss and Orin Bell bring the roster to five crew, while the Reedline wheel sink and divided Mirror Run beacons bring the event catalog to eight families. Each recruit unlocks a resource-backed deterministic response with a persistent route consequence, and every event retains non-crew recovery choices.

**MA-EA-6:** harden packaging, migration, accessibility, performance, and versioned documentation.

## Non-negotiable boundaries

The economy remains authoritative in `src/core/`; UI and effects remain presentation-only. Randomness uses named deterministic streams. Contracts are optional. Price and demand information must be honest enough to support planning but not remove uncertainty. Temporary asset packs may fill background, VFX, and audio roles, but they must be marked as placeholders and must not be presented as the final frontier identity.
