extends SceneTree

const CAPTURE_SCREENS := [
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
	"new_game_confirmation",
]

var output_directory := ""
var requested_size := Vector2i.ZERO
var captures: Array[Dictionary] = []

const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if not _parse_arguments():
		quit(2)
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(output_directory)
	if directory_error != OK:
		push_error("Could not create native capture directory: %s" % error_string(directory_error))
		quit(1)
		return

	var scene: PackedScene = load("res://scenes/Main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame
	var capture_user_prefix := "user://market_of_ash_native_capture_%d" % OS.get_process_id()
	ui.settings_persistence_enabled = false
	ui.autosave_enabled = false
	ui.save_path = capture_user_prefix + ".save"
	ui.settings_path = capture_user_prefix + ".cfg"
	ui.report_path = capture_user_prefix + ".json"
	ui.save_status_text = "SAVE — No save written this session."
	ui._on_restore_default_bindings()
	ui.reduce_motion_checkbox.set_pressed_no_signal(false)
	ui._on_reduce_motion_toggled(false)
	ui.interface_sounds_checkbox.set_pressed_no_signal(false)
	ui._on_interface_sounds_toggled(false)
	ui.large_text_checkbox.set_pressed_no_signal(false)
	ui._on_large_text_toggled(false)
	ui._refresh_continue_availability()
	ui._show_main_menu()
	await _capture(ui, "main_menu", "main-menu")
	ui._on_new_game_pressed()
	await _capture(ui, "introduction_basin", "introduction-basin")
	ui._on_intro_next_pressed()
	if ui.intro_page != 1:
		push_error("Native capture could not advance to Introduction 2.")
		quit(1)
		return
	await _capture(ui, "introduction_caravan", "introduction-caravan")
	ui._on_intro_next_pressed()
	if ui.intro_page != 2:
		push_error("Native capture could not advance to Introduction 3.")
		quit(1)
		return
	await _capture(ui, "introduction_road", "introduction-road")
	ui.large_text_checkbox.set_pressed_no_signal(true)
	ui._on_large_text_toggled(true)
	await _capture(ui, "introduction_road_large_text", "introduction-road-large-text")
	ui.large_text_checkbox.set_pressed_no_signal(false)
	ui._on_large_text_toggled(false)
	ui._on_intro_next_pressed()
	await _capture(ui, "settlement_shop", "settlement-shop")
	ui._on_bazaar_navigation_pressed("assignments")
	await _capture(ui, "bazaar_jobs", "bazaar-jobs")
	if not _complete_player_opening_trade(ui):
		quit(1)
		return
	await _capture(ui, "trade_receipt", "trade-receipt")
	ui._on_bazaar_navigation_pressed("crew")
	await _capture(ui, "bazaar_crew", "bazaar-crew")
	ui._on_bazaar_navigation_pressed("trade")
	ui._open_pause()
	await _capture(ui, "pause", "pause")
	ui._close_pause()
	ui._on_plan_departure_pressed()
	await _capture(ui, "departure_desk", "departure-desk")
	ui._on_return_to_shop_pressed()
	await _capture(ui, "returned_shop", "returned-shop")
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	ui.map_panel._process(2.0)
	ui._on_continue_journey_pressed()
	ui._on_event_choice_pressed("three_riders_no_banner", "pay_for_escort")
	ui._on_enter_settlement_pressed()
	ui._select_option_by_id(ui.shop_good_option, "water")
	ui.shop_quantity.value = int(ui.world.cargo.get("water", 0))
	ui._on_sell_pressed()
	await _capture(ui, "market_change_receipt", "market-change-receipt")

	ui.pending_tutorial_enabled = false
	ui._on_start_game_pressed()
	ui.world.advance_day(3)
	ui._refresh_ui()
	ui._on_bazaar_navigation_pressed("assignments")
	await _capture(ui, "well_commons_jobs", "well-commons-jobs")
	ui._on_bazaar_navigation_pressed("trade")
	ui._select_option_by_id(ui.shop_good_option, "charcoal")
	ui.shop_quantity.value = 4
	ui._on_shop_plan_changed(ui.shop_good_option.selected)
	await _capture(ui, "well_commons_market", "well-commons-market")
	ui.world.current_settlement = "reedwatch"
	ui._refresh_ui()
	ui._on_bazaar_navigation_pressed("information")
	await _capture(ui, "well_commons_actions", "well-commons-actions")
	ui.world.current_settlement = "ashgate"
	ui.world.cargo = {"weight": 0}
	ui.world.resolved_event_ids.clear()
	ui.world.resolved_event_ids.append("span_at_cinderford")
	ui.world.resolved_event_ids.append("three_riders_no_banner")
	var commons_buy := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "charcoal", "quantity": 6}})
	var commons_depart := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}}) if commons_buy.ok else {"ok": false}
	var commons_sale := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.SELL_GOODS, "inputs": {"good_id": "charcoal", "quantity": 4}}) if commons_depart.ok and ui.world.pending_event.is_empty() else {"ok": false}
	var commons_support := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}}) if commons_sale.ok else {"ok": false}
	if not commons_support.ok:
		push_error("Native capture could not complete the ordinary-trade Commons ending fixture.")
		quit(1)
		return
	ui.world.advance_day(maxi(0, 10 - ui.world.day))
	ui._refresh_ui()
	if ui.world.ending_id != "ending_commons_exchange" or not ui.ending_panel.visible:
		push_error("Native capture expected the Commons alternate ending.")
		quit(1)
		return
	ui._on_bazaar_navigation_pressed("outlook")
	await _capture(ui, "commons_ending", "commons-ending")

	ui.pending_tutorial_enabled = true
	ui._on_start_game_pressed()
	ui.large_text_checkbox.set_pressed_no_signal(true)
	ui._on_large_text_toggled(true)
	await _capture(ui, "settlement_shop_large_text", "settlement-shop-large-text")
	ui._on_bazaar_navigation_pressed("assignments")
	if not _complete_player_opening_trade(ui):
		quit(1)
		return
	await _capture(ui, "trade_receipt_large_text", "trade-receipt-large-text")
	ui._on_bazaar_navigation_pressed("crew")
	await _capture(ui, "bazaar_crew_large_text", "bazaar-crew-large-text")
	ui._on_bazaar_navigation_pressed("trade")
	ui._open_pause()
	await _capture(ui, "pause_large_text", "pause-large-text")
	ui._close_pause()
	ui._on_plan_departure_pressed()
	await _capture(ui, "departure_desk_large_text", "departure-desk-large-text")
	ui._show_main_menu()
	await _capture(ui, "main_menu_large_text", "main-menu-large-text")

	ui.large_text_checkbox.set_pressed_no_signal(false)
	ui._on_large_text_toggled(false)
	ui.pending_tutorial_enabled = false
	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._on_depart_pressed()
	if ui.world.pending_event.get("id", "") != "gatekeepers_chalk":
		push_error("Native capture expected the deterministic Gatekeeper's Chalk event.")
		quit(1)
		return
	await _capture(ui, "route_departure", "route-departure")
	ui.map_panel._process(2.0)
	if ui.map_panel.travel_phase != "road" or not ui.continue_journey_button.visible:
		push_error("Native capture expected the dedicated road view before the route encounter.")
		quit(1)
		return
	await _capture(ui, "route_travel", "route-travel")
	ui._on_continue_journey_pressed()
	if ui.map_panel._caravan_motion_label() != "ENCOUNTER":
		push_error("Native capture expected the caravan to stop at the route encounter.")
		quit(1)
		return
	await _capture(ui, "route_event", "route-event")
	ui.large_text_checkbox.set_pressed_no_signal(true)
	ui._on_large_text_toggled(true)
	await _capture(ui, "route_event_large_text", "route-event-large-text")
	ui.large_text_checkbox.set_pressed_no_signal(false)
	ui._on_large_text_toggled(false)
	var event_id := String(ui.world.pending_event.get("id", ""))
	var choices: Array = ui.world.pending_event.get("choices", [])
	if choices.is_empty():
		push_error("Native capture route event has no choices.")
		quit(1)
		return
	ui._on_event_choice_pressed(event_id, String(choices[0].get("id", "")))
	await _capture(ui, "route_event_result", "route-event-result")
	ui._on_enter_settlement_pressed()
	await _capture(ui, "destination_shop", "destination-shop")

	ui.pending_tutorial_enabled = false
	ui._on_start_game_pressed()
	ui.world.seed = 1107
	ui.world.current_settlement = "sunfall_exchange"
	ui.world.day = 5
	ui.world._update_crisis_modifiers()
	ui._populate_destination_options()
	ui._populate_route_options()
	ui._refresh_ui()
	ui._select_option_by_id(ui.shop_good_option, "lamp_oil")
	ui.shop_quantity.value = 3
	ui._on_shop_plan_changed(ui.shop_good_option.selected)
	await _capture(ui, "glasswind_market", "glasswind-market")
	ui._on_bazaar_navigation_pressed("assignments")
	await _capture(ui, "glasswind_jobs", "glasswind-jobs")
	ui._on_accept_contract_pressed("mirror_wells_lamp_relief_01")
	ui._on_bazaar_navigation_pressed("trade")
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "mirror_wells")
	ui._on_destination_changed(ui.destination_option.selected)
	await _capture(ui, "glasswind_departure_desk", "glasswind-departure-desk")
	ui._on_depart_pressed()
	if ui.world.pending_event.get("id", "") != "shardwind_tithe":
		push_error("Native capture expected the deterministic Shardwind Tithe event.")
		quit(1)
		return
	await _capture(ui, "glasswind_departure", "glasswind-departure")
	ui.map_panel._process(2.0)
	await _capture(ui, "glasswind_road", "glasswind-road")
	ui._on_continue_journey_pressed()
	await _capture(ui, "glasswind_event", "glasswind-event")
	ui._on_event_choice_pressed("shardwind_tithe", "shelter_behind_cairns")
	await _capture(ui, "glasswind_arrival", "glasswind-arrival")
	ui._on_enter_settlement_pressed()
	await _capture(ui, "mirror_wells_market", "mirror-wells-market")

	ui._on_start_game_pressed()
	ui.world.advance_day(7)
	ui.world.current_settlement = "mirror_wells"
	ui._populate_destination_options()
	ui._populate_route_options()
	ui._refresh_ui()
	ui._on_bazaar_navigation_pressed("information")
	await _capture(ui, "night_market", "night-market")
	ui.world.cargo = {"lamp_oil": 2, "weight": 2}
	ui._on_settlement_action_pressed("mirror_wells_night_beacons")
	await _capture(ui, "night_market_supported", "night-market-supported")
	ui._on_settlement_action_pressed("mirror_wells_consortium_license")
	await _capture(ui, "night_market_opposed", "night-market-opposed")
	ui.world.reset_visit_slots()
	ui._on_settlement_action_pressed("mirror_wells_signal_ledger")
	await _capture(ui, "night_market_reconciled", "night-market-reconciled")
	ui.world.cargo = {"saltglass": 4, "weight": 4}
	ui._on_bazaar_navigation_pressed("trade")
	ui._select_option_by_id(ui.shop_good_option, "saltglass")
	ui.shop_quantity.value = 4
	ui._on_sell_pressed()
	ui.world.advance_day(maxi(0, 10 - ui.world.day))
	ui._refresh_ui()
	await _capture(ui, "night_market_ending", "night-market-ending")

	ui._on_start_game_pressed()
	ui.world.seed = 1
	ui.world.current_settlement = "brine_cross"
	ui.world.day = 1
	ui.world._update_crisis_modifiers()
	ui._populate_destination_options()
	ui._populate_route_options()
	ui._refresh_ui()
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_shop_plan_changed(ui.shop_good_option.selected)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "mothlight_quay")
	ui._on_destination_changed(ui.destination_option.selected)
	await _capture(ui, "siltfire_departure_desk", "siltfire-departure-desk")
	ui._on_depart_pressed()
	if ui.world.pending_event.get("id", "") != "causeway_whiteout":
		push_error("Native capture expected the deterministic causeway whiteout event.")
		quit(1)
		return
	await _capture(ui, "siltfire_departure", "siltfire-departure")
	ui.map_panel._process(2.0)
	await _capture(ui, "siltfire_road", "siltfire-road")
	ui._on_continue_journey_pressed()
	await _capture(ui, "siltfire_event", "siltfire-event")
	ui._on_event_choice_pressed("causeway_whiteout", "hire_bell_keeper")
	await _capture(ui, "siltfire_arrival", "siltfire-arrival")
	ui._on_enter_settlement_pressed()
	ui._select_option_by_id(ui.destination_option, "blackreed_post")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_shop_plan_changed(ui.shop_good_option.selected)
	await _capture(ui, "siltfire_mothlight_market", "siltfire-mothlight-market")
	ui._on_bazaar_navigation_pressed("information")
	await _capture(ui, "siltfire_mothlight_actions", "siltfire-mothlight-actions")
	ui._on_settlement_action_pressed("mothlight_bell_chart")
	ui._on_bazaar_navigation_pressed("trade")
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	await _capture(ui, "siltfire_bellkeeper_route_terms", "siltfire-bellkeeper-route-terms")
	ui._on_return_to_shop_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "blackreed_post")
	ui._on_destination_changed(ui.destination_option.selected)
	await _capture(ui, "siltfire_reedline_departure_desk", "siltfire-reedline-departure-desk")
	ui._on_depart_pressed()
	await _capture(ui, "siltfire_reedline_departure", "siltfire-reedline-departure")
	ui.map_panel._process(2.0)
	await _capture(ui, "siltfire_reedline_road", "siltfire-reedline-road")
	ui._on_continue_journey_pressed()
	ui.map_panel._process(2.0)
	await _capture(ui, "siltfire_blackreed_arrival", "siltfire-blackreed-arrival")
	ui._on_enter_settlement_pressed()
	ui._select_option_by_id(ui.destination_option, "mothlight_quay")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._select_option_by_id(ui.shop_good_option, "grain")
	ui.shop_quantity.value = 2
	ui._on_shop_plan_changed(ui.shop_good_option.selected)
	await _capture(ui, "siltfire_blackreed_market", "siltfire-blackreed-market")
	ui._on_bazaar_navigation_pressed("information")
	await _capture(ui, "siltfire_blackreed_actions", "siltfire-blackreed-actions")

	ui._on_start_game_pressed()
	ui.world.seed = 1
	ui.world.current_settlement = "blackreed_post"
	ui.world.reset_visit_slots()
	ui._populate_destination_options()
	ui._populate_route_options()
	ui._refresh_ui()
	ui._on_bazaar_navigation_pressed("crew")
	await _capture(ui, "ma_ea_5_mara_roster", "ma-ea-5-mara-roster")
	var mara_recruit := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.RECRUIT_CREW, "inputs": {"crew_id": "mara_voss"}})
	var mara_assign := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.ASSIGN_CREW, "inputs": {"crew_id": "mara_voss"}}) if mara_recruit.ok else {"ok": false}
	if not mara_assign.ok:
		push_error("Native capture could not recruit and assign Mara Voss.")
		quit(1)
		return
	ui.world.cargo = {"scrap": 2, "medicine": 2, "weight": 4}
	ui._refresh_ui()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "mothlight_quay")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._on_depart_pressed()
	ui.map_panel._process(2.0)
	ui._on_continue_journey_pressed()
	if ui.world.pending_event.get("id", "") != "reedline_wheel_sink":
		push_error("Native capture expected the deterministic Reedline wheel-sink event.")
		quit(1)
		return
	await _capture(ui, "ma_ea_5_reedline_event", "ma-ea-5-reedline-event")
	ui._on_event_choice_pressed("reedline_wheel_sink", "mara_split_axle_brace")
	await _capture(ui, "ma_ea_5_reedline_result", "ma-ea-5-reedline-result")

	ui._on_start_game_pressed()
	ui.world.seed = 3
	ui.world.current_settlement = "mirror_wells"
	ui.world.resolved_event_ids.append("shardwind_tithe")
	ui.world.reset_visit_slots()
	ui._populate_destination_options()
	ui._populate_route_options()
	ui._refresh_ui()
	ui._on_bazaar_navigation_pressed("crew")
	await _capture(ui, "ma_ea_5_orin_roster", "ma-ea-5-orin-roster")
	var orin_recruit := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.RECRUIT_CREW, "inputs": {"crew_id": "orin_bell"}})
	var orin_assign := MarketCommandProcessor.execute(ui.world, {"id": MarketCommandProcessor.ASSIGN_CREW, "inputs": {"crew_id": "orin_bell"}}) if orin_recruit.ok else {"ok": false}
	if not orin_assign.ok:
		push_error("Native capture could not recruit and assign Orin Bell.")
		quit(1)
		return
	ui.world.cargo = {"lamp_oil": 2, "saltglass": 2, "weight": 4}
	ui._refresh_ui()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "sunfall_exchange")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._on_depart_pressed()
	ui.map_panel._process(2.0)
	ui._on_continue_journey_pressed()
	if ui.world.pending_event.get("id", "") != "mirror_beacon_split":
		push_error("Native capture expected the deterministic divided-beacon event.")
		quit(1)
		return
	await _capture(ui, "ma_ea_5_mirror_event", "ma-ea-5-mirror-event")
	ui._on_event_choice_pressed("mirror_beacon_split", "orin_occlusion_marks")
	await _capture(ui, "ma_ea_5_mirror_result", "ma-ea-5-mirror-result")

	ui._on_start_game_pressed()
	ui.world.seed = 5
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	if ui.world.pending_event.get("id", "") != "three_riders_no_banner":
		push_error("Native capture expected the deterministic Three Riders, No Banner event.")
		quit(1)
		return
	ui.map_panel._process(2.0)
	ui._on_continue_journey_pressed()
	ui._on_event_choice_pressed("three_riders_no_banner", "cross_without_escort")
	if int(ui.world.cargo.get("medicine", 0)) != 1 or not ui.conflict_outcome_label.text.contains("RECOVERY —"):
		push_error("Native capture expected one realized medicine loss and recovery guidance.")
		quit(1)
		return
	await _capture(ui, "route_event_loss_result", "route-event-loss-result")
	ui.large_text_checkbox.set_pressed_no_signal(true)
	ui._on_large_text_toggled(true)
	await _capture(ui, "route_event_loss_result_large_text", "route-event-loss-result-large-text")
	ui.large_text_checkbox.set_pressed_no_signal(false)
	ui._on_large_text_toggled(false)
	if not ui._write_save("SAVED"):
		push_error("Native capture could not create its isolated confirmation save.")
		quit(1)
		return
	ui._show_main_menu()
	ui._refresh_continue_availability()
	ui._on_start_game_requested()
	await _capture(ui, "new_game_confirmation", "new-game-confirmation")
	ui.new_game_confirmation_dialog.canceled.emit()
	ui.new_game_confirmation_dialog.hide()

	var captured_screens: Array = captures.map(func(capture: Dictionary) -> String: return String(capture.get("screen", "")))
	for required_screen in CAPTURE_SCREENS:
		if not captured_screens.has(required_screen):
			push_error("Native capture omitted required screen: %s" % required_screen)
			quit(1)
			return
	var manifest_path := output_directory.path_join("native-capture-%dx%d.json" % [requested_size.x, requested_size.y])
	var manifest_file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if manifest_file == null:
		push_error("Could not write native capture manifest: %s" % error_string(FileAccess.get_open_error()))
		quit(1)
		return
	manifest_file.store_string(JSON.stringify({
		"manifest_version": 1,
		"platform": OS.get_name(),
		"display_scale": ui._report_display_scale(),
		"reported_viewport": {"width": ui._report_viewport_size().x, "height": ui._report_viewport_size().y},
		"required_screens": CAPTURE_SCREENS,
		"captures": captures,
	}, "  "))
	manifest_file = null
	print("Native UI captures: PASS (%dx%d)" % [requested_size.x, requested_size.y])
	for suffix in [".save", ".save.bak", ".save.tmp", ".cfg", ".json"]:
		var generated_path := ProjectSettings.globalize_path(capture_user_prefix + suffix)
		if FileAccess.file_exists(generated_path):
			DirAccess.remove_absolute(generated_path)
	ui.queue_free()
	await process_frame
	quit(0)

