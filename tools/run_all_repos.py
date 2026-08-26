#!/usr/bin/env python3
"""Run the shared validation contract across the three local game repositories."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
from pathlib import Path

REPOS = {
    "market-of-ash": "market_of_ash",
    "the-cartographers-siege": "the_cartographers_siege",
    "pack-the-keep": "pack_the_keep",
}


def run(command: list[str], cwd: Path, allow_failure: bool = False) -> dict:
    result = subprocess.run(command, cwd=cwd, text=True, capture_output=True, check=False)
    record = {"command": command, "cwd": str(cwd), "returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr}
    if result.returncode and not allow_failure:
        raise RuntimeError(json.dumps(record, indent=2))
    return record


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default="/home/ubuntu")
    parser.add_argument("--output", default="artifacts/all_games_report.json")
    parser.add_argument("--ai", action="store_true", help="run AI reviews when OPENAI_API_KEY is configured")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    report = {"repositories": [], "verdict": "pass"}

    for slug, directory in REPOS.items():
        repo = root / directory
        entry = {"slug": slug, "path": str(repo), "checks": []}
        if not repo.exists():
            entry["verdict"] = "block"
            entry["checks"].append({"error": "repository directory missing"})
            report["verdict"] = "block"
            report["repositories"].append(entry)
            continue
        entry["checks"].append(run(["python3", "tools/policy_check.py", "--repo", slug], repo, allow_failure=True))
        entry["checks"].append(run(["bash", "scripts/verify.sh"], repo, allow_failure=True))
        diff_path = repo / "artifacts" / "local_change.diff"
        diff_path.parent.mkdir(parents=True, exist_ok=True)
        diff = run(["git", "diff", "HEAD~1", "HEAD"], repo, allow_failure=True)
        diff_path.write_text(diff["stdout"], encoding="utf-8")
        if args.ai:
            ai_path = repo / "artifacts" / "local_ai_review.json"
            entry["checks"].append(run(["python3", "tools/ai_review_runner.py", "--diff", str(diff_path), "--repo", slug, "--output", str(ai_path)], repo, allow_failure=True))
        if any(check.get("returncode", 0) != 0 for check in entry["checks"]):
            entry["verdict"] = "block"
            report["verdict"] = "block"
        else:
            entry["verdict"] = "pass"
        report["repositories"].append(entry)

    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"verdict": report["verdict"], "repositories": len(report["repositories"])}))
    return 1 if report["verdict"] == "block" else 0


if __name__ == "__main__":
    raise SystemExit(main())
