extends Control

const MarketContent = preload("res://src/core/market_content.gd")
const VisualRegistry = preload("res://src/ui/visual_registry.gd")

signal settlement_selected(settlement_id: String)
signal travel_state_changed(state: String)

const DEPARTURE_DUST_PATH := "res://assets/temporary/selected-vfx/departure-dust.pngdata"
const GRID_SIZE := Vector2i(17, 11)
const NORMAL_BOARD_ORIGIN := Vector2(34, 230)
const NORMAL_CELL_WIDTH := 44.0
const MIN_CELL_WIDTH := 44.0
const MAX_CELL_WIDTH := 56.0
const NORMAL_CELL_HEIGHT := 20.0
const MIN_CELL_HEIGHT := 14.0
const MAP_HEADER_HEIGHT := 30.0
const ENCOUNTER_PROGRESS := 0.39
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
var departure_dust_texture: ImageTexture

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	departure_dust_texture = _load_departure_dust_texture()

func _load_departure_dust_texture() -> ImageTexture:
	var bytes := FileAccess.get_file_as_bytes(DEPARTURE_DUST_PATH)
	if bytes.is_empty():
		return null
	var image := Image.new()
	if image.load_png_from_buffer(bytes) != OK:
		return null
	return ImageTexture.create_from_image(image)

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
	return _cell_center(_settlement_cell(settlement_id))

func _settlement_cell(settlement_id: String) -> Vector2i:
	var settlement_record: Dictionary = world.settlement(settlement_id) if world != null else MarketContent.settlements().get(settlement_id, {})
	var coordinates: Array = settlement_record.get("identity", {}).get("map_cell", [0, 0])
	return Vector2i(int(coordinates[0]), int(coordinates[1]))

func _settlement_ids() -> Array[String]:
	if world == null:
		return MarketContent.settlement_ids()
	var region: Dictionary = MarketContent.region_for_settlement(world.current_settlement)
	var visible_ids: Dictionary = {}
	for settlement_id_value in region.get("settlement_ids", []):
		visible_ids[String(settlement_id_value)] = true
	for route_id_value in region.get("route_ids", []):
		var route_record: Dictionary = world.routes.get(String(route_id_value), {})
		for settlement_id_value in route_record.get("map_path", route_record.get("stops", route_record.get("endpoints", []))):
			visible_ids[String(settlement_id_value)] = true
	var ordered_ids: Array[String] = []
	for settlement_id in MarketContent.settlement_ids():
		if visible_ids.has(settlement_id):
			ordered_ids.append(settlement_id)
	return ordered_ids

func _route_ids() -> Array[String]:
	var ids: Array[String] = []
	var route_records: Dictionary = world.routes if world != null else MarketContent.routes()
	var region_route_ids: Array = MarketContent.region_for_settlement(world.current_settlement).get("route_ids", []) if world != null else route_records.keys()
	for route_id_value in region_route_ids:
		if route_records.has(String(route_id_value)):
			ids.append(String(route_id_value))
	return ids

func _route_legend_ids() -> Array[String]:
	if world == null:
		return _route_ids()
	var region := MarketContent.region_for_settlement(world.current_settlement)
	var ids: Array[String] = []
	for route_id_value in region.get("route_ids", []):
		var route_id := String(route_id_value)
		if world.routes.has(route_id):
			ids.append(route_id)
	return ids if not ids.is_empty() else _route_ids()

func _settlement_marker_rect(settlement_id: String) -> Rect2:
	var cell := _settlement_cell(settlement_id)
	var marker_size := Vector2(cell_width * 2.0 + 52.0, 40)
	var marker_position := _cell_rect(cell).position - Vector2(10, 8)
	var board := _board_rect()
	marker_position.x = clampf(marker_position.x, board.position.x + 2.0, board.end.x - marker_size.x - 2.0)
	marker_position.y = clampf(marker_position.y, board.position.y + MAP_HEADER_HEIGHT + 2.0, board.end.y - marker_size.y - 2.0)
	return Rect2(marker_position, marker_size)

func _settlement_footprint(settlement_id: String) -> Rect2:
	var vertical_margin := 0.0 if String(MarketContent.settlements().get(settlement_id, {}).get("region_id", "")) == "siltfire_march" else 10.0
	return _settlement_marker_rect(settlement_id).grow_individual(0.0, vertical_margin, 0.0, vertical_margin)

