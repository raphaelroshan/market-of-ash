# Market of Ash — Decision Log

## ADR-001: Godot 4.x for Windows desktop

**Decision:** Use Godot 4.x with GDScript-first gameplay for the Steam and Epic Games Store desktop release.

**Reason:** The project is 2D-oriented, simulation-heavy, and agent-first. A text-readable scene and script structure, straightforward headless execution, and low engine overhead make it easier for coding agents to inspect, modify, and test than a more editor-dependent workflow.

**Trade-off:** Steamworks and Epic integrations may require community modules, GDExtension wrappers, or small native adapters. Keep these behind platform interfaces and do not make the core simulation depend on them.

## ADR-002: Simulation is presentation-agnostic

**Decision:** Economy, routes, events, factions, crew, and save migration are plain GDScript classes or data resources with no rendering dependency.

**Reason:** The agent can run them headlessly, deterministic simulations can expose balance problems, and UI changes cannot silently alter business rules.

**Trade-off:** The UI needs explicit state refreshes and command/result contracts. This is slightly more verbose but substantially safer.

## ADR-003: Deterministic seed before procedural variety

**Decision:** World state and event resolution accept a seed and remain reproducible.

**Reason:** A bug or balance failure must be replayable. Deterministic seeds also allow agents to create regression tests for specific market, route, and crisis states.

**Trade-off:** The game must later add controlled variation and seed presentation without making outcomes feel sterile.

## ADR-004: One-region vertical slice first

**Decision:** Build five settlements, three routes, six goods, three crew roles, four events, two factions, one crisis, and one ending before adding a second region.

**Reason:** The primary risk is not content volume; it is whether trade remains interesting after the first profitable route is learned. A small region is enough to test that risk.

**Trade-off:** Early builds will feel narrow. This is intentional and protects the project from building a large but repetitive economy.

## ADR-005: No early save deletion or permadeath

**Decision:** Early failure may lose money, cargo, time, or trust but must not delete a save or create an unexplained unrecoverable campaign.

**Reason:** The inspiration audit identified opaque fuel systems, difficulty spikes, and death spirals as recurring reasons otherwise appealing games lose players.

**Trade-off:** The game must create tension through escalating consequence and opportunity cost rather than blunt loss.

## ADR-006: Platform services behind adapters

**Decision:** Steam and Epic features are exposed through an internal platform interface. Gameplay can run without an online service.

**Reason:** The product targets two storefronts while remaining a single-player game. Platform-specific calls in simulation code would complicate testing and cross-store behavior.

**Trade-off:** The project must maintain a small amount of integration glue and test both offline and platform-enabled paths.

## ADR-007: Procedural regional grid before final art

**Decision:** Add a procedural 17x11 Five-Well Basin board with stable grid cells, settlement footprints, route corridors, a selectable future placement cell, and a caravan token that traverses a route after departure.

**Reason:** Spatial readability is required before final art. The player needs to understand where future camp, service, obstacle, escort, and route objects can be placed, and the caravan should visibly move through the region instead of teleporting between settlement menus.

**Trade-off:** The first pass is functional placeholder presentation rather than final illustration. Traversal is presentation-only after the authoritative travel command succeeds; it does not add a second movement simulation or alter prices, risk, provisions, time, or save state. A future art layer must preserve the grid, route, settlement, and token interfaces.

## ADR-008: Generated map art remains optional

**Decision:** Keep the procedural renderer as the source-controlled default and layer generated or authored art beneath it only when an asset is available and does not reduce grid or route readability.

**Reason:** The requested map should be usable immediately, while image generation is not guaranteed and generated maps cannot be trusted to encode gameplay-accurate settlement or route geometry.

**Trade-off:** The current build will not claim final pixel art. Generated assets may improve atmosphere later, but gameplay geometry remains deterministic and code-driven.

## ADR-009: Runtime world content and command/result boundary

**Decision:** Store the initial six goods, five settlements, and three routes in validated `content/runtime_world.json`. Route buy, sell, and depart actions through `MarketCommandProcessor`, which accepts stable command IDs and plain inputs, validates state, applies deterministic changes, returns structured player-facing results, and records a bounded serializable command history. Save data now declares a `save_version` and `content_version`; unversioned prototype saves migrate to version 1, while newer incompatible saves fail safely.

**Reason:** The vertical slice needs one canonical content source, reproducible state changes, UI-independent validation, and actionable test/debug evidence before economy presentation, market memory, events, or faction work expand the system.

