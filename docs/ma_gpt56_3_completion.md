# MA-GPT56-3 — Market Breadth and Non-Railroaded Play

**Status:** Complete  
**Next packet:** MA-GPT56-4 Early Access package

## Player result

All three regions now contain at least three settlements, three roads, three ordinary goods, optional work, an event family, faction pressure, a failure-forward response, and a post-consequence opportunity.

Siltfire March is the completed gap. Emberfen Refuge is a third market reached by the high-exposure Emberfen Drift. Cloth carried from Mothlight is profitable without a contract; the optional Smoke Cloth posting adds a guaranteed Bellkeeper premium. The `Smoke Without Bells` contact offers paid, material, delayed, and disclosed-risk responses. If the official smoke ward is ignored or fails, the Ash Sifters open a charcoal market and a kiln action that improves Emberfen resilience and marks a safer road.

The map now renders the current region and its authored gateway settlements, preserving the FTL-like network while preventing eleven global nodes from overlapping at 1280×720.

## Deterministic acceptance

- `tests/test_gpt56_regional_breadth.gd` enforces three settlements, three roads, three produced goods, optional work, events, factions, replacement actors, post-consequence actions, and contract-free endings in every region.
- `tests/test_third_region.gd` executes Emberfen ordinary trade, the smoke event, optional contract completion, ignored-contract replacement, Ash Sifter support, road improvement, and save/restore.
- `tests/test_investment_economy_matrix.gd` runs 100 seeded trials across five unrelated routes and four goods before any balance claim.
- The matrix completes 100/100 trials profitably with zero bankruptcies and no route above 20% usage.
- Native captures add Emberfen planning, departure, road, event, arrival, market, replacement opportunity, and result states.

The durable 1280×720 and 1600×900 sequence is in `docs/visual_evidence/v0.15.0-ma-gpt56-3-2026-09-03/`.

## Balance observation

The current 100-seed matrix reports mean profit `53.35`, nine cargo-loss trials, and equal 20-run use of Old Road, Mirror Run, Emberglass Byway, Reedline Track, and Emberfen Drift. Cloth appears in 20 trials, lamp oil in 40, medicine in 20, and water in 20. These are deterministic guardrails, not a claim of human-calibrated final balance.

## Save and authority boundary

The new content uses existing authoritative commands and save fields. Save version 12 already sanitizes scenario records against the current registry, adds missing authored scenario states, and preserves emergent actors, market changes, event history, route conditions, and support. No UI code calculates prices or resolves outcomes.

## Known deficiencies

- Emberfen art remains code-native production scaffolding.
- The Ash Sifters have one strong cooperation path; opposition and reconciliation remain optional post-alpha depth.
- Human playtesting is still needed to tune contract reward and smoke-event comprehension, but no implementation gate depends on it.
