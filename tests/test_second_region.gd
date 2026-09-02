extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_region_manifest_and_route_choice()
	_test_ordinary_trade_and_event_replay()
	_test_emberglass_trade_and_changed_market_restore()
	_test_contract_path()
	_test_failure_forward_path()
	if failures.is_empty():
		print("Second region smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_region_manifest_and_route_choice() -> void:
	var region := MarketContent.regions().get("glasswind_reach", {}) as Dictionary
	var route_ids: Array = region.get("route_ids", [])
	_expect((region.get("settlement_ids", []) as Array).size() == 3, "Glasswind Reach should contain three authored settlements")
	_expect(route_ids.size() == 3 and route_ids.has("glasswind_trace") and route_ids.has("mirror_run") and route_ids.has("emberglass_byway"), "Glasswind Reach should expose three distinct routes")
	var byway := MarketContent.route("emberglass_byway")
	_expect(byway.get("endpoints", []) == ["kiln_rest", "mirror_wells"], "the Emberglass Byway should close the regional triangle")
	_expect(int(byway.get("cost", 0)) == 2 and int(byway.get("days", 0)) == 1 and is_equal_approx(float(byway.get("risk", 0.0)), 0.58), "the byway should state its cheap, fast, high-risk terms")
	var trace_leg := MarketContent.route_segment("glasswind_trace", "kiln_rest", "sunfall_exchange")
	var mirror_leg := MarketContent.route("mirror_run")
	_expect(int(byway.get("cost", 0)) < int(trace_leg.get("cost", 0)) + int(mirror_leg.get("cost", 0)) and int(byway.get("days", 0)) < int(trace_leg.get("days", 0)) + int(mirror_leg.get("days", 0)), "the direct byway should save money and time against the licensed two-leg road")
	_expect(float(byway.get("risk", 0.0)) > maxf(float(trace_leg.get("risk", 0.0)), float(mirror_leg.get("risk", 0.0))), "the direct byway should disclose more cargo exposure than either licensed leg")
	for settlement_id in region.get("settlement_ids", []):
		var exits := 0
		for route_id in route_ids:
			if MarketContent.routes_from(String(settlement_id)).has(String(route_id)):
				exits += 1
		_expect(exits >= 2, "%s should have two local route choices" % settlement_id)

func _test_ordinary_trade_and_event_replay() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "sunfall_exchange"
	world.day = 5
	world._update_crisis_modifiers()
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "lamp_oil", "quantity": 3}), "buy ordinary lamp oil")
	var departure := _command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "mirror_run", "destination_id": "mirror_wells"})
	_expect_ok(departure, "depart on the Mirror Run")
	_expect(world.pending_event.get("id", "") == "shardwind_tithe", "the named seed should pause at the Glasswind event")
	var pending_save := world.serialize()
	var resumed := AshWorldState.new(0)
	_expect_ok(resumed.load_serialized(pending_save), "resume the pending Glasswind event")
	_expect(resumed.pending_event == world.pending_event and resumed.current_settlement == "sunfall_exchange", "event replay should restore its frozen choice state and origin")
	_expect_ok(_command(resumed, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "shardwind_tithe", "choice_id": "shelter_behind_cairns"}), "take the no-loss recovery response")
	_expect(resumed.current_settlement == "mirror_wells" and resumed.known_information.has("glasswind_shelter_cairns"), "the recovery response should arrive and preserve useful route information")
	var money_before_sale := resumed.money
	_expect_ok(_command(resumed, MarketCommandProcessor.SELL_GOODS, {"good_id": "lamp_oil", "quantity": 3}), "sell lamp oil through the ordinary market")
	_expect(resumed.money > money_before_sale and resumed.money > 120, "the ordinary second-region loop should finish profitably without a contract")
	_expect(resumed.money >= 0 and resumed.provisions >= 0 and int(resumed.cargo.get("weight", 0)) <= resumed.cargo_capacity, "the region journey should preserve resource invariants")

