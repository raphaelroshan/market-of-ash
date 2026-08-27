#!/usr/bin/env python3
"""Capture a loaded Godot Web build at the alpha viewport sizes."""

from __future__ import annotations

import argparse
import json
import struct
import time
import traceback
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


def set_viewport_size(driver: webdriver.Chrome, width: int, height: int) -> None:
    # Headless Chrome can transiently ignore WebDriver window-resize calls while
    # its first renderer is starting. CDP's device metrics apply to the page
    # viewport directly, avoiding dependence on runner window-manager chrome.
    driver.execute_cdp_cmd(
        "Emulation.setDeviceMetricsOverride",
        {
            "width": width,
            "height": height,
            "deviceScaleFactor": 1,
            "mobile": False,
        },
    )
    deadline = time.monotonic() + 5.0
    actual = (0, 0)
    while time.monotonic() < deadline:
        actual = (
            int(driver.execute_script("return window.innerWidth")),
            int(driver.execute_script("return window.innerHeight")),
        )
        if actual == (width, height):
            return
        time.sleep(0.1)
    raise AssertionError(f"could not establish requested viewport {(width, height)}; got {actual}")


def capture_frame(driver: webdriver.Chrome, output: Path, expected_size: tuple[int, int]) -> int:
    if not driver.save_screenshot(str(output)):
        raise RuntimeError(f"Chrome did not save {output}")
    image_size = png_dimensions(output)
    if image_size != expected_size:
        raise AssertionError(f"{output.name}: PNG is {image_size}, expected {expected_size}")
    byte_count = output.stat().st_size
    if byte_count < 10_000:
        raise AssertionError(f"{output.name}: rendered frame is unexpectedly small")
    return byte_count


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
    driver: webdriver.Chrome | None = None
    try:
        driver = webdriver.Chrome(options=options)
        for width, height in VIEWPORTS:
            set_viewport_size(driver, width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            actual_width = int(driver.execute_script("return window.innerWidth"))
            actual_height = int(driver.execute_script("return window.innerHeight"))
            output = args.output_dir / f"main-menu-{width}x{height}.png"
            main_bytes = capture_frame(driver, output, (actual_width, actual_height))
            captures.append(
                {
                    "screen": "main_menu",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": output.name,
                    "bytes": main_bytes,
                }
            )
            canvas = driver.find_element(By.ID, "canvas")
            canvas.click()
            time.sleep(1.0)
            shop_output = args.output_dir / f"settlement-shop-{width}x{height}.png"
            shop_bytes = capture_frame(driver, shop_output, (actual_width, actual_height))
            if shop_output.read_bytes() == output.read_bytes():
                raise AssertionError(f"{shop_output.name}: Start did not change the rendered frame")
            size_ratio = shop_bytes / main_bytes
            if shop_bytes - main_bytes < 20_000 or size_ratio < 1.2:
                raise AssertionError(
                    f"{shop_output.name}: navigation changed too little to prove the Shop rendered "
                    f"({main_bytes} -> {shop_bytes} bytes, ratio {size_ratio:.2f})"
                )
            captures.append(
                {
                    "screen": "settlement_shop",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": shop_output.name,
                    "bytes": shop_bytes,
                    "main_menu_size_ratio": round(size_ratio, 3),
                }
            )
        (args.output_dir / "dom.html").write_text(driver.page_source, encoding="utf-8")
        (args.output_dir / "capture_manifest.json").write_text(
            json.dumps({"url": args.url, "loading_overlay_cleared": True, "captures": captures}, indent=2),
            encoding="utf-8",
        )
    except Exception as error:
        (args.output_dir / "capture_failure.json").write_text(
            json.dumps(
                {
                    "url": args.url,
                    "error_type": type(error).__name__,
                    "message": str(error),
                    "traceback": traceback.format_exc(),
                    "completed_captures": captures,
                },
                indent=2,
            ),
            encoding="utf-8",
        )
        if driver is not None:
            try:
                driver.save_screenshot(str(args.output_dir / "failure-state.png"))
                (args.output_dir / "failure-dom.html").write_text(driver.page_source, encoding="utf-8")
            except Exception:
                pass
        raise
    finally:
        if driver is not None:
            driver.quit()
    print("Web render captures: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
