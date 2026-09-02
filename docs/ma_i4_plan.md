# MA-I4 — Glasswind Reach Route-Depth Plan

## Player-facing behavior

Glasswind Reach will offer a real three-road decision. From Kiln Rest, the player may pay for the two-leg licensed road through Sunfall Exchange or commit directly to the Emberglass Byway: one day and a lower fee, but materially higher cargo exposure. The direct road supports the same ordinary dune-spice and lamp-oil economy without requiring a contract.

## Data shape

- Stable route id: `emberglass_byway`.
- Endpoints: `kiln_rest` and `mirror_wells`; map path uses those two authored settlements.
- Base terms: 2 ashmarks, 1 day, 0.58 risk.
- Region membership: third route in `glasswind_reach.route_ids`.
- Event family: the existing `shardwind_tithe` may trigger on the byway, preserving paid, delayed, and disclosed cargo-risk responses.
- Crew guidance: every specialist receives one route-specific note through the existing `route_notes` record.
- Presentation: a dedicated copper/ember palette and furnace-vent landmark profile in the existing road renderer.

## Acceptance criteria

1. Glasswind Reach contains exactly three settlements and three routes, and every settlement has at least two legal exits within the region graph.
2. A seeded Kiln Rest → Mirror Wells ordinary-trade run can buy dune spice, encounter shardwind, recover through a no-loss choice, arrive, sell profitably, and survive save/load at the pending-event and changed-market phases.
3. The direct byway visibly states its fee, duration, and risk before confirmation and is cheaper/faster but riskier than traveling via Sunfall Exchange.
4. The optional beacon-oil contract and Night Market failure-forward state remain functional and are not required for ordinary profitability.
5. Runtime validation, economy tests, the full verification suite, and a native 1600×900 route-flow capture pass.

## Ordinary-trade alternative

Ignoring the byway leaves the licensed Glasswind Trace and Mirror Run connection intact. Ignoring the contract leaves lamp-oil and dune-spice trading profitable. Ignoring the Shardwind Tithe's licensed payment leaves a one-day shelter response and a disclosed cargo-risk crossing.
