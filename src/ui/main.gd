extends Control

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

const PLAYTEST_SEED := 1107
const PLAYTEST_GOOD := "grain"
const PLAYTEST_QUANTITY := 2
const PLAYTEST_DESTINATION := "reedwatch"
const PLAYTEST_ROUTE := "old_road"

var world: AshWorldState
var game_layer: Control
var shop_layer: Control
var menu_layer: Control
var start_game_button: Button
var shop_good_option: OptionButton
var shop_quantity: SpinBox
var shop_market_preview_label: Label
var shop_status_label: Label
var shop_cargo_label: Label
var opportunity_status_label: Label
var opportunity_list: VBoxContainer
var opportunity_buttons: Array[Button] = []
var contract_buttons: Array[Button] = []
var crew_buttons: Array[Button] = []
var active_contract_label: Label
var plan_departure_button: Button
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
var arrival_pending := false
var guided_test_button: Button
var playtest_banner: Label
var playtest_status_label: Label
var playtest_grain_sold := 0
var status_label: Label
var event_label: Label
var destination_option: OptionButton
var route_option: OptionButton
var cargo_good_option: OptionButton
var cargo_quantity: SpinBox
var market_preview_label: Label
var route_preview_label: Label
var log_label: Label
var map_panel
var selected_map_cell: Vector2i = Vector2i(-1, -1)

func _ready() -> void:
	world = AshWorldState.new(PLAYTEST_SEED)
	game_layer = Control.new()
	game_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_layer)
	_build_ui()
	_build_shop()
	_build_main_menu()
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
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	card.add_child(content)

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
	preset.text = "QUICK PLAYTEST\nAshgate · Day 1 · 120 ashmarks · 12 provisions · empty cargo\nSuggested first move: buy 2 grain, then compare the Old Road to Reedwatch."
	preset.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preset.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preset.add_theme_color_override("font_color", Color("#f0d2a0"))
	content.add_child(preset)
	start_game_button = Button.new()
	start_game_button.text = "Start Game"
	start_game_button.custom_minimum_size = Vector2(0, 48)
	start_game_button.pressed.connect(_on_start_game_pressed)
	content.add_child(start_game_button)

func _show_main_menu() -> void:
	game_layer.visible = false
	shop_layer.visible = false
	menu_layer.visible = true
	if start_game_button:
		start_game_button.grab_focus()

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

