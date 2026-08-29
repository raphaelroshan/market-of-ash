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
	var settlement_id := String(settlement.get("id", ""))
	var market_pressure_value: Variant = world.get("market_pressure", {})
	var market_pressure_table: Dictionary = market_pressure_value if typeof(market_pressure_value) == TYPE_DICTIONARY else {}
	var settlement_pressure_value: Variant = market_pressure_table.get(settlement_id, {})
	var settlement_pressure: Dictionary = settlement_pressure_value if typeof(settlement_pressure_value) == TYPE_DICTIONARY else {}
	var memory_rules := MarketContent.market_memory_rules()
	var market_pressure := clampf(
		float(settlement_pressure.get(good, memory_rules.get("pressure_min", 0.0))),
		float(memory_rules.get("pressure_min", 0.0)),
		float(memory_rules.get("pressure_max", 0.0)),
	)
	var market_memory_modifier := 1.0 - market_pressure
	var trade_profile: Dictionary = settlement.get("trade_profile", {})
	var produced_goods: Dictionary = trade_profile.get("produces", {})
	var consumed_goods: Dictionary = trade_profile.get("consumes", {})
	var reasons: Array[String] = []
	if produced_goods.has(good):
		reasons.append(String(produced_goods.get(good, "Local production keeps this good available.")))
	elif settlement_modifier >= 1.15:
		reasons.append("local production is limited")
	elif settlement_modifier <= 0.85:
		reasons.append("local production is abundant")
	if consumed_goods.has(good):
		reasons.append(String(consumed_goods.get(good, "Local demand absorbs this good.")))
	elif demand_modifier > 1.15:
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
	if market_pressure > 0.0:
		reasons.append("your recent deliveries increased local supply")
	if reasons.is_empty():
		reasons.append("normal local conditions")
	return {
		"ok": true,
		"unit_price": maxi(1, int(round(base * settlement_modifier * demand_modifier * crisis_modifier * faction_modifier * market_memory_modifier))),
		"base_price": base,
		"settlement_modifier": settlement_modifier,
		"demand_modifier": demand_modifier,
		"crisis_modifier": crisis_modifier,
		"faction_modifier": faction_modifier,
		"market_pressure": market_pressure,
		"market_memory_modifier": market_memory_modifier,
		"reasons": reasons,
	}

static func market_role(settlement: Dictionary, good: String) -> Dictionary:
	var profile: Dictionary = settlement.get("trade_profile", {})
	var produced_goods: Dictionary = profile.get("produces", {})
	var consumed_goods: Dictionary = profile.get("consumes", {})
	return {
		"is_source": produced_goods.has(good),
		"is_consumer": consumed_goods.has(good),
		"source_reason": String(produced_goods.get(good, "This is not one of the settlement's named exports.")),
		"need_reason": String(consumed_goods.get(good, "Demand follows ordinary local conditions.")),
		"settlement_note": String(profile.get("ordinary_trade_note", "Local production and demand set the ordinary market.")),
	}

static func market_pressure_decay_rate(settlement: Dictionary, good: String) -> float:
	var rules := MarketContent.market_memory_rules()
	var base_decay := float(rules.get("daily_decay_per_day", 0.0))
	var role := market_role(settlement, good)
	var multiplier := float(rules.get("neutral_decay_multiplier", 1.0))
	if bool(role.get("is_consumer", false)):
		multiplier = float(rules.get("consumer_decay_multiplier", 1.0))
	elif bool(role.get("is_source", false)):
		multiplier = float(rules.get("producer_decay_multiplier", 1.0))
	return base_decay * multiplier

static func ordinary_trade_story(good: String, quantity: int, origin: Dictionary, destination: Dictionary, route: Dictionary, world: Dictionary) -> Dictionary:
	var preview := route_profit_preview(good, quantity, origin, destination, route, world)
	if not preview.ok:
		return preview
	var origin_role := market_role(origin, good)
	var destination_role := market_role(destination, good)
	return {
		"ok": true,
		"good_id": good,
		"quantity": quantity,
		"origin_name": String(origin.get("name", "Origin")),
		"destination_name": String(destination.get("name", "Destination")),
		"route_name": String(route.get("name", "Route")),
		"origin_price": int(preview.origin_price),
		"destination_price": int(preview.destination_price),
		"unit_spread": int(preview.destination_price) - int(preview.origin_price),
		"gross_margin": int(preview.gross_trade_margin),
		"expected_net_profit": int(preview.expected_net_profit),
		"route_cost": int(preview.route_cost),
		"provisions": int(preview.provisions),
		"risk": float(preview.risk),
		"loss_good_id": String(preview.loss_good_id),
		"source_reason": String(origin_role.source_reason),
		"need_reason": String(destination_role.need_reason),
		"origin_is_source": bool(origin_role.is_source),
		"destination_is_consumer": bool(destination_role.is_consumer),
		"no_contract_required": true,
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

static func cargo_value(cargo: Dictionary, settlement: Dictionary, world: Dictionary) -> int:
	var total := 0
	for good_id in MarketContent.good_ids():
		total += int(cargo.get(good_id, 0)) * price_for(good_id, settlement, world)
	return total

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
	var provisions := int(route.get("provisions", route.get("days", 0)))
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