**Trade-off:** The first command processor supports only the already playable buy, sell, and depart actions. Future contracts, services, events, faction effects, and upgrades must be added as explicit commands rather than interpreting authored effect text.

## ADR-010: Explainable planning forecast before confirmation

**Decision:** Present the active cargo and route plan through a display-only settlement market and route forecast. The forecast exposes unit price, load total, price drivers, regional comparison, purchase total, expected sale total, gross margin, route fee, provision value, risk-adjusted expected loss, time opportunity cost, and expected net profit. Its assumptions live in validated runtime content.

**Reason:** The core Frontier-inspired decision requires a player to understand why a price spread exists and whether margin justifies risk before buying cargo or departing. The explanation and forecast make the existing deterministic economy legible without changing actual transaction or route-resolution behavior.

**Trade-off:** Expected loss and time opportunity cost are estimates rather than guarantees. The displayed planning model must remain simple and transparent until later work adds information quality, guards, events, contracts, market memory, and other factors as explicit forecast inputs.

## ADR-011: Thin main menu and deterministic quick-playtest preset

**Decision:** Launch to a minimal main menu with one `Start Game` action. Starting a game creates a fresh, deterministic Ashgate day-one state with 120 ashmarks, twelve provisions, empty cargo, and the initial Grain-to-Reedwatch/Old Road forecast selected. The market screen exposes one optional, single-use `Test action: Buy 2 grain` control that executes the normal explicit buy command; departure remains the player’s decision.

**Reason:** The project needs a frictionless external-playtest entry point that demonstrates the game’s core trade decision without introducing a tutorial contract, scenario system, or parallel simulation path. The preset makes the intended first decision reproducible for observation and regression testing.

**Trade-off:** This is an intentionally narrow test loop rather than a complete campaign start, save/load menu, or onboarding flow. The guided button is a temporary playtest affordance and must remain an ordinary command invocation rather than a special reward or hidden state mutation.

## ADR-012: Optional objective ladder with a player-selected route

**Decision:** Refine the quick playtest with a visible three-step objective: inspect the grain forecast and buy two units, choose a route and reach Reedwatch with grain, then sell the grain. The screen reports completion only after the normal sale command succeeds. The test action remains optional, and the player may choose another cargo, destination, route, or continued trading.

**Reason:** The earlier menu established a working entry point but did not make its test purpose, completion condition, or next action sufficiently visible. A compact objective ladder lets a new player recognize the core loop and identify whether the market explanation, forecast, and realized transaction are coherent.

**Trade-off:** The refined status text creates a recommended delivery objective but does not assess player skill, promise profit, force route choice, or impose a tutorial contract. It is playtest scaffolding, not an authored quest or a substitute for later event, contract, and campaign systems.

## ADR-013: Authoritative route endpoints

**Decision:** Each runtime route declares exactly two stable settlement endpoints. The command processor rejects a departure unless its selected route connects the caravan’s current settlement and selected destination. Runtime and command-line content validation reject missing, duplicate, or unknown endpoints. The destination and route controls are populated from the same canonical endpoint data.

**Reason:** Route fees, risk, travel animation, profit forecast, and state mutation must all describe the same corridor. Allowing an arbitrary destination after selecting a route created invalid paths that looked legal in the caravan desk but contradicted the traversal map and distorted simulation results.

**Trade-off:** The first alpha map has deliberately limited direct connectivity; inaccessible settlements remain authored economic contexts until a connected corridor or a broader travel system is added. Endpoint validation takes precedence over offering a complete regional travel graph prematurely.

## ADR-014: Settlement shop as home state; departure map as commitment state

**Decision:** The playable flow separates the local trade screen from the regional travel screen. Starting a run and entering a settlement opens the Settlement Shop. The shop owns buying, selling, local price explanations, cargo context, and the `Plan departure` handoff. The Departure Desk owns the map, canonical destinations and routes, route forecast, `Return to shop`, and `Commit departure`. A successful departure remains on an arrival report until the player selects `Enter settlement`.

**Reason:** The product’s central rhythm is inspect market, form a plan, commit to a route, experience a consequence, arrive, and reinvest. Keeping map and purchase controls in one screen weakens the difference between local browsing and an action that spends time, provisions, and risk. The separation makes the route forecast a deliberate commitment check while preserving the simulation command boundary.

