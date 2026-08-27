extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_runtime_content()
	_test_base_prices()
	_test_regional_price_spread()
	_test_crisis_changes_water_price()
	_test_capacity_validation()
	_test_explainable_route_preview()
	_test_incident_loss_model()
	_test_command_buy_and_sell()
	_test_market_memory()
	_test_command_validation_and_history()
	_test_depart_command()
	_test_travel_consumes_resources()
	_test_save_round_trip()
	_test_legacy_save_migration()
	if failures.is_empty():
		print("PASS: Market of Ash economy tests")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_runtime_content() -> void:
	MarketContent.reset_cache()
	var content := MarketContent.load_runtime()
	_expect(content.ok, "runtime world content should load and validate")
	_expect(MarketContent.content_version() == "0.5.0", "runtime content should expose content version")
	var memory_rules := MarketContent.market_memory_rules()
	_expect(float(memory_rules.get("pressure_max", 0.0)) == 0.35, "runtime content should expose bounded market-memory rules")
	_expect(MarketContent.good_ids() == ["grain", "water", "scrap", "medicine", "charcoal", "cloth"], "runtime content should expose authored stable good ids")
	_expect(MarketContent.settlements().size() == 5, "runtime content should expose five settlements")
	_expect(MarketContent.routes().size() == 3, "runtime content should expose three routes")
	_expect(MarketContent.route_connects("old_road", "ashgate", "reedwatch"), "old road should connect its authored endpoints")
	_expect(not MarketContent.route_connects("old_road", "ashgate", "brine_cross"), "old road should reject destinations outside its authored endpoints")
	_expect(MarketContent.destinations_from("ashgate") == ["reedwatch", "brine_cross"], "Ashgate should expose only the two directly connected destinations")

func _test_base_prices() -> void:
	_expect(MarketEconomy.base_price("water") == 18, "water base price should be 18")
	_expect(MarketEconomy.base_price("medicine") == 32, "medicine base price should be 32")
	_expect(MarketEconomy.base_price("missing") == 0, "unknown goods should have price 0")

func _test_regional_price_spread() -> void:
	var world := AshWorldState.new(1107)
	var origin := world.settlement("cinderford")
	var destination := world.settlement("reedwatch")
	var origin_price := MarketEconomy.price_for("scrap", origin, {"crisis_modifiers": world.crisis_modifiers})
	var destination_price := MarketEconomy.price_for("scrap", destination, {"crisis_modifiers": world.crisis_modifiers})
	var projected := MarketEconomy.projected_profit("scrap", 2, origin, destination, {"crisis_modifiers": world.crisis_modifiers})
	_expect(destination_price > origin_price, "regional price spread should reward moving scrap from Cinderford to Reedwatch")
	_expect(projected > 0, "a useful distant-market cargo should have positive projected gross profit")
	var explanation := MarketEconomy.explain_price("water", destination, {"crisis_modifiers": {"water": 1.5}})
	_expect(explanation.find("high") >= 0, "price explanation should identify high demand or crisis pressure")

func _test_crisis_changes_water_price() -> void:
	var world := AshWorldState.new(1107)
	var settlement := world.settlement("reedwatch")
	var before := MarketEconomy.price_for("water", settlement, {"crisis_modifiers": world.crisis_modifiers})
	world.crisis_stage = 2
	world._update_crisis_modifiers()
	var after := MarketEconomy.price_for("water", settlement, {"crisis_modifiers": world.crisis_modifiers})
	_expect(after > before, "water should become more expensive during the crisis")

func _test_capacity_validation() -> void:
	var result := MarketEconomy.validate_trade({"weight": 11}, "grain", 2, 12)
	_expect(not result.ok, "trade should fail when cargo capacity is exceeded")
	var valid := MarketEconomy.validate_trade({"weight": 10}, "grain", 2, 12)
	_expect(valid.ok, "trade should pass when cargo fits")
	_expect(int(valid.added_weight) == 2, "trade validation should report added cargo weight")

