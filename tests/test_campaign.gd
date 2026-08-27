extends SceneTree

const AshWorldState = preload("res://src/core/world_state.gd")
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
	_expect(JSON.stringify(restored.serialize()) == JSON.stringify(world.serialize()), "the restored ending state should exactly match the serialized campaign")

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

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
