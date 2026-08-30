extends RefCounted

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")


static func event_view(world, pending: Dictionary) -> Dictionary:
	var destination_name := String(world.settlement(String(pending.get("destination_id", ""))).get("name", "destination"))
	var loss_basis: Dictionary = pending.get("loss_basis", {})
	var cargo_context := "no carried cargo"
	if int(loss_basis.get("loss_quantity", 0)) > 0:
		cargo_context = "1 %s unit valued at %d" % [String(loss_basis.get("loss_good_id", "")).capitalize(), int(loss_basis.get("loss_unit_value", 0))]
	var material_basis: Dictionary = pending.get("material_basis", {})
	var material_parts: Array[String] = []
	var material_goods: Dictionary = material_basis.get("goods", {})
	for good_id in material_goods.keys():
		material_parts.append("%d %s" % [int(material_goods.get(good_id, 0)), String(good_id).capitalize()])
	var material_context := " Repair stock recognized: %s." % " + ".join(material_parts) if not material_parts.is_empty() else ""
	var trade_basis: Dictionary = pending.get("trade_basis", {})
	var trade_context := ""
	if not trade_basis.is_empty():
		trade_context = " Shortage basis: %d %s at %d each, plus %d premium each." % [int(trade_basis.get("quantity", 0)), String(trade_basis.get("good_id", "cargo")).capitalize(), int(trade_basis.get("unit_price", 0)), int(trade_basis.get("premium_per_unit", 0))]
	var maximum_cargo_risk := 0.0
	for raw_choice in pending.get("choices", []):
		if typeof(raw_choice) == TYPE_DICTIONARY:
			maximum_cargo_risk = maxf(maximum_cargo_risk, float(raw_choice.get("cargo_risk", 0.0)))
	var maximum_risk_percent := int(round(maximum_cargo_risk * 100.0))
	var threat_summary := "No choice uses a cargo-loss roll." if maximum_risk_percent == 0 else "Highest disclosed cargo-loss chance: %d%% against %s." % [maximum_risk_percent, cargo_context]
	var stakes := "DANGER — %s\nROAD — %s to %s via %s.%s%s\nAT STAKE — %s\nWHAT COUNTS — Only the written money, provisions, cargo, time, or standing can change. There is no hidden health damage." % [threat_summary, String(world.settlement(String(pending.get("origin_id", ""))).get("name", "origin")), destination_name, String(world.route(String(pending.get("route_id", ""))).get("name", "route")), material_context, trade_context, String(pending.get("stakes", ""))]
	var choices: Array[Dictionary] = []
	for raw_choice in pending.get("choices", []):
		if typeof(raw_choice) != TYPE_DICTIONARY:
			continue
		choices.append(_event_choice_view(world, pending, Dictionary(raw_choice), cargo_context, material_goods, trade_basis))
	return {
		"title": String(pending.get("title", "Route decision")),
		"setup": String(pending.get("setup", "")),
		"stakes": stakes,
		"choices": choices,
	}