**Trade-off:** This adds one navigation step before travel and does not yet add full contracts, crew, events, or final art. Planning selections persist when returning to the shop, and the added step is justified only because it clarifies the real player decision rather than hiding it behind a modal confirmation.

## ADR-015: GPT implementation work proceeds through one testable vertical slice at a time

**Decision:** Bulk implementation may be delegated to a GPT coding agent, but the agent receives the persistent product charter and one narrowly scoped task card at a time. Every card names an observable player behavior, data/command/UI boundary, acceptance criteria, focused automated checks, manual/visual evidence requirement, and exactly one next task. The product lead reviews the player-facing result and test evidence before releasing the next slice.

**Reason:** Market of Ash has a strong central promise but limited alpha scope. Large autonomous batches are likely to introduce generic framework abstraction, content breadth, or mechanics that are genre-appropriate but weaken the economic route decision. Small vertical slices make determinism, save safety, content validation, balance simulation, and player comprehension reviewable.

**Trade-off:** This process is slower than parallel feature generation and requires explicit review gates. It avoids far more expensive rework from schema drift, UI-owned rules, ambiguous visual feedback, and systems that fail to deepen trade/travel decisions.

## ADR-016: Forecast and route incidents share a one-exposed-unit model

**Decision:** Preserve the bounded one-unit route incident. Before departure, identify the carried good with the highest destination unit value, breaking equal-value ties by canonical good order. Calculate expected cargo loss as route risk multiplied by that one unit value. The forecast and resolver both call pure `MarketEconomy` helpers for this selection and valuation, and every forecast/result exposes the loss-model label, good, value basis, risk source, and expected loss. Empty caravans have zero cargo loss risk.

**Reason:** The previous forecast multiplied risk by the entire selected load value while the resolver removed at most one unit. This made forecasts structurally too pessimistic as load size increased and weakened trust in the commitment screen. A shared one-unit model matches actual resolution, stays legible for mixed cargo, and preserves recovery after an unlucky early trip.

**Trade-off:** The most valuable destination unit is predictably exposed, so mixed-cargo players cannot use content-order accidents to shield expensive goods. This is intentionally conservative and simple; later guards, packing services, or crew hooks may change the exposed-unit selection only through an explicit, tested rule.

## ADR-017: Events are controlled trade consequences, not random interruption volume

**Decision:** The project uses a structured catalogue of travel events, settlement occurrences, market pulses, chance meetings, faction pressure, crisis beats, and regional projects. Events are selected from explicit deterministic predicates and bounded by relevance, cooldown, journey/visit cadence, and prior state. Each implemented major entry must change at least one material category: route access, information, cargo/money, faction reputation, crew trust, settlement resilience, or crisis stage. Every entry has visible stakes, a follow-up state where appropriate, and a recoverable early-game failure outcome.

**Reason:** The game needs an inhabited region and Frontier-style consequential travel, but generic random encounters would interrupt commerce, obscure risk, and create content breadth without memory. A small number of authored scenes with state-sensitive variants makes route choice, cargo, people, and regional projects feel connected.

**Trade-off:** Authoring truth tables and tests per scene is more disciplined than prose-first content generation. It prevents opaque procedural content and allows the initial four canonical events to establish a reliable resolver/UI/content seam before additional variants are activated.

## ADR-018: Market memory is bounded supply pressure with deterministic decay

**Decision:** Represent delivery memory as a per-settlement, per-good supply-pressure value from `0.0` through an authored maximum below `1.0`. Successful sales add pressure after paying the pre-delivery price; elapsed days decay pressure toward zero. The price pipeline applies the resulting `1 - pressure` multiplier after base, settlement, demand, crisis, and faction modifiers. Crisis stages reduce how much new pressure a delivery creates without hiding or replacing the separate crisis modifier.

**Reason:** Repeating the same profitable delivery must change the next trade decision, but a town must recover and retain its authored economic identity. Separate bounded pressure, crisis effectiveness, and decay provide predictable causes that can be shown directly in the market UI and replayed exactly.

**Trade-off:** This is a deliberately compact market response rather than a production/consumption simulation. It models recent local supply relief, not inventories, factories, autonomous traders, or globally coupled prices.

## ADR-019: Settlement opportunities share a two-slot arrival budget

