extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_ordinary_trade_both_directions()
	_test_whiteout_recovery_and_mitigation_save()
	_test_region_topology_and_identity()
	if failures.is_empty():
		print("Third region smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_ordinary_trade_both_directions() -> void:
	var world := AshWorldState.new(2)
	world.current_settlement = "mothlight_quay"
	var opening_money := world.money
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 3}), "buy Mothlight medicine")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "reedline_track", "destination_id": "blackreed_post"}), "carry medicine down the Reedline")
	_expect(world.pending_event.is_empty() and world.current_settlement == "blackreed_post", "ordinary Reedline trade should reach Blackreed without a scripted encounter")
	_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "medicine", "quantity": 3}), "sell medicine at Blackreed")
	var outbound_money := world.money
	_expect(outbound_money > opening_money, "Mothlight medicine should cover purchase and Reedline travel through ordinary trade")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "grain", "quantity": 4}), "buy Blackreed grain")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "reedline_track", "destination_id": "mothlight_quay"}), "return grain to Mothlight")
	_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "grain", "quantity": 4}), "sell grain at Mothlight")
	_expect(world.money > outbound_money, "Blackreed grain should fund a profitable ordinary return journey")
	_expect(world.money >= 0 and world.provisions >= 0 and int(world.cargo.get("weight", 0)) <= world.cargo_capacity, "the two-way March loop should preserve resource invariants")

func _test_whiteout_recovery_and_mitigation_save() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "brine_cross"
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 2}), "prepare valuable cargo for the causeway")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "salt_causeway", "destination_id": "mothlight_quay"}), "depart across the Salt Causeway")
	_expect(world.pending_event.get("id", "") == "causeway_whiteout", "the named seed should pause at the authored whiteout")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "causeway_whiteout", "choice_id": "wait_on_salt_island"}), "take the no-loss whiteout recovery")
	_expect(world.current_settlement == "mothlight_quay" and world.known_information.has("causeway_salt_islands"), "the recovery choice should arrive and preserve useful causeway knowledge")
	var base_risk := float(world.route("salt_causeway").get("risk", 0.0))
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mothlight_bell_chart"}), "chart the Mothlight bells")
	_expect(float(world.route("salt_causeway").get("risk", 1.0)) < base_risk, "the bell chart should visibly reduce Salt Causeway risk")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "resume after charting the causeway")
	_expect(restored.known_information.has("salt_causeway_bell_chart") and float(restored.route("salt_causeway").get("risk", 1.0)) == float(world.route("salt_causeway").get("risk", 0.0)), "save/load should preserve the March route mitigation")

func _test_region_topology_and_identity() -> void:
	var mothlight: Dictionary = MarketContent.settlements().get("mothlight_quay", {})
	var blackreed: Dictionary = MarketContent.settlements().get("blackreed_post", {})
	var context := {"crisis_modifiers": {}, "market_pressure": {}, "adaptive_market_modifiers": {}}
	_expect(MarketEconomy.price_for("medicine", mothlight, context) < MarketEconomy.price_for("medicine", blackreed, context), "medicine should have a clear Mothlight-to-Blackreed spread")
	_expect(MarketEconomy.price_for("grain", blackreed, context) < MarketEconomy.price_for("grain", mothlight, context), "grain should have a clear Blackreed-to-Mothlight return spread")
	_expect(MarketContent.route_connects("salt_causeway", "brine_cross", "mothlight_quay"), "the Salt Causeway should connect the March to Brine Cross")
	_expect(MarketContent.route_connects("reedline_track", "blackreed_post", "reedwatch"), "the Reedline should connect the March to Reedwatch")
	_expect(mothlight.get("identity", {}).get("landmark", "") == "quay" and blackreed.get("identity", {}).get("landmark", "") == "watchtower", "both March settlements should expose distinct authored landmarks")

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, context: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [context, String(result.get("message", "command failed"))])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
