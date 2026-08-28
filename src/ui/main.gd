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
const PLAYTEST_PATH_GUIDED := "guided_trade"
const PLAYTEST_PATH_CONFLICT := "conflict_recovery"
const PLAYTEST_PATH_CAMPAIGN := "contract_crew"
const PLAYTEST_PATH_CONTINUED := "continued_campaign"
const PLAYTEST_PATHS := {
	PLAYTEST_PATH_GUIDED: {
		"label": "Guided Trade",
		"good_id": "water",
		"quantity": 2,
		"destination_id": "reedwatch",
		"route_id": "old_road",
		"banner": "GUIDED TRADE — Learn price, cargo, route, arrival, and sale with the optional Water run.",
		"opening": "Ashgate market is open. Inspect Water, buy 2 when ready, then compare routes to Reedwatch.",
	},
	PLAYTEST_PATH_CONFLICT: {
		"label": "Conflict & Recovery",
		"good_id": "medicine",
		"quantity": 2,
		"destination_id": "brine_cross",
		"route_id": "toll_road",
		"banner": "CONFLICT & RECOVERY — Prepare Medicine for the Toll Road, resolve a caravan confrontation, and review the outcome.",
		"opening": "Ashgate market is open. Buy 2 Medicine, then take the Toll Road to Brine Cross to test conflict choices and recovery.",
	},
	PLAYTEST_PATH_CAMPAIGN: {
		"label": "Contract & Crew",
		"good_id": "water",
		"quantity": 4,
		"destination_id": "reedwatch",
		"route_id": "old_road",
		"banner": "CONTRACT & CREW — Accept the Reedwatch relief work, recruit help if desired, then prepare its four-Water load.",
		"opening": "Ashgate market is open. Review the relief contract and crew offers before buying 4 Water for Reedwatch.",
	},
}
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
var pause_save_button: Button
var pause_load_button: Button
var pause_report_button: Button
var pause_main_menu_button: Button
var pause_summary_label: Label
var focus_before_pause: Control
var start_game_button: Button
var start_conflict_button: Button
var start_campaign_button: Button
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
var shop_title_label: Label
var bazaar_navigation_buttons: Array[Button] = []
var bazaar_outlook_button: Button
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
var recent_conflict_panel: PanelContainer
var recent_conflict_label: Label
var ending_panel: PanelContainer
var ending_label: Label
var plan_departure_button: Button
var departure_travel_actions: HBoxContainer
var return_to_shop_button: Button
var commit_departure_button: Button
var continue_journey_button: Button
var enter_settlement_button: Button
var departure_load_label: Label
var departure_contract_label: Label
var departure_status_label: Label
var departure_planning_panel: VBoxContainer
var event_card: PanelContainer
var event_mode_label: Label
var event_title_label: Label
var event_setup_label: Label
var event_stakes_label: Label
var event_readiness_label: Label
var event_choice_list: VBoxContainer
var event_choice_buttons: Array[Button] = []
var event_choice_reason_labels: Array[Label] = []
var conflict_outcome_panel: PanelContainer
var conflict_outcome_label: Label
var last_conflict_outcome_text := ""
var committed_journey_message := ""
var arrival_pending := false
var guided_test_button: Button
var playtest_banner: Label
var playtest_status_label: Label
var status_label: Label
var caravan_context_label: Label
var map_hint: Label
var event_scroll: ScrollContainer
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
var active_playtest_path_id := ""
var pending_new_game_path_id := PLAYTEST_PATH_GUIDED
var last_input_device := "unknown"
var map_panel
var web_accessibility_callback: Variant
var web_accessibility_control_callback: Variant
var web_accessibility_key_callback: Variant

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
	_setup_web_accessibility_bridge()
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
	preset.text = "QUICK PLAYTEST PATHS\nEvery path begins the same canonical Ashgate campaign. Paths only change the opening selections and guidance; every action still uses the normal game rules."
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
	reduce_motion_checkbox.custom_minimum_size = Vector2(0, 44)
	reduce_motion_checkbox.tooltip_text = "Show the caravan at its destination immediately; route outcomes and timing are unchanged."
	reduce_motion_checkbox.button_pressed = reduce_motion_enabled
	reduce_motion_checkbox.toggled.connect(_on_reduce_motion_toggled)
	content.add_child(reduce_motion_checkbox)
	large_text_checkbox = CheckBox.new()
	large_text_checkbox.text = "Large text"
	large_text_checkbox.custom_minimum_size = Vector2(0, 44)
	large_text_checkbox.tooltip_text = "Increase interface text by 25%. Long shop and route panels remain scrollable."
	large_text_checkbox.button_pressed = large_text_enabled
	large_text_checkbox.toggled.connect(_on_large_text_toggled)
	content.add_child(large_text_checkbox)
	interface_sounds_checkbox = CheckBox.new()
	interface_sounds_checkbox.text = "Interface sounds"
	interface_sounds_checkbox.custom_minimum_size = Vector2(0, 44)
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
		binding_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		binding_button.custom_minimum_size = Vector2(0, 72)
		binding_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		binding_button.tooltip_text = "Change the keyboard or controller binding for %s." % String(ACTION_LABELS.get(action_name, action_name))
		binding_button.set_meta("web_accessibility_id", "rebind_%s" % action_name)
		binding_button.pressed.connect(_on_rebind_pressed.bind(action_name))
		binding_row.add_child(binding_button)
		binding_buttons[action_name] = binding_button
	restore_bindings_button = Button.new()
	restore_bindings_button.text = "Restore default inputs"
	restore_bindings_button.custom_minimum_size = Vector2(0, 44)
	restore_bindings_button.tooltip_text = "Restore the default keyboard and controller bindings for Accept, Back, and Pause."
	restore_bindings_button.set_meta("web_accessibility_id", "restore_default_bindings")
	restore_bindings_button.pressed.connect(_on_restore_default_bindings)
	content.add_child(restore_bindings_button)
	binding_status_label = Label.new()
	binding_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	binding_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_status_label.add_theme_font_size_override("font_size", 11)
	binding_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	content.add_child(binding_status_label)
	start_game_button = Button.new()
	start_game_button.text = "Start Guided Trade — Water to Reedwatch"
	start_game_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_game_button.custom_minimum_size = Vector2(0, 56)
	start_game_button.tooltip_text = "Start the canonical campaign with the two-Water teaching trade selected."
	start_game_button.pressed.connect(_on_start_game_requested.bind(PLAYTEST_PATH_GUIDED))
	content.add_child(start_game_button)
	start_conflict_button = Button.new()
	start_conflict_button.text = "Start Conflict & Recovery — Medicine on the Toll Road"
	start_conflict_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_conflict_button.custom_minimum_size = Vector2(0, 56)
	start_conflict_button.tooltip_text = "Start the same campaign with a deterministic Gatekeeper conflict route selected."
	start_conflict_button.pressed.connect(_on_start_game_requested.bind(PLAYTEST_PATH_CONFLICT))
	content.add_child(start_conflict_button)
	start_campaign_button = Button.new()
	start_campaign_button.text = "Start Contract & Crew — Reedwatch Relief"
	start_campaign_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_campaign_button.custom_minimum_size = Vector2(0, 56)
	start_campaign_button.tooltip_text = "Start the same campaign with the relief-contract load selected and local crew offers visible."
	start_campaign_button.pressed.connect(_on_start_game_requested.bind(PLAYTEST_PATH_CAMPAIGN))
	content.add_child(start_campaign_button)
	continue_game_button = Button.new()
	continue_game_button.text = "Continue saved game"
	continue_game_button.custom_minimum_size = Vector2(0, 44)
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
	quit_button.custom_minimum_size = Vector2(0, 44)
	quit_button.tooltip_text = "Close the desktop build. Browser builds use the browser tab instead."
	quit_button.visible = not OS.has_feature("web")
	quit_button.pressed.connect(_on_quit_pressed)
	content.add_child(quit_button)
	content.move_child(start_game_button, 4)
	content.move_child(start_conflict_button, 5)
	content.move_child(start_campaign_button, 6)
	content.move_child(continue_game_button, 7)
	content.move_child(menu_save_status_label, 8)
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
	pause_save_button = Button.new()
	pause_save_button.text = "Save campaign"
	pause_save_button.custom_minimum_size = Vector2(0, 44)
	pause_save_button.pressed.connect(_on_save_pressed)
	content.add_child(pause_save_button)
	pause_load_button = Button.new()
	pause_load_button.text = "Load saved campaign"
	pause_load_button.custom_minimum_size = Vector2(0, 44)
	pause_load_button.pressed.connect(_on_pause_load_pressed)
	content.add_child(pause_load_button)
	pause_report_button = Button.new()
	pause_report_button.text = "Export playtest report"
	pause_report_button.custom_minimum_size = Vector2(0, 44)
	pause_report_button.tooltip_text = "Download or write build, seed, campaign summary, command history, and game log without personal data."
	pause_report_button.pressed.connect(_on_export_report_pressed)
	content.add_child(pause_report_button)
	pause_main_menu_button = Button.new()
	pause_main_menu_button.text = "Return to main menu"
	pause_main_menu_button.custom_minimum_size = Vector2(0, 44)
	pause_main_menu_button.pressed.connect(_on_pause_main_menu_pressed)
	content.add_child(pause_main_menu_button)
	_link_focus_cycle([pause_resume_button, pause_save_button, pause_load_button, pause_report_button, pause_main_menu_button])

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
	_queue_web_ui_state_after_layout()

func _refresh_start_button_labels(requires_confirmation: bool) -> void:
	var prefix := "New" if requires_confirmation else "Start"
	var confirmation_note := " Existing campaign files remain until the new run's first successful autosave." if requires_confirmation else ""
	if start_game_button:
		start_game_button.text = "%s Guided Trade — Water to Reedwatch" % prefix
		start_game_button.tooltip_text = "Begin the canonical campaign with the two-Water teaching trade selected.%s" % confirmation_note
	if start_conflict_button:
		start_conflict_button.text = "%s Conflict & Recovery — Medicine on the Toll Road" % prefix
		start_conflict_button.tooltip_text = "Begin the same campaign with a deterministic Gatekeeper conflict route selected.%s" % confirmation_note
	if start_campaign_button:
		start_campaign_button.text = "%s Contract & Crew — Reedwatch Relief" % prefix
		start_campaign_button.tooltip_text = "Begin the same campaign with the relief-contract load selected and local crew offers visible.%s" % confirmation_note

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
		var existing_files := FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path)
		_refresh_start_button_labels(existing_files)
		continue_game_button.tooltip_text = "No valid saved campaign is available."
		if FileAccess.file_exists(save_path) or FileAccess.file_exists(backup_path):
			save_status_text = "SAVE — Existing files could not be validated. New campaign paths remain available with confirmation."
		if menu_save_status_label:
			menu_save_status_label.text = save_status_text
		_link_main_menu_focus_cycle()
		return
	var saved_world: AshWorldState = preview.world
	var source_text := "backup" if backup_preview else "primary"
	_refresh_start_button_labels(true)
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
	last_conflict_outcome_text = ""
	committed_journey_message = ""
	if map_panel:
		map_panel.reset_travel(world.current_settlement)
	if conflict_outcome_panel:
		conflict_outcome_panel.visible = false
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
	enter_settlement_button.visible = arrival_pending and map_panel != null and map_panel.travel_phase == "arrived"
	_refresh_ui()
	_request_map_layout_update()
	if not world.pending_event.is_empty():
		_grab_first_enabled(event_choice_buttons)
	elif arrival_pending:
		_grab_focus_if_available(enter_settlement_button)
	else:
		_grab_focus_if_available(destination_option)

func _update_map_layout() -> void:
	if map_panel == null or map_hint == null or event_label == null or game_layer == null or not game_layer.visible:
		return
	map_panel.fit_vertical_space(
		map_hint.get_global_rect().end.y + 18.0,
		event_scroll.get_global_rect().position.y - 16.0,
		event_scroll.get_global_rect().size.x
	)

func _request_map_layout_update() -> void:
	if not get_tree().process_frame.is_connected(_update_map_layout):
		get_tree().process_frame.connect(_update_map_layout, CONNECT_ONE_SHOT)

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
		map_panel.set_text_scale(1.25 if enabled else 1.0)
	_request_map_layout_update()
	_save_presentation_settings()
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()
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
	call_deferred("_queue_web_ui_state_after_layout")

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

func _input_bindings_report() -> Dictionary:
	var report: Dictionary = {}
	for action_name in REMAPPABLE_ACTIONS:
		report[action_name] = {
			"keyboard_codes": _keyboard_binding_codes(action_name),
			"keyboard_label": _keyboard_binding_text(action_name),
			"controller_buttons": _controller_binding_codes(action_name),
			"controller_label": _controller_binding_text(action_name),
		}
	return report

func _refresh_binding_labels() -> void:
	for action_name in REMAPPABLE_ACTIONS:
		var button: Button = binding_buttons.get(action_name)
		if button:
			button.text = "Press a key or controller button…" if remapping_action == action_name else "%s: %s · Pad %s" % [String(ACTION_LABELS.get(action_name, action_name)), _keyboard_binding_text(action_name), _controller_binding_text(action_name)]
	if controls_hint_label:
		controls_hint_label.text = "Controls: arrows/Tab or controller D-pad/stick move focus; Left/Right changes quantity. Accept: %s / %s. Back: %s / %s. Pause: %s / %s." % [_keyboard_binding_text("ui_accept"), _controller_binding_text("ui_accept"), _keyboard_binding_text("ui_cancel"), _controller_binding_text("ui_cancel"), _keyboard_binding_text("ui_pause"), _controller_binding_text("ui_pause")]
	if menu_layer != null:
		_publish_web_ui_state()

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

