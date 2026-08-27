class_name MarketCommandProcessor
extends RefCounted

## Explicit command boundary between presentation and deterministic simulation.
## Commands contain stable IDs and plain input data. Results describe validated state changes.

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")

const BUY_GOODS := "buy_goods"
const SELL_GOODS := "sell_goods"
const DEPART_ROUTE := "depart_route"

static func execute(world: AshWorldState, command: Dictionary) -> Dictionary:
	var command_id := String(command.get("id", ""))
	var inputs_value: Variant = command.get("inputs", {})
	if typeof(inputs_value) != TYPE_DICTIONARY:
		return _record(world, command, _failure("command inputs must be an object"))
	var inputs: Dictionary = inputs_value
	var result: Dictionary
	match command_id:
		BUY_GOODS:
			result = _buy_goods(world, inputs)
		SELL_GOODS:
			result = _sell_goods(world, inputs)
		DEPART_ROUTE:
			result = _depart_route(world, inputs)
		_:
			result = _failure("unknown command: %s" % command_id)
	return _record(world, command, result)

static func _buy_goods(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var good_id := String(inputs.get("good_id", ""))
	var quantity := int(inputs.get("quantity", 0))
	var validation := MarketEconomy.validate_trade(world.cargo, good_id, quantity, world.cargo_capacity)
	if not validation.ok:
		return _failure(String(validation.reason))
	var origin := world.settlement(world.current_settlement)
	if origin.is_empty():
		return _failure("current settlement is unavailable")
	var unit_price := MarketEconomy.price_for(good_id, origin, {"crisis_modifiers": world.crisis_modifiers})
	var total := unit_price * quantity
	if world.money < total:
		return _failure("you need %d ashmarks, but have %d" % [total, world.money])

	world.money -= total
	world.cargo[good_id] = int(validation.new_quantity)
	world.cargo["weight"] = int(validation.new_weight)
	var message := "Bought %d %s for %d ashmarks. %s." % [quantity, good_id, total, MarketEconomy.explain_price(good_id, origin, {"crisis_modifiers": world.crisis_modifiers})]
	world.log.append(message)
	return _success(message, {
		"money": -total,
		"cargo": {good_id: quantity, "weight": int(validation.added_weight)},
		"unit_price": unit_price,
	})

static func _sell_goods(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var good_id := String(inputs.get("good_id", ""))
	var requested_quantity := int(inputs.get("quantity", 0))
	var good := MarketContent.good(good_id)
	if good.is_empty():
		return _failure("unknown good")
	if requested_quantity <= 0:
		return _failure("quantity must be positive")
	var held_quantity := int(world.cargo.get(good_id, 0))
	if held_quantity < requested_quantity:
		return _failure("you do not have %d %s to sell" % [requested_quantity, good_id])
	var destination := world.settlement(world.current_settlement)
	if destination.is_empty():
		return _failure("current settlement is unavailable")
	var unit_price := MarketEconomy.price_for(good_id, destination, {"crisis_modifiers": world.crisis_modifiers})
	var total := unit_price * requested_quantity
	var removed_weight := int(good.get("weight", 0)) * requested_quantity

	world.money += total
	world.cargo[good_id] = held_quantity - requested_quantity
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - removed_weight)
	var message := "Sold %d %s for %d ashmarks." % [requested_quantity, good_id, total]
	world.log.append(message)
	return _success(message, {
		"money": total,
		"cargo": {good_id: -requested_quantity, "weight": -removed_weight},
		"unit_price": unit_price,
	})

static func _depart_route(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var route_id := String(inputs.get("route_id", ""))
	var destination_id := String(inputs.get("destination_id", ""))
	if not world.has_settlement(destination_id):
		return _failure("unknown destination")
	if destination_id == world.current_settlement:
		return _failure("destination must differ from the current settlement")
	var travel_result := world.travel(route_id)
	if not travel_result.ok:
		return _failure(String(travel_result.reason))

	world.current_settlement = destination_id
	var risk: float = float(travel_result.risk)
	var roll := fmod(float(world.seed * 17 + world.day * 31), 100.0) / 100.0
	var state_delta := {
		"money": -int(travel_result.cost),
		"provisions": -int(travel_result.days),
		"day": int(travel_result.days),
		"current_settlement": destination_id,
		"route_id": route_id,
		"risk": risk,
		"risk_roll": roll,
	}
	var message: String
	if roll < risk:
		var lost := _remove_first_cargo_unit(world)
		state_delta["cargo"] = lost.delta
		if lost.good_id.is_empty():
			message = "The %s was hit by a route incident, but you had no cargo to lose. You arrived at %s." % [world.route(route_id).name, world.settlement(destination_id).name]
		else:
			message = "The %s was hit by a route incident. You lost 1 %s, but arrived at %s." % [world.route(route_id).name, lost.good_id, world.settlement(destination_id).name]
	else:
		message = "You arrived at %s by the %s. The route held." % [world.settlement(destination_id).name, world.route(route_id).name]
	world.log.append(message)
	return _success(message, state_delta)

static func _remove_first_cargo_unit(world: AshWorldState) -> Dictionary:
	for good_id in MarketContent.good_ids():
		var held_quantity := int(world.cargo.get(good_id, 0))
		if held_quantity <= 0:
			continue
		var weight := int(MarketContent.good(good_id).get("weight", 0))
		world.cargo[good_id] = held_quantity - 1
		world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - weight)
		return {"good_id": good_id, "delta": {good_id: -1, "weight": -weight}}
	return {"good_id": "", "delta": {"weight": 0}}

static func _record(world: AshWorldState, command: Dictionary, result: Dictionary) -> Dictionary:
	world.record_command(command, result)
	return result

static func _success(message: String, state_delta: Dictionary) -> Dictionary:
	return {"ok": true, "reason": "", "message": message, "state_delta": state_delta.duplicate(true)}

static func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": reason.capitalize() + ".", "state_delta": {}}
