# Market of Ash — Implementation Status

**Baseline branch:** `a0-command-result-boundary`  
**Baseline commit:** `5859d89` (`docs: add GPT agent alpha handoff roadmap`)  
**Roadmap status:** A0–A1 foundations and B0–B8 are implemented. B9 now has four distinct fresh-save strategy/ending proofs. B10 build operations and automated accessibility safeguards are configured; the documented hardware/rendered audit remains.

## Implemented player-facing spine

- Main Menu starts a deterministic Ashgate day-one playtest state.
- Settlement Shop owns local price inspection, buying, selling, cargo context, and the handoff to travel planning.
- Departure Desk owns the regional map, legal destination/route selection, route forecast, return-to-shop navigation, and travel commitment.
- Successful travel presents an arrival report before the player enters the destination shop.
- The regional map is a real planning surface rather than a placeholder grid: settlement markers select direct destinations, explain unreachable stops, label the current crisis stage/location and local resilience without relying on color, and visually highlight the caravan's position. Once travel is committed, map clicks and planning selectors lock until the route decision and arrival report are complete.
- The scroll-safe Main Menu keeps fresh-start and validated-continue actions above optional accessibility/input settings, and exposes reduced motion, large text, keyboard/controller button remapping, and default restoration.
- Desktop builds expose a conventional Main Menu Quit action; Web builds omit it and leave tab lifecycle to the browser.
- The Main Menu also exposes a persisted Interface Sounds switch. Short generated cues distinguish successful commands, blocked actions, and committed travel without carrying essential information or adding external audio assets.
- Runtime goods, settlements, route endpoints, and planning assumptions load from validated `content/runtime_world.json`.
- Prices and route forecasts are deterministic and explain their current inputs.
- The optional first-run Water delivery has a positive risk-adjusted forecast, and pre-purchase route forecasts include the proposed load in the same one-exposed-unit risk model used after purchase.
- Forecasts label selected quantities as trade scenarios, show the matching quantity actually held, and warn that departure carries only the real hold when a proposed load has not been purchased.
- First-run objective progress is reconstructed from saved command evidence, so loading after the guided purchase or completed sale cannot reset the prompt or repeat its one-use action; missing cargo produces a specific recovery prompt instead of silently returning to step one.
- The optional purchase helper exists only in the Ashgate Day 1 opening. Skipping it transitions the status to free play instead of carrying a tutorial-only action into later settlements.
- Completing the optional purchase transfers keyboard/controller focus from the now-disabled helper to Plan departure, matching the visible next-step instruction.
- Buy, sell, and departure mutations pass through a serializable command/result boundary; runtime and loaded histories both retain only the newest 100 command records.
- The human-readable campaign log retains the newest 200 entries both during play and after load, preventing long sessions or imported saves from inflating saves and diagnostic reports without bound.
- Every command result appends a state-aware `NEXT` instruction: revise a blocked plan, resolve a pending event, enter after arrival, or continue shop planning.
- Saves declare save version 11 and runtime content version `1.15.0`; successful commands autosave through a temporary file with one backup generation, manual save/load summaries are visible, older saves migrate safely, and oversized files, malformed structure, invalid bounds/references, impossible pending journeys, forged current-content contract/event terms, or future versions cannot replace the active run.
- A deterministic 100-seed policy simulation records opening-route incentives and forecast error.
- Route forecasts and incidents share a disclosed one-exposed-unit model owned by `MarketEconomy`.
- Successful sales create bounded per-settlement/per-good supply pressure, prices explain the effect, elapsed days decay it, and versioned saves preserve it.
- Settlement visits expose a two-slot auxiliary-action budget. Ashgate's provisions and escalation recovery, Brine Cross's cistern queue, Cinderford's repair bench, Hollow Market's route rumor, and Reedwatch's supply shelter create local tradeoffs with visible dependency reasons.
- Ashgate offers one fixed-term Reedwatch water-relief contract; accepted terms are pinned during departure and resolve deterministically on arrival.
- Eligible Toll Road journeys can pause at `The Gatekeeper's Chalk`, with visible pay, detour, and wait choices and a guaranteed recovery option.
- Repair-material loads on the Old Road can pause at `The Span at Cinderford`; public choices persist a visible lower-risk route condition while a turn-back option preserves the load.
- Shortage-stage water arrivals can pause at `The Last Clean Barrel`; the player can take a frozen premium, share supply, honor an active relief contract, or preserve the load for ordinary trade.
- High-value Old Road or Dry Cut loads can meet `Three Riders, No Banner`; money, medicine, disclosed one-unit risk, and a time-for-information recovery create distinct responses without combat.
- Disabled route-event responses render their prerequisite as persistent text below the control, so keyboard/controller players do not need hover access to understand unavailable choices.
- Dynamic contract, settlement, crew, and route-event actions use full-width wrapped controls; long cost/risk/consequence labels remain readable instead of being truncated in the narrow action rails.
- Nara Vey can be recruited and assigned through the visit budget; departure forecasts distinguish unavailable, stale, and same-day scout-informed route notes without changing the authored risk.
- Jorun Pale shares the same recruit/assign lifecycle; a current logistics plan reduces provision use by one, never below one, while leaving route time and risk intact.
- Tess Oryn shares the crew lifecycle and visibly unlocks a Gatekeeper ledger challenge with a one-day cost, a named information lead, and a disclosed Warden-standing penalty.
- Ash Warden standing is bounded and visible; recognized carriers at +2 pay three fewer ashmarks on the Toll Road while accepting greater official visibility.
- Free Caravan standing is bounded and visible; known road-sharers at +2 pay two fewer ashmarks on the Old Road while its cargo risk remains unchanged.
- One sealed arms crate and one named Cinder Rider broker offer create a visible 0–6 escalation track; the first threshold adds a disclosed Toll Road inspection surcharge only while arms cargo is carried.
- Ashgate's public manifest audit spends twelve ashmarks, one day, and one visit slot to reduce arms escalation by one and preserve a named information lead.
- Crisis stages now expose authored labels/objectives at days 1, 4, 7, and 10; one deterministic regional ending combines relief completion, Reedwatch resilience, and bounded arms pressure.

