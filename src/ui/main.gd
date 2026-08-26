extends Control

const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")

var world: AshWorldState
var status_label: Label
var event_label: Label
var destination_option: OptionButton
var route_option: OptionButton
var cargo_good_option: OptionButton
var cargo_quantity: SpinBox
var log_label: Label
var map_panel: Control

func _ready() -> void:
	world = AshWorldState.new(1107)
	_build_ui()
	_refresh_ui()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#17130f")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	map_panel = MapPanel.new()
	map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(map_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

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

	status_label = Label.new()
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("#f4e6c7"))
	left.add_child(status_label)

	var map_hint := Label.new()
	map_hint.text = "Five settlements. Three routes. A water shortage is coming."
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
	control_title.text = "CARAVAN DESK"
	control_title.add_theme_font_size_override("font_size", 20)
	control_title.add_theme_color_override("font_color", Color("#e6c58d"))
	controls.add_child(control_title)

	destination_option = OptionButton.new()
	for id in world.settlements.keys():
		if id != world.current_settlement:
			destination_option.add_item(world.settlements[id].name)
			destination_option.set_item_metadata(destination_option.item_count - 1, id)
	controls.add_child(_labeled_control("Destination", destination_option))

	route_option = OptionButton.new()
	for id in world.routes.keys():
		route_option.add_item(world.routes[id].name)
		route_option.set_item_metadata(route_option.item_count - 1, id)
	controls.add_child(_labeled_control("Route", route_option))

	cargo_good_option = OptionButton.new()
	for good in MarketEconomy.GOODS:
		cargo_good_option.add_item(good.capitalize())
		cargo_good_option.set_item_metadata(cargo_good_option.item_count - 1, good)
	controls.add_child(_labeled_control("Cargo", cargo_good_option))

	cargo_quantity = SpinBox.new()
	cargo_quantity.min_value = 1
	cargo_quantity.max_value = 12
	cargo_quantity.value = 2
	controls.add_child(_labeled_control("Quantity", cargo_quantity))

	var buy_button := Button.new()
	buy_button.text = "Buy cargo"
	buy_button.tooltip_text = "Buy from the current settlement and add it to the caravan."
	buy_button.pressed.connect(_on_buy_pressed)
	controls.add_child(buy_button)

	var travel_button := Button.new()
	travel_button.text = "Depart"
	travel_button.tooltip_text = "Pay route cost, consume provisions, and resolve travel risk."
	travel_button.pressed.connect(_on_depart_pressed)
	controls.add_child(travel_button)

	var sell_button := Button.new()
	sell_button.text = "Sell selected cargo"
	sell_button.pressed.connect(_on_sell_pressed)
	controls.add_child(sell_button)

	var save_button := Button.new()
	save_button.text = "Save prototype state"
	save_button.pressed.connect(_on_save_pressed)
	controls.add_child(save_button)

	var reset_button := Button.new()
	reset_button.text = "Reset run"
	reset_button.pressed.connect(_on_reset_pressed)
	controls.add_child(reset_button)

func _labeled_control(label_text: String, control: Control) -> VBoxContainer:
	var group := VBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color("#b5a18b"))
	group.add_child(label)
	group.add_child(control)
	return group

func _selected_id(option: OptionButton) -> String:
	if option.selected < 0:
		return ""
	return String(option.get_item_metadata(option.selected))

func _on_buy_pressed() -> void:
	var good := _selected_id(cargo_good_option)
	var quantity := int(cargo_quantity.value)
	var origin := world.settlement(world.current_settlement)
	var price := MarketEconomy.price_for(good, origin, {"crisis_modifiers": world.crisis_modifiers})
	var result := MarketEconomy.validate_trade(world.cargo, good, quantity, world.cargo_capacity)
	if not result.ok:
		_set_event("Purchase blocked: %s." % result.reason)
		return
	var total := price * quantity
	if world.money < total:
		_set_event("Purchase blocked: you need %d ashmarks, but have %d." % [total, world.money])
		return
	world.money -= total
	world.cargo[good] = int(world.cargo.get(good, 0)) + quantity
	world.cargo.weight = int(world.cargo.get("weight", 0)) + quantity
	_set_event("Bought %d %s for %d ashmarks. %s." % [quantity, good, total, MarketEconomy.explain_price(good, origin, {"crisis_modifiers": world.crisis_modifiers})])
	_refresh_ui()

