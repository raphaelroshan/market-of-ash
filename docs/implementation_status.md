# Market of Ash — Implementation Status

**Investment update (2026-09-02):** MA-I1 through MA-I3 are complete. The guided opening proves a contract-free Water-and-Grain circuit and visible market response; the authored journey now carries crew and optional side deals into the terminal economic/political receipt. MA-I4 is active.

**Baseline branch:** `a0-command-result-boundary`  
**Baseline commit:** `5859d89` (`docs: add GPT agent alpha handoff roadmap`)  
**Roadmap status:** A0–A1 foundations, B0–B10's automated scope, the bounded Five-Well Basin deterministic vertical slice, **MA-EA-1 through MA-EA-6**, and **MA-I1** are implemented and locally verified. The open-trade Feeds A–E remain intact: authored production/consumption roles, differentiated replenishment, ordinary-trade-first Bazaar language, non-contract balance gates, two causal replacement actors, reversible emergent-faction interaction, explicit cross-path reward balance, and two alternate endings reached through scenario failure followed by ordinary trade. Native evidence verifies the release-facing shell and all three playable regions at 960×540, 1280×720, 1600×900, and 1920×1080; every frame proves developer panels, diagnostics, and report actions are absent. Every numeric Early Access content floor and agent-implementable release-hardening gate is met. MA-I1 also reduces 25 deterministic world/save round trips from the audited approximately 5,161.91 ms to 41.62 ms locally by eliminating whole-document copies from individual content lookups. MA-I2 is active. Commercial art polish, physical-device and assistive-technology coverage, antivirus/storefront certification, and moderated player evidence remain external gates.

## Implemented player-facing spine

