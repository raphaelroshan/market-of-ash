extends SceneTree

## Read-only behavioral simulation for the current quick-playtest economy.
## Policy rows are representative decision rules, not claims about real player behavior.

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

const STARTING_MONEY := 120
const STARTING_PROVISIONS := 12
const SEED_COUNT := 100
const POLICIES := ["guided_grain_delivery", "forecast_maximizer", "gross_margin_chaser", "toll_road_only", "no_trade"]

func _init() -> void:
	var rows: Array[Dictionary] = []
	var multi_trip_rows: Array[Dictionary] = []
	var event_probe_rows: Array[Dictionary] = []
	var arms_policy_rows: Array[Dictionary] = []
	for seed in range(1, SEED_COUNT + 1):
		for policy in POLICIES:
			rows.append(_run_policy(seed, policy))
		multi_trip_rows.append_array(_run_multi_trip_policy(seed))
		event_probe_rows.append(_run_span_event_probe(seed))
		event_probe_rows.append(_run_last_barrel_probe(seed))
		arms_policy_rows.append(_run_arms_policy(seed, "arms_broker_sale"))
		arms_policy_rows.append(_run_arms_policy(seed, "non_arms_relief"))
	var payload := {
		"simulation": "Market of Ash first-run single-trade policy simulation",
		"seed_count": SEED_COUNT,
		"starting_state": {"money": STARTING_MONEY, "provisions": STARTING_PROVISIONS, "cargo_weight": 0, "settlement": "ashgate", "day": 1},
		"policies": POLICIES,
		"rows": rows,
		"multi_trip_rows": multi_trip_rows,
		"event_probe_rows": event_probe_rows,
		"arms_policy_rows": arms_policy_rows,
		"market_memory_probe": _market_memory_probe(),
	}
	var output_path := _output_path()
	if not output_path.is_empty():
		var file := FileAccess.open(output_path, FileAccess.WRITE)
		if file == null:
			push_error("Could not write simulation output: %s" % output_path)
			quit(1)
			return
		file.store_string(JSON.stringify(payload))
		print("Wrote simulation output to %s" % output_path)
	else:
		print("SIMULATION_JSON=" + JSON.stringify(payload))
	quit(0)

func _run_arms_policy(seed: int, policy: String) -> Dictionary:
	var world := AshWorldState.new(seed)
	var status := "completed"
	if policy == "arms_broker_sale":
		var buy := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "sealed_arms_crate", "quantity": 1}})
		var sale := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "ashgate_cinder_rider_arms_sale"}}) if buy.ok else {"ok": false, "reason": buy.reason}
		status = "completed" if sale.ok else String(sale.get("reason", "failed"))
	else:
		var accepted := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.ACCEPT_CONTRACT, "inputs": {"contract_id": "reedwatch_water_relief_01"}})
		var bought := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "water", "quantity": 4}}) if accepted.ok else {"ok": false, "reason": accepted.reason}
		var departed := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}}) if bought.ok else {"ok": false, "reason": bought.reason}
		var resolved := _resolve_pending_event_for_policy(world) if departed.ok else {"ok": false, "reason": departed.reason}
		status = "completed" if resolved.ok and world.has_contract_outcome("reedwatch_water_relief_01") else "contract incomplete"
	var assumptions := MarketContent.planning_assumptions()
	var economic_profit := world.money - STARTING_MONEY - (STARTING_PROVISIONS - world.provisions) * int(assumptions.provision_value) - (world.day - 1) * int(assumptions.time_opportunity_cost_per_day)
	return {"seed": seed, "policy": policy, "status": status, "economic_profit": economic_profit, "ending_money": world.money, "arms_escalation": world.arms_escalation}

