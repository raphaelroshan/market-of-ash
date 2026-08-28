extends Control

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

const PLAYTEST_SEED := 1107
const PLAYTEST_GOOD := "water"
const PLAYTEST_QUANTITY := 2
const PLAYTEST_DESTINATION := "reedwatch"
const PLAYTEST_ROUTE := "old_road"
const DEFAULT_SAVE_PATH := "user://market_of_ash_prototype.save"
const DEFAULT_SETTINGS_PATH := "user://market_of_ash_settings.cfg"
const DEFAULT_REPORT_PATH := "user://market_of_ash_playtest_report.json"
const WEB_REPORT_FILENAME := "market_of_ash_playtest_report.json"
const MAX_SAVE_BYTES := 5 * 1024 * 1024
const REMAPPABLE_ACTIONS := ["ui_accept", "ui_cancel", "ui_pause"]
const ACTION_LABELS := {"ui_accept": "Accept", "ui_cancel": "Back", "ui_pause": "Pause"}
const DEFAULT_KEY_BINDINGS := {"ui_accept": [KEY_ENTER, KEY_SPACE], "ui_cancel": [KEY_ESCAPE], "ui_pause": [KEY_P]}
const DEFAULT_CONTROLLER_BINDINGS := {"ui_accept": [JOY_BUTTON_A], "ui_cancel": [JOY_BUTTON_B], "ui_pause": [JOY_BUTTON_START]}
const RESERVED_REMAP_KEYS := [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
const RESERVED_CONTROLLER_BUTTONS := [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]
const CONTROLLER_BUTTON_LABELS := {
	JOY_BUTTON_A: "A / Cross",
	JOY_BUTTON_B: "B / Circle",
	JOY_BUTTON_X: "X / Square",
	JOY_BUTTON_Y: "Y / Triangle",
	JOY_BUTTON_BACK: "Back / Select",
	JOY_BUTTON_START: "Menu / Start",
	JOY_BUTTON_LEFT_SHOULDER: "Left bumper",
	JOY_BUTTON_RIGHT_SHOULDER: "Right bumper",
}

var world: AshWorldState
var game_layer: Control
var shop_layer: Control
var menu_layer: Control
var pause_layer: Control
var pause_resume_button: Button
var pause_summary_label: Label
var focus_before_pause: Control
var start_game_button: Button
var continue_game_button: Button
var quit_button: Button
var menu_save_status_label: Label
var controls_hint_label: Label
var binding_status_label: Label
var binding_buttons: Dictionary = {}
var restore_bindings_button: Button
var remapping_action: String = ""
var reset_confirmation_dialog: ConfirmationDialog
var new_game_confirmation_dialog: ConfirmationDialog
var reduce_motion_checkbox: CheckBox
var large_text_checkbox: CheckBox
var interface_sounds_checkbox: CheckBox
var shop_good_option: OptionButton
var shop_quantity: SpinBox
var shop_market_preview_label: Label
var shop_buy_button: Button
var shop_sell_button: Button
var shop_transaction_status_label: Label
var shop_status_label: Label
var shop_cargo_label: Label
var shop_save_button: Button
var shop_load_button: Button
var shop_reset_button: Button
var shop_report_button: Button
var opportunity_status_label: Label
var opportunity_list: VBoxContainer
var opportunity_buttons: Array[Button] = []
var contract_buttons: Array[Button] = []
var crew_buttons: Array[Button] = []
var active_contract_label: Label
var campaign_outlook_label: Label
var ending_panel: PanelContainer
var ending_label: Label
var plan_departure_button: Button
var departure_travel_actions: HBoxContainer
var return_to_shop_button: Button
var commit_departure_button: Button
var enter_settlement_button: Button
var departure_load_label: Label
var departure_contract_label: Label
var departure_status_label: Label
var event_card: PanelContainer
var event_title_label: Label
var event_setup_label: Label
var event_stakes_label: Label
var event_choice_list: VBoxContainer
var event_choice_buttons: Array[Button] = []
var event_choice_reason_labels: Array[Label] = []
var arrival_pending := false
var guided_test_button: Button
var playtest_banner: Label
var playtest_status_label: Label
var status_label: Label
var event_label: Label
var destination_option: OptionButton
var route_option: OptionButton
var cargo_good_option: OptionButton
var cargo_quantity: SpinBox
var market_preview_label: Label
var route_preview_label: Label
var log_label: Label
var diagnostics_label: Label
var save_status_label: Label
var departure_save_status_label: Label
var save_status_text := "SAVE — No save written this session."
var save_path := DEFAULT_SAVE_PATH
var autosave_enabled := true
var settings_path := DEFAULT_SETTINGS_PATH
var settings_persistence_enabled := true
var report_path := DEFAULT_REPORT_PATH
var reduce_motion_enabled := false
var large_text_enabled := false
var interface_sounds_enabled := true
var audio_player: AudioStreamPlayer
var audio_cues: Dictionary = {}
var run_started_msec := 0
var first_trade_elapsed_msec := -1
var last_input_device := "unknown"
var map_panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run_started_msec = Time.get_ticks_msec()
	world = AshWorldState.new(PLAYTEST_SEED)
	_load_presentation_settings()
	theme = Theme.new()
	theme.default_font_size = 20 if large_text_enabled else 16
	_build_audio_cues()
	game_layer = Control.new()
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_layer)
	_build_ui()
	_build_shop()
	_build_main_menu()
	_build_pause_menu()
	_refresh_continue_availability()
	if large_text_enabled:
		_apply_text_scale(self, 1.25)
	_show_main_menu()

func _build_main_menu() -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color("#17130f")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(center)
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(600, 640)
	center.add_child(card)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	scroll.add_child(content)

	var title := Label.new()
	title.text = "MARKET OF ASH"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color("#e6c58d"))
	content.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "A trade route is a promise you make to the road."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("#b5a18b"))
	content.add_child(subtitle)
	var preset := Label.new()
	preset.text = "QUICK PLAYTEST\nAshgate · Day 1 · 120 ashmarks · 12 provisions · empty cargo\nSuggested first move: buy 2 water, then compare the profitable but exposed Old Road to Reedwatch."
	preset.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preset.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preset.add_theme_color_override("font_color", Color("#f0d2a0"))
	content.add_child(preset)
	controls_hint_label = Label.new()
	controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint_label.add_theme_color_override("font_color", Color("#c7b49a"))
	content.add_child(controls_hint_label)
	reduce_motion_checkbox = CheckBox.new()
	reduce_motion_checkbox.text = "Reduce travel motion"
	reduce_motion_checkbox.tooltip_text = "Show the caravan at its destination immediately; route outcomes and timing are unchanged."
	reduce_motion_checkbox.button_pressed = reduce_motion_enabled
	reduce_motion_checkbox.toggled.connect(_on_reduce_motion_toggled)
	content.add_child(reduce_motion_checkbox)
	large_text_checkbox = CheckBox.new()
	large_text_checkbox.text = "Large text"
	large_text_checkbox.tooltip_text = "Increase interface text by 25%. Long shop and route panels remain scrollable."
	large_text_checkbox.button_pressed = large_text_enabled
	large_text_checkbox.toggled.connect(_on_large_text_toggled)
	content.add_child(large_text_checkbox)
	interface_sounds_checkbox = CheckBox.new()
	interface_sounds_checkbox.text = "Interface sounds"
	interface_sounds_checkbox.tooltip_text = "Play restrained confirmation, blocked-action, and travel cues. All essential feedback remains visible as text."
	interface_sounds_checkbox.button_pressed = interface_sounds_enabled
	interface_sounds_checkbox.toggled.connect(_on_interface_sounds_toggled)
	content.add_child(interface_sounds_checkbox)
	var bindings_title := Label.new()
	bindings_title.text = "INPUT BINDINGS"
	bindings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bindings_title.add_theme_color_override("font_color", Color("#e6c58d"))
	content.add_child(bindings_title)
	var binding_row := HBoxContainer.new()
	binding_row.alignment = BoxContainer.ALIGNMENT_CENTER
	binding_row.add_theme_constant_override("separation", 8)
	content.add_child(binding_row)
	for action_name in REMAPPABLE_ACTIONS:
		var binding_button := Button.new()
		binding_button.pressed.connect(_on_rebind_pressed.bind(action_name))
		binding_row.add_child(binding_button)
		binding_buttons[action_name] = binding_button
	restore_bindings_button = Button.new()
	restore_bindings_button.text = "Restore default inputs"
	restore_bindings_button.pressed.connect(_on_restore_default_bindings)
	content.add_child(restore_bindings_button)
	binding_status_label = Label.new()
	binding_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	binding_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_status_label.add_theme_font_size_override("font_size", 11)
	binding_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	content.add_child(binding_status_label)
	start_game_button = Button.new()
	start_game_button.text = "Start Game"
	start_game_button.custom_minimum_size = Vector2(0, 48)
	start_game_button.pressed.connect(_on_start_game_requested)
	content.add_child(start_game_button)
	continue_game_button = Button.new()
	continue_game_button.text = "Continue saved game"
	continue_game_button.custom_minimum_size = Vector2(0, 42)
	continue_game_button.disabled = not FileAccess.file_exists(save_path)
	continue_game_button.tooltip_text = "No saved campaign exists yet." if continue_game_button.disabled else "Validate and continue the saved campaign."
	continue_game_button.pressed.connect(_on_load_pressed)
	content.add_child(continue_game_button)
	menu_save_status_label = Label.new()
	menu_save_status_label.text = save_status_text
	menu_save_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_save_status_label.add_theme_font_size_override("font_size", 11)
	menu_save_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	content.add_child(menu_save_status_label)
	quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.tooltip_text = "Close the desktop build. Browser builds use the browser tab instead."
	quit_button.visible = not OS.has_feature("web")
	quit_button.pressed.connect(_on_quit_pressed)
	content.add_child(quit_button)
	content.move_child(start_game_button, 4)
	content.move_child(continue_game_button, 5)
	content.move_child(menu_save_status_label, 6)
	_refresh_binding_labels()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _build_pause_menu() -> void:
	pause_layer = Control.new()
	pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.visible = false
	add_child(pause_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.04, 0.03, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_layer.add_child(center)
	var card := PanelContainer.new()
	card.name = "PauseCard"
	card.custom_minimum_size = Vector2(480, 0)
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	card.add_child(content)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e6c58d"))
	content.add_child(title)
	pause_summary_label = Label.new()
	pause_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pause_summary_label.add_theme_color_override("font_color", Color("#d9c6a2"))
	content.add_child(pause_summary_label)
	pause_resume_button = Button.new()
	pause_resume_button.text = "Resume"
	pause_resume_button.custom_minimum_size = Vector2(0, 46)
	pause_resume_button.pressed.connect(_close_pause)
	content.add_child(pause_resume_button)
	var save_button := Button.new()
	save_button.text = "Save campaign"
	save_button.pressed.connect(_on_save_pressed)
	content.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Load saved campaign"
	load_button.pressed.connect(_on_pause_load_pressed)
	content.add_child(load_button)
	var report_button := Button.new()
	report_button.text = "Export playtest report"
	report_button.tooltip_text = "Download or write build, seed, campaign summary, command history, and game log without personal data."
	report_button.pressed.connect(_on_export_report_pressed)
	content.add_child(report_button)
	var menu_button := Button.new()
	menu_button.text = "Return to main menu"
	menu_button.pressed.connect(_on_pause_main_menu_pressed)
	content.add_child(menu_button)

func _show_main_menu() -> void:
	get_tree().paused = false
	if pause_layer:
		pause_layer.visible = false
	game_layer.visible = false
	shop_layer.visible = false
	menu_layer.visible = true
	if start_game_button:
		start_game_button.grab_focus()
	_publish_web_ui_state()

func _refresh_continue_availability() -> void:
	if continue_game_button == null:
		return
	var backup_path := save_path + ".bak"
	var preview := _load_candidate(save_path)
	var backup_preview := false
	if not bool(preview.get("ok", false)) and FileAccess.file_exists(backup_path):
		preview = _load_candidate(backup_path)
		backup_preview = bool(preview.get("ok", false))
	continue_game_button.disabled = not bool(preview.get("ok", false))
	if continue_game_button.disabled:
		if start_game_button:
			var existing_files := FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)
			start_game_button.text = "Start new game" if existing_files else "Start Game"
			start_game_button.tooltip_text = "Requires confirmation because campaign save files already exist." if existing_files else "Begin the deterministic Ashgate day-one campaign."
		continue_game_button.tooltip_text = "No valid saved campaign is available."
		if FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path):
			save_status_text = "SAVE — Existing files could not be validated. Start Game remains safe."
		if menu_save_status_label:
			menu_save_status_label.text = save_status_text
		_link_main_menu_focus_cycle()
		return
	var saved_world: AshWorldState = preview.world
	var source_text := "backup" if backup_preview else "primary"
	if start_game_button:
		start_game_button.text = "Start new game"
		start_game_button.tooltip_text = "Requires confirmation because a validated saved campaign is available."
	save_status_text = "CONTINUE — Day %d · %s · %d ashmarks · hold %d/%d · %s save" % [saved_world.day, String(saved_world.settlement(saved_world.current_settlement).get("name", saved_world.current_settlement)), saved_world.money, int(saved_world.cargo.get("weight", 0)), saved_world.cargo_capacity, source_text]
	continue_game_button.tooltip_text = "Validate and continue this saved campaign."
	if menu_save_status_label:
		menu_save_status_label.text = save_status_text
	_link_main_menu_focus_cycle()

func _show_shop() -> void:
	menu_layer.visible = false
	game_layer.visible = false
	shop_layer.visible = true
	arrival_pending = false
	if enter_settlement_button:
		enter_settlement_button.visible = false
	if commit_departure_button:
		commit_departure_button.disabled = false
	if return_to_shop_button:
		return_to_shop_button.disabled = false
	_refresh_ui()
	_grab_focus_if_available(shop_good_option)

func _show_departure() -> void:
	shop_layer.visible = false
	game_layer.visible = true
	var journey_locked := not world.pending_event.is_empty() or arrival_pending
	commit_departure_button.disabled = journey_locked
	return_to_shop_button.disabled = journey_locked
	enter_settlement_button.visible = arrival_pending
	_refresh_ui()
	if not world.pending_event.is_empty():
		_grab_first_enabled(event_choice_buttons)
	elif arrival_pending:
		_grab_focus_if_available(enter_settlement_button)
	else:
		_grab_focus_if_available(destination_option)

func _grab_focus_if_available(control: Variant) -> bool:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree() or control.focus_mode == Control.FOCUS_NONE:
		return false
	if control is BaseButton and control.disabled:
		return false
	control.grab_focus()
	return true

func _grab_first_enabled(controls: Array[Button]) -> bool:
	for control in controls:
		if _grab_focus_if_available(control):
			return true
	return false

