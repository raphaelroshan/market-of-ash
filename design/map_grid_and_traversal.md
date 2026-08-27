# Market of Ash — Placeholder Map, Placement Grid, and Traversal

## Goal

Give the trade-and-travel loop a legible spatial board before final art exists. The player should see the five settlements, route corridors, caravan position, a grid reserved for future placement, and a moving token that travels along the selected route rather than teleporting between menus.

## Scope

This slice is presentation-first. It adds a procedural regional board with a square cell grid, route lanes, settlement footprints, a selected-cell highlight, a caravan movement token, and route/settlement legend text. Clicking an empty map cell selects it as a future placement or traversal cell and reports the coordinates. It does not yet add a new economy command for building stalls, guards, obstacles, or permanent map objects.

## Grid contract

The regional board uses a fixed 17 by 11 presentation grid. Each cell is a stable coordinate suitable for future camp, warehouse, obstacle, escort, or route-object placement. Settlement footprints occupy cells visually but are not currently placeable. Empty cells remain visibly distinct from route cells, hazard cells, and settlement cells.

## Traversal contract

The caravan token begins on the current settlement. A successful departure supplies the selected route ID and the current/destination settlement IDs to the map renderer. The UI animates the token along the route corridor while the authoritative world state has already committed the travel command. Movement is presentation-only; it does not add time, risk, or a second simulation. The current destination and route result remain authoritative in `world_state.gd`.

## Route presentation

The placeholder renderer uses the existing three route IDs and gives each a distinct corridor treatment: Old Road is a warm exposed line with hazard marks, Toll Road is a pale maintained line with checkpoint marks, and Dry Cut is a blue-grey shortcut with provision-warning marks. This is a visual explanation of existing route descriptions, not a new route rule.

## Acceptance criteria

The board must remain visible behind the caravan controls. A tester must be able to identify all five settlements, distinguish the three route styles, see the current caravan marker, click a grid cell and receive a coordinate event, and see the caravan move through the route corridor after a successful departure. The grid and traversal marker must not mutate the authoritative serialized world state.

## Art boundary

The first pass is procedural and intentionally replaceable. If a generated ashland map texture becomes available, it may be layered behind the same grid, route, settlement, and token interfaces. Generated art must not obscure the grid or reduce route readability.
