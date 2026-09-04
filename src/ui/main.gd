extends Control

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")
const TutorialDirector = preload("res://src/ui/tutorial_director.gd")
const TradePresenter = preload("res://src/ui/trade_presenter.gd")
const JourneyPresenter = preload("res://src/ui/journey_presenter.gd")
const JourneyPanelView = preload("res://src/ui/journey_panel_view.gd")
const VisualRegistry = preload("res://src/ui/visual_registry.gd")
const BazaarSceneView = preload("res://src/ui/bazaar_scene.gd")
const JourneyMapPanel = preload("res://src/ui/journey_map_panel.gd")

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
const INTRO_PAGES := [
	{
		"eyebrow": "THE FIVE-WELL BASIN",
		"title": "The roads are open. The wells are failing.",
		"body": "Water, medicine, and trust rarely arrive together. A small caravan can turn scarcity into relief, influence, or profit.",
		"scene": "basin",
	},
	{
		"eyebrow": "YOUR CARAVAN",
		"title": "Every load is a promise.",
		"body": "Ashmarks buy cargo and passage. Provisions keep you moving. Hold space limits your load. Crew reveals roads, saves supplies, or changes how people receive you.",
		"scene": "caravan",
	},
	{
		"eyebrow": "TRADE · ROAD · CONSEQUENCE",
		"title": "A cheap road always exposes something.",
		"body": "Read the need. Compare fee, time, provisions, and cargo at risk. Face the road, arrive changed, and decide what to do next.",
		"scene": "road",
	},
]
const DEFAULT_SAVE_PATH := "user://market_of_ash_prototype.save"
const DEFAULT_SETTINGS_PATH := "user://market_of_ash_settings.cfg"
const DEFAULT_REPORT_PATH := "user://market_of_ash_playtest_report.json"
const WEB_REPORT_FILENAME := "market_of_ash_playtest_report.json"
const MAX_PACING_TRACE_ENTRIES := 256
const SAVE_ENVELOPE_FORMAT := "market_of_ash_campaign"
const SAVE_ENVELOPE_VERSION := 1
const MAX_SAVE_BYTES := 5 * 1024 * 1024
const REMAPPABLE_ACTIONS := ["ui_accept", "ui_cancel", "ui_pause"]
const ACTION_LABELS := {"ui_accept": "Accept", "ui_cancel": "Back", "ui_pause": "Pause"}
const DEFAULT_KEY_BINDINGS := {"ui_accept": [KEY_ENTER, KEY_SPACE], "ui_cancel": [KEY_ESCAPE], "ui_pause": [KEY_P]}
const DEFAULT_CONTROLLER_BINDINGS := {"ui_accept": [JOY_BUTTON_A], "ui_cancel": [JOY_BUTTON_B], "ui_pause": [JOY_BUTTON_START]}
const RESERVED_REMAP_KEYS := [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
const RESERVED_CONTROLLER_BUTTONS := [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT]
const AUDIO_CUE_PATHS := {
	"success": "res://assets/temporary/selected-audio/command-success.oggstr",
	"blocked": "res://assets/temporary/selected-audio/command-blocked.oggstr",
	"travel": "res://assets/temporary/selected-audio/caravan-departure.oggstr",
	"information": "res://assets/temporary/selected-audio/guide-intel-open.oggstr",
	"trade": "res://assets/temporary/selected-audio/trade-complete.oggstr",
}
const COMPACT_OPENING_WINDOW_WIDTH := 1280
const ROUTE_CARD_HEIGHT := 200.0
const ROUTE_CARD_LARGE_TEXT_HEIGHT := 260.0
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
var shop_background: ColorRect
var shop_market_card: PanelContainer
var shop_action_card: PanelContainer
var menu_layer: Control
var intro_layer: Control
var menu_columns
var intro_columns
var intro_scene
var intro_title_label: Label
var intro_body_label: RichTextLabel
var intro_progress_label: Label
var intro_back_button: Button
var intro_next_button: Button
var intro_skip_button: Button
var intro_page := 0
var settings_panel: Control
var credits_panel: Control
var developer_panel: Control
var settings_button: Button
var credits_button: Button
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
var trade_receipt_panel: PanelContainer
var trade_receipt_title_label: Label
var trade_receipt_detail_label: Label
var trade_receipt_tween: Tween
var trade_receipt_generation := 0
var shop_status_label: Label
var shop_cargo_label: Label
var shop_decision_summary_panel: PanelContainer
var shop_decision_summary_label: Label
var shop_decision_path_label: Label
var shop_decision_cargo_label: Label
var shop_decision_journey_label: Label
var shop_decision_metric_values: Dictionary = {}
var shop_decision_road_label: Label
var shop_decision_resources_label: Label
var shop_decision_reason_label: Label
var shop_decision_next_label: Label
var shop_title_label: Label
var bazaar_navigation_buttons: Array[Button] = []
var bazaar_section_label: Label
var bazaar_scene
var shop_market_scroll: ScrollContainer
var shop_action_scroll: ScrollContainer
var shop_purchase_row: HBoxContainer
var active_bazaar_section := "trade"
var shop_save_button: Button
var shop_load_button: Button
var shop_reset_button: Button
var shop_report_button: Button
var opportunity_status_label: Label
var opportunity_title_label: Label
var opportunity_list: VBoxContainer
var opportunity_buttons: Array[Button] = []
var contract_buttons: Array[Button] = []
var crew_buttons: Array[Button] = []
var crew_profile_cards: Array[PanelContainer] = []
var active_contract_label: Label
var campaign_outlook_label: Label
var recent_conflict_panel: PanelContainer
var recent_conflict_label: Label
var ending_panel: PanelContainer
var ending_label: Label
var ending_continue_button: Button
var ending_replay_button: Button
var ending_title_button: Button
var ending_feedback_button: Button
var ending_debrief_dismissed := false
var last_presented_ending_id := ""
var plan_departure_button: Button
var departure_travel_actions: HBoxContainer
var return_to_shop_button: Button
var commit_departure_button: Button
var continue_journey_button: Button
var enter_settlement_button: Button
var departure_load_label: Label
var departure_contract_label: Label
var departure_status_label: Label
var journey_phase_title_label: Label
var departure_planning_panel: VBoxContainer
var event_card: PanelContainer
var event_mode_label: Label
var event_title_label: Label
var event_setup_label: Label
var event_stakes_label: Label
var event_threat_label: Label
var event_exposed_label: Label
var event_route_label: Label
var event_basis_label: Label
var event_decision_label: Label
var event_rules_label: Label
var event_readiness_label: Label
var event_choice_list: VBoxContainer
var event_choice_buttons: Array[Button] = []
var event_choice_reason_labels: Array[Label] = []
var conflict_outcome_panel: PanelContainer
var conflict_outcome_receipt: PanelContainer
var conflict_outcome_receipt_glyph
var conflict_outcome_receipt_kicker: Label
var conflict_outcome_receipt_title: Label
var conflict_outcome_receipt_detail: Label
var conflict_outcome_label: Label
var last_conflict_outcome_text := ""
var committed_journey_message := ""
var arrival_pending := false
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
var route_comparison_grid: GridContainer
var route_comparison_buttons: Array[Button] = []
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
var pacing_session_started_msec := 0
var pacing_trace: Array[Dictionary] = []
var last_pacing_context_id := ""
var active_playtest_path_id := ""
var pending_new_game_path_id := PLAYTEST_PATH_CAMPAIGN
var pending_tutorial_enabled := true
var tutorial := TutorialDirector.new()
var last_tutorial_presented_step := ""
var tutorial_panel: PanelContainer
var tutorial_chapter_label: Label
var tutorial_title_label: Label
var tutorial_body_label: Label
var tutorial_skip_button: Button
var last_input_device := "unknown"
var map_panel
var web_accessibility_callback: Variant
var web_accessibility_control_callback: Variant
var web_accessibility_key_callback: Variant
var initial_window_fit_pending := true
var initial_window_fit_recheck_scheduled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fit_initial_window_to_display()
	run_started_msec = Time.get_ticks_msec()
	pacing_session_started_msec = run_started_msec
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
	_build_intro()
	_build_pause_menu()
	_refresh_responsive_layout()
	_schedule_initial_window_fit_recheck()
	_refresh_continue_availability()
	if large_text_enabled:
		_apply_text_scale(self, 1.25)
	_setup_web_accessibility_bridge()
	_show_main_menu()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED and is_inside_tree():
		call_deferred("_refresh_responsive_layout")
		if initial_window_fit_pending:
			_schedule_initial_window_fit_recheck()

func _fit_initial_window_to_display() -> void:
	var window_mode := DisplayServer.window_get_mode()
	if OS.has_feature("web") or DisplayServer.get_name() == "headless" or not _startup_window_mode_allows_fit(window_mode):
		return
	if OS.get_cmdline_user_args().has("--output-dir"):
		return
	var screen := DisplayServer.window_get_current_screen()
	var usable_rect := DisplayServer.screen_get_usable_rect(screen)
	var screen_size := DisplayServer.screen_get_size(screen)
	var current_size := DisplayServer.window_get_size()
	var available_size := _effective_display_size(usable_rect.size, screen_size)
	var target_size := _clamped_window_size(current_size, available_size)
	if target_size == current_size:
		return
	if window_mode == DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(target_size)
	var placement_size := usable_rect.size if usable_rect.size.x > 0 and usable_rect.size.y > 0 else available_size
	DisplayServer.window_set_position(usable_rect.position + (placement_size - target_size) / 2)

func _startup_window_mode_allows_fit(window_mode: int) -> bool:
	return window_mode in [DisplayServer.WINDOW_MODE_WINDOWED, DisplayServer.WINDOW_MODE_MAXIMIZED]

func _schedule_initial_window_fit_recheck() -> void:
	if initial_window_fit_recheck_scheduled or not initial_window_fit_pending:
		return
	initial_window_fit_recheck_scheduled = true
	call_deferred("_settle_initial_window_fit")

func _settle_initial_window_fit() -> void:
	for _attempt in range(4):
		await get_tree().process_frame
		_fit_initial_window_to_display()
	initial_window_fit_pending = false
	initial_window_fit_recheck_scheduled = false
	_refresh_responsive_layout()

func _effective_display_size(usable_size: Vector2i, screen_size: Vector2i) -> Vector2i:
	if usable_size.x <= 0 or usable_size.y <= 0:
		return screen_size
	if screen_size.x <= 0 or screen_size.y <= 0:
		return usable_size
	return Vector2i(mini(usable_size.x, screen_size.x), mini(usable_size.y, screen_size.y))

func _clamped_window_size(current_size: Vector2i, usable_size: Vector2i) -> Vector2i:
	if current_size.x <= 0 or current_size.y <= 0 or usable_size.x <= 0 or usable_size.y <= 0:
		return current_size
	var fit_scale := minf(1.0, minf(float(usable_size.x) / float(current_size.x), float(usable_size.y) / float(current_size.y)))
	return Vector2i(floori(float(current_size.x) * fit_scale), floori(float(current_size.y) * fit_scale))

func _refresh_responsive_layout() -> void:
	var compact := _opening_layout_should_compact(_opening_layout_width())
	if menu_columns != null:
		menu_columns.set_compact(compact)
	if intro_columns != null:
		intro_columns.set_compact(compact)

func _opening_layout_width() -> int:
	var window_width := _report_viewport_size().x
	if window_width > 0:
		return window_width
	var visible_width := floori(get_viewport().get_visible_rect().size.x)
	return visible_width if visible_width > 0 else COMPACT_OPENING_WINDOW_WIDTH

func _opening_layout_should_compact(viewport_width: int) -> bool:
	return viewport_width <= COMPACT_OPENING_WINDOW_WIDTH

func _build_main_menu() -> void:
	menu_layer = Control.new()
	menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color("#100d0a")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_layer.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_bottom", 32)
	menu_layer.add_child(margin)
	menu_columns = ResponsiveColumns.new()
	menu_columns.name = "MainMenuLayout"
	menu_columns.separation = 20.0
	menu_columns.first_ratio = 1.5
	menu_columns.compact_visual_height = 160.0
	var columns: Container = menu_columns
	margin.add_child(columns)
	var title_scene := TitleScene.new()
	title_scene.custom_minimum_size = Vector2(420, 0)
	title_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_scene.size_flags_stretch_ratio = 1.5
	columns.add_child(title_scene)
	var card := PanelContainer.new()
	card.name = "MainMenuCard"
	card.custom_minimum_size = Vector2(440, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	columns.add_child(card)
	var scroll := ScrollContainer.new()
	scroll.name = "MainMenuScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	card.add_child(scroll)
	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 18)
	content_margin.add_theme_constant_override("margin_top", 2)
	content_margin.add_theme_constant_override("margin_right", 18)
	scroll.add_child(content_margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	content_margin.add_child(content)

	var heading := Label.new()
	heading.name = "MainMenuHeading"
	heading.text = "CARAVAN LEDGER"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_color_override("font_color", Color("#e6c58d"))
	content.add_child(heading)
	var welcome := Label.new()
	welcome.name = "MainMenuWelcome"
	welcome.text = "Trade between settlements. Choose what the road may cost. Help decide what the basin becomes."
	welcome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	welcome.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	welcome.add_theme_color_override("font_color", Color("#c7b49a"))
	content.add_child(welcome)
	start_game_button = Button.new()
	start_game_button.name = "MainMenuPrimaryAction"
	start_game_button.text = "New Game"
	start_game_button.custom_minimum_size = Vector2(0, 58)
	start_game_button.tooltip_text = "Begin a new campaign, with an optional guided first caravan run."
	start_game_button.pressed.connect(_on_new_game_pressed)
	content.add_child(start_game_button)
	continue_game_button = Button.new()
	continue_game_button.name = "MainMenuContinueAction"
	continue_game_button.text = "Continue"
	continue_game_button.custom_minimum_size = Vector2(0, 52)
	continue_game_button.disabled = not FileAccess.file_exists(save_path)
	continue_game_button.tooltip_text = "No saved campaign exists yet." if continue_game_button.disabled else "Validate and continue the saved campaign."
	continue_game_button.pressed.connect(_on_load_pressed)
	content.add_child(continue_game_button)
	settings_button = Button.new()
	settings_button.name = "MainMenuSettingsAction"
	settings_button.text = "Settings"
	settings_button.custom_minimum_size = Vector2(0, 48)
	settings_button.pressed.connect(_on_settings_pressed)
	content.add_child(settings_button)
	credits_button = Button.new()
	credits_button.name = "MainMenuCreditsAction"
	credits_button.text = "Credits"
	credits_button.custom_minimum_size = Vector2(0, 48)
	credits_button.pressed.connect(_on_credits_pressed)
	content.add_child(credits_button)
	menu_save_status_label = Label.new()
	menu_save_status_label.name = "MainMenuSaveStatus"
	menu_save_status_label.text = save_status_text
	menu_save_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_save_status_label.add_theme_font_size_override("font_size", 11)
	menu_save_status_label.add_theme_color_override("font_color", Color("#8f8374"))
	content.add_child(menu_save_status_label)

	settings_panel = VBoxContainer.new()
	settings_panel.visible = false
	settings_panel.add_theme_constant_override("separation", 10)
	content.add_child(settings_panel)
	var settings_title := Label.new()
	settings_title.text = "SETTINGS"
	settings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_title.add_theme_color_override("font_color", Color("#e6c58d"))
	settings_panel.add_child(settings_title)
	controls_hint_label = Label.new()
	controls_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	controls_hint_label.add_theme_color_override("font_color", Color("#c7b49a"))
	settings_panel.add_child(controls_hint_label)
	reduce_motion_checkbox = CheckBox.new()
	reduce_motion_checkbox.text = "Reduce travel motion"
	reduce_motion_checkbox.custom_minimum_size = Vector2(0, 44)
	reduce_motion_checkbox.tooltip_text = "Skip caravan travel animation and brief interface flourishes; route outcomes and timing are unchanged."
	reduce_motion_checkbox.button_pressed = reduce_motion_enabled
	reduce_motion_checkbox.toggled.connect(_on_reduce_motion_toggled)
	settings_panel.add_child(reduce_motion_checkbox)
	large_text_checkbox = CheckBox.new()
	large_text_checkbox.text = "Large text"
	large_text_checkbox.custom_minimum_size = Vector2(0, 44)
	large_text_checkbox.tooltip_text = "Increase interface text by 25%. Long shop and route panels remain scrollable."
	large_text_checkbox.button_pressed = large_text_enabled
	large_text_checkbox.toggled.connect(_on_large_text_toggled)
	settings_panel.add_child(large_text_checkbox)
	interface_sounds_checkbox = CheckBox.new()
	interface_sounds_checkbox.text = "Interface sounds"
	interface_sounds_checkbox.custom_minimum_size = Vector2(0, 44)
	interface_sounds_checkbox.tooltip_text = "Play restrained confirmation, blocked-action, and travel cues. All essential feedback remains visible as text."
	interface_sounds_checkbox.button_pressed = interface_sounds_enabled
	interface_sounds_checkbox.toggled.connect(_on_interface_sounds_toggled)
	settings_panel.add_child(interface_sounds_checkbox)
	var bindings_title := Label.new()
	bindings_title.text = "INPUT BINDINGS"
	bindings_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bindings_title.add_theme_color_override("font_color", Color("#e6c58d"))
	settings_panel.add_child(bindings_title)
	var binding_row := HBoxContainer.new()
	binding_row.alignment = BoxContainer.ALIGNMENT_CENTER
	binding_row.add_theme_constant_override("separation", 8)
	settings_panel.add_child(binding_row)
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
	settings_panel.add_child(restore_bindings_button)
	binding_status_label = Label.new()
	binding_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	binding_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	binding_status_label.add_theme_font_size_override("font_size", 11)
	binding_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	settings_panel.add_child(binding_status_label)

	credits_panel = VBoxContainer.new()
	credits_panel.visible = false
	content.add_child(credits_panel)
	var credits_text := Label.new()
	credits_text.text = "MARKET OF ASH\nA trade-and-travel RPG in development.\n\nDesigned around commerce, consequence, and the people who keep a road open."
	credits_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credits_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	credits_text.add_theme_color_override("font_color", Color("#c7b49a"))
	credits_panel.add_child(credits_text)

	developer_panel = VBoxContainer.new()
	developer_panel.visible = false
	developer_panel.add_theme_constant_override("separation", 8)
	content.add_child(developer_panel)
	var developer_title := Label.new()
	developer_title.text = "DEVELOPER TOOLS"
	developer_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	developer_title.add_theme_color_override("font_color", Color("#d08b62"))
	developer_panel.add_child(developer_title)
	start_conflict_button = Button.new()
	start_conflict_button.text = "Scenario: Toll Road conflict"
	start_conflict_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_conflict_button.custom_minimum_size = Vector2(0, 44)
	start_conflict_button.pressed.connect(_on_developer_scenario_requested.bind(PLAYTEST_PATH_CONFLICT))
	developer_panel.add_child(start_conflict_button)
	start_campaign_button = Button.new()
	start_campaign_button.text = "Scenario: Contract and crew"
	start_campaign_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	start_campaign_button.custom_minimum_size = Vector2(0, 44)
	start_campaign_button.pressed.connect(_on_developer_scenario_requested.bind(PLAYTEST_PATH_CAMPAIGN))
	developer_panel.add_child(start_campaign_button)
	var developer_report_button := Button.new()
	developer_report_button.text = "Export diagnostic report"
	developer_report_button.custom_minimum_size = Vector2(0, 44)
	developer_report_button.pressed.connect(_on_export_report_pressed)
	developer_panel.add_child(developer_report_button)
	quit_button = Button.new()
	quit_button.name = "MainMenuQuitAction"
	quit_button.text = "Quit"
	quit_button.custom_minimum_size = Vector2(0, 44)
	quit_button.tooltip_text = "Close the desktop build. Browser builds use the browser tab instead."
	quit_button.visible = not OS.has_feature("web")
	quit_button.pressed.connect(_on_quit_pressed)
	content.add_child(quit_button)
	_refresh_binding_labels()

func _on_settings_pressed() -> void:
	settings_panel.visible = not settings_panel.visible
	credits_panel.visible = false
	developer_panel.visible = false
	_link_main_menu_focus_cycle()
	if settings_panel.visible:
		_grab_focus_if_available(reduce_motion_checkbox)
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _on_credits_pressed() -> void:
	credits_panel.visible = not credits_panel.visible
	settings_panel.visible = false
	developer_panel.visible = false
	_link_main_menu_focus_cycle()
	_grab_focus_if_available(credits_button)
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _on_developer_scenario_requested(path_id: String) -> void:
	pending_tutorial_enabled = false
	_on_start_game_requested(path_id)

func _build_intro() -> void:
	intro_layer = Control.new()
	intro_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_layer.visible = false
	add_child(intro_layer)
	var backdrop := ColorRect.new()
	backdrop.color = Color("#100d0a")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	intro_layer.add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 48)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 40)
	intro_layer.add_child(margin)
	intro_columns = ResponsiveColumns.new()
	intro_columns.name = "IntroductionLayout"
	intro_columns.separation = 30.0
	intro_columns.first_ratio = 1.35
	intro_columns.compact_visual_height = 220.0
	intro_columns.clip_contents = true
	var columns: Container = intro_columns
	margin.add_child(columns)
	intro_scene = IntroScene.new()
	intro_scene.custom_minimum_size = Vector2(620, 0)
	intro_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_scene.size_flags_stretch_ratio = 1.55
	columns.add_child(intro_scene)
	var card := PanelContainer.new()
	card.name = "IntroductionCard"
	card.custom_minimum_size = Vector2(420, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.clip_contents = true
	columns.add_child(card)
	var content_margin := MarginContainer.new()
	content_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_margin.add_theme_constant_override("margin_left", 16)
	content_margin.add_theme_constant_override("margin_top", 2)
	content_margin.add_theme_constant_override("margin_right", 16)
	card.add_child(content_margin)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	content_margin.add_child(content)
	intro_progress_label = Label.new()
	intro_progress_label.name = "IntroductionProgress"
	intro_progress_label.add_theme_color_override("font_color", Color("#d08b62"))
	content.add_child(intro_progress_label)
	intro_title_label = Label.new()
	intro_title_label.name = "IntroductionTitle"
	intro_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_title_label.add_theme_font_size_override("font_size", 28)
	intro_title_label.add_theme_color_override("font_color", Color("#e6c58d"))
	content.add_child(intro_title_label)
	var body_scroll := ScrollContainer.new()
	body_scroll.name = "IntroductionBodyScroll"
	body_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body_scroll.custom_minimum_size = Vector2(0, 72)
	content.add_child(body_scroll)
	intro_body_label = RichTextLabel.new()
	intro_body_label.name = "IntroductionBody"
	intro_body_label.bbcode_enabled = false
	intro_body_label.fit_content = false
	intro_body_label.scroll_active = false
	intro_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	intro_body_label.custom_minimum_size = Vector2(0, 72)
	intro_body_label.add_theme_font_size_override("font_size", 18)
	intro_body_label.add_theme_color_override("font_color", Color("#d9c6a2"))
	body_scroll.add_child(intro_body_label)
	var note := Label.new()
	note.name = "IntroductionNote"
	note.text = "Guidance marks the next useful action. Every load, road cost, and consequence remains yours to choose."
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_font_size_override("font_size", 12)
	note.add_theme_color_override("font_color", Color("#8f8374"))
	content.add_child(note)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	content.add_child(buttons)
	intro_back_button = Button.new()
	intro_back_button.name = "IntroductionBackAction"
	intro_back_button.text = "Back"
	intro_back_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_back_button.custom_minimum_size = Vector2(0, 52)
	intro_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_back_button.pressed.connect(_on_intro_back_pressed)
	buttons.add_child(intro_back_button)
	intro_next_button = Button.new()
	intro_next_button.name = "IntroductionPrimaryAction"
	intro_next_button.text = "Next"
	intro_next_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_next_button.custom_minimum_size = Vector2(0, 52)
	intro_next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intro_next_button.pressed.connect(_on_intro_next_pressed)
	buttons.add_child(intro_next_button)
	intro_skip_button = Button.new()
	intro_skip_button.name = "IntroductionSkipAction"
	intro_skip_button.text = "Start without guidance"
	intro_skip_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_skip_button.custom_minimum_size = Vector2(0, 48)
	intro_skip_button.pressed.connect(_on_intro_skip_pressed)
	content.add_child(intro_skip_button)
	_link_focus_cycle([intro_back_button, intro_next_button, intro_skip_button])

func _on_new_game_pressed() -> void:
	intro_page = 0
	menu_layer.visible = false
	intro_layer.visible = true
	_refresh_intro_page()
	_grab_focus_if_available(intro_next_button)

func _refresh_intro_page() -> void:
	var page: Dictionary = INTRO_PAGES[intro_page]
	intro_progress_label.text = "%s\nINTRODUCTION %d OF %d" % [String(page.get("eyebrow", "")), intro_page + 1, INTRO_PAGES.size()]
	intro_title_label.text = String(page.get("title", ""))
	intro_body_label.text = String(page.get("body", ""))
	intro_back_button.text = "Main Menu" if intro_page == 0 else "Back"
	intro_next_button.text = "Begin Guided Campaign" if intro_page == INTRO_PAGES.size() - 1 else "Next"
	intro_scene.set_scene(String(page.get("scene", "basin")))
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _on_intro_back_pressed() -> void:
	if intro_page > 0:
		intro_page -= 1
		_refresh_intro_page()
		_grab_focus_if_available(intro_next_button)
		return
	intro_layer.visible = false
	_show_main_menu()

func _on_intro_next_pressed() -> void:
	if intro_page < INTRO_PAGES.size() - 1:
		intro_page += 1
		_refresh_intro_page()
		return
	_begin_new_campaign(true)

func _on_intro_skip_pressed() -> void:
	_begin_new_campaign(false)

func _begin_new_campaign(with_tutorial: bool) -> void:
	pending_tutorial_enabled = with_tutorial
	pending_new_game_path_id = PLAYTEST_PATH_CAMPAIGN if with_tutorial else PLAYTEST_PATH_GUIDED
	_on_start_game_requested(pending_new_game_path_id)

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
	pause_save_button.text = "Save Game"
	pause_save_button.custom_minimum_size = Vector2(0, 44)
	pause_save_button.pressed.connect(_on_save_pressed)
	content.add_child(pause_save_button)
	pause_load_button = Button.new()
	pause_load_button.text = "Load Game"
	pause_load_button.custom_minimum_size = Vector2(0, 44)
	pause_load_button.pressed.connect(_on_pause_load_pressed)
	content.add_child(pause_load_button)
	pause_report_button = Button.new()
	pause_report_button.text = "Export playtest report"
	pause_report_button.custom_minimum_size = Vector2(0, 44)
	pause_report_button.tooltip_text = "Write build, pacing timeline, campaign summary, command history, and game log locally without personal data."
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
	_dismiss_trade_receipt()
	if pause_layer:
		pause_layer.visible = false
	game_layer.visible = false
	shop_layer.visible = false
	intro_layer.visible = false
	menu_layer.visible = true
	settings_panel.visible = false
	credits_panel.visible = false
	developer_panel.visible = false
	_link_main_menu_focus_cycle()
	if start_game_button:
		start_game_button.grab_focus()
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

func _refresh_start_button_labels(requires_confirmation: bool) -> void:
	var confirmation_note := " Existing campaign files remain until the new run's first successful autosave." if requires_confirmation else ""
	if start_game_button:
		start_game_button.text = "New Game"
		start_game_button.tooltip_text = "Begin a new campaign, with an optional guided first caravan run.%s" % confirmation_note

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
	intro_layer.visible = false
	game_layer.visible = false
	shop_layer.visible = true
	arrival_pending = false
	last_conflict_outcome_text = ""
	committed_journey_message = ""
	active_bazaar_section = "trade"
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
	if ending_panel != null and ending_panel.visible:
		_grab_focus_if_available(ending_continue_button)
	elif not _grab_focus_if_available(shop_buy_button):
		_grab_focus_if_available(shop_good_option)
	if shop_market_scroll:
		shop_market_scroll.scroll_vertical = 0
	if shop_action_scroll:
		shop_action_scroll.scroll_vertical = 0

func _show_departure() -> void:
	_dismiss_trade_receipt()
	shop_layer.visible = false
	intro_layer.visible = false
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
		_grab_focus_if_available(_selected_route_comparison_button())

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
	for route_card in route_comparison_buttons:
		route_card.custom_minimum_size.y = ROUTE_CARD_LARGE_TEXT_HEIGHT if enabled else ROUTE_CARD_HEIGHT
	if map_panel:
		map_panel.set_text_scale(1.25 if enabled else 1.0)
	if bazaar_scene:
		bazaar_scene.set_text_scale(1.25 if enabled else 1.0)
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
	audio_player.volume_db = -18.0
	add_child(audio_player)
	for cue_id in AUDIO_CUE_PATHS:
		var stream := _load_ogg_cue(String(AUDIO_CUE_PATHS[cue_id]))
		if stream == null:
			push_error("Could not load interface audio cue: %s" % AUDIO_CUE_PATHS[cue_id])
			continue
		audio_cues[cue_id] = stream

func _load_ogg_cue(resource_path: String) -> AudioStreamOggVorbis:
	if not FileAccess.file_exists(resource_path):
		return null
	var encoded_audio := FileAccess.get_file_as_bytes(resource_path)
	if encoded_audio.is_empty():
		return null
	return AudioStreamOggVorbis.load_from_buffer(encoded_audio)

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
	shop_background = ColorRect.new()
	shop_background.color = Color("#17130f")
	shop_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shop_layer.add_child(shop_background)

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

	shop_market_card = PanelContainer.new()
	shop_market_card.name = "BazaarMarketPanel"
	shop_market_card.custom_minimum_size = Vector2(690, 0)
	shop_market_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_market_card.size_flags_stretch_ratio = 1.8
	columns.add_child(shop_market_card)
	var market_shell := VBoxContainer.new()
	market_shell.add_theme_constant_override("separation", 10)
	shop_market_card.add_child(market_shell)
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
	var bazaar_entries := [
		{"id": "trade", "label": "Market Stall"},
		{"id": "assignments", "label": "Job Board"},
		{"id": "information", "label": "Guide / Intel"},
		{"id": "crew", "label": "Crew Yard"},
		{"id": "outlook", "label": "Town Outlook"},
	]
	for entry_index in range(bazaar_entries.size()):
		var entry: Dictionary = bazaar_entries[entry_index]
		var bazaar_button := Button.new()
		bazaar_button.text = String(entry.label)
		bazaar_button.toggle_mode = true
		bazaar_button.custom_minimum_size = Vector2(0, 58)
		bazaar_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_style_bazaar_navigation_button(bazaar_button, entry_index)
		bazaar_button.set_meta("web_accessibility_id", "bazaar_%s" % String(entry.id))
		bazaar_button.pressed.connect(_on_bazaar_navigation_pressed.bind(String(entry.id)))
		bazaar_navigation.add_child(bazaar_button)
		bazaar_navigation_buttons.append(bazaar_button)
	shop_status_label = Label.new()
	shop_status_label.name = "BazaarMarketStatus"
	shop_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_status_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	market_shell.add_child(shop_status_label)
	shop_cargo_label = Label.new()
	shop_cargo_label.name = "BazaarCargoStatus"
	shop_cargo_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_cargo_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	market_shell.add_child(shop_cargo_label)
	bazaar_scene = BazaarSceneView.new()
	bazaar_scene.custom_minimum_size = Vector2(620, 140)
	bazaar_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bazaar_scene.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bazaar_scene.set_text_scale(1.25 if large_text_enabled else 1.0)
	market_shell.add_child(bazaar_scene)
	shop_market_scroll = ScrollContainer.new()
	shop_market_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_market_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	shop_market_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	market_shell.add_child(shop_market_scroll)
	var market := VBoxContainer.new()
	market.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	market.add_theme_constant_override("separation", 14)
	shop_market_scroll.add_child(market)
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
	shop_market_preview_label.name = "BazaarPricePreview"
	shop_market_preview_label.custom_minimum_size = Vector2(620, 152)
	market.add_child(shop_market_preview_label)
	shop_purchase_row = HBoxContainer.new()
	shop_purchase_row.add_theme_constant_override("separation", 12)
	market_shell.add_child(shop_purchase_row)
	shop_buy_button = Button.new()
	shop_buy_button.name = "BuyCargoButton"
	shop_buy_button.text = "Buy cargo"
	shop_buy_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_buy_button.custom_minimum_size = Vector2(0, 56)
	shop_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_buy_button.tooltip_text = "Buy the selected cargo from this settlement."
	shop_buy_button.pressed.connect(_on_buy_pressed)
	shop_purchase_row.add_child(shop_buy_button)
	shop_sell_button = Button.new()
	shop_sell_button.name = "SellCargoButton"
	shop_sell_button.text = "Sell selected cargo"
	shop_sell_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_sell_button.custom_minimum_size = Vector2(0, 56)
	shop_sell_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_sell_button.tooltip_text = "Sell the selected cargo held by the caravan."
	shop_sell_button.pressed.connect(_on_sell_pressed)
	shop_purchase_row.add_child(shop_sell_button)
	trade_receipt_panel = PanelContainer.new()
	trade_receipt_panel.name = "TradeReceiptPanel"
	trade_receipt_panel.visible = false
	trade_receipt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	trade_receipt_panel.custom_minimum_size = Vector2(0, 58)
	var receipt_style := StyleBoxFlat.new()
	receipt_style.bg_color = Color("#2a2118")
	receipt_style.border_color = Color("#c99a52")
	receipt_style.set_border_width_all(2)
	receipt_style.corner_radius_top_left = 3
	receipt_style.corner_radius_top_right = 3
	receipt_style.corner_radius_bottom_left = 3
	receipt_style.corner_radius_bottom_right = 3
	receipt_style.content_margin_left = 12
	receipt_style.content_margin_right = 12
	receipt_style.content_margin_top = 7
	receipt_style.content_margin_bottom = 7
	trade_receipt_panel.add_theme_stylebox_override("panel", receipt_style)
	market_shell.add_child(trade_receipt_panel)
	var receipt_row := HBoxContainer.new()
	receipt_row.add_theme_constant_override("separation", 12)
	trade_receipt_panel.add_child(receipt_row)
	var receipt_seal := Label.new()
	receipt_seal.text = "◈"
	receipt_seal.custom_minimum_size = Vector2(38, 0)
	receipt_seal.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	receipt_seal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	receipt_seal.add_theme_font_size_override("font_size", 28)
	receipt_seal.add_theme_color_override("font_color", Color("#e6b85f"))
	receipt_row.add_child(receipt_seal)
	var receipt_copy := VBoxContainer.new()
	receipt_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	receipt_copy.add_theme_constant_override("separation", 1)
	receipt_row.add_child(receipt_copy)
	trade_receipt_title_label = Label.new()
	trade_receipt_title_label.add_theme_font_size_override("font_size", 13)
	trade_receipt_title_label.add_theme_color_override("font_color", Color("#f0d27d"))
	receipt_copy.add_child(trade_receipt_title_label)
	trade_receipt_detail_label = Label.new()
	trade_receipt_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	trade_receipt_detail_label.add_theme_font_size_override("font_size", 11)
	trade_receipt_detail_label.add_theme_color_override("font_color", Color("#d9c6a2"))
	receipt_copy.add_child(trade_receipt_detail_label)
	shop_transaction_status_label = Label.new()
	shop_transaction_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_transaction_status_label.add_theme_font_size_override("font_size", 12)
	shop_transaction_status_label.add_theme_color_override("font_color", Color("#c7b49a"))
	market_shell.add_child(shop_transaction_status_label)
	shop_good_option.item_selected.connect(_on_shop_plan_changed)
	shop_quantity.value_changed.connect(_on_shop_quantity_changed)

	shop_action_card = PanelContainer.new()
	shop_action_card.name = "ShopActionCard"
	shop_action_card.custom_minimum_size = Vector2(360, 0)
	shop_action_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_action_card.size_flags_stretch_ratio = 1.0
	columns.add_child(shop_action_card)
	var action_shell := VBoxContainer.new()
	action_shell.add_theme_constant_override("separation", 10)
	shop_action_card.add_child(action_shell)
	shop_action_scroll = ScrollContainer.new()
	shop_action_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_action_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	shop_action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_shell.add_child(shop_action_scroll)
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_theme_constant_override("separation", 14)
	shop_action_scroll.add_child(actions)
	var caravan_title := Label.new()
	caravan_title.text = "BAZAAR STALLS"
	caravan_title.add_theme_font_size_override("font_size", 20)
	caravan_title.add_theme_color_override("font_color", Color("#e6c58d"))
	actions.add_child(caravan_title)
	bazaar_section_label = Label.new()
	bazaar_section_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bazaar_section_label.add_theme_color_override("font_color", Color("#d08b62"))
	actions.add_child(bazaar_section_label)
	shop_decision_summary_panel = PanelContainer.new()
	shop_decision_summary_panel.name = "BazaarDecisionSummary"
	shop_decision_summary_panel.custom_minimum_size = Vector2(0, 212)
	actions.add_child(shop_decision_summary_panel)
	var decision_shell := VBoxContainer.new()
	decision_shell.add_theme_constant_override("separation", 5)
	shop_decision_summary_panel.add_child(decision_shell)
	shop_decision_summary_label = Label.new()
	shop_decision_summary_label.name = "BazaarDecisionSummaryText"
	shop_decision_summary_label.visible = false
	decision_shell.add_child(shop_decision_summary_label)
	shop_decision_path_label = Label.new()
	shop_decision_path_label.add_theme_font_size_override("font_size", 11)
	shop_decision_path_label.add_theme_color_override("font_color", Color("#d08b62"))
	decision_shell.add_child(shop_decision_path_label)
	shop_decision_cargo_label = Label.new()
	shop_decision_cargo_label.add_theme_font_size_override("font_size", 20)
	shop_decision_cargo_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	decision_shell.add_child(shop_decision_cargo_label)
	shop_decision_journey_label = Label.new()
	shop_decision_journey_label.add_theme_font_size_override("font_size", 13)
	shop_decision_journey_label.add_theme_color_override("font_color", Color("#c7b49a"))
	decision_shell.add_child(shop_decision_journey_label)
	var decision_metrics := GridContainer.new()
	decision_metrics.columns = 4
	decision_metrics.add_theme_constant_override("h_separation", 8)
	decision_shell.add_child(decision_metrics)
	for metric_id in ["buy", "sell", "road", "net"]:
		var metric_shell := VBoxContainer.new()
		metric_shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		metric_shell.add_theme_constant_override("separation", 0)
		decision_metrics.add_child(metric_shell)
		var metric_title := Label.new()
		metric_title.text = String(metric_id).to_upper()
		metric_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metric_title.add_theme_font_size_override("font_size", 10)
		metric_title.add_theme_color_override("font_color", Color("#a69379"))
		metric_shell.add_child(metric_title)
		var metric_value := Label.new()
		metric_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		metric_value.add_theme_font_size_override("font_size", 17)
		metric_value.add_theme_color_override("font_color", Color("#f4e6c7"))
		metric_shell.add_child(metric_value)
		shop_decision_metric_values[metric_id] = metric_value
	shop_decision_road_label = Label.new()
	shop_decision_road_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_decision_road_label.add_theme_font_size_override("font_size", 11)
	shop_decision_road_label.add_theme_color_override("font_color", Color("#c7b49a"))
	decision_shell.add_child(shop_decision_road_label)
	shop_decision_resources_label = Label.new()
	shop_decision_resources_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_decision_resources_label.add_theme_font_size_override("font_size", 11)
	shop_decision_resources_label.add_theme_color_override("font_color", Color("#c7b49a"))
	decision_shell.add_child(shop_decision_resources_label)
	shop_decision_reason_label = Label.new()
	shop_decision_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_decision_reason_label.add_theme_font_size_override("font_size", 11)
	shop_decision_reason_label.add_theme_color_override("font_color", Color("#b5a18b"))
	decision_shell.add_child(shop_decision_reason_label)
	shop_decision_next_label = Label.new()
	shop_decision_next_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_decision_next_label.add_theme_font_size_override("font_size", 13)
	shop_decision_next_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	decision_shell.add_child(shop_decision_next_label)
	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "CaravanLedgerTutorial"
	tutorial_panel.visible = false
	actions.add_child(tutorial_panel)
	var tutorial_shell := VBoxContainer.new()
	tutorial_shell.add_theme_constant_override("separation", 6)
	tutorial_panel.add_child(tutorial_shell)
	tutorial_chapter_label = Label.new()
	tutorial_chapter_label.add_theme_font_size_override("font_size", 11)
	tutorial_chapter_label.add_theme_color_override("font_color", Color("#d08b62"))
	tutorial_shell.add_child(tutorial_chapter_label)
	tutorial_title_label = Label.new()
	tutorial_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_title_label.add_theme_font_size_override("font_size", 17)
	tutorial_title_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	tutorial_shell.add_child(tutorial_title_label)
	tutorial_body_label = Label.new()
	tutorial_body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tutorial_body_label.add_theme_font_size_override("font_size", 12)
	tutorial_body_label.add_theme_color_override("font_color", Color("#c7b49a"))
	tutorial_shell.add_child(tutorial_body_label)
	tutorial_skip_button = Button.new()
	tutorial_skip_button.text = "Hide tutorial guidance"
	tutorial_skip_button.custom_minimum_size = Vector2(0, 40)
	tutorial_skip_button.pressed.connect(_on_tutorial_skip_pressed)
	tutorial_shell.add_child(tutorial_skip_button)
	campaign_outlook_label = Label.new()
	campaign_outlook_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	campaign_outlook_label.add_theme_font_size_override("font_size", 12)
	campaign_outlook_label.add_theme_color_override("font_color", Color("#d9c6a2"))
	campaign_outlook_label.visible = false
	actions.add_child(campaign_outlook_label)
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
	ending_panel.name = "CampaignDebriefPanel"
	ending_panel.visible = false
	actions.add_child(ending_panel)
	var ending_shell := VBoxContainer.new()
	ending_shell.add_theme_constant_override("separation", 10)
	ending_panel.add_child(ending_shell)
	var ending_text_scroll := ScrollContainer.new()
	ending_text_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ending_text_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	ending_text_scroll.custom_minimum_size = Vector2(0, 190)
	ending_shell.add_child(ending_text_scroll)
	ending_label = Label.new()
	ending_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_label.add_theme_font_size_override("font_size", 14)
	ending_label.add_theme_color_override("font_color", Color("#e6c58d"))
	ending_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_text_scroll.add_child(ending_label)
	var ending_actions := GridContainer.new()
	ending_actions.columns = 2
	ending_actions.add_theme_constant_override("h_separation", 8)
	ending_actions.add_theme_constant_override("v_separation", 8)
	ending_shell.add_child(ending_actions)
	ending_continue_button = Button.new()
	ending_continue_button.name = "EndingContinueAction"
	ending_continue_button.text = "Continue this region"
	ending_continue_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_continue_button.custom_minimum_size = Vector2(130, 52)
	ending_continue_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_continue_button.pressed.connect(_on_ending_continue_pressed)
	ending_actions.add_child(ending_continue_button)
	ending_replay_button = Button.new()
	ending_replay_button.name = "EndingReplayAction"
	ending_replay_button.text = "Replay the experiment"
	ending_replay_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_replay_button.custom_minimum_size = Vector2(130, 52)
	ending_replay_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_replay_button.pressed.connect(_on_ending_replay_pressed)
	ending_actions.add_child(ending_replay_button)
	ending_title_button = Button.new()
	ending_title_button.name = "EndingTitleAction"
	ending_title_button.text = "Return to title"
	ending_title_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_title_button.custom_minimum_size = Vector2(130, 52)
	ending_title_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_title_button.pressed.connect(_on_ending_title_pressed)
	ending_actions.add_child(ending_title_button)
	ending_feedback_button = Button.new()
	ending_feedback_button.name = "EndingFeedbackAction"
	ending_feedback_button.text = "Export journey report"
	ending_feedback_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_feedback_button.custom_minimum_size = Vector2(130, 52)
	ending_feedback_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_feedback_button.pressed.connect(_on_export_report_pressed)
	ending_actions.add_child(ending_feedback_button)
	actions.move_child(ending_panel, 2)
	opportunity_title_label = Label.new()
	opportunity_title_label.name = "BazaarSectionTitle"
	opportunity_title_label.text = "LOCAL STALLS & OPPORTUNITIES"
	opportunity_title_label.add_theme_font_size_override("font_size", 18)
	opportunity_title_label.add_theme_color_override("font_color", Color("#e6c58d"))
	actions.add_child(opportunity_title_label)
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
	plan_departure_button.name = "BazaarPrimaryAction"
	plan_departure_button.text = "Plan departure"
	plan_departure_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	plan_departure_button.custom_minimum_size = Vector2(0, 56)
	plan_departure_button.tooltip_text = "Open the regional map, choose a legal corridor, and inspect the full route forecast."
	plan_departure_button.pressed.connect(_on_plan_departure_pressed)
	action_shell.add_child(plan_departure_button)
	shop_save_button = Button.new()
	shop_save_button.text = "Save Game"
	shop_save_button.custom_minimum_size = Vector2(0, 44)
	shop_save_button.set_meta("web_accessibility_id", "shop_save")
	shop_save_button.pressed.connect(_on_save_pressed)
	actions.add_child(shop_save_button)
	shop_save_button.visible = false
	shop_load_button = Button.new()
	shop_load_button.text = "Load saved state"
	shop_load_button.custom_minimum_size = Vector2(0, 44)
	shop_load_button.tooltip_text = "Validate and load the saved campaign. A malformed or newer save leaves the current run unchanged."
	shop_load_button.set_meta("web_accessibility_id", "shop_load")
	shop_load_button.pressed.connect(_on_load_pressed)
	actions.add_child(shop_load_button)
	shop_load_button.visible = false
	save_status_label = Label.new()
	save_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_status_label.add_theme_font_size_override("font_size", 11)
	save_status_label.add_theme_color_override("font_color", Color("#b5a18b"))
	actions.add_child(save_status_label)
	save_status_label.visible = false
	shop_reset_button = Button.new()
	shop_reset_button.text = "Reset run"
	shop_reset_button.custom_minimum_size = Vector2(0, 44)
	shop_reset_button.set_meta("web_accessibility_id", "shop_reset")
	shop_reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(shop_reset_button)
	shop_reset_button.visible = false
	shop_report_button = Button.new()
	shop_report_button.text = "Export playtest report"
	shop_report_button.custom_minimum_size = Vector2(0, 44)
	shop_report_button.tooltip_text = "Download or write build, seed, campaign summary, command history, and game log without personal data."
	shop_report_button.set_meta("web_accessibility_id", "shop_report")
	shop_report_button.pressed.connect(_on_export_report_pressed)
	actions.add_child(shop_report_button)
	shop_report_button.visible = false
	diagnostics_label = Label.new()
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostics_label.add_theme_font_size_override("font_size", 11)
	diagnostics_label.add_theme_color_override("font_color", Color("#8f8374"))
	actions.add_child(diagnostics_label)
	diagnostics_label.visible = false

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#17130f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(background)

	map_panel = JourneyMapPanel.new()
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
	left.name = "JourneyMapPanel"
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
	right.name = "DeparturePanel"
	right.custom_minimum_size = Vector2(360, 0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.0
	columns.add_child(right)
	var controls_shell := VBoxContainer.new()
	controls_shell.add_theme_constant_override("separation", 10)
	right.add_child(controls_shell)
	journey_phase_title_label = Label.new()
	journey_phase_title_label.name = "JourneyPhaseTitle"
	journey_phase_title_label.text = "DEPARTURE DESK"
	journey_phase_title_label.add_theme_font_size_override("font_size", 20)
	journey_phase_title_label.add_theme_color_override("font_color", Color("#e6c58d"))
	controls_shell.add_child(journey_phase_title_label)
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

	var comparison_title := Label.new()
	comparison_title.text = "COMPARE EVERY OPEN ITINERARY · PLAN / HELD / FEE / TIME / SUPPLY / RISK / CONFIDENCE / NET"
	comparison_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_title.add_theme_font_size_override("font_size", 13)
	comparison_title.add_theme_color_override("font_color", Color("#d08b62"))
	departure_planning_panel.add_child(comparison_title)
	route_comparison_grid = GridContainer.new()
	route_comparison_grid.name = "RouteComparisonGrid"
	route_comparison_grid.columns = 2
	route_comparison_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	route_comparison_grid.add_theme_constant_override("h_separation", 8)
	route_comparison_grid.add_theme_constant_override("v_separation", 8)
	departure_planning_panel.add_child(route_comparison_grid)
	departure_planning_panel.move_child(comparison_title, 0)
	departure_planning_panel.move_child(route_comparison_grid, 1)

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
	event_card.name = "RoadEventPanel"
	event_card.visible = false
	controls.add_child(event_card)
	var event_content := VBoxContainer.new()
	event_content.add_theme_constant_override("separation", 8)
	event_card.add_child(event_content)
	event_mode_label = Label.new()
	event_mode_label.text = "ROADSIDE DECISION"
	event_mode_label.visible = false
	event_mode_label.add_theme_font_size_override("font_size", 12)
	event_mode_label.add_theme_color_override("font_color", Color("#d08b62"))
	event_content.add_child(event_mode_label)
	event_title_label = Label.new()
	event_title_label.visible = false
	event_title_label.add_theme_font_size_override("font_size", 18)
	event_title_label.add_theme_color_override("font_color", Color("#e6c58d"))
	event_content.add_child(event_title_label)
	event_setup_label = Label.new()
	event_setup_label.visible = false
	event_setup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_setup_label.add_theme_font_size_override("font_size", 13)
	event_setup_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	event_content.add_child(event_setup_label)
	event_stakes_label = Label.new()
	event_stakes_label.visible = false
	event_content.add_child(event_stakes_label)
	var event_dossier := PanelContainer.new()
	event_dossier.name = "RoadEventDossier"
	event_content.add_child(event_dossier)
	var dossier_shell := VBoxContainer.new()
	dossier_shell.add_theme_constant_override("separation", 3)
	event_dossier.add_child(dossier_shell)
	event_threat_label = Label.new()
	event_threat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_threat_label.add_theme_font_size_override("font_size", 13)
	event_threat_label.add_theme_color_override("font_color", Color("#d08b62"))
	dossier_shell.add_child(event_threat_label)
	event_exposed_label = Label.new()
	event_exposed_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_exposed_label.add_theme_font_size_override("font_size", 12)
	event_exposed_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	dossier_shell.add_child(event_exposed_label)
	event_route_label = Label.new()
	event_route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_route_label.add_theme_font_size_override("font_size", 12)
	event_route_label.add_theme_color_override("font_color", Color("#c7b49a"))
	dossier_shell.add_child(event_route_label)
	event_basis_label = Label.new()
	event_basis_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_basis_label.add_theme_font_size_override("font_size", 11)
	event_basis_label.add_theme_color_override("font_color", Color("#a69379"))
	dossier_shell.add_child(event_basis_label)
	event_decision_label = Label.new()
	event_decision_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_decision_label.add_theme_font_size_override("font_size", 12)
	event_decision_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	dossier_shell.add_child(event_decision_label)
	event_rules_label = Label.new()
	event_rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_rules_label.add_theme_font_size_override("font_size", 10)
	event_rules_label.add_theme_color_override("font_color", Color("#8f8374"))
	dossier_shell.add_child(event_rules_label)
	event_readiness_label = Label.new()
	event_readiness_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_readiness_label.add_theme_font_size_override("font_size", 12)
	event_readiness_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	event_content.add_child(event_readiness_label)
	event_choice_list = VBoxContainer.new()
	event_choice_list.add_theme_constant_override("separation", 10)
	event_content.add_child(event_choice_list)
	conflict_outcome_panel = PanelContainer.new()
	conflict_outcome_panel.name = "ArrivalDebriefPanel"
	conflict_outcome_panel.visible = false
	controls.add_child(conflict_outcome_panel)
	var conflict_outcome_shell := VBoxContainer.new()
	conflict_outcome_shell.add_theme_constant_override("separation", 8)
	conflict_outcome_panel.add_child(conflict_outcome_shell)
	conflict_outcome_receipt = PanelContainer.new()
	conflict_outcome_receipt.name = "JourneyConsequenceReceipt"
	conflict_outcome_shell.add_child(conflict_outcome_receipt)
	var receipt_row := HBoxContainer.new()
	receipt_row.add_theme_constant_override("separation", 10)
	conflict_outcome_receipt.add_child(receipt_row)
	conflict_outcome_receipt_glyph = JourneyConsequenceGlyph.new()
	conflict_outcome_receipt_glyph.name = "JourneyConsequenceGlyph"
	conflict_outcome_receipt_glyph.custom_minimum_size = Vector2(48, 48)
	receipt_row.add_child(conflict_outcome_receipt_glyph)
	var receipt_copy := VBoxContainer.new()
	receipt_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	receipt_copy.add_theme_constant_override("separation", 0)
	receipt_row.add_child(receipt_copy)
	conflict_outcome_receipt_kicker = Label.new()
	conflict_outcome_receipt_kicker.name = "JourneyConsequenceKicker"
	conflict_outcome_receipt_kicker.add_theme_font_size_override("font_size", 11)
	receipt_copy.add_child(conflict_outcome_receipt_kicker)
	conflict_outcome_receipt_title = Label.new()
	conflict_outcome_receipt_title.name = "JourneyConsequenceTitle"
	conflict_outcome_receipt_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conflict_outcome_receipt_title.add_theme_font_size_override("font_size", 15)
	receipt_copy.add_child(conflict_outcome_receipt_title)
	conflict_outcome_receipt_detail = Label.new()
	conflict_outcome_receipt_detail.name = "JourneyConsequenceDetail"
	conflict_outcome_receipt_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conflict_outcome_receipt_detail.add_theme_font_size_override("font_size", 10)
	receipt_copy.add_child(conflict_outcome_receipt_detail)
	conflict_outcome_label = Label.new()
	conflict_outcome_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	conflict_outcome_label.add_theme_font_size_override("font_size", 13)
	conflict_outcome_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	conflict_outcome_shell.add_child(conflict_outcome_label)

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
	commit_departure_button.name = "DeparturePrimaryAction"
	commit_departure_button.text = "Commit departure"
	commit_departure_button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	commit_departure_button.custom_minimum_size = Vector2(0, 56)
	commit_departure_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	commit_departure_button.tooltip_text = "Pay the displayed route cost, consume provisions, and resolve this route's risk."
	commit_departure_button.pressed.connect(_on_depart_pressed)
	departure_travel_actions.add_child(commit_departure_button)

	continue_journey_button = Button.new()
	continue_journey_button.name = "RoadPrimaryAction"
	continue_journey_button.text = "Continue along the road"
	continue_journey_button.custom_minimum_size = Vector2(0, 52)
	continue_journey_button.tooltip_text = "Leave the road view and continue to the next encounter or arrival."
	continue_journey_button.set_meta("web_accessibility_id", "continue_journey")
	continue_journey_button.pressed.connect(_on_continue_journey_pressed)
	continue_journey_button.visible = false
	controls_shell.add_child(continue_journey_button)

	arrival_pending = false
	enter_settlement_button = Button.new()
	enter_settlement_button.name = "ArrivalPrimaryAction"
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
	save_button.text = "Save Game"
	save_button.custom_minimum_size = Vector2(0, 44)
	save_button.pressed.connect(_on_save_pressed)
	controls.add_child(save_button)
	save_button.visible = false
	var load_button := Button.new()
	load_button.text = "Load Game"
	load_button.custom_minimum_size = Vector2(0, 44)
	load_button.tooltip_text = "Validate and load the saved campaign. A malformed or newer save leaves the current run unchanged."
	load_button.pressed.connect(_on_load_pressed)
	controls.add_child(load_button)
	load_button.visible = false
	_refresh_departure_focus_cycle()
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

func _style_bazaar_navigation_button(button: Button, index: int) -> void:
	var accents := [Color("#c46f45"), Color("#c6a15b"), Color("#6f9b87"), Color("#9a795f"), Color("#788aa3")]
	var accent: Color = accents[index % accents.size()]
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#211a15")
	normal.border_color = accent.darkened(0.28)
	normal.set_border_width_all(2)
	normal.corner_radius_top_left = 3
	normal.corner_radius_top_right = 3
	normal.corner_radius_bottom_left = 3
	normal.corner_radius_bottom_right = 3
	var hover := normal.duplicate()
	hover.bg_color = accent.darkened(0.58)
	hover.border_color = accent
	var pressed := normal.duplicate()
	pressed.bg_color = accent.darkened(0.42)
	pressed.border_color = Color("#f1d39d")
	pressed.set_border_width_all(3)
	var focus := pressed.duplicate()
	focus.border_color = Color("#fff0bd")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("hover_pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color("#e6d5b8"))
	button.add_theme_color_override("font_pressed_color", Color("#fff0bd"))
	button.add_theme_font_size_override("font_size", 13)

func _on_bazaar_navigation_pressed(section_id: String) -> void:
	var section_changed := section_id != active_bazaar_section
	if section_id != "trade":
		_dismiss_trade_receipt()
	active_bazaar_section = section_id
	if section_changed and section_id == "information":
		_play_ui_cue("information")
	if tutorial.enabled and section_id in ["assignments", "outlook"]:
		if section_id == "outlook":
			tutorial.mark_outlook_seen()
		elif tutorial.current_step == TutorialDirector.STEP_REVIEW_OPTIONAL_WORK:
			tutorial.mark_optional_work_seen()
		tutorial.refresh(world, _current_ui_state_id(), arrival_pending)
		if autosave_enabled:
			_write_save("AUTOSAVED")
	_refresh_playtest_status()
	_apply_bazaar_section()
	var target: Control
	var section_has_options := false
	match section_id:
		"trade":
			target = shop_good_option
			section_has_options = true
		"assignments":
			section_has_options = not contract_buttons.is_empty()
			for button in contract_buttons:
				if not button.disabled:
					target = button
					break
		"information":
			section_has_options = not opportunity_buttons.is_empty()
			for button in opportunity_buttons:
				if not button.disabled:
					target = button
					break
		"crew":
			section_has_options = not crew_buttons.is_empty()
			for button in crew_buttons:
				if not button.disabled:
					target = button
					break
		"outlook":
			shop_transaction_status_label.text = "BAZAAR — Regional outlook opened."
			_publish_web_ui_state()
			return
	if target != null and _grab_focus_if_available(target):
		_ensure_focused_control_visible()
		shop_transaction_status_label.text = "BAZAAR — %s is ready." % section_id.replace("_", " ").capitalize()
	elif section_has_options:
		shop_transaction_status_label.text = "BAZAAR — %s has posted terms, but none are currently actionable." % section_id.replace("_", " ").capitalize()
	else:
		shop_transaction_status_label.text = "BAZAAR — No %s option is available at this settlement today." % section_id.replace("_", " ")
	call_deferred("_reset_bazaar_scroll_positions", section_id == "trade")
	_publish_web_ui_state()

func _reset_bazaar_scroll_positions(reset_market: bool) -> void:
	if not reset_market:
		return
	if shop_action_scroll:
		shop_action_scroll.scroll_vertical = 0
	if shop_market_scroll:
		shop_market_scroll.scroll_vertical = 0

func _on_tutorial_skip_pressed() -> void:
	tutorial.skip()
	last_tutorial_presented_step = ""
	_set_event("Tutorial guidance hidden. The campaign and every current decision remain unchanged. Replay is available from the New Game introduction.")
	_refresh_ui()

func _on_ending_continue_pressed() -> void:
	ending_debrief_dismissed = true
	ending_panel.visible = false
	_set_event("Campaign conclusion reviewed. Trading remains open, so you can inspect the region your choices created.")
	_grab_focus_if_available(shop_good_option)
	_publish_web_ui_state()

func _on_ending_replay_pressed() -> void:
	pending_tutorial_enabled = false
	ending_debrief_dismissed = false
	_on_start_game_requested(PLAYTEST_PATH_GUIDED)

func _on_ending_title_pressed() -> void:
	ending_debrief_dismissed = false
	_show_main_menu()

func _apply_bazaar_section() -> void:
	if opportunity_list == null:
		return
	var trade_active := active_bazaar_section == "trade"
	var section_names := {
		"trade": "MARKET STALL — Buy and sell the selected cargo on the left.",
		"assignments": "JOB BOARD — Review local delivery work and accepted terms.",
		"information": "GUIDE / INTEL — Buy supplies, repairs, and route knowledge.",
		"crew": "CREW YARD — Hire or assign people for the next road.",
		"outlook": "TOWN OUTLOOK — Review the wider campaign when you need it.",
	}
	var section_titles := {
		"trade": "LOCAL STALLS & OPPORTUNITIES",
		"assignments": "POSTED WORK & ACTIVE TERMS",
		"information": "LOCAL SERVICES & INFORMATION",
		"crew": "AVAILABLE CARAVAN HANDS",
		"outlook": "REGIONAL OUTLOOK",
	}
	if opportunity_title_label:
		opportunity_title_label.text = String(section_titles.get(active_bazaar_section, "LOCAL STALLS & OPPORTUNITIES"))
	bazaar_section_label.text = String(section_names.get(active_bazaar_section, "BAZAAR — Choose a stall."))
	var settlement_identity: Dictionary = world.settlement(world.current_settlement).get("identity", {})
	var market_read := String(settlement_identity.get("market_read", ""))
	if not market_read.is_empty():
		bazaar_section_label.text += "\nPLACE — %s" % market_read
	if trade_active and not world.emergent_faction("well_commons").is_empty():
		bazaar_section_label.text += "\nWELL COMMONS — Reedwatch water stabilized; charcoal wanted."
	for button in bazaar_navigation_buttons:
		button.set_pressed_no_signal(String(button.get_meta("web_accessibility_id", "")).trim_prefix("bazaar_") == active_bazaar_section)
	if shop_market_scroll:
		shop_market_scroll.visible = trade_active
	if shop_decision_summary_panel:
		shop_decision_summary_panel.visible = trade_active
	if shop_purchase_row:
		shop_purchase_row.visible = trade_active
	if bazaar_scene:
		bazaar_scene.visible = true
		bazaar_scene.custom_minimum_size.y = 72.0 if trade_active else 236.0
		bazaar_scene.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if trade_active else Control.SIZE_EXPAND_FILL
		var settlement := world.settlement(world.current_settlement)
		bazaar_scene.set_context(
			world.current_settlement,
			String(settlement.get("name", world.current_settlement)),
			String(settlement.get("role", "market")),
			Dictionary(settlement.get("identity", {})),
			active_bazaar_section,
		)
	campaign_outlook_label.visible = active_bazaar_section == "outlook"
	active_contract_label.visible = active_bazaar_section == "assignments" and not world.active_contracts.is_empty()
	for child in opportunity_list.get_children():
		child.visible = String(child.get_meta("bazaar_section", "")) == active_bazaar_section
	_link_shop_focus_cycle()

func _link_main_menu_focus_cycle() -> void:
	if start_game_button == null or continue_game_button == null:
		return
	var controls: Array = [start_game_button]
	if not continue_game_button.disabled:
		controls.append(continue_game_button)
	controls.append(settings_button)
	controls.append(credits_button)
	if settings_panel != null and settings_panel.visible:
		controls.append(reduce_motion_checkbox)
		controls.append(large_text_checkbox)
		controls.append(interface_sounds_checkbox)
		for action_name in REMAPPABLE_ACTIONS:
			controls.append(binding_buttons[action_name])
		controls.append(restore_bindings_button)
	if developer_panel != null and developer_panel.visible:
		controls.append(start_conflict_button)
		controls.append(start_campaign_button)
	if quit_button.visible:
		controls.append(quit_button)
	_link_focus_cycle(controls)

func _link_shop_focus_cycle() -> void:
	if shop_good_option == null or plan_departure_button == null:
		return
	var controls: Array = []
	for control in bazaar_navigation_buttons:
		controls.append(control)
	if tutorial_skip_button != null and tutorial_skip_button.visible and not tutorial_skip_button.disabled:
		controls.append(tutorial_skip_button)
	if active_bazaar_section == "trade":
		controls.append(shop_good_option)
		controls.append(shop_quantity.get_line_edit())
		for control in [shop_buy_button, shop_sell_button]:
			if control.visible and not control.disabled:
				controls.append(control)
	for group in [contract_buttons, opportunity_buttons, crew_buttons]:
		for control in group:
			if control.is_visible_in_tree() and not control.disabled:
				controls.append(control)
	for control in [shop_save_button, shop_load_button, shop_reset_button, shop_report_button, plan_departure_button]:
		if control.visible and not control.disabled:
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

func _refresh_route_comparison(world_context: Dictionary) -> void:
	if route_comparison_grid == null:
		return
	for child in route_comparison_grid.get_children():
		route_comparison_grid.remove_child(child)
		child.queue_free()
	route_comparison_buttons.clear()
	var views := TradePresenter.route_comparison_views(
		world,
		_selected_id(cargo_good_option),
		int(cargo_quantity.value),
		_selected_id(destination_option),
		_selected_id(route_option),
		world_context,
	)
	for view in views:
		var button := Button.new()
		button.name = "RouteComparison%d" % route_comparison_buttons.size()
		button.text = String(view.get("text", ""))
		button.tooltip_text = String(view.get("tooltip", ""))
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(158, ROUTE_CARD_LARGE_TEXT_HEIGHT if large_text_enabled else ROUTE_CARD_HEIGHT)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16 if large_text_enabled else 14)
		button.toggle_mode = true
		button.button_pressed = bool(view.get("selected", false))
		button.set_meta("web_accessibility_id", "route_plan_%s_%s" % [String(view.get("destination_id", "")), String(view.get("route_id", ""))])
		button.pressed.connect(_on_route_comparison_pressed.bind(String(view.get("destination_id", "")), String(view.get("route_id", ""))))
		route_comparison_grid.add_child(button)
		route_comparison_buttons.append(button)
	_refresh_departure_focus_cycle()

func _refresh_departure_focus_cycle() -> void:
	var controls: Array = [destination_option, route_option, cargo_good_option]
	if cargo_quantity != null:
		controls.append(cargo_quantity.get_line_edit())
	controls.append_array(route_comparison_buttons)
	controls.append(commit_departure_button)
	controls.append(return_to_shop_button)
	_link_focus_cycle(controls)

func _selected_route_comparison_button() -> Button:
	for button in route_comparison_buttons:
		if button != null and is_instance_valid(button) and button.button_pressed:
			return button
	return route_comparison_buttons[0] if not route_comparison_buttons.is_empty() else null

func _on_route_comparison_pressed(destination_id: String, route_id: String) -> void:
	_select_option_by_id(destination_option, destination_id)
	_populate_route_options()
	_select_option_by_id(route_option, route_id)
	_refresh_forecasts()
	_grab_focus_if_available(_selected_route_comparison_button())
	_publish_web_ui_state()
	_queue_web_ui_state_after_layout()

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
	ending_debrief_dismissed = false
	last_presented_ending_id = ""
	run_started_msec = Time.get_ticks_msec()
	first_trade_elapsed_msec = -1
	if map_panel:
		map_panel.world = world
		map_panel.reduce_motion = reduce_motion_checkbox != null and reduce_motion_checkbox.button_pressed
		map_panel.reset_travel(world.current_settlement)
	_populate_destination_options()
	_populate_route_options()
	_apply_playtest_path_defaults(path_id)
	if pending_tutorial_enabled:
		tutorial.start()
		_set_event("The caravan begins its first morning in Ashgate. The Reedwatch Wellkeepers are looking for a carrier before the wells fall further.")
	else:
		tutorial.skip()
		_set_event("Ashgate market is open. Inspect local prices, opportunities, and roads before committing the caravan.")
	arrival_pending = false
	enter_settlement_button.visible = false
	commit_departure_button.disabled = false
	return_to_shop_button.disabled = false
	_show_shop()

func _on_start_game_requested(path_id: String = PLAYTEST_PATH_CAMPAIGN) -> void:
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
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_D and event.ctrl_pressed and event.shift_pressed and menu_layer != null and menu_layer.visible:
		developer_panel.visible = not developer_panel.visible
		settings_panel.visible = false
		credits_panel.visible = false
		_link_main_menu_focus_cycle()
		if developer_panel.visible:
			_grab_focus_if_available(start_conflict_button)
		_publish_web_ui_state()
		_queue_web_ui_state_after_layout()
		get_viewport().set_input_as_handled()
		return
	if not remapping_action.is_empty():
		if event is InputEventKey and event.pressed and not event.echo:
			_capture_keyboard_binding(event)
			get_viewport().set_input_as_handled()
		elif event is InputEventJoypadButton and event.pressed:
			_capture_controller_binding(event)
			get_viewport().set_input_as_handled()
		return
	if intro_layer != null and intro_layer.visible and event.is_action_pressed("ui_cancel"):
		_on_intro_back_pressed()
		get_viewport().set_input_as_handled()
	elif menu_layer != null and menu_layer.visible and event.is_action_pressed("ui_cancel") and ((settings_panel != null and settings_panel.visible) or (credits_panel != null and credits_panel.visible) or (developer_panel != null and developer_panel.visible)):
		settings_panel.visible = false
		credits_panel.visible = false
		developer_panel.visible = false
		_link_main_menu_focus_cycle()
		_grab_focus_if_available(settings_button)
		_publish_web_ui_state()
		_queue_web_ui_state_after_layout()
		get_viewport().set_input_as_handled()
	elif pause_layer != null and pause_layer.visible and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_pause")):
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
	_dismiss_trade_receipt()
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

func _pacing_context_id() -> String:
	var screen_id := _current_ui_state_id()
	match screen_id:
		"main_menu":
			if settings_panel != null and settings_panel.visible:
				return "main_menu:settings"
			if credits_panel != null and credits_panel.visible:
				return "main_menu:credits"
			if developer_panel != null and developer_panel.visible:
				return "main_menu:developer"
		"introduction":
			return "introduction:%d" % (intro_page + 1)
		"settlement_shop":
			if ending_panel != null and ending_panel.visible:
				return "settlement_shop:ending"
			return "settlement_shop:%s" % active_bazaar_section
		"route_travel":
			return "route_travel:%s" % String(map_panel.travel_phase if map_panel != null else "unknown")
		"route_event":
			return "route_event:%s" % String(world.pending_event.get("id", "unknown") if world != null else "unknown")
		"arrival_handoff":
			return "arrival_handoff:%s" % String(world.current_settlement if world != null else "unknown")
	return screen_id

func _pacing_elapsed_seconds() -> float:
	if pacing_session_started_msec <= 0:
		return 0.0
	return maxf(0.0, float(Time.get_ticks_msec() - pacing_session_started_msec) / 1000.0)

func _append_pacing_entry(entry: Dictionary) -> void:
	pacing_trace.append(entry)
	while pacing_trace.size() > MAX_PACING_TRACE_ENTRIES:
		pacing_trace.pop_front()

func _record_pacing_transition() -> void:
	if world == null:
		return
	var screen_id := _current_ui_state_id()
	if screen_id == "unknown":
		return
	var context_id := _pacing_context_id()
	if context_id == last_pacing_context_id:
		return
	last_pacing_context_id = context_id
	_append_pacing_entry({
		"elapsed_seconds": _pacing_elapsed_seconds(),
		"kind": "transition",
		"screen_id": screen_id,
		"context_id": context_id,
		"day": world.day,
		"settlement_id": world.current_settlement,
	})

func _record_pacing_command(result: Dictionary, fallback_label: String) -> void:
	if world == null:
		return
	var action_id := fallback_label.to_snake_case()
	if not world.command_history.is_empty():
		action_id = String(world.command_history.back().get("id", action_id))
	_append_pacing_entry({
		"elapsed_seconds": _pacing_elapsed_seconds(),
		"kind": "command",
		"screen_id": _current_ui_state_id(),
		"context_id": _pacing_context_id(),
		"action_id": action_id,
		"outcome": "ok" if bool(result.get("ok", false)) else "blocked",
		"day": world.day,
		"settlement_id": world.current_settlement,
	})

func _on_export_report_pressed() -> void:
	var viewport_size := _report_viewport_size()
	var report := {
		"report_version": 7,
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
		"pacing_session_elapsed_seconds": _pacing_elapsed_seconds(),
		"time_to_first_trade_seconds": null if first_trade_elapsed_msec < 0 else float(first_trade_elapsed_msec) / 1000.0,
		"pacing_trace": pacing_trace.duplicate(true),
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
		_set_event("REPORT DOWNLOAD REQUESTED — %s\nIf the browser asks, allow the download. Build, entry path, platform, viewport, input mappings, pacing timeline, seed, and campaign evidence are included. No personal data is included." % WEB_REPORT_FILENAME)
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
			_set_event("REPORT EXPORTED — %s\nBuild, entry path, platform, viewport, input mappings, pacing timeline, seed, and campaign evidence are included. No personal data is included." % ProjectSettings.globalize_path(report_path))
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
	if intro_layer != null and intro_layer.visible:
		return "introduction"
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
	_record_pacing_transition()
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
	const activeControlId = document.activeElement && document.activeElement.dataset
		? document.activeElement.dataset.control || ''
		: '';
	const activeActionId = document.activeElement && document.activeElement.dataset
		? document.activeElement.dataset.action || ''
		: '';
	// A travel animation can temporarily publish no semantic action. Carry focus
	// through that empty frame, then hand it to the first action on the road.
	const focusedControlId = activeControlId || controlsRegion.dataset.pendingFocusedControl || '';
	const focusedActionId = activeActionId || controlsRegion.dataset.pendingFocusedAction || '';
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
		controlsRegion.dataset.pendingFocusedControl = '';
		controlsRegion.dataset.pendingFocusedAction = '';
	} else if (focusedControlId || focusedActionId) {
		controlsRegion.dataset.pendingFocusedControl = focusedControlId;
		controlsRegion.dataset.pendingFocusedAction = focusedActionId;
	} else {
		controlsRegion.dataset.pendingFocusedControl = '';
		controlsRegion.dataset.pendingFocusedAction = '';
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
		"menu_settings": return settings_button
		"menu_credits": return credits_button
		"intro_back": return intro_back_button
		"intro_next": return intro_next_button
		"intro_skip": return intro_skip_button
		"tutorial_skip": return tutorial_skip_button
		"start_conflict": return start_conflict_button
		"start_campaign": return start_campaign_button
		"continue_game": return continue_game_button
		"shop_buy": return shop_buy_button
		"shop_sell": return shop_sell_button
		"plan_departure": return plan_departure_button
		"ending_continue": return ending_continue_button
		"ending_replay": return ending_replay_button
		"ending_title": return ending_title_button
		"ending_feedback": return ending_feedback_button
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
	for control in [shop_save_button, shop_load_button, shop_reset_button, shop_report_button, restore_bindings_button]:
		if control != null and is_instance_valid(control) and String(control.get_meta("web_accessibility_id", "")) == action_id:
			return control
	for control in route_comparison_buttons:
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

func _append_web_accessibility_control(controls: Array, control_record: Dictionary) -> void:
	if not control_record.is_empty():
		controls.append(control_record)

func _web_accessibility_controls() -> Array:
	var controls: Array = []
	match _current_ui_state_id():
		"main_menu":
			if settings_panel != null and settings_panel.visible:
				_append_web_accessibility_control(controls, _web_accessibility_checkbox_control("reduce_motion", reduce_motion_checkbox))
				_append_web_accessibility_control(controls, _web_accessibility_checkbox_control("large_text", large_text_checkbox))
				_append_web_accessibility_control(controls, _web_accessibility_checkbox_control("interface_sounds", interface_sounds_checkbox))
		"settlement_shop":
			_append_web_accessibility_control(controls, _web_accessibility_option_control("shop_good", "Cargo", shop_good_option))
			_append_web_accessibility_control(controls, _web_accessibility_quantity_control("shop_quantity", "Quantity", shop_quantity))
		"departure_desk":
			_append_web_accessibility_control(controls, _web_accessibility_option_control("destination", "Destination", destination_option))
			_append_web_accessibility_control(controls, _web_accessibility_option_control("route", "Route", route_option))
			_append_web_accessibility_control(controls, _web_accessibility_option_control("cargo_good", "Forecast cargo", cargo_good_option))
			_append_web_accessibility_control(controls, _web_accessibility_quantity_control("cargo_quantity", "Forecast quantity", cargo_quantity))
	return controls

func _web_accessibility_actions() -> Array:
	var actions: Array = []
	match _current_ui_state_id():
		"main_menu":
			_append_web_accessibility_action(actions, "start_game", start_game_button)
			_append_web_accessibility_action(actions, "continue_game", continue_game_button)
			_append_web_accessibility_action(actions, "menu_settings", settings_button)
			_append_web_accessibility_action(actions, "menu_credits", credits_button)
			if settings_panel != null and settings_panel.visible:
				for action_name in REMAPPABLE_ACTIONS:
					_append_web_accessibility_action(actions, "rebind_%s" % action_name, binding_buttons.get(action_name))
				_append_web_accessibility_action(actions, "restore_default_bindings", restore_bindings_button)
		"introduction":
			_append_web_accessibility_action(actions, "intro_back", intro_back_button)
			_append_web_accessibility_action(actions, "intro_next", intro_next_button)
			_append_web_accessibility_action(actions, "intro_skip", intro_skip_button)
		"settlement_shop":
			if ending_panel != null and ending_panel.visible:
				_append_web_accessibility_action(actions, "ending_continue", ending_continue_button)
				_append_web_accessibility_action(actions, "ending_replay", ending_replay_button)
				_append_web_accessibility_action(actions, "ending_title", ending_title_button)
				_append_web_accessibility_action(actions, "ending_feedback", ending_feedback_button)
			_append_tagged_web_accessibility_actions(actions, bazaar_navigation_buttons)
			_append_web_accessibility_action(actions, "tutorial_skip", tutorial_skip_button)
			_append_web_accessibility_action(actions, "shop_buy", shop_buy_button)
			_append_web_accessibility_action(actions, "shop_sell", shop_sell_button)
			_append_tagged_web_accessibility_actions(actions, contract_buttons)
			_append_tagged_web_accessibility_actions(actions, opportunity_buttons)
			_append_tagged_web_accessibility_actions(actions, crew_buttons)
			_append_web_accessibility_action(actions, "shop_save", shop_save_button)
			_append_web_accessibility_action(actions, "shop_load", shop_load_button)
			_append_web_accessibility_action(actions, "shop_reset", shop_reset_button)
			_append_web_accessibility_action(actions, "shop_report", shop_report_button)
			_append_web_accessibility_action(actions, "plan_departure", plan_departure_button)
		"departure_desk":
			_append_tagged_web_accessibility_actions(actions, route_comparison_buttons)
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
		for action_id in ["start_game", "continue_game", "menu_settings", "menu_credits"]:
			for action in actions:
				if action.get("id") == action_id:
					order.append("action:%s" % action_id)
					break
		for control in controls:
			order.append("control:%s" % String(control.get("id", "")))
		for action in actions:
			var action_id := String(action.get("id", ""))
			if action_id not in ["start_game", "continue_game", "menu_settings", "menu_credits"]:
				order.append("action:%s" % action_id)
		return order
	if _current_ui_state_id() == "settlement_shop":
		if ending_panel != null and ending_panel.visible:
			for ending_action_id in ["ending_continue", "ending_replay", "ending_title", "ending_feedback"]:
				order.append("action:%s" % ending_action_id)
			for control in controls:
				order.append("control:%s" % String(control.get("id", "")))
			for action in actions:
				var remaining_action_id := String(action.get("id", ""))
				if remaining_action_id not in ["ending_continue", "ending_replay", "ending_title", "ending_feedback"]:
					order.append("action:%s" % remaining_action_id)
			return order
		for action in actions:
			var action_id := String(action.get("id", ""))
			if action_id.begins_with("bazaar_"):
				order.append("action:%s" % action_id)
		for control in controls:
			order.append("control:%s" % String(control.get("id", "")))
		for action in actions:
			var action_id := String(action.get("id", ""))
			if not action_id.begins_with("bazaar_"):
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
			var menu_announcement := "Market of Ash main menu. New Game is focused, followed by Continue, Settings, and Credits. Accept uses %s or controller %s." % [_keyboard_binding_text("ui_accept"), _controller_binding_text("ui_accept")]
			if binding_status_label != null and not binding_status_label.text.is_empty():
				menu_announcement += " %s" % binding_status_label.text
			return menu_announcement
		"introduction":
			return "Market of Ash introduction, page %d of %d. %s %s Next, Back, and Start without guidance are available." % [intro_page + 1, INTRO_PAGES.size(), intro_title_label.text, intro_body_label.text]
		"settlement_shop":
			if not world.ending_id.is_empty():
				var debrief := JourneyPresenter.campaign_debrief(world)
				return "Campaign conclusion. %s Continue this region, replay the experiment, return to title, and export journey report are available." % String(debrief.get("text", ""))
			var recent_conflict_text := _latest_conflict_outcome_text()
			var recent_conflict_note := " Latest conflict report: %s" % recent_conflict_text.replace("\n", " ") if not recent_conflict_text.is_empty() else ""
			var trade_plan_note := " Current trade plan: %s" % shop_decision_summary_label.text.replace("\n", " ") if active_bazaar_section == "trade" and shop_decision_summary_label != null else ""
			return "Settlement Bazaar at %s. Trade, Jobs, Services and Intel, Crew, Outlook, and Departure form the repeatable hub.%s%s" % [String(world.settlement(world.current_settlement).get("name", world.current_settlement)), trade_plan_note, recent_conflict_note]
		"departure_desk":
			return "Departure Desk. Choose destination, route, cargo forecast, and quantity before Commit departure. Return to shop spends nothing."
		"route_travel":
			return "On the road. %s. The committed corridor is shown before any encounter or arrival. Continue journey is focused when the road observation is ready." % map_panel._road_waypoint_label()
		"route_event":
			return "Roadside decision: %s. Threat, available responses, costs, risk, and expected outcomes are stated before the first available response; unavailable choices include written reasons." % String(world.pending_event.get("title", "travel event"))
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
	var selected_good_id: String = _selected_id(shop_good_option) if shop_good_option != null else ""
	var logical_size: Vector2 = get_viewport().get_visible_rect().size
	var accessibility_actions: Array = _web_accessibility_actions()
	var accessibility_controls: Array = _web_accessibility_controls()
	var active_route_id: String = String(map_panel.travel_route_id) if map_panel != null and not String(map_panel.travel_route_id).is_empty() else _selected_id(route_option) if route_option != null else ""
	var active_route_risk: float = float(world.route(active_route_id).get("risk", 0.0)) if world != null and not active_route_id.is_empty() else 0.0
	var settlement_identity: Dictionary = world.settlement(world.current_settlement).get("identity", {}) if world != null else {}
	var settlement_visual: Dictionary = VisualRegistry.settlement_style(world.current_settlement, settlement_identity) if world != null else {}
	var targets := {
		"start_game": _web_control_rect(start_game_button),
		"menu_settings": _web_control_rect(settings_button),
		"menu_credits": _web_control_rect(credits_button),
		"intro_back": _web_control_rect(intro_back_button),
		"intro_next": _web_control_rect(intro_next_button),
		"intro_skip": _web_control_rect(intro_skip_button),
		"start_conflict": _web_control_rect(start_conflict_button),
		"start_campaign": _web_control_rect(start_campaign_button),
		"bazaar_trade": _web_control_rect(bazaar_navigation_buttons[0]),
		"bazaar_assignments": _web_control_rect(bazaar_navigation_buttons[1]),
		"bazaar_information": _web_control_rect(bazaar_navigation_buttons[2]),
		"bazaar_crew": _web_control_rect(bazaar_navigation_buttons[3]),
		"bazaar_outlook": _web_control_rect(bazaar_navigation_buttons[4]),
		"large_text": _web_control_rect(large_text_checkbox),
		"plan_departure": _web_control_rect(plan_departure_button),
		"ending_continue": _web_control_rect(ending_continue_button),
		"ending_replay": _web_control_rect(ending_replay_button),
		"ending_title": _web_control_rect(ending_title_button),
		"ending_feedback": _web_control_rect(ending_feedback_button),
		"return_to_shop": _web_control_rect(return_to_shop_button),
		"commit_departure": _web_control_rect(commit_departure_button),
		"continue_journey": _web_control_rect(continue_journey_button),
		"enter_settlement": _web_control_rect(enter_settlement_button),
		"pause_main_menu": _web_control_rect(pause_main_menu_button),
		"shop_good": _web_control_rect(shop_good_option),
		"shop_buy": _web_control_rect(shop_buy_button),
		"destination": _web_control_rect(destination_option),
		"event_choice": _web_control_rect(_first_available_event_choice()),
	}
	for button in route_comparison_buttons:
		var target_id := String(button.get_meta("web_accessibility_id", ""))
		if not target_id.is_empty():
			targets[target_id] = _web_control_rect(button)
	return {
		"screen": _current_ui_state_id(),
		"announcement": _web_accessibility_announcement(),
		"accessibility_actions": accessibility_actions,
		"accessibility_controls": accessibility_controls,
		"accessibility_order": _web_accessibility_order(accessibility_actions, accessibility_controls),
		"logical_viewport": {"width": logical_size.x, "height": logical_size.y},
		"targets": targets,
		"large_text": large_text_enabled,
		"reduced_motion": reduce_motion_enabled,
		"interface_sounds": interface_sounds_enabled,
		"playtest_path_id": active_playtest_path_id,
		"intro_page": intro_page,
		"tutorial": tutorial.serialize(),
		"remapping_action": remapping_action,
		"binding_status": binding_status_label.text if binding_status_label != null else "",
		"input_bindings": _input_bindings_report(),
		"settlement_id": world.current_settlement if world != null else "",
		"day": world.day if world != null else 0,
		"money": world.money if world != null else 0,
		"provisions": world.provisions if world != null else 0,
		"cargo_weight": int(world.cargo.get("weight", 0)) if world != null else 0,
		"reputation": world.reputation.duplicate(true) if world != null else {},
		"arms_escalation": world.arms_escalation if world != null else 0,
		"pending_event_id": String(world.pending_event.get("id", "")) if world != null else "",
		"recruited_crew": world.recruited_crew.duplicate() if world != null else [],
		"assigned_crew": world.assigned_crew if world != null else "",
		"route_conditions": world.route_conditions.duplicate(true) if world != null else {},
		"adaptive_scenario_state": String(world.scenario_state("reedwatch_water_relief").get("state", "")) if world != null else "",
		"adaptive_scenario_states": world.scenario_states.duplicate(true) if world != null else {},
		"emergent_factions": world.emergent_factions.keys() if world != null else [],
		"adaptive_response": world.adaptive_response_summary() if world != null else "",
		"ending_id": world.ending_id if world != null else "",
		"ending_summary": world.ending_summary if world != null else "",
		"campaign_debrief": ending_label.text if ending_panel != null and ending_panel.visible else "",
		"travel_phase": map_panel.travel_phase if map_panel != null else "rest",
		"journey_phase_title": journey_phase_title_label.text if journey_phase_title_label != null else "",
		"road_scene_id": String(map_panel._road_profile(map_panel.travel_route_id).get("scene_id", "")) if map_panel != null and map_panel._is_road_view() else "",
		"route_texture": VisualRegistry.route_texture(active_route_id) if not active_route_id.is_empty() else "",
		"risk_cue": String(VisualRegistry.risk_cue(active_route_risk).get("tier", "stable")),
		"road_waypoint": map_panel._road_waypoint_label() if map_panel != null and map_panel._is_road_view() else "",
		"bazaar_section": active_bazaar_section,
		"bazaar_scene_id": bazaar_scene.scene_id() if bazaar_scene != null and world != null else "",
		"settlement_motif": String(settlement_visual.get("motif", "")),
		"arrival_treatment": String(settlement_visual.get("arrival_treatment", "")),
		"trade_decision_summary": shop_decision_summary_label.text if shop_decision_summary_label != null else "",
		"trade_receipt_title": trade_receipt_title_label.text if trade_receipt_panel != null and trade_receipt_panel.visible else "",
		"trade_receipt_detail": trade_receipt_detail_label.text if trade_receipt_panel != null and trade_receipt_panel.visible else "",
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
	_refresh_route_comparison(world_context)
	world_context["route_intelligence"] = world.route_intelligence(route_id)
	var selected_route: Dictionary = {}
	if MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		selected_route = world.route(route_id, world.current_settlement, destination_id)
		selected_route["provisions"] = world.route_provision_cost(route_id, destination_id)
	var market_text := TradePresenter.market_preview_text(world, good_id, quantity, origin, destination, selected_route, world_context)
	market_preview_label.text = market_text
	if shop_market_preview_label:
		shop_market_preview_label.text = market_text
	if shop_decision_summary_label:
		var decision_view := TradePresenter.shop_decision_view(world, good_id, quantity, origin, destination, selected_route, world_context)
		shop_decision_summary_label.text = String(decision_view.get("accessibility_text", ""))
		shop_decision_path_label.text = String(decision_view.get("path_label", ""))
		shop_decision_cargo_label.text = String(decision_view.get("cargo_label", ""))
		shop_decision_journey_label.text = String(decision_view.get("journey_label", ""))
		var decision_metrics: Dictionary = decision_view.get("metrics", {})
		for metric_id in shop_decision_metric_values:
			var metric_value: Label = shop_decision_metric_values[metric_id]
			metric_value.text = String(decision_metrics.get(metric_id, "—"))
		shop_decision_metric_values["net"].add_theme_color_override("font_color", Color("#8ab7a5") if bool(decision_view.get("net_positive", false)) else Color("#d08b62"))
		shop_decision_road_label.text = String(decision_view.get("road_label", ""))
		shop_decision_resources_label.text = String(decision_view.get("resources_label", ""))
		shop_decision_reason_label.text = String(decision_view.get("reason_label", ""))
		shop_decision_next_label.text = String(decision_view.get("next_label", ""))
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
		departure_load_label.text = "JOURNEY ESTIMATE\n%s x%d · actually held %d · total hold %d/%d · cash %d · provisions %d" % [good_id.capitalize(), quantity, int(world.cargo.get(good_id, 0)), int(world.cargo.get("weight", 0)), world.cargo_capacity, world.money, world.provisions]
	if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		route_preview_label.text = "ROUTE FORECAST\nChoose a directly connected destination and route."
		if commit_departure_button:
			commit_departure_button.text = "Commit departure"
		return
	if commit_departure_button:
		var provision_count := int(selected_route.get("provisions", 0))
		var provision_label := "provision" if provision_count == 1 else "provisions"
		var held_selected_quantity := int(world.cargo.get(good_id, 0))
		if held_selected_quantity < quantity:
			var load_state := "without planned load" if held_selected_quantity == 0 else "with partial plan %d/%d" % [held_selected_quantity, quantity]
			commit_departure_button.text = "Set out %s — %d ashmarks · %d %s" % [load_state, int(selected_route.get("cost", 0)), provision_count, provision_label]
			commit_departure_button.tooltip_text = "Departure carries the actual hold. The %s x%d forecast is hypothetical; %d is held. Return to the shop to load the full plan." % [good_id.capitalize(), quantity, held_selected_quantity]
		else:
			commit_departure_button.text = "Confirm and set out — %d ashmarks · %d %s" % [int(selected_route.get("cost", 0)), provision_count, provision_label]
			commit_departure_button.tooltip_text = "Commit this route with the current hold and spend the disclosed fee and provisions."
	route_preview_label.text = TradePresenter.route_preview_text(world, good_id, quantity, origin, destination, selected_route, world_context)

func _on_buy_pressed() -> void:
	_sync_shop_plan_to_departure()
	var good_id := _selected_id(cargo_good_option)
	var quantity := int(cargo_quantity.value)
	var money_before := world.money
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {
			"good_id": good_id,
			"quantity": quantity,
		},
	})
	_record_first_trade(result)
	_show_command_result(result, "Purchase")
	if result.ok:
		_show_trade_receipt("PURCHASE SEALED", "%s x%d loaded · %d ashmarks paid · hold %d/%d" % [good_id.capitalize(), quantity, money_before - world.money, int(world.cargo.get("weight", 0)), world.cargo_capacity])
		_grab_focus_if_available(plan_departure_button)

func _on_sell_pressed() -> void:
	_sync_shop_plan_to_departure()
	var good_id := _selected_id(cargo_good_option)
	var quantity := int(cargo_quantity.value)
	var money_before := world.money
	var settlement := world.settlement(world.current_settlement)
	var unit_price_before := MarketEconomy.price_for(good_id, settlement, world.pricing_context())
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {
			"good_id": good_id,
			"quantity": quantity,
		},
	})
	_record_first_trade(result)
	_show_command_result(result, "Sale")
	if result.ok:
		var unit_price_after := MarketEconomy.price_for(good_id, settlement, world.pricing_context())
		_show_trade_receipt("SALE RECORDED", "%s x%d released · %d ashmarks received · local unit %d → %d after supply · hold %d/%d" % [good_id.capitalize(), quantity, world.money - money_before, unit_price_before, unit_price_after, int(world.cargo.get("weight", 0)), world.cargo_capacity])
	if result.ok and shop_sell_button != null and shop_sell_button.disabled:
		_grab_focus_if_available(plan_departure_button)

