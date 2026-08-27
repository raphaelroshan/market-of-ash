class_name AshWorldState
extends RefCounted

## Serializable, presentation-agnostic state for the first Market of Ash region.
## The world owns state; commands validate and mutate this state through MarketCommandProcessor.

const MarketContent = preload("res://src/core/market_content.gd")
const SAVE_VERSION := 2
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
	_update_crisis_modifiers()

func settlement(id: String) -> Dictionary:
	var result: Dictionary = settlements.get(id, {}).duplicate(true)
	if not result.is_empty():
		result["id"] = id
	return result

func route(id: String) -> Dictionary:
	return routes.get(id, {}).duplicate(true)

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
	crisis_modifiers = {"grain": 1.0, "water": 1.0, "scrap": 1.0, "medicine": 1.0, "charcoal": 1.0, "cloth": 1.0}
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
	if day >= 4 and crisis_stage == 0:
		crisis_stage = 1
		_update_crisis_modifiers()
		log.append("A water shortage is spreading through the region.")
	elif day >= 7 and crisis_stage == 1:
		crisis_stage = 2
		_update_crisis_modifiers()
		log.append("The water shortage is now changing trade routes and faction demands.")

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
	if provisions < int(selected.days):
		return {"ok": false, "reason": "not enough provisions"}
	money -= int(selected.cost)
	provisions -= int(selected.days)
	advance_day(int(selected.days))
	return {"ok": true, "risk": float(selected.risk), "days": int(selected.days), "cost": int(selected.cost)}

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
	cargo = restored.get("cargo", {"weight": 0}).duplicate(true)
	current_settlement = String(restored.get("current_settlement", current_settlement))
	if not has_settlement(current_settlement):
		current_settlement = "ashgate"
	reputation = restored.get("reputation", reputation).duplicate(true)
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
	return {"ok": true, "data": migrated, "migrated_from": source_version}

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