static func _event_choice_view(world, pending: Dictionary, choice: Dictionary, cargo_context: String, material_goods: Dictionary, trade_basis: Dictionary) -> Dictionary:
	var money_cost := int(choice.get("money_cost", 0))
	var money_reward := int(choice.get("money_reward", 0))
	var trade_mode := String(choice.get("trade_mode", "none"))
	var trade_quantity := int(trade_basis.get("quantity", 0)) if trade_mode != "none" else 0
	if trade_mode == "premium_sale":
		money_reward += int(trade_basis.get("premium_total", 0))
	var provision_cost := int(choice.get("provision_cost", 0))
	var material_quantity := int(choice.get("material_quantity", 0))
	var cargo_cost: Dictionary = choice.get("cargo_cost", {})
	var cargo_cost_quantity := int(cargo_cost.get("quantity", 0))
	var cargo_cost_good_id := String(cargo_cost.get("good_id", ""))
	var days := int(choice.get("days", 0))
	var cargo_risk := int(round(float(choice.get("cargo_risk", 0.0)) * 100.0))
	var money_text := "no ashmark change"
	if money_reward > 0:
		money_text = "+%d ashmarks" % money_reward
	elif money_cost > 0:
		money_text = "-%d ashmarks" % money_cost
	var arrival_text := "return to origin" if String(choice.get("arrival_target", "destination")) == "origin" else "continue to destination"
	var cargo_cost_text := "%d %s" % [trade_quantity, String(trade_basis.get("good_id", "cargo"))] if trade_quantity > 0 else "%d materials" % material_quantity if material_quantity > 0 else "no cargo spent"
	if cargo_cost_quantity > 0:
		cargo_cost_text = "%d %s" % [cargo_cost_quantity, cargo_cost_good_id]
	var tactic_label := event_tactic_label(choice, trade_quantity, cargo_cost_quantity)
	var certainty_label := "CERTAIN" if cargo_risk == 0 else "RISK ROLL %d%% cargo risk" % cargo_risk
	var text := "%s / %s — %s\nCOST — %s · %d provisions · %s · %d days\nRESULT — %s · %s\nEXPECTED — %s" % [tactic_label, certainty_label, String(choice.get("label", "Choose")), money_text, provision_cost, cargo_cost_text, days, arrival_text, "no cargo-loss roll" if cargo_risk == 0 else "up to %s exposed" % cargo_context, String(choice.get("outcome", "Resolve the confrontation."))]
	var blocked_reason := ""
	if world.money < money_cost:
		blocked_reason = "Needs %d ashmarks; you have %d." % [money_cost, world.money]
	elif world.provisions < provision_cost:
		blocked_reason = "Needs %d provision; you have %d." % [provision_cost, world.provisions]
	elif material_quantity > 0:
		var available_materials := 0
		for good_id in material_goods.keys():
			available_materials += mini(int(material_goods.get(good_id, 0)), int(world.cargo.get(good_id, 0)))
		if available_materials < material_quantity:
			blocked_reason = "Needs %d of the disclosed repair materials; %d remain." % [material_quantity, available_materials]
	elif trade_quantity > int(world.cargo.get(String(trade_basis.get("good_id", "")), 0)):
		blocked_reason = "Needs %d %s; you have %d." % [trade_quantity, String(trade_basis.get("good_id", "cargo")), int(world.cargo.get(String(trade_basis.get("good_id", "")), 0))]
	elif cargo_cost_quantity > int(world.cargo.get(cargo_cost_good_id, 0)):
		blocked_reason = "Needs %d %s; you have %d." % [cargo_cost_quantity, cargo_cost_good_id, int(world.cargo.get(cargo_cost_good_id, 0))]
	elif bool(choice.get("requires_active_contract", false)) and not _has_relevant_event_contract(world, String(pending.get("destination_id", "")), String(trade_basis.get("good_id", "water"))):
		blocked_reason = "Needs an active water relief commitment for this destination."
	elif not String(choice.get("requires_assigned_crew_id", "")).is_empty() and world.assigned_crew != String(choice.get("requires_assigned_crew_id", "")):
		blocked_reason = "Requires %s to be assigned." % String(MarketContent.crew_member(String(choice.get("requires_assigned_crew_id", ""))).get("name", "the required crew member"))
	return {
		"id": String(choice.get("id", "")),
		"text": text,
		"disabled": not blocked_reason.is_empty(),
		"blocked_reason": blocked_reason,
		"tooltip": blocked_reason if not blocked_reason.is_empty() else String(choice.get("outcome", "")),
	}


static func event_tactic_label(choice: Dictionary, trade_quantity: int, cargo_cost_quantity: int) -> String:
	if String(choice.get("arrival_target", "destination")) == "origin":
		return "RETREAT"
	if not String(choice.get("requires_assigned_crew_id", "")).is_empty():
		return "CREW LEVERAGE"
	if float(choice.get("cargo_risk", 0.0)) > 0.0:
		return "MANEUVER"
	if int(choice.get("money_cost", 0)) > 0:
		return "PAY"
	if trade_quantity > 0 or int(choice.get("material_quantity", 0)) > 0 or cargo_cost_quantity > 0:
		return "TRADE"
	if int(choice.get("days", 0)) > 0:
		return "WAIT"
	if not Dictionary(choice.get("reputation_delta", {})).is_empty() or not String(choice.get("information_id", "")).is_empty():
		return "NEGOTIATE"
	return "COMMIT"


