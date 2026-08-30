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
    re.compile(r"(?<![A-Za-z0-9_-])(?:ghp_|github_pat_|sk-)[A-Za-z0-9_-]{16,}"),
    re.compile(r"BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY", re.I),
]
WINDOWS_VERSION_PATTERN = re.compile(r"^[0-9]+(?:\.[0-9]+){0,3}$")


def valid_windows_version(value: str) -> bool:
    return bool(WINDOWS_VERSION_PATTERN.fullmatch(value))


def contains_secret(text: str) -> bool:
    return any(pattern.search(text) for pattern in SECRET_PATTERNS)


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

    for generated_directory in ["build", "artifacts", "research"]:
        directory = root / generated_directory
        if directory.exists() and not (directory / ".gdignore").is_file():
            errors.append(f"Godot-excluded directory is missing {generated_directory}/.gdignore")

    export_presets_path = root / "export_presets.cfg"
    if export_presets_path.is_file():
        preset_text = export_presets_path.read_text(encoding="utf-8")
        required_export_exclusions = ["build/*", "build/web/*", "artifacts/*"]
        for line_number, line in enumerate(preset_text.splitlines(), start=1):
            if not line.startswith("exclude_filter="):
                continue
            for exclusion in required_export_exclusions:
                if exclusion not in line:
                    errors.append(f"export preset exclusion missing {exclusion} at export_presets.cfg:{line_number}")
        for setting in ("application/file_version", "application/product_version"):
            match = re.search(rf'^{re.escape(setting)}="([^"]*)"$', preset_text, re.MULTILINE)
            if match is None or not valid_windows_version(match.group(1)):
                errors.append(f"Windows export requires a numeric {setting} with at most four components")

    gd_files = list(root.glob("**/*.gd"))
    test_files = list((root / "tests").glob("**/*")) if (root / "tests").exists() else []
    if gd_files and not any(path.suffix == ".gd" for path in test_files):
        errors.append("GDScript exists but tests/ contains no GDScript test")

    changed = git_diff_names(args.base, root)
    if changed and any(path.endswith(".gd") for path in changed) and not any("test" in path.lower() for path in changed):
        warnings.append("GDScript changed without a changed test file; review coverage manually")

    ignored_directories = {".git", ".godot", "artifacts", "build", "__pycache__"}
    for path in root.rglob("*"):
        if not path.is_file() or any(part in ignored_directories for part in path.parts):
            continue
        relative = str(path.relative_to(root))
        if path.suffix in {".save", ".log"} or "user://" in relative:
            warnings.append(f"generated/local-looking file present: {relative}")
        if path.stat().st_size > 5_000_000:
            errors.append(f"large artifact exceeds 5 MB: {relative}")
        try:
            text = path.read_text(encoding="utf-8", errors="ignore")
        except OSError:
            continue
        if contains_secret(text):
            errors.append(f"possible secret pattern in: {relative}")

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
