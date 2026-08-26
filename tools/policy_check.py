#!/usr/bin/env python3
"""Deterministic CI policy checks shared by the three game repositories."""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
from pathlib import Path

SECRET_PATTERNS = [
    # Match assignments or literal credentials, not harmless references such as os.environ.get("OPENAI_API_KEY").
    re.compile(r"(?:OPENAI_API_KEY|BUILT_IN_FORGE_API_KEY|AWS_SECRET_ACCESS_KEY)\s*[:=]\s*['\"][^'\"]{12,}['\"]", re.I),
    re.compile(r"Authorization:\s*Bearer\s+[A-Za-z0-9._-]{20,}", re.I),
    re.compile(r"(?:ghp_|github_pat_|sk-)[A-Za-z0-9_-]{16,}"),
    re.compile(r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY", re.I),
]


def git_diff_names(base: str, root: Path) -> list[str]:
    result = subprocess.run(["git", "diff", "--name-only", f"{base}...HEAD"], cwd=root, check=False, capture_output=True, text=True)
    if result.returncode != 0:
        return []
    return [line for line in result.stdout.splitlines() if line]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", required=True)
    parser.add_argument("--base", default="HEAD~1")
    args = parser.parse_args()
    requested_root = Path(args.repo).expanduser()
    root = requested_root.resolve() if requested_root.exists() else Path.cwd().resolve()
    errors: list[str] = []
    warnings: list[str] = []

    required = ["project.godot", "AGENTS.md", "README.md", "tests"]
    for item in required:
        if not (root / item).exists():
            errors.append(f"required path missing: {item}")

    gd_files = list(root.glob("**/*.gd"))
    test_files = list((root / "tests").glob("**/*")) if (root / "tests").exists() else []
    if gd_files and not any(path.suffix == ".gd" for path in test_files):
        errors.append("GDScript exists but tests/ contains no GDScript test")

    changed = git_diff_names(args.base, root)
    if changed and any(path.endswith(".gd") for path in changed) and not any("test" in path.lower() for path in changed):
        warnings.append("GDScript changed without a changed test file; review coverage manually")

    for path in root.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        relative = str(path.relative_to(root))
        if ".godot" in path.parts or path.suffix in {".save", ".log"} or "user://" in relative:
            warnings.append(f"generated/local-looking file present: {relative}")
        if path.stat().st_size > 5_000_000:
            errors.append(f"large artifact exceeds 5 MB: {relative}")
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        for pattern in SECRET_PATTERNS:
            if pattern.search(text):
                errors.append(f"possible secret pattern in: {relative}")
                break

    print(f"repository={args.repo}")
    for warning in warnings:
        print(f"WARNING: {warning}")
    for error in errors:
        print(f"ERROR: {error}")
    if errors:
        return 1
    print("PASS: repository policy checks")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