func _on_large_text_toggled(enabled: bool) -> void:
	large_text_enabled = enabled
	theme.default_font_size = 20 if enabled else 16
	_apply_text_scale(self, 1.25 if enabled else 1.0)
	if map_panel:
		map_panel.text_scale = 1.25 if enabled else 1.0
		map_panel.queue_redraw()
	_save_presentation_settings()
	_publish_web_ui_state()
	if not get_tree().process_frame.is_connected(_ensure_focused_control_visible):
		get_tree().process_frame.connect(_ensure_focused_control_visible, CONNECT_ONE_SHOT)

func _ensure_focused_control_visible() -> void:
	var focused := get_viewport().gui_get_focus_owner()
	if focused == null:
		return
	var ancestor := focused.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(focused)
		ancestor = ancestor.get_parent()

func _on_reduce_motion_toggled(enabled: bool) -> void:
	reduce_motion_enabled = enabled
	if map_panel:
		map_panel.reduce_motion = enabled
	_save_presentation_settings()

func _on_interface_sounds_toggled(enabled: bool) -> void:
	interface_sounds_enabled = enabled
	if not enabled and audio_player:
		audio_player.stop()
	_save_presentation_settings()

func _build_audio_cues() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.volume_db = -14.0
	add_child(audio_player)
	audio_cues = {
		"success": _tone_stream(660.0, 0.08),
		"blocked": _tone_stream(220.0, 0.11),
		"travel": _tone_stream(360.0, 0.14),
	}

func _tone_stream(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(round(duration * sample_rate))
	var samples := PackedByteArray()
	samples.resize(sample_count * 2)
	for index in range(sample_count):
		var progress := float(index) / float(maxi(1, sample_count - 1))
		var envelope := sin(PI * progress)
		var sample := int(round(sin(TAU * frequency * float(index) / float(sample_rate)) * envelope * 32767.0 * 0.12))
		samples.encode_s16(index * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = samples
	return stream

func _play_ui_cue(cue_id: String) -> void:
	if not interface_sounds_enabled or audio_player == null or not audio_cues.has(cue_id):
		return
	audio_player.stream = audio_cues[cue_id]
	audio_player.play()

func _on_rebind_pressed(action_name: String) -> void:
	remapping_action = action_name
	binding_status_label.text = "Press one unmodified key or controller button for %s. Escape cancels." % String(ACTION_LABELS.get(action_name, action_name))
	_refresh_binding_labels()

func _on_restore_default_bindings() -> void:
	for action_name in REMAPPABLE_ACTIONS:
		_replace_keyboard_bindings(action_name, DEFAULT_KEY_BINDINGS[action_name])
		_replace_controller_bindings(action_name, DEFAULT_CONTROLLER_BINDINGS[action_name])
	remapping_action = ""
	if binding_status_label:
		binding_status_label.text = "Default keyboard and controller bindings restored."
	_refresh_binding_labels()
	_save_presentation_settings()

func _capture_controller_binding(event: InputEventJoypadButton) -> void:
	var pressed_button := int(event.button_index)
	if RESERVED_CONTROLLER_BUTTONS.has(pressed_button):
		binding_status_label.text = "D-pad directions are reserved for focus navigation. Press another controller button, or Escape to cancel."
		return
	for action_name in REMAPPABLE_ACTIONS:
		if action_name == remapping_action:
			continue
		if _controller_binding_codes(action_name).has(pressed_button):
			binding_status_label.text = "%s is already assigned to %s. Choose a different controller button." % [_controller_button_text(pressed_button), String(ACTION_LABELS.get(action_name, action_name))]
			return
	_replace_controller_bindings(remapping_action, [pressed_button])
	var updated_action := remapping_action
	remapping_action = ""
	binding_status_label.text = "%s now uses controller %s. Keyboard bindings are unchanged." % [String(ACTION_LABELS.get(updated_action, updated_action)), _controller_binding_text(updated_action)]
	_refresh_binding_labels()
	_save_presentation_settings()

func _capture_keyboard_binding(event: InputEventKey) -> void:
	var pressed_keycode: int = int(event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode)
	if pressed_keycode == KEY_ESCAPE:
		remapping_action = ""
		binding_status_label.text = "Key change cancelled."
		_refresh_binding_labels()
		return
	if pressed_keycode == KEY_NONE or RESERVED_REMAP_KEYS.has(pressed_keycode) or event.alt_pressed or event.ctrl_pressed or event.meta_pressed or event.shift_pressed:
		binding_status_label.text = "That shortcut is reserved. Press one unmodified key, or Escape to cancel."
		return
	for action_name in REMAPPABLE_ACTIONS:
		if action_name == remapping_action:
			continue
		if _keyboard_binding_codes(action_name).has(pressed_keycode):
			binding_status_label.text = "%s is already assigned to %s. Choose a different key." % [OS.get_keycode_string(pressed_keycode), String(ACTION_LABELS.get(action_name, action_name))]
			return
	_replace_keyboard_bindings(remapping_action, [pressed_keycode])
	var updated_action := remapping_action
	remapping_action = ""
	binding_status_label.text = "%s now uses %s. Controller bindings are unchanged." % [String(ACTION_LABELS.get(updated_action, updated_action)), _keyboard_binding_text(updated_action)]
	_refresh_binding_labels()
	_save_presentation_settings()

func _replace_keyboard_bindings(action_name: String, keycodes: Array) -> void:
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey:
			InputMap.action_erase_event(action_name, input_event)
	for keycode_value in keycodes:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = int(keycode_value)
		InputMap.action_add_event(action_name, key_event)

func _keyboard_binding_codes(action_name: String) -> Array:
	var keycodes: Array = []
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventKey:
			var keycode: int = int(input_event.physical_keycode if input_event.physical_keycode != KEY_NONE else input_event.keycode)
			if keycode != KEY_NONE and not keycodes.has(keycode):
				keycodes.append(keycode)
	return keycodes

func _replace_controller_bindings(action_name: String, button_indices: Array) -> void:
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventJoypadButton:
			InputMap.action_erase_event(action_name, input_event)
	for button_index_value in button_indices:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = int(button_index_value)
		InputMap.action_add_event(action_name, button_event)

func _controller_binding_codes(action_name: String) -> Array:
	var button_indices: Array = []
	for input_event in InputMap.action_get_events(action_name):
		if input_event is InputEventJoypadButton and not button_indices.has(input_event.button_index):
			button_indices.append(input_event.button_index)
	return button_indices

func _keyboard_binding_text(action_name: String) -> String:
	var labels: Array[String] = []
	for keycode in _keyboard_binding_codes(action_name):
		labels.append(OS.get_keycode_string(int(keycode)))
	return " / ".join(labels) if not labels.is_empty() else "Unbound"

func _controller_button_text(button_index: int) -> String:
	return String(CONTROLLER_BUTTON_LABELS.get(button_index, "Button %d" % button_index))

func _controller_binding_text(action_name: String) -> String:
	var labels: Array[String] = []
	for button_index in _controller_binding_codes(action_name):
		labels.append(_controller_button_text(int(button_index)))
	return " / ".join(labels) if not labels.is_empty() else "Unbound"

func _refresh_binding_labels() -> void:
	for action_name in REMAPPABLE_ACTIONS:
		var button: Button = binding_buttons.get(action_name)
		if button:
			button.text = "Press a key or controller button…" if remapping_action == action_name else "%s: %s · Pad %s" % [String(ACTION_LABELS.get(action_name, action_name)), _keyboard_binding_text(action_name), _controller_binding_text(action_name)]
	if controls_hint_label:
		controls_hint_label.text = "Controls: arrows/Tab or controller D-pad/stick move focus. Accept: %s / %s. Back: %s / %s. Pause: %s / %s." % [_keyboard_binding_text("ui_accept"), _controller_binding_text("ui_accept"), _keyboard_binding_text("ui_cancel"), _controller_binding_text("ui_cancel"), _keyboard_binding_text("ui_pause"), _controller_binding_text("ui_pause")]

func _load_presentation_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	large_text_enabled = bool(config.get_value("accessibility", "large_text", false))
	reduce_motion_enabled = bool(config.get_value("accessibility", "reduce_motion", false))
	interface_sounds_enabled = bool(config.get_value("audio", "interface_sounds", true))
	var requested_bindings: Dictionary = {}
	var requested_controller_bindings: Dictionary = {}
	var claimed_keys: Array = []
	var claimed_controller_buttons: Array = []
	var bindings_valid := true
	for action_name in REMAPPABLE_ACTIONS:
		var saved_codes: Variant = config.get_value("input", action_name, DEFAULT_KEY_BINDINGS[action_name])
		if typeof(saved_codes) != TYPE_ARRAY or saved_codes.is_empty():
			bindings_valid = false
			break
		var validated_codes: Array = []
		for code_value in saved_codes:
			if (typeof(code_value) != TYPE_INT and typeof(code_value) != TYPE_FLOAT) or int(code_value) == KEY_NONE or RESERVED_REMAP_KEYS.has(int(code_value)) or claimed_keys.has(int(code_value)):
				bindings_valid = false
				break
			validated_codes.append(int(code_value))
			claimed_keys.append(int(code_value))
		if not bindings_valid:
			break
		requested_bindings[action_name] = validated_codes
		var saved_buttons: Variant = config.get_value("input", "%s_joypad" % action_name, DEFAULT_CONTROLLER_BINDINGS[action_name])
		if typeof(saved_buttons) != TYPE_ARRAY or saved_buttons.is_empty():
			bindings_valid = false
			break
		var validated_buttons: Array = []
		for button_value in saved_buttons:
			if (typeof(button_value) != TYPE_INT and typeof(button_value) != TYPE_FLOAT) or int(button_value) < 0 or int(button_value) >= JOY_BUTTON_MAX or RESERVED_CONTROLLER_BUTTONS.has(int(button_value)) or claimed_controller_buttons.has(int(button_value)):
				bindings_valid = false
				break
			validated_buttons.append(int(button_value))
			claimed_controller_buttons.append(int(button_value))
		if not bindings_valid:
			break
		requested_controller_bindings[action_name] = validated_buttons
	for action_name in REMAPPABLE_ACTIONS:
		var keycodes: Array = requested_bindings.get(action_name, DEFAULT_KEY_BINDINGS[action_name]) if bindings_valid else DEFAULT_KEY_BINDINGS[action_name]
		var controller_buttons: Array = requested_controller_bindings.get(action_name, DEFAULT_CONTROLLER_BINDINGS[action_name]) if bindings_valid else DEFAULT_CONTROLLER_BINDINGS[action_name]
		_replace_keyboard_bindings(action_name, keycodes)
		_replace_controller_bindings(action_name, controller_buttons)
	if not bindings_valid:
		_save_presentation_settings()

func _save_presentation_settings() -> void:
	if not settings_persistence_enabled:
		return
	var config := ConfigFile.new()
	config.set_value("accessibility", "large_text", large_text_enabled)
	config.set_value("accessibility", "reduce_motion", reduce_motion_enabled)
	config.set_value("audio", "interface_sounds", interface_sounds_enabled)
	for action_name in REMAPPABLE_ACTIONS:
		config.set_value("input", action_name, _keyboard_binding_codes(action_name))
		config.set_value("input", "%s_joypad" % action_name, _controller_binding_codes(action_name))
	config.save(settings_path)

func _apply_text_scale(node: Node, scale: float) -> void:
	if node is Control and node.has_theme_font_size_override("font_size"):
		if not node.has_meta("base_font_size"):
			node.set_meta("base_font_size", node.get_theme_font_size("font_size"))
		node.add_theme_font_size_override("font_size", int(round(float(node.get_meta("base_font_size")) * scale)))
	for child in node.get_children():
		_apply_text_scale(child, scale)

func _build_shop() -> void:
	shop_layer = Control.new()
	shop_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shop_layer)
	var background := ColorRect.new()
	background.color = Color("#17130f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_layer.add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 36)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 36)
	shop_layer.add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 28)
	margin.add_child(columns)

	var market_card := PanelContainer.new()
	market_card.custom_minimum_size = Vector2(690, 0)
	columns.add_child(market_card)
	var market_shell := VBoxContainer.new()
	market_shell.add_theme_constant_override("separation", 10)
	market_card.add_child(market_shell)
	var market_scroll := ScrollContainer.new()
	market_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	market_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_shell.add_child(market_scroll)
	var market := VBoxContainer.new()
	market.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market.add_theme_constant_override("separation", 14)
	market_scroll.add_child(market)
	var title := Label.new()
	title.text = "SETTLEMENT SHOP"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e6c58d"))
	market.add_child(title)
	shop_status_label = Label.new()
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_status_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	market.add_child(shop_status_label)
	shop_cargo_label = Label.new()
	shop_cargo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_cargo_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	market.add_child(shop_cargo_label)
	var ledger_label := Label.new()
	ledger_label.text = "MARKET LEDGER — Select a good to see its local price, reason, and regional comparison."
	ledger_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ledger_label.add_theme_color_override("font_color", Color("#b5a18b"))
	market.add_child(ledger_label)
	shop_good_option = OptionButton.new()
	for good_id in MarketContent.good_ids():
		shop_good_option.add_item(good_id.capitalize())
		shop_good_option.set_item_metadata(shop_good_option.item_count - 1, good_id)
	market.add_child(_labeled_control("Cargo", shop_good_option))
	shop_quantity = SpinBox.new()
	shop_quantity.min_value = 1
	shop_quantity.max_value = 12
	shop_quantity.value = PLAYTEST_QUANTITY
	market.add_child(_labeled_control("Quantity", shop_quantity))
	shop_market_preview_label = _forecast_label()
	shop_market_preview_label.custom_minimum_size = Vector2(620, 152)
	market.add_child(shop_market_preview_label)
	var purchase_row := HBoxContainer.new()
	purchase_row.add_theme_constant_override("separation", 12)
	market_shell.add_child(purchase_row)
	shop_buy_button = Button.new()
	shop_buy_button.name = "BuyCargoButton"
	shop_buy_button.text = "Buy cargo"
	shop_buy_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_buy_button.custom_minimum_size = Vector2(0, 56)
	shop_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_buy_button.tooltip_text = "Buy the selected cargo from this settlement."
	shop_buy_button.pressed.connect(_on_buy_pressed)
	purchase_row.add_child(shop_buy_button)
	shop_sell_button = Button.new()
	shop_sell_button.name = "SellCargoButton"
	shop_sell_button.text = "Sell selected cargo"
	shop_sell_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_sell_button.custom_minimum_size = Vector2(0, 56)
	shop_sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_sell_button.tooltip_text = "Sell the selected cargo held by the caravan."
	shop_sell_button.pressed.connect(_on_sell_pressed)
	purchase_row.add_child(shop_sell_button)
	shop_transaction_status_label = Label.new()
	shop_transaction_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_transaction_status_label.add_theme_font_size_override("font_size", 12)
	shop_transaction_status_label.add_theme_color_override("font_color", Color("#c7b49a"))
	market_shell.add_child(shop_transaction_status_label)
	guided_test_button = Button.new()
	guided_test_button.text = "Optional: Buy 2 water"
	guided_test_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guided_test_button.custom_minimum_size = Vector2(0, 48)
	guided_test_button.tooltip_text = "Runs the normal buy command for the first-run learning example."
	guided_test_button.pressed.connect(_on_guided_test_action)
	market_shell.add_child(guided_test_button)
	shop_good_option.item_selected.connect(_on_shop_plan_changed)
	shop_quantity.value_changed.connect(_on_shop_quantity_changed)

	var action_card := PanelContainer.new()
	action_card.name = "ShopActionCard"
	action_card.custom_minimum_size = Vector2(360, 0)
	columns.add_child(action_card)
	var action_shell := VBoxContainer.new()
	action_shell.add_theme_constant_override("separation", 10)
	action_card.add_child(action_shell)
	var action_scroll := ScrollContainer.new()
	action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_shell.add_child(action_scroll)
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 14)
	action_scroll.add_child(actions)
	var caravan_title := Label.new()
	caravan_title.text = "CARAVAN"
	caravan_title.add_theme_font_size_override("font_size", 20)
	caravan_title.add_theme_color_override("font_color", Color("#e6c58d"))
	actions.add_child(caravan_title)
	campaign_outlook_label = Label.new()
	campaign_outlook_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_outlook_label.add_theme_font_size_override("font_size", 12)
	campaign_outlook_label.add_theme_color_override("font_color", Color("#d9c6a2"))
	actions.add_child(campaign_outlook_label)
	ending_panel = PanelContainer.new()
	ending_panel.visible = false
	actions.add_child(ending_panel)
	ending_label = Label.new()
	ending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_label.add_theme_font_size_override("font_size", 16)
	ending_label.add_theme_color_override("font_color", Color("#e6c58d"))
	ending_panel.add_child(ending_label)
	var opportunity_title := Label.new()
	opportunity_title.text = "LOCAL OPPORTUNITIES"
	opportunity_title.add_theme_font_size_override("font_size", 18)
	opportunity_title.add_theme_color_override("font_color", Color("#e6c58d"))
	actions.add_child(opportunity_title)
	opportunity_status_label = Label.new()
	opportunity_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	opportunity_status_label.add_theme_color_override("font_color", Color("#c7b49a"))
	actions.add_child(opportunity_status_label)
	active_contract_label = Label.new()
	active_contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_contract_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	actions.add_child(active_contract_label)
	opportunity_list = VBoxContainer.new()
	opportunity_list.add_theme_constant_override("separation", 8)
	actions.add_child(opportunity_list)
	var next_step := Label.new()
	next_step.text = "When the load makes sense, take it to the Departure Desk. Planning a trip does not spend resources."
	next_step.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_step.add_theme_color_override("font_color", Color("#c7b49a"))
	action_shell.add_child(next_step)
	plan_departure_button = Button.new()
	plan_departure_button.text = "Plan departure"
	plan_departure_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plan_departure_button.custom_minimum_size = Vector2(0, 56)
	plan_departure_button.tooltip_text = "Open the regional map, choose a legal corridor, and inspect the full route forecast."
	plan_departure_button.pressed.connect(_on_plan_departure_pressed)
	action_shell.add_child(plan_departure_button)
	shop_save_button = Button.new()
	shop_save_button.text = "Save prototype state"
	shop_save_button.pressed.connect(_on_save_pressed)
	actions.add_child(shop_save_button)
	shop_load_button = Button.new()
	shop_load_button.text = "Load saved state"
	shop_load_button.tooltip_text = "Validate and load the saved campaign. A malformed or newer save leaves the current run unchanged."
	shop_load_button.pressed.connect(_on_load_pressed)
	actions.add_child(shop_load_button)
	save_status_label = Label.new()
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.add_theme_font_size_override("font_size", 11)
	save_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	actions.add_child(save_status_label)
	shop_reset_button = Button.new()
	shop_reset_button.text = "Reset run"
	shop_reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(shop_reset_button)
	shop_report_button = Button.new()
	shop_report_button.text = "Export playtest report"
	shop_report_button.tooltip_text = "Download or write build, seed, campaign summary, command history, and game log without personal data."
	shop_report_button.pressed.connect(_on_export_report_pressed)
	actions.add_child(shop_report_button)
	diagnostics_label = Label.new()
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics_label.add_theme_font_size_override("font_size", 11)
	diagnostics_label.add_theme_color_override("font_color", Color("#8f8374"))
	actions.add_child(diagnostics_label)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#17130f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(background)

	map_panel = MapPanel.new()
	map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	map_panel.world = world
	map_panel.text_scale = 1.25 if large_text_enabled else 1.0
	map_panel.settlement_selected.connect(_on_map_settlement_selected)
	game_layer.add_child(map_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	game_layer.add_child(margin)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	margin.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(700, 0)
	left.add_theme_constant_override("separation", 12)
	columns.add_child(left)

	var title := Label.new()
	title.text = "MARKET OF ASH"
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#e6c58d"))
	left.add_child(title)

	playtest_banner = Label.new()
	playtest_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	playtest_banner.add_theme_font_size_override("font_size", 12)
	playtest_banner.add_theme_color_override("font_color", Color("#f0d2a0"))
	left.add_child(playtest_banner)
	playtest_status_label = Label.new()
	playtest_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	playtest_status_label.add_theme_color_override("font_color", Color("#e6c58d"))
	left.add_child(playtest_status_label)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	left.add_child(status_label)

	var map_hint := Label.new()
	map_hint.name = "MapHint"
	map_hint.text = "Choose a settlement. HERE = current location; RES = resilience."
	map_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_hint.add_theme_color_override("font_color", Color("#c7b49a"))
	left.add_child(map_hint)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 198)
	left.add_child(spacer)

	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size = Vector2(660, 76)
	event_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	left.add_child(event_label)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_color_override("font_color", Color("#aa9a87"))
	left.add_child(log_label)

	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	columns.add_child(right)
	var controls_shell := VBoxContainer.new()
	controls_shell.add_theme_constant_override("separation", 10)
	right.add_child(controls_shell)
	var controls_scroll := ScrollContainer.new()
	controls_scroll.name = "DepartureControlsScroll"
	controls_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	controls_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	controls_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls_shell.add_child(controls_scroll)
	var controls := VBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_theme_constant_override("separation", 10)
	controls_scroll.add_child(controls)

	var control_title := Label.new()
	control_title.text = "DEPARTURE DESK"
	control_title.add_theme_font_size_override("font_size", 20)
	control_title.add_theme_color_override("font_color", Color("#e6c58d"))
	controls.add_child(control_title)

	destination_option = OptionButton.new()
	_populate_destination_options()
	controls.add_child(_labeled_control("Destination", destination_option))

	route_option = OptionButton.new()
	_populate_route_options()
	controls.add_child(_labeled_control("Route", route_option))

	cargo_good_option = OptionButton.new()
	for good in MarketContent.good_ids():
		cargo_good_option.add_item(good.capitalize())
		cargo_good_option.set_item_metadata(cargo_good_option.item_count - 1, good)
	controls.add_child(_labeled_control("Forecast cargo", cargo_good_option))

	cargo_quantity = SpinBox.new()
	cargo_quantity.min_value = 1
	cargo_quantity.max_value = 12
	cargo_quantity.value = PLAYTEST_QUANTITY
	controls.add_child(_labeled_control("Forecast quantity", cargo_quantity))

	departure_load_label = Label.new()
	departure_load_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_load_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	controls.add_child(departure_load_label)
	departure_contract_label = Label.new()
	departure_contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_contract_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	controls.add_child(departure_contract_label)

	market_preview_label = _forecast_label()
	market_preview_label.visible = false
	controls.add_child(market_preview_label)
	route_preview_label = _forecast_label()
	controls.add_child(route_preview_label)

	event_card = PanelContainer.new()
	event_card.visible = false
	controls.add_child(event_card)
	var event_content := VBoxContainer.new()
	event_content.add_theme_constant_override("separation", 6)
	event_card.add_child(event_content)
	event_title_label = Label.new()
	event_title_label.add_theme_font_size_override("font_size", 18)
	event_title_label.add_theme_color_override("font_color", Color("#e6c58d"))
	event_content.add_child(event_title_label)
	event_setup_label = Label.new()
	event_setup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_setup_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	event_content.add_child(event_setup_label)
	event_stakes_label = Label.new()
	event_stakes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_stakes_label.add_theme_color_override("font_color", Color("#c7b49a"))
	event_content.add_child(event_stakes_label)
	event_choice_list = VBoxContainer.new()
	event_choice_list.add_theme_constant_override("separation", 6)
	event_content.add_child(event_choice_list)

	destination_option.item_selected.connect(_on_destination_changed)
	route_option.item_selected.connect(_on_forecast_input_changed)
	cargo_good_option.item_selected.connect(_on_forecast_input_changed)
	cargo_quantity.value_changed.connect(_on_forecast_value_changed)

	return_to_shop_button = Button.new()
	return_to_shop_button.text = "Return to shop"
	return_to_shop_button.custom_minimum_size = Vector2(0, 44)
	return_to_shop_button.tooltip_text = "Go back to the settlement market without spending resources."
	return_to_shop_button.pressed.connect(_on_return_to_shop_pressed)
	departure_travel_actions = HBoxContainer.new()
	departure_travel_actions.add_theme_constant_override("separation", 10)
	controls_shell.add_child(departure_travel_actions)
	return_to_shop_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	departure_travel_actions.add_child(return_to_shop_button)

	commit_departure_button = Button.new()
	commit_departure_button.text = "Commit departure"
	commit_departure_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	commit_departure_button.custom_minimum_size = Vector2(0, 56)
	commit_departure_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	commit_departure_button.tooltip_text = "Pay the displayed route cost, consume provisions, and resolve this route's risk."
	commit_departure_button.pressed.connect(_on_depart_pressed)
	departure_travel_actions.add_child(commit_departure_button)

	arrival_pending = false
	enter_settlement_button = Button.new()
	enter_settlement_button.text = "Enter settlement"
	enter_settlement_button.custom_minimum_size = Vector2(0, 48)
	enter_settlement_button.tooltip_text = "Return to the central shop after reviewing the route outcome."
	enter_settlement_button.pressed.connect(_on_enter_settlement_pressed)
	enter_settlement_button.visible = false
	controls_shell.add_child(enter_settlement_button)

	departure_status_label = Label.new()
	departure_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_status_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	controls.add_child(departure_status_label)

	var save_button := Button.new()
	save_button.text = "Save prototype state"
	save_button.pressed.connect(_on_save_pressed)
	controls.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Load saved state"
	load_button.tooltip_text = "Validate and load the saved campaign. A malformed or newer save leaves the current run unchanged."
	load_button.pressed.connect(_on_load_pressed)
	controls.add_child(load_button)
	_link_focus_cycle([
		destination_option,
		route_option,
		cargo_good_option,
		cargo_quantity.get_line_edit(),
		commit_departure_button,
		return_to_shop_button,
		save_button,
		load_button,
	])
	departure_save_status_label = Label.new()
	departure_save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_save_status_label.add_theme_font_size_override("font_size", 11)
	departure_save_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	controls.add_child(departure_save_status_label)

