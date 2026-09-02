extends Control

const VisualRegistry = preload("res://src/ui/visual_registry.gd")

const SECTION_IDS := ["trade", "assignments", "information", "crew", "outlook"]
const SECTION_LABELS := ["TRADE", "JOBS", "INTEL", "CREW", "OUTLOOK"]

var settlement_id := "ashgate"
var settlement_name := "Ashgate"
var settlement_role := "regulated hub"
var identity: Dictionary = {}
var active_section := "trade"
var text_scale := 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func set_context(next_id: String, next_name: String, next_role: String, next_identity: Dictionary, next_section: String) -> void:
	settlement_id = next_id
	settlement_name = next_name
	settlement_role = next_role
	identity = next_identity.duplicate(true)
	active_section = next_section
	queue_redraw()

func set_text_scale(next_scale: float) -> void:
	text_scale = next_scale
	queue_redraw()

func _font_size(base_size: int) -> int:
	return int(round(float(base_size) * text_scale))

func _settlement_tint() -> Color:
	return Color(String(_settlement_profile().get("market_accent", "#80634d")))

func _settlement_profile() -> Dictionary:
	var profile := VisualRegistry.settlement_style(settlement_id, identity)
	profile["sky"] = Color(String(profile.get("sky", "#30251f")))
	profile["ground"] = Color(String(profile.get("ground", "#443327")))
	return profile

func scene_id() -> String:
	return String(_settlement_profile().get("scene_id", "roadside_bazaar"))

