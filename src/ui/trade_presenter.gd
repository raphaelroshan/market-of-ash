extends RefCounted

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")


static func route_comparison_views(world, good_id: String, quantity: int, selected_destination_id: String, selected_route_id: String, world_context: Dictionary) -> Array[Dictionary]:
	var origin: Dictionary = world.settlement(world.current_settlement)
	var views: Array[Dictionary] = []
	var destination_ids := MarketContent.destinations_from(world.current_settlement)
	destination_ids.sort()
	if destination_ids.has(selected_destination_id):
		destination_ids.erase(selected_destination_id)
		destination_ids.push_front(selected_destination_id)
	for destination_id in destination_ids:
		var destination: Dictionary = world.settlement(destination_id)
		for route_id in MarketContent.routes_from(world.current_settlement):
			if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
				continue
			var route: Dictionary = world.route(route_id, world.current_settlement, destination_id)
			route["provisions"] = world.route_provision_cost(route_id, destination_id)
			var context := world_context.duplicate(true)
			context["route_intelligence"] = world.route_intelligence(route_id)
			var preview := MarketEconomy.route_profit_preview(good_id, quantity, origin, destination, route, context)
			if not bool(preview.get("ok", false)):
				continue
			var net := int(preview.get("expected_net_profit", 0))
			var consequence := "Forecast loss; choose only for another strategic reason."
			var consequence_label := "LOSS"
			if net > 20:
				consequence = "Strong margin if the disclosed forecast holds."
				consequence_label = "STRONG GAIN"
			elif net > 0:
				consequence = "Positive but narrow margin after road burden."
				consequence_label = "NARROW GAIN"
			elif net == 0:
				consequence = "Break-even forecast before unpriced political value."
				consequence_label = "BREAK EVEN"
			var intelligence: Dictionary = context.get("route_intelligence", {})
			var confidence_label := String(intelligence.get("status", "unavailable")).replace("_informed", "").to_upper()
			if confidence_label == "UNAVAILABLE":
				confidence_label = "NONE"
			var risk_percent := int(round(float(preview.get("risk", 0.0)) * 100.0))
			var selected := destination_id == selected_destination_id and route_id == selected_route_id
			var held_quantity := int(world.cargo.get(good_id, 0))
			var shortfall := maxi(0, quantity - held_quantity)
			var readiness_label := "READY"
			var readiness_detail := "The hold carries at least the planned %d %s." % [quantity, good_id.capitalize()]
			if shortfall > 0:
				readiness_label = "IF BOUGHT"
				readiness_detail = "Hypothetical %s x%d forecast: the hold has %d. Buy %d before leaving to carry this plan; empty travel remains legal." % [good_id.capitalize(), quantity, held_quantity, shortfall]
			views.append({
				"destination_id": destination_id,
				"route_id": route_id,
				"selected": selected,
				"text": "%s%s\n%s\nFEE %d · TIME %dD · SUPPLY %dP\nPLAN %s x%d · HELD %d\nVALUE %d → %d · GROSS %+d\nRISK %d%% · CONF %s\nNET %+d · %s / %s" % [
					"SELECTED\n" if selected else "",
					String(destination.get("name", destination_id)).to_upper(),
					String(route.get("name", route_id)),
					int(preview.get("route_cost", 0)),
					int(route.get("days", 0)),
					int(preview.get("provisions", 0)),
					good_id.capitalize(),
					quantity,
					held_quantity,
					int(preview.get("purchase_total", 0)),
					int(preview.get("sale_total", 0)),
					int(preview.get("gross_trade_margin", 0)),
					risk_percent,
					confidence_label,
					net,
					readiness_label,
					consequence_label,
				],
				"tooltip": "%s via %s. %s %s" % [String(destination.get("name", destination_id)), String(route.get("name", route_id)), readiness_detail, consequence],
			})
	return views


