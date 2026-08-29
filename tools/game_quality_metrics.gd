class_name GameQualityMetrics
extends RefCounted

## Deterministic release-gate probes derived from the GPT game-quality audit.
## These exercise the same command and economy boundaries as the player build.

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

const STARTING_MONEY := 120
const STARTING_PROVISIONS := 12
const SEED_COUNT := 100

static func evaluate() -> Dictionary:
	return {
		"safe_opening": _safe_opening_probe(),
		"opening_variety": _opening_variety_probe(),
		"trade_pattern_families": _trade_pattern_families_probe(),
		"contract_parity": _contract_parity_probe(),
		"path_reward_balance": _path_reward_balance_probe(),
		"adaptive_failure_recovery": _adaptive_failure_recovery_probe(),
		"replacement_faction_agency": _replacement_faction_agency_probe(),
		"adaptive_ending": _adaptive_ending_probe(),
		"world_state_variety": _world_state_variety_probe(),
		"cargo_loss_recovery": _cargo_loss_recovery_probe(),
		"preparation_overhead": _preparation_overhead_probe(),
	}

static func _safe_opening_probe() -> Dictionary:
	var completed := 0
	var minimum_money := STARTING_MONEY
	var minimum_provisions := STARTING_PROVISIONS
	var loss_runs := 0
	for seed in range(1, SEED_COUNT + 1):
		var world := AshWorldState.new(seed)
		var result := _execute_trade(world, _candidate_for(world, "water", 2, "reedwatch", "old_road"))
		if bool(result.get("ok", false)):
			completed += 1
		minimum_money = mini(minimum_money, world.money)
		minimum_provisions = mini(minimum_provisions, world.provisions)
		if bool(result.get("cargo_lost", false)):
			loss_runs += 1
	return {
		"runs": SEED_COUNT,
		"completed": completed,
		"completion_rate": float(completed) / float(SEED_COUNT),
		"minimum_money": minimum_money,
		"minimum_provisions": minimum_provisions,
		"cargo_loss_runs": loss_runs,
	}

static func _opening_variety_probe() -> Dictionary:
	var world := AshWorldState.new(1107)
	var candidates := _positive_candidates(world)
	var choices: Array[String] = []
	var goods := {}
	var routes := {}
	for candidate in candidates:
		var choice := "%s → %s / %s" % [String(candidate.good_id), String(candidate.destination_id), String(candidate.route_id)]
		if not choices.has(choice):
			choices.append(choice)
		goods[String(candidate.good_id)] = true
		routes[String(candidate.route_id)] = true
	return {
		"positive_strategy_count": choices.size(),
		"good_count": goods.size(),
		"route_count": routes.size(),
		"choices": choices,
	}

static func _trade_pattern_families_probe() -> Dictionary:
	var fixtures := [
		{"family": "staple", "origin_id": "ashgate", "good_id": "water", "quantity": 2, "destination_id": "reedwatch", "route_id": "old_road"},
		{"family": "repair", "origin_id": "cinderford", "good_id": "scrap", "quantity": 4, "destination_id": "ashgate", "route_id": "toll_road"},
		{"family": "medicine", "origin_id": "hollow_market", "good_id": "medicine", "quantity": 2, "destination_id": "reedwatch", "route_id": "dry_cut"},
		{"family": "industrial", "origin_id": "cinderford", "good_id": "charcoal", "quantity": 4, "destination_id": "brine_cross", "route_id": "toll_road"},
	]
	var results: Array[Dictionary] = []
	var viable_count := 0
	for fixture in fixtures:
		var world := AshWorldState.new(1107)
		world.current_settlement = String(fixture.origin_id)
		var candidate := _candidate_for(world, String(fixture.good_id), int(fixture.quantity), String(fixture.destination_id), String(fixture.route_id))
		var expected_net := int(candidate.get("preview", {}).get("expected_net_profit", 0))
		var viable := not candidate.is_empty() and expected_net > 0
		if viable:
			viable_count += 1
		results.append({
			"family": String(fixture.family),
			"origin_id": String(fixture.origin_id),
			"destination_id": String(fixture.destination_id),
			"good_id": String(fixture.good_id),
			"route_id": String(fixture.route_id),
			"expected_net_profit": expected_net,
			"viable": viable,
			"requires_contract": false,
		})
	return {"fixture_count": fixtures.size(), "viable_count": viable_count, "all_viable": viable_count == fixtures.size(), "results": results}

