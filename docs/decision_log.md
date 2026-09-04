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

**Decision:** Launch to a minimal main menu with one `Start Game` action. Starting a game creates a fresh, deterministic Ashgate day-one state with 120 ashmarks, twelve provisions, empty cargo, and the initial Water-to-Reedwatch/Old Road forecast selected. The market screen exposes one optional, single-use `Test action: Buy 2 water` control that executes the normal explicit buy command; departure remains the player’s decision.

**Reason:** The project needs a frictionless external-playtest entry point that demonstrates the game’s core trade decision without introducing a tutorial contract, scenario system, or parallel simulation path. The preset makes the intended first decision reproducible for observation and regression testing.

**Trade-off:** This is an intentionally narrow test loop rather than a complete campaign start, save/load menu, or onboarding flow. The guided button is a temporary playtest affordance and must remain an ordinary command invocation rather than a special reward or hidden state mutation.

## ADR-012: Optional objective ladder with a player-selected route

**Decision:** Refine the quick playtest with a visible three-step objective: inspect the water forecast and buy two units, choose a route and reach Reedwatch with water, then sell the water. The proposed load is included in the route's exposed-cargo calculation even before purchase. The screen reports completion only after the normal sale command succeeds. The test action remains optional, and the player may choose another cargo, destination, route, or continued trading.

**Reason:** The earlier menu established a working entry point but did not make its test purpose, completion condition, or next action sufficiently visible. A compact objective ladder lets a new player recognize the core loop and identify whether the market explanation, forecast, and realized transaction are coherent.

The objective is presentation state derived from serialized successful buy/sell commands, not a second campaign progression field. This keeps save/load deterministic, prevents the one-use helper from reappearing after load, and lets lost or spent teaching cargo produce a recoverable explanation without changing simulation rules.

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

**Decision:** Opening the Settlement Shop focuses the cargo selector, opening the Departure Desk focuses the destination selector, a pending route event focuses its first enabled response, and a completed journey focuses `Enter settlement`. Returning with `ui_cancel` restores the shop target. Main Menu, Shop, Departure, Pause, and enabled event responses expose explicit cyclic focus order; rebuilt dynamic cycles omit disabled actions. Focus changes occur only at navigation/command boundaries, not during ordinary forecast refreshes.

**Reason:** Mouse, keyboard, and controller players need the same primary path without guessing which control owns input after a layer change or dynamically rebuilt event card. Explicit transition focus is small, deterministic, and regression-testable.

**Trade-off:** Disabled event choices cannot receive focus, so their prerequisites are repeated as persistent text directly below the control; a manual controller and assistive-readability audit is still required before external alpha distribution.

## ADR-035: Save files are validated before replacing the active campaign

**Decision:** Every successful player command writes the current versioned state to a temporary file, preserves the previous primary as one backup generation, promotes the completed write, and exposes a concise autosave summary. Manual Save uses the same writer. Load parses into a separate candidate world, validates top-level field types, bounds, settlement/ending/contract references, the pending-event journey pair, exact current-content contract/event terms, and bounded frozen values before swapping the live world. Older content-version snapshots retain their frozen terms within structural bounds. If the primary is invalid, Load attempts the backup; unrecoverable missing, malformed, structurally invalid, forged, or future-version files leave the current run untouched and produce a visible recovery message.

**Reason:** External playtests need recoverable progress and useful bug context without allowing a damaged file to destroy a playable in-memory run. Candidate loading also keeps migration and sanitization inside the simulation boundary rather than duplicating them in UI code. The Main Menu uses the same validation path to preview day, settlement, money, and cargo before enabling Continue.

**Trade-off:** The prototype currently maintains one primary slot and one backup generation rather than a save browser or journaling system. Campaign saves intentionally exclude device-specific accessibility and input preferences.

## ADR-036: Accessibility options change presentation, never simulation

**Decision:** Expose independent runtime keyboard-key and controller-button remapping for Accept/Back/Pause. Reject keyboard modifiers, focus-navigation keys, controller D-pad directions, and any binding already claimed by another required action. Preserve the untouched input family, expose the complete current scheme in the Main Menu, and restore both default families together. Also expose a 25% large-text option, place both Shop columns and the Departure action rail in vertical scroll containers, and offer reduced travel motion. Input, large-text, and reduced-motion preferences persist in a separate user settings file and do not enter campaign state or command history. Invalid persisted binding sets fall back atomically to the complete defaults, and failed preference writes leave the choice active for the session while showing a warning.

**Reason:** The alpha's core route can be made substantially more usable without introducing a settings framework into the deterministic simulation. Scrollable rails let text reflow instead of clipping, while reduced motion preserves immediate access to the same resolved outcome.

**Trade-off:** Custom controller-axis remapping is intentionally excluded so analog sticks remain reliable navigation inputs. Physical-controller, screen-reader, and high-DPI verification remain manual release gates.

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

**Decision:** Add a modal pause layer available through P/controller Menu from gameplay. Escape/controller B remains Back only during uncommitted departure planning; in the Shop, a route event, or an arrival report it opens Pause. Resume restores the prior focused control, and the menu offers Save, validated Load, and Return to main menu. Failed load or protective-exit-save attempts keep the live campaign paused with an actionable explanation; successful load closes Pause and focuses the restored state.

**Reason:** A consistent pause path is required for external testing, but Cancel must not silently escape a paid route event or mutate the campaign. Separating navigation Back from modal Pause preserves both expectations.

**Trade-off:** Runtime remapping remains future work. Returning to the main menu relies on the current autosave/manual-save system rather than an unsaved-changes confirmation dialog, but it fails closed if that save cannot be written.

## ADR-045: Playtest reports export deterministic evidence without identity data

**Decision:** Add an `Export playtest report` action to the Shop and Pause menu. It produces one JSON report containing the app/content/save versions, packaged build/run, platform, broad last-input type, active keyboard/controller action mappings, actual desktop/browser window dimensions and display scale, presentation settings, session/first-trade timing, seed, location/resources, crisis/faction/escalation/resilience state, contracts, events, route conditions, information, crew, ending context, bounded command history, and game log. It contains no player name, account, controller identifier, or network data and does not mutate campaign state. Desktop builds write the report to the Godot user-data directory; Web builds invoke a deliberate browser download. Pause-menu exports keep the overlay open and show the result.

**Reason:** External alpha reports need enough context to reproduce a problem or understand a run without asking testers to transcribe diagnostics or surrender unnecessary personal data.

**Trade-off:** Desktop builds do not yet open a native share dialog, and no build submits anything automatically. Testers must deliberately attach the locally written or browser-downloaded file.

## ADR-046: The regional map selects destinations instead of placeholder cells

**Decision:** Settlement markers on the route map are clickable planning controls. A directly connected marker selects the matching destination and legal route without committing resources; the current settlement and unreachable settlements explain why no journey was selected. Markers also identify the caravan's current location and each settlement's resilience. After route commitment, map selection and planning controls remain locked until the event and arrival report are complete.

