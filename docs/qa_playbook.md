# Agent-First QA Playbook

This repository uses a layered QA contract. The existing game-specific verifier remains authoritative for simulation, content, release, and acceptance behavior. The shared agent QA wrapper adds evidence truth, timing, and artifact preservation; it does not replace domain tests.

## Required agent loop

Before editing, record the current commit, game version, Godot version, viewport, renderer, locale, and baseline command. Run `bash scripts/agent_qa.sh` and preserve `artifacts/agent-qa/qa-result.json` even when the baseline fails.

Select one unfinished roadmap task. State the player-facing objective, authoritative owner, presentation owner, non-goals, acceptance criteria, expected state sequence, screenshot states, save checkpoints, and time budget before changing code. Large tasks are acceptable, but they must expose independently verifiable checkpoints.

After editing, run the focused test, then `bash scripts/agent_qa.sh`, then the named end-to-end scenario for the changed claim. A result must be classified as `PASS`, `FAIL`, `BLOCKED_ENVIRONMENT`, `TIMEOUT_PARTIAL`, or `INVALID_EVIDENCE`. Do not call a timeout a pass.

## Evidence contract

Every QA output must identify the game, commit, version, engine, viewport, renderer, locale, seed, input trace, state identifier, screenshot path, duration, exit code, and known limitation. Screenshots must be captured after a named readiness condition and fixed frame/tick boundary. A blank, uniform, wrong-size, or semantically wrong screenshot is invalid evidence.

Simulation authority must remain in the core layer. UI, audio, animation, screenshot timing, and visual effects may not decide prices, damage, targeting, route outcomes, persistence, or endings.

## Commands

```bash
# Fast local evidence bundle; all games use their existing verifier.
bash scripts/agent_qa.sh

# Longer run when the full suite is known to be slow.
AGENT_QA_TIMEOUT_SECONDS=1800 bash scripts/agent_qa.sh

# Disable the title capture when only logic verification is needed.
AGENT_QA_CAPTURE=0 bash scripts/agent_qa.sh
```

The first implementation of `agent_qa.sh` runs the existing verifier and captures a readiness-validated title frame. Game-specific semantic journeys should be added to `qa/scenarios/` and wired to existing Godot fixtures rather than simulated with sleeps or coordinate clicks.

## PR report format

Agents must report changed files, baseline and final result tables, exact commands, durations, screenshot paths, state traces, deterministic hashes where available, remaining limitations, and one next task. Visual changes require an intentional-baseline note describing what changed and what contract remains unchanged.

## Current game-specific priorities

Market of Ash: add a semantic ordinary-trade round trip from first purchase through route, departure, event, arrival, return market, and terminal receipt. Pack the Keep: add a semantic Greywatch run from War Council through placement, three waves, intervention, damage, Recovery, and Results. The Long March: profile slow verifier groups and add a semantic clean-save journey through route, contact, consequence, recovery, arrival, and Debrief.
