#!/usr/bin/env python3
"""Write portable SHA-256 entries for files published as release assets."""

from __future__ import annotations

import argparse
import hashlib
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as source:
        for chunk in iter(lambda: source.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_release_checksums(output: Path, inputs: list[Path]) -> list[str]:
    resolved = [path.resolve(strict=True) for path in inputs]
    basenames = [path.name for path in resolved]
    if len(set(basenames)) != len(basenames):
        raise AssertionError("release checksum inputs must have unique basenames")
    entries = [f"{sha256(path)}  {path.name}" for path in resolved]
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="\n") as destination:
        destination.write("\n".join(entries) + "\n")
    return entries


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("inputs", type=Path, nargs="+")
    args = parser.parse_args()
    entries = write_release_checksums(args.output, args.inputs)
    print(f"Release checksums: PASS ({len(entries)} portable entries)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