func _parse_arguments() -> bool:
	var arguments := OS.get_cmdline_user_args()
	var index := 0
	while index < arguments.size():
		match arguments[index]:
			"--output-dir":
				index += 1
				if index < arguments.size():
					output_directory = ProjectSettings.globalize_path(arguments[index])
			"--width":
				index += 1
				if index < arguments.size():
					requested_size.x = int(arguments[index])
			"--height":
				index += 1
				if index < arguments.size():
					requested_size.y = int(arguments[index])
		index += 1
	if output_directory.is_empty() or requested_size.x <= 0 or requested_size.y <= 0:
		push_error("Usage: capture_native_ui.gd -- --output-dir PATH --width WIDTH --height HEIGHT")
		return false
	return true

func _complete_player_opening_trade(ui: Control) -> bool:
	ui._on_bazaar_navigation_pressed("trade")
	var command_count_before: int = ui.world.command_history.size()
	ui._on_buy_pressed()
	var purchase_succeeded: bool = (
		ui.world.command_history.size() == command_count_before + 1
		and String(ui.world.command_history.back().get("id", "")) == MarketCommandProcessor.BUY_GOODS
		and bool(ui.world.command_history.back().get("ok", false))
	)
	if not purchase_succeeded:
		push_error("Native capture could not complete the opening trade through player-facing actions.")
	return purchase_succeeded

