extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame
	var test_save_path := "user://market_of_ash_map_ui_test.save"
	var absolute_test_save_path := ProjectSettings.globalize_path(test_save_path)
	var test_backup_path := test_save_path + ".bak"
	var absolute_test_backup_path := ProjectSettings.globalize_path(test_backup_path)
	var test_temporary_path := test_save_path + ".tmp"
	var absolute_test_temporary_path := ProjectSettings.globalize_path(test_temporary_path)
	var test_settings_path := "user://market_of_ash_map_ui_settings_test.cfg"
	var absolute_test_settings_path := ProjectSettings.globalize_path(test_settings_path)
	var test_report_path := "user://market_of_ash_map_ui_report_test.json"
	var absolute_test_report_path := ProjectSettings.globalize_path(test_report_path)
	for test_path in [absolute_test_save_path, absolute_test_backup_path, absolute_test_temporary_path]:
		if FileAccess.file_exists(test_path):
			DirAccess.remove_absolute(test_path)
	if FileAccess.file_exists(test_settings_path):
		DirAccess.remove_absolute(absolute_test_settings_path)
	ui.save_path = test_save_path
	ui.autosave_enabled = false
	ui.settings_persistence_enabled = false
	ui._on_restore_default_bindings()
	ui.large_text_checkbox.button_pressed = false
	ui.reduce_motion_checkbox.button_pressed = false
	ui.settings_path = test_settings_path
	ui.report_path = test_report_path
	ui.settings_persistence_enabled = true
	ui.continue_game_button.disabled = true

	_expect(ui.menu_layer != null and ui.menu_layer.visible, "main menu should be visible on first launch")
	_expect(ui.shop_layer != null and not ui.shop_layer.visible, "shop should remain hidden until Start Game")
	_expect(ui.game_layer != null and not ui.game_layer.visible, "departure map should remain hidden until planning begins")
	_expect(ui.start_game_button != null and ui.start_game_button.text == "Start Game", "main menu should expose a Start Game button")
	_expect(_has_scroll_ancestor(ui.start_game_button), "the expanded Main Menu settings and launch controls should remain reachable through a scroll container")
	_expect(ui.continue_game_button != null and ui.continue_game_button.text == "Continue saved game", "main menu should expose a separate validated continue action")
	_expect(ui.reduce_motion_checkbox != null and ui.reduce_motion_checkbox.text == "Reduce travel motion", "main menu should expose a reduced-motion option")
	_expect(ui.large_text_checkbox != null and ui.large_text_checkbox.text == "Large text", "main menu should expose a large-text option")
	_expect(_action_has_joypad_button("ui_accept", 0), "ui_accept should retain the primary controller button")
	_expect(_action_has_joypad_button("ui_cancel", 1), "ui_cancel should retain the secondary controller button")
	_expect(_action_has_joypad_button("ui_pause", 6), "ui_pause should expose the controller menu button")
	_expect(ui.binding_buttons.size() == 3 and ui.controls_hint_label.text.contains("Enter / Space") and ui.controls_hint_label.text.contains("Escape/B"), "main menu should expose the current keyboard bindings alongside the controller scheme")
	ui._on_rebind_pressed("ui_pause")
	var rebind_pause := InputEventKey.new()
	rebind_pause.physical_keycode = KEY_R
	rebind_pause.pressed = true
	ui._unhandled_input(rebind_pause)
	_expect(_action_has_key("ui_pause", KEY_R) and _action_has_joypad_button("ui_pause", 6), "rebinding Pause should replace its keyboard key without removing controller Menu")
	var rebound_settings := ConfigFile.new()
	_expect(rebound_settings.load(test_settings_path) == OK and rebound_settings.get_value("input", "ui_pause", []).has(KEY_R), "keyboard remapping should persist outside the campaign save")
	ui._replace_keyboard_bindings("ui_pause", [KEY_P])
	ui._load_presentation_settings()
	_expect(_action_has_key("ui_pause", KEY_R) and _action_has_joypad_button("ui_pause", 6), "loading presentation settings should restore the saved keyboard mapping without changing controller input")
	ui._on_rebind_pressed("ui_cancel")
	ui._unhandled_input(rebind_pause)
	_expect(ui.remapping_action == "ui_cancel" and ui.binding_status_label.text.contains("already assigned to Pause"), "keyboard remapping should reject a key already owned by another required action")
	var reserved_rebind := InputEventKey.new()
	reserved_rebind.physical_keycode = KEY_DOWN
	reserved_rebind.pressed = true
	ui._unhandled_input(reserved_rebind)
	_expect(ui.remapping_action == "ui_cancel" and ui.binding_status_label.text.contains("reserved"), "keyboard remapping should preserve focus-navigation keys")
	var cancel_rebind := InputEventKey.new()
	cancel_rebind.physical_keycode = KEY_ESCAPE
	cancel_rebind.pressed = true
	ui._unhandled_input(cancel_rebind)
	_expect(ui.remapping_action.is_empty() and ui.binding_status_label.text.contains("cancelled"), "Escape should cancel key capture without changing bindings")
	ui._on_restore_default_bindings()
	_expect(_action_has_key("ui_pause", KEY_P) and _action_has_key("ui_cancel", KEY_ESCAPE) and _action_has_key("ui_accept", KEY_ENTER), "Restore default keys should recover the complete keyboard control scheme")
	var invalid_bindings := ConfigFile.new()
	invalid_bindings.set_value("input", "ui_accept", [KEY_R])
	invalid_bindings.set_value("input", "ui_cancel", [KEY_R])
	invalid_bindings.set_value("input", "ui_pause", [KEY_P])
	invalid_bindings.save(test_settings_path)
	ui._load_presentation_settings()
	_expect(_action_has_key("ui_accept", KEY_ENTER) and _action_has_key("ui_cancel", KEY_ESCAPE) and _action_has_key("ui_pause", KEY_P), "invalid persisted key conflicts should fall back to the complete default scheme")
	var repaired_bindings := ConfigFile.new()
	_expect(repaired_bindings.load(test_settings_path) == OK and repaired_bindings.get_value("input", "ui_accept", []).has(KEY_ENTER) and repaired_bindings.get_value("input", "ui_cancel", []).has(KEY_ESCAPE), "invalid persisted bindings should be replaced with a valid default settings file")

	ui._on_start_game_pressed()
	_expect(not ui.menu_layer.visible and ui.shop_layer.visible and not ui.game_layer.visible, "Start Game should open the central shop rather than the departure map")
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.shop_good_option, "opening the shop should focus its first planning control")
	ui._open_pause()
	_expect(ui.pause_layer.visible and ui.get_tree().paused and ui.get_viewport().gui_get_focus_owner() == ui.pause_resume_button, "pausing from the shop should stop the tree and focus Resume")
	ui._close_pause()
	_expect(not ui.pause_layer.visible and not ui.get_tree().paused and ui.get_viewport().gui_get_focus_owner() == ui.shop_good_option, "resuming should restore the previous gameplay focus")
	var valid_test_save_path: String = ui.save_path
	ui.save_path = "user://market_of_ash_missing_parent_test/campaign.save"
	ui.autosave_enabled = true
	ui._open_pause()
	ui._on_pause_main_menu_pressed()
	_expect(ui.pause_layer.visible and ui.get_tree().paused and ui.shop_layer.visible and not ui.menu_layer.visible, "Return to main menu should keep the live campaign open when its protective autosave fails")
	_expect(ui.pause_summary_label.text.contains("RETURN BLOCKED") and ui.pause_summary_label.text.contains("could not be saved"), "a blocked return should explain the save failure inside Pause")
	ui.save_path = valid_test_save_path
	ui.autosave_enabled = false
	ui._close_pause()
	_expect(ui.world.current_settlement == "ashgate" and ui.world.day == 1, "Start Game did not load the authored Ashgate day-one preset")
	_expect(ui.world.money == 120 and ui.world.provisions == 12 and int(ui.world.cargo.get("weight", 0)) == 0, "Start Game did not restore the authored resource preset")
	_expect(ui._selected_id(ui.shop_good_option) == "grain" and int(ui.shop_quantity.value) == 2, "shop did not select the authored first market example")
	_expect(ui.plan_departure_button != null and ui.plan_departure_button.text == "Plan departure", "shop did not expose the plan-departure handoff")
	_expect(_has_scroll_ancestor(ui.plan_departure_button), "the long shop action rail should remain reachable through a scroll container")
	_expect(ui.shop_market_preview_label != null and ui.shop_market_preview_label.text.contains("Why this price:"), "shop did not render an explainable market preview")
	_expect(_has_scroll_ancestor(ui.shop_good_option), "the primary Shop trade workflow should remain reachable through a scroll container")
	_expect(ui.shop_status_label != null and ui.shop_status_label.text.contains("Ashgate"), "shop did not render local settlement context")
	_expect(ui.opportunity_status_label != null and ui.opportunity_status_label.text.contains("2 of 2 visit slots remain"), "shop did not expose the visit-action budget")
	_expect(ui.campaign_outlook_label.text.contains("Open Routes") and ui.campaign_outlook_label.text.contains("Wardens 0/3") and ui.campaign_outlook_label.text.contains("120/220 ashmarks"), "shop should expose exact progress toward each campaign conclusion")
	_expect(ui.opportunity_buttons.size() == 3 and not ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[1].disabled and ui.opportunity_buttons[2].disabled, "Ashgate should expose provisions, cargo-gated arms, and condition-gated recovery")
	_expect(ui.opportunity_buttons[0].focus_mode != Control.FOCUS_NONE, "the local opportunity should remain keyboard/controller focusable")
	_expect(ui.contract_buttons.size() == 1 and not ui.contract_buttons[0].disabled, "Ashgate should expose the Reedwatch relief contract")
	_expect(ui.crew_buttons.size() == 3 and ui.crew_buttons[0].text.contains("Recruit Nara Vey") and ui.crew_buttons[1].text.contains("Recruit Jorun Pale") and ui.crew_buttons[2].text.contains("Recruit Tess Oryn"), "Ashgate should expose all authored crew recruit actions")
	_expect(ui.route_preview_label.text.contains("Scout unavailable"), "route forecast should explain that scout information is unavailable")
	_expect(ui.diagnostics_label.text.contains("build development") and ui.diagnostics_label.text.contains("seed 1107") and ui.diagnostics_label.text.contains("save v11") and ui.diagnostics_label.text.contains("content 1.15.0"), "shop diagnostics should expose reproducible build/seed/save/content versions")
	var state_before_missing_load := JSON.stringify(ui.world.serialize())
	ui._on_load_pressed()
	_expect(JSON.stringify(ui.world.serialize()) == state_before_missing_load and ui.save_status_label.text.contains("No saved campaign exists"), "loading a missing save should explain the block without changing the current run")
	ui._open_pause()
	ui._on_pause_load_pressed()
	_expect(ui.pause_layer.visible and ui.get_tree().paused and ui.pause_summary_label.text.contains("No saved campaign exists"), "a failed load from Pause should keep the campaign paused with the validation reason visible")
	ui._close_pause()
	ui._on_save_pressed()
	_expect(FileAccess.file_exists(test_save_path) and ui.save_status_label.text.contains("SAVED — Day 1 · Ashgate · 120 ashmarks · hold 0/12"), "manual save should write a versioned campaign and expose a readable resource summary")
	_expect(not ui.continue_game_button.disabled, "a successful save should enable the main-menu continue action")
	ui._open_pause()
	ui._on_save_pressed()
	_expect(ui.pause_layer.visible and ui.pause_summary_label.text.contains("SAVED — Day 1 · Ashgate"), "saving from Pause should keep the overlay open and show its result there")
	ui._close_pause()
	ui._refresh_continue_availability()
	_expect(ui.menu_save_status_label.text.contains("CONTINUE — Day 1 · Ashgate · 120 ashmarks · hold 0/12 · primary save"), "main menu should preview a validated saved campaign before loading")
	var manual_save_state := JSON.stringify(ui.world.serialize())
	ui._on_settlement_action_pressed("ashgate_provision_bundle")
	_expect(JSON.stringify(ui.world.serialize()) != manual_save_state, "save/load fixture should mutate the active run before restoration")
	ui._open_pause()
	ui._on_pause_load_pressed()
	_expect(JSON.stringify(ui.world.serialize()) == manual_save_state and ui.save_status_label.text.contains("LOADED — Day 1 · Ashgate"), "loading a valid save should restore the exact campaign state")
	_expect(not ui.pause_layer.visible and not ui.get_tree().paused and ui.get_viewport().gui_get_focus_owner() == ui.shop_good_option, "a successful load from Pause should close the overlay and focus the restored Shop")
	ui._on_save_pressed()
	_expect(FileAccess.file_exists(test_backup_path), "replacing a valid save should preserve one backup generation")
	var corrupt_file := FileAccess.open(test_save_path, FileAccess.WRITE)
	corrupt_file.store_string("{not valid json")
	corrupt_file = null
	var state_before_corrupt_load := JSON.stringify(ui.world.serialize())
	ui._refresh_continue_availability()
	_expect(not ui.continue_game_button.disabled and ui.menu_save_status_label.text.contains("backup save"), "a valid backup should keep Continue available when the primary is corrupt")
	ui._on_load_pressed()
	_expect(JSON.stringify(ui.world.serialize()) == state_before_corrupt_load and ui.save_status_label.text.contains("RECOVERED BACKUP"), "a corrupt primary save should recover the previous validated generation")
	if FileAccess.file_exists(test_backup_path):
		DirAccess.remove_absolute(absolute_test_backup_path)
	var future_save: Dictionary = ui.world.serialize()
	future_save["save_version"] = 999
	var future_file := FileAccess.open(test_save_path, FileAccess.WRITE)
	future_file.store_string(JSON.stringify(future_save))
	future_file = null
	var future_backup_file := FileAccess.open(test_backup_path, FileAccess.WRITE)
	future_backup_file.store_string(JSON.stringify(future_save))
	future_backup_file = null
	var state_before_future_load := JSON.stringify(ui.world.serialize())
	ui._refresh_continue_availability()
	_expect(ui.continue_game_button.disabled and ui.menu_save_status_label.text.contains("could not be validated"), "Continue should disable when neither primary nor backup can be validated")
	ui._on_load_pressed()
	_expect(JSON.stringify(ui.world.serialize()) == state_before_future_load and ui.save_status_label.text.contains("newer than this build"), "a future-version save should be rejected without replacing the active run")
	var invalid_shape_file := FileAccess.open(test_save_path, FileAccess.WRITE)
	var invalid_shape_payload := JSON.stringify({"save_version": 11, "command_history": "not-a-list"})
	invalid_shape_file.store_string(invalid_shape_payload)
	invalid_shape_file = null
	var invalid_shape_backup_file := FileAccess.open(test_backup_path, FileAccess.WRITE)
	invalid_shape_backup_file.store_string(invalid_shape_payload)
	invalid_shape_backup_file = null
	var state_before_invalid_shape := JSON.stringify(ui.world.serialize())
	ui._on_load_pressed()
	_expect(JSON.stringify(ui.world.serialize()) == state_before_invalid_shape and ui.save_status_label.text.contains("command_history must be a list"), "valid JSON with an invalid save shape should be rejected without replacing the active run")
	ui._on_save_pressed()
	ui.autosave_enabled = true
	var action_money_before: int = ui.world.money
	var action_provisions_before: int = ui.world.provisions
	ui._on_settlement_action_pressed("ashgate_provision_bundle")
	_expect(ui.world.money == action_money_before - 6 and ui.world.provisions == action_provisions_before + 4, "local opportunity UI did not execute the command's visible effects")
	_expect(ui.world.reputation.wardens == 1 and ui.shop_status_label.text.contains("Wardens +1"), "Warden ration action did not expose its named standing gain")
	_expect(ui.opportunity_status_label.text.contains("1 of 2 visit slots remain"), "local opportunity UI did not refresh the remaining visit budget")
	ui.world.current_settlement = "brine_cross"
	ui.world.reset_visit_slots()
	ui._refresh_ui()
	_expect(ui.opportunity_buttons.size() == 1 and ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[0].tooltip_text.contains("crisis stage 1"), "Brine Cross should preview the cistern queue before the shortage")
	ui.world.crisis_stage = 1
	ui.world._update_crisis_modifiers()
	ui._refresh_ui()
	_expect(not ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[0].text.contains("local resilience"), "Thin Wells should activate the visible Brine Cross cistern opportunity")
	ui._on_settlement_action_pressed("brine_cross_cistern_queue")
	_expect(ui.world.resilience_for("brine_cross") == 1 and ui.world.known_information.has("brine_pump_failures"), "cistern queue UI should apply and expose its durable local result")
	_expect(ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[0].tooltip_text.contains("Already completed"), "completed cistern work should remain visible without being repeatable")
	ui.world.current_settlement = "hollow_market"
	ui.world.crisis_stage = 0
	ui.world._update_crisis_modifiers()
	ui.world.reset_visit_slots()
	ui._refresh_ui()
	_expect(ui.opportunity_buttons.size() == 1 and not ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[0].text.contains("-5% Dry Cut risk"), "Hollow Market should expose its paid Dry Cut report")
	ui._on_settlement_action_pressed("hollow_market_route_rumor")
	_expect(ui.world.known_information.has("dry_cut_water_cache") and is_equal_approx(float(ui.world.route("dry_cut").risk), 0.50), "Hollow Market rumor UI should apply its visible route condition")
	ui.world.current_settlement = "cinderford"
	ui.world.reset_visit_slots()
	ui._refresh_ui()
	_expect(ui.opportunity_buttons.size() == 1 and not ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[0].text.contains("-3% Toll Road risk"), "reachable Cinderford should expose its repair-bench route investment")
	ui._on_settlement_action_pressed("cinderford_repair_bench")
	_expect(ui.world.known_information.has("cinderford_repair_ledger") and is_equal_approx(float(ui.world.route("toll_road").risk), 0.07), "Cinderford repair UI should apply its visible Toll Road condition")
	ui.world.current_settlement = "reedwatch"
	ui.world.crisis_stage = 1
	ui.world._update_crisis_modifiers()
	ui.world.reset_visit_slots()
	ui.world.contract_history.append({"id": "reedwatch_water_relief_01", "status": "completed"})
	ui._refresh_ui()
	_expect(ui.opportunity_buttons.size() == 1 and not ui.opportunity_buttons[0].disabled and ui.opportunity_buttons[0].text.contains("local resilience"), "completed relief should unlock Reedwatch's supply shelter during the crisis")
	ui._on_settlement_action_pressed("reedwatch_supply_shelter")
	_expect(ui.world.resilience_for("reedwatch") == 1 and int(ui.world.reputation.get("caravans", 0)) == 1, "Reedwatch shelter UI should apply its local and faction results")
	ui._on_start_game_pressed()
	ui._on_accept_contract_pressed("reedwatch_water_relief_01")
	_expect(not ui.world.active_contract("reedwatch_water_relief_01").is_empty(), "contract card did not accept the relief contract through the command boundary")
	_expect(ui.active_contract_label.text.contains("4 water at Reedwatch by Day 3"), "shop did not show the frozen active-contract terms")

	var forecast_before: String = JSON.stringify(ui.world.serialize())
	ui.shop_quantity.value = 3
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	if JSON.stringify(ui.world.serialize()) != forecast_before:
		failures.append("shop forecast changes mutated authoritative world state")
	if not ui.shop_market_preview_label.text.contains("load total"):
		failures.append("shop market preview did not refresh selected load total")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)

	ui._on_guided_test_action()
	_expect(int(ui.world.cargo.get("grain", 0)) == 2 and int(ui.world.cargo.get("weight", 0)) == 2, "guided test action did not execute the promised grain purchase")
	_expect(ui.world.command_history.size() == 2 and ui.world.command_history.back().id == "buy_goods", "guided test action did not use the explicit command boundary")
	_expect(ui.event_label.text.contains("NEXT —") and ui.event_label.text.contains("Plan departure"), "a successful shop command should end with a concrete next action")
	_expect(ui.guided_test_button.disabled, "guided test action should be unavailable after its one preset execution")
	_expect(ui.save_status_label.text.contains("AUTOSAVED") and ui.save_status_label.text.contains("save v11"), "successful commands should expose a versioned autosave summary")
	_expect(ui.playtest_status_label.text.contains("STEP 2 OF 3"), "grain purchase did not advance the playtest objective")
	var state_before_report := JSON.stringify(ui.world.serialize())
	ui._on_export_report_pressed()
	_expect(FileAccess.file_exists(test_report_path) and JSON.stringify(ui.world.serialize()) == state_before_report, "playtest report export should write diagnostics without mutating campaign state")
	var report_parser := JSON.new()
	var report_file := FileAccess.open(test_report_path, FileAccess.READ)
	var report_error := report_parser.parse(report_file.get_as_text())
	report_file = null
	var report: Dictionary = report_parser.data if report_error == OK and typeof(report_parser.data) == TYPE_DICTIONARY else {}
	_expect(int(report.get("report_version", 0)) == 1 and report.get("game_version", "") == "0.9.0-alpha-roadmap" and report.get("build_commit", "") == "development" and int(report.get("seed", 0)) == 1107 and report.get("command_history", []).size() == 2, "playtest report should include schema, build, seed, and command evidence")
	_expect(report.has("active_contracts") and report.has("contract_history") and report.has("event_history") and report.has("route_conditions") and report.has("known_information") and report.has("ending_summary"), "playtest report should include the campaign evidence needed to reconstruct decisions and outcomes")
	_expect(ui.event_label.text.contains("No personal data is included"), "report export should explain its privacy boundary")
	ui._open_pause()
	ui._on_export_report_pressed()
	_expect(ui.pause_layer.visible and ui.pause_summary_label.text.contains("REPORT EXPORTED") and ui.pause_summary_label.text.contains("market_of_ash_map_ui_report_test.json"), "report export from Pause should show a visible result and output path without closing the overlay")
	ui._close_pause()
	var valid_report_path: String = ui.report_path
	ui.report_path = "user://market_of_ash_missing_report_parent/report.json"
	ui._open_pause()
	ui._on_export_report_pressed()
	_expect(ui.pause_layer.visible and ui.pause_summary_label.text.contains("Report export failed") and JSON.stringify(ui.world.serialize()) == state_before_report, "a failed report export should stay visible in Pause without mutating the campaign")
	ui.report_path = valid_report_path
	ui._close_pause()

	var shop_state: String = JSON.stringify(ui.world.serialize())
	ui._on_plan_departure_pressed()
	_expect(not ui.shop_layer.visible and ui.game_layer.visible, "Plan departure should open the dedicated departure map")
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.destination_option, "opening departure planning should focus the destination control")
	_expect(ui._selected_id(ui.destination_option) == "reedwatch" and ui._selected_id(ui.route_option) == "old_road", "departure desk did not preserve the selected first-route plan")
	_expect(ui.departure_load_label != null and ui.departure_load_label.text.contains("Grain x2"), "departure desk did not carry the planned load forward")
	_expect(ui.route_preview_label != null and ui.route_preview_label.text.contains("EXPECTED NET PROFIT"), "departure desk did not render the route-profit preview")
	_expect(_has_scroll_ancestor(ui.commit_departure_button), "the departure control rail should remain reachable through a scroll container")
	_expect(ui.departure_contract_label.text.contains("CONTRACT PIN") and ui.departure_contract_label.text.contains("Held 0/4"), "departure desk did not pin the active contract and cargo shortfall")
	_expect(ui.route_preview_label.text.contains("1 Grain unit at risk"), "departure desk did not disclose the one-unit cargo risk basis")
	_expect(ui.route_preview_label.text.contains("Risk source:"), "departure desk did not disclose the authored route-risk source")
	var cancel_event := InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	ui._unhandled_input(cancel_event)
	_expect(ui.shop_layer.visible and not ui.game_layer.visible, "Return to shop should close the departure map")
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.shop_good_option, "returning to the shop should restore a predictable keyboard focus target")
	if JSON.stringify(ui.world.serialize()) != shop_state:
		failures.append("returning from departure planning mutated authoritative world state")

	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_option.item_count == 1 and ui._selected_id(ui.route_option) == "toll_road", "destination selection should expose only the connected Toll Road route")
	ui._select_option_by_id(ui.destination_option, "cinderford")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_option.item_count == 1 and ui._selected_id(ui.route_option) == "toll_road" and ui.route_preview_label.text.contains("Route fee 6"), "Cinderford should be selectable as the nearer Toll Road stop with its segment fee")
	ui._select_option_by_id(ui.destination_option, "reedwatch")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_option.item_count == 1 and ui._selected_id(ui.route_option) == "old_road", "destination selection should restore the connected Old Road route")

	_expect(ui.map_panel != null, "departure UI did not create the map panel")
	if ui.map_panel != null:
		_expect(ui.map_panel.GRID_SIZE == Vector2i(17, 11), "map grid size is not the stable 17x11 contract")
		_expect(ui.map_panel._route_points("old_road").size() == 3, "old road does not expose a traversable three-point corridor")
		_expect(ui.map_panel._map_heading().contains("ORDINARY PRESSURE") and ui.map_panel._settlement_marker_detail("ashgate").contains("HERE") and not ui.map_panel._settlement_marker_detail("reedwatch").contains("HERE"), "map text should identify the crisis stage and current location without relying on color")
		var map_before: String = JSON.stringify(ui.world.serialize())
		var map_click := InputEventMouseButton.new()
		map_click.button_index = MOUSE_BUTTON_LEFT
		map_click.pressed = true
		map_click.position = ui.map_panel._settlement_point("brine_cross")
		ui.map_panel._gui_input(map_click)
		_expect(ui._selected_id(ui.destination_option) == "brine_cross" and ui._selected_id(ui.route_option) == "toll_road", "clicking a reachable settlement marker should select its legal destination and route")
		ui._on_map_settlement_selected("hollow_market")
		_expect(ui.event_label.text.contains("No direct route reaches Hollow Market"), "an unreachable settlement marker should explain the required intermediate journey")
		ui._on_map_settlement_selected("reedwatch")
		_expect(ui._selected_id(ui.destination_option) == "reedwatch" and ui._selected_id(ui.route_option) == "old_road" and ui.event_label.text.contains("Map destination selected: Reedwatch"), "map planning should restore a directly reachable destination with clear commitment guidance")
		if JSON.stringify(ui.world.serialize()) != map_before:
			failures.append("map destination selection mutated authoritative world state")
		ui._on_depart_pressed()
		_expect(ui.map_panel.traveling, "successful departure did not start presentation traversal")
		_expect(ui.map_panel.travel_points.size() == 3, "travel traversal did not create origin, waypoint, destination")
		_expect(ui.enter_settlement_button.visible and ui.commit_departure_button.disabled, "arrival state did not present an explicit settlement-entry action")
		_expect(ui.get_viewport().gui_get_focus_owner() == ui.enter_settlement_button, "an uninterrupted arrival should focus the settlement-entry action")
		_expect(ui.playtest_status_label.text.contains("STEP 3 OF 3"), "arrival with grain did not advance the playtest objective")
		await process_frame
		_expect(ui.map_panel.travel_progress > 0.0, "presentation traversal did not advance")

	ui._on_enter_settlement_pressed()
	_expect(not ui.destination_option.disabled and not ui.route_option.disabled and not ui.cargo_good_option.disabled and ui.cargo_quantity.editable, "entering the settlement should unlock planning controls for the next journey")
	_expect(ui.shop_layer.visible and not ui.game_layer.visible, "Enter settlement should return the player to the central shop")
	_expect(ui.opportunity_status_label.text.contains("2 of 2 visit slots remain"), "arrival did not refresh the destination visit budget")
	_expect(ui.opportunity_buttons.size() == 1 and ui.opportunity_buttons[0].disabled, "Reedwatch should show its unavailable opportunity with a disabled control")
	_expect(ui.opportunity_buttons[0].tooltip_text.contains("completed Reedwatch Water Relief"), "disabled Reedwatch opportunity did not explain its contract and crisis dependency")
	_expect(ui.contract_buttons.size() == 1 and ui.contract_buttons[0].disabled, "partial contract should remain visible but blocked until required cargo is acquired")
	_expect(ui.contract_buttons[0].tooltip_text.contains("Acquire 4 more water"), "partial contract should explain the exact missing cargo")
	ui._on_sell_pressed()
	_expect(ui.playtest_status_label.text.contains("RUN COMPLETE"), "selling delivered grain from the destination shop did not complete the playtest objective")
	_expect(ui.shop_market_preview_label.text.contains("Market memory: your last 2 grain delivered here softened this price by 8%"), "completed sale did not expose the local delivery-memory explanation")
	_expect(ui.shop_market_preview_label.text.contains("memory 0.92"), "market preview did not show the post-delivery price multiplier")

	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._on_depart_pressed()
	_expect(not ui.world.pending_event.is_empty() and ui.world.pending_event.id == "gatekeepers_chalk", "eligible Toll Road trip did not present Gatekeeper's Chalk")
	_expect(ui.event_card.visible and not ui.enter_settlement_button.visible, "pending route event should block arrival and show the event card")
	_expect(ui.event_label.text.contains("NEXT — Choose one available route response"), "a pending route event should state the next required action")
	_expect(ui.destination_option.disabled and ui.route_option.disabled and ui.cargo_good_option.disabled and not ui.cargo_quantity.editable, "a committed route event should lock planning controls until it resolves")
	var committed_destination: String = ui._selected_id(ui.destination_option)
	ui._on_map_settlement_selected("reedwatch")
	_expect(ui._selected_id(ui.destination_option) == committed_destination and ui.event_label.text.contains("journey is already committed"), "map clicks should not rewrite the displayed plan during a committed journey")
	_expect(ui.event_title_label.text == "The Gatekeeper's Chalk", "event card did not render the authored title")
	_expect(ui.event_stakes_label.text.contains("Toll Road") and ui.event_stakes_label.text.contains("1 Medicine unit valued at 44"), "event card did not expose route and cargo context")
	_expect(ui.event_choice_buttons.size() == 4, "Gatekeeper's Chalk should expose its three base choices and Tess's visible negotiation option")
	_expect(ui.event_choice_buttons[0].autowrap_mode == TextServer.AUTOWRAP_WORD_SMART and ui.event_choice_buttons[0].custom_minimum_size.y >= 58.0, "long event choices should wrap instead of clipping their costs and consequences")
	_expect(ui.event_choice_buttons[3].disabled and ui.event_choice_buttons[3].tooltip_text.contains("Tess Oryn"), "Tess's Gatekeeper option should remain visible with its assignment prerequisite")
	_expect(ui.event_choice_reason_labels.size() == 1 and ui.event_choice_reason_labels[0].text.contains("Tess Oryn"), "disabled event prerequisites should remain readable without hovering or focusing the unavailable control")
	_expect(ui.event_choice_buttons[0].focus_mode != Control.FOCUS_NONE, "event choices should remain keyboard/controller focusable")
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.event_choice_buttons[0], "a route decision should focus its first available choice")
	ui._on_save_pressed()
	ui._open_pause()
	ui._on_pause_load_pressed()
	_expect(not ui.pause_layer.visible and not ui.get_tree().paused and ui.world.pending_event.get("id", "") == "gatekeepers_chalk" and ui.get_viewport().gui_get_focus_owner() == ui.event_choice_buttons[0], "loading a pending journey from Pause should restore the event and focus its first available response")
	_expect(ui.departure_status_label.text.contains("ROUTE DECISION"), "departure screen did not identify the paused route decision")
	ui._unhandled_input(cancel_event)
	_expect(ui.pause_layer.visible and not ui.world.pending_event.is_empty(), "Escape during a route decision should pause without bypassing the pending choice")
	ui._unhandled_input(cancel_event)
	_expect(not ui.pause_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.event_choice_buttons[0], "closing pause during an event should restore the focused response")
	ui._on_event_choice_pressed("gatekeepers_chalk", "pay_posted_toll")
	_expect(ui.world.pending_event.is_empty() and ui.world.current_settlement == "brine_cross", "paying the event toll did not complete arrival")
	_expect(not ui.event_card.visible and ui.enter_settlement_button.visible, "resolved event should hide its choices and expose settlement entry")
	_expect(ui.event_label.text.contains("NEXT — Review the result") and ui.event_label.text.contains("Enter settlement"), "a resolved journey should state how to continue into the destination")
	_expect(ui.destination_option.disabled and ui.route_option.disabled, "an arrival report should keep planning controls locked until the player enters the settlement")
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.enter_settlement_button, "resolving a route decision should move focus to settlement entry")
	_expect(ui.world.event_history.size() == 1 and ui.world.event_history.back().choice_id == "pay_posted_toll", "event UI did not preserve the chosen outcome")

	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "scrap")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	_expect(ui.world.pending_event.get("id", "") == "span_at_cinderford", "eligible Old Road load did not present The Span at Cinderford")
	_expect(ui.event_title_label.text == "The Span at Cinderford", "span event card did not render its authored title")
	_expect(ui.event_stakes_label.text.contains("Old Road") and ui.event_stakes_label.text.contains("Repair stock recognized: 2 Scrap"), "span event card did not expose route and frozen material context")
	_expect(ui.event_choice_buttons.size() == 4, "span event should expose all four authored choices")
	_expect(ui.event_choice_buttons[0].text.contains("+30 ashmarks") and ui.event_choice_buttons[0].text.contains("2 materials"), "premium option did not disclose its reward and cargo cost")
	_expect(ui.event_choice_buttons[3].text.contains("return to origin"), "turn-back recovery did not disclose its movement result")
	_expect(ui.event_choice_buttons[0].focus_mode != Control.FOCUS_NONE, "span choices should remain keyboard/controller focusable")
	ui._on_event_choice_pressed("span_at_cinderford", "reserve_materials_for_span")
	_expect(ui.world.pending_event.is_empty() and ui.world.current_settlement == "reedwatch", "reserving span materials did not complete arrival")
	_expect(is_equal_approx(float(ui.world.route("old_road").risk), 0.25), "span event UI choice did not apply the disclosed later-route improvement")
	_expect(ui.event_label.text.contains("public support") and ui.enter_settlement_button.visible, "arrival report did not explain why the span choice changed the next route decision")

	ui._on_start_game_pressed()
	ui.world.crisis_stage = 1
	ui.world._update_crisis_modifiers()
	ui._select_option_by_id(ui.shop_good_option, "water")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	_expect(ui.route_preview_label.text.contains("40% risk") and ui.route_preview_label.text.contains("Crisis route change: Thin wells draw more opportunists"), "shortage-stage departure forecast should explain its higher Old Road exposure")
	ui._on_depart_pressed()
	_expect(ui.world.pending_event.get("id", "") == "last_clean_barrel", "shortage-stage water load did not present The Last Clean Barrel")
	_expect(ui.event_title_label.text == "The Last Clean Barrel", "barrel event card did not render its authored title")
	_expect(ui.event_stakes_label.text.contains("Shortage basis: 2 Water") and ui.event_stakes_label.text.contains("plus 6 premium each"), "barrel event did not expose its frozen cargo and premium basis")
	_expect(ui.event_choice_buttons.size() == 4 and ui.event_choice_buttons[0].text.contains("+"), "barrel event did not expose all choices and the exact emergency payout")
	_expect(ui.event_choice_buttons[2].disabled and ui.event_choice_buttons[2].tooltip_text.contains("active water relief commitment"), "contract-only barrel response did not show its unavailable prerequisite")
	_expect(ui.event_choice_reason_labels.size() == 1 and ui.event_choice_reason_labels[0].text.contains("active water relief commitment"), "the unavailable contract response should expose its prerequisite as persistent text")
	_expect(ui.event_choice_buttons[3].focus_mode != Control.FOCUS_NONE, "sealed-cargo recovery should remain focusable")
	ui._on_event_choice_pressed("last_clean_barrel", "share_barrels_fairly")
	_expect(ui.world.current_settlement == "reedwatch" and ui.world.resilience_for("reedwatch") == 2, "fair barrel distribution did not strengthen destination resilience")
	_expect(ui.event_label.text.contains("resilience is now 2/10"), "barrel arrival report did not explain the persistent settlement result")
	ui._on_enter_settlement_pressed()
	_expect(ui.shop_status_label.text.contains("Settlement resilience: 2/10") and ui.shop_status_label.text.contains("Caravans +1"), "settlement shop did not expose the event's resilience and Caravan-standing results")

	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	_expect(ui.world.pending_event.get("id", "") == "three_riders_no_banner", "high-value Old Road cargo did not present Three Riders, No Banner")
	_expect(ui.event_title_label.text == "Three Riders, No Banner", "escort event card did not render its authored title")
	_expect(ui.event_stakes_label.text.contains("1 Medicine unit") and ui.event_stakes_label.text.contains("Old Road"), "escort event did not expose its route and loss basis")
	_expect(ui.event_choice_buttons.size() == 4, "escort event should expose all four authored choices")
	_expect(ui.event_choice_buttons[0].text.contains("10 ashmarks") and ui.event_choice_buttons[1].text.contains("45% cargo risk"), "escort choices did not disclose payment and solo-crossing risk")
	_expect(ui.event_choice_buttons[2].text.contains("1 medicine") and not ui.event_choice_buttons[2].disabled, "medicine-for-passage choice did not expose its real cargo prerequisite")
	_expect(ui.event_choice_buttons[3].focus_mode != Control.FOCUS_NONE, "information recovery choice should remain focusable")
	ui._on_event_choice_pressed("three_riders_no_banner", "wait_and_read_the_tracks")
	_expect(ui.world.known_information.has("three_riders_sponsor_mark") and ui.world.day == 3, "waiting for the riders did not record the sponsor lead and delay")
	_expect(ui.event_label.text.contains("New information recorded"), "escort arrival report did not name the persistent information result")
	ui._on_enter_settlement_pressed()
	_expect(ui.shop_status_label.text.contains("Known leads: 1"), "settlement shop did not expose the persistent information lead")

	ui._on_start_game_pressed()
	ui._on_recruit_crew_pressed("nara_vey")
	_expect(ui.world.is_crew_recruited("nara_vey") and ui.world.money == 100 and ui.world.visit_slots_remaining == 1, "Nara recruitment UI did not apply its visible cost and slot")
	_expect(ui.crew_buttons.size() == 3 and ui.crew_buttons[0].text.contains("Refresh Nara Vey's route plan"), "recruited Nara should expose the assignment action alongside the other crew")
	ui._on_assign_crew_pressed("nara_vey")
	_expect(ui.world.assigned_crew == "nara_vey" and ui.world.visit_slots_remaining == 0, "Nara assignment UI did not consume its visit slot")
	ui._on_plan_departure_pressed()
	_expect(ui.route_preview_label.text.contains("Nara-informed") and ui.route_preview_label.text.contains("unmarked riders"), "departure forecast did not show Nara's same-day route note")
	_expect(ui.route_preview_label.text.contains("35% risk"), "Nara's route note should not erase the authored uncertainty")

	ui._on_start_game_pressed()
	ui._on_recruit_crew_pressed("tess_oryn")
	ui._on_assign_crew_pressed("tess_oryn")
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._on_depart_pressed()
	_expect(ui.world.pending_event.get("id", "") == "gatekeepers_chalk" and not ui.event_choice_buttons[3].disabled, "assigned Tess should enable the visible Gatekeeper negotiation")
	ui._on_event_choice_pressed("gatekeepers_chalk", "challenge_chalk_ledger")
	_expect(ui.world.reputation.wardens == -1 and ui.world.known_information.has("gatekeeper_invented_tolls"), "Tess's UI choice did not apply its named political and information consequences")
	_expect(ui.event_label.text.contains("Warden standing is now -1"), "Tess's arrival report did not disclose the relationship cost")

	ui._on_start_game_pressed()
	ui.world.adjust_reputation("wardens", 2)
	ui._refresh_ui()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_preview_label.text.contains("Route fee 9") and ui.route_preview_label.text.contains("Recognized carriers pay 3 fewer"), "recognized Warden forecast did not show the discounted Toll Road fee")
	_expect(ui.route_preview_label.text.contains("greater official visibility"), "Warden threshold forecast did not disclose its control tradeoff")

	ui.world.adjust_reputation("wardens", -2)
	ui.world.adjust_reputation("caravans", 2)
	ui._select_option_by_id(ui.destination_option, "reedwatch")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_preview_label.text.contains("Route fee 2") and ui.route_preview_label.text.contains("Known road-sharers pay 2 fewer"), "Free Caravan threshold did not show the discounted Old Road fee")
	_expect(ui.route_preview_label.text.contains("does not reduce the route's exposed cargo risk"), "Free Caravan threshold did not disclose its risk tradeoff")

	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "sealed_arms_crate")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	_expect(not ui.opportunity_buttons[1].disabled and ui.opportunity_buttons[1].text.contains("escalation +2"), "arms offer did not expose its cargo gate, payout, and escalation")
	ui._on_settlement_action_pressed("ashgate_cinder_rider_arms_sale")
	_expect(ui.world.arms_escalation == 2 and int(ui.world.cargo.get("sealed_arms_crate", 0)) == 1, "arms offer UI did not apply the named sale")
	_expect(ui.shop_status_label.text.contains("Arms escalation: 2/6") and ui.event_label.text.contains("Reedwatch Water Relief"), "arms result did not show its threshold and non-arms alternative")
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_preview_label.text.contains("Route fee 17") and ui.route_preview_label.text.contains("Arms inspection surcharge: +5"), "arms escalation did not expose the Toll Road inspection surcharge before departure")
	ui._on_return_to_shop_pressed()
	ui._on_settlement_action_pressed("ashgate_public_manifest_audit")
	_expect(ui.world.arms_escalation == 1 and ui.event_label.text.contains("fell to 1/6"), "manifest audit UI did not apply and explain de-escalation")

	ui.world.contract_history.append({"id": "reedwatch_water_relief_01", "status": "completed"})
	ui.world.settlement_resilience["reedwatch"] = 2
	ui.world.advance_day(8)
	ui._refresh_ui()
	_expect(ui.world.ending_id == "open_routes_relief" and ui.shop_status_label.text.contains("ENDING — Open Routes, Shared Wells"), "qualified crisis state did not expose the deterministic ending summary")
	_expect(ui.ending_panel.visible and ui.ending_label.text.contains("CAMPAIGN CONCLUSION") and ui.ending_label.text.contains("Open Routes, Shared Wells"), "completed relief should receive a dedicated campaign-conclusion card")
	ui._on_start_game_pressed()
	ui.world.adjust_reputation("wardens", 3)
	ui.world.advance_day(9)
	ui._refresh_ui()
	_expect(ui.world.ending_id == "ending_warden_reserve" and ui.shop_status_label.text.contains("ENDING — Order at the Cistern"), "regulated crisis state did not expose the second deterministic ending summary")
	ui._on_start_game_pressed()
	ui.world.adjust_reputation("caravans", 2)
	ui.world.advance_day(9)
	ui._refresh_ui()
	_expect(ui.world.ending_id == "ending_free_caravan_routes" and ui.shop_status_label.text.contains("ENDING — No Road Owns the Sky"), "open-road crisis state did not expose the third deterministic ending summary")
	ui._on_start_game_pressed()
	ui.world.money = 220
	ui.world.advance_day(9)
	ui._refresh_ui()
	_expect(ui.world.ending_id == "ending_ash_merchant" and ui.shop_status_label.text.contains("ENDING — The Best Margin"), "profit-first crisis state did not expose the fourth deterministic ending summary")
	_expect(ui.ending_panel.visible and ui.ending_label.text.contains("The Best Margin") and ui.ending_label.text.contains("continue trading"), "profit-first ending should update the dedicated conclusion card without blocking continued play")
	_expect(ui.campaign_outlook_label.text.contains("Conclusion recorded: The Best Margin"), "campaign outlook should collapse to the immutable reached conclusion")

	var state_before_text_scale := JSON.stringify(ui.world.serialize())
	ui.large_text_checkbox.button_pressed = true
	_expect(ui.theme.default_font_size == 20 and ui.diagnostics_label.get_theme_font_size("font_size") == 14, "large text should scale inherited and explicit font sizes")
	_expect(JSON.stringify(ui.world.serialize()) == state_before_text_scale, "large-text changes should not mutate campaign state")
	ui.reduce_motion_checkbox.button_pressed = true
	var saved_settings := ConfigFile.new()
	_expect(saved_settings.load(test_settings_path) == OK and bool(saved_settings.get_value("accessibility", "large_text", false)) and bool(saved_settings.get_value("accessibility", "reduce_motion", false)), "accessibility preferences should persist outside the campaign save")
	ui.large_text_enabled = false
	ui.reduce_motion_enabled = false
	ui._load_presentation_settings()
	_expect(ui.large_text_enabled and ui.reduce_motion_enabled, "saved accessibility preferences should load with safe defaults")
	ui._on_start_game_pressed()
	ui._on_guided_test_action()
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	_expect(not ui.map_panel.traveling and is_equal_approx(ui.map_panel.travel_progress, 1.0), "reduced motion should present the completed route immediately without changing its outcome")

	for test_path in [absolute_test_save_path, absolute_test_backup_path, absolute_test_temporary_path]:
		if FileAccess.file_exists(test_path):
			DirAccess.remove_absolute(test_path)
	if FileAccess.file_exists(test_settings_path):
		DirAccess.remove_absolute(absolute_test_settings_path)
	if FileAccess.file_exists(test_report_path):
		DirAccess.remove_absolute(absolute_test_report_path)
	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("Map UI smoke: PASS")
	else:
		for failure in failures:
			push_error(failure)
		printerr("Map UI smoke: FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _action_has_joypad_button(action: StringName, button_index: int) -> bool:
	for input_event in InputMap.action_get_events(action):
		if input_event is InputEventJoypadButton and input_event.button_index == button_index:
			return true
	return false

func _action_has_key(action: StringName, keycode: int) -> bool:
	for input_event in InputMap.action_get_events(action):
		if input_event is InputEventKey and (input_event.physical_keycode == keycode or input_event.keycode == keycode):
			return true
	return false

func _has_scroll_ancestor(control: Control) -> bool:
	var parent := control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			return true
		parent = parent.get_parent()
	return false