func _route_points(route_id: String) -> Array[Vector2]:
	var route_record: Dictionary = world.routes.get(route_id, {}) if world != null else MarketContent.route(route_id)
	var path: Array = route_record.get("map_path", route_record.get("stops", route_record.get("endpoints", [])))
	var points: Array[Vector2] = []
	for settlement_id_value in path:
		var settlement_id := String(settlement_id_value)
		if _settlement_ids().has(settlement_id):
			points.append(_settlement_point(settlement_id))
	return points

func _route_color(route_id: String) -> Color:
	return VisualRegistry.route_color(route_id)

func _route_label(route_id: String) -> String:
	if world != null and world.routes.has(route_id):
		return String(world.routes[route_id].get("name", route_id))
	return route_id.replace("_", " ").capitalize()

func _route_map_label(route_id: String) -> String:
	var route_record: Dictionary = world.routes.get(route_id, {}) if world != null else MarketContent.route(route_id)
	return String(route_record.get("map_label", route_record.get("name", route_id)))

func _map_heading() -> String:
	var region := MarketContent.region_for_settlement(world.current_settlement) if world != null else {}
	var region_name := String(region.get("name", "Ashland Trade Network"))
	return region_name.to_upper()

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
		if String(contract.get("destination_id", "")) == settlement_id and not world.has_contract_outcome(String(contract.get("id", ""))) and world.contract_offer_closed_reason(String(contract.get("id", ""))).is_empty():
			return "available"
	return ""

func _route_to(settlement_id: String) -> String:
	if world == null:
		return ""
	for route_id in _route_ids():
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
	var response_text := " · Well Commons exchange active" if settlement_id == "reedwatch" and not world.emergent_faction("well_commons").is_empty() else ""
	return "%s%s%s · %s\n%s · %d ashmarks · %d provisions · %d day" % [String(settlement.get("name", settlement_id)), assignment_text, response_text, String(settlement.get("role", "market")), String(route.get("name", route_id)), int(route.get("cost", 0)), world.route_provision_cost(route_id, settlement_id), int(route.get("days", 0))]

func _map_info_settlement_id() -> String:
	return hovered_settlement_id

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
	if text_scale > 1.0:
		return Rect2()
	var route_ids := _route_legend_ids()
	var text := _route_map_label(route_ids[route_index])
	var text_size := ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10))
	var slot_width := _board_rect().size.x / float(route_ids.size())
	var footer_x := slot_width * float(route_index) + 5.0
	return Rect2(Vector2(board_origin.x + footer_x, _board_rect().end.y), Vector2(slot_width - 8.0, text_size.y))

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

func _departure_dust_strength() -> float:
	if reduce_motion or travel_phase != "moving_out":
		return 0.0
	var dust_end_progress := ENCOUNTER_PROGRESS * 0.68
	return clampf(1.0 - travel_progress / dust_end_progress, 0.0, 1.0)