static func _contract_parity_probe() -> Dictionary:
	var world := AshWorldState.new(1107)
	var best_ordinary := _best_candidate(world)
	var ordinary_net := int(best_ordinary.get("preview", {}).get("expected_net_profit", 0))
	var contract := MarketContent.contract("reedwatch_water_relief_01")
	var contract_preview := MarketEconomy.contract_reward_preview(contract, world.settlement("ashgate"), world.settlement("reedwatch"), world.route("old_road", "ashgate", "reedwatch"), world.pricing_context())
	var contract_expected_net := int(contract_preview.get("expected_net_profit", 0))
	var parity_ratio := float(ordinary_net) / float(contract_expected_net) if contract_expected_net > 0 else 0.0
	return {
		"ordinary_choice": "%s → %s / %s" % [String(best_ordinary.get("good_id", "")), String(best_ordinary.get("destination_id", "")), String(best_ordinary.get("route_id", ""))],
		"ordinary_expected_net_profit": ordinary_net,
		"contract_id": String(contract.get("id", "")),
		"contract_expected_net_profit": contract_expected_net,
		"ordinary_to_contract_ratio": parity_ratio,
		"minimum_ratio": 0.70,
		"passed": ordinary_net > 0 and parity_ratio >= 0.70,
	}

static func _path_reward_balance_probe() -> Dictionary:
	var assumptions := MarketContent.planning_assumptions()
	var world := AshWorldState.new(1107)
	var ordinary := _best_candidate(world)
	var ordinary_preview: Dictionary = ordinary.get("preview", {})
	var ordinary_vector := MarketEconomy.reward_vector_from_trade_preview(ordinary_preview)
	var contract := MarketContent.contract("reedwatch_water_relief_01")
	var contract_preview := MarketEconomy.contract_reward_preview(contract, world.settlement("ashgate"), world.settlement("reedwatch"), world.route("old_road", "ashgate", "reedwatch"), world.pricing_context())
	var contract_vector: Dictionary = contract_preview.get("reward_vector", {})
	var civic_vector := _action_reward_vector(MarketContent.settlement_action("reedwatch_supply_shelter"))
	var faction_vector := _action_reward_vector(MarketContent.settlement_action("reedwatch_commons_boiler_fuel"))
	var ordinary_net := int(ordinary_vector.get("expected_net_profit", 0))
	var contract_net := int(contract_vector.get("expected_net_profit", 0))
	var contract_ratio := float(contract_net) / float(ordinary_net) if ordinary_net > 0 else 0.0
	var minimum_ratio := float(assumptions.get("contract_expected_net_min_ratio", 1.0))
	var maximum_ratio := float(assumptions.get("contract_expected_net_max_ratio", 1.2))
	var required_dimensions := ["ashmarks_after_direct_costs", "expected_net_profit", "provisions_used", "capacity_committed", "standing", "time_days", "visit_slots"]
	var all_dimensions_tracked := true
	for vector in [ordinary_vector, contract_vector, civic_vector, faction_vector]:
		for dimension in required_dimensions:
			if not vector.has(dimension):
				all_dimensions_tracked = false
	var paths := {
		"ordinary": ordinary_vector,
		"contract": contract_vector,
		"civic": civic_vector,
		"faction": faction_vector,
	}
	return {
		"fixture_minutes": int(assumptions.get("reward_fixture_minutes", 0)),
		"ordinary_choice": "%s → %s / %s" % [String(ordinary.get("good_id", "")), String(ordinary.get("destination_id", "")), String(ordinary.get("route_id", ""))],
		"contract_id": String(contract.get("id", "")),
		"contract_to_ordinary_expected_net_ratio": contract_ratio,
		"minimum_contract_ratio": minimum_ratio,
		"maximum_contract_ratio": maximum_ratio,
		"all_dimensions_tracked": all_dimensions_tracked,
		"non_cash_paths_are_explicit": int(civic_vector.get("resilience", 0)) > 0 and int(faction_vector.get("support", 0)) > 0,
		"passed": int(assumptions.get("reward_fixture_minutes", 0)) == 10 and all_dimensions_tracked and ordinary_net > 0 and contract_ratio >= minimum_ratio and contract_ratio <= maximum_ratio,
		"paths": paths,
	}

static func _action_reward_vector(action: Dictionary) -> Dictionary:
	var effects: Dictionary = action.get("effects", {})
	var cargo_cost: Dictionary = effects.get("cargo_cost", {})
	var capacity_committed := int(cargo_cost.get("quantity", 0)) * int(MarketContent.good(String(cargo_cost.get("good_id", ""))).get("weight", 0))
	var resilience: Dictionary = effects.get("settlement_resilience", {})
	var support: Dictionary = effects.get("emergent_faction_support", {})
	return {
		"ashmarks_after_direct_costs": -int(action.get("cost", 0)),
		"expected_net_profit": -int(action.get("cost", 0)),
		"provisions_used": 0,
		"capacity_committed": capacity_committed,
		"standing": effects.get("reputation", {}).duplicate(true),
		"time_days": int(action.get("time_cost", 0)),
		"visit_slots": int(action.get("service_slots", 0)),
		"resilience": int(resilience.get("delta", 0)),
		"support": int(support.get("delta", 0)),
	}

