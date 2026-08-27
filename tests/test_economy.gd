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
	_test_command_buy_and_sell()
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
	_expect(MarketContent.content_version() == "0.4.0", "runtime content should expose content version")
	_expect(MarketContent.good_ids() == ["grain", "water", "scrap", "medicine", "charcoal", "cloth"], "runtime content should expose authored stable good ids")
	_expect(MarketContent.settlements().size() == 5, "runtime content should expose five settlements")
	_expect(MarketContent.routes().size() == 3, "runtime content should expose three routes")

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
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "brine_cross"},
	})
	_expect(depart.ok, "depart command should allow a valid route and destination")
	_expect(world.current_settlement == "brine_cross", "depart command should move the caravan after successful travel")
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
	_expect(restored.serialize().content_version == "0.4.0", "serialized state should declare the content version")

func _test_legacy_save_migration() -> void:
	var legacy_world := AshWorldState.new(42)
	var legacy_save := legacy_world.serialize()
	legacy_save.erase("save_version")
	legacy_save.erase("content_version")
	legacy_save.erase("command_history")
	var migrated := AshWorldState.new(0)
	var migration_result := migrated.load_serialized(legacy_save)
	_expect(migration_result.ok, "legacy save without version metadata should migrate")
	_expect(int(migration_result.migrated_from) == 0, "legacy save should report its source version")
	_expect(migrated.command_history.is_empty(), "legacy save migration should initialize empty command history")
	var future_save := legacy_world.serialize()
	future_save["save_version"] = AshWorldState.SAVE_VERSION + 1
	var rejected := AshWorldState.new(0).load_serialized(future_save)
	_expect(not rejected.ok, "future save versions should be rejected safely")
