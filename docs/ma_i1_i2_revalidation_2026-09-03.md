# MA-I1 / MA-I2 Game-Quality Revalidation

**Status:** Complete

**Candidate:** `0.16.1-early-access-rc1`

## Review finding resolved

The RC2 review captured a 1600-wide desktop window through a 1280-wide Xvfb surface. Introduction 2 therefore lost its right-side copy and navigation margin even though source-level bounds tests passed. The launch path now takes the smaller physical/usable screen boundary, including virtual displays, and no longer assumes a resolution argument guarantees a fitting native window.

`ResponsiveColumns` also stacks defensively before visible child minimum widths collide. The Introduction reading area no longer derives an intrinsic horizontal minimum from its prose, and native validation requires the opening card plus every progress, title, body, note, and action control to remain within explicit safe bounds.

## Clean-save trade proof

The named `gpt56_clean_investment_vertical` at seed `1107` executes through normal player commands:

1. open New Game and read all three Introduction cards;
2. buy ordinary Water without accepting a contract;
3. compare destination cost, time, provisions, exposure, and expected net;
4. depart, stop on the road, and resolve Three Riders;
5. arrive, sell, and read the changed destination price;
6. buy Grain, return, sell, and inspect the changed Ashgate market;
7. take or ignore the optional Cinder Rider pressure path;
8. reach the causal terminal receipt.

Save/restore parity remains asserted at every authored phase. The ordinary-only control reaches success without the black market.

## Evidence

Fresh real-renderer captures and complete manifests are in `docs/visual_evidence/v0.16.1-ma-i1-i2-revalidation-2026-09-03/` at 1280×720 and 1600×900. The same run also passed 960×540 including Large Text.

The validator accepted all 86 required states at every tested viewport. It enforces the opening safe area, control containment, distinct journey phases, ordinary purchase and sale receipts, market change, optional pressure, and terminal receipt.

## Known limits

Physical-controller, assistive-technology, antivirus-reputation, storefront, and moderated comprehension checks remain external calibration. No economy, command, save, or content authority moved into the UI.
