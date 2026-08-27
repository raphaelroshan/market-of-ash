extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/Main.tscn")
	var ui: Control = scene.instantiate()
	root.add_child(ui)
	await process_frame

	_expect(ui.menu_layer != null and ui.menu_layer.visible, "main menu should be visible on first launch")
	_expect(ui.shop_layer != null and not ui.shop_layer.visible, "shop should remain hidden until Start Game")
	_expect(ui.game_layer != null and not ui.game_layer.visible, "departure map should remain hidden until planning begins")
	_expect(ui.start_game_button != null and ui.start_game_button.text == "Start Game", "main menu should expose a Start Game button")

	ui._on_start_game_pressed()
	_expect(not ui.menu_layer.visible and ui.shop_layer.visible and not ui.game_layer.visible, "Start Game should open the central shop rather than the departure map")
	_expect(ui.world.current_settlement == "ashgate" and ui.world.day == 1, "Start Game did not load the authored Ashgate day-one preset")
	_expect(ui.world.money == 120 and ui.world.provisions == 12 and int(ui.world.cargo.get("weight", 0)) == 0, "Start Game did not restore the authored resource preset")
	_expect(ui._selected_id(ui.shop_good_option) == "grain" and int(ui.shop_quantity.value) == 2, "shop did not select the authored first market example")
	_expect(ui.plan_departure_button != null and ui.plan_departure_button.text == "Plan departure", "shop did not expose the plan-departure handoff")
	_expect(ui.shop_market_preview_label != null and ui.shop_market_preview_label.text.contains("Why this price:"), "shop did not render an explainable market preview")
	_expect(ui.shop_status_label != null and ui.shop_status_label.text.contains("Ashgate"), "shop did not render local settlement context")

	var forecast_before: String = JSON.stringify(ui.world.serialize())
	ui.shop_quantity.value = 3
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	if JSON.stringify(ui.world.serialize()) != forecast_before:
		failures.append("shop forecast changes mutated authoritative world state")
	if not ui.shop_market_preview_label.text.contains("load total"):
		failures.append("shop market preview did not refresh selected load total")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)

	ui._on_guided_test_action()
	_expect(int(ui.world.cargo.get("grain", 0)) == 2 and int(ui.world.cargo.get("weight", 0)) == 2, "guided test action did not execute the promised grain purchase")
	_expect(ui.world.command_history.size() == 1, "guided test action did not use the explicit command boundary")
	_expect(ui.guided_test_button.disabled, "guided test action should be unavailable after its one preset execution")
	_expect(ui.playtest_status_label.text.contains("STEP 2 OF 3"), "grain purchase did not advance the playtest objective")

	var shop_state: String = JSON.stringify(ui.world.serialize())
	ui._on_plan_departure_pressed()
	_expect(not ui.shop_layer.visible and ui.game_layer.visible, "Plan departure should open the dedicated departure map")
	_expect(ui._selected_id(ui.destination_option) == "reedwatch" and ui._selected_id(ui.route_option) == "old_road", "departure desk did not preserve the selected first-route plan")
	_expect(ui.departure_load_label != null and ui.departure_load_label.text.contains("Grain x2"), "departure desk did not carry the planned load forward")
	_expect(ui.route_preview_label != null and ui.route_preview_label.text.contains("EXPECTED NET PROFIT"), "departure desk did not render the route-profit preview")
	_expect(ui.route_preview_label.text.contains("1 Grain unit at risk"), "departure desk did not disclose the one-unit cargo risk basis")
	_expect(ui.route_preview_label.text.contains("Risk source:"), "departure desk did not disclose the authored route-risk source")
	ui._on_return_to_shop_pressed()
	_expect(ui.shop_layer.visible and not ui.game_layer.visible, "Return to shop should close the departure map")
	if JSON.stringify(ui.world.serialize()) != shop_state:
		failures.append("returning from departure planning mutated authoritative world state")

	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_option.item_count == 1 and ui._selected_id(ui.route_option) == "toll_road", "destination selection should expose only the connected Toll Road route")
	ui._select_option_by_id(ui.destination_option, "reedwatch")
	ui._on_destination_changed(ui.destination_option.selected)
	_expect(ui.route_option.item_count == 1 and ui._selected_id(ui.route_option) == "old_road", "destination selection should restore the connected Old Road route")

	_expect(ui.map_panel != null, "departure UI did not create the map panel")
	if ui.map_panel != null:
		_expect(ui.map_panel.GRID_SIZE == Vector2i(17, 11), "map grid size is not the stable 17x11 contract")
		_expect(ui.map_panel._route_points("old_road").size() == 3, "old road does not expose a traversable three-point corridor")
		var map_before: String = JSON.stringify(ui.world.serialize())
		ui._on_map_cell_selected(Vector2i(6, 4))
		_expect(ui.event_label.text.contains("Grid cell (6, 4) selected"), "grid selection did not produce a readable coordinate event")
		if JSON.stringify(ui.world.serialize()) != map_before:
			failures.append("grid selection mutated authoritative world state")
		ui._on_depart_pressed()
		_expect(ui.map_panel.traveling, "successful departure did not start presentation traversal")
		_expect(ui.map_panel.travel_points.size() == 3, "travel traversal did not create origin, waypoint, destination")
		_expect(ui.enter_settlement_button.visible and ui.commit_departure_button.disabled, "arrival state did not present an explicit settlement-entry action")
		_expect(ui.playtest_status_label.text.contains("STEP 3 OF 3"), "arrival with grain did not advance the playtest objective")
		await process_frame
		_expect(ui.map_panel.travel_progress > 0.0, "presentation traversal did not advance")

	ui._on_enter_settlement_pressed()
	_expect(ui.shop_layer.visible and not ui.game_layer.visible, "Enter settlement should return the player to the central shop")
	ui._on_sell_pressed()
	_expect(ui.playtest_status_label.text.contains("RUN COMPLETE"), "selling delivered grain from the destination shop did not complete the playtest objective")

	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("Map UI smoke: PASS")
	else:
		for failure in failures:
			push_error(failure)
		printerr("Map UI smoke: FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
