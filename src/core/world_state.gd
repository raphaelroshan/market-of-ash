class_name AshWorldState
extends RefCounted

## Serializable, presentation-agnostic state for the first Market of Ash region.
## The world owns state; commands validate and mutate this state through MarketCommandProcessor.

const MarketContent = preload("res://src/core/market_content.gd")
const SAVE_VERSION := 11
const MAX_COMMAND_HISTORY := 100

var seed: int = 1107
var day: int = 1
var money: int = 120
var provisions: int = 12
var cargo_capacity: int = 12
var cargo: Dictionary = {"weight": 0}
var current_settlement: String = "ashgate"
var reputation: Dictionary = {"wardens": 0, "caravans": 0}
var crisis_stage: int = 0
var crisis_modifiers: Dictionary = {}
var market_pressure: Dictionary = {}
var market_delivery_history: Array[Dictionary] = []
var visit_slots_remaining: int = 2
var active_contracts: Dictionary = {}
var contract_history: Array[Dictionary] = []
var journey_context: Dictionary = {}
var pending_event: Dictionary = {}
var resolved_event_ids: Array[String] = []
var event_history: Array[Dictionary] = []
var route_conditions: Dictionary = {}
var settlement_resilience: Dictionary = {}
var known_information: Array[String] = []
var recruited_crew: Array[String] = []
var assigned_crew: String = ""
var crew_reports: Dictionary = {}
var arms_escalation: int = 0
var arms_trade_history: Array[Dictionary] = []
var ending_id: String = ""
var ending_summary: String = ""
var log: Array[String] = []
var command_history: Array[Dictionary] = []

var settlements: Dictionary = {}
var routes: Dictionary = {}

func _init(world_seed: int = 1107) -> void:
	seed = world_seed
	var content_result := MarketContent.load_runtime()
	if not content_result.ok:
		push_error("Market of Ash runtime content failed validation: %s" % "; ".join(content_result.errors))
		return
	settlements = content_result.data.settlements.duplicate(true)
	routes = content_result.data.routes.duplicate(true)
	reset_visit_slots()
	_update_crisis_modifiers()

func settlement(id: String) -> Dictionary:
	var result: Dictionary = settlements.get(id, {}).duplicate(true)
	if not result.is_empty():
		result["id"] = id
	return result

func route(id: String) -> Dictionary:
	var result: Dictionary = routes.get(id, {}).duplicate(true)
	if result.is_empty():
		return result
	var condition_value: Variant = route_conditions.get(id, {})
	if typeof(condition_value) == TYPE_DICTIONARY:
		var condition: Dictionary = condition_value
		if not condition.is_empty():
			result["risk"] = clampf(float(result.get("risk", 0.0)) + float(condition.get("risk_delta", 0.0)), 0.0, 1.0)
			result["cost"] = maxi(0, int(result.get("cost", 0)) + int(condition.get("cost_delta", 0)))
			result["condition"] = condition.duplicate(true)
			result["description"] = "%s Route condition: %s" % [String(result.get("description", "")), String(condition.get("description", ""))]
	for faction_id_value in MarketContent.factions().keys():
		var faction_id := String(faction_id_value)
		var faction := MarketContent.faction(faction_id)
		if id == String(faction.get("toll_route_id", "")) and int(reputation.get(faction_id, 0)) >= int(faction.get("trusted_threshold", 999)):
			result["cost"] = maxi(0, int(result.get("cost", 0)) - int(faction.get("toll_discount", 0)))
			result["faction_name"] = String(faction.get("name", faction_id))
			result["faction_effect"] = String(faction.get("effect", ""))
			result["faction_tradeoff"] = String(faction.get("tradeoff", ""))
	var arms_rules := MarketContent.arms_trade_rules()
	if id == String(arms_rules.get("inspection_route_id", "")) and arms_escalation >= int(arms_rules.get("inspection_threshold", 999)) and int(cargo.get("sealed_arms_crate", 0)) > 0:
		result["cost"] = int(result.get("cost", 0)) + int(arms_rules.get("inspection_surcharge", 0))
		result["arms_effect"] = "Arms inspection surcharge: +%d ashmarks." % int(arms_rules.get("inspection_surcharge", 0))
	return result