func _save_presentation_settings() -> bool:
	if not settings_persistence_enabled:
		return true
	var config := ConfigFile.new()
	config.set_value("accessibility", "large_text", large_text_enabled)
	config.set_value("accessibility", "reduce_motion", reduce_motion_enabled)
	config.set_value("audio", "interface_sounds", interface_sounds_enabled)
	for action_name in REMAPPABLE_ACTIONS:
		config.set_value("input", action_name, _keyboard_binding_codes(action_name))
		config.set_value("input", "%s_joypad" % action_name, _controller_binding_codes(action_name))
	var save_error := config.save(settings_path)
	if save_error != OK:
		if binding_status_label:
			binding_status_label.text = "SETTINGS WARNING — This change is active for the current session but could not be saved."
		return false
	return true

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
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(columns)

	var market_card := PanelContainer.new()
	market_card.custom_minimum_size = Vector2(690, 0)
	market_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market_card.size_flags_stretch_ratio = 1.8
	columns.add_child(market_card)
	var market_shell := VBoxContainer.new()
	market_shell.add_theme_constant_override("separation", 10)
	market_card.add_child(market_shell)
	shop_title_label = Label.new()
	shop_title_label.text = "SETTLEMENT BAZAAR"
	shop_title_label.add_theme_font_size_override("font_size", 30)
	shop_title_label.add_theme_color_override("font_color", Color("#e6c58d"))
	market_shell.add_child(shop_title_label)
	var bazaar_prompt := Label.new()
	bazaar_prompt.text = "Choose a stall, then return here after each road."
	bazaar_prompt.add_theme_color_override("font_color", Color("#b5a18b"))
	market_shell.add_child(bazaar_prompt)
	var bazaar_navigation := HBoxContainer.new()
	bazaar_navigation.add_theme_constant_override("separation", 8)
	market_shell.add_child(bazaar_navigation)
	for entry in [
		{"id": "trade", "label": "Market Stall"},
		{"id": "assignments", "label": "Job Board"},
		{"id": "information", "label": "Guide / Intel"},
		{"id": "crew", "label": "Crew Yard"},
		{"id": "outlook", "label": "Town Outlook"},
	]:
		var bazaar_button := Button.new()
		bazaar_button.text = String(entry.label)
		bazaar_button.custom_minimum_size = Vector2(0, 46)
		bazaar_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bazaar_button.set_meta("web_accessibility_id", "bazaar_%s" % String(entry.id))
		bazaar_button.pressed.connect(_on_bazaar_navigation_pressed.bind(String(entry.id)))
		bazaar_navigation.add_child(bazaar_button)
		bazaar_navigation_buttons.append(bazaar_button)
	var market_scroll := ScrollContainer.new()
	market_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	market_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	market_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_shell.add_child(market_scroll)
	var market := VBoxContainer.new()
	market.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market.add_theme_constant_override("separation", 14)
	market_scroll.add_child(market)
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
	shop_good_option.custom_minimum_size = Vector2(0, 44)
	shop_good_option.tooltip_text = "Choose which cargo to price, buy, or sell at this settlement."
	for good_id in MarketContent.good_ids():
		shop_good_option.add_item(good_id.capitalize())
		shop_good_option.set_item_metadata(shop_good_option.item_count - 1, good_id)
	market.add_child(_labeled_control("Cargo", shop_good_option))
	shop_quantity = SpinBox.new()
	shop_quantity.custom_minimum_size = Vector2(0, 44)
	shop_quantity.min_value = 1
	shop_quantity.max_value = 12
	shop_quantity.step = 1
	shop_quantity.value = PLAYTEST_QUANTITY
	shop_quantity.tooltip_text = "Controller: Left/Right changes quantity."
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
	guided_test_button.set_meta("web_accessibility_id", "guided_trade")
	guided_test_button.pressed.connect(_on_guided_test_action)
	market_shell.add_child(guided_test_button)
	shop_good_option.item_selected.connect(_on_shop_plan_changed)
	shop_quantity.value_changed.connect(_on_shop_quantity_changed)

	var action_card := PanelContainer.new()
	action_card.name = "ShopActionCard"
	action_card.custom_minimum_size = Vector2(360, 0)
	action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_card.size_flags_stretch_ratio = 1.0
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
	caravan_title.text = "BAZAAR STALLS"
	caravan_title.add_theme_font_size_override("font_size", 20)
	caravan_title.add_theme_color_override("font_color", Color("#e6c58d"))
	actions.add_child(caravan_title)
	campaign_outlook_label = Label.new()
	campaign_outlook_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_outlook_label.add_theme_font_size_override("font_size", 12)
	campaign_outlook_label.add_theme_color_override("font_color", Color("#d9c6a2"))
	campaign_outlook_label.visible = false
	actions.add_child(campaign_outlook_label)
	bazaar_outlook_button = Button.new()
	bazaar_outlook_button.text = "Show regional outlook"
	bazaar_outlook_button.custom_minimum_size = Vector2(0, 42)
	bazaar_outlook_button.pressed.connect(_on_bazaar_outlook_pressed)
	actions.add_child(bazaar_outlook_button)
	recent_conflict_panel = PanelContainer.new()
	recent_conflict_panel.name = "RecentConflictPanel"
	recent_conflict_panel.visible = false
	actions.add_child(recent_conflict_panel)
	recent_conflict_label = Label.new()
	recent_conflict_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recent_conflict_label.add_theme_font_size_override("font_size", 12)
	recent_conflict_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	recent_conflict_panel.add_child(recent_conflict_label)
	ending_panel = PanelContainer.new()
	ending_panel.visible = false
	actions.add_child(ending_panel)
	ending_label = Label.new()
	ending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_label.add_theme_font_size_override("font_size", 16)
	ending_label.add_theme_color_override("font_color", Color("#e6c58d"))
	ending_panel.add_child(ending_label)
	var opportunity_title := Label.new()
	opportunity_title.text = "LOCAL STALLS & OPPORTUNITIES"
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
	shop_save_button.custom_minimum_size = Vector2(0, 44)
	shop_save_button.set_meta("web_accessibility_id", "shop_save")
	shop_save_button.pressed.connect(_on_save_pressed)
	actions.add_child(shop_save_button)
	shop_load_button = Button.new()
	shop_load_button.text = "Load saved state"
	shop_load_button.custom_minimum_size = Vector2(0, 44)
	shop_load_button.tooltip_text = "Validate and load the saved campaign. A malformed or newer save leaves the current run unchanged."
	shop_load_button.set_meta("web_accessibility_id", "shop_load")
	shop_load_button.pressed.connect(_on_load_pressed)
	actions.add_child(shop_load_button)
	save_status_label = Label.new()
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.add_theme_font_size_override("font_size", 11)
	save_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	actions.add_child(save_status_label)
	shop_reset_button = Button.new()
	shop_reset_button.text = "Reset run"
	shop_reset_button.custom_minimum_size = Vector2(0, 44)
	shop_reset_button.set_meta("web_accessibility_id", "shop_reset")
	shop_reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(shop_reset_button)
	shop_report_button = Button.new()
	shop_report_button.text = "Export playtest report"
	shop_report_button.custom_minimum_size = Vector2(0, 44)
	shop_report_button.tooltip_text = "Download or write build, seed, campaign summary, command history, and game log without personal data."
	shop_report_button.set_meta("web_accessibility_id", "shop_report")
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
	map_panel.set_text_scale(1.25 if large_text_enabled else 1.0)
	map_panel.settlement_selected.connect(_on_map_settlement_selected)
	map_panel.travel_state_changed.connect(_on_map_travel_state_changed)
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
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(columns)

	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(700, 0)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.7
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

	map_hint = Label.new()
	map_hint.name = "MapHint"
	map_hint.text = "Choose a settlement. HERE = current location; RES = resilience."
	map_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_hint.add_theme_color_override("font_color", Color("#c7b49a"))
	left.add_child(map_hint)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 230)
	left.add_child(spacer)

	event_scroll = ScrollContainer.new()
	event_scroll.name = "JourneyResultScroll"
	event_scroll.custom_minimum_size = Vector2(660, 76)
	event_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	event_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	left.add_child(event_scroll)
	event_label = Label.new()
	event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_label.custom_minimum_size = Vector2(660, 0)
	event_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	event_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	event_scroll.add_child(event_label)

	log_label = Label.new()
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_color_override("font_color", Color("#aa9a87"))
	left.add_child(log_label)

	var right := PanelContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	columns.add_child(right)
	var controls_shell := VBoxContainer.new()
	controls_shell.add_theme_constant_override("separation", 10)
	right.add_child(controls_shell)
	var control_title := Label.new()
	control_title.text = "DEPARTURE DESK"
	control_title.add_theme_font_size_override("font_size", 20)
	control_title.add_theme_color_override("font_color", Color("#e6c58d"))
	controls_shell.add_child(control_title)
	var caravan_status_title := Label.new()
	caravan_status_title.text = "CARAVAN STATUS"
	caravan_status_title.add_theme_font_size_override("font_size", 13)
	caravan_status_title.add_theme_color_override("font_color", Color("#d08b62"))
	controls_shell.add_child(caravan_status_title)
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	controls_shell.add_child(status_label)
	caravan_context_label = Label.new()
	caravan_context_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caravan_context_label.add_theme_font_size_override("font_size", 13)
	caravan_context_label.add_theme_color_override("font_color", Color("#d08b62"))
	controls_shell.add_child(caravan_context_label)
	controls_shell.add_child(HSeparator.new())
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
	departure_planning_panel = VBoxContainer.new()
	departure_planning_panel.add_theme_constant_override("separation", 10)
	controls.add_child(departure_planning_panel)

	destination_option = OptionButton.new()
	destination_option.custom_minimum_size = Vector2(0, 44)
	destination_option.tooltip_text = "Choose a connected settlement for the next journey."
	_populate_destination_options()
	departure_planning_panel.add_child(_labeled_control("Destination", destination_option))

	route_option = OptionButton.new()
	route_option.custom_minimum_size = Vector2(0, 44)
	route_option.tooltip_text = "Choose one legal route to the selected destination."
	_populate_route_options()
	departure_planning_panel.add_child(_labeled_control("Route", route_option))

	cargo_good_option = OptionButton.new()
	cargo_good_option.custom_minimum_size = Vector2(0, 44)
	cargo_good_option.tooltip_text = "Choose the cargo used by the route forecast."
	for good in MarketContent.good_ids():
		cargo_good_option.add_item(good.capitalize())
		cargo_good_option.set_item_metadata(cargo_good_option.item_count - 1, good)
	departure_planning_panel.add_child(_labeled_control("Forecast cargo", cargo_good_option))

	cargo_quantity = SpinBox.new()
	cargo_quantity.custom_minimum_size = Vector2(0, 44)
	cargo_quantity.min_value = 1
	cargo_quantity.max_value = 12
	cargo_quantity.step = 1
	cargo_quantity.value = PLAYTEST_QUANTITY
	cargo_quantity.tooltip_text = "Controller: Left/Right changes forecast quantity."
	departure_planning_panel.add_child(_labeled_control("Forecast quantity", cargo_quantity))

	departure_load_label = Label.new()
	departure_load_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_load_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	departure_planning_panel.add_child(departure_load_label)
	departure_contract_label = Label.new()
	departure_contract_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_contract_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	departure_planning_panel.add_child(departure_contract_label)

	market_preview_label = _forecast_label()
	market_preview_label.visible = false
	departure_planning_panel.add_child(market_preview_label)
	route_preview_label = _forecast_label()
	departure_planning_panel.add_child(route_preview_label)

	event_card = PanelContainer.new()
	event_card.visible = false
	controls.add_child(event_card)
	var event_content := VBoxContainer.new()
	event_content.add_theme_constant_override("separation", 8)
	event_card.add_child(event_content)
	event_mode_label = Label.new()
	event_mode_label.text = "CARAVAN CONFLICT SIMULATION"
	event_mode_label.add_theme_font_size_override("font_size", 12)
	event_mode_label.add_theme_color_override("font_color", Color("#d08b62"))
	event_content.add_child(event_mode_label)
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
	event_readiness_label = Label.new()
	event_readiness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_readiness_label.add_theme_font_size_override("font_size", 12)
	event_readiness_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	event_content.add_child(event_readiness_label)
	event_choice_list = VBoxContainer.new()
	event_choice_list.add_theme_constant_override("separation", 10)
	event_content.add_child(event_choice_list)
	conflict_outcome_panel = PanelContainer.new()
	conflict_outcome_panel.visible = false
	controls.add_child(conflict_outcome_panel)
	conflict_outcome_label = Label.new()
	conflict_outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conflict_outcome_label.add_theme_font_size_override("font_size", 13)
	conflict_outcome_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	conflict_outcome_panel.add_child(conflict_outcome_label)

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

	continue_journey_button = Button.new()
	continue_journey_button.text = "Continue along the road"
	continue_journey_button.custom_minimum_size = Vector2(0, 52)
	continue_journey_button.tooltip_text = "Leave the road view and continue to the next encounter or arrival."
	continue_journey_button.set_meta("web_accessibility_id", "continue_journey")
	continue_journey_button.pressed.connect(_on_continue_journey_pressed)
	continue_journey_button.visible = false
	controls_shell.add_child(continue_journey_button)

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
	save_button.custom_minimum_size = Vector2(0, 44)
	save_button.pressed.connect(_on_save_pressed)
	controls.add_child(save_button)
	var load_button := Button.new()
	load_button.text = "Load saved state"
	load_button.custom_minimum_size = Vector2(0, 44)
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

func _on_bazaar_navigation_pressed(section_id: String) -> void:
	var target: Control
	match section_id:
		"trade":
			target = shop_good_option
		"assignments":
			target = contract_buttons[0] if not contract_buttons.is_empty() else null
		"information":
			target = opportunity_buttons[0] if not opportunity_buttons.is_empty() else null
		"crew":
			target = crew_buttons[0] if not crew_buttons.is_empty() else null
		"outlook":
			_on_bazaar_outlook_pressed()
			return
	if target != null and _grab_focus_if_available(target):
		_ensure_focused_control_visible()
		shop_transaction_status_label.text = "BAZAAR — %s is ready." % section_id.replace("_", " ").capitalize()
	else:
		shop_transaction_status_label.text = "BAZAAR — No %s option is available at this settlement today." % section_id.replace("_", " ")
	_publish_web_ui_state()

func _on_bazaar_outlook_pressed() -> void:
	campaign_outlook_label.visible = not campaign_outlook_label.visible
	bazaar_outlook_button.text = "Hide regional outlook" if campaign_outlook_label.visible else "Show regional outlook"
	shop_transaction_status_label.text = "BAZAAR — Regional outlook %s." % ("opened" if campaign_outlook_label.visible else "closed")
	_link_shop_focus_cycle()
	_publish_web_ui_state()

func _link_main_menu_focus_cycle() -> void:
	if start_game_button == null or continue_game_button == null:
		return
	var controls: Array = [start_game_button, start_conflict_button, start_campaign_button]
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
		control.focus_neighbor_bottom = control.get_path_to(next_control)
		control.focus_neighbor_top = control.get_path_to(previous_control)

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

func _playtest_path(path_id: String) -> Dictionary:
	return Dictionary(PLAYTEST_PATHS.get(path_id, PLAYTEST_PATHS[PLAYTEST_PATH_GUIDED]))

func _playtest_path_label(path_id: String) -> String:
	if path_id == PLAYTEST_PATH_CONTINUED:
		return "Continued campaign"
	if PLAYTEST_PATHS.has(path_id):
		return String(PLAYTEST_PATHS[path_id].get("label", path_id))
	return "Not selected"

