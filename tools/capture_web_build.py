#!/usr/bin/env python3
"""Capture a loaded Godot Web build at the alpha viewport sizes."""

from __future__ import annotations

import argparse
import json
import time
import traceback
from pathlib import Path
from typing import Any

from capture_validation import (
    REQUIRED_CAPTURE_SCREENS,
    VIEWPORTS,
    changed_pixel_ratio,
    png_dimensions,
    require_distinct_screen,
    validate_capture_matrix,
)
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys

INPUT_SETTLE_SECONDS = 0.2
OPTION_ROW_HEIGHT = 28.0


def send_game_key(driver: Any, key: str) -> None:
    """Send one key to the canvas, then allow Godot to process a frame."""
    canvas = driver.find_element(By.ID, "canvas")
    driver.execute_script("arguments[0].focus()", canvas)
    ActionChains(driver).send_keys(key).perform()
    time.sleep(INPUT_SETTLE_SECONDS)


def click_game_target(driver: Any, target_name: str, timeout_seconds: float = 5.0) -> None:
    """Click the center of a Godot control described by the Web test state."""
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        state = driver.execute_script("return window.marketOfAshUiState || null")
        if isinstance(state, dict):
            target = state.get("targets", {}).get(target_name, {})
            viewport = state.get("logical_viewport", {})
            if (
                isinstance(target, dict)
                and target.get("width", 0) > 0
                and target.get("height", 0) > 0
                and viewport.get("width", 0) > 0
                and viewport.get("height", 0) > 0
            ):
                logical_x = target["x"] + target["width"] / 2
                logical_y = target["y"] + target["height"] / 2
                if not (0 <= logical_x < viewport["width"] and 0 <= logical_y < viewport["height"]):
                    time.sleep(0.1)
                    continue
                canvas = driver.find_element(By.ID, "canvas")
                canvas_rect = driver.execute_script(
                    "const r=arguments[0].getBoundingClientRect();"
                    "return {width:r.width,height:r.height};",
                    canvas,
                )
                target_x = logical_x * canvas_rect["width"] / viewport["width"]
                target_y = logical_y * canvas_rect["height"] / viewport["height"]
                x_offset = round(target_x - canvas_rect["width"] / 2)
                y_offset = round(target_y - canvas_rect["height"] / 2)
                ActionChains(driver).move_to_element_with_offset(canvas, x_offset, y_offset).click().perform()
                time.sleep(INPUT_SETTLE_SECONDS)
                return
        time.sleep(0.1)
    raise TimeoutError(f"Web UI target {target_name!r} was not available")


def activate_accessibility_action(driver: Any, action_id: str, timeout_seconds: float = 5.0) -> None:
    """Focus and keyboard-activate one screen-reader-facing HTML action."""
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        button = driver.execute_script(
            """
            const actionId = arguments[0];
            return Array.from(document.querySelectorAll('#market-of-ash-actions button'))
              .find(candidate => candidate.dataset.action === actionId) || null;
            """,
            action_id,
        )
        if button is not None and button.is_enabled():
            ready = driver.execute_script(
                """
                const button = arguments[0];
                const actions = document.getElementById('market-of-ash-actions');
                if (!actions || typeof window.marketOfAshAccessibilityActivate !== 'function') {
                  return false;
                }
                button.focus();
                const bounds = actions.getBoundingClientRect();
                return document.activeElement === button && bounds.left >= 0 && bounds.width > 1;
                """,
                button,
            )
            if not ready:
                time.sleep(0.1)
                continue
            button.send_keys(Keys.ENTER)
            time.sleep(INPUT_SETTLE_SECONDS)
            return
        time.sleep(0.1)
    raise TimeoutError(f"Web accessibility action {action_id!r} was not available")


def activate_game_action(driver: Any, action_id: str, through_accessibility: bool) -> None:
    if through_accessibility:
        activate_accessibility_action(driver, action_id)
    else:
        click_game_target(driver, action_id if not action_id.startswith("event_choice_") else "event_choice")


