# MA-I5 completion — Siltfire March and basin memory

## Acceptance crosswalk

- **Connected third region:** Siltfire March connects Brine Cross to Mothlight Quay through the Salt Causeway and reconnects Blackreed Post to Reedwatch through segmented Reedline travel.
- **Distinct market identity:** Mothlight exports medicine and waxed cloth while importing food and signal goods; Blackreed exports grain and charcoal while importing medicine, cloth, and spice. Deterministic coverage proves profitable ordinary cargo in both directions.
- **Faction pressure:** Causeway Bellkeeper standing changes only the named road's fee and is earned or lost through visible whiteout/service choices.
- **Replacement actor:** ignoring the official Mirror Wells beacon offer activates the Night Market; support, opposition, and reconciliation remain open while ordinary saltglass supply drives its alternate ending.
- **Changed return conditions:** persistent route conditions, market pressure, settlement resilience, faction support, and post-activation delivery history survive save/load and appear in the terminal receipt.

## Required evidence

- `tests/test_third_region.gd` covers two-way trade, whiteout recovery, persistent mitigation, and the two-edge connection back to the Basin.
- `tests/test_campaign.gd` reaches all ten settlements by legal segments and proves every stressed fixture retains a recovery or progression command.
- `tests/test_ma_ea_4.gd` covers the fourth faction, Night Market agency, ending requirements, and rejection of pre-activation or non-ordinary deliveries.
- `tests/test_ma_ea_5.gd` covers the two regional specialists, their material-backed event responses, persistence, and replay contrast.
- The six-ending matrix and causal debrief are exercised by `tests/test_campaign.gd`, `tests/test_ma_ea_4.gd`, and `tests/test_investment_vertical.gd`.
- `docs/visual_evidence/v0.15.0-ma-i5-basin-memory-2026-09-02/` records the Siltfire consequence/arrival/market sequence and the changed Night Market ending.

## Remaining boundary

This gate reuses already completed MA-EA-3 through MA-EA-5 systems rather than duplicating them. Human balance and art-direction review remain external calibration, not missing implementation.