func _show_departure() -> void:
	shop_layer.visible = false
	game_layer.visible = true
	_refresh_ui()

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
	var market := VBoxContainer.new()
	market.add_theme_constant_override("separation", 14)
	market_card.add_child(market)
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
	market.add_child(purchase_row)
	var buy_button := Button.new()
	buy_button.text = "Buy cargo"
	buy_button.tooltip_text = "Buy the selected cargo from this settlement."
	buy_button.pressed.connect(_on_buy_pressed)
	purchase_row.add_child(buy_button)
	var sell_button := Button.new()
	sell_button.text = "Sell selected cargo"
	sell_button.tooltip_text = "Sell the selected cargo held by the caravan."
	sell_button.pressed.connect(_on_sell_pressed)
	purchase_row.add_child(sell_button)
	guided_test_button = Button.new()
	guided_test_button.text = "Optional: Buy 2 grain"
	guided_test_button.tooltip_text = "Runs the normal buy command for the first-run learning example."
	guided_test_button.pressed.connect(_on_guided_test_action)
	market.add_child(guided_test_button)
	shop_good_option.item_selected.connect(_on_shop_plan_changed)
	shop_quantity.value_changed.connect(_on_shop_quantity_changed)

	var action_card := PanelContainer.new()
	action_card.custom_minimum_size = Vector2(360, 0)
	columns.add_child(action_card)
	var actions := VBoxContainer.new()
	actions.add_theme_constant_override("separation", 14)
	action_card.add_child(actions)
	var caravan_title := Label.new()
	caravan_title.text = "CARAVAN"
	caravan_title.add_theme_font_size_override("font_size", 20)
	caravan_title.add_theme_color_override("font_color", Color("#e6c58d"))
	actions.add_child(caravan_title)
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
	actions.add_child(next_step)
	plan_departure_button = Button.new()
	plan_departure_button.text = "Plan departure"
	plan_departure_button.custom_minimum_size = Vector2(0, 48)
	plan_departure_button.tooltip_text = "Open the regional map, choose a legal corridor, and inspect the full route forecast."
	plan_departure_button.pressed.connect(_on_plan_departure_pressed)
	actions.add_child(plan_departure_button)
	var save_button := Button.new()
	save_button.text = "Save prototype state"
	save_button.pressed.connect(_on_save_pressed)
	actions.add_child(save_button)
	var reset_button := Button.new()
	reset_button.text = "Reset run"
	reset_button.pressed.connect(_on_reset_pressed)
	actions.add_child(reset_button)

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#17130f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_layer.add_child(background)

	map_panel = MapPanel.new()
	map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	map_panel.world = world
	map_panel.grid_cell_selected.connect(_on_map_cell_selected)
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

	var subtitle := Label.new()
	subtitle.text = "A trade route is a promise you make to the road."
	subtitle.add_theme_color_override("font_color", Color("#b5a18b"))
	left.add_child(subtitle)

	playtest_banner = Label.new()
	playtest_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	playtest_banner.add_theme_color_override("font_color", Color("#f0d2a0"))
	left.add_child(playtest_banner)
	playtest_status_label = Label.new()
	playtest_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	playtest_status_label.add_theme_color_override("font_color", Color("#e6c58d"))
	left.add_child(playtest_status_label)

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	left.add_child(status_label)

	var map_hint := Label.new()
	map_hint.text = "Click the regional grid to select a future placement cell; route lanes show where the caravan can travel."
	map_hint.add_theme_color_override("font_color", Color("#c7b49a"))
	left.add_child(map_hint)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 320)
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
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	right.add_child(controls)

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
	return_to_shop_button.tooltip_text = "Go back to the settlement market without spending resources."
	return_to_shop_button.pressed.connect(_on_return_to_shop_pressed)
	controls.add_child(return_to_shop_button)

	commit_departure_button = Button.new()
	commit_departure_button.text = "Commit departure"
	commit_departure_button.custom_minimum_size = Vector2(0, 48)
	commit_departure_button.tooltip_text = "Pay the displayed route cost, consume provisions, and resolve this route's risk."
	commit_departure_button.pressed.connect(_on_depart_pressed)
	controls.add_child(commit_departure_button)

	arrival_pending = false
	enter_settlement_button = Button.new()
	enter_settlement_button.text = "Enter settlement"
	enter_settlement_button.tooltip_text = "Return to the central shop after reviewing the route outcome."
	enter_settlement_button.pressed.connect(_on_enter_settlement_pressed)
	enter_settlement_button.visible = false
	controls.add_child(enter_settlement_button)

	departure_status_label = Label.new()
	departure_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	departure_status_label.add_theme_color_override("font_color", Color("#f0d2a0"))
	controls.add_child(departure_status_label)

	var save_button := Button.new()
	save_button.text = "Save prototype state"
	save_button.pressed.connect(_on_save_pressed)
	controls.add_child(save_button)

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
	world = AshWorldState.new(PLAYTEST_SEED)
	playtest_grain_sold = 0
	selected_map_cell = Vector2i(-1, -1)
	if map_panel:
		map_panel.world = world
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
	playtest_banner.text = "QUICK PLAYTEST — A compact trade run through the Five-Well Basin. The recommendation is optional; every normal trade and route choice remains available."
	_set_event("Ashgate market is open. Inspect local prices, load cargo, then plan a route when you are ready.")
	_show_shop()

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
	if result.ok:
		guided_test_button.disabled = true
	_show_command_result(result, "Test action")

func _on_plan_departure_pressed() -> void:
	_sync_shop_plan_to_departure()
	_set_event("Departure planning is open. Compare a legal route before committing; returning to the shop spends nothing.")
	_show_departure()

func _on_return_to_shop_pressed() -> void:
	_sync_departure_plan_to_shop()
	_set_event("Back at the settlement shop. Your planning selection was preserved; no resources changed.")
	_show_shop()

func _on_enter_settlement_pressed() -> void:
	_set_event("You entered %s. Review the local market and decide how to recover or reinvest." % String(world.settlement(world.current_settlement).get("name", "the settlement")))
	_show_shop()

func _on_settlement_action_pressed(action_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": action_id},
	})
	_show_command_result(result, "Opportunity")

func _on_accept_contract_pressed(contract_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": contract_id},
	})
	_show_command_result(result, "Contract")

func _on_resolve_contract_pressed(contract_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RESOLVE_CONTRACT,
		"inputs": {"contract_id": contract_id},
	})
	_show_command_result(result, "Contract")

