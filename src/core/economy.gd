class_name MarketEconomy
extends RefCounted

## Deterministic, data-driven price calculation for the Market of Ash prototype.
## The simulation contains no rendering or UI dependencies so it can run headlessly.

const MarketContent = preload("res://src/core/market_content.gd")
const LOSS_MODEL_ONE_EXPOSED_UNIT := "one_exposed_unit"

static func base_price(good: String) -> int:
	return int(MarketContent.good(good).get("base_price", 0))

static func price_for(good: String, settlement: Dictionary, world: Dictionary) -> int:
	return int(price_details(good, settlement, world).get("unit_price", 0))

static func price_details(good: String, settlement: Dictionary, world: Dictionary) -> Dictionary:
	var base := base_price(good)
	if base <= 0:
		return {"ok": false, "reason": "unknown good", "unit_price": 0, "reasons": []}
	var settlement_modifier: float = float(settlement.get("price_modifiers", {}).get(good, 1.0))
	var demand_modifier: float = float(settlement.get("demand", {}).get(good, 1.0))
	var crisis_modifier: float = float(world.get("crisis_modifiers", {}).get(good, 1.0))
	var faction_modifier: float = float(settlement.get("faction_price_modifier", 1.0))
	var reasons: Array[String] = []
	if settlement_modifier >= 1.15:
		reasons.append("local production is limited")
	elif settlement_modifier <= 0.85:
		reasons.append("local production is abundant")
	if demand_modifier > 1.15:
		reasons.append("local demand is high")
	elif demand_modifier < 0.85:
		reasons.append("local supply is comfortable")
	if crisis_modifier > 1.15:
		reasons.append("the regional crisis is increasing demand")
	elif crisis_modifier < 0.85:
		reasons.append("the regional crisis is suppressing demand")
	if faction_modifier > 1.05:
		reasons.append("local faction terms raise market prices")
	elif faction_modifier < 0.95:
		reasons.append("local faction terms lower market prices")
	if reasons.is_empty():
		reasons.append("normal local conditions")
	return {
		"ok": true,
		"unit_price": maxi(1, int(round(base * settlement_modifier * demand_modifier * crisis_modifier * faction_modifier))),
		"base_price": base,
		"settlement_modifier": settlement_modifier,
		"demand_modifier": demand_modifier,
		"crisis_modifier": crisis_modifier,
		"faction_modifier": faction_modifier,
		"reasons": reasons,
	}

static func projected_profit(good: String, quantity: int, origin: Dictionary, destination: Dictionary, world: Dictionary) -> int:
	var buy_price := price_for(good, origin, world)
	var sell_price := price_for(good, destination, world)
	return (sell_price - buy_price) * quantity

static func explain_price(good: String, settlement: Dictionary, world: Dictionary) -> String:
	var details := price_details(good, settlement, world)
	var reasons: Array = details.get("reasons", [])
	return ", ".join(reasons)

static func incident_loss_basis(cargo: Dictionary, destination: Dictionary, world: Dictionary) -> Dictionary:
	var selected_good_id := ""
	var selected_unit_value := 0
	for good_id in MarketContent.good_ids():
		if int(cargo.get(good_id, 0)) <= 0:
			continue
		var unit_value := price_for(good_id, destination, world)
		if unit_value > selected_unit_value:
			selected_good_id = good_id
			selected_unit_value = unit_value
	return {
		"loss_model": LOSS_MODEL_ONE_EXPOSED_UNIT,
		"loss_good_id": selected_good_id,
		"loss_quantity": 0 if selected_good_id.is_empty() else 1,
		"loss_unit_value": selected_unit_value,
		"loss_value_basis": "destination_unit_price",
	}

static func expected_incident_loss(route: Dictionary, loss_basis: Dictionary) -> int:
	var risk := clampf(float(route.get("risk", 0.0)), 0.0, 1.0)
	var exposed_value := int(loss_basis.get("loss_unit_value", 0)) * int(loss_basis.get("loss_quantity", 0))
	return int(round(exposed_value * risk))

static func route_profit_preview(good: String, quantity: int, origin: Dictionary, destination: Dictionary, route: Dictionary, world: Dictionary) -> Dictionary:
	if base_price(good) <= 0:
		return {"ok": false, "reason": "unknown good"}
	if quantity <= 0:
		return {"ok": false, "reason": "quantity must be positive"}
	if origin.is_empty() or destination.is_empty():
		return {"ok": false, "reason": "origin and destination are required"}
	if route.is_empty():
		return {"ok": false, "reason": "route is required"}
	var assumptions := MarketContent.planning_assumptions()
	var buy_price := price_for(good, origin, world)
	var sell_price := price_for(good, destination, world)
	var purchase_total := buy_price * quantity
	var sale_total := sell_price * quantity
	var route_cost := int(route.get("cost", 0))
	var provisions := int(route.get("days", 0))
	var provision_value := int(assumptions.get("provision_value", 0))
	var provision_cost := provisions * provision_value
	var risk := float(route.get("risk", 0.0))
	var cargo_value: Variant = world.get("cargo", {})
	var cargo: Dictionary = cargo_value if typeof(cargo_value) == TYPE_DICTIONARY else {}
	var loss_basis := incident_loss_basis(cargo, destination, world)
	var expected_loss := expected_incident_loss(route, loss_basis)
	var time_cost := provisions * int(assumptions.get("time_opportunity_cost_per_day", 0))
	var gross_trade_margin := sale_total - purchase_total
	var expected_net_profit := gross_trade_margin - route_cost - provision_cost - expected_loss - time_cost
	return {
		"ok": true,
		"good_id": good,
		"quantity": quantity,
		"purchase_total": purchase_total,
		"sale_total": sale_total,
		"gross_trade_margin": gross_trade_margin,
		"route_cost": route_cost,
		"provisions": provisions,
		"provision_value": provision_value,
		"provision_cost": provision_cost,
		"risk": risk,
		"expected_loss": expected_loss,
		"loss_model": String(loss_basis.loss_model),
		"loss_good_id": String(loss_basis.loss_good_id),
		"loss_quantity": int(loss_basis.loss_quantity),
		"loss_unit_value": int(loss_basis.loss_unit_value),
		"loss_value_basis": String(loss_basis.loss_value_basis),
		"risk_source": String(route.get("description", "Route conditions are uncertain.")),
		"time_cost": time_cost,
		"expected_net_profit": expected_net_profit,
		"origin_price": buy_price,
		"destination_price": sell_price,
	}

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