func _show_trade_receipt(title: String, detail: String) -> void:
	if trade_receipt_panel == null:
		return
	trade_receipt_generation += 1
	var generation := trade_receipt_generation
	if trade_receipt_tween != null and trade_receipt_tween.is_valid():
		trade_receipt_tween.kill()
	trade_receipt_title_label.text = title
	trade_receipt_detail_label.text = detail
	trade_receipt_panel.visible = true
	trade_receipt_panel.pivot_offset = Vector2(trade_receipt_panel.size.x * 0.5, trade_receipt_panel.size.y * 0.5)
	trade_receipt_panel.modulate = Color.WHITE
	trade_receipt_panel.scale = Vector2.ONE
	trade_receipt_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if reduce_motion_enabled:
		trade_receipt_tween.tween_interval(1.55)
	else:
		trade_receipt_panel.modulate.a = 0.0
		trade_receipt_panel.scale = Vector2(0.97, 0.97)
		trade_receipt_tween.set_parallel(true)
		trade_receipt_tween.tween_property(trade_receipt_panel, "modulate:a", 1.0, 0.14)
		trade_receipt_tween.tween_property(trade_receipt_panel, "scale", Vector2.ONE, 0.14)
		trade_receipt_tween.set_parallel(false)
		trade_receipt_tween.tween_interval(1.15)
		trade_receipt_tween.tween_property(trade_receipt_panel, "modulate:a", 0.0, 0.24)
	trade_receipt_tween.tween_callback(_finish_trade_receipt.bind(generation))