func _draw_settlement_landmark(profile: Dictionary, area: Rect2, tint: Color) -> void:
	var horizon_y := area.position.y + area.size.y * 0.58
	draw_rect(area, Color(profile.get("sky", Color("#30251f"))), true)
	draw_rect(Rect2(area.position.x, horizon_y, area.size.x, area.end.y - horizon_y), Color(profile.get("ground", Color("#443327"))), true)
	var ink := tint.lightened(0.12)
	match String(profile.get("motif", "gate")):
		"glass":
			for shard_index in range(7):
				var shard_x := area.position.x + 34.0 + shard_index * (area.size.x - 68.0) / 6.0
				var shard_height := 18.0 + float((shard_index * 11) % 26)
				draw_colored_polygon(PackedVector2Array([Vector2(shard_x - 8, horizon_y + 10), Vector2(shard_x, horizon_y - shard_height), Vector2(shard_x + 9, horizon_y + 10)]), ink.darkened(0.08 + 0.04 * (shard_index % 2)))
		"kiln":
			for kiln_index in range(4):
				var kiln_x := area.position.x + area.size.x * (0.28 + kiln_index * 0.15)
				draw_arc(Vector2(kiln_x, horizon_y + 8), 22, PI, TAU, 20, ink, 5.0)
				draw_line(Vector2(kiln_x + 17, horizon_y - 6), Vector2(kiln_x + 17, horizon_y - 35), ink.darkened(0.2), 6.0)
		"mirrors":
			for mirror_index in range(6):
				var mirror_x := area.position.x + 38.0 + mirror_index * (area.size.x - 76.0) / 5.0
				var mirror_center := Vector2(mirror_x, horizon_y - 8 - float(mirror_index % 2) * 13.0)
				draw_colored_polygon(PackedVector2Array([mirror_center + Vector2(0, -18), mirror_center + Vector2(13, 0), mirror_center + Vector2(0, 18), mirror_center + Vector2(-13, 0)]), ink.darkened(0.12))
				draw_line(mirror_center + Vector2(0, 18), mirror_center + Vector2(0, 34), ink, 3.0)
		"quay":
			draw_rect(Rect2(area.position.x, horizon_y + 9, area.size.x, 7), Color("#36544e"), true)
			for pier_index in range(4):
				var pier_x := area.position.x + area.size.x * (0.18 + pier_index * 0.2)
				draw_line(Vector2(pier_x, horizon_y - 2), Vector2(pier_x, horizon_y + 27), ink.darkened(0.22), 5.0)
				draw_line(Vector2(pier_x - 22, horizon_y - 2), Vector2(pier_x + 22, horizon_y - 2), ink, 4.0)
			draw_line(Vector2(area.position.x + 18, horizon_y - 37), Vector2(area.end.x - 22, horizon_y - 25), ink.darkened(0.14), 2.0)
			for lamp_index in range(6):
				var lamp_x := area.position.x + 34.0 + lamp_index * (area.size.x - 68.0) / 5.0
				draw_circle(Vector2(lamp_x, horizon_y - 31.0 + lamp_index * 2.4), 4.5, Color("#d7b568"))
		"watchtower":
			var tower_center := Vector2(area.position.x + area.size.x * 0.68, horizon_y)
			draw_line(tower_center + Vector2(-24, 12), tower_center + Vector2(-13, -48), ink.darkened(0.16), 6.0)
			draw_line(tower_center + Vector2(24, 12), tower_center + Vector2(13, -48), ink.darkened(0.16), 6.0)
			draw_rect(Rect2(tower_center + Vector2(-29, -55), Vector2(58, 18)), ink, true)
			draw_circle(tower_center + Vector2(0, -64), 7.0, Color("#d99a55"))
			for reed_index in range(13):
				var reed_x := area.position.x + 12.0 + reed_index * (area.size.x - 24.0) / 12.0
				draw_line(Vector2(reed_x, horizon_y + 15), Vector2(reed_x + 2, horizon_y - float((reed_index * 5) % 17)), ink.darkened(0.18), 2.0)
		"brine":
			for pan_index in range(5):
				var pan_x := area.position.x + 30.0 + pan_index * area.size.x / 5.0
				draw_arc(Vector2(pan_x, horizon_y + 12), 22, 0, PI, 16, ink, 2.0)
			draw_line(Vector2(area.position.x + area.size.x * 0.72, horizon_y - 34), Vector2(area.position.x + area.size.x * 0.72, horizon_y + 18), ink, 5.0)
			draw_line(Vector2(area.position.x + area.size.x * 0.68, horizon_y - 20), Vector2(area.position.x + area.size.x * 0.79, horizon_y - 20), ink, 3.0)
		"forge":
			for stack_index in range(3):
				var stack_x := area.position.x + area.size.x * (0.62 + stack_index * 0.08)
				draw_rect(Rect2(stack_x, horizon_y - 38 - stack_index * 6, 10, 48 + stack_index * 6), ink.darkened(0.18), true)
				draw_circle(Vector2(stack_x + 5, horizon_y - 46 - stack_index * 8), 8 + stack_index * 2, Color(ink, 0.32))
			draw_line(Vector2(area.position.x + 20, horizon_y + 4), Vector2(area.end.x - 22, horizon_y - 12), ink, 4.0)
		"lanterns":
			draw_line(Vector2(area.position.x + 12, horizon_y - 28), Vector2(area.end.x - 12, horizon_y - 18), ink.darkened(0.12), 2.0)
			for lantern_index in range(7):
				var lantern_x := area.position.x + 35.0 + lantern_index * (area.size.x - 70.0) / 6.0
				var lantern_y := horizon_y - 26.0 + lantern_index * 1.6
				draw_line(Vector2(lantern_x, lantern_y), Vector2(lantern_x, lantern_y + 9), ink, 1.5)
				draw_circle(Vector2(lantern_x, lantern_y + 12), 4.0, Color("#e1a75b"))
		"reeds":
			draw_rect(Rect2(area.position.x, horizon_y + 11, area.size.x, 5), Color("#52706a"), true)
			for reed_index in range(18):
				var reed_x := area.position.x + 12.0 + reed_index * (area.size.x - 24.0) / 17.0
				var reed_height := 13.0 + float((reed_index * 7) % 15)
				draw_line(Vector2(reed_x, horizon_y + 14), Vector2(reed_x + 3, horizon_y + 14 - reed_height), ink, 1.5)
			draw_rect(Rect2(area.position.x + area.size.x * 0.72, horizon_y - 36, 28, 38), ink.darkened(0.12), false, 3.0)
		_:
			var gate_center := Vector2(area.position.x + area.size.x * 0.72, horizon_y)
			draw_rect(Rect2(gate_center.x - 42, gate_center.y - 34, 84, 40), ink.darkened(0.18), true)
			draw_arc(Vector2(gate_center.x, gate_center.y + 5), 22, PI, TAU, 18, Color("#19140f"), 16.0)
			draw_rect(Rect2(gate_center.x - 55, gate_center.y - 48, 18, 54), ink, true)
			draw_rect(Rect2(gate_center.x + 37, gate_center.y - 48, 18, 54), ink, true)

func _draw_person(center: Vector2, coat: Color, scale: float = 1.0) -> void:
	draw_circle(center + Vector2(0, -14) * scale, 6.5 * scale, Color("#d6ad7b"))
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-9, -7) * scale,
		center + Vector2(9, -7) * scale,
		center + Vector2(13, 18) * scale,
		center + Vector2(-13, 18) * scale,
	]), coat)
	draw_line(center + Vector2(-4, 18) * scale, center + Vector2(-7, 29) * scale, Color("#34251d"), 3.0 * scale)
	draw_line(center + Vector2(4, 18) * scale, center + Vector2(7, 29) * scale, Color("#34251d"), 3.0 * scale)

