extends SceneTree

const CAPTURE_SCREENS := [
	"main_menu",
	"settlement_shop",
	"pause",
	"departure_desk",
	"returned_shop",
	"main_menu_large_text",
	"settlement_shop_large_text",
	"pause_large_text",
	"departure_desk_large_text",
	"route_event",
	"route_event_large_text",
	"route_event_result",
	"destination_shop",
	"new_game_confirmation",
]

var output_directory := ""
var requested_size := Vector2i.ZERO
var captures: Array[Dictionary] = []

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

	ui._on_start_game_requested()
	await _capture(ui, "settlement_shop", "settlement-shop")
	ui._open_pause()
	await _capture(ui, "pause", "pause")
	ui._close_pause()
	ui._on_plan_departure_pressed()
	await _capture(ui, "departure_desk", "departure-desk")
	ui._on_return_to_shop_pressed()
	await _capture(ui, "returned_shop", "returned-shop")
	ui._on_plan_departure_pressed()

	ui.large_text_checkbox.set_pressed_no_signal(true)
	ui._on_large_text_toggled(true)
	await _capture(ui, "departure_desk_large_text", "departure-desk-large-text")
	ui._on_return_to_shop_pressed()
	await _capture(ui, "settlement_shop_large_text", "settlement-shop-large-text")
	ui._open_pause()
	await _capture(ui, "pause_large_text", "pause-large-text")
	ui._close_pause()
	ui._show_main_menu()
	await _capture(ui, "main_menu_large_text", "main-menu-large-text")

	ui.large_text_checkbox.set_pressed_no_signal(false)
	ui._on_large_text_toggled(false)
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

func _capture(ui: Control, screen: String, file_stem: String) -> void:
	await process_frame
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
	return {
		"map_hint": {"x": hint_rect.position.x, "y": hint_rect.position.y, "width": hint_rect.size.x, "height": hint_rect.size.y},
		"map_board": {"x": board_rect.position.x, "y": board_rect.position.y, "width": board_rect.size.x, "height": board_rect.size.y},
		"result": {"x": result_rect.position.x, "y": result_rect.position.y, "width": result_rect.size.x, "height": result_rect.size.y},
		"game_layer": _rect_data(game_rect),
		"focused": _rect_data(focused.get_global_rect()) if focused != null else {},
		"departure_scroll": _rect_data(departure_scroll.get_global_rect()) if departure_scroll != null else {},
	}

func _rect_data(rect: Rect2) -> Dictionary:
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}
