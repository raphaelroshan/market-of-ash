# MA-EA-3 — Siltfire March acceptance plan

## Player-facing behavior

MA-EA-3 completes the connected three-region trade map. From Brine Cross or
Reedwatch, the caravan can enter the Siltfire March without skipping the road
phase, visit two mechanically different markets, and return through a second
connection. Mothlight Quay rewards medicine and cloth exports while importing
food, glass, and lamp oil. Blackreed Post exports grain and charcoal while
paying for medicine, cloth, and spice. Both directions must support profitable
ordinary trade without accepting a contract.

The Salt Causeway is a low-cost brine crossing exposed to sudden whiteouts.
Its event always offers a bounded recovery choice: pay the bell keepers, wait
on a marked salt island, or accept disclosed cargo risk and continue. The
Reedline Track is a slower, steadier marsh road. Local services let the player
reduce the characteristic risk of each road and preserve those changes through
save/load.

## Authored data shape

- Region: `siltfire_march`.
- Settlements: `mothlight_quay`, `blackreed_post`.
- Routes: `salt_causeway`, `reedline_track`, each with authored `map_path`,
  cost, duration, risk, description, and direct travel segments where needed.
- Event family: `causeway_whiteout`, eligible only on `salt_causeway`, with
  three deterministic and fully disclosed outcomes.
- Services: one risk-mitigation action in each new settlement.
- Existing goods remain authoritative; MA-EA-3 adds trade relationships rather
  than decorative cargo types.

## Acceptance gates

1. The canonical validators require all three regions, ten settlements, and
   seven routes, reject overlapping/out-of-range map cells, and accept the new
   landmarks and route references.
2. Deterministic smoke tests complete profitable ordinary-trade runs in both
   Siltfire directions, exercise the whiteout recovery branch, and preserve a
   route mitigation through save/load.
3. Native evidence includes Mothlight and Blackreed bazaars, both departure
   boards, the Salt Causeway road and event, Reedline travel, and arrival at
   both settlements at 1280x720 and 1600x900 with no developer surface.
4. The full verification suite, packaged-browser capture validation, and a
   fresh Windows export pass before merge.