func _apply_playtest_path_defaults(path_id: String) -> void:
	var path := _playtest_path(path_id)
	active_playtest_path_id = String(path.get("id", path_id))
	if not PLAYTEST_PATHS.has(active_playtest_path_id):
		active_playtest_path_id = PLAYTEST_PATH_GUIDED
		path = _playtest_path(active_playtest_path_id)
	var destination_id := String(path.get("destination_id", PLAYTEST_DESTINATION))
	var route_id := String(path.get("route_id", PLAYTEST_ROUTE))
	var good_id := String(path.get("good_id", PLAYTEST_GOOD))
	var quantity := int(path.get("quantity", PLAYTEST_QUANTITY))
	_select_option_by_id(destination_option, destination_id)
	_populate_route_options()
	_select_option_by_id(route_option, route_id)
	_select_option_by_id(cargo_good_option, good_id)
	_select_option_by_id(shop_good_option, good_id)
	cargo_quantity.value = quantity
	shop_quantity.value = quantity
	playtest_banner.text = String(path.get("banner", "QUICK PLAYTEST — Guidance is optional; every trade and route remains available."))
	_set_event(String(path.get("opening", "Ashgate market is open. Inspect local prices, load cargo, then plan a route when you are ready.")))

func _on_start_game_pressed(path_id: String = PLAYTEST_PATH_GUIDED) -> void:
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
	_populate_route_options()
	_apply_playtest_path_defaults(path_id)
	guided_test_button.disabled = false
	arrival_pending = false
	enter_settlement_button.visible = false
	commit_departure_button.disabled = false
	return_to_shop_button.disabled = false
	_show_shop()

func _on_start_game_requested(path_id: String = PLAYTEST_PATH_GUIDED) -> void:
	pending_new_game_path_id = path_id if PLAYTEST_PATHS.has(path_id) else PLAYTEST_PATH_GUIDED
	var save_files_exist := FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path + ".bak")
	if not save_files_exist:
		_on_start_game_pressed(pending_new_game_path_id)
		return
	if new_game_confirmation_dialog == null:
		new_game_confirmation_dialog = ConfirmationDialog.new()
		new_game_confirmation_dialog.title = "Start a new campaign?"
		new_game_confirmation_dialog.dialog_text = "Campaign save files already exist. They remain untouched until the new run's first successful autosave, which may replace them."
		new_game_confirmation_dialog.ok_button_text = "Start new campaign"
		new_game_confirmation_dialog.cancel_button_text = "Keep saved campaign"
		new_game_confirmation_dialog.confirmed.connect(_on_confirm_start_game)
		new_game_confirmation_dialog.canceled.connect(_on_confirmation_closed)
		add_child(new_game_confirmation_dialog)
	new_game_confirmation_dialog.popup_centered(Vector2i(560, 190))
	_configure_confirmation_targets(new_game_confirmation_dialog)
	call_deferred("_configure_confirmation_targets", new_game_confirmation_dialog)
	new_game_confirmation_dialog.get_cancel_button().call_deferred("grab_focus")
	call_deferred("_publish_web_ui_state")

func _on_confirm_start_game() -> void:
	_on_start_game_pressed(pending_new_game_path_id)

func _configure_confirmation_targets(dialog: ConfirmationDialog) -> void:
	if dialog == null or not is_instance_valid(dialog):
		return
	dialog.get_ok_button().custom_minimum_size = Vector2(0, 44)
	dialog.get_cancel_button().custom_minimum_size = Vector2(0, 44)
	dialog.get_ok_button().add_theme_font_size_override("font_size", 28)
	dialog.get_cancel_button().add_theme_font_size_override("font_size", 28)

func _on_confirmation_closed() -> void:
	call_deferred("_publish_web_ui_state")

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
		if event is InputEventJoypadButton and event.pressed and remapping_action.is_empty() and _adjust_focused_quantity(event.button_index):
			get_viewport().set_input_as_handled()
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

func _adjust_focused_quantity(button_index: int) -> bool:
	var direction := -1 if button_index == JOY_BUTTON_DPAD_LEFT else 1 if button_index == JOY_BUTTON_DPAD_RIGHT else 0
	if direction == 0:
		return false
	var focused := get_viewport().gui_get_focus_owner()
	for quantity_control in [shop_quantity, cargo_quantity]:
		if quantity_control != null and quantity_control.editable and focused == quantity_control.get_line_edit():
			quantity_control.value += direction * quantity_control.step
			return true
	return false

func _open_pause() -> void:
	if pause_layer == null or menu_layer.visible:
		return
	focus_before_pause = get_viewport().gui_get_focus_owner()
	_refresh_pause_summary()
	pause_layer.visible = true
	get_tree().paused = true
	pause_resume_button.grab_focus()
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _refresh_pause_summary(feedback_text: String = "") -> void:
	if pause_summary_label == null:
		return
	var detail := feedback_text if not feedback_text.is_empty() else save_status_text
	pause_summary_label.text = "Day %d · %s · %d ashmarks · hold %d/%d\n%s" % [world.day, String(world.settlement(world.current_settlement).get("name", world.current_settlement)), world.money, int(world.cargo.get("weight", 0)), world.cargo_capacity, detail]

func _close_pause() -> void:
	get_tree().paused = false
	pause_layer.visible = false
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()
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
		"report_version": 6,
		"game_version": String(ProjectSettings.get_setting("application/config/version", "unknown")),
		"content_version": MarketContent.content_version(),
		"save_version": AshWorldState.SAVE_VERSION,
		"build_commit": String(ProjectSettings.get_setting("market_of_ash/build_commit", "development")),
		"build_run": String(ProjectSettings.get_setting("market_of_ash/build_run", "local")),
		"platform": OS.get_name(),
		"input_device": last_input_device,
		"input_bindings": _input_bindings_report(),
		"viewport": {"width": int(viewport_size.x), "height": int(viewport_size.y)},
		"display_scale": _report_display_scale(),
		"presentation": {"large_text": large_text_enabled, "reduced_motion": reduce_motion_enabled, "interface_sounds": interface_sounds_enabled},
		"session_elapsed_seconds": maxf(0.0, float(Time.get_ticks_msec() - run_started_msec) / 1000.0),
		"time_to_first_trade_seconds": null if first_trade_elapsed_msec < 0 else float(first_trade_elapsed_msec) / 1000.0,
		"playtest_path_id": active_playtest_path_id,
		"playtest_path_label": _playtest_path_label(active_playtest_path_id),
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
		_set_event("REPORT DOWNLOAD REQUESTED — %s\nIf the browser asks, allow the download. Build, entry path, platform, viewport, input mappings, presentation settings, timing, seed, and campaign evidence are included. No personal data is included." % WEB_REPORT_FILENAME)
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
			_set_event("REPORT EXPORTED — %s\nBuild, entry path, platform, viewport, input mappings, presentation settings, timing, seed, and campaign evidence are included. No personal data is included." % ProjectSettings.globalize_path(report_path))
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
	if new_game_confirmation_dialog != null and new_game_confirmation_dialog.visible:
		return "new_game_confirmation"
	if reset_confirmation_dialog != null and reset_confirmation_dialog.visible:
		return "reset_confirmation"
	if pause_layer != null and pause_layer.visible:
		return "pause"
	if menu_layer != null and menu_layer.visible:
		return "main_menu"
	if shop_layer != null and shop_layer.visible:
		return "settlement_shop"
	if game_layer != null and game_layer.visible:
		if map_panel != null and map_panel.travel_phase in ["moving_out", "road", "moving_in"]:
			return "route_travel"
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
	var state_json := JSON.stringify(_web_ui_state())
	var script := """
(function(state) {
	window.marketOfAshUiState = state;
	const hiddenStyle = 'position:absolute;left:-10000px;top:0;width:1px;height:1px;overflow:hidden;';
	let region = document.getElementById('market-of-ash-status');
	if (!region) {
		region = document.createElement('div');
		region.id = 'market-of-ash-status';
		region.setAttribute('role', 'status');
		region.setAttribute('aria-live', 'polite');
		region.setAttribute('aria-atomic', 'true');
		region.style.cssText = hiddenStyle;
		document.body.appendChild(region);
	}
	if (region.textContent !== state.announcement) {
		region.textContent = state.announcement;
	}
	let controlsRegion = document.getElementById('market-of-ash-actions');
	if (!controlsRegion) {
		controlsRegion = document.createElement('section');
		controlsRegion.id = 'market-of-ash-actions';
		controlsRegion.setAttribute('role', 'region');
		controlsRegion.setAttribute('aria-label', 'Available game controls');
		controlsRegion.style.cssText = hiddenStyle;
		controlsRegion.addEventListener('focusin', function() {
			controlsRegion.style.cssText = 'position:fixed;left:8px;top:8px;width:360px;max-height:calc(100vh - 16px);overflow:auto;padding:12px;background:#17130f;color:#f4d69a;border:2px solid #f4d69a;z-index:2147483647;';
		});
		controlsRegion.addEventListener('focusout', function() {
			setTimeout(function() {
				if (!controlsRegion.contains(document.activeElement)) {
					controlsRegion.style.cssText = hiddenStyle;
				}
			}, 0);
		});
		controlsRegion.addEventListener('keydown', function(event) {
			const currentState = window.marketOfAshUiState || {};
			if (!currentState.remapping_action) {
				return;
			}
			event.preventDefault();
			event.stopPropagation();
			const modifierOnly = ['Alt', 'Control', 'Meta', 'Shift'].includes(event.key);
			if (!event.repeat && !modifierOnly && typeof window.marketOfAshAccessibilityKey === 'function') {
				window.marketOfAshAccessibilityKey(
					event.key,
					event.code,
					event.altKey,
					event.ctrlKey,
					event.metaKey,
					event.shiftKey
				);
			}
		}, true);
		document.body.appendChild(controlsRegion);
	}
	const focusedControlId = document.activeElement && document.activeElement.dataset
		? document.activeElement.dataset.control || ''
		: '';
	const focusedActionId = document.activeElement && document.activeElement.dataset
		? document.activeElement.dataset.action || ''
		: '';
	controlsRegion.dataset.screen = state.screen;
	controlsRegion.dataset.renderSequence = String(Number(controlsRegion.dataset.renderSequence || '0') + 1);
	controlsRegion.replaceChildren();
	const heading = document.createElement('h2');
	heading.id = 'market-of-ash-actions-heading';
	heading.textContent = 'Market of Ash — ' + state.screen.replaceAll('_', ' ');
	controlsRegion.appendChild(heading);
	const summary = document.createElement('p');
	summary.id = 'market-of-ash-actions-description';
	summary.textContent = state.announcement;
	controlsRegion.appendChild(summary);
	const semanticItems = new Map();
	for (const control of state.accessibility_controls) {
		const item = document.createDocumentFragment();
		const fieldId = 'market-of-ash-control-' + control.id;
		const label = document.createElement('label');
		label.htmlFor = fieldId;
		label.textContent = control.label;
		label.style.cssText = 'display:block;margin-top:8px;font-weight:600;';
		item.appendChild(label);
		let field;
		if (control.kind === 'select') {
			field = document.createElement('select');
			for (const item of control.options) {
				const option = document.createElement('option');
				option.value = item.value;
				option.textContent = item.label;
				field.appendChild(option);
			}
			field.value = control.value;
		} else if (control.kind === 'checkbox') {
			field = document.createElement('input');
			field.type = 'checkbox';
			field.checked = Boolean(control.value);
		} else {
			field = document.createElement('input');
			field.type = 'number';
			field.min = String(control.minimum);
			field.max = String(control.maximum);
			field.step = String(control.step);
			field.value = String(control.value);
		}
		field.id = fieldId;
		field.dataset.control = control.id;
		field.disabled = !control.enabled;
		field.setAttribute('aria-disabled', String(!control.enabled));
		field.style.cssText = 'display:block;width:100%%;min-height:44px;margin:4px 0 8px;box-sizing:border-box;font:inherit;';
		item.appendChild(field);
		if (control.description) {
			const description = document.createElement('p');
			description.id = 'market-of-ash-control-description-' + control.id;
			description.textContent = control.description;
			description.hidden = true;
			field.setAttribute('aria-describedby', description.id);
			item.appendChild(description);
		}
		field.addEventListener('change', function() {
			if (typeof window.marketOfAshAccessibilityChange === 'function') {
				const value = control.kind === 'checkbox' ? String(field.checked) : field.value;
				window.marketOfAshAccessibilityChange(control.id, value);
			}
		});
		semanticItems.set('control:' + control.id, item);
	}
	for (const action of state.accessibility_actions) {
		const item = document.createDocumentFragment();
		const button = document.createElement('button');
		button.type = 'button';
		button.dataset.action = action.id;
		button.textContent = action.label;
		button.disabled = !action.enabled;
		button.setAttribute('aria-disabled', String(!action.enabled));
		button.style.cssText = 'display:block;width:100%%;min-height:44px;margin-top:8px;box-sizing:border-box;font:inherit;';
		item.appendChild(button);
		if (action.description) {
			const description = document.createElement('p');
			description.id = 'market-of-ash-action-description-' + action.id;
			description.textContent = action.description;
			description.hidden = true;
			button.setAttribute('aria-describedby', description.id);
			item.appendChild(description);
		}
		button.addEventListener('click', function() {
			if (typeof window.marketOfAshAccessibilityActivate === 'function') {
				window.marketOfAshAccessibilityActivate(action.id);
			}
		});
		semanticItems.set('action:' + action.id, item);
	}
	for (const itemId of state.accessibility_order) {
		if (semanticItems.has(itemId)) {
			controlsRegion.appendChild(semanticItems.get(itemId));
			semanticItems.delete(itemId);
		}
	}
	for (const item of semanticItems.values()) {
		controlsRegion.appendChild(item);
	}
	let focusTarget = null;
	if (focusedControlId) {
		focusTarget = Array.from(controlsRegion.querySelectorAll('[data-control]'))
			.find(candidate => candidate.dataset.control === focusedControlId && !candidate.disabled) || null;
	}
	if (!focusTarget && focusedActionId) {
		focusTarget = Array.from(controlsRegion.querySelectorAll('[data-action]'))
			.find(candidate => candidate.dataset.action === focusedActionId && !candidate.disabled) || null;
	}
	if (!focusTarget && (focusedControlId || focusedActionId)) {
		focusTarget = controlsRegion.querySelector('[data-control]:not(:disabled),[data-action]:not(:disabled)');
	}
	if (focusTarget) {
		focusTarget.focus();
	}
	const canvas = document.getElementById('canvas');
	if (canvas) {
		canvas.setAttribute('role', 'application');
		canvas.setAttribute('aria-label', state.announcement);
		canvas.setAttribute('aria-describedby', 'market-of-ash-status market-of-ash-actions-description');
	}
})(%s);
""" % state_json
	bridge.call("eval", script)