static func conflict_outcome_comparison(world, event_record: Dictionary) -> String:
	var outcome: Dictionary = event_record.get("outcome", {})
	var choice_id := String(event_record.get("choice_id", ""))
	if event_record.is_empty() or outcome.is_empty() or choice_id.is_empty():
		return ""
	var choice := _event_choice_from_record(event_record, choice_id)
	if choice.is_empty():
		return ""
	var trade_basis: Dictionary = event_record.get("trade_basis", {})
	var trade_mode := String(choice.get("trade_mode", "none"))
	var trade_quantity := int(trade_basis.get("quantity", 0)) if trade_mode != "none" else 0
	var cargo_cost: Dictionary = choice.get("cargo_cost", {})
	var cargo_cost_quantity := int(cargo_cost.get("quantity", 0))
	var tactic_label := event_tactic_label(choice, trade_quantity, cargo_cost_quantity)
	var risk := float(choice.get("cargo_risk", 0.0))
	var risk_percent := int(round(risk * 100.0))
	var certainty_label := "CERTAIN" if risk_percent == 0 else "%d%% RISK" % risk_percent
	var planned_money := int(choice.get("money_reward", 0)) - int(choice.get("money_cost", 0))
	if trade_mode == "premium_sale":
		planned_money += int(trade_basis.get("premium_total", 0))
	var arrival_target := String(choice.get("arrival_target", "destination"))
	var planned_settlement_id := String(event_record.get("origin_id", "")) if arrival_target == "origin" else String(event_record.get("destination_id", ""))
	var planned_settlement_name := String(world.settlement(planned_settlement_id).get("name", planned_settlement_id))
	var actual_settlement_id := String(outcome.get("current_settlement", planned_settlement_id))
	var actual_settlement_name := String(world.settlement(actual_settlement_id).get("name", actual_settlement_id))
	var planned_cargo := _planned_conflict_cargo_text(choice, event_record, trade_quantity, cargo_cost_quantity)
	var actual_cargo := _actual_conflict_cargo_text(Dictionary(outcome.get("cargo", {})))
	var risk_variance := _conflict_risk_variance_text(event_record, outcome)
	var persistent_effects := _conflict_persistent_effects_text(outcome)
	var comparison := "JOURNEY RESULT\nCHOICE — %s / %s — %s\nEXPECTED — %s · %s · %s · %s · %s · %s.\nARRIVAL — %s · %s · %s · %s · arrived at %s.\nWHAT CHANGED — %s\nWHY — %s" % [
		tactic_label,
		certainty_label,
		String(choice.get("label", "Choice")),
		_resource_delta_text(planned_money, "ashmarks"),
		_resource_delta_text(-int(choice.get("provision_cost", 0)), "provisions"),
		planned_cargo,
		_resource_delta_text(int(choice.get("days", 0)), "days"),
		"no cargo-loss roll" if risk_percent == 0 else "%d%% cargo-loss roll" % risk_percent,
		"return to %s" % planned_settlement_name if arrival_target == "origin" else "continue to %s" % planned_settlement_name,
		_resource_delta_text(int(outcome.get("money", 0)), "ashmarks"),
		_resource_delta_text(int(outcome.get("provisions", 0)), "provisions"),
		actual_cargo,
		_resource_delta_text(int(outcome.get("day", 0)), "days"),
		actual_settlement_name,
		risk_variance,
		String(choice.get("outcome", "The conflict resolves.")),
	]
	if not persistent_effects.is_empty():
		comparison += "\nPERSISTENT — %s" % persistent_effects
	var recovery_text := _conflict_recovery_text(world, event_record, outcome)
	if not recovery_text.is_empty():
		comparison += "\n%s" % recovery_text
	return comparison


static func best_recovery_sale(world) -> Dictionary:
	return _best_recovery_sale(world)


static func safest_affordable_recovery_route(world, available_money: int) -> Dictionary:
	return _safest_affordable_recovery_route(world, available_money)


static func _event_choice_from_record(event_record: Dictionary, choice_id: String) -> Dictionary:
	for raw_choice in event_record.get("choices", []):
		if typeof(raw_choice) == TYPE_DICTIONARY and String(raw_choice.get("id", "")) == choice_id:
			return Dictionary(raw_choice)
	return {}