**Reason:** The alpha's primary map should support the trade-and-travel decision rather than expose a future-editor placeholder interaction. Reusing the authoritative destination list keeps map clicks equivalent to the Departure Desk selector.

**Trade-off:** Keyboard and controller planning continues through the adjacent destination selector, which has clearer focus behavior than making every drawn marker a custom focus target. The grid remains a restrained visual scaffold rather than a free-movement system.

## ADR-047: Web builds expose a minimal assistive and verification state

**Decision:** The Web UI publishes a small state object containing screen, presentation, settlement/event, planning, and coarse resource context. The same update maintains a visually hidden polite ARIA status region and a descriptive canvas label for major screen transitions. Browser automation waits on this state before capturing evidence.

**Reason:** Godot 4.4 does not expose a native per-Control accessibility tree in this project, while timing-only browser tests can mistake a focus-ring change for successful navigation. A narrow Web bridge improves screen-change announcements and makes packaged evidence deterministic without moving gameplay rules into JavaScript.

**Trade-off:** This is not full control-level screen-reader support, and the exposed state deliberately omits identity, hardware, and detailed history. Manual assistive-technology testing remains an alpha gate.

## ADR-048: Web primary actions have a semantic HTML mirror

**Decision:** The Web build mirrors each active screen's primary and safety-critical buttons, generated Shop actions, planning fields, and presentation settings into a visually hidden HTML region. Each mirror entry preserves its current label, value or enabled state, and concise description and invokes the corresponding Godot control; existing UI handlers and the command processor remain the only gameplay mutation path. The mirror follows each screen's visual control order, becomes visibly discoverable when browser focus enters it, and preserves focus across state-driven DOM rebuilds, while the canvas keeps its application role, current-screen label, and live-region description.

**Reason:** A canvas-only interface can announce screen changes but cannot expose actionable controls to browser accessibility APIs. A bounded mirror makes Start/Continue, trade, contracts, settlement opportunities, crew, departure, event, arrival, Pause, destructive-confirmation, planning, and presentation controls discoverable and operable without duplicating simulation rules in JavaScript.

**Trade-off:** Browser keyboard remapping now uses the semantic HTML action region and the same Godot validation path, including modifier-aware shortcut rejection and Escape cancellation, but physical controller remapping still requires a real device. Browser automation verifies and operates the mirrored actions, planning fields, presentation checkboxes, and keyboard remapping through the minimum-viewport journey; hands-on screen-reader and broader browser-shortcut testing remain required before claiming full control-level accessibility.

## ADR-049: The caravan is the persistent travel viewpoint

**Decision:** Replace the route map's anonymous dot with a readable caravan silhouette and explicit `AT REST`, `MOVING`, `ENCOUNTER`, and `ARRIVED` presentation states. Move the key caravan resources into the side rail, while the regional network remains the central stage and the right rail changes from planning to encounter and arrival details. Encounter travel stops at a fixed visual point; command results remain the only authority for costs, events, and destination changes.

**Reason:** The player needs to understand that one persistent caravan connects settlement trade, travel risk, crew, and the regional crisis. Frontier's repeatable settlement-to-navigation-to-road-to-arrival path makes the initial vertical slice easier to read and gives every journey a visible middle instead of jumping directly from commitment to an event or destination.

**Trade-off:** This first pass uses a code-drawn silhouette, one road scene, and one fixed encounter stop rather than multiple biomes, caravan modules, or a freely pannable map. Those additions should only arrive with new trade, travel, or negotiation decisions; this decision does not create a combat subsystem.

## ADR-050: Settlement interaction is organized as a bazaar directory

**Decision:** Present each settlement as a repeatable bazaar hub with direct entries for Trade, Jobs, Services / Intel, Crew, Outlook, and Departure. Keep the default settlement summary compact, hide the full campaign outlook until requested, and route every entry to the existing command-backed controls rather than duplicating actions.

**Reason:** Showing market details, campaign goals, contracts, local services, crew, save tools, and departure guidance at once makes the settlement feel like a report. A stable directory makes the place feel inhabited and teaches a reusable navigation path without obscuring the economy.

**Trade-off:** The alpha uses typographic stall buttons rather than illustrated characters or a spatial bazaar scene. Character art and richer stall presentation can replace those buttons later without changing the underlying actions or navigation contract.

## ADR-051: Bazaar stalls replace the active work surface

**Decision:** Keep Trade as the default settlement action, but make the five Bazaar directory buttons the first navigation layer. Selecting Jobs, Services / Intel, Crew, or Outlook hides the market ledger and transaction row, shows only that stall's authoritative actions, and presents a settlement-tinted illustrated row of keepers with the active stall emphasized. Departure remains pinned and available from every stall.

**Reason:** A directory that leaves the entire trade form visible still reads as one dense report. Replacing the work surface gives each visit action a legible place, makes the Bazaar feel inhabited, and preserves the repeatable Trade → stall → Departure rhythm without creating new simulation state.

**Trade-off:** The keepers are deliberately code-drawn silhouettes rather than final character art, and the scene is not a free-roaming environment. It can later receive authored portraits or settlement art without changing commands, save data, input flow, or accessibility semantics.

## ADR-052: Every route has a stable in-between visual identity

**Decision:** Render the Old Road, Toll Road, and Dry Cut as distinct side-on travel environments derived from their stable route IDs. Each scene names its corridor and current travel beat, keeps the origin and destination visible as horizon anchors, and repeats the route's authored risk description. The Old Road uses ruined milestones, the Toll Road uses maintained paving and inspection posts, and the Dry Cut uses exposed saltwind ridges and navigation markers.

**Reason:** A mandatory road stop is only meaningful if the player can recognize which road they chose and connect its atmosphere to the disclosed tradeoff. Frontier's useful lesson is the repeated sense of leaving one place, occupying transit, and approaching another—not a generic loading screen.

**Trade-off:** Route scenes remain lightweight code-drawn presentations and share one caravan camera. They add no new random rolls, intermediate map nodes, travel commands, or simulation state; authored roadside locations should only become gameplay nodes when they support a real trade, information, or event decision.

## ADR-053: Every settlement has a stable Bazaar identity

**Decision:** Keep the same five-stall Bazaar directory in every settlement, but render a stable location-specific backdrop and caption from the settlement ID. Ashgate uses its Warden gate, Brine Cross its salt pans and cistern frame, Cinderford its forge stacks and span, Hollow Market its rumour lanterns, and Reedwatch its reeds and watched water store. The scene remains visible as a compact identity strip during Trade and expands when another stall is opened.

**Reason:** The repeatable Frontier-inspired loop needs both familiarity and a sense of arrival. Keeping navigation fixed lets players build muscle memory, while a distinct place silhouette makes travel feel like movement between actual markets rather than a text swap on one universal screen.