func _run_span_event_probe(seed: int) -> Dictionary:
	var world := AshWorldState.new(seed)
	world.cargo = {"scrap": 2, "weight": 2}
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	if not depart.ok:
		return {"seed": seed, "policy": "span_material_reserve_probe", "status": String(depart.reason), "event_id": "", "event_choice_id": "", "route_risk_after": float(world.route("old_road").risk)}
	var event_id := String(world.pending_event.get("id", ""))
	var choice_id := ""
	var status := "no event"
	if event_id == "span_at_cinderford":
		choice_id = "reserve_materials_for_span"
		var resolution := MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.RESOLVE_EVENT,
			"inputs": {"event_id": event_id, "choice_id": choice_id},
		})
		status = "completed" if resolution.ok else String(resolution.reason)
	return {
		"seed": seed,
		"policy": "span_material_reserve_probe",
		"status": status,
		"event_id": event_id,
		"event_choice_id": choice_id,
		"route_risk_after": float(world.route("old_road").risk),
	}

func _run_last_barrel_probe(seed: int) -> Dictionary:
	var world := AshWorldState.new(seed)
	world.resolved_event_ids.append("three_riders_no_banner")
	world.crisis_stage = 1
	world._update_crisis_modifiers()
	world.cargo = {"water": 2, "weight": 2}
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	if not depart.ok:
		return {"seed": seed, "policy": "last_barrel_fair_share_probe", "status": String(depart.reason), "event_id": "", "event_choice_id": "", "resilience_after": world.resilience_for("reedwatch")}
	var event_id := String(world.pending_event.get("id", ""))
	var choice_id := ""
	var status := "no event"
	if event_id == "last_clean_barrel":
		choice_id = "share_barrels_fairly"
		var resolution := MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.RESOLVE_EVENT,
			"inputs": {"event_id": event_id, "choice_id": choice_id},
		})
		status = "completed" if resolution.ok else String(resolution.reason)
	return {
		"seed": seed,
		"policy": "last_barrel_fair_share_probe",
		"status": status,
		"event_id": event_id,
		"event_choice_id": choice_id,
		"resilience_after": world.resilience_for("reedwatch"),
	}

func _output_path() -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			return argument.trim_prefix("--output=")
	return ""

func _run_policy(seed: int, policy: String) -> Dictionary:
	var world := AshWorldState.new(seed)
	if policy == "no_trade":
		return _row(world, policy, {}, {}, "no action", false, 0, "No trade taken")
	var candidate := _choose_candidate(world, policy)
	if candidate.is_empty():
		return _row(world, policy, {}, {}, "no valid candidate", false, 0, "No feasible trade")
	var preview: Dictionary = candidate.preview
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": candidate.good_id, "quantity": candidate.quantity},
	})
	if not buy.ok:
		return _row(world, policy, candidate, preview, String(buy.reason), false, 0, String(buy.message))
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": candidate.route_id, "destination_id": candidate.destination_id},
	})
	if not depart.ok:
		return _row(world, policy, candidate, preview, String(depart.reason), false, 0, String(depart.message))
	var event_result := _resolve_pending_event_for_policy(world)
	if not event_result.ok:
		return _row(world, policy, candidate, preview, String(event_result.reason), false, 0, String(event_result.message))
	var remaining := int(world.cargo.get(String(candidate.good_id), 0))
	var sold_quantity := 0
	var sell_message := "Cargo lost before sale"
	if remaining > 0:
		var sell := MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.SELL_GOODS,
			"inputs": {"good_id": candidate.good_id, "quantity": remaining},
		})
		if sell.ok:
			sold_quantity = remaining
			sell_message = String(sell.message)
		else:
			sell_message = String(sell.reason)
	var incident := bool(depart.state_delta.get("cargo", {}).get("weight", 0) < 0) or bool(event_result.state_delta.get("outcome", {}).get("cargo", {}).get("weight", 0) < 0)
	return _row(world, policy, candidate, preview, "completed", incident, sold_quantity, sell_message)

func _run_multi_trip_policy(seed: int) -> Array[Dictionary]:
	var world := AshWorldState.new(seed)
	var rows: Array[Dictionary] = []
	for delivery_index in range(1, 4):
		var candidate := _choose_candidate(world, "forecast_maximizer")
		if candidate.is_empty():
			rows.append({"seed": seed, "delivery_index": delivery_index, "status": "no feasible trade"})
			break
		var buy := MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.BUY_GOODS,
			"inputs": {"good_id": candidate.good_id, "quantity": candidate.quantity},
		})
		if not buy.ok:
			rows.append({"seed": seed, "delivery_index": delivery_index, "status": String(buy.reason)})
			break
		var depart := MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.DEPART_ROUTE,
			"inputs": {"route_id": candidate.route_id, "destination_id": candidate.destination_id},
		})
		if not depart.ok:
			rows.append({"seed": seed, "delivery_index": delivery_index, "status": String(depart.reason)})
			break
		var event_result := _resolve_pending_event_for_policy(world)
		if not event_result.ok:
			rows.append({"seed": seed, "delivery_index": delivery_index, "status": String(event_result.reason)})
			break
		var sell_price_before := MarketEconomy.price_for(candidate.good_id, world.settlement(candidate.destination_id), world.pricing_context())
		var remaining := int(world.cargo.get(String(candidate.good_id), 0))
		var sell := {"ok": true, "reason": "", "message": "No cargo remained", "state_delta": {}}
		if remaining > 0:
			sell = MarketCommandProcessor.execute(world, {
				"id": MarketCommandProcessor.SELL_GOODS,
				"inputs": {"good_id": candidate.good_id, "quantity": remaining},
			})
		var sell_price_after := MarketEconomy.price_for(candidate.good_id, world.settlement(candidate.destination_id), world.pricing_context())
		rows.append({
			"seed": seed,
			"delivery_index": delivery_index,
			"status": "completed" if sell.ok else String(sell.reason),
			"good_id": String(candidate.good_id),
			"destination_id": String(candidate.destination_id),
			"route_id": String(candidate.route_id),
			"quantity_purchased": int(candidate.quantity),
			"quantity_delivered": remaining if sell.ok else 0,
			"forecast_expected_net_profit": int(candidate.preview.expected_net_profit),
			"sale_price_before": sell_price_before,
			"sale_price_after": sell_price_after,
			"market_pressure_after": world.market_pressure_for(String(candidate.destination_id), String(candidate.good_id)),
		})
		if delivery_index == 3:
			break
		var return_route_id := _route_between(world.current_settlement, "ashgate")
		if return_route_id.is_empty():
			break
		var return_result := MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.DEPART_ROUTE,
			"inputs": {"route_id": return_route_id, "destination_id": "ashgate"},
		})
		if not return_result.ok:
			break
		var return_event_result := _resolve_pending_event_for_policy(world)
		if not return_event_result.ok:
			break
	return rows

func _resolve_pending_event_for_policy(world: AshWorldState) -> Dictionary:
	if world.pending_event.is_empty():
		return {"ok": true, "reason": "", "message": "no event", "state_delta": {}}
	var event_id := String(world.pending_event.get("id", ""))
	var choice_id := "wait_for_stamped_review"
	if event_id == "gatekeepers_chalk" and world.money >= 6:
		choice_id = "pay_posted_toll"
	elif event_id == "span_at_cinderford":
		var material_basis: Dictionary = world.pending_event.get("material_basis", {})
		choice_id = "reserve_materials_for_span" if int(material_basis.get("quantity", 0)) >= 2 else "turn_back_with_cargo"
	elif event_id == "last_clean_barrel":
		choice_id = "keep_barrels_sealed"
	elif event_id == "three_riders_no_banner":
		choice_id = "pay_for_escort" if world.money >= 10 else "wait_and_read_the_tracks"
	return MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": event_id, "choice_id": choice_id},
	})

func _route_between(origin_id: String, destination_id: String) -> String:
	for route_id in MarketContent.routes_from(origin_id):
		if MarketContent.route_connects(route_id, origin_id, destination_id):
			return route_id
	return ""

