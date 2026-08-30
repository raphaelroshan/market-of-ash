# Market of Ash — Latest Visual Review

**Build:** `v0.13.0-alpha-basin-vertical-slice`

**Branch:** `origin/main`

**Engine:** Godot 4.4.1

**Capture:** 1280×720 Xvfb display; title and early introduction flow captured from a real launch.

## Verification

The full repository verification suite passed, including policy checks, runtime world validation, economy tests, presenter tests, campaign coverage, tutorial coverage, controller coverage, and game-quality gates. The project launches successfully and advances from the title screen into the introduction.

## Evidence

- [Title](visual_evidence/v0.13.0-alpha-basin-vertical-slice-review-2026-08-30/market_01_title.png)
- [Introduction](visual_evidence/v0.13.0-alpha-basin-vertical-slice-review-2026-08-30/market_02_first_action.png)
- [Follow-up](visual_evidence/v0.13.0-alpha-basin-vertical-slice-review-2026-08-30/market_03_followup.png)

## Findings

The title communicates a spare frontier-road premise and has a strong left-side illustration, but the right-side menu is clipped at the 1280×720 viewport edge. Menu labels are cut off horizontally. The introduction has the same issue more severely: the heading, body copy, and lower action area extend beyond the right edge, preventing the player from seeing the full explanation and all controls.

The deterministic economy and campaign systems are healthy. This is a presentation-blocking issue, not a simulation failure.

## Next roadmap sequence

1. Repair the responsive shell for Introduction, Bazaar, Departure, event, and arrival/debrief at 1280×720, 1600×900, the minimum supported width, large text, reduced motion, and controller focus.
2. Make the Bazaar answer local need, selected cargo, destination value, route risk, capacity, cash, and next action in one hierarchy while preserving ordinary buying and selling as a complete path.
3. Extract presentation panels from `src/ui/main.gd` without moving authoritative economy or campaign logic.
4. Add side-by-side route comparison for fee, days, provisions, value, risk, and practical consequence without automatic route selection.
5. Capture and verify a complete Introduction → Bazaar → Departure → road → event/contact → arrival receipt → return Bazaar sequence at 1600×900.
6. Only after the flow is readable, deepen existing settlement identity and add one adaptive replacement opportunity for an ignored or failed scenario.

Human testing is optional follow-up calibration and is not a prerequisite for these implementation steps. Automated tests, deterministic replay, layout bounds, and screenshot evidence are the active gates.