## Current command IDs

| Command ID | Owner | Current behavior |
| --- | --- | --- |
| `buy_goods` | `MarketCommandProcessor` | Validates good, quantity, capacity, settlement, and affordability; then mutates money/cargo. |
| `sell_goods` | `MarketCommandProcessor` | Validates good, quantity, held cargo, and settlement; then mutates money/cargo. |
| `depart_route` | `MarketCommandProcessor` | Validates destination and canonical route endpoints, charges fee/provisions, advances time, then either resolves one deterministic incident/arrival or freezes one relevant pending event. |
| `use_settlement_action` | `MarketCommandProcessor` | Validates current settlement, availability, money, and visit slots; the first implementation packs Ashgate route provisions. |
| `accept_contract` | `MarketCommandProcessor` | Freezes authored terms after validating origin, free cargo capacity, prior outcome, and visit-slot cost. |
| `resolve_contract` | `MarketCommandProcessor` | Completes an on-time delivery or applies a bounded late penalty while preserving recoverable spot cargo. |
| `resolve_event` | `MarketCommandProcessor` | Validates a pending event choice, applies explicit deterministic costs/outcomes and route follow-up, archives the result, and completes arrival or a disclosed return. |
| `recruit_crew` | `MarketCommandProcessor` | Validates Nara's location, fee, prior recruitment, and visit slot before adding her to the caravan. |
| `assign_crew` | `MarketCommandProcessor` | Validates recruitment, outgoing routes, and visit budget before writing same-day route reports. |

Successful and failed commands append to `command_history`, bounded to 100 records.

## Current serialized fields

- `save_version`
- `content_version`
- `seed`
- `day`
- `money`
- `provisions`
- `cargo_capacity`
- `cargo`
- `current_settlement`
- `reputation`
- `crisis_stage`
- `market_pressure`
- `market_delivery_history`
- `visit_slots_remaining`
- `active_contracts`
- `contract_history`
- `journey_context`
- `pending_event`
- `resolved_event_ids`
- `event_history`
- `route_conditions`
- `settlement_resilience`
- `known_information`
- `recruited_crew`
- `assigned_crew`
- `crew_reports`
- `arms_escalation`
- `arms_trade_history`
- `ending_id`
- `ending_summary`
- `log`
- `command_history`