func _finish_trade_receipt(generation: int) -> void:
	if trade_receipt_panel == null or generation != trade_receipt_generation:
		return
	trade_receipt_panel.visible = false
	trade_receipt_panel.modulate = Color.WHITE
	trade_receipt_panel.scale = Vector2.ONE

func _dismiss_trade_receipt() -> void:
	if trade_receipt_panel == null:
		return
	trade_receipt_generation += 1
	if trade_receipt_tween != null and trade_receipt_tween.is_valid():
		trade_receipt_tween.kill()
	trade_receipt_panel.visible = false
	trade_receipt_panel.modulate = Color.WHITE
	trade_receipt_panel.scale = Vector2.ONE

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
		tutorial.refresh(world, _current_ui_state_id(), arrival_pending)
		var save_succeeded := true
		if autosave_enabled:
			save_succeeded = _write_save("AUTOSAVED")
		if not save_succeeded:
			result_text += "\nSAVE WARNING — %s" % save_status_text.trim_prefix("SAVE ERROR — ")
		var cue_id := "success"
		if label == "Departure":
			cue_id = "travel"
		elif label in ["Purchase", "Sale"]:
			cue_id = "trade"
		_play_ui_cue(cue_id if save_succeeded else "blocked")
		_set_event("%s\nNEXT — %s" % [result_text, _next_step_text()])
	else:
		_play_ui_cue("blocked")
		_set_event("%s blocked: %s.\nNEXT — %s" % [label, String(result.reason), _next_step_text()])
	_record_pacing_command(result, label)
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
		_set_event("Campaign saved. Your caravan, contracts, road history, and tutorial progress are preserved.")
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
	file.store_string(JSON.stringify({
		"format": SAVE_ENVELOPE_FORMAT,
		"format_version": SAVE_ENVELOPE_VERSION,
		"world": world.serialize(),
		"presentation": {"tutorial": tutorial.serialize()},
	}))
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
	ending_debrief_dismissed = false
	last_presented_ending_id = ""
	tutorial.load_serialized(load_attempt.get("tutorial", {}))
	last_tutorial_presented_step = ""
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
	var parsed_record: Dictionary = parsed
	if parsed_record.has("world"):
		if String(parsed_record.get("format", "")) != SAVE_ENVELOPE_FORMAT:
			return {"ok": false, "reason": "The campaign save uses an unknown container format"}
		var format_version := int(parsed_record.get("format_version", 0))
		if format_version != SAVE_ENVELOPE_VERSION:
			return {"ok": false, "reason": "The campaign save container version is not supported by this build"}
	var world_data: Variant = parsed_record.get("world", parsed_record)
	if typeof(world_data) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "The save does not contain a valid campaign"}
	var candidate := AshWorldState.new(world.seed)
	var load_result := candidate.load_serialized(world_data)
	if not bool(load_result.get("ok", false)):
		return {"ok": false, "reason": String(load_result.get("reason", "Save validation failed"))}
	var presentation: Variant = parsed_record.get("presentation", {}) if parsed_record.has("world") else {}
	var tutorial_data: Variant = presentation.get("tutorial", {}) if typeof(presentation) == TYPE_DICTIONARY else {}
	return {"ok": true, "world": candidate, "result": load_result, "tutorial": tutorial_data}

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
	if tutorial.enabled or tutorial.completed:
		_refresh_tutorial_guidance()
		return
	var crisis := MarketContent.crisis_stage(world.crisis_stage)
	playtest_banner.text = "REGIONAL OBJECTIVE — %s" % String(crisis.get("label", "Five-Well Basin"))
	playtest_status_label.text = String(crisis.get("objective", "Inspect the market, prepare the caravan, and choose the next road."))