static func _resource_delta_text(value: int, unit: String) -> String:
	return "%+d %s" % [value, unit] if value != 0 else "0 %s" % unit


static func _planned_conflict_cargo_text(choice: Dictionary, event_record: Dictionary, trade_quantity: int, cargo_cost_quantity: int) -> String:
	if trade_quantity > 0:
		var trade_basis: Dictionary = event_record.get("trade_basis", {})
		return "-%d %s planned" % [trade_quantity, String(trade_basis.get("good_id", "cargo")).capitalize()]
	var material_quantity := int(choice.get("material_quantity", 0))
	if material_quantity > 0:
		return "-%d repair materials planned" % material_quantity
	if cargo_cost_quantity > 0:
		return "-%d %s planned" % [cargo_cost_quantity, String(choice.get("cargo_cost", {}).get("good_id", "cargo")).capitalize()]
	return "no planned cargo spend"


static func _actual_conflict_cargo_text(cargo_delta: Dictionary) -> String:
	var parts: Array[String] = []
	var good_ids: Array = cargo_delta.keys()
	good_ids.sort()
	for good_id_value in good_ids:
		var good_id := String(good_id_value)
		if good_id == "weight" or int(cargo_delta.get(good_id_value, 0)) == 0:
			continue
		parts.append("%s %+d" % [good_id.capitalize(), int(cargo_delta.get(good_id_value, 0))])
	return "cargo unchanged" if parts.is_empty() else ", ".join(parts)


static func _conflict_risk_variance_text(event_record: Dictionary, outcome: Dictionary) -> String:
	var risk := float(outcome.get("cargo_risk", 0.0))
	if risk <= 0.0:
		return "Matched the disclosed plan; no cargo-loss roll occurred."
	var roll := float(outcome.get("resolution_roll", 1.0))
	var roll_percent := int(round(roll * 100.0))
	var risk_percent := int(round(risk * 100.0))
	var loss_basis: Dictionary = event_record.get("loss_basis", {})
	var loss_good_id := String(loss_basis.get("loss_good_id", ""))
	if roll < risk:
		return "Risk realized: the %d%% roll was below %d%%; 1 %s was exposed." % [roll_percent, risk_percent, loss_good_id.capitalize() if not loss_good_id.is_empty() else "cargo unit"]
	return "Risk avoided: the %d%% roll cleared the %d%% threshold; the exposed %s remained intact." % [roll_percent, risk_percent, loss_good_id.capitalize() if not loss_good_id.is_empty() else "cargo"]


static func _conflict_persistent_effects_text(outcome: Dictionary) -> String:
	var parts: Array[String] = []
	var route_condition: Dictionary = outcome.get("route_condition", {})
	if not route_condition.is_empty():
		parts.append(String(route_condition.get("label", "Route condition changed")))
	var resilience: Dictionary = outcome.get("settlement_resilience", {})
	if not resilience.is_empty():
		parts.append("settlement resilience %d/10" % int(resilience.get("after", 0)))
	var information_id := String(outcome.get("information_id", ""))
	if not information_id.is_empty():
		parts.append("information: %s" % information_id.replace("_", " "))
	var reputation: Dictionary = outcome.get("reputation", {})
	var faction_ids: Array = reputation.keys()
	faction_ids.sort()
	for faction_id_value in faction_ids:
		var faction_id := String(faction_id_value)
		var reputation_result: Dictionary = reputation.get(faction_id_value, {})
		parts.append("%s standing %+d to %d" % [faction_id.capitalize(), int(reputation_result.get("delta", 0)), int(reputation_result.get("after", 0))])
	var contracts: Array = outcome.get("contract_resolutions", [])
	if not contracts.is_empty():
		parts.append("%d contract result%s" % [contracts.size(), "" if contracts.size() == 1 else "s"])
	return "; ".join(parts)


