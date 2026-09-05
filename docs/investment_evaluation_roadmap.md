# Market of Ash — Investment-Evaluation Roadmap

## Purpose

The next milestone is not another isolated feature or a documentation-complete vertical slice. It is a **full creative vertical** that lets an investor or prospective player understand the game immediately: buy low, sell where demand is real, choose a road, manage risk, survive a consequence, return to a changing market, and understand why the basin changed.

The intended reference shape is a modern, original Frontier-style caravan-trading game. It may use the familiar structure of a caravan, settlement markets, route risk, cargo capacity, provisions, crew, and black-market opportunities, but all writing, art, characters, maps, music, and specific content must remain original. The game should feel like a real product even if the second and third regions use compact or temporary art.

## Verified baseline

The current repository contains a substantial deterministic Five-Well Basin slice, a connected three-region network, ordinary trade, optional contracts, factions, replacement actors, multiple endings, five decision-changing specialists, events, persistence, and automated economy/game-quality checks. The current audit also found two investment blockers: the 1280×720 Introduction remains visibly clipped, and the full verification suite reports 25 deterministic world/save round trips above the five-second release budget at approximately 5,161.91 ms.

Therefore, the next agent must treat the vertical slice as **mechanically complete but not yet presentation- or performance-ready**. Do not add more factions or goods until the opening shell is clean, the first trade is legible, and the deterministic performance regression is either fixed or explicitly bounded and explained.

## Definition of the full creative vertical

A reviewer must be able to start a fresh run and complete the following without debug fixtures: title → introduction → first Bazaar purchase → destination comparison → road commitment → travel/event consequence → arrival sale or recovery → return to a changed Bazaar → optional contract or black-market choice → terminal regional outcome.

The vertical must include one authored caravan identity, five distinctive settlement presentations, three visually differentiated road types, seven goods with readable supply/demand stories, five specialists, at least four event families, four factions or faction-like actors, one black-market pressure chain, one replacement-faction response, six endings, and a final receipt that explains the player's economic and political story. Every choice must expose cash, capacity, provisions, time, risk, standing, or resilience before commitment.

The black-market layer should be an optional **parallel economy**, not the optimal route. It may offer scarce medicines, restricted tools, weapons, forged papers, or contraband routes with better margins but added inspection, faction, legitimacy, and seizure risks. Ordinary trade must remain profitable through at least four unrelated patterns, and a clean run must be completable without taking a black-market offer.

## Skeletal Early Access floor

Beyond the creative vertical, the investment build needs enough breadth to prove the game is not a one-route demo. The first Early Access candidate should contain three connected regions, nine to ten settlements, ten to twelve goods, seven to nine routes, five to six specialists, eight to ten event families, four major factions, two replacement actors, six to eight composable endings, and at least three viable non-contract trade patterns per region.

The later regions may reuse shared UI, map grammar, settlement construction kits, temporary audio, and placeholder travel backgrounds. They may not reuse the same economic question with renamed locations. Each region must add one new market relationship, one route risk, one settlement service trade-off, one event or black-market pressure, one recovery option, and one failure-forward consequence.

## Ordered implementation gates

| Gate | Player-facing deliverable | Required evidence |
|---|---|---|
| **MA-I1 — Shell and performance** | The full opening and first Bazaar are readable at 1280×720, 1600×900, minimum width, large text, and controller focus. Save/world round-trips return below the release budget. | Bounds tests, focused performance benchmark, fresh-save launch, screenshots, and exact timing output. |
| **MA-I2 — Trade fantasy** | The first five minutes visibly teach buying, demand, capacity, route cost, provisions, sale, and return-market change. | Normal-flow test, deterministic trade fixture, before/after market receipt, and a three-screenshot sequence. |
| **MA-I3 — Creative vertical** | One complete authored journey with characters, art motifs, audio cues, event consequence, black-market option, and ending receipt. | Clean-flow fixture, save/resume at every phase, controller/large-text checks, and a recorded 1600×900 capture. |
| **MA-I4 — Region two** | A second region with three settlements, three routes, three goods, one new risk, one optional contract, one event family, and one alternate ordinary-trade pattern. | Region manifest, deterministic seeded matrix, route/economy report, complete-flow capture, and failure-forward save test. |
| **MA-I5 — Region three and basin memory** | A connected third region with a distinct market identity, black-market or faction pressure, replacement actor, and changed return conditions. | Map continuity test, no-dead-end test, ending matrix, and post-consequence screenshot sequence. |
| **MA-I6 — Early Access hardening** | A repeatable 30–90 minute campaign loop with restart, save recovery, settings, controller, offline operation, clean package, known limitations, and a credible update boundary. | Full verification, 100 seeded economy trials, packaged launch smoke, migration/backup checks, and release manifest. |