func _setup_web_accessibility_bridge() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	web_accessibility_callback = JavaScriptBridge.create_callback(_on_web_accessibility_action)
	web_accessibility_control_callback = JavaScriptBridge.create_callback(_on_web_accessibility_control_change)
	web_accessibility_key_callback = JavaScriptBridge.create_callback(_on_web_accessibility_key)
	var browser_window: JavaScriptObject = JavaScriptBridge.get_interface("window")
	if browser_window != null:
		browser_window.marketOfAshAccessibilityActivate = web_accessibility_callback
		browser_window.marketOfAshAccessibilityChange = web_accessibility_control_callback
		browser_window.marketOfAshAccessibilityKey = web_accessibility_key_callback

func _on_web_accessibility_action(arguments: Array) -> void:
	if arguments.is_empty():
		return
	call_deferred("_activate_web_accessibility_action", String(arguments[0]))

func _activate_web_accessibility_action(action_id: String) -> void:
	var control: Variant = _web_accessibility_action_control(action_id)
	if not _grab_focus_if_available(control) or not (control is BaseButton):
		_publish_web_ui_state()
		return
	control.emit_signal("pressed")

func _on_web_accessibility_control_change(arguments: Array) -> void:
	if arguments.size() < 2:
		return
	call_deferred("_change_web_accessibility_control", String(arguments[0]), String(arguments[1]))

func _on_web_accessibility_key(arguments: Array) -> void:
	if arguments.size() < 6:
		return
	call_deferred(
		"_capture_web_accessibility_key",
		String(arguments[0]),
		String(arguments[1]),
		bool(arguments[2]),
		bool(arguments[3]),
		bool(arguments[4]),
		bool(arguments[5]),
	)

func _capture_web_accessibility_key(key_text: String, code_text: String, alt_pressed: bool, ctrl_pressed: bool, meta_pressed: bool, shift_pressed: bool) -> void:
	if remapping_action.is_empty():
		_publish_web_ui_state()
		return
	var keycode := _web_accessibility_keycode(key_text, code_text)
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.physical_keycode = keycode
	key_event.alt_pressed = alt_pressed
	key_event.ctrl_pressed = ctrl_pressed
	key_event.meta_pressed = meta_pressed
	key_event.shift_pressed = shift_pressed
	key_event.pressed = true
	last_input_device = "keyboard"
	_capture_keyboard_binding(key_event)
	_publish_web_ui_state()

func _web_accessibility_keycode(key_text: String, code_text: String) -> int:
	var key_name := key_text
	if code_text.begins_with("Key") and code_text.length() == 4:
		key_name = code_text.substr(3)
	elif code_text.begins_with("Digit") and code_text.length() == 6:
		key_name = code_text.substr(5)
	elif code_text == "Space" or key_text == " ":
		key_name = "Space"
	elif code_text == "NumpadEnter":
		key_name = "Enter"
	elif key_text.begins_with("Arrow"):
		key_name = key_text.trim_prefix("Arrow")
	return int(OS.find_keycode_from_string(key_name))

func _change_web_accessibility_control(control_id: String, value: String) -> void:
	match control_id:
		"shop_good":
			_select_web_accessibility_option(shop_good_option, value)
		"shop_quantity":
			_set_web_accessibility_quantity(shop_quantity, value)
		"destination":
			_select_web_accessibility_option(destination_option, value)
		"route":
			_select_web_accessibility_option(route_option, value)
		"cargo_good":
			_select_web_accessibility_option(cargo_good_option, value)
		"cargo_quantity":
			_set_web_accessibility_quantity(cargo_quantity, value)
		"reduce_motion":
			_set_web_accessibility_checkbox(reduce_motion_checkbox, value)
		"large_text":
			_set_web_accessibility_checkbox(large_text_checkbox, value)
		"interface_sounds":
			_set_web_accessibility_checkbox(interface_sounds_checkbox, value)
		_:
			_publish_web_ui_state()

func _select_web_accessibility_option(control: OptionButton, target_id: String) -> void:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree() or control.disabled:
		_publish_web_ui_state()
		return
	for index in range(control.item_count):
		if String(control.get_item_metadata(index)) != target_id:
			continue
		control.select(index)
		control.item_selected.emit(index)
		return
	_publish_web_ui_state()

func _set_web_accessibility_quantity(control: SpinBox, requested_value: String) -> void:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree() or not control.editable or not requested_value.is_valid_int():
		_publish_web_ui_state()
		return
	control.value = clampi(int(requested_value), int(control.min_value), int(control.max_value))

func _set_web_accessibility_checkbox(control: CheckBox, requested_value: String) -> void:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree() or control.disabled or requested_value not in ["true", "false"]:
		_publish_web_ui_state()
		return
	control.button_pressed = requested_value == "true"
	_publish_web_ui_state()

func _web_accessibility_action_control(action_id: String) -> Variant:
	match action_id:
		"start_game": return start_game_button
		"start_conflict": return start_conflict_button
		"start_campaign": return start_campaign_button
		"continue_game": return continue_game_button
		"shop_buy": return shop_buy_button
		"shop_sell": return shop_sell_button
		"plan_departure": return plan_departure_button
		"pause_resume": return pause_resume_button
		"pause_save": return pause_save_button
		"pause_load": return pause_load_button
		"pause_report": return pause_report_button
		"pause_main_menu": return pause_main_menu_button
		"return_to_shop": return return_to_shop_button
		"commit_departure": return commit_departure_button
		"continue_journey": return continue_journey_button
		"enter_settlement": return enter_settlement_button
		"keep_saved_campaign": return new_game_confirmation_dialog.get_cancel_button() if new_game_confirmation_dialog != null else null
		"start_new_campaign": return new_game_confirmation_dialog.get_ok_button() if new_game_confirmation_dialog != null else null
		"keep_current_run": return reset_confirmation_dialog.get_cancel_button() if reset_confirmation_dialog != null else null
		"reset_run": return reset_confirmation_dialog.get_ok_button() if reset_confirmation_dialog != null else null
	if action_id.begins_with("event_choice_"):
		var choice_index := int(action_id.trim_prefix("event_choice_"))
		if choice_index >= 0 and choice_index < event_choice_buttons.size():
			return event_choice_buttons[choice_index]
	for control in [guided_test_button, shop_save_button, shop_load_button, shop_reset_button, shop_report_button, restore_bindings_button]:
		if control != null and is_instance_valid(control) and String(control.get_meta("web_accessibility_id", "")) == action_id:
			return control
	for control in binding_buttons.values():
		if control != null and is_instance_valid(control) and String(control.get_meta("web_accessibility_id", "")) == action_id:
			return control
	for controls in [bazaar_navigation_buttons, contract_buttons, opportunity_buttons, crew_buttons]:
		for control in controls:
			if is_instance_valid(control) and String(control.get_meta("web_accessibility_id", "")) == action_id:
				return control
	return null

func _append_web_accessibility_action(actions: Array, action_id: String, control: Variant) -> void:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree() or not (control is BaseButton):
		return
	actions.append({
		"id": action_id,
		"label": String(control.text),
		"enabled": not control.disabled,
		"description": String(control.tooltip_text),
	})

func _append_tagged_web_accessibility_actions(actions: Array, controls: Array) -> void:
	for control in controls:
		_append_web_accessibility_action(actions, String(control.get_meta("web_accessibility_id", "")), control)

func _web_accessibility_option_control(control_id: String, label: String, control: OptionButton) -> Dictionary:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return {}
	var options: Array = []
	for index in range(control.item_count):
		options.append({
			"value": String(control.get_item_metadata(index)),
			"label": control.get_item_text(index),
		})
	return {
		"id": control_id,
		"label": label,
		"kind": "select",
		"value": _selected_id(control),
		"enabled": not control.disabled,
		"description": control.tooltip_text,
		"options": options,
	}

func _web_accessibility_quantity_control(control_id: String, label: String, control: SpinBox) -> Dictionary:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return {}
	return {
		"id": control_id,
		"label": label,
		"kind": "number",
		"value": int(control.value),
		"minimum": int(control.min_value),
		"maximum": int(control.max_value),
		"step": int(control.step),
		"enabled": control.editable,
		"description": control.tooltip_text,
	}

func _web_accessibility_checkbox_control(control_id: String, control: CheckBox) -> Dictionary:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return {}
	return {
		"id": control_id,
		"label": control.text,
		"kind": "checkbox",
		"value": control.button_pressed,
		"enabled": not control.disabled,
		"description": control.tooltip_text,
	}

func _web_accessibility_controls() -> Array:
	var controls: Array = []
	match _current_ui_state_id():
		"main_menu":
			controls.append(_web_accessibility_checkbox_control("reduce_motion", reduce_motion_checkbox))
			controls.append(_web_accessibility_checkbox_control("large_text", large_text_checkbox))
			controls.append(_web_accessibility_checkbox_control("interface_sounds", interface_sounds_checkbox))
		"settlement_shop":
			controls.append(_web_accessibility_option_control("shop_good", "Cargo", shop_good_option))
			controls.append(_web_accessibility_quantity_control("shop_quantity", "Quantity", shop_quantity))
		"departure_desk":
			controls.append(_web_accessibility_option_control("destination", "Destination", destination_option))
			controls.append(_web_accessibility_option_control("route", "Route", route_option))
			controls.append(_web_accessibility_option_control("cargo_good", "Forecast cargo", cargo_good_option))
			controls.append(_web_accessibility_quantity_control("cargo_quantity", "Forecast quantity", cargo_quantity))
	return controls

func _web_accessibility_actions() -> Array:
	var actions: Array = []
	match _current_ui_state_id():
		"main_menu":
			_append_web_accessibility_action(actions, "start_game", start_game_button)
			_append_web_accessibility_action(actions, "start_conflict", start_conflict_button)
			_append_web_accessibility_action(actions, "start_campaign", start_campaign_button)
			_append_web_accessibility_action(actions, "continue_game", continue_game_button)
			for action_name in REMAPPABLE_ACTIONS:
				_append_web_accessibility_action(actions, "rebind_%s" % action_name, binding_buttons.get(action_name))
			_append_web_accessibility_action(actions, "restore_default_bindings", restore_bindings_button)
		"settlement_shop":
			_append_web_accessibility_action(actions, "shop_buy", shop_buy_button)
			_append_web_accessibility_action(actions, "shop_sell", shop_sell_button)
			_append_web_accessibility_action(actions, "guided_trade", guided_test_button)
			_append_tagged_web_accessibility_actions(actions, contract_buttons)
			_append_tagged_web_accessibility_actions(actions, opportunity_buttons)
			_append_tagged_web_accessibility_actions(actions, crew_buttons)
			_append_web_accessibility_action(actions, "shop_save", shop_save_button)
			_append_web_accessibility_action(actions, "shop_load", shop_load_button)
			_append_web_accessibility_action(actions, "shop_reset", shop_reset_button)
			_append_web_accessibility_action(actions, "shop_report", shop_report_button)
			_append_web_accessibility_action(actions, "plan_departure", plan_departure_button)
			_append_tagged_web_accessibility_actions(actions, bazaar_navigation_buttons)
		"departure_desk":
			_append_web_accessibility_action(actions, "return_to_shop", return_to_shop_button)
			_append_web_accessibility_action(actions, "commit_departure", commit_departure_button)
		"route_travel":
			_append_web_accessibility_action(actions, "continue_journey", continue_journey_button)
		"route_event":
			for choice_index in range(event_choice_buttons.size()):
				_append_web_accessibility_action(actions, "event_choice_%d" % choice_index, event_choice_buttons[choice_index])
		"arrival_handoff":
			_append_web_accessibility_action(actions, "enter_settlement", enter_settlement_button)
		"pause":
			_append_web_accessibility_action(actions, "pause_resume", pause_resume_button)
			_append_web_accessibility_action(actions, "pause_save", pause_save_button)
			_append_web_accessibility_action(actions, "pause_load", pause_load_button)
			_append_web_accessibility_action(actions, "pause_report", pause_report_button)
			_append_web_accessibility_action(actions, "pause_main_menu", pause_main_menu_button)
		"new_game_confirmation":
			_append_web_accessibility_action(actions, "keep_saved_campaign", new_game_confirmation_dialog.get_cancel_button())
			_append_web_accessibility_action(actions, "start_new_campaign", new_game_confirmation_dialog.get_ok_button())
		"reset_confirmation":
			_append_web_accessibility_action(actions, "keep_current_run", reset_confirmation_dialog.get_cancel_button())
			_append_web_accessibility_action(actions, "reset_run", reset_confirmation_dialog.get_ok_button())
	return actions

func _web_accessibility_order(actions: Array, controls: Array) -> Array:
	var order: Array = []
	if _current_ui_state_id() == "main_menu":
		for action_id in ["start_game", "start_conflict", "start_campaign", "continue_game"]:
			for action in actions:
				if action.get("id") == action_id:
					order.append("action:%s" % action_id)
					break
		for control in controls:
			order.append("control:%s" % String(control.get("id", "")))
		for action in actions:
			var action_id := String(action.get("id", ""))
			if action_id not in ["start_game", "start_conflict", "start_campaign", "continue_game"]:
				order.append("action:%s" % action_id)
		return order
	for control in controls:
		order.append("control:%s" % String(control.get("id", "")))
	for action in actions:
		order.append("action:%s" % String(action.get("id", "")))
	return order

func _queue_web_ui_state_after_layout() -> void:
	if not OS.has_feature("web") or not Engine.has_singleton("JavaScriptBridge"):
		return
	if not get_tree().process_frame.is_connected(_publish_web_ui_state):
		get_tree().process_frame.connect(_publish_web_ui_state, CONNECT_ONE_SHOT)