func _refresh_tutorial_guidance() -> void:
	var objective := tutorial.objective()
	var chapter := String(objective.get("chapter", "CARAVAN LEDGER"))
	var title := String(objective.get("title", "Choose the next road"))
	var body := String(objective.get("body", "Inspect the current market and decide what the caravan should carry next."))
	if playtest_banner:
		playtest_banner.text = "CARAVAN LEDGER — %s" % chapter
	if playtest_status_label:
		playtest_status_label.text = "%s\n%s" % [title, body]
	if tutorial_panel:
		tutorial_panel.visible = true
		tutorial_chapter_label.text = chapter
		tutorial_title_label.text = title
		tutorial_body_label.text = body
		tutorial_skip_button.visible = not tutorial.completed
		tutorial_skip_button.disabled = tutorial.completed
	if last_tutorial_presented_step == tutorial.current_step:
		return
	last_tutorial_presented_step = tutorial.current_step
	match tutorial.current_step:
		TutorialDirector.STEP_BUY_WATER:
			_select_option_by_id(shop_good_option, "water")
			_select_option_by_id(cargo_good_option, "water")
			shop_quantity.value = 4
			cargo_quantity.value = 4
		TutorialDirector.STEP_PLAN_REEDWATCH:
			_select_option_by_id(destination_option, "reedwatch")
			_populate_route_options()
			_select_option_by_id(route_option, "old_road")
			_select_option_by_id(cargo_good_option, "water")
			cargo_quantity.value = 4
		TutorialDirector.STEP_SELL_WATER:
			_select_option_by_id(shop_good_option, "water")
			shop_quantity.value = maxi(1, mini(4, int(world.cargo.get("water", 0))))
		TutorialDirector.STEP_BUY_GRAIN:
			_select_option_by_id(shop_good_option, "grain")
			_select_option_by_id(cargo_good_option, "grain")
			shop_quantity.value = 4
			cargo_quantity.value = 4
		TutorialDirector.STEP_RETURN_ASHGATE:
			_select_option_by_id(destination_option, "ashgate")
			_populate_route_options()
			_select_option_by_id(route_option, "old_road")
			_select_option_by_id(cargo_good_option, "grain")
			cargo_quantity.value = 4
		TutorialDirector.STEP_SELL_GRAIN:
			_select_option_by_id(shop_good_option, "grain")
			shop_quantity.value = mini(4, int(world.cargo.get("grain", 0)))

