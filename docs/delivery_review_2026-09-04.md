# Journey-phase delivery review — 2026-09-04

## Evidence and scope

Reviewed the completion-aware 1280×720 ordinary-trade journey in player order, then compared its road and arrival frames with the validated 1600×900 capture. This is a presentation review; it makes no balance or human-comprehension claim. No exported human pacing report was available, so dwell time and hesitation remain unknown.

## Major finding — stale journey-rail identity

**Frames:** Departure Desk, road stop, roadside encounter, and arrival.

**Visible evidence:** The right rail retained `DEPARTURE DESK` after the caravan had committed, stopped on the road, met an encounter, and arrived at Reedwatch. The status and actions changed correctly underneath it.

**Player cost:** The repeated planning title weakened the Bazaar → Departure → road → encounter → arrival rhythm. Arrival read as a modified planning panel instead of a destination handoff.

**Change:** The rail now derives a phase title from the existing read-only journey presenter: `DEPARTURE DESK`, `ON THE ROAD`, `ROAD STOP`, `ROADSIDE DECISION`, or `ARRIVED AT <SETTLEMENT>`. Repeated generic context labels were tightened while authored event names and all factual costs remained unchanged.

**Verification:** The completion fixture requires the expected title at the canonical Departure, road, encounter, and arrival states. The label is also a required visible control in those 1280×720 captures. Native capture and pixel validation pass at 960×540, 1280×720, and 1600×900.

## Remaining judgment

The arrival receipt still carries intentionally explicit comparison detail. Only moderated observation can show whether new players read the causal receipt or move directly to the Bazaar; this pass does not shorten or hide that information without evidence.

## Follow-up — recognizable road endpoints

The same evidence review found that every road endpoint used one generic block-and-flag silhouette. Road scenes now reuse the settlement motifs already established in the Bazaar: Ashgate's gate, Reedwatch's reeds, Brine Cross's pans, forge or kiln stacks, lantern and quay lines, glass or mirror marks, watchtowers, and peat smoke. The route frame retains the written settlement names and color-independent geometry.

Fresh 1280×720 evidence covers the Five-Well Basin, Glasswind Reach, and Siltfire March in `docs/visual_evidence/v0.16.1-road-endpoint-identity-2026-09-04/`.
