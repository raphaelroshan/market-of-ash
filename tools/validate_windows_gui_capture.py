#!/usr/bin/env python3
"""Validate a screenshot and version record from the packaged Windows game."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

try:
    from capture_validation import png_dimensions, png_rgb
except ModuleNotFoundError:
    from tools.capture_validation import png_dimensions, png_rgb


def validate_capture(
    image_path: Path,
    metadata_path: Path,
    *,
    expected_width: int = 960,
    expected_height: int = 540,
    minimum_colors: int = 32,
    minimum_bytes: int = 10_000,
) -> dict[str, object]:
    dimensions = png_dimensions(image_path)
    expected_dimensions = (expected_width, expected_height)
    if dimensions != expected_dimensions:
        raise AssertionError(f"Windows GUI capture is {dimensions}, expected {expected_dimensions}")
    if image_path.stat().st_size < minimum_bytes:
        raise AssertionError("Windows GUI capture is unexpectedly small")
    _, pixels = png_rgb(image_path)
    pixel_count = len(pixels) // 3
    stride = max(1, pixel_count // 50_000)
    colors = {tuple(pixels[index : index + 3]) for index in range(0, len(pixels), 3 * stride)}
    if len(colors) < minimum_colors:
        raise AssertionError(f"Windows GUI capture lacks visual detail: {len(colors)} sampled colors")

    metadata = json.loads(metadata_path.read_text(encoding="utf-8-sig"))
    if metadata.get("product_name") != "Market of Ash":
        raise AssertionError(f"unexpected Windows product name: {metadata.get('product_name')!r}")
    for field in ("file_version", "product_version"):
        if metadata.get(field) != "0.13.12.0":
            raise AssertionError(f"unexpected Windows {field}: {metadata.get(field)!r}")
    window = metadata.get("window")
    if not isinstance(window, dict) or int(window.get("width", 0)) < expected_width or int(window.get("height", 0)) < expected_height:
        raise AssertionError(f"invalid Windows window bounds: {window!r}")
    capture = metadata.get("capture")
    if not isinstance(capture, dict):
        raise AssertionError(f"missing Windows client capture bounds: {capture!r}")
    capture_bounds = (
        int(capture.get("x", -1)),
        int(capture.get("y", -1)),
        int(capture.get("width", 0)),
        int(capture.get("height", 0)),
    )
    if capture_bounds[0] < 0 or capture_bounds[1] < 0 or capture_bounds[2:] != expected_dimensions:
        raise AssertionError(f"invalid Windows client capture bounds: {capture!r}")
    if not str(metadata.get("window_title", "")).strip():
        raise AssertionError("packaged Windows game has no visible window title")
    return {"dimensions": dimensions, "sampled_colors": len(colors), "metadata": metadata}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--metadata", type=Path, required=True)
    args = parser.parse_args()
    details = validate_capture(args.image, args.metadata)
    print(
        "Windows GUI capture validation: PASS "
        f"({details['dimensions'][0]}x{details['dimensions'][1]}, "
        f"{details['sampled_colors']} sampled colors)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