func set_route_condition(route_id: String, condition: Dictionary) -> Dictionary:
	if not routes.has(route_id):
		return {"ok": false, "reason": "unknown route"}
	if String(condition.get("id", "")).is_empty():
		return {"ok": false, "reason": "route condition needs a stable id"}
	var snapshot := condition.duplicate(true)
	snapshot["route_id"] = route_id
	snapshot["applied_day"] = day
	route_conditions[route_id] = snapshot
	return {"ok": true, "condition": snapshot.duplicate(true)}

func resilience_for(settlement_id: String) -> int:
	if not has_settlement(settlement_id):
		return 0
	return clampi(int(settlement_resilience.get(settlement_id, 0)), 0, 10)

func adjust_settlement_resilience(settlement_id: String, delta: int) -> Dictionary:
	if not has_settlement(settlement_id):
		return {"ok": false, "reason": "unknown settlement"}
	var before := resilience_for(settlement_id)
	var after := clampi(before + delta, 0, 10)
	settlement_resilience[settlement_id] = after
	return {"ok": true, "before": before, "after": after, "delta": after - before}

func record_information(information_id: String) -> bool:
	if information_id.is_empty() or known_information.has(information_id):
		return false
	known_information.append(information_id)
	return true

func adjust_reputation(faction_id: String, delta: int) -> Dictionary:
	if not reputation.has(faction_id):
		return {"ok": false, "reason": "unknown faction"}
	var rules := MarketContent.faction(faction_id)
	var before := int(reputation.get(faction_id, 0))
	var after := clampi(before + delta, int(rules.get("minimum", -10)), int(rules.get("maximum", 10)))
	reputation[faction_id] = after
	return {"ok": true, "before": before, "after": after, "delta": after - before}

func faction_status(faction_id: String) -> Dictionary:
	var rules := MarketContent.faction(faction_id)
	if rules.is_empty():
		return {}
	var value := int(reputation.get(faction_id, 0))
	var threshold := int(rules.get("trusted_threshold", 0))
	return {
		"value": value,
		"tier": String(rules.get("trusted_label", "Trusted")) if value >= threshold else String(rules.get("below_label", "Unrecognized")),
		"next_threshold": threshold,
		"effect": String(rules.get("effect", "")),
		"tradeoff": String(rules.get("tradeoff", "")),
	}

func adjust_arms_escalation(delta: int, source_id: String) -> Dictionary:
	var rules := MarketContent.arms_trade_rules()
	var before := arms_escalation
	arms_escalation = clampi(before + delta, int(rules.get("minimum", 0)), int(rules.get("maximum", 6)))
	var record := {"source_id": source_id, "day": day, "before": before, "after": arms_escalation, "delta": arms_escalation - before}
	arms_trade_history.append(record)
	return record

func is_crew_recruited(crew_id: String) -> bool:
	return recruited_crew.has(crew_id)

func route_intelligence(route_id: String) -> Dictionary:
	if route(route_id).is_empty():
		return {"status": "unavailable", "label": "No route", "detail": "No authored route is selected."}
	if recruited_crew.is_empty():
		return {"status": "unavailable", "label": "Scout unavailable", "detail": "Recruit Nara Vey in Ashgate for route-specific field notes."}
	var report_value: Variant = crew_reports.get(route_id, {})
	if assigned_crew.is_empty() or typeof(report_value) != TYPE_DICTIONARY:
		return {"status": "stale", "label": "Crew report stale", "detail": "Assign a recruited route specialist during this settlement visit to refresh nearby notes."}
	var assigned := MarketContent.crew_member(assigned_crew)
	var report: Dictionary = report_value
	var age := day - int(report.get("observed_day", day))
	if age > int(assigned.get("report_valid_days", 0)):
		return {"status": "stale", "label": "%s report stale" % String(assigned.get("name", "Crew")), "detail": "The note is %d day old; refresh it before relying on current conditions." % age}
	var status := "scout_informed" if assigned_crew == "nara_vey" else "logistics_informed"
	return {"status": status, "label": "%s-informed" % String(assigned.get("name", "Crew")).trim_suffix(" Vey").trim_suffix(" Pale"), "detail": String(report.get("note", "The route remains uncertain.")), "observed_day": int(report.get("observed_day", day))}

