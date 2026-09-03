---
name: market-of-ash-pacing
description: Audit Market of Ash playtest pacing from exported report JSON, especially first trade, departure, road consequence, arrival, return trade, and ending cadence. Use for pacing reviews, playtest synthesis, slow onboarding, repeated blocked actions, or deciding what to shorten. Do not use timing alone to claim that the game is fun or understood.
---

# Market of Ash pacing audit

Turn one or more deliberately exported playtest reports into a small, evidence-backed improvement packet.

## Evidence

Prefer report version 7 or newer from **Export playtest report**. It contains a bounded, privacy-safe `pacing_trace` of screen/context transitions and command outcomes. It does not contain player identity, free-form notes, hardware identifiers, or network data.

Run:

```bash
python3 tools/analyze_playtest_pacing.py <report.json> [more-report.json ...]
```

If reports are unavailable, use deterministic captures and tests only as provisional evidence. State that dwell time, hesitation, comprehension, and voluntary replay remain unknown.

## Product targets

Read the first-five, first-fifteen, and first-thirty-minute targets in `docs/game_quality_vertical_slice_roadmap.md`. Preserve these invariants:

- Ordinary trade remains complete without contracts.
- Routes disclose fee, provisions, time, exposure, and likely consequence before commitment.
- A setback remains recoverable during the first hour.
- The player sees the road between settlements; never bypass it to improve timing.
- Pacing fixes must not hide required information or move simulation rules into UI code.

## Analysis workflow

1. Run the analyzer and separate observed timing from interpretation.
2. For each high or medium signal, inspect its surrounding trace entries, command history, relevant screenshot, and tester comprehension answer.
3. Classify the issue as orientation, comprehension, deliberation, interaction friction, waiting, recovery, or missing payoff.
4. Propose the smallest player-facing change that addresses the evidence. Prefer clearer hierarchy, shorter copy, earlier feedback, or removing repetition over accelerating animations globally.
5. Define an observable acceptance check and the exact regression test or capture state that will protect it.
6. When implementation is requested, change one coherent pacing issue at a time and run the relevant Godot flow plus `python3 tests/test_playtest_pacing_analysis.py`.

## Output

Report:

- observed beat timeline;
- the strongest evidence-backed friction point;
- likely cause, labeled as a hypothesis;
- one to three prioritized changes;
- acceptance threshold for each change;
- missing human evidence.

Never convert a single tester's pause into a universal rule. Aggregate multiple reports when possible and preserve individual outliers.
