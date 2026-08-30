# Market of Ash — Departure Clarity Patch Test Report

## Candidate

| Field | Result |
|---|---|
| Release | `v0.13.1-alpha-basin-vertical-slice` |
| Engine | Godot 4.4.1 |
| Scope | First-time Departure forecast comprehension |
| Simulation impact | None; presentation only |

## Finding

The released 0.13.0 Departure screen could show `CARGO 60 → 128` and `NET +48` beside `Cargo: empty`. Although the detailed forecast later explained the selected quantity versus the actual hold, the comparison card itself could be read as value already aboard. The commit action also did not repeat that the selected forecast load was absent.

## Resolution

The comparison card now says `PLAN Water x4 · HELD 0`, labels the result `IF BOUGHT`, and retains the profit/loss consequence. The committing action says `Set out without planned load` while leaving empty travel legal. Once the planned quantity is held, the same cards say `READY` and the conventional confirmation label returns.

## Evidence

The affected state passed the real-renderer capture validator at 1280×720 and 1600×900, including Large text. Curated images and capture provenance are under [`docs/visual_evidence/v0.13.1-alpha-basin-vertical-slice/`](visual_evidence/v0.13.1-alpha-basin-vertical-slice/).

![Unloaded Departure plan at 1600×900](visual_evidence/v0.13.1-alpha-basin-vertical-slice/departure-empty-plan-1600x900.png)

![Unloaded Departure plan with Large text at 1280×720](visual_evidence/v0.13.1-alpha-basin-vertical-slice/departure-empty-plan-large-text-1280x720.png)

## Verification

- Presenter regressions cover unloaded `IF BOUGHT` and loaded `READY` states.
- The UI smoke enters Departure from an empty Bazaar, checks the cards and commit copy, returns without mutation, then later confirms the loaded path.
- The complete repository verification suite passes locally; packaged Linux, Windows, native-render, and browser CI remain the merge gate.

## Interpretation

This is an evidence-backed interface correction from an agent-led clean-flow audit, not a substitute for a moderated human session. It removes one observable ambiguity before that session.
