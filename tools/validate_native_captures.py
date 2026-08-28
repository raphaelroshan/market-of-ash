#!/usr/bin/env python3
"""Validate real-renderer Godot screenshots from the alpha UI journey."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from capture_validation import png_dimensions, require_distinct_screen, validate_capture_matrix


REQUIRED_NATIVE_SCREENS = {
    "main_menu",
    "settlement_shop",
    "pause",
    "departure_desk",
    "main_menu_large_text",
    "settlement_shop_large_text",
    "pause_large_text",
    "departure_desk_large_text",
}
NATIVE_VIEWPORTS = ((960, 540), (1280, 720), (1920, 1080))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()
    captures: list[dict[str, object]] = []
    for width, height in NATIVE_VIEWPORTS:
        manifest_path = args.output_dir / f"native-capture-{width}x{height}.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        if manifest.get("manifest_version") != 1:
            raise AssertionError(f"{manifest_path.name}: unsupported manifest version")
        if float(manifest.get("display_scale", 0.0)) <= 0.0:
            raise AssertionError(f"{manifest_path.name}: missing display scale")
        if manifest.get("reported_viewport") != {"width": width, "height": height}:
            raise AssertionError(f"{manifest_path.name}: reported viewport does not match requested size")
        manifest_captures = manifest.get("captures")
        if not isinstance(manifest_captures, list):
            raise AssertionError(f"{manifest_path.name}: captures must be a list")
        captures.extend(manifest_captures)

    validate_capture_matrix(
        captures,
        required_screens=REQUIRED_NATIVE_SCREENS,
        viewports=NATIVE_VIEWPORTS,
    )
    by_viewport: dict[tuple[int, int], dict[str, Path]] = {}
    output_root = args.output_dir.resolve()
    for capture in captures:
        requested = capture.get("requested_window")
        if not isinstance(requested, dict):
            raise AssertionError("capture is missing requested_window")
        viewport = (int(requested.get("width", 0)), int(requested.get("height", 0)))
        file_name = str(capture.get("file", ""))
        file_path = (args.output_dir / file_name).resolve()
        if file_path.parent != output_root:
            raise AssertionError(f"capture file must remain inside output directory: {file_name}")
        if png_dimensions(file_path) != viewport:
            raise AssertionError(f"{file_name}: PNG dimensions do not match {viewport}")
        if file_path.stat().st_size < 10_000:
            raise AssertionError(f"{file_name}: rendered frame is unexpectedly small")
        screen = str(capture.get("screen", ""))
        ui_state = capture.get("ui_state")
        if not isinstance(ui_state, dict):
            raise AssertionError(f"{file_name}: missing UI state")
        expected_state_screen = screen.removesuffix("_large_text")
        if ui_state.get("screen") != expected_state_screen:
            raise AssertionError(f"{file_name}: UI state does not match {expected_state_screen}")
        if bool(ui_state.get("large_text")) != screen.endswith("_large_text"):
            raise AssertionError(f"{file_name}: Large text state does not match its capture name")
        by_viewport.setdefault(viewport, {})[screen] = file_path

    for viewport, screens in by_viewport.items():
        require_distinct_screen(screens["main_menu"], screens["settlement_shop"], f"{viewport} Start")
        require_distinct_screen(screens["settlement_shop"], screens["pause"], f"{viewport} Pause")
        require_distinct_screen(screens["settlement_shop"], screens["departure_desk"], f"{viewport} Plan departure")
        for screen in ("main_menu", "settlement_shop", "pause", "departure_desk"):
            require_distinct_screen(
                screens[screen],
                screens[f"{screen}_large_text"],
                f"{viewport} {screen} large text",
                minimum_ratio=0.01,
            )
        for screen in ("departure_desk", "departure_desk_large_text"):
            capture = next(
                item
                for item in captures
                if item.get("requested_window") == {"width": viewport[0], "height": viewport[1]}
                and item.get("screen") == screen
            )
            layout = capture.get("layout")
            if not isinstance(layout, dict):
                raise AssertionError(f"{viewport} {screen}: missing layout evidence")
            hint = layout.get("map_hint", {})
            board = layout.get("map_board", {})
            result = layout.get("result", {})
            hint_bottom = float(hint.get("y", 0.0)) + float(hint.get("height", 0.0))
            board_top = float(board.get("y", 0.0))
            board_bottom = board_top + float(board.get("height", 0.0))
            result_top = float(result.get("y", 0.0))
            if board_top < hint_bottom + 8.0:
                raise AssertionError(f"{viewport} {screen}: map overlaps its instructions")
            if board_bottom > result_top - 8.0:
                raise AssertionError(f"{viewport} {screen}: map overlaps the journey result")
    print("Native UI render validation: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
