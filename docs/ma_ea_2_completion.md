# MA-EA-2 — Glasswind Reach Completion

**Status:** Complete
**Scope:** Compact second-region trade slice
**Next milestone:** MA-EA-3 third region and connected-map trade patterns

## Player result

Glasswind Reach adds three connected destinations with distinct reasons to trade: Sunfall Exchange exports licensed saltglass and lamp oil, Kiln Rest exports oil and dune spice, and Mirror Wells pays for beacon fuel, medicine, and signal glass. The region supports ordinary merchant play without contracts, an optional short-deadline beacon-oil delivery, a deterministic Shardwind road decision, and a failure-forward Night Market when official relief is ignored or missed.

The regional map connects the existing Hollow Market edge to Sunfall Exchange and Kiln Rest through the Glasswind Trace, then reaches Mirror Wells through the Mirror Run. Both roads have distinct palettes, silhouettes, costs, risks, and descriptions. The Bazaar gives all three settlements authored glass, kiln, or mirror landmarks, while the Night Market becomes a visible and interactable local service rather than a hidden state flag.

## Enforced acceptance contract

- Runtime content version `1.23.0` validates two regions, ten goods, eight settlements, five routes, three standing factions, and two independent adaptive scenarios.
- `tests/test_second_region.gd` covers profitable ordinary lamp-oil trade, the Shardwind encounter, event-boundary save/resume, optional contract success, ignored-contract expiry, Night Market activation, local interaction, and save/load persistence.
- `tests/test_campaign.gd` proves all eight settlements remain connected through player-legal route segments.
- `tests/test_runtime_world_validator.py` rejects malformed, overlapping, incomplete, and unknown region membership.
- Native capture evidence follows the player-facing Glasswind market → jobs → departure → road stop → encounter → arrival flow, then proves the failed-scenario Night Market at Mirror Wells.
- `tools/validate_native_captures.py` checks the region, Bazaar, road, event, adaptive state, responsive bounds, visual transitions, and absence of developer surfaces.

## Verification

Run:

```bash
MARKET_GODOT_BIN=/path/to/godot ./scripts/verify_ma_ea_2.sh
```

The gate is complete only when `MA-EA-2 acceptance: PASS` is printed. The implementation was verified locally with Godot `4.4.1.stable.official.49a5bc7b6`: every deterministic suite passed, and 160 native frames passed render validation across 960×540, 1280×720, 1600×900, and 1920×1080.

A fresh Windows Desktop export also passed structural validation as a 98,140,032-byte x86-64 executable with a 619,892-byte embedded PCK. The macOS export reported the expected missing-`rcedit` warning; Windows CI remains authoritative for resource stamping.

## Boundaries

Glasswind Reach uses code-native provisional visuals and the shared temporary presentation kit. It completes the second-region mechanical contract, not the full Early Access breadth floor. The third playable region, fourth standing faction, broader crew/event set, alternate-ending expansion, and final release hardening remain MA-EA-3 through MA-EA-6.