- Main Menu presents New Game, validated Continue, Settings, Credits, and desktop Quit as a restrained game menu. Debug-only QA scenarios and diagnostics are hidden behind Ctrl+Shift+D.
- New Game opens three illustrated story cards that establish the basin crisis, caravan resources, and route tradeoffs before entering Ashgate. The player can begin the guided campaign or explicitly start without guidance; existing saves remain protected by the same confirmation flow.
- The optional tutorial follows two complete journeys through authoritative commands: accept Reedwatch Water Relief, buy four Water, plan and resolve the Old Road, recover and complete the delivery, buy Grain, return to Ashgate, sell the surviving load, recruit and assign crew, and review Town Outlook.
- Tutorial progress is derived from world state and bounded command evidence rather than duplicated simulation flags. Presentation progress is stored beside the world in a versioned campaign-save envelope; legacy direct-world saves still load safely.
- Privacy-safe playtest reports record the selected fresh-run path; Main Menu Continue is identified separately so resumed saves are not misclassified as a guided opening.
- The Settlement Bazaar owns local price inspection, buying, selling, jobs, services/intelligence, crew, optional outlook, and the handoff to travel planning through a stable stall directory.
- The Bazaar keeps that directory spatially consistent while giving all ten settlements stable visual identities: the Basin's Warden gate, brine pans, forge span, lantern market, and watched reed-water store; Glasswind Reach's glass exchange, kiln yard, and mirrored night oasis; and Siltfire March's resin-lit quay and raised watch post. Authored palettes now theme the full Bazaar cards and canvas so region changes read beyond the identity strip.
- Glasswind Reach is a complete second-region loop. Sunfall Exchange, Kiln Rest, and Mirror Wells exchange saltglass, dune spice, and lamp oil through two profitable ordinary-trade patterns, with no contract required.
- The Glasswind Trace connects Hollow Market to Sunfall Exchange and Kiln Rest through legal intermediate segments. The Mirror Run links Sunfall Exchange to Mirror Wells. Both roads have authored costs, time, risk, map paths, descriptions, palettes, and code-native silhouettes.
- `The Shardwind Tithe` presents a licensed safe lane, a time-and-provision shelter recovery, and a disclosed cargo-risk crossing. Its pending state and resolved result survive save/load.
- Mirror Wells Beacon Oil is optional. Success rewards the Glass Consortium; ignoring or missing it activates the Night Market, changes lamp-oil and saltglass prices, adds local resilience, closes the stale offer, and exposes a reversible beacon-support action.
- Siltfire March closes the three-region map through Mothlight Quay and Blackreed Post. Medicine and cloth travel toward the isolated post; grain and charcoal fund the return, with no named assignment required.
- The low-cost Salt Causeway connects Brine Cross to Mothlight through a brine-whiteout hazard and a pay/wait/risk recovery event. The steadier Reedline Track connects Mothlight and Blackreed to Reedwatch through authored segments. Bell charts and reed skids persistently reduce their respective road risks.
- The Causeway Bellkeepers are the fourth standing faction. Paying their whiteout guide or funding a current bell chart builds trust; rejecting their line costs it. Trusted bell-line regulars pay two fewer ashmarks on the Salt Causeway without erasing cargo risk.
- The five-person roster now includes Blackreed wheelwright Mara Voss and Mirror Wells signal reader Orin Bell. Their assigned responses consume carried scrap or lamp oil to create persistent, route-specific safety knowledge; neither character is a passive global modifier.
- `The Reedline Takes a Wheel` and `Two Beacon Lines` bring the game to eight deterministic event families. Each has paid, delayed, risky, and crew-enabled responses, explicit prerequisites, save-safe outcomes, and zero-resource recovery.
- The Night Market now exposes cooperation, opposition, and reconciliation through beacon fuel, Consortium registration, and a public signal ledger. `Beacons Without Licenses` requires positive Night Market support, two Mirror Wells resilience, controlled arms pressure, and four ordinary saltglass sold after the replacement market activates.
- Departure Desk owns the regional map, legal destination/route selection, route forecast, assignment-aware node state, hover/selection briefs, return-to-bazaar navigation, and travel confirmation.
- Every successful departure enters a dedicated road view before an authored event or arrival can appear; the player explicitly continues from the midpoint observation.
- Animated departures add a short palette-tinted dust trail from the licensed temporary particle kit. It fades before the mandatory road stop, carries no state, and is suppressed by Reduce Travel Motion.
- The regional map is a real planning surface rather than a placeholder grid: settlement markers select direct destinations, explain unreachable stops, distinguish available and accepted assignment destinations, label the current crisis stage/location and local resilience without relying on color, and emphasize the selected corridor. Once travel is committed, map clicks and planning selectors lock until the road, route decision, and arrival report are complete.
- The scroll-safe Main Menu keeps fresh-start and validated-continue actions above optional accessibility/input settings, and exposes reduced motion, large text, keyboard/controller button remapping, and default restoration.
- Desktop builds expose a conventional Main Menu Quit action; Web builds omit it and leave tab lifecycle to the browser.
- The Main Menu also exposes a persisted Interface Sounds switch. Short CC0 Kenney cues distinguish successful commands, blocked actions, and committed travel without carrying essential information; the source files and licenses remain in the temporary asset kit for later replacement.
- Opening Guide / Intel plays a short CC0 page cue only when entering that stall; revisiting the active stall and disabling Interface Sounds remain silent.
- Successful purchases and sales use a short CC0 coin-handling cue instead of the generic command confirmation. Blocked trades still use the warning cue, and Interface Sounds suppresses both.
- Successful purchases and sales briefly show a stamped Bazaar receipt with realized quantity, ashmark movement, and resulting hold use. The receipt adds no simulation state, dismisses on navigation, and skips scaling/fading when reduced motion is enabled.
- Runtime goods, settlements, route endpoints, and planning assumptions load from validated `content/runtime_world.json`.
- Every settlement declares authoritative exports, recurring consumption, and a concise ordinary-market thesis. Validation requires every good to have at least one producer and one consumer across the basin.
- Prices and route forecasts are deterministic and explain their current inputs.
- The Trade stall frames the selected load as `ORDINARY TRADE — NO CONTRACT REQUIRED`, connecting its authored source and destination need to unit spread, load margin, route burden, exposed-unit risk, and expected net value.
- The first-run Water delivery has a positive risk-adjusted forecast, and pre-purchase route forecasts include the proposed load in the same one-exposed-unit risk model used after purchase.
- Forecasts label selected quantities as trade scenarios, show the matching quantity actually held, and warn that departure carries only the real hold when a proposed load has not been purchased.
- First-run objective progress is reconstructed from saved command evidence, so loading after the guided purchase or completed sale cannot reset the prompt or repeat its one-use action; missing cargo produces a specific recovery prompt instead of silently returning to step one.
- The tutorial and visual evidence buy through the same visible Bazaar control as ordinary play; the retired one-click test helper no longer exists in runtime UI or semantic actions.
- Completing a purchase transfers keyboard/controller focus to Plan departure, matching the visible next-step instruction.
- Buy, sell, and departure mutations pass through a serializable command/result boundary; runtime and loaded histories both retain only the newest 100 command records.
- The human-readable campaign log retains the newest 200 entries both during play and after load, preventing long sessions or imported saves from inflating saves and diagnostic reports without bound.
- Every command result appends a state-aware `NEXT` instruction: revise a blocked plan, resolve a pending event, enter after arrival, or continue shop planning.
- Saves declare save version 12 and runtime content version `1.26.0`; successful commands autosave through a temporary file with one backup generation, manual save/load summaries are visible, older saves migrate safely, and oversized files, malformed structure, invalid bounds/references, impossible pending journeys, forged current-content contract/event/scenario terms, or future versions cannot replace the active run.
- A deterministic 100-seed policy simulation records opening-route incentives, forecast error, safe-opening resource floors, viable strategy breadth, best-choice rotation across changed world states, real cargo-loss recovery, and tutorial preparation overhead.
- Route forecasts and incidents share a disclosed one-exposed-unit model owned by `MarketEconomy`.
- Successful sales create bounded per-settlement/per-good supply pressure, prices explain the effect, elapsed days decay it, and versioned saves preserve it. Consumer markets replenish at 150% of baseline decay, neutral markets at 100%, and producer markets at 75%, keeping recurring needs useful without erasing recent deliveries.
- Settlement visits expose a two-slot auxiliary-action budget. Ashgate's provisions and escalation recovery, Brine Cross's cistern queue, Cinderford's repair bench, Hollow Market's route rumor, and Reedwatch's supply shelter create local tradeoffs with visible dependency reasons.
- Ashgate offers a fixed-term Reedwatch water-relief contract and a Warden-gated Brine Cross medicine escort. Accepted terms, prerequisites, and relationship effects are visible, frozen, pinned during departure, and resolved deterministically on arrival.
- Reedwatch relief now has an authoritative offered/accepted/delayed/failed/resolved/expired state machine. Ignoring it through Day 4 or letting an accepted load run overdue activates the Well Commons once, closes the stale offer, adds one local resilience, stabilizes water, and turns charcoal into a new profitable ordinary-trade opportunity; successful relief prevents that response.
- Once active, the Well Commons offers two cooperation paths and a Warden bypass: charcoal can fuel public boilers, the public ledger can mark safer Dry Cut stations, or a permit can bypass the ration queue. Commons support is bounded from -3 to +3, saved, changes the strength of the water/charcoal response, and can be reversed by later action.
- A ten-minute reward fixture compares ordinary trade, the opening relief contract, civic work, and Commons work across ashmarks, provisions, hold capacity, standing, time, and visit slots. The relief reward is 180 ashmarks: 100 expected net versus 99 for the best ordinary opening, keeping the contract attractive without making it compulsory. The Job Board presents this value vector instead of collapsing reputation and civic effects into cash.
- `The Wells Belong to Those Who Carry` is a fifth regional ending. It requires missed or failed official relief, positive Commons support, two Reedwatch resilience, and a post-activation ordinary delivery of at least four charcoal. A pre-activation delivery cannot satisfy it.
- Eligible Toll Road journeys can pause at `The Gatekeeper's Chalk`, with visible pay, detour, and wait choices and a guaranteed recovery option.
- Repair-material loads on the Old Road can pause at `The Span at Cinderford`; public choices persist a visible lower-risk route condition while a turn-back option preserves the load.
- Shortage-stage water arrivals can pause at `The Last Clean Barrel`; the player can take a frozen premium, share supply, honor an active relief contract, or preserve the load for ordinary trade.
- High-value Old Road or Dry Cut loads can meet `Three Riders, No Banner`; money, medicine, disclosed one-unit risk, and a time-for-information recovery create distinct responses without combat.
- Every route decision presents a `Roadside Decision` summary with the highest disclosed cargo-loss chance, exposed asset, route context, available-choice count, and explicit certainty/cost/result/expected-outcome lines. This clarifies confrontation resolution without adding hidden health, real-time combat, or a second simulation path.
- Resolving a route conflict replaces the choice card with a `Journey Result` comparison derived from the archived event and authoritative command outcome. It shows expected versus arrival money, provisions, cargo, days, destination, the deterministic risk roll, and persistent route/resilience/information/reputation effects; the Web arrival announcement reads the same comparison.
- The Journey Result now leads with a compact consequence receipt: `PLAN HELD`, `RISK AVOIDED`, or `RISK REALIZED`, plus the exact cargo and roll/threshold result. Its code-native crate seal and color treatment are redundant with text, static under every motion setting, and derived only from the archived event outcome.
- Entering the destination clears the transient arrival card but preserves the latest comparison in a `Since Your Last Visit — Last Conflict` shop panel. The panel and its Web announcement are rebuilt from bounded saved event history after load, so this continuity requires no additional UI save state or migration.
- When a disclosed conflict risk actually removes cargo, the same report adds a concrete recovery line. It selects the highest-value uncommitted surviving local sale, prices that stack at the current market, and names the lowest-risk route affordable with current funds plus that sale; contract-reserved cargo is protected, and if neither option exists the report directs the player to the visible opportunity blockers instead of implying a restart.
- Disabled route-event responses render their prerequisite as persistent text below the control, so keyboard/controller players do not need hover access to understand unavailable choices.
- Dynamic contract, settlement, crew, and route-event actions use full-width wrapped controls; long cost/risk/consequence labels remain readable instead of being truncated in the narrow action rails.
- Nara Vey can be recruited and assigned through the visit budget; departure forecasts distinguish unavailable, stale, and same-day scout-informed route notes without changing the authored risk.
- Jorun Pale shares the same recruit/assign lifecycle; a current logistics plan reduces provision use by one, never below one, while leaving route time and risk intact.
- Tess Oryn shares the crew lifecycle and visibly unlocks a Gatekeeper ledger challenge with a one-day cost, a named information lead, and a disclosed Warden-standing penalty.
- The Caravan Yard presents Nara, Jorun, and Tess as distinct roster cards with code-native portraits, visible availability/assignment state, personality, decision lever, limitation, and the authoritative recruit or assignment action.
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
- `scenario_states`
- `emergent_factions`
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
- `tests/test_tutorial_flow.gd`: game-facing menu and introduction, hidden developer tools, the complete two-journey guided campaign, recovery, trade, crew, Outlook completion, and tutorial save/load persistence.
- `tests/test_controller_flow.gd`: dispatches joypad A/B/Menu/D-pad events through Godot to verify Main Menu traversal, controller quantity adjustment, Pause/Resume, safe Back, non-mutating planning, and a complete Medicine → Toll Road → Gatekeeper event → Brine Cross journey.
- `tests/test_campaign.gd`: command-only fresh campaign from relief acceptance through deterministic travel/events, public resilience, the day-ten ending, command history, and canonical save/load restoration.
- `tests/test_second_region.gd`: Glasswind ordinary trade, Shardwind branches, pending-event save/resume, optional beacon contract, ignored-contract Night Market activation, emergent-faction interaction, and save/load persistence.
- `tests/test_ma_ea_5.gd`: both new recruits, all new event responses, blocked specialist/material choices, deterministic pending-event replay, persistent route conditions, faction result copy, and save/load persistence.
- `tests/test_capture_validation.py`, `tests/test_policy_check.py`, and `tests/test_windows_export_validation.py`: dependency-free regression coverage for screenshot evidence, release policy, and embedded-PCK x86-64 PE structure.
- `tools/simulate_trade_policies.gd`: read-only 100-seed opening-policy simulation through the production command boundary.