static func _adaptive_failure_recovery_probe() -> Dictionary:
	var world := AshWorldState.new(1107)
	var baseline := _candidate_for(world, "charcoal", 4, "reedwatch", "old_road")
	var baseline_net := int(baseline.get("preview", {}).get("expected_net_profit", 0))
	world.advance_day(3)
	var replacement := _candidate_for(world, "charcoal", 4, "reedwatch", "old_road")
	var replacement_net := int(replacement.get("preview", {}).get("expected_net_profit", 0))
	return {
		"scenario_state": String(world.scenario_state("reedwatch_water_relief").get("state", "")),
		"faction_active": not world.emergent_faction("well_commons").is_empty(),
		"reedwatch_resilience": world.resilience_for("reedwatch"),
		"baseline_charcoal_net": baseline_net,
		"replacement_charcoal_net": replacement_net,
		"new_trade_viable": baseline_net <= 0 and replacement_net > 0,
		"offer_closed": not world.contract_offer_closed_reason("reedwatch_water_relief_01").is_empty(),
	}

static func _replacement_faction_agency_probe() -> Dictionary:
	var cooperative := AshWorldState.new(1107)
	cooperative.advance_day(3)
	cooperative.current_settlement = "reedwatch"
	cooperative.cargo = {"charcoal": 2, "weight": 2}
	var fuel := MarketCommandProcessor.execute(cooperative, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	var ledger := MarketCommandProcessor.execute(cooperative, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_open_ledger"}})
	var cooperative_support := int(cooperative.emergent_faction("well_commons").get("support", 0))

	var bypass := AshWorldState.new(1107)
	bypass.advance_day(3)
	bypass.current_settlement = "reedwatch"
	var permit := MarketCommandProcessor.execute(bypass, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_warden_cistern_bypass"}})
	var opposed_support := int(bypass.emergent_faction("well_commons").get("support", 0))
	bypass.reset_visit_slots()
	bypass.cargo = {"charcoal": 2, "weight": 2}
	var reconcile := MarketCommandProcessor.execute(bypass, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	var reconciled_support := int(bypass.emergent_faction("well_commons").get("support", 0))
	return {
		"cooperation_paths_completed": int(bool(fuel.ok)) + int(bool(ledger.ok)),
		"cooperative_support": cooperative_support,
		"opposition_path_completed": bool(permit.ok),
		"opposed_support": opposed_support,
		"reconciliation_completed": bool(reconcile.ok),
		"reconciled_support": reconciled_support,
		"ordinary_trade_open": MarketEconomy.price_for("charcoal", bypass.settlement("reedwatch"), bypass.pricing_context()) > MarketEconomy.price_for("charcoal", bypass.settlement("ashgate"), bypass.pricing_context()),
	}

static func _adaptive_ending_probe() -> Dictionary:
	var world := AshWorldState.new(1107)
	world.advance_day(3)
	world.resolved_event_ids = ["span_at_cinderford", "three_riders_no_banner"]
	var bought := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "charcoal", "quantity": 6}})
	var departed := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}}) if bought.ok else {"ok": false}
	var sold := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.SELL_GOODS, "inputs": {"good_id": "charcoal", "quantity": 4}}) if departed.ok and world.pending_event.is_empty() else {"ok": false}
	var supported := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}}) if sold.ok else {"ok": false}
	if supported.ok:
		world.advance_day(maxi(0, 10 - world.day))
	var delivery := world.latest_market_delivery("reedwatch", "charcoal")
	var faction := world.emergent_faction("well_commons")
	return {
		"commands_completed": bool(bought.ok) and bool(departed.ok) and bool(sold.ok) and bool(supported.ok),
		"scenario_state": String(world.scenario_state("reedwatch_water_relief").get("state", "")),
		"delivery_quantity": int(faction.get("ordinary_deliveries", {}).get("charcoal", 0)),
		"delivery_day": int(delivery.get("day", 0)),
		"activation_day": int(faction.get("activated_day", 0)),
		"support": int(faction.get("support", 0)),
		"reedwatch_resilience": world.resilience_for("reedwatch"),
		"ending_id": world.ending_id,
		"passed": world.ending_id == "ending_commons_exchange",
	}

