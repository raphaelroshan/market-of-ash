# Market of Ash — AI Game-Quality Execution Plan

**Applies to:** `v0.13.9-alpha-basin-vertical-slice` and later

**Purpose:** Move the game from a technically sound deterministic prototype toward a presentable private-alpha slice. The deterministic Five-Well Basin vertical-slice milestone is complete, but the game-quality presentation milestone remains open. Automated tests, scripted launches, screenshot inspection, and deterministic replay evidence are the active development gates. Human playtesting is valuable later, but it is not a prerequisite for the following work.

> **Current audit:** `0.13.9-alpha-basin-vertical-slice` passes the automated vertical-slice scope. The opening shell, trade receipts, licensed command/travel audio, departure dust, and complete deterministic journey are integrated. Guide / Intel now has a restrained licensed page-opening cue that respects Interface Sounds and carries no unique information. Current native evidence verifies the complete scripted journey and all required opening controls at 960×540, 1280×720, 1600×900, and 1920×1080. The broader game-quality roadmap remains open for commercial art polish, physical-device and assistive-technology coverage, antivirus/storefront hardening, and moderated player evidence.

## Operating contract

The core simulation remains authoritative, deterministic, and data-driven. UI work may expose, stage, or explain existing state, but it must not change prices, demand, route costs, event outcomes, settlement state, or replay keys. Every task must include a focused implementation, deterministic regression coverage, normal and large-text screenshots, and a concise report of what changed.

The game must preserve two equally legitimate ways to play: ordinary buying and selling, and optional authored opportunities. Contracts, faction requests, and emergencies may create unusual risk or access, but they must not make anonymous trade a filler activity or the only profitable path.

## Execution order

| Step | Objective | Required outcome |
|---|---|---|
| **M1** | Repair the responsive shell | At 1280×720, 1600×900, and the minimum supported width, no required heading, explanation, price, cargo value, or primary action is clipped. Narrow layouts deliberately reflow rather than merely shrink. |
| **M2** | Establish the Bazaar decision hierarchy | The first Bazaar view clearly answers local need, selected cargo, destination value, route risk, available cash/capacity, and next action. Ordinary trade can be completed without accepting a contract. |
| **M3** | Extract UI presentation panels | Move Bazaar, Departure, event, and arrival/debrief presentation into focused components or presenter functions. Keep commands and simulation state in the existing authoritative boundary. |
| **M4** | Make route comparison actionable | Show fee, days, provisions, cargo opportunity, risk, forecast confidence, and expected consequence side by side. Never auto-select a route or hide an unfavorable option. |
| **M5** | Build the complete journey beat | Present Introduction → Bazaar → Departure → road → event/contact → arrival receipt → return Bazaar. Transitions are short, skippable, save-safe, and reduced-motion compatible. |
| **M6** | Give locations distinct identity | Add data-driven visual and textual treatment for Ashgate, Reedwatch, and the next existing locations. Identity must change how a player reads the opportunity, not only recolor a panel. |
| **M7** | Add adaptive opportunity substitution | When a scenario is ignored, delayed, or failed, preserve the underlying need and let another faction, settlement, or trader respond. This creates a new trade opportunity or risk rather than a dead end. |
| **M8** | Add one complete authored event slice | Implement one event from data through command, deterministic outcome, save/load, destination acknowledgment, and debrief. The event must coexist with ordinary trading. |
| **M9** | Compose outcomes and replay | Debrief route, cargo, event, profit/loss, political pressure, and consequence. Offer a replay experiment without requiring one canonical ending. |
| **M10** | Package the private alpha | Run all verification suites, capture a complete 1600×900 journey, check 1280×720 and large text, verify clean install and save migration, and publish an internal artifact with known limitations. Human sessions remain optional follow-up evidence. |

