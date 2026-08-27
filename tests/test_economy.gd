extends SceneTree

const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_base_prices()
	_test_regional_price_spread()
	_test_crisis_changes_water_price()
	_test_capacity_validation()
	_test_travel_consumes_resources()
	_test_save_round_trip()
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
	var projected := MarketEconomy.projected_profit("scrap", 2, origin, destination, world)
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
	var restored := AshWorldState.new(0)
	restored.load_serialized(world.serialize())
	_expect(restored.seed == 42, "save should preserve seed")
	_expect(restored.money == 77, "save should preserve money")
	_expect(restored.crisis_stage == 2, "save should preserve crisis stage")
