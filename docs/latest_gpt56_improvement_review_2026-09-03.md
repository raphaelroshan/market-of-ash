# Market of Ash — GPT-5.6 improvement review

**Build:** `v0.15.0-early-access-rc2`  
**Review date:** 2026-09-03  
**Engine:** Godot 4.4.1  
**Evidence:** `docs/visual_evidence/v0.15.0-gpt56-review-2026-09-03/`

## Verification

The full repository verification suite passed after the implementation changes. The game-quality test reports 100/100 seeded openings completed, 100 profitable trials, zero bankruptcies, four viable trade-pattern families, eight positive opening strategies, ordinary trade remaining contract-free, adaptive replacement-faction behavior, and 25 deterministic world/save round trips in approximately 136 ms against a 5,000 ms budget. The focused tutorial flow also passed.

## Implemented improvement

The opening layout breakpoint now uses the actual Godot visible layout width before falling back to reported window metadata. The three introduction cards also use shorter, more scannable copy that preserves the original premise and tutorial meaning. This is presentation-only; the authoritative economy, tutorial state, commands, and save data remain unchanged.

## Remaining issue

The 1280×720 capture still shows the Introduction body reaching the right viewport edge. The breakpoint fix and copy reduction are safe improvements, but they do not fully solve the underlying container-width behavior. MA-GPT56-1 therefore remains active: inspect the `ResponsiveColumns`/`ScrollContainer` minimum-size negotiation, add a layout-bound assertion for all required introduction controls, and prove the complete Bazaar path in a normal clean save.

Do not solve this by hiding text, shrinking the entire UI, or making a contract mandatory. The next implementation should preserve 1600×900 quality while providing a deliberate narrow single-column composition at 1280×720.

## Next complex task

Issue `MA-GPT56-1` from `docs/gpt56_investment_execution_packets.md`: complete the first-purchase → route → departure → road consequence → arrival → changed return market → optional black-market pressure → terminal receipt path, with 1280×720 and 1600×900 screenshots, save/resume parity, controller focus, and deterministic replay.