def activation_path(through_accessibility: bool, action: str) -> str:
    method = "Assistive HTML action" if through_accessibility else "Canvas pointer action"
    return f"{method}: {action}"


def click_game_position(driver: Any, logical_x: float, logical_y: float) -> None:
    """Click a logical Godot canvas position with a trusted pointer action."""
    state = driver.execute_script("return window.marketOfAshUiState || null")
    if not isinstance(state, dict):
        raise RuntimeError("Web UI state is unavailable for pointer conversion")
    viewport = state.get("logical_viewport", {})
    if viewport.get("width", 0) <= 0 or viewport.get("height", 0) <= 0:
        raise RuntimeError(f"Web UI logical viewport is invalid: {viewport!r}")
    canvas = driver.find_element(By.ID, "canvas")
    canvas_rect = driver.execute_script(
        "const r=arguments[0].getBoundingClientRect();return {width:r.width,height:r.height};",
        canvas,
    )
    x_offset = round(logical_x * canvas_rect["width"] / viewport["width"] - canvas_rect["width"] / 2)
    y_offset = round(logical_y * canvas_rect["height"] / viewport["height"] - canvas_rect["height"] / 2)
    ActionChains(driver).move_to_element_with_offset(canvas, x_offset, y_offset).click().perform()
    time.sleep(INPUT_SETTLE_SECONDS)


def select_game_option(driver: Any, target_name: str, item_index: int) -> None:
    """Open a Godot OptionButton and click a known authored item row."""
    state = driver.execute_script("return window.marketOfAshUiState || null")
    target = state.get("targets", {}).get(target_name, {}) if isinstance(state, dict) else {}
    if not target:
        raise RuntimeError(f"Web UI option target {target_name!r} is unavailable")
    click_game_target(driver, target_name)
    click_game_position(
        driver,
        target["x"] + target["width"] / 2,
        target["y"] + target["height"] + (item_index + 0.5) * OPTION_ROW_HEIGHT,
    )


def wait_for_game(driver: Any, timeout_seconds: float) -> None:
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if not driver.find_elements(By.ID, "status"):
            return
        time.sleep(0.5)
    raise TimeoutError("Godot loading overlay did not clear before the capture timeout")