## Current UI transitions

| From | Action | To | Authoritative mutation |
| --- | --- | --- | --- |
| Main Menu | New Game | Introduction | None. Story-card navigation is presentation-only. |
| Introduction | Begin Guided Campaign / Start without guidance | Settlement Bazaar | Creates deterministic fresh world state and initializes or skips tutorial presentation. |
| Settlement Bazaar | Choose stall / Buy / Sell / local action | Settlement Bazaar | Stall navigation is presentation-only; transactions use the command processor. |
| Settlement Bazaar | Plan Departure | Departure Desk | None. Planning selection is preserved. |
| Departure Desk | Return to Bazaar | Settlement Bazaar | None. |
| Departure Desk | Confirm and set out | Road View | Yes, through `depart_route`; presentation cannot alter the result. |
| Road View | Continue journey | Route Event or Arrival Report | None; reveals the next already-resolved journey phase. |
| Route Event | Choose response | Arrival/Return Report on map layer | Yes, through `resolve_event`. |
| Arrival Report | Enter Settlement | Destination Settlement Bazaar | None beyond the completed departure command. |

## Remaining roadmap-to-code mismatches

1. **Godot is not installed on the default shell `PATH`.** CI uses Godot 4.4.1 on Ubuntu and Windows. Current work was verified locally with a temporary Godot 4.4.1 binary, so future sessions must either reuse/provision that version or report the limitation explicitly.
2. **Local Chrome cannot start inside the host sandbox.** Matching Godot 4.4.1 Web templates are installed and repeated local exports produce the complete payload without recursively importing prior build outputs. Selenium still fails before session creation because Chrome's Mach-port bootstrap is denied, while CI now supplies authoritative packaged-browser evidence in Chrome, Firefox, and Edge.
3. **External release certification remains.** The project meets the floor for regions (3), settlements (10), goods (10), routes (7), crew (5), event families (8), standing factions (4), replacement actors (2), and endings (6), and MA-EA-6 automates packaging and publication. Signing, antivirus reputation, storefront review, physical-device and assistive-technology checks, and moderated playtests cannot be claimed from repository automation.

