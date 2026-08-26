class_name AshWorldState
extends RefCounted

## Minimal vertical-slice state model. Keep this serializable and presentation-agnostic.

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

var settlements: Dictionary = {
	"ashgate": {
		"name": "Ashgate",
		"role": "regulated hub",
		"price_modifiers": {"grain": 1.0, "water": 0.85, "scrap": 1.1, "medicine": 1.05, "charcoal": 1.0, "cloth": 1.1},
		"demand": {"grain": 1.0, "water": 1.0, "scrap": 0.95, "medicine": 1.0, "charcoal": 1.0, "cloth": 1.1},
		"faction_price_modifier": 1.0,
	},
	"brine_cross": {
		"name": "Brine Cross",
		"role": "water market",
		"price_modifiers": {"grain": 1.1, "water": 0.65, "scrap": 1.0, "medicine": 1.15, "charcoal": 1.0, "cloth": 0.95},
		"demand": {"grain": 1.1, "water": 0.75, "scrap": 1.0, "medicine": 1.2, "charcoal": 1.0, "cloth": 0.95},
		"faction_price_modifier": 1.0,
	},
	"cinderford": {
		"name": "Cinderford",
		"role": "foundry town",
		"price_modifiers": {"grain": 1.15, "water": 1.05, "scrap": 0.65, "medicine": 1.0, "charcoal": 0.7, "cloth": 1.15},
		"demand": {"grain": 1.15, "water": 1.0, "scrap": 0.8, "medicine": 1.0, "charcoal": 0.75, "cloth": 1.0},
		"faction_price_modifier": 1.0,
	},
	"hollow_market": {
		"name": "Hollow Market",
		"role": "free-trade bazaar",
		"price_modifiers": {"grain": 0.9, "water": 1.1, "scrap": 1.0, "medicine": 0.9, "charcoal": 1.1, "cloth": 0.75},
		"demand": {"grain": 0.9, "water": 1.1, "scrap": 1.0, "medicine": 0.9, "charcoal": 1.0, "cloth": 0.8},
		"faction_price_modifier": 0.95,
	},
	"reedwatch": {
		"name": "Reedwatch",
		"role": "frontier settlement",
		"price_modifiers": {"grain": 0.8, "water": 1.25, "scrap": 1.15, "medicine": 1.2, "charcoal": 1.05, "cloth": 0.9},
		"demand": {"grain": 0.8, "water": 1.35, "scrap": 1.15, "medicine": 1.3, "charcoal": 1.0, "cloth": 1.0},
		"faction_price_modifier": 1.05,
	},
}

var routes: Dictionary = {
	"old_road": {"name": "Old Road", "cost": 4, "days": 1, "risk": 0.35, "description": "Cheap, exposed, and watched by opportunists."},
	"toll_road": {"name": "Toll Road", "cost": 12, "days": 1, "risk": 0.10, "description": "Expensive but maintained by the Ash Wardens."},
	"dry_cut": {"name": "Dry Cut", "cost": 2, "days": 2, "risk": 0.55, "description": "Fast on the map, punishing on provisions."},
}

func _init(world_seed: int = 1107) -> void:
	seed = world_seed
	_update_crisis_modifiers()

func settlement(id: String) -> Dictionary:
	return settlements.get(id, {})

func route(id: String) -> Dictionary:
	return routes.get(id, {})

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
	return {"ok": true, "risk": float(selected.risk), "days": int(selected.days)}

func serialize() -> Dictionary:
	return {
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
	}

func load_serialized(data: Dictionary) -> void:
	seed = int(data.get("seed", seed))
	day = int(data.get("day", day))
	money = int(data.get("money", money))
	provisions = int(data.get("provisions", provisions))
	cargo_capacity = int(data.get("cargo_capacity", cargo_capacity))
	cargo = data.get("cargo", {"weight": 0}).duplicate(true)
	current_settlement = String(data.get("current_settlement", current_settlement))
	reputation = data.get("reputation", reputation).duplicate(true)
	crisis_stage = int(data.get("crisis_stage", crisis_stage))
	log = data.get("log", []).duplicate()
	_update_crisis_modifiers()