func _test_explainable_route_preview() -> void:
	var world := AshWorldState.new(1107)
	var origin := world.settlement("ashgate")
	var destination := world.settlement("reedwatch")
	var details := MarketEconomy.price_details("water", destination, {"crisis_modifiers": world.crisis_modifiers})
	_expect(details.ok, "price details should be available for a valid good and settlement")
	_expect(details.reasons.has("local production is limited"), "price details should expose local production pressure")
	_expect(details.reasons.has("local demand is high"), "price details should expose high local demand")
	world.crisis_stage = 2
	world._update_crisis_modifiers()
	var crisis_details := MarketEconomy.price_details("water", destination, {"crisis_modifiers": world.crisis_modifiers})
	_expect(crisis_details.reasons.has("the regional crisis is increasing demand"), "price details should expose crisis pressure")

	var route := world.route("old_road")
	var preview := MarketEconomy.route_profit_preview("water", 2, origin, destination, route, {
		"crisis_modifiers": world.crisis_modifiers,
		"cargo": {"water": 2, "weight": 2},
	})
	_expect(preview.ok, "route profit preview should return a valid forecast")
	_expect(int(preview.purchase_total) == int(preview.origin_price) * 2, "preview should expose the complete purchase total")
	_expect(int(preview.sale_total) == int(preview.destination_price) * 2, "preview should expose the complete expected sale total")
	_expect(int(preview.provision_cost) == int(preview.provisions) * int(preview.provision_value), "preview should expose provisions and their value")
	_expect(preview.loss_model == MarketEconomy.LOSS_MODEL_ONE_EXPOSED_UNIT, "route preview should expose the stable one-unit loss model")
	_expect(preview.loss_good_id == "water" and int(preview.loss_quantity) == 1, "route preview should identify the exposed carried unit")
	_expect(int(preview.loss_unit_value) == int(preview.destination_price), "route preview should value the exposed unit at the destination price")
	_expect(int(preview.expected_loss) == int(round(float(preview.loss_unit_value) * float(preview.risk))), "route preview should calculate expected loss from one exposed unit")
	_expect(not String(preview.risk_source).is_empty(), "route preview should expose the authored risk source")
	_expect(int(preview.expected_net_profit) == int(preview.gross_trade_margin) - int(preview.route_cost) - int(preview.provision_cost) - int(preview.expected_loss) - int(preview.time_cost), "preview net profit should equal the displayed cost breakdown")
	var invalid := MarketEconomy.route_profit_preview("missing", 2, origin, destination, route, {"crisis_modifiers": world.crisis_modifiers})
	_expect(not invalid.ok, "route preview should reject an unknown good")