func route_provision_cost(route_id: String) -> int:
	var selected := route(route_id)
	if selected.is_empty():
		return 0
	var base_cost := int(selected.get("days", 0))
	var intelligence := route_intelligence(route_id)
	if String(intelligence.get("status", "")) != "logistics_informed":
		return base_cost
	var assigned := MarketContent.crew_member(assigned_crew)
	return maxi(1, base_cost - int(assigned.get("provision_discount", 0)))

func has_settlement(id: String) -> bool:
	return settlements.has(id)

func pricing_context() -> Dictionary:
	return {
		"crisis_modifiers": crisis_modifiers.duplicate(true),
		"market_pressure": market_pressure.duplicate(true),
	}

func market_pressure_for(settlement_id: String, good_id: String) -> float:
	if not has_settlement(settlement_id) or MarketContent.good(good_id).is_empty():
		return 0.0
	var settlement_pressure_value: Variant = market_pressure.get(settlement_id, {})
	if typeof(settlement_pressure_value) != TYPE_DICTIONARY:
		return 0.0
	var rules := MarketContent.market_memory_rules()
	return clampf(
		float(settlement_pressure_value.get(good_id, rules.get("pressure_min", 0.0))),
		float(rules.get("pressure_min", 0.0)),
		float(rules.get("pressure_max", 0.0)),
	)

func latest_market_delivery(settlement_id: String, good_id: String) -> Dictionary:
	for index in range(market_delivery_history.size() - 1, -1, -1):
		var record: Dictionary = market_delivery_history[index]
		if String(record.get("settlement_id", "")) == settlement_id and String(record.get("good_id", "")) == good_id:
			return record.duplicate(true)
	return {}

func reset_visit_slots() -> void:
	visit_slots_remaining = int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2))

func active_contract(contract_id: String) -> Dictionary:
	var value: Variant = active_contracts.get(contract_id, {})
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value.duplicate(true)

func has_contract_outcome(contract_id: String) -> bool:
	for record in contract_history:
		if String(record.get("id", "")) == contract_id:
			return true
	return false

func archive_contract(contract_id: String, status: String, extra: Dictionary = {}) -> Dictionary:
	var snapshot := active_contract(contract_id)
	if snapshot.is_empty():
		return {}
	active_contracts.erase(contract_id)
	snapshot["status"] = status
	snapshot["resolved_day"] = day
	for key in extra.keys():
		snapshot[key] = extra[key]
	contract_history.append(snapshot)
	var history_limit := int(MarketContent.contract_rules().get("max_history", 1))
	while contract_history.size() > history_limit:
		contract_history.pop_front()
	return snapshot.duplicate(true)

func has_resolved_event(event_id: String) -> bool:
	return resolved_event_ids.has(event_id)

func begin_pending_event(event_snapshot: Dictionary, journey: Dictionary) -> void:
	pending_event = event_snapshot.duplicate(true)
	journey_context = journey.duplicate(true)

func archive_pending_event(choice_id: String, outcome: Dictionary) -> Dictionary:
	if pending_event.is_empty():
		return {}
	var record := pending_event.duplicate(true)
	record["choice_id"] = choice_id
	record["resolved_day"] = day
	record["outcome"] = outcome.duplicate(true)
	event_history.append(record)
	var history_limit := int(MarketContent.event_rules().get("max_history", 1))
	while event_history.size() > history_limit:
		event_history.pop_front()
	var event_id := String(pending_event.get("id", ""))
	if not event_id.is_empty() and not resolved_event_ids.has(event_id):
		resolved_event_ids.append(event_id)
	pending_event.clear()
	journey_context.clear()
	return record.duplicate(true)

