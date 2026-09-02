extends SceneTree

const AshWorldState = preload("res://src/core/world_state.gd")
const MarketContent = preload("res://src/core/market_content.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

var failures: Array[String] = []

func _init() -> void:
	var world := AshWorldState.new(1107)

	_expect_ok(_command(world, MarketCommandProcessor.ACCEPT_CONTRACT, {"contract_id": "reedwatch_water_relief_01"}), "accept the Reedwatch relief contract")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "water", "quantity": 4}), "buy the contract water")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "begin the first Reedwatch delivery")
	_expect(world.pending_event.get("id", "") == "three_riders_no_banner", "the seeded first delivery should pause at Three Riders, No Banner")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "three_riders_no_banner", "choice_id": "pay_for_escort"}), "pay for the first delivery escort")
	_expect(world.current_settlement == "reedwatch", "the escorted relief run should arrive at Reedwatch")
	_expect(_contract_status(world, "reedwatch_water_relief_01") == "completed", "arrival should complete the relief contract through normal command resolution")
	_expect(int(world.cargo.get("water", 0)) == 0, "the completed contract should consume all four committed water units")

	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "return to Ashgate for a public water load")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "water", "quantity": 2}), "buy two public-reserve water units")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "make the first shortage-stage water attempt")
	_expect(world.pending_event.is_empty() and world.current_settlement == "reedwatch", "the seeded day-four attempt should arrive without forcing the barrel event")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "preserve the water while resetting the approach")
	_expect(int(world.cargo.get("water", 0)) == 2, "the safe return should preserve both public-reserve water units")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "make the seeded public-reserve delivery")
	_expect(world.pending_event.get("id", "") == "last_clean_barrel", "the seeded day-six delivery should pause at The Last Clean Barrel")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "last_clean_barrel", "choice_id": "share_barrels_fairly"}), "share the barrels through the public queue")
	_expect(world.resilience_for("reedwatch") == 2, "the public queue choice should establish the required Reedwatch resilience")
	_expect(int(world.cargo.get("water", 0)) == 0, "the public queue should receive both water units")

	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "return to the hub on day seven")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "brine_cross"}), "cross to Brine Cross on day eight")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "ashgate"}), "return from Brine Cross on day nine")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "reach the settlement decision on day ten")

	_expect(world.day == 10 and world.crisis_stage == 3, "the command-only campaign should reach the authored day-ten crisis stage")
	_expect(world.ending_id == "open_routes_relief", "the completed relief and resilience path should reach Open Routes, Shared Wells")
	_expect(world.arms_escalation == 0, "the relief campaign should finish without arms escalation")
	_expect(world.command_history.size() == 15, "the campaign should preserve every player command in deterministic history")

	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(world.serialize())
	_expect(restore_result.ok, "the completed campaign should survive save/load")
	_expect(restored.ending_id == world.ending_id and restored.day == world.day and restored.current_settlement == world.current_settlement, "the restored campaign should preserve its ending, time, and location")
	_expect(restored.command_history == world.command_history and restored.contract_history == world.contract_history, "the restored campaign should preserve its command and contract evidence")
	var canonical_restore := AshWorldState.new(0)
	var canonical_result := canonical_restore.load_serialized(restored.serialize())
	_expect(canonical_result.ok and JSON.stringify(canonical_restore.serialize()) == JSON.stringify(restored.serialize()), "a normalized campaign save should remain stable across another load")

	var warden_world := AshWorldState.new(1107)
	_expect_ok(_command(warden_world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_provision_bundle"}), "earn initial Warden standing through logistics")
	_expect_ok(_command(warden_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 2}), "buy a valuable regulated-road cargo")
	_expect_ok(_command(warden_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "brine_cross"}), "take medicine through the Toll Road")
	_expect(warden_world.pending_event.get("id", "") == "gatekeepers_chalk", "the regulated campaign should encounter the Gatekeeper's Chalk")
	_expect_ok(_command(warden_world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "gatekeepers_chalk", "choice_id": "pay_posted_toll"}), "pay the posted Warden toll")
	_expect_ok(_command(warden_world, MarketCommandProcessor.SELL_GOODS, {"good_id": "medicine", "quantity": 2}), "sell the medicine at Brine Cross")
	_expect_ok(_command(warden_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "ashgate"}), "return to Ashgate under Warden oversight")
	_expect_ok(_command(warden_world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_provision_bundle"}), "cross the recognized-carrier threshold")
	_expect(int(warden_world.reputation.get("wardens", 0)) == 3 and int(warden_world.reputation.get("caravans", 0)) == 0, "the regulated path should establish its distinct faction state")
	var route_targets := ["reedwatch", "ashgate", "reedwatch", "ashgate", "reedwatch", "ashgate", "reedwatch"]
	for destination_id in route_targets:
		_expect_ok(_command(warden_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": destination_id}), "advance the regulated campaign toward day ten")
	_expect(warden_world.day == 10 and warden_world.crisis_stage == 3, "the regulated campaign should reach the settlement-decision stage")
	_expect(warden_world.ending_id == "ending_warden_reserve", "the high-Warden strategy should reach Order at the Cistern")
	_expect(warden_world.ending_id != world.ending_id, "the two fresh command paths should produce distinct campaign conclusions")
	_expect(warden_world.ending_summary.contains("predictable access") and warden_world.ending_summary.contains("regulated margins"), "the regulated ending should explain access and trade-style consequences")

	var caravan_world := AshWorldState.new(3)
	_expect_ok(_command(caravan_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 2}), "buy cargo for the independent-route opening")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "take the exposed road for route information")
	_expect(caravan_world.pending_event.get("id", "") == "three_riders_no_banner", "the independent-route campaign should encounter the unmarked riders")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "three_riders_no_banner", "choice_id": "wait_and_read_the_tracks"}), "trade time for public route information")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.SELL_GOODS, {"good_id": "medicine", "quantity": 2}), "sell the medicine after preserving the route lead")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "return for a public water shipment")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "water", "quantity": 2}), "buy water for the public queue")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "deliver water during the shortage")
	_expect(caravan_world.pending_event.get("id", "") == "last_clean_barrel", "the seeded independent-route delivery should reach The Last Clean Barrel")
	_expect_ok(_command(caravan_world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "last_clean_barrel", "choice_id": "share_barrels_fairly"}), "share water through the public queue")
	_expect(int(caravan_world.reputation.get("caravans", 0)) == 2 and int(caravan_world.reputation.get("wardens", 0)) == 0, "the independent route should cross its distinct Caravan threshold")
	var caravan_targets := ["ashgate", "brine_cross", "ashgate", "reedwatch", "ashgate"]
	var caravan_routes := ["old_road", "toll_road", "toll_road", "old_road", "old_road"]
	for index in range(caravan_targets.size()):
		_expect_ok(_command(caravan_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": caravan_routes[index], "destination_id": caravan_targets[index]}), "advance the independent-route campaign toward day ten")
	_expect(caravan_world.day == 10 and caravan_world.crisis_stage == 3, "the independent-route campaign should reach the settlement-decision stage")
	_expect(caravan_world.ending_id == "ending_free_caravan_routes", "the information-and-public-supply strategy should reach No Road Owns the Sky")
	_expect(caravan_world.ending_id != world.ending_id and caravan_world.ending_id != warden_world.ending_id, "all three fresh campaign strategies should produce distinct conclusions")
	_expect(caravan_world.ending_summary.contains("volatile margins") and caravan_world.ending_summary.contains("public information"), "the independent ending should explain access and trade-style consequences")

	var merchant_world := AshWorldState.new(1)
	_expect_ok(_command(merchant_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 3}), "buy the first merchant medicine load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "take the first merchant run")
	_expect(merchant_world.pending_event.is_empty(), "the seeded first merchant run should arrive without a route decision")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.SELL_GOODS, {"good_id": "medicine", "quantity": 3}), "sell the first medicine load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "return for the second merchant load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 3}), "buy the second merchant medicine load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "take the second merchant run")
	_expect(merchant_world.pending_event.get("id", "") == "three_riders_no_banner", "the second merchant run should encounter the unmarked riders")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "three_riders_no_banner", "choice_id": "pay_for_escort"}), "protect the second merchant load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.SELL_GOODS, {"good_id": "medicine", "quantity": 3}), "sell the second medicine load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "return for the scarcity trade")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.BUY_GOODS, {"good_id": "water", "quantity": 3}), "buy the merchant water load")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "take water into the shortage")
	_expect(merchant_world.pending_event.get("id", "") == "last_clean_barrel", "the merchant water run should reach The Last Clean Barrel")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "last_clean_barrel", "choice_id": "sell_barrels_at_peak"}), "take the emergency water premium")
	_expect_ok(_command(merchant_world, MarketCommandProcessor.SELL_GOODS, {"good_id": "water", "quantity": 1}), "sell the remaining water through the ordinary market")
	_expect(merchant_world.money >= 220 and merchant_world.resilience_for("reedwatch") == 1 and not merchant_world.emergent_faction("well_commons").is_empty(), "the profit-first strategy should establish its distinct ending state after leaving relief to the Well Commons")
	var merchant_targets := ["ashgate", "brine_cross", "ashgate", "reedwatch"]
	var merchant_routes := ["old_road", "toll_road", "toll_road", "old_road"]
	for index in range(merchant_targets.size()):
		_expect_ok(_command(merchant_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": merchant_routes[index], "destination_id": merchant_targets[index]}), "advance the merchant campaign toward day ten")
	_expect(merchant_world.day == 10 and merchant_world.crisis_stage == 3, "the merchant campaign should reach the settlement-decision stage")
	_expect(merchant_world.ending_id == "ending_ash_merchant", "the profit-first strategy should reach The Best Margin")
	_expect(merchant_world.ending_summary.contains("concentrated profit") and merchant_world.ending_summary.contains("public reserve remains fragile"), "the merchant ending should explain its supply and trade-style consequences")

	var tour_world := AshWorldState.new(1107)
	var visited := {"ashgate": true}
	var tour_destinations := ["cinderford", "brine_cross", "ashgate", "reedwatch", "hollow_market", "sunfall_exchange", "kiln_rest", "sunfall_exchange", "mirror_wells"]
	var tour_routes := ["toll_road", "toll_road", "toll_road", "old_road", "dry_cut", "glasswind_trace", "glasswind_trace", "glasswind_trace", "mirror_run"]
	for index in range(tour_destinations.size()):
		var tour_result := _command(tour_world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": tour_routes[index], "destination_id": tour_destinations[index]})
		_expect_ok(tour_result, "reach %s during the eight-settlement tour" % tour_destinations[index])
		if tour_result.ok:
			visited[tour_world.current_settlement] = true
	_expect(visited.size() == 8 and tour_world.current_settlement == "mirror_wells", "the authored five-route graph should make all eight settlements reachable from a fresh save")
	_expect(tour_world.money >= 0 and tour_world.provisions >= 0, "the empty-cargo eight-settlement tour should not soft-lock on route resources")

	var fresh_ashgate := AshWorldState.new(1107)
	var loaded_exposed_route := AshWorldState.new(1107)
	_expect_ok(_command(loaded_exposed_route, MarketCommandProcessor.BUY_GOODS, {"good_id": "medicine", "quantity": 2}), "prepare the exposed-route fixture")
	_expect_ok(_command(loaded_exposed_route, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "brine_cross"}), "trigger the exposed-route fixture")
	loaded_exposed_route.money = 0
	loaded_exposed_route.provisions = 0
	var low_provisions := AshWorldState.new(1107)
	low_provisions.money = 6
	low_provisions.provisions = 0
	var saturated_reedwatch := AshWorldState.new(1107)
	saturated_reedwatch.current_settlement = "reedwatch"
	saturated_reedwatch.money = 0
	saturated_reedwatch.provisions = 0
	saturated_reedwatch.cargo["grain"] = 2
	saturated_reedwatch.cargo["weight"] = 2
	saturated_reedwatch.record_market_delivery("reedwatch", "grain", 6)
	var active_contract_deadline := AshWorldState.new(1107)
	_expect_ok(_command(active_contract_deadline, MarketCommandProcessor.ACCEPT_CONTRACT, {"contract_id": "reedwatch_water_relief_01"}), "prepare the near-deadline contract fixture")
	active_contract_deadline.day = int(active_contract_deadline.active_contract("reedwatch_water_relief_01").get("deadline_day", 3)) - 1
	var crew_hook := AshWorldState.new(1107)
	_expect_ok(_command(crew_hook, MarketCommandProcessor.RECRUIT_CREW, {"crew_id": "nara_vey"}), "prepare the crew fixture")
	_expect_ok(_command(crew_hook, MarketCommandProcessor.ASSIGN_CREW, {"crew_id": "nara_vey"}), "activate the crew fixture")
	var faction_threshold := AshWorldState.new(1107)
	faction_threshold.adjust_reputation("wardens", 3)
	var recovery_fixtures := {
		"fresh_ashgate": fresh_ashgate,
		"loaded_exposed_route": loaded_exposed_route,
		"low_provisions": low_provisions,
		"saturated_reedwatch": saturated_reedwatch,
		"active_contract_deadline": active_contract_deadline,
		"crew_hook": crew_hook,
		"faction_threshold": faction_threshold,
	}
	for fixture_name in recovery_fixtures.keys():
		var fixture: AshWorldState = recovery_fixtures[fixture_name]
		var recovery_command := _first_legal_progression(fixture)
		_expect(not recovery_command.is_empty(), "%s should retain at least one legal recovery or progression command" % fixture_name)

	if failures.is_empty():
		print("Campaign smoke: PASS")
	else:
		for failure in failures:
			push_error(failure)
		printerr("Campaign smoke: FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, action: String) -> void:
	_expect(bool(result.get("ok", false)), "%s should succeed: %s" % [action, String(result.get("reason", "unknown failure"))])

func _contract_status(world: AshWorldState, contract_id: String) -> String:
	for record in world.contract_history:
		if String(record.get("id", "")) == contract_id:
			return String(record.get("status", ""))
	return ""

func _first_legal_progression(world: AshWorldState) -> String:
	if not world.pending_event.is_empty():
		for raw_choice in world.pending_event.get("choices", []):
			if typeof(raw_choice) != TYPE_DICTIONARY:
				continue
			var choice: Dictionary = raw_choice
			var choice_id := String(choice.get("id", ""))
			if _trial_command_ok(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": String(world.pending_event.get("id", "")), "choice_id": choice_id}):
				return "%s/%s" % [MarketCommandProcessor.RESOLVE_EVENT, choice_id]
		return ""
	for good_id in MarketContent.good_ids():
		if int(world.cargo.get(good_id, 0)) > 0 and _trial_command_ok(world, MarketCommandProcessor.SELL_GOODS, {"good_id": good_id, "quantity": 1}):
			return "%s/%s" % [MarketCommandProcessor.SELL_GOODS, good_id]
	for action in MarketContent.settlement_actions_for(world.current_settlement):
		var action_id := String(action.get("id", ""))
		if _trial_command_ok(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": action_id}):
			return "%s/%s" % [MarketCommandProcessor.USE_SETTLEMENT_ACTION, action_id]
	for destination_id in MarketContent.destinations_from(world.current_settlement):
		for route_id in MarketContent.routes_from(world.current_settlement):
			if MarketContent.route_connects(route_id, world.current_settlement, destination_id) and _trial_command_ok(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": route_id, "destination_id": destination_id}):
				return "%s/%s/%s" % [MarketCommandProcessor.DEPART_ROUTE, route_id, destination_id]
	for good_id in MarketContent.good_ids():
		if _trial_command_ok(world, MarketCommandProcessor.BUY_GOODS, {"good_id": good_id, "quantity": 1}):
			return "%s/%s" % [MarketCommandProcessor.BUY_GOODS, good_id]
	return ""

func _trial_command_ok(source: AshWorldState, command_id: String, inputs: Dictionary) -> bool:
	var candidate := AshWorldState.new(source.seed)
	var restored := candidate.load_serialized(source.serialize())
	if not bool(restored.get("ok", false)):
		return false
	return bool(_command(candidate, command_id, inputs).get("ok", false))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
