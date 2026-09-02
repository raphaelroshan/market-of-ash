extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_mara_changes_the_reedline_decision()
	_test_mara_response_requires_crew_and_scrap()
	_test_orin_changes_the_mirror_run_decision()
	_test_orin_response_requires_crew_and_oil()
	if failures.is_empty():
		print("MA-EA-5 crew and event depth smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_mara_changes_the_reedline_decision() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "blackreed_post"
	world.reset_visit_slots()
	_expect_ok(_command(world, MarketCommandProcessor.RECRUIT_CREW, {"crew_id": "mara_voss"}), "recruit Mara at Blackreed")
	_expect_ok(_command(world, MarketCommandProcessor.ASSIGN_CREW, {"crew_id": "mara_voss"}), "assign Mara to the Reedline")
	_expect(world.money == 101 and world.visit_slots_remaining == 0, "Mara should charge 19 ashmarks and use both recruit and assignment slots")
	world.cargo = {"scrap": 2, "medicine": 2, "weight": 4}
	var base_risk := float(world.route("reedline_track").get("risk", 0.0))
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "reedline_track", "destination_id": "mothlight_quay"}), "enter the Reedline wheel sink")
	_expect(world.pending_event.get("id", "") == "reedline_wheel_sink", "the named seed should pause at the authored Reedline wheel sink")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "reedline_wheel_sink", "choice_id": "mara_split_axle_brace"}), "use Mara's split-axle brace")
	_expect(world.current_settlement == "mothlight_quay" and int(world.cargo.get("scrap", 0)) == 1, "Mara's response should arrive and consume exactly one carried scrap")
	_expect(world.known_information.has("reedline_split_axle_line"), "Mara's response should record the discovered load line")
	_expect(float(world.route("reedline_track").get("risk", 1.0)) == base_risk - 0.08, "Mara's repair should persistently reduce only Reedline risk")
	_expect(float(world.route("salt_causeway").get("risk", 0.0)) == 0.38, "Mara's repair should not alter an unrelated route")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "restore Mara's completed journey")
	_expect(restored.is_crew_recruited("mara_voss") and restored.assigned_crew == "mara_voss", "save/load should preserve Mara's roster state")
	_expect(restored.has_resolved_event("reedline_wheel_sink") and float(restored.route("reedline_track").get("risk", 1.0)) == base_risk - 0.08, "save/load should preserve the event and its route consequence")

func _test_mara_response_requires_crew_and_scrap() -> void:
	var unassigned := _reedline_event_world()
	var pending_before := unassigned.pending_event.duplicate(true)
	var money_before := unassigned.money
	var provisions_before := unassigned.provisions
	var cargo_before := unassigned.cargo.duplicate(true)
	var blocked_crew := _command(unassigned, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "reedline_wheel_sink", "choice_id": "mara_split_axle_brace"})
	_expect(not blocked_crew.ok and String(blocked_crew.get("message", "")).contains("Mara Voss"), "the repair response should name Mara when she is not assigned")
	_expect(unassigned.pending_event == pending_before and unassigned.money == money_before and unassigned.provisions == provisions_before and unassigned.cargo == cargo_before, "a missing-crew response must not mutate the pending journey resources")

	var no_scrap := _reedline_event_world()
	no_scrap.recruited_crew.append("mara_voss")
	no_scrap.assigned_crew = "mara_voss"
	no_scrap.cargo.erase("scrap")
	no_scrap.cargo["weight"] = 2
	var blocked_scrap := _command(no_scrap, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "reedline_wheel_sink", "choice_id": "mara_split_axle_brace"})
	_expect(not blocked_scrap.ok and String(blocked_scrap.get("message", "")).to_lower().contains("1 scrap"), "Mara's repair should disclose and enforce its scrap cost: %s" % String(blocked_scrap.get("message", "")))
	_expect(not no_scrap.pending_event.is_empty(), "a missing-material response should leave the decision open")
	_expect_ok(_command(no_scrap, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "reedline_wheel_sink", "choice_id": "force_the_loaded_axle"}), "retain a zero-resource fallback")
	_expect(no_scrap.current_settlement == "mothlight_quay", "the fallback should prevent a low-resource soft lock")

func _reedline_event_world() -> AshWorldState:
	var world := AshWorldState.new(1)
	world.current_settlement = "blackreed_post"
	world.cargo = {"scrap": 2, "medicine": 2, "weight": 4}
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "reedline_track", "destination_id": "mothlight_quay"}), "prepare a Reedline event fixture")
	_expect(world.pending_event.get("id", "") == "reedline_wheel_sink", "the Reedline event fixture should trigger deterministically")
	return world