**Decision:** Every settlement arrival refreshes two auxiliary-action slots. Spot buying and selling remain free, while a successful service or opportunity consumes its authored slot cost through `use_settlement_action`. The first live proof is Ashgate's explicit `ashgate_provision_bundle` command path; unavailable future actions remain visible with concrete dependency reasons.

**Reason:** Settlement visits need a small opportunity-cost layer without turning trade into a menu tax. Two slots make optional preparation compete for attention while preserving immediate commerce and a quick departure path. One explicit live action proves the content, command, UI, save, and focus seams before broader service implementation.

**Trade-off:** The first implementation is intentionally asymmetric: Ashgate has one usable logistics service while other settlements preview disabled future opportunities. This creates honest scaffolding without pretending unfinished systems are interactive.

## ADR-020: Accepted contracts freeze terms and resolve through the command boundary

**Decision:** The first delivery contract is an authored Ashgate-to-Reedwatch water relief commitment. Acceptance copies its economic terms into serializable active state and consumes one visit slot without creating cargo. Arrival attempts deterministic resolution after route incidents: sufficient on-time cargo completes the contract, partial cargo remains actionable, and overdue contracts fail with a bounded cash penalty while leaving cargo available for spot trade.

**Reason:** A contract should change cargo and route planning without becoming a generic quest engine or invalidating normal market trade. Frozen terms protect active commitments from content changes, while command-driven completion and failure make every mutation testable and replayable.

**Trade-off:** The alpha exposes one fixed contract and one active-contract summary rather than a broad contract board. Automatic arrival resolution is convenient, but it means route incidents are resolved before delivery and can force a visible local recovery purchase.

## ADR-021: The first travel event pauses arrival with a bounded choice set

**Decision:** Implement `gatekeepers_chalk` as the first deterministic travel decision on the Toll Road. Eligible journeys use a saved trigger roll and freeze the route, destination, exposed cargo basis, and three authored choices in `pending_event`. The caravan pays the normal route costs but remains at its origin until `resolve_event` applies one choice and completes arrival. Paying costs six ashmarks, detouring costs one provision and one day with a disclosed 25% one-unit cargo risk, and waiting costs one day but is always available.

**Reason:** Travel needs a real decision rather than only a passive cargo-loss roll, but the first event seam must remain narrow, testable, and recoverable. A saved pending event supports exact replay and mid-event saves, while an always-available wait choice prevents low-money/low-provision soft locks.

**Trade-off:** Eligible Toll Road journeys that trigger this event do not also roll the generic route incident. The first event is one-time per campaign and uses explicit core resolution rather than a generic effect interpreter; later events must reuse this seam unless an ADR justifies extending it.

## ADR-022: The Cinderford span stores one visible route condition

**Decision:** Implement `span_at_cinderford` on the Old Road as the first cargo-to-infrastructure event. Carrying at least two scrap/charcoal units makes the event relevant. The player may sell two units for immediate cash, reserve them and one day for a ten-point route-risk reduction, carry measurements for one provision/day and a five-point reduction, or spend a day returning to the origin with cargo intact. A successful public outcome stores one bounded `route_conditions[old_road]` snapshot that directly modifies the same route record used by forecasts and resolution.

**Reason:** The second event must make preparation materially different from Gatekeeper's Chalk and prove that a travel decision can change a later trade plan. Repair cargo now competes between immediate margin and public route safety, while the saved route condition keeps the consequence visible, deterministic, and reusable without introducing a generic project engine.

**Trade-off:** The alpha route graph does not yet connect Cinderford directly, so the bridge crew appears on the infrastructure-heavy Old Road corridor and the condition is named for their town. Only one active condition is stored per route; stacking, deterioration, project stages, and competing private conditions remain future explicit slices.

## ADR-023: Shortage settlement choices reuse market memory and contract resolution

**Decision:** Implement `last_clean_barrel` as a crisis-stage arrival decision at Reedwatch or Brine Cross when at least two water units are carried. Event selection freezes two water units, the destination price, and a six-ashmark per-unit emergency premium. Premium sale and fair distribution both record ordinary delivery pressure; fair distribution additionally adds two points to a bounded `settlement_resilience` value. A contract-only choice preserves cargo and delegates to the existing arrival contract resolver, while keeping the barrels sealed is always available.

**Reason:** The Desperate Settlement template must change the next market decision rather than attach moral prose to an ordinary sale. Reusing market memory makes released water soften scarcity consistently, frozen pricing protects replay, and a small visible resilience state records the non-cash public outcome without creating a general settlement simulation.