func _forecast_label() -> Label:
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(332, 120)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("#d9c6a2"))
	return label

func _labeled_control(label_text: String, control: Control) -> VBoxContainer:
	var group := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color("#b5a18b"))
	group.add_child(label)
	group.add_child(control)
	return group

func _wrapped_action_button(minimum_height: float = 42.0) -> Button:
	var button := Button.new()
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.custom_minimum_size = Vector2(0, minimum_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return button

func _link_main_menu_focus_cycle() -> void:
	if start_game_button == null or continue_game_button == null:
		return
	var controls: Array = [start_game_button]
	if not continue_game_button.disabled:
		controls.append(continue_game_button)
	controls.append(reduce_motion_checkbox)
	controls.append(large_text_checkbox)
	controls.append(interface_sounds_checkbox)
	for action_name in REMAPPABLE_ACTIONS:
		controls.append(binding_buttons[action_name])
	controls.append(restore_bindings_button)
	if quit_button.visible:
		controls.append(quit_button)
	_link_focus_cycle(controls)

func _link_shop_focus_cycle() -> void:
	if shop_good_option == null or plan_departure_button == null:
		return
	var controls: Array = [shop_good_option, shop_quantity.get_line_edit()]
	for control in [shop_buy_button, shop_sell_button, guided_test_button]:
		if control.visible and not control.disabled:
			controls.append(control)
	for group in [contract_buttons, opportunity_buttons, crew_buttons]:
		for control in group:
			if control.visible and not control.disabled:
				controls.append(control)
	for control in [shop_save_button, shop_load_button, shop_reset_button, shop_report_button, plan_departure_button]:
		controls.append(control)
	_link_focus_cycle(controls)

func _link_focus_cycle(controls: Array) -> void:
	for index in range(controls.size()):
		var control: Control = controls[index]
		var next_control: Control = controls[(index + 1) % controls.size()]
		var previous_control: Control = controls[(index - 1 + controls.size()) % controls.size()]
		control.focus_next = control.get_path_to(next_control)
		control.focus_previous = control.get_path_to(previous_control)

func _populate_destination_options() -> void:
	if destination_option == null:
		return
	var previous_destination := _selected_id(destination_option)
	destination_option.clear()
	for settlement_id in MarketContent.destinations_from(world.current_settlement):
		var settlement := world.settlement(settlement_id)
		destination_option.add_item(String(settlement.get("name", settlement_id)))
		destination_option.set_item_metadata(destination_option.item_count - 1, settlement_id)
		if settlement_id == previous_destination:
			destination_option.select(destination_option.item_count - 1)
	if destination_option.selected < 0 and destination_option.item_count > 0:
		destination_option.select(0)

func _populate_route_options() -> void:
	if route_option == null:
		return
	var previous_route := _selected_id(route_option)
	var destination_id := _selected_id(destination_option)
	route_option.clear()
	for route_id in MarketContent.routes_from(world.current_settlement):
		if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
			continue
		var route := world.route(route_id)
		route_option.add_item(String(route.get("name", route_id)))
		route_option.set_item_metadata(route_option.item_count - 1, route_id)
		if route_id == previous_route:
			route_option.select(route_option.item_count - 1)
	if route_option.selected < 0 and route_option.item_count > 0:
		route_option.select(0)

func _selected_id(option: OptionButton) -> String:
	if option.selected < 0:
		return ""
	return String(option.get_item_metadata(option.selected))

func _on_start_game_pressed() -> void:
	remapping_action = ""
	if binding_status_label:
		binding_status_label.text = ""
	_refresh_binding_labels()
	world = AshWorldState.new(PLAYTEST_SEED)
	run_started_msec = Time.get_ticks_msec()
	first_trade_elapsed_msec = -1
	if map_panel:
		map_panel.world = world
		map_panel.reduce_motion = reduce_motion_checkbox != null and reduce_motion_checkbox.button_pressed
		map_panel.reset_travel(world.current_settlement)
	_populate_destination_options()
	_select_option_by_id(destination_option, PLAYTEST_DESTINATION)
	_populate_route_options()
	_select_option_by_id(route_option, PLAYTEST_ROUTE)
	_select_option_by_id(cargo_good_option, PLAYTEST_GOOD)
	_select_option_by_id(shop_good_option, PLAYTEST_GOOD)
	cargo_quantity.value = PLAYTEST_QUANTITY
	shop_quantity.value = PLAYTEST_QUANTITY
	guided_test_button.disabled = false
	arrival_pending = false
	enter_settlement_button.visible = false
	commit_departure_button.disabled = false
	return_to_shop_button.disabled = false
	playtest_banner.text = "QUICK PLAYTEST — Guidance is optional; every trade and route remains available."
	_set_event("Ashgate market is open. Inspect local prices, load cargo, then plan a route when you are ready.")
	_show_shop()

func _on_start_game_requested() -> void:
	var save_files_exist := FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak")
	if not save_files_exist:
		_on_start_game_pressed()
		return
	if new_game_confirmation_dialog == null:
		new_game_confirmation_dialog = ConfirmationDialog.new()
		new_game_confirmation_dialog.title = "Start a new campaign?"
		new_game_confirmation_dialog.dialog_text = "Campaign save files already exist. They remain untouched until the new run's first successful autosave, which may replace them."
		new_game_confirmation_dialog.ok_button_text = "Start new campaign"
		new_game_confirmation_dialog.cancel_button_text = "Keep saved campaign"
		new_game_confirmation_dialog.confirmed.connect(_on_start_game_pressed)
		add_child(new_game_confirmation_dialog)
	new_game_confirmation_dialog.popup_centered(Vector2i(560, 190))
	new_game_confirmation_dialog.get_cancel_button().call_deferred("grab_focus")

func _select_option_by_id(option: OptionButton, target_id: String) -> void:
	for index in range(option.item_count):
		if String(option.get_item_metadata(index)) == target_id:
			option.select(index)
			return

func _on_guided_test_action() -> void:
	_select_option_by_id(destination_option, PLAYTEST_DESTINATION)
	_populate_route_options()
	_select_option_by_id(route_option, PLAYTEST_ROUTE)
	_select_option_by_id(cargo_good_option, PLAYTEST_GOOD)
	_select_option_by_id(shop_good_option, PLAYTEST_GOOD)
	cargo_quantity.value = PLAYTEST_QUANTITY
	shop_quantity.value = PLAYTEST_QUANTITY
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": PLAYTEST_GOOD, "quantity": PLAYTEST_QUANTITY},
	})
	_record_first_trade(result)
	if result.ok:
		guided_test_button.disabled = true
	_show_command_result(result, "Test action")
	if result.ok:
		_grab_focus_if_available(plan_departure_button)