static func _conflict_recovery_text(world, event_record: Dictionary, outcome: Dictionary) -> String:
	var risk := float(outcome.get("cargo_risk", 0.0))
	var roll := float(outcome.get("resolution_roll", 1.0))
	if risk <= 0.0 or roll >= risk:
		return ""
	var sale := _best_recovery_sale(world)
	var recovery_steps: Array[String] = []
	var available_money: int = world.money
	if not sale.is_empty():
		available_money += int(sale.get("total", 0))
		recovery_steps.append("%s x%d remains and would sell here for %d ashmarks" % [String(sale.get("name", "Cargo")), int(sale.get("quantity", 0)), int(sale.get("total", 0))])
	var route_option := _safest_affordable_recovery_route(world, available_money)
	if not route_option.is_empty():
		var funding_basis := "With current funds"
		if not sale.is_empty():
			funding_basis = "After that sale"
		recovery_steps.append("%s, %s to %s is the lowest-risk affordable onward route at %d ashmarks, %d provision%s, and %d%% route risk" % [funding_basis, String(route_option.get("route_name", "Route")), String(route_option.get("destination_name", "destination")), int(route_option.get("money_cost", 0)), int(route_option.get("provision_cost", 0)), "" if int(route_option.get("provision_cost", 0)) == 1 else "s", int(route_option.get("risk_percent", 0))])
	if recovery_steps.is_empty():
		var loss_basis: Dictionary = event_record.get("loss_basis", {})
		var loss_good_id := String(loss_basis.get("loss_good_id", "cargo"))
		recovery_steps.append("the lost %s leaves no immediately affordable sale or route, so check the visible Local Opportunities and their exact blockers" % loss_good_id.capitalize())
	return "RECOVERY — %s. No restart is required." % ". ".join(recovery_steps)


static func _best_recovery_sale(world) -> Dictionary:
	var settlement: Dictionary = world.settlement(world.current_settlement)
	var context: Dictionary = world.pricing_context()
	var best: Dictionary = {}
	for good_id in MarketContent.good_ids():
		var quantity := _uncommitted_cargo_quantity(world, good_id)
		if quantity <= 0:
			continue
		var unit_price := MarketEconomy.price_for(good_id, settlement, context)
		var total := unit_price * quantity
		if best.is_empty() or total > int(best.get("total", 0)):
			best = {
				"good_id": good_id,
				"name": String(MarketContent.good(good_id).get("name", good_id.capitalize())),
				"quantity": quantity,
				"unit_price": unit_price,
				"total": total,
			}
	return best


static func _uncommitted_cargo_quantity(world, good_id: String) -> int:
	var reserved_quantity := 0
	for contract_id in world.active_contracts.keys():
		var contract: Dictionary = world.active_contract(String(contract_id))
		if String(contract.get("good_id", "")) == good_id:
			reserved_quantity += int(contract.get("quantity", 0))
	return maxi(0, int(world.cargo.get(good_id, 0)) - reserved_quantity)


static func _safest_affordable_recovery_route(world, available_money: int) -> Dictionary:
	var best: Dictionary = {}
	var destination_ids := MarketContent.destinations_from(world.current_settlement)
	destination_ids.sort()
	var route_ids := MarketContent.routes_from(world.current_settlement)
	route_ids.sort()
	for destination_id_value in destination_ids:
		var destination_id := String(destination_id_value)
		for route_id_value in route_ids:
			var route_id := String(route_id_value)
			if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
				continue
			var route: Dictionary = world.route(route_id, world.current_settlement, destination_id)
			var money_cost := int(route.get("cost", 0))
			var provision_cost: int = world.route_provision_cost(route_id, destination_id)
			if available_money < money_cost or world.provisions < provision_cost:
				continue
			var risk_percent := int(round(float(route.get("risk", 0.0)) * 100.0))
			if not best.is_empty():
				var best_risk := int(best.get("risk_percent", 0))
				var best_cost := int(best.get("money_cost", 0))
				if risk_percent > best_risk or (risk_percent == best_risk and money_cost >= best_cost):
					continue
			best = {
				"route_id": route_id,
				"route_name": String(route.get("name", route_id)),
				"destination_id": destination_id,
				"destination_name": String(world.settlement(destination_id).get("name", destination_id)),
				"money_cost": money_cost,
				"provision_cost": provision_cost,
				"risk_percent": risk_percent,
			}
	return best


static func _has_relevant_event_contract(world, destination_id: String, good_id: String) -> bool:
	for contract_id in world.active_contracts.keys():
		var contract: Dictionary = world.active_contract(String(contract_id))
		if String(contract.get("destination_id", "")) == destination_id and String(contract.get("good_id", "")) == good_id:
			return true
	return false
