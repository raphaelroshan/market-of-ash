extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame

	if ui.map_panel == null:
		failures.append("main UI did not create the map panel")
	else:
		if ui.map_panel.GRID_SIZE != Vector2i(17, 11):
			failures.append("map grid size is not the stable 17x11 contract")
		if ui.map_panel._route_points("old_road").size() != 3:
			failures.append("old road does not expose a traversable three-point corridor")
		var before: String = JSON.stringify(ui.world.serialize())
		ui._on_map_cell_selected(Vector2i(6, 4))
		if not ui.event_label.text.contains("Grid cell (6, 4) selected"):
			failures.append("grid selection did not produce a readable coordinate event")
		if JSON.stringify(ui.world.serialize()) != before:
			failures.append("grid selection mutated authoritative world state")
		ui._on_depart_pressed()
		if not ui.map_panel.traveling:
			failures.append("successful departure did not start presentation traversal")
		if ui.map_panel.travel_points.size() != 3:
			failures.append("travel traversal did not create origin, waypoint, destination")
		await process_frame
		if ui.map_panel.travel_progress <= 0.0:
			failures.append("presentation traversal did not advance")

	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("Map UI smoke: PASS")
	else:
		for failure in failures:
			push_error(failure)
		printerr("Map UI smoke: FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)