Derived `crisis_modifiers`, runtime settlements, and runtime routes are rebuilt from authoritative content after load.

## Current content validators

- `tools/policy_check.py`
- `tools/validate_content.py --manifest content/content_manifest.json`
- `tools/validate_political_geography.py --data content/political_geography.json`
- `tools/validate_tribal_conflict.py --data content/tribal_conflict.json`
- `tools/validate_economy_and_settlements.py --economy content/economy_framework.json --settlements content/settlement_actions.json`
- `tools/validate_runtime_world.py --data content/runtime_world.json`

## Current test scripts

- `tests/test_economy.gd`: content loading, prices, crisis modifiers, capacity, route forecasts, command success/failure/history, route topology, travel resources, save normalization, and migration.
- `tests/test_map_ui.gd`: main-menu start, non-mutating forecast/navigation, guided purchase command use, Shop → Departure Desk transition, legal route filtering, forecast presentation, route geometry, and predictable keyboard/controller focus across screen and event transitions.
- `tests/test_campaign.gd`: command-only fresh campaign from relief acceptance through deterministic travel/events, public resilience, the day-ten ending, command history, and canonical save/load restoration.
- `tools/simulate_trade_policies.gd`: read-only 100-seed opening-policy simulation through the production command boundary.

## Current UI transitions

| From | Action | To | Authoritative mutation |
| --- | --- | --- | --- |
| Main Menu | Start Game | Settlement Shop | Creates deterministic fresh world state. |
| Settlement Shop | Buy / Sell | Settlement Shop | Yes, through command processor. |
| Settlement Shop | Plan Departure | Departure Desk | None. Planning selection is preserved. |
| Departure Desk | Return to Shop | Settlement Shop | None. |
| Departure Desk | Commit Departure | Route Event or Arrival Report on map layer | Yes, through `depart_route`. |
| Route Event | Choose response | Arrival/Return Report on map layer | Yes, through `resolve_event`. |
| Arrival Report | Enter Settlement | Destination Settlement Shop | None beyond the completed departure command. |

## Remaining roadmap-to-code mismatches

1. **Godot is not installed on the default shell `PATH`.** CI uses Godot 4.4.1 on Ubuntu and Windows. Current work was verified locally with a temporary Godot 4.4.1 binary, so future sessions must either reuse/provision that version or report the limitation explicitly.
2. **Local export templates are not installed.** Windows and Web presets now exist and CI installs matching Godot 4.4.1 templates, but this laptop's temporary editor can only verify preset parsing/project import until templates are installed.

## Baseline verification commands

```bash
bash scripts/verify.sh
godot --headless --path . --editor --quit
```

`scripts/verify.sh` runs repository policy, every content validator, validator fixtures, and all deterministic Godot suites. The separate editor import remains useful for import/cache validation.

The most recent GitHub run at this baseline passed repository policy, Ubuntu and Windows Godot tests, AI review, and source packaging. Local results must still be recorded for every subsequent slice.

## Baseline verification result

Verified locally with Godot `4.4.1.stable.official.49a5bc7b6`:

- Economy suite: `PASS: Market of Ash economy tests`
- Map UI suite: `Map UI smoke: PASS`
- Campaign suite: `Campaign smoke: PASS`
- Headless editor import: completed successfully; Godot emitted a non-fatal shutdown warning after its filesystem scan.
- Repository policy: pass, with expected warnings for local `.godot/` import metadata.
- Content manifest, political geography, tribal conflict, economy/settlement, and runtime-world validators: pass.
- `git diff --check`: pass.

## B0 calibration result

