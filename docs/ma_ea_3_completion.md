# MA-EA-3 completion — Siltfire March

## Delivered slice

- `siltfire_march` completes the connected three-region map with Mothlight Quay and Blackreed Post.
- `salt_causeway` links Brine Cross to Mothlight; `reedline_track` links Mothlight and Blackreed to Reedwatch through explicit legal segments.
- Mothlight exports medicine and cloth while Blackreed exports grain and charcoal, producing profitable ordinary trade in both directions without a contract.
- `Bells in the Whiteout` offers pay, wait, and disclosed cargo-risk branches; every branch reaches a usable destination.
- Mothlight's bell chart and Blackreed's reed skids persistently reduce their named route risks and survive save/load.
- Quay/watchtower landmarks, settlement-derived Bazaar palettes, brine-bell road art, and marsh-watch road art give the region a distinct code-native presentation.

## Verification

- Runtime content version `1.24.0` validates three regions, ten goods, ten settlements, seven routes, three standing factions, two adaptive replacement actors, and six route-event families.
- `tests/test_third_region.gd` proves two-way ordinary profitability, deterministic whiteout recovery, persistent mitigation, topology, and visual identity metadata.
- `tests/test_campaign.gd` proves all ten settlements are reachable through player-legal route segments.
- The full repository/Godot suite passes, including economy, map UI, presenters, tutorial, controller, campaign, game-quality, second-region, and third-region coverage.
- Native evidence renders 53 player-facing states per viewport at 960×540, 1280×720, 1600×900, and 1920×1080. The validator checks bounds, release-surface cleanliness, distinct transitions, both March bazaars/services, both roads, the whiteout, and both arrival handoffs.
- A fresh Windows export validates as a 98,152,656-byte x86-64 GUI executable with a 632,516-byte embedded PCK. The expected macOS `rcedit` metadata warning remains non-blocking; Windows CI performs the authoritative resource/package checks.

## Remaining boundary

MA-EA-3 meets the Early Access breadth floor for regions, settlements, goods, and routes. It does not add the fourth standing faction, additional crew, or final ending/event breadth; those remain explicit MA-EA-4 and MA-EA-5 work.