**Trade-off:** Resilience is currently a visible bounded campaign fact but does not yet modify prices, services, or crisis transitions; those effects require explicit later rules. The event handles water only in its first version, and eligible journeys replace rather than stack with another travel event.

## ADR-024: Suspicious escort risk reuses the exposed-unit model

**Decision:** Implement `three_riders_no_banner` on exposed Old Road and Dry Cut journeys carrying at least 70 ashmarks of destination-valued cargo. Paying ten ashmarks or trading one medicine guarantees passage; refusing uses a saved 45% roll against the same disclosed one-unit loss basis as route incidents; waiting one day guarantees safe arrival and records the stable information lead `three_riders_sponsor_mark`.

**Reason:** The fourth canonical event needs valuable cargo—not a generic random encounter—to create the decision. Reusing the calibrated exposed-unit model keeps the risky refusal legible, while the medicine alternative and information-bearing wait make cargo composition and patience useful without requiring combat, a hidden reputation mutation, or an unfinished crew system.

**Trade-off:** A triggered escort scene replaces the generic route incident, so a policy that always buys escort can reduce realized variance compared with the pre-event forecast. Known information is currently displayed as a lead count and saved for later faction/contact content; it has no hidden mechanical bonus yet.

## ADR-025: Nara improves forecast confidence without changing route odds

**Decision:** Nara Vey is recruited in Ashgate for twenty ashmarks and one visit slot, then assigned or refreshed for one visit slot. Assignment records same-day notes for routes leaving the current settlement. The departure forecast distinguishes unavailable, stale, and `Nara-informed` reports and displays her authored route note alongside the unchanged numeric risk.

**Reason:** The first crew member must visibly change planning while preserving honest uncertainty. A dated report gives Nara a concrete, testable job and a real visit-budget cost without introducing hidden modifiers, morale, a skill tree, or a second travel resolver.

**Trade-off:** Nara does not lower risk and her reports expire as soon as the day advances. This makes assignment a recurring opportunity-cost decision; later crew or relationship work may extend report life or add event choices only through explicit content and commands.

## ADR-026: Jorun's logistics plan changes provisions, not travel time

**Decision:** Jorun Pale uses the existing recruit/assign/report lifecycle. A same-day Jorun report reduces provision consumption for a covered route by one, with a hard minimum of one provision, while route duration, fee, risk, incidents, and event selection remain unchanged. Forecast and travel resolution call the same `route_provision_cost` helper.

**Reason:** The quartermaster needs an observed logistics effect that changes route viability and competes with Nara's information role. Separating provisions from elapsed days makes the benefit legible without silently accelerating the crisis clock or weakening route danger.

**Trade-off:** The current Ashgate routes already cost one provision, so Jorun's saving becomes material after reaching Reedwatch and planning the two-day Dry Cut. Reports remain same-day and only one crew member can be assigned at a time.

## ADR-027: Tess unlocks an explicit event response with a named political cost

**Decision:** Tess Oryn uses the shared recruit/assign lifecycle and adds one crew-gated choice to Gatekeeper's Chalk. `challenge_chalk_ledger` is always visible, requires Tess to be assigned, costs one day, preserves route resources and cargo, records an invented-tolls information lead, and changes Warden standing by minus one through a bounded reputation helper.

**Reason:** A fixer should change an actual negotiation rather than add an invisible percentage bonus. Keeping the unavailable choice visible teaches Tess's role before recruitment, while the named relationship cost makes the option a tradeoff rather than a universally superior replacement for paying or waiting.

**Trade-off:** Tess currently changes one event only; broader contract and market negotiation hooks remain later slices. Her Warden penalty now feeds the explicit B7 threshold rather than a hidden global modifier.

## ADR-028: Warden recognition discounts one official route

**Decision:** Bound Ash Warden standing from -10 through +10 and define one threshold at +2. Below it, the caravan is `Unregistered` and pays the authored Toll Road fee. At or above it, `Recognized carrier` status discounts that route by three ashmarks. Buying Warden ration packs and paying the Gatekeeper's posted toll each grant +1; Tess's ledger challenge grants -1. The UI shows value, tier, threshold, effect, and the official-visibility tradeoff.

**Reason:** Faction alignment needs a practical commerce consequence with named causes and counterweight. A single official-route discount is easy to understand and test, composes with route forecasting and resolution, and does not make Warden standing a universal price bonus.