func _on_recruit_crew_pressed(crew_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RECRUIT_CREW,
		"inputs": {"crew_id": crew_id},
	})
	_show_command_result(result, "Recruitment")

func _on_assign_crew_pressed(crew_id: String) -> void:
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": crew_id},
	})
	_show_command_result(result, "Crew assignment")

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
	var world_context := world.pricing_context()
	world_context["cargo"] = world.cargo
	world_context["route_intelligence"] = world.route_intelligence(route_id)
	var market_text := _market_preview_text(good_id, quantity, origin, world_context)
	market_preview_label.text = market_text
	if shop_market_preview_label:
		shop_market_preview_label.text = market_text
	if departure_load_label:
		departure_load_label.text = "PLANNED LOAD\n%s x%d · hold %d/%d · cash %d · provisions %d" % [good_id.capitalize(), quantity, int(world.cargo.get("weight", 0)), world.cargo_capacity, world.money, world.provisions]
	if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		route_preview_label.text = "ROUTE FORECAST\nChoose a directly connected destination and route."
		return
	route_preview_label.text = _route_preview_text(good_id, quantity, origin, destination, world.route(route_id), world_context)

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
	return "ROUTE FORECAST — %s to %s via %s\nPurchase %d · expected sale %d · gross margin %+d\nRoute fee %d · provisions %d (%d value) · time cost %d\n%s\nEXPECTED NET PROFIT %s ashmarks\nRisk source: %s\nScout confidence: %s" % [origin.get("name", "Origin"), destination.get("name", "Destination"), route.get("name", "Route"), int(preview.purchase_total), int(preview.sale_total), int(preview.gross_trade_margin), int(preview.route_cost), int(preview.provisions), int(preview.provision_cost), int(preview.time_cost), cargo_risk_text, net_text, String(preview.risk_source), intelligence_text]

func _on_buy_pressed() -> void:
	_sync_shop_plan_to_departure()
	var result := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {
			"good_id": _selected_id(cargo_good_option),
			"quantity": int(cargo_quantity.value),
		},
	})
	_show_command_result(result, "Purchase")

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
	if result.ok and world.current_settlement == PLAYTEST_DESTINATION and good_id == PLAYTEST_GOOD:
		playtest_grain_sold += quantity
	_show_command_result(result, "Sale")

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
		_set_event(String(result.message))
	else:
		_set_event("%s blocked: %s." % [label, String(result.reason)])
	_refresh_ui()

