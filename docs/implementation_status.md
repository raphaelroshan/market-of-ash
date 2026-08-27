# Market of Ash — Implementation Status

**Baseline branch:** `a0-command-result-boundary`  
**Baseline commit:** `5859d89` (`docs: add GPT agent alpha handoff roadmap`)  
**Roadmap status:** A0–A1 foundations and B0–B8 are implemented. The first B9 ending proof is playable through ordinary commands. B10 build operations and focus continuity are configured; broader manual accessibility review remains.

## Implemented player-facing spine

- Main Menu starts a deterministic Ashgate day-one playtest state.
- Settlement Shop owns local price inspection, buying, selling, cargo context, and the handoff to travel planning.
- Departure Desk owns the regional map, legal destination/route selection, route forecast, return-to-shop navigation, and travel commitment.
- Successful travel presents an arrival report before the player enters the destination shop.
- Runtime goods, settlements, route endpoints, and planning assumptions load from validated `content/runtime_world.json`.
- Prices and route forecasts are deterministic and explain their current inputs.
- Buy, sell, and departure mutations pass through a serializable command/result boundary.
- Saves declare save version 11 and runtime content version `1.9.0`; older saves migrate safely and future saves fail safely.
- A deterministic 100-seed policy simulation records opening-route incentives and forecast error.
- Route forecasts and incidents share a disclosed one-exposed-unit model owned by `MarketEconomy`.
- Successful sales create bounded per-settlement/per-good supply pressure, prices explain the effect, elapsed days decay it, and versioned saves preserve it.
- Settlement visits expose a two-slot auxiliary-action budget. Ashgate's live provision service competes with cargo spending; future settlement actions remain visible with dependency reasons.
- Ashgate offers one fixed-term Reedwatch water-relief contract; accepted terms are pinned during departure and resolve deterministically on arrival.
- Eligible Toll Road journeys can pause at `The Gatekeeper's Chalk`, with visible pay, detour, and wait choices and a guaranteed recovery option.
- Repair-material loads on the Old Road can pause at `The Span at Cinderford`; public choices persist a visible lower-risk route condition while a turn-back option preserves the load.
- Shortage-stage water arrivals can pause at `The Last Clean Barrel`; the player can take a frozen premium, share supply, honor an active relief contract, or preserve the load for ordinary trade.
- High-value Old Road or Dry Cut loads can meet `Three Riders, No Banner`; money, medicine, disclosed one-unit risk, and a time-for-information recovery create distinct responses without combat.
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

- `tests/test_economy.gd`: content loading, prices, crisis modifiers, capacity, route forecasts, command success/failure/history, route topology, travel resources, saves, and migration.
- `tests/test_map_ui.gd`: main-menu start, non-mutating forecast/navigation, guided purchase command use, Shop → Departure Desk transition, legal route filtering, forecast presentation, route geometry, and predictable keyboard/controller focus across screen and event transitions.
- `tests/test_campaign.gd`: command-only fresh campaign from relief acceptance through deterministic travel/events, public resilience, the day-ten ending, command history, and exact save/load restoration.
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

1. **One charter reference is stale.** `docs/gpt_agent_handoff_roadmap.md` references `docs/alpha_release_roadmap.md`, which is not present. The active roadmap is `docs/gpt_agent_handoff_roadmap.md`.
2. **Most named campaign fixtures are not present.** A fresh command-only ending path and the first invalid market-memory fixture exist, but the broader saturated/contract/event/faction/crisis/ending fixture matrix remains planned.
3. **Godot is not installed on the default shell `PATH`.** CI uses Godot 4.4.1 on Ubuntu and Windows. Current work was verified locally with a temporary Godot 4.4.1 binary, so future sessions must either reuse/provision that version or report the limitation explicitly.
4. **Local export templates are not installed.** Windows and Web presets now exist and CI installs matching Godot 4.4.1 templates, but this laptop's temporary editor can only verify preset parsing/project import until templates are installed.

## Baseline verification commands

```bash
bash scripts/verify.sh
python3 tools/policy_check.py --repo raphaelroshan/market-of-ash
python3 tools/validate_content.py --manifest content/content_manifest.json
python3 tools/validate_political_geography.py --data content/political_geography.json
python3 tools/validate_tribal_conflict.py --data content/tribal_conflict.json
python3 tools/validate_economy_and_settlements.py --economy content/economy_framework.json --settlements content/settlement_actions.json
python3 tools/validate_runtime_world.py --data content/runtime_world.json
godot --headless --path . --editor --quit
```

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

## B1 market-memory result

- A four-unit Reedwatch water delivery creates 16% supply pressure and lowers the immediate unit price from 32 to 27 ashmarks.
- Pressure decays by 3% per elapsed day, returns to zero after six days for that delivery, and clamps at 35% under repeated supply.
- Crisis stages reduce the effect of new deliveries while keeping crisis and memory modifiers separately visible.
- The adaptive three-delivery simulation chooses Water → Reedwatch for the first two deliveries and rotates to Medicine → Reedwatch on the third.

## B2 settlement-opportunity result

- Each fresh start and settlement arrival provides two auxiliary-action slots; normal buying and selling consume none.
- Ashgate offers `Pack Warden rations`: six ashmarks for four provisions and one visit slot.
- Brine Cross, Cinderford, Hollow Market, and Reedwatch show one disabled future opportunity each with a specific dependency reason.
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
- `Open Routes, Shared Wells` requires the completed Reedwatch relief contract, Reedwatch resilience 2+, and arms escalation 1 or lower at stage 3.
- Unqualified day-ten states remain playable in `Settlement decision`; a qualified state records an immutable ending ID and regional summary.
- Save version 11 preserves the ending. Tests cover every stage boundary, unmet predicates, successful resolution, save/load, migration, and UI presentation.
- A fresh seed-1107 campaign now reaches the ending through fifteen ordinary commands: accept and fulfill relief, make a second public water delivery, advance through legal routes, then restore the exact completed state from a save.

## B10 build-operations result

- Source-controlled export presets now define `Windows Desktop` and `Web` artifacts.
- Pull-request packaging and tagged releases export both targets with Godot 4.4.1 templates before uploading artifacts.
- The project declares a 1280×720 canvas with a 960×540 minimum window and canvas-item stretch for smaller desktop displays.
- The settlement shop exposes seed, save version, content version, and last command status for reproducible playtest reports; `ui_cancel` returns safely from departure planning when no event is pending.
- Shop, Departure Desk, route decision, and arrival transitions now place focus on a predictable enabled control and retain ordinary focus traversal.
- Local preset parsing and project import pass. CI run 36 exported and uploaded a 94 MB Windows executable plus a complete Web payload (`index.html`, JavaScript, PCK, and WASM); direct local export remains unavailable only because the temporary editor installation lacks templates.

## Next permitted task

Continue B10 with a documented input/accessibility audit and the lowest-risk blockers it identifies.