func _web_accessibility_announcement() -> String:
	var screen_id := _current_ui_state_id()
	match screen_id:
		"main_menu":
			if not remapping_action.is_empty() and binding_status_label != null:
				return "Market of Ash input remapping. %s" % binding_status_label.text
			var menu_announcement := "Market of Ash main menu. Start Guided Trade is focused, followed by Conflict and Recovery, Contract and Crew, and Continue. Every new path uses the same canonical campaign rules. Accept uses %s or controller %s. Accessibility and input settings follow the launch actions." % [_keyboard_binding_text("ui_accept"), _controller_binding_text("ui_accept")]
			if binding_status_label != null and not binding_status_label.text.is_empty():
				menu_announcement += " %s" % binding_status_label.text
			return menu_announcement
		"settlement_shop":
			var recent_conflict_text := _latest_conflict_outcome_text()
			var recent_conflict_note := " Latest conflict report: %s" % recent_conflict_text.replace("\n", " ") if not recent_conflict_text.is_empty() else ""
			return "Settlement Bazaar at %s. Trade, Jobs, Services and Intel, Crew, Outlook, and Departure form the repeatable hub.%s" % [String(world.settlement(world.current_settlement).get("name", world.current_settlement)), recent_conflict_note]
		"departure_desk":
			return "Departure Desk. Choose destination, route, cargo forecast, and quantity before Commit departure. Return to shop spends nothing."
		"route_travel":
			return "On the road. The committed caravan route is shown before any encounter or arrival. Continue journey is focused when the road observation is ready."
		"route_event":
			return "Caravan conflict simulation: %s. Threat, readiness, costs, risk, and expected outcomes are stated before the first available response; unavailable tactics include written reasons." % String(world.pending_event.get("title", "travel event"))
		"arrival_handoff":
			var comparison_note := " " + last_conflict_outcome_text.replace("\n", " ") if not last_conflict_outcome_text.is_empty() else ""
			return "Arrival report for %s.%s Enter settlement is focused." % [String(world.settlement(world.current_settlement).get("name", world.current_settlement)), comparison_note]
		"pause":
			return "Game paused. Resume is focused; save, load, report, and main-menu actions follow."
		"new_game_confirmation":
			return "Start a new campaign? Existing save files remain until the next successful autosave. Keep saved campaign is focused."
		"reset_confirmation":
			return "Reset the current run to Day 1? The existing disk save remains available. Keep current run is focused."
	return "Market of Ash"

func _web_ui_state() -> Dictionary:
	var selected_good_id := _selected_id(shop_good_option) if shop_good_option != null else ""
	var logical_size := get_viewport().get_visible_rect().size
	var accessibility_actions := _web_accessibility_actions()
	var accessibility_controls := _web_accessibility_controls()
	return {
		"screen": _current_ui_state_id(),
		"announcement": _web_accessibility_announcement(),
		"accessibility_actions": accessibility_actions,
		"accessibility_controls": accessibility_controls,
		"accessibility_order": _web_accessibility_order(accessibility_actions, accessibility_controls),
		"logical_viewport": {"width": logical_size.x, "height": logical_size.y},
		"targets": {
			"start_game": _web_control_rect(start_game_button),
			"start_conflict": _web_control_rect(start_conflict_button),
			"start_campaign": _web_control_rect(start_campaign_button),
			"large_text": _web_control_rect(large_text_checkbox),
			"plan_departure": _web_control_rect(plan_departure_button),
			"return_to_shop": _web_control_rect(return_to_shop_button),
			"commit_departure": _web_control_rect(commit_departure_button),
			"continue_journey": _web_control_rect(continue_journey_button),
			"enter_settlement": _web_control_rect(enter_settlement_button),
			"pause_main_menu": _web_control_rect(pause_main_menu_button),
			"shop_good": _web_control_rect(shop_good_option),
			"shop_buy": _web_control_rect(shop_buy_button),
			"destination": _web_control_rect(destination_option),
			"event_choice": _web_control_rect(_first_available_event_choice()),
		},
		"large_text": large_text_enabled,
		"reduced_motion": reduce_motion_enabled,
		"interface_sounds": interface_sounds_enabled,
		"playtest_path_id": active_playtest_path_id,
		"remapping_action": remapping_action,
		"binding_status": binding_status_label.text if binding_status_label != null else "",
		"input_bindings": _input_bindings_report(),
		"settlement_id": world.current_settlement if world != null else "",
		"day": world.day if world != null else 0,
		"money": world.money if world != null else 0,
		"provisions": world.provisions if world != null else 0,
		"cargo_weight": int(world.cargo.get("weight", 0)) if world != null else 0,
		"pending_event_id": String(world.pending_event.get("id", "")) if world != null else "",
		"travel_phase": map_panel.travel_phase if map_panel != null else "rest",
		"selected_good_id": selected_good_id,
		"selected_destination_id": _selected_id(destination_option) if destination_option != null else "",
		"selected_route_id": _selected_id(route_option) if route_option != null else "",
		"selected_quantity": int(shop_quantity.value) if shop_quantity != null else 0,
		"held_selected_quantity": int(world.cargo.get(selected_good_id, 0)) if world != null else 0,
	}

func _web_control_rect(control: Control) -> Dictionary:
	if control == null or not is_instance_valid(control) or not control.is_visible_in_tree():
		return {}
	if control is BaseButton and control.disabled:
		return {}
	var rect := control.get_global_rect()
	return {"x": rect.position.x, "y": rect.position.y, "width": rect.size.x, "height": rect.size.y}

func _first_available_event_choice() -> Control:
	for button in event_choice_buttons:
		if button != null and is_instance_valid(button) and button.visible and not button.disabled:
			return button
	return null

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
		last_conflict_outcome_text = _conflict_outcome_comparison(result)
		arrival_pending = true
		enter_settlement_button.visible = true
		if map_panel:
			map_panel.complete_travel()
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
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _on_forecast_input_changed(_index: int) -> void:
	_sync_departure_plan_to_shop()
	_refresh_forecasts()
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _on_forecast_value_changed(_value: float) -> void:
	_sync_departure_plan_to_shop()
	_refresh_forecasts()
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _refresh_forecasts() -> void:
	if market_preview_label == null or route_preview_label == null:
		return
	var good_id := _selected_id(cargo_good_option)
	var destination_id := _selected_id(destination_option)
	var route_id := _selected_id(route_option)
	if map_panel:
		map_panel.set_plan(route_id, destination_id)
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
		commit_departure_button.text = "Confirm and set out — %d ashmarks · %d %s" % [int(selected_route.get("cost", 0)), provision_count, provision_label]
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
		last_conflict_outcome_text = ""
		committed_journey_message = String(result.get("message", "Journey committed."))
		arrival_pending = world.pending_event.is_empty()
		commit_departure_button.disabled = true
		return_to_shop_button.disabled = true
		enter_settlement_button.visible = false
		if map_panel:
			map_panel.begin_travel(route_id, previous_settlement, destination_id)
		_populate_destination_options()
		_populate_route_options()
	_show_command_result(result, "Departure")

func _on_map_travel_state_changed(_state: String) -> void:
	if status_label == null or world == null:
		return
	_refresh_ui()
	if map_panel.travel_phase == "road":
		_grab_focus_if_available(continue_journey_button)
	elif map_panel.travel_phase == "encounter":
		_grab_first_enabled(event_choice_buttons)
	elif map_panel.travel_phase == "arrived":
		_grab_focus_if_available(enter_settlement_button)

func _on_continue_journey_pressed() -> void:
	if map_panel == null or map_panel.travel_phase != "road":
		return
	map_panel.continue_from_road()
	if map_panel.travel_phase == "encounter":
		_set_event("%s — %s\nNEXT — %s" % [String(world.pending_event.get("title", "Route encounter")), String(world.pending_event.get("setup", "The road is blocked.")), _next_step_text()])
		_refresh_ui()
		_grab_first_enabled(event_choice_buttons)

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
	if map_panel != null and map_panel.travel_phase in ["moving_out", "moving_in"]:
		return "Watch the committed road; the next action appears when the caravan reaches its travel stop."
	if map_panel != null and map_panel.travel_phase == "road":
		return "Review the road view, then choose Continue along the road."
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
	var target_absolute := ProjectSettings.globalize_path(save_path)
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(temporary_path):
		var stale_remove_error := DirAccess.remove_absolute(temporary_absolute)
		if stale_remove_error != OK:
			save_status_text = "SAVE ERROR — Could not clear the stale temporary save file. Current run unchanged."
			return false
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		save_status_text = "SAVE ERROR — Could not open a temporary save file. Current run unchanged."
		return false
	file.store_string(JSON.stringify(world.serialize()))
	file.flush()
	if file.get_error() != OK:
		file = null
		DirAccess.remove_absolute(temporary_absolute)
		save_status_text = "SAVE ERROR — Could not finish writing. Current run unchanged."
		return false
	file = null
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
		if FileAccess.file_exists(temporary_path):
			DirAccess.remove_absolute(temporary_absolute)
		save_status_text = "SAVE ERROR — Could not promote the validated save. Previous save preserved when available."
		return false
	var settlement_name := String(world.settlement(world.current_settlement).get("name", world.current_settlement))
	save_status_text = "%s — Day %d · %s · %d ashmarks · hold %d/%d · save v%d · content %s" % [status_prefix, world.day, settlement_name, world.money, int(world.cargo.get("weight", 0)), world.cargo_capacity, AshWorldState.SAVE_VERSION, MarketContent.content_version()]
	if continue_game_button:
		continue_game_button.disabled = false
		continue_game_button.tooltip_text = "Validate and continue the saved campaign."
	_refresh_start_button_labels(true)
	_link_main_menu_focus_cycle()
	return true

func _on_load_pressed() -> bool:
	var loaded_from_main_menu := menu_layer != null and menu_layer.visible
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
	if loaded_from_main_menu:
		active_playtest_path_id = PLAYTEST_PATH_CONTINUED
	arrival_pending = false
	last_conflict_outcome_text = ""
	if map_panel:
		map_panel.world = world
		map_panel.reduce_motion = reduce_motion_checkbox != null and reduce_motion_checkbox.button_pressed
		map_panel.reset_travel(world.current_settlement)
		if not world.pending_event.is_empty() and not world.journey_context.is_empty():
			map_panel.restore_pending_travel(String(world.journey_context.get("route_id", "")), String(world.journey_context.get("origin_id", world.current_settlement)), String(world.journey_context.get("destination_id", world.current_settlement)))
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
		reset_confirmation_dialog.canceled.connect(_on_confirmation_closed)
		add_child(reset_confirmation_dialog)
	reset_confirmation_dialog.popup_centered(Vector2i(520, 180))
	_configure_confirmation_targets(reset_confirmation_dialog)
	call_deferred("_configure_confirmation_targets", reset_confirmation_dialog)
	reset_confirmation_dialog.get_cancel_button().call_deferred("grab_focus")
	call_deferred("_publish_web_ui_state")

func _confirm_reset() -> void:
	if reset_confirmation_dialog:
		reset_confirmation_dialog.hide()
	world = AshWorldState.new(PLAYTEST_SEED)
	_populate_destination_options()
	_populate_route_options()
	_apply_playtest_path_defaults(active_playtest_path_id)
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
	if map_panel != null and map_panel.travel_phase in ["moving_out", "road", "moving_in"]:
		if guided_test_button:
			guided_test_button.visible = false
		playtest_status_label.text = "ON THE ROAD — Follow the committed route, inspect the travel stop, then continue toward the next event or settlement."
		return
	if active_playtest_path_id == PLAYTEST_PATH_CONFLICT:
		_refresh_conflict_playtest_status()
		return
	if active_playtest_path_id == PLAYTEST_PATH_CAMPAIGN:
		_refresh_campaign_playtest_status()
		return
	if active_playtest_path_id == PLAYTEST_PATH_CONTINUED:
		if guided_test_button:
			guided_test_button.visible = false
		playtest_status_label.text = "CONTINUED CAMPAIGN — Resume from the saved market, route, contract, crew, and campaign evidence; no opening-path assumptions are applied."
		return
	if active_playtest_path_id != PLAYTEST_PATH_GUIDED:
		if guided_test_button:
			guided_test_button.visible = false
		playtest_status_label.text = "FREE PLAY — Use the live market, route, contract, crew, and campaign outlook to choose the next test."
		return
	var guided_cargo_held := int(world.cargo.get(PLAYTEST_GOOD, 0))
	var guided_cargo_bought := _guided_trade_quantity(MarketCommandProcessor.BUY_GOODS)
	var guided_cargo_sold := _guided_trade_quantity(MarketCommandProcessor.SELL_GOODS, PLAYTEST_DESTINATION)
	if guided_test_button:
		guided_test_button.visible = active_playtest_path_id == PLAYTEST_PATH_GUIDED and world.current_settlement == "ashgate" and world.day == 1 and guided_cargo_sold < PLAYTEST_QUANTITY
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

func _refresh_conflict_playtest_status() -> void:
	if guided_test_button:
		guided_test_button.visible = false
	if world.has_resolved_event("gatekeepers_chalk"):
		playtest_status_label.text = "RUN COMPLETE — You resolved the Gatekeeper conflict. Compare Plan vs Actual, follow any recovery guidance, then enter Brine Cross."
	elif String(world.pending_event.get("id", "")) == "gatekeepers_chalk":
		playtest_status_label.text = "STEP 3 OF 3 — The Gatekeeper conflict is active. Compare every tactic's certainty, cost, and expected outcome before choosing."
	elif world.current_settlement == "ashgate" and int(world.cargo.get("medicine", 0)) >= 2:
		playtest_status_label.text = "STEP 2 OF 3 — Medicine is loaded. Plan Brine Cross by the Toll Road, confirm the exposed unit, then commit."
	elif world.current_settlement == "ashgate" and world.day == 1:
		playtest_status_label.text = "STEP 1 OF 3 — Buy 2 Medicine. The selected Toll Road plan will surface a deterministic Gatekeeper conflict without bypassing normal trade rules."
	else:
		playtest_status_label.text = "FREE PLAY — The conflict test path was left behind. Use the live market, route, and campaign state to continue."

