#!/usr/bin/env python3
"""Validate the structure of an embedded-PCK Windows x86-64 export."""

from __future__ import annotations

import argparse
import struct
from pathlib import Path


PE_X86_64_MACHINE = 0x8664
PCK_MAGIC = b"GDPC"


def inspect_windows_export(path: Path, minimum_size: int = 50_000_000) -> dict[str, int]:
    file_size = path.stat().st_size
    if file_size < minimum_size:
        raise AssertionError(f"{path.name}: export is unexpectedly small ({file_size} bytes)")
    with path.open("rb") as executable:
        dos_header = executable.read(64)
        if len(dos_header) != 64 or dos_header[:2] != b"MZ":
            raise AssertionError(f"{path.name}: missing DOS/PE header")
        pe_offset = struct.unpack_from("<I", dos_header, 0x3C)[0]
        executable.seek(pe_offset)
        if executable.read(4) != b"PE\0\0":
            raise AssertionError(f"{path.name}: missing PE signature")
        machine = struct.unpack("<H", executable.read(2))[0]
        if machine != PE_X86_64_MACHINE:
            raise AssertionError(f"{path.name}: expected x86-64 machine 0x8664, got 0x{machine:04x}")
        executable.seek(-12, 2)
        pack_size = struct.unpack("<Q", executable.read(8))[0]
        if executable.read(4) != PCK_MAGIC:
            raise AssertionError(f"{path.name}: missing embedded PCK footer")
        pack_offset = file_size - 12 - pack_size
        if pack_size <= 0 or pack_offset <= pe_offset:
            raise AssertionError(f"{path.name}: invalid embedded PCK size {pack_size}")
        executable.seek(pack_offset)
        if executable.read(4) != PCK_MAGIC:
            raise AssertionError(f"{path.name}: embedded PCK offset does not point to its header")
    sidecar = path.with_suffix(".pck")
    if sidecar.exists():
        raise AssertionError(f"{path.name}: unexpected sidecar PCK for an embedded export")
    return {"bytes": file_size, "machine": machine, "pck_bytes": pack_size, "pck_offset": pack_offset}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("export", type=Path)
    args = parser.parse_args()
    details = inspect_windows_export(args.export)
    print(
        "Windows export validation: PASS "
        f"({details['bytes']} bytes, x86-64, embedded PCK {details['pck_bytes']} bytes)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
