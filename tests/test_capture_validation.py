#!/usr/bin/env python3
"""Regression tests for packaged browser evidence validation."""

from __future__ import annotations

import argparse
import struct
import sys
import tempfile
import zlib
from pathlib import Path

REPOSITORY_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPOSITORY_ROOT))
sys.path.insert(0, str(REPOSITORY_ROOT / "tools"))

from tools.capture_validation import (
    REQUIRED_CAPTURE_SCREENS,
    VIEWPORTS,
    changed_pixel_ratio,
    apply_color_matrix,
    png_dimensions,
    png_rgb,
    require_distinct_screen,
    validate_capture_matrix,
    write_rgb_png,
)
from tools.validate_native_captures import parse_viewport, require_release_surface


def png_chunk(chunk_type: bytes, payload: bytes) -> bytes:
    checksum = zlib.crc32(chunk_type + payload) & 0xFFFFFFFF
    return struct.pack(">I", len(payload)) + chunk_type + payload + struct.pack(">I", checksum)


def write_solid_rgb_png(path: Path, width: int, height: int, color: tuple[int, int, int]) -> None:
    scanline = bytes(color) * width
    raw = b"".join(b"\x00" + scanline for _ in range(height))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(raw))
        + png_chunk(b"IEND", b"")
    )


def write_rgba_png(path: Path, width: int, height: int, color: tuple[int, int, int, int]) -> None:
    scanline = bytes(color) * width
    raw = b"".join(b"\x00" + scanline for _ in range(height))
    path.write_bytes(
        b"\x89PNG\r\n\x1a\n"
        + png_chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0))
        + png_chunk(b"IDAT", zlib.compress(raw))
        + png_chunk(b"IEND", b"")
    )


def main() -> int:
    assert parse_viewport("960x540") == (960, 540)
    for invalid_viewport in ("960", "0x540", "widextall"):
        try:
            parse_viewport(invalid_viewport)
        except argparse.ArgumentTypeError:
            pass
        else:
            raise AssertionError(f"invalid viewport should be rejected: {invalid_viewport}")
    release_capture = {
        "screen": "settlement_shop",
        "layout": {
            "release_surface": {
                "developer_panel_hidden": True,
                "diagnostics_hidden": True,
                "report_action_hidden": True,
            }
        },
    }
    require_release_surface(release_capture)
    release_capture["layout"]["release_surface"]["diagnostics_hidden"] = False
    try:
        require_release_surface(release_capture)
    except AssertionError:
        pass
    else:
        raise AssertionError("visible diagnostics should fail the release-surface gate")
    with tempfile.TemporaryDirectory() as temporary_directory:
        root = Path(temporary_directory)
        dark = root / "dark.png"
        light = root / "light.png"
        light_rgba = root / "light-rgba.png"
        write_solid_rgb_png(dark, 4, 3, (10, 10, 10))
        write_solid_rgb_png(light, 4, 3, (240, 240, 240))
        write_rgba_png(light_rgba, 4, 3, (240, 240, 240, 128))
        assert png_dimensions(dark) == (4, 3)
        assert changed_pixel_ratio(dark, light) == 1.0
        assert changed_pixel_ratio(light, light_rgba) == 0.0
        round_trip = root / "round-trip.png"
        source_size, source_rgb = png_rgb(dark)
        write_rgb_png(round_trip, source_size, source_rgb)
        assert png_rgb(round_trip) == (source_size, source_rgb)
        grayscale = apply_color_matrix(bytes((255, 0, 0)), ((0.2126, 0.7152, 0.0722),) * 3)
        assert grayscale == bytes((54, 54, 54))
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
    validate_capture_matrix(
        [{"screen": "menu", "requested_window": {"width": 320, "height": 180}}],
        required_screens={"menu"},
        viewports=((320, 180),),
    )
    print("Browser capture validation: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
