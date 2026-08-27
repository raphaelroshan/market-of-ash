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