func _market_memory_probe() -> Dictionary:
	var world := AshWorldState.new(1)
	world.current_settlement = "reedwatch"
	world.cargo = {"water": 4, "weight": 4}
	var baseline_price := MarketEconomy.price_for("water", world.settlement("reedwatch"), world.pricing_context())
	var sale := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 4},
	})
	var post_delivery_price := MarketEconomy.price_for("water", world.settlement("reedwatch"), world.pricing_context())
	var initial_pressure := world.market_pressure_for("reedwatch", "water")
	var recovery_days := 0
	while world.market_pressure_for("reedwatch", "water") > 0.0 and recovery_days < 100:
		world.advance_day(1)
		recovery_days += 1

	var saturation_world := AshWorldState.new(1)
	saturation_world.current_settlement = "reedwatch"
	for _index in range(3):
		saturation_world.cargo = {"water": 4, "weight": 4}
		MarketCommandProcessor.execute(saturation_world, {
			"id": MarketCommandProcessor.SELL_GOODS,
			"inputs": {"good_id": "water", "quantity": 4},
		})
	return {
		"sale_ok": bool(sale.ok),
		"baseline_price": baseline_price,
		"post_delivery_price": post_delivery_price,
		"initial_pressure": initial_pressure,
		"recovery_days": recovery_days,
		"saturated_pressure": saturation_world.market_pressure_for("reedwatch", "water"),
	}

func _choose_candidate(world: AshWorldState, policy: String) -> Dictionary:
	if policy == "guided_grain_delivery":
		return _candidate_for(world, "grain", 2, "reedwatch", "old_road")
	var best: Dictionary = {}
	for good_id in MarketContent.good_ids():
		var origin := world.settlement(world.current_settlement)
		var purchase_price := MarketEconomy.price_for(good_id, origin, world.pricing_context())
		for destination_id in MarketContent.destinations_from(world.current_settlement):
			for route_id in MarketContent.routes_from(world.current_settlement):
				if policy == "toll_road_only" and route_id != "toll_road":
					continue
				if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
					continue
				var route_cost := int(world.route(route_id).get("cost", 0))
				var max_quantity := mini(world.cargo_capacity, int((world.money - route_cost) / purchase_price))
				if max_quantity <= 0:
					continue
				var quantity_boundaries: Array[int] = [max_quantity]
				if max_quantity > 1:
					quantity_boundaries.push_front(1)
				for quantity in quantity_boundaries:
					var candidate := _candidate_for(world, good_id, quantity, destination_id, route_id)
					if candidate.is_empty():
						continue
					if _is_better(candidate, best, policy):
						best = candidate
	return best

func _candidate_for(world: AshWorldState, good_id: String, quantity: int, destination_id: String, route_id: String) -> Dictionary:
	if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		return {}
	var simulated_cargo := world.cargo.duplicate(true)
	simulated_cargo[good_id] = int(simulated_cargo.get(good_id, 0)) + quantity
	simulated_cargo["weight"] = int(simulated_cargo.get("weight", 0)) + int(MarketContent.good(good_id).get("weight", 0)) * quantity
	var preview := MarketEconomy.route_profit_preview(
		good_id,
		quantity,
		world.settlement(world.current_settlement),
		world.settlement(destination_id),
		world.route(route_id),
		_world_context_with_cargo(world, simulated_cargo),
	)
	if not preview.ok:
		return {}
	if int(preview.purchase_total) + int(preview.route_cost) > world.money:
		return {}
	if int(preview.provisions) > world.provisions:
		return {}
	return {
		"good_id": good_id,
		"quantity": quantity,
		"destination_id": destination_id,
		"route_id": route_id,
		"preview": preview,
	}