func _on_sell_pressed() -> void:
	var good := _selected_id(cargo_good_option)
	var quantity := mini(int(cargo_quantity.value), int(world.cargo.get(good, 0)))
	if quantity <= 0:
		_set_event("You do not have any %s to sell." % good)
		return
	var destination := world.settlement(world.current_settlement)
	var price := MarketEconomy.price_for(good, destination, {"crisis_modifiers": world.crisis_modifiers})
	world.money += price * quantity
	world.cargo[good] = int(world.cargo.get(good, 0)) - quantity
	world.cargo.weight = int(world.cargo.get("weight", 0)) - quantity
	_set_event("Sold %d %s for %d ashmarks." % [quantity, good, price * quantity])
	_refresh_ui()

func _on_depart_pressed() -> void:
	var route_id := _selected_id(route_option)
	var destination_id := _selected_id(destination_option)
	var result := world.travel(route_id)
	if not result.ok:
		_set_event("Departure blocked: %s." % result.reason)
		return
	world.current_settlement = destination_id
	var risk: float = float(result.risk)
	var roll := fmod(float(world.seed * 17 + world.day * 31), 100.0) / 100.0
	if roll < risk:
		var lost := mini(int(world.cargo.get("weight", 0)), 1)
		world.cargo.weight = int(world.cargo.get("weight", 0)) - lost
		_set_event("The %s was hit by a route incident. You lost %d cargo weight, but arrived at %s." % [world.route(route_id).name, lost, world.settlement(destination_id).name])
	else:
		_set_event("You arrived at %s by the %s. The route held." % [world.settlement(destination_id).name, world.route(route_id).name])
	_refresh_ui()

func _on_save_pressed() -> void:
	var file := FileAccess.open("user://market_of_ash_prototype.save", FileAccess.WRITE)
	file.store_string(JSON.stringify(world.serialize()))
	_set_event("Prototype state saved. The production version will add versioned migrations and Steam Cloud/Epic adapters.")

func _on_reset_pressed() -> void:
	world = AshWorldState.new(1107)
	_set_event("The caravan has been reset to its first morning.")
	_refresh_ui()

func _set_event(text: String) -> void:
	event_label.text = text

func _refresh_ui() -> void:
	status_label.text = "Day %d   |   %s   |   Ashmarks %d   |   Provisions %d   |   Cargo %d/%d   |   Crisis %d" % [world.day, world.settlement(world.current_settlement).name, world.money, world.provisions, int(world.cargo.get("weight", 0)), world.cargo_capacity, world.crisis_stage]
	var cargo_lines: Array[String] = []
	for good in MarketEconomy.GOODS:
		var count := int(world.cargo.get(good, 0))
		if count > 0:
			cargo_lines.append("%s x%d" % [good.capitalize(), count])
	log_label.text = "Cargo: " + (", ".join(cargo_lines) if not cargo_lines.is_empty() else "empty")
	if event_label.text.is_empty():
		event_label.text = "Choose a destination, buy a small load, and compare the Old Road with the Toll Road."
	if map_panel:
		map_panel.queue_redraw()

class MapPanel extends Control:
	func _draw() -> void:
		var points := {
			"ashgate": Vector2(240, 210),
			"brine_cross": Vector2(450, 120),
			"cinderford": Vector2(600, 320),
			"hollow_market": Vector2(830, 170),
			"reedwatch": Vector2(900, 430),
		}
		var links := [["ashgate", "brine_cross"], ["ashgate", "cinderford"], ["brine_cross", "hollow_market"], ["cinderford", "reedwatch"], ["hollow_market", "reedwatch"]]
		for link in links:
			draw_line(points[link[0]], points[link[1]], Color("#705746"), 4.0, true)
		for id in points.keys():
			var p: Vector2 = points[id]
			draw_circle(p, 26.0, Color("#3b2b24"))
			draw_circle(p, 20.0, Color("#bd8553"))
			draw_string(ThemeDB.fallback_font, p + Vector2(-42, 48), String(id).replace("_", " ").capitalize(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#e6c58d"))