func _test_incident_loss_model() -> void:
	var world := AshWorldState.new(3)
	var destination := world.settlement("reedwatch")
	var context := {"crisis_modifiers": world.crisis_modifiers}
	var water_basis := MarketEconomy.incident_loss_basis({"water": 2, "weight": 2}, destination, context)
	_expect(water_basis.loss_model == MarketEconomy.LOSS_MODEL_ONE_EXPOSED_UNIT, "incident basis should expose the stable model id")
	_expect(water_basis.loss_good_id == "water" and int(water_basis.loss_quantity) == 1, "single-good cargo should expose exactly one unit")
	_expect(int(water_basis.loss_unit_value) == 32, "water incident basis should use the current Reedwatch unit price")
	_expect(MarketEconomy.expected_incident_loss(world.route("old_road"), water_basis) == 11, "Old Road water expected loss should be risk times one unit value")
	var toll_basis := MarketEconomy.incident_loss_basis({"medicine": 3, "weight": 3}, world.settlement("brine_cross"), context)
	_expect(int(toll_basis.loss_unit_value) == 44, "medicine incident basis should use the current Brine Cross unit price")
	_expect(MarketEconomy.expected_incident_loss(world.route("toll_road"), toll_basis) == 4, "Toll Road medicine expected loss should use one unit")
	var mixed_basis := MarketEconomy.incident_loss_basis({"water": 2, "medicine": 1, "weight": 3}, destination, context)
	_expect(mixed_basis.loss_good_id == "medicine" and int(mixed_basis.loss_unit_value) == 52, "mixed cargo should expose the highest destination-value unit")
	var empty_basis := MarketEconomy.incident_loss_basis({"weight": 0}, destination, context)
	_expect(empty_basis.loss_good_id.is_empty() and int(empty_basis.loss_quantity) == 0, "empty cargo should expose no unit")
	_expect(MarketEconomy.expected_incident_loss(world.route("old_road"), empty_basis) == 0, "empty cargo should have zero expected loss")

	world.cargo = {"water": 2, "medicine": 1, "weight": 3}
	var incident := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(incident.ok and float(incident.state_delta.risk_roll) < float(incident.state_delta.risk), "seeded incident fixture should resolve an Old Road incident")
	_expect(incident.state_delta.loss_good_id == "medicine" and int(incident.state_delta.loss_unit_value) == 52, "incident result should preserve the disclosed loss basis")
	_expect(int(incident.state_delta.expected_loss) == 18, "incident result should preserve the disclosed expected loss")
	_expect(int(world.cargo.get("medicine", 0)) == 0 and int(world.cargo.get("water", 0)) == 2, "incident should remove the same exposed unit chosen by the forecast helper")
	_expect(incident.message.contains("lost 1 medicine worth 52 ashmarks"), "incident result should explain the unit and destination value lost")

	var replay_world := AshWorldState.new(3)
	replay_world.cargo = {"water": 2, "medicine": 1, "weight": 3}
	var replay := MarketCommandProcessor.execute(replay_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(JSON.stringify(replay) == JSON.stringify(incident), "equivalent seed, state, and departure should reproduce the same incident result")
	var restored_incident_world := AshWorldState.new(0)
	var restored_incident_result := restored_incident_world.load_serialized(world.serialize())
	_expect(restored_incident_result.ok, "incident state should survive save/load")
	_expect(restored_incident_world.command_history.back().state_delta.loss_good_id == "medicine", "save/load should preserve the resolved loss basis in command history")
	_expect(int(restored_incident_world.command_history.back().state_delta.loss_unit_value) == 52, "save/load should preserve the exposed unit value")

	var safe_world := AshWorldState.new(1)
	safe_world.cargo = {"water": 2, "weight": 2}
	var safe_departure := MarketCommandProcessor.execute(safe_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(safe_departure.ok and float(safe_departure.state_delta.risk_roll) >= float(safe_departure.state_delta.risk), "seeded safe fixture should resolve without an incident")
	_expect(safe_departure.state_delta.loss_good_id == "water" and int(safe_departure.state_delta.expected_loss) == 11, "non-incident result should retain the disclosed forecast basis")
	_expect(int(safe_world.cargo.get("water", 0)) == 2, "non-incident departure should preserve exposed cargo")

	var empty_world := AshWorldState.new(3)
	var empty_departure := MarketCommandProcessor.execute(empty_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(empty_departure.ok and int(empty_departure.state_delta.expected_loss) == 0, "zero-cargo departure should remain legal with zero expected loss")
	_expect(String(empty_departure.state_delta.loss_good_id).is_empty(), "zero-cargo departure should record no exposed good")

func _test_command_buy_and_sell() -> void:
	var world := AshWorldState.new(1107)
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "water", "quantity": 2},
	})
	_expect(buy.ok, "buy command should succeed for affordable cargo")
	_expect(world.cargo.get("water", 0) == 2, "buy command should add the requested cargo")
	_expect(world.cargo.get("weight", 0) == 2, "buy command should update cargo weight")
	_expect(int(buy.state_delta.money) < 0, "buy command should report money spent")
	_expect(buy.message.find("Bought 2 water") >= 0, "buy command should return a player-facing message")
	var money_after_buy := world.money
	var sell := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 2},
	})
	_expect(sell.ok, "sell command should succeed when cargo is held")
	_expect(world.money > money_after_buy, "sell command should add current settlement value")
	_expect(world.cargo.get("water", 0) == 0, "sell command should remove sold cargo")
	_expect(world.cargo.get("weight", 0) == 0, "sell command should reduce cargo weight")

