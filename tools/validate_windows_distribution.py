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
        if [normalized for _, normalized in files] != [EXPECTED_EXECUTABLE]:
            names = ", ".join(str(normalized) for _, normalized in files)
            raise AssertionError(f"{path.name}: expected only {EXPECTED_EXECUTABLE}; found {names or 'no files'}")
        executable_entry = files[0][0]
        with tempfile.TemporaryDirectory() as temporary_directory:
            executable_path = Path(temporary_directory) / EXPECTED_EXECUTABLE.name
            with archive.open(executable_entry) as source, executable_path.open("wb") as destination:
                shutil.copyfileobj(source, destination)
            details = inspect_windows_export(executable_path, minimum_size=minimum_executable_size)
    return {
        "archive_bytes": path.stat().st_size,
        "executable_bytes": details["bytes"],
        "pck_bytes": details["pck_bytes"],
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    details = inspect_windows_distribution(args.archive)
    print(
        "Windows portable distribution validation: PASS "
        f"({details['archive_bytes']} archive bytes, {details['executable_bytes']} executable bytes, "
        f"embedded PCK {details['pck_bytes']} bytes)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