**Trade-off:** These are restrained code-drawn landmarks rather than final environment art. They add no settlement state or gameplay rules; future authored art should preserve the stable scene IDs, captions, action order, and compact-versus-expanded layout contract.

## ADR-054: First-run guidance is a persistent campaign layer, not a scenario menu

**Decision:** Replace the visible QA-path selector with a conventional New Game flow: three illustrated introduction cards followed by an optional two-journey tutorial. The tutorial observes authoritative world state and command history, recommends existing Bazaar and travel actions, and stores only presentation progress beside the serialized world in a versioned save envelope. Debug builds retain the deterministic QA fixtures behind Ctrl+Shift+D; release-facing navigation never advertises them.

**Reason:** A strong vertical slice must teach the caravan, trade, contracts, roads, recovery, crew, and regional consequences as one coherent campaign. Visible test scenarios make the opening read like a harness and divide learning into artificial starts, while a state-derived guide can survive saves and reasonable mistakes without bypassing simulation rules.

**Trade-off:** The introduction and environments currently use deliberate code-drawn illustration with stable scene identities rather than final raster art. Tutorial completion is per campaign save rather than a profile-wide preference, and skipping guidance is explicit but does not suppress future authored onboarding across all saves.

## ADR-055: Ordinary trade is authored as a renewable source-to-need loop

**Decision:** Give every runtime settlement explicit produced goods, consumed goods, and an ordinary-market thesis. Recent-delivery pressure decays at a role-specific rate: consumer needs replenish faster, neutral markets use baseline recovery, and producer markets retain added supply longer. The Bazaar presents source, need, spread, route burden, risk, and expected net before detailed price factors, and labels the path as requiring no contract. Deterministic gates keep staple, repair, medicine, and industrial fixtures profitable and require the best ordinary opening to retain at least 70% of the opening relief contract's expected net value.

**Reason:** Contracts and authored scenarios should change the caravan's commitments and consequences, not rescue an otherwise insolvent economy. A stable renewable baseline gives players a reason to read places and revisit markets while leaving crisis, faction, event, and market-memory state free to create volatile opportunities.

**Trade-off:** The five-node slice still uses fixed authored profiles rather than capacity-limited production inventories or a continuous population model. Replenishment changes only recent-delivery pressure, so later adaptive-basin work must introduce replacement actors and changed access through explicit world state rather than hiding them inside price formulas.

## ADR-056: Missed relief creates the Well Commons instead of resetting the offer

**Decision:** Model Reedwatch relief as a serialized scenario state machine. The offer remains optional through Day 3. On Day 4, an ignored offer expires; an accepted but overdue offer becomes delayed and later records formal failure. Either unmet path activates the Well Commons exactly once, adds one Reedwatch resilience, closes the stale contract offer, lowers the local water multiplier, and raises the local charcoal multiplier enough to create a new contract-free trade. Completed relief resolves the scenario without activating the response.

**Reason:** Expiry should be a world transition rather than a failed player test. The same unmet water need gives local organizers material legitimacy and creates new trade geometry, making the player's omission visible and playable without blocking the Bazaar, roads, or other systems.

**Trade-off:** Feed B exposes the Commons as a replacement actor and market condition but does not yet add relationship scores or direct faction actions. Feed C must add at least two cooperation paths and one bypass or opposition path while keeping ordinary trade open.

## ADR-057: Commons support modifies a market but never gates it

**Decision:** Represent interaction with the emergent Well Commons as bounded support stored on its existing response record. Two cooperation actions exchange cargo or resources for resilience, route information, and support; a Warden permit provides a negative-support bypass. Support scales the already-authored water and charcoal response but never disables spot buying, selling, or travel. Distinct one-time interaction IDs prevent farming, and later cooperation can reverse opposition.

**Reason:** A replacement faction should be a relationship the player can use, resist, and reconsider—not a second mandatory quest chain. Reusing settlement actions and ordinary cargo keeps the interaction inside the established Bazaar loop.

**Trade-off:** Support currently changes one local market response and is summarized as a signed value rather than a dedicated faction screen. Feed D should compare its total economic value against contracts and ordinary trade before more rewards are authored.

## ADR-058: Cross-path rewards remain a visible vector

**Decision:** Evaluate ordinary trade, contracts, civic work, and replacement-faction work in a deterministic ten-minute fixture that reports ashmarks, provisions, hold commitment, standing, time, and visit slots separately. Tune Reedwatch Water Relief to 180 ashmarks, placing its expected net at 100 against the best ordinary opening's 99, with an authored acceptable band of 100–120%. Present the contract vector on the Job Board and preserve civic resilience and Commons support as named non-cash outcomes rather than converting them into a synthetic currency.

**Reason:** A contract should compensate the player for reduced flexibility and a visit-slot commitment, but a dominant cash premium would quietly turn the open economy back into a quest ladder. Separate dimensions make the real tradeoff legible and executable.

**Trade-off:** The fixture compares representative paths rather than claiming that one standing point or resilience point has a universal ashmark value. Feed E can now compose these durable non-cash outcomes into alternate endings without changing the currency model.

## ADR-059: Post-failure ordinary trade can define the regional ending

**Decision:** Add `The Wells Belong to Those Who Carry` ahead of the broad faction endings. Eligibility requires Reedwatch relief to expire or fail, the Well Commons to be active with positive support, Reedwatch resilience of at least two, contained arms escalation, and at least four charcoal sold into Reedwatch after Commons activation. Qualifying spot deliveries accumulate in the serialized Commons record; contract and event transfers do not count, and the bounded market-history log is not authoritative for ending eligibility.

**Reason:** The adaptive-basin promise is incomplete if the replacement actor changes prices but disappears from the final verdict. Requiring a real post-activation market delivery and direct support makes the ending emerge from the same Bazaar → road → arrival loop as the rest of the game.

**Trade-off:** This adds a fifth ending and gives it priority over the generic Free Caravan outcome when both qualify. The delivery threshold is deliberately narrow and should be revisited only with playtest evidence, not converted into a hidden score.

## ADR-060: The desktop shell fits the display and reflows its opening panels

**Decision:** Keep the authored 1600×900 desktop preference on displays that can contain it, but clamp the initial window to the current screen's usable area before constructing the interface. Retain the 1280×720 logical canvas for deterministic rendering and reflow the Main Menu and Introduction into stacked illustration-and-card compositions at the 960×540 minimum window. Bazaar, Departure, road, event, and arrival retain their established two-column decision surfaces, with deterministic capture assertions proving their required panels and primary actions stay inside the active layer.

**Reason:** A preferred window larger than the available desktop can make an otherwise valid layout appear clipped before the player can resize it. The opening screens also need an intentional minimum-window composition rather than relying only on uniform canvas reduction, while the denser trade and route screens remain more readable in their proven side-by-side form.

