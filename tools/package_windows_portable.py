#!/usr/bin/env python3
"""Create and clean-extract the deterministic Windows portable package."""

from __future__ import annotations

import argparse
import shutil
import zipfile
from pathlib import Path


PRODUCT_DIRECTORY = "Market of Ash"
EXECUTABLE_NAME = "market-of-ash.exe"
README_NAME = "README.txt"


def package_windows_portable(
    executable: Path,
    readme: Path,
    archive: Path,
    extract_directory: Path,
) -> Path:
    executable = executable.resolve(strict=True)
    readme = readme.resolve(strict=True)
    archive = archive.resolve()
    extract_directory = extract_directory.resolve()
    if extract_directory.exists():
        raise AssertionError(f"clean extraction target already exists: {extract_directory}")
    archive.parent.mkdir(parents=True, exist_ok=True)
    if archive.exists():
        archive.unlink()
    with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as package:
        package.write(executable, f"{PRODUCT_DIRECTORY}/{EXECUTABLE_NAME}")
        package.write(readme, f"{PRODUCT_DIRECTORY}/{README_NAME}")
    extract_directory.mkdir(parents=True)
    with zipfile.ZipFile(archive) as package:
        package.extractall(extract_directory)
    extracted_executable = extract_directory / PRODUCT_DIRECTORY / EXECUTABLE_NAME
    if not extracted_executable.is_file():
        raise AssertionError(f"portable archive did not extract {extracted_executable}")
    if executable.read_bytes() != extracted_executable.read_bytes():
        raise AssertionError("clean-extracted executable differs from its source")
    return extracted_executable


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--executable", type=Path, required=True)
    parser.add_argument("--readme", type=Path, required=True)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--extract-directory", type=Path, required=True)
    args = parser.parse_args()
    extracted = package_windows_portable(
        args.executable,
        args.readme,
        args.archive,
        args.extract_directory,
    )
    print(f"Windows portable package: {args.archive.resolve()}")
    print(f"Clean extracted executable: {extracted}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
