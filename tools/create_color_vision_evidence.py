#!/usr/bin/env python3
"""Create approximate color-vision review frames from native render evidence."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from capture_validation import apply_color_matrix, png_rgb, write_rgb_png


TARGET_SCREENS = {
    "main_menu_large_text",
    "settlement_shop_large_text",
    "departure_desk_large_text",
    "route_event_large_text",
    "route_event_result",
    "new_game_confirmation",
}
MATRICES = {
    "grayscale": (
        (0.2126, 0.7152, 0.0722),
        (0.2126, 0.7152, 0.0722),
        (0.2126, 0.7152, 0.0722),
    ),
    "protanopia": (
        (0.56667, 0.43333, 0.0),
        (0.55833, 0.44167, 0.0),
        (0.0, 0.24167, 0.75833),
    ),
    "deuteranopia": (
        (0.625, 0.375, 0.0),
        (0.7, 0.3, 0.0),
        (0.0, 0.3, 0.7),
    ),
}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--capture-dir", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    source_manifest_path = args.capture_dir / "native-capture-960x540.json"
    source_manifest = json.loads(source_manifest_path.read_text(encoding="utf-8"))
    selected = [
        capture
        for capture in source_manifest.get("captures", [])
        if capture.get("screen") in TARGET_SCREENS
    ]
    captured_screens = {str(capture.get("screen", "")) for capture in selected}
    missing = sorted(TARGET_SCREENS - captured_screens)
    if missing:
        raise AssertionError(f"missing source captures: {', '.join(missing)}")

    generated: list[dict[str, object]] = []
    for capture in selected:
        source_path = args.capture_dir / str(capture["file"])
        size, rgb = png_rgb(source_path)
        for mode, matrix in MATRICES.items():
            output_name = f"{source_path.stem}-{mode}.png"
            output_path = args.output_dir / output_name
            write_rgb_png(output_path, size, apply_color_matrix(rgb, matrix))
            generated.append(
                {
                    "screen": capture["screen"],
                    "mode": mode,
                    "source": source_path.name,
                    "file": output_name,
                    "width": size[0],
                    "height": size[1],
                    "bytes": output_path.stat().st_size,
                }
            )

    manifest_path = args.output_dir / "color-vision-manifest.json"
    manifest_path.write_text(
        json.dumps(
            {
                "manifest_version": 1,
                "source_manifest": source_manifest_path.name,
                "note": "Approximate review filters; not a substitute for human color-vision accessibility testing.",
                "required_screens": sorted(TARGET_SCREENS),
                "modes": sorted(MATRICES),
                "captures": generated,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    print(f"Color-vision evidence: PASS ({len(generated)} frames)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
