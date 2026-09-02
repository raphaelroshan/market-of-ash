#!/usr/bin/env python3
"""Validate the contents and executable structure of the Windows portable archive."""

from __future__ import annotations

import argparse
import shutil
import tempfile
import zipfile
from pathlib import Path, PurePosixPath

try:
    from validate_windows_export import inspect_windows_export
except ModuleNotFoundError:
    from tools.validate_windows_export import inspect_windows_export


EXPECTED_EXECUTABLE = PurePosixPath("Market of Ash/market-of-ash.exe")
EXPECTED_README = PurePosixPath("Market of Ash/README.txt")
REQUIRED_README_SECTIONS = (
    "Market of Ash 0.14.0 — Early Access Candidate",
    "## Install",
    "## Upgrade and save compatibility",
    "## Rollback",
    "## Known limitations",
)


def inspect_windows_distribution(path: Path, minimum_executable_size: int = 50_000_000) -> dict[str, int]:
    if not zipfile.is_zipfile(path):
        raise AssertionError(f"{path.name}: not a valid ZIP archive")
    with zipfile.ZipFile(path) as archive:
        files: list[tuple[zipfile.ZipInfo, PurePosixPath]] = []
        for entry in archive.infolist():
            normalized = PurePosixPath(entry.filename.replace("\\", "/"))
            if normalized.is_absolute() or ".." in normalized.parts:
                raise AssertionError(f"{path.name}: unsafe archive member {entry.filename!r}")
            if not entry.is_dir():
                files.append((entry, normalized))
        file_by_path = {normalized: entry for entry, normalized in files}
        if set(file_by_path) != {EXPECTED_EXECUTABLE, EXPECTED_README}:
            names = ", ".join(str(normalized) for _, normalized in files)
            raise AssertionError(
                f"{path.name}: expected {EXPECTED_EXECUTABLE} and {EXPECTED_README}; "
                f"found {names or 'no files'}"
            )
        readme = archive.read(file_by_path[EXPECTED_README]).decode("utf-8-sig")
        for section in REQUIRED_README_SECTIONS:
            if section not in readme:
                raise AssertionError(f"{path.name}: packaged README is missing {section!r}")
        executable_entry = file_by_path[EXPECTED_EXECUTABLE]
        with tempfile.TemporaryDirectory() as temporary_directory:
            executable_path = Path(temporary_directory) / EXPECTED_EXECUTABLE.name
            with archive.open(executable_entry) as source, executable_path.open("wb") as destination:
                shutil.copyfileobj(source, destination)
            details = inspect_windows_export(executable_path, minimum_size=minimum_executable_size)
    return {
        "archive_bytes": path.stat().st_size,
        "executable_bytes": details["bytes"],
        "pck_bytes": details["pck_bytes"],
        "readme_bytes": file_by_path[EXPECTED_README].file_size,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    details = inspect_windows_distribution(args.archive)
    print(
        "Windows portable distribution validation: PASS "
        f"({details['archive_bytes']} archive bytes, {details['executable_bytes']} executable bytes, "
        f"embedded PCK {details['pck_bytes']} bytes, README {details['readme_bytes']} bytes)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
