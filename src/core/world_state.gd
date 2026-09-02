class_name AshWorldState
extends RefCounted

## Serializable, presentation-agnostic state for the Market of Ash trade network.
## The world owns state; commands validate and mutate this state through MarketCommandProcessor.

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const SAVE_VERSION := 12
const MAX_COMMAND_HISTORY := 100
const MAX_LOG_ENTRIES := 200

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
var scenario_states: Dictionary = {}
var emergent_factions: Dictionary = {}
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
	reputation.clear()
	for faction_id_value in MarketContent.factions().keys():
		reputation[String(faction_id_value)] = 0
	_initialize_adaptive_scenarios()
	reset_visit_slots()
	_update_crisis_modifiers()

func settlement(id: String) -> Dictionary:
	var result: Dictionary = settlements.get(id, {}).duplicate(true)
	if not result.is_empty():
		result["id"] = id
	return result

func route(id: String, origin_id: String = "", destination_id: String = "") -> Dictionary:
	var result: Dictionary = routes.get(id, {}).duplicate(true)
	if result.is_empty():
		return result
	if not origin_id.is_empty() and not destination_id.is_empty():
		var segment := MarketContent.route_segment(id, origin_id, destination_id)
		if not segment.is_empty():
			for field in ["cost", "days", "risk"]:
				result[field] = segment.get(field, result.get(field))
			result["segment_endpoints"] = segment.get("endpoints", []).duplicate()
	var condition_value: Variant = route_conditions.get(id, {})
	if typeof(condition_value) == TYPE_DICTIONARY:
		var condition: Dictionary = condition_value
		if not condition.is_empty():
			result["risk"] = clampf(float(result.get("risk", 0.0)) + float(condition.get("risk_delta", 0.0)), 0.0, 1.0)
			result["cost"] = maxi(0, int(result.get("cost", 0)) + int(condition.get("cost_delta", 0)))
			result["condition"] = condition.duplicate(true)
			result["description"] = "%s Route condition: %s" % [String(result.get("description", "")), String(condition.get("description", ""))]
	var stage := MarketContent.crisis_stage(crisis_stage)
	var stage_effects: Dictionary = stage.get("route_effects", {})
	var stage_effect: Dictionary = stage_effects.get(id, {})
	if not stage_effect.is_empty():
		result["risk"] = clampf(float(result.get("risk", 0.0)) + float(stage_effect.get("risk_delta", 0.0)), 0.0, 1.0)
		result["cost"] = maxi(0, int(result.get("cost", 0)) + int(stage_effect.get("cost_delta", 0)))
		result["crisis_effect"] = String(stage_effect.get("description", ""))
		result["description"] = "%s Crisis pressure: %s" % [String(result.get("description", "")), String(stage_effect.get("description", ""))]
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

func route_provision_cost(route_id: String, destination_id: String = "") -> int:
	var selected := route(route_id, current_settlement, destination_id) if not destination_id.is_empty() else route(route_id)
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
		"adaptive_market_modifiers": adaptive_market_modifiers(),
	}

func scenario_state(scenario_id: String) -> Dictionary:
	var state_value: Variant = scenario_states.get(scenario_id, {})
	return state_value.duplicate(true) if typeof(state_value) == TYPE_DICTIONARY else {}

func emergent_faction(faction_id: String) -> Dictionary:
	var faction_value: Variant = emergent_factions.get(faction_id, {})
	return faction_value.duplicate(true) if typeof(faction_value) == TYPE_DICTIONARY else {}

func adaptive_market_modifiers() -> Dictionary:
	var modifiers: Dictionary = {}
	for faction_id_value in emergent_factions.keys():
		var faction: Dictionary = emergent_faction(String(faction_id_value))
		var scenario := MarketContent.adaptive_scenario(String(faction.get("scenario_id", "")))
		var response: Dictionary = scenario.get("failure_response", {})
		var settlement_id := String(response.get("settlement_id", ""))
		if settlement_id.is_empty():
			continue
		var settlement_modifiers: Dictionary = modifiers.get(settlement_id, {}).duplicate(true)
		var support := int(faction.get("support", 0))
		var support_steps: Dictionary = response.get("support_market_steps", {})
		for good_id_value in response.get("market_modifiers", {}).keys():
			var good_id := String(good_id_value)
			var support_factor := 1.0 + float(support_steps.get(good_id, 0.0)) * float(support)
			settlement_modifiers[good_id] = float(settlement_modifiers.get(good_id, 1.0)) * float(response.get("market_modifiers", {}).get(good_id_value, 1.0)) * support_factor
		modifiers[settlement_id] = settlement_modifiers
	return modifiers