func record_market_delivery(settlement_id: String, good_id: String, quantity: int) -> Dictionary:
	if not has_settlement(settlement_id):
		return {"ok": false, "reason": "unknown settlement"}
	if MarketContent.good(good_id).is_empty():
		return {"ok": false, "reason": "unknown good"}
	if quantity <= 0:
		return {"ok": false, "reason": "quantity must be positive"}
	var rules := MarketContent.market_memory_rules()
	var pressure_min := float(rules.get("pressure_min", 0.0))
	var pressure_max := float(rules.get("pressure_max", 0.0))
	var effectiveness: Dictionary = rules.get("crisis_effectiveness", {})
	var crisis_factor := float(effectiveness.get(str(crisis_stage), 1.0))
	var before := market_pressure_for(settlement_id, good_id)
	var requested_impact := float(quantity) * float(rules.get("sale_impact_per_unit", 0.0)) * crisis_factor
	var after := _rounded_pressure(clampf(before + requested_impact, pressure_min, pressure_max))
	var settlement_pressure: Dictionary = market_pressure.get(settlement_id, {}).duplicate(true)
	settlement_pressure[good_id] = after
	market_pressure[settlement_id] = settlement_pressure
	var record := {
		"settlement_id": settlement_id,
		"good_id": good_id,
		"quantity": quantity,
		"day": day,
		"pressure_before": before,
		"pressure_after": after,
		"effective_impact": _rounded_pressure(after - before),
		"crisis_stage": crisis_stage,
		"crisis_effectiveness": crisis_factor,
	}
	market_delivery_history.append(record)
	var history_limit := int(rules.get("max_delivery_history", 1))
	while market_delivery_history.size() > history_limit:
		market_delivery_history.pop_front()
	return {"ok": true, "record": record.duplicate(true)}

func _update_crisis_modifiers() -> void:
	crisis_modifiers = {"grain": 1.0, "water": 1.0, "scrap": 1.0, "medicine": 1.0, "charcoal": 1.0, "cloth": 1.0, "sealed_arms_crate": 1.0}
	if crisis_stage >= 1:
		crisis_modifiers["water"] = 1.35
		crisis_modifiers["medicine"] = 1.15
	if crisis_stage >= 2:
		crisis_modifiers["water"] = 1.7
		crisis_modifiers["grain"] = 1.2
	if crisis_stage >= 3:
		crisis_modifiers["water"] = 1.95
		crisis_modifiers["medicine"] = 1.35

func advance_day(days: int) -> void:
	var elapsed_days := maxi(0, days)
	day += elapsed_days
	_decay_market_pressure(elapsed_days)
	var next_stage := crisis_stage
	for stage in MarketContent.crisis_rules().get("stages", []):
		if day >= int(stage.get("starts_day", 1)):
			next_stage = maxi(next_stage, int(stage.get("id", 0)))
	if next_stage != crisis_stage:
		crisis_stage = next_stage
		_update_crisis_modifiers()
		log.append("Crisis stage %d: %s." % [crisis_stage, String(MarketContent.crisis_stage(crisis_stage).get("label", "Regional pressure"))])
	evaluate_ending()

func evaluate_ending() -> bool:
	if not ending_id.is_empty() or crisis_stage < 3:
		return not ending_id.is_empty()
	var ending: Dictionary = MarketContent.crisis_rules().get("ending", {})
	if not has_contract_outcome(String(ending.get("required_contract_id", ""))):
		return false
	var required_contract_completed := false
	for contract in contract_history:
		if String(contract.get("id", "")) == String(ending.get("required_contract_id", "")) and String(contract.get("status", "")) == "completed":
			required_contract_completed = true
	if not required_contract_completed or resilience_for("reedwatch") < int(ending.get("minimum_reedwatch_resilience", 0)) or arms_escalation > int(ending.get("maximum_arms_escalation", 0)):
		return false
	ending_id = String(ending.get("id", ""))
	ending_summary = String(ending.get("summary", ""))
	log.append("Ending reached: %s — %s" % [String(ending.get("title", ending_id)), ending_summary])
	return true

