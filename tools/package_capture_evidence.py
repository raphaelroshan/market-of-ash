#!/usr/bin/env python3
"""Archive one validated native-capture directory with stable relative paths."""

from __future__ import annotations

import argparse
import zipfile
from pathlib import Path


def package_capture(source: Path, output: Path) -> int:
    source = source.resolve(strict=True)
    files = sorted(path for path in source.rglob("*") if path.is_file())
    if not files:
        raise AssertionError("capture directory is empty")
    output = output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        output.unlink()
    with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            archive.write(path, Path("market-of-ash-1600-capture") / path.relative_to(source))
    return len(files)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    count = package_capture(args.source, args.output)
    print(f"Capture evidence package: PASS ({count} files, {args.output.resolve()})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
