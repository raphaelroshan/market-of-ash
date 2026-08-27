# E03 — The Last Clean Barrel Truth Table

## Trigger

- Destination must be `reedwatch` or `brine_cross`.
- Crisis stage must be at least 1.
- The caravan must carry at least two water units.
- Event must not already be resolved and no other event may be pending.
- The deterministic trigger roll must be below `0.60`.
- Trigger roll: `(seed × 13 + post-travel day × 17 + 19) mod 100 / 100`.

When selected, normal route cost, time, and provisions have already been paid. The event freezes a two-water trade basis and the destination's pre-event water unit price so every choice remains exact across save/load and replay.

## Choices

| Choice ID | Visible cost or return | Preconditions | Deterministic result | Follow-up and recovery |
| --- | --- | --- | --- | --- |
| `sell_barrels_at_peak` | 2 water; destination price plus 6 ashmarks per unit | Two frozen water units still held | Remove 2 water, pay the frozen premium total, record a normal two-unit market delivery, and arrive. | Immediate cash is highest, but local water pressure softens by the ordinary sale amount and contract cargo may be short. |
| `share_barrels_fairly` | 2 water; no cash | Two frozen water units still held | Remove 2 water, record the delivery, add 2 bounded destination resilience, and arrive. | The same market pressure softens, but resilience becomes visible in the settlement header for later crisis work. |
| `honor_relief_commitment` | Preserve all cargo for the active contract | An active water contract for this destination | Arrive without event cargo mutation, then run the normal contract resolver. | The contract pays or remains partial under its frozen terms. When unavailable, the exact missing commitment is shown. |
| `keep_barrels_sealed` | No immediate cost | Always available | Arrive with cargo intact for ordinary spot trade. | This is the guaranteed recovery choice and preserves player control of the post-arrival sale.

## State transitions

1. Event selection freezes destination, route, trigger/resolution rolls, exposed-unit basis, and a two-water `trade_basis` containing unit price and premium.
2. `resolve_event` validates cargo and active-contract prerequisites before mutation.
3. Peak sale and fair distribution remove the frozen cargo basis and write bounded market memory. Fair distribution also updates `settlement_resilience[destination]` within `0..10`.
4. Arrival refreshes visit slots. Contract resolution runs only after the event's own cargo outcome, so selling/sharing can leave an active contract partial while the commitment choice preserves its normal completion path.
5. One archived event result names cash, cargo, market pressure, resilience, and contract follow-up; duplicate resolution is rejected.

## Required tests

- Crisis/destination/cargo eligibility and deterministic trigger/no-trigger seeds.
- Peak sale exact frozen payout and post-delivery market pressure.
- Fair distribution cargo removal, pressure, and bounded resilience.
- Contract choice enabled/disabled state and normal completion after arrival.
- Always-available sealed-cargo recovery.
- Insufficient cargo block without mutation.
- Save/load of pending trade basis, resilience save/load, and version-6 migration.
- Equivalent deterministic replay.
- Event UI shows shortage context, exact premium, cargo requirements, disabled contract reason, and focusable controls.