func adaptive_response_summary() -> String:
	var faction_ids: Array = emergent_factions.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction: Dictionary = emergent_faction(String(faction_id_value))
		var scenario := MarketContent.adaptive_scenario(String(faction.get("scenario_id", "")))
		var response: Dictionary = scenario.get("failure_response", {})
		var opportunity: Dictionary = response.get("opportunity", {})
		return "%s · support %+d — %s\n%s" % [String(response.get("name", faction_id_value)), int(faction.get("support", 0)), String(response.get("legitimacy_claim", "A local actor responded to an unmet need.")), String(opportunity.get("summary", response.get("trade_footprint", "A replacement market is now active.")))]
	return ""

func contract_offer_closed_reason(contract_id: String) -> String:
	var scenario := MarketContent.adaptive_scenario_for_contract(contract_id)
	if scenario.is_empty():
		return ""
	var state := scenario_state(String(scenario.get("id", "")))
	if String(state.get("state", "offered")) == "expired":
		return "offer closed on Day %d; %s now responds to the unmet need" % [int(scenario.get("response_day", 0)), String(scenario.get("failure_response", {}).get("name", "a local exchange"))]
	return ""

func adjust_emergent_faction_support(faction_id: String, delta: int, interaction_id: String) -> Dictionary:
	var faction := emergent_faction(faction_id)
	if faction.is_empty():
		return {"ok": false, "reason": "emergent faction is not active"}
	var before := int(faction.get("support", 0))
	var after := clampi(before + delta, -3, 3)
	faction["support"] = after
	var interactions: Array = faction.get("interaction_ids", []).duplicate()
	if not interaction_id.is_empty() and not interactions.has(interaction_id):
		interactions.append(interaction_id)
	faction["interaction_ids"] = interactions
	emergent_factions[faction_id] = faction
	return {"ok": true, "before": before, "after": after, "delta": after - before, "interaction_id": interaction_id}

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
	_evaluate_adaptive_scenarios()
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

func record_market_delivery(settlement_id: String, good_id: String, quantity: int, delivery_mode: String = "ordinary_trade") -> Dictionary:
	if not has_settlement(settlement_id):
		return {"ok": false, "reason": "unknown settlement"}
	if MarketContent.good(good_id).is_empty():
		return {"ok": false, "reason": "unknown good"}
	if quantity <= 0:
		return {"ok": false, "reason": "quantity must be positive"}
	if not ["ordinary_trade", "contract", "event_trade"].has(delivery_mode):
		return {"ok": false, "reason": "unknown delivery mode"}
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
		"delivery_mode": delivery_mode,
	}
	market_delivery_history.append(record)
	if delivery_mode == "ordinary_trade":
		_record_emergent_faction_delivery(settlement_id, good_id, quantity)
	var history_limit := int(rules.get("max_delivery_history", 1))
	while market_delivery_history.size() > history_limit:
		market_delivery_history.pop_front()
	return {"ok": true, "record": record.duplicate(true)}

func _record_emergent_faction_delivery(settlement_id: String, good_id: String, quantity: int) -> void:
	for faction_id_value in emergent_factions.keys():
		var faction_id := String(faction_id_value)
		var faction: Dictionary = emergent_factions.get(faction_id_value, {}).duplicate(true)
		if String(faction.get("settlement_id", "")) != settlement_id:
			continue
		var deliveries: Dictionary = faction.get("ordinary_deliveries", {}).duplicate(true)
		deliveries[good_id] = mini(1000000, int(deliveries.get(good_id, 0)) + quantity)
		faction["ordinary_deliveries"] = deliveries
		emergent_factions[faction_id] = faction

