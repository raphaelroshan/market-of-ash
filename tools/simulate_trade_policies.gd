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
	for seed in range(1, SEED_COUNT + 1):
		for policy in POLICIES:
			rows.append(_run_policy(seed, policy))
	var payload := {
		"simulation": "Market of Ash first-run single-trade policy simulation",
		"seed_count": SEED_COUNT,
		"starting_state": {"money": STARTING_MONEY, "provisions": STARTING_PROVISIONS, "cargo_weight": 0, "settlement": "ashgate", "day": 1},
		"policies": POLICIES,
		"rows": rows,
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
	var incident := bool(depart.state_delta.get("cargo", {}).get("weight", 0) < 0)
	return _row(world, policy, candidate, preview, "completed", incident, sold_quantity, sell_message)

func _choose_candidate(world: AshWorldState, policy: String) -> Dictionary:
	if policy == "guided_grain_delivery":
		return _candidate_for(world, "grain", 2, "reedwatch", "old_road")
	var best: Dictionary = {}
	for good_id in MarketContent.good_ids():
		var origin := world.settlement(world.current_settlement)
		var purchase_price := MarketEconomy.price_for(good_id, origin, {"crisis_modifiers": world.crisis_modifiers})
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
		{"crisis_modifiers": world.crisis_modifiers, "cargo": simulated_cargo},
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
		"note": note,
	}

func _route_roll_from_history(world: AshWorldState) -> float:
	for index in range(world.command_history.size() - 1, -1, -1):
		var entry: Dictionary = world.command_history[index]
		if String(entry.id) == MarketCommandProcessor.DEPART_ROUTE:
			return float(entry.state_delta.get("risk_roll", -1.0))
	return -1.0