func _draw_departure_dust(position: Vector2) -> void:
	var strength := _departure_dust_strength()
	if strength <= 0.0 or departure_dust_texture == null:
		return
	var heading := _caravan_heading()
	draw_set_transform(position, heading, Vector2.ONE)
	var tint := Color(0.92, 0.73, 0.49, strength * 0.82)
	var puffs := [
		{"offset": Vector2(-54, 11), "size": Vector2(104, 78), "alpha": 1.0},
		{"offset": Vector2(-96, 15), "size": Vector2(76, 57), "alpha": 0.72},
		{"offset": Vector2(-131, 18), "size": Vector2(52, 39), "alpha": 0.44},
	]
	for puff in puffs:
		var puff_size: Vector2 = puff["size"] * lerpf(0.82, 1.18, 1.0 - strength)
		var puff_center: Vector2 = puff["offset"]
		var puff_tint := tint
		puff_tint.a *= float(puff["alpha"])
		draw_texture_rect(departure_dust_texture, Rect2(puff_center - puff_size * 0.5, puff_size), false, puff_tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_caravan(position: Vector2) -> void:
	var state := _caravan_motion_label()
	var accent := Color("#f0d27d")
	if state == "ENCOUNTER":
		accent = Color("#e07151")
		draw_circle(position, 28.0, Color(0.88, 0.33, 0.22, 0.16))
		draw_arc(position, 28.0, 0.0, TAU, 32, accent, 3.0, true)
	elif state == "MOVING":
		draw_line(position - Vector2(34, 0), position - Vector2(22, 0), Color(0.94, 0.82, 0.49, 0.42), 4.0)
	elif state == "ARRIVED":
		var arrival_settlement: String = travel_destination_id if not travel_destination_id.is_empty() else String(world.current_settlement)
		var arrival_style: Dictionary = VisualRegistry.settlement_style(arrival_settlement, world.settlement(arrival_settlement).get("identity", {}) if world != null else {})
		accent = Color(String(arrival_style.get("market_accent", "#f0d27d"))).lightened(0.25)
		_draw_arrival_treatment(position, String(arrival_style.get("arrival_treatment", "lantern_welcome")), accent)
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

func _draw_arrival_treatment(position: Vector2, treatment: String, accent: Color) -> void:
	match treatment:
		"warden_bells", "warning_bell":
			draw_arc(position, 33.0, PI, TAU, 20, Color(accent, 0.55), 3.0)
			draw_circle(position + Vector2(0, -35), 4.0, accent)
		"cistern_queue", "water_witness":
			for ring_radius in [31.0, 37.0]:
				draw_arc(position, ring_radius, 0.0, TAU, 24, Color(accent, 0.42), 2.0)
		"sealed_shards", "beacon_reflection":
			draw_colored_polygon(PackedVector2Array([position + Vector2(0, -42), position + Vector2(35, 0), position + Vector2(0, 42), position + Vector2(-35, 0)]), Color(accent, 0.14))
			draw_polyline(PackedVector2Array([position + Vector2(0, -42), position + Vector2(35, 0), position + Vector2(0, 42), position + Vector2(-35, 0), position + Vector2(0, -42)]), accent, 2.0)
		"kiln_fires", "watch_fires", "resin_lamps":
			for offset_x in [-30.0, 30.0]:
				draw_circle(position + Vector2(offset_x, 5), 7.0, Color(accent, 0.36))
				draw_colored_polygon(PackedVector2Array([position + Vector2(offset_x - 5, 7), position + Vector2(offset_x, -8), position + Vector2(offset_x + 5, 7)]), accent)
		_:
			draw_arc(position, 35.0, 0.0, TAU, 24, Color(accent, 0.5), 2.0)

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

func _road_profile(route_id: String) -> Dictionary:
	return VisualRegistry.route_style(route_id)

func _road_waypoint_label() -> String:
	var origin_name := String(world.settlement(travel_origin_id).get("name", travel_origin_id)) if world != null else travel_origin_id
	var destination_name := String(world.settlement(travel_destination_id).get("name", travel_destination_id)) if world != null else travel_destination_id
	var profile := _road_profile(travel_route_id)
	match travel_phase:
		"moving_out":
			return "LEAVING %s" % origin_name.to_upper()
		"road":
			return "ROAD STOP — %s" % String(profile.get("waypoint", "The road ahead")).to_upper()
		"encounter":
			return "ENCOUNTER — %s" % String(world.pending_event.get("title", "Road obstruction")).to_upper() if world != null else "ENCOUNTER"
		"moving_in":
			return "APPROACHING %s" % destination_name.to_upper()
	return "AT REST"

func _road_settlement_motif(settlement_id: String) -> String:
	var identity: Dictionary = world.settlement(settlement_id).get("identity", {}) if world != null else {}
	return String(VisualRegistry.settlement_style(settlement_id, identity).get("motif", "gate"))

func _draw_road_settlement(position: Vector2, settlement_id: String, name: String, color: Color, right_aligned: bool) -> void:
	var direction := -1.0 if right_aligned else 1.0
	var ink := color.darkened(0.24)
	draw_rect(Rect2(position + Vector2(-27, -8), Vector2(54, 8)), color.darkened(0.58), true)
	match _road_settlement_motif(settlement_id):
		"reeds":
			draw_line(position + Vector2(-27, -5), position + Vector2(27, -5), Color("#52706a"), 3.0)
			for index in range(8):
				var x := -23.0 + index * 6.5
				var height := 17.0 + float((index * 5) % 12)
				draw_line(position + Vector2(x, -4), position + Vector2(x + 2, -4 - height), ink, 2.0)
			draw_rect(Rect2(position + Vector2(10, -32), Vector2(14, 27)), ink.darkened(0.08), false, 3.0)
		"brine":
			for index in range(3):
				draw_arc(position + Vector2(-18 + index * 18, -7), 10.0, 0.0, PI, 12, ink, 2.0)
			draw_line(position + Vector2(17, -8), position + Vector2(17, -36), ink, 4.0)
			draw_line(position + Vector2(9, -25), position + Vector2(26, -25), ink, 2.0)
		"forge", "kiln":
			draw_arc(position + Vector2(-8, -6), 18.0, PI, TAU, 16, ink, 5.0)
			for index in range(2):
				var stack_x := 9.0 + index * 11.0
				draw_rect(Rect2(position + Vector2(stack_x, -34 - index * 5), Vector2(7, 29 + index * 5)), ink.darkened(0.1), true)
				draw_circle(position + Vector2(stack_x + 3, -40 - index * 7), 5.0 + index * 2.0, Color(ink, 0.3))
		"lanterns", "quay":
			draw_line(position + Vector2(-25, -28), position + Vector2(24, -19), ink, 2.0)
			for index in range(4):
				var lamp := position + Vector2(-19 + index * 14, -25 + index * 2.5)
				draw_line(lamp, lamp + Vector2(0, 7), ink, 1.5)
				draw_circle(lamp + Vector2(0, 10), 3.0, Color("#e1a75b"))
		"glass", "mirrors":
			for index in range(3):
				var center := position + Vector2(-16 + index * 16, -17 - float(index % 2) * 7)
				draw_colored_polygon(PackedVector2Array([center + Vector2(0, -12), center + Vector2(8, 0), center + Vector2(0, 12), center + Vector2(-8, 0)]), Color(ink, 0.78))
				draw_line(center + Vector2(0, 12), center + Vector2(0, 19), ink, 2.0)
		"watchtower":
			draw_line(position + Vector2(-18, -5), position + Vector2(-10, -38), ink, 4.0)
			draw_line(position + Vector2(18, -5), position + Vector2(10, -38), ink, 4.0)
			draw_rect(Rect2(position + Vector2(-22, -43), Vector2(44, 12)), ink, true)
			draw_circle(position + Vector2(0, -49), 4.0, Color("#d99a55"))
		"peat_stacks":
			for index in range(3):
				draw_rect(Rect2(position + Vector2(-24 + index * 17, -12 - index * 5), Vector2(15, 12 + index * 5)), ink.darkened(0.1), true)
			draw_arc(position + Vector2(10, -34), 10.0, PI * 1.1, PI * 1.9, 12, Color("#8db7a7"), 2.0)
		_:
			draw_rect(Rect2(position + Vector2(-25, -31), Vector2(50, 27)), ink.darkened(0.12), true)
			draw_arc(position + Vector2(0, -4), 14.0, PI, TAU, 16, Color("#19140f"), 8.0)
			draw_rect(Rect2(position + Vector2(-31, -38), Vector2(9, 34)), ink, true)
			draw_rect(Rect2(position + Vector2(22, -38), Vector2(9, 34)), ink, true)
	draw_line(position + Vector2(0, -36), position + Vector2(0, -49), color, 2.0)
	draw_colored_polygon(PackedVector2Array([
		position + Vector2(0, -49),
		position + Vector2(14 * direction, -44),
		position + Vector2(0, -39),
	]), color)
	var label_width := 150.0
	var label_x := position.x - label_width if right_aligned else position.x
	draw_string(ThemeDB.fallback_font, Vector2(label_x, position.y + 18), name.to_upper(), HORIZONTAL_ALIGNMENT_RIGHT if right_aligned else HORIZONTAL_ALIGNMENT_LEFT, label_width, _font_size(10), Color("#c7b49a"))

func _draw_old_road_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(5):
		var drift := fmod(float(index * 183) - travel_progress * 540.0, board.size.x + 130.0) - 65.0
		var x := board.position.x + drift
		var y := horizon_y + 32.0 + float(index % 2) * 34.0
		draw_line(Vector2(x, y), Vector2(x, y - 31), accent.darkened(0.32), 4.0)
		draw_line(Vector2(x - 8, y - 24), Vector2(x + 8, y - 24), accent.darkened(0.18), 3.0)
	if travel_phase in ["road", "encounter"]:
		var arch_center := Vector2(board.position.x + board.size.x * 0.72, horizon_y + 16)
		draw_line(arch_center + Vector2(-22, 18), arch_center + Vector2(-22, -23), Color("#76513e"), 7.0)
		draw_line(arch_center + Vector2(22, 18), arch_center + Vector2(22, -23), Color("#76513e"), 7.0)
		draw_arc(arch_center + Vector2(0, -21), 22, PI, TAU, 18, Color("#76513e"), 7.0)

func _draw_toll_road_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(7):
		var drift := fmod(float(index * 141) - travel_progress * 620.0, board.size.x + 100.0) - 50.0
		var x := board.position.x + drift
		var y := horizon_y + 26.0 + float(index % 3) * 20.0
		draw_line(Vector2(x, y), Vector2(x, y - 27), accent.darkened(0.38), 3.0)
		draw_rect(Rect2(x - 5, y - 32, 10, 7), accent.darkened(0.08), true)
	for stripe in range(5):
		var stripe_y := lerpf(horizon_y + 22.0, board.end.y - 34.0, float(stripe) / 5.0)
		var half_width := lerpf(34.0, board.size.x * 0.30, float(stripe) / 5.0)
		draw_line(Vector2(board.get_center().x - half_width, stripe_y), Vector2(board.get_center().x + half_width, stripe_y), Color(0.82, 0.73, 0.58, 0.18), 2.0)

func _draw_dry_cut_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for ridge in range(3):
		var ridge_y := horizon_y + 24.0 + ridge * 30.0
		var points := PackedVector2Array()
		for point_index in range(9):
			var x := board.position.x + float(point_index) * board.size.x / 8.0
			var y := ridge_y + sin(float(point_index + ridge) * 1.35 + travel_progress * 4.0) * (8.0 + ridge * 2.0)
			points.append(Vector2(x, y))
		draw_polyline(points, accent.darkened(0.38 + ridge * 0.08), 3.0, true)
	var marker := Vector2(board.position.x + board.size.x * 0.72, horizon_y + 38)
	draw_line(marker, marker + Vector2(0, -42), accent, 4.0)
	draw_line(marker + Vector2(0, -39), marker + Vector2(17, -31), accent, 3.0)
	draw_line(marker + Vector2(0, -27), marker + Vector2(-14, -19), accent.darkened(0.15), 3.0)

func _draw_glasswind_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(6):
		var drift := fmod(float(index * 157) - travel_progress * 650.0, board.size.x + 120.0) - 60.0
		var base := Vector2(board.position.x + drift, horizon_y + 30.0 + float(index % 3) * 24.0)
		var height := 25.0 + float(index % 2) * 14.0
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-9, 0),
			base + Vector2(1, -height),
			base + Vector2(11, 0),
		]), Color(accent, 0.42))
		draw_line(base + Vector2(1, -height), base + Vector2(5, -4), accent.lightened(0.18), 1.5)
	if travel_phase in ["road", "encounter"]:
		var cairn := Vector2(board.position.x + board.size.x * 0.67, horizon_y + 42.0)
		for stone in range(4):
			var width := 32.0 - float(stone) * 6.0
			draw_rect(Rect2(cairn.x - width * 0.5, cairn.y - float(stone + 1) * 8.0, width, 7.0), accent.darkened(0.22 + stone * 0.05), true)