- Forecast and resolver now use the highest destination-value carried unit as the single exposed unit.
- The UI names that unit, destination value, expected loss, percentage risk, and authored risk source.
- Forecast-maximizer mean error improved from `+66.8` to `-0.2` ashmarks-equivalent across 100 seeds.
- Forecast-maximizer mean absolute error improved from `66.8` to `14.5`; the residual is binary incident variance rather than structural load-size error.
- With all four travel events active, the current synthetic policy's event choices reduce forecast-maximizer mean absolute error further to `7.0`; this is policy behavior, not a retuning of the forecast formula.
- After Cinderford became reachable, the Toll-road-only policy shifted from Medicine → Brine Cross to Grain → Cinderford and improved mean realized economic value from `+7.8` to `+20.6`; the primary forecast-maximizer remained Water → Reedwatch at `+99.7`.

## B1 market-memory result

- A four-unit Reedwatch water delivery creates 16% supply pressure and lowers the immediate unit price from 32 to 27 ashmarks.
- Pressure decays by 3% per elapsed day, returns to zero after six days for that delivery, and clamps at 35% under repeated supply.
- Crisis stages reduce the effect of new deliveries while keeping crisis and memory modifiers separately visible.
- The adaptive three-delivery simulation chooses Water → Reedwatch for the first two deliveries and rotates to Medicine → Reedwatch on the third.

## B2 settlement-opportunity result

- Each fresh start and settlement arrival provides two auxiliary-action slots; normal buying and selling consume none.
- Ashgate offers `Pack Warden rations`: six ashmarks for four provisions and one visit slot.
- Brine Cross's cistern queue becomes actionable at Thin Wells. Cinderford can reserve a Toll Road repair, Hollow Market sells one persistent Dry Cut report, and completed water relief unlocks Reedwatch's supply shelter during the crisis.
- Cinderford is a real Toll Road stop rather than a decorative waypoint: Ashgate and Brine Cross each connect to it through a six-ashmark segment, while the direct through passage remains available.
- A third auxiliary action is blocked without changing resources, and save version 3 preserves remaining slots.

## B3 first-contract result

- The Reedwatch Wellkeepers offer a four-water delivery due two days after acceptance for 150 ashmarks.
- Acceptance consumes one visit slot, freezes terms, and reserves no cargo; spot buying and selling remain available.
- The Departure Desk pins destination, deadline, reward, held quantity, and free hold space.
- Route incidents resolve before delivery. A complete load auto-delivers; a partial load remains active with the exact shortfall; late failure costs at most eight ashmarks and leaves cargo sellable.
- Save version 4 preserves active and resolved contract state.

## B4 first-event result

- Valuable or contract-relevant Toll Road journeys have a deterministic 65% chance to pause at `The Gatekeeper's Chalk` until the player chooses.
- Pay, detour, and wait choices state their money, provision, time, and cargo-risk costs before selection.
- The detour uses a saved roll and the same one-exposed-unit cargo basis as route forecasting; waiting is always available.
- Pending journeys and events survive save/load, resolved events do not repeat, and arrival then resumes contract checks and visit-slot refresh.
- The 100-seed simulation triggered the event in 65 Toll Road runs and resolved each through its declared command path.

## B5 first remaining-event result

- An Old Road caravan carrying at least two scrap/charcoal units has a deterministic 70% chance to meet `The Span at Cinderford`.
- The event freezes and displays a canonical scrap-then-charcoal material basis so cargo prerequisites remain exact across save/load and replay.
- Selling the material pays 30 ashmarks immediately; reserving it for the public span costs one day and lowers future Old Road risk from 35% to 25%; carrying measurements costs one provision/day and lowers risk to 30%.
- Turning back costs one day, preserves cargo, returns to the origin, and prevents a low-resource soft lock without falsely running destination contract resolution.
- Save version 6 preserves route conditions. The 100-seed material-reserve probe triggered exactly 70 times and applied the authored persistent route-risk change.

## B5 second remaining-event result

- A Reedwatch or Brine Cross arrival during crisis stage 1+ with two water has a deterministic 60% chance to meet `The Last Clean Barrel`.
- The event freezes two water, destination unit price, and a six-ashmark-per-unit premium across save/load and replay.
- Emergency sale pays the frozen premium and writes normal crisis-adjusted market memory; fair distribution writes the same supply memory plus two bounded settlement-resilience points.
- The commitment choice is available only for a matching active relief contract and then delegates to normal contract resolution. Keeping cargo sealed is always available.
- Save version 7 preserves settlement resilience. The 100-seed fair-share probe triggered exactly 60 times and applied the authored memory/resilience result.