**Trade-off:** The minimum-window opening uses less illustration height and scrollable supporting copy so its primary action remains available. The simulation, command order, economy, and saved campaign state are unchanged.

## ADR-061: The Bazaar opens on one ordinary-trade decision

**Decision:** Put a compact, derived trade-plan card at the top of the Market Stall work surface. It names the selected load, source and destination need, buy and sale values, route fee, expected net, provision and risk burden, available cash, projected hold use, and the immediate next action. Focus opens on the enabled Buy action while the detailed price explanation and editable cargo controls remain in the same scrollable ledger. Publish the same summary through the Web accessibility state.

**Reason:** The full market ledger already contained every calculation, but a first-time player had to read across status text, controls, and a long forecast to reconstruct the decision. The compact card makes ordinary trade legible before optional contracts without introducing a separate recommendation or changing any authoritative calculation.

**Trade-off:** The card summarizes one currently selected cargo-route plan and can be scrolled away when editing deeper market details. It deliberately does not rank routes, auto-buy, or claim certainty beyond the existing deterministic forecast.

## ADR-062: Presentation copy is derived outside the scene controller

**Decision:** Move Bazaar forecasts, Departure forecasts, road-event choice cards, and arrival/debrief comparisons into deterministic presenter modules. Presenters may read authoritative world state and content definitions, but they return text and availability view models only. `main.gd` continues to own Godot nodes, focus, signals, and input, while the command processor and world state remain the only mutation boundary.

**Reason:** The vertical slice now has enough decision surfaces that keeping presentation derivation inside one scene controller makes the full loop difficult to test and risky to extend. Pure presenter outputs can be regression-tested without constructing the entire scene and make later route-comparison and authored-event improvements local changes.

**Trade-off:** Presenters are still aware of the current world-state query API and authored content IDs. This is an extraction seam rather than a new domain layer; no forecast is cached, no command is issued, and no simulation rule is duplicated outside the core.

## ADR-063: Departure compares every legal itinerary before commitment

**Decision:** Add a selectable two-column itinerary board to the Departure Desk. Every legal destination-and-route pair from the current settlement remains visible, including unfavorable forecasts, and each card uses the existing economy preview to show fee, days, provisions, cargo opportunity, risk, field-confidence language, and expected net consequence. Selecting a card updates the existing destination and route controls; only the existing Commit action spends resources.

**Reason:** A route dropdown reveals one option at a time and makes the player reconstruct tradeoffs from memory. The Frontier-inspired travel loop depends on choosing a road with clear costs and consequences before leaving, so alternatives need to be comparable in one stable decision surface.

**Trade-off:** The slice compares direct legal itineraries rather than pathfinding across multiple legs. At compact sizes the board wraps to additional rows inside the existing planning scroll, while the selected detailed forecast and pinned commit action remain unchanged.

## ADR-064: Settlement identity belongs to runtime content

**Decision:** Store each settlement's Bazaar scene ID, caption, market-reading sentence, landmark type, and palette in its runtime settlement record. Validate those fields with both runtime validators and pass the record into the Bazaar renderer instead of branching on settlement IDs inside the UI.

**Reason:** Location identity must explain how a place trades as well as how it looks. Keeping the market read and visual vocabulary beside production, consumption, and price data lets a settlement arrive as one authored place and gives future locations a stable content path without editing the scene controller.

**Trade-off:** Landmark drawing remains a small supported vocabulary rather than arbitrary scene composition. New landmark families require renderer work, but new settlements using an existing family can be authored and validated entirely in data.

## ADR-065: Campaign conclusions open a causal debrief, not a score screen

**Decision:** Expand a reached ending into a deterministic campaign debrief assembled from command history, event history, final resources, relationships, resilience, and the ending summary. The debrief shows the recent route and trade timeline, names the causal lesson, proposes one ending-specific replay experiment, and offers Continue, Replay, Title, and report-export actions. Replay restarts the same authored opening and seed but explicitly treats the player's new command sequence as the experiment.

**Reason:** An ending title alone does not teach the player how market, road, event, and political decisions combined. A causal receipt closes the vertical slice and turns replay into a purposeful comparison instead of presenting a canonical winning path or implying that the seed reproduces player choices.

**Trade-off:** The compact debrief summarizes the most recent six routes and trades while the exported report retains the full bounded history. Continuing dismisses the debrief for the current session but leaves the immutable ending visible in Bazaar status and the saved campaign.

## ADR-066: The basin vertical slice ships as a provenance-bound portable alpha

**Decision:** Version the completed automated vertical slice as `0.13.0-alpha-basin-vertical-slice` and distribute its Windows build as both a standalone executable and a clean-extracted portable ZIP. The tagged build must carry exact commit/run provenance, numeric Windows resource version `0.13.0.0`, SHA-256 checksums, a packaged GUI capture, and a source snapshot. Curated full-flow screenshots record their version, viewport, state, and local real-renderer origin. The public repository release is marked as a prerelease intended for limited alpha testing, with external hardware and human-playtest gates listed explicitly.

**Reason:** A testable vertical slice needs a reproducible artifact and evidence trail, not only a passing development branch. Binding package, visuals, source, and checksums to one tag lets testers report against the exact game they ran and prevents automated coverage from being mistaken for human or storefront certification.

**Trade-off:** The portable package has no installer, signing certificate, auto-update channel, or storefront integration. Public prerelease availability does not remove the roadmap's physical-controller, assistive-technology, high-DPI hardware, antivirus-reputation, and moderated-comprehension gates.

## ADR-067: Itinerary cards distinguish a forecast plan from carried cargo

**Decision:** Every Departure itinerary card names the selected cargo plan and the quantity actually held. When the hold contains less than the forecast quantity, the card labels its net as `IF BOUGHT` and the tooltip states the exact shortfall; when covered, it labels the plan `READY`. Empty travel remains legal and the authoritative route command is unchanged.

**Reason:** A positive cargo and net forecast beside an empty hold can read as value already aboard, especially to a first-time player scanning the comparison board before the detailed load check. The route forecast is useful as a hypothetical shopping plan, but its status must be visible on the card where the value appears.

**Trade-off:** The cards gain one compact line and therefore use slightly more vertical space inside the existing scrollable planning rail. They still compare every legal itinerary and do not turn the forecast into an automatic purchase or a departure gate.

## ADR-068: Large-text itinerary cards preserve the selected-state label

**Decision:** Give itinerary cards enough additional minimum height to preserve their standalone `SELECTED` label when Large text is enabled, while leaving their normal-text height unchanged. The planning rail remains scrollable and the Commit and Return actions remain pinned outside it.

**Reason:** The 960×540 Windows evidence showed every route value but clipped the first `SELECTED` line from the active card. A focus border alone is not an adequate selection signal because route state must remain legible without relying on color or focus styling.

