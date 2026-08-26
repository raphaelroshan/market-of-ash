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
