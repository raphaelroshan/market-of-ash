# E04 — Three Riders, No Banner Truth Table

## Trigger

- Route must be `old_road` or `dry_cut`.
- Destination-valued cargo must total at least 70 ashmarks.
- Event must not already be resolved and no other event may be pending.
- The deterministic trigger roll must be below `0.55`.
- Trigger roll: `(seed × 13 + post-travel day × 17 + 29) mod 100 / 100`.

The base route fee, time, and provisions are already spent when the event appears. The pending snapshot freezes the route's exposed cargo unit/value and a separate resolution roll.

## Choices

| Choice ID | Visible cost | Preconditions | Deterministic result | Follow-up and recovery |
| --- | --- | --- | --- | --- |
| `pay_for_escort` | 10 ashmarks | At least 10 ashmarks after base travel | Pay the riders and arrive without an extra cargo roll. | Immediate certainty at a stated price; no hidden reputation gain. |
| `cross_without_escort` | 45% one-unit cargo risk | None | Compare the saved resolution roll with 0.45; lose the disclosed exposed unit on failure, then arrive. | The loss is bounded to one known unit and never ends the campaign. |
| `trade_medicine_for_passage` | 1 medicine | At least 1 medicine held | Remove one medicine and arrive without extra risk. | Converts high-value cargo into safe passage; the remaining load stays available for trade or contracts. |
| `wait_and_read_the_tracks` | 1 day | Always available | Advance one day, arrive safely, and record `three_riders_sponsor_mark` as known information. | Guaranteed no-resource escape. The information lead persists in saves and is visible in the settlement header.

## State transitions

1. Event selection freezes route, destination, exposed-unit basis, and deterministic rolls.
2. `resolve_event` validates money and specific-cargo costs before mutation.
3. The solo choice reuses the stored one-exposed-unit basis; medicine passage removes exactly one medicine; the wait choice writes one stable information ID without duplication.
4. Every successful choice arrives, refreshes visit slots, archives one result, and resumes normal contract checks.
5. Repeated resolution or unaffordable choices leave authoritative state unchanged.

## Required tests

- High-value trigger, low-value ineligibility, wrong-route ineligibility, and deterministic trigger/no-trigger seeds.
- Paid escort success and low-money block.
- Solo crossing success/loss boundaries using the saved roll and disclosed unit.
- Medicine passage success and missing-medicine block.
- Always-available wait, one-day delay, and persistent non-duplicating information lead.
- Mid-event save/load, information save/load, version-7 migration, and equivalent replay.
- Event UI route/cargo context, exact costs/risk, disabled reasons, focusability, and information-bearing arrival report.