func _update_crisis_modifiers() -> void:
	crisis_modifiers = {}
	for good_id in MarketContent.good_ids():
		crisis_modifiers[good_id] = 1.0
	if crisis_stage >= 1:
		crisis_modifiers["water"] = 1.35
		crisis_modifiers["medicine"] = 1.15
	if crisis_stage >= 2:
		crisis_modifiers["water"] = 1.7
		crisis_modifiers["grain"] = 1.2
	if crisis_stage >= 3:
		crisis_modifiers["water"] = 1.95
		crisis_modifiers["medicine"] = 1.35

func advance_day(days: int, evaluate_campaign: bool = true) -> void:
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
		add_log("Crisis stage %d: %s." % [crisis_stage, String(MarketContent.crisis_stage(crisis_stage).get("label", "Regional pressure"))])
	_evaluate_adaptive_scenarios()
	if evaluate_campaign:
		evaluate_ending()

func evaluate_ending() -> bool:
	if not ending_id.is_empty() or crisis_stage < 3:
		return not ending_id.is_empty()
	for ending in MarketContent.ending_records():
		if not _ending_is_eligible(ending):
			continue
		ending_id = String(ending.get("id", ""))
		ending_summary = String(ending.get("summary", ""))
		add_log("Ending reached: %s — %s" % [String(ending.get("title", ending_id)), ending_summary])
		return true
	return false

func _ending_is_eligible(ending: Dictionary) -> bool:
	if arms_escalation > int(ending.get("maximum_arms_escalation", 6)):
		return false
	if ending.has("required_scenario_id"):
		return _adaptive_ending_is_eligible(ending)
	match String(ending.get("id", "")):
		"open_routes_relief":
			var required_contract_id := String(ending.get("required_contract_id", ""))
			for contract in contract_history:
				if String(contract.get("id", "")) == required_contract_id and String(contract.get("status", "")) == "completed":
					return resilience_for("reedwatch") >= int(ending.get("minimum_reedwatch_resilience", 0))
			return false
		"ending_warden_reserve":
			return int(reputation.get("wardens", 0)) >= int(ending.get("minimum_warden_reputation", 0)) and int(reputation.get("caravans", 0)) <= int(ending.get("maximum_caravan_reputation", 10))
		"ending_free_caravan_routes":
			return int(reputation.get("caravans", 0)) >= int(ending.get("minimum_caravan_reputation", 0)) and int(reputation.get("wardens", 0)) <= int(ending.get("maximum_warden_reputation", 10))
		"ending_ash_merchant":
			return money >= int(ending.get("minimum_money", 0)) and resilience_for("reedwatch") <= int(ending.get("maximum_reedwatch_resilience", 10))
	return false

func _adaptive_ending_is_eligible(ending: Dictionary) -> bool:
	var scenario := scenario_state(String(ending.get("required_scenario_id", "")))
	if not ending.get("required_scenario_states", []).has(String(scenario.get("state", ""))):
		return false
	var faction := emergent_faction(String(ending.get("required_faction_id", "")))
	if faction.is_empty() or int(faction.get("support", 0)) < int(ending.get("minimum_faction_support", 0)):
		return false
	var resilience_requirement: Dictionary = ending.get("minimum_settlement_resilience", {})
	if resilience_for(String(resilience_requirement.get("settlement_id", ""))) < int(resilience_requirement.get("minimum", 0)):
		return false
	var maximum_reputation: Dictionary = ending.get("maximum_reputation", {})
	for faction_id_value in maximum_reputation.keys():
		var faction_id := String(faction_id_value)
		if int(reputation.get(faction_id, 0)) > int(maximum_reputation.get(faction_id_value, 10)):
			return false
	return _ordinary_delivery_requirement_met(ending.get("required_ordinary_delivery", {}), faction.get("ordinary_deliveries", {}))

func _ordinary_delivery_requirement_met(requirement: Dictionary, delivery_value: Variant) -> bool:
	var deliveries: Dictionary = delivery_value if typeof(delivery_value) == TYPE_DICTIONARY else {}
	return int(deliveries.get(String(requirement.get("good_id", "")), 0)) >= int(requirement.get("minimum_quantity", 0))

