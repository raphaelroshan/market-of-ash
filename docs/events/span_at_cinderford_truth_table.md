# E02 — The Span at Cinderford Truth Table

## Trigger

- Route must be `old_road`.
- Event must not already be resolved and no other event may be pending.
- The caravan must carry at least two units total of `scrap` and/or `charcoal`.
- The deterministic trigger roll must be below `0.70`.
- Trigger roll: `(seed × 13 + post-travel day × 17 + 29) mod 100 / 100`.

When eligible but not selected, normal Old Road incident resolution and arrival continue. When selected, the route fee, base travel day, and base provision cost have already been paid; destination arrival waits for a choice.

The event uses the first two available repair-material units in canonical order: scrap, then charcoal. That frozen material basis is displayed and serialized with the pending event.

## Choices

| Choice ID | Visible cost | Preconditions | Deterministic result | Persistent follow-up and recovery |
| --- | --- | --- | --- | --- |
| `sell_materials_at_premium` | 2 repair-material units | At least 2 frozen eligible units | Remove 2 units and receive 30 ashmarks; arrive immediately. | The crew records the materials as privately purchased. The public span remains unchanged, so later Old Road forecasts do not improve. If unavailable, message or turn-back choices remain. |
| `reserve_materials_for_span` | 2 repair-material units, 1 day | At least 2 frozen eligible units | Remove 2 units, advance 1 day, and patch the public support; arrive. | `old_road` gains the visible `cinderford_span_patched` condition and its risk falls by 10 percentage points on later forecasts and resolutions. |
| `carry_repair_message` | 1 provision, 1 day | At least 1 provision after base travel | Spend provision/day and carry the failed-support measurements onward; arrive. | `old_road` gains the visible `cinderford_span_surveyed` condition and its risk falls by 5 percentage points on later forecasts and resolutions. |
| `turn_back_with_cargo` | 1 day | Always available | Advance 1 day and return to the origin with cargo intact. | No route improvement is applied. This is the guaranteed no-resource soft-lock escape; the event remains resolved and the player can recover in the origin market. |

## State transitions

1. `depart_route` validates and pays the normal Old Road cost, advances the normal route day, and records a frozen `journey_context`.
2. If the trigger passes, `pending_event` stores the event, trigger/resolution rolls, route context, disclosed incident basis, and a frozen two-unit repair-material basis. The caravan remains at the origin.
3. `resolve_event` validates the choice and its material/provision precondition before mutation.
4. A successful choice applies its explicit cargo, money, day, arrival-target, and route-condition effects; archives one event result; refreshes visit slots at the resulting settlement; and checks contracts only when the caravan reaches the intended destination.
5. Repeating the same resolution is rejected without authoritative mutation.

## Required tests

- Material-cargo trigger, ineligible cargo, wrong route, deterministic trigger/no-trigger seeds, and one-event-per-journey selection.
- Premium sale, public reservation, repair message, and turn-back outcomes.
- Mixed scrap/charcoal frozen material basis and insufficient-material/provision blocks.
- Patched and surveyed conditions changing later Old Road forecast and resolution risk by the exact disclosed amount.
- Turn-back preserving cargo and skipping destination contract resolution.
- Repeat resolution rejection.
- Mid-event save/load, route-condition save/load and version-5 migration.
- Equivalent deterministic replay.
- Event card setup, route/material context, all costs, disabled reasons, focusability, and arrival/return report.
