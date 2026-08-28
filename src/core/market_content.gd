class_name MarketContent
extends RefCounted

## Canonical runtime content for the first Market of Ash region.
## Authored JSON remains data only; simulation code maps it to explicit commands.

const RUNTIME_WORLD_PATH := "res://content/runtime_world.json"
const REQUIRED_GOOD_IDS := ["grain", "water", "scrap", "medicine", "charcoal", "cloth", "sealed_arms_crate"]
const REQUIRED_SETTLEMENT_IDS := ["ashgate", "brine_cross", "cinderford", "hollow_market", "reedwatch"]
const REQUIRED_ROUTE_IDS := ["old_road", "toll_road", "dry_cut"]

static var _cached_result: Dictionary = {}

static func reset_cache() -> void:
	_cached_result = {}

static func load_runtime() -> Dictionary:
	if not _cached_result.is_empty():
		return _cached_result.duplicate(true)

	var file := FileAccess.open(RUNTIME_WORLD_PATH, FileAccess.READ)
	if file == null:
		_cached_result = _failure(["could not open %s" % RUNTIME_WORLD_PATH])
		return _cached_result.duplicate(true)

	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	if parse_error != OK:
		_cached_result = _failure(["invalid JSON in %s at line %d: %s" % [RUNTIME_WORLD_PATH, json.get_error_line(), json.get_error_message()]])
		return _cached_result.duplicate(true)

	if typeof(json.data) != TYPE_DICTIONARY:
		_cached_result = _failure(["runtime world content must be a JSON object"])
		return _cached_result.duplicate(true)

	var data: Dictionary = json.data
	var validation := validate_runtime(data)
	if not validation.ok:
		_cached_result = _failure(validation.errors)
		return _cached_result.duplicate(true)

	_cached_result = {"ok": true, "data": data.duplicate(true), "errors": []}
	return _cached_result.duplicate(true)

static func runtime_world() -> Dictionary:
	var result := load_runtime()
	if not result.ok:
		return {}
	return result.data.duplicate(true)

static func content_version() -> String:
	return String(runtime_world().get("content_version", "unknown"))

static func planning_assumptions() -> Dictionary:
	var assumptions: Variant = runtime_world().get("planning_assumptions", {})
	if typeof(assumptions) != TYPE_DICTIONARY:
		return {}
	return assumptions.duplicate(true)

static func market_memory_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("market_memory", {})
	if typeof(rules) != TYPE_DICTIONARY:
		return {}
	return rules.duplicate(true)

static func settlement_action_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("settlement_actions", {})
	if typeof(rules) != TYPE_DICTIONARY:
		return {}
	return rules.duplicate(true)

static func settlement_action(action_id: String) -> Dictionary:
	var actions: Array = settlement_action_rules().get("actions", [])
	for raw_action in actions:
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = raw_action
		if String(action.get("id", "")) == action_id:
			return action.duplicate(true)
	return {}

