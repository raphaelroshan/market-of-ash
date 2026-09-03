---
name: market-of-ash-delivery-review
description: Review Market of Ash screenshots or captured journeys for game-like delivery, visual hierarchy, spatial continuity, anticipation, consequence, recovery, and place or character identity. Use for visual reviews and presentation-polish planning. Do not use for simulation correctness or balance claims.
---

# Market of Ash delivery review

Evaluate whether the existing trade-and-travel systems are delivered as a coherent journey rather than a sequence of forms.

## Required evidence

Use images from one consistent build and viewport. Prefer a complete sequence containing Main Menu, Introduction, Bazaar, Departure, moving caravan, road stop, encounter, arrival, changed Bazaar, and terminal receipt. Compare 1280×720 and 1600×900 when the finding concerns hierarchy or composition.

Inspect screenshots visually. Do not infer presentation quality from source code. Read `design/design_prompt.md` for the intended emotional rhythm and `docs/ux/frontier_reference_notes.md` for the project's interpretation of Frontier; do not copy another game's assets or layouts.

## Review lenses

- **Orientation:** Can the player name the place, current caravan state, immediate opportunity, and next reversible action?
- **Hierarchy:** Do cargo, destination, road cost, exposure, and commitment outrank explanation and diagnostics?
- **Continuity:** Does departure visibly become travel, encounter, arrival, and a changed market without teleporting or bypassing the road?
- **Anticipation:** Is the chosen risk visible before commitment without presenting a fake best answer?
- **Consequence:** Does the result visibly change cargo, money, road, market, relationship, or future opportunity?
- **Recovery:** After loss or a blocked action, is the next viable move concrete and prominent?
- **Identity:** Are caravan, settlement, route, character, and faction silhouettes distinguishable without relying only on labels or color?
- **Restraint:** Remove duplicate status, repeated prose, and equal-weight controls before adding decoration.

## Workflow

1. Review the sequence in player order, then revisit individual frames.
2. Record only visible evidence. Separate defects from taste and hypotheses from facts.
3. Identify the single frame where the intended emotional beat is weakest.
4. Recommend the smallest coherent presentation change and name the screens it must preserve.
5. Specify before/after captures and readable-control assertions at supported viewports.
6. If a new raster asset would materially improve the chosen beat and image generation is available, use `imagegen`; otherwise prefer the existing visual registry and replaceable asset paths.

## Output

Prioritize findings as blocker, major, or polish. For each finding provide the frame, visible evidence, player cost, proposed change, and verification capture. End with one next implementation slice, not a broad art backlog.