**Trade-off:** Official visibility is currently a disclosed narrative cost rather than a second mechanical penalty. Only the Toll Road changes, and the Free Caravan counter-path is modeled separately rather than as a shared generic discount.

## ADR-029: Free Caravan standing discounts the exposed road without reducing risk

**Decision:** Add a parallel bounded Free Caravan threshold at +2. `Known road-sharers` pay two fewer ashmarks in Old Road guide and camp fees, while its cargo-risk percentage remains unchanged. Fair distribution at The Last Clean Barrel and preserving the Three Riders' sponsor mark each grant one named standing point.

**Reason:** The first political choice needs a viable counter-path to Warden recognition. The Caravan benefit rewards public supply and shared intelligence on an informal corridor, whereas Wardens reward paid official participation on the Toll Road.

**Trade-off:** The current benefits are route-specific fee discounts and can coexist if the player earns both; they are not exclusive ideology locks. The Old Road remains exposed, and faction conflict, access restrictions, and stronger consequences remain later work.

## ADR-030: Arms enter as optional commerce with bounded visible escalation

**Decision:** The first arms proof will add one sealed, regulated, high-value cargo type and a visible `arms_escalation` track from 0 through 6. Every sale names its buyer, payout, escalation/faction deltas, next threshold consequence, and a viable non-arms alternative. Thresholds may alter a specific route fee/risk or service, but never introduce combat or close all recovery paths.

**Reason:** Arms can deepen the region's politics only if they remain part of the trading game. A bounded, previewed state with explicit counterplay lets the player compare immediate margin against future access without turning weapons into mandatory progression or a hidden morality meter.

**Trade-off:** The first implementation will support one arms good and one buyer rather than a broad weapons economy. Non-arms parity and recovery are release gates, so profitable arms tuning may be constrained even when fiction suggests a larger premium.

## ADR-031: The first arms sale crosses one visible inspection threshold

**Decision:** Add `sealed_arms_crate` as the sole arms-tagged good and one Ashgate Cinder Rider broker offer. Buying remains an ordinary cargo transaction; selling one crate through the named opportunity pays 82 ashmarks, consumes one visit slot, raises arms escalation by two, and lowers both Warden and Free Caravan standing by one. At escalation two, carrying another arms crate on the Toll Road adds a visible five-ashmark inspection surcharge. The result names Reedwatch Water Relief as the non-arms alternative.

**Reason:** This is the smallest end-to-end proof that immediate arms profit can create a future commercial cost. It reuses cargo, settlement actions, reputation, route preview, and save boundaries without adding combat or a generic political scripting engine.

**Trade-off:** The arms crate has flat ordinary-market pricing so its special broker offer—not generic arbitrage—carries the premium. The first threshold affects one route only, and de-escalation actions remain the next implementation slice required by the contract.

## ADR-032: Arms escalation recovers through a costly public audit

**Decision:** Add `Fund a public manifest audit` as the first de-escalation action. It is available in Ashgate only when escalation is above zero and costs twelve ashmarks, one day, and one visit slot to reduce escalation by one and record `public_manifest_audit` as known information.

**Reason:** Arms pressure must be recoverable through a named non-combat action whose opportunity cost is clear. A public audit directly counters hidden manifests while preserving the profit already earned and the historical record of the sale.

**Trade-off:** Recovery is deliberately slower than escalation: one sale adds two while one audit removes one. Additional material-based recovery and high-stage consequences remain future work.

## ADR-033: The first ending requires relief, resilience, and restrained arms pressure

**Decision:** Drive crisis stages from authored day thresholds at days 1, 4, 7, and 10. At stage 3, award the first ending, `open_routes_relief`, only when the Reedwatch relief contract is completed, Reedwatch resilience is at least two, and arms escalation is at most one. Save the ending ID and summary permanently and display the current stage objective and reached ending in the settlement UI.

**Reason:** A campaign proof needs a reproducible regional outcome built from previously visible trade, event, and political decisions. The predicate rewards delivery, public supply, and escalation recovery without inventing a separate score or requiring combat.

**Trade-off:** This implements one ending only. Players who reach day ten without the predicate remain in the decision stage and may continue trading; additional endings and richer world-state summaries remain later slices.

## ADR-034: Primary screen transitions restore predictable focus