static func settlement_actions_for(settlement_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var actions: Array = settlement_action_rules().get("actions", [])
	for raw_action in actions:
		if typeof(raw_action) != TYPE_DICTIONARY:
			continue
		var action: Dictionary = raw_action
		if String(action.get("settlement_id", "")) == settlement_id:
			matches.append(action.duplicate(true))
	return matches

static func contract_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("contracts", {})
	if typeof(rules) != TYPE_DICTIONARY:
		return {}
	return rules.duplicate(true)

static func contract(contract_id: String) -> Dictionary:
	var records: Array = contract_rules().get("records", [])
	for raw_contract in records:
		if typeof(raw_contract) != TYPE_DICTIONARY:
			continue
		var contract_record: Dictionary = raw_contract
		if String(contract_record.get("id", "")) == contract_id:
			return contract_record.duplicate(true)
	return {}

static func contracts_from(settlement_id: String) -> Array[Dictionary]:
	var matches: Array[Dictionary] = []
	var records: Array = contract_rules().get("records", [])
	for raw_contract in records:
		if typeof(raw_contract) != TYPE_DICTIONARY:
			continue
		var contract_record: Dictionary = raw_contract
		if String(contract_record.get("origin_id", "")) == settlement_id:
			matches.append(contract_record.duplicate(true))
	return matches

static func event_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("events", {})
	if typeof(rules) != TYPE_DICTIONARY:
		return {}
	return rules.duplicate(true)

static func event(event_id: String) -> Dictionary:
	var records: Array = event_rules().get("records", [])
	for raw_event in records:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_record: Dictionary = raw_event
		if String(event_record.get("id", "")) == event_id:
			return event_record.duplicate(true)
	return {}

static func crew_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("crew", {})
	return rules.duplicate(true) if typeof(rules) == TYPE_DICTIONARY else {}

static func crew_member(crew_id: String) -> Dictionary:
	for raw_crew in crew_rules().get("records", []):
		if typeof(raw_crew) == TYPE_DICTIONARY and String(raw_crew.get("id", "")) == crew_id:
			return raw_crew.duplicate(true)
	return {}

static func crew_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for raw_crew in crew_rules().get("records", []):
		if typeof(raw_crew) == TYPE_DICTIONARY:
			records.append(raw_crew.duplicate(true))
	return records

static func faction(faction_id: String) -> Dictionary:
	var records := factions()
	if records.is_empty():
		return {}
	return records.get(faction_id, {}).duplicate(true)

static func factions() -> Dictionary:
	var records: Variant = runtime_world().get("factions", {})
	return records.duplicate(true) if typeof(records) == TYPE_DICTIONARY else {}

static func arms_trade_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("arms_trade", {})
	return rules.duplicate(true) if typeof(rules) == TYPE_DICTIONARY else {}

static func crisis_rules() -> Dictionary:
	var rules: Variant = runtime_world().get("crisis", {})
	return rules.duplicate(true) if typeof(rules) == TYPE_DICTIONARY else {}

static func crisis_stage(stage_id: int) -> Dictionary:
	for raw_stage in crisis_rules().get("stages", []):
		if typeof(raw_stage) == TYPE_DICTIONARY and int(raw_stage.get("id", -1)) == stage_id:
			return raw_stage.duplicate(true)
	return {}

static func ending_records() -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for raw_ending in crisis_rules().get("endings", []):
		if typeof(raw_ending) == TYPE_DICTIONARY:
			records.append(raw_ending.duplicate(true))
	return records

static func ending(ending_id: String) -> Dictionary:
	for ending_record in ending_records():
		if String(ending_record.get("id", "")) == ending_id:
			return ending_record.duplicate(true)
	return {}

static func good_ids() -> Array[String]:
	var ids: Array[String] = []
	var data := runtime_world()
	var goods: Array = data.get("goods", [])
	for raw_good in goods:
		if typeof(raw_good) == TYPE_DICTIONARY:
			var good: Dictionary = raw_good
			ids.append(String(good.get("id", "")))
	return ids

static func good(good_id: String) -> Dictionary:
	var data := runtime_world()
	var goods: Array = data.get("goods", [])
	for raw_good in goods:
		if typeof(raw_good) != TYPE_DICTIONARY:
			continue
		var record: Dictionary = raw_good
		if String(record.get("id", "")) == good_id:
			return record.duplicate(true)
	return {}

static func settlements() -> Dictionary:
	return runtime_world().get("settlements", {}).duplicate(true)

static func settlement_ids() -> Array[String]:
	var ids: Array[String] = []
	var available := settlements()
	for settlement_id in REQUIRED_SETTLEMENT_IDS:
		if available.has(settlement_id):
			ids.append(settlement_id)
	return ids

static func routes() -> Dictionary:
	return runtime_world().get("routes", {}).duplicate(true)

static func route(route_id: String) -> Dictionary:
	return routes().get(route_id, {}).duplicate(true)

static func route_connects(route_id: String, origin_id: String, destination_id: String) -> bool:
	if origin_id == destination_id:
		return false
	var route_record := route(route_id)
	for raw_segment in route_record.get("segments", []):
		if typeof(raw_segment) != TYPE_DICTIONARY:
			continue
		var endpoints: Array = raw_segment.get("endpoints", [])
		if endpoints.size() == 2 and endpoints.has(origin_id) and endpoints.has(destination_id):
			return true
	var endpoints: Variant = route_record.get("endpoints", [])
	return typeof(endpoints) == TYPE_ARRAY and endpoints.size() == 2 and endpoints.has(origin_id) and endpoints.has(destination_id)

static func route_segment(route_id: String, origin_id: String, destination_id: String) -> Dictionary:
	for raw_segment in route(route_id).get("segments", []):
		if typeof(raw_segment) != TYPE_DICTIONARY:
			continue
		var segment: Dictionary = raw_segment
		var endpoints: Array = segment.get("endpoints", [])
		if endpoints.size() == 2 and endpoints.has(origin_id) and endpoints.has(destination_id):
			return segment.duplicate(true)
	return {}

static func routes_from(settlement_id: String) -> Array[String]:
	var ids: Array[String] = []
	for route_id in REQUIRED_ROUTE_IDS:
		var route_record := route(route_id)
		var stops: Variant = route_record.get("stops", route_record.get("endpoints", []))
		if typeof(stops) == TYPE_ARRAY and stops.has(settlement_id):
			ids.append(route_id)
	return ids

static func destinations_from(settlement_id: String) -> Array[String]:
	var ids: Array[String] = []
	for route_id in routes_from(settlement_id):
		var route_record := route(route_id)
		var segments: Array = route_record.get("segments", [])
		if not segments.is_empty():
			for raw_segment in segments:
				if typeof(raw_segment) != TYPE_DICTIONARY:
					continue
				var endpoints: Array = raw_segment.get("endpoints", [])
				if endpoints.has(settlement_id):
					for endpoint_id in endpoints:
						var destination_id := String(endpoint_id)
						if destination_id != settlement_id and not ids.has(destination_id):
							ids.append(destination_id)
			continue
		for endpoint_id in route_record.get("endpoints", []):
			var destination_id := String(endpoint_id)
			if destination_id != settlement_id and not ids.has(destination_id):
				ids.append(destination_id)
	return ids

static func validate_runtime(data: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if int(data.get("schema_version", 0)) != 1:
		errors.append("runtime world content must declare schema_version 1")
	if String(data.get("content_version", "")).is_empty():
		errors.append("runtime world content must declare content_version")

	var planning_value: Variant = data.get("planning_assumptions", {})
	if typeof(planning_value) != TYPE_DICTIONARY:
		errors.append("planning_assumptions must be an object")
	else:
		var planning: Dictionary = planning_value
		if int(planning.get("provision_value", 0)) <= 0:
			errors.append("planning_assumptions must declare a positive provision_value")
		if int(planning.get("time_opportunity_cost_per_day", 0)) < 0:
			errors.append("planning_assumptions must declare a non-negative time_opportunity_cost_per_day")

	_validate_market_memory(data.get("market_memory", {}), errors)

	var goods: Array = data.get("goods", [])
	var seen_goods: Dictionary = {}
	for raw_good in goods:
		if typeof(raw_good) != TYPE_DICTIONARY:
			errors.append("each good must be an object")
			continue
		var good: Dictionary = raw_good
		var good_id := String(good.get("id", ""))
		if good_id.is_empty():
			errors.append("each good must have a stable id")
			continue
		if seen_goods.has(good_id):
			errors.append("duplicate good id: %s" % good_id)
		seen_goods[good_id] = true
		if int(good.get("base_price", 0)) <= 0:
			errors.append("good %s must have a positive base_price" % good_id)
		if int(good.get("weight", 0)) <= 0:
			errors.append("good %s must have a positive weight" % good_id)
	for required_good in REQUIRED_GOOD_IDS:
		if not seen_goods.has(required_good):
			errors.append("missing required good: %s" % required_good)

	var settlements_data: Variant = data.get("settlements", {})
	if typeof(settlements_data) != TYPE_DICTIONARY:
		errors.append("settlements must be an object keyed by stable id")
	else:
		var settlements_dictionary: Dictionary = settlements_data
		for settlement_id in REQUIRED_SETTLEMENT_IDS:
			if not settlements_dictionary.has(settlement_id):
				errors.append("missing required settlement: %s" % settlement_id)
				continue
			var settlement_value: Variant = settlements_dictionary[settlement_id]
			if typeof(settlement_value) != TYPE_DICTIONARY:
				errors.append("settlement %s must be an object" % settlement_id)
				continue
			var settlement: Dictionary = settlement_value
			if String(settlement.get("name", "")).is_empty():
				errors.append("settlement %s must have a name" % settlement_id)
			_validate_modifier_table("settlement %s price_modifiers" % settlement_id, settlement.get("price_modifiers", {}), seen_goods, errors)
			_validate_modifier_table("settlement %s demand" % settlement_id, settlement.get("demand", {}), seen_goods, errors)
			if float(settlement.get("faction_price_modifier", 0.0)) <= 0.0:
				errors.append("settlement %s must have a positive faction_price_modifier" % settlement_id)

	_validate_settlement_actions(data.get("settlement_actions", {}), errors)
	var settlement_action_rules_value: Dictionary = data.get("settlement_actions", {}) if typeof(data.get("settlement_actions", {})) == TYPE_DICTIONARY else {}
	_validate_contracts(data.get("contracts", {}), int(settlement_action_rules_value.get("visit_slots_per_arrival", 0)), errors)
	_validate_crew(data.get("crew", {}), int(settlement_action_rules_value.get("visit_slots_per_arrival", 0)), errors)
	_validate_factions(data.get("factions", {}), errors)
	_validate_arms_trade(data.get("arms_trade", {}), errors)
	_validate_crisis(data.get("crisis", {}), errors)
	_validate_events(data.get("events", {}), errors)

	var routes_data: Variant = data.get("routes", {})
	if typeof(routes_data) != TYPE_DICTIONARY:
		errors.append("routes must be an object keyed by stable id")
	else:
		var routes_dictionary: Dictionary = routes_data
		for route_id in REQUIRED_ROUTE_IDS:
			if not routes_dictionary.has(route_id):
				errors.append("missing required route: %s" % route_id)
				continue
			var route_value: Variant = routes_dictionary[route_id]
			if typeof(route_value) != TYPE_DICTIONARY:
				errors.append("route %s must be an object" % route_id)
				continue
			var route: Dictionary = route_value
			if String(route.get("name", "")).is_empty():
				errors.append("route %s must have a name" % route_id)
			var endpoints_value: Variant = route.get("endpoints", [])
			if typeof(endpoints_value) != TYPE_ARRAY or endpoints_value.size() != 2:
				errors.append("route %s must declare exactly two endpoints" % route_id)
			else:
				var endpoints: Array = endpoints_value
				var origin_id := String(endpoints[0])
				var destination_id := String(endpoints[1])
				if origin_id == destination_id:
					errors.append("route %s endpoints must differ" % route_id)
				if not REQUIRED_SETTLEMENT_IDS.has(origin_id):
					errors.append("route %s has unknown endpoint: %s" % [route_id, origin_id])
				if not REQUIRED_SETTLEMENT_IDS.has(destination_id):
					errors.append("route %s has unknown endpoint: %s" % [route_id, destination_id])
			if int(route.get("cost", -1)) < 0:
				errors.append("route %s must have a non-negative cost" % route_id)
			if int(route.get("days", 0)) <= 0:
				errors.append("route %s must have positive days" % route_id)
			var risk := float(route.get("risk", -1.0))
			if risk < 0.0 or risk > 1.0:
				errors.append("route %s risk must be between 0 and 1" % route_id)
			var segments_value: Variant = route.get("segments", [])
			if typeof(segments_value) != TYPE_ARRAY:
				errors.append("route %s segments must be an array" % route_id)
			else:
				for raw_segment in segments_value:
					if typeof(raw_segment) != TYPE_DICTIONARY:
						errors.append("route %s segments must be objects" % route_id)
						continue
					var segment: Dictionary = raw_segment
					var segment_endpoints: Array = segment.get("endpoints", [])
					if segment_endpoints.size() != 2 or String(segment_endpoints[0]) == String(segment_endpoints[1]):
						errors.append("route %s segment endpoints are invalid" % route_id)
						continue
					for endpoint_id in segment_endpoints:
						if not REQUIRED_SETTLEMENT_IDS.has(String(endpoint_id)):
							errors.append("route %s segment has unknown endpoint: %s" % [route_id, String(endpoint_id)])
					if int(segment.get("cost", -1)) < 0 or int(segment.get("days", 0)) <= 0:
						errors.append("route %s segment cost or days is invalid" % route_id)
					var segment_risk := float(segment.get("risk", -1.0))
					if segment_risk < 0.0 or segment_risk > 1.0:
						errors.append("route %s segment risk must be between 0 and 1" % route_id)

	return {"ok": errors.is_empty(), "errors": errors}

static func _validate_market_memory(value: Variant, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("market_memory must be an object")
		return
	var rules: Dictionary = value
	var pressure_min := float(rules.get("pressure_min", -1.0))
	var pressure_max := float(rules.get("pressure_max", -1.0))
	if not is_equal_approx(pressure_min, 0.0):
		errors.append("market_memory pressure_min must equal 0")
	if pressure_max <= pressure_min or pressure_max >= 1.0:
		errors.append("market_memory pressure_max must be greater than pressure_min and less than 1")
	var sale_impact := float(rules.get("sale_impact_per_unit", 0.0))
	if sale_impact <= 0.0 or sale_impact > pressure_max:
		errors.append("market_memory sale_impact_per_unit must be greater than 0 and no greater than pressure_max")
	var daily_decay := float(rules.get("daily_decay_per_day", 0.0))
	if daily_decay <= 0.0 or daily_decay > pressure_max:
		errors.append("market_memory daily_decay_per_day must be greater than 0 and no greater than pressure_max")
	var effectiveness_value: Variant = rules.get("crisis_effectiveness", {})
	if typeof(effectiveness_value) != TYPE_DICTIONARY:
		errors.append("market_memory crisis_effectiveness must be an object")
	else:
		var effectiveness: Dictionary = effectiveness_value
		for stage in ["0", "1", "2", "3"]:
			if not effectiveness.has(stage):
				errors.append("market_memory crisis_effectiveness must contain stages 0, 1, 2, and 3")
				break
		for stage in effectiveness.keys():
			var multiplier := float(effectiveness.get(stage, 0.0))
			if multiplier <= 0.0 or multiplier > 1.0:
				errors.append("market_memory crisis_effectiveness.%s must be greater than 0 and no greater than 1" % stage)
	var history_limit := int(rules.get("max_delivery_history", 0))
	if history_limit < 1 or history_limit > 100:
		errors.append("market_memory max_delivery_history must be an integer from 1 through 100")

static func _validate_settlement_actions(value: Variant, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("settlement_actions must be an object")
		return
	var rules: Dictionary = value
	var visit_slots := int(rules.get("visit_slots_per_arrival", 0))
	if visit_slots < 1 or visit_slots > 5:
		errors.append("settlement_actions visit_slots_per_arrival must be between 1 and 5")
	var actions_value: Variant = rules.get("actions", [])
	if typeof(actions_value) != TYPE_ARRAY:
		errors.append("settlement_actions actions must be an array")
		return
	var seen_ids: Dictionary = {}
	for raw_action in actions_value:
		if typeof(raw_action) != TYPE_DICTIONARY:
			errors.append("each settlement action must be an object")
			continue
		var action: Dictionary = raw_action
		var action_id := String(action.get("id", ""))
		if action_id.is_empty() or not action_id.is_valid_identifier() or action_id != action_id.to_lower():
			errors.append("settlement action ids must use lower_snake_case")
		elif seen_ids.has(action_id):
			errors.append("duplicate settlement action id: %s" % action_id)
		else:
			seen_ids[action_id] = true
		if not REQUIRED_SETTLEMENT_IDS.has(String(action.get("settlement_id", ""))):
			errors.append("settlement action %s must reference a known settlement" % action_id)
		for required_text in ["name", "category", "description", "tradeoff"]:
			if String(action.get(required_text, "")).is_empty():
				errors.append("settlement action %s must declare %s" % [action_id, required_text])
		if bool(action.get("available", false)) and ["information", "relief"].has(String(action.get("category", ""))) and String(action.get("result", "")).is_empty():
			errors.append("available settlement action %s must declare result" % action_id)
		if int(action.get("cost", -1)) < 0:
			errors.append("settlement action %s cost must be non-negative" % action_id)
		if int(action.get("service_slots", 0)) < 1 or int(action.get("service_slots", 0)) > visit_slots:
			errors.append("settlement action %s service_slots must be between 1 and the visit limit" % action_id)
		if int(action.get("time_cost", -1)) < 0:
			errors.append("settlement action %s time_cost must be non-negative" % action_id)
		var minimum_crisis_stage := int(action.get("minimum_crisis_stage", 0))
		if minimum_crisis_stage < 0 or minimum_crisis_stage > 3:
			errors.append("settlement action %s minimum_crisis_stage must be between 0 and 3" % action_id)
		if typeof(action.get("once_per_campaign", false)) != TYPE_BOOL:
			errors.append("settlement action %s once_per_campaign must be boolean" % action_id)
		if typeof(action.get("requires_completed_contract_id", "")) != TYPE_STRING:
			errors.append("settlement action %s requires_completed_contract_id must be a string" % action_id)
		var effects_value: Variant = action.get("effects", {})
		if typeof(effects_value) != TYPE_DICTIONARY:
			errors.append("settlement action %s effects must be an object" % action_id)
		elif String(action.get("category", "")) == "arms_trade":
			var arms_sale_value: Variant = effects_value.get("arms_sale", {})
			if typeof(arms_sale_value) != TYPE_DICTIONARY:
				errors.append("settlement action %s arms_sale must be an object" % action_id)
			else:
				var arms_sale: Dictionary = arms_sale_value
				if String(arms_sale.get("good_id", "")) != "sealed_arms_crate":
					errors.append("settlement action %s arms_sale must use sealed_arms_crate" % action_id)
				for field in ["quantity", "payout", "escalation_delta"]:
					if int(arms_sale.get(field, 0)) <= 0:
						errors.append("settlement action %s arms_sale %s must be positive" % [action_id, field])
				if String(arms_sale.get("alternative_contract_id", "")).is_empty():
					errors.append("settlement action %s arms_sale must name a non-arms alternative" % action_id)
		elif bool(action.get("available", false)) and action_id == "ashgate_provision_bundle" and int(effects_value.get("provisions", 0)) <= 0:
			errors.append("settlement action ashgate_provision_bundle must add provisions")
		elif bool(action.get("available", false)) and action_id == "brine_cross_cistern_queue":
			var resilience: Dictionary = effects_value.get("settlement_resilience", {})
			if String(effects_value.get("information_id", "")).is_empty():
				errors.append("settlement action brine_cross_cistern_queue must record information")
			if String(resilience.get("settlement_id", "")) != "brine_cross" or int(resilience.get("delta", 0)) <= 0:
				errors.append("settlement action brine_cross_cistern_queue must strengthen Brine Cross resilience")
		elif bool(action.get("available", false)) and action_id == "hollow_market_route_rumor":
			var condition: Dictionary = effects_value.get("route_condition", {})
			if String(effects_value.get("information_id", "")).is_empty():
				errors.append("settlement action hollow_market_route_rumor must record information")
			if String(condition.get("route_id", "")) != "dry_cut" or float(condition.get("risk_delta", 0.0)) >= 0.0:
				errors.append("settlement action hollow_market_route_rumor must reduce Dry Cut risk")
		elif bool(action.get("available", false)) and action_id == "cinderford_repair_bench":
			var condition: Dictionary = effects_value.get("route_condition", {})
			if String(effects_value.get("information_id", "")).is_empty():
				errors.append("settlement action cinderford_repair_bench must record information")
			if String(condition.get("route_id", "")) != "toll_road" or float(condition.get("risk_delta", 0.0)) >= 0.0:
				errors.append("settlement action cinderford_repair_bench must reduce Toll Road risk")
		elif bool(action.get("available", false)) and action_id == "reedwatch_supply_shelter":
			var resilience: Dictionary = effects_value.get("settlement_resilience", {})
			if String(action.get("requires_completed_contract_id", "")) != "reedwatch_water_relief_01":
				errors.append("settlement action reedwatch_supply_shelter must require completed water relief")
			if String(effects_value.get("information_id", "")).is_empty():
				errors.append("settlement action reedwatch_supply_shelter must record information")
			if String(resilience.get("settlement_id", "")) != "reedwatch" or int(resilience.get("delta", 0)) <= 0:
				errors.append("settlement action reedwatch_supply_shelter must strengthen Reedwatch resilience")
		if not bool(action.get("available", false)) and String(action.get("unavailable_reason", "")).is_empty():
			errors.append("unavailable settlement action %s must declare unavailable_reason" % action_id)

static func _validate_contracts(value: Variant, visit_slot_limit: int, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("contracts must be an object")
		return
	var rules: Dictionary = value
	var history_limit := int(rules.get("max_history", 0))
	if history_limit < 1 or history_limit > 100:
		errors.append("contracts max_history must be between 1 and 100")
	var records_value: Variant = rules.get("records", [])
	if typeof(records_value) != TYPE_ARRAY:
		errors.append("contracts records must be an array")
		return
	var seen_ids: Dictionary = {}
	for raw_contract in records_value:
		if typeof(raw_contract) != TYPE_DICTIONARY:
			errors.append("each contract must be an object")
			continue
		var contract_record: Dictionary = raw_contract
		var contract_id := String(contract_record.get("id", ""))
		if contract_id.is_empty() or not contract_id.is_valid_identifier() or contract_id != contract_id.to_lower():
			errors.append("contract ids must use lower_snake_case")
		elif seen_ids.has(contract_id):
			errors.append("duplicate contract id: %s" % contract_id)
		else:
			seen_ids[contract_id] = true
		for required_text in ["name", "sponsor", "description", "tradeoff", "failure_recovery"]:
			if String(contract_record.get(required_text, "")).is_empty():
				errors.append("contract %s must declare %s" % [contract_id, required_text])
		for settlement_field in ["origin_id", "destination_id"]:
			if not REQUIRED_SETTLEMENT_IDS.has(String(contract_record.get(settlement_field, ""))):
				errors.append("contract %s %s must reference a known settlement" % [contract_id, settlement_field])
		if String(contract_record.get("origin_id", "")) == String(contract_record.get("destination_id", "")):
			errors.append("contract %s origin and destination must differ" % contract_id)
		if not REQUIRED_GOOD_IDS.has(String(contract_record.get("good_id", ""))):
			errors.append("contract %s good_id must reference a known good" % contract_id)
		for positive_field in ["quantity", "deadline_days", "reward", "service_slots"]:
			if int(contract_record.get(positive_field, 0)) <= 0:
				errors.append("contract %s %s must be positive" % [contract_id, positive_field])
		if int(contract_record.get("service_slots", 0)) > visit_slot_limit:
			errors.append("contract %s service_slots must not exceed the visit limit" % contract_id)
		if int(contract_record.get("failure_penalty", -1)) < 0:
			errors.append("contract %s failure_penalty must be non-negative" % contract_id)

static func _validate_events(value: Variant, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("events must be an object")
		return
	var rules: Dictionary = value
	var history_limit := int(rules.get("max_history", 0))
	if history_limit < 1 or history_limit > 100:
		errors.append("events max_history must be between 1 and 100")
	var records_value: Variant = rules.get("records", [])
	if typeof(records_value) != TYPE_ARRAY:
		errors.append("events records must be an array")
		return
	var seen_ids: Dictionary = {}
	for raw_event in records_value:
		if typeof(raw_event) != TYPE_DICTIONARY:
			errors.append("each event must be an object")
			continue
		var event_record: Dictionary = raw_event
		var event_id := String(event_record.get("id", ""))
		if event_id.is_empty() or not event_id.is_valid_identifier() or event_id != event_id.to_lower():
			errors.append("event ids must use lower_snake_case")
		elif seen_ids.has(event_id):
			errors.append("duplicate event id: %s" % event_id)
		else:
			seen_ids[event_id] = true
		for required_text in ["title", "category", "setup", "stakes"]:
			if String(event_record.get(required_text, "")).is_empty():
				errors.append("event %s must declare %s" % [event_id, required_text])
		var route_ids: Array = event_record.get("route_ids", [])
		if route_ids.is_empty():
			errors.append("event %s must declare at least one route" % event_id)
		for route_id in route_ids:
			if not REQUIRED_ROUTE_IDS.has(String(route_id)):
				errors.append("event %s references unknown route %s" % [event_id, route_id])
		var destination_ids: Array = event_record.get("destination_ids", [])
		for destination_id in destination_ids:
			if not REQUIRED_SETTLEMENT_IDS.has(String(destination_id)):
				errors.append("event %s references unknown destination %s" % [event_id, destination_id])
		if int(event_record.get("crisis_stage_min", 0)) < 0 or int(event_record.get("crisis_stage_min", 0)) > 3:
			errors.append("event %s crisis_stage_min must be between 0 and 3" % event_id)
		var trigger_chance := float(event_record.get("trigger_chance", -1.0))
		if trigger_chance < 0.0 or trigger_chance > 1.0:
			errors.append("event %s trigger_chance must be between 0 and 1" % event_id)
		if int(event_record.get("trigger_roll_salt", -1)) < 0:
			errors.append("event %s trigger_roll_salt must be non-negative" % event_id)
		if int(event_record.get("minimum_cargo_value", -1)) < 0:
			errors.append("event %s minimum_cargo_value must be non-negative" % event_id)
		if typeof(event_record.get("active_contract_relevant", false)) != TYPE_BOOL:
			errors.append("event %s active_contract_relevant must be boolean" % event_id)
		var trigger_good_ids: Array = event_record.get("trigger_good_ids_any", [])
		for trigger_good_id in trigger_good_ids:
			if not REQUIRED_GOOD_IDS.has(String(trigger_good_id)):
				errors.append("event %s references unknown trigger good %s" % [event_id, trigger_good_id])
		var minimum_trigger_quantity := int(event_record.get("minimum_trigger_good_quantity", 0))
		if minimum_trigger_quantity < 0:
			errors.append("event %s minimum_trigger_good_quantity must be non-negative" % event_id)
		if not trigger_good_ids.is_empty() and minimum_trigger_quantity <= 0:
			errors.append("event %s must require a positive trigger-good quantity" % event_id)
		for event_number_field in ["trade_quantity", "premium_per_unit"]:
			if int(event_record.get(event_number_field, 0)) < 0:
				errors.append("event %s %s must be non-negative" % [event_id, event_number_field])
		var choices: Array = event_record.get("choices", [])
		if choices.size() < 2:
			errors.append("event %s must declare at least two choices" % event_id)
		var seen_choice_ids: Dictionary = {}
		for raw_choice in choices:
			if typeof(raw_choice) != TYPE_DICTIONARY:
				errors.append("event %s choices must be objects" % event_id)
				continue
			var choice: Dictionary = raw_choice
			var choice_id := String(choice.get("id", ""))
			if choice_id.is_empty() or not choice_id.is_valid_identifier() or choice_id != choice_id.to_lower():
				errors.append("event %s choice ids must use lower_snake_case" % event_id)
			elif seen_choice_ids.has(choice_id):
				errors.append("event %s has duplicate choice %s" % [event_id, choice_id])
			else:
				seen_choice_ids[choice_id] = true
			for required_text in ["label", "outcome"]:
				if String(choice.get(required_text, "")).is_empty():
					errors.append("event %s choice %s must declare %s" % [event_id, choice_id, required_text])
			for non_negative_field in ["money_cost", "money_reward", "provision_cost", "material_quantity", "days"]:
				if int(choice.get(non_negative_field, 0)) < 0:
					errors.append("event %s choice %s %s must be non-negative" % [event_id, choice_id, non_negative_field])
			var cargo_risk := float(choice.get("cargo_risk", -1.0))
			if cargo_risk < 0.0 or cargo_risk > 1.0:
				errors.append("event %s choice %s cargo_risk must be between 0 and 1" % [event_id, choice_id])
			var arrival_target := String(choice.get("arrival_target", "destination"))
			if not ["destination", "origin"].has(arrival_target):
					errors.append("event %s choice %s arrival_target must be destination or origin" % [event_id, choice_id])
			var trade_mode := String(choice.get("trade_mode", "none"))
			if not ["none", "premium_sale", "fair_share"].has(trade_mode):
				errors.append("event %s choice %s trade_mode is unsupported" % [event_id, choice_id])
			if typeof(choice.get("requires_active_contract", false)) != TYPE_BOOL:
				errors.append("event %s choice %s requires_active_contract must be boolean" % [event_id, choice_id])
			if int(choice.get("resilience_delta", 0)) < 0 or int(choice.get("resilience_delta", 0)) > 10:
				errors.append("event %s choice %s resilience_delta must be between 0 and 10" % [event_id, choice_id])
			var cargo_cost_value: Variant = choice.get("cargo_cost", {})
			if typeof(cargo_cost_value) != TYPE_DICTIONARY:
				errors.append("event %s choice %s cargo_cost must be an object" % [event_id, choice_id])
			else:
				var cargo_cost: Dictionary = cargo_cost_value
				if not cargo_cost.is_empty():
					if not REQUIRED_GOOD_IDS.has(String(cargo_cost.get("good_id", ""))):
						errors.append("event %s choice %s cargo_cost references an unknown good" % [event_id, choice_id])
					if int(cargo_cost.get("quantity", 0)) <= 0:
						errors.append("event %s choice %s cargo_cost quantity must be positive" % [event_id, choice_id])
			var information_id := String(choice.get("information_id", ""))
			if not information_id.is_empty() and (not information_id.is_valid_identifier() or information_id != information_id.to_lower()):
				errors.append("event %s choice %s information_id must use lower_snake_case" % [event_id, choice_id])
			var required_crew_id := String(choice.get("requires_assigned_crew_id", ""))
			if not required_crew_id.is_empty() and (not required_crew_id.is_valid_identifier() or required_crew_id != required_crew_id.to_lower()):
				errors.append("event %s choice %s requires_assigned_crew_id must use lower_snake_case" % [event_id, choice_id])
			var reputation_delta_value: Variant = choice.get("reputation_delta", {})
			if typeof(reputation_delta_value) != TYPE_DICTIONARY:
				errors.append("event %s choice %s reputation_delta must be an object" % [event_id, choice_id])
			else:
				for faction_id in reputation_delta_value.keys():
					if not ["wardens", "caravans"].has(String(faction_id)) or absi(int(reputation_delta_value.get(faction_id, 0))) > 10:
						errors.append("event %s choice %s reputation_delta is invalid" % [event_id, choice_id])
			var condition_value: Variant = choice.get("route_condition", {})
			if typeof(condition_value) != TYPE_DICTIONARY:
				errors.append("event %s choice %s route_condition must be an object" % [event_id, choice_id])
			else:
				var condition: Dictionary = condition_value
				if not condition.is_empty():
					if not REQUIRED_ROUTE_IDS.has(String(condition.get("route_id", ""))):
						errors.append("event %s choice %s route_condition references an unknown route" % [event_id, choice_id])
					for condition_text in ["id", "label", "description"]:
						if String(condition.get(condition_text, "")).is_empty():
							errors.append("event %s choice %s route_condition must declare %s" % [event_id, choice_id, condition_text])
					var risk_delta := float(condition.get("risk_delta", 0.0))
					if risk_delta < -1.0 or risk_delta > 1.0:
						errors.append("event %s choice %s route_condition risk_delta must be between -1 and 1" % [event_id, choice_id])

static func _validate_crew(value: Variant, visit_slot_limit: int, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("crew must be an object")
		return
	var seen_ids: Dictionary = {}
	for raw_crew in value.get("records", []):
		if typeof(raw_crew) != TYPE_DICTIONARY:
			errors.append("crew records must be objects")
			continue
		var crew: Dictionary = raw_crew
		var crew_id := String(crew.get("id", ""))
		if crew_id.is_empty() or not crew_id.is_valid_identifier() or crew_id != crew_id.to_lower():
			errors.append("crew ids must use lower_snake_case")
		elif seen_ids.has(crew_id):
			errors.append("duplicate crew id: %s" % crew_id)
		else:
			seen_ids[crew_id] = true
		for field in ["name", "role", "personality", "limitation", "hook"]:
			if String(crew.get(field, "")).is_empty():
				errors.append("crew %s must declare %s" % [crew_id, field])
		if not REQUIRED_SETTLEMENT_IDS.has(String(crew.get("recruit_settlement_id", ""))):
			errors.append("crew %s recruit_settlement_id must reference a known settlement" % crew_id)
		if int(crew.get("recruit_cost", -1)) < 0:
			errors.append("crew %s recruit_cost must be non-negative" % crew_id)
		for field in ["recruit_service_slots", "assignment_service_slots"]:
			var slots := int(crew.get(field, 0))
			if slots <= 0 or slots > visit_slot_limit:
				errors.append("crew %s %s must be between 1 and the visit limit" % [crew_id, field])
		if int(crew.get("report_valid_days", -1)) < 0:
			errors.append("crew %s report_valid_days must be non-negative" % crew_id)
		if int(crew.get("provision_discount", -1)) < 0 or int(crew.get("provision_discount", -1)) > 3:
			errors.append("crew %s provision_discount must be between 0 and 3" % crew_id)
		var route_notes: Dictionary = crew.get("route_notes", {})
		for route_id in REQUIRED_ROUTE_IDS:
			if String(route_notes.get(route_id, "")).is_empty():
				errors.append("crew %s route_notes must describe %s" % [crew_id, route_id])

static func _validate_factions(value: Variant, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("factions must be an object")
		return
	var factions: Dictionary = value
	for faction_id in ["wardens", "caravans"]:
		var faction_value: Variant = factions.get(faction_id, {})
		if typeof(faction_value) != TYPE_DICTIONARY:
			errors.append("factions.%s must be an object" % faction_id)
			continue
		var faction: Dictionary = faction_value
		for field in ["name", "below_label", "trusted_label", "effect", "tradeoff"]:
			if String(faction.get(field, "")).is_empty():
				errors.append("factions.%s must declare %s" % [faction_id, field])
		var minimum := int(faction.get("minimum", 0))
		var maximum := int(faction.get("maximum", 0))
		var threshold := int(faction.get("trusted_threshold", 0))
		if minimum >= maximum or threshold <= minimum or threshold > maximum:
			errors.append("factions.%s bounds and trusted_threshold are invalid" % faction_id)
		if not REQUIRED_ROUTE_IDS.has(String(faction.get("toll_route_id", ""))):
			errors.append("factions.%s toll_route_id must reference a known route" % faction_id)
		if int(faction.get("toll_discount", 0)) <= 0:
			errors.append("factions.%s toll_discount must be positive" % faction_id)

static func _validate_arms_trade(value: Variant, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("arms_trade must be an object")
		return
	var rules: Dictionary = value
	var minimum := int(rules.get("minimum", -1))
	var maximum := int(rules.get("maximum", -1))
	var threshold := int(rules.get("inspection_threshold", -1))
	if minimum != 0 or maximum != 6 or threshold <= minimum or threshold > maximum:
		errors.append("arms_trade bounds or inspection_threshold are invalid")
	if not REQUIRED_ROUTE_IDS.has(String(rules.get("inspection_route_id", ""))):
		errors.append("arms_trade inspection_route_id must reference a known route")
	if int(rules.get("inspection_surcharge", 0)) <= 0:
		errors.append("arms_trade inspection_surcharge must be positive")
	for field in ["quiet_label", "noticed_label", "warning", "recovery"]:
		if String(rules.get(field, "")).is_empty():
			errors.append("arms_trade must declare %s" % field)

static func _validate_crisis(value: Variant, errors: Array[String]) -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append("crisis must be an object")
		return
	var rules: Dictionary = value
	var stages: Array = rules.get("stages", [])
	if stages.size() != 4:
		errors.append("crisis must declare exactly four stages")
	for index in range(stages.size()):
		var stage: Dictionary = stages[index]
		if int(stage.get("id", -1)) != index or int(stage.get("starts_day", 0)) <= 0 or String(stage.get("label", "")).is_empty() or String(stage.get("objective", "")).is_empty():
			errors.append("crisis stage %d is invalid" % index)
		var route_effects: Variant = stage.get("route_effects", {})
		if typeof(route_effects) != TYPE_DICTIONARY:
			errors.append("crisis stage %d route_effects must be an object" % index)
			continue
		for route_id_value in route_effects.keys():
			var route_id := String(route_id_value)
			if not REQUIRED_ROUTE_IDS.has(route_id):
				errors.append("crisis stage %d references unknown route %s" % [index, route_id])
				continue
			var effect: Dictionary = route_effects.get(route_id_value, {})
			var risk_delta := float(effect.get("risk_delta", -2.0))
			if risk_delta < -1.0 or risk_delta > 1.0:
				errors.append("crisis stage %d route %s risk_delta is invalid" % [index, route_id])
			if int(effect.get("cost_delta", -1)) < 0 or String(effect.get("description", "")).is_empty():
				errors.append("crisis stage %d route %s cost or description is invalid" % [index, route_id])
	var endings: Array = rules.get("endings", [])
	if endings.size() < 4:
		errors.append("crisis must declare at least four endings")
	var ending_ids: Dictionary = {}
	for raw_ending in endings:
		if typeof(raw_ending) != TYPE_DICTIONARY:
			errors.append("crisis endings must be objects")
			continue
		var ending: Dictionary = raw_ending
		var ending_id := String(ending.get("id", ""))
		for field in ["id", "title", "summary"]:
			if String(ending.get(field, "")).is_empty():
				errors.append("crisis ending must declare %s" % field)
		if ending_ids.has(ending_id):
			errors.append("duplicate crisis ending id: %s" % ending_id)
		ending_ids[ending_id] = true
		if int(ending.get("maximum_arms_escalation", -1)) < 0:
			errors.append("crisis ending maximum_arms_escalation must be non-negative")
		match ending_id:
			"open_routes_relief":
				if String(ending.get("required_contract_id", "")).is_empty() or int(ending.get("minimum_reedwatch_resilience", -1)) < 0:
					errors.append("open_routes_relief must declare its contract and resilience bounds")
			"ending_warden_reserve":
				if int(ending.get("minimum_warden_reputation", -1)) < 0 or int(ending.get("maximum_caravan_reputation", -1)) < 0:
					errors.append("ending_warden_reserve must declare faction bounds")
			"ending_free_caravan_routes":
				if int(ending.get("minimum_caravan_reputation", -1)) < 0 or int(ending.get("maximum_warden_reputation", -1)) < 0:
					errors.append("ending_free_caravan_routes must declare faction bounds")
			"ending_ash_merchant":
				if int(ending.get("minimum_money", -1)) < 0 or int(ending.get("maximum_reedwatch_resilience", -1)) < 0:
					errors.append("ending_ash_merchant must declare money and resilience bounds")
			_:
				errors.append("unsupported crisis ending id: %s" % ending_id)

static func _validate_modifier_table(label: String, table_value: Variant, known_goods: Dictionary, errors: Array[String]) -> void:
	if typeof(table_value) != TYPE_DICTIONARY:
		errors.append("%s must be an object" % label)
		return
	var table: Dictionary = table_value
	for good_id in known_goods.keys():
		if not table.has(good_id):
			errors.append("%s is missing %s" % [label, good_id])
		elif float(table.get(good_id, 0.0)) <= 0.0:
			errors.append("%s must use a positive modifier for %s" % [label, good_id])

static func _failure(errors: Array[String]) -> Dictionary:
	return {"ok": false, "data": {}, "errors": errors.duplicate()}