func _decay_market_pressure(days: int) -> void:
	if days <= 0 or market_pressure.is_empty():
		return
	var rules := MarketContent.market_memory_rules()
	var pressure_min := float(rules.get("pressure_min", 0.0))
	for settlement_id in market_pressure.keys():
		var settlement_pressure: Dictionary = market_pressure.get(settlement_id, {}).duplicate(true)
		for good_id in settlement_pressure.keys():
			var decay := float(days) * MarketEconomy.market_pressure_decay_rate(settlement(String(settlement_id)), String(good_id))
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

func travel(route_id: String, destination_id: String = "") -> Dictionary:
	var selected := route(route_id, current_settlement, destination_id) if not destination_id.is_empty() else route(route_id)
	if selected.is_empty():
		return {"ok": false, "reason": "unknown route"}
	if money < int(selected.cost):
		return {"ok": false, "reason": "not enough money for route cost"}
	var provision_cost := route_provision_cost(route_id, destination_id)
	if provisions < provision_cost:
		return {"ok": false, "reason": "not enough provisions"}
	money -= int(selected.cost)
	provisions -= provision_cost
	advance_day(int(selected.days), false)
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

func add_log(message: String) -> void:
	log.append(message)
	if log.size() > MAX_LOG_ENTRIES:
		log.pop_front()

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
		"scenario_states": scenario_states.duplicate(true),
		"emergent_factions": emergent_factions.duplicate(true),
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
	var validation := _validate_serialized_shape(restored)
	if not validation.ok:
		return validation
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
	scenario_states = _sanitize_scenario_states(restored.get("scenario_states", {}))
	emergent_factions = _sanitize_emergent_factions(restored.get("emergent_factions", {}))
	ending_id = String(restored.get("ending_id", ""))
	ending_summary = String(restored.get("ending_summary", ""))
	log.clear()
	var saved_log: Array = restored.get("log", [])
	for log_entry in saved_log.slice(maxi(0, saved_log.size() - MAX_LOG_ENTRIES)):
		log.append(String(log_entry))
	command_history.clear()
	var saved_history: Array = restored.get("command_history", [])
	for raw_entry in saved_history.slice(maxi(0, saved_history.size() - MAX_COMMAND_HISTORY)):
		if typeof(raw_entry) == TYPE_DICTIONARY:
			command_history.append(raw_entry.duplicate(true))
	_update_crisis_modifiers()
	_evaluate_adaptive_scenarios()
	return {"ok": true, "data": serialize(), "migrated_from": int(migration.migrated_from)}