func _draw_mirror_run_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(5):
		var drift := fmod(float(index * 191) - travel_progress * 580.0, board.size.x + 140.0) - 70.0
		var base := Vector2(board.position.x + drift, horizon_y + 36.0 + float(index % 2) * 31.0)
		draw_line(base, base + Vector2(0, -38), accent.darkened(0.18), 3.0)
		draw_circle(base + Vector2(0, -43), 6.0, Color("#e5d2a3"))
		draw_circle(base + Vector2(0, -43), 12.0, Color(0.62, 0.49, 0.76, 0.16))
	var mirror := Vector2(board.position.x + board.size.x * 0.76, horizon_y + 28.0)
	draw_colored_polygon(PackedVector2Array([
		mirror + Vector2(-18, 15),
		mirror + Vector2(-12, -35),
		mirror + Vector2(13, -28),
		mirror + Vector2(18, 15),
	]), Color(accent, 0.30))
	draw_polyline(PackedVector2Array([
		mirror + Vector2(-18, 15),
		mirror + Vector2(-12, -35),
		mirror + Vector2(13, -28),
		mirror + Vector2(18, 15),
	]), accent, 2.0)

func _draw_emberglass_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(7):
		var drift := fmod(float(index * 149) - travel_progress * 680.0, board.size.x + 120.0) - 60.0
		var base := Vector2(board.position.x + drift, horizon_y + 34.0 + float(index % 3) * 23.0)
		var vent_height := 24.0 + float(index % 2) * 13.0
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-12, 0),
			base + Vector2(-5, -vent_height),
			base + Vector2(7, -vent_height + 4),
			base + Vector2(13, 0),
		]), accent.darkened(0.42))
		draw_arc(base + Vector2(1, -vent_height - 5), 11.0, PI * 1.08, PI * 1.92, 14, Color(accent, 0.38), 2.0)
	for shard_index in range(5):
		var shard_x := board.position.x + board.size.x * (0.16 + shard_index * 0.17)
		var shard_base := Vector2(shard_x, horizon_y + 70.0 + float(shard_index % 2) * 27.0)
		draw_colored_polygon(PackedVector2Array([
			shard_base + Vector2(-5, 0),
			shard_base + Vector2(1, -18),
			shard_base + Vector2(7, 0),
		]), Color(Color("#e5a16d"), 0.46))