func _draw_stall_icon(index: int, center: Vector2, color: Color) -> void:
	match index:
		0:
			draw_rect(Rect2(center + Vector2(-13, -5), Vector2(11, 11)), color, false, 2.0)
			draw_rect(Rect2(center + Vector2(2, -10), Vector2(11, 16)), color, false, 2.0)
		1:
			draw_rect(Rect2(center + Vector2(-12, -12), Vector2(24, 22)), color, false, 2.0)
			draw_line(center + Vector2(-7, -5), center + Vector2(7, -5), color, 2.0)
			draw_line(center + Vector2(-7, 1), center + Vector2(5, 1), color, 2.0)
		2:
			draw_circle(center + Vector2(0, -2), 8, color, false, 2.0)
			draw_line(center + Vector2(0, 6), center + Vector2(0, 14), color, 2.0)
			draw_line(center + Vector2(-7, 14), center + Vector2(7, 14), color, 2.0)
		3:
			draw_circle(center + Vector2(-7, -5), 5, color, false, 2.0)
			draw_circle(center + Vector2(7, -5), 5, color, false, 2.0)
			draw_line(center + Vector2(-12, 10), center + Vector2(12, 10), color, 3.0)
		4:
			draw_line(center + Vector2(-11, 10), center + Vector2(6, -9), color, 3.0)
			draw_circle(center + Vector2(9, -12), 5, color, false, 2.0)
			draw_line(center + Vector2(-3, 1), center + Vector2(8, 11), color, 2.0)

func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	var tint := _settlement_tint()
	var profile := _settlement_profile()
	draw_rect(bounds, Color("#19140f"), true)
	draw_rect(Rect2(1, 1, size.x - 2, size.y - 2), tint.darkened(0.52), false, 2.0)
	draw_rect(Rect2(2, 2, size.x - 4, 36), tint.darkened(0.62), true)
	draw_string(ThemeDB.fallback_font, Vector2(16, 25), "%s — %s" % [settlement_name.to_upper(), settlement_role.to_upper()], HORIZONTAL_ALIGNMENT_LEFT, -1, _font_size(14), Color("#e6c58d"))
	draw_string(ThemeDB.fallback_font, Vector2(size.x - 250, 25), String(profile.get("caption", "A LIVING MARKET BETWEEN ROADS")), HORIZONTAL_ALIGNMENT_LEFT, 235, _font_size(11), Color("#b5a18b"))
	_draw_settlement_landmark(profile, Rect2(3, 38, size.x - 6, maxf(40.0, size.y - 41.0)), tint)

	var gap := 8.0
	var left_margin := 10.0
	var stall_width := (size.x - left_margin * 2.0 - gap * 4.0) / 5.0
	var stall_top := 49.0
	var stall_height := maxf(54.0, size.y - stall_top - 12.0)
	var active_index := SECTION_IDS.find(active_section)
	for index in range(5):
		var accent := Color(String(VisualRegistry.BAZAAR_SECTION_ACCENTS.get(SECTION_IDS[index], "#80634d")))
		var stall_rect := Rect2(left_margin + index * (stall_width + gap), stall_top, stall_width, stall_height)
		var selected := index == active_index
		draw_rect(stall_rect, accent.darkened(0.68 if selected else 0.78), true)
		draw_rect(stall_rect, Color("#f1d39d") if selected else accent.darkened(0.25), false, 3.0 if selected else 1.5)
		var canopy_height := minf(30.0, stall_height * 0.35)
		var canopy := Rect2(stall_rect.position, Vector2(stall_width, canopy_height))
		draw_rect(canopy, accent.darkened(0.22), true)
		var stripe_width := stall_width / 6.0
		for stripe in range(6):
			if stripe % 2 == 0:
				draw_rect(Rect2(canopy.position.x + stripe * stripe_width, canopy.position.y, stripe_width, canopy.size.y), accent.lightened(0.13), true)
		draw_rect(Rect2(stall_rect.position + Vector2(7, maxf(canopy_height + 8.0, stall_height - 42)), Vector2(stall_width - 14, minf(24.0, stall_height * 0.22))), Color("#3b2a1f"), true)
		var figure_color := accent.lightened(0.08) if selected else accent.darkened(0.05)
		if stall_height >= 120.0:
			_draw_person(Vector2(stall_rect.get_center().x - 18, stall_rect.position.y + stall_height - 70), figure_color, 0.9)
			_draw_stall_icon(index, Vector2(stall_rect.get_center().x + 23, stall_rect.position.y + 73), Color("#e7d3aa") if selected else Color("#a9987c"))
		draw_string(ThemeDB.fallback_font, Vector2(stall_rect.position.x, stall_rect.position.y + 24), SECTION_LABELS[index], HORIZONTAL_ALIGNMENT_CENTER, stall_width, _font_size(12), Color("#fff0bd") if selected else Color("#d3c0a0"))
		if selected:
			draw_circle(Vector2(stall_rect.get_center().x, stall_rect.end.y - 8), 3.5, Color("#fff0bd"))

