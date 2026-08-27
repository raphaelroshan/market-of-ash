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
const USE_SETTLEMENT_ACTION := "use_settlement_action"

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
		USE_SETTLEMENT_ACTION:
			result = _use_settlement_action(world, inputs)
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
	var unit_price := MarketEconomy.price_for(good_id, origin, world.pricing_context())
	var total := unit_price * quantity
	if world.money < total:
		return _failure("you need %d ashmarks, but have %d" % [total, world.money])

	world.money -= total
	world.cargo[good_id] = int(validation.new_quantity)
	world.cargo["weight"] = int(validation.new_weight)
	var message := "Bought %d %s for %d ashmarks. %s." % [quantity, good_id, total, MarketEconomy.explain_price(good_id, origin, world.pricing_context())]
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
	var unit_price := MarketEconomy.price_for(good_id, destination, world.pricing_context())
	var total := unit_price * requested_quantity
	var removed_weight := int(good.get("weight", 0)) * requested_quantity
	var memory_result := world.record_market_delivery(world.current_settlement, good_id, requested_quantity)
	if not memory_result.ok:
		return _failure(String(memory_result.reason))

	world.money += total
	world.cargo[good_id] = held_quantity - requested_quantity
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - removed_weight)
	var memory_record: Dictionary = memory_result.record
	var pressure_points := int(round(float(memory_record.effective_impact) * 100.0))
	var message := "Sold %d %s for %d ashmarks. Your delivery softened this market's %s price pressure by %d%%." % [requested_quantity, good_id, total, good_id, pressure_points]
	world.log.append(message)
	return _success(message, {
		"money": total,
		"cargo": {good_id: -requested_quantity, "weight": -removed_weight},
		"unit_price": unit_price,
		"market_memory": memory_record,
	})

