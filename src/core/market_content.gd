class_name MarketContent
extends RefCounted

## Canonical runtime content for the first Market of Ash region.
## Authored JSON remains data only; simulation code maps it to explicit commands.

const RUNTIME_WORLD_PATH := "res://content/runtime_world.json"
const REQUIRED_GOOD_IDS := ["grain", "water", "scrap", "medicine", "charcoal", "cloth"]
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
	var endpoints: Variant = route(route_id).get("endpoints", [])
	if typeof(endpoints) != TYPE_ARRAY or endpoints.size() != 2:
		return false
	var forward := String(endpoints[0]) == origin_id and String(endpoints[1]) == destination_id
	var reverse := String(endpoints[1]) == origin_id and String(endpoints[0]) == destination_id
	return forward or reverse

static func routes_from(settlement_id: String) -> Array[String]:
	var ids: Array[String] = []
	for route_id in REQUIRED_ROUTE_IDS:
		var endpoints: Variant = route(route_id).get("endpoints", [])
		if typeof(endpoints) == TYPE_ARRAY and endpoints.has(settlement_id):
			ids.append(route_id)
	return ids

static func destinations_from(settlement_id: String) -> Array[String]:
	var ids: Array[String] = []
	for route_id in routes_from(settlement_id):
		var endpoints: Array = route(route_id).get("endpoints", [])
		for endpoint_id in endpoints:
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
		if int(action.get("cost", -1)) < 0:
			errors.append("settlement action %s cost must be non-negative" % action_id)
		if int(action.get("service_slots", 0)) < 1 or int(action.get("service_slots", 0)) > visit_slots:
			errors.append("settlement action %s service_slots must be between 1 and the visit limit" % action_id)
		if int(action.get("time_cost", -1)) < 0:
			errors.append("settlement action %s time_cost must be non-negative" % action_id)
		var effects_value: Variant = action.get("effects", {})
		if typeof(effects_value) != TYPE_DICTIONARY:
			errors.append("settlement action %s effects must be an object" % action_id)
		elif bool(action.get("available", false)) and action_id == "ashgate_provision_bundle" and int(effects_value.get("provisions", 0)) <= 0:
			errors.append("settlement action ashgate_provision_bundle must add provisions")
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
		var trigger_chance := float(event_record.get("trigger_chance", -1.0))
		if trigger_chance < 0.0 or trigger_chance > 1.0:
			errors.append("event %s trigger_chance must be between 0 and 1" % event_id)
		if int(event_record.get("trigger_roll_salt", -1)) < 0:
			errors.append("event %s trigger_roll_salt must be non-negative" % event_id)
		if int(event_record.get("minimum_cargo_value", -1)) < 0:
			errors.append("event %s minimum_cargo_value must be non-negative" % event_id)
		if typeof(event_record.get("active_contract_relevant", false)) != TYPE_BOOL:
			errors.append("event %s active_contract_relevant must be boolean" % event_id)
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
			for non_negative_field in ["money_cost", "provision_cost", "days"]:
				if int(choice.get(non_negative_field, -1)) < 0:
					errors.append("event %s choice %s %s must be non-negative" % [event_id, choice_id, non_negative_field])
			var cargo_risk := float(choice.get("cargo_risk", -1.0))
			if cargo_risk < 0.0 or cargo_risk > 1.0:
				errors.append("event %s choice %s cargo_risk must be between 0 and 1" % [event_id, choice_id])

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