func _is_better(candidate: Dictionary, incumbent: Dictionary, policy: String) -> bool:
	if incumbent.is_empty():
		return true
	var candidate_preview: Dictionary = candidate.preview
	var incumbent_preview: Dictionary = incumbent.preview
	if policy == "gross_margin_chaser":
		if int(candidate_preview.gross_trade_margin) != int(incumbent_preview.gross_trade_margin):
			return int(candidate_preview.gross_trade_margin) > int(incumbent_preview.gross_trade_margin)
		if int(candidate_preview.route_cost) != int(incumbent_preview.route_cost):
			return int(candidate_preview.route_cost) < int(incumbent_preview.route_cost)
		return float(candidate_preview.risk) < float(incumbent_preview.risk)
	if policy == "toll_road_only":
		if int(candidate_preview.expected_net_profit) != int(incumbent_preview.expected_net_profit):
			return int(candidate_preview.expected_net_profit) > int(incumbent_preview.expected_net_profit)
		return int(candidate_preview.gross_trade_margin) > int(incumbent_preview.gross_trade_margin)
	if int(candidate_preview.expected_net_profit) != int(incumbent_preview.expected_net_profit):
		return int(candidate_preview.expected_net_profit) > int(incumbent_preview.expected_net_profit)
	if float(candidate_preview.risk) != float(incumbent_preview.risk):
		return float(candidate_preview.risk) < float(incumbent_preview.risk)
	return int(candidate_preview.gross_trade_margin) > int(incumbent_preview.gross_trade_margin)

func _row(world: AshWorldState, policy: String, candidate: Dictionary, preview: Dictionary, status: String, incident: bool, sold_quantity: int, note: String) -> Dictionary:
	var cash_profit := world.money - STARTING_MONEY
	var provisions_used := STARTING_PROVISIONS - world.provisions
	var days_used := world.day - 1
	var assumptions := MarketContent.planning_assumptions()
	var realized_economic_profit := cash_profit - provisions_used * int(assumptions.provision_value) - days_used * int(assumptions.time_opportunity_cost_per_day)
	var event_id := ""
	var event_choice_id := ""
	if not world.event_history.is_empty():
		var event_record: Dictionary = world.event_history.back()
		event_id = String(event_record.get("id", ""))
		event_choice_id = String(event_record.get("choice_id", ""))
	return {
		"seed": world.seed,
		"policy": policy,
		"status": status,
		"good_id": String(candidate.get("good_id", "")),
		"quantity_purchased": int(candidate.get("quantity", 0)),
		"quantity_sold": sold_quantity,
		"destination_id": String(candidate.get("destination_id", "")),
		"route_id": String(candidate.get("route_id", "")),
		"incident": incident,
		"forecast_expected_net_profit": int(preview.get("expected_net_profit", 0)),
		"forecast_gross_trade_margin": int(preview.get("gross_trade_margin", 0)),
		"forecast_risk": float(preview.get("risk", 0.0)),
		"forecast_expected_loss": int(preview.get("expected_loss", 0)),
		"forecast_loss_good_id": String(preview.get("loss_good_id", "")),
		"forecast_loss_unit_value": int(preview.get("loss_unit_value", 0)),
		"realized_cash_profit": cash_profit,
		"realized_economic_profit": realized_economic_profit,
		"ending_money": world.money,
		"ending_provisions": world.provisions,
		"ending_day": world.day,
		"route_roll": _route_roll_from_history(world),
		"event_id": event_id,
		"event_choice_id": event_choice_id,
		"note": note,
	}

func _route_roll_from_history(world: AshWorldState) -> float:
	for index in range(world.command_history.size() - 1, -1, -1):
		var entry: Dictionary = world.command_history[index]
		if String(entry.id) == MarketCommandProcessor.DEPART_ROUTE:
			if entry.state_delta.has("risk_roll"):
				return float(entry.state_delta.risk_roll)
			return float(entry.state_delta.get("pending_event", {}).get("trigger_roll", -1.0))
	return -1.0

func _world_context_with_cargo(world: AshWorldState, cargo: Dictionary) -> Dictionary:
	var context := world.pricing_context()
	context["cargo"] = cargo
	return context