func _decay_market_pressure(days: int) -> void:
	if days <= 0 or market_pressure.is_empty():
		return
	var rules := MarketContent.market_memory_rules()
	var pressure_min := float(rules.get("pressure_min", 0.0))
	var decay := float(days) * float(rules.get("daily_decay_per_day", 0.0))
	for settlement_id in market_pressure.keys():
		var settlement_pressure: Dictionary = market_pressure.get(settlement_id, {}).duplicate(true)
		for good_id in settlement_pressure.keys():
			var after := _rounded_pressure(maxf(pressure_min, float(settlement_pressure.get(good_id, pressure_min)) - decay))
			if is_equal_approx(after, pressure_min):
				settlement_pressure.erase(good_id)
			else:
				settlement_pressure[good_id] = after
		if settlement_pressure.is_empty():
			market_pressure.erase(settlement_id)
		else:
			market_pressure[settlement_id] = settlement_pressure

func _rounded_pressure(value: float) -> float:
	return roundf(value * 10000.0) / 10000.0

func travel(route_id: String) -> Dictionary:
	var selected := route(route_id)
	if selected.is_empty():
		return {"ok": false, "reason": "unknown route"}
	if money < int(selected.cost):
		return {"ok": false, "reason": "not enough money for route cost"}
	var provision_cost := route_provision_cost(route_id)
	if provisions < provision_cost:
		return {"ok": false, "reason": "not enough provisions"}
	money -= int(selected.cost)
	provisions -= provision_cost
	advance_day(int(selected.days))
	return {"ok": true, "risk": float(selected.risk), "days": int(selected.days), "provisions": provision_cost, "cost": int(selected.cost)}

func record_command(command: Dictionary, result: Dictionary) -> void:
	var entry := {
		"id": String(command.get("id", "unknown")),
		"inputs": command.get("inputs", {}).duplicate(true),
		"day": day,
		"ok": bool(result.get("ok", false)),
		"message": String(result.get("message", "")),
		"state_delta": result.get("state_delta", {}).duplicate(true),
	}
	command_history.append(entry)
	if command_history.size() > MAX_COMMAND_HISTORY:
		command_history.pop_front()

func serialize() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"content_version": MarketContent.content_version(),
		"seed": seed,
		"day": day,
		"money": money,
		"provisions": provisions,
		"cargo_capacity": cargo_capacity,
		"cargo": cargo.duplicate(true),
		"current_settlement": current_settlement,
		"reputation": reputation.duplicate(true),
		"crisis_stage": crisis_stage,
		"market_pressure": market_pressure.duplicate(true),
		"market_delivery_history": market_delivery_history.duplicate(true),
		"visit_slots_remaining": visit_slots_remaining,
		"active_contracts": active_contracts.duplicate(true),
		"contract_history": contract_history.duplicate(true),
		"journey_context": journey_context.duplicate(true),
		"pending_event": pending_event.duplicate(true),
		"resolved_event_ids": resolved_event_ids.duplicate(),
		"event_history": event_history.duplicate(true),
		"route_conditions": route_conditions.duplicate(true),
		"settlement_resilience": settlement_resilience.duplicate(true),
		"known_information": known_information.duplicate(),
		"recruited_crew": recruited_crew.duplicate(),
		"assigned_crew": assigned_crew,
		"crew_reports": crew_reports.duplicate(true),
		"arms_escalation": arms_escalation,
		"arms_trade_history": arms_trade_history.duplicate(true),
		"ending_id": ending_id,
		"ending_summary": ending_summary,
		"log": log.duplicate(),
		"command_history": command_history.duplicate(true),
	}