**Decision:** Opening the Settlement Shop focuses the cargo selector, opening the Departure Desk focuses the destination selector, a pending route event focuses its first enabled response, and a completed journey focuses `Enter settlement`. Returning with `ui_cancel` restores the shop target. Focus changes occur only at these navigation boundaries, not during ordinary forecast refreshes.

**Reason:** Mouse, keyboard, and controller players need the same primary path without guessing which control owns input after a layer change or dynamically rebuilt event card. Explicit transition focus is small, deterministic, and regression-testable.

**Trade-off:** Godot's default directional traversal still determines movement between controls, and disabled-choice explanations remain visible text rather than focusable controls. A manual controller and assistive-readability audit is still required before external alpha distribution.

## ADR-035: Save files are validated before replacing the active campaign

**Decision:** Every successful player command writes the current versioned state to a temporary file, preserves the previous primary as one backup generation, promotes the completed write, and exposes a concise autosave summary. Manual Save uses the same writer. Load parses into a separate candidate world, applies migrations and normalization there, and swaps the live world only after validation succeeds. If the primary is invalid, Load attempts the backup; unrecoverable missing, malformed, or future-version files leave the current run untouched and produce a visible recovery message.

**Reason:** External playtests need recoverable progress and useful bug context without allowing a damaged file to destroy a playable in-memory run. Candidate loading also keeps migration and sanitization inside the simulation boundary rather than duplicating them in UI code.

**Trade-off:** The prototype currently maintains one primary slot and one backup generation rather than a save browser or journaling system. Campaign saves intentionally exclude device-specific accessibility and input preferences.

## ADR-036: Accessibility options change presentation, never simulation

**Decision:** Restore controller A/B bindings alongside keyboard Accept/Cancel, expose a 25% large-text option, place long Shop and Departure rails in vertical scroll containers, and offer reduced travel motion. Large text and reduced motion are session presentation preferences and do not enter campaign state or command history.

**Reason:** The alpha's core route can be made substantially more usable without introducing a settings framework into the deterministic simulation. Scrollable rails let text reflow instead of clipping, while reduced motion preserves immediate access to the same resolved outcome.

**Trade-off:** Preferences are not persisted yet, directional focus still relies on Godot's default traversal, and physical-controller/high-DPI verification remains a manual release gate.

## ADR-037: Ending selection is ordered and supports faction-specific conclusions

**Decision:** Replace the singular runtime ending record with an ordered `crisis.endings` list. `open_routes_relief` remains first and wins if its contract/resilience predicate overlaps another ending. `ending_warden_reserve` resolves at crisis stage three when Warden standing is at least three and Free Caravan standing is at most one. `ending_free_caravan_routes` resolves when Free Caravan standing is at least two and Warden standing is at most one. `ending_ash_merchant` resolves with at least 220 ashmarks and Reedwatch resilience at one or lower. All four require arms escalation at one or lower.

**Reason:** The campaign roadmap requires distinct viable conclusions from different trade and relationship strategies. Regulated medicine trade plus Warden logistics produces controlled access, route information plus public water sharing produces an independent-road outcome, and repeated arbitrage plus a scarcity-premium sale produces a profitable but uneven recovery. None requires a new subsystem or makes arms mandatory.

**Trade-off:** All four concept-manifest ending directions now have runtime counterparts, although their IDs and exact thresholds remain specific to this compact alpha. Ending predicates remain explicit core branches rather than a generic expression interpreter, and earlier authored outcomes have deliberate precedence when predicates overlap.

## ADR-038: Endings resolve after the complete player command

**Decision:** Day advancement inside travel, event responses, and settlement actions updates crisis stages but defers ending evaluation. The command recorder evaluates endings only after every cost, event choice, arrival effect, contract resolution, reputation change, and resilience change from that command is complete. Direct test/setup calls to `advance_day` retain immediate evaluation by default.

**Reason:** A day-ten route event can change the very values that select an ending. Recording an immutable result at the midpoint of travel would ignore the player's final choice and could produce a summary contradicted by the completed command.

**Trade-off:** Callers that compose a state-changing action outside `MarketCommandProcessor` must explicitly decide whether to defer evaluation. Production mutation remains command-boundary only, and the regression suite covers a day-ten choice that changes the winning ending.

## ADR-039: Crisis stages visibly alter route economics