static func _world_state_variety_probe() -> Dictionary:
	var scenarios: Array[Dictionary] = []
	var baseline := AshWorldState.new(1107)
	scenarios.append({"id": "ordinary_opening", "world": baseline})

	var supplied_reedwatch := AshWorldState.new(1107)
	_saturate_market(supplied_reedwatch, "reedwatch", ["water"])
	scenarios.append({"id": "reedwatch_water_supplied", "world": supplied_reedwatch})

	var broad_reedwatch_supply := AshWorldState.new(1107)
	_saturate_market(broad_reedwatch_supply, "reedwatch", ["water", "medicine", "scrap", "charcoal", "cloth", "grain"])
	scenarios.append({"id": "reedwatch_broad_supply", "world": broad_reedwatch_supply})

	var regulated_corridor := AshWorldState.new(1107)
	regulated_corridor.adjust_reputation("wardens", 2)
	regulated_corridor.set_route_condition("toll_road", {
		"id": "quality_probe_repaired_corridor",
		"label": "Repaired regulated corridor",
		"risk_delta": -0.08,
		"cost_delta": -2,
		"description": "A test-only state representing accumulated Warden access and road work.",
	})
	_saturate_market(regulated_corridor, "reedwatch", ["water", "medicine", "scrap", "charcoal", "cloth", "grain"])
	scenarios.append({"id": "recognized_warden_corridor", "world": regulated_corridor})

	var results: Array[Dictionary] = []
	var choices := {}
	var routes := {}
	for scenario in scenarios:
		var world: AshWorldState = scenario.world
		var best := _best_candidate(world)
		var choice := "%s → %s / %s" % [String(best.get("good_id", "")), String(best.get("destination_id", "")), String(best.get("route_id", ""))]
		choices[choice] = true
		routes[String(best.get("route_id", ""))] = true
		results.append({
			"scenario": String(scenario.id),
			"choice": choice,
			"expected_net_profit": int(best.get("preview", {}).get("expected_net_profit", 0)),
		})
	return {"scenario_count": results.size(), "choice_count": choices.size(), "route_count": routes.size(), "results": results}

static func _cargo_loss_recovery_probe() -> Dictionary:
	for seed in range(1, SEED_COUNT + 1):
		var world := AshWorldState.new(seed)
		var first_result := _execute_trade(world, _candidate_for(world, "water", 2, "reedwatch", "old_road"))
		if not bool(first_result.get("cargo_lost", false)):
			continue
		var money_after_loss := world.money
		var minimum_money := world.money
		var recovery_trips := 0
		while world.money < STARTING_MONEY and recovery_trips < 3:
			if world.current_settlement != "ashgate":
				var return_route := _route_between(world.current_settlement, "ashgate")
				var returned := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": return_route, "destination_id": "ashgate"}})
				if not returned.ok or not _resolve_pending_event(world).ok:
					break
			minimum_money = mini(minimum_money, world.money)
			var candidate := _best_candidate(world)
			if candidate.is_empty() or int(candidate.get("preview", {}).get("expected_net_profit", 0)) <= 0:
				break
			var recovery_result := _execute_trade(world, candidate)
			recovery_trips += 1
			minimum_money = mini(minimum_money, world.money)
			if not bool(recovery_result.get("ok", false)):
				break
		return {
			"cargo_loss_observed": true,
			"seed": seed,
			"money_after_loss": money_after_loss,
			"minimum_money": minimum_money,
			"ending_money": world.money,
			"ending_provisions": world.provisions,
			"recovery_trips": recovery_trips,
			"recovered": world.money >= STARTING_MONEY,
		}
	return {"cargo_loss_observed": false, "recovered": false}

static func _preparation_overhead_probe() -> Dictionary:
	var world := AshWorldState.new(1107)
	var accepted := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.ACCEPT_CONTRACT, "inputs": {"contract_id": "reedwatch_water_relief_01"}})
	var bought := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "water", "quantity": 4}}) if accepted.ok else {"ok": false}
	var first_trade_command := 0
	for index in range(world.command_history.size()):
		if String(world.command_history[index].get("id", "")) == MarketCommandProcessor.BUY_GOODS:
			first_trade_command = index + 1
			break
	return {
		"tutorial_setup_ok": bool(accepted.ok) and bool(bought.ok),
		"commands_through_first_trade": first_trade_command,
		"non_trade_commands_before_first_trade": maxi(0, first_trade_command - 1),
	}