func _refresh_campaign_playtest_status() -> void:
	if guided_test_button:
		guided_test_button.visible = false
	if _has_completed_contract("reedwatch_water_relief_01"):
		playtest_status_label.text = "RUN COMPLETE — Reedwatch Water Relief is complete. Review the reward, market response, resilience options, and campaign outlook."
	elif not world.active_contract("reedwatch_water_relief_01").is_empty() and int(world.cargo.get("water", 0)) >= 4:
		playtest_status_label.text = "STEP 3 OF 3 — The relief terms and 4 Water are ready. Compare crew-informed routes, then commit to Reedwatch before the deadline."
	elif not world.active_contract("reedwatch_water_relief_01").is_empty():
		playtest_status_label.text = "STEP 2 OF 3 — The relief contract is active. Buy enough Water to reach 4/4; crew recruitment remains optional and costs a visit slot."
	elif world.current_settlement == "ashgate" and world.day == 1:
		playtest_status_label.text = "STEP 1 OF 3 — Accept Reedwatch Water Relief. Recruit and assign one crew member if their tradeoff fits the plan, then prepare 4 Water."
	else:
		playtest_status_label.text = "FREE PLAY — The contract-and-crew test path was left behind. Use the live opportunities and campaign outlook to continue."

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
		contract_button.set_meta("web_accessibility_id", "accept_contract_%s" % contract_id)
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
		resolve_button.set_meta("web_accessibility_id", "resolve_contract_%s" % active_id)
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
		action_button.set_meta("web_accessibility_id", "settlement_action_%s" % String(action.get("id", "")))
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
		button.set_meta("web_accessibility_id", "%s_crew_%s" % ["assign" if recruited else "recruit", crew_id])
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
		active_contract_label.visible = false
		departure_contract_label.text = "ACTIVE CONTRACT — none."
		return
	active_contract_label.visible = true
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
	var enabled_choice_buttons: Array = []
	var pending := world.pending_event
	var event_revealed: bool = not pending.is_empty() and map_panel != null and map_panel.travel_phase == "encounter"
	event_card.visible = event_revealed
	if conflict_outcome_panel and conflict_outcome_label:
		conflict_outcome_panel.visible = pending.is_empty() and arrival_pending and not last_conflict_outcome_text.is_empty()
		conflict_outcome_label.text = last_conflict_outcome_text
	if pending.is_empty():
		if arrival_pending and (pause_layer == null or not pause_layer.visible):
			_grab_focus_if_available(enter_settlement_button)
		return
	if not event_revealed:
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
	var maximum_cargo_risk := 0.0
	for raw_choice in pending.get("choices", []):
		if typeof(raw_choice) == TYPE_DICTIONARY:
			maximum_cargo_risk = maxf(maximum_cargo_risk, float(raw_choice.get("cargo_risk", 0.0)))
	var maximum_risk_percent := int(round(maximum_cargo_risk * 100.0))
	var threat_summary := "No tactic uses a cargo-loss roll." if maximum_risk_percent == 0 else "Highest disclosed cargo-loss chance: %d%% against %s." % [maximum_risk_percent, cargo_context]
	event_stakes_label.text = "THREAT — %s\nROUTE — %s to %s via %s.%s%s\nAT STAKE — %s\nMODEL — This is an abstract caravan conflict: outcomes spend only the resources, time, cargo, or standing written below; there is no hidden health damage." % [threat_summary, String(world.settlement(String(pending.get("origin_id", ""))).get("name", "origin")), destination_name, String(world.route(String(pending.get("route_id", ""))).get("name", "route")), material_context, trade_context, String(pending.get("stakes", ""))]
	for raw_choice in pending.get("choices", []):
		if typeof(raw_choice) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = raw_choice
		var button := _wrapped_action_button(92.0)
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
		var money_text := "no ashmark change"
		if money_reward > 0:
			money_text = "+%d ashmarks" % money_reward
		elif money_cost > 0:
			money_text = "-%d ashmarks" % money_cost
		var arrival_text := "return to origin" if String(choice.get("arrival_target", "destination")) == "origin" else "continue to destination"
		var cargo_cost_text := "%d %s" % [trade_quantity, String(trade_basis.get("good_id", "cargo"))] if trade_quantity > 0 else "%d materials" % material_quantity if material_quantity > 0 else "no cargo spent"
		if cargo_cost_quantity > 0:
			cargo_cost_text = "%d %s" % [cargo_cost_quantity, cargo_cost_good_id]
		var tactic_label := _event_tactic_label(choice, trade_quantity, cargo_cost_quantity)
		var certainty_label := "CERTAIN" if cargo_risk == 0 else "RISK ROLL %d%% cargo risk" % cargo_risk
		button.text = "%s / %s — %s\nCOST — %s · %d provisions · %s · %d days\nRESULT — %s · %s\nEXPECTED — %s" % [tactic_label, certainty_label, String(choice.get("label", "Choose")), money_text, provision_cost, cargo_cost_text, days, arrival_text, "no cargo-loss roll" if cargo_risk == 0 else "up to %s exposed" % cargo_context, String(choice.get("outcome", "Resolve the confrontation."))]
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
		if not button.disabled:
			enabled_choice_buttons.append(button)
		if button.disabled:
			var reason_label := Label.new()
			reason_label.text = "Unavailable: %s" % blocked_reason
			reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			reason_label.add_theme_font_size_override("font_size", 11)
			reason_label.add_theme_color_override("font_color", Color("#b5a18b"))
			event_choice_list.add_child(reason_label)
			event_choice_reason_labels.append(reason_label)
	if not enabled_choice_buttons.is_empty():
		_link_focus_cycle(enabled_choice_buttons)
	if event_readiness_label:
		event_readiness_label.text = "READINESS — %d of %d tactics ready. Disabled tactics remain visible and name the missing money, cargo, provisions, contract, or crew leverage." % [enabled_choice_buttons.size(), event_choice_buttons.size()]
	if pause_layer == null or not pause_layer.visible:
		if _grab_first_enabled(event_choice_buttons) and not get_tree().process_frame.is_connected(_ensure_focused_control_visible):
			get_tree().process_frame.connect(_ensure_focused_control_visible, CONNECT_ONE_SHOT)

func _event_tactic_label(choice: Dictionary, trade_quantity: int, cargo_cost_quantity: int) -> String:
	if String(choice.get("arrival_target", "destination")) == "origin":
		return "RETREAT"
	if not String(choice.get("requires_assigned_crew_id", "")).is_empty():
		return "CREW LEVERAGE"
	if float(choice.get("cargo_risk", 0.0)) > 0.0:
		return "MANEUVER"
	if int(choice.get("money_cost", 0)) > 0:
		return "PAY"
	if trade_quantity > 0 or int(choice.get("material_quantity", 0)) > 0 or cargo_cost_quantity > 0:
		return "TRADE"
	if int(choice.get("days", 0)) > 0:
		return "WAIT"
	if not Dictionary(choice.get("reputation_delta", {})).is_empty() or not String(choice.get("information_id", "")).is_empty():
		return "NEGOTIATE"
	return "COMMIT"

func _conflict_outcome_comparison(result: Dictionary) -> String:
	var state_delta: Dictionary = result.get("state_delta", {})
	var event_record: Dictionary = Dictionary(state_delta.get("event", {})).duplicate(true)
	event_record["outcome"] = Dictionary(state_delta.get("outcome", {})).duplicate(true)
	event_record["choice_id"] = String(state_delta.get("choice_id", ""))
	return _conflict_outcome_comparison_from_event(event_record)

func _latest_conflict_outcome_text() -> String:
	if world == null or world.event_history.is_empty():
		return ""
	return _conflict_outcome_comparison_from_event(Dictionary(world.event_history.back()))

func _conflict_outcome_comparison_from_event(event_record: Dictionary) -> String:
	var outcome: Dictionary = event_record.get("outcome", {})
	var choice_id := String(event_record.get("choice_id", ""))
	if event_record.is_empty() or outcome.is_empty() or choice_id.is_empty():
		return ""
	var choice := _event_choice_from_record(event_record, choice_id)
	if choice.is_empty():
		return ""
	var trade_basis: Dictionary = event_record.get("trade_basis", {})
	var trade_mode := String(choice.get("trade_mode", "none"))
	var trade_quantity := int(trade_basis.get("quantity", 0)) if trade_mode != "none" else 0
	var cargo_cost: Dictionary = choice.get("cargo_cost", {})
	var cargo_cost_quantity := int(cargo_cost.get("quantity", 0))
	var tactic_label := _event_tactic_label(choice, trade_quantity, cargo_cost_quantity)
	var risk := float(choice.get("cargo_risk", 0.0))
	var risk_percent := int(round(risk * 100.0))
	var certainty_label := "CERTAIN" if risk_percent == 0 else "%d%% RISK" % risk_percent
	var planned_money := int(choice.get("money_reward", 0)) - int(choice.get("money_cost", 0))
	if trade_mode == "premium_sale":
		planned_money += int(trade_basis.get("premium_total", 0))
	var arrival_target := String(choice.get("arrival_target", "destination"))
	var planned_settlement_id := String(event_record.get("origin_id", "")) if arrival_target == "origin" else String(event_record.get("destination_id", ""))
	var planned_settlement_name := String(world.settlement(planned_settlement_id).get("name", planned_settlement_id))
	var actual_settlement_id := String(outcome.get("current_settlement", planned_settlement_id))
	var actual_settlement_name := String(world.settlement(actual_settlement_id).get("name", actual_settlement_id))
	var planned_cargo := _planned_conflict_cargo_text(choice, event_record, trade_quantity, cargo_cost_quantity)
	var actual_cargo := _actual_conflict_cargo_text(Dictionary(outcome.get("cargo", {})))
	var risk_variance := _conflict_risk_variance_text(event_record, outcome)
	var persistent_effects := _conflict_persistent_effects_text(outcome)
	var comparison := "PLAN VS ACTUAL\nTACTIC — %s / %s — %s\nPLAN — %s · %s · %s · %s · %s · %s.\nACTUAL — %s · %s · %s · %s · arrived at %s.\nVARIANCE — %s\nEXPECTED — %s" % [
		tactic_label,
		certainty_label,
		String(choice.get("label", "Choice")),
		_resource_delta_text(planned_money, "ashmarks"),
		_resource_delta_text(-int(choice.get("provision_cost", 0)), "provisions"),
		planned_cargo,
		_resource_delta_text(int(choice.get("days", 0)), "days"),
		"no cargo-loss roll" if risk_percent == 0 else "%d%% cargo-loss roll" % risk_percent,
		"return to %s" % planned_settlement_name if arrival_target == "origin" else "continue to %s" % planned_settlement_name,
		_resource_delta_text(int(outcome.get("money", 0)), "ashmarks"),
		_resource_delta_text(int(outcome.get("provisions", 0)), "provisions"),
		actual_cargo,
		_resource_delta_text(int(outcome.get("day", 0)), "days"),
		actual_settlement_name,
		risk_variance,
		String(choice.get("outcome", "The conflict resolves.")),
	]
	if not persistent_effects.is_empty():
		comparison += "\nPERSISTENT — %s" % persistent_effects
	var recovery_text := _conflict_recovery_text(event_record, outcome)
	if not recovery_text.is_empty():
		comparison += "\n%s" % recovery_text
	return comparison

func _event_choice_from_record(event_record: Dictionary, choice_id: String) -> Dictionary:
	for raw_choice in event_record.get("choices", []):
		if typeof(raw_choice) == TYPE_DICTIONARY and String(raw_choice.get("id", "")) == choice_id:
			return Dictionary(raw_choice)
	return {}

func _resource_delta_text(value: int, unit: String) -> String:
	return "%+d %s" % [value, unit] if value != 0 else "0 %s" % unit

func _planned_conflict_cargo_text(choice: Dictionary, event_record: Dictionary, trade_quantity: int, cargo_cost_quantity: int) -> String:
	if trade_quantity > 0:
		var trade_basis: Dictionary = event_record.get("trade_basis", {})
		return "-%d %s planned" % [trade_quantity, String(trade_basis.get("good_id", "cargo")).capitalize()]
	var material_quantity := int(choice.get("material_quantity", 0))
	if material_quantity > 0:
		return "-%d repair materials planned" % material_quantity
	if cargo_cost_quantity > 0:
		return "-%d %s planned" % [cargo_cost_quantity, String(choice.get("cargo_cost", {}).get("good_id", "cargo")).capitalize()]
	return "no planned cargo spend"

func _actual_conflict_cargo_text(cargo_delta: Dictionary) -> String:
	var parts: Array[String] = []
	var good_ids: Array = cargo_delta.keys()
	good_ids.sort()
	for good_id_value in good_ids:
		var good_id := String(good_id_value)
		if good_id == "weight" or int(cargo_delta.get(good_id_value, 0)) == 0:
			continue
		parts.append("%s %+d" % [good_id.capitalize(), int(cargo_delta.get(good_id_value, 0))])
	return "cargo unchanged" if parts.is_empty() else ", ".join(parts)

func _conflict_risk_variance_text(event_record: Dictionary, outcome: Dictionary) -> String:
	var risk := float(outcome.get("cargo_risk", 0.0))
	if risk <= 0.0:
		return "Matched the disclosed plan; no cargo-loss roll occurred."
	var roll := float(outcome.get("resolution_roll", 1.0))
	var roll_percent := int(round(roll * 100.0))
	var risk_percent := int(round(risk * 100.0))
	var loss_basis: Dictionary = event_record.get("loss_basis", {})
	var loss_good_id := String(loss_basis.get("loss_good_id", ""))
	if roll < risk:
		return "Risk realized: the %d%% roll was below %d%%; 1 %s was exposed." % [roll_percent, risk_percent, loss_good_id.capitalize() if not loss_good_id.is_empty() else "cargo unit"]
	return "Risk avoided: the %d%% roll cleared the %d%% threshold; the exposed %s remained intact." % [roll_percent, risk_percent, loss_good_id.capitalize() if not loss_good_id.is_empty() else "cargo"]

func _conflict_persistent_effects_text(outcome: Dictionary) -> String:
	var parts: Array[String] = []
	var route_condition: Dictionary = outcome.get("route_condition", {})
	if not route_condition.is_empty():
		parts.append(String(route_condition.get("label", "Route condition changed")))
	var resilience: Dictionary = outcome.get("settlement_resilience", {})
	if not resilience.is_empty():
		parts.append("settlement resilience %d/10" % int(resilience.get("after", 0)))
	var information_id := String(outcome.get("information_id", ""))
	if not information_id.is_empty():
		parts.append("information: %s" % information_id.replace("_", " "))
	var reputation: Dictionary = outcome.get("reputation", {})
	var faction_ids: Array = reputation.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := String(faction_id_value)
		var reputation_result: Dictionary = reputation.get(faction_id_value, {})
		parts.append("%s standing %+d to %d" % [faction_id.capitalize(), int(reputation_result.get("delta", 0)), int(reputation_result.get("after", 0))])
	var contracts: Array = outcome.get("contract_resolutions", [])
	if not contracts.is_empty():
		parts.append("%d contract result%s" % [contracts.size(), "" if contracts.size() == 1 else "s"])
	return "; ".join(parts)

func _conflict_recovery_text(event_record: Dictionary, outcome: Dictionary) -> String:
	var risk := float(outcome.get("cargo_risk", 0.0))
	var roll := float(outcome.get("resolution_roll", 1.0))
	if risk <= 0.0 or roll >= risk:
		return ""
	var sale := _best_recovery_sale()
	var recovery_steps: Array[String] = []
	var available_money := world.money
	if not sale.is_empty():
		available_money += int(sale.get("total", 0))
		recovery_steps.append("%s x%d remains and would sell here for %d ashmarks" % [String(sale.get("name", "Cargo")), int(sale.get("quantity", 0)), int(sale.get("total", 0))])
	var route_option := _safest_affordable_recovery_route(available_money)
	if not route_option.is_empty():
		var funding_basis := "With current funds"
		if not sale.is_empty():
			funding_basis = "After that sale"
		recovery_steps.append("%s, %s to %s is the lowest-risk affordable onward route at %d ashmarks, %d provision%s, and %d%% route risk" % [funding_basis, String(route_option.get("route_name", "Route")), String(route_option.get("destination_name", "destination")), int(route_option.get("money_cost", 0)), int(route_option.get("provision_cost", 0)), "" if int(route_option.get("provision_cost", 0)) == 1 else "s", int(route_option.get("risk_percent", 0))])
	if recovery_steps.is_empty():
		var loss_basis: Dictionary = event_record.get("loss_basis", {})
		var loss_good_id := String(loss_basis.get("loss_good_id", "cargo"))
		recovery_steps.append("the lost %s leaves no immediately affordable sale or route, so check the visible Local Opportunities and their exact blockers" % loss_good_id.capitalize())
	return "RECOVERY — %s. No restart is required." % ". ".join(recovery_steps)