func _on_plan_departure_pressed() -> void:
	_sync_shop_plan_to_departure()
	_set_event("Departure planning is open. Compare a legal route before committing; returning to the shop spends nothing.")
	_show_departure()

func _on_return_to_shop_pressed() -> void:
	_sync_departure_plan_to_shop()
	_set_event("Back at the settlement shop. Your planning selection was preserved; no resources changed.")
	_show_shop()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		last_input_device = "controller"
	elif event is InputEventKey:
		last_input_device = "keyboard"
	elif event is InputEventMouseButton or event is InputEventMouseMotion:
		last_input_device = "mouse"

func _unhandled_input(event: InputEvent) -> void:
	if not remapping_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			_capture_keyboard_binding(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.pressed:
			_capture_controller_binding(event)
			get_viewport().set_input_as_handled()
		return
	if pause_layer != null and pause_layer.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
		_close_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_pause") and menu_layer != null and not menu_layer.visible:
		_open_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and game_layer != null and game_layer.visible and world.pending_event.is_empty() and not arrival_pending:
		_on_return_to_shop_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") and menu_layer != null and not menu_layer.visible:
		_open_pause()
		get_viewport().set_input_as_handled()

func _open_pause() -> void:
	if pause_layer == null or menu_layer.visible:
		return
	focus_before_pause = get_viewport().gui_get_focus_owner()
	_refresh_pause_summary()
	pause_layer.visible = true
	get_tree().paused = true
	pause_resume_button.grab_focus()
	_publish_web_ui_state()

func _refresh_pause_summary(feedback_text: String = "") -> void:
	if pause_summary_label == null:
		return
	var detail := feedback_text if not feedback_text.is_empty() else save_status_text
	pause_summary_label.text = "Day %d · %s · %d ashmarks · hold %d/%d\n%s" % [world.day, String(world.settlement(world.current_settlement).get("name", world.current_settlement)), world.money, int(world.cargo.get("weight", 0)), world.cargo_capacity, detail]

func _close_pause() -> void:
	get_tree().paused = false
	pause_layer.visible = false
	_publish_web_ui_state()
	if _grab_focus_if_available(focus_before_pause):
		return
	if shop_layer.visible:
		_grab_focus_if_available(shop_good_option)
	elif not world.pending_event.is_empty():
		_grab_first_enabled(event_choice_buttons)
	else:
		_grab_focus_if_available(destination_option)

func _on_pause_load_pressed() -> void:
	if not _on_load_pressed():
		_refresh_pause_summary(event_label.text)
		return
	get_tree().paused = false
	pause_layer.visible = false
	_publish_web_ui_state()
	if not world.pending_event.is_empty():
		_grab_first_enabled(event_choice_buttons)
	else:
		_grab_focus_if_available(shop_good_option)

func _on_pause_main_menu_pressed() -> void:
	if autosave_enabled and not _write_save("AUTOSAVED"):
		_set_event("Return to main menu blocked because the campaign could not be saved. The current run remains open and unchanged.")
		_refresh_ui()
		_refresh_pause_summary("RETURN BLOCKED — The campaign could not be saved. Resume to keep playing or choose another save path before leaving.")
		return
	_close_pause()
	_show_main_menu()

func _on_export_report_pressed() -> void:
	var viewport_size := _report_viewport_size()
	var report := {
		"report_version": 4,
		"game_version": String(ProjectSettings.get_setting("application/config/version", "unknown")),
		"content_version": MarketContent.content_version(),
		"save_version": AshWorldState.SAVE_VERSION,
		"build_commit": String(ProjectSettings.get_setting("market_of_ash/build_commit", "development")),
		"build_run": String(ProjectSettings.get_setting("market_of_ash/build_run", "local")),
		"platform": OS.get_name(),
		"input_device": last_input_device,
		"viewport": {"width": int(viewport_size.x), "height": int(viewport_size.y)},
		"display_scale": _report_display_scale(),
		"presentation": {"large_text": large_text_enabled, "reduced_motion": reduce_motion_enabled, "interface_sounds": interface_sounds_enabled},
		"session_elapsed_seconds": maxf(0.0, float(Time.get_ticks_msec() - run_started_msec) / 1000.0),
		"time_to_first_trade_seconds": null if first_trade_elapsed_msec < 0 else float(first_trade_elapsed_msec) / 1000.0,
		"seed": world.seed,
		"day": world.day,
		"settlement_id": world.current_settlement,
		"money": world.money,
		"provisions": world.provisions,
		"cargo": world.cargo.duplicate(true),
		"crisis_stage": world.crisis_stage,
		"reputation": world.reputation.duplicate(true),
		"arms_escalation": world.arms_escalation,
		"settlement_resilience": world.settlement_resilience.duplicate(true),
		"ending_id": world.ending_id,
		"ending_summary": world.ending_summary,
		"active_contracts": world.active_contracts.duplicate(true),
		"contract_history": world.contract_history.duplicate(true),
		"pending_event": world.pending_event.duplicate(true),
		"event_history": world.event_history.duplicate(true),
		"route_conditions": world.route_conditions.duplicate(true),
		"known_information": world.known_information.duplicate(),
		"recruited_crew": world.recruited_crew.duplicate(),
		"assigned_crew": world.assigned_crew,
		"command_history": world.command_history.duplicate(true),
		"game_log": world.log.duplicate(),
	}
	var report_json := JSON.stringify(report, "\t")
	if _download_web_report(report_json):
		_play_ui_cue("success")
		_set_event("REPORT DOWNLOAD REQUESTED — %s\nIf the browser asks, allow the download. Build, platform, viewport, presentation settings, timing, seed, and campaign evidence are included. No personal data is included." % WEB_REPORT_FILENAME)
	else:
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		if file == null:
			_play_ui_cue("blocked")
			_set_event("Report export failed. The campaign remains unchanged.")
			_refresh_ui()
			if pause_layer != null and pause_layer.visible:
				_refresh_pause_summary(event_label.text)
			return
		file.store_string(report_json)
		file.flush()
		if file.get_error() != OK:
			_play_ui_cue("blocked")
			_set_event("Report export failed. The campaign remains unchanged.")
		else:
			_play_ui_cue("success")
			_set_event("REPORT EXPORTED — %s\nBuild, platform, viewport, presentation settings, timing, seed, and campaign evidence are included. No personal data is included." % ProjectSettings.globalize_path(report_path))
	_refresh_ui()
	if pause_layer != null and pause_layer.visible:
		_refresh_pause_summary(event_label.text)

func _download_web_report(report_json: String) -> bool:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return false
	var bridge: Object = Engine.get_singleton("JavaScriptBridge")
	if not bridge.has_method("download_buffer"):
		return false
	bridge.call("download_buffer", report_json.to_utf8_buffer(), WEB_REPORT_FILENAME, "application/json")
	return true

func _current_ui_state_id() -> String:
	if pause_layer != null and pause_layer.visible:
		return "pause"
	if menu_layer != null and menu_layer.visible:
		return "main_menu"
	if shop_layer != null and shop_layer.visible:
		return "settlement_shop"
	if game_layer != null and game_layer.visible:
		if not world.pending_event.is_empty():
			return "route_event"
		if arrival_pending:
			return "arrival_handoff"
		return "departure_desk"
	return "unknown"

func _publish_web_ui_state() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	var bridge: Object = Engine.get_singleton("JavaScriptBridge")
	bridge.call("eval", "window.marketOfAshUiState = %s;" % JSON.stringify(_web_ui_state()))

func _web_ui_state() -> Dictionary:
	var selected_good_id := _selected_id(shop_good_option) if shop_good_option != null else ""
	return {
		"screen": _current_ui_state_id(),
		"large_text": large_text_enabled,
		"settlement_id": world.current_settlement if world != null else "",
		"pending_event_id": String(world.pending_event.get("id", "")) if world != null else "",
		"selected_good_id": selected_good_id,
		"selected_destination_id": _selected_id(destination_option) if destination_option != null else "",
		"selected_quantity": int(shop_quantity.value) if shop_quantity != null else 0,
		"held_selected_quantity": int(world.cargo.get(selected_good_id, 0)) if world != null else 0,
	}

func _report_viewport_size() -> Vector2i:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge: Object = Engine.get_singleton("JavaScriptBridge")
		var browser_width := int(bridge.call("eval", "window.innerWidth"))
		var browser_height := int(bridge.call("eval", "window.innerHeight"))
		if browser_width > 0 and browser_height > 0:
			return Vector2i(browser_width, browser_height)
	var window_size := DisplayServer.window_get_size()
	if window_size.x > 0 and window_size.y > 0:
		return window_size
	return Vector2i(get_viewport().get_visible_rect().size)

func _report_display_scale() -> float:
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var bridge: Object = Engine.get_singleton("JavaScriptBridge")
		var browser_scale := float(bridge.call("eval", "window.devicePixelRatio"))
		if browser_scale > 0.0:
			return browser_scale
	var screen_scale := DisplayServer.screen_get_scale(DisplayServer.window_get_current_screen())
	return screen_scale if screen_scale > 0.0 else 1.0

func _on_enter_settlement_pressed() -> void:
	_set_event("You entered %s. Review the local market and decide how to recover or reinvest." % String(world.settlement(world.current_settlement).get("name", "the settlement")))
	_show_shop()

func _on_settlement_action_pressed(action_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": action_id},
	})
	_show_command_result(result, "Opportunity")
	_restore_shop_action_focus()

func _on_accept_contract_pressed(contract_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": contract_id},
	})
	_show_command_result(result, "Contract")
	_restore_shop_action_focus()

func _on_resolve_contract_pressed(contract_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RESOLVE_CONTRACT,
		"inputs": {"contract_id": contract_id},
	})
	_show_command_result(result, "Contract")
	_restore_shop_action_focus()

func _on_recruit_crew_pressed(crew_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RECRUIT_CREW,
		"inputs": {"crew_id": crew_id},
	})
	_show_command_result(result, "Recruitment")
	_restore_shop_action_focus()

func _on_assign_crew_pressed(crew_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": crew_id},
	})
	_show_command_result(result, "Crew assignment")
	_restore_shop_action_focus()

func _restore_shop_action_focus() -> void:
	if not shop_layer.visible or (pause_layer != null and pause_layer.visible):
		return
	for controls in [contract_buttons, opportunity_buttons, crew_buttons]:
		if _grab_first_enabled(controls):
			return
	_grab_focus_if_available(plan_departure_button)

func _on_event_choice_pressed(event_id: String, choice_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": event_id, "choice_id": choice_id},
	})
	if result.ok:
		arrival_pending = true
		enter_settlement_button.visible = true
		_populate_destination_options()
		_populate_route_options()
	_show_command_result(result, "Route decision")

func _on_shop_plan_changed(_index: int) -> void:
	_sync_shop_plan_to_departure()
	_refresh_ui()

func _on_shop_quantity_changed(_value: float) -> void:
	_sync_shop_plan_to_departure()
	_refresh_ui()

func _sync_shop_plan_to_departure() -> void:
	if shop_good_option == null or cargo_good_option == null:
		return
	_select_option_by_id(cargo_good_option, _selected_id(shop_good_option))
	cargo_quantity.value = shop_quantity.value

func _sync_departure_plan_to_shop() -> void:
	if shop_good_option == null or cargo_good_option == null:
		return
	_select_option_by_id(shop_good_option, _selected_id(cargo_good_option))
	shop_quantity.value = cargo_quantity.value

func _on_destination_changed(_index: int) -> void:
	_populate_route_options()
	_refresh_forecasts()

func _on_forecast_input_changed(_index: int) -> void:
	_sync_departure_plan_to_shop()
	_refresh_forecasts()

func _on_forecast_value_changed(_value: float) -> void:
	_sync_departure_plan_to_shop()
	_refresh_forecasts()