def wait_for_ui_state(
    driver: Any,
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
                const actions = document.getElementById('market-of-ash-actions');
                return {
                  canvasRole: canvas ? canvas.getAttribute('role') : null,
                  canvasLabel: canvas ? canvas.getAttribute('aria-label') : null,
                  canvasDescribedBy: canvas ? canvas.getAttribute('aria-describedby') : null,
                  regionRole: region ? region.getAttribute('role') : null,
                  regionLive: region ? region.getAttribute('aria-live') : null,
                  regionText: region ? region.textContent : null,
                  actionRegionRole: actions ? actions.getAttribute('role') : null,
                  actionRegionLabel: actions ? actions.getAttribute('aria-label') : null,
                  actionScreen: actions ? actions.dataset.screen : null,
                  actions: actions ? Array.from(actions.querySelectorAll('button')).map(button => ({
                    id: button.dataset.action,
                    label: button.textContent,
                    enabled: !button.disabled,
                    description: button.getAttribute('aria-describedby')
                      ? document.getElementById(button.getAttribute('aria-describedby')).textContent
                      : '',
                  })) : [],
                };
                """
            )
            expected_actions = [
                {
                    "id": str(action.get("id", "")),
                    "label": str(action.get("label", "")),
                    "enabled": bool(action.get("enabled", False)),
                    "description": str(action.get("description", "")),
                }
                for action in last_state.get("accessibility_actions", [])
            ]
            expected_assistive_state = {
                "canvasRole": "application",
                "canvasLabel": announcement,
                "canvasDescribedBy": "market-of-ash-status market-of-ash-actions-description",
                "regionRole": "status",
                "regionLive": "polite",
                "regionText": announcement,
                "actionRegionRole": "region",
                "actionRegionLabel": "Available game actions",
                "actionScreen": expected_screen,
                "actions": expected_actions,
            }
            if assistive_state != expected_assistive_state:
                time.sleep(0.1)
                continue
            time.sleep(0.2)
            return last_state
        time.sleep(0.1)
    raise TimeoutError(f"expected Web UI state {expected_screen!r}; last state was {last_state!r}")


def create_driver(browser: str, width: int, height: int) -> Any:
    if browser in ("chrome", "edge"):
        options = webdriver.ChromeOptions() if browser == "chrome" else webdriver.EdgeOptions()
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
        if browser == "chrome":
            return webdriver.Chrome(options=options)
        return webdriver.Edge(options=options)
    if browser == "firefox":
        options = webdriver.FirefoxOptions()
        # In an Xvfb session Firefox reserves 85 pixels for browser chrome.
        # Supplying the outer size at process start is reliable where Gecko's
        # later set-window-rect calls are ignored without a window manager.
        options.add_argument(f"--width={width}")
        options.add_argument(f"--height={height + 85}")
        options.set_preference("browser.startup.page", 0)
        options.set_preference("media.autoplay.default", 0)
        options.set_preference("webgl.disabled", False)
        options.set_preference("webgl.force-enabled", True)
        options.set_preference("webgl.enable-webgl2", True)
        options.set_preference("gfx.webrender.all", True)
        options.set_preference("layers.acceleration.force-enabled", True)
        return webdriver.Firefox(options=options)
    raise ValueError(f"unsupported browser {browser!r}")


def set_viewport_size(driver: Any, browser: str, width: int, height: int) -> None:
    if browser in ("chrome", "edge"):
        # Headless Chromium can transiently ignore WebDriver window-resize
        # calls while its first renderer is starting. CDP applies page viewport
        # metrics directly, avoiding runner window-manager chrome.
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
        if browser == "firefox":
            window = driver.get_window_rect()
            driver.set_window_rect(
                width=max(1, int(window["width"]) + width - actual[0]),
                height=max(1, int(window["height"]) + height - actual[1]),
            )
        time.sleep(0.1)
    raise AssertionError(f"could not establish requested viewport {(width, height)}; got {actual}")


def capture_frame(driver: Any, output: Path, expected_size: tuple[int, int]) -> int:
    if not driver.save_screenshot(str(output)):
        raise RuntimeError(f"Browser did not save {output}")
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
    parser.add_argument("--browser", choices=("chrome", "edge", "firefox"), default="chrome")
    args = parser.parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)

    captures: list[dict[str, object]] = []
    driver: Any | None = None
    try:
        for width, height in VIEWPORTS:
            use_accessibility_actions = (width, height) == VIEWPORTS[0]
            if driver is not None:
                driver.quit()
            driver = create_driver(args.browser, width, height)
            set_viewport_size(driver, args.browser, width, height)
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
            activate_game_action(driver, "start_game", use_accessibility_actions)
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
            activate_game_action(driver, "plan_departure", use_accessibility_actions)
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
                    "navigation": activation_path(use_accessibility_actions, "Plan departure"),
                    "ui_state": departure_state,
                }
            )
            activate_game_action(driver, "return_to_shop", use_accessibility_actions)
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
                    "navigation": activation_path(use_accessibility_actions, "Return to shop"),
                    "unchanged_fields": list(unchanged_fields),
                    "ui_state": returned_shop_state,
                }
            )
            activate_game_action(driver, "plan_departure", use_accessibility_actions)
            wait_for_ui_state(driver, "departure_desk", args.timeout, large_text=False, settlement_id="ashgate")
            activate_game_action(driver, "commit_departure", use_accessibility_actions)
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
                    "navigation": activation_path(use_accessibility_actions, "Commit departure"),
                    "ui_state": arrival_state,
                }
            )
            activate_game_action(driver, "enter_settlement", use_accessibility_actions)
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
                    "navigation": activation_path(use_accessibility_actions, "Enter settlement"),
                    "ui_state": destination_state,
                }
            )
            send_game_key(driver, "p")
            wait_for_ui_state(driver, "pause", args.timeout, large_text=False, settlement_id="reedwatch")
            activate_game_action(driver, "pause_main_menu", use_accessibility_actions)
            wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False, settlement_id="reedwatch")
            activate_game_action(driver, "start_game", use_accessibility_actions)
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
                    "navigation": "Pause, then %s and %s"
                    % (
                        activation_path(use_accessibility_actions, "Return to main menu"),
                        activation_path(use_accessibility_actions, "Start new game"),
                    ),
                    "ui_state": confirmation_state,
                }
            )
            driver.quit()
            driver = create_driver(args.browser, width, height)
            set_viewport_size(driver, args.browser, width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False)
            click_game_target(driver, "large_text")
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
                    "navigation": "Pointer activation of the published Large text target",
                    "ui_state": large_menu_state,
                }
            )
            activate_game_action(driver, "start_game", use_accessibility_actions)
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
                    "navigation": activation_path(use_accessibility_actions, "Start with Large text enabled"),
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
            click_game_target(driver, "plan_departure")
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
                    "navigation": "Pointer activation of Plan with Large text enabled",
                    "ui_state": large_departure_state,
                }
            )
            driver.quit()
            driver = create_driver(args.browser, width, height)
            set_viewport_size(driver, args.browser, width, height)
            driver.get(args.url)
            wait_for_game(driver, args.timeout)
            wait_for_ui_state(driver, "main_menu", args.timeout, large_text=False)
            click_game_target(driver, "start_game")
            wait_for_ui_state(driver, "settlement_shop", args.timeout, large_text=False, settlement_id="ashgate")
            # Select Medicine (two entries after Water), buy the default two
            # units, and use the success focus handoff to open Departure.
            select_game_option(driver, "shop_good", 3)
            wait_for_ui_state(
                driver,
                "settlement_shop",
                args.timeout,
                expected_values={"selected_good_id": "medicine", "selected_quantity": 2},
            )
            activate_game_action(driver, "shop_buy", use_accessibility_actions)
            wait_for_ui_state(
                driver,
                "settlement_shop",
                args.timeout,
                expected_values={"selected_good_id": "medicine", "held_selected_quantity": 2},
            )
            activate_game_action(driver, "plan_departure", use_accessibility_actions)
            wait_for_ui_state(
                driver,
                "departure_desk",
                args.timeout,
                large_text=False,
                settlement_id="ashgate",
                expected_values={"selected_good_id": "medicine", "selected_destination_id": "reedwatch"},
            )
            # Brine Cross is two entries after the default Reedwatch choice.
            select_game_option(driver, "destination", 2)
            wait_for_ui_state(
                driver,
                "departure_desk",
                args.timeout,
                expected_values={"selected_destination_id": "brine_cross"},
            )
            activate_game_action(driver, "commit_departure", use_accessibility_actions)
            event_state = wait_for_ui_state(
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
                    "navigation": "Buy Medicine, plan Brine Cross, and commit using the assistive HTML actions at the minimum viewport and canvas pointer actions at the standard viewport",
                    "ui_state": event_state,
                }
            )
            activate_game_action(driver, "event_choice_0", use_accessibility_actions)
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
                    "navigation": activation_path(use_accessibility_actions, "first available route-event response"),
                    "ui_state": event_arrival_state,
                }
            )
        validate_capture_matrix(captures)
        (args.output_dir / "dom.html").write_text(driver.page_source, encoding="utf-8")
        (args.output_dir / "capture_manifest.json").write_text(
            json.dumps(
                {
                    "manifest_version": 4,
                    "browser": args.browser,
                    "url": args.url,
                    "loading_overlay_cleared": True,
                    "assistive_action_bridge": "focused and keyboard-activated with Enter at 960x540; canvas pointer retained at 1280x720",
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
    print(f"Web render captures ({args.browser}): PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