func _test_market_memory() -> void:
	var world := AshWorldState.new(1107)
	world.current_settlement = "reedwatch"
	world.cargo = {"water": 4, "weight": 4}
	var destination := world.settlement("reedwatch")
	var before_price := MarketEconomy.price_for("water", destination, world.pricing_context())
	var sale := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 4},
	})
	_expect(sale.ok, "market-memory fixture sale should succeed")
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.16), "four-unit stage-zero delivery should add 16% supply pressure")
	_expect(is_equal_approx(float(sale.state_delta.market_memory.effective_impact), 0.16), "sale result should expose the effective pressure change")
	_expect(sale.message.contains("softened this market's water price pressure by 16%"), "sale result should explain the market-memory effect")
	var after_details := MarketEconomy.price_details("water", destination, world.pricing_context())
	_expect(int(after_details.unit_price) < before_price, "a completed delivery should soften the next local sale price")
	_expect(is_equal_approx(float(after_details.market_memory_modifier), 0.84), "price details should expose the bounded memory multiplier")
	_expect(after_details.reasons.has("your recent deliveries increased local supply"), "price details should explain recent-delivery pressure")
	var latest := world.latest_market_delivery("reedwatch", "water")
	_expect(int(latest.quantity) == 4 and int(latest.day) == 1, "latest delivery should retain visible quantity and day inputs")

	var pressure_before_buy := world.market_pressure_for("reedwatch", "water")
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "water", "quantity": 1},
	})
	_expect(buy.ok, "buy should remain legal after a delivery changes local pressure")
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), pressure_before_buy), "buying must not change local supply pressure")

	world.advance_day(1)
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.13), "one elapsed day should decay pressure by the authored amount")
	world.advance_day(20)
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.0), "market pressure should decay to but never below zero")

	var failed_world := AshWorldState.new(1107)
	failed_world.current_settlement = "reedwatch"
	var failed_sale := MarketCommandProcessor.execute(failed_world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 1},
	})
	_expect(not failed_sale.ok, "sale without cargo should fail")
	_expect(failed_world.market_pressure.is_empty() and failed_world.market_delivery_history.is_empty(), "failed sale should not write market memory")
	_expect(not failed_world.record_market_delivery("missing", "water", 1).ok, "unknown settlements should not receive market pressure")
	_expect(not failed_world.record_market_delivery("reedwatch", "missing", 1).ok, "unknown goods should not receive market pressure")

	var saturated_world := AshWorldState.new(1107)
	saturated_world.current_settlement = "reedwatch"
	saturated_world.cargo_capacity = 20
	saturated_world.cargo = {"water": 12, "weight": 12}
	for _index in range(3):
		var saturated_sale := MarketCommandProcessor.execute(saturated_world, {
			"id": MarketCommandProcessor.SELL_GOODS,
			"inputs": {"good_id": "water", "quantity": 4},
		})
		_expect(saturated_sale.ok, "repeated legal sales should succeed through the command boundary")
	_expect(is_equal_approx(saturated_world.market_pressure_for("reedwatch", "water"), 0.35), "repeated deliveries should clamp at the authored pressure maximum")
	for _index in range(13):
		saturated_world.record_market_delivery("reedwatch", "grain", 1)
	_expect(saturated_world.market_delivery_history.size() == 12, "delivery history should remain bounded to the authored limit")

	var crisis_world := AshWorldState.new(1107)
	crisis_world.current_settlement = "reedwatch"
	crisis_world.crisis_stage = 2
	crisis_world._update_crisis_modifiers()
	crisis_world.cargo = {"water": 4, "weight": 4}
	var crisis_sale := MarketCommandProcessor.execute(crisis_world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 4},
	})
	_expect(crisis_sale.ok, "crisis delivery should succeed")
	_expect(is_equal_approx(crisis_world.market_pressure_for("reedwatch", "water"), 0.112), "stage-two crisis should reduce delivery effectiveness without changing the pressure formula")

	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(crisis_world.serialize())
	_expect(restore_result.ok and is_equal_approx(restored.market_pressure_for("reedwatch", "water"), 0.112), "save/load should preserve market pressure")
	_expect(restored.latest_market_delivery("reedwatch", "water") == crisis_world.latest_market_delivery("reedwatch", "water"), "save/load should preserve visible delivery memory")

func _test_command_validation_and_history() -> void:
	var world := AshWorldState.new(1107)
	var money_before := world.money
	var invalid := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "unknown", "quantity": 1},
	})
	_expect(not invalid.ok, "buy command should reject unknown goods")
	_expect(world.money == money_before, "rejected command should not mutate money")
	_expect(world.command_history.size() == 1, "command history should record rejected commands")
	_expect(not bool(world.command_history[0].ok), "rejected command history should preserve failure state")
	var unknown := MarketCommandProcessor.execute(world, {"id": "invent_profit", "inputs": {}})
	_expect(not unknown.ok, "processor should reject unsupported commands")
	_expect(world.command_history.size() == 2, "unsupported commands should also be recorded")

