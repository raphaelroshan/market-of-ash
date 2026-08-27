#!/usr/bin/env python3
"""Capture a loaded Godot Web build at the alpha viewport sizes."""

from __future__ import annotations

import argparse
import json
import struct
import time
from pathlib import Path

from selenium import webdriver
from selenium.webdriver.common.by import By


VIEWPORTS = ((960, 540), (1280, 720))


def wait_for_game(driver: webdriver.Chrome, timeout_seconds: float) -> None:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if not driver.find_elements(By.ID, "status"):
            return
        time.sleep(0.5)
    raise TimeoutError("Godot loading overlay did not clear before the capture timeout")


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if data[:8] != b"\x89PNG\r\n\x1a\n" or len(data) < 24:
        raise ValueError(f"invalid PNG: {path}")
    return struct.unpack(">II", data[16:24])


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--timeout", type=float, default=90.0)
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    options = webdriver.ChromeOptions()
    for option in [
        "--headless=new",
        "--no-sandbox",
        "--no-first-run",
        "--disable-background-networking",
        "--disable-dev-shm-usage",
        "--use-angle=swiftshader",
        "--enable-unsafe-swiftshader",
    ]:
        options.add_argument(option)

    captures: list[dict[str, object]] = []
    driver = webdriver.Chrome(options=options)
    try:
        for width, height in VIEWPORTS:
            driver.set_window_size(width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            actual_width = int(driver.execute_script("return window.innerWidth"))
            actual_height = int(driver.execute_script("return window.innerHeight"))
            output = args.output_dir / f"main-menu-{width}x{height}.png"
            if not driver.save_screenshot(str(output)):
                raise RuntimeError(f"Chrome did not save {output}")
            image_width, image_height = png_dimensions(output)
            if image_width != actual_width or image_height != actual_height:
                raise AssertionError(
                    f"{output.name}: PNG is {(image_width, image_height)}, viewport is {(actual_width, actual_height)}"
                )
            if output.stat().st_size < 10_000:
                raise AssertionError(f"{output.name}: rendered frame is unexpectedly small")
            captures.append(
                {
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": output.name,
                    "bytes": output.stat().st_size,
                }
            )
        (args.output_dir / "dom.html").write_text(driver.page_source, encoding="utf-8")
        (args.output_dir / "capture_manifest.json").write_text(
            json.dumps({"url": args.url, "loading_overlay_cleared": True, "captures": captures}, indent=2),
            encoding="utf-8",
        )
    finally:
        driver.quit()
    print("Web render captures: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