## Content authoring rule

Every new settlement, good, route, specialist, event, or faction must answer four questions: what player question does it create; what resource or risk does it change; what is the ordinary-trade alternative; and what remains true if the player ignores it? Content that only adds prose, a larger number, or a renamed icon should be rejected.

## What not to build yet

Do not add multiplayer, procedural text generation, a large skill tree, dozens of goods, a universal reputation meter, a mandatory contract campaign, or a full black-market economy before MA-I1 through MA-I3 pass. Do not commission final key art before the first complete creative vertical is playable. Do not use the black market to force the player down the authored story.

## Agent task contract

Each agent task must name one player-facing behavior, preserve the authoritative simulation boundary, include data and UI ownership, add deterministic tests, verify save/resume, run the normal flow, and capture the affected screen at the current build version. The final report must list changed files, exact commands, timing or test output, screenshots, known limitations, and one next task.

The active sequence is **MA-I1 Shell/performance**, **MA-I2 Trade fantasy**, **MA-I3 Creative vertical**, **MA-I4 Region two**, **MA-I5 Region three and basin memory**, and **MA-I6 Early Access hardening**. MA-I1 through MA-I6 are complete for the automated scope, with evidence in their corresponding completion records and release notes. Physical-device, storefront, assistive-technology, and moderated player testing remain explicitly external gates.

## Decision

The investment target is a compact but honest game: one memorable trade fantasy, one complete creative journey, and enough adjacent systemic breadth to demonstrate continuation. We prefer three regions with strong decision density over ten empty regions, and a black-market option that enriches ordinary commerce over a black-market route that invalidates the core game.


## 2026-09-03 review checkpoint — status correction

The current `0.16.0-early-access-rc2` main build passes the automated deterministic and Early Access checks, including the 150.15 ms world/save budget result. This confirms the simulation and test contract; it does not mean the creative vertical or Early Access campaign is complete.

The current 1280×720 smoke evidence still shows the Introduction copy and Next action reaching the right viewport edge. Therefore **MA-I1 is not complete for game-quality scope**. The next agent must repair the actual `ResponsiveColumns`/minimum-size negotiation and add layout assertions for every required opening control. The agent must then prove MA-I2 in one clean save: first purchase, route comparison, departure, road consequence, arrival sale or recovery, changed return market, and terminal receipt. Contracts remain optional and ordinary trade remains a first-class path.

The dated evidence is in `docs/latest_review_2026-09-03.md` and `docs/visual_evidence/v0.16.0-early-access-rc2-review-2026-09-03/`. The prior statement that MA-I1 through MA-I6 were complete applies only to the automated scope; it is superseded for investment evaluation by this checkpoint.

## 2026-09-03 execution checkpoint — MA-I1 and MA-I2 restored

The review finding is resolved in `0.16.1-early-access-rc1`. The application now clamps its preferred 1600×900 window against both usable and physical screen bounds, including virtual displays; `ResponsiveColumns` falls back to stacking when child minimum widths cannot coexist; and Introduction prose wraps inside a bounded, horizontal-scroll-free reading area. Native validation requires a 24 px safe area around every opening card and containment for every required opening control.