static func market_preview_text(world, good_id: String, quantity: int, settlement: Dictionary, destination: Dictionary, route: Dictionary, world_context: Dictionary) -> String:
	var details := MarketEconomy.price_details(good_id, settlement, world_context)
	if not details.ok:
		return "MARKET\nNo valid good selected."
	var reason_text := "; ".join(details.reasons)
	var unit_price := int(details.unit_price)
	var memory_text := ""
	if float(details.market_pressure) > 0.0:
		var delivery: Dictionary = world.latest_market_delivery(String(settlement.get("id", "")), good_id)
		var decay_percent := int(round(MarketEconomy.market_pressure_decay_rate(settlement, good_id) * 100.0))
		if delivery.is_empty():
			memory_text = "\nMarket memory: recent deliveries softened this price by %d%%; the effect recovers by %d%% per day." % [int(round(float(details.market_pressure) * 100.0)), decay_percent]
		else:
			memory_text = "\nMarket memory: your last %d %s delivered here softened this price by %d%%; the effect recovers by %d%% per day." % [int(delivery.quantity), good_id, int(round(float(details.market_pressure) * 100.0)), decay_percent]
	var comparison: Array[String] = []
	for settlement_id in MarketContent.settlement_ids():
		var candidate: Dictionary = world.settlement(settlement_id)
		if candidate == settlement:
			continue
		comparison.append("%s %d" % [String(candidate.get("name", settlement_id)), MarketEconomy.price_for(good_id, candidate, world_context)])
	if route.is_empty() or destination.is_empty():
		return "MARKET — %s\n%s: %d ashmarks each · load total %d\nWhy this price: %s%s\nOther markets: %s" % [settlement.get("name", "Unknown market"), good_id.capitalize(), unit_price, unit_price * quantity, reason_text, memory_text, "; ".join(comparison)]
	var story := MarketEconomy.ordinary_trade_story(good_id, quantity, settlement, destination, route, world_context)
	if not story.ok:
		return "MARKET — %s\n%s: %d ashmarks each · load total %d\nWhy this price: %s%s\nOther markets: %s" % [settlement.get("name", "Unknown market"), good_id.capitalize(), unit_price, unit_price * quantity, reason_text, memory_text, "; ".join(comparison)]
	var spread_text := "%+d" % int(story.unit_spread)
	var gross_text := "%+d" % int(story.gross_margin)
	var net_text := "%+d" % int(story.expected_net_profit)
	var provision_word := "provision" if int(story.provisions) == 1 else "provisions"
	return "ORDINARY TRADE — NO CONTRACT REQUIRED\n%s x%d · %s → %s via %s\nSOURCE — %s\nNEED — %s\nSPREAD — buy %d · sell %d · %s each · load total %s\nROAD — %d ashmarks · %d %s · %d%% exposed-unit risk\nEXPECTED NET %s ashmarks after travel, time, and expected loss\nWhy this price: %s%s\nMarket factors: local %.2f · demand %.2f · crisis %.2f · faction %.2f · response %.2f · memory %.2f\nOther markets: %s" % [good_id.capitalize(), quantity, story.origin_name, story.destination_name, story.route_name, story.source_reason, story.need_reason, int(story.origin_price), int(story.destination_price), spread_text, gross_text, int(story.route_cost), int(story.provisions), provision_word, int(round(float(story.risk) * 100.0)), net_text, reason_text, memory_text, float(details.settlement_modifier), float(details.demand_modifier), float(details.crisis_modifier), float(details.faction_modifier), float(details.adaptive_modifier), float(details.market_memory_modifier), "; ".join(comparison)]


static func shop_decision_summary_text(world, good_id: String, quantity: int, origin: Dictionary, destination: Dictionary, route: Dictionary, world_context: Dictionary) -> String:
	if route.is_empty() or destination.is_empty():
		return "ORDINARY TRADE PLAN — NO CONTRACT REQUIRED\nChoose a connected destination to compare value, road burden, risk, and hold space."
	var story := MarketEconomy.ordinary_trade_story(good_id, quantity, origin, destination, route, world_context)
	if not bool(story.get("ok", false)):
		return "ORDINARY TRADE PLAN — NO CONTRACT REQUIRED\nChoose a valid cargo load to compare this journey."
	var good := MarketContent.good(good_id)
	var held_quantity := int(world.cargo.get(good_id, 0))
	var current_hold := int(world.cargo.get("weight", 0))
	var load_weight := maxi(0, quantity - held_quantity) * int(good.get("weight", 0))
	var projected_hold := current_hold + load_weight
	var buy_total := int(story.origin_price) * quantity
	var sale_total := int(story.destination_price) * quantity
	var next_action := "Buy %d %s, then Plan departure." % [quantity, good_id.capitalize()]
	if held_quantity >= quantity:
		next_action = "Plan departure; this forecast load is already in the hold."
	else:
		var buy_validation := MarketEconomy.validate_trade(world.cargo, good_id, quantity, world.cargo_capacity)
		if world.money < buy_total:
			next_action = "Adjust the load: it costs %d ashmarks and %d are available." % [buy_total, world.money]
		elif not bool(buy_validation.get("ok", false)):
			next_action = "Adjust the load: %s." % String(buy_validation.get("reason", "it does not fit"))
	var trade_path_label := "COMMONS / NO CONTRACT" if good_id == "charcoal" and String(destination.get("id", "")) == "reedwatch" and not world.emergent_faction("well_commons").is_empty() else "ORDINARY / NO CONTRACT"
	return "%s — %s x%d · %s → %s\nWHY — %s → %s\nVALUE — buy %d · sell %d · road %d · expected %+d ashmarks\nROAD / CAPACITY — %s · %d provision%s · %d%% exposed-unit risk · %d ashmarks available · hold %d/%d → %d/%d\nNEXT — %s" % [trade_path_label, good_id.capitalize(), quantity, String(story.origin_name), String(story.destination_name), String(story.source_reason), String(story.need_reason), buy_total, sale_total, int(story.route_cost), int(story.expected_net_profit), String(story.route_name), int(story.provisions), "" if int(story.provisions) == 1 else "s", int(round(float(story.risk) * 100.0)), world.money, current_hold, world.cargo_capacity, projected_hold, world.cargo_capacity, next_action]


