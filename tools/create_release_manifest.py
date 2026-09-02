#!/usr/bin/env python3
"""Create the provenance manifest shared by local and tagged release builds."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def create_manifest(root: Path, output: Path, commit: str, ref: str, run_id: str, run_number: str) -> dict[str, object]:
    manifest = json.loads((root / "tools/ci_manifest.json").read_text(encoding="utf-8"))
    project = (root / "project.godot").read_text(encoding="utf-8")
    version_match = re.search(r'^config/version="([^"]+)"', project, re.MULTILINE)
    if version_match is None:
        raise AssertionError("project.godot is missing config/version")
    runtime = json.loads((root / "content/runtime_world.json").read_text(encoding="utf-8"))
    manifest.update(
        {
            "game_version": version_match.group(1),
            "content_version": runtime["content_version"],
            "commit": commit,
            "ref": ref,
            "run_id": run_id,
            "run_number": run_number,
        }
    )
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    return manifest


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--ref", required=True)
    parser.add_argument("--run-id", default="local")
    parser.add_argument("--run-number", default="local")
    args = parser.parse_args()
    manifest = create_manifest(args.repo.resolve(), args.output.resolve(), args.commit, args.ref, args.run_id, args.run_number)
    print(json.dumps(manifest, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
