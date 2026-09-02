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
	_test_emberfen_ordinary_trade_event_and_contract()
	_test_emberfen_failure_forward_opportunity()
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
	var emberfen: Dictionary = MarketContent.settlements().get("emberfen_refuge", {})
	var region: Dictionary = MarketContent.region("siltfire_march")
	var context := {"crisis_modifiers": {}, "market_pressure": {}, "adaptive_market_modifiers": {}}
	_expect(MarketEconomy.price_for("medicine", mothlight, context) < MarketEconomy.price_for("medicine", blackreed, context), "medicine should have a clear Mothlight-to-Blackreed spread")
	_expect(MarketEconomy.price_for("grain", blackreed, context) < MarketEconomy.price_for("grain", mothlight, context), "grain should have a clear Blackreed-to-Mothlight return spread")
	_expect(MarketContent.route_connects("salt_causeway", "brine_cross", "mothlight_quay"), "the Salt Causeway should connect the March to Brine Cross")
	_expect(MarketContent.route_connects("reedline_track", "blackreed_post", "reedwatch"), "the Reedline should connect the March to Reedwatch")
	_expect(MarketContent.route_connects("emberfen_drift", "mothlight_quay", "emberfen_refuge"), "the Emberfen Drift should open the March's third market")
	_expect(region.get("settlement_ids", []).size() == 3 and region.get("route_ids", []).size() == 3, "Siltfire March should contain three settlements and three roads")
	_expect(mothlight.get("identity", {}).get("landmark", "") == "quay" and blackreed.get("identity", {}).get("landmark", "") == "watchtower" and emberfen.get("identity", {}).get("landmark", "") == "peat_stacks", "all three March settlements should expose distinct authored landmarks")

func _test_emberfen_ordinary_trade_event_and_contract() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "mothlight_quay"
	var opening_money := world.money
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "cloth", "quantity": 3}), "buy ordinary smoke cloth")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "emberfen_drift", "destination_id": "emberfen_refuge"}), "depart for Emberfen")
	_expect(world.pending_event.get("id", "") == "emberfen_smoke_crossing", "the named seed should reach the authored Emberfen smoke event")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "emberfen_smoke_crossing", "choice_id": "hire_smoke_bell"}), "hire the Bellkeeper at the smoke crossing")
	_expect(world.current_settlement == "emberfen_refuge" and int(world.reputation.get("bellkeepers", 0)) == 1, "the Bellkeeper response should arrive and expose regional faction pressure")
	_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "cloth", "quantity": 3}), "sell ordinary cloth at Emberfen")
	_expect(world.money > opening_money, "the ordinary Mothlight-to-Emberfen trade should remain profitable without a contract")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "restore the completed Emberfen ordinary route")
	_expect(restored.current_settlement == "emberfen_refuge" and restored.has_resolved_event("emberfen_smoke_crossing"), "save/load should preserve Emberfen arrival and event history")

	var contract_world := AshWorldState.new(1)
	contract_world.current_settlement = "mothlight_quay"
	_expect_ok(_command(contract_world, MarketCommandProcessor.ACCEPT_CONTRACT, {"contract_id": "emberfen_smoke_cloth_01"}), "accept the optional Emberfen smoke-cloth contract")
	_expect_ok(_command(contract_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "cloth", "quantity": 3}), "buy the optional contract cargo")
	_expect_ok(_command(contract_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "emberfen_drift", "destination_id": "emberfen_refuge"}), "depart on the optional contract")
	_expect_ok(_command(contract_world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "emberfen_smoke_crossing", "choice_id": "hire_smoke_bell"}), "resolve the contract road contact")
	_expect(contract_world.contract_history.any(func(outcome: Dictionary) -> bool: return outcome.get("id", "") == "emberfen_smoke_cloth_01" and outcome.get("status", "") == "completed"), "arrival should complete the optional smoke-cloth contract")

func _test_emberfen_failure_forward_opportunity() -> void:
	var world := AshWorldState.new(9)
	world.advance_day(8)
	_expect(world.scenario_state("emberfen_smoke_ward").get("state", "") == "expired", "ignoring the Emberfen contract through Day 9 should expire the official offer")
	_expect(not world.emergent_faction("ash_sifters").is_empty(), "the missed smoke ward should create the Ash Sifters replacement actor")
	_expect(world.resilience_for("emberfen_refuge") == 1, "the replacement actor should keep Emberfen playable instead of removing access")
	var emberfen := world.settlement("emberfen_refuge")
	var base_context := {"crisis_modifiers": world.crisis_modifiers, "market_pressure": {}, "adaptive_market_modifiers": {}}
	_expect(MarketEconomy.price_for("charcoal", emberfen, world.pricing_context()) > MarketEconomy.price_for("charcoal", emberfen, base_context), "the Ash Sifters should create a new ordinary charcoal premium")
	world.current_settlement = "emberfen_refuge"
	world.cargo = {"charcoal": 2, "weight": 2}
	world.reset_visit_slots()
	var risk_before := float(world.route("emberfen_drift").get("risk", 0.0))
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "emberfen_sifter_kiln"}), "fund the post-consequence Ash Sifter kiln")
	_expect(int(world.emergent_faction("ash_sifters").get("support", 0)) == 1 and world.resilience_for("emberfen_refuge") == 2, "the post-consequence opportunity should build replacement legitimacy and local resilience")
	_expect(float(world.route("emberfen_drift").get("risk", 1.0)) < risk_before, "the post-consequence opportunity should leave a durable road improvement")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "restore the Ash Sifter consequence state")
	_expect(restored.scenario_state("emberfen_smoke_ward").get("state", "") == "expired" and int(restored.emergent_faction("ash_sifters").get("support", 0)) == 1, "save/load should preserve the replacement actor and its post-consequence support")

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, context: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [context, String(result.get("message", "command failed"))])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
