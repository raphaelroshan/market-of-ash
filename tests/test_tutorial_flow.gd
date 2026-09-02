extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")
const TutorialDirector = preload("res://src/ui/tutorial_director.gd")
const MarketEconomy = preload("res://src/core/economy.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var ui: Control = MainScene.instantiate()
	root.add_child(ui)
	await process_frame
	var prefix := "user://market_of_ash_tutorial_test_%d" % OS.get_process_id()
	ui.save_path = prefix + ".save"
	ui.settings_path = prefix + ".cfg"
	ui.report_path = prefix + ".json"
	ui.autosave_enabled = false
	ui.settings_persistence_enabled = false
	ui._on_interface_sounds_toggled(false)

	_expect(ui._current_ui_state_id() == "main_menu", "the game should begin at the player-facing main menu")
	_expect(ui.start_game_button.text == "New Game" and ui.settings_button.text == "Settings" and ui.credits_button.text == "Credits", "the main menu should use game-facing actions")
	_expect(not ui.developer_panel.visible and not ui.shop_report_button.visible and not ui.diagnostics_label.visible, "developer utilities should be absent from normal play")
	_expect_release_surface(ui, "main menu")

	ui._on_new_game_pressed()
	_expect_release_surface(ui, "introduction")
	_expect(ui._current_ui_state_id() == "introduction" and ui.intro_page == 0, "New Game should open the introduction before creating a campaign")
	_expect(ui.intro_title_label.text.contains("roads are open"), "the first introduction card should establish the basin")
	var intro_state: Dictionary = ui._web_ui_state()
	var intro_actions: Array = intro_state.get("accessibility_actions", [])
	_expect(intro_actions.any(func(action: Dictionary) -> bool: return action.get("id", "") == "intro_next") and intro_actions.any(func(action: Dictionary) -> bool: return action.get("id", "") == "intro_skip"), "the introduction should expose semantic next and skip actions")
	ui._on_intro_next_pressed()
	_expect(ui.intro_page == 1 and ui.intro_title_label.text.contains("promise"), "the second introduction card should explain the caravan")
	ui._on_intro_next_pressed()
	_expect(ui.intro_page == 2 and ui.intro_title_label.text.contains("cheap road"), "the third introduction card should explain route tradeoffs")
	ui._on_intro_next_pressed()
	await process_frame
	_expect(ui._current_ui_state_id() == "settlement_shop" and ui.tutorial.enabled, "the final introduction card should begin the guided campaign")
	_expect_release_surface(ui, "opening Bazaar")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_BUY_WATER and ui.tutorial_panel.visible, "the first tutorial objective should be an ordinary Water purchase")
	_expect(int(ui.shop_quantity.value) == 4 and ui._selected_id(ui.shop_good_option) == "water", "the canonical tutorial should prepare the four-Water relief plan")
	_expect(ui.world.active_contracts.is_empty() and ui.world.contract_history.is_empty(), "the ordinary-trade tutorial should not accept a contract for the player")
	_expect(ui.shop_decision_path_label.text == "ORDINARY TRADE · NO CONTRACT" and ui.shop_decision_journey_label.text == "ASHGATE → REEDWATCH" and ui.shop_decision_resources_label.text.contains("HOLD 0/12 → 4/12") and ui.shop_decision_reason_label.text.contains("Frontier wells run low"), "the first Bazaar plan should expose demand, destination, and capacity before purchase")

	ui._on_buy_pressed()
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_PLAN_REEDWATCH and int(ui.world.cargo.get("water", 0)) == 4, "buying the ordinary Water load should advance to route planning")
	_expect(ui.trade_receipt_panel.visible and ui.trade_receipt_detail_label.text.contains("60 ashmarks paid") and ui.trade_receipt_detail_label.text.contains("hold 4/12"), "the purchase receipt should expose cash and capacity changes")

	ui._on_plan_departure_pressed()
	_expect(ui._selected_id(ui.destination_option) == "reedwatch" and ui._selected_id(ui.route_option) == "old_road", "the tutorial should prepare Reedwatch by the Old Road without committing it")
	_expect(ui.route_preview_label.text.contains("Route fee 4") and ui.route_preview_label.text.contains("provisions 1") and ui.route_preview_label.text.contains("at 35% risk"), "route comparison should expose fee, provisions, and cargo risk before commitment")
	ui._on_depart_pressed()
	_expect_release_surface(ui, "first departure")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_ROAD_DECISION and ui.world.pending_event.get("id", "") == "three_riders_no_banner", "the first committed journey should teach the seeded roadside decision")
	ui.map_panel._process(2.0)
	_expect(ui.map_panel.travel_phase == "road", "the tutorial may not bypass the road observation")
	ui._on_continue_journey_pressed()
	_expect_release_surface(ui, "first road stop")
	ui._on_event_choice_pressed("three_riders_no_banner", "pay_for_escort")
	_expect_release_surface(ui, "first encounter result")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_ENTER_REEDWATCH and ui.arrival_pending, "resolving the roadside decision should advance to arrival review")
	ui._on_enter_settlement_pressed()
	_expect_release_surface(ui, "Reedwatch Bazaar")
	_expect(ui.world.current_settlement == "reedwatch" and ui.tutorial.current_step == TutorialDirector.STEP_SELL_WATER, "arrival should lead to the ordinary Water sale")
	_expect(ui._selected_id(ui.shop_good_option) == "water" and int(ui.shop_quantity.value) == 4, "the arrival lesson should prepare the surviving Water load")
	var water_price_before := MarketEconomy.price_for("water", ui.world.settlement("reedwatch"), ui.world.pricing_context())
	ui._on_sell_pressed()
	var water_price_after := MarketEconomy.price_for("water", ui.world.settlement("reedwatch"), ui.world.pricing_context())
	_expect(water_price_after < water_price_before and ui.tutorial.current_step == TutorialDirector.STEP_BUY_GRAIN, "the ordinary Water sale should soften Reedwatch's next local price and advance to return trade")
	_expect(ui.trade_receipt_panel.visible and ui.trade_receipt_detail_label.text.contains("local unit %d → %d after supply" % [water_price_before, water_price_after]), "the sale receipt should show the before/after market price")
	_expect(ui.world.market_delivery_history.back().get("delivery_mode", "") == "ordinary_trade", "the taught market change should come from ordinary trade")
	_expect(ui._selected_id(ui.shop_good_option) == "grain" and int(ui.shop_quantity.value) == 4, "the return lesson should prepare four Grain")

	ui._on_buy_pressed()
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_RETURN_ASHGATE and int(ui.world.cargo.get("grain", 0)) == 4, "buying Grain should advance to the return journey")
	ui._on_plan_departure_pressed()
	_expect(ui._selected_id(ui.destination_option) == "ashgate" and ui._selected_id(ui.route_option) == "old_road", "the second journey should point back to Ashgate")
	ui._on_depart_pressed()
	_expect_release_surface(ui, "return departure")
	ui.map_panel._process(2.0)
	ui._on_continue_journey_pressed()
	ui.map_panel._process(2.0)
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_ENTER_ASHGATE and ui.arrival_pending, "the return journey should end at an explicit arrival handoff")
	ui._on_enter_settlement_pressed()
	_expect_release_surface(ui, "return to Ashgate")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_SELL_GRAIN, "entering Ashgate should teach closing the trade loop")
	ui._on_sell_pressed()
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_REVIEW_OPTIONAL_WORK, "selling the return load should introduce optional assignments; step=%s cargo=%s history=%s" % [ui.tutorial.current_step, JSON.stringify(ui.world.cargo), JSON.stringify(ui.world.command_history.back())])
	_expect(ui.world.active_contracts.is_empty() and ui.world.contract_history.is_empty(), "the complete taught trade circuit should remain contract-free")

	ui._on_bazaar_navigation_pressed("assignments")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_RECRUIT_CREW and not ui.contract_buttons.is_empty(), "opening the Job Board should teach that assignments are available without accepting one")

	ui._on_bazaar_navigation_pressed("crew")
	ui._on_recruit_crew_pressed("nara_vey")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_ASSIGN_CREW, "recruitment should advance to route assignment")
	ui._on_assign_crew_pressed("nara_vey")
	_expect(ui.tutorial.current_step == TutorialDirector.STEP_REVIEW_OUTLOOK, "crew assignment should advance to the wider campaign")
	ui._on_bazaar_navigation_pressed("outlook")
	_expect_release_surface(ui, "completed tutorial Outlook")
	_expect(ui.tutorial.completed and not ui.tutorial.enabled and ui.tutorial.current_step == TutorialDirector.STEP_COMPLETE, "opening Town Outlook should complete the two-journey tutorial")

	_expect(ui._write_save("SAVED"), "the completed tutorial campaign should save")
	var saved_file := FileAccess.open(ui.save_path, FileAccess.READ)
	var saved_data: Variant = JSON.parse_string(saved_file.get_as_text()) if saved_file != null else null
	_expect(typeof(saved_data) == TYPE_DICTIONARY and saved_data.has("world") and saved_data.has("presentation"), "new saves should wrap world and presentation state")
	var loaded: Dictionary = ui._load_candidate(ui.save_path)
	_expect(bool(loaded.get("ok", false)) and bool(Dictionary(loaded.get("tutorial", {})).get("completed", false)) and bool(Dictionary(loaded.get("tutorial", {})).get("optional_work_seen", false)), "tutorial completion and optional-work lesson should survive validated loading")
	ui.tutorial.start()
	_expect(ui._on_load_pressed() and ui.tutorial.completed and not ui.tutorial.enabled, "loading should restore completed tutorial presentation state into the active campaign")

	var future_path := prefix + "_future.save"
	var future_file := FileAccess.open(future_path, FileAccess.WRITE)
	if future_file != null:
		future_file.store_string(JSON.stringify({"format": ui.SAVE_ENVELOPE_FORMAT, "format_version": ui.SAVE_ENVELOPE_VERSION + 1, "world": ui.world.serialize()}))
		future_file = null
	_expect(not bool(ui._load_candidate(future_path).get("ok", true)), "a future campaign save envelope should fail closed")
	if FileAccess.file_exists(future_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(future_path))

	_cleanup(prefix)
	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("Tutorial flow: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("Tutorial flow: FAIL (%d)" % failures.size())
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _expect_release_surface(ui: Control, milestone: String) -> void:
	_expect(not ui.developer_panel.visible, "%s should keep the developer panel hidden" % milestone)
	_expect(not ui.diagnostics_label.visible, "%s should keep diagnostics hidden" % milestone)
	_expect(not ui.shop_report_button.visible, "%s should keep report tooling hidden" % milestone)
	var action_ids: Array[String] = []
	for action in ui._web_ui_state().get("accessibility_actions", []):
		action_ids.append(String(action.get("id", "")))
	_expect("start_conflict" not in action_ids and "start_campaign" not in action_ids and "shop_report" not in action_ids and "guided_trade" not in action_ids, "%s should expose only player-facing semantic actions" % milestone)

func _cleanup(prefix: String) -> void:
	for suffix in [".save", ".save.tmp", ".save.bak", ".cfg", ".json"]:
		var path: String = prefix + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