**Trade-off:** Large text shows less of the next itinerary row before scrolling. The full active card becomes readable, and all alternatives remain present in the same scrollable comparison board.

## ADR-069: The Bazaar presents a trade ticket before explanatory detail

**Decision:** Replace the Market Stall's paragraph-style decision summary with a structured trade ticket. Cargo and journey identity lead; buy, sell, road, and expected-net values occupy a four-column scan line; route risk, cash, hold use, source-to-need reason, and next action remain immediately below. The presenter still publishes one complete plain-text equivalent for Web accessibility and reports.

**Reason:** The 0.13.2 Bazaar exposed every required value but gave labels, tutorial copy, market prose, and route arithmetic nearly equal visual weight. A first-time player should be able to answer “what am I carrying, where, and is this worthwhile?” before reading the underlying explanation.

**Trade-off:** The ticket uses more authored presentation nodes than one Label and therefore requires explicit UI regression coverage. It does not remove the detailed market ledger, change any calculation, or make positive routes mandatory.

## ADR-070: Roadside encounters lead with a compact threat dossier

**Decision:** Present route, maximum disclosed cargo risk, exposed cargo value, authored dilemma, special frozen basis, and the no-hidden-health boundary as a compact dossier above the response list. Do not repeat the event title and setup inside the scroll rail when they are already visible in the persistent journey context and road narrative.

**Reason:** The previous event rail repeated the encounter identity and setup before a long prose stakes block. At 1280×720 this delayed the second response until below the fold even though the left road scene and persistent status already carried that context.

**Trade-off:** The detailed all-in-one stakes string remains as presentation data for regressions, while the visible rail uses several purpose-specific labels. Response cards remain scrollable and retain their complete disclosed costs, results, outcomes, and blocked prerequisites.

## ADR-071: The constrained opening stacks through 1280 pixels

**Decision:** Use the stacked illustration-and-card composition for Main Menu and Introduction at window widths up to and including 1280 pixels, while retaining the split composition at 1600×900 and larger. Add explicit horizontal card gutters, allow Introduction actions to wrap, shorten the compact Main Menu illustration, and validate every required opening copy/action against both its card and active viewport.

**Reason:** The prior 1100-pixel breakpoint left the 1280×720 Introduction action rail with almost no Large Text safety margin and allowed a bounds test to pass while checking only the outer panel and primary action. The opening should reflow before text becomes visually fragile rather than depending on clipping tolerance.

**Trade-off:** At 1280×720 the illustration becomes a wide header rather than a side-by-side scene. The richer split composition remains available at the preferred 1600×900 desktop size, and no gameplay, focus order, tutorial state, or simulation rule changes.

## ADR-072: Temporary licensed cues replace generated interface tones

**Decision:** Load three short CC0 audio resources from the versioned temporary asset kit: Kenney confirmation for successful commands, Kenney error for blocked commands, and a restrained RPG Audio creak for committed travel. Keep the existing Interface Sounds toggle and all visible feedback unchanged.

**Reason:** Generated sine tones proved the feedback hooks but sounded like diagnostics rather than a game. The licensed cues give trade and travel distinct tactile character while preserving offline operation, deterministic simulation, and explicit provenance.

**Trade-off:** These generic cues are testing assets rather than final market, coin, wagon, or faction-specific sound design. They should be replaced once the command vocabulary and final audio direction are stable.

## ADR-073: Departure dust is brief, deterministic presentation

**Decision:** Draw three palette-tinted puffs from the licensed Kenney particle kit behind the caravan during only the opening portion of `moving_out`. Derive opacity and scale from presentation progress, suppress the effect when Reduce Travel Motion is enabled, and capture the committed departure as its own visual-evidence state. Copy the selected texture into a curated runtime folder and exclude unused raw source packs from release exports.

**Reason:** The road view already communicates route, status, and progress, but the transition from a static Departure Desk to a moving caravan lacked a readable physical cue. A small dust wake makes commitment feel like departure without adding a new simulation system or obscuring the route information.

**Trade-off:** The texture is temporary generic VFX and remains deliberately subtle. The repository retains the complete source kit and licenses, while packaged builds contain only selected runtime assets. The effect carries no economic or event meaning, does not consume random state, and disappears before the player receives the next action.

## ADR-074: Successful trades receive a stamped visual receipt

**Decision:** After an authoritative buy or sell succeeds, show a short Bazaar receipt naming the realized cargo quantity, ashmark movement, and resulting hold use. Use a code-native geometric seal and restrained border rather than the temporary particle pack's lightning-like sparks. Dismiss the receipt on navigation and skip its scale/fade flourish when reduced motion is enabled.

**Reason:** The Bazaar already reports command results and updates its ledger, but the moment of exchange lacked a focused game-feel response. A compact receipt makes the transaction legible as a completed market action without making animation, color, or sound carry unique information.

**Trade-off:** The receipt briefly consumes vertical space in the Trade stall and is intentionally transient. It does not persist in saves, alter command history, or appear for blocked trades.

## ADR-075: Guide / Intel receives a restrained page cue

**Decision:** Play the CC0 Kenney `bookOpen` cue once when the player enters Guide / Intel from another Bazaar stall. Route it through the existing Interface Sounds preference and load it from an export-safe byte copy.

**Reason:** The information stall changes the player's mode from exchange to reading and investigation. A short material cue reinforces that transition without adding decorative noise to every navigation action.

**Trade-off:** The generic page sound is temporary and intentionally brief. Re-selecting the already active stall remains silent, and all information remains visible without audio.

## ADR-076: Journey consequences lead with a factual receipt

**Decision:** Place a compact receipt above the full Journey Result after an authoritative route-event response resolves. Classify the archived result as `PLAN HELD`, `RISK AVOIDED`, or `RISK REALIZED`; repeat the exposed cargo and exact roll/threshold result; and draw a static code-native crate seal with a check or slash.

**Reason:** The complete expected-versus-arrival comparison is accurate but dense, so the most important outcome can take several lines to locate at 1280×720. A concise receipt lets a player understand whether the disclosed risk landed before reading the detailed causal and recovery text.

**Trade-off:** The receipt consumes a small amount of vertical space in the already scrollable arrival rail. It adds no saved or simulation state, uses no animation, and never replaces the full textual report or its Web accessibility announcement.

## ADR-077: Completed trades use a material coin cue

**Decision:** Route successful `Purchase` and `Sale` command feedback to the short CC0 Kenney `handleCoins2` cue. Keep general success, blocked-action, travel, and information cues unchanged, and continue honoring the single persisted Interface Sounds preference.

**Reason:** A generic interface confirmation establishes success but does not make the Bazaar exchange feel materially distinct from saving, recruitment, or other commands. The brief coin-handling sound reinforces the existing stamped receipt without carrying unique economic information.