static func route_preview_text(world, good_id: String, quantity: int, origin: Dictionary, destination: Dictionary, route: Dictionary, world_context: Dictionary) -> String:
	var preview := MarketEconomy.route_profit_preview(good_id, quantity, origin, destination, route, world_context)
	if not preview.ok:
		return "ROUTE FORECAST\nChoose a valid cargo, destination, and route."
	var net_profit := int(preview.expected_net_profit)
	var net_text := ("+%d" % net_profit) if net_profit > 0 else str(net_profit)
	var cargo_risk_text: String
	if int(preview.loss_quantity) <= 0:
		cargo_risk_text = "Cargo risk: no carried cargo is currently at risk; expected loss 0 at %d%% risk." % int(round(float(preview.risk) * 100.0))
	else:
		cargo_risk_text = "Cargo risk: 1 %s unit at risk, valued at %d at %s; expected loss %d at %d%% risk." % [String(preview.loss_good_id).capitalize(), int(preview.loss_unit_value), destination.get("name", "the destination"), int(preview.expected_loss), int(round(float(preview.risk) * 100.0))]
	var intelligence: Dictionary = world_context.get("route_intelligence", {})
	var intelligence_text := "%s — %s" % [String(intelligence.get("label", "Scout unavailable")), String(intelligence.get("detail", "No current field report."))]
	var held_quantity := int(world.cargo.get(good_id, 0))
	var load_check: String
	if held_quantity < quantity:
		load_check = "LOAD CHECK — Held %d/%d selected %s. Buy %d before departure to carry this full scenario; travel uses the actual hold." % [held_quantity, quantity, good_id.capitalize(), quantity - held_quantity]
	else:
		load_check = "LOAD CHECK — Held %d/%d selected %s. This scenario is covered; departure still carries the full actual hold." % [held_quantity, quantity, good_id.capitalize()]
	var faction_text := ""
	if route.has("faction_effect"):
		faction_text = "\n%s standing: %s Trade-off: %s" % [String(route.get("faction_name", "Faction")), String(route.get("faction_effect", "")), String(route.get("faction_tradeoff", ""))]
	if route.has("arms_effect"):
		faction_text += "\nEscalation warning: %s" % String(route.get("arms_effect", ""))
	if route.has("crisis_effect"):
		faction_text += "\nCrisis route change: %s" % String(route.get("crisis_effect", ""))
	return "ROUTE FORECAST — %s to %s via %s\nScenario buy %d · expected sale %d · gross margin %+d\nRoute fee %d · provisions %d (%d value) · time cost %d\n%s\n%s\nEXPECTED NET PROFIT %s ashmarks\nRisk source: %s\nScout confidence: %s%s" % [origin.get("name", "Origin"), destination.get("name", "Destination"), route.get("name", "Route"), int(preview.purchase_total), int(preview.sale_total), int(preview.gross_trade_margin), int(preview.route_cost), int(preview.provisions), int(preview.provision_cost), int(preview.time_cost), load_check, cargo_risk_text, net_text, String(preview.risk_source), intelligence_text, faction_text]
