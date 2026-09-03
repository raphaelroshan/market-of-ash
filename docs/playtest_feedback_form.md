# Market of Ash — Structured Alpha Feedback

Do not collect names, email addresses, account IDs, or other unnecessary personal data.

## Build context

Use **Export playtest report** from the Pause menu or ending debrief and attach the resulting JSON when practical. Desktop builds write the named local file; Web builds trigger a browser download. Report version 7 contains no personal or controller identifiers and records the build, platform, broad last-input type, active key/button mappings, viewport and display scale, presentation settings, session duration, observed time to first trade, and a bounded timeline of screen/context transitions and command outcomes. Nothing is transmitted automatically.

For a single report or a small cohort, generate a deterministic timing summary with:

```bash
python3 tools/analyze_playtest_pacing.py <report.json> [more-report.json ...]
```

Timing signals identify moments to inspect. Pair them with the comprehension answers below; a short dwell does not prove understanding, and a long dwell may be deliberate planning rather than friction.

- Build commit/version:
- Platform and OS version:
- Input device: mouse / keyboard / controller (model optional):
- Display resolution and OS scale:
- Seed shown in Diagnostics:
- Approximate play time:
- Starting path: Guided New Game / New Game without guidance / Continued campaign / debug QA scenario (included automatically in the report)

## Run record

- Time to first intentional trade:
- First cargo, quantity, destination, and route:
- First route event and response:
- Contract accepted/completed/failed:
- Crew recruited/assigned:
- Ending reached, or day/stage when stopped:
- Did you use Save/Load or recover from a setback? What happened?

## Comprehension prompts

1. Before your first purchase, why did you expect that cargo to be valuable elsewhere?
2. Before departure, what did the route cost and what was exposed?
3. After the first event or incident, what changed and what did you plan to do next?
4. What action changed a market, route, relationship, resilience, or escalation state?
5. If you reached an ending, which decisions do you think caused it?

## Problems

- Blocker or confusing moment:
- Exact screen/action immediately before it:
- Expected result:
- Actual result:
- Save summary and last-command value shown in Diagnostics:
- Could you continue without restarting? yes / no

## One-sentence story

Complete: “In this run, I _____ because _____, which caused _____.”

## Closing rating

- I understood why prices differed: 1–5
- I understood the route tradeoff before committing: 1–5
- I understood how to recover after a setback: 1–5
- I could navigate comfortably with my chosen input: 1–5
- One thing that should change before the next build:
