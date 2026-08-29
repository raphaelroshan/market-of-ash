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
const ACCEPT_CONTRACT := "accept_contract"
const RESOLVE_CONTRACT := "resolve_contract"
const RESOLVE_EVENT := "resolve_event"
const RECRUIT_CREW := "recruit_crew"
const ASSIGN_CREW := "assign_crew"

static func execute(world: AshWorldState, command: Dictionary) -> Dictionary:
	var command_id := String(command.get("id", ""))
	var inputs_value: Variant = command.get("inputs", {})
	if typeof(inputs_value) != TYPE_DICTIONARY:
		return _record(world, command, _failure("command inputs must be an object"))
	if not world.pending_event.is_empty() and command_id != RESOLVE_EVENT:
		return _record(world, command, _failure("resolve the current route event before taking another action"))
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
		ACCEPT_CONTRACT:
			result = _accept_contract(world, inputs)
		RESOLVE_CONTRACT:
			result = _resolve_contract(world, inputs)
		RESOLVE_EVENT:
			result = _resolve_event(world, inputs)
		RECRUIT_CREW:
			result = _recruit_crew(world, inputs)
		ASSIGN_CREW:
			result = _assign_crew(world, inputs)
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
	world.add_log(message)
	return _success(message, {
		"money": -total,
		"cargo": {good_id: quantity, "weight": int(validation.added_weight)},
		"unit_price": unit_price,
	})

static func _recruit_crew(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var crew_id := String(inputs.get("crew_id", ""))
	var crew := MarketContent.crew_member(crew_id)
	if crew.is_empty():
		return _failure("unknown crew member")
	if world.is_crew_recruited(crew_id):
		return _failure("%s is already recruited" % String(crew.get("name", crew_id)))
	if world.current_settlement != String(crew.get("recruit_settlement_id", "")):
		return _failure("%s can only be recruited in %s" % [String(crew.get("name", crew_id)), String(world.settlement(String(crew.get("recruit_settlement_id", ""))).get("name", "their home settlement"))])
	var cost := int(crew.get("recruit_cost", 0))
	var slots := int(crew.get("recruit_service_slots", 1))
	if world.money < cost:
		return _failure("recruiting %s needs %d ashmarks, but you have %d" % [String(crew.get("name", crew_id)), cost, world.money])
	if world.visit_slots_remaining < slots:
		return _failure("no visit slots remain; depart and arrive to recruit %s later" % String(crew.get("name", crew_id)))
	world.money -= cost
	world.visit_slots_remaining -= slots
	world.recruited_crew.append(crew_id)
	var message := "Recruited %s, %s. %s" % [String(crew.get("name", crew_id)), String(crew.get("role", "crew")), String(crew.get("limitation", ""))]
	world.add_log(message)
	return _success(message, {"crew_id": crew_id, "money": -cost, "visit_slots": -slots, "visit_slots_remaining": world.visit_slots_remaining})

static func _assign_crew(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var crew_id := String(inputs.get("crew_id", ""))
	var crew := MarketContent.crew_member(crew_id)
	if crew.is_empty():
		return _failure("unknown crew member")
	if not world.is_crew_recruited(crew_id):
		return _failure("recruit %s before assigning them" % String(crew.get("name", crew_id)))
	var route_ids := MarketContent.routes_from(world.current_settlement)
	if route_ids.is_empty():
		return _failure("no authored routes leave this settlement, so there is nothing for %s to scout" % String(crew.get("name", crew_id)))
	var slots := int(crew.get("assignment_service_slots", 1))
	if world.visit_slots_remaining < slots:
		return _failure("no visit slots remain; depart and arrive to refresh %s's route notes later" % String(crew.get("name", crew_id)))
	world.visit_slots_remaining -= slots
	world.assigned_crew = crew_id
	var route_notes: Dictionary = crew.get("route_notes", {})
	for route_id in route_ids:
		world.crew_reports[route_id] = {"crew_id": crew_id, "observed_day": world.day, "note": String(route_notes.get(route_id, "Route signs remain uncertain."))}
	var message := "Assigned %s. Same-day scout reports are ready for %s." % [String(crew.get("name", crew_id)), ", ".join(route_ids)]
	world.add_log(message)
	return _success(message, {"crew_id": crew_id, "assigned": true, "visit_slots": -slots, "visit_slots_remaining": world.visit_slots_remaining, "route_ids": route_ids})

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
	world.add_log(message)
	return _success(message, {
		"money": total,
		"cargo": {good_id: -requested_quantity, "weight": -removed_weight},
		"unit_price": unit_price,
		"market_memory": memory_record,
	})

static func _depart_route(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var route_id := String(inputs.get("route_id", ""))
	var destination_id := String(inputs.get("destination_id", ""))
	var origin_id := world.current_settlement
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
	var selected_route := world.route(route_id, origin_id, destination_id)
	var destination := world.settlement(destination_id)
	var loss_basis := MarketEconomy.incident_loss_basis(
		world.cargo,
		destination,
		world.pricing_context(),
	)
	var expected_loss := MarketEconomy.expected_incident_loss(selected_route, loss_basis)
	var cargo_value := MarketEconomy.cargo_value(world.cargo, destination, world.pricing_context())
	var departed_day := world.day
	var travel_result := world.travel(route_id, destination_id)
	if not travel_result.ok:
		return _failure(String(travel_result.reason))

	var risk: float = float(travel_result.risk)
	var state_delta := {
		"money": -int(travel_result.cost),
		"provisions": -int(travel_result.provisions),
		"day": int(travel_result.days),
		"route_id": route_id,
		"risk": risk,
		"risk_source": String(selected_route.get("description", "Route conditions are uncertain.")),
		"loss_model": String(loss_basis.loss_model),
		"loss_good_id": String(loss_basis.loss_good_id),
		"loss_quantity": int(loss_basis.loss_quantity),
		"loss_unit_value": int(loss_basis.loss_unit_value),
		"loss_value_basis": String(loss_basis.loss_value_basis),
		"expected_loss": expected_loss,
	}
	var pending := _select_travel_event(world, origin_id, destination_id, route_id, cargo_value, loss_basis, departed_day)
	if not pending.is_empty():
		var journey := {
			"origin_id": origin_id,
			"destination_id": destination_id,
			"route_id": route_id,
			"departed_day": departed_day,
			"base_arrival_day": world.day,
		}
		world.begin_pending_event(pending, journey)
		state_delta["pending_event"] = pending.duplicate(true)
		state_delta["journey_context"] = journey.duplicate(true)
		var event_message := "%s — %s %s" % [String(pending.title), String(pending.setup), String(pending.stakes)]
		world.add_log(event_message)
		return _success(event_message, state_delta)

	world.current_settlement = destination_id
	world.reset_visit_slots()
	state_delta["current_settlement"] = destination_id
	state_delta["visit_slots_remaining"] = world.visit_slots_remaining
	var roll := fmod(float(world.seed * 17 + world.day * 31), 100.0) / 100.0
	state_delta["risk_roll"] = roll
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
	world.add_log(message)
	var contract_resolutions := _resolve_arrival_contracts(world)
	if not contract_resolutions.is_empty():
		state_delta["contract_resolutions"] = contract_resolutions
		var resolution_messages: Array[String] = []
		for resolution in contract_resolutions:
			resolution_messages.append(String(resolution.get("message", "")))
		message += " " + " ".join(resolution_messages)
	return _success(message, state_delta)

static func _select_travel_event(world: AshWorldState, origin_id: String, destination_id: String, route_id: String, cargo_value: int, loss_basis: Dictionary, departed_day: int) -> Dictionary:
	var records: Array = MarketContent.event_rules().get("records", [])
	for raw_event in records:
		if typeof(raw_event) != TYPE_DICTIONARY:
			continue
		var event_record: Dictionary = raw_event
		var event_id := String(event_record.get("id", ""))
		if world.has_resolved_event(event_id):
			continue
		var route_ids: Array = event_record.get("route_ids", [])
		if not route_ids.has(route_id):
			continue
		var destination_ids: Array = event_record.get("destination_ids", [])
		if not destination_ids.is_empty() and not destination_ids.has(destination_id):
			continue
		if world.crisis_stage < int(event_record.get("crisis_stage_min", 0)):
			continue
		var trigger_good_ids: Array = event_record.get("trigger_good_ids_any", [])
		var minimum_trigger_quantity := int(event_record.get("minimum_trigger_good_quantity", 0))
		var material_basis := _event_material_basis(world.cargo, trigger_good_ids, minimum_trigger_quantity)
		if not trigger_good_ids.is_empty() and int(material_basis.get("quantity", 0)) < minimum_trigger_quantity:
			continue
		var contract_relevant := bool(event_record.get("active_contract_relevant", false)) and not world.active_contracts.is_empty()
		if cargo_value < int(event_record.get("minimum_cargo_value", 0)) and not contract_relevant:
			continue
		var salt := int(event_record.get("trigger_roll_salt", 0))
		var trigger_roll := fmod(float(world.seed * 13 + world.day * 17 + salt), 100.0) / 100.0
		if trigger_roll >= float(event_record.get("trigger_chance", 0.0)):
			continue
		var snapshot := event_record.duplicate(true)
		snapshot["origin_id"] = origin_id
		snapshot["destination_id"] = destination_id
		snapshot["route_id"] = route_id
		snapshot["departed_day"] = departed_day
		snapshot["base_arrival_day"] = world.day
		snapshot["trigger_roll"] = trigger_roll
		snapshot["resolution_roll"] = fmod(float(world.seed * 31 + world.day * 41 + salt * 3), 100.0) / 100.0
		snapshot["loss_basis"] = loss_basis.duplicate(true)
		snapshot["material_basis"] = material_basis.duplicate(true)
		snapshot["trade_basis"] = _event_trade_basis(world, event_record, destination_id)
		return snapshot
	return {}

static func _resolve_event(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var event_id := String(inputs.get("event_id", ""))
	var choice_id := String(inputs.get("choice_id", ""))
	var pending := world.pending_event.duplicate(true)
	if pending.is_empty():
		return _failure("no route event is pending")
	if String(pending.get("id", "")) != event_id:
		return _failure("a different route event is pending")
	var choice := _event_choice(pending, choice_id)
	if choice.is_empty():
		return _failure("unknown event choice")
	var money_cost := int(choice.get("money_cost", 0))
	var money_reward := int(choice.get("money_reward", 0))
	var provision_cost := int(choice.get("provision_cost", 0))
	var material_quantity := int(choice.get("material_quantity", 0))
	var trade_mode := String(choice.get("trade_mode", "none"))
	var trade_basis: Dictionary = pending.get("trade_basis", {})
	var trade_quantity := int(trade_basis.get("quantity", 0)) if trade_mode != "none" else 0
	var cargo_cost: Dictionary = choice.get("cargo_cost", {})
	var cargo_cost_quantity := int(cargo_cost.get("quantity", 0))
	var cargo_cost_good_id := String(cargo_cost.get("good_id", ""))
	if world.money < money_cost:
		return _failure("this choice needs %d ashmarks, but you have %d; choose another available route response" % [money_cost, world.money])
	if world.provisions < provision_cost:
		return _failure("this choice needs %d provision, but you have %d; choose another available route response" % [provision_cost, world.provisions])
	var material_basis: Dictionary = pending.get("material_basis", {})
	if material_quantity > 0 and not _event_materials_available(world, material_basis, material_quantity):
		return _failure("this choice needs %d of the disclosed repair-material units; choose the message or turn-back response" % material_quantity)
	var journey := world.journey_context.duplicate(true)
	var destination_id := String(journey.get("destination_id", ""))
	if not world.has_settlement(destination_id):
		return _failure("pending journey destination is unavailable")
	if trade_quantity > 0 and not _event_materials_available(world, trade_basis, trade_quantity):
		return _failure("this choice needs %d %s, but the frozen event cargo is no longer held; keep the remaining load sealed" % [trade_quantity, String(trade_basis.get("good_id", "cargo"))])
	if cargo_cost_quantity > 0 and int(world.cargo.get(cargo_cost_good_id, 0)) < cargo_cost_quantity:
		return _failure("this choice needs %d %s, but you have %d; choose another available route response" % [cargo_cost_quantity, cargo_cost_good_id, int(world.cargo.get(cargo_cost_good_id, 0))])
	if bool(choice.get("requires_active_contract", false)) and not _has_relevant_active_contract(world, destination_id, String(trade_basis.get("good_id", "water"))):
		return _failure("this response needs an active water relief commitment for this destination; choose a sale, share, or sealed-cargo response")
	var required_crew_id := String(choice.get("requires_assigned_crew_id", ""))
	if not required_crew_id.is_empty() and world.assigned_crew != required_crew_id:
		return _failure("this response requires %s to be assigned" % String(MarketContent.crew_member(required_crew_id).get("name", required_crew_id)))
	var arrival_target := String(choice.get("arrival_target", "destination"))
	var resulting_settlement_id := String(journey.get("origin_id", "")) if arrival_target == "origin" else destination_id
	if not world.has_settlement(resulting_settlement_id):
		return _failure("pending journey result settlement is unavailable")
	var route_condition: Dictionary = choice.get("route_condition", {})
	if not route_condition.is_empty():
		if world.route(String(route_condition.get("route_id", ""))).is_empty():
			return _failure("event route condition references an unavailable route")
		if String(route_condition.get("id", "")).is_empty():
			return _failure("event route condition needs a stable id")

	world.money -= money_cost
	if trade_mode == "premium_sale":
		money_reward += int(trade_basis.get("premium_total", 0))
	world.money += money_reward
	world.provisions -= provision_cost
	var material_delta: Dictionary = {}
	var material_summary := ""
	if material_quantity > 0:
		var removed_materials := _remove_event_materials(world, material_basis, material_quantity)
		material_delta = removed_materials.delta
		material_summary = String(removed_materials.summary)
	var trade_delta: Dictionary = {}
	var market_memory: Dictionary = {}
	if trade_quantity > 0:
		var removed_trade := _remove_event_materials(world, trade_basis, trade_quantity)
		trade_delta = removed_trade.delta
		var delivery_result := world.record_market_delivery(destination_id, String(trade_basis.get("good_id", "")), trade_quantity, "event_trade")
		if delivery_result.ok:
			market_memory = delivery_result.record
	var specific_cargo_delta: Dictionary = {}
	if cargo_cost_quantity > 0:
		var specific_basis := {"quantity": cargo_cost_quantity, "goods": {cargo_cost_good_id: cargo_cost_quantity}}
		specific_cargo_delta = _remove_event_materials(world, specific_basis, cargo_cost_quantity).delta
	var extra_days := int(choice.get("days", 0))
	if extra_days > 0:
		world.advance_day(extra_days, false)
	var cargo_delta: Dictionary = {}
	var cargo_loss_message := ""
	var cargo_risk := float(choice.get("cargo_risk", 0.0))
	var resolution_roll := float(pending.get("resolution_roll", 1.0))
	var loss_basis: Dictionary = pending.get("loss_basis", {})
	if cargo_risk > 0.0 and resolution_roll < cargo_risk:
		var lost := _remove_cargo_unit(world, String(loss_basis.get("loss_good_id", "")))
		cargo_delta = lost.delta
		if not String(lost.good_id).is_empty():
			cargo_loss_message = " The route choice cost 1 %s worth %d ashmarks at the destination." % [String(lost.good_id), int(loss_basis.get("loss_unit_value", 0))]

	var applied_condition: Dictionary = {}
	if not route_condition.is_empty():
		var condition_result := world.set_route_condition(String(route_condition.get("route_id", "")), route_condition)
		if not condition_result.ok:
			return _failure(String(condition_result.reason))
		applied_condition = condition_result.condition
	var resilience_result: Dictionary = {}
	var resilience_delta := int(choice.get("resilience_delta", 0))
	if resilience_delta > 0:
		resilience_result = world.adjust_settlement_resilience(destination_id, resilience_delta)
	var information_id := String(choice.get("information_id", ""))
	var information_added := world.record_information(information_id) if not information_id.is_empty() else false
	var reputation_results: Dictionary = {}
	var reputation_delta: Dictionary = choice.get("reputation_delta", {})
	for faction_id_value in reputation_delta.keys():
		var faction_id := String(faction_id_value)
		var reputation_result := world.adjust_reputation(faction_id, int(reputation_delta.get(faction_id_value, 0)))
		if reputation_result.ok:
			reputation_results[faction_id] = reputation_result

	world.current_settlement = resulting_settlement_id
	world.reset_visit_slots()
	for good_id in material_delta.keys():
		if good_id == "weight":
			continue
		cargo_delta[good_id] = int(cargo_delta.get(good_id, 0)) + int(material_delta.get(good_id, 0))
	if material_delta.has("weight"):
		cargo_delta["weight"] = int(cargo_delta.get("weight", 0)) + int(material_delta.get("weight", 0))
	for good_id in trade_delta.keys():
		cargo_delta[good_id] = int(cargo_delta.get(good_id, 0)) + int(trade_delta.get(good_id, 0))
	for good_id in specific_cargo_delta.keys():
		cargo_delta[good_id] = int(cargo_delta.get(good_id, 0)) + int(specific_cargo_delta.get(good_id, 0))
	var outcome := {
		"money": money_reward - money_cost,
		"provisions": -provision_cost,
		"day": extra_days,
		"cargo": cargo_delta,
		"cargo_risk": cargo_risk,
		"resolution_roll": resolution_roll,
		"current_settlement": resulting_settlement_id,
		"visit_slots_remaining": world.visit_slots_remaining,
		"route_condition": applied_condition,
		"market_memory": market_memory,
		"settlement_resilience": resilience_result,
		"information_id": information_id if information_added else "",
		"reputation": reputation_results,
	}
	var archived := world.archive_pending_event(choice_id, outcome)
	var material_message := " The crew took %s." % material_summary if not material_summary.is_empty() else ""
	var trade_message := " The ration line received %d %s; the local market now remembers that supply." % [trade_quantity, String(trade_basis.get("good_id", "cargo"))] if trade_quantity > 0 else ""
	var resilience_message := " %s resilience is now %d/10." % [String(world.settlement(destination_id).name), int(resilience_result.get("after", 0))] if not resilience_result.is_empty() else ""
	var information_message := " New information recorded: %s." % information_id.replace("_", " ") if information_added else ""
	var reputation_message := " Warden standing is now %d." % int(world.reputation.get("wardens", 0)) if reputation_results.has("wardens") else ""
	var movement_message := "You returned to %s." % String(world.settlement(resulting_settlement_id).name) if arrival_target == "origin" else "You arrived at %s." % String(world.settlement(resulting_settlement_id).name)
	var message := "%s %s%s%s%s%s%s%s %s" % [String(choice.get("label", "Choice resolved.")), String(choice.get("outcome", "")), material_message, trade_message, resilience_message, information_message, reputation_message, cargo_loss_message, movement_message]
	world.add_log(message)
	var contract_resolutions: Array[Dictionary] = []
	if arrival_target == "destination":
		contract_resolutions = _resolve_arrival_contracts(world)
	if not contract_resolutions.is_empty():
		outcome["contract_resolutions"] = contract_resolutions
		var contract_messages: Array[String] = []
		for resolution in contract_resolutions:
			contract_messages.append(String(resolution.get("message", "")))
		message += " " + " ".join(contract_messages)
	return _success(message, {
		"event_id": event_id,
		"choice_id": choice_id,
		"event": archived,
		"outcome": outcome,
	})

static func _event_choice(event_record: Dictionary, choice_id: String) -> Dictionary:
	var choices: Array = event_record.get("choices", [])
	for raw_choice in choices:
		if typeof(raw_choice) != TYPE_DICTIONARY:
			continue
		var choice: Dictionary = raw_choice
		if String(choice.get("id", "")) == choice_id:
			return choice.duplicate(true)
	return {}

static func _event_material_basis(cargo: Dictionary, good_ids: Array, requested_quantity: int) -> Dictionary:
	if good_ids.is_empty() or requested_quantity <= 0:
		return {"quantity": 0, "goods": {}}
	var remaining := requested_quantity
	var goods: Dictionary = {}
	for good_id_value in good_ids:
		var good_id := String(good_id_value)
		var selected := mini(remaining, int(cargo.get(good_id, 0)))
		if selected > 0:
			goods[good_id] = selected
			remaining -= selected
		if remaining <= 0:
			break
	return {"quantity": requested_quantity - remaining, "goods": goods}

static func _event_trade_basis(world: AshWorldState, event_record: Dictionary, destination_id: String) -> Dictionary:
	var quantity := int(event_record.get("trade_quantity", 0))
	var good_ids: Array = event_record.get("trigger_good_ids_any", [])
	var basis := _event_material_basis(world.cargo, good_ids, quantity)
	if int(basis.get("quantity", 0)) < quantity or good_ids.is_empty():
		return {}
	var good_id := String(good_ids[0])
	var unit_price := MarketEconomy.price_for(good_id, world.settlement(destination_id), world.pricing_context())
	var premium_per_unit := int(event_record.get("premium_per_unit", 0))
	basis["good_id"] = good_id
	basis["unit_price"] = unit_price
	basis["premium_per_unit"] = premium_per_unit
	basis["premium_total"] = quantity * (unit_price + premium_per_unit)
	return basis

static func _has_relevant_active_contract(world: AshWorldState, destination_id: String, good_id: String) -> bool:
	for contract_id in world.active_contracts.keys():
		var contract := world.active_contract(String(contract_id))
		if String(contract.get("destination_id", "")) == destination_id and String(contract.get("good_id", "")) == good_id:
			return true
	return false

static func _event_materials_available(world: AshWorldState, basis: Dictionary, requested_quantity: int) -> bool:
	if int(basis.get("quantity", 0)) < requested_quantity:
		return false
	var available := 0
	var goods: Dictionary = basis.get("goods", {})
	for good_id in goods.keys():
		available += mini(int(goods.get(good_id, 0)), int(world.cargo.get(good_id, 0)))
	return available >= requested_quantity

static func _remove_event_materials(world: AshWorldState, basis: Dictionary, requested_quantity: int) -> Dictionary:
	var remaining := requested_quantity
	var delta: Dictionary = {}
	var summary_parts: Array[String] = []
	var removed_weight := 0
	var goods: Dictionary = basis.get("goods", {})
	for good_id_value in goods.keys():
		if remaining <= 0:
			break
		var good_id := String(good_id_value)
		var removed := mini(remaining, mini(int(goods.get(good_id, 0)), int(world.cargo.get(good_id, 0))))
		if removed <= 0:
			continue
		world.cargo[good_id] = int(world.cargo.get(good_id, 0)) - removed
		var weight := removed * int(MarketContent.good(good_id).get("weight", 0))
		removed_weight += weight
		delta[good_id] = -removed
		summary_parts.append("%d %s" % [removed, good_id])
		remaining -= removed
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - removed_weight)
	delta["weight"] = -removed_weight
	return {"delta": delta, "summary": " and ".join(summary_parts)}

static func _accept_contract(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var contract_id := String(inputs.get("contract_id", ""))
	var contract_record := MarketContent.contract(contract_id)
	if contract_record.is_empty():
		return _failure("unknown contract")
	if String(contract_record.get("origin_id", "")) != world.current_settlement:
		return _failure("%s can only be accepted in %s" % [String(contract_record.get("name", contract_id)), String(world.settlement(String(contract_record.get("origin_id", ""))).get("name", contract_record.get("origin_id", "")))])
	var blocked_reason := contract_acceptance_reason(world, contract_record)
	if not blocked_reason.is_empty():
		return _failure(blocked_reason)
	var slots_required := int(contract_record.get("service_slots", 1))
	var good_id := String(contract_record.get("good_id", ""))
	var quantity := int(contract_record.get("quantity", 0))
	var snapshot := contract_record.duplicate(true)
	snapshot["accepted_day"] = world.day
	snapshot["deadline_day"] = world.day + int(contract_record.get("deadline_days", 0))
	snapshot["status"] = "active"
	world.active_contracts[contract_id] = snapshot
	world.visit_slots_remaining -= slots_required
	world._evaluate_adaptive_scenarios()
	var message := "Accepted %s. Deliver %d %s to %s by Day %d for %d ashmarks. %d visit slot remains." % [String(snapshot.name), quantity, good_id, String(world.settlement(String(snapshot.destination_id)).name), int(snapshot.deadline_day), int(snapshot.reward), world.visit_slots_remaining]
	world.add_log(message)
	return _success(message, {
		"contract_id": contract_id,
		"status": "active",
		"accepted_day": world.day,
		"deadline_day": int(snapshot.deadline_day),
		"visit_slots": -slots_required,
		"visit_slots_remaining": world.visit_slots_remaining,
	})

static func contract_acceptance_reason(world: AshWorldState, contract_record: Dictionary) -> String:
	var contract_id := String(contract_record.get("id", ""))
	var closed_reason := world.contract_offer_closed_reason(contract_id)
	if not closed_reason.is_empty():
		return closed_reason
	if not world.active_contract(contract_id).is_empty():
		return "contract is already active"
	if world.has_contract_outcome(contract_id):
		return "contract has already been resolved"
	var minimum_reputation: Dictionary = contract_record.get("minimum_reputation", {})
	var faction_ids: Array = minimum_reputation.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := String(faction_id_value)
		var required := int(minimum_reputation.get(faction_id_value, 0))
		var held := int(world.reputation.get(faction_id, 0))
		if held < required:
			return "requires %d %s standing; you have %d" % [required, String(MarketContent.faction(faction_id).get("name", faction_id)), held]
	var slots_required := int(contract_record.get("service_slots", 1))
	if world.visit_slots_remaining < slots_required:
		return "no visit slots remain; depart and arrive at a settlement to refresh them"
	var good_id := String(contract_record.get("good_id", ""))
	var quantity := int(contract_record.get("quantity", 0))
	var required_weight := int(MarketContent.good(good_id).get("weight", 0)) * quantity
	var free_capacity := world.cargo_capacity - int(world.cargo.get("weight", 0))
	if free_capacity < required_weight:
		return "contract requires %d free cargo space, but only %d is available" % [required_weight, free_capacity]
	return ""

static func _apply_contract_reputation(world: AshWorldState, effects: Dictionary) -> Dictionary:
	var results := {}
	var faction_ids: Array = effects.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := String(faction_id_value)
		results[faction_id] = world.adjust_reputation(faction_id, int(effects.get(faction_id_value, 0)))
	return results

static func _contract_reputation_message(effects: Dictionary) -> String:
	if effects.is_empty():
		return ""
	var parts: Array[String] = []
	var faction_ids: Array = effects.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := String(faction_id_value)
		var delta := int(effects.get(faction_id_value, 0))
		if delta != 0:
			parts.append("%s standing %+d" % [String(MarketContent.faction(faction_id).get("name", faction_id)), delta])
	return "; ".join(parts)

static func _resolve_contract(world: AshWorldState, inputs: Dictionary) -> Dictionary:
	var contract_id := String(inputs.get("contract_id", ""))
	var snapshot := world.active_contract(contract_id)
	if snapshot.is_empty():
		return _failure("contract is not active")
	if world.day > int(snapshot.get("deadline_day", 0)):
		var penalty := mini(world.money, int(snapshot.get("failure_penalty", 0)))
		world.money -= penalty
		var failure_reputation: Dictionary = snapshot.get("failure_reputation", {})
		var reputation_results := _apply_contract_reputation(world, failure_reputation)
		var failed := world.archive_contract(contract_id, "failed", {"penalty_paid": penalty, "reputation_results": reputation_results})
		var relationship_message := _contract_reputation_message(failure_reputation)
		var failure_message := "%s expired on Day %d. You paid %d ashmarks; the cargo remains yours to trade.%s" % [String(snapshot.name), int(snapshot.deadline_day), penalty, " " + relationship_message + "." if not relationship_message.is_empty() else ""]
		world.add_log(failure_message)
		return _success(failure_message, {
			"contract_id": contract_id,
			"status": "failed",
			"money": -penalty,
			"reputation": reputation_results,
			"contract": failed,
		})
	if world.current_settlement != String(snapshot.get("destination_id", "")):
		return _failure("deliver this contract to %s by Day %d" % [String(world.settlement(String(snapshot.destination_id)).name), int(snapshot.deadline_day)])
	var good_id := String(snapshot.get("good_id", ""))
	var quantity := int(snapshot.get("quantity", 0))
	var held_quantity := int(world.cargo.get(good_id, 0))
	if held_quantity < quantity:
		return _failure("contract needs %d more %s by Day %d" % [quantity - held_quantity, good_id, int(snapshot.deadline_day)])
	var memory_result := world.record_market_delivery(world.current_settlement, good_id, quantity, "contract")
	if not memory_result.ok:
		return _failure(String(memory_result.reason))
	var removed_weight := int(MarketContent.good(good_id).get("weight", 0)) * quantity
	var reward := int(snapshot.get("reward", 0))
	world.cargo[good_id] = held_quantity - quantity
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - removed_weight)
	world.money += reward
	var success_reputation: Dictionary = snapshot.get("success_reputation", {})
	var reputation_results := _apply_contract_reputation(world, success_reputation)
	var completed := world.archive_contract(contract_id, "completed", {"reward_paid": reward, "reputation_results": reputation_results})
	var relationship_message := _contract_reputation_message(success_reputation)
	var message := "Completed %s: delivered %d %s to %s and received %d ashmarks.%s" % [String(snapshot.name), quantity, good_id, String(world.settlement(world.current_settlement).name), reward, " " + relationship_message + "." if not relationship_message.is_empty() else ""]
	world.add_log(message)
	return _success(message, {
		"contract_id": contract_id,
		"status": "completed",
		"money": reward,
		"cargo": {good_id: -quantity, "weight": -removed_weight},
		"reputation": reputation_results,
		"market_memory": memory_result.record,
		"contract": completed,
	})

static func _resolve_arrival_contracts(world: AshWorldState) -> Array[Dictionary]:
	var resolutions: Array[Dictionary] = []
	var contract_ids: Array = world.active_contracts.keys()
	contract_ids.sort()
	for contract_id_value in contract_ids:
		var contract_id := String(contract_id_value)
		var snapshot := world.active_contract(contract_id)
		var should_resolve := world.day > int(snapshot.get("deadline_day", 0))
		if world.current_settlement == String(snapshot.get("destination_id", "")) and int(world.cargo.get(String(snapshot.get("good_id", "")), 0)) >= int(snapshot.get("quantity", 0)):
			should_resolve = true
		if should_resolve:
			var command := {"id": RESOLVE_CONTRACT, "inputs": {"contract_id": contract_id, "automatic": true}}
			var result := _resolve_contract(world, command.inputs)
			world.record_command(command, result)
			resolutions.append(result)
		elif world.current_settlement == String(snapshot.get("destination_id", "")):
			var remaining := int(snapshot.get("quantity", 0)) - int(world.cargo.get(String(snapshot.get("good_id", "")), 0))
			resolutions.append({
				"ok": true,
				"reason": "",
				"message": "%s remains active: acquire %d more %s by Day %d." % [String(snapshot.name), remaining, String(snapshot.good_id), int(snapshot.deadline_day)],
				"state_delta": {},
			})
	return resolutions

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
	if world.crisis_stage < int(action.get("minimum_crisis_stage", 0)):
		return _failure(String(action.get("unavailable_reason", "this opportunity is not available at the current crisis stage")))
	var information_id := String(action.get("effects", {}).get("information_id", ""))
	if bool(action.get("once_per_campaign", false)) and not information_id.is_empty() and world.known_information.has(information_id):
		return _failure("this opportunity is already complete; its information remains in the caravan log")
	var required_contract_id := String(action.get("requires_completed_contract_id", ""))
	if not required_contract_id.is_empty() and not _has_completed_contract(world, required_contract_id):
		return _failure(String(action.get("unavailable_reason", "complete the required contract first")))
	var required_emergent_faction_id := String(action.get("requires_emergent_faction_id", ""))
	if not required_emergent_faction_id.is_empty() and world.emergent_faction(required_emergent_faction_id).is_empty():
		return _failure(String(action.get("unavailable_reason", "the required local faction is not active")))
	var slots_required := int(action.get("service_slots", 0))
	if world.visit_slots_remaining < slots_required:
		return _failure("no visit slots remain; depart and arrive at a settlement to refresh them")
	var cost := int(action.get("cost", 0))
	if world.money < cost:
		return _failure("you need %d ashmarks for %s, but have %d" % [cost, String(action.get("name", action_id)), world.money])
	var cargo_cost: Dictionary = action.get("effects", {}).get("cargo_cost", {})
	if not cargo_cost.is_empty() and int(world.cargo.get(String(cargo_cost.get("good_id", "")), 0)) < int(cargo_cost.get("quantity", 0)):
		return _failure("you need %d %s for %s" % [int(cargo_cost.get("quantity", 0)), String(cargo_cost.get("good_id", "")), String(action.get("name", action_id))])

	match action_id:
		"ashgate_provision_bundle":
			return _apply_provision_bundle(world, action)
		"brine_cross_cistern_queue", "cinderford_repair_bench", "hollow_market_route_rumor", "reedwatch_supply_shelter", "reedwatch_commons_boiler_fuel", "reedwatch_commons_open_ledger", "reedwatch_warden_cistern_bypass":
			return _apply_civic_action(world, action)
		"ashgate_cinder_rider_arms_sale":
			return _apply_arms_sale(world, action)
		"ashgate_public_manifest_audit":
			return _apply_arms_recovery(world, action)
		_:
			return _failure(String(action.get("unavailable_reason", "this opportunity is not implemented yet")))

static func _apply_civic_action(world: AshWorldState, action: Dictionary) -> Dictionary:
	var cost := int(action.get("cost", 0))
	var slots := int(action.get("service_slots", 1))
	var days := int(action.get("time_cost", 0))
	var effects: Dictionary = action.get("effects", {})
	var cargo_delta: Dictionary = {}
	var cargo_cost: Dictionary = effects.get("cargo_cost", {})
	if not cargo_cost.is_empty():
		var good_id := String(cargo_cost.get("good_id", ""))
		var quantity := int(cargo_cost.get("quantity", 0))
		var removed_weight := quantity * int(MarketContent.good(good_id).get("weight", 0))
		world.cargo[good_id] = int(world.cargo.get(good_id, 0)) - quantity
		world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - removed_weight)
		cargo_delta = {good_id: -quantity, "weight": -removed_weight}
	world.money -= cost
	var information_id := String(effects.get("information_id", ""))
	var information_added := world.record_information(information_id)
	var resilience_effect: Dictionary = effects.get("settlement_resilience", {})
	var resilience_result: Dictionary = {}
	if not resilience_effect.is_empty():
		resilience_result = world.adjust_settlement_resilience(
			String(resilience_effect.get("settlement_id", world.current_settlement)),
			int(resilience_effect.get("delta", 0)),
		)
	var route_condition: Dictionary = effects.get("route_condition", {})
	var route_result: Dictionary = {}
	if not route_condition.is_empty():
		route_result = world.set_route_condition(String(route_condition.get("route_id", "")), route_condition)
	var reputation_results: Dictionary = {}
	var reputation_delta: Dictionary = effects.get("reputation", {})
	for faction_id_value in reputation_delta.keys():
		var faction_id := String(faction_id_value)
		reputation_results[faction_id] = world.adjust_reputation(faction_id, int(reputation_delta.get(faction_id_value, 0)))
	var emergent_support_result: Dictionary = {}
	var emergent_support: Dictionary = effects.get("emergent_faction_support", {})
	if not emergent_support.is_empty():
		emergent_support_result = world.adjust_emergent_faction_support(String(emergent_support.get("faction_id", "")), int(emergent_support.get("delta", 0)), String(action.get("id", "")))
	world.visit_slots_remaining -= slots
	if days > 0:
		world.advance_day(days, false)
	var message := String(action.get("result", "%s completed." % String(action.get("name", "Local action"))))
	world.add_log(message)
	return _success(message, {
		"action_id": String(action.id),
		"money": -cost,
		"day": days,
		"visit_slots": -slots,
		"visit_slots_remaining": world.visit_slots_remaining,
		"settlement_resilience": resilience_result,
		"information_id": information_id if information_added else "",
		"route_condition": route_result.get("condition", {}),
		"reputation": reputation_results,
		"cargo": cargo_delta,
		"emergent_faction_support": emergent_support_result,
	})

static func _has_completed_contract(world: AshWorldState, contract_id: String) -> bool:
	for contract in world.contract_history:
		if String(contract.get("id", "")) == contract_id and String(contract.get("status", "")) == "completed":
			return true
	return false

static func _apply_provision_bundle(world: AshWorldState, action: Dictionary) -> Dictionary:
	var cost := int(action.get("cost", 0))
	var slots_required := int(action.get("service_slots", 1))
	var time_cost := int(action.get("time_cost", 0))
	var effects: Dictionary = action.get("effects", {})
	var provisions_added := int(effects.get("provisions", 0))
	world.money -= cost
	world.provisions += provisions_added
	world.visit_slots_remaining -= slots_required
	var reputation_results: Dictionary = {}
	var reputation_delta: Dictionary = effects.get("reputation", {})
	for faction_id_value in reputation_delta.keys():
		var faction_id := String(faction_id_value)
		var reputation_result := world.adjust_reputation(faction_id, int(reputation_delta.get(faction_id_value, 0)))
		if reputation_result.ok:
			reputation_results[faction_id] = reputation_result
	if time_cost > 0:
		world.advance_day(time_cost, false)
	var standing_message := " Warden standing is now %d." % int(world.reputation.get("wardens", 0)) if reputation_results.has("wardens") else ""
	var message := "Packed %d route provisions for %d ashmarks. %d of %d visit slots remain.%s" % [provisions_added, cost, world.visit_slots_remaining, int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 2)), standing_message]
	world.add_log(message)
	return _success(message, {
		"action_id": String(action.id),
		"money": -cost,
		"provisions": provisions_added,
		"day": time_cost,
		"visit_slots": -slots_required,
		"visit_slots_remaining": world.visit_slots_remaining,
		"reputation": reputation_results,
	})

static func _apply_arms_sale(world: AshWorldState, action: Dictionary) -> Dictionary:
	var effects: Dictionary = action.get("effects", {})
	var sale: Dictionary = effects.get("arms_sale", {})
	var good_id := String(sale.get("good_id", ""))
	var quantity := int(sale.get("quantity", 0))
	if int(world.cargo.get(good_id, 0)) < quantity:
		return _failure("this offer needs %d sealed arms crate; buy or acquire one first" % quantity)
	var slots := int(action.get("service_slots", 1))
	var payout := int(sale.get("payout", 0))
	var removed_weight := int(MarketContent.good(good_id).get("weight", 0)) * quantity
	world.cargo[good_id] = int(world.cargo.get(good_id, 0)) - quantity
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - removed_weight)
	world.money += payout
	world.visit_slots_remaining -= slots
	var escalation := world.adjust_arms_escalation(int(sale.get("escalation_delta", 0)), String(action.get("id", "")))
	var reputation_results: Dictionary = {}
	var reputation_delta: Dictionary = sale.get("reputation", {})
	for faction_id_value in reputation_delta.keys():
		var faction_id := String(faction_id_value)
		reputation_results[faction_id] = world.adjust_reputation(faction_id, int(reputation_delta.get(faction_id_value, 0)))
	var alternative := MarketContent.contract(String(sale.get("alternative_contract_id", "")))
	var message := "Sold %d sealed arms crate for %d ashmarks. Arms escalation is now %d/6; Wardens and Free Caravans each lost standing. Non-arms alternative: %s." % [quantity, payout, world.arms_escalation, String(alternative.get("name", "relief trade"))]
	world.add_log(message)
	return _success(message, {"action_id": String(action.id), "money": payout, "cargo": {good_id: -quantity, "weight": -removed_weight}, "visit_slots": -slots, "visit_slots_remaining": world.visit_slots_remaining, "arms_escalation": escalation, "reputation": reputation_results})

static func _apply_arms_recovery(world: AshWorldState, action: Dictionary) -> Dictionary:
	if world.arms_escalation <= 0:
		return _failure("arms escalation is already at zero; no manifest audit is needed")
	var cost := int(action.get("cost", 0))
	var slots := int(action.get("service_slots", 1))
	var days := int(action.get("time_cost", 0))
	var recovery: Dictionary = action.get("effects", {}).get("arms_recovery", {})
	world.money -= cost
	world.visit_slots_remaining -= slots
	if days > 0:
		world.advance_day(days, false)
	var escalation := world.adjust_arms_escalation(int(recovery.get("escalation_delta", -1)), String(action.get("id", "")))
	var information_id := String(recovery.get("information_id", ""))
	world.record_information(information_id)
	var message := "Funded the public manifest audit for %d ashmarks and %d day. Arms escalation fell to %d/6; the published audit is now a known lead." % [cost, days, world.arms_escalation]
	world.add_log(message)
	return _success(message, {"action_id": String(action.id), "money": -cost, "day": days, "visit_slots": -slots, "visit_slots_remaining": world.visit_slots_remaining, "arms_escalation": escalation, "information_id": information_id})

static func _remove_cargo_unit(world: AshWorldState, good_id: String) -> Dictionary:
	if good_id.is_empty() or int(world.cargo.get(good_id, 0)) <= 0:
		return {"good_id": "", "delta": {"weight": 0}}
	var weight := int(MarketContent.good(good_id).get("weight", 0))
	world.cargo[good_id] = int(world.cargo.get(good_id, 0)) - 1
	world.cargo["weight"] = maxi(0, int(world.cargo.get("weight", 0)) - weight)
	return {"good_id": good_id, "delta": {good_id: -1, "weight": -weight}}

static func _record(world: AshWorldState, command: Dictionary, result: Dictionary) -> Dictionary:
	if bool(result.get("ok", false)):
		world.evaluate_ending()
	world.record_command(command, result)
	return result

static func _success(message: String, state_delta: Dictionary) -> Dictionary:
	return {"ok": true, "reason": "", "message": message, "state_delta": state_delta.duplicate(true)}

static func _failure(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason, "message": reason.capitalize() + ".", "state_delta": {}}