func _best_recovery_sale() -> Dictionary:
	var settlement := world.settlement(world.current_settlement)
	var context := world.pricing_context()
	var best: Dictionary = {}
	for good_id in MarketContent.good_ids():
		var quantity := _uncommitted_cargo_quantity(good_id)
		if quantity <= 0:
			continue
		var unit_price := MarketEconomy.price_for(good_id, settlement, context)
		var total := unit_price * quantity
		if best.is_empty() or total > int(best.get("total", 0)):
			best = {
				"good_id": good_id,
				"name": String(MarketContent.good(good_id).get("name", good_id.capitalize())),
				"quantity": quantity,
				"unit_price": unit_price,
				"total": total,
			}
	return best

func _uncommitted_cargo_quantity(good_id: String) -> int:
	var reserved_quantity := 0
	for contract_id in world.active_contracts.keys():
		var contract := world.active_contract(String(contract_id))
		if String(contract.get("good_id", "")) == good_id:
			reserved_quantity += int(contract.get("quantity", 0))
	return maxi(0, int(world.cargo.get(good_id, 0)) - reserved_quantity)

func _safest_affordable_recovery_route(available_money: int) -> Dictionary:
	var best: Dictionary = {}
	var destination_ids := MarketContent.destinations_from(world.current_settlement)
	destination_ids.sort()
	var route_ids := MarketContent.routes_from(world.current_settlement)
	route_ids.sort()
	for destination_id_value in destination_ids:
		var destination_id := String(destination_id_value)
		for route_id_value in route_ids:
			var route_id := String(route_id_value)
			if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
				continue
			var route := world.route(route_id, world.current_settlement, destination_id)
			var money_cost := int(route.get("cost", 0))
			var provision_cost := world.route_provision_cost(route_id, destination_id)
			if available_money < money_cost or world.provisions < provision_cost:
				continue
			var risk_percent := int(round(float(route.get("risk", 0.0)) * 100.0))
			if not best.is_empty():
				var best_risk := int(best.get("risk_percent", 0))
				var best_cost := int(best.get("money_cost", 0))
				if risk_percent > best_risk or (risk_percent == best_risk and money_cost >= best_cost):
					continue
			best = {
				"route_id": route_id,
				"route_name": String(route.get("name", route_id)),
				"destination_id": destination_id,
				"destination_name": String(world.settlement(destination_id).get("name", destination_id)),
				"money_cost": money_cost,
				"provision_cost": provision_cost,
				"risk_percent": risk_percent,
			}
	return best

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
	if event_scroll:
		event_scroll.scroll_vertical = 0

func _refresh_ui() -> void:
	_refresh_caravan_status()
	var journey_locked := not world.pending_event.is_empty() or arrival_pending
	var road_waiting: bool = map_panel != null and map_panel.travel_phase == "road"
	var actively_traveling: bool = map_panel != null and map_panel.travel_phase in ["moving_out", "moving_in"]
	if map_hint:
		if actively_traveling:
			map_hint.text = "The caravan is crossing the committed road. Travel presentation cannot change the resolved costs or risk."
		elif road_waiting:
			map_hint.text = "Mid-route view. Continue when you are ready to reveal the next road event or arrival."
		elif map_panel != null and map_panel.travel_phase == "encounter":
			map_hint.text = "Road encounter. Review the visible stakes and choose one available response."
		elif arrival_pending:
			map_hint.text = "Journey complete. Review the outcome, then enter the destination bazaar."
		else:
			map_hint.text = "Choose a settlement. HERE = current location; JOB = available assignment; ASSIGNED = accepted work."
	if event_label:
		if actively_traveling:
			event_label.text = "The caravan is moving through the selected corridor.\nNEXT — Watch for the road stop before any encounter or arrival."
		elif road_waiting:
			event_label.text = "MID-ROUTE — The caravan has reached a readable road stop.\nNEXT — Inspect the route, then continue the journey."
		elif arrival_pending and world.pending_event.is_empty() and last_conflict_outcome_text.is_empty() and not committed_journey_message.is_empty():
			event_label.text = "%s\nNEXT — Review the result, then choose Enter %s to trade at the destination." % [committed_journey_message, String(world.settlement(world.current_settlement).get("name", "the settlement"))]
	if departure_travel_actions:
		departure_travel_actions.visible = not journey_locked
	if departure_planning_panel:
		departure_planning_panel.visible = not journey_locked
	if continue_journey_button:
		continue_journey_button.visible = road_waiting
		continue_journey_button.disabled = actively_traveling
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
		if shop_title_label:
			shop_title_label.text = "%s BAZAAR" % String(settlement.get("name", "Settlement")).to_upper()
		var arms_rules := MarketContent.arms_trade_rules()
		var arms_label := String(arms_rules.get("noticed_label", "Noticed traffic")) if world.arms_escalation >= int(arms_rules.get("inspection_threshold", 2)) else String(arms_rules.get("quiet_label", "Quiet manifests"))
		var leads_text := " · Leads %d" % world.known_information.size() if not world.known_information.is_empty() else ""
		shop_status_label.text = "%s · Day %d · Crisis %d: %s\nTODAY'S NEED — %s\nResilience %d/10 · Wardens %+d · Caravans %+d · Arms %d/6 (%s)%s" % [String(settlement.get("role", "market")).capitalize(), world.day, world.crisis_stage, String(crisis.get("label", "Regional pressure")), String(crisis.get("objective", "Keep trading.")), world.resilience_for(world.current_settlement), int(world.reputation.get("wardens", 0)), int(world.reputation.get("caravans", 0)), world.arms_escalation, arms_label, leads_text]
		if not world.ending_id.is_empty():
			shop_status_label.text += "\nENDING — %s\n%s" % [String(MarketContent.ending(world.ending_id).get("title", world.ending_id)), world.ending_summary]
	if ending_panel and ending_label:
		ending_panel.visible = not world.ending_id.is_empty()
		if ending_panel.visible:
			var ending := MarketContent.ending(world.ending_id)
			ending_label.text = "CAMPAIGN CONCLUSION\n%s\n%s\n\nThis outcome is recorded in the save. You may continue trading to inspect the resulting region." % [String(ending.get("title", world.ending_id)), world.ending_summary]
	if campaign_outlook_label:
		campaign_outlook_label.text = _campaign_outlook_text()
	if recent_conflict_panel and recent_conflict_label:
		var recent_conflict_text := _latest_conflict_outcome_text()
		recent_conflict_panel.visible = not recent_conflict_text.is_empty()
		recent_conflict_label.text = "SINCE YOUR LAST VISIT — LAST CONFLICT\n" + recent_conflict_text if not recent_conflict_text.is_empty() else ""
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
		if actively_traveling:
			departure_status_label.text = "ON THE ROAD — The committed caravan is crossing the selected route. No additional choice is being resolved yet."
		elif road_waiting:
			departure_status_label.text = "ROAD VIEW — Inspect the journey, then continue to the next authored encounter or arrival."
		elif not world.pending_event.is_empty():
			departure_status_label.text = "ROUTE DECISION — Travel is paused until you choose. Costs already paid remain spent; each option states whether you continue or return."
		elif arrival_pending:
			departure_status_label.text = "ARRIVAL REPORT — %s\n%s\nReview what changed, then enter the settlement to trade again." % [String(world.settlement(world.current_settlement).get("name", "Unknown settlement")), String(event_label.text)]
		else:
			departure_status_label.text = "COMMITMENT CHECK — The map only shows legal corridors. Returning to the shop preserves this plan and spends nothing."
	if enter_settlement_button:
		enter_settlement_button.text = "Enter %s" % String(world.settlement(world.current_settlement).get("name", "settlement"))
		enter_settlement_button.visible = arrival_pending and map_panel != null and map_panel.travel_phase == "arrived"
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
	if game_layer != null and game_layer.visible:
		_request_map_layout_update()
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _refresh_caravan_status() -> void:
	status_label.text = "%s · %s\nDay %d · Crisis %d\n%d ashmarks · %d provisions\nHold %d/%d" % [String(world.settlement(world.current_settlement).name), map_panel._caravan_motion_label() if map_panel else "AT REST", world.day, world.crisis_stage, world.money, world.provisions, int(world.cargo.get("weight", 0)), world.cargo_capacity]
	if map_panel != null and map_panel.travel_phase in ["moving_out", "road", "moving_in"]:
		caravan_context_label.text = "PATH — SETTLEMENT > MAP > ROAD > ARRIVAL\nCURRENT — ON THE ROAD"
	elif not world.pending_event.is_empty():
		caravan_context_label.text = "PATH — SETTLEMENT > MAP > ROAD > ARRIVAL\nCURRENT — %s" % String(world.pending_event.get("title", "Route encounter"))
	elif arrival_pending:
		caravan_context_label.text = "PATH — SETTLEMENT > MAP > ROAD > ARRIVAL\nCURRENT — ARRIVAL REPORT"
	else:
		caravan_context_label.text = "PATH — SETTLEMENT > MAP > ROAD > ARRIVAL\nCURRENT — PLAN ROUTE"

