class_name MarketEconomy
extends RefCounted

## Deterministic, data-driven price calculation for the Market of Ash prototype.
## The simulation contains no rendering or UI dependencies so it can run headlessly.

const MarketContent = preload("res://src/core/market_content.gd")

static func base_price(good: String) -> int:
	return int(MarketContent.good(good).get("base_price", 0))

static func price_for(good: String, settlement: Dictionary, world: Dictionary) -> int:
	var base := base_price(good)
	if base <= 0:
		return 0
	var settlement_modifier: float = float(settlement.get("price_modifiers", {}).get(good, 1.0))
	var demand_modifier: float = float(settlement.get("demand", {}).get(good, 1.0))
	var crisis_modifier: float = float(world.get("crisis_modifiers", {}).get(good, 1.0))
	var faction_modifier: float = float(settlement.get("faction_price_modifier", 1.0))
	return maxi(1, int(round(base * settlement_modifier * demand_modifier * crisis_modifier * faction_modifier)))

static func projected_profit(good: String, quantity: int, origin: Dictionary, destination: Dictionary, world: Dictionary) -> int:
	var buy_price := price_for(good, origin, world)
	var sell_price := price_for(good, destination, world)
	return (sell_price - buy_price) * quantity

static func explain_price(good: String, settlement: Dictionary, world: Dictionary) -> String:
	var reasons: Array[String] = []
	var demand: float = float(settlement.get("demand", {}).get(good, 1.0))
	var crisis: float = float(world.get("crisis_modifiers", {}).get(good, 1.0))
	if demand > 1.15:
		reasons.append("local demand is high")
	elif demand < 0.85:
		reasons.append("local supply is comfortable")
	if crisis > 1.15:
		reasons.append("the regional crisis is increasing demand")
	elif crisis < 0.85:
		reasons.append("the regional crisis is suppressing demand")
	if reasons.is_empty():
		return "normal local conditions"
	return ", ".join(reasons)

static func validate_trade(cargo: Dictionary, good: String, quantity: int, capacity: int) -> Dictionary:
	var good_record := MarketContent.good(good)
	if good_record.is_empty():
		return {"ok": false, "reason": "unknown good"}
	if quantity <= 0:
		return {"ok": false, "reason": "quantity must be positive"}
	var current_weight := int(cargo.get("weight", 0))
	var current_quantity := int(cargo.get(good, 0))
	var added_weight := int(good_record.get("weight", 0)) * quantity
	if current_weight + added_weight > capacity:
		return {"ok": false, "reason": "cargo capacity exceeded"}
	return {
		"ok": true,
		"new_quantity": current_quantity + quantity,
		"new_weight": current_weight + added_weight,
		"added_weight": added_weight,
	}