func _refresh_forecasts() -> void:
	if market_preview_label == null or route_preview_label == null:
		return
	var good_id := _selected_id(cargo_good_option)
	var destination_id := _selected_id(destination_option)
	var route_id := _selected_id(route_option)
	var quantity := int(cargo_quantity.value)
	var origin := world.settlement(world.current_settlement)
	var destination := world.settlement(destination_id)
	if plan_departure_button:
		plan_departure_button.text = "Plan %s x%d to %s" % [good_id.capitalize(), quantity, String(destination.get("name", destination_id))]
	var world_context := world.pricing_context()
	var forecast_cargo := world.cargo.duplicate(true)
	forecast_cargo[good_id] = maxi(int(forecast_cargo.get(good_id, 0)), quantity)
	world_context["cargo"] = forecast_cargo
	world_context["route_intelligence"] = world.route_intelligence(route_id)
	var market_text := _market_preview_text(good_id, quantity, origin, world_context)
	market_preview_label.text = market_text
	if shop_market_preview_label:
		shop_market_preview_label.text = market_text
	var transaction_notes: Array[String] = []
	if shop_buy_button:
		var unit_price := MarketEconomy.price_for(good_id, origin, world_context)
		var buy_total := unit_price * quantity
		var buy_validation := MarketEconomy.validate_trade(world.cargo, good_id, quantity, world.cargo_capacity)
		shop_buy_button.text = "Buy %d %s — %d ashmarks" % [quantity, good_id.capitalize(), buy_total]
		shop_buy_button.disabled = not bool(buy_validation.get("ok", false)) or world.money < buy_total
		if not bool(buy_validation.get("ok", false)):
			shop_buy_button.tooltip_text = "Cannot buy this load: %s." % String(buy_validation.get("reason", "invalid cargo load"))
			transaction_notes.append("Buy unavailable: %s." % String(buy_validation.get("reason", "invalid cargo load")))
		elif world.money < buy_total:
			shop_buy_button.tooltip_text = "This load costs %d ashmarks; the caravan has %d." % [buy_total, world.money]
			transaction_notes.append("Buy unavailable: need %d ashmarks; have %d." % [buy_total, world.money])
		else:
			shop_buy_button.tooltip_text = "Buy the selected cargo from this settlement."
	if shop_sell_button:
		var held_quantity := int(world.cargo.get(good_id, 0))
		var sale_total := MarketEconomy.price_for(good_id, origin, world_context) * quantity
		shop_sell_button.text = "Sell %d %s — %d ashmarks" % [quantity, good_id.capitalize(), sale_total]
		shop_sell_button.disabled = held_quantity < quantity
		shop_sell_button.tooltip_text = "Sell the selected cargo held by the caravan." if not shop_sell_button.disabled else "Hold contains %d of the selected %d %s." % [held_quantity, quantity, good_id.capitalize()]
		if shop_sell_button.disabled:
			transaction_notes.append("Sell unavailable: hold has %d/%d %s." % [held_quantity, quantity, good_id.capitalize()])
	if shop_transaction_status_label:
		shop_transaction_status_label.text = "Buy or sell the selected load." if transaction_notes.is_empty() else " ".join(transaction_notes)
	if departure_load_label:
		departure_load_label.text = "FORECAST SCENARIO\n%s x%d · actually held %d · total hold %d/%d · cash %d · provisions %d" % [good_id.capitalize(), quantity, int(world.cargo.get(good_id, 0)), int(world.cargo.get("weight", 0)), world.cargo_capacity, world.money, world.provisions]
	if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		route_preview_label.text = "ROUTE FORECAST\nChoose a directly connected destination and route."
		if commit_departure_button:
			commit_departure_button.text = "Commit departure"
		return
	var selected_route := world.route(route_id, world.current_settlement, destination_id)
	selected_route["provisions"] = world.route_provision_cost(route_id, destination_id)
	if commit_departure_button:
		var provision_count := int(selected_route.get("provisions", 0))
		var provision_label := "provision" if provision_count == 1 else "provisions"
		commit_departure_button.text = "Commit — %d ashmarks · %d %s" % [int(selected_route.get("cost", 0)), provision_count, provision_label]
	route_preview_label.text = _route_preview_text(good_id, quantity, origin, destination, selected_route, world_context)

func _market_preview_text(good_id: String, quantity: int, settlement: Dictionary, world_context: Dictionary) -> String:
	var details := MarketEconomy.price_details(good_id, settlement, world_context)
	if not details.ok:
		return "MARKET\nNo valid good selected."
	var reason_text := "; ".join(details.reasons)
	var unit_price := int(details.unit_price)
	var memory_text := ""
	if float(details.market_pressure) > 0.0:
		var delivery := world.latest_market_delivery(String(settlement.get("id", "")), good_id)
		var decay_percent := int(round(float(MarketContent.market_memory_rules().get("daily_decay_per_day", 0.0)) * 100.0))
		if delivery.is_empty():
			memory_text = "\nMarket memory: recent deliveries softened this price by %d%%; the effect recovers by %d%% per day." % [int(round(float(details.market_pressure) * 100.0)), decay_percent]
		else:
			memory_text = "\nMarket memory: your last %d %s delivered here softened this price by %d%%; the effect recovers by %d%% per day." % [int(delivery.quantity), good_id, int(round(float(details.market_pressure) * 100.0)), decay_percent]
	var comparison: Array[String] = []
	for settlement_id in MarketContent.settlement_ids():
		var candidate := world.settlement(settlement_id)
		if candidate == settlement:
			continue
		comparison.append("%s %d" % [String(candidate.get("name", settlement_id)), MarketEconomy.price_for(good_id, candidate, world_context)])
	return "MARKET — %s\n%s: %d ashmarks each · load total %d\nWhy this price: %s%s\nOther markets: %s\nBase %d × local %.2f × demand %.2f × crisis %.2f × faction %.2f × memory %.2f" % [settlement.get("name", "Unknown market"), good_id.capitalize(), unit_price, unit_price * quantity, reason_text, memory_text, "; ".join(comparison), int(details.base_price), float(details.settlement_modifier), float(details.demand_modifier), float(details.crisis_modifier), float(details.faction_modifier), float(details.market_memory_modifier)]

func _route_preview_text(good_id: String, quantity: int, origin: Dictionary, destination: Dictionary, route: Dictionary, world_context: Dictionary) -> String:
	var preview := MarketEconomy.route_profit_preview(good_id, quantity, origin, destination, route, world_context)
	if not preview.ok:
		return "ROUTE FORECAST\nChoose a valid cargo, destination, and route."
	var net_profit := int(preview.expected_net_profit)
	var net_text := ("+%d" % net_profit) if net_profit > 0 else str(net_profit)
	var cargo_risk_text: String
	if int(preview.loss_quantity) <= 0:
		cargo_risk_text = "Cargo risk: no carried cargo is currently at risk; expected loss 0 at %d%% risk." % int(round(float(preview.risk) * 100.0))
	else:
		cargo_risk_text = "Cargo risk: 1 %s unit at risk, valued at %d at %s; expected loss %d at %d%% risk." % [String(preview.loss_good_id).capitalize(), int(preview.loss_unit_value), destination.get("name", "the destination"), int(preview.expected_loss), int(round(float(preview.risk) * 100.0))]
	var intelligence: Dictionary = world_context.get("route_intelligence", {})
	var intelligence_text := "%s — %s" % [String(intelligence.get("label", "Scout unavailable")), String(intelligence.get("detail", "No current field report."))]
	var held_quantity := int(world.cargo.get(good_id, 0))
	var load_check: String
	if held_quantity < quantity:
		load_check = "LOAD CHECK — Held %d/%d selected %s. Buy %d before departure to carry this full scenario; travel uses the actual hold." % [held_quantity, quantity, good_id.capitalize(), quantity - held_quantity]
	else:
		load_check = "LOAD CHECK — Held %d/%d selected %s. This scenario is covered; departure still carries the full actual hold." % [held_quantity, quantity, good_id.capitalize()]
	var faction_text := ""
	if route.has("faction_effect"):
		faction_text = "\n%s standing: %s Trade-off: %s" % [String(route.get("faction_name", "Faction")), String(route.get("faction_effect", "")), String(route.get("faction_tradeoff", ""))]
	if route.has("arms_effect"):
		faction_text += "\nEscalation warning: %s" % String(route.get("arms_effect", ""))
	if route.has("crisis_effect"):
		faction_text += "\nCrisis route change: %s" % String(route.get("crisis_effect", ""))
	return "ROUTE FORECAST — %s to %s via %s\nScenario buy %d · expected sale %d · gross margin %+d\nRoute fee %d · provisions %d (%d value) · time cost %d\n%s\n%s\nEXPECTED NET PROFIT %s ashmarks\nRisk source: %s\nScout confidence: %s%s" % [origin.get("name", "Origin"), destination.get("name", "Destination"), route.get("name", "Route"), int(preview.purchase_total), int(preview.sale_total), int(preview.gross_trade_margin), int(preview.route_cost), int(preview.provisions), int(preview.provision_cost), int(preview.time_cost), load_check, cargo_risk_text, net_text, String(preview.risk_source), intelligence_text, faction_text]

func _on_buy_pressed() -> void:
	_sync_shop_plan_to_departure()
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {
			"good_id": _selected_id(cargo_good_option),
			"quantity": int(cargo_quantity.value),
		},
	})
	_record_first_trade(result)
	_show_command_result(result, "Purchase")
	if result.ok:
		_grab_focus_if_available(plan_departure_button)

func _on_sell_pressed() -> void:
	_sync_shop_plan_to_departure()
	var good_id := _selected_id(cargo_good_option)
	var quantity := int(cargo_quantity.value)
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {
			"good_id": good_id,
			"quantity": quantity,
		},
	})
	_record_first_trade(result)
	_show_command_result(result, "Sale")
	if result.ok and shop_sell_button != null and shop_sell_button.disabled:
		_grab_focus_if_available(plan_departure_button)

func _record_first_trade(result: Dictionary) -> void:
	if bool(result.get("ok", false)) and first_trade_elapsed_msec < 0:
		first_trade_elapsed_msec = maxi(0, Time.get_ticks_msec() - run_started_msec)

func _on_depart_pressed() -> void:
	var route_id := _selected_id(route_option)
	var destination_id := _selected_id(destination_option)
	var previous_settlement: String = world.current_settlement
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {
			"route_id": route_id,
			"destination_id": destination_id,
		},
	})
	if result.ok:
		arrival_pending = world.pending_event.is_empty()
		commit_departure_button.disabled = true
		return_to_shop_button.disabled = true
		enter_settlement_button.visible = arrival_pending
		if map_panel:
			map_panel.begin_travel(route_id, previous_settlement, destination_id)
		_populate_destination_options()
		_populate_route_options()
	_show_command_result(result, "Departure")

func _show_command_result(result: Dictionary, label: String) -> void:
	if result.ok:
		var result_text := String(result.message)
		var save_succeeded := true
		if autosave_enabled:
			save_succeeded = _write_save("AUTOSAVED")
		if not save_succeeded:
			result_text += "\nSAVE WARNING — %s" % save_status_text.trim_prefix("SAVE ERROR — ")
		_play_ui_cue(("travel" if label == "Departure" else "success") if save_succeeded else "blocked")
		_set_event("%s\nNEXT — %s" % [result_text, _next_step_text()])
	else:
		_play_ui_cue("blocked")
		_set_event("%s blocked: %s.\nNEXT — %s" % [label, String(result.reason), _next_step_text()])
	_refresh_ui()

func _next_step_text() -> String:
	if not world.pending_event.is_empty():
		return "Choose one available route response; unavailable prerequisites are listed below their choices."
	if arrival_pending:
		return "Review the result, then choose Enter %s to trade at the destination." % String(world.settlement(world.current_settlement).get("name", "settlement"))
	if shop_layer != null and shop_layer.visible:
		return "Adjust cargo or local commitments, then open Plan departure when the next route is worthwhile."
	return "Adjust the destination, route, or forecast load before committing travel."

func _on_save_pressed() -> void:
	var save_succeeded := _write_save("SAVED")
	_play_ui_cue("success" if save_succeeded else "blocked")
	if save_succeeded:
		_set_event("Versioned prototype state saved. Command history is included for deterministic review.")
	else:
		_set_event("Save failed. The current run remains active and unchanged.")
	_refresh_ui()
	if pause_layer != null and pause_layer.visible:
		_refresh_pause_summary()

func _write_save(status_prefix: String) -> bool:
	var temporary_path := save_path + ".tmp"
	var backup_path := save_path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		save_status_text = "SAVE ERROR — Could not open a temporary save file. Current run unchanged."
		return false
	file.store_string(JSON.stringify(world.serialize()))
	file.flush()
	if file.get_error() != OK:
		save_status_text = "SAVE ERROR — Could not finish writing. Current run unchanged."
		return false
	file = null
	var target_absolute := ProjectSettings.globalize_path(save_path)
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(save_path):
		var primary_is_valid := bool(_load_candidate(save_path).get("ok", false))
		if primary_is_valid:
			if FileAccess.file_exists(backup_path):
				var remove_backup_error := DirAccess.remove_absolute(backup_absolute)
				if remove_backup_error != OK:
					DirAccess.remove_absolute(temporary_absolute)
					save_status_text = "SAVE ERROR — Could not rotate the previous backup. Current run unchanged."
					return false
			var backup_error := DirAccess.copy_absolute(target_absolute, backup_absolute)
			if backup_error != OK:
				DirAccess.remove_absolute(temporary_absolute)
				save_status_text = "SAVE ERROR — Could not preserve the previous save. Current run unchanged."
				return false
		var remove_error := DirAccess.remove_absolute(target_absolute)
		if remove_error != OK:
			DirAccess.remove_absolute(temporary_absolute)
			save_status_text = "SAVE ERROR — Could not replace the previous save. Current run unchanged."
			return false
	var promote_error := DirAccess.rename_absolute(temporary_absolute, target_absolute)
	if promote_error != OK:
		if FileAccess.file_exists(backup_path) and not FileAccess.file_exists(save_path):
			DirAccess.copy_absolute(backup_absolute, target_absolute)
		save_status_text = "SAVE ERROR — Could not promote the validated save. Previous save preserved when available."
		return false
	var settlement_name := String(world.settlement(world.current_settlement).get("name", world.current_settlement))
	save_status_text = "%s — Day %d · %s · %d ashmarks · hold %d/%d · save v%d · content %s" % [status_prefix, world.day, settlement_name, world.money, int(world.cargo.get("weight", 0)), world.cargo_capacity, AshWorldState.SAVE_VERSION, MarketContent.content_version()]
	if continue_game_button:
		continue_game_button.disabled = false
		continue_game_button.tooltip_text = "Validate and continue the saved campaign."
	if start_game_button:
		start_game_button.text = "Start new game"
		start_game_button.tooltip_text = "Requires confirmation because a validated saved campaign is available."
	return true