func _on_save_pressed() -> void:
	var file := FileAccess.open("user://market_of_ash_prototype.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(world.serialize()))
	_set_event("Versioned prototype state saved. Command history is included for deterministic review.")

func _on_reset_pressed() -> void:
	world = AshWorldState.new(PLAYTEST_SEED)
	playtest_grain_sold = 0
	_populate_destination_options()
	_populate_route_options()
	selected_map_cell = Vector2i(-1, -1)
	map_panel.world = world
	map_panel.reset_travel(world.current_settlement)
	_set_event("The caravan has been reset to its first morning.")
	_refresh_ui()

func _on_map_cell_selected(cell: Vector2i) -> void:
	selected_map_cell = cell
	_set_event("Grid cell (%d, %d) selected. Future camp, service, obstacle, or route objects can occupy this stable placeholder cell." % [cell.x, cell.y])
	_refresh_ui()

func _refresh_playtest_status() -> void:
	if playtest_status_label == null:
		return
	var grain_held := int(world.cargo.get(PLAYTEST_GOOD, 0))
	if playtest_grain_sold >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "RUN COMPLETE — You moved grain to Reedwatch and sold it. Compare the opening forecast with the realized result, then reset or keep trading."
	elif world.current_settlement == PLAYTEST_DESTINATION and grain_held >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "STEP 3 OF 3 — You reached Reedwatch with grain. Sell 2 grain to see the delivery result."
	elif grain_held >= PLAYTEST_QUANTITY:
		playtest_status_label.text = "STEP 2 OF 3 — Grain is loaded. Read the Old Road forecast, compare it with the Toll Road, then choose whether to depart for Reedwatch."
	else:
		playtest_status_label.text = "STEP 1 OF 3 — Read the Grain market price and route forecast. Buy 2 grain when you are ready; the marked test button simply executes that normal trade."

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
		var contract_button := Button.new()
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
		var resolve_button := Button.new()
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
		var action_button := Button.new()
		var cost := int(action.get("cost", 0))
		var slots := int(action.get("service_slots", 1))
		var time_cost := int(action.get("time_cost", 0))
		var effects: Dictionary = action.get("effects", {})
		var effect_summary := "+%d provisions" % int(effects.get("provisions", 0)) if effects.has("provisions") else "future effect"
		action_button.text = "%s — %d ashmarks, %s" % [String(action.get("name", "Opportunity")), cost, effect_summary]
		var unavailable_reason := String(action.get("unavailable_reason", ""))
		if not bool(action.get("available", false)):
			action_button.disabled = true
		elif world.visit_slots_remaining < slots:
			action_button.disabled = true
			unavailable_reason = "No visit slots remain. Depart and arrive at a settlement to refresh them."
		elif world.money < cost:
			action_button.disabled = true
			unavailable_reason = "You need %d ashmarks, but have %d." % [cost, world.money]
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
	var crew := MarketContent.crew_member("nara_vey")
	if crew.is_empty():
		return
	var recruited := world.is_crew_recruited("nara_vey")
	if not recruited and world.current_settlement != String(crew.get("recruit_settlement_id", "")):
		return
	var button := Button.new()
	var reason := ""
	if not recruited:
		button.text = "Recruit Nara Vey — %d ashmarks, %d slot" % [int(crew.get("recruit_cost", 0)), int(crew.get("recruit_service_slots", 1))]
		if world.money < int(crew.get("recruit_cost", 0)):
			button.disabled = true
			reason = "Needs %d ashmarks; you have %d." % [int(crew.get("recruit_cost", 0)), world.money]
		elif world.visit_slots_remaining < int(crew.get("recruit_service_slots", 1)):
			button.disabled = true
			reason = "No visit slots remain."
		button.pressed.connect(_on_recruit_crew_pressed.bind("nara_vey"))
	else:
		button.text = "Refresh Nara's route notes — %d slot" % int(crew.get("assignment_service_slots", 1))
		if MarketContent.routes_from(world.current_settlement).is_empty():
			button.disabled = true
			reason = "No authored routes leave this settlement."
		elif world.visit_slots_remaining < int(crew.get("assignment_service_slots", 1)):
			button.disabled = true
			reason = "No visit slots remain."
		button.pressed.connect(_on_assign_crew_pressed.bind("nara_vey"))
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
	var pending := world.pending_event
	event_card.visible = not pending.is_empty()
	if pending.is_empty():
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
		var button := Button.new()
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
		button.tooltip_text = blocked_reason if button.disabled else String(choice.get("outcome", ""))
		button.pressed.connect(_on_event_choice_pressed.bind(String(pending.get("id", "")), String(choice.get("id", ""))))
		event_choice_list.add_child(button)
		event_choice_buttons.append(button)

func _has_relevant_event_contract(destination_id: String, good_id: String) -> bool:
	for contract_id in world.active_contracts.keys():
		var contract := world.active_contract(String(contract_id))
		if String(contract.get("destination_id", "")) == destination_id and String(contract.get("good_id", "")) == good_id:
			return true
	return false

func _set_event(text: String) -> void:
	event_label.text = text

func _refresh_ui() -> void:
	status_label.text = "Day %d   |   %s   |   Ashmarks %d   |   Provisions %d   |   Cargo %d/%d   |   Crisis %d" % [world.day, world.settlement(world.current_settlement).name, world.money, world.provisions, int(world.cargo.get("weight", 0)), world.cargo_capacity, world.crisis_stage]
	if shop_status_label:
		var settlement := world.settlement(world.current_settlement)
		shop_status_label.text = "%s — %s\nDay %d · Crisis %d · %s" % [String(settlement.get("name", "Unknown settlement")), String(settlement.get("role", "market")), world.day, world.crisis_stage, String(event_label.text if event_label else "Inspect the local need, then load only what your plan can carry.")]
		shop_status_label.text += "\nSettlement resilience: %d/10" % world.resilience_for(world.current_settlement)
		if not world.known_information.is_empty():
			shop_status_label.text += " · Known leads: %d" % world.known_information.size()
	if departure_status_label:
		if not world.pending_event.is_empty():
			departure_status_label.text = "ROUTE DECISION — Travel is paused until you choose. Costs already paid remain spent; each option states whether you continue or return."
		elif arrival_pending:
			departure_status_label.text = "ARRIVAL REPORT — %s\n%s\nReview what changed, then enter the settlement to trade again." % [String(world.settlement(world.current_settlement).get("name", "Unknown settlement")), String(event_label.text)]
		else:
			departure_status_label.text = "COMMITMENT CHECK — The map only shows legal corridors. Returning to the shop preserves this plan and spends nothing."
	if playtest_banner and playtest_banner.text.is_empty():
		playtest_banner.text = "QUICK PLAYTEST — A compact trade run through the Five-Well Basin."
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
	if map_panel:
		map_panel.world = world
		map_panel.selected_cell = selected_map_cell
		map_panel.queue_redraw()

class MapPanel extends Control:
	signal grid_cell_selected(cell: Vector2i)

	const GRID_SIZE := Vector2i(17, 11)
	const BOARD_ORIGIN := Vector2(34, 200)
	const CELL_SIZE := Vector2(44, 24)
	const SETTLEMENT_CELLS := {
		"ashgate": Vector2i(2, 7),
		"brine_cross": Vector2i(13, 2),
		"cinderford": Vector2i(5, 7),
		"hollow_market": Vector2i(9, 3),
		"reedwatch": Vector2i(13, 8)
	}

	var world
	var selected_cell: Vector2i = Vector2i(-1, -1)
	var travel_route_id: String = ""
	var travel_points: Array[Vector2] = []
	var travel_progress: float = 1.0
	var traveling: bool = false

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
		travel_progress = 0.0
		traveling = true
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
		if not _board_rect().has_point(event.position):
			return
		var local: Vector2 = event.position - BOARD_ORIGIN
		var cell := Vector2i(floori(local.x / CELL_SIZE.x), floori(local.y / CELL_SIZE.y))
		if cell.x < 0 or cell.y < 0 or cell.x >= GRID_SIZE.x or cell.y >= GRID_SIZE.y:
			return
		selected_cell = cell
		grid_cell_selected.emit(cell)
		queue_redraw()

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
		if selected_cell.x >= 0:
			draw_rect(_cell_rect(selected_cell).grow(-2), Color("#f0d27d"), false, 3.0)
		draw_string(ThemeDB.fallback_font, BOARD_ORIGIN + Vector2(8, -12), "FIVE-WELL BASIN — PLACEHOLDER TRAVERSAL GRID", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#e6c58d"))
		var route_ids := ["old_road", "toll_road", "dry_cut"]
		for route_id in route_ids:
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
		var route_profiles := ["cheap / exposed", "safe / expensive", "fast / provision-heavy"]
		var route_footer_x := [8.0, 166.0, 344.0]
		for route_index in range(route_ids.size()):
			draw_string(ThemeDB.fallback_font, BOARD_ORIGIN + Vector2(route_footer_x[route_index], board.size.y + 24), "%s: %s" % [_route_label(route_ids[route_index]), route_profiles[route_index]], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, _route_color(route_ids[route_index]))
		for settlement_id in SETTLEMENT_CELLS.keys():
			var cell: Vector2i = SETTLEMENT_CELLS[settlement_id]
			var footprint := Rect2(_cell_rect(cell).position - Vector2(10, 8), Vector2(CELL_SIZE.x * 2.0 + 20, CELL_SIZE.y + 16))
			draw_rect(footprint, Color("#3b2b24"), true)
			draw_rect(footprint, Color("#bd8553") if settlement_id != "brine_cross" else Color("#7d9ca4"), false, 3.0)
			var name_text: String = String(settlement_id).replace("_", " ").capitalize()
			draw_string(ThemeDB.fallback_font, footprint.position + Vector2(5, 20), name_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("#f4e6c7"))
			draw_string(ThemeDB.fallback_font, footprint.position + Vector2(5, 37), String(world.settlement(settlement_id).get("role", "market")) if world != null else "settlement", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("#c7b49a"))
		var caravan_position: Vector2 = _settlement_point(world.current_settlement) if world != null else _settlement_point("ashgate")
		if traveling:
			caravan_position = _polyline_position(travel_points, travel_progress)
		draw_circle(caravan_position, 10.0, Color("#17130f"))
		draw_circle(caravan_position, 7.0, Color("#f0d27d"))
		draw_string(ThemeDB.fallback_font, caravan_position + Vector2(12, 4), "CARAVAN" if not traveling else "MOVING", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#f0d27d"))
		draw_string(ThemeDB.fallback_font, board.position + Vector2(board.size.x - 185, board.size.y + 24), "GRID CELL = FUTURE PLACE / WALK SPACE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#c7b49a"))
