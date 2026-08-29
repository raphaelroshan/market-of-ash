# Brine Cross Medicine Escort — Alpha Contract

## Player-facing behavior

At Ashgate, a caravan with at least one Ash Warden standing may spend one visit slot to accept a registered escort manifest: deliver two medicine to Brine Cross within two days for 108 ashmarks. The player first earns the prerequisite through visible Warden-aligned work, then chooses a smaller guaranteed margin and relationship gain instead of unrestricted spot trade.

## Frozen terms

| Field | Value |
| --- | --- |
| Contract ID | `brine_cross_medicine_escort_01` |
| Origin | Ashgate |
| Destination | Brine Cross |
| Sponsor | Ash Warden Cistern Office |
| Cargo | 2 medicine |
| Deadline | Acceptance day + 2 |
| Reward | 108 ashmarks |
| Prerequisite | Ash Warden standing 1 |
| Completion relationship | Ash Warden standing +1 |
| Late penalty | Up to 6 ashmarks and Ash Warden standing -1 |
| Visit cost | 1 slot |

The complete record, including prerequisite and relationship effects, is copied into `active_contracts` at acceptance. Current-version saves reject altered frozen terms.

## Resolution table

| State | Result |
| --- | --- |
| Warden standing below 1 | Acceptance is blocked without consuming a visit slot; UI states required and current standing. |
| At Brine Cross on/before deadline with at least 2 medicine | Remove 2 medicine, pay 108 ashmarks, apply market memory, grant one Warden standing, archive `completed`. |
| At Brine Cross on/before deadline with fewer than 2 medicine | Keep contract and cargo active and state the missing quantity. |
| Anywhere after deadline | Charge at most 6 ashmarks, withdraw one Warden standing, retain all cargo, archive `failed`. |
| Resolve after completion/failure | Reject without mutation. |

## Design tradeoff

The contract is deliberately not the highest-profit opening. It buys certainty and official access: the player pays for medicine, Toll Road passage, a possible inspection response, and sponsor visibility. Success moves the player across the first Warden threshold; failure preserves sellable medicine so it cannot create a death spiral.

## Test contract

- Faction prerequisite and persistent disabled reason.
- Capacity, visit-slot, duplicate, and origin validation through the shared contract boundary.
- Frozen deadline, reward, prerequisite, and relationship terms.
- Automatic arrival completion, cargo consumption, market memory, reward, and standing.
- Partial-delivery recovery and bounded late failure with retained medicine.
- Save/load integrity and no duplicate completion.