**Progress:** M1–M10 are implemented for the automated vertical-slice scope. The `v0.13.9-alpha-basin-vertical-slice` patch extends the restrained sound vocabulary to Guide / Intel while retaining the stamped trade receipt, departure dust, curated release payload, responsive opening, complete journey evidence, save migration/recovery checks, browser verification, and honest limitations record. Physical-controller, assistive-technology, high-DPI hardware, antivirus-reputation, and moderated human-playtest evidence remain external follow-up gates.

## Acceptance tests for every AI task

The agent must prove that the same seed and command sequence produce the same simulation result regardless of viewport, text scale, reduced motion, controller path, or screenshot capture. At least one test must enter the affected screen through the normal player flow. Layout tests must assert visible bounds rather than only checking that nodes exist.

A task is incomplete if it adds a new mechanic while a required action is clipped, if it makes a contract mandatory for economic progress, if it moves authoritative calculations into the UI, or if it uses a screenshot from an unrecorded build. Every curated image must include the exact version, display size, capture state, and whether it is a local recapture or packaged artifact.

## Recommended first prompt

> Read `docs/game_quality_vertical_slice_roadmap.md`, `docs/design/nonlinear_trade_and_adaptive_basin_addendum.md`, this document, and `docs/latest_test_report_2026-08-30.md`. Implement **M1 Responsive Shell Repair** only. Preserve the deterministic economy and all existing commands. Fix the 1280×720 composition using an explicit responsive layout contract, add bounds assertions for Introduction, Bazaar, Departure, event, and arrival panels, capture 1280×720 and 1600×900 evidence, run the full verification suite, and report any remaining clipping. Do not add goods, factions, contracts, or currencies in this task.

## Definition of game-quality readiness

Market of Ash is ready for a private alpha when the complete journey can be played without debug actions, ordinary trade is rewarding and understandable, each required screen is readable at supported sizes, events produce visible causal consequences, the player can recover from a poor route, and at least two different profitable plans can reach a successful debrief. Human testing can then improve confidence, but it must not be used to postpone the deterministic and presentation work above.

## Historical evidence

The current Bazaar hierarchy finding and correction are recorded in [`latest_visual_review_2026-08-31.md`](latest_visual_review_2026-08-31.md), while [`latest_test_report_2026-08-31.md`](latest_test_report_2026-08-31.md) preserves the preceding Departure accessibility patch. [`latest_visual_review_2026-08-30.md`](latest_visual_review_2026-08-30.md) preserves the earlier Xvfb opening-shell finding that M1 subsequently repaired, and [`latest_test_report_2026-08-30.md`](latest_test_report_2026-08-30.md) records the completed 0.13.0 journey audit. Screenshots remain in the versioned `docs/visual_evidence/` directories. The primary quality contract is [`game_quality_vertical_slice_roadmap.md`](game_quality_vertical_slice_roadmap.md).

## References

[1]: game_quality_vertical_slice_roadmap.md "Market of Ash Game-Quality Vertical-Slice Roadmap"
[2]: design/nonlinear_trade_and_adaptive_basin_addendum.md "Market of Ash Open Trade and Adaptive Basin Addendum"
[3]: latest_test_report_2026-08-31.md "Market of Ash Departure Clarity Patch Test Report"

The source documents are internal repository contracts and are intentionally versioned with the game.


## Latest verification update — 2026-08-31

The previous `0.13.4-alpha-basin-vertical-slice` verification identified horizontal safety-margin failures in the split Main Menu and Introduction composition at 1280×720. `0.13.5-alpha-basin-vertical-slice` resolves that finding with an explicit constrained-width composition and expanded bounds evidence. The deterministic vertical-slice milestone remains complete, while the broader game-quality presentation roadmap remains open.

**M1 verification result:** Main Menu and Introduction stack at 960×540 and 1280×720, retain the split scene at 1600×900 and 1920×1080, and keep all named opening copy and actions within their cards in normal and Large Text modes. The complete native journey matrix passes at all four sizes. Human testing remains optional and non-blocking.