func _on_load_pressed() -> bool:
	var backup_path := save_path + ".bak"
	if not FileAccess.file_exists(save_path) and not FileAccess.file_exists(backup_path):
		_play_ui_cue("blocked")
		save_status_text = "LOAD BLOCKED — No saved campaign exists yet. Current run unchanged."
		_set_event(save_status_text)
		_refresh_ui()
		return false
	var load_attempt := _load_candidate(save_path)
	var recovered_backup := false
	if not bool(load_attempt.get("ok", false)) and FileAccess.file_exists(backup_path):
		load_attempt = _load_candidate(backup_path)
		recovered_backup = bool(load_attempt.get("ok", false))
	if not bool(load_attempt.get("ok", false)):
		_play_ui_cue("blocked")
		save_status_text = "LOAD BLOCKED — %s. Current run unchanged." % String(load_attempt.get("reason", "Save validation failed"))
		_set_event(save_status_text)
		_refresh_ui()
		return false
	var candidate: AshWorldState = load_attempt.world
	var load_result: Dictionary = load_attempt.result
	remapping_action = ""
	if binding_status_label:
		binding_status_label.text = ""
	_refresh_binding_labels()
	world = candidate
	arrival_pending = false
	if map_panel:
		map_panel.world = world
		map_panel.reduce_motion = reduce_motion_checkbox != null and reduce_motion_checkbox.button_pressed
		map_panel.reset_travel(world.current_settlement)
	_populate_destination_options()
	_populate_route_options()
	var migrated_from := int(load_result.get("migrated_from", AshWorldState.SAVE_VERSION))
	var migration_text := " · migrated from v%d" % migrated_from if migrated_from < AshWorldState.SAVE_VERSION else ""
	var status_prefix := "RECOVERED BACKUP" if recovered_backup else "LOADED"
	save_status_text = "%s — Day %d · %s · %d ashmarks · hold %d/%d · save v%d%s" % [status_prefix, world.day, String(world.settlement(world.current_settlement).get("name", world.current_settlement)), world.money, int(world.cargo.get("weight", 0)), world.cargo_capacity, AshWorldState.SAVE_VERSION, migration_text]
	_set_event("Saved campaign loaded after validation. Seed %d and command history are restored." % world.seed)
	_play_ui_cue("success")
	if world.pending_event.is_empty():
		_show_shop()
	else:
		_show_departure()
	return true

func _load_candidate(candidate_path: String) -> Dictionary:
	if not FileAccess.file_exists(candidate_path):
		return {"ok": false, "reason": "No saved campaign exists at this path"}
	var file := FileAccess.open(candidate_path, FileAccess.READ)
	if file == null:
		return {"ok": false, "reason": "The save could not be opened"}
	if file.get_length() > MAX_SAVE_BYTES:
		return {"ok": false, "reason": "The save is larger than the supported 5 MB limit"}
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	var parsed: Variant = parser.data
	if parse_error != OK or typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "The file is not a valid save object"}
	var candidate := AshWorldState.new(world.seed)
	var load_result := candidate.load_serialized(parsed)
	if not bool(load_result.get("ok", false)):
		return {"ok": false, "reason": String(load_result.get("reason", "Save validation failed"))}
	return {"ok": true, "world": candidate, "result": load_result}

func _on_reset_pressed() -> void:
	if reset_confirmation_dialog == null:
		reset_confirmation_dialog = ConfirmationDialog.new()
		reset_confirmation_dialog.title = "Reset current run?"
		reset_confirmation_dialog.dialog_text = "Return to Ashgate on Day 1 with the default caravan? Your existing disk save remains available until the next successful command autosaves."
		reset_confirmation_dialog.ok_button_text = "Reset to Day 1"
		reset_confirmation_dialog.cancel_button_text = "Keep current run"
		reset_confirmation_dialog.confirmed.connect(_confirm_reset)
		add_child(reset_confirmation_dialog)
	reset_confirmation_dialog.popup_centered(Vector2i(520, 180))
	reset_confirmation_dialog.get_cancel_button().call_deferred("grab_focus")

func _confirm_reset() -> void:
	if reset_confirmation_dialog:
		reset_confirmation_dialog.hide()
	world = AshWorldState.new(PLAYTEST_SEED)
	_populate_destination_options()
	_populate_route_options()
	map_panel.world = world
	map_panel.reset_travel(world.current_settlement)
	_set_event("The caravan has been reset to its first morning. The previous disk save remains available until another command autosaves.")
	_show_shop()

func _on_map_settlement_selected(settlement_id: String) -> void:
	if not world.pending_event.is_empty() or arrival_pending:
		_set_event("This journey is already committed. Resolve the route decision or enter the destination before planning another trip.")
		_refresh_ui()
		return
	var settlement_name := String(world.settlement(settlement_id).get("name", settlement_id))
	if settlement_id == world.current_settlement:
		_set_event("You are already in %s. Choose another settlement to plan a journey." % settlement_name)
		_refresh_ui()
		return
	for index in range(destination_option.item_count):
		if String(destination_option.get_item_metadata(index)) != settlement_id:
			continue
		destination_option.select(index)
		_on_destination_changed(index)
		_set_event("Map destination selected: %s. Review the route cost, provisions, time, and exposed cargo before committing." % settlement_name)
		_refresh_ui()
		return
	_set_event("No direct route reaches %s from %s. Travel through a connected settlement first." % [settlement_name, String(world.settlement(world.current_settlement).get("name", world.current_settlement))])
	_refresh_ui()

func _refresh_playtest_status() -> void:
	if playtest_status_label == null:
		return
	var guided_cargo_held := int(world.cargo.get(PLAYTEST_GOOD, 0))
	var guided_cargo_bought := _guided_trade_quantity(MarketCommandProcessor.BUY_GOODS)
	var guided_cargo_sold := _guided_trade_quantity(MarketCommandProcessor.SELL_GOODS, PLAYTEST_DESTINATION)
	if guided_test_button:
		guided_test_button.visible = world.current_settlement == "ashgate" and world.day == 1 and guided_cargo_sold < PLAYTEST_QUANTITY
		var origin := world.settlement(world.current_settlement)
		var guided_total := MarketEconomy.price_for(PLAYTEST_GOOD, origin, world.pricing_context()) * PLAYTEST_QUANTITY
		var guided_validation := MarketEconomy.validate_trade(world.cargo, PLAYTEST_GOOD, PLAYTEST_QUANTITY, world.cargo_capacity)
		var guided_completed := guided_cargo_bought >= PLAYTEST_QUANTITY or guided_cargo_held >= PLAYTEST_QUANTITY or guided_cargo_sold >= PLAYTEST_QUANTITY
		guided_test_button.text = "Optional: Buy 2 Water — %d ashmarks" % guided_total
		guided_test_button.disabled = guided_completed or not bool(guided_validation.get("ok", false)) or world.money < guided_total
		if guided_completed:
			guided_test_button.tooltip_text = "The opening purchase has already been completed or superseded."
		elif not bool(guided_validation.get("ok", false)):
			guided_test_button.tooltip_text = "The opening purchase is unavailable: %s." % String(guided_validation.get("reason", "invalid cargo load"))
		elif world.money < guided_total:
			guided_test_button.tooltip_text = "The opening purchase needs %d ashmarks; the caravan has %d." % [guided_total, world.money]
		else:
			guided_test_button.tooltip_text = "Runs the normal buy command for the first-run learning example."
	if guided_cargo_sold >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "RUN COMPLETE — You moved water to Reedwatch and sold it. Compare the opening forecast with the realized result, then reset or keep trading."
	elif world.current_settlement == PLAYTEST_DESTINATION and guided_cargo_held >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "STEP 3 OF 3 — You reached Reedwatch with water. Sell 2 water to see the delivery result."
	elif world.current_settlement == PLAYTEST_DESTINATION and guided_cargo_held > 0 and guided_cargo_bought >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "RECOVERY — Only %d of the planned 2 water reached Reedwatch. Sell what remains, trade onward, or reset; the run is still playable." % guided_cargo_held
	elif guided_cargo_held >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "STEP 2 OF 3 — Water is loaded. Read the Old Road forecast, compare it with the Toll Road, then choose whether to depart for Reedwatch."
	elif guided_cargo_bought >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "RECOVERY — The planned water is no longer in the hold. Review the latest result, then trade onward or reset; no restart is required."
	elif world.current_settlement != "ashgate" or world.day > 1:
		playtest_status_label.text = "FREE PLAY — The optional opening example was skipped. Use the live market, route, contract, and campaign outlook to choose the next trade."
	else:
		playtest_status_label.text = "STEP 1 OF 3 — Read the Water market price and route forecast. Buy 2 water when you are ready; the marked test button simply executes that normal trade."

func _guided_trade_quantity(command_id: String, settlement_id: String = "") -> int:
	var total := 0
	for entry in world.command_history:
		if not bool(entry.get("ok", false)) or String(entry.get("id", "")) != command_id:
			continue
		var inputs_value: Variant = entry.get("inputs", {})
		if typeof(inputs_value) != TYPE_DICTIONARY:
			continue
		var inputs: Dictionary = inputs_value
		if String(inputs.get("good_id", "")) != PLAYTEST_GOOD:
			continue
		if not settlement_id.is_empty():
			var state_delta_value: Variant = entry.get("state_delta", {})
			if typeof(state_delta_value) != TYPE_DICTIONARY:
				continue
			var state_delta: Dictionary = state_delta_value
			var market_memory_value: Variant = state_delta.get("market_memory", {})
			if typeof(market_memory_value) != TYPE_DICTIONARY:
				continue
			var market_memory: Dictionary = market_memory_value
			if String(market_memory.get("settlement_id", "")) != settlement_id:
				continue
		total += maxi(0, int(inputs.get("quantity", 0)))
	return total

func _refresh_opportunities() -> void:
	if opportunity_list == null or opportunity_status_label == null:
		return
	for child in opportunity_list.get_children():
		opportunity_list.remove_child(child)
		child.queue_free()
	opportunity_buttons.clear()
	contract_buttons.clear()
	crew_buttons.clear()
	var slot_limit := int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2))
	opportunity_status_label.text = "%d of %d visit slots remain. Trading never consumes a slot." % [world.visit_slots_remaining, slot_limit]
	_refresh_contract_summary()
	for contract_record in MarketContent.contracts_from(world.current_settlement):
		var contract_id := String(contract_record.get("id", ""))
		var active := world.active_contract(contract_id)
		var contract_button := _wrapped_action_button()
		contract_button.text = "Accept %s" % String(contract_record.get("name", "Contract"))
		var contract_reason := ""
		if not active.is_empty():
			contract_button.disabled = true
			contract_button.text = "%s — active" % String(contract_record.get("name", "Contract"))
			contract_reason = "Already accepted; see the pinned contract summary."
		elif world.has_contract_outcome(contract_id):
			contract_button.disabled = true
			contract_button.text = "%s — resolved" % String(contract_record.get("name", "Contract"))
			contract_reason = "This one-time alpha contract has already been resolved."
		elif world.visit_slots_remaining < int(contract_record.get("service_slots", 1)):
			contract_button.disabled = true
			contract_reason = "No visit slots remain. Depart and arrive at a settlement to refresh them."
		else:
			var good := MarketContent.good(String(contract_record.get("good_id", "")))
			var required_weight := int(good.get("weight", 0)) * int(contract_record.get("quantity", 0))
			var free_capacity := world.cargo_capacity - int(world.cargo.get("weight", 0))
			if free_capacity < required_weight:
				contract_button.disabled = true
				contract_reason = "Needs %d free cargo space; only %d is available." % [required_weight, free_capacity]
		contract_button.tooltip_text = contract_reason if contract_button.disabled else String(contract_record.get("tradeoff", ""))
		contract_button.pressed.connect(_on_accept_contract_pressed.bind(contract_id))
		opportunity_list.add_child(contract_button)
		contract_buttons.append(contract_button)
		var contract_details := Label.new()
		contract_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contract_details.add_theme_font_size_override("font_size", 12)
		contract_details.add_theme_color_override("font_color", Color("#aa9a87"))
		contract_details.text = contract_reason if contract_button.disabled else "%s Sponsor: %s. Deliver %d %s to %s within %d days for %d ashmarks. Failure: %d ashmarks. %s" % [String(contract_record.get("description", "")), String(contract_record.get("sponsor", "")), int(contract_record.get("quantity", 0)), String(contract_record.get("good_id", "")), String(world.settlement(String(contract_record.get("destination_id", ""))).get("name", "destination")), int(contract_record.get("deadline_days", 0)), int(contract_record.get("reward", 0)), int(contract_record.get("failure_penalty", 0)), String(contract_record.get("failure_recovery", ""))]
		opportunity_list.add_child(contract_details)
	var active_ids: Array = world.active_contracts.keys()
	active_ids.sort()
	for active_id_value in active_ids:
		var active_id := String(active_id_value)
		var active := world.active_contract(active_id)
		if world.current_settlement != String(active.get("destination_id", "")):
			continue
		var resolve_button := _wrapped_action_button()
		var remaining := maxi(0, int(active.get("quantity", 0)) - int(world.cargo.get(String(active.get("good_id", "")), 0)))
		resolve_button.text = "Deliver %s" % String(active.get("name", "contract"))
		if world.day <= int(active.get("deadline_day", 0)) and remaining > 0:
			resolve_button.disabled = true
			resolve_button.tooltip_text = "Acquire %d more %s by Day %d." % [remaining, String(active.get("good_id", "")), int(active.get("deadline_day", 0))]
		else:
			resolve_button.tooltip_text = "Resolve the contract using the currently carried cargo and deadline."
		resolve_button.pressed.connect(_on_resolve_contract_pressed.bind(active_id))
		opportunity_list.add_child(resolve_button)
		contract_buttons.append(resolve_button)
	var actions := MarketContent.settlement_actions_for(world.current_settlement)
	for action in actions:
		var action_button := _wrapped_action_button()
		var cost := int(action.get("cost", 0))
		var slots := int(action.get("service_slots", 1))
		var time_cost := int(action.get("time_cost", 0))
		var effects: Dictionary = action.get("effects", {})
		var effect_summary := "+%d provisions" % int(effects.get("provisions", 0)) if effects.has("provisions") else "future effect"
		if effects.has("arms_sale"):
			var arms_sale: Dictionary = effects.get("arms_sale", {})
			effect_summary = "+%d ashmarks, -%d sealed crate, escalation +%d" % [int(arms_sale.get("payout", 0)), int(arms_sale.get("quantity", 0)), int(arms_sale.get("escalation_delta", 0))]
		elif effects.has("arms_recovery"):
			effect_summary = "arms escalation %d" % int(effects.get("arms_recovery", {}).get("escalation_delta", 0))
		elif effects.has("settlement_resilience"):
			var resilience_effect: Dictionary = effects.get("settlement_resilience", {})
			effect_summary = "+%d local resilience, information" % int(resilience_effect.get("delta", 0))
		elif effects.has("route_condition"):
			var route_effect: Dictionary = effects.get("route_condition", {})
			effect_summary = "%+d%% %s risk, information" % [int(round(float(route_effect.get("risk_delta", 0.0)) * 100.0)), String(route_effect.get("route_id", "route")).replace("_", " ").capitalize()]
		action_button.text = "%s — %d ashmarks, %s" % [String(action.get("name", "Opportunity")), cost, effect_summary]
		var unavailable_reason := String(action.get("unavailable_reason", ""))
		if not bool(action.get("available", false)):
			action_button.disabled = true
		elif world.crisis_stage < int(action.get("minimum_crisis_stage", 0)):
			action_button.disabled = true
			unavailable_reason = String(action.get("unavailable_reason", "Unavailable at the current crisis stage."))
		elif bool(action.get("once_per_campaign", false)) and world.known_information.has(String(effects.get("information_id", ""))):
			action_button.disabled = true
			unavailable_reason = "Already completed; its information remains in the caravan log."
		elif not String(action.get("requires_completed_contract_id", "")).is_empty() and not _has_completed_contract(String(action.get("requires_completed_contract_id", ""))):
			action_button.disabled = true
			unavailable_reason = String(action.get("unavailable_reason", "Complete the required contract first."))
		elif world.visit_slots_remaining < slots:
			action_button.disabled = true
			unavailable_reason = "No visit slots remain. Depart and arrive at a settlement to refresh them."
		elif world.money < cost:
			action_button.disabled = true
			unavailable_reason = "You need %d ashmarks, but have %d." % [cost, world.money]
		elif effects.has("arms_sale"):
			var arms_requirement: Dictionary = effects.get("arms_sale", {})
			if int(world.cargo.get(String(arms_requirement.get("good_id", "")), 0)) < int(arms_requirement.get("quantity", 0)):
				action_button.disabled = true
				unavailable_reason = "Needs %d sealed arms crate; acquire one first." % int(arms_requirement.get("quantity", 0))
		elif effects.has("arms_recovery") and world.arms_escalation <= 0:
			action_button.disabled = true
			unavailable_reason = "Arms escalation is already zero; no audit is needed."
		action_button.tooltip_text = unavailable_reason if action_button.disabled else "%s %s" % [String(action.get("description", "")), String(action.get("tradeoff", ""))]
		action_button.pressed.connect(_on_settlement_action_pressed.bind(String(action.get("id", ""))))
		opportunity_list.add_child(action_button)
		opportunity_buttons.append(action_button)
		var details := Label.new()
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 12)
		details.add_theme_color_override("font_color", Color("#aa9a87"))
		details.text = unavailable_reason if action_button.disabled else "%s Cost: %d ashmarks, %d visit slot, %s. %s" % [String(action.get("description", "")), cost, slots, "no day" if time_cost == 0 else "%d day" % time_cost, String(action.get("tradeoff", ""))]
		opportunity_list.add_child(details)
	_append_crew_opportunity()

