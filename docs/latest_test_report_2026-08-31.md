# Market of Ash — Large-Text Route Selection Patch Test Report

## Candidate

| Field | Result |
|---|---|
| Release | `v0.13.2-alpha-basin-vertical-slice` |
| Engine | Godot 4.4.1 |
| Scope | Departure selection visibility with Large text |
| Simulation impact | None; presentation only |

## Finding

The 0.13.1 clarity patch correctly separated planned cargo from the actual hold, but its taller itinerary copy exposed a constrained-window issue: at 1280×720 with Large text, the selected card could clip the literal `SELECTED` line. The border still changed, but selection could no longer be understood from text alone.

## Resolution

Large-text itinerary cards now receive additional vertical capacity, including cards already present when the setting is toggled. Compact `DAY` and `PROV` labels reduce wrapping while retaining every disclosed cost. The selected card again begins with `SELECTED`, and the return and commitment actions remain pinned below the scrollable comparison.

## Evidence

The affected state passed the real-renderer capture validator at 1280×720 and 1600×900 with Large text. Curated images and capture provenance are under [`docs/visual_evidence/v0.13.2-alpha-basin-vertical-slice/`](visual_evidence/v0.13.2-alpha-basin-vertical-slice/).

![Selected Departure route with Large text at 1600×900](visual_evidence/v0.13.2-alpha-basin-vertical-slice/departure-selected-large-text-1600x900.png)

![Selected Departure route with Large text at 1280×720](visual_evidence/v0.13.2-alpha-basin-vertical-slice/departure-selected-large-text-1280x720.png)

## Verification

- Presenter regressions cover unloaded `IF BOUGHT`, loaded `READY`, and the compact route labels.
- The UI smoke enters Departure from an empty Bazaar, enables Large text, and verifies card height, the explicit selection label, route costs, and pinned actions.
- The complete repository verification suite passes locally; packaged Linux, Windows, native-render, and browser CI remain the merge gate.

## Interpretation

This is an evidence-backed accessibility correction from an agent-led clean-flow audit, not a substitute for a moderated human session. It preserves redundant selection communication before that session.
