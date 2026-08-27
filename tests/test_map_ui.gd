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
	_expect(ui.opportunity_status_label != null and ui.opportunity_status_label.text.contains("2 of 2 visit slots remain"), "shop did not expose the visit-action budget")
	_expect(ui.opportunity_buttons.size() == 1 and not ui.opportunity_buttons[0].disabled, "Ashgate should expose one usable local opportunity")
	_expect(ui.opportunity_buttons[0].focus_mode != Control.FOCUS_NONE, "the local opportunity should remain keyboard/controller focusable")
	_expect(ui.contract_buttons.size() == 1 and not ui.contract_buttons[0].disabled, "Ashgate should expose the Reedwatch relief contract")
	var action_money_before: int = ui.world.money
	var action_provisions_before: int = ui.world.provisions
	ui._on_settlement_action_pressed("ashgate_provision_bundle")
	_expect(ui.world.money == action_money_before - 6 and ui.world.provisions == action_provisions_before + 4, "local opportunity UI did not execute the command's visible effects")
	_expect(ui.opportunity_status_label.text.contains("1 of 2 visit slots remain"), "local opportunity UI did not refresh the remaining visit budget")
	ui._on_start_game_pressed()
	ui._on_accept_contract_pressed("reedwatch_water_relief_01")
	_expect(not ui.world.active_contract("reedwatch_water_relief_01").is_empty(), "contract card did not accept the relief contract through the command boundary")
	_expect(ui.active_contract_label.text.contains("4 water at Reedwatch by Day 3"), "shop did not show the frozen active-contract terms")

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
	_expect(ui.world.command_history.size() == 2 and ui.world.command_history.back().id == "buy_goods", "guided test action did not use the explicit command boundary")
	_expect(ui.guided_test_button.disabled, "guided test action should be unavailable after its one preset execution")
	_expect(ui.playtest_status_label.text.contains("STEP 2 OF 3"), "grain purchase did not advance the playtest objective")

	var shop_state: String = JSON.stringify(ui.world.serialize())
	ui._on_plan_departure_pressed()
	_expect(not ui.shop_layer.visible and ui.game_layer.visible, "Plan departure should open the dedicated departure map")
	_expect(ui._selected_id(ui.destination_option) == "reedwatch" and ui._selected_id(ui.route_option) == "old_road", "departure desk did not preserve the selected first-route plan")
	_expect(ui.departure_load_label != null and ui.departure_load_label.text.contains("Grain x2"), "departure desk did not carry the planned load forward")
	_expect(ui.route_preview_label != null and ui.route_preview_label.text.contains("EXPECTED NET PROFIT"), "departure desk did not render the route-profit preview")
	_expect(ui.departure_contract_label.text.contains("CONTRACT PIN") and ui.departure_contract_label.text.contains("Held 0/4"), "departure desk did not pin the active contract and cargo shortfall")
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
	_expect(ui.opportunity_status_label.text.contains("2 of 2 visit slots remain"), "arrival did not refresh the destination visit budget")
	_expect(ui.opportunity_buttons.size() == 1 and ui.opportunity_buttons[0].disabled, "Reedwatch should show its unavailable opportunity with a disabled control")
	_expect(ui.opportunity_buttons[0].tooltip_text.contains("relief-contract system"), "disabled Reedwatch opportunity did not explain its dependency")
	_expect(ui.contract_buttons.size() == 1 and ui.contract_buttons[0].disabled, "partial contract should remain visible but blocked until required cargo is acquired")
	_expect(ui.contract_buttons[0].tooltip_text.contains("Acquire 4 more water"), "partial contract should explain the exact missing cargo")
	ui._on_sell_pressed()
	_expect(ui.playtest_status_label.text.contains("RUN COMPLETE"), "selling delivered grain from the destination shop did not complete the playtest objective")
	_expect(ui.shop_market_preview_label.text.contains("Market memory: your last 2 grain delivered here softened this price by 8%"), "completed sale did not expose the local delivery-memory explanation")
	_expect(ui.shop_market_preview_label.text.contains("memory 0.92"), "market preview did not show the post-delivery price multiplier")

	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "medicine")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._select_option_by_id(ui.destination_option, "brine_cross")
	ui._on_destination_changed(ui.destination_option.selected)
	ui._on_depart_pressed()
	_expect(not ui.world.pending_event.is_empty() and ui.world.pending_event.id == "gatekeepers_chalk", "eligible Toll Road trip did not present Gatekeeper's Chalk")
	_expect(ui.event_card.visible and not ui.enter_settlement_button.visible, "pending route event should block arrival and show the event card")
	_expect(ui.event_title_label.text == "The Gatekeeper's Chalk", "event card did not render the authored title")
	_expect(ui.event_stakes_label.text.contains("Toll Road") and ui.event_stakes_label.text.contains("1 Medicine unit valued at 44"), "event card did not expose route and cargo context")
	_expect(ui.event_choice_buttons.size() == 3, "Gatekeeper's Chalk should expose all three authored choices")
	_expect(ui.event_choice_buttons[0].focus_mode != Control.FOCUS_NONE, "event choices should remain keyboard/controller focusable")
	_expect(ui.departure_status_label.text.contains("ROUTE DECISION"), "departure screen did not identify the paused route decision")
	ui._on_event_choice_pressed("gatekeepers_chalk", "pay_posted_toll")
	_expect(ui.world.pending_event.is_empty() and ui.world.current_settlement == "brine_cross", "paying the event toll did not complete arrival")
	_expect(not ui.event_card.visible and ui.enter_settlement_button.visible, "resolved event should hide its choices and expose settlement entry")
	_expect(ui.world.event_history.size() == 1 and ui.world.event_history.back().choice_id == "pay_posted_toll", "event UI did not preserve the chosen outcome")

	ui._on_start_game_pressed()
	ui._select_option_by_id(ui.shop_good_option, "scrap")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	_expect(ui.world.pending_event.get("id", "") == "span_at_cinderford", "eligible Old Road load did not present The Span at Cinderford")
	_expect(ui.event_title_label.text == "The Span at Cinderford", "span event card did not render its authored title")
	_expect(ui.event_stakes_label.text.contains("Old Road") and ui.event_stakes_label.text.contains("Repair stock recognized: 2 Scrap"), "span event card did not expose route and frozen material context")
	_expect(ui.event_choice_buttons.size() == 4, "span event should expose all four authored choices")
	_expect(ui.event_choice_buttons[0].text.contains("+30 ashmarks") and ui.event_choice_buttons[0].text.contains("2 materials"), "premium option did not disclose its reward and cargo cost")
	_expect(ui.event_choice_buttons[3].text.contains("return to origin"), "turn-back recovery did not disclose its movement result")
	_expect(ui.event_choice_buttons[0].focus_mode != Control.FOCUS_NONE, "span choices should remain keyboard/controller focusable")
	ui._on_event_choice_pressed("span_at_cinderford", "reserve_materials_for_span")
	_expect(ui.world.pending_event.is_empty() and ui.world.current_settlement == "reedwatch", "reserving span materials did not complete arrival")
	_expect(is_equal_approx(float(ui.world.route("old_road").risk), 0.25), "span event UI choice did not apply the disclosed later-route improvement")
	_expect(ui.event_label.text.contains("public support") and ui.enter_settlement_button.visible, "arrival report did not explain why the span choice changed the next route decision")

	ui._on_start_game_pressed()
	ui.world.crisis_stage = 1
	ui.world._update_crisis_modifiers()
	ui._select_option_by_id(ui.shop_good_option, "water")
	ui.shop_quantity.value = 2
	ui._on_shop_quantity_changed(ui.shop_quantity.value)
	ui._on_buy_pressed()
	ui._on_plan_departure_pressed()
	ui._on_depart_pressed()
	_expect(ui.world.pending_event.get("id", "") == "last_clean_barrel", "shortage-stage water load did not present The Last Clean Barrel")
	_expect(ui.event_title_label.text == "The Last Clean Barrel", "barrel event card did not render its authored title")
	_expect(ui.event_stakes_label.text.contains("Shortage basis: 2 Water") and ui.event_stakes_label.text.contains("plus 6 premium each"), "barrel event did not expose its frozen cargo and premium basis")
	_expect(ui.event_choice_buttons.size() == 4 and ui.event_choice_buttons[0].text.contains("+"), "barrel event did not expose all choices and the exact emergency payout")
	_expect(ui.event_choice_buttons[2].disabled and ui.event_choice_buttons[2].tooltip_text.contains("active water relief commitment"), "contract-only barrel response did not show its unavailable prerequisite")
	_expect(ui.event_choice_buttons[3].focus_mode != Control.FOCUS_NONE, "sealed-cargo recovery should remain focusable")
	ui._on_event_choice_pressed("last_clean_barrel", "share_barrels_fairly")
	_expect(ui.world.current_settlement == "reedwatch" and ui.world.resilience_for("reedwatch") == 2, "fair barrel distribution did not strengthen destination resilience")
	_expect(ui.event_label.text.contains("resilience is now 2/10"), "barrel arrival report did not explain the persistent settlement result")
	ui._on_enter_settlement_pressed()
	_expect(ui.shop_status_label.text.contains("Settlement resilience: 2/10"), "settlement shop did not expose the event's persistent resilience result")

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