## B5 final-event result

- Old Road and Dry Cut journeys carrying at least 70 destination-valued ashmarks have a deterministic 55% chance to meet `Three Riders, No Banner`.
- Paying ten ashmarks guarantees passage; crossing alone uses a saved 45% one-exposed-unit cargo roll; one medicine can buy safe passage; waiting one day is always available and records a sponsor-mark lead.
- The event reuses the calibrated loss basis, blocks unaffordable choices without mutation, and persists information without duplication through save version 8.
- In the 100-seed opening simulation, both high-value Old Road policies triggered the event 55 times and selected the explicit paid-escort response.

## B6 first-crew result

- Ashgate exposes Nara Vey as a 20-ashmark, one-slot recruit with an explicit scout role, personality, and same-day limitation.
- Assigning her costs one visit slot and writes reports only for authored routes leaving the current settlement; locations without routes block safely.
- Forecasts show `Scout unavailable`, `Scout report stale`, or `Nara-informed` and include a route-specific field note. The underlying risk remains unchanged and visible.
- Save version 9 preserves recruitment, assignment, report text, and report age.

## B6 second-crew result

- Ashgate exposes Jorun Pale as an 18-ashmark quartermaster recruit. Assignment competes for the same visit budget and active crew slot as Nara.
- His current report changes both the displayed and resolved provision cost through one helper; a two-provision Dry Cut becomes one provision, while one-provision routes remain at one.
- The same trip still advances its full authored days and uses its unchanged risk/event rules. Reports become stale after travel.

## B6 final-crew result

- Ashgate exposes Tess Oryn as a 22-ashmark fixer recruit competing for the same assignment and visit slots as Nara and Jorun.
- Gatekeeper's Chalk always displays Tess's ledger challenge; it is disabled with an exact prerequisite unless she is assigned.
- The enabled challenge costs one day, avoids extra cargo/resource loss, records `gatekeeper_invented_tolls`, and visibly changes Warden standing from 0 to -1.
- The choice resolves through the existing event command and save boundary; no persuasion roll or dialogue framework was added.

## B7 first-faction result

- `Pack Warden rations` and `Pay the posted toll` each grant one named Warden-standing point; Tess's ledger challenge removes one.
- Standing is clamped from -10 to +10. The shop shows the current value, tier, and +2 threshold.
- At +2 the Toll Road fee changes from 12 to 9 ashmarks in both forecast and travel resolution, with the named-manifest visibility tradeoff shown before departure.
- Other routes, prices, event chances, and contracts are unchanged, preventing a universal faction bonus.

## B7 counter-faction result

- Fair sharing during `The Last Clean Barrel` and waiting to identify the Three Riders' sponsor each grant one named Free Caravan standing point.
- At +2, `Known road-sharer` status lowers the Old Road fee from 4 to 2 ashmarks in forecast and resolution.
- The forecast explicitly states that the route's exposed cargo risk is unchanged; Warden standing does not receive this benefit.

## B8 first-arms result

- `sealed_arms_crate` is the only arms-tagged good and has flat ordinary-market pricing, preventing generic route arbitrage from becoming the feature.
- The Ashgate Cinder Rider broker pays 82 ashmarks for one crate, consumes one visit slot, raises escalation from 0 to 2, and lowers both implemented faction standings by one.
- At escalation 2, carrying another crate adds a visible five-ashmark Toll Road inspection surcharge; Warden permit discounts compose deterministically with it.
- The sale result names Reedwatch Water Relief as the viable non-arms alternative. Save version 10 preserves escalation and named arms history.
- Escalation is recoverable: the public manifest audit is blocked at zero, otherwise lowers pressure by one and records its cost and result without deleting the original sale history.
- The 100-seed viability probe gives the arms broker a median economic result of 37 with 100% transaction completion, while the risk-bearing non-arms relief path has median 71, mean 53, and 85% contract completion. Non-arms progress clears the contract's 80% median-resource gate and arms do not dominate campaign progress.