func _validate_serialized_shape(data: Dictionary) -> Dictionary:
	for field in ["seed", "day", "money", "provisions", "cargo_capacity", "crisis_stage", "visit_slots_remaining", "arms_escalation"]:
		var value: Variant = data.get(field, 0)
		if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
			return {"ok": false, "reason": "save field %s must be numeric" % field}
	if int(data.get("day", 1)) < 1:
		return {"ok": false, "reason": "save day must be at least 1"}
	if int(data.get("money", 0)) < 0 or int(data.get("provisions", 0)) < 0:
		return {"ok": false, "reason": "save resources cannot be negative"}
	if int(data.get("cargo_capacity", 12)) < 1 or int(data.get("cargo_capacity", 12)) > 100:
		return {"ok": false, "reason": "save cargo capacity is outside supported bounds"}
	if int(data.get("crisis_stage", 0)) < 0 or int(data.get("crisis_stage", 0)) > 3:
		return {"ok": false, "reason": "save crisis stage is outside supported bounds"}
	for field in ["cargo", "reputation", "market_pressure", "active_contracts", "journey_context", "pending_event", "route_conditions", "settlement_resilience", "crew_reports", "scenario_states", "emergent_factions"]:
		if typeof(data.get(field, {})) != TYPE_DICTIONARY:
			return {"ok": false, "reason": "save field %s must be an object" % field}
	for field in ["market_delivery_history", "contract_history", "resolved_event_ids", "event_history", "known_information", "recruited_crew", "arms_trade_history", "log", "command_history"]:
		if typeof(data.get(field, [])) != TYPE_ARRAY:
			return {"ok": false, "reason": "save field %s must be a list" % field}
	for field in ["content_version", "current_settlement", "assigned_crew", "ending_id", "ending_summary"]:
		if typeof(data.get(field, "")) != TYPE_STRING:
			return {"ok": false, "reason": "save field %s must be text" % field}
	var settlement_id := String(data.get("current_settlement", "ashgate"))
	if not settlement_id.is_empty() and not has_settlement(settlement_id):
		return {"ok": false, "reason": "save references an unknown current settlement"}
	var saved_ending_id := String(data.get("ending_id", ""))
	if not saved_ending_id.is_empty() and MarketContent.ending(saved_ending_id).is_empty():
		return {"ok": false, "reason": "save references an unknown ending"}
	var contracts: Dictionary = data.get("active_contracts", {})
	var same_content_version := String(data.get("content_version", "")) == MarketContent.content_version()
	for contract_id_value in contracts.keys():
		var contract_id := String(contract_id_value)
		var snapshot: Variant = contracts.get(contract_id_value, {})
		var authored_contract := MarketContent.contract(contract_id)
		if authored_contract.is_empty() or typeof(snapshot) != TYPE_DICTIONARY or String(snapshot.get("id", contract_id)) != contract_id:
			return {"ok": false, "reason": "save references an invalid active contract"}
		if String(snapshot.get("status", "")) != "active" or not has_settlement(String(snapshot.get("origin_id", ""))) or not has_settlement(String(snapshot.get("destination_id", ""))) or MarketContent.good(String(snapshot.get("good_id", ""))).is_empty():
			return {"ok": false, "reason": "save active contract has invalid references or status"}
		for numeric_field in ["quantity", "deadline_days", "reward", "failure_penalty", "service_slots", "accepted_day", "deadline_day"]:
			var numeric_value: Variant = snapshot.get(numeric_field, -1)
			if typeof(numeric_value) != TYPE_INT and typeof(numeric_value) != TYPE_FLOAT:
				return {"ok": false, "reason": "save active contract field %s must be numeric" % numeric_field}
		var accepted_day := int(snapshot.get("accepted_day", 0))
		var deadline_day := int(snapshot.get("deadline_day", 0))
		if int(snapshot.get("quantity", 0)) <= 0 or int(snapshot.get("quantity", 0)) > int(data.get("cargo_capacity", 12)) or int(snapshot.get("reward", -1)) < 0 or int(snapshot.get("failure_penalty", -1)) < 0 or accepted_day < 1 or accepted_day > int(data.get("day", 1)) or deadline_day != accepted_day + int(snapshot.get("deadline_days", 0)):
			return {"ok": false, "reason": "save active contract has invalid frozen terms"}
		if same_content_version:
			for field in authored_contract.keys():
				if snapshot.get(field) != authored_contract.get(field):
					return {"ok": false, "reason": "save active contract does not match authored %s" % field}
	var pending: Dictionary = data.get("pending_event", {})
	var journey: Dictionary = data.get("journey_context", {})
	if pending.is_empty() != journey.is_empty():
		return {"ok": false, "reason": "save has an incomplete pending journey"}
	if not pending.is_empty():
		var event_id := String(pending.get("id", ""))
		var route_id := String(journey.get("route_id", ""))
		var origin_id := String(journey.get("origin_id", ""))
		var destination_id := String(journey.get("destination_id", ""))
		var authored_event := MarketContent.event(event_id)
		if authored_event.is_empty() or typeof(pending.get("choices", [])) != TYPE_ARRAY:
			return {"ok": false, "reason": "save references an invalid pending event"}
		if not MarketContent.route_connects(route_id, origin_id, destination_id) or settlement_id != origin_id:
			return {"ok": false, "reason": "save references an invalid pending journey"}
		if same_content_version:
			for field in ["id", "title", "setup", "stakes", "choices"]:
				if pending.get(field) != authored_event.get(field):
					return {"ok": false, "reason": "save pending event does not match authored %s" % field}
		if String(pending.get("origin_id", "")) != origin_id or String(pending.get("destination_id", "")) != destination_id or String(pending.get("route_id", "")) != route_id:
			return {"ok": false, "reason": "save pending event does not match its journey"}
		for roll_field in ["trigger_roll", "resolution_roll"]:
			var roll_value: Variant = pending.get(roll_field, -1.0)
			if (typeof(roll_value) != TYPE_INT and typeof(roll_value) != TYPE_FLOAT) or float(roll_value) < 0.0 or float(roll_value) > 1.0:
				return {"ok": false, "reason": "save pending event has an invalid %s" % roll_field}
		if same_content_version:
			var basis_validation := _validate_pending_event_bases(pending, authored_event)
			if not basis_validation.ok:
				return basis_validation
	var saved_scenarios: Dictionary = data.get("scenario_states", {})
	for scenario_id_value in saved_scenarios.keys():
		var scenario_id := String(scenario_id_value)
		var state_value: Variant = saved_scenarios.get(scenario_id_value, {})
		if MarketContent.adaptive_scenario(scenario_id).is_empty() or typeof(state_value) != TYPE_DICTIONARY:
			return {"ok": false, "reason": "save references an invalid adaptive scenario"}
		var state: Dictionary = state_value
		if not ["offered", "accepted", "delayed", "failed", "resolved", "expired"].has(String(state.get("state", ""))) or int(state.get("updated_day", 0)) < 1 or int(state.get("updated_day", 0)) > int(data.get("day", 1)):
			return {"ok": false, "reason": "save adaptive scenario has invalid state"}
	var saved_emergent_factions: Dictionary = data.get("emergent_factions", {})
	for faction_id_value in saved_emergent_factions.keys():
		var faction_id := String(faction_id_value)
		var record_value: Variant = saved_emergent_factions.get(faction_id_value, {})
		if typeof(record_value) != TYPE_DICTIONARY:
			return {"ok": false, "reason": "save emergent faction must be an object"}
		var record: Dictionary = record_value
		var scenario := MarketContent.adaptive_scenario(String(record.get("scenario_id", "")))
		if scenario.is_empty() or String(scenario.get("failure_response", {}).get("faction_id", "")) != faction_id or int(record.get("activated_day", 0)) < 1 or int(record.get("activated_day", 0)) > int(data.get("day", 1)):
			return {"ok": false, "reason": "save references an invalid emergent faction"}
		var scenario_state_value: Variant = saved_scenarios.get(String(scenario.get("id", "")), {})
		var scenario_state: Dictionary = scenario_state_value if typeof(scenario_state_value) == TYPE_DICTIONARY else {}
		if not ["delayed", "failed", "expired"].has(String(scenario_state.get("state", ""))) or int(record.get("activated_day", 0)) < int(scenario.get("response_day", 0)):
			return {"ok": false, "reason": "save emergent faction does not match its adaptive scenario state"}
		if int(record.get("support", 0)) < -3 or int(record.get("support", 0)) > 3 or typeof(record.get("interaction_ids", [])) != TYPE_ARRAY:
			return {"ok": false, "reason": "save emergent faction has invalid support state"}
		var ordinary_deliveries_value: Variant = record.get("ordinary_deliveries", {})
		if typeof(ordinary_deliveries_value) != TYPE_DICTIONARY:
			return {"ok": false, "reason": "save emergent faction has invalid ordinary deliveries"}
		for good_id_value in ordinary_deliveries_value.keys():
			if MarketContent.good(String(good_id_value)).is_empty() or int(ordinary_deliveries_value.get(good_id_value, -1)) < 0 or int(ordinary_deliveries_value.get(good_id_value, 0)) > 1000000:
				return {"ok": false, "reason": "save emergent faction has invalid ordinary deliveries"}
		for interaction_id_value in record.get("interaction_ids", []):
			var interaction := MarketContent.settlement_action(String(interaction_id_value))
			if interaction.is_empty() or String(interaction.get("requires_emergent_faction_id", "")) != faction_id:
				return {"ok": false, "reason": "save emergent faction references an invalid interaction"}
	return {"ok": true, "reason": ""}