## Baseline verification commands

```bash
bash scripts/verify.sh
godot --headless --path . --editor --quit
godot --headless --path . --export-release Web build/web/index.html
```

`scripts/verify.sh` runs repository policy, every content validator, validator fixtures, and all deterministic Godot suites. The separate editor import remains useful for import/cache validation.

CI run 231 on PR head `b8b55a3` passed repository policy, Ubuntu and Windows Godot tests, deterministic review, Windows/Web packaging and smoke checks, packaged Windows GUI/resource validation, and 84 packaged-browser captures across Chrome, Firefox, and Edge. Local results must still be recorded for every subsequent slice.

## Baseline verification result

Verified locally with Godot `4.4.1.stable.official.49a5bc7b6`:

- Economy suite: `PASS: Market of Ash economy tests`
- Map UI suite: `Map UI smoke: PASS`
- Campaign suite: `Campaign smoke: PASS`
- Headless editor import: completed successfully; Godot emitted a non-fatal shutdown warning after its filesystem scan.
- Repository policy: pass, with expected warnings for local `.godot/` import metadata.
- Content manifest, political geography, tribal conflict, economy/settlement, and runtime-world validators: pass.
- `git diff --check`: pass.

## MA-EA-2 verification result

Verified locally with Godot `4.4.1.stable.official.49a5bc7b6`:

- Full `scripts/verify.sh`: pass, including the dedicated second-region suite and all existing deterministic, tutorial, controller, campaign, policy, content, and validator tests.
- Native render capture: 160 frames passed at 960×540, 1280×720, 1600×900, and 1920×1080.
- Glasswind evidence covers Market, Jobs, Departure Desk, committed travel, road observation, Shardwind encounter, arrival, Mirror Wells Bazaar, and the failure-forward Night Market.
- Fresh Windows export: 98,140,032-byte x86-64 executable with a valid 619,892-byte embedded PCK; local resource stamping emitted the expected missing-`rcedit` warning.

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

## B3 contract result

- The Reedwatch Wellkeepers offer a four-water delivery due two days after acceptance for 150 ashmarks.
- Completing Reedwatch relief grants one Free Caravan standing, making its public relationship consequence part of the frozen contract terms.
- The Ash Warden Cistern Office offers a two-medicine Brine Cross escort due within two days for 108 ashmarks. It requires one Warden standing, grants one on success, and withdraws one on failure.
- Acceptance consumes one visit slot, freezes terms, and reserves no cargo; spot buying and selling remain available.
- The Job Board persistently explains unmet faction standing, updates immediately when standing changes, and lists sponsor visibility plus success/failure relationship effects before acceptance.
- The Departure Desk pins every active contract's destination, deadline, reward, held quantity, and free hold space.
- Route incidents resolve before delivery. A complete load auto-delivers; a partial load remains active with the exact shortfall; late failure costs at most eight ashmarks and leaves cargo sellable.
- Regulated escort failure costs at most six ashmarks, preserves medicine for spot-sale recovery, and applies its disclosed standing loss.
- Save version 4 and later preserve active and resolved contract state; current-content saves reject forged prerequisite or relationship terms.

## Executable game-quality gates

- The guided first expedition completes in 100/100 deterministic seeds and never falls below 118 ashmarks or 11 provisions.
- The opening contains seven positive strategies across four goods and both the exposed and regulated road types.
- Four named ordinary-trade fixtures cover staple, repair, medicine, and industrial cargo; all remain profitable without accepting a contract.
- The best opening ordinary trade must retain at least 70% of the accessible relief contract's expected net value; the current deterministic result is 99 versus 70 ashmarks.
- Ignored relief must expire causally, activate the Well Commons once, raise Reedwatch resilience to one, close the stale assignment, and turn a four-charcoal Ashgate run from -10 to +7 expected net.
- The Commons must expose two executable cooperation paths, one executable opposition path, and reconciliation from -1 back to neutral while ordinary charcoal trade remains open.
- Four representative market/access states rotate the best forecast across three choices and two routes, preventing a permanent route winner in the measured slice.
- A real command-path cargo-loss run recovers starting cash in one outbound trade while retaining positive money and provisions.
- The guided contract flow reaches its first cargo purchase in two authoritative commands, with one non-trade action before meaningful trade.
- `tests/test_game_quality.gd` blocks regressions in these thresholds, while `research/playtest_simulation/quality_gate_summary.csv` records the current evidence.

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
- Save version 12 preserves endings plus adaptive scenario and emergent-faction state. Tests cover every stage boundary, unmet predicates, both successful resolutions, precedence, save/load, migration, and UI presentation.
- Four fresh command campaigns reach different endings: relief plus public resilience, regulated medicine trade plus Warden recognition, exposed-route information plus publicly shared water for Free Caravan standing, and repeated arbitrage plus a scarcity-premium sale for concentrated merchant profit.
- Reached endings appear in a dedicated scrollable campaign-conclusion card, remain saved, and do not prevent post-ending trade inspection.

