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
    "bazaar_jobs",
    "bazaar_crew",
    "pause",
    "departure_desk",
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
    "night_market",
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
    "night_market": "settlement_shop",
    "trade_receipt": "settlement_shop",
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
    "introduction_basin": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "introduction_caravan": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "introduction_road": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "introduction_road_large_text": ("IntroductionCard", "IntroductionProgress", "IntroductionTitle", "IntroductionBodyScroll", "IntroductionNote", "IntroductionBackAction", "IntroductionPrimaryAction", "IntroductionSkipAction"),
    "settlement_shop": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "BazaarPrimaryAction"),
    "trade_receipt": ("BazaarMarketPanel", "ShopActionCard", "BazaarMarketStatus", "BazaarCargoStatus", "BazaarDecisionSummary", "BuyCargoButton", "SellCargoButton", "TradeReceiptPanel", "BazaarPrimaryAction"),
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
    "night_market": ("BazaarMarketPanel", "ShopActionCard", "BazaarSectionTitle", "BazaarPrimaryAction"),
    "departure_desk": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
    "departure_desk_large_text": ("JourneyMapPanel", "DeparturePanel", "DepartureControlsScroll", "DeparturePrimaryAction", "JourneyResultScroll"),
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
        if screen == "settlement_shop" and ui_state.get("bazaar_scene_id") != "warden_gate_market":
            raise AssertionError(f"{file_name}: Ashgate capture is missing its gate-market identity")
        if screen == "destination_shop" and ui_state.get("bazaar_scene_id") != "brine_pan_exchange":
            raise AssertionError(f"{file_name}: destination capture is missing Brine Cross's salt-market identity")
        if screen == "glasswind_market" and ui_state.get("bazaar_scene_id") != "sunfall_glass_exchange":
            raise AssertionError(f"{file_name}: Glasswind capture is missing Sunfall Exchange's identity")
        if screen == "mirror_wells_market" and ui_state.get("bazaar_scene_id") != "mirror_wells_night_market":
            raise AssertionError(f"{file_name}: Glasswind arrival is missing Mirror Wells's identity")
        if screen == "night_market" and (
            ui_state.get("adaptive_scenario_states", {}).get("mirror_wells_beacon_oil", {}).get("state") != "expired"
            or "night_market" not in ui_state.get("emergent_factions", [])
            or "saltglass" not in ui_state.get("adaptive_response", "").lower()
        ):
            raise AssertionError(f"{file_name}: Night Market capture is missing its failure-forward state")
        if screen in {"glasswind_departure", "glasswind_road"} and ui_state.get("road_scene_id") != "mirror_night_road":
            raise AssertionError(f"{file_name}: Glasswind road capture is missing the Mirror Run identity")
        if screen == "glasswind_event" and ui_state.get("pending_event_id") != "shardwind_tithe":
            raise AssertionError(f"{file_name}: Glasswind event capture is missing Shardwind Tithe")
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
        require_distinct_screen(screens["mirror_wells_market"], screens["night_market"], f"{viewport} Activate Night Market")
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
