#!/usr/bin/env python3
"""Regression tests for packaged browser evidence validation."""

from __future__ import annotations

import struct
import sys
import tempfile
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tools.capture_validation import (
    REQUIRED_CAPTURE_SCREENS,
    VIEWPORTS,
    changed_pixel_ratio,
    png_dimensions,
    require_distinct_screen,
    validate_capture_matrix,
)


def png_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    checksum = zlib.crc32(chunk_type + payload) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + chunk_type + payload + struct.pack(">I", checksum)


def write_rgb_png(path: Path, width: int, height: int, color: tuple[int, int, int]) -> None:
    scanline = bytes(color) * width
    raw = b"".join(b"\x00" + scanline for _ in range(height))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(raw))
        + png_chunk(b"IEND", b"")
    )


def main() -> int:
    with tempfile.TemporaryDirectory() as temporary_directory:
        root = Path(temporary_directory)
        dark = root / "dark.png"
        light = root / "light.png"
        write_rgb_png(dark, 4, 3, (10, 10, 10))
        write_rgb_png(light, 4, 3, (240, 240, 240))
        assert png_dimensions(dark) == (4, 3)
        assert changed_pixel_ratio(dark, light) == 1.0
        assert require_distinct_screen(dark, light, "test transition") == 1.0
        try:
            require_distinct_screen(dark, dark, "identity")
        except AssertionError:
            pass
        else:
            raise AssertionError("identity frames should be rejected")

    captures = [
        {"screen": screen, "requested_window": {"width": width, "height": height}}
        for width, height in VIEWPORTS
        for screen in REQUIRED_CAPTURE_SCREENS
    ]
    validate_capture_matrix(captures)
    try:
        validate_capture_matrix(captures[:-1])
    except AssertionError:
        pass
    else:
        raise AssertionError("incomplete capture matrix should be rejected")
    print("Browser capture validation: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
