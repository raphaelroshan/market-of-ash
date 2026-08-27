extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame

	if ui.menu_layer == null or not ui.menu_layer.visible:
		failures.append("main menu should be visible on first launch")
	if ui.game_layer == null or ui.game_layer.visible:
		failures.append("playtest screen should remain hidden until Start Game")
	if ui.start_game_button == null or ui.start_game_button.text != "Start Game":
		failures.append("main menu should expose a Start Game button")

	ui._on_start_game_pressed()
	if ui.menu_layer.visible or not ui.game_layer.visible:
		failures.append("Start Game should transition from menu to playtest screen")
	if ui.world.current_settlement != "ashgate" or ui.world.day != 1:
		failures.append("Start Game did not load the authored Ashgate day-one preset")
	if ui.world.money != 120 or ui.world.provisions != 12 or int(ui.world.cargo.get("weight", 0)) != 0:
		failures.append("Start Game did not restore the authored resource preset")
	if ui._selected_id(ui.destination_option) != "reedwatch" or ui._selected_id(ui.route_option) != "old_road":
		failures.append("playtest preset did not select the authored first route forecast")
	if ui.guided_test_button == null or ui.guided_test_button.disabled:
		failures.append("playtest screen did not expose the guided test action")
	if ui.playtest_status_label == null or not ui.playtest_status_label.text.contains("STEP 1 OF 3"):
		failures.append("playtest screen did not explain the opening decision")

	if ui.map_panel == null:
		failures.append("main UI did not create the map panel")
	else:
		if ui.market_preview_label == null or not ui.market_preview_label.text.contains("Why this price:"):
			failures.append("main UI did not render an explainable market preview")
		elif not ui.market_preview_label.text.contains("Other markets:"):
			failures.append("market preview did not render regional price comparison")
		if ui.route_preview_label == null or not ui.route_preview_label.text.contains("EXPECTED NET PROFIT"):
			failures.append("main UI did not render a route-profit preview")
		elif not ui.route_preview_label.text.contains("expected loss"):
			failures.append("route preview did not render risk-adjusted loss")
		var forecast_before: String = JSON.stringify(ui.world.serialize())
		ui.cargo_quantity.value = 3
		ui._refresh_forecasts()
		if JSON.stringify(ui.world.serialize()) != forecast_before:
			failures.append("forecast refresh mutated authoritative world state")
		if ui.market_preview_label.text.find("load total") < 0:
			failures.append("market preview did not refresh selected load total")

		ui._on_guided_test_action()
		if int(ui.world.cargo.get("grain", 0)) != 2 or int(ui.world.cargo.get("weight", 0)) != 2:
			failures.append("guided test action did not execute the promised grain purchase")
		if ui.world.command_history.size() != 1:
			failures.append("guided test action did not use the explicit command boundary")
		if not ui.guided_test_button.disabled:
			failures.append("guided test action should be unavailable after its one preset execution")
		if not ui.playtest_status_label.text.contains("STEP 2 OF 3"):
			failures.append("grain purchase did not advance the playtest objective")

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
		if not ui.playtest_status_label.text.contains("STEP 3 OF 3"):
			failures.append("arrival with grain did not advance the playtest objective")
		ui._on_sell_pressed()
		if not ui.playtest_status_label.text.contains("RUN COMPLETE"):
			failures.append("selling the delivered grain did not complete the playtest objective")
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