static func _saturate_market(world: AshWorldState, settlement_id: String, good_ids: Array[String]) -> void:
	for good_id in good_ids:
		world.record_market_delivery(settlement_id, good_id, 12)

static func _positive_candidates(world: AshWorldState) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	for good_id in MarketContent.good_ids():
		var purchase_price := MarketEconomy.price_for(good_id, world.settlement(world.current_settlement), world.pricing_context())
		for destination_id in MarketContent.destinations_from(world.current_settlement):
			for route_id in MarketContent.routes_from(world.current_settlement):
				if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
					continue
				var route := world.route(route_id, world.current_settlement, destination_id)
				var max_quantity := mini(world.cargo_capacity, int((world.money - int(route.get("cost", 0))) / purchase_price))
				if max_quantity <= 0:
					continue
				var candidate := _candidate_for(world, good_id, max_quantity, destination_id, route_id)
				if not candidate.is_empty() and int(candidate.preview.expected_net_profit) > 0:
					candidates.append(candidate)
	return candidates

static func _best_candidate(world: AshWorldState) -> Dictionary:
	var best := {}
	for candidate in _positive_candidates(world):
		if best.is_empty() or int(candidate.preview.expected_net_profit) > int(best.preview.expected_net_profit):
			best = candidate
	return best

static func _candidate_for(world: AshWorldState, good_id: String, quantity: int, destination_id: String, route_id: String) -> Dictionary:
	if not MarketContent.route_connects(route_id, world.current_settlement, destination_id):
		return {}
	var simulated_cargo := world.cargo.duplicate(true)
	simulated_cargo[good_id] = int(simulated_cargo.get(good_id, 0)) + quantity
	simulated_cargo["weight"] = int(simulated_cargo.get("weight", 0)) + int(MarketContent.good(good_id).get("weight", 0)) * quantity
	var context := world.pricing_context()
	context["cargo"] = simulated_cargo
	var route := world.route(route_id, world.current_settlement, destination_id)
	var preview := MarketEconomy.route_profit_preview(good_id, quantity, world.settlement(world.current_settlement), world.settlement(destination_id), route, context)
	if not preview.ok or int(preview.purchase_total) + int(preview.route_cost) > world.money or int(preview.provisions) > world.provisions:
		return {}
	return {"good_id": good_id, "quantity": quantity, "destination_id": destination_id, "route_id": route_id, "preview": preview}

static func _execute_trade(world: AshWorldState, candidate: Dictionary) -> Dictionary:
	if candidate.is_empty():
		return {"ok": false, "cargo_lost": false}
	var before_weight := int(world.cargo.get("weight", 0))
	var buy := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": candidate.good_id, "quantity": candidate.quantity}})
	if not buy.ok:
		return {"ok": false, "cargo_lost": false}
	var loaded_weight := int(world.cargo.get("weight", 0))
	var depart := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": candidate.route_id, "destination_id": candidate.destination_id}})
	if not depart.ok:
		return {"ok": false, "cargo_lost": false}
	var event_result := _resolve_pending_event(world)
	if not event_result.ok:
		return {"ok": false, "cargo_lost": false}
	var cargo_lost := int(world.cargo.get("weight", 0)) < loaded_weight
	var remaining := int(world.cargo.get(String(candidate.good_id), 0))
	if remaining > 0:
		var sell := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.SELL_GOODS, "inputs": {"good_id": candidate.good_id, "quantity": remaining}})
		if not sell.ok:
			return {"ok": false, "cargo_lost": cargo_lost}
	return {"ok": int(world.cargo.get("weight", 0)) == before_weight, "cargo_lost": cargo_lost}

static func _resolve_pending_event(world: AshWorldState) -> Dictionary:
	if world.pending_event.is_empty():
		return {"ok": true}
	var event_id := String(world.pending_event.get("id", ""))
	var choice_id := "wait_for_stamped_review"
	if event_id == "gatekeepers_chalk":
		choice_id = "pay_posted_toll" if world.money >= 6 else "wait_for_stamped_review"
	elif event_id == "span_at_cinderford":
		choice_id = "turn_back_with_cargo"
	elif event_id == "last_clean_barrel":
		choice_id = "keep_barrels_sealed"
	elif event_id == "three_riders_no_banner":
		choice_id = "pay_for_escort" if world.money >= 10 else "wait_and_read_the_tracks"
	return MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.RESOLVE_EVENT, "inputs": {"event_id": event_id, "choice_id": choice_id}})

static func _route_between(origin_id: String, destination_id: String) -> String:
	for route_id in MarketContent.routes_from(origin_id):
		if MarketContent.route_connects(route_id, origin_id, destination_id):
			return route_id
	return ""