func _hide_tutorial_guidance() -> void:
	if tutorial_panel:
		tutorial_panel.visible = false

func _refresh_opportunities() -> void:
	if opportunity_list == null or opportunity_status_label == null:
		return
	for child in opportunity_list.get_children():
		opportunity_list.remove_child(child)
		child.queue_free()
	opportunity_buttons.clear()
	contract_buttons.clear()
	crew_buttons.clear()
	crew_profile_cards.clear()
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
		else:
			contract_reason = MarketCommandProcessor.contract_acceptance_reason(world, contract_record)
			if not contract_reason.is_empty():
				contract_button.disabled = true
		contract_button.tooltip_text = contract_reason if contract_button.disabled else String(contract_record.get("tradeoff", ""))
		contract_button.set_meta("web_accessibility_id", "accept_contract_%s" % contract_id)
		contract_button.set_meta("bazaar_section", "assignments")
		contract_button.pressed.connect(_on_accept_contract_pressed.bind(contract_id))
		opportunity_list.add_child(contract_button)
		contract_buttons.append(contract_button)
		var contract_details := Label.new()
		contract_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		contract_details.add_theme_font_size_override("font_size", 12)
		contract_details.add_theme_color_override("font_color", Color("#aa9a87"))
		var relationship_terms := _contract_relationship_terms(contract_record)
		var value_terms := _contract_value_terms(contract_record)
		var compact_terms := "SPONSOR — %s · LOAD — %d %s → %s · DUE — %d days\nREWARD — %d ashmarks · LATE COST — up to %d%s\n%s\nDECISION — %s RECOVERY — %s" % [String(contract_record.get("sponsor", "")), int(contract_record.get("quantity", 0)), String(contract_record.get("good_id", "")).capitalize(), String(world.settlement(String(contract_record.get("destination_id", ""))).get("name", "destination")), int(contract_record.get("deadline_days", 0)), int(contract_record.get("reward", 0)), int(contract_record.get("failure_penalty", 0)), relationship_terms, value_terms, String(contract_record.get("decision_summary", "")), String(contract_record.get("recovery_summary", ""))]
		contract_details.text = ("LOCKED — %s\n" % contract_reason if contract_button.disabled else "") + compact_terms
		contract_details.set_meta("bazaar_section", "assignments")
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
		resolve_button.set_meta("bazaar_section", "assignments")
		resolve_button.pressed.connect(_on_resolve_contract_pressed.bind(active_id))
		opportunity_list.add_child(resolve_button)
		contract_buttons.append(resolve_button)
	var actions := MarketContent.settlement_actions_for(world.current_settlement)
	for action in actions:
		var required_emergent_faction_id := String(action.get("requires_emergent_faction_id", ""))
		if not required_emergent_faction_id.is_empty() and world.emergent_faction(required_emergent_faction_id).is_empty():
			continue
		var action_button := _wrapped_action_button()
		var action_category := String(action.get("category", ""))
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
		if effects.has("emergent_faction_support"):
			var support_effect: Dictionary = effects.get("emergent_faction_support", {})
			var support_name := String(support_effect.get("faction_id", "local group")).replace("_", " ").capitalize()
			effect_summary += ", %s support %+d" % [support_name, int(support_effect.get("delta", 0))]
		var action_prefix := "BLACK MARKET · OPTIONAL\n" if action_category == "arms_trade" else ""
		var action_terms := "%d ashmarks, %s" % [cost, effect_summary] if cost > 0 else effect_summary
		action_button.text = "%s%s — %s" % [action_prefix, String(action.get("name", "Opportunity")), action_terms]
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
		elif effects.has("cargo_cost"):
			var cargo_requirement: Dictionary = effects.get("cargo_cost", {})
			if int(world.cargo.get(String(cargo_requirement.get("good_id", "")), 0)) < int(cargo_requirement.get("quantity", 0)):
				action_button.disabled = true
				unavailable_reason = "Needs %d %s; acquire it through ordinary trade first." % [int(cargo_requirement.get("quantity", 0)), String(cargo_requirement.get("good_id", "")).capitalize()]
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
		action_button.set_meta("bazaar_section", "information")
		action_button.pressed.connect(_on_settlement_action_pressed.bind(String(action.get("id", ""))))
		opportunity_list.add_child(action_button)
		opportunity_buttons.append(action_button)
		var details := Label.new()
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 12)
		details.add_theme_color_override("font_color", Color("#aa9a87"))
		var optional_context := "OPTIONAL PARALLEL ECONOMY — Ordinary Water relief remains viable.\n" if action_category == "arms_trade" else ""
		details.text = unavailable_reason if action_button.disabled else optional_context + "%s Cost: %d ashmarks, %d visit slot, %s. %s" % [String(action.get("description", "")), cost, slots, "no day" if time_cost == 0 else "%d day" % time_cost, String(action.get("tradeoff", ""))]
		details.set_meta("bazaar_section", "information")
		opportunity_list.add_child(details)
	_append_crew_opportunity()
	_apply_bazaar_section()