**Trade-off:** The cue remains temporary generic foley rather than final ashmark sound design. It plays only after the authoritative command and protective autosave succeed; blocked trades and save failures continue to use the warning cue.

## ADR-078: The Caravan Yard presents people before actions

**Decision:** Group each existing crew recruit/assignment action into a roster card with a distinct code-native portrait, role and availability line, personality, decision lever, and limitation. Keep all rules and command handling unchanged, and add normal/Large Text capture states for the stall.

**Reason:** The prior Caravan Yard was a stack of buttons followed by prose, which made three mechanically distinct characters read like debug actions. Stable faces and repeated information hierarchy make the hiring decision recognizable without hiding cost or consequence.

**Trade-off:** The portraits are restrained procedural illustrations rather than final commissioned character art, and the cards require scrolling to inspect the full roster at smaller windows. All three actions remain keyboard/controller reachable and Web-accessible in their authored order.

## ADR-079: Glasswind Reach extends the same trade-and-travel grammar

**Decision:** Add Glasswind Reach as a compact second region connected to Hollow Market. Author three settlements, three goods, two roads, one standing faction, one optional delivery, one three-branch route event, and one failure-forward replacement market in `content/runtime_world.json`. Reuse the existing Bazaar, itinerary, command, event, save, and debrief boundaries; extend only the supported code-native landmark vocabulary needed to give glass, kiln, mirror, shardwind, and beacon scenes distinct silhouettes.

**Reason:** Early Access breadth needs another complete economic loop, not decorative map nodes or a prescribed quest chain. Saltglass, dune spice, and lamp oil create ordinary two-way trading among Sunfall Exchange, Kiln Rest, and Mirror Wells. The official beacon contract offers a modest alternate path, while ignoring it creates the Night Market and a new saltglass premium instead of removing play.

**Trade-off:** The region uses provisional code-native art and shares the Basin's crisis clock and interface shell. It adds no new combat model, pathfinder, or parallel economy; the third region and broader crew/event/ending targets remain separate milestones.

## ADR-080: Siltfire March closes the map through ordinary trade

**Decision:** Add Siltfire March as two settlements connected to opposite sides of the existing network. Mothlight Quay and Blackreed Post reuse the canonical goods catalog but invert medicine/cloth and grain/charcoal supply roles. The Salt Causeway carries a recoverable whiteout event; the Reedline Track provides a steadier return connection. Both roads expose one save-safe local preparation. Bazaar card palettes derive from authored settlement identity so arrival changes the full place presentation.

**Reason:** The third region must make the map more connected and ordinary trading more legible, not inflate the catalog. Two complementary markets create a repeatable loop, while the two Basin connections let the player enter and leave without retracing a single branch. Distinct route hazards and preparations make road choice consequential.

**Trade-off:** Siltfire uses existing factions and goods, reserving the fourth standing faction and additional endings for MA-EA-4. Its visuals remain code-native production scaffolding, and the shared Basin crisis clock still governs all regions.

## ADR-081: Adaptive endings share authored causal requirements

**Decision:** Promote the Causeway Bellkeepers to a fourth standing faction whose trusted threshold discounts only the Salt Causeway. Express both replacement-actor endings through shared scenario-state, support, local-resilience, post-activation ordinary-delivery, reputation, and escalation requirements. Add support, opposition, and reconciliation actions for the Night Market before enabling `Beacons Without Licenses`.

**Reason:** A replacement market is meaningful only if the player can materially support or oppose it and if its outcome remembers how legitimacy was earned. The shared evaluator prevents the Well Commons from remaining a one-off code path and ensures ordinary trade—not a contract or event transfer—can establish either alternate institution.

**Trade-off:** The fourth faction currently changes one route fee and two event/service decisions rather than owning a full quest chain. The Night Market ending shares the Basin crisis clock, so its political resolution arrives at Day 10 even when most play occurred outside the Basin.

## ADR-082: Regional specialists unlock material-backed road responses

**Decision:** Add Mara Voss at Blackreed Post and Orin Bell at Mirror Wells as the fourth and fifth crew members. Each exposes one otherwise unavailable response in a new regional event: Mara consumes scrap to mark a safer Reedline load path, while Orin consumes lamp oil to establish a true Mirror Run beacon line. Both outcomes use the existing route-condition and information systems.

**Reason:** The Early Access roster needed breadth without turning people into interchangeable percentage modifiers. A named person, carried material, route dilemma, and persistent callback form a complete decision loop the player can understand before committing.

**Trade-off:** Both specialist responses are deliberately strong once their recruitment and cargo prerequisites are met. The events therefore retain paid, delayed, and disclosed-risk alternatives, and the Mirror Run event appears after the established Shardwind encounter on later eligible crossings rather than displacing it.

## ADR-083: The candidate ships as a self-describing portable release

**Decision:** Bind the project, Windows resource, content, manifest, tag, and release-note versions through one validator. Include the versioned release guide inside the recommended Windows ZIP, require explicit install/upgrade/rollback/limitations sections, impose a clean-launch timeout, and publish tagged GitHub prereleases only from the validated Windows workflow.

**Reason:** A working executable is not enough for an Early Access handoff. Testers need to know what they downloaded, how to preserve and roll back saves, which limitations remain, and which artifacts and checksums came from the same commit.

**Trade-off:** Release identifiers and the guide path are intentionally strict for this candidate, so the next candidate must update them together. The binary remains unsigned, and automated packaging evidence does not replace storefront, antivirus-vendor, physical-device, assistive-technology, or moderated player certification.

## ADR-084: Runtime content access copies only returned records

**Decision:** Keep the validated runtime JSON in one private read-only cache. Public content accessors return deep copies of the requested record or section, while `runtime_world()` remains the explicit full-snapshot API.

**Reason:** Save validation repeatedly asks for individual goods, routes, factions, and rule sets. Deep-copying the entire runtime document for every lookup made deterministic save restoration scale with the whole content file and pushed the release benchmark past five seconds. Copying only the returned record preserves caller isolation while removing unrelated allocation.

**Trade-off:** Internal helpers must never expose the cached dictionary to callers. Tests retain a mutation-isolation check for the public full-snapshot API, and new accessors must duplicate any mutable value they return.

## ADR-085: The guided opening proves ordinary trade before optional work

**Decision:** Start the tutorial with an ordinary Ashgate Water purchase and Reedwatch sale, then teach return Grain trade before asking the player to inspect—but not accept—a Job Board assignment. Every successful sale shows the realized payout and the local unit price before and after new supply.

**Reason:** The investment vertical must demonstrate that local production, demand, capacity, road burden, and changing prices form a complete game without a contract. Introducing optional work only after the player has profited from a two-way circuit makes its added deadline and political value legible as a choice rather than disguised mandatory progression.

**Trade-off:** The guided path no longer demonstrates contract completion in its first journey; deterministic campaign tests and the optional Job Board retain that coverage. Existing guided saves that already completed relief remain recoverable through derived tutorial state.