func _draw_salt_causeway_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(7):
		var drift := fmod(float(index * 139) - travel_progress * 610.0, board.size.x + 120.0) - 60.0
		var base := Vector2(board.position.x + drift, horizon_y + 30.0 + float(index % 3) * 24.0)
		draw_line(base, base + Vector2(0, -34), accent.darkened(0.24), 3.0)
		draw_arc(base + Vector2(0, -39), 6.0, 0.0, TAU, 16, accent, 2.0)
		draw_line(base + Vector2(-6, -39), base + Vector2(6, -39), accent, 2.0)
	for steam_index in range(4):
		var steam_x := board.position.x + board.size.x * (0.18 + steam_index * 0.2)
		draw_arc(Vector2(steam_x, horizon_y + 12), 24.0 + steam_index * 4.0, PI * 1.15, PI * 1.75, 18, Color(accent, 0.24), 3.0)

func _draw_reedline_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(16):
		var drift := fmod(float(index * 71) - travel_progress * 470.0, board.size.x + 80.0) - 40.0
		var base := Vector2(board.position.x + drift, horizon_y + 38.0 + float(index % 4) * 18.0)
		var bend := -5.0 if index % 2 == 0 else 5.0
		draw_line(base, base + Vector2(bend, -27.0 - float(index % 3) * 5.0), accent.darkened(0.28), 2.0)
	if travel_phase in ["road", "encounter"]:
		var watch := Vector2(board.position.x + board.size.x * 0.73, horizon_y + 31.0)
		draw_line(watch + Vector2(-13, 18), watch + Vector2(-7, -32), accent.darkened(0.18), 4.0)
		draw_line(watch + Vector2(13, 18), watch + Vector2(7, -32), accent.darkened(0.18), 4.0)
		draw_rect(Rect2(watch + Vector2(-17, -38), Vector2(34, 11)), accent, true)
		draw_circle(watch + Vector2(0, -45), 5.0, Color("#d99a55"))

