#!/usr/bin/env python3
"""Regression coverage for versioned Early Access release metadata."""

from __future__ import annotations

import json
import shutil
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.validate_release_contract import validate_release_contract
from tools.write_release_checksums import sha256, write_release_checksums


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    details = validate_release_contract(ROOT)
    assert details == {
        "game_version": "0.15.0-early-access-rc1",
        "windows_version": "0.15.0.0",
        "content_version": "1.27.0",
        "release_notes": "docs/releases/v0.15.0-early-access-rc1.md",
    }

    with tempfile.TemporaryDirectory() as temporary_directory:
        fixture = Path(temporary_directory)
        (fixture / "tools").mkdir()
        (fixture / "content").mkdir()
        (fixture / "docs/releases").mkdir(parents=True)
        for relative in (
            "project.godot",
            "export_presets.cfg",
            "tools/ci_manifest.json",
            "content/runtime_world.json",
            "docs/releases/v0.15.0-early-access-rc1.md",
        ):
            source = ROOT / relative
            target = fixture / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, target)

        manifest_path = fixture / "tools/ci_manifest.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        manifest["release_ready"] = False
        manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
        try:
            validate_release_contract(fixture)
        except AssertionError as error:
            assert "release_ready" in str(error)
        else:
            raise AssertionError("a non-release-ready manifest should be rejected")

    with tempfile.TemporaryDirectory() as temporary_directory:
        fixture = Path(temporary_directory)
        first = fixture / "candidate.exe"
        second = fixture / "release_manifest.json"
        first.write_bytes(b"candidate")
        second.write_text("{}", encoding="utf-8")
        checksum_file = fixture / "SHA256SUMS.txt"
        entries = write_release_checksums(checksum_file, [first, second])
        assert entries == [f"{sha256(first)}  candidate.exe", f"{sha256(second)}  release_manifest.json"]
        assert all("/" not in entry.split("  ", 1)[1] for entry in entries)
        assert b"\r" not in checksum_file.read_bytes(), "release checksums must use portable LF newlines"

    print("Release contract validator tests: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
