#!/usr/bin/env python3
"""Regression tests for Windows export structure validation."""

from __future__ import annotations

import struct
import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.validate_windows_export import inspect_windows_export


def write_fixture(path: Path, machine: int = 0x8664) -> None:
    executable = bytearray(256)
    executable[:2] = b"MZ"
    struct.pack_into("<I", executable, 0x3C, 0x80)
    executable[0x80:0x84] = b"PE\0\0"
    struct.pack_into("<H", executable, 0x84, machine)
    pack = b"GDPC" + bytes(128)
    path.write_bytes(executable + pack + struct.pack("<Q", len(pack)) + b"GDPC")


def main() -> int:
    with tempfile.TemporaryDirectory() as temporary_directory:
        root = Path(temporary_directory)
        valid = root / "valid.exe"
        write_fixture(valid)
        details = inspect_windows_export(valid, minimum_size=1)
        assert details["machine"] == 0x8664 and details["pck_bytes"] == 132

        wrong_architecture = root / "wrong-architecture.exe"
        write_fixture(wrong_architecture, machine=0x014C)
        try:
            inspect_windows_export(wrong_architecture, minimum_size=1)
        except AssertionError:
            pass
        else:
            raise AssertionError("32-bit Windows exports should be rejected")

        missing_pack = root / "missing-pack.exe"
        missing_pack.write_bytes(valid.read_bytes()[:-4] + b"NOPE")
        try:
            inspect_windows_export(missing_pack, minimum_size=1)
        except AssertionError:
            pass
        else:
            raise AssertionError("Windows exports without the embedded PCK footer should be rejected")
    print("Windows export validator tests: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
