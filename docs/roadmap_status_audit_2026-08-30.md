# Market of Ash — Roadmap Status Audit

**Audit date:** 2026-08-30

**Audited branch:** `origin/main`

**Current build:** `0.13.2-alpha-basin-vertical-slice`

**Engine:** Godot 4.4.1

## Executive finding

Market of Ash has completed the **deterministic Five-Well Basin vertical-slice milestone**, but it has not completed the broader **game-quality private-alpha roadmap**. The wording that the roadmap is “complete” is accurate only when referring to the bounded mechanical and verification milestone. It is inaccurate if read as a claim of commercial, visual, or player-comprehension readiness.

## Verified complete

The current main branch passes the repository verification suite. The verified foundation includes ordinary trade, local demand, route comparison, disclosed journey risk, authored events, arrival consequences, adaptive Well Commons response, replacement-faction interaction, alternate ending logic, save/load recovery, controller and accessibility coverage, deterministic replay metrics, and packaged-build validation surfaces.

The latest test report also records a complete authored path from title through introduction, ordinary Bazaar trade, itinerary comparison, a road beat, encounter, arrival, changed destination market, and campaign debrief. These are valid completion claims for the vertical-slice systems contract.

## Verified incomplete

A fresh launch of the current `0.13.2-alpha-basin-vertical-slice` build at 1280×720 still shows horizontal clipping in the right-side Main Menu controls. The Introduction screen also clips the heading, explanatory copy, and lower controls beyond the right edge. This is visible in the current audit captures and means the responsive presentation contract is not complete.

The current evidence does not yet establish a polished complete player journey at the presentation layer. A passing automated traversal proves deterministic operation and bounds checks; it does not prove that the full path reads as a commercial-quality experience without developer explanation.

The art remains procedural alpha presentation, the package is unsigned and portable, and Windows high-DPI hardware, physical-controller feel, screen-reader behavior, antivirus reputation, and storefront behavior remain release-hardening work.

## Correct status language

Use this status:

> **The Market of Ash deterministic Five-Well Basin vertical slice is complete and verified. The game-quality private-alpha roadmap remains in progress, beginning with responsive shell repair and full-flow presentation validation.**

Do not use “the game-quality roadmap is complete,” “commercial alpha ready,” or “storefront ready.”

## Remaining execution order

1. Repair the responsive shell at 1280×720, 1600×900, minimum supported width, large text, reduced motion, and controller focus.
2. Re-capture Main Menu and Introduction after the fix and verify that every required control and sentence remains inside the viewport.
3. Verify the complete Introduction → Bazaar → Departure → road → event/contact → arrival receipt → return Bazaar path from a clean save at both target viewports.
4. Finish the Bazaar hierarchy and route comparison so ordinary trade remains valuable without forcing contracts or a single route.
5. Extract presentation panels from `src/ui/main.gd` while preserving the authoritative command boundary.
6. Add one controlled settlement-identity or adaptive-replacement slice only after presentation gates pass.
7. Complete private-alpha hardening for signed/package artifacts, scaling, controller, accessibility, save recovery, and provenance.

Human testing is optional later calibration and is not a prerequisite for this sequence. Automated verification, deterministic replay, scripted launches, layout assertions, and screenshot evidence are the active gates.

## Evidence

- [Latest automated test report](latest_test_report_2026-08-30.md)
- [Latest visual review](latest_visual_review_2026-08-30.md)
- [Current visual evidence gallery](visual_evidence_gallery.md)