func _capture(ui: Control, screen: String, file_stem: String) -> void:
	await process_frame
	await process_frame
	RenderingServer.force_draw(false)
	await process_frame
	var image := root.get_texture().get_image()
	if image == null or image.is_empty():
		push_error("Native capture requires a real renderer; do not run this tool with --headless.")
		quit(1)
		return
	if image.get_size() != requested_size:
		push_error("Native capture for %s is %s, expected %s." % [screen, image.get_size(), requested_size])
		quit(1)
		return
	var file_name := "%s-%dx%d.png" % [file_stem, requested_size.x, requested_size.y]
	var file_path := output_directory.path_join(file_name)
	var save_error := image.save_png(file_path)
	if save_error != OK:
		push_error("Could not save %s: %s" % [file_path, error_string(save_error)])
		quit(1)
		return
	captures.append({
		"screen": screen,
		"requested_window": {"width": requested_size.x, "height": requested_size.y},
		"captured_viewport": {"width": image.get_width(), "height": image.get_height()},
		"file": file_name,
		"bytes": FileAccess.get_file_as_bytes(file_path).size(),
		"ui_state": ui._web_ui_state(),
		"layout": _layout_evidence(ui),
	})

func _layout_evidence(ui: Control) -> Dictionary:
	if ui.map_hint == null or ui.map_panel == null or ui.event_scroll == null:
		return {}
	var hint_rect: Rect2 = ui.map_hint.get_global_rect()
	var board_rect: Rect2 = ui.map_panel._board_rect()
	var result_rect: Rect2 = ui.event_scroll.get_global_rect()
	var game_rect: Rect2 = ui.game_layer.get_global_rect()
	var focused: Control = ui.get_viewport().gui_get_focus_owner()
	var departure_scroll: ScrollContainer = ui.find_child("DepartureControlsScroll", true, false)
	var active_layer: Control = ui.menu_layer if ui.menu_layer.visible else ui.intro_layer if ui.intro_layer.visible else ui.shop_layer if ui.shop_layer.visible else ui.game_layer
	var required_controls := {}
	for node_name in [
		"MainMenuCard",
		"MainMenuHeading",
		"MainMenuWelcome",
		"MainMenuPrimaryAction",
		"MainMenuContinueAction",
		"MainMenuSettingsAction",
		"MainMenuCreditsAction",
		"MainMenuSaveStatus",
		"MainMenuQuitAction",
		"IntroductionCard",
		"IntroductionProgress",
		"IntroductionTitle",
		"IntroductionBodyScroll",
		"IntroductionNote",
		"IntroductionBackAction",
		"IntroductionPrimaryAction",
		"IntroductionSkipAction",
		"BazaarMarketPanel",
		"ShopActionCard",
		"BazaarMarketStatus",
		"BazaarCargoStatus",
		"BazaarDecisionSummary",
		"BazaarSectionTitle",
		"CrewRosterCard0",
		"CrewPortrait0",
		"CrewIdentity0",
		"CrewAction0",
		"BazaarPricePreview",
		"BuyCargoButton",
		"SellCargoButton",
		"TradeReceiptPanel",
		"BazaarPrimaryAction",
		"CampaignDebriefPanel",
		"EndingContinueAction",
		"EndingReplayAction",
		"EndingTitleAction",
		"EndingFeedbackAction",
		"JourneyMapPanel",
		"DeparturePanel",
		"DepartureControlsScroll",
		"DeparturePrimaryAction",
		"RoadPrimaryAction",
		"RoadEventPanel",
		"ArrivalDebriefPanel",
		"JourneyConsequenceReceipt",
		"JourneyConsequenceKicker",
		"JourneyConsequenceTitle",
		"JourneyConsequenceDetail",
		"ArrivalPrimaryAction",
		"JourneyResultScroll",
	]:
		var control: Control = ui.find_child(node_name, true, false)
		if control != null:
			required_controls[node_name] = {
				"visible": control.is_visible_in_tree(),
				"rect": _rect_data(control.get_global_rect()),
			}
	return {
		"map_hint": {"x": hint_rect.position.x, "y": hint_rect.position.y, "width": hint_rect.size.x, "height": hint_rect.size.y},
		"map_board": {"x": board_rect.position.x, "y": board_rect.position.y, "width": board_rect.size.x, "height": board_rect.size.y},
		"result": {"x": result_rect.position.x, "y": result_rect.position.y, "width": result_rect.size.x, "height": result_rect.size.y},
		"game_layer": _rect_data(game_rect),
		"focused": _rect_data(focused.get_global_rect()) if focused != null else {},
		"departure_scroll": _rect_data(departure_scroll.get_global_rect()) if departure_scroll != null else {},
		"active_layer": _rect_data(active_layer.get_global_rect()),
		"required_controls": required_controls,
		"opening_compact": (ui.menu_columns != null and ui.menu_columns.compact) or (ui.intro_columns != null and ui.intro_columns.compact),
		"release_surface": {
			"developer_panel_hidden": ui.developer_panel == null or not ui.developer_panel.visible,
			"diagnostics_hidden": ui.diagnostics_label == null or not ui.diagnostics_label.visible,
			"report_action_hidden": ui.shop_report_button == null or not ui.shop_report_button.visible,
		},
	}

func _rect_data(rect: Rect2) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}