func _append_crew_opportunity() -> void:
	for crew in MarketContent.crew_records():
		var crew_id := String(crew.get("id", ""))
		var recruited := world.is_crew_recruited(crew_id)
		if not recruited and world.current_settlement != String(crew.get("recruit_settlement_id", "")):
			continue
		var accent := Color("#8fae9e")
		match crew_id:
			"jorun_pale":
				accent = Color("#c6a15b")
			"tess_oryn":
				accent = Color("#c9785a")
			"mara_voss":
				accent = Color("#8fb56c")
			"orin_bell":
				accent = Color("#829fc2")
		var card := PanelContainer.new()
		card.name = "CrewRosterCard%d" % crew_profile_cards.size()
		card.set_meta("bazaar_section", "crew")
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color("#211a16")
		card_style.border_color = accent.darkened(0.32)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(3)
		card_style.content_margin_left = 8
		card_style.content_margin_right = 8
		card_style.content_margin_top = 8
		card_style.content_margin_bottom = 8
		card.add_theme_stylebox_override("panel", card_style)
		opportunity_list.add_child(card)
		crew_profile_cards.append(card)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var portrait := CrewPortrait.new()
		portrait.name = "CrewPortrait%d" % (crew_profile_cards.size() - 1)
		portrait.custom_minimum_size = Vector2(68, 84)
		portrait.crew_id = crew_id
		portrait.accent = accent
		row.add_child(portrait)
		var profile_copy := VBoxContainer.new()
		profile_copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		profile_copy.add_theme_constant_override("separation", 4)
		row.add_child(profile_copy)
		var identity := Label.new()
		identity.name = "CrewIdentity%d" % (crew_profile_cards.size() - 1)
		identity.text = "%s · %s" % [String(crew.get("role", "Crew")).to_upper(), "ASSIGNED" if world.assigned_crew == crew_id else "ON ROSTER" if recruited else "AVAILABLE"]
		identity.add_theme_font_size_override("font_size", 10)
		identity.add_theme_color_override("font_color", accent)
		profile_copy.add_child(identity)
		var button := _wrapped_action_button()
		button.name = "CrewAction%d" % crew_buttons.size()
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
		button.set_meta("bazaar_section", "crew")
		profile_copy.add_child(button)
		crew_buttons.append(button)
		var details := Label.new()
		details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		details.add_theme_font_size_override("font_size", 11)
		details.add_theme_color_override("font_color", Color("#aa9a87"))
		details.text = "UNAVAILABLE — %s" % reason if button.disabled else "PERSON — %s\nLEVER — %s\nLIMIT — %s" % [String(crew.get("personality", "")), String(crew.get("hook", "")), String(crew.get("limitation", ""))]
		details.set_meta("bazaar_section", "crew")
		profile_copy.add_child(details)

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
	var summaries: Array[String] = []
	for contract_id_value in contract_ids:
		var contract_record := world.active_contract(String(contract_id_value))
		var good_id := String(contract_record.get("good_id", ""))
		var quantity := int(contract_record.get("quantity", 0))
		var held := int(world.cargo.get(good_id, 0))
		var free_capacity := world.cargo_capacity - int(world.cargo.get("weight", 0))
		var destination_name := String(world.settlement(String(contract_record.get("destination_id", ""))).get("name", "destination"))
		summaries.append("%s — %s wants %d %s at %s by Day %d for %d ashmarks. Held %d/%d; free hold %d." % [String(contract_record.get("name", "Contract")), String(contract_record.get("sponsor", "Sponsor")), quantity, good_id, destination_name, int(contract_record.get("deadline_day", 0)), int(contract_record.get("reward", 0)), held, quantity, free_capacity])
	var summary := "\n".join(summaries)
	active_contract_label.text = "ACTIVE CONTRACTS\n" + summary
	departure_contract_label.text = "CONTRACT PINS\n" + summary