func _test_orin_changes_the_mirror_run_decision() -> void:
	var world := AshWorldState.new(3)
	world.current_settlement = "mirror_wells"
	world.resolved_event_ids.append("shardwind_tithe")
	world.reset_visit_slots()
	_expect_ok(_command(world, MarketCommandProcessor.RECRUIT_CREW, {"crew_id": "orin_bell"}), "recruit Orin at Mirror Wells")
	_expect_ok(_command(world, MarketCommandProcessor.ASSIGN_CREW, {"crew_id": "orin_bell"}), "assign Orin to the Mirror Run")
	_expect(world.money == 99 and world.visit_slots_remaining == 0, "Orin should charge 21 ashmarks and use both recruit and assignment slots")
	world.cargo = {"lamp_oil": 2, "saltglass": 2, "weight": 4}
	var base_risk := float(world.route("mirror_run").get("risk", 0.0))
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "mirror_run", "destination_id": "sunfall_exchange"}), "enter the divided beacon line")
	_expect(world.pending_event.get("id", "") == "mirror_beacon_split", "the named seed should pause at the authored Mirror Run event after the Shardwind encounter")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "mirror_beacon_split", "choice_id": "orin_occlusion_marks"}), "use Orin's occlusion marks")
	_expect(world.current_settlement == "sunfall_exchange" and int(world.cargo.get("lamp_oil", 0)) == 1, "Orin's response should arrive and consume exactly one lamp oil")
	_expect(world.known_information.has("mirror_run_occlusion_marks"), "Orin's response should record the true beacon line")
	_expect(float(world.route("mirror_run").get("risk", 1.0)) == base_risk - 0.07, "Orin's signal work should persistently reduce only Mirror Run risk")
	_expect(float(world.route("glasswind_trace").get("risk", 0.0)) == 0.30, "Orin's signal work should not alter the broader Glasswind Trace")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "restore Orin's completed journey")
	_expect(restored.is_crew_recruited("orin_bell") and restored.assigned_crew == "orin_bell", "save/load should preserve Orin's roster state")
	_expect(restored.has_resolved_event("mirror_beacon_split") and float(restored.route("mirror_run").get("risk", 1.0)) == base_risk - 0.07, "save/load should preserve the beacon event and route consequence")

func _test_orin_response_requires_crew_and_oil() -> void:
	var unassigned := _mirror_event_world()
	var pending_before := unassigned.pending_event.duplicate(true)
	var cargo_before := unassigned.cargo.duplicate(true)
	var blocked_crew := _command(unassigned, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "mirror_beacon_split", "choice_id": "orin_occlusion_marks"})
	_expect(not blocked_crew.ok and String(blocked_crew.get("message", "")).contains("Orin Bell"), "the signal response should name Orin when he is not assigned")
	_expect(unassigned.pending_event == pending_before and unassigned.cargo == cargo_before, "a missing-signal-reader response must preserve the pending journey resources")

	var no_oil := _mirror_event_world()
	no_oil.recruited_crew.append("orin_bell")
	no_oil.assigned_crew = "orin_bell"
	no_oil.cargo.erase("lamp_oil")
	no_oil.cargo["weight"] = 2
	var blocked_oil := _command(no_oil, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "mirror_beacon_split", "choice_id": "orin_occlusion_marks"})
	_expect(not blocked_oil.ok and String(blocked_oil.get("message", "")).to_lower().contains("1 lamp oil"), "Orin's signal response should disclose and enforce its lamp-oil cost: %s" % String(blocked_oil.get("message", "")))
	_expect(not no_oil.pending_event.is_empty(), "a missing-oil response should leave the beacon decision open")
	_expect_ok(_command(no_oil, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "mirror_beacon_split", "choice_id": "follow_nearest_reflection"}), "retain a zero-resource beacon fallback")
	_expect(no_oil.current_settlement == "sunfall_exchange", "the beacon fallback should prevent a low-resource soft lock")

func _mirror_event_world() -> AshWorldState:
	var world := AshWorldState.new(3)
	world.current_settlement = "mirror_wells"
	world.resolved_event_ids.append("shardwind_tithe")
	world.cargo = {"lamp_oil": 2, "saltglass": 2, "weight": 4}
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "mirror_run", "destination_id": "sunfall_exchange"}), "prepare a Mirror Run event fixture")
	_expect(world.pending_event.get("id", "") == "mirror_beacon_split", "the Mirror Run fixture should trigger deterministically")
	return world

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, context: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [context, String(result.get("message", "command failed"))])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