func load_serialized(data: Dictionary) -> Dictionary:
	var migration := migrate_serialized(data)
	if not migration.ok:
		return migration
	var restored: Dictionary = migration.data
	seed = int(restored.get("seed", seed))
	day = int(restored.get("day", day))
	money = int(restored.get("money", money))
	provisions = int(restored.get("provisions", provisions))
	cargo_capacity = int(restored.get("cargo_capacity", cargo_capacity))
	cargo = _sanitize_cargo(restored.get("cargo", {"weight": 0}))
	current_settlement = String(restored.get("current_settlement", current_settlement))
	if not has_settlement(current_settlement):
		current_settlement = "ashgate"
	reputation = _sanitize_reputation(restored.get("reputation", reputation))
	crisis_stage = int(restored.get("crisis_stage", crisis_stage))
	market_pressure = _sanitize_market_pressure(restored.get("market_pressure", {}))
	market_delivery_history.clear()
	var saved_delivery_history: Array = restored.get("market_delivery_history", [])
	var history_limit := int(MarketContent.market_memory_rules().get("max_delivery_history", 1))
	for raw_record in saved_delivery_history.slice(maxi(0, saved_delivery_history.size() - history_limit)):
		if typeof(raw_record) == TYPE_DICTIONARY:
			var record: Dictionary = raw_record
			if has_settlement(String(record.get("settlement_id", ""))) and not MarketContent.good(String(record.get("good_id", ""))).is_empty():
				market_delivery_history.append(record.duplicate(true))
	visit_slots_remaining = clampi(
		int(restored.get("visit_slots_remaining", MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2))),
		0,
		int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2)),
	)
	active_contracts = _sanitize_active_contracts(restored.get("active_contracts", {}))
	contract_history.clear()
	var saved_contract_history: Array = restored.get("contract_history", [])
	var contract_history_limit := int(MarketContent.contract_rules().get("max_history", 1))
	for raw_contract in saved_contract_history.slice(maxi(0, saved_contract_history.size() - contract_history_limit)):
		if typeof(raw_contract) == TYPE_DICTIONARY and not String(raw_contract.get("id", "")).is_empty():
			contract_history.append(raw_contract.duplicate(true))
	journey_context = restored.get("journey_context", {}).duplicate(true)
	pending_event = restored.get("pending_event", {}).duplicate(true)
	resolved_event_ids.clear()
	for event_id in restored.get("resolved_event_ids", []):
		var normalized_event_id := String(event_id)
		if not normalized_event_id.is_empty() and not resolved_event_ids.has(normalized_event_id):
			resolved_event_ids.append(normalized_event_id)
	event_history.clear()
	var saved_event_history: Array = restored.get("event_history", [])
	var event_history_limit := int(MarketContent.event_rules().get("max_history", 1))
	for raw_event in saved_event_history.slice(maxi(0, saved_event_history.size() - event_history_limit)):
		if typeof(raw_event) == TYPE_DICTIONARY:
			event_history.append(raw_event.duplicate(true))
	route_conditions = _sanitize_route_conditions(restored.get("route_conditions", {}))
	settlement_resilience = _sanitize_settlement_resilience(restored.get("settlement_resilience", {}))
	known_information.clear()
	for information_id_value in restored.get("known_information", []):
		var information_id := String(information_id_value)
		if not information_id.is_empty() and not known_information.has(information_id):
			known_information.append(information_id)
	recruited_crew.clear()
	for crew_id_value in restored.get("recruited_crew", []):
		var crew_id := String(crew_id_value)
		if not MarketContent.crew_member(crew_id).is_empty() and not recruited_crew.has(crew_id):
			recruited_crew.append(crew_id)
	assigned_crew = String(restored.get("assigned_crew", ""))
	if not recruited_crew.has(assigned_crew):
		assigned_crew = ""
	crew_reports = restored.get("crew_reports", {}).duplicate(true) if typeof(restored.get("crew_reports", {})) == TYPE_DICTIONARY else {}
	var arms_rules := MarketContent.arms_trade_rules()
	arms_escalation = clampi(int(restored.get("arms_escalation", 0)), int(arms_rules.get("minimum", 0)), int(arms_rules.get("maximum", 6)))
	arms_trade_history.clear()
	var saved_arms_history: Variant = restored.get("arms_trade_history", [])
	if typeof(saved_arms_history) == TYPE_ARRAY:
		for raw_arms_record in saved_arms_history:
			if typeof(raw_arms_record) == TYPE_DICTIONARY:
				arms_trade_history.append(raw_arms_record.duplicate(true))
	ending_id = String(restored.get("ending_id", ""))
	ending_summary = String(restored.get("ending_summary", ""))
	log.clear()
	var saved_log: Array = restored.get("log", [])
	for log_entry in saved_log:
		log.append(String(log_entry))
	command_history.clear()
	var saved_history: Array = restored.get("command_history", [])
	for raw_entry in saved_history:
		if typeof(raw_entry) == TYPE_DICTIONARY:
			command_history.append(raw_entry.duplicate(true))
	_update_crisis_modifiers()
	return {"ok": true, "data": serialize(), "migrated_from": int(migration.migrated_from)}