class MapPanel extends Control:
	signal settlement_selected(settlement_id: String)
	signal travel_state_changed(state: String)

	const GRID_SIZE := Vector2i(17, 11)
	const NORMAL_BOARD_ORIGIN := Vector2(34, 230)
	const NORMAL_CELL_WIDTH := 44.0
	const MIN_CELL_WIDTH := 44.0
	const MAX_CELL_WIDTH := 56.0
	const NORMAL_CELL_HEIGHT := 20.0
	const MIN_CELL_HEIGHT := 14.0
	const MAP_HEADER_HEIGHT := 30.0
	const ENCOUNTER_PROGRESS := 0.39
	const ROUTE_IDS := ["old_road", "toll_road", "dry_cut"]
	const ROUTE_PROFILES := ["cheap / exposed", "safe / expensive", "fast / provision-heavy"]
	const SETTLEMENT_CELLS := {
		"ashgate": Vector2i(7, 6),
		"brine_cross": Vector2i(13, 2),
		"cinderford": Vector2i(11, 6),
		"hollow_market": Vector2i(4, 3),
		"reedwatch": Vector2i(14, 9)
	}

	var world
	var travel_route_id: String = ""
	var travel_origin_id: String = ""
	var travel_destination_id: String = ""
	var selected_route_id: String = ""
	var selected_destination_id: String = ""
	var hovered_settlement_id: String = ""
	var travel_points: Array[Vector2] = []
	var travel_progress: float = 1.0
	var traveling: bool = false
	var travel_phase: String = "rest"
	var reduce_motion: bool = false
	var text_scale: float = 1.0
	var board_origin: Vector2 = NORMAL_BOARD_ORIGIN
	var cell_width: float = NORMAL_CELL_WIDTH
	var cell_height: float = NORMAL_CELL_HEIGHT

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		if not traveling:
			return
		var target_progress: float = ENCOUNTER_PROGRESS if travel_phase == "moving_out" else 1.0
		travel_progress = minf(target_progress, travel_progress + delta / 1.8)
		if is_equal_approx(travel_progress, target_progress):
			traveling = false
			travel_phase = "road" if travel_phase == "moving_out" else "arrived"
			travel_state_changed.emit(_caravan_motion_label())
		queue_redraw()

	func set_text_scale(value: float) -> void:
		text_scale = value
		queue_redraw()

	func fit_vertical_space(top: float, bottom: float, available_width: float) -> void:
		board_origin = Vector2(NORMAL_BOARD_ORIGIN.x, maxf(NORMAL_BOARD_ORIGIN.y, top))
		cell_width = clampf((available_width - board_origin.x - 24.0) / float(GRID_SIZE.x), MIN_CELL_WIDTH, MAX_CELL_WIDTH)
		var available_height := maxf(0.0, bottom - board_origin.y)
		cell_height = clampf(available_height / float(GRID_SIZE.y), MIN_CELL_HEIGHT, NORMAL_CELL_HEIGHT)
		queue_redraw()

	func set_plan(route_id: String, destination_id: String) -> void:
		selected_route_id = route_id
		selected_destination_id = destination_id
		queue_redraw()

	func _board_rect() -> Rect2:
		return Rect2(board_origin, Vector2(GRID_SIZE.x * cell_width, GRID_SIZE.y * cell_height))

	func _cell_rect(cell: Vector2i) -> Rect2:
		return Rect2(board_origin + Vector2(cell.x * cell_width, cell.y * cell_height), Vector2(cell_width, cell_height))

	func _cell_center(cell: Vector2i) -> Vector2:
		return _cell_rect(cell).get_center()

	func _settlement_point(settlement_id: String) -> Vector2:
		return _cell_center(SETTLEMENT_CELLS.get(settlement_id, Vector2i.ZERO))

	func _settlement_marker_rect(settlement_id: String) -> Rect2:
		var cell: Vector2i = SETTLEMENT_CELLS.get(settlement_id, Vector2i.ZERO)
		return Rect2(_cell_rect(cell).position - Vector2(10, 8), Vector2(cell_width * 2.0 + 38, 40))

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
		var state_prefix := ""
		if settlement_id == world.current_settlement:
			state_prefix = "HERE · "
		elif _assignment_state(settlement_id) == "accepted":
			state_prefix = "ASSIGNED · "
		elif _assignment_state(settlement_id) == "available":
			state_prefix = "JOB · "
		elif settlement_id == selected_destination_id:
			state_prefix = "NEXT · "
		return "%sRES %d/10" % [state_prefix, world.resilience_for(settlement_id)]

	func _assignment_state(settlement_id: String) -> String:
		if world == null:
			return ""
		for contract_id_value in world.active_contracts.keys():
			var active: Dictionary = world.active_contract(String(contract_id_value))
			if String(active.get("destination_id", "")) == settlement_id:
				return "accepted"
		for contract in MarketContent.contracts_from(world.current_settlement):
			if String(contract.get("destination_id", "")) == settlement_id and not world.has_contract_outcome(String(contract.get("id", ""))):
				return "available"
		return ""

	func _route_to(settlement_id: String) -> String:
		if world == null:
			return ""
		for route_id in ROUTE_IDS:
			if MarketContent.route_connects(route_id, world.current_settlement, settlement_id):
				return route_id
		return ""

	func _hover_text(settlement_id: String) -> String:
		if world == null or settlement_id.is_empty():
			return ""
		var settlement: Dictionary = world.settlement(settlement_id)
		if settlement_id == world.current_settlement:
			return "%s\nCurrent bazaar · no travel cost" % String(settlement.get("name", settlement_id))
		var route_id := _route_to(settlement_id)
		if route_id.is_empty():
			return "%s\nNo direct road from %s" % [String(settlement.get("name", settlement_id)), String(world.settlement(world.current_settlement).get("name", "here"))]
		var route: Dictionary = world.route(route_id, world.current_settlement, settlement_id)
		var assignment := _assignment_state(settlement_id)
		var assignment_text := " · accepted assignment" if assignment == "accepted" else " · assignment available" if assignment == "available" else ""
		return "%s%s · %s\n%s · %d ashmarks · %d provisions · %d day" % [String(settlement.get("name", settlement_id)), assignment_text, String(settlement.get("role", "market")), String(route.get("name", route_id)), int(route.get("cost", 0)), world.route_provision_cost(route_id, settlement_id), int(route.get("days", 0))]

	func _font_size(base_size: int) -> int:
		return int(round(float(base_size) * text_scale))

	func _caravan_motion_label() -> String:
		match travel_phase:
			"moving_out", "moving_in":
				return "MOVING"
			"road":
				return "ON ROAD"
			"encounter":
				return "ENCOUNTER"
			"arrived":
				return "ARRIVED"
		return "AT REST"

	func _route_footer_rect(route_index: int) -> Rect2:
		var text := "%s: %s" % [_route_label(ROUTE_IDS[route_index]), ROUTE_PROFILES[route_index]]
		var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12))
		var footer_x: float = float([8.0, cell_width * 5.3, cell_width * 10.7][route_index])
		return Rect2(board_origin + Vector2(footer_x, _board_rect().size.y - text_size.y - 6.0), text_size)

	func _map_heading_rect() -> Rect2:
		var text_size := ThemeDB.fallback_font.get_string_size(_map_heading(), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(16))
		return Rect2(board_origin + Vector2(8, (MAP_HEADER_HEIGHT - text_size.y) / 2.0), text_size)

	func reset_travel(settlement_id: String) -> void:
		travel_route_id = ""
		travel_origin_id = settlement_id
		travel_destination_id = settlement_id
		travel_points.clear()
		travel_progress = 1.0
		traveling = false
		travel_phase = "rest"
		queue_redraw()

	func begin_travel(route_id: String, origin_id: String, destination_id: String) -> void:
		travel_route_id = route_id
		travel_origin_id = origin_id
		travel_destination_id = destination_id
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
		travel_progress = ENCOUNTER_PROGRESS if reduce_motion else 0.0
		traveling = not reduce_motion
		travel_phase = "road" if reduce_motion else "moving_out"
		travel_state_changed.emit(_caravan_motion_label())
		queue_redraw()

	func continue_from_road() -> void:
		if travel_phase != "road":
			return
		if world != null and not world.pending_event.is_empty():
			travel_phase = "encounter"
			traveling = false
		else:
			travel_phase = "arrived" if reduce_motion else "moving_in"
			traveling = not reduce_motion
			if reduce_motion:
				travel_progress = 1.0
		travel_state_changed.emit(_caravan_motion_label())
		queue_redraw()

	func restore_pending_travel(route_id: String, origin_id: String, destination_id: String) -> void:
		begin_travel(route_id, origin_id, destination_id)
		travel_progress = ENCOUNTER_PROGRESS
		traveling = false
		travel_phase = "encounter"
		travel_state_changed.emit(_caravan_motion_label())
		queue_redraw()

	func complete_travel() -> void:
		if travel_route_id.is_empty():
			travel_route_id = "completed_journey"
		travel_progress = 1.0
		traveling = false
		travel_phase = "arrived"
		travel_state_changed.emit(_caravan_motion_label())
		queue_redraw()

	func _caravan_position() -> Vector2:
		if travel_phase in ["moving_out", "road", "moving_in", "encounter"]:
			return _polyline_position(travel_points, travel_progress)
		return _settlement_point(world.current_settlement) if world != null else _settlement_point("ashgate")

	func _caravan_heading() -> float:
		if travel_points.size() < 2:
			return 0.0
		var before := _polyline_position(travel_points, maxf(0.0, travel_progress - 0.015))
		var after := _polyline_position(travel_points, minf(1.0, travel_progress + 0.015))
		return before.angle_to_point(after)

	func _draw_caravan(position: Vector2) -> void:
		var state := _caravan_motion_label()
		var accent := Color("#f0d27d")
		if state == "ENCOUNTER":
			accent = Color("#e07151")
			draw_circle(position, 28.0, Color(0.88, 0.33, 0.22, 0.16))
			draw_arc(position, 28.0, 0.0, TAU, 32, accent, 3.0, true)
		elif state == "MOVING":
			draw_line(position - Vector2(34, 0), position - Vector2(22, 0), Color(0.94, 0.82, 0.49, 0.42), 4.0)
		else:
			draw_line(position - Vector2(28, 20), position + Vector2(28, 20), Color("#85694e"), 2.0)
			draw_line(position + Vector2(28, -20), position - Vector2(28, 20), Color("#85694e"), 2.0)

		draw_set_transform(position, _caravan_heading() if state == "MOVING" else 0.0, Vector2.ONE)
		draw_colored_polygon(PackedVector2Array([Vector2(-24, 10), Vector2(-20, -9), Vector2(-12, -14), Vector2(13, -14), Vector2(24, -6), Vector2(25, 10)]), Color("#211914"))
		draw_polyline(PackedVector2Array([Vector2(-24, 10), Vector2(-20, -9), Vector2(-12, -14), Vector2(13, -14), Vector2(24, -6), Vector2(25, 10), Vector2(-24, 10)]), accent, 3.0, true)
		draw_rect(Rect2(-17, -18, 10, 14), Color("#4b382a"), true)
		draw_rect(Rect2(6, -20, 11, 16), Color("#4b382a"), true)
		draw_line(Vector2(-12, -18), Vector2(-12, -24), accent, 2.0)
		draw_line(Vector2(12, -20), Vector2(12, -27), accent, 2.0)
		draw_circle(Vector2(-13, 11), 6.0, Color("#17130f"))
		draw_circle(Vector2(15, 11), 6.0, Color("#17130f"))
		draw_circle(Vector2(-13, 11), 3.0, accent)
		draw_circle(Vector2(15, 11), 3.0, accent)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var label_size := ThemeDB.fallback_font.get_string_size(state, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(11))
		var label_offset_y := -43.0
		var label_rect := Rect2(position + Vector2(-label_size.x / 2.0 - 5.0, label_offset_y), label_size + Vector2(10.0, 6.0))
		draw_rect(label_rect, Color("#17130f"), true)
		draw_rect(label_rect, accent, false, 1.0)
		draw_string(ThemeDB.fallback_font, label_rect.position + Vector2(5.0, label_size.y + 1.0), state, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(11), accent)

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

	func _is_road_view() -> bool:
		return travel_phase in ["moving_out", "road", "moving_in", "encounter"]

	func _draw_road_scene() -> void:
		var board := _board_rect()
		draw_rect(board.grow(8), Color("#2a211b"), true)
		draw_rect(board, Color("#29231d"), true)
		var horizon_y := board.position.y + board.size.y * 0.43
		draw_colored_polygon(PackedVector2Array([
			board.position,
			board.position + Vector2(board.size.x, 0),
			Vector2(board.end.x, horizon_y - 8),
			Vector2(board.position.x, horizon_y + 18),
		]), Color("#40352b"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(board.position.x, horizon_y + 8),
			Vector2(board.end.x, horizon_y - 16),
			board.end,
			Vector2(board.position.x, board.end.y),
		]), Color("#241c17"))
		var road_center := board.position.x + board.size.x * 0.52
		draw_colored_polygon(PackedVector2Array([
			Vector2(road_center - 26, horizon_y),
			Vector2(road_center + 26, horizon_y),
			Vector2(road_center + board.size.x * 0.34, board.end.y),
			Vector2(road_center - board.size.x * 0.34, board.end.y),
		]), Color("#594635"))
		for index in range(7):
			var drift := fmod(float(index * 149) - travel_progress * 620.0, board.size.x + 100.0) - 50.0
			var post_x := board.position.x + drift
			var post_y := horizon_y + 24.0 + float(index % 3) * 22.0
			draw_line(Vector2(post_x, post_y), Vector2(post_x, post_y - 22), Color("#8d6847"), 3.0)
			draw_line(Vector2(post_x - 7, post_y - 17), Vector2(post_x + 7, post_y - 17), Color("#8d6847"), 2.0)
		var route_name := _route_label(travel_route_id).to_upper()
		var origin_name := String(world.settlement(travel_origin_id).get("name", travel_origin_id)) if world != null else travel_origin_id
		var destination_name := String(world.settlement(travel_destination_id).get("name", travel_destination_id)) if world != null else travel_destination_id
		draw_rect(Rect2(board.position, Vector2(board.size.x, MAP_HEADER_HEIGHT + 16.0)), Color("#17130f"), true)
		draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 21), "ON THE ROAD — %s" % route_name, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(16), Color("#e6c58d"))
		draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 39), "%s  >  %s" % [origin_name, destination_name], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(11), Color("#c7b49a"))
		var progress_y := board.end.y - 18.0
		draw_line(Vector2(board.position.x + 24, progress_y), Vector2(board.end.x - 24, progress_y), Color("#705746"), 4.0)
		draw_line(Vector2(board.position.x + 24, progress_y), Vector2(lerpf(board.position.x + 24, board.end.x - 24, travel_progress), progress_y), _route_color(travel_route_id), 4.0)
		draw_string(ThemeDB.fallback_font, Vector2(board.position.x + 24, progress_y - 7), "DEPART", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10), Color("#c7b49a"))
		var arrive_text_size := ThemeDB.fallback_font.get_string_size("ARRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10))
		draw_string(ThemeDB.fallback_font, Vector2(board.end.x - 24 - arrive_text_size.x, progress_y - 7), "ARRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10), Color("#c7b49a"))
		var caravan_position := Vector2(road_center, board.position.y + board.size.y * 0.67)
		if travel_phase == "encounter":
			draw_line(caravan_position + Vector2(58, -26), caravan_position + Vector2(58, 22), Color("#d08b62"), 5.0)
			draw_line(caravan_position + Vector2(42, -18), caravan_position + Vector2(74, -18), Color("#d08b62"), 4.0)
		_draw_caravan(caravan_position)

	func _draw_hover_card(settlement_id: String) -> void:
		var text := _hover_text(settlement_id)
		if text.is_empty():
			return
		var board := _board_rect()
		var marker := _settlement_marker_rect(settlement_id)
		var card_size := Vector2(minf(290.0, board.size.x * 0.42), 58.0)
		var card_position := marker.end + Vector2(8, -4)
		if card_position.x + card_size.x > board.end.x - 8:
			card_position.x = marker.position.x - card_size.x - 8
		card_position.y = clampf(card_position.y, board.position.y + MAP_HEADER_HEIGHT + 8.0, board.end.y - 34.0 - card_size.y)
		var card := Rect2(card_position, card_size)
		draw_rect(card, Color("#17130f"), true)
		draw_rect(card, Color("#e6c58d"), false, 2.0)
		draw_multiline_string(ThemeDB.fallback_font, card.position + Vector2(8, 18), text, HORIZONTAL_ALIGNMENT_LEFT, card.size.x - 16.0, _font_size(11), -1, Color("#f4e6c7"))

	func _gui_input(event: InputEvent) -> void:
		if _is_road_view():
			return
		if event is InputEventMouseMotion:
			var next_hover := ""
			for settlement_id_value in SETTLEMENT_CELLS.keys():
				var candidate_id := String(settlement_id_value)
				if _settlement_footprint(candidate_id).has_point(event.position):
					next_hover = candidate_id
					break
			if hovered_settlement_id != next_hover:
				hovered_settlement_id = next_hover
				queue_redraw()
			return
		if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		for settlement_id_value in SETTLEMENT_CELLS.keys():
			var settlement_id := String(settlement_id_value)
			if _settlement_footprint(settlement_id).has_point(event.position):
				settlement_selected.emit(settlement_id)
				accept_event()
				return

	func _draw() -> void:
		if _is_road_view():
			_draw_road_scene()
			return
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
			var is_selected: bool = route_id == selected_route_id
			var route_color := _route_color(route_id)
			if not selected_route_id.is_empty() and not is_selected:
				route_color.a = 0.28
			if is_selected:
				draw_polyline(PackedVector2Array(route_points), Color("#17130f"), 11.0, true)
			draw_polyline(PackedVector2Array(route_points), route_color, 7.0 if is_selected else 4.0, true)
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
			draw_string(ThemeDB.fallback_font, _route_footer_rect(route_index).position + Vector2(0, _font_size(12)), "%s: %s" % [_route_label(ROUTE_IDS[route_index]), ROUTE_PROFILES[route_index]], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12), _route_color(ROUTE_IDS[route_index]))
		for settlement_id_value in SETTLEMENT_CELLS.keys():
			var settlement_id := String(settlement_id_value)
			var footprint := _settlement_marker_rect(settlement_id)
			var is_current: bool = world != null and settlement_id == world.current_settlement
			var is_selected := settlement_id == selected_destination_id
			var assignment_state := _assignment_state(settlement_id)
			var fill := Color("#5a4027") if is_current else Color("#3b2b24")
			if assignment_state == "available":
				fill = Color("#34312d")
			elif assignment_state == "accepted":
				fill = Color("#28434a")
			draw_rect(footprint, fill, true)
			var outline := Color("#f0d27d") if is_current or is_selected else Color("#7d9ca4") if assignment_state == "accepted" else Color("#7b746d") if assignment_state == "available" else Color("#bd8553")
			draw_rect(footprint, outline, false, 4.0 if is_current or is_selected else 3.0)
			var name_text: String = String(settlement_id).replace("_", " ").capitalize()
			var text_inset := 56.0 if is_current else 5.0
			draw_string(ThemeDB.fallback_font, footprint.position + Vector2(text_inset, 18), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(12), Color("#f4e6c7"))
			draw_string(ThemeDB.fallback_font, footprint.position + Vector2(text_inset, 35), _settlement_marker_detail(settlement_id), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(11), Color("#c7b49a"))
		_draw_caravan(_caravan_position())
		var info_settlement := hovered_settlement_id if not hovered_settlement_id.is_empty() else selected_destination_id
		_draw_hover_card(info_settlement)