## B9 crisis and ending proof

- Crisis stages transition deterministically at days 4, 7, and 10 and expose a current label plus practical objective in the settlement header.
- The Shop's campaign outlook lists the exact contract, resilience, faction, arms, and money progress for every ending, then collapses to the immutable conclusion once one is reached.
- Thin Wells, Empty Reservoir, and Settlement Decision add named route pressure to the same Old Road/Toll Road records used by forecasts and resolution; saved repairs, faction discounts, and arms inspections compose deterministically.
- At Thin Wells, Brine Cross activates a one-time cistern queue action: spending one day and one visit slot records the pump-failure lead and adds one visible local resilience point.
- Hollow Market's one-time route rumor costs six ashmarks and one visit slot, records a water-cache lead, and lowers Dry Cut risk by five points. Reedwatch's one-time shelter requires completed relief plus Thin Wells, spends one day/slot, and adds resilience and Free Caravan standing.
- Cinderford is now a selectable Toll Road stop. Ashgate–Cinderford and Cinderford–Brine Cross each cost six ashmarks, while the existing direct Ashgate–Brine Cross passage remains twelve. Its repair bench spends fourteen ashmarks, one day, and one slot to lower Toll Road exposure by three points.
- `Open Routes, Shared Wells` requires the completed Reedwatch relief contract, Reedwatch resilience 2+, and arms escalation 1 or lower at stage 3.
- `Order at the Cistern` requires Warden standing 3+, Free Caravan standing 1 or lower, and arms escalation 1 or lower at stage 3. It describes the resulting permit-controlled access and regulated trade style.
- `No Road Owns the Sky` requires Free Caravan standing 2+, Warden standing 1 or lower, and arms escalation 1 or lower at stage 3. It describes independent access, volatile margins, and shared route information.
- `The Best Margin` requires at least 220 ashmarks, Reedwatch resilience 1 or lower, and arms escalation 1 or lower at stage 3. It describes profitable but uneven crisis recovery.
- Unqualified day-ten states remain playable in `Settlement decision`; a qualified state records an immutable ending ID and regional summary.
- Ending rules are ordered: when a state qualifies for both, completed shared relief takes precedence over regulated reserve control.
- Ending evaluation occurs after the complete command, so a day-ten event choice or arrival consequence can change the selected conclusion before it becomes immutable.
- Save version 11 preserves either ending. Tests cover every stage boundary, unmet predicates, both successful resolutions, precedence, save/load, migration, and UI presentation.
- Four fresh command campaigns reach different endings: relief plus public resilience, regulated medicine trade plus Warden recognition, exposed-route information plus publicly shared water for Free Caravan standing, and repeated arbitrage plus a scarcity-premium sale for concentrated merchant profit.
- Reached endings appear in a dedicated scrollable campaign-conclusion card, remain saved, and do not prevent post-ending trade inspection.

## B10 build-operations result