## B10 build-operations result

- Source-controlled export presets now define `Windows Desktop` and `Web` artifacts.
- Pull-request packaging and tagged releases export both targets with Godot 4.4.1 templates, verify the Web payload, and produce a validated portable Windows ZIP. CI extracts that archive into a fresh runner directory, launches the extracted executable headlessly and visibly, and records a manifest with game/content versions and exact commit/ref/run provenance.
- Runtime packages exclude repository-only tests, tools, research, documentation, and workflow files; the adjacent source snapshot preserves them for auditability.
- The project declares a 1280×720 canvas with a 960×540 minimum window and canvas-item stretch for smaller desktop displays.
- The settlement shop exposes the packaged build commit, seed, save version, content version, and last command status for reproducible playtest reports; `ui_cancel` returns safely from departure planning when no event is pending.
- Shop, Departure Desk, route decision, and arrival transitions now place focus on a predictable enabled control and retain ordinary focus traversal.
- Rebuilding contract, local-opportunity, or crew controls after a result restores focus to the first remaining enabled Shop action, falling back to Plan departure when none remain.
- Main Menu, Shop, Departure, Pause, and route-event choices use explicit cyclic focus order. Dynamic Shop and event cycles skip disabled actions while leaving their reasons visible.
- Selectors and utility actions maintain a 44-logical-pixel minimum target; primary trade, journey, binding, and event actions remain larger where labels need wrapping.
- Web builds mirror the active screen into a polite ARIA live region and descriptive canvas label. A visually hidden, focus-revealed HTML region exposes current primary and safety-critical actions as real buttons and the Shop/Departure planning fields as native select/number controls, preserving exact labels, options, values, bounds, enabled states, and Godot tooltip descriptions. Interaction emits the existing Godot signals, so JavaScript owns no gameplay rule.
- Enter/Space and controller A activate focused controls; Escape and controller B share the safe departure-back action. Explicit vertical focus neighbors prevent D-pad traps, and controller Left/Right changes focused quantities. The Main Menu explains both schemes.
- The Main Menu can independently remap keyboard keys and controller buttons for Accept, Back, and Pause, rejects modifier/reserved/conflicting inputs, reserves D-pad directions for focus navigation, persists mappings outside campaign saves, and restores both input families in one action.
- If the separate presentation-settings file cannot be written, the chosen option remains active for the current session and the Main Menu shows an explicit persistence warning.
- P/controller Menu pauses from any gameplay state; Escape/B pauses where it cannot safely act as Back. The modal preserves pending events and restores the previous focus on Resume.
- Reduced-motion and 25% large-text options persist in a separate user settings file without entering deterministic campaign state. Long Shop/Departure context scrolls while Buy, Sell, the guided purchase, Plan departure, Commit/Return, and Enter Settlement remain pinned; changing text size also scrolls the focused event choice back into view. Run 200's packaged-browser evidence covers the complete normal/Large text matrix at 960×540 and 1280×720 in Chrome, Firefox, and Edge.
- Successful commands autosave to the prototype slot while rotating one backup generation. If the command succeeds but its autosave fails, the primary result immediately shows a `SAVE WARNING` and uses the blocked cue. Manual Save, Continue, and Load show day/location/version context; a corrupt primary recovers from backup, while unrecoverable missing, malformed, and future saves are rejected before the active world is replaced.
- Save attempts clear stale temporary generations before writing and remove partial temporary files after write or promotion failures, so only the primary and validated backup remain as load candidates.
- Saving after backup recovery validates the current primary before rotation, so a corrupt primary cannot overwrite the known-good backup generation.
- Returning from Pause to the Main Menu requires its protective autosave to succeed; a write failure leaves the live campaign paused and explains how to resume instead of silently discarding the session.
- Loading from Pause also fails closed: invalid or missing files keep the overlay open with the validation reason, while a successful load closes it and focuses the restored Shop or route decision.
- Reset requires explicit confirmation, initially focuses the non-destructive cancel action for keyboard/controller users, does not overwrite the disk save itself, and explains that the previous campaign remains loadable until the next successful autosave.
- The Main Menu pre-validates primary and backup saves, shows day/location/money/cargo before Continue, and disables Continue when neither generation is safe to load.
- When any campaign save generation exists—even one this build cannot validate—Start Game becomes Start new game, requires a cancel-focused confirmation, and states exactly when the new run may replace those files; first launch remains immediate.
- Shop and Pause can export a versioned, privacy-safe JSON playtest report containing the exact packaged commit/run, build/content/save versions, platform, broad last-input type, active keyboard/controller action mappings, actual desktop/browser window dimensions and display scale, presentation settings, session/first-trade timing, seed, current resources, contracts, events, route conditions, information, crew, ending context, command history, and game log without personal or controller identifiers. Desktop builds write a local file, Web builds trigger a JSON download, and Pause keeps the result visible above the overlay actions.
- Local preset parsing, project import, and current-head Web export pass with matching Godot 4.4.1 templates. CI exports the Windows executable and complete Web payload, verifies their required files, launches the packaged Windows game headlessly, and uploads a provenance manifest, source snapshot, and SHA-256 integrity list. Run 217 passed 28 required captures in each of Chrome, Firefox, and Edge: 14 normal/Large text/event/result states at exact 960×540 and 1280×720 viewports, with app state, ARIA announcements, exact semantic action inventory, non-mutating Return-to-Shop checks, and decoded-pixel transition validation. The minimum-viewport journey focuses the mirrored HTML buttons and activates them with Enter; the standard viewport retains canvas pointer traversal. Local Selenium remains blocked before session creation by the host's Chrome Mach-port sandbox.
- Desktop builds now open at 1600×900 while preserving the 1280×720 logical canvas and 960×540 minimum window. Shop and Departure columns consume the available width, and the route board scales horizontally within safe marker bounds instead of leaving unused space.
- Responsive-shell M1 clamps the preferred 1600×900 launch size to the current display's usable area and deliberately stacks Main Menu and Introduction at 1280 pixels wide and below. The compact Main Menu uses a shorter illustrated header so New Game, Continue, Settings, Credits, save status, and Quit remain inside the card; both opening cards add horizontal safety gutters, and Introduction actions wrap under Large Text. Native capture manifests now require every named opening heading, explanation, status, and action to remain inside both its card and the active layer, alongside the existing Bazaar, Departure, route-event, and arrival/debrief bounds.
- Bazaar hierarchy M2 now opens the Market Stall on a single ordinary-trade card derived from the existing economy and route forecast. It connects the selected source to the destination need, shows buy/sale/route/expected values, provisions and exposed-unit risk, available ashmarks, projected hold use, and the immediate Buy-or-adjust-or-depart action. The same text is published to the Web accessibility state; contracts remain optional and no simulation rule moved into presentation.
- A local real-renderer Godot matrix now captures Main Menu, all three Introduction cards, Trade, normal and Large Text transaction receipts, the illustrated Job Board Bazaar, Pause, Departure, non-mutating return, committed departure, the dedicated road stop, Gatekeeper event/result, a deterministic realized-loss recovery result, destination Shop, and new-game confirmation at 960×540, 1280×720, 1600×900, and 1920×1080; the current macOS/OpenGL run covers all 112 frames. The validator accepts both Chrome RGB and Godot RGBA screenshots, checks exact dimensions/state/distinct transitions, validates required responsive-shell bounds, and verifies that the Departure map remains between its instructions and result text. These source-run images complement but do not replace packaged Windows/Web evidence.
- The CI native renderer executes the same real-renderer journey on Windows through ANGLE at the exact minimum 960×540 viewport, validates all 26 states, and uploads the screenshots and manifest. Larger Windows windows remain a physical-machine gate because the hosted runner's virtual desktop constrains them below their requested dimensions.
- A dependency-free color-vision evidence tool produces grayscale, protanopia, and deuteranopia approximations for six constrained 960×540 states. The current 18-frame review keeps route identities, current-location/resilience text, focus borders, disabled reasons, and primary actions legible without relying on hue; these approximations remain a supplement to human accessibility testing.
- The current head cross-exports locally as a 64-bit Windows PE with a structurally verified embedded PCK after installing the matching Godot 4.4.1 x86-64 templates. Windows file/product versions use the numeric `0.14.0.0` required by PE resources while the player-facing project version is `0.14.0-early-access-rc1`.
- CI run 210 installs checksum-pinned `rcedit` before export, launches the packaged executable as a visible Windows GUI, captures only its exact 960×540 client area, and rejects missing/wrong product name, file version, product version, title, bounds, dimensions, or low-detail pixels. The downloaded frame was visually inspected after two iterations fixed off-screen desktop leakage and a stray hover tooltip; it is a clean neutral Main Menu. The 97,848,976-byte x86-64 executable contains a 328,836-byte embedded PCK and all recorded release checksums revalidate.
- CI run 212 packages that executable as a 34,567,550-byte `market-of-ash-windows.zip` containing exactly `Market of Ash/market-of-ash.exe`, rejects unexpected or unsafe archive members, clean-extracts it outside the checkout, and uses the extracted copy for both launch smoke tests and the inspected GUI capture. The separately dispatched release workflow run `33149086304` passed the same resource stamping, portable-package, clean-extraction, GUI, provenance, and checksum path from branch head `8922a9e`.
- CI run 220 (`33152425997`) passed all nine jobs at `f6ddf4a`. Its Chrome, Firefox, and Edge manifests are version 5, each contains 28 captures, 38 minimum-viewport semantic-action instances, and 16 published Shop/Departure form snapshots. The browser flow changes cargo, destination, and integer quantities through native HTML fields, verifies exact labels/options/values/bounds/descriptions after each update, and still routes all actions through the Godot callback. Downloaded constrained Shop evidence shows the semantic overlay hides before capture and leaves the game canvas unobscured.
- CI run 224 (`33154435995`) passed all nine jobs at `4b4ee4d`. Each browser artifact contains 28 captures, 159 total action snapshots, and 32 planning-control snapshots across both viewports. The minimum-viewport flow accepts Reedwatch Water Relief through its generated semantic button, requires the same action to become disabled, and preserves semantic focus through the resulting Shop rebuild. Stable IDs also cover generated contract resolution, settlement opportunities, crew recruitment/assignment, the guided trade, and Shop save/load/reset/report controls. Downloaded Chrome and Edge frames confirm the focus-only overlay is absent from captures and the canvas remains unobscured.
- CI run 225 (`33155440504`) passed all nine jobs at `9de5d5b`. Its manifest-v6 Chrome, Firefox, and Edge artifacts each contain 28 captures, 159 action snapshots, and 44 semantic-control snapshots across both viewports. At 960×540 the harness toggles Reduce travel motion, Large text, and Interface sounds off and on with Space through native HTML checkboxes, requires the published Godot values to match, preserves focus through each DOM rebuild, and checks that Start/Continue precede the optional settings in semantic order. The 1280×720 path remains independently canvas-driven.
- CI run 227 (`33156731432`) passed all nine jobs at `c323604`. Its manifest-v7 browser artifacts each contain 28 captures, 175 action snapshots, and 44 control snapshots. At 960×540 the harness enters Pause remapping through the semantic button, sends `R` through the browser key bridge, verifies Godot preserves the Menu/Start controller binding while publishing Pause as `R`, keeps focus on the same semantic action across the DOM rebuild, then activates Restore default inputs and requires Pause to return to `P`. The mixed action/control order exactly matches the Main Menu's visual sequence in Chrome, Firefox, and Edge.
- CI run 231 (`33160112676`) passed all nine jobs at `b8b55a3`. Its manifest-v8 artifacts add a real modified-shortcut and cancellation check: each browser enters Back remapping, receives Ctrl+R as one modified input without navigating or refreshing, publishes the existing reserved-shortcut explanation while retaining focus and the prior binding, then cancels with Escape. The failed precursor run exposed that `project.godot` shipped Backspace while the runtime default-restoration contract and documentation specified Escape; the shipped input map now uses Escape and a controller smoke regression guards that invariant.
- The settlement Bazaar now opens on Trade and treats its directory as the first navigation layer. Jobs, Services / Intel, Crew, and Outlook replace the ledger and transaction controls with one focused action set plus a settlement-tinted illustrated keeper row; Departure remains pinned throughout. Native capture evidence includes this dedicated Job Board state, and the Web bridge publishes only the selected stall's controls while preserving stable directory actions.
- The mandatory road view now has three stable corridor identities: Ashen Milestones for the Old Road, Warden Causeway for the Toll Road, and Saltwind Cut for the Dry Cut. Departure, named midpoint, encounter, and approach labels are derived from presentation state; origin/destination silhouettes and the authored route-risk description remain visible without changing travel resolution.
- `docs/ux/alpha_accessibility_input_audit.md` separates automated minimum-window evidence from the physical-controller, high-DPI, rendered large-text, color-simulation, and deeper browser checks still requiring human execution. `docs/playtest_feedback_form.md` captures comprehension and causal run stories without personal data.

## Next permitted task

Run a moderated first-time-player comprehension session through the complete introduction and two-journey tutorial, then make only evidence-backed clarity fixes before expanding content.