func _test_emberglass_trade_and_changed_market_restore() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "kiln_rest"
	world.day = 5
	world._update_crisis_modifiers()
	var kiln := world.settlement("kiln_rest")
	var mirror := world.settlement("mirror_wells")
	var base_context := {"crisis_modifiers": world.crisis_modifiers, "market_pressure": {}, "adaptive_market_modifiers": {}}
	_expect(MarketEconomy.price_for("lamp_oil", mirror, base_context) > MarketEconomy.price_for("lamp_oil", kiln, base_context), "lamp oil should support an ordinary Kiln Rest to Mirror Wells trade")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "lamp_oil", "quantity": 3}), "buy lamp oil for the direct byway")
	var money_after_purchase := world.money
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "emberglass_byway", "destination_id": "mirror_wells"}), "depart on the Emberglass Byway")
	_expect(world.pending_event.get("id", "") == "shardwind_tithe", "the seeded byway run should pause at its recoverable event family")
	var pending_restore := AshWorldState.new(0)
	_expect_ok(pending_restore.load_serialized(world.serialize()), "restore the byway at the pending event")
	_expect_ok(_command(pending_restore, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "shardwind_tithe", "choice_id": "shelter_behind_cairns"}), "trade one day for a no-loss byway recovery")
	_expect(pending_restore.current_settlement == "mirror_wells" and int(pending_restore.cargo.get("lamp_oil", 0)) == 3, "the shelter response should deliver the complete ordinary cargo")
	_expect_ok(_command(pending_restore, MarketCommandProcessor.SELL_GOODS, {"good_id": "lamp_oil", "quantity": 3}), "sell the byway lamp oil")
	_expect(pending_restore.money > money_after_purchase and pending_restore.money > 120, "the direct byway sale should finish profitably without contract rewards")
	_expect(float(pending_restore.market_pressure.get("mirror_wells", {}).get("lamp_oil", 0.0)) > 0.0, "the ordinary sale should change the destination market")
	var changed_market_restore := AshWorldState.new(0)
	_expect_ok(changed_market_restore.load_serialized(pending_restore.serialize()), "restore after the changed destination market")
	_expect(changed_market_restore.market_pressure == pending_restore.market_pressure and changed_market_restore.command_history == pending_restore.command_history, "save/load should preserve the byway trade and its market memory")

func _test_contract_path() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "sunfall_exchange"
	world.day = 5
	world._update_crisis_modifiers()
	_expect_ok(_command(world, MarketCommandProcessor.ACCEPT_CONTRACT, {"contract_id": "mirror_wells_lamp_relief_01"}), "accept the optional beacon-oil contract")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "lamp_oil", "quantity": 3}), "buy the contracted oil")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "mirror_run", "destination_id": "mirror_wells"}), "depart with contracted oil")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "shardwind_tithe", "choice_id": "buy_wind_lane_seal"}), "buy the licensed wind lane")
	_expect(world.contract_history.any(func(outcome: Dictionary) -> bool: return outcome.get("id", "") == "mirror_wells_lamp_relief_01" and outcome.get("status", "") == "completed"), "arrival should complete the optional second-region contract")
	_expect(int(world.reputation.get("glass_consortium", 0)) == 2, "the contract and licensed event response should build visible Consortium standing")
	_expect(world.current_settlement == "mirror_wells" and world.active_contracts.is_empty(), "the contract path should end at a usable destination market")

func _test_failure_forward_path() -> void:
	var world := AshWorldState.new(7)
	world.advance_day(7)
	_expect(world.scenario_state("mirror_wells_beacon_oil").get("state", "") == "expired", "ignoring beacon oil through Day 8 should expire the official offer")
	_expect(not world.emergent_faction("night_market").is_empty(), "the failed official offer should activate the Night Market")
	_expect(world.resilience_for("mirror_wells") == 1, "the replacement market should strengthen Mirror Wells instead of soft-locking it")
	var mirror := world.settlement("mirror_wells")
	var base_context := {"crisis_modifiers": world.crisis_modifiers, "market_pressure": {}, "adaptive_market_modifiers": {}}
	var adaptive_context := world.pricing_context()
	_expect(MarketEconomy.price_for("saltglass", mirror, adaptive_context) > MarketEconomy.price_for("saltglass", mirror, base_context), "the Night Market should create its authored ordinary-trade saltglass premium")
	world.current_settlement = "mirror_wells"
	world.cargo = {"lamp_oil": 2, "weight": 2}
	world.reset_visit_slots()
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mirror_wells_night_beacons"}), "support the replacement beacon network")
	_expect(world.resilience_for("mirror_wells") == 2 and int(world.emergent_faction("night_market").get("support", 0)) == 1, "Night Market support should change durable local state")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "save the failure-forward second-region state")
	_expect(restored.scenario_state("mirror_wells_beacon_oil").get("state", "") == "expired" and int(restored.emergent_faction("night_market").get("support", 0)) == 1, "save/load should preserve the replacement actor and support")

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, context: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [context, String(result.get("message", "command failed"))])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