func _validate_pending_event_bases(pending: Dictionary, authored_event: Dictionary) -> Dictionary:
	for field in ["loss_basis", "material_basis", "trade_basis"]:
		if typeof(pending.get(field, {})) != TYPE_DICTIONARY:
			return {"ok": false, "reason": "save pending event %s must be an object" % field}
	var trigger_good_ids: Array = authored_event.get("trigger_good_ids_any", [])
	var material_basis: Dictionary = pending.get("material_basis", {})
	var material_quantity := int(material_basis.get("quantity", 0))
	var expected_material_quantity := int(authored_event.get("minimum_trigger_good_quantity", 0))
	if material_quantity != expected_material_quantity or not _event_basis_goods_are_valid(material_basis.get("goods", {}), trigger_good_ids, material_quantity):
		return {"ok": false, "reason": "save pending event has an invalid material basis"}
	var trade_basis: Dictionary = pending.get("trade_basis", {})
	var expected_trade_quantity := int(authored_event.get("trade_quantity", 0))
	if expected_trade_quantity <= 0:
		if not trade_basis.is_empty():
			return {"ok": false, "reason": "save pending event has an unexpected trade basis"}
	else:
		var trade_good_id := String(trade_basis.get("good_id", ""))
		var unit_price := int(trade_basis.get("unit_price", -1))
		var premium_per_unit := int(trade_basis.get("premium_per_unit", -1))
		var premium_total := int(trade_basis.get("premium_total", -1))
		if trigger_good_ids.is_empty() or trade_good_id != String(trigger_good_ids[0]) or int(trade_basis.get("quantity", 0)) != expected_trade_quantity:
			return {"ok": false, "reason": "save pending event has an invalid trade basis"}
		if unit_price < 0 or premium_per_unit != int(authored_event.get("premium_per_unit", 0)) or premium_total != expected_trade_quantity * (unit_price + premium_per_unit):
			return {"ok": false, "reason": "save pending event has an invalid trade value"}
		if not _event_basis_goods_are_valid(trade_basis.get("goods", {}), [trade_good_id], expected_trade_quantity):
			return {"ok": false, "reason": "save pending event has invalid trade cargo"}
	var loss_basis: Dictionary = pending.get("loss_basis", {})
	var loss_good_id := String(loss_basis.get("loss_good_id", ""))
	var loss_quantity := int(loss_basis.get("loss_quantity", 0))
	var loss_unit_value := int(loss_basis.get("loss_unit_value", 0))
	if loss_quantity < 0 or loss_quantity > 1 or loss_unit_value < 0 or (not loss_good_id.is_empty() and MarketContent.good(loss_good_id).is_empty()):
		return {"ok": false, "reason": "save pending event has an invalid loss basis"}
	return {"ok": true, "reason": ""}