- Source-controlled export presets now define `Windows Desktop` and `Web` artifacts.
- Pull-request packaging and tagged releases export both targets with Godot 4.4.1 templates, verify the Web payload, and launch the packaged Windows executable headlessly before upload; each candidate carries a manifest with game/content versions and exact commit/ref/run provenance.
- Runtime packages exclude repository-only tests, tools, research, documentation, and workflow files; the adjacent source snapshot preserves them for auditability.
- The project declares a 1280×720 canvas with a 960×540 minimum window and canvas-item stretch for smaller desktop displays.
- The settlement shop exposes the packaged build commit, seed, save version, content version, and last command status for reproducible playtest reports; `ui_cancel` returns safely from departure planning when no event is pending.
- Shop, Departure Desk, route decision, and arrival transitions now place focus on a predictable enabled control and retain ordinary focus traversal.
- Rebuilding contract, local-opportunity, or crew controls after a result restores focus to the first remaining enabled Shop action, falling back to Plan departure when none remain.
- Main Menu, Shop, and Departure use explicit cyclic focus order. The Shop cycle is rebuilt with dynamic content and skips disabled trade, contract, opportunity, and crew actions.
- Enter/Space and controller A activate focused controls; Escape and controller B share the safe departure-back action. The Main Menu explains both schemes.
- The Main Menu can independently remap keyboard keys and controller buttons for Accept, Back, and Pause, rejects modifier/reserved/conflicting inputs, reserves D-pad directions for focus navigation, persists mappings outside campaign saves, and restores both input families in one action.
- P/controller Menu pauses from any gameplay state; Escape/B pauses where it cannot safely act as Back. The modal preserves pending events and restores the previous focus on Resume.
- Reduced-motion and 25% large-text options persist in a separate user settings file without entering deterministic campaign state. Long Shop/Departure context scrolls while Buy, Sell, the guided purchase, Plan departure, Commit/Return, and Enter Settlement remain pinned; changing text size also scrolls the focused event choice back into view. Packaged-browser evidence covers the 960×540 baseline.
- Successful commands autosave to the prototype slot while rotating one backup generation. If the command succeeds but its autosave fails, the primary result immediately shows a `SAVE WARNING` and uses the blocked cue. Manual Save, Continue, and Load show day/location/version context; a corrupt primary recovers from backup, while unrecoverable missing, malformed, and future saves are rejected before the active world is replaced.
- Saving after backup recovery validates the current primary before rotation, so a corrupt primary cannot overwrite the known-good backup generation.
- Returning from Pause to the Main Menu requires its protective autosave to succeed; a write failure leaves the live campaign paused and explains how to resume instead of silently discarding the session.
- Loading from Pause also fails closed: invalid or missing files keep the overlay open with the validation reason, while a successful load closes it and focuses the restored Shop or route decision.
- Reset requires explicit confirmation, initially focuses the non-destructive cancel action for keyboard/controller users, does not overwrite the disk save itself, and explains that the previous campaign remains loadable until the next successful autosave.
- The Main Menu pre-validates primary and backup saves, shows day/location/money/cargo before Continue, and disables Continue when neither generation is safe to load.
- When any campaign save generation exists—even one this build cannot validate—Start Game becomes Start new game, requires a cancel-focused confirmation, and states exactly when the new run may replace those files; first launch remains immediate.
- Shop and Pause can export a versioned, privacy-safe JSON playtest report containing the exact packaged commit/run, build/content/save versions, platform, broad last-input type, actual desktop/browser window dimensions and display scale, presentation settings, session/first-trade timing, seed, current resources, contracts, events, route conditions, information, crew, ending context, command history, and game log without personal identifiers. Desktop builds write a local file, Web builds trigger a JSON download, and Pause keeps the result visible above the overlay actions.
- Local preset parsing and project import pass. CI exports the Windows executable and complete Web payload, verifies their required files, launches the packaged Windows game headlessly, and uploads a provenance manifest, source snapshot, and SHA-256 integrity list. The last successful dependent Linux/Chrome job verifies that the packaged Web loading overlay clears, enters the campaign through the rendered canvas, and records Main Menu plus Settlement Shop screenshots at the minimum and standard viewports. The current workflow additionally uses keyboard focus to open Departure, commit the route, enter the destination, enable Large text, and trigger a cargo-gated Toll Road event; captures the normal journey flow, Gatekeeper event card, and large-text Main Menu/Shop/Departure at both sizes; and decodes screenshot pixels to reject superficial transitions. This awaits a runner because of the external billing/spend gate. Direct local export remains unavailable only because the temporary editor installation lacks templates.
- `docs/ux/alpha_accessibility_input_audit.md` separates automated minimum-window evidence from the physical-controller, high-DPI, rendered large-text, color-simulation, and deeper browser checks still requiring human execution. `docs/playtest_feedback_form.md` captures comprehension and causal run stories without personal data.

## Next permitted task

Run the packaged candidate through the documented rendered browser/Windows, high-DPI, and physical-controller matrix. Keep any resulting fixes narrow; do not broaden into beta content or storefront integration until those observations are recorded.
