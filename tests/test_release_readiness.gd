extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const AshWorldState = preload("res://src/core/world_state.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_early_access_content_floor()
	_test_runtime_budget_and_bounded_history()
	if failures.is_empty():
		print("Early Access release readiness: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_early_access_content_floor() -> void:
	_expect(MarketContent.content_version() == "1.28.0", "release candidate should use content version 1.28.0")
	_expect(MarketContent.regions().size() >= 3, "release candidate needs at least three regions")
	_expect(MarketContent.settlements().size() >= 11, "release candidate needs at least eleven settlements")
	_expect(MarketContent.good_ids().size() >= 10, "release candidate needs at least ten goods")
	_expect(MarketContent.routes().size() >= 9, "release candidate needs at least nine routes")
	_expect(MarketContent.crew_records().size() >= 5, "release candidate needs at least five decision-changing crew")
	_expect(MarketContent.event_rules().get("records", []).size() >= 9, "release candidate needs at least nine event families")
	_expect(MarketContent.factions().size() >= 4, "release candidate needs at least four standing factions")
	_expect(MarketContent.adaptive_scenarios().size() >= 3, "release candidate needs at least three replacement actors")
	_expect(MarketContent.ending_records().size() >= 6, "release candidate needs at least six endings")

func _test_runtime_budget_and_bounded_history() -> void:
	var isolated_snapshot := MarketContent.runtime_world()
	var isolated_settlements: Dictionary = isolated_snapshot.get("settlements", {})
	var isolated_ashgate: Dictionary = isolated_settlements.get("ashgate", {})
	isolated_ashgate["name"] = "Mutated test settlement"
	isolated_settlements["ashgate"] = isolated_ashgate
	isolated_snapshot["settlements"] = isolated_settlements
	_expect(String(MarketContent.settlements().get("ashgate", {}).get("name", "")) == "Ashgate", "public runtime snapshots must not mutate the validated content cache")

	var started_usec := Time.get_ticks_usec()
	var checksum := 0
	for seed in range(25):
		var world := AshWorldState.new(seed + 1)
		for route_id_value in MarketContent.routes().keys():
			var route := world.route(String(route_id_value))
			checksum += int(route.get("cost", 0)) + int(round(float(route.get("risk", 0.0)) * 100.0))
		var restored := AshWorldState.new(0)
		var load_result := restored.load_serialized(world.serialize())
		if not load_result.ok:
			failures.append("release budget fixture could not round-trip seed %d" % (seed + 1))
			return
	var elapsed_msec := float(Time.get_ticks_usec() - started_usec) / 1000.0
	print("Release budget: 25 deterministic world/save round trips in %.2f ms (limit: <5000.00 ms)" % elapsed_msec)
	_expect(checksum > 0, "release budget fixture should exercise route calculations")
	_expect(elapsed_msec < 5000.0, "25 deterministic world/save round trips exceeded the 5-second release budget: %.2f ms" % elapsed_msec)

	var bounded := AshWorldState.new(1)
	for index in range(300):
		bounded.add_log("release readiness entry %d" % index)
		bounded.record_command({"id": "release_probe", "inputs": {"index": index}}, {"ok": true, "message": "probe"})
	_expect(bounded.log.size() == AshWorldState.MAX_LOG_ENTRIES, "the release log should remain bounded during long sessions")
	_expect(bounded.command_history.size() == AshWorldState.MAX_COMMAND_HISTORY, "the command history should remain bounded during long sessions")

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
