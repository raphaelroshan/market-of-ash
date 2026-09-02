#!/usr/bin/env python3
"""Validate version alignment and release-facing documentation."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


SEMVER_CANDIDATE = re.compile(r"^(\d+)\.(\d+)\.(\d+)-early-access-rc(\d+)$")
REQUIRED_RELEASE_SECTIONS = (
    "## Install",
    "## Upgrade and save compatibility",
    "## Rollback",
    "## What to test",
    "## Known limitations",
    "## Verification",
)
REQUIRED_PRIVATE_ALPHA_TERMS = (
    "30–90 minutes",
    "operates offline",
    "automatic `.bak`",
    "physical controller",
    "1600×900",
    "provenance",
)


def _setting(text: str, name: str, source: str) -> str:
    match = re.search(rf'^{re.escape(name)}="([^"]+)"$', text, re.MULTILINE)
    if match is None:
        raise AssertionError(f"{source}: missing {name}")
    return match.group(1)


def validate_release_contract(root: Path) -> dict[str, str]:
    project = (root / "project.godot").read_text(encoding="utf-8")
    presets = (root / "export_presets.cfg").read_text(encoding="utf-8")
    manifest = json.loads((root / "tools/ci_manifest.json").read_text(encoding="utf-8"))
    runtime = json.loads((root / "content/runtime_world.json").read_text(encoding="utf-8"))

    game_version = _setting(project, "config/version", "project.godot")
    match = SEMVER_CANDIDATE.fullmatch(game_version)
    if match is None:
        raise AssertionError("project version must identify an early-access release candidate")
    windows_version = ".".join((*match.groups()[:3], "0"))
    for setting in ("application/file_version", "application/product_version"):
        actual = _setting(presets, setting, "export_presets.cfg")
        if actual != windows_version:
            raise AssertionError(f"{setting} is {actual}, expected {windows_version}")

    if manifest.get("release_ready") is not True:
        raise AssertionError("tools/ci_manifest.json must mark the candidate release_ready")
    private_alpha = manifest.get("private_alpha")
    if not isinstance(private_alpha, dict):
        raise AssertionError("tools/ci_manifest.json must declare private_alpha requirements")
    if (
        private_alpha.get("minimum_session_minutes") != 30
        or private_alpha.get("maximum_session_minutes") != 90
        or private_alpha.get("offline_required") is not True
    ):
        raise AssertionError("private_alpha must require a 30–90 minute offline session")
    notes_relative = manifest.get("release_notes")
    if not isinstance(notes_relative, str) or notes_relative != f"docs/releases/v{game_version}.md":
        raise AssertionError("release_notes must match the project version")
    notes_path = root / notes_relative
    notes = notes_path.read_text(encoding="utf-8")
    for section in REQUIRED_RELEASE_SECTIONS:
        if section not in notes:
            raise AssertionError(f"release notes are missing {section}")
    for term in REQUIRED_PRIVATE_ALPHA_TERMS:
        if term not in notes:
            raise AssertionError(f"release notes are missing private-alpha requirement: {term}")
    content_version = runtime.get("content_version")
    if not isinstance(content_version, str) or f"Content: `{content_version}`" not in notes:
        raise AssertionError("release notes must name the runtime content version")
    if "Save format: `12`" not in notes:
        raise AssertionError("release notes must name the supported save format")

    release_workflow = (root / ".github/workflows/release.yml").read_text(encoding="utf-8")
    capture_marker = "\n  capture-1600:\n"
    candidate_marker = "\n  release-candidate:\n"
    publish_marker = "\n  publish-release:\n"
    if capture_marker not in release_workflow or candidate_marker not in release_workflow:
        raise AssertionError("release workflow must define separate 1600 capture and Windows candidate jobs")
    capture_job = release_workflow.split(capture_marker, 1)[1].split(candidate_marker, 1)[0]
    for token in (
        "runs-on: ubuntu-latest",
        "MARKET_CAPTURE_GEOMETRIES: 1600x900",
        "xvfb-run",
        "-screen 0 1920x1080x24",
        "private-alpha-1600-${{ github.run_id }}",
    ):
        if token not in capture_job:
            raise AssertionError(f"release 1600 capture job is missing: {token}")
    candidate_job = release_workflow.split(candidate_marker, 1)[1].split(publish_marker, 1)[0]
    for token in (
        "needs: [capture-1600]",
        "actions/download-artifact@v7",
        "python tools/package_capture_evidence.py",
    ):
        if token not in candidate_job:
            raise AssertionError(f"Windows release candidate job is missing: {token}")
    return {
        "game_version": game_version,
        "windows_version": windows_version,
        "content_version": content_version,
        "release_notes": notes_relative,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", type=Path, default=Path.cwd())
    args = parser.parse_args()
    details = validate_release_contract(args.repo.resolve())
    print(
        "Release contract validation: PASS "
        f"(game {details['game_version']}, content {details['content_version']}, "
        f"Windows {details['windows_version']})"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
