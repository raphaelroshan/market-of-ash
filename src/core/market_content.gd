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
			if int(route.get("cost", -1)) < 0:
				errors.append("route %s must have a non-negative cost" % route_id)
			if int(route.get("days", 0)) <= 0:
				errors.append("route %s must have positive days" % route_id)
			var risk := float(route.get("risk", -1.0))
			if risk < 0.0 or risk > 1.0:
				errors.append("route %s risk must be between 0 and 1" % route_id)

	return {"ok": errors.is_empty(), "errors": errors}

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