func _append_crew_opportunity() -> void:
	for crew in MarketContent.crew_records():
		var crew_id := String(crew.get("id", ""))
		var recruited := world.is_crew_recruited(crew_id)
		if not recruited and world.current_settlement != String(crew.get("recruit_settlement_id", "")):
			continue
		var button := _wrapped_action_button()
		var reason := ""
		if not recruited:
			button.text = "Recruit %s — %d ashmarks, %d slot" % [String(crew.get("name", "Crew")), int(crew.get("recruit_cost", 0)), int(crew.get("recruit_service_slots", 1))]
			if world.money < int(crew.get("recruit_cost", 0)):
				button.disabled = true
				reason = "Needs %d ashmarks; you have %d." % [int(crew.get("recruit_cost", 0)), world.money]
			elif world.visit_slots_remaining < int(crew.get("recruit_service_slots", 1)):
				button.disabled = true
				reason = "No visit slots remain."
			button.pressed.connect(_on_recruit_crew_pressed.bind(crew_id))
		else:
			button.text = "Refresh %s's route plan — %d slot" % [String(crew.get("name", "Crew")), int(crew.get("assignment_service_slots", 1))]
			if MarketContent.routes_from(world.current_settlement).is_empty():
				button.disabled = true
				reason = "No authored routes leave this settlement."
			elif world.visit_slots_remaining < int(crew.get("assignment_service_slots", 1)):
				button.disabled = true
				reason = "No visit slots remain."
			button.pressed.connect(_on_assign_crew_pressed.bind(crew_id))
		button.tooltip_text = reason if button.disabled else String(crew.get("hook", ""))
		opportunity_list.add_child(button)
		crew_buttons.append(button)
		var details := Label.new()
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 12)
		details.add_theme_color_override("font_color", Color("#aa9a87"))
		details.text = reason if button.disabled else "%s — %s %s" % [String(crew.get("role", "Crew")), String(crew.get("personality", "")), String(crew.get("limitation", ""))]
		opportunity_list.add_child(details)

func _refresh_contract_summary() -> void:
	if active_contract_label == null or departure_contract_label == null:
		return
	var contract_ids: Array = world.active_contracts.keys()
	contract_ids.sort()
	if contract_ids.is_empty():
		active_contract_label.text = "ACTIVE CONTRACT — none. Spot trade remains unrestricted."
		departure_contract_label.text = "ACTIVE CONTRACT — none."
		return
	var contract_record := world.active_contract(String(contract_ids[0]))
	var good_id := String(contract_record.get("good_id", ""))
	var quantity := int(contract_record.get("quantity", 0))
	var held := int(world.cargo.get(good_id, 0))
	var free_capacity := world.cargo_capacity - int(world.cargo.get("weight", 0))
	var destination_name := String(world.settlement(String(contract_record.get("destination_id", ""))).get("name", "destination"))
	var summary := "%s — %s wants %d %s at %s by Day %d for %d ashmarks. Held %d/%d; free hold %d." % [String(contract_record.get("name", "Contract")), String(contract_record.get("sponsor", "Sponsor")), quantity, good_id, destination_name, int(contract_record.get("deadline_day", 0)), int(contract_record.get("reward", 0)), held, quantity, free_capacity]
	active_contract_label.text = "ACTIVE CONTRACT\n" + summary
	departure_contract_label.text = "CONTRACT PIN\n" + summary

func _refresh_event_card() -> void:
	if event_card == null or event_choice_list == null:
		return
	for child in event_choice_list.get_children():
		event_choice_list.remove_child(child)
		child.queue_free()
	event_choice_buttons.clear()
	event_choice_reason_labels.clear()
	var pending := world.pending_event
	event_card.visible = not pending.is_empty()
	if pending.is_empty():
		if arrival_pending and (pause_layer == null or not pause_layer.visible):
			_grab_focus_if_available(enter_settlement_button)
		return
	event_title_label.text = String(pending.get("title", "Route decision"))
	event_setup_label.text = String(pending.get("setup", ""))
	var destination_name := String(world.settlement(String(pending.get("destination_id", ""))).get("name", "destination"))
	var loss_basis: Dictionary = pending.get("loss_basis", {})
	var cargo_context := "no carried cargo"
	if int(loss_basis.get("loss_quantity", 0)) > 0:
		cargo_context = "1 %s unit valued at %d" % [String(loss_basis.get("loss_good_id", "")).capitalize(), int(loss_basis.get("loss_unit_value", 0))]
	var material_basis: Dictionary = pending.get("material_basis", {})
	var material_parts: Array[String] = []
	var material_goods: Dictionary = material_basis.get("goods", {})
	for good_id in material_goods.keys():
		material_parts.append("%d %s" % [int(material_goods.get(good_id, 0)), String(good_id).capitalize()])
	var material_context := " Repair stock recognized: %s." % " + ".join(material_parts) if not material_parts.is_empty() else ""
	var trade_basis: Dictionary = pending.get("trade_basis", {})
	var trade_context := ""
	if not trade_basis.is_empty():
		trade_context = " Shortage basis: %d %s at %d each, plus %d premium each." % [int(trade_basis.get("quantity", 0)), String(trade_basis.get("good_id", "cargo")).capitalize(), int(trade_basis.get("unit_price", 0)), int(trade_basis.get("premium_per_unit", 0))]
	event_stakes_label.text = "Route context: %s to %s via %s; exposed cargo: %s.%s%s\nWhat is at stake: %s" % [String(world.settlement(String(pending.get("origin_id", ""))).get("name", "origin")), destination_name, String(world.route(String(pending.get("route_id", ""))).get("name", "route")), cargo_context, material_context, trade_context, String(pending.get("stakes", ""))]
	for raw_choice in pending.get("choices", []):
		if typeof(raw_choice) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = raw_choice
		var button := _wrapped_action_button(58.0)
		var money_cost := int(choice.get("money_cost", 0))
		var money_reward := int(choice.get("money_reward", 0))
		var trade_mode := String(choice.get("trade_mode", "none"))
		var trade_quantity := int(trade_basis.get("quantity", 0)) if trade_mode != "none" else 0
		if trade_mode == "premium_sale":
			money_reward += int(trade_basis.get("premium_total", 0))
		var provision_cost := int(choice.get("provision_cost", 0))
		var material_quantity := int(choice.get("material_quantity", 0))
		var cargo_cost: Dictionary = choice.get("cargo_cost", {})
		var cargo_cost_quantity := int(cargo_cost.get("quantity", 0))
		var cargo_cost_good_id := String(cargo_cost.get("good_id", ""))
		var days := int(choice.get("days", 0))
		var cargo_risk := int(round(float(choice.get("cargo_risk", 0.0)) * 100.0))
		var money_text := "%d ashmarks" % money_cost if money_reward == 0 else "+%d ashmarks" % money_reward
		var arrival_text := "return to origin" if String(choice.get("arrival_target", "destination")) == "origin" else "continue to destination"
		var cargo_cost_text := "%d %s" % [trade_quantity, String(trade_basis.get("good_id", "cargo"))] if trade_quantity > 0 else "%d materials" % material_quantity
		if cargo_cost_quantity > 0:
			cargo_cost_text = "%d %s" % [cargo_cost_quantity, cargo_cost_good_id]
		button.text = "%s — %s · %d provisions · %s · %d days · %d%% cargo risk · %s" % [String(choice.get("label", "Choose")), money_text, provision_cost, cargo_cost_text, days, cargo_risk, arrival_text]
		var blocked_reason := ""
		if world.money < money_cost:
			button.disabled = true
			blocked_reason = "Needs %d ashmarks; you have %d." % [money_cost, world.money]
		elif world.provisions < provision_cost:
			button.disabled = true
			blocked_reason = "Needs %d provision; you have %d." % [provision_cost, world.provisions]
		elif material_quantity > 0:
			var available_materials := 0
			for good_id in material_goods.keys():
				available_materials += mini(int(material_goods.get(good_id, 0)), int(world.cargo.get(good_id, 0)))
			if available_materials < material_quantity:
				button.disabled = true
				blocked_reason = "Needs %d of the disclosed repair materials; %d remain." % [material_quantity, available_materials]
		elif trade_quantity > int(world.cargo.get(String(trade_basis.get("good_id", "")), 0)):
			button.disabled = true
			blocked_reason = "Needs %d %s; you have %d." % [trade_quantity, String(trade_basis.get("good_id", "cargo")), int(world.cargo.get(String(trade_basis.get("good_id", "")), 0))]
		elif cargo_cost_quantity > int(world.cargo.get(cargo_cost_good_id, 0)):
			button.disabled = true
			blocked_reason = "Needs %d %s; you have %d." % [cargo_cost_quantity, cargo_cost_good_id, int(world.cargo.get(cargo_cost_good_id, 0))]
		elif bool(choice.get("requires_active_contract", false)) and not _has_relevant_event_contract(String(pending.get("destination_id", "")), String(trade_basis.get("good_id", "water"))):
			button.disabled = true
			blocked_reason = "Needs an active water relief commitment for this destination."
		elif not String(choice.get("requires_assigned_crew_id", "")).is_empty() and world.assigned_crew != String(choice.get("requires_assigned_crew_id", "")):
			button.disabled = true
			blocked_reason = "Requires %s to be assigned." % String(MarketContent.crew_member(String(choice.get("requires_assigned_crew_id", ""))).get("name", "the required crew member"))
		button.tooltip_text = blocked_reason if button.disabled else String(choice.get("outcome", ""))
		button.pressed.connect(_on_event_choice_pressed.bind(String(pending.get("id", "")), String(choice.get("id", ""))))
		event_choice_list.add_child(button)
		event_choice_buttons.append(button)
		if button.disabled:
			var reason_label := Label.new()
			reason_label.text = "Unavailable: %s" % blocked_reason
			reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			reason_label.add_theme_font_size_override("font_size", 11)
			reason_label.add_theme_color_override("font_color", Color("#b5a18b"))
			event_choice_list.add_child(reason_label)
			event_choice_reason_labels.append(reason_label)
	if pause_layer == null or not pause_layer.visible:
		_grab_first_enabled(event_choice_buttons)

func _has_relevant_event_contract(destination_id: String, good_id: String) -> bool:
	for contract_id in world.active_contracts.keys():
		var contract := world.active_contract(String(contract_id))
		if String(contract.get("destination_id", "")) == destination_id and String(contract.get("good_id", "")) == good_id:
			return true
	return false

func _has_completed_contract(contract_id: String) -> bool:
	for contract in world.contract_history:
		if String(contract.get("id", "")) == contract_id and String(contract.get("status", "")) == "completed":
			return true
	return false

func _campaign_outlook_text() -> String:
	if not world.ending_id.is_empty():
		return "CAMPAIGN OUTLOOK — Conclusion recorded: %s." % String(MarketContent.ending(world.ending_id).get("title", world.ending_id))
	var relief_mark := "done" if _has_completed_contract("reedwatch_water_relief_01") else "needed"
	return "CAMPAIGN OUTLOOK — Outcomes are checked at crisis stage 3 (Day 10).\nOpen Routes: relief %s · Reedwatch %d/2 resilience · arms %d/1 max.\nOrder at the Cistern: Wardens %d/3 · Caravans %d/1 max · arms %d/1 max.\nNo Road Owns the Sky: Caravans %d/2 · Wardens %d/1 max · arms %d/1 max.\nThe Best Margin: %d/220 ashmarks · Reedwatch %d/1 max resilience · arms %d/1 max." % [relief_mark, world.resilience_for("reedwatch"), world.arms_escalation, int(world.reputation.get("wardens", 0)), int(world.reputation.get("caravans", 0)), world.arms_escalation, int(world.reputation.get("caravans", 0)), int(world.reputation.get("wardens", 0)), world.arms_escalation, world.money, world.resilience_for("reedwatch"), world.arms_escalation]

func _set_event(text: String) -> void:
	event_label.text = text

