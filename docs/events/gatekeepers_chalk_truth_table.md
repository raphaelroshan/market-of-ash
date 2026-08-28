# E01 — The Gatekeeper's Chalk Truth Table

## Trigger

- Route must be `toll_road`.
- Event must not already be resolved and no other event may be pending.
- The caravan must either carry at least 60 ashmarks of destination-valued cargo or have an active contract.
- The deterministic trigger roll must be below `0.65`.
- Trigger roll: `(seed × 13 + post-travel day × 17 + 17) mod 100 / 100`.

When eligible but not selected, normal Toll Road incident resolution and arrival continue. When selected, the route fee, base travel day, and base provision cost have already been paid; destination arrival waits for a choice.

## Choices

| Choice ID | Visible cost | Preconditions | Deterministic result | Recovery |
| --- | --- | --- | --- | --- |
| `pay_posted_toll` | 6 ashmarks | At least 6 ashmarks after the route fee | Pay 6, clear the chalk, arrive immediately. | If unaffordable, detour or stamped review remains visible. |
| `take_dust_detour` | 1 provision, 1 day, 25% one-unit cargo risk | At least 1 provision after base travel | Spend provision/day; use the stored resolution roll and exposed-unit basis; arrive with cargo intact or one disclosed unit lost. | If unavailable, pay or stamped review remains visible. |
| `wait_for_stamped_review` | 1 day | Always available | Advance one day, preserve money/cargo/provisions, arrive after the office confirms the fare. | This is the guaranteed no-resource soft-lock escape. |

## State transitions

1. `depart_route` validates and pays the normal Toll Road cost, advances the normal route day, and records a frozen `journey_context`.
2. If the trigger passes, `pending_event` stores the event ID, title/setup/stakes, route context, trigger and resolution rolls, exposed cargo unit/value, and authored choices. The caravan remains at the origin until resolution.
3. `resolve_event` validates the pending event and choice before mutation.
4. A successful choice applies its explicit costs and optional detour loss, archives one event result, clears pending journey state, completes arrival, refreshes visit slots, and then checks active contract completion/failure.
5. Repeating the same resolution is rejected without authoritative mutation.

## Required tests

- Eligible trigger and deterministic no-trigger seeds.
- Ineligible route and low-cargo/no-contract path.
- Pay success and insufficient-money block.
- Detour success, insufficient-provision block, and deterministic one-unit loss.
- Always-available stamped review.
- Repeat resolution rejection.
- Mid-event save/load and equivalent replay.
- Arrival state, visit-slot refresh, and contract deadline interaction.
- Event card setup, stakes, all choices, disabled reasons, and focusability.