func _test_depart_command() -> void:
	var world := AshWorldState.new(1107)
	var money_before := world.money
	var provisions_before := world.provisions
	var blocked := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "brine_cross"},
	})
	_expect(not blocked.ok, "depart command should reject a destination outside the authored route endpoints")
	_expect(blocked.reason.find("does not connect") >= 0, "blocked departure should explain the route-endpoint mismatch")
	_expect(world.current_settlement == "ashgate", "blocked departure should not move the caravan")
	_expect(world.money == money_before, "blocked departure should not charge the route cost")
	_expect(world.provisions == provisions_before, "blocked departure should not consume provisions")
	_expect(world.command_history.size() == 1 and not world.command_history.back().ok, "blocked departure should be recorded as a failed command")
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(depart.ok, "depart command should allow an authored route endpoint")
	_expect(world.current_settlement == "reedwatch", "depart command should move the caravan to the connected endpoint")
	_expect(world.money == money_before - 4, "depart command should charge the route cost")
	_expect(world.provisions == provisions_before - 1, "depart command should consume route provisions")
	_expect(depart.state_delta.get("route_id", "") == "old_road", "depart command should identify the resolved route")
	_expect(world.command_history.back().id == MarketCommandProcessor.DEPART_ROUTE, "departure should be recorded with a stable command id")

func _test_travel_consumes_resources() -> void:
	var world := AshWorldState.new(1107)
	var money_before := world.money
	var provisions_before := world.provisions
	var result := world.travel("old_road")
	_expect(result.ok, "old road travel should succeed from the starting state")
	_expect(world.money == money_before - 4, "travel should charge route cost")
	_expect(world.provisions == provisions_before - 1, "travel should consume route provisions")

func _test_save_round_trip() -> void:
	var world := AshWorldState.new(42)
	world.money = 77
	world.crisis_stage = 2
	world._update_crisis_modifiers()
	var command := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "grain", "quantity": 1},
	})
	_expect(command.ok, "save fixture purchase should succeed")
	world.money = 77
	var restored := AshWorldState.new(0)
	var restored_result := restored.load_serialized(world.serialize())
	_expect(restored_result.ok, "current-version save should load")
	_expect(restored.seed == 42, "save should preserve seed")
	_expect(restored.money == 77, "save should preserve money")
	_expect(restored.crisis_stage == 2, "save should preserve crisis stage")
	_expect(restored.command_history.size() == 1, "save should preserve command history")
	_expect(restored.serialize().save_version == AshWorldState.SAVE_VERSION, "serialized state should declare the current save version")
	_expect(restored.serialize().content_version == "0.5.0", "serialized state should declare the content version")

func _test_legacy_save_migration() -> void:
	var legacy_world := AshWorldState.new(42)
	var legacy_save := legacy_world.serialize()
	legacy_save.erase("save_version")
	legacy_save.erase("content_version")
	legacy_save.erase("command_history")
	legacy_save.erase("market_pressure")
	legacy_save.erase("market_delivery_history")
	var migrated := AshWorldState.new(0)
	var migration_result := migrated.load_serialized(legacy_save)
	_expect(migration_result.ok, "legacy save without version metadata should migrate")
	_expect(int(migration_result.migrated_from) == 0, "legacy save should report its source version")
	_expect(migrated.command_history.is_empty(), "legacy save migration should initialize empty command history")
	_expect(migrated.market_pressure.is_empty() and migrated.market_delivery_history.is_empty(), "legacy save migration should initialize empty market memory")
	var version_one_save := legacy_world.serialize()
	version_one_save["save_version"] = 1
	version_one_save.erase("market_pressure")
	version_one_save.erase("market_delivery_history")
	var migrated_v1 := AshWorldState.new(0)
	var migration_v1_result := migrated_v1.load_serialized(version_one_save)
	_expect(migration_v1_result.ok and int(migration_v1_result.migrated_from) == 1, "version-one saves should migrate to the market-memory schema")
	_expect(migrated_v1.serialize().save_version == 2, "version-one migration should produce save version two")
	var future_save := legacy_world.serialize()
	future_save["save_version"] = AshWorldState.SAVE_VERSION + 1
	var rejected := AshWorldState.new(0).load_serialized(future_save)
	_expect(not rejected.ok, "future save versions should be rejected safely")
