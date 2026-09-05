#!/usr/bin/env python3
"""Run a repository verifier and emit an agent-readable QA evidence bundle."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import time
from pathlib import Path


def load_scenario(root: Path, scenario_arg: str | None) -> tuple[dict[str, object], str | None]:
    if not scenario_arg:
        return {"status": "NOT_CONFIGURED"}, None
    path = Path(scenario_arg)
    if not path.is_absolute():
        path = root / path
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:  # noqa: BLE001 - report malformed agent input as evidence
        return {"status": "INVALID_MANIFEST", "path": str(path), "error": str(exc)}, None
    required = {"schema_version", "game", "scenario_id", "status", "expected_states", "semantic_commands", "checkpoints", "screenshot_states", "time_budget_ms"}
    missing = sorted(required - set(data))
    if missing:
        return {"status": "INVALID_MANIFEST", "path": str(path), "missing": missing}, None
    if not isinstance(data["expected_states"], list) or not data["expected_states"]:
        return {"status": "INVALID_MANIFEST", "path": str(path), "error": "expected_states must be a non-empty list"}, None
    if not isinstance(data["semantic_commands"], list) or not data["semantic_commands"]:
        return {"status": "INVALID_MANIFEST", "path": str(path), "error": "semantic_commands must be a non-empty list"}, None
    summary = {
        "status": "PLANNED" if data.get("status") == "planned" else str(data.get("status")),
        "path": str(path),
        "scenario_id": data["scenario_id"],
        "declared_game": data["game"],
        "expected_state_count": len(data["expected_states"]),
        "semantic_command_count": len(data["semantic_commands"]),
        "checkpoint_count": len(data["checkpoints"]),
        "screenshot_state_count": len(data["screenshot_states"]),
        "time_budget_ms": data["time_budget_ms"],
    }
    return summary, json.dumps(data, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify", nargs="+", required=True, help="Verifier command")
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--game", required=True)
    parser.add_argument("--scenario", help="Scenario manifest path relative to the repository root")
    args = parser.parse_args()

    root = Path.cwd()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    scenario, scenario_text = load_scenario(root, args.scenario)
    if scenario_text is not None:
        (output / "scenario-manifest.json").write_text(scenario_text, encoding="utf-8")
    started = time.time()
    env = os.environ.copy()
    env.setdefault("GODOT_SILENCE_ROOT_WARNING", "1")
    command = list(args.verify)
    result: dict[str, object] = {
        "schema_version": 2,
        "game": args.game,
        "command": command,
        "cwd": str(root),
        "timeout_seconds": args.timeout,
        "started_unix": started,
        "status": "UNKNOWN",
        "scenario": scenario,
    }
    if scenario.get("status") == "INVALID_MANIFEST":
        result.update({"status": "INVALID_EVIDENCE", "exit_code": 2, "duration_ms": 0.0, "note": "Scenario manifest is invalid; no verifier was run."})
        (output / "qa-result.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(result, indent=2))
        return 1
    try:
        completed = subprocess.run(
            command,
            cwd=root,
            env=env,
            text=True,
            capture_output=True,
            timeout=args.timeout,
            check=False,
        )
        duration_ms = round((time.time() - started) * 1000, 2)
        (output / "verify.stdout.log").write_text(completed.stdout, encoding="utf-8")
        (output / "verify.stderr.log").write_text(completed.stderr, encoding="utf-8")
        result.update({
            "status": "PASS" if completed.returncode == 0 else "FAIL",
            "exit_code": completed.returncode,
            "duration_ms": duration_ms,
            "stdout_log": "verify.stdout.log",
            "stderr_log": "verify.stderr.log",
        })
    except subprocess.TimeoutExpired as exc:
        duration_ms = round((time.time() - started) * 1000, 2)
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        (output / "verify.stdout.log").write_text(stdout, encoding="utf-8")
        (output / "verify.stderr.log").write_text(stderr, encoding="utf-8")
        result.update({
            "status": "TIMEOUT_PARTIAL",
            "exit_code": 124,
            "duration_ms": duration_ms,
            "stdout_log": "verify.stdout.log",
            "stderr_log": "verify.stderr.log",
            "note": "Verifier timed out; inspect logs and per-suite markers before classifying as a game failure.",
        })
    (output / "qa-result.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if result["status"] == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