func _draw_peat_smoke_landmarks(board: Rect2, horizon_y: float, accent: Color) -> void:
	for index in range(7):
		var drift := fmod(float(index * 133) - travel_progress * 520.0, board.size.x + 110.0) - 55.0
		var base := Vector2(board.position.x + drift, horizon_y + 31.0 + float(index % 3) * 25.0)
		draw_rect(Rect2(base + Vector2(-13, -12), Vector2(26, 12)), accent.darkened(0.38), true)
		draw_arc(base + Vector2(0, -21), 13.0 + float(index % 2) * 5.0, PI * 1.1, PI * 1.9, 14, Color(0.55, 0.73, 0.68, 0.34), 2.0)
	if travel_phase in ["road", "encounter"]:
		var smoke_marker := Vector2(board.position.x + board.size.x * 0.72, horizon_y + 24.0)
		draw_rect(Rect2(smoke_marker + Vector2(-16, -18), Vector2(32, 18)), accent.darkened(0.3), true)
		draw_circle(smoke_marker + Vector2(0, -29), 8.0, Color("#8db7a7"))

func _draw_road_scene() -> void:
	var board := _board_rect()
	var profile := _road_profile(travel_route_id)
	var accent: Color = profile.get("accent", Color("#c7b49a"))
	draw_rect(board.grow(8), Color("#2a211b"), true)
	draw_rect(board, Color("#29231d"), true)
	var horizon_y := board.position.y + board.size.y * 0.43
	draw_colored_polygon(PackedVector2Array([
		board.position,
		board.position + Vector2(board.size.x, 0),
		Vector2(board.end.x, horizon_y - 8),
		Vector2(board.position.x, horizon_y + 18),
	]), profile.get("sky", Color("#40352b")))
	draw_colored_polygon(PackedVector2Array([
		Vector2(board.position.x, horizon_y + 8),
		Vector2(board.end.x, horizon_y - 16),
		board.end,
		Vector2(board.position.x, board.end.y),
	]), profile.get("ground", Color("#241c17")))
	var road_center := board.position.x + board.size.x * 0.52
	draw_colored_polygon(PackedVector2Array([
		Vector2(road_center - 26, horizon_y),
		Vector2(road_center + 26, horizon_y),
		Vector2(road_center + board.size.x * 0.34, board.end.y),
		Vector2(road_center - board.size.x * 0.34, board.end.y),
	]), profile.get("road", Color("#594635")))
	match VisualRegistry.route_texture(travel_route_id):
		"milestone_crosses":
			_draw_old_road_landmarks(board, horizon_y, accent)
		"toll_posts":
			_draw_toll_road_landmarks(board, horizon_y, accent)
		"wind_ridges":
			_draw_dry_cut_landmarks(board, horizon_y, accent)
		"glass_shards":
			_draw_glasswind_landmarks(board, horizon_y, accent)
		"mirror_beacons":
			_draw_mirror_run_landmarks(board, horizon_y, accent)
		"ember_vents":
			_draw_emberglass_landmarks(board, horizon_y, accent)
		"causeway_bells":
			_draw_salt_causeway_landmarks(board, horizon_y, accent)
		"reed_marks":
			_draw_reedline_landmarks(board, horizon_y, accent)
		"peat_smoke":
			_draw_peat_smoke_landmarks(board, horizon_y, accent)
	var route_name := _route_label(travel_route_id).to_upper()
	var origin_name := String(world.settlement(travel_origin_id).get("name", travel_origin_id)) if world != null else travel_origin_id
	var destination_name := String(world.settlement(travel_destination_id).get("name", travel_destination_id)) if world != null else travel_destination_id
	draw_rect(Rect2(board.position, Vector2(board.size.x, MAP_HEADER_HEIGHT + 34.0)), Color("#17130f"), true)
	draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 20), "%s — %s" % [route_name, String(profile.get("title", "BASIN ROAD"))], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(15), Color("#e6c58d"))
	draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 39), _road_waypoint_label(), HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(11), accent)
	var route_description := String(world.route(travel_route_id, travel_origin_id, travel_destination_id).get("description", "Committed caravan corridor.")) if world != null else "Committed caravan corridor."
	draw_string(ThemeDB.fallback_font, board.position + Vector2(12, 56), route_description, HORIZONTAL_ALIGNMENT_LEFT, board.size.x - 24.0, _font_size(10), Color("#b5a18b"))
	_draw_road_settlement(Vector2(board.position.x + 34, horizon_y + 5), travel_origin_id, origin_name, accent, false)
	_draw_road_settlement(Vector2(board.end.x - 34, horizon_y - 5), travel_destination_id, destination_name, accent, true)
	var progress_y := board.end.y - 18.0
	draw_line(Vector2(board.position.x + 24, progress_y), Vector2(board.end.x - 24, progress_y), Color("#705746"), 4.0)
	draw_line(Vector2(board.position.x + 24, progress_y), Vector2(lerpf(board.position.x + 24, board.end.x - 24, travel_progress), progress_y), _route_color(travel_route_id), 4.0)
	var road_stop_x := lerpf(board.position.x + 24, board.end.x - 24, ENCOUNTER_PROGRESS)
	draw_circle(Vector2(road_stop_x, progress_y), 5.0, Color("#17130f"))
	draw_circle(Vector2(road_stop_x, progress_y), 3.0, accent)
	draw_string(ThemeDB.fallback_font, Vector2(board.position.x + 24, progress_y - 7), "DEPART", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10), Color("#c7b49a"))
	var arrive_text_size := ThemeDB.fallback_font.get_string_size("ARRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10))
	draw_string(ThemeDB.fallback_font, Vector2(board.end.x - 24 - arrive_text_size.x, progress_y - 7), "ARRIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(10), Color("#c7b49a"))
	var caravan_position := Vector2(road_center, board.position.y + board.size.y * 0.67)
	if travel_phase == "encounter":
		draw_line(caravan_position + Vector2(58, -26), caravan_position + Vector2(58, 22), Color("#d08b62"), 5.0)
		draw_line(caravan_position + Vector2(42, -18), caravan_position + Vector2(74, -18), Color("#d08b62"), 4.0)
	_draw_departure_dust(caravan_position)
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
		for settlement_id_value in _settlement_ids():
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
	for settlement_id_value in _settlement_ids():
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
	for route_id in _route_ids():
		var route_points: Array[Vector2] = _route_points(route_id)
		if route_points.size() < 2:
			continue
		var is_selected: bool = route_id == selected_route_id
		var route_color := _route_color(route_id)
		var route_record: Dictionary = world.routes.get(route_id, {}) if world != null else MarketContent.route(route_id)
		var risk_cue := VisualRegistry.risk_cue(float(route_record.get("risk", 0.0)))
		if not selected_route_id.is_empty() and not is_selected:
			route_color.a = 0.28
		if is_selected:
			draw_polyline(PackedVector2Array(route_points), Color("#17130f"), 11.0, true)
		draw_polyline(PackedVector2Array(route_points), route_color, 7.0 if is_selected else 4.0, true)
		for point_index in range(route_points.size() - 1):
			var midpoint: Vector2 = route_points[point_index].lerp(route_points[point_index + 1], 0.5)
			match String(risk_cue.get("glyph", "ring")):
				"triangle":
					draw_polyline(PackedVector2Array([midpoint + Vector2(0, -6), midpoint + Vector2(6, 5), midpoint + Vector2(-6, 5), midpoint + Vector2(0, -6)]), Color(risk_cue.color), 2.0)
				"diamond":
					draw_polyline(PackedVector2Array([midpoint + Vector2(0, -6), midpoint + Vector2(6, 0), midpoint + Vector2(0, 6), midpoint + Vector2(-6, 0), midpoint + Vector2(0, -6)]), Color(risk_cue.color), 2.0)
				_:
					draw_circle(midpoint, 5.0, Color(risk_cue.color), false, 2.0)
	if text_scale <= 1.0:
		draw_rect(Rect2(board.position + Vector2(0, board.size.y), Vector2(board.size.x, 18.0)), Color("#231b16"), true)
		var route_ids := _route_legend_ids()
		for route_index in range(route_ids.size()):
			var footer_rect := _route_footer_rect(route_index)
			var footer_text := _route_map_label(route_ids[route_index])
			draw_string(ThemeDB.fallback_font, footer_rect.position + Vector2(0, _font_size(10)), footer_text, HORIZONTAL_ALIGNMENT_CENTER, footer_rect.size.x, _font_size(10), _route_color(route_ids[route_index]))
	for settlement_id_value in _settlement_ids():
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
	_draw_hover_card(_map_info_settlement_id())