## ADR-086: The ending receipt includes crew and optional side deals

**Decision:** Extend the terminal campaign debrief with recruited/assigned crew and every successful settlement service or side deal from command history. Arms-market and recovery entries include the visible escalation transition.

**Reason:** A terminal receipt must explain the player's economic and political story, not only roads and ordinary transactions. The sealed-arms choice is optional and recoverable, but omitting it from the debrief would hide the most consequential parallel-economy decision from the campaign's closing account.

**Trade-off:** The receipt can become long in mature campaigns, so it remains scrollable and route/trade lists retain their bounded recent-history presentation. It summarizes authoritative commands without adding new save state.

## ADR-087: Glasswind Reach gains a direct high-risk trade road

**Decision:** Add the Emberglass Byway between Kiln Rest and Mirror Wells as Glasswind Reach's third road. It is cheaper and faster than the licensed two-leg connection through Sunfall Exchange, but carries materially higher cargo risk and shares the recoverable Shardwind event family. Keep its terms, region membership, specialist notes, and visual identity in the existing runtime-content and route-presentation boundaries.

**Reason:** The Reach already has three markets and multiple ordinary goods, but two roads leave Kiln Rest and Mirror Wells dependent on the same Sunfall junction. A direct high-risk edge creates a legible speed-versus-exposure decision, closes the local triangle, and satisfies the investment gate without inventing another settlement, currency, or mandatory quest.

**Trade-off:** The byway reuses an established event family and existing trade goods. Its value comes from topology and route terms rather than a new subsystem; final route illustration and balance still require human playtest calibration.

## ADR-088: The map legend sits outside the route field

**Decision:** Keep the compact data-authored route labels, but show only the current region's roads in a dedicated strip immediately below the map board rather than inside its bottom grid row. Keep the in-map heading to the region name because the objective and instruction immediately above already provide pressure and selection context. Show the map detail card only during an actual pointer hover; a selected destination remains fully described by its itinerary card. Use the full route name everywhere interactive.

**Reason:** Eight global routes made the old in-board footer collide with Kiln Rest, Mirror Wells, and Reedwatch, while repeated objective and selection text extended the regional heading beneath Mothlight Quay. The selected-destination fallback also pinned a duplicate tooltip across the network. A local key, separated layers, and contextual hover preserve the Frontier-style network at a glance without covering settlements or weakening the detailed pre-commitment comparison.

**Trade-off:** The legend uses a smaller ten-point base label and a narrow amount of space above the journey text. Large Text still scales it, and responsive bounds tests require the strip to remain between the board and the result rail.

## ADR-089: The investment vertical is one replayable command path

**Decision:** Define `gpt56_clean_investment_vertical` at seed `1107` as the canonical investment-evaluation journey. It begins with ordinary Water and Grain trade, crosses the Old Road through the disclosed Three Riders contact, records both destination and return-market changes, then offers—but never requires—the sealed-arms side economy before reaching a causal regional receipt. Exercise every transition through the same command handlers used by players, serialize and restore the authoritative world at each phase, and capture the journey at both 1280×720 and 1600×900.

**Reason:** Separate feature tests could prove buying, travel, events, market memory, side deals, and endings without proving that they form a coherent game from a clean save. One named path makes the complete economic and political arc reproducible, while an ordinary-trade-only control demonstrates that the black market remains genuinely optional.

**Trade-off:** The canonical path is an evaluation fixture rather than a prescribed strategy or tutorial script. It fixes a seed and chooses certain responses to make evidence stable, but the player-facing campaign retains all route, event, trade, contract, crew, and recovery alternatives.

## ADR-090: Presentation identity has one registry and read-only view boundary

**Decision:** Centralize settlement motifs, market accents, route textures, route colors, risk cues, and arrival treatments in `src/ui/visual_registry.gd`. Extract the Bazaar canvas, journey map/road canvas, and departure-road-event-arrival copy state from `main.gd` into dedicated presentation modules. These modules may read world snapshots and emit navigation signals, but they may not execute market or campaign commands.

**Reason:** Authored place and road identity had grown inside a monolithic UI script, with route colors, scene profiles, and state copy decided in separate methods. A registry makes the visual grammar inspectable and testable, while read-only views preserve the simulation/UI boundary and make later asset replacement local.

**Trade-off:** Procedural drawing remains deliberately lightweight and some layout construction remains in the application shell. The extraction removes more than one thousand lines from `main.gd` without introducing a scene framework or changing authoritative outcomes.

## ADR-091: Siltfire closes as a three-market failure-forward slice

**Decision:** Add Emberfen Refuge and Emberfen Drift to Siltfire March. The new market turns Mothlight cloth into an ordinary outbound opportunity and charcoal/spice into return cargo; the optional Smoke Cloth contract adds Bellkeeper standing but is never required. Ignoring or failing it activates the Ash Sifters, whose charcoal premium and kiln action create a replacement economy, local resilience, and a persistent route improvement. Limit the map canvas to the current region plus the settlements named on its gateway roads.

**Reason:** Two settlements and two roads demonstrated a loop but not a regional sandbox. A third market, a distinct high-exposure road event, faction pressure, and a material response after failure let the March support comparison, consequence, and recovery on its own. Region-scoped map drawing keeps eleven global settlements readable without hiding gateway destinations.

**Trade-off:** Emberfen reuses the shared goods catalog and crisis clock rather than adding a currency or separate campaign. Its procedural peat-stack and smoke art is replaceable through the visual registry. The Ash Sifters currently have one cooperation action rather than the broader support/oppose/reconcile set available to the older replacement factions.

## ADR-092: The private alpha is one reproducible offline package

**Decision:** Ship `0.16.0-early-access-rc1` as a portable Windows ZIP and standalone executable, accompanied by a provenance manifest, SHA-256 list, versioned tester guide, and the complete validated 1600×900 journey capture. Generate local and tagged manifests and capture archives through shared tested helpers. Require the release contract to declare a 30–90 minute offline campaign and to document backup recovery, migration, rollback, controller/scaling coverage, known limitations, and provenance.

**Reason:** The four GPT-5.6 packets must end in a tester-ready artifact rather than a collection of passing source tests. A self-describing offline package lets a private-alpha tester install, preserve a save, exercise the full creative vertical, report the exact build, and recover or roll back without repository access. Shared package helpers keep the local acceptance run and tagged GitHub workflow structurally identical.

**Trade-off:** The Windows build remains unsigned and cannot establish SmartScreen reputation, physical-controller behavior, assistive-technology compatibility, or moderated comprehension by automation. Those are explicit external calibration gates, not hidden release claims.

## ADR-093: Full-size release evidence runs on a fixed Linux display

