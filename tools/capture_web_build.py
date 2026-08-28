#!/usr/bin/env python3
"""Capture a loaded Godot Web build at the alpha viewport sizes."""

from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path

from capture_validation import (
    VIEWPORTS,
    png_dimensions,
    require_distinct_screen,
    validate_capture_matrix,
)
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys

INPUT_SETTLE_SECONDS = 0.2


def send_game_key(driver: webdriver.Chrome, key: str) -> None:
    """Send one key to the canvas, then allow Godot to process a frame."""
    canvas = driver.find_element(By.ID, "canvas")
    driver.execute_script("arguments[0].focus()", canvas)
    ActionChains(driver).send_keys(key).perform()
    time.sleep(INPUT_SETTLE_SECONDS)


def wait_for_game(driver: webdriver.Chrome, timeout_seconds: float) -> None:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if not driver.find_elements(By.ID, "status"):
            return
        time.sleep(0.5)
    raise TimeoutError("Godot loading overlay did not clear before the capture timeout")


def wait_for_ui_state(
    driver: webdriver.Chrome,
    expected_screen: str,
    timeout_seconds: float,
    *,
    large_text: bool | None = None,
    settlement_id: str | None = None,
    pending_event_id: str | None = None,
    expected_values: dict[str, object] | None = None,
) -> dict[str, object]:
    deadline = time.monotonic() + timeout_seconds
    last_state: object = None
    while time.monotonic() < deadline:
        last_state = driver.execute_script("return window.marketOfAshUiState || null")
        if isinstance(last_state, dict) and last_state.get("screen") == expected_screen:
            announcement = last_state.get("announcement")
            if not isinstance(announcement, str) or not announcement.strip():
                time.sleep(0.1)
                continue
            if large_text is not None and last_state.get("large_text") is not large_text:
                time.sleep(0.1)
                continue
            if settlement_id is not None and last_state.get("settlement_id") != settlement_id:
                time.sleep(0.1)
                continue
            if pending_event_id is not None and last_state.get("pending_event_id") != pending_event_id:
                time.sleep(0.1)
                continue
            if expected_values is not None and any(last_state.get(key) != value for key, value in expected_values.items()):
                time.sleep(0.1)
                continue
            assistive_state = driver.execute_script(
                """
                const canvas = document.getElementById('canvas');
                const region = document.getElementById('market-of-ash-status');
                return {
                  canvasRole: canvas ? canvas.getAttribute('role') : null,
                  canvasLabel: canvas ? canvas.getAttribute('aria-label') : null,
                  regionRole: region ? region.getAttribute('role') : null,
                  regionLive: region ? region.getAttribute('aria-live') : null,
                  regionText: region ? region.textContent : null,
                };
                """
            )
            if assistive_state != {
                "canvasRole": "application",
                "canvasLabel": announcement,
                "regionRole": "status",
                "regionLive": "polite",
                "regionText": announcement,
            }:
                time.sleep(0.1)
                continue
            time.sleep(0.2)
            return last_state
        time.sleep(0.1)
    raise TimeoutError(f"expected Web UI state {expected_screen!r}; last state was {last_state!r}")


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
        for width, height in VIEWPORTS:
            if driver is not None:
                driver.quit()
            driver = webdriver.Chrome(options=options)
            set_viewport_size(driver, width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            main_state = wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False)
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
                    "ui_state": main_state,
                }
            )
            send_game_key(driver, Keys.ENTER)
            shop_state = wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=False, settlement_id="ashgate")
            shop_output = args.output_dir / f"settlement-shop-{width}x{height}.png"
            shop_bytes = capture_frame(driver, shop_output, (actual_width, actual_height))
            if shop_output.read_bytes() == output.read_bytes():
                raise AssertionError(f"{shop_output.name}: Start did not change the rendered frame")
            size_ratio = shop_bytes / main_bytes
            shop_changed_ratio = require_distinct_screen(output, shop_output, "Start")
            captures.append(
                {
                    "screen": "settlement_shop",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": shop_output.name,
                    "bytes": shop_bytes,
                    "main_menu_size_ratio": round(size_ratio, 3),
                    "changed_pixel_ratio": round(shop_changed_ratio, 4),
                    "ui_state": shop_state,
                }
            )
            send_game_key(driver, "p")
            pause_state = wait_for_ui_state(driver, "pause", args.timeout, large_text=False, settlement_id="ashgate")
            pause_output = args.output_dir / f"pause-{width}x{height}.png"
            pause_bytes = capture_frame(driver, pause_output, (actual_width, actual_height))
            pause_changed_ratio = require_distinct_screen(shop_output, pause_output, "Pause")
            captures.append(
                {
                    "screen": "pause",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": pause_output.name,
                    "bytes": pause_bytes,
                    "changed_pixel_ratio": round(pause_changed_ratio, 4),
                    "navigation": "P from the focused Shop cargo selector",
                    "ui_state": pause_state,
                }
            )
            # Chrome consumes Escape in some headless environments before the
            # canvas receives it. Toggle the same in-game Pause action with P
            # so this transition remains a real keyboard-input check.
            send_game_key(driver, "p")
            wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=False, settlement_id="ashgate")
            # Start focuses the Shop cargo selector. Up is intentionally wired
            # to the pinned Plan action, so this both opens the next screen and
            # exercises packaged keyboard focus continuity without browser Tab.
            send_game_key(driver, Keys.ARROW_UP)
            send_game_key(driver, Keys.ENTER)
            departure_state = wait_for_ui_state(driver, "departure_desk", args.timeout, large_text=False, settlement_id="ashgate")
            departure_output = args.output_dir / f"departure-desk-{width}x{height}.png"
            departure_bytes = capture_frame(driver, departure_output, (actual_width, actual_height))
            departure_changed_ratio = require_distinct_screen(shop_output, departure_output, "Plan departure")
            captures.append(
                {
                    "screen": "departure_desk",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": departure_output.name,
                    "bytes": departure_bytes,
                    "changed_pixel_ratio": round(departure_changed_ratio, 4),
                    "navigation": "Arrow up from cargo selector, then Enter",
                    "ui_state": departure_state,
                }
            )
            for _ in range(5):
                send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ENTER)
            returned_shop_state = wait_for_ui_state(
                driver, "settlement_shop", args.timeout, large_text=False, settlement_id="ashgate"
            )
            unchanged_fields = ("day", "money", "provisions", "cargo_weight", "held_selected_quantity")
            changed_fields = [
                field for field in unchanged_fields if returned_shop_state.get(field) != shop_state.get(field)
            ]
            if changed_fields:
                raise AssertionError(f"Return to Shop changed authoritative fields: {changed_fields}")
            returned_shop_output = args.output_dir / f"returned-shop-{width}x{height}.png"
            returned_shop_bytes = capture_frame(driver, returned_shop_output, (actual_width, actual_height))
            returned_shop_changed_ratio = changed_pixel_ratio(shop_output, returned_shop_output)
            captures.append(
                {
                    "screen": "returned_shop",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": returned_shop_output.name,
                    "bytes": returned_shop_bytes,
                    "changed_pixel_ratio": round(returned_shop_changed_ratio, 4),
                    "navigation": "Arrow through the explicit Departure focus cycle, then Enter on Return to shop",
                    "unchanged_fields": list(unchanged_fields),
                    "ui_state": returned_shop_state,
                }
            )
            send_game_key(driver, Keys.ARROW_UP)
            send_game_key(driver, Keys.ENTER)
            wait_for_ui_state(driver, "departure_desk", args.timeout, large_text=False, settlement_id="ashgate")
            for _ in range(4):
                send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ENTER)
            arrival_state = wait_for_ui_state(driver, "arrival_handoff", args.timeout, large_text=False, settlement_id="reedwatch")
            time.sleep(1.8)
            arrival_output = args.output_dir / f"arrival-handoff-{width}x{height}.png"
            arrival_bytes = capture_frame(driver, arrival_output, (actual_width, actual_height))
            arrival_changed_ratio = require_distinct_screen(departure_output, arrival_output, "Commit departure")
            captures.append(
                {
                    "screen": "arrival_handoff",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": arrival_output.name,
                    "bytes": arrival_bytes,
                    "changed_pixel_ratio": round(arrival_changed_ratio, 4),
                    "navigation": "Arrow through the explicit departure focus cycle, then Enter",
                    "ui_state": arrival_state,
                }
            )
            send_game_key(driver, Keys.ENTER)
            destination_state = wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=False, settlement_id="reedwatch")
            destination_output = args.output_dir / f"destination-shop-{width}x{height}.png"
            destination_bytes = capture_frame(driver, destination_output, (actual_width, actual_height))
            destination_changed_ratio = require_distinct_screen(arrival_output, destination_output, "Enter settlement")
            captures.append(
                {
                    "screen": "destination_shop",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": destination_output.name,
                    "bytes": destination_bytes,
                    "changed_pixel_ratio": round(destination_changed_ratio, 4),
                    "navigation": "Enter on the focused destination-specific arrival action",
                    "ui_state": destination_state,
                }
            )
            send_game_key(driver, "p")
            wait_for_ui_state(driver, "pause", args.timeout, large_text=False, settlement_id="reedwatch")
            for _ in range(4):
                send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ENTER)
            wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False, settlement_id="reedwatch")
            send_game_key(driver, Keys.ENTER)
            confirmation_state = wait_for_ui_state(
                driver, "new_game_confirmation", args.timeout, large_text=False, settlement_id="reedwatch"
            )
            confirmation_output = args.output_dir / f"new-game-confirmation-{width}x{height}.png"
            confirmation_bytes = capture_frame(driver, confirmation_output, (actual_width, actual_height))
            confirmation_changed_ratio = require_distinct_screen(
                destination_output, confirmation_output, "Open new-game confirmation"
            )
            captures.append(
                {
                    "screen": "new_game_confirmation",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": confirmation_output.name,
                    "bytes": confirmation_bytes,
                    "changed_pixel_ratio": round(confirmation_changed_ratio, 4),
                    "navigation": "Pause, Return to main menu, then Enter on Start new game",
                    "ui_state": confirmation_state,
                }
            )
            driver.quit()
            driver = webdriver.Chrome(options=options)
            set_viewport_size(driver, width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False)
            canvas = driver.find_element(By.ID, "canvas")
            driver.execute_script("arguments[0].focus()", canvas)
            send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.SPACE)
            large_menu_state = wait_for_ui_state(driver, "main_menu", args.timeout, large_text=True)
            large_menu_output = args.output_dir / f"main-menu-large-text-{width}x{height}.png"
            large_menu_bytes = capture_frame(driver, large_menu_output, (actual_width, actual_height))
            large_menu_changed_ratio = require_distinct_screen(
                output, large_menu_output, "Enable large text", minimum_ratio=0.01
            )
            captures.append(
                {
                    "screen": "main_menu_large_text",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": large_menu_output.name,
                    "bytes": large_menu_bytes,
                    "changed_pixel_ratio": round(large_menu_changed_ratio, 4),
                    "navigation": "Arrow down from Start to Large text, then Space",
                    "ui_state": large_menu_state,
                }
            )
            send_game_key(driver, Keys.ARROW_UP)
            send_game_key(driver, Keys.ARROW_UP)
            send_game_key(driver, Keys.ENTER)
            large_shop_state = wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=True, settlement_id="ashgate")
            large_shop_output = args.output_dir / f"settlement-shop-large-text-{width}x{height}.png"
            large_shop_bytes = capture_frame(driver, large_shop_output, (actual_width, actual_height))
            large_shop_changed_ratio = require_distinct_screen(
                shop_output, large_shop_output, "Start with large text", minimum_ratio=0.01
            )
            captures.append(
                {
                    "screen": "settlement_shop_large_text",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": large_shop_output.name,
                    "bytes": large_shop_bytes,
                    "changed_pixel_ratio": round(large_shop_changed_ratio, 4),
                    "navigation": "Arrow up from Large text to Start, then Enter",
                    "ui_state": large_shop_state,
                }
            )
            send_game_key(driver, "p")
            large_pause_state = wait_for_ui_state(driver, "pause", args.timeout, large_text=True, settlement_id="ashgate")
            large_pause_output = args.output_dir / f"pause-large-text-{width}x{height}.png"
            large_pause_bytes = capture_frame(driver, large_pause_output, (actual_width, actual_height))
            large_pause_changed_ratio = require_distinct_screen(
                pause_output, large_pause_output, "Open Pause with large text", minimum_ratio=0.01
            )
            captures.append(
                {
                    "screen": "pause_large_text",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": large_pause_output.name,
                    "bytes": large_pause_bytes,
                    "changed_pixel_ratio": round(large_pause_changed_ratio, 4),
                    "navigation": "P from the focused large-text Shop cargo selector",
                    "ui_state": large_pause_state,
                }
            )
            send_game_key(driver, "p")
            wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=True, settlement_id="ashgate")
            send_game_key(driver, Keys.ARROW_UP)
            send_game_key(driver, Keys.ENTER)
            large_departure_state = wait_for_ui_state(driver, "departure_desk", args.timeout, large_text=True, settlement_id="ashgate")
            large_departure_output = args.output_dir / f"departure-desk-large-text-{width}x{height}.png"
            large_departure_bytes = capture_frame(driver, large_departure_output, (actual_width, actual_height))
            large_departure_changed_ratio = require_distinct_screen(
                departure_output, large_departure_output, "Open Departure with large text", minimum_ratio=0.01
            )
            captures.append(
                {
                    "screen": "departure_desk_large_text",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": large_departure_output.name,
                    "bytes": large_departure_bytes,
                    "changed_pixel_ratio": round(large_departure_changed_ratio, 4),
                    "navigation": "Arrow up from cargo selector to Plan, then Enter",
                    "ui_state": large_departure_state,
                }
            )
            driver.quit()
            driver = webdriver.Chrome(options=options)
            set_viewport_size(driver, width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False)
            send_game_key(driver, Keys.ENTER)
            wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=False, settlement_id="ashgate")
            # Select Medicine (two entries after Water), buy the default two
            # units, and use the success focus handoff to open Departure.
            for key in [Keys.SPACE, Keys.ARROW_DOWN, Keys.ARROW_DOWN, Keys.ENTER]:
                send_game_key(driver, key)
            event_state = wait_for_ui_state(
                driver,
                "settlement_shop",
                args.timeout,
                expected_values={"selected_good_id": "medicine", "selected_quantity": 2},
            )
            send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ENTER)
            wait_for_ui_state(
                driver,
                "settlement_shop",
                args.timeout,
                expected_values={"selected_good_id": "medicine", "held_selected_quantity": 2},
            )
            send_game_key(driver, Keys.ENTER)
            wait_for_ui_state(
                driver,
                "departure_desk",
                args.timeout,
                large_text=False,
                settlement_id="ashgate",
                expected_values={"selected_good_id": "medicine", "selected_destination_id": "reedwatch"},
            )
            # Brine Cross is two entries after the default Reedwatch choice.
            for key in [Keys.SPACE, Keys.ARROW_DOWN, Keys.ARROW_DOWN, Keys.ENTER]:
                send_game_key(driver, key)
            wait_for_ui_state(
                driver,
                "departure_desk",
                args.timeout,
                expected_values={"selected_destination_id": "brine_cross"},
            )
            for _ in range(4):
                send_game_key(driver, Keys.ARROW_DOWN)
            send_game_key(driver, Keys.ENTER)
            wait_for_ui_state(
                driver,
                "route_event",
                args.timeout,
                large_text=False,
                settlement_id="ashgate",
                pending_event_id="gatekeepers_chalk",
            )
            event_output = args.output_dir / f"route-event-{width}x{height}.png"
            event_bytes = capture_frame(driver, event_output, (actual_width, actual_height))
            event_changed_ratio = require_distinct_screen(departure_output, event_output, "Open route event")
            captures.append(
                {
                    "screen": "route_event",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": event_output.name,
                    "bytes": event_bytes,
                    "changed_pixel_ratio": round(event_changed_ratio, 4),
                    "navigation": "Buy Medicine, plan Brine Cross, and commit through keyboard focus",
                    "ui_state": event_state,
                }
            )
            send_game_key(driver, Keys.ENTER)
            event_arrival_state = wait_for_ui_state(
                driver,
                "arrival_handoff",
                args.timeout,
                large_text=False,
                settlement_id="brine_cross",
                pending_event_id="",
            )
            event_arrival_output = args.output_dir / f"route-event-result-{width}x{height}.png"
            event_arrival_bytes = capture_frame(driver, event_arrival_output, (actual_width, actual_height))
            event_arrival_changed_ratio = require_distinct_screen(event_output, event_arrival_output, "Resolve route event")
            captures.append(
                {
                    "screen": "route_event_result",
                    "requested_window": {"width": width, "height": height},
                    "captured_viewport": {"width": actual_width, "height": actual_height},
                    "file": event_arrival_output.name,
                    "bytes": event_arrival_bytes,
                    "changed_pixel_ratio": round(event_arrival_changed_ratio, 4),
                    "navigation": "Enter on the focused first available route-event response",
                    "ui_state": event_arrival_state,
                }
            )
        validate_capture_matrix(captures)
        (args.output_dir / "dom.html").write_text(driver.page_source, encoding="utf-8")
        (args.output_dir / "capture_manifest.json").write_text(
            json.dumps(
                {
                    "manifest_version": 2,
                    "url": args.url,
                    "loading_overlay_cleared": True,
                    "required_screens": sorted(REQUIRED_CAPTURE_SCREENS),
                    "captures": captures,
                },
                indent=2,
            ),
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