Fresh normal-flow captures at 960×540, 1280×720, and 1600×900 prove the full clean-save MA-I2 path from Introduction through first purchase, route comparison, departure, road consequence, arrival sale, changed return Bazaar, optional black-market pressure, and terminal receipt. The canonical seed remains `1107`; every transition uses player command handlers, and ordinary trade remains sufficient. Evidence and exact acceptance output are recorded in `docs/ma_i1_i2_revalidation_2026-09-03.md`.


## 2026-09-04 repeat-test checkpoint — MA-I1A remains open

The current `0.16.1-early-access-rc1` main build passes the full automated suite and records 25 deterministic world/save round trips in 141.06 ms. The repeatable 1280×720 visual smoke run, however, still shows Introduction 2 of 3 with truncated explanatory copy and a Next action pressed against the right viewport edge. This is a player-facing evidence conflict with the earlier MA-I1/MA-I2 revalidation record, so the visual gate is reopened for investment evaluation.

The next agent task is **MA-GPT56-1A**: reconcile the capture-window contract with the actual responsive container/minimum-size negotiation, add a completion-aware navigation fixture, and prove the full ordinary-trade path in the same reproducible evidence system. The agent must not solve the issue by shortening copy again, hiding controls, globally shrinking text, or making black-market activity mandatory. Evidence is recorded in `docs/latest_review_2026-09-04.md` and `docs/visual_evidence/v0.16.1-early-access-rc1-review-2026-09-04/`.

## 2026-09-04 execution checkpoint — MA-GPT56-1A restored

The repeated-review conflict is resolved. Startup window fitting now handles an oversized window that the host reports as maximized and repeats its check while initial display metrics settle. The native capture contract rejects evidence unless requested pixel size and actual native-window size agree, retains the 1280×720 logical canvas explicitly, and waits for two stable frames of expected UI state before each critical capture.

Fresh Godot 4.4.1 runs pass at 960×540, 1280×720, and 1600×900. The curated 1280×720 sequence proves Introduction 2 with complete copy and safe gutters, then the Bazaar purchase, Departure, road stop, encounter, arrival, changed market, return trade, optional black-market pressure, and terminal regional receipt. See `docs/ma_gpt56_1a_completion.md` and `docs/visual_evidence/v0.16.1-ma-gpt56-1a-2026-09-04/`.


## 2026-09-05 audit checkpoint — MA-GPT56-1C remains open

The current `0.16.1-early-access-rc1` main build passes the full automated suite and remains inside the deterministic performance budget. The fresh 1280×720 audit still shows Introduction 1 with the Next action pressed against the right edge and Introduction 2 with explanatory copy truncated at the right boundary. The repeat audit therefore keeps the responsive visual gate open even though the automated completion records are green.

The next agent must execute **MA-GPT56-1C**: reconcile the capture-window contract with the actual `ResponsiveColumns` and minimum-size negotiation, add bounds assertions for required Introduction controls, and replace blind keypress capture with completion-aware navigation. Then prove the first Bazaar decision and complete ordinary-trade journey. Do not hide content, globally shrink text, or make black-market activity mandatory. Evidence is recorded in `docs/audit_report_2026-09-05.md` and `docs/visual_evidence/v0.16.1-early-access-rc1-audit-2026-09-05/`.

## 2026-09-05 execution checkpoint — MA-GPT56-1C restored

The repeated startup crop is resolved at its earliest boundary. Native builds now bootstrap at 1280×720 and promote to the preferred 1600×900 only when the display can contain it. The capture manifest records the composition actually selected after minimum-size negotiation, and all three Introduction pages enforce containment for every required explanation and action. Opening traversal activates semantic controls and waits for exact state rather than relying on blind key timing.

Fresh Godot 4.4.1 captures and render validation pass at 960×540, 1280×720, and 1600×900. The curated 1280×720 sequence proves all three Introduction pages, ordinary purchase, route comparison, road consequence, arrival sale, changed return market, and terminal receipt. See `docs/ma_gpt56_1c_completion.md` and `docs/visual_evidence/v0.16.1-ma-gpt56-1c-2026-09-05/`.
