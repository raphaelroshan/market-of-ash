#!/usr/bin/env python3
"""Dependency-free validation helpers for packaged browser evidence."""

from __future__ import annotations

import struct
import zlib
from pathlib import Path


VIEWPORTS = ((960, 540), (1280, 720))
REQUIRED_CAPTURE_SCREENS = {
    "main_menu",
    "settlement_shop",
    "pause",
    "departure_desk",
    "returned_shop",
    "arrival_handoff",
    "destination_shop",
    "main_menu_large_text",
    "settlement_shop_large_text",
    "pause_large_text",
    "departure_desk_large_text",
    "route_event",
    "route_event_result",
    "new_game_confirmation",
}


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 24:
        raise ValueError(f"invalid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def png_rgb(path: Path) -> tuple[tuple[int, int], bytes]:
    """Decode Chrome's non-interlaced 8-bit RGB screenshots without Pillow."""
    data = path.read_bytes()
    position = 8
    image_data: list[bytes] = []
    width = height = 0
    bit_depth = color_type = compression = filter_method = interlace = -1
    while position < len(data):
        chunk_length = struct.unpack(">I", data[position : position + 4])[0]
        chunk_type = data[position + 4 : position + 8]
        chunk_data = data[position + 8 : position + 8 + chunk_length]
        position += chunk_length + 12
        if chunk_type == b"IHDR":
            width, height, bit_depth, color_type, compression, filter_method, interlace = struct.unpack(
                ">IIBBBBB", chunk_data
            )
        elif chunk_type == b"IDAT":
            image_data.append(chunk_data)
        elif chunk_type == b"IEND":
            break
    if (bit_depth, color_type, compression, filter_method, interlace) != (8, 2, 0, 0, 0):
        raise ValueError(f"unsupported screenshot PNG format: {path}")
    bytes_per_pixel = 3
    stride = width * bytes_per_pixel
    raw = zlib.decompress(b"".join(image_data))
    expected_length = height * (stride + 1)
    if len(raw) != expected_length:
        raise ValueError(f"unexpected decompressed PNG length for {path}: {len(raw)} != {expected_length}")
    decoded = bytearray()
    previous = bytearray(stride)
    source_offset = 0
    for _ in range(height):
        filter_type = raw[source_offset]
        source_offset += 1
        row = bytearray(raw[source_offset : source_offset + stride])
        source_offset += stride
        for index in range(stride):
            left = row[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            above = previous[index]
            upper_left = previous[index - bytes_per_pixel] if index >= bytes_per_pixel else 0
            if filter_type == 1:
                row[index] = (row[index] + left) & 0xFF
            elif filter_type == 2:
                row[index] = (row[index] + above) & 0xFF
            elif filter_type == 3:
                row[index] = (row[index] + ((left + above) // 2)) & 0xFF
            elif filter_type == 4:
                estimate = left + above - upper_left
                left_distance = abs(estimate - left)
                above_distance = abs(estimate - above)
                upper_left_distance = abs(estimate - upper_left)
                predictor = (
                    left
                    if left_distance <= above_distance and left_distance <= upper_left_distance
                    else above if above_distance <= upper_left_distance else upper_left
                )
                row[index] = (row[index] + predictor) & 0xFF
            elif filter_type != 0:
                raise ValueError(f"unsupported PNG row filter {filter_type} in {path}")
        decoded.extend(row)
        previous = row
    return (width, height), bytes(decoded)


def changed_pixel_ratio(before: Path, after: Path, channel_threshold: int = 12) -> float:
    before_size, before_rgb = png_rgb(before)
    after_size, after_rgb = png_rgb(after)
    if before_size != after_size:
        raise AssertionError(f"cannot compare screenshots with different dimensions: {before_size} and {after_size}")
    changed_pixels = 0
    for offset in range(0, len(before_rgb), 3):
        if max(abs(before_rgb[offset + channel] - after_rgb[offset + channel]) for channel in range(3)) > channel_threshold:
            changed_pixels += 1
    return changed_pixels / (before_size[0] * before_size[1])


def require_distinct_screen(before: Path, after: Path, transition: str, minimum_ratio: float = 0.04) -> float:
    ratio = changed_pixel_ratio(before, after)
    if ratio < minimum_ratio:
        raise AssertionError(
            f"{after.name}: {transition} changed only {ratio:.1%} of pixels; "
            "this may be only a focus highlight rather than the requested screen"
        )
    return ratio


def validate_capture_matrix(captures: list[dict[str, object]]) -> None:
    for width, height in VIEWPORTS:
        captured_screens = {
            str(capture.get("screen", ""))
            for capture in captures
            if capture.get("requested_window") == {"width": width, "height": height}
        }
        missing = sorted(REQUIRED_CAPTURE_SCREENS - captured_screens)
        if missing:
            raise AssertionError(f"{width}x{height}: missing required captures: {', '.join(missing)}")
