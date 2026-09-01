# MA-EA-1 — Responsive Basin Completion

**Status:** Complete
**Scope:** Five-Well Basin presentation anchor only
**Next milestone:** MA-EA-2 compact second-region trade slice

## Player result

A fresh player can move from Main Menu through the introduction, Ashgate Bazaar, a real contract and purchase, Departure Desk, an in-between road view, a deterministic encounter, arrival, return trade, crew assignment, Town Outlook, and save/resume without using or seeing a developer control.

The Basin shell is supported at 960×540, 1280×720, 1600×900, and 1920×1080. Large Text and Reduce Travel Motion preserve the same decisions and required actions. Keyboard and controller flows retain explicit focus handoffs.

## Enforced acceptance contract

- `tests/test_tutorial_flow.gd` checks the complete two-journey onboarding at each major transition and rejects developer panel, diagnostics, report tooling, or debug semantic actions.
- `tools/capture_native_ui.gd` creates the opening contract and purchase through player-facing handlers rather than a one-click fixture.
- Every native capture records a release-surface invariant. `tools/validate_native_captures.py` rejects a frame if the developer panel, diagnostics, or report action is visible.
- The runtime one-click purchase helper and its semantic action have been removed. Tests and evidence use the ordinary Buy action.
- `scripts/verify_ma_ea_1.sh` combines the repository's deterministic, save, input, campaign, policy, and Windows-export validator suites with the full four-viewport native render matrix.

## Verification

Run:

```bash
MARKET_GODOT_BIN=/path/to/godot ./scripts/verify_ma_ea_1.sh
```

The gate is complete only when `MA-EA-1 acceptance: PASS` is printed. Generated screenshots are evidence, not source assets, and are written to a temporary directory unless an output path is supplied.

The release preset was also exported locally and checked with `python3 tools/validate_windows_export.py`; the x86-64 executable and embedded PCK passed structural validation. Resource stamping remains authoritative in Windows CI because the local macOS editor has no `rcedit` binary.

## Boundaries

MA-EA-1 does not claim Early Access breadth. The two neighboring regions, four required play paths across the broader sandbox, expanded faction/replacement content, and final release hardening remain MA-EA-2 through MA-EA-6. Temporary procedural visuals remain honestly provisional.