func _refresh_ui() -> void:
	status_label.text = "Day %d   |   %s   |   Ashmarks %d   |   Provisions %d   |   Cargo %d/%d   |   Crisis %d" % [world.day, world.settlement(world.current_settlement).name, world.money, world.provisions, int(world.cargo.get("weight", 0)), world.cargo_capacity, world.crisis_stage]
	var journey_locked := not world.pending_event.is_empty() or arrival_pending
	if departure_travel_actions:
		departure_travel_actions.visible = not journey_locked
	if destination_option:
		destination_option.disabled = journey_locked
	if route_option:
		route_option.disabled = journey_locked
	if cargo_good_option:
		cargo_good_option.disabled = journey_locked
	if cargo_quantity:
		cargo_quantity.editable = not journey_locked
	if shop_status_label:
		var settlement := world.settlement(world.current_settlement)
		var crisis := MarketContent.crisis_stage(world.crisis_stage)
		shop_status_label.text = "%s — %s\nDay %d · Crisis %d: %s\nObjective: %s\n%s" % [String(settlement.get("name", "Unknown settlement")), String(settlement.get("role", "market")), world.day, world.crisis_stage, String(crisis.get("label", "Regional pressure")), String(crisis.get("objective", "Keep trading.")), String(event_label.text if event_label else "Inspect the local need, then load only what your plan can carry.")]
		shop_status_label.text += "\nSettlement resilience: %d/10" % world.resilience_for(world.current_settlement)
		if not world.known_information.is_empty():
			shop_status_label.text += " · Known leads: %d" % world.known_information.size()
		var warden_status := world.faction_status("wardens")
		var caravan_status := world.faction_status("caravans")
		shop_status_label.text += " · Wardens %+d (%s; threshold %+d) · Caravans %+d (%s; threshold %+d)" % [int(world.reputation.get("wardens", 0)), String(warden_status.get("tier", "Unknown")), int(warden_status.get("next_threshold", 0)), int(world.reputation.get("caravans", 0)), String(caravan_status.get("tier", "Unknown")), int(caravan_status.get("next_threshold", 0))]
		var arms_rules := MarketContent.arms_trade_rules()
		var arms_label := String(arms_rules.get("noticed_label", "Noticed traffic")) if world.arms_escalation >= int(arms_rules.get("inspection_threshold", 2)) else String(arms_rules.get("quiet_label", "Quiet manifests"))
		shop_status_label.text += "\nArms escalation: %d/6 — %s" % [world.arms_escalation, arms_label]
		if not world.ending_id.is_empty():
			shop_status_label.text += "\nENDING — %s\n%s" % [String(MarketContent.ending(world.ending_id).get("title", world.ending_id)), world.ending_summary]
	if ending_panel and ending_label:
		ending_panel.visible = not world.ending_id.is_empty()
		if ending_panel.visible:
			var ending := MarketContent.ending(world.ending_id)
			ending_label.text = "CAMPAIGN CONCLUSION\n%s\n%s\n\nThis outcome is recorded in the save. You may continue trading to inspect the resulting region." % [String(ending.get("title", world.ending_id)), world.ending_summary]
	if campaign_outlook_label:
		campaign_outlook_label.text = _campaign_outlook_text()
	if diagnostics_label:
		var last_command := "none"
		if not world.command_history.is_empty():
			var latest: Dictionary = world.command_history.back()
			last_command = "%s (%s)" % [String(latest.get("id", "unknown")), "ok" if bool(latest.get("ok", false)) else "blocked"]
		var build_commit := String(ProjectSettings.get_setting("market_of_ash/build_commit", "development"))
		var build_label := build_commit.substr(0, 8) if build_commit != "development" and build_commit.length() > 8 else build_commit
		diagnostics_label.text = "DIAGNOSTICS — build %s · seed %d · save v%d · content %s · last command %s" % [build_label, world.seed, AshWorldState.SAVE_VERSION, MarketContent.content_version(), last_command]
	if save_status_label:
		save_status_label.text = save_status_text
	if departure_save_status_label:
		departure_save_status_label.text = save_status_text
	if menu_save_status_label:
		menu_save_status_label.text = save_status_text
	if departure_status_label:
		if not world.pending_event.is_empty():
			departure_status_label.text = "ROUTE DECISION — Travel is paused until you choose. Costs already paid remain spent; each option states whether you continue or return."
		elif arrival_pending:
			departure_status_label.text = "ARRIVAL REPORT — %s\n%s\nReview what changed, then enter the settlement to trade again." % [String(world.settlement(world.current_settlement).get("name", "Unknown settlement")), String(event_label.text)]
		else:
			departure_status_label.text = "COMMITMENT CHECK — The map only shows legal corridors. Returning to the shop preserves this plan and spends nothing."
	if enter_settlement_button:
		enter_settlement_button.text = "Enter %s" % String(world.settlement(world.current_settlement).get("name", "settlement"))
	if playtest_banner and playtest_banner.text.is_empty():
		playtest_banner.text = "QUICK PLAYTEST — Guidance is optional; every trade and route remains available."
	_refresh_playtest_status()
	var cargo_lines: Array[String] = []
	for good in MarketContent.good_ids():
		var count := int(world.cargo.get(good, 0))
		if count > 0:
			cargo_lines.append("%s x%d" % [good.capitalize(), count])
	log_label.text = "Cargo: " + (", ".join(cargo_lines) if not cargo_lines.is_empty() else "empty")
	if shop_cargo_label:
		shop_cargo_label.text = "CARAVAN — %d ashmarks · %d provisions · hold %d/%d · %s" % [world.money, world.provisions, int(world.cargo.get("weight", 0)), world.cargo_capacity, log_label.text]
	if event_label.text.is_empty():
		event_label.text = "Choose a destination, buy a small load, and compare the Old Road with the Toll Road."
	_refresh_opportunities()
	_refresh_event_card()
	_refresh_forecasts()
	_link_shop_focus_cycle()
	if map_panel:
		map_panel.world = world
		map_panel.queue_redraw()
	if large_text_checkbox and large_text_checkbox.button_pressed:
		_apply_text_scale(self, 1.25)
	_publish_web_ui_state()

class MapPanel extends Control:
	signal settlement_selected(settlement_id: String)

	const GRID_SIZE := Vector2i(17, 11)
	const BOARD_ORIGIN := Vector2(34, 230)
	const CELL_SIZE := Vector2(44, 20)
	const MAP_HEADER_HEIGHT := 30.0
	const ROUTE_IDS := ["old_road", "toll_road", "dry_cut"]
	const ROUTE_PROFILES := ["cheap / exposed", "safe / expensive", "fast / provision-heavy"]
	const ROUTE_FOOTER_X := [8.0, 235.0, 470.0]
	const SETTLEMENT_CELLS := {
		"ashgate": Vector2i(2, 7),
		"brine_cross": Vector2i(13, 2),
		"cinderford": Vector2i(5, 7),
		"hollow_market": Vector2i(9, 3),
		"reedwatch": Vector2i(13, 8)
	}

	var world
	var travel_route_id: String = ""
	var travel_points: Array[Vector2] = []
	var travel_progress: float = 1.0
	var traveling: bool = false
	var reduce_motion: bool = false
	var text_scale: float = 1.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		if not traveling:
			return
		travel_progress = minf(1.0, travel_progress + delta / 1.8)
		if is_equal_approx(travel_progress, 1.0):
			traveling = false
		queue_redraw()

	func _board_rect() -> Rect2:
		return Rect2(BOARD_ORIGIN, Vector2(GRID_SIZE.x * CELL_SIZE.x, GRID_SIZE.y * CELL_SIZE.y))

	func _cell_rect(cell: Vector2i) -> Rect2:
		return Rect2(BOARD_ORIGIN + Vector2(cell.x * CELL_SIZE.x, cell.y * CELL_SIZE.y), CELL_SIZE)

	func _cell_center(cell: Vector2i) -> Vector2:
		return _cell_rect(cell).get_center()

	func _settlement_point(settlement_id: String) -> Vector2:
		return _cell_center(SETTLEMENT_CELLS.get(settlement_id, Vector2i.ZERO))

	func _settlement_marker_rect(settlement_id: String) -> Rect2:
		var cell: Vector2i = SETTLEMENT_CELLS.get(settlement_id, Vector2i.ZERO)
		return Rect2(_cell_rect(cell).position - Vector2(10, 8), Vector2(CELL_SIZE.x * 2.0 + 38, 40))

	func _settlement_footprint(settlement_id: String) -> Rect2:
		return _settlement_marker_rect(settlement_id).grow_individual(0.0, 10.0, 0.0, 10.0)

	func _route_points(route_id: String) -> Array[Vector2]:
		match route_id:
			"old_road":
				return [_settlement_point("ashgate"), _settlement_point("hollow_market"), _settlement_point("reedwatch")]
			"toll_road":
				return [_settlement_point("ashgate"), _settlement_point("cinderford"), _settlement_point("brine_cross")]
			"dry_cut":
				return [_settlement_point("hollow_market"), _settlement_point("brine_cross"), _settlement_point("reedwatch")]
		return []

	func _route_color(route_id: String) -> Color:
		match route_id:
			"old_road":
				return Color("#c47c52")
			"toll_road":
				return Color("#e6c58d")
			"dry_cut":
				return Color("#7d9ca4")
		return Color("#705746")

	func _route_label(route_id: String) -> String:
		if world != null and world.routes.has(route_id):
			return String(world.routes[route_id].get("name", route_id))
		return route_id.replace("_", " ").capitalize()

	func _map_heading() -> String:
		var crisis_label := String(MarketContent.crisis_stage(world.crisis_stage).get("label", "Regional pressure")) if world != null else "Regional pressure"
		return "FIVE-WELL BASIN — %s — SELECT A SETTLEMENT" % crisis_label.to_upper()

	func _settlement_marker_detail(settlement_id: String) -> String:
		if world == null:
			return "Settlement"
		var location_prefix := "HERE · " if settlement_id == world.current_settlement else ""
		return "%sRES %d/10" % [location_prefix, world.resilience_for(settlement_id)]

	func _font_size(base_size: int) -> int:
		return int(round(float(base_size) * text_scale))

	func _caravan_motion_label() -> String:
		return "MOVING" if traveling else ""

	func _route_footer_rect(route_index: int) -> Rect2:
		var text := "%s: %s" % [_route_label(ROUTE_IDS[route_index]), ROUTE_PROFILES[route_index]]
		var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12))
		return Rect2(BOARD_ORIGIN + Vector2(ROUTE_FOOTER_X[route_index], _board_rect().size.y - text_size.y - 6.0), text_size)

	func _map_heading_rect() -> Rect2:
		var text_size := ThemeDB.fallback_font.get_string_size(_map_heading(), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(16))
		return Rect2(BOARD_ORIGIN + Vector2(8, (MAP_HEADER_HEIGHT - text_size.y) / 2.0), text_size)

	func reset_travel(settlement_id: String) -> void:
		travel_route_id = ""
		travel_points.clear()
		travel_progress = 1.0
		traveling = false
		queue_redraw()

	func begin_travel(route_id: String, origin_id: String, destination_id: String) -> void:
		travel_route_id = route_id
		var origin: Vector2 = _settlement_point(origin_id)
		var destination: Vector2 = _settlement_point(destination_id)
		var route: Array[Vector2] = _route_points(route_id)
		travel_points = [origin]
		if route.size() >= 3:
			var midpoint: Vector2 = route[1]
			if midpoint.distance_to(origin) > 12.0 and midpoint.distance_to(destination) > 12.0:
				travel_points.append(midpoint)
		else:
			travel_points.append(origin.lerp(destination, 0.5) + Vector2(0, -28))
		travel_points.append(destination)
		travel_progress = 1.0 if reduce_motion else 0.0
		traveling = not reduce_motion
		queue_redraw()

	func _polyline_position(points: Array[Vector2], progress: float) -> Vector2:
		if points.is_empty():
			return Vector2.ZERO
		if points.size() == 1:
			return points[0]
		var total_length: float = 0.0
		for index in range(points.size() - 1):
			total_length += points[index].distance_to(points[index + 1])
		if is_zero_approx(total_length):
			return points[0]
		var target_length: float = total_length * clampf(progress, 0.0, 1.0)
		var walked: float = 0.0
		for index in range(points.size() - 1):
			var segment: float = points[index].distance_to(points[index + 1])
			if walked + segment >= target_length:
				return points[index].lerp(points[index + 1], (target_length - walked) / segment)
			walked += segment
		return points.back()

	func _gui_input(event: InputEvent) -> void:
		if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		for settlement_id_value in SETTLEMENT_CELLS.keys():
			var settlement_id := String(settlement_id_value)
			if _settlement_footprint(settlement_id).has_point(event.position):
				settlement_selected.emit(settlement_id)
				accept_event()
				return

	func _draw() -> void:
		var board := _board_rect()
		draw_rect(board.grow(8), Color("#2a211b"), true)
		draw_rect(board, Color("#574437"), true)
		for y in range(GRID_SIZE.y):
			for x in range(GRID_SIZE.x):
				var cell := Vector2i(x, y)
				var fill := Color("#332820") if (x + y) % 2 == 0 else Color("#382c23")
				draw_rect(_cell_rect(cell), fill, true)
				draw_rect(_cell_rect(cell), Color("#5c4838"), false, 1.0)
		draw_rect(Rect2(board.position, Vector2(board.size.x, MAP_HEADER_HEIGHT)), Color("#231b16"), true)
		var heading_rect := _map_heading_rect()
		draw_string(ThemeDB.fallback_font, heading_rect.position + Vector2(0, heading_rect.size.y), _map_heading(), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(16), Color("#e6c58d"))
		for route_id in ROUTE_IDS:
			var route_points: Array[Vector2] = _route_points(route_id)
			if route_points.size() < 2:
				continue
			draw_polyline(PackedVector2Array(route_points), _route_color(route_id), 6.0, true)
			for point_index in range(route_points.size() - 1):
				var midpoint: Vector2 = route_points[point_index].lerp(route_points[point_index + 1], 0.5)
				if route_id == "old_road":
					draw_line(midpoint - Vector2(5, 5), midpoint + Vector2(5, 5), Color("#e09a65"), 2.0)
				elif route_id == "toll_road":
					draw_rect(Rect2(midpoint - Vector2(5, 5), Vector2(10, 10)), Color("#f0dca8"), false, 2.0)
				else:
					draw_circle(midpoint, 4.0, Color("#9fc1c5"))
		draw_rect(Rect2(board.position + Vector2(0, board.size.y - 28), Vector2(board.size.x, 28)), Color("#231b16"), true)
		for route_index in range(ROUTE_IDS.size()):
			draw_string(ThemeDB.fallback_font, BOARD_ORIGIN + Vector2(ROUTE_FOOTER_X[route_index], board.size.y - 10.0), "%s: %s" % [_route_label(ROUTE_IDS[route_index]), ROUTE_PROFILES[route_index]], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12), _route_color(ROUTE_IDS[route_index]))
		for settlement_id_value in SETTLEMENT_CELLS.keys():
			var settlement_id := String(settlement_id_value)
			var footprint := _settlement_marker_rect(settlement_id)
			var is_current: bool = world != null and settlement_id == world.current_settlement
			draw_rect(footprint, Color("#5a4027") if is_current else Color("#3b2b24"), true)
			draw_rect(footprint, Color("#f0d27d") if is_current else (Color("#7d9ca4") if settlement_id == "brine_cross" else Color("#bd8553")), false, 4.0 if is_current else 3.0)
			var name_text: String = String(settlement_id).replace("_", " ").capitalize()
			draw_string(ThemeDB.fallback_font, footprint.position + Vector2(5, 20), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12), Color("#f4e6c7"))
			draw_string(ThemeDB.fallback_font, footprint.position + Vector2(5, 37), _settlement_marker_detail(settlement_id), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(11), Color("#c7b49a"))
		var caravan_position: Vector2 = _settlement_point(world.current_settlement) if world != null else _settlement_point("ashgate")
		if traveling:
			caravan_position = _polyline_position(travel_points, travel_progress)
		draw_circle(caravan_position, 10.0, Color("#17130f"))
		draw_circle(caravan_position, 7.0, Color("#f0d27d"))
		var motion_label := _caravan_motion_label()
		if not motion_label.is_empty():
			draw_string(ThemeDB.fallback_font, caravan_position + Vector2(12, 4), motion_label, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12), Color("#f0d27d"))
