#!/usr/bin/env python3
"""Validate real-renderer Godot screenshots from the alpha UI journey."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from capture_validation import png_dimensions, require_distinct_screen, validate_capture_matrix


REQUIRED_NATIVE_SCREENS = {
    "main_menu",
    "introduction_basin",
    "introduction_caravan",
    "introduction_road",
    "introduction_road_large_text",
    "settlement_shop",
    "trade_receipt",
    "market_change_receipt",
    "bazaar_jobs",
    "bazaar_crew",
    "pause",
    "departure_desk",
    "investment_departure",
    "investment_road",
    "investment_event",
    "investment_arrival",
    "investment_changed_return",
    "investment_black_market_offer",
    "investment_black_market_pressure",
    "investment_terminal_receipt",
    "returned_shop",
    "well_commons_jobs",
    "well_commons_market",
    "well_commons_actions",
    "commons_ending",
    "main_menu_large_text",
    "settlement_shop_large_text",
    "trade_receipt_large_text",
    "bazaar_crew_large_text",
    "pause_large_text",
    "departure_desk_large_text",
    "route_departure",
    "route_travel",
    "route_event",
    "route_event_large_text",
    "route_event_result",
    "route_event_loss_result",
    "route_event_loss_result_large_text",
    "destination_shop",
    "glasswind_market",
    "glasswind_jobs",
    "glasswind_departure_desk",
    "glasswind_departure",
    "glasswind_road",
    "glasswind_event",
    "glasswind_arrival",
    "mirror_wells_market",
    "emberglass_departure_desk",
    "emberglass_road",
    "emberglass_event",
    "emberglass_arrival",
    "night_market",
    "night_market_supported",
    "night_market_opposed",
    "night_market_reconciled",
    "night_market_ending",
    "siltfire_mothlight_market",
    "siltfire_mothlight_actions",
    "siltfire_bellkeeper_route_terms",
    "siltfire_departure_desk",
    "siltfire_departure",
    "siltfire_road",
    "siltfire_event",
    "siltfire_arrival",
    "siltfire_reedline_departure_desk",
    "siltfire_reedline_departure",
    "siltfire_reedline_road",
    "siltfire_blackreed_arrival",
    "siltfire_blackreed_market",
    "siltfire_blackreed_actions",
    "ma_ea_5_mara_roster",
    "ma_ea_5_reedline_event",
    "ma_ea_5_reedline_result",
    "ma_ea_5_orin_roster",
    "ma_ea_5_mirror_event",
    "ma_ea_5_mirror_result",
    "black_market_offer",
    "new_game_confirmation",
}
NATIVE_VIEWPORTS = ((960, 540), (1280, 720), (1600, 900), (1920, 1080))
EXPECTED_UI_STATE = {
    "introduction_basin": "introduction",
    "introduction_caravan": "introduction",
    "introduction_road": "introduction",
    "introduction_road_large_text": "introduction",
    "bazaar_jobs": "settlement_shop",
    "bazaar_crew": "settlement_shop",
    "bazaar_crew_large_text": "settlement_shop",
    "investment_departure": "route_travel",
    "investment_road": "route_travel",
    "investment_event": "route_event",
    "investment_arrival": "arrival_handoff",
    "investment_changed_return": "settlement_shop",
    "investment_black_market_offer": "settlement_shop",
    "investment_black_market_pressure": "settlement_shop",
    "investment_terminal_receipt": "settlement_shop",
    "returned_shop": "settlement_shop",
    "well_commons_jobs": "settlement_shop",
    "well_commons_market": "settlement_shop",
    "well_commons_actions": "settlement_shop",
    "commons_ending": "settlement_shop",
    "destination_shop": "settlement_shop",
    "glasswind_market": "settlement_shop",
    "glasswind_jobs": "settlement_shop",
    "glasswind_departure_desk": "departure_desk",
    "glasswind_departure": "route_travel",
    "glasswind_road": "route_travel",
    "glasswind_event": "route_event",
    "glasswind_arrival": "arrival_handoff",
    "mirror_wells_market": "settlement_shop",
    "emberglass_departure_desk": "departure_desk",
    "emberglass_road": "route_travel",
    "emberglass_event": "route_event",
    "emberglass_arrival": "arrival_handoff",
    "night_market": "settlement_shop",
    "night_market_supported": "settlement_shop",
    "night_market_opposed": "settlement_shop",
    "night_market_reconciled": "settlement_shop",
    "night_market_ending": "settlement_shop",
    "siltfire_mothlight_market": "settlement_shop",
    "siltfire_mothlight_actions": "settlement_shop",
    "siltfire_bellkeeper_route_terms": "departure_desk",
    "siltfire_departure_desk": "departure_desk",
    "siltfire_departure": "route_travel",
    "siltfire_road": "route_travel",
    "siltfire_event": "route_event",
    "siltfire_arrival": "arrival_handoff",
    "siltfire_reedline_departure_desk": "departure_desk",
    "siltfire_reedline_departure": "route_travel",
    "siltfire_reedline_road": "route_travel",
    "siltfire_blackreed_arrival": "arrival_handoff",
    "siltfire_blackreed_market": "settlement_shop",
    "siltfire_blackreed_actions": "settlement_shop",
    "ma_ea_5_mara_roster": "settlement_shop",
    "ma_ea_5_reedline_event": "route_event",
    "ma_ea_5_reedline_result": "arrival_handoff",
    "ma_ea_5_orin_roster": "settlement_shop",
    "ma_ea_5_mirror_event": "route_event",
    "ma_ea_5_mirror_result": "arrival_handoff",
    "black_market_offer": "settlement_shop",
    "trade_receipt": "settlement_shop",
    "market_change_receipt": "settlement_shop",
    "trade_receipt_large_text": "settlement_shop",
    "route_departure": "route_travel",
    "route_event_large_text": "route_event",
    "route_event_result": "arrival_handoff",
    "route_event_loss_result": "arrival_handoff",
    "route_event_loss_result_large_text": "arrival_handoff",
}
REQUIRED_LAYOUT_CONTROLS = {
    "main_menu": ("MainMenuCard", "MainMenuHeading", "MainMenuWelcome", "MainMenuPrimaryAction", "MainMenuContinueAction", "MainMenuSettingsAction", "MainMenuCreditsAction", "MainMenuSaveStatus", "MainMenuQuitAction"),
    "main_menu_large_text": ("MainMenuCard", "MainMenuHeading", "MainMenuWelcome", "MainMenuPrimaryAction", "MainMenuContinueAction", "MainMenuSettingsAction", "MainMenuCreditsAction", "MainMenuSaveStatus", "MainMenuQuitAction"),
    "introduction_basin": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionBody", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "introduction_caravan": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionBody", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "introduction_road": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionBody", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "introduction_road_large_text": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionBody", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "settlement_shop": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "BazaarPrimaryAction"),
    "trade_receipt": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "TradeReceiptPanel", "BazaarPrimaryAction"),
    "market_change_receipt": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "TradeReceiptPanel", "BazaarPrimaryAction"),
    "settlement_shop_large_text": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "BazaarPrimaryAction"),
    "trade_receipt_large_text": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "TradeReceiptPanel", "BazaarPrimaryAction"),
    "bazaar_jobs": ("BazaarMarketPanel", "ShopActionCard", "BazaarPrimaryAction"),
    "bazaar_crew": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "CrewRosterCard0", "CrewPortrait0", "CrewIdentity0", "CrewAction0", "BazaarPrimaryAction"),
    "bazaar_crew_large_text": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "CrewRosterCard0", "CrewPortrait0", "CrewIdentity0", "CrewAction0", "BazaarPrimaryAction"),
    "returned_shop": ("BazaarMarketPanel", "ShopActionCard", "BazaarPrimaryAction"),
    "well_commons_jobs": ("BazaarMarketPanel", "ShopActionCard", "BazaarPrimaryAction"),
    "well_commons_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "BazaarPrimaryAction"),
    "well_commons_actions": ("BazaarMarketPanel", "ShopActionCard", "BazaarPrimaryAction"),
    "commons_ending": ("BazaarMarketPanel", "ShopActionCard", "CampaignDebriefPanel", "EndingContinueAction", "EndingReplayAction", "EndingTitleAction", "EndingFeedbackAction", "BazaarPrimaryAction"),
    "destination_shop": ("BazaarMarketPanel", "ShopActionCard", "BazaarDecisionSummary", "BazaarPrimaryAction"),
    "glasswind_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarDecisionSummary", "BazaarPrimaryAction"),
    "glasswind_jobs": ("BazaarMarketPanel", "ShopActionCard", "BazaarPrimaryAction"),
    "glasswind_departure_desk": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "glasswind_departure": ("JourneyMapPanel", "DeparturePanel", "JourneyResultScroll"),
    "glasswind_road": ("JourneyMapPanel", "DeparturePanel", "RoadPrimaryAction", "JourneyResultScroll"),
    "glasswind_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "glasswind_arrival": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt"),
    "mirror_wells_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarDecisionSummary", "BazaarPrimaryAction"),
    "emberglass_departure_desk": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "emberglass_road": ("JourneyMapPanel", "DeparturePanel", "RoadPrimaryAction", "JourneyResultScroll"),
    "emberglass_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "emberglass_arrival": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt"),
    "night_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "night_market_supported": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "night_market_opposed": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "night_market_reconciled": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "night_market_ending": ("BazaarMarketPanel", "ShopActionCard", "CampaignDebriefPanel", "EndingContinueAction", "EndingReplayAction", "EndingTitleAction", "EndingFeedbackAction", "BazaarPrimaryAction"),
    "siltfire_mothlight_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarDecisionSummary", "BazaarPrimaryAction"),
    "siltfire_mothlight_actions": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "siltfire_bellkeeper_route_terms": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "siltfire_departure_desk": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "siltfire_departure": ("JourneyMapPanel", "DeparturePanel", "JourneyResultScroll"),
    "siltfire_road": ("JourneyMapPanel", "DeparturePanel", "RoadPrimaryAction", "JourneyResultScroll"),
    "siltfire_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "siltfire_arrival": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt"),
    "siltfire_reedline_departure_desk": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "siltfire_reedline_departure": ("JourneyMapPanel", "DeparturePanel", "JourneyResultScroll"),
    "siltfire_reedline_road": ("JourneyMapPanel", "DeparturePanel", "RoadPrimaryAction", "JourneyResultScroll"),
    "siltfire_blackreed_arrival": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll"),
    "siltfire_blackreed_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarDecisionSummary", "BazaarPrimaryAction"),
    "siltfire_blackreed_actions": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "ma_ea_5_mara_roster": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "CrewRosterCard0", "CrewPortrait0", "CrewIdentity0", "CrewAction0", "BazaarPrimaryAction"),
    "ma_ea_5_reedline_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "ma_ea_5_reedline_result": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt"),
    "ma_ea_5_orin_roster": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "CrewRosterCard0", "CrewPortrait0", "CrewIdentity0", "CrewAction0", "BazaarPrimaryAction"),
    "ma_ea_5_mirror_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "ma_ea_5_mirror_result": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt"),
    "black_market_offer": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "departure_desk": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "departure_desk_large_text": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "investment_departure": ("JourneyMapPanel", "DeparturePanel", "JourneyResultScroll"),
    "investment_road": ("JourneyMapPanel", "DeparturePanel", "RoadPrimaryAction", "JourneyResultScroll"),
    "investment_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "investment_arrival": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt"),
    "investment_changed_return": ("BazaarMarketPanel", "ShopActionCard", "TradeReceiptPanel", "BazaarPrimaryAction"),
    "investment_black_market_offer": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "investment_black_market_pressure": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "investment_terminal_receipt": ("BazaarMarketPanel", "ShopActionCard", "CampaignDebriefPanel", "EndingContinueAction", "EndingReplayAction", "EndingTitleAction", "EndingFeedbackAction", "BazaarPrimaryAction"),
    "route_departure": ("JourneyMapPanel", "DeparturePanel", "JourneyResultScroll"),
    "route_travel": ("JourneyMapPanel", "DeparturePanel", "RoadPrimaryAction", "JourneyResultScroll"),
    "route_event": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "route_event_large_text": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "JourneyResultScroll"),
    "route_event_result": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt", "JourneyConsequenceKicker", "JourneyConsequenceTitle", "JourneyConsequenceDetail"),
    "route_event_loss_result": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt", "JourneyConsequenceKicker", "JourneyConsequenceTitle", "JourneyConsequenceDetail"),
    "route_event_loss_result_large_text": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "ArrivalPrimaryAction", "JourneyResultScroll", "JourneyConsequenceReceipt", "JourneyConsequenceKicker", "JourneyConsequenceTitle", "JourneyConsequenceDetail"),
}


def parse_viewport(value: str) -> tuple[int, int]:
    try:
        width_text, height_text = value.lower().split("x", 1)
        width, height = int(width_text), int(height_text)
    except (ValueError, TypeError) as error:
        raise argparse.ArgumentTypeError(f"invalid viewport {value!r}; expected WIDTHxHEIGHT") from error
    if width <= 0 or height <= 0:
        raise argparse.ArgumentTypeError(f"invalid viewport {value!r}; dimensions must be positive")
    return width, height


def rect_encloses(outer: dict[str, object], inner: dict[str, object]) -> bool:
    epsilon = 0.5
    outer_left = float(outer.get("x", 0.0))
    outer_top = float(outer.get("y", 0.0))
    inner_left = float(inner.get("x", 0.0))
    inner_top = float(inner.get("y", 0.0))
    return (
        inner_left >= outer_left - epsilon
        and inner_top >= outer_top - epsilon
        and inner_left + float(inner.get("width", 0.0)) <= outer_left + float(outer.get("width", 0.0)) + epsilon
        and inner_top + float(inner.get("height", 0.0)) <= outer_top + float(outer.get("height", 0.0)) + epsilon
    )


def require_layout_bounds(capture: dict[str, object]) -> None:
    screen = str(capture.get("screen", ""))
    expected_controls = REQUIRED_LAYOUT_CONTROLS.get(screen, ())
    if not expected_controls:
        return
    layout = capture.get("layout")
    if not isinstance(layout, dict):
        raise AssertionError(f"{screen}: missing layout evidence")
    active_layer = layout.get("active_layer")
    controls = layout.get("required_controls")
    if not isinstance(active_layer, dict) or not isinstance(controls, dict):
        raise AssertionError(f"{screen}: missing responsive-shell bounds")
    for control_name in expected_controls:
        evidence = controls.get(control_name)
        if not isinstance(evidence, dict) or not evidence.get("visible"):
            raise AssertionError(f"{screen}: required control {control_name} is not visible")
        rect = evidence.get("rect")
        if not isinstance(rect, dict) or float(rect.get("width", 0.0)) <= 0.0 or float(rect.get("height", 0.0)) <= 0.0:
            raise AssertionError(f"{screen}: required control {control_name} has no rendered bounds")
        if not rect_encloses(active_layer, rect):
            raise AssertionError(f"{screen}: required control {control_name} leaves the active layer")
    opening_panel_name = "MainMenuCard" if screen.startswith("main_menu") else "IntroductionCard" if screen.startswith("introduction_") else ""
    if opening_panel_name:
        opening_panel = controls.get(opening_panel_name, {}).get("rect", {})
        for control_name in expected_controls:
            if control_name == opening_panel_name:
                continue
            if not rect_encloses(opening_panel, controls[control_name]["rect"]):
                raise AssertionError(f"{screen}: required control {control_name} leaves {opening_panel_name}")


def require_release_surface(capture: dict[str, object]) -> None:
    screen = str(capture.get("screen", "unknown"))
    layout = capture.get("layout")
    release_surface = layout.get("release_surface") if isinstance(layout, dict) else None
    if not isinstance(release_surface, dict):
        raise AssertionError(f"{screen}: missing release-surface evidence")
    for invariant in ("developer_panel_hidden", "diagnostics_hidden", "report_action_hidden"):
        if release_surface.get(invariant) is not True:
            raise AssertionError(f"{screen}: release-surface invariant failed: {invariant}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-dir", type=Path, required=True)
    parser.add_argument("--viewport", action="append", type=parse_viewport, default=[])
    args = parser.parse_args()
    viewports = tuple(args.viewport) if args.viewport else NATIVE_VIEWPORTS
    captures: list[dict[str, object]] = []
    for width, height in viewports:
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
        viewports=viewports,
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
        expected_state_screen = EXPECTED_UI_STATE.get(screen, screen.removesuffix("_large_text"))
        if ui_state.get("screen") != expected_state_screen:
            raise AssertionError(f"{file_name}: UI state does not match {expected_state_screen}")
        if screen == "route_departure" and (
            ui_state.get("road_scene_id") != "warden_causeway"
            or ui_state.get("road_waypoint") != "LEAVING ASHGATE"
        ):
            raise AssertionError(f"{file_name}: departure capture is missing its moving corridor identity")
        if screen == "route_travel" and (
            ui_state.get("road_scene_id") != "warden_causeway"
            or ui_state.get("road_waypoint") != "ROAD STOP — THE NEXT INSPECTION POST"
        ):
            raise AssertionError(f"{file_name}: Toll Road capture is missing its corridor identity")
        if screen in {"investment_departure", "investment_road", "investment_event"} and ui_state.get("road_scene_id") != "ashen_milestones":
            raise AssertionError(f"{file_name}: investment journey is missing its Old Road identity")
        if screen == "investment_event" and ui_state.get("pending_event_id") != "three_riders_no_banner":
            raise AssertionError(f"{file_name}: investment journey is missing Three Riders, No Banner")
        if screen == "investment_arrival" and (
            ui_state.get("settlement_id") != "reedwatch"
            or "JOURNEY RESULT" not in ui_state.get("announcement", "")
        ):
            raise AssertionError(f"{file_name}: investment arrival does not explain the Reedwatch result")
        if screen == "investment_changed_return" and (
            ui_state.get("settlement_id") != "ashgate"
            or ui_state.get("trade_receipt_title") != "SALE RECORDED"
            or "after supply" not in ui_state.get("trade_receipt_detail", "")
        ):
            raise AssertionError(f"{file_name}: investment return Bazaar is missing its changed-market receipt")
        if screen == "investment_black_market_offer" and not any(
            action.get("id") == "settlement_action_ashgate_cinder_rider_arms_sale"
            and "BLACK MARKET · OPTIONAL" in action.get("label", "")
            and not action.get("disabled", False)
            for action in ui_state.get("accessibility_actions", [])
        ):
            raise AssertionError(f"{file_name}: investment journey is missing its optional black-market pressure")
        if screen == "investment_black_market_pressure" and ui_state.get("arms_escalation") != 2:
            raise AssertionError(f"{file_name}: black-market choice did not create visible arms pressure")
        if screen == "investment_terminal_receipt" and (
            ui_state.get("ending_id") != "ending_warden_reserve"
            or "Order at the Cistern" not in ui_state.get("campaign_debrief", "")
            or "Cinder Rider broker" not in ui_state.get("campaign_debrief", "")
            or "public manifest audit" not in ui_state.get("campaign_debrief", "")
        ):
            raise AssertionError(f"{file_name}: investment terminal receipt is missing its economic and political causes")
        if screen == "settlement_shop" and ui_state.get("bazaar_scene_id") != "warden_gate_market":
            raise AssertionError(f"{file_name}: Ashgate capture is missing its gate-market identity")
        if screen == "destination_shop" and ui_state.get("bazaar_scene_id") != "brine_pan_exchange":
            raise AssertionError(f"{file_name}: destination capture is missing Brine Cross's salt-market identity")
        if screen == "glasswind_market" and ui_state.get("bazaar_scene_id") != "sunfall_glass_exchange":
            raise AssertionError(f"{file_name}: Glasswind capture is missing Sunfall Exchange's identity")
        if screen == "mirror_wells_market" and ui_state.get("bazaar_scene_id") != "mirror_wells_night_market":
            raise AssertionError(f"{file_name}: Glasswind arrival is missing Mirror Wells's identity")
        if screen in {"night_market", "night_market_supported", "night_market_opposed", "night_market_reconciled", "night_market_ending"} and (
            ui_state.get("adaptive_scenario_states", {}).get("mirror_wells_beacon_oil", {}).get("state") != "expired"
            or "night_market" not in ui_state.get("emergent_factions", [])
            or "saltglass" not in ui_state.get("adaptive_response", "").lower()
        ):
            raise AssertionError(f"{file_name}: Night Market capture is missing its failure-forward state")
        if screen == "night_market_supported" and "support +1" not in ui_state.get("adaptive_response", ""):
            raise AssertionError(f"{file_name}: Night Market cooperation did not raise support")
        if screen == "night_market_opposed" and "support +0" not in ui_state.get("adaptive_response", ""):
            raise AssertionError(f"{file_name}: Night Market opposition did not reverse support")
        if screen == "night_market_reconciled" and "support +1" not in ui_state.get("adaptive_response", ""):
            raise AssertionError(f"{file_name}: Night Market reconciliation did not restore support")
        if screen == "night_market_ending" and (
            ui_state.get("ending_id") != "ending_night_market_network"
            or "Beacons Without Licenses" not in ui_state.get("campaign_debrief", "")
            or "Causeway Bellkeepers" not in ui_state.get("campaign_debrief", "")
        ):
            raise AssertionError(f"{file_name}: Night Market ending capture is missing its adaptive debrief")
        if screen in {"glasswind_departure", "glasswind_road"} and ui_state.get("road_scene_id") != "mirror_night_road":
            raise AssertionError(f"{file_name}: Glasswind road capture is missing the Mirror Run identity")
        if screen == "glasswind_event" and ui_state.get("pending_event_id") != "shardwind_tithe":
            raise AssertionError(f"{file_name}: Glasswind event capture is missing Shardwind Tithe")
        if screen in {"emberglass_road", "emberglass_event"} and ui_state.get("road_scene_id") != "emberglass_ventway":
            raise AssertionError(f"{file_name}: Emberglass capture is missing its furnace-road identity")
        if screen == "emberglass_event" and ui_state.get("pending_event_id") != "shardwind_tithe":
            raise AssertionError(f"{file_name}: Emberglass event capture is missing Shardwind Tithe")
        if screen == "emberglass_arrival" and ui_state.get("settlement_id") != "mirror_wells":
            raise AssertionError(f"{file_name}: Emberglass arrival did not reach Mirror Wells")
        if screen == "emberglass_departure_desk" and not any(
            action.get("id") == "route_plan_mirror_wells_emberglass_byway"
            and "FEE 2" in action.get("label", "")
            and "DAY 1" in action.get("label", "")
            and "58%" in action.get("label", "")
            for action in ui_state.get("accessibility_actions", [])
        ):
            raise AssertionError(f"{file_name}: Emberglass departure does not expose fee, time, and risk")
        if screen in {"siltfire_departure", "siltfire_road"} and ui_state.get("road_scene_id") != "brine_bell_causeway":
            raise AssertionError(f"{file_name}: Siltfire causeway capture is missing its bell-road identity")
        if screen == "siltfire_event" and ui_state.get("pending_event_id") != "causeway_whiteout":
            raise AssertionError(f"{file_name}: Siltfire event capture is missing Bells in the Whiteout")
        if screen == "siltfire_mothlight_market" and ui_state.get("bazaar_scene_id") != "mothlight_resin_quay":
            raise AssertionError(f"{file_name}: Siltfire arrival is missing Mothlight Quay's identity")
        if screen == "siltfire_bellkeeper_route_terms":
            route_cards = ui_state.get("accessibility_actions", [])
            bellkeeper_card = next((card for card in route_cards if card.get("id") == "route_plan_brine_cross_salt_causeway"), {})
            if "FEE 1" not in bellkeeper_card.get("label", ""):
                raise AssertionError(f"{file_name}: Bellkeeper trust did not expose the discounted Salt Causeway fee")
        if screen in {"siltfire_reedline_departure", "siltfire_reedline_road"} and ui_state.get("road_scene_id") != "blackreed_marsh_track":
            raise AssertionError(f"{file_name}: Reedline capture is missing its marsh-road identity")
        if screen == "siltfire_blackreed_market" and ui_state.get("bazaar_scene_id") != "blackreed_watch_market":
            raise AssertionError(f"{file_name}: Siltfire arrival is missing Blackreed Post's identity")
        if screen == "ma_ea_5_mara_roster" and (
            ui_state.get("settlement_id") != "blackreed_post"
            or ui_state.get("bazaar_section") != "crew"
        ):
            raise AssertionError(f"{file_name}: Mara roster capture is missing the Blackreed Caravan Yard")
        if screen == "ma_ea_5_reedline_event" and (
            ui_state.get("pending_event_id") != "reedline_wheel_sink"
            or ui_state.get("assigned_crew") != "mara_voss"
        ):
            raise AssertionError(f"{file_name}: Reedline event capture is missing Mara's assigned response")
        if screen == "ma_ea_5_reedline_event" and not any(
            action.get("id") == "event_choice_3"
            and "Let Mara brace the axle" in action.get("label", "")
            and not action.get("disabled", False)
            for action in ui_state.get("accessibility_actions", [])
        ):
            raise AssertionError(f"{file_name}: Mara's enabled response is missing from the semantic action order")
        if screen == "ma_ea_5_reedline_result" and (
            "reedline_track" not in ui_state.get("route_conditions", {})
            or "mara_voss" not in ui_state.get("recruited_crew", [])
        ):
            raise AssertionError(f"{file_name}: Reedline result is missing Mara's persistent route consequence")
        if screen == "ma_ea_5_orin_roster" and (
            ui_state.get("settlement_id") != "mirror_wells"
            or ui_state.get("bazaar_section") != "crew"
        ):
            raise AssertionError(f"{file_name}: Orin roster capture is missing the Mirror Wells Caravan Yard")
        if screen == "ma_ea_5_mirror_event" and (
            ui_state.get("pending_event_id") != "mirror_beacon_split"
            or ui_state.get("assigned_crew") != "orin_bell"
        ):
            raise AssertionError(f"{file_name}: Mirror Run event capture is missing Orin's assigned response")
        if screen == "ma_ea_5_mirror_event" and not any(
            action.get("id") == "event_choice_3"
            and "Let Orin expose the false line" in action.get("label", "")
            and not action.get("disabled", False)
            for action in ui_state.get("accessibility_actions", [])
        ):
            raise AssertionError(f"{file_name}: Orin's enabled response is missing from the semantic action order")
        if screen == "ma_ea_5_mirror_result" and (
            "mirror_run" not in ui_state.get("route_conditions", {})
            or "orin_bell" not in ui_state.get("recruited_crew", [])
        ):
            raise AssertionError(f"{file_name}: Mirror Run result is missing Orin's persistent route consequence")
        if screen in {"well_commons_jobs", "well_commons_market", "well_commons_actions"} and (
            ui_state.get("adaptive_scenario_state") != "expired"
            or "well_commons" not in ui_state.get("emergent_factions", [])
            or "ordinary charcoal deliveries" not in ui_state.get("adaptive_response", "")
        ):
            raise AssertionError(f"{file_name}: adaptive response capture is missing the Well Commons state")
        if screen == "commons_ending" and (
            ui_state.get("ending_id") != "ending_commons_exchange"
            or ui_state.get("adaptive_scenario_state") != "expired"
            or "well_commons" not in ui_state.get("emergent_factions", [])
            or "ROUTE TIMELINE" not in ui_state.get("campaign_debrief", "")
            or "REPLAY EXPERIMENT" not in ui_state.get("campaign_debrief", "")
        ):
            raise AssertionError(f"{file_name}: Commons ending capture is missing its causal campaign state")
        if bool(ui_state.get("large_text")) != screen.endswith("_large_text"):
            raise AssertionError(f"{file_name}: Large text state does not match its capture name")
        if screen == "market_change_receipt" and (
            ui_state.get("settlement_id") != "reedwatch"
            or ui_state.get("trade_receipt_title") != "SALE RECORDED"
            or "after supply" not in ui_state.get("trade_receipt_detail", "")
        ):
            raise AssertionError(f"{file_name}: market-change receipt must show the Reedwatch sale and its new local price")
        if screen == "black_market_offer" and not any(
            action.get("id") == "settlement_action_ashgate_cinder_rider_arms_sale"
            and "BLACK MARKET · OPTIONAL" in action.get("label", "")
            and not action.get("disabled", False)
            for action in ui_state.get("accessibility_actions", [])
        ):
            raise AssertionError(f"{file_name}: optional black-market offer is not visible and enabled")
        require_release_surface(capture)
        require_layout_bounds(capture)
        if screen in {"main_menu", "introduction_basin", "introduction_caravan", "introduction_road", "introduction_road_large_text"}:
            expected_compact = viewport[0] <= 1280
            if bool(capture.get("layout", {}).get("opening_compact")) != expected_compact:
                raise AssertionError(f"{file_name}: opening layout did not use the expected {'stacked' if expected_compact else 'split'} composition")
        by_viewport.setdefault(viewport, {})[screen] = file_path

    for viewport, screens in by_viewport.items():
        require_distinct_screen(screens["main_menu"], screens["introduction_basin"], f"{viewport} Open introduction")
        require_distinct_screen(screens["introduction_basin"], screens["introduction_caravan"], f"{viewport} Introduction caravan page")
        require_distinct_screen(screens["introduction_caravan"], screens["introduction_road"], f"{viewport} Introduction road page")
        require_distinct_screen(screens["introduction_road"], screens["introduction_road_large_text"], f"{viewport} Introduction large text", minimum_ratio=0.01)
        require_distinct_screen(screens["introduction_road"], screens["settlement_shop"], f"{viewport} Begin guided campaign")
        require_distinct_screen(screens["main_menu"], screens["settlement_shop"], f"{viewport} Start")
        require_distinct_screen(screens["settlement_shop"], screens["trade_receipt"], f"{viewport} Complete purchase", minimum_ratio=0.005)
        require_distinct_screen(screens["trade_receipt"], screens["market_change_receipt"], f"{viewport} Sell into changed destination market", minimum_ratio=0.005)
        require_distinct_screen(screens["settlement_shop"], screens["black_market_offer"], f"{viewport} Open optional black market", minimum_ratio=0.005)
        require_distinct_screen(screens["settlement_shop_large_text"], screens["trade_receipt_large_text"], f"{viewport} Complete purchase with large text", minimum_ratio=0.005)
        require_distinct_screen(screens["settlement_shop"], screens["bazaar_jobs"], f"{viewport} Open Job Board")
        require_distinct_screen(screens["bazaar_jobs"], screens["bazaar_crew"], f"{viewport} Open Caravan Yard")
        require_distinct_screen(screens["bazaar_crew"], screens["bazaar_crew_large_text"], f"{viewport} Caravan Yard large text", minimum_ratio=0.01)
        require_distinct_screen(screens["bazaar_jobs"], screens["well_commons_jobs"], f"{viewport} Expire relief offer")
        require_distinct_screen(screens["well_commons_jobs"], screens["well_commons_market"], f"{viewport} Open Commons market")
        require_distinct_screen(screens["well_commons_market"], screens["well_commons_actions"], f"{viewport} Open Commons interactions")
        require_distinct_screen(screens["well_commons_actions"], screens["commons_ending"], f"{viewport} Reach Commons ending")
        require_distinct_screen(screens["settlement_shop"], screens["pause"], f"{viewport} Pause")
        require_distinct_screen(screens["settlement_shop"], screens["departure_desk"], f"{viewport} Plan departure")
        require_distinct_screen(screens["departure_desk"], screens["investment_departure"], f"{viewport} Investment departure")
        require_distinct_screen(screens["investment_departure"], screens["investment_road"], f"{viewport} Investment road stop", minimum_ratio=0.005)
        require_distinct_screen(screens["investment_road"], screens["investment_event"], f"{viewport} Investment encounter")
        require_distinct_screen(screens["investment_event"], screens["investment_arrival"], f"{viewport} Investment arrival")
        require_distinct_screen(screens["market_change_receipt"], screens["investment_changed_return"], f"{viewport} Investment changed return Bazaar")
        require_distinct_screen(screens["investment_changed_return"], screens["investment_black_market_offer"], f"{viewport} Investment optional black market")
        require_distinct_screen(screens["investment_black_market_offer"], screens["investment_black_market_pressure"], f"{viewport} Investment black-market consequence", minimum_ratio=0.005)
        require_distinct_screen(screens["investment_black_market_pressure"], screens["investment_terminal_receipt"], f"{viewport} Investment terminal receipt")
        require_distinct_screen(screens["departure_desk"], screens["route_departure"], f"{viewport} Commit departure")
        require_distinct_screen(screens["route_departure"], screens["route_travel"], f"{viewport} Reach road stop", minimum_ratio=0.005)
        require_distinct_screen(screens["route_travel"], screens["route_event"], f"{viewport} Reveal route event")
        require_distinct_screen(screens["route_event"], screens["route_event_result"], f"{viewport} Resolve event")
        require_distinct_screen(screens["route_event_result"], screens["route_event_loss_result"], f"{viewport} Realized loss recovery")
        require_distinct_screen(screens["route_event_loss_result"], screens["route_event_loss_result_large_text"], f"{viewport} Realized loss recovery large text", minimum_ratio=0.01)
        require_distinct_screen(screens["route_event_result"], screens["destination_shop"], f"{viewport} Enter settlement")
        require_distinct_screen(screens["destination_shop"], screens["glasswind_market"], f"{viewport} Enter Glasswind Reach")
        require_distinct_screen(screens["glasswind_market"], screens["glasswind_jobs"], f"{viewport} Open Glasswind jobs")
        require_distinct_screen(screens["glasswind_market"], screens["glasswind_departure_desk"], f"{viewport} Plan Glasswind departure")
        require_distinct_screen(screens["glasswind_departure"], screens["glasswind_road"], f"{viewport} Reach Glasswind road stop", minimum_ratio=0.005)
        require_distinct_screen(screens["glasswind_road"], screens["glasswind_event"], f"{viewport} Reveal Shardwind Tithe")
        require_distinct_screen(screens["glasswind_event"], screens["glasswind_arrival"], f"{viewport} Resolve Shardwind Tithe")
        require_distinct_screen(screens["glasswind_arrival"], screens["mirror_wells_market"], f"{viewport} Enter Mirror Wells")
        require_distinct_screen(screens["glasswind_road"], screens["emberglass_road"], f"{viewport} Distinguish the Emberglass Byway", minimum_ratio=0.01)
        require_distinct_screen(screens["emberglass_road"], screens["emberglass_event"], f"{viewport} Reveal the byway encounter")
        require_distinct_screen(screens["emberglass_event"], screens["emberglass_arrival"], f"{viewport} Resolve the byway encounter")
        require_distinct_screen(screens["mirror_wells_market"], screens["night_market"], f"{viewport} Activate Night Market")
        require_distinct_screen(screens["night_market"], screens["night_market_supported"], f"{viewport} Support Night Market", minimum_ratio=0.005)
        require_distinct_screen(screens["night_market_supported"], screens["night_market_opposed"], f"{viewport} Oppose Night Market", minimum_ratio=0.005)
        require_distinct_screen(screens["night_market_opposed"], screens["night_market_reconciled"], f"{viewport} Reconcile Night Market", minimum_ratio=0.005)
        require_distinct_screen(screens["night_market_reconciled"], screens["night_market_ending"], f"{viewport} Reach Night Market ending", minimum_ratio=0.01)
        require_distinct_screen(screens["destination_shop"], screens["siltfire_mothlight_market"], f"{viewport} Enter Siltfire March")
        require_distinct_screen(screens["siltfire_mothlight_market"], screens["siltfire_mothlight_actions"], f"{viewport} Open Mothlight services")
        require_distinct_screen(screens["siltfire_mothlight_actions"], screens["siltfire_bellkeeper_route_terms"], f"{viewport} Apply Bellkeeper route terms")
        require_distinct_screen(screens["siltfire_departure_desk"], screens["siltfire_departure"], f"{viewport} Commit Salt Causeway departure")
        require_distinct_screen(screens["siltfire_departure"], screens["siltfire_road"], f"{viewport} Reach Salt Causeway road stop", minimum_ratio=0.005)
        require_distinct_screen(screens["siltfire_road"], screens["siltfire_event"], f"{viewport} Reveal causeway whiteout")
        require_distinct_screen(screens["siltfire_event"], screens["siltfire_arrival"], f"{viewport} Resolve causeway whiteout")
        require_distinct_screen(screens["siltfire_arrival"], screens["siltfire_mothlight_market"], f"{viewport} Enter Mothlight Quay")
        require_distinct_screen(screens["siltfire_reedline_departure_desk"], screens["siltfire_reedline_departure"], f"{viewport} Commit Reedline departure")
        require_distinct_screen(screens["siltfire_reedline_departure"], screens["siltfire_reedline_road"], f"{viewport} Reach Reedline road stop", minimum_ratio=0.005)
        require_distinct_screen(screens["siltfire_reedline_road"], screens["siltfire_blackreed_arrival"], f"{viewport} Complete Reedline travel")
        require_distinct_screen(screens["siltfire_blackreed_arrival"], screens["siltfire_blackreed_market"], f"{viewport} Enter Blackreed Post")
        require_distinct_screen(screens["siltfire_blackreed_market"], screens["siltfire_blackreed_actions"], f"{viewport} Open Blackreed services")
        require_distinct_screen(screens["siltfire_blackreed_market"], screens["ma_ea_5_mara_roster"], f"{viewport} Open Mara's Caravan Yard")
        require_distinct_screen(screens["ma_ea_5_mara_roster"], screens["ma_ea_5_reedline_event"], f"{viewport} Reach Reedline wheel sink")
        require_distinct_screen(screens["ma_ea_5_reedline_event"], screens["ma_ea_5_reedline_result"], f"{viewport} Resolve Reedline wheel sink")
        require_distinct_screen(screens["mirror_wells_market"], screens["ma_ea_5_orin_roster"], f"{viewport} Open Orin's Caravan Yard")
        require_distinct_screen(screens["ma_ea_5_orin_roster"], screens["ma_ea_5_mirror_event"], f"{viewport} Reach divided beacons")
        require_distinct_screen(screens["ma_ea_5_mirror_event"], screens["ma_ea_5_mirror_result"], f"{viewport} Resolve divided beacons")
        require_distinct_screen(screens["main_menu"], screens["new_game_confirmation"], f"{viewport} New game confirmation", minimum_ratio=0.01)
        for screen in ("main_menu", "settlement_shop", "pause", "departure_desk"):
            require_distinct_screen(
                screens[screen],
                screens[f"{screen}_large_text"],
                f"{viewport} {screen} large text",
                minimum_ratio=0.01,
            )
        require_distinct_screen(
            screens["route_event"],
            screens["route_event_large_text"],
            f"{viewport} route event large text",
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
        event_capture = next(
            item
            for item in captures
            if item.get("requested_window") == {"width": viewport[0], "height": viewport[1]}
            and item.get("screen") == "route_event_large_text"
        )
        event_layout = event_capture.get("layout")
        if not isinstance(event_layout, dict):
            raise AssertionError(f"{viewport} route_event_large_text: missing layout evidence")
        game_layer = event_layout.get("game_layer", {})
        departure_scroll = event_layout.get("departure_scroll", {})
        focused = event_layout.get("focused", {})
        result = event_layout.get("result", {})
        if not rect_encloses(game_layer, departure_scroll):
            raise AssertionError(f"{viewport} route_event_large_text: Departure scroll rail leaves the viewport")
        if not rect_encloses(departure_scroll, focused):
            raise AssertionError(f"{viewport} route_event_large_text: focused response is clipped")
        if not rect_encloses(game_layer, result):
            raise AssertionError(f"{viewport} route_event_large_text: journey result scroll leaves the viewport")
    print("Native UI render validation: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
