extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_expect(_input_action_has_key("ui_cancel", KEY_ESCAPE) and not _input_action_has_key("ui_cancel", KEY_BACKSPACE), "the shipped Back binding should match the documented and restorable Escape default")
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame
	ui.settings_persistence_enabled = false
	ui.autosave_enabled = false
	ui._on_interface_sounds_toggled(false)
	ui.save_path = "user://market_of_ash_controller_test_%d.save" % OS.get_process_id()
	ui.save_status_text = "SAVE — No save written this session."
	ui._on_restore_default_bindings()
	ui._refresh_continue_availability()
	ui._show_main_menu()
	await process_frame

	_expect(ui.get_viewport().gui_get_focus_owner() == ui.start_game_button, "Main Menu should start controller navigation on New Game")
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.settings_button, "D-pad Down should reach Settings when Continue is unavailable")
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.credits_button, "D-pad Down should reach Credits")
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.settings_button, "D-pad Up should reverse through the player-facing menu")
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.start_game_button, "D-pad Up should reverse the Main Menu focus cycle")
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.intro_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.intro_next_button, "controller Accept should open the illustrated introduction and focus Next")
	await _press_joypad(JOY_BUTTON_A)
	await _press_joypad(JOY_BUTTON_A)
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.shop_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.shop_buy_button, "controller Accept should complete the introduction and focus the ordinary-trade Buy action")
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.shop_good_option, "D-pad Up should move from the primary trade action back to the cargo selector")
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.shop_quantity.get_line_edit(), "D-pad Down should move from cargo selection to quantity")
	var starting_quantity: float = ui.shop_quantity.value
	await _press_joypad(JOY_BUTTON_DPAD_RIGHT)
	_expect(ui.shop_quantity.value == starting_quantity + 1.0 and ui.get_viewport().gui_get_focus_owner() == ui.shop_quantity.get_line_edit(), "D-pad Right should increase Shop quantity without moving focus")
	await _press_joypad(JOY_BUTTON_DPAD_LEFT)
	_expect(ui.shop_quantity.value == starting_quantity and ui.get_viewport().gui_get_focus_owner() == ui.shop_quantity.get_line_edit(), "D-pad Left should decrease Shop quantity without moving focus")

	var reached_plan := false
	for _step in range(32):
		if ui.get_viewport().gui_get_focus_owner() == ui.plan_departure_button:
			reached_plan = true
			break
		await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(reached_plan, "D-pad Down should reach Plan departure without becoming trapped on a dynamic Shop action")
	var shop_state := JSON.stringify(ui.world.serialize())
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.game_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.route_comparison_buttons[0], "controller Accept should open Departure and focus the selected itinerary")
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.cargo_quantity.get_line_edit(), "D-pad Up should move from the selected itinerary to forecast quantity")
	var starting_forecast_quantity: float = ui.cargo_quantity.value
	await _press_joypad(JOY_BUTTON_DPAD_RIGHT)
	_expect(ui.cargo_quantity.value == starting_forecast_quantity + 1.0 and ui.get_viewport().gui_get_focus_owner() == ui.cargo_quantity.get_line_edit(), "D-pad Right should increase forecast quantity without moving focus")

	await _press_joypad(JOY_BUTTON_START)
	_expect(ui.pause_layer.visible and ui.get_tree().paused and ui.get_viewport().gui_get_focus_owner() == ui.pause_resume_button, "controller Menu should open Pause and focus Resume")
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.pause_save_button, "D-pad Down should traverse Pause actions")
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.pause_resume_button, "D-pad Up should reverse through Pause actions")
	await _press_joypad(JOY_BUTTON_B)
	_expect(not ui.pause_layer.visible and not ui.get_tree().paused and ui.get_viewport().gui_get_focus_owner() == ui.cargo_quantity.get_line_edit(), "controller Back should close Pause and restore Departure focus")
	await _press_joypad(JOY_BUTTON_B)
	_expect(ui.shop_layer.visible and not ui.game_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.shop_buy_button, "controller Back should return from uncommitted Departure to the visible Buy action")
	_expect(JSON.stringify(ui.world.serialize()) == shop_state, "controller-only reversible navigation should not mutate campaign state")

	await _press_joypad(JOY_BUTTON_START)
	_expect(ui.pause_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.pause_resume_button, "controller Menu should also pause from the Shop")
	await _press_joypad(JOY_BUTTON_A)
	_expect(not ui.pause_layer.visible and not ui.get_tree().paused and ui.get_viewport().gui_get_focus_owner() == ui.shop_buy_button, "controller Accept should activate Resume and restore Shop focus")

	ui.pending_tutorial_enabled = false
	ui._on_start_game_pressed()
	await process_frame
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	await _press_joypad(JOY_BUTTON_DPAD_UP)
	await _press_joypad(JOY_BUTTON_A)
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui._selected_id(ui.shop_good_option) == "medicine", "controller option navigation should select Medicine in the Shop")
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.shop_buy_button, "controller focus should reach Buy after cargo and quantity")
	await _press_joypad(JOY_BUTTON_A)
	_expect(int(ui.world.cargo.get("medicine", 0)) == 2 and ui.get_viewport().gui_get_focus_owner() == ui.plan_departure_button, "controller Accept should buy Medicine and follow the success handoff to Plan departure")
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.game_layer.visible and ui.get_viewport().gui_get_focus_owner() == ui.route_comparison_buttons[0], "controller Accept should reopen Departure on the selected itinerary")
	await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui._selected_id(ui.destination_option) == "brine_cross" and ui._selected_id(ui.route_option) == "toll_road", "controller option navigation should select Brine Cross and its legal Toll Road")
	var reached_commit := false
	for _step in range(12):
		if ui.get_viewport().gui_get_focus_owner() == ui.commit_departure_button:
			reached_commit = true
			break
		await _press_joypad(JOY_BUTTON_DPAD_DOWN)
	_expect(reached_commit, "controller focus should traverse route comparisons and reach Commit departure")
	if not reached_commit:
		ui.commit_departure_button.grab_focus()
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.world.pending_event.get("id", "") == "gatekeepers_chalk" and ui._current_ui_state_id() == "route_travel", "controller Commit should enter the road before revealing Gatekeeper's Chalk")
	ui.map_panel._process(2.0)
	_expect(ui.get_viewport().gui_get_focus_owner() == ui.continue_journey_button, "controller road arrival should focus Continue journey")
	await _press_joypad(JOY_BUTTON_A)
	_expect(not ui.event_choice_buttons.is_empty() and ui.get_viewport().gui_get_focus_owner() == ui.event_choice_buttons[0], "controller Continue should reveal Gatekeeper's Chalk and focus its first available response")
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.world.pending_event.is_empty() and ui.arrival_pending and ui.get_viewport().gui_get_focus_owner() == ui.enter_settlement_button, "controller Accept should resolve the route event and focus Enter settlement")
	await _press_joypad(JOY_BUTTON_A)
	_expect(ui.shop_layer.visible and ui.world.current_settlement == "brine_cross" and ui.get_viewport().gui_get_focus_owner() == ui.shop_good_option, "controller Accept should enter Brine Cross and restore Shop focus")

	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("Controller input smoke: PASS")
	else:
		for failure in failures:
			push_error(failure)
		printerr("Controller input smoke: FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _press_joypad(button_index: int) -> void:
	var pressed := InputEventJoypadButton.new()
	pressed.button_index = button_index
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventJoypadButton.new()
	released.button_index = button_index
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame

func _input_action_has_key(action_name: String, keycode: int) -> bool:
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey and int(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode) == keycode:
			return true
	return false

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