func _event_basis_goods_are_valid(value: Variant, allowed_good_ids: Array, expected_quantity: int) -> bool:
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var total := 0
	var goods: Dictionary = value
	for good_id_value in goods.keys():
		var good_id := String(good_id_value)
		var quantity_value: Variant = goods.get(good_id_value, 0)
		if not allowed_good_ids.has(good_id) or (typeof(quantity_value) != TYPE_INT and typeof(quantity_value) != TYPE_FLOAT) or int(quantity_value) < 0:
			return false
		total += int(quantity_value)
	return total == expected_quantity

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
	if source_version < 12:
		migrated["save_version"] = 12
		migrated["scenario_states"] = migrated.get("scenario_states", {})
		migrated["emergent_factions"] = migrated.get("emergent_factions", {})
	return {"ok": true, "data": migrated, "migrated_from": source_version}

func _initialize_adaptive_scenarios() -> void:
	scenario_states.clear()
	for scenario in MarketContent.adaptive_scenarios():
		var scenario_id := String(scenario.get("id", ""))
		scenario_states[scenario_id] = {"id": scenario_id, "state": String(scenario.get("initial_state", "offered")), "updated_day": day}

func _evaluate_adaptive_scenarios() -> void:
	for scenario in MarketContent.adaptive_scenarios():
		var scenario_id := String(scenario.get("id", ""))
		var contract_id := String(scenario.get("contract_id", ""))
		var next_state := "offered"
		var outcome_status := ""
		for outcome in contract_history:
			if String(outcome.get("id", "")) == contract_id:
				outcome_status = String(outcome.get("status", ""))
		if outcome_status == "completed":
			next_state = "resolved"
		elif outcome_status == "failed":
			next_state = "failed"
		elif not active_contract(contract_id).is_empty():
			next_state = "delayed" if day > int(active_contract(contract_id).get("deadline_day", day)) else "accepted"
		elif day >= int(scenario.get("response_day", 0)):
			next_state = "expired"
		var previous := scenario_state(scenario_id)
		if String(previous.get("state", "")) != next_state:
			scenario_states[scenario_id] = {"id": scenario_id, "state": next_state, "updated_day": day}
		if ["delayed", "failed", "expired"].has(next_state):
			_activate_adaptive_response(scenario)

