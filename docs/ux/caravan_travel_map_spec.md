# Caravan travel and regional map presentation

## Purpose

The caravan is the player's persistent vehicle, home, and point of view. Travel should feel like moving that specific place through a dangerous trade network, not moving an anonymous dot between menu choices.

This presentation remains downstream of the deterministic command processor. It visualizes committed state and never rolls events, spends resources, or changes route legality.

## Screen composition

- The regional network occupies the central stage and keeps the caravan visually prominent.
- Caravan resources move into the side rail: location/state, day/crisis, ashmarks/provisions, and hold usage.
- The right rail is contextual. At rest it contains route planning; on the road it contains one continue action; during an encounter it contains the event, stakes, and available responses; after arrival it contains plan-versus-actual results and the settlement-entry action.
- The journey result remains below the map so the map, controls, and authoritative outcome can all be read at once on the supported 960×540 through 1600×900 window range.

## Caravan states

### At rest

The caravan is anchored at the current settlement and labelled `AT REST`. Connected settlement nodes remain selectable. No resource changes occur until Commit departure.

Potential assignment destinations use a restrained grey marker; accepted assignments use a colored marker. Selecting or hovering a settlement opens a compact brief with its role, assignment state, direct route, ashmark fee, provision cost, and travel time. The chosen corridor is emphasized while unrelated roads recede.

### Moving

After a successful departure command, the regional map gives way to a side-on road view. The caravan crosses an authored landscape and stops at a readable midpoint observation. The player explicitly continues before an event or arrival is revealed, so the journey is never bypassed. Paid route costs have already been applied by the command result; animation duration never affects simulation.

### Encounter

If the committed journey creates a route event, the caravan stops at a fixed presentation point on the route and is labelled `ENCOUNTER`. The alert ring and right-side event card make the interruption explicit. There is no timer: travel resumes only through an authored response, and the response resolver remains authoritative.

### Arrival

When a journey completes or an encounter resolves, the caravan appears at the destination and is labelled `ARRIVED`. Planning remains locked until the player reviews the result and enters the settlement.

## Frontier-style repeatable navigation path

The reference is Frontier's repeatable sequence of occupying a settlement, choosing a destination, setting out, crossing an in-between road, resolving what happens there, and entering the next settlement. Market of Ash makes that path explicit and consistent:

1. Inspect adjacent legal destinations and route forecasts.
2. Commit one route segment with disclosed costs and risk.
3. Enter a distinct road view and inspect the journey before continuing.
4. Resolve at most one focused route encounter for this vertical slice.
5. Arrive, review plan versus actual, enter the bazaar, and begin the loop again.

The implementation follows Frontier's navigation rhythm without reproducing its artwork or historical interface. Strategic pressure comes from cargo, provisions, tolls, risk, settlement resilience, factions, and the crisis clock.

## Settlement bazaar

The settlement is a recurring hub rather than one long report. A stable bazaar directory exposes Trade, Jobs, Services / Intel, Crew, Outlook, and the Departure Gate. Each entry points to an existing authoritative action set:

- Trade opens buying and selling around one selected cargo.
- Jobs exposes available and accepted delivery assignments.
- Services / Intel exposes local purchases, repairs, relief work, and route information.
- Crew exposes hiring and route assignments.
- Outlook reveals the larger campaign state on demand instead of occupying the default view.
- Departure opens the regional map and preserves the currently prepared load.

The bazaar header keeps only the settlement identity, today's need, caravan resources, and compact regional pressure visible. Longer explanations remain attached to the relevant stall or result.

## Expansion path

1. Current slice: readable caravan silhouette, side-rail resources, and distinct rest/move/encounter/arrival states.
2. Route intelligence: emphasize reachable nodes, selected corridor, assignment destinations, known hazards, and information freshness without exposing hidden rolls.
3. Regional evolution: change node and route presentation as crisis stages, repairs, contracts, and faction thresholds alter the authoritative forecast.
4. Caravan identity: add named modules and crew stations only when they create trade, travel, or negotiation choices; avoid a parallel combat subsystem.