func _contract_relationship_terms(contract_record: Dictionary) -> String:
	var parts: Array[String] = []
	var minimum_reputation: Dictionary = contract_record.get("minimum_reputation", {})
	for faction_id_value in minimum_reputation.keys():
		var faction_id := String(faction_id_value)
		parts.append("requires %s %d" % [String(MarketContent.faction(faction_id).get("name", faction_id)), int(minimum_reputation.get(faction_id_value, 0))])
	for field_and_label in [["success_reputation", "Success"], ["failure_reputation", "Failure"]]:
		var effects: Dictionary = contract_record.get(String(field_and_label[0]), {})
		for faction_id_value in effects.keys():
			var delta := int(effects.get(faction_id_value, 0))
			if delta != 0:
				var faction_id := String(faction_id_value)
				parts.append("%s %s %+d" % [String(field_and_label[1]).to_lower(), String(MarketContent.faction(faction_id).get("name", faction_id)), delta])
	return " · " + " · ".join(parts) if not parts.is_empty() else ""

func _contract_value_terms(contract_record: Dictionary) -> String:
	var origin_id := String(contract_record.get("origin_id", ""))
	var destination_id := String(contract_record.get("destination_id", ""))
	var best_preview: Dictionary = {}
	for route_id_value in MarketContent.routes_from(origin_id):
		var route_id := String(route_id_value)
		if not MarketContent.route_connects(route_id, origin_id, destination_id):
			continue
		var preview := MarketEconomy.contract_reward_preview(
			contract_record,
			world.settlement(origin_id),
			world.settlement(destination_id),
			world.route(route_id, origin_id, destination_id),
			world.pricing_context(),
		)
		if bool(preview.get("ok", false)) and (best_preview.is_empty() or int(preview.get("expected_net_profit", 0)) > int(best_preview.get("expected_net_profit", 0))):
			best_preview = preview
	if best_preview.is_empty():
		return "PATH VALUE — unavailable until a route connects the sponsor and destination"
	var vector: Dictionary = best_preview.get("reward_vector", {})
	var standing_total := 0
	for delta_value in vector.get("standing", {}).values():
		standing_total += int(delta_value)
	return "PATH VALUE — %+d expected · %d provisions · %d/%d hold · %+d standing · %d day · %d visit slot" % [int(vector.get("expected_net_profit", 0)), int(vector.get("provisions_used", 0)), int(vector.get("capacity_committed", 0)), world.cargo_capacity, standing_total, int(vector.get("time_days", 0)), int(vector.get("visit_slots", 0))]

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
		if conflict_outcome_panel.visible:
			_refresh_conflict_outcome_receipt(_latest_conflict_event_record())
	if pending.is_empty():
		if arrival_pending and (pause_layer == null or not pause_layer.visible):
			_grab_focus_if_available(enter_settlement_button)
		return
	if not event_revealed:
		return
	var view := JourneyPresenter.event_view(world, pending)
	event_title_label.text = String(view.get("title", "Route decision"))
	event_setup_label.text = String(view.get("setup", ""))
	event_stakes_label.text = String(view.get("stakes", ""))
	event_threat_label.text = String(view.get("threat_label", ""))
	event_exposed_label.text = String(view.get("exposed_label", ""))
	event_route_label.text = String(view.get("road_label", ""))
	event_basis_label.text = String(view.get("basis_label", ""))
	event_basis_label.visible = not event_basis_label.text.is_empty()
	event_decision_label.text = String(view.get("decision_label", ""))
	event_rules_label.text = String(view.get("rules_label", ""))
	for choice_view in view.get("choices", []):
		var button := _wrapped_action_button(92.0)
		button.name = "RoadEventChoice%d" % event_choice_buttons.size()
		button.text = String(choice_view.get("text", ""))
		button.disabled = bool(choice_view.get("disabled", false))
		button.tooltip_text = String(choice_view.get("tooltip", ""))
		button.pressed.connect(_on_event_choice_pressed.bind(String(pending.get("id", "")), String(choice_view.get("id", ""))))
		event_choice_list.add_child(button)
		event_choice_buttons.append(button)
		if not button.disabled:
			enabled_choice_buttons.append(button)
		if button.disabled:
			var reason_label := Label.new()
			reason_label.text = "Unavailable: %s" % String(choice_view.get("blocked_reason", ""))
			reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			reason_label.add_theme_font_size_override("font_size", 11)
			reason_label.add_theme_color_override("font_color", Color("#b5a18b"))
			event_choice_list.add_child(reason_label)
			event_choice_reason_labels.append(reason_label)
	if not enabled_choice_buttons.is_empty():
		_link_focus_cycle(enabled_choice_buttons)
	if event_readiness_label:
		event_readiness_label.text = "READINESS · %d/%d RESPONSES AVAILABLE%s" % [enabled_choice_buttons.size(), event_choice_buttons.size(), " · Blocked responses name their requirement." if enabled_choice_buttons.size() < event_choice_buttons.size() else ""]
	if pause_layer == null or not pause_layer.visible:
		if _grab_first_enabled(event_choice_buttons) and not get_tree().process_frame.is_connected(_ensure_focused_control_visible):
			get_tree().process_frame.connect(_ensure_focused_control_visible, CONNECT_ONE_SHOT)
func _conflict_outcome_comparison(result: Dictionary) -> String:
	var state_delta: Dictionary = result.get("state_delta", {})
	var event_record: Dictionary = Dictionary(state_delta.get("event", {})).duplicate(true)
	event_record["outcome"] = Dictionary(state_delta.get("outcome", {})).duplicate(true)
	event_record["choice_id"] = String(state_delta.get("choice_id", ""))
	return JourneyPresenter.conflict_outcome_comparison(world, event_record)

func _latest_conflict_event_record() -> Dictionary:
	if world == null or world.event_history.is_empty():
		return {}
	return Dictionary(world.event_history.back())

func _refresh_conflict_outcome_receipt(event_record: Dictionary) -> void:
	if conflict_outcome_receipt == null:
		return
	var receipt := JourneyPresenter.conflict_outcome_receipt(event_record)
	conflict_outcome_receipt.visible = not receipt.is_empty()
	if receipt.is_empty():
		return
	var state := String(receipt.get("state", "certain"))
	var accent := Color("#8fb59f")
	var surface := Color("#17231d")
	if state == "loss":
		accent = Color("#d97757")
		surface = Color("#2a1815")
	elif state == "certain":
		accent = Color("#c9ab72")
		surface = Color("#242019")
	var style := StyleBoxFlat.new()
	style.bg_color = surface
	style.border_color = accent.darkened(0.15)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	conflict_outcome_receipt.add_theme_stylebox_override("panel", style)
	conflict_outcome_receipt_kicker.text = String(receipt.get("kicker", "JOURNEY RESULT"))
	conflict_outcome_receipt_kicker.add_theme_color_override("font_color", accent)
	conflict_outcome_receipt_title.text = String(receipt.get("title", ""))
	conflict_outcome_receipt_title.add_theme_color_override("font_color", Color("#f4e6c7"))
	conflict_outcome_receipt_detail.text = String(receipt.get("detail", ""))
	conflict_outcome_receipt_detail.add_theme_color_override("font_color", Color("#bda88f"))
	conflict_outcome_receipt_glyph.receipt_state = state
	conflict_outcome_receipt_glyph.accent = accent
	conflict_outcome_receipt_glyph.queue_redraw()

func _latest_conflict_outcome_text() -> String:
	if world == null or world.event_history.is_empty():
		return ""
	return JourneyPresenter.conflict_outcome_comparison(world, Dictionary(world.event_history.back()))

func _conflict_outcome_comparison_from_event(event_record: Dictionary) -> String:
	return JourneyPresenter.conflict_outcome_comparison(world, event_record)

func _best_recovery_sale() -> Dictionary:
	return JourneyPresenter.best_recovery_sale(world)

func _safest_affordable_recovery_route(available_money: int) -> Dictionary:
	return JourneyPresenter.safest_affordable_recovery_route(world, available_money)

func _has_completed_contract(contract_id: String) -> bool:
	for contract in world.contract_history:
		if String(contract.get("id", "")) == contract_id and String(contract.get("status", "")) == "completed":
			return true
	return false

func _campaign_outlook_text() -> String:
	if not world.ending_id.is_empty():
		return "CAMPAIGN OUTLOOK — Conclusion recorded: %s." % String(MarketContent.ending(world.ending_id).get("title", world.ending_id))
	var relief_mark := "done" if _has_completed_contract("reedwatch_water_relief_01") else "needed"
	if not world.emergent_faction("well_commons").is_empty():
		relief_mark = "Commons active"
	return "CAMPAIGN OUTLOOK — Outcomes are checked at crisis stage 3 (Day 10).\nOpen Routes: relief %s · Reedwatch %d/2 resilience · arms %d/1 max.\nOrder at the Cistern: Wardens %d/3 · Caravans %d/1 max · arms %d/1 max.\nNo Road Owns the Sky: Caravans %d/2 · Wardens %d/1 max · arms %d/1 max.\nThe Best Margin: %d/220 ashmarks · Reedwatch %d/1 max resilience · arms %d/1 max." % [relief_mark, world.resilience_for("reedwatch"), world.arms_escalation, int(world.reputation.get("wardens", 0)), int(world.reputation.get("caravans", 0)), world.arms_escalation, int(world.reputation.get("caravans", 0)), int(world.reputation.get("wardens", 0)), world.arms_escalation, world.money, world.resilience_for("reedwatch"), world.arms_escalation]

func _set_event(text: String) -> void:
	event_label.text = text
	if event_scroll:
		event_scroll.scroll_vertical = 0

func _apply_bazaar_identity_theme(settlement: Dictionary) -> void:
	var identity: Dictionary = settlement.get("identity", {})
	var tint := Color(String(identity.get("tint", "#80634d")))
	var sky := Color(String(identity.get("sky", "#30251f")))
	var ground := Color(String(identity.get("ground", "#443327")))
	if shop_background:
		shop_background.color = sky.darkened(0.62)
	if shop_market_card:
		var market_style := StyleBoxFlat.new()
		market_style.bg_color = ground.darkened(0.42)
		market_style.border_color = tint.darkened(0.08)
		market_style.set_border_width_all(2)
		market_style.set_corner_radius_all(3)
		shop_market_card.add_theme_stylebox_override("panel", market_style)
	if shop_action_card:
		var action_style := StyleBoxFlat.new()
		action_style.bg_color = sky.darkened(0.34)
		action_style.border_color = tint.darkened(0.18)
		action_style.set_border_width_all(2)
		action_style.set_corner_radius_all(3)
		shop_action_card.add_theme_stylebox_override("panel", action_style)

