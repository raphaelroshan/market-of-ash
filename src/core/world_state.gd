class_name AshWorldState
extends RefCounted

## Serializable, presentation-agnostic state for the first Market of Ash region.
## The world owns state; commands validate and mutate this state through MarketCommandProcessor.

const MarketContent = preload("res://src/core/market_content.gd")
const SAVE_VERSION := 1
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
	return settlements.get(id, {}).duplicate(true)

func route(id: String) -> Dictionary:
	return routes.get(id, {}).duplicate(true)

func has_settlement(id: String) -> bool:
	return settlements.has(id)

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
	day += maxi(0, days)
	if day >= 4 and crisis_stage == 0:
		crisis_stage = 1
		_update_crisis_modifiers()
		log.append("A water shortage is spreading through the region.")
	elif day >= 7 and crisis_stage == 1:
		crisis_stage = 2
		_update_crisis_modifiers()
		log.append("The water shortage is now changing trade routes and faction demands.")

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
	return {"ok": true, "data": migrated, "migrated_from": source_version}
