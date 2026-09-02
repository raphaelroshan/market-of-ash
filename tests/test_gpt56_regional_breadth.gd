extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")

const REGION_FACTIONS := {
	"five_well_basin": ["wardens", "caravans"],
	"glasswind_reach": ["glass_consortium"],
	"siltfire_march": ["bellkeepers"],
}

var failures: Array[String] = []

func _init() -> void:
	var runtime := MarketContent.runtime_world()
	var contracts: Array = runtime.get("contracts", {}).get("records", [])
	var events: Array = runtime.get("events", {}).get("records", [])
	var scenarios: Array = runtime.get("adaptive_scenarios", {}).get("records", [])
	var actions: Array = runtime.get("settlement_actions", {}).get("actions", [])
	for region_id_value in runtime.get("regions", {}).keys():
		var region_id := String(region_id_value)
		var region: Dictionary = runtime.regions[region_id]
		var settlement_ids: Array = region.get("settlement_ids", [])
		var route_ids: Array = region.get("route_ids", [])
		_expect(settlement_ids.size() >= 3, "%s needs at least three settlements" % region_id)
		_expect(route_ids.size() >= 3, "%s needs at least three routes" % region_id)
		var produced_goods: Dictionary = {}
		for settlement_id in settlement_ids:
			for good_id in runtime.settlements[String(settlement_id)].get("trade_profile", {}).get("produces", {}).keys():
				produced_goods[String(good_id)] = true
		_expect(produced_goods.size() >= 3, "%s needs at least three ordinary goods" % region_id)
		_expect(contracts.any(func(record: Dictionary) -> bool: return settlement_ids.has(String(record.get("origin_id", "")))), "%s needs optional local work" % region_id)
		_expect(events.any(func(record: Dictionary) -> bool: return (record.get("route_ids", []) as Array).any(func(route_id) -> bool: return route_ids.has(route_id))), "%s needs a regional event family" % region_id)
		_expect((REGION_FACTIONS.get(region_id, []) as Array).any(func(faction_id) -> bool: return runtime.factions.has(faction_id)), "%s needs visible faction pressure" % region_id)
		var regional_scenarios := scenarios.filter(func(record: Dictionary) -> bool: return settlement_ids.has(String(record.get("failure_response", {}).get("settlement_id", ""))))
		_expect(not regional_scenarios.is_empty(), "%s needs a failure-forward replacement actor" % region_id)
		for scenario in regional_scenarios:
			var faction_id := String(scenario.get("failure_response", {}).get("faction_id", ""))
			_expect(actions.any(func(action: Dictionary) -> bool: return action.get("requires_emergent_faction_id", "") == faction_id), "%s replacement actor needs a post-consequence opportunity" % region_id)
	var contract_free_endings: Array = runtime.get("crisis", {}).get("endings", []).filter(func(ending: Dictionary) -> bool: return not ending.has("required_contract_id"))
	_expect(not contract_free_endings.is_empty(), "the campaign needs terminal outcomes that do not require a contract")
	if failures.is_empty():
		print("GPT56 regional breadth: PASS")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