static func _depart_route(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var route_id := String(inputs.get("route_id", ""))
	var destination_id := String(inputs.get("destination_id", ""))
	if not world.has_settlement(destination_id):
		return _failure("unknown destination")
	if destination_id == world.current_settlement:
		return _failure("destination must differ from the current settlement")
	if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		var route := MarketContent.route(route_id)
		if route.is_empty():
			return _failure("unknown route")
		var endpoints: Array = route.get("endpoints", [])
		return _failure("%s does not connect %s to %s" % [String(route.get("name", route_id)), world.settlement(world.current_settlement).get("name", world.current_settlement), world.settlement(destination_id).get("name", destination_id)])
	var selected_route := world.route(route_id)
	var destination := world.settlement(destination_id)
	var loss_basis := MarketEconomy.incident_loss_basis(
		world.cargo,
		destination,
		world.pricing_context(),
	)
	var expected_loss := MarketEconomy.expected_incident_loss(selected_route, loss_basis)
	var travel_result := world.travel(route_id)
	if not travel_result.ok:
		return _failure(String(travel_result.reason))

	world.current_settlement = destination_id
	world.reset_visit_slots()
	var risk: float = float(travel_result.risk)
	var roll := fmod(float(world.seed * 17 + world.day * 31), 100.0) / 100.0
	var state_delta := {
		"money": -int(travel_result.cost),
		"provisions": -int(travel_result.days),
		"day": int(travel_result.days),
		"current_settlement": destination_id,
		"visit_slots_remaining": world.visit_slots_remaining,
		"route_id": route_id,
		"risk": risk,
		"risk_roll": roll,
		"risk_source": String(selected_route.get("description", "Route conditions are uncertain.")),
		"loss_model": String(loss_basis.loss_model),
		"loss_good_id": String(loss_basis.loss_good_id),
		"loss_quantity": int(loss_basis.loss_quantity),
		"loss_unit_value": int(loss_basis.loss_unit_value),
		"loss_value_basis": String(loss_basis.loss_value_basis),
		"expected_loss": expected_loss,
	}
	var message: String
	if roll < risk:
		var lost := _remove_cargo_unit(world, String(loss_basis.loss_good_id))
		state_delta["cargo"] = lost.delta
		if lost.good_id.is_empty():
			message = "The %s was hit by a route incident, but you had no cargo to lose. You arrived at %s." % [world.route(route_id).name, world.settlement(destination_id).name]
		else:
			message = "The %s was hit by a route incident. You lost 1 %s worth %d ashmarks at %s prices, but arrived safely." % [world.route(route_id).name, lost.good_id, int(loss_basis.loss_unit_value), world.settlement(destination_id).name]
	else:
		if String(loss_basis.loss_good_id).is_empty():
			message = "You arrived at %s by the %s. The route held, and no cargo was exposed." % [world.settlement(destination_id).name, world.route(route_id).name]
		else:
			message = "You arrived at %s by the %s. The route held; the exposed %s arrived intact." % [world.settlement(destination_id).name, world.route(route_id).name, String(loss_basis.loss_good_id)]
	world.log.append(message)
	return _success(message, state_delta)

static func _use_settlement_action(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var action_id := String(inputs.get("action_id", ""))
	var action := MarketContent.settlement_action(action_id)
	if action.is_empty():
		return _failure("unknown settlement action")
	if String(action.get("settlement_id", "")) != world.current_settlement:
		var action_settlement := world.settlement(String(action.get("settlement_id", "")))
		return _failure("%s is only available in %s" % [String(action.get("name", action_id)), String(action_settlement.get("name", action.get("settlement_id", "")))])
	if not bool(action.get("available", false)):
		return _failure(String(action.get("unavailable_reason", "this opportunity is not available yet")))
	var slots_required := int(action.get("service_slots", 0))
	if world.visit_slots_remaining < slots_required:
		return _failure("no visit slots remain; depart and arrive at a settlement to refresh them")
	var cost := int(action.get("cost", 0))
	if world.money < cost:
		return _failure("you need %d ashmarks for %s, but have %d" % [cost, String(action.get("name", action_id)), world.money])

	match action_id:
		"ashgate_provision_bundle":
			return _apply_provision_bundle(world, action)
		_:
			return _failure(String(action.get("unavailable_reason", "this opportunity is not implemented yet")))

static func _apply_provision_bundle(world: AshWorldState, action: Dictionary) -> Dictionary:
	var cost := int(action.get("cost", 0))
	var slots_required := int(action.get("service_slots", 1))
	var time_cost := int(action.get("time_cost", 0))
	var effects: Dictionary = action.get("effects", {})
	var provisions_added := int(effects.get("provisions", 0))
	world.money -= cost
	world.provisions += provisions_added
	world.visit_slots_remaining -= slots_required
	if time_cost > 0:
		world.advance_day(time_cost)
	var message := "Packed %d route provisions for %d ashmarks. %d of %d visit slots remain." % [provisions_added, cost, world.visit_slots_remaining, int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2))]
	world.log.append(message)
	return _success(message, {
		"action_id": String(action.id),
		"money": -cost,
		"provisions": provisions_added,
		"day": time_cost,
		"visit_slots": -slots_required,
		"visit_slots_remaining": world.visit_slots_remaining,
	})

static func _remove_cargo_unit(world: AshWorldState, good_id: String) -> Dictionary:
	if good_id.is_empty() or int(world.cargo.get(good_id, 0)) <= 0:
		return {"good_id": "", "delta": {"weight": 0}}
	var weight := int(MarketContent.good(good_id).get("weight", 0))
	world.cargo[good_id] = int(world.cargo.get(good_id, 0)) - 1
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - weight)
	return {"good_id": good_id, "delta": {good_id: -1, "weight": -weight}}

static func _record(world: AshWorldState, command: Dictionary, result: Dictionary) -> Dictionary:
	world.record_command(command, result)
	return result

static func _success(message: String, state_delta: Dictionary) -> Dictionary:
	return {"ok": true, "reason": "", "message": message, "state_delta": state_delta.duplicate(true)}

static func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": reason.capitalize() + ".", "state_delta": {}}