func migrate_serialized(data: Dictionary) -> Dictionary:
	var source_version := int(data.get("save_version", 0))
	if source_version > SAVE_VERSION:
		return {"ok": false, "reason": "save version %d is newer than this build" % source_version}
	var migrated := data.duplicate(true)
	if source_version < 1:
		migrated["save_version"] = 1
		migrated["content_version"] = String(migrated.get("content_version", MarketContent.content_version()))
		migrated["command_history"] = migrated.get("command_history", [])
	if source_version < 2:
		migrated["save_version"] = 2
		migrated["market_pressure"] = migrated.get("market_pressure", {})
		migrated["market_delivery_history"] = migrated.get("market_delivery_history", [])
	if source_version < 3:
		migrated["save_version"] = 3
		migrated["visit_slots_remaining"] = int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2))
	if source_version < 4:
		migrated["save_version"] = 4
		migrated["active_contracts"] = migrated.get("active_contracts", {})
		migrated["contract_history"] = migrated.get("contract_history", [])
	if source_version < 5:
		migrated["save_version"] = 5
		migrated["journey_context"] = migrated.get("journey_context", {})
		migrated["pending_event"] = migrated.get("pending_event", {})
		migrated["resolved_event_ids"] = migrated.get("resolved_event_ids", [])
		migrated["event_history"] = migrated.get("event_history", [])
	if source_version < 6:
		migrated["save_version"] = 6
		migrated["route_conditions"] = migrated.get("route_conditions", {})
	if source_version < 7:
		migrated["save_version"] = 7
		migrated["settlement_resilience"] = migrated.get("settlement_resilience", {})
	if source_version < 8:
		migrated["save_version"] = 8
		migrated["known_information"] = migrated.get("known_information", [])
	if source_version < 9:
		migrated["save_version"] = 9
		migrated["recruited_crew"] = migrated.get("recruited_crew", [])
		migrated["assigned_crew"] = migrated.get("assigned_crew", "")
		migrated["crew_reports"] = migrated.get("crew_reports", {})
	if source_version < 10:
		migrated["save_version"] = 10
		migrated["arms_escalation"] = migrated.get("arms_escalation", 0)
		migrated["arms_trade_history"] = migrated.get("arms_trade_history", [])
	if source_version < 11:
		migrated["save_version"] = 11
		migrated["ending_id"] = migrated.get("ending_id", "")
		migrated["ending_summary"] = migrated.get("ending_summary", "")
	return {"ok": true, "data": migrated, "migrated_from": source_version}