func _refresh_ui() -> void:
	tutorial.refresh(world, _current_ui_state_id(), arrival_pending)
	if not tutorial.enabled and not tutorial.completed:
		_hide_tutorial_guidance()
	_refresh_caravan_status()
	var journey_locked := not world.pending_event.is_empty() or arrival_pending
	var journey_view := JourneyPanelView.snapshot(world, String(map_panel.travel_phase), map_panel._road_waypoint_label(), arrival_pending, committed_journey_message, last_conflict_outcome_text)
	var road_waiting: bool = bool(journey_view.road_waiting)
	var actively_traveling: bool = bool(journey_view.actively_traveling)
	if map_hint:
		map_hint.text = String(journey_view.map_hint)
	if event_label and not String(journey_view.event_text).is_empty():
		event_label.text = String(journey_view.event_text)
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
		_apply_bazaar_identity_theme(settlement)
		
		var crisis := MarketContent.crisis_stage(world.crisis_stage)
		if shop_title_label:
			shop_title_label.text = "%s BAZAAR" % String(settlement.get("name", "Settlement")).to_upper()
		var arms_rules := MarketContent.arms_trade_rules()
		var arms_label := String(arms_rules.get("noticed_label", "Noticed traffic")) if world.arms_escalation >= int(arms_rules.get("inspection_threshold", 2)) else String(arms_rules.get("quiet_label", "Quiet manifests"))
		var leads_text := " · Leads %d" % world.known_information.size() if not world.known_information.is_empty() else ""
		var regional_faction_text := ""
		match String(settlement.get("region_id", "five_well_basin")):
			"glasswind_reach":
				regional_faction_text = " · Glass Consortium %+d" % int(world.reputation.get("glass_consortium", 0))
			"siltfire_march":
				regional_faction_text = " · Bellkeepers %+d" % int(world.reputation.get("bellkeepers", 0))
		shop_status_label.text = "MARKET — %s · Day %d · Crisis %d: %s · Resilience %d/10\nREGION — %s · Wardens %+d · Caravans %+d%s · Arms %d/6 (%s)%s" % [String(settlement.get("role", "market")).capitalize(), world.day, world.crisis_stage, String(crisis.get("label", "Regional pressure")), world.resilience_for(world.current_settlement), String(crisis.get("objective", "Keep trading.")), int(world.reputation.get("wardens", 0)), int(world.reputation.get("caravans", 0)), regional_faction_text, world.arms_escalation, arms_label, leads_text]
		if not world.ending_id.is_empty():
			shop_status_label.text += "\nENDING — %s\n%s" % [String(MarketContent.ending(world.ending_id).get("title", world.ending_id)), world.ending_summary]
	if ending_panel and ending_label:
		if world.ending_id != last_presented_ending_id:
			ending_debrief_dismissed = false
			last_presented_ending_id = world.ending_id
		ending_panel.visible = not world.ending_id.is_empty() and not ending_debrief_dismissed
		if ending_panel.visible:
			var debrief := JourneyPresenter.campaign_debrief(world)
			ending_label.text = String(debrief.get("text", ""))
			_link_focus_cycle([ending_continue_button, ending_replay_button, ending_title_button, ending_feedback_button])
			if shop_layer.visible and get_viewport().gui_get_focus_owner() == null:
				call_deferred("_grab_focus_if_available", ending_continue_button)
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
		departure_status_label.text = String(journey_view.departure_status)
	if journey_phase_title_label:
		journey_phase_title_label.text = String(journey_view.panel_title)
	if enter_settlement_button:
		enter_settlement_button.text = String(journey_view.enter_action)
		enter_settlement_button.visible = arrival_pending and map_panel != null and map_panel.travel_phase == "arrived"
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
	var journey_view := JourneyPanelView.snapshot(world, String(map_panel.travel_phase), map_panel._road_waypoint_label(), arrival_pending, committed_journey_message, last_conflict_outcome_text)
	caravan_context_label.text = String(journey_view.caravan_context)

class ResponsiveColumns extends Container:
	var compact := false
	var separation := 24.0
	var first_ratio := 1.5
	var compact_visual_height := 220.0

	func set_compact(enabled: bool) -> void:
		if compact == enabled:
			return
		compact = enabled
		update_minimum_size()
		queue_sort()

	func _get_minimum_size() -> Vector2:
		return Vector2.ZERO

	func _notification(what: int) -> void:
		if what != NOTIFICATION_SORT_CHILDREN:
			return
		var controls: Array[Control] = []
		for child in get_children():
			if child is Control and child.visible:
				controls.append(child)
		if controls.is_empty():
			return
		if controls.size() == 1:
			fit_child_in_rect(controls[0], Rect2(Vector2.ZERO, size))
			return
		var first := controls[0]
		var second := controls[1]
		var required_split_width := first.get_combined_minimum_size().x + separation + second.get_combined_minimum_size().x
		var use_compact := compact or size.x + 0.5 < required_split_width
		if use_compact:
			var first_height := minf(compact_visual_height, maxf(140.0, size.y * 0.42))
			var second_height := maxf(0.0, size.y - first_height - separation)
			fit_child_in_rect(first, Rect2(Vector2.ZERO, Vector2(size.x, first_height)))
			fit_child_in_rect(second, Rect2(Vector2(0, first_height + separation), Vector2(size.x, second_height)))
			return
		var available_width := maxf(0.0, size.x - separation)
		var first_width := available_width * first_ratio / (first_ratio + 1.0)
		fit_child_in_rect(first, Rect2(Vector2.ZERO, Vector2(first_width, size.y)))
		fit_child_in_rect(second, Rect2(Vector2(first_width + separation, 0), Vector2(available_width - first_width, size.y)))

class CrewPortrait extends Control:
	var crew_id := ""
	var accent := Color("#8fae9e")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var bounds := Rect2(Vector2(1, 1), size - Vector2(2, 2))
		draw_rect(bounds, Color("#17130f"), true)
		draw_rect(bounds, accent.darkened(0.25), false, 2.0)
		var center := Vector2(size.x * 0.5, size.y * 0.40)
		draw_circle(center, 14.0, Color("#d2a170"))
		draw_colored_polygon(PackedVector2Array([
			Vector2(size.x * 0.18, size.y * 0.90),
			Vector2(size.x * 0.28, size.y * 0.58),
			Vector2(size.x * 0.72, size.y * 0.58),
			Vector2(size.x * 0.82, size.y * 0.90),
		]), accent.darkened(0.18))
		match crew_id:
			"nara_vey":
				draw_colored_polygon(PackedVector2Array([
					center + Vector2(-21, 4), center + Vector2(-15, -20),
					center + Vector2(0, -28), center + Vector2(17, -19),
					center + Vector2(22, 5),
				]), accent.darkened(0.35))
				draw_line(Vector2(size.x * 0.18, size.y * 0.70), Vector2(size.x * 0.83, size.y * 0.52), Color("#e7d1a6"), 3.0, true)
				draw_circle(Vector2(size.x * 0.80, size.y * 0.53), 5.0, accent, false, 2.0)
			"jorun_pale":
				draw_rect(Rect2(center + Vector2(-18, -18), Vector2(36, 7)), accent.darkened(0.30), true)
				draw_rect(Rect2(Vector2(size.x * 0.25, size.y * 0.66), Vector2(size.x * 0.50, size.y * 0.25)), Color("#3b3024"), true)
				for line_index in range(3):
					draw_line(Vector2(size.x * 0.31, size.y * (0.72 + line_index * 0.06)), Vector2(size.x * 0.69, size.y * (0.72 + line_index * 0.06)), accent, 1.5)
			"tess_oryn":
				draw_arc(center, 19.0, PI, TAU, 16, accent.darkened(0.28), 7.0, true)
				draw_line(Vector2(size.x * 0.31, size.y * 0.66), Vector2(size.x * 0.69, size.y * 0.80), Color("#e2bd8d"), 4.0, true)
				draw_circle(Vector2(size.x * 0.69, size.y * 0.80), 5.0, accent, false, 2.0)
			"mara_voss":
				draw_rect(Rect2(center + Vector2(-19, -19), Vector2(38, 6)), accent.darkened(0.30), true)
				draw_circle(Vector2(size.x * 0.33, size.y * 0.76), 11.0, Color("#2c281f"), false, 3.0)
				draw_circle(Vector2(size.x * 0.67, size.y * 0.76), 11.0, Color("#2c281f"), false, 3.0)
				draw_line(Vector2(size.x * 0.33, size.y * 0.76), Vector2(size.x * 0.67, size.y * 0.76), Color("#e7d1a6"), 4.0, true)
			"orin_bell":
				draw_arc(center, 19.0, PI, TAU, 18, accent.darkened(0.30), 6.0, true)
				draw_circle(Vector2(size.x * 0.50, size.y * 0.70), 10.0, Color("#202a34"), true)
				draw_circle(Vector2(size.x * 0.50, size.y * 0.70), 10.0, accent, false, 2.0)
				draw_line(Vector2(size.x * 0.50, size.y * 0.60), Vector2(size.x * 0.50, size.y * 0.82), Color("#ecd7a4"), 2.0, true)
				draw_line(Vector2(size.x * 0.39, size.y * 0.70), Vector2(size.x * 0.61, size.y * 0.70), Color("#ecd7a4"), 2.0, true)


class JourneyConsequenceGlyph extends Control:
	var receipt_state := "certain"
	var accent := Color("#c9ab72")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var center := size * 0.5
		var radius := minf(size.x, size.y) * 0.38
		draw_circle(center, radius, accent.darkened(0.55), true)
		draw_arc(center, radius, 0.0, TAU, 32, accent, 2.0, true)
		var crate_rect := Rect2(center + Vector2(-11, -8), Vector2(22, 17))
		draw_rect(crate_rect, accent, false, 2.0)
		draw_line(crate_rect.position + Vector2(0, 5), crate_rect.end - Vector2(0, 12), accent, 1.5)
		draw_line(crate_rect.position + Vector2(0, 11), crate_rect.end - Vector2(0, 6), accent, 1.5)
		if receipt_state == "loss":
			draw_line(center + Vector2(-15, 15), center + Vector2(15, -15), accent.lightened(0.2), 4.0, true)
		else:
			draw_line(center + Vector2(-9, 1), center + Vector2(-2, 8), accent.lightened(0.2), 3.0, true)
			draw_line(center + Vector2(-2, 8), center + Vector2(12, -8), accent.lightened(0.2), 3.0, true)


class TitleScene extends Control:
	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var bounds := Rect2(Vector2.ZERO, size)
		draw_rect(bounds, Color("#17110d"), true)
		for band in range(7):
			var y := size.y * (0.32 + band * 0.045)
			draw_colored_polygon(PackedVector2Array([
				Vector2(0, y + 18), Vector2(size.x * 0.18, y - 8 + band * 2), Vector2(size.x * 0.38, y + 5),
				Vector2(size.x * 0.58, y - 14), Vector2(size.x * 0.78, y + 2), Vector2(size.x, y - 10), Vector2(size.x, size.y), Vector2(0, size.y),
			]), Color("#2a211b").lightened(float(band) * 0.025))
		var sun := Vector2(size.x * 0.72, size.y * 0.24)
		draw_circle(sun, minf(size.x, size.y) * 0.09, Color("#b86842"))
		draw_circle(sun, minf(size.x, size.y) * 0.065, Color("#d89a61"))
		var road := PackedVector2Array([
			Vector2(size.x * 0.43, size.y), Vector2(size.x * 0.57, size.y),
			Vector2(size.x * 0.53, size.y * 0.50), Vector2(size.x * 0.49, size.y * 0.50),
		])
		draw_colored_polygon(road, Color("#6e5a43"))
		_draw_caravan(Vector2(size.x * 0.51, size.y * 0.61), minf(size.x, size.y) / 540.0)
		draw_string(ThemeDB.fallback_font, Vector2(30, 56), "MARKET OF ASH", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("#f0cf91"))
		draw_string(ThemeDB.fallback_font, Vector2(32, 86), "A TRADE ROUTE IS A PROMISE YOU MAKE TO THE ROAD", HORIZONTAL_ALIGNMENT_LEFT, maxf(0, size.x - 64), 13, Color("#c7b49a"))
		draw_string(ThemeDB.fallback_font, Vector2(32, size.y - 30), "THE FIVE-WELL BASIN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#d08b62"))

	func _draw_caravan(center: Vector2, scale: float) -> void:
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-45, -14) * scale, center + Vector2(34, -14) * scale,
			center + Vector2(44, 13) * scale, center + Vector2(-48, 13) * scale,
		]), Color("#9b5237"))
		draw_colored_polygon(PackedVector2Array([
			center + Vector2(-34, -15) * scale, center + Vector2(-19, -42) * scale,
			center + Vector2(18, -42) * scale, center + Vector2(32, -15) * scale,
		]), Color("#d0a062"))
		draw_line(center + Vector2(-19, -42) * scale, center + Vector2(-19, 4) * scale, Color("#493127"), 3.0 * scale)
		draw_line(center + Vector2(18, -42) * scale, center + Vector2(18, 4) * scale, Color("#493127"), 3.0 * scale)
		draw_circle(center + Vector2(-27, 15) * scale, 11 * scale, Color("#241a15"))
		draw_circle(center + Vector2(27, 15) * scale, 11 * scale, Color("#241a15"))
		draw_circle(center + Vector2(-27, 15) * scale, 4 * scale, Color("#c08b52"))
		draw_circle(center + Vector2(27, 15) * scale, 4 * scale, Color("#c08b52"))

class IntroScene extends Control:
	var scene_id := "basin"

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func set_scene(next_scene_id: String) -> void:
		scene_id = next_scene_id
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#17110d"), true)
		match scene_id:
			"caravan":
				_draw_caravan_ledger()
			"road":
				_draw_road_choice()
			_:
				_draw_basin()

	func _draw_basin() -> void:
		draw_circle(Vector2(size.x * 0.76, size.y * 0.20), minf(size.x, size.y) * 0.10, Color("#bd7047"))
		for layer in range(5):
			var y := size.y * (0.34 + layer * 0.10)
			draw_colored_polygon(PackedVector2Array([Vector2(0, y), Vector2(size.x * 0.18, y - 42), Vector2(size.x * 0.36, y + 4), Vector2(size.x * 0.58, y - 55), Vector2(size.x * 0.79, y - 5), Vector2(size.x, y - 38), Vector2(size.x, size.y), Vector2(0, size.y)]), Color("#332820").lightened(layer * 0.035))
		for well_index in range(5):
			var point := Vector2(size.x * (0.14 + well_index * 0.17), size.y * (0.56 + (well_index % 2) * 0.08))
			draw_circle(point, 12, Color("#5f817b"), false, 3.0)
			draw_line(point + Vector2(-20, 18), point + Vector2(20, 18), Color("#a97951"), 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(24, size.y - 32), "TEN MARKETS · SEVEN ROADS · ONE CARAVAN NETWORK", HORIZONTAL_ALIGNMENT_LEFT, size.x - 48, 14, Color("#e6c58d"))

	func _draw_caravan_ledger() -> void:
		var center := Vector2(size.x * 0.50, size.y * 0.48)
		var scale := minf(size.x, size.y) / 500.0
		draw_circle(center, 118 * scale, Color("#2a211b"))
		draw_rect(Rect2(center + Vector2(-120, -48) * scale, Vector2(240, 96) * scale), Color("#8c4e35"), true)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-96, -50) * scale, center + Vector2(-52, -112) * scale, center + Vector2(56, -112) * scale, center + Vector2(98, -50) * scale]), Color("#c69a61"))
		for wheel_x in [-72, 72]:
			draw_circle(center + Vector2(wheel_x, 56) * scale, 28 * scale, Color("#201814"))
			draw_circle(center + Vector2(wheel_x, 56) * scale, 9 * scale, Color("#d1a268"))
		var labels := ["ASHMARKS", "PROVISIONS", "HOLD", "CREW"]
		for index in range(labels.size()):
			var x := size.x * (0.16 + index * 0.23)
			draw_circle(Vector2(x, size.y * 0.76), 18, Color(["#c6a15b", "#71835c", "#9a795f", "#6f9b87"][index]), true)
			draw_string(ThemeDB.fallback_font, Vector2(x - 45, size.y * 0.83), labels[index], HORIZONTAL_ALIGNMENT_CENTER, 90, 12, Color("#e6c58d"))

	func _draw_road_choice() -> void:
		var origin := Vector2(size.x * 0.16, size.y * 0.70)
		var destination := Vector2(size.x * 0.84, size.y * 0.28)
		var colors := [Color("#c46f45"), Color("#c6a15b"), Color("#6f9b87")]
		var bends := [Vector2(size.x * 0.38, size.y * 0.40), Vector2(size.x * 0.52, size.y * 0.62), Vector2(size.x * 0.67, size.y * 0.22)]
		for index in range(3):
			draw_polyline(PackedVector2Array([origin, bends[index], destination]), colors[index], 8.0)
		draw_circle(origin, 18, Color("#f0cf91"))
		draw_circle(destination, 18, Color("#5f817b"))
		var captions := ["CHEAP · EXPOSED", "GUARDED · COSTLY", "FAST · THIRSTY"]
		for index in range(captions.size()):
			draw_string(ThemeDB.fallback_font, Vector2(28, 48 + index * 32), captions[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, colors[index])