**Decision:** Generate the complete 1600×900 release journey in a dedicated Ubuntu/Xvfb job with a fixed 1920×1080 virtual display, upload it as a workflow artifact, and make the Windows packaging job consume and archive that validated capture. Name cross-job artifacts by numeric workflow run ID so tagged and manually dispatched branch runs use the same filesystem-safe path. Keep the Windows runner responsible for the executable, clean-install smoke, and packaged native GUI evidence at its available desktop size. Advance the repaired candidate to `0.16.0-early-access-rc2` rather than moving the failed RC1 tag.

**Reason:** GitHub's hosted Windows desktop exposed only a 1028×578 drawable area when asked for 1600×900, so the capture correctly rejected the scaled frame. Xvfb gives the evidence harness an explicit viewport while the Windows-specific checks continue to validate the platform artifact. Separate jobs preserve both guarantees without weakening the dimension assertion or rewriting a public tag.

**Trade-off:** The complete journey archive is rendered with Linux OpenGL rather than Windows ANGLE. The release still includes a real packaged-Windows screenshot and metadata, and the same capture script and validator run on both platforms.

## ADR-094: Opening layout follows real display bounds and bounded prose

**Decision:** Clamp the preferred desktop window against the smaller of the platform's usable and physical screen sizes, even when the process receives a resolution argument. Keep the authored 1280 compact/1600 split breakpoint, but let `ResponsiveColumns` stack defensively whenever visible child minimum widths cannot coexist. Bound Introduction prose inside a horizontal-scroll-free `RichTextLabel`, clip the presentation shell as a final safety boundary, and require opening cards to retain at least 24 px of horizontal safe area in native evidence.

**Reason:** The RC2 source-level capture passed at 1280×720, but a separate Xvfb smoke run exposed a 1600-wide window inside a 1280-wide virtual display. Its cropped pixels made otherwise valid logical control bounds meaningless. Display-aware launch negotiation fixes the real window, while defensive container and prose constraints prevent intrinsic minimum sizes from recreating the overflow.

**Trade-off:** The 1280 and minimum-width openings remain vertically stacked rather than compressing both illustrations and prose side by side. This preserves readable type and complete controls; 1600×900 retains the wider split composition.

## ADR-095: Playtest pacing evidence is bounded, local, and interpretive

**Decision:** Extend the deliberate playtest-report export with a maximum 256-entry in-memory timeline of screen/context transitions and command outcomes. Each entry records only elapsed time, stable state identifiers, broad outcome, campaign day, and settlement. Add a deterministic cohort analyzer and repo-local pacing and delivery review skills that turn this evidence into hypotheses and small acceptance-tested changes.

**Reason:** Automated flow tests prove reachability but cannot show where a player hesitates, repeats blocked actions, or loses the journey's rhythm. A local timeline connects observed friction to the existing first-five, first-fifteen, and first-thirty-minute targets without introducing telemetry, identity collection, or a second gameplay state.

**Trade-off:** Timing cannot establish comprehension or fun. Reports remain manually exported and must be paired with tester answers and visual evidence; the bounded timeline may omit the earliest transitions in exceptionally long, high-churn sessions.

## ADR-096: Journey copy speaks as a caravan, not a test harness

**Decision:** Keep exact costs, risks, cargo exposure, rolls, and consequences visible, but remove implementation language from release-facing travel copy. Event responses list only non-zero costs, show rewards on a separate `RECEIVE` line, and describe the road result before the authored consequence. Tutorial and ending prose stays compact and addresses the world directly rather than narrating a test or “the player.”

**Reason:** The existing copy was unusually honest but repeatedly used phrases such as “presentation cannot change,” “next authored encounter,” “disclosed exposed-unit roll,” and “factual journey receipt.” Those phrases explain the software instead of the caravan, while repeated zero values obscure the differences between choices.

**Trade-off:** Mechanical labels and deterministic roll comparisons remain deliberately explicit, so the interface is not fully diegetic. Character-specific dialogue is still sparse and requires later authored content rather than longer utility prose.

## ADR-097: Visual evidence proves the native window before judging layout

**Decision:** Treat windowed and host-maximized startup states as eligible for display-bound fitting, then repeat the fit for four frames while platform metrics settle. A native capture is valid only when its requested size equals the actual native-window size, its logical viewport remains the authored 1280×720 canvas, and the expected player state is stable for two frames before rendering. Curated review sequences must be extracted from that validated manifest.

**Reason:** A repeat smoke review cropped a 1600×900 game window to a 1280×720 virtual desktop and interpreted the crop as an in-game container defect. The UI's canonical 1280×720 renderer capture was contained, but the evidence systems did not record enough window or navigation state to explain the conflict.

**Trade-off:** Full native capture takes slightly longer because every state waits for stability, and oversized startup windows may be restored from a host-imposed maximized state. Deliberate fullscreen modes remain untouched.

## ADR-098: The journey rail names the current beat

**Decision:** Replace the persistent `DEPARTURE DESK` heading after commitment with phase-specific titles: `ON THE ROAD`, `ROAD STOP`, `ROADSIDE DECISION`, and `ARRIVED AT <SETTLEMENT>`. Derive the title in the read-only journey presenter, publish it in capture state, and require it in the canonical investment-journey fixture.

**Reason:** The validated sequence showed that road, encounter, and arrival all retained the planning-room heading. The controls changed correctly, but the repeated title weakened spatial continuity and made the arrival payoff look like another Departure state.

**Trade-off:** The rail still shares one stable layout across journey phases. This improves identity and player orientation without introducing separate scenes, longer transitions, or simulation state.

## ADR-099: Encounter action names and numeric terms have separate roles

**Decision:** Allow an event choice to declare an optional concise `action_label` for its button heading while preserving the existing `label` for command results, history, and debriefs. Choice cards omit the `COST` row when nothing is spent and show all non-zero costs and rewards exactly once in dedicated rows. Any authored choice label containing a number must provide the concise action label.

**Reason:** The encounter cards already separated `COST` and `RECEIVE`, but several headings repeated the same ashmark, cargo, provision, or day term. The repetition made the choice rail denser without adding information and contradicted the intended action-first hierarchy.

**Trade-off:** The runtime content gains one optional presentation field. Older saved pending encounters safely fall back to their complete historical label, while authoritative choice IDs, costs, outcomes, and debrief records remain unchanged.

## ADR-100: Road horizons reuse settlement motif identity

**Decision:** Render origin and destination silhouettes in road scenes from each settlement's existing visual-registry motif. Gate, reeds, brine, forge, lantern/quay, glass/mirror, watchtower, and peat-stack families share the same small horizon footprint and preserve written settlement labels.

**Reason:** Route environments were distinct, but every endpoint used the same block-and-flag silhouette. The road therefore communicated corridor identity while relying almost entirely on text to distinguish the places being left and approached.

**Trade-off:** These remain economical code-drawn marks rather than final environment paintings. Reusing the registry keeps them deterministic and replaceable, but final commercial art direction still requires authored asset work.