func _activate_adaptive_response(scenario: Dictionary) -> void:
	var response: Dictionary = scenario.get("failure_response", {})
	var faction_id := String(response.get("faction_id", ""))
	if faction_id.is_empty() or emergent_factions.has(faction_id):
		return
	emergent_factions[faction_id] = {
		"id": faction_id,
		"scenario_id": String(scenario.get("id", "")),
		"activated_day": day,
		"settlement_id": String(response.get("settlement_id", "")),
		"information_id": String(response.get("information_id", "")),
		"support": 0,
		"interaction_ids": [],
		"ordinary_deliveries": {},
	}
	var resilience_settlement := String(response.get("settlement_id", ""))
	if not resilience_settlement.is_empty():
		adjust_settlement_resilience(resilience_settlement, int(response.get("resilience_delta", 0)))
	add_log("%s emerged on Day %d. %s" % [String(response.get("name", faction_id)), day, String(response.get("trade_footprint", "A replacement market opened."))])

func _sanitize_scenario_states(value: Variant) -> Dictionary:
	var sanitized: Dictionary = {}
	var records: Dictionary = value if typeof(value) == TYPE_DICTIONARY else {}
	for scenario in MarketContent.adaptive_scenarios():
		var scenario_id := String(scenario.get("id", ""))
		var raw_state: Variant = records.get(scenario_id, {})
		var state: Dictionary = raw_state if typeof(raw_state) == TYPE_DICTIONARY else {}
		var state_id := String(state.get("state", scenario.get("initial_state", "offered")))
		if not ["offered", "accepted", "delayed", "failed", "resolved", "expired"].has(state_id):
			state_id = String(scenario.get("initial_state", "offered"))
		sanitized[scenario_id] = {"id": scenario_id, "state": state_id, "updated_day": clampi(int(state.get("updated_day", 1)), 1, day)}
	return sanitized

func _sanitize_emergent_factions(value: Variant) -> Dictionary:
	var sanitized: Dictionary = {}
	var records: Dictionary = value if typeof(value) == TYPE_DICTIONARY else {}
	for faction_id_value in records.keys():
		var raw_record: Variant = records.get(faction_id_value, {})
		if typeof(raw_record) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = raw_record
		var scenario := MarketContent.adaptive_scenario(String(record.get("scenario_id", "")))
		var response: Dictionary = scenario.get("failure_response", {})
		var faction_id := String(faction_id_value)
		if scenario.is_empty() or String(response.get("faction_id", "")) != faction_id:
			continue
		var interactions: Array = []
		for interaction_id_value in record.get("interaction_ids", []):
			var interaction_id := String(interaction_id_value)
			if not interaction_id.is_empty() and not interactions.has(interaction_id):
				interactions.append(interaction_id)
		var ordinary_deliveries: Dictionary = {}
		var delivery_value: Variant = record.get("ordinary_deliveries", {})
		if typeof(delivery_value) == TYPE_DICTIONARY:
			for good_id_value in delivery_value.keys():
				var good_id := String(good_id_value)
				if not MarketContent.good(good_id).is_empty():
					ordinary_deliveries[good_id] = clampi(int(delivery_value.get(good_id_value, 0)), 0, 1000000)
		sanitized[faction_id] = {"id": faction_id, "scenario_id": String(scenario.get("id", "")), "activated_day": clampi(int(record.get("activated_day", 1)), 1, day), "settlement_id": String(response.get("settlement_id", "")), "information_id": String(response.get("information_id", "")), "support": clampi(int(record.get("support", 0)), -3, 3), "interaction_ids": interactions, "ordinary_deliveries": ordinary_deliveries}
	return sanitized

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
		if normalized_id.is_empty() or MarketContent.contract(normalized_id).is_empty():
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