func _sanitize_settlement_resilience(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var sanitized: Dictionary = {}
	var records: Dictionary = value
	for settlement_id_value in records.keys():
		var settlement_id := String(settlement_id_value)
		if not has_settlement(settlement_id):
			continue
		sanitized[settlement_id] = clampi(int(records.get(settlement_id_value, 0)), 0, 10)
	return sanitized

func _sanitize_cargo(value: Variant) -> Dictionary:
	var sanitized: Dictionary = {"weight": 0}
	if typeof(value) != TYPE_DICTIONARY:
		return sanitized
	var records: Dictionary = value
	var remaining_capacity := maxi(0, cargo_capacity)
	for good_id in MarketContent.good_ids():
		var good := MarketContent.good(good_id)
		var unit_weight := maxi(1, int(good.get("weight", 1)))
		var requested := maxi(0, int(records.get(good_id, 0)))
		var accepted := mini(requested, int(remaining_capacity / unit_weight))
		if accepted <= 0:
			continue
		sanitized[good_id] = accepted
		sanitized["weight"] = int(sanitized.weight) + accepted * unit_weight
		remaining_capacity -= accepted * unit_weight
	return sanitized

func _sanitize_reputation(value: Variant) -> Dictionary:
	var records: Dictionary = value if typeof(value) == TYPE_DICTIONARY else {}
	var sanitized: Dictionary = {}
	for faction_id_value in MarketContent.factions().keys():
		var faction_id := String(faction_id_value)
		var faction := MarketContent.faction(faction_id)
		sanitized[faction_id] = clampi(
			int(records.get(faction_id, 0)),
			int(faction.get("reputation_min", -10)),
			int(faction.get("reputation_max", 10)),
		)
	return sanitized

func _sanitize_route_conditions(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var sanitized: Dictionary = {}
	var records: Dictionary = value
	for route_id_value in records.keys():
		var route_id := String(route_id_value)
		if not routes.has(route_id):
			continue
		var raw_condition: Variant = records.get(route_id_value, {})
		if typeof(raw_condition) != TYPE_DICTIONARY:
			continue
		var condition: Dictionary = raw_condition
		if String(condition.get("id", "")).is_empty():
			continue
		var snapshot := condition.duplicate(true)
		snapshot["route_id"] = route_id
		snapshot["risk_delta"] = clampf(float(snapshot.get("risk_delta", 0.0)), -1.0, 1.0)
		snapshot["cost_delta"] = int(snapshot.get("cost_delta", 0))
		sanitized[route_id] = snapshot
	return sanitized

func _sanitize_active_contracts(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var sanitized: Dictionary = {}
	var records: Dictionary = value
	for contract_id in records.keys():
		var raw_snapshot: Variant = records.get(contract_id, {})
		if typeof(raw_snapshot) != TYPE_DICTIONARY:
			continue
		var snapshot: Dictionary = raw_snapshot
		var normalized_id := String(snapshot.get("id", contract_id))
		if normalized_id.is_empty():
			continue
		snapshot = snapshot.duplicate(true)
		snapshot["id"] = normalized_id
		snapshot["status"] = "active"
		sanitized[normalized_id] = snapshot
	return sanitized

func _sanitize_market_pressure(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	var rules := MarketContent.market_memory_rules()
	var pressure_min := float(rules.get("pressure_min", 0.0))
	var pressure_max := float(rules.get("pressure_max", 0.0))
	var sanitized: Dictionary = {}
	var raw_pressure: Dictionary = value
	for settlement_id in raw_pressure.keys():
		var normalized_settlement_id := String(settlement_id)
		if not has_settlement(normalized_settlement_id):
			continue
		var goods_value: Variant = raw_pressure.get(settlement_id, {})
		if typeof(goods_value) != TYPE_DICTIONARY:
			continue
		var sanitized_goods: Dictionary = {}
		var goods: Dictionary = goods_value
		for good_id in goods.keys():
			var normalized_good_id := String(good_id)
			if MarketContent.good(normalized_good_id).is_empty():
				continue
			var pressure := _rounded_pressure(clampf(float(goods.get(good_id, pressure_min)), pressure_min, pressure_max))
			if pressure > pressure_min:
				sanitized_goods[normalized_good_id] = pressure
		if not sanitized_goods.is_empty():
			sanitized[normalized_settlement_id] = sanitized_goods
	return sanitized
