# Agent QA Decision Record

## Decision

Adopt a shared repository-owned agent QA layer across Market of Ash, Pack the Keep, and The Long March. The layer consists of `docs/qa_playbook.md`, `tools/agent_qa_runner.py`, `tools/agent_qa_capture.gd`, `scripts/agent_qa.sh`, scenario manifests under `qa/scenarios/`, and CI evidence artifacts.

## Why this design

The repositories already contain valuable game-specific acceptance suites. Replacing them with a generic framework would risk losing domain knowledge and would delay work on the investment vertical. The shared layer therefore wraps the existing verifier, adds explicit result classification, captures stdout/stderr, measures duration, records the environment, and performs a readiness-aware Godot viewport capture.

## Trade-offs

The first implementation captures a validated title frame and defines semantic scenario manifests as the contract; it does not pretend that the manifests are already executable journeys. Wiring semantic commands to each game’s public command boundary is the next implementation step. This is preferable to a fake universal driver that relies on sleeps, coordinates, or assumptions about each game’s scene tree.

The capture script rejects empty, wrong-size, and visually uniform frames. This can expose renderer or startup problems earlier, but it may require per-game readiness signals for scenes whose first frame is intentionally sparse. Such exceptions must be explicit in the manifest rather than weakening the global check.

Third-party frameworks remain optional. If a framework is adopted, pin a Godot 4.4.1-compatible version and pilot it in one repository. The custom verifier remains authoritative for simulation, content, release, save, and campaign acceptance.

## Status vocabulary

`PASS` means the requested verifier completed successfully and the required evidence was produced. `FAIL` means an assertion, command, or capture failed. `TIMEOUT_PARTIAL` means the verifier exceeded its budget and partial logs are available; it is never equivalent to pass. `BLOCKED_ENVIRONMENT` means a required tool or binary was unavailable. `INVALID_EVIDENCE` means a screenshot or manifest could not prove the claimed state.

## Next decisions

1. Wire the three scenario manifests to semantic command adapters.
2. Add per-suite timing records to the existing long wrappers.
3. Add CI artifact upload for `artifacts/agent-qa/` on success and failure.
4. Add state-specific visual baselines after the semantic journeys produce stable evidence.
5. Pilot one compatible Godot test framework only if it reduces maintenance.
