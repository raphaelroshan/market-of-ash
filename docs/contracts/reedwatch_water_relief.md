# Reedwatch Water Relief — Alpha Contract

## Player-facing behavior

At Ashgate, the player may spend one visit slot to accept a fixed commitment from the Reedwatch Wellkeepers: deliver four water to Reedwatch within two days for 180 ashmarks. Acceptance reserves no cargo and does not prevent spot trading, but the departure desk pins the required load and deadline. The Job Board separately shows expected net, provisions, hold commitment, standing, travel time, and visit cost so the premium can be compared with ordinary trade without inventing a single abstract score.

## Frozen terms

| Field | Value |
| --- | --- |
| Contract ID | `reedwatch_water_relief_01` |
| Origin | Ashgate |
| Destination | Reedwatch |
| Sponsor | Reedwatch Wellkeepers |
| Cargo | 4 water |
| Deadline | Acceptance day + 2 |
| Reward | 180 ashmarks |
| Completion relationship | Free Caravan standing +1 |
| Late penalty | Up to 8 currently held ashmarks |
| Visit cost | 1 slot |

The complete record is copied into `active_contracts` at acceptance. Later content edits cannot silently alter an accepted deadline, quantity, reward, or penalty.

## Resolution table

| State | Result |
| --- | --- |
| At Reedwatch on/before deadline with at least 4 water | Remove 4 water, pay 180 ashmarks, grant one Free Caravan standing, apply a four-unit market-memory delivery, archive `completed`. |
| At Reedwatch on/before deadline with fewer than 4 water | Keep the contract active, keep cargo, and state the exact missing quantity. The player may buy the remainder locally and resolve explicitly. |
| Anywhere after deadline | Charge at most 8 ashmarks, preserve all cargo for spot sale, and archive `failed`. |
| Resolve after completion/failure | Reject without authoritative mutation. |

Successful arrival resolution runs after route risk. A route incident can therefore reduce the load below four and leave the player with a clear recovery path rather than silently consuming a partial delivery.

## Test contract

- Acceptance location, capacity, duplicate, and visit-slot checks.
- Frozen accepted terms and deadline calculation.
- Automatic on-time completion at arrival.
- Partial arrival with exact missing-cargo feedback.
- Late failure with bounded penalty and retained cargo.
- Duplicate resolution rejection.
- Market-memory effect on completed delivery.
- Save/load of active terms and migration from save version 3.
- Shop offer, departure pin, and destination delivery-state UI checks.
- Ten-minute cross-path fixture that keeps contract expected net within 100–120% of the best ordinary opening while tracking non-cash costs and rewards separately.