**Decision:** Each post-opening crisis stage carries authored route effects. Thin Wells adds five risk points to the Old Road; Empty Reservoir raises that to ten and adds two ashmarks to the Toll Road; Settlement Decision raises Old Road exposure by fifteen points and the official toll by four. These effects compose with saved repairs, faction discounts, and arms inspections in the single `world.route` projection used by forecasts and travel.

**Reason:** Price inflation alone does not make the regional crisis legible at the travel decision. Named route pressure makes late-campaign margins and safety visibly different while preserving one authoritative calculation path.

**Trade-off:** Crisis pressure currently changes only the Old Road and Toll Road. Dry Cut remains the authored high-provision alternative until its settlement links and late-crisis role receive a dedicated slice.

## ADR-040: Thin Wells activates Brine Cross's cistern queue

**Decision:** `brine_cross_cistern_queue` becomes available at crisis stage one. It costs one visit slot and one day, adds one bounded Brine Cross resilience point, and records the durable `brine_pump_failures` lead. The action is one-time per campaign and remains visible with its stage or completion reason when disabled.

**Reason:** Crisis progression needs to change a settlement decision as well as prices and routes. Waiting at the queue trades time for public capacity and information, making Brine Cross more than a resale destination without creating a separate investigation system.

**Trade-off:** The pump-failure lead is currently a visible campaign fact rather than a prerequisite for another contract. Cinderford, Hollow Market, and Reedwatch still need their own non-event settlement actions before all five locations meet the full identity target.

## ADR-041: Hollow Market and Reedwatch opportunities change future travel and crisis state

**Decision:** Activate two one-time settlement actions through the same explicit civic-action resolver. Hollow Market sells `dry_cut_water_cache` for six ashmarks and one visit slot, applying a saved five-point Dry Cut risk reduction. Reedwatch opens a supply shelter only after completed water relief and crisis stage one, spending one day/slot to add one resilience, one Free Caravan standing, and a durable information lead.

**Reason:** Settlement identity must affect the next trade, route, or regional decision. Hollow Market now sells actionable uncertainty reduction, while Reedwatch lets completed relief become local infrastructure instead of ending at a payout message.

**Trade-off:** Both actions are deliberately one-time and explicit. Their information IDs remain visible records rather than inputs to a generic quest graph, and Cinderford remains the final inaccessible/non-interactive settlement gap.

## ADR-042: Cinderford is an explicit Toll Road stop

**Decision:** Keep the three canonical route IDs, but allow a route to declare validated point-to-point segments. The Toll Road now supports Ashgate–Cinderford and Cinderford–Brine Cross segments at six ashmarks each, plus the existing twelve-ashmark Ashgate–Brine Cross through passage. Cinderford's one-time repair bench costs fourteen ashmarks, one day, and one visit slot to record its ledger and reduce Toll Road risk by three points.

**Reason:** Cinderford was drawn and authored as a settlement but could not be selected, leaving the five-settlement promise false. Segment profiles make the existing map stop playable without inventing a fourth route type or charging the full corridor fee for half a journey.

**Trade-off:** Segment travel shares the Toll Road's faction, crisis, arms, crew, and event rules. Segment-specific narrative variants and different provision costs remain future content rather than a second routing engine.

## ADR-043: Ending progress is visible before the deadline

**Decision:** The Settlement Shop includes a compact campaign-outlook block that names all four conclusions and shows live progress toward their contract, resilience, faction, arms, and money thresholds. At an ending, it collapses to the recorded title while the separate conclusion card provides the full regional summary.

**Reason:** A deterministic ending is not a meaningful player goal if its predicate is only visible in code or documentation. Showing exact thresholds lets the player intentionally pursue or avoid a political/economic outcome before day ten.

**Trade-off:** The outlook is intentionally numeric and compact for the alpha. It does not predict future event availability or recommend a morally preferred ending.

## ADR-044: Pause never bypasses a committed route decision

**Decision:** Add a modal pause layer available through P/controller Menu from gameplay. Escape/controller B remains Back only during uncommitted departure planning; in the Shop, a route event, or an arrival report it opens Pause. Resume restores the prior focused control, and the menu offers Save, validated Load, and Return to main menu.

**Reason:** A consistent pause path is required for external testing, but Cancel must not silently escape a paid route event or mutate the campaign. Separating navigation Back from modal Pause preserves both expectations.

**Trade-off:** Runtime remapping and persisted accessibility preferences remain future work. Returning to the main menu relies on the current autosave/manual-save system rather than an unsaved-changes confirmation dialog.
