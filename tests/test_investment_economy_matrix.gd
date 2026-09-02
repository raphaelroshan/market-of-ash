extends SceneTree

const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

const TRIALS := 100
const STRATEGIES := [
	{"origin": "ashgate", "destination": "reedwatch", "route": "old_road", "good": "water", "quantity": 3, "day": 0},
	{"origin": "sunfall_exchange", "destination": "mirror_wells", "route": "mirror_run", "good": "lamp_oil", "quantity": 3, "day": 5},
	{"origin": "kiln_rest", "destination": "mirror_wells", "route": "emberglass_byway", "good": "lamp_oil", "quantity": 3, "day": 5},
	{"origin": "mothlight_quay", "destination": "blackreed_post", "route": "reedline_track", "good": "medicine", "quantity": 3, "day": 1},
	{"origin": "mothlight_quay", "destination": "emberfen_refuge", "route": "emberfen_drift", "good": "cloth", "quantity": 3, "day": 1},
]

var failures: Array[String] = []

func _init() -> void:
	var completed := 0
	var profitable := 0
	var bankruptcies := 0
	var cargo_loss_trials := 0
	var total_profit := 0
	var total_utilization := 0.0
	var total_arrival_day := 0
	var route_usage := {}
	var good_usage := {}
	var event_outcomes := {"none": 0}
	var route_profit := {}
	var crisis_stages := {}
	for trial_index in range(TRIALS):
		var strategy: Dictionary = STRATEGIES[trial_index % STRATEGIES.size()]
		var world := AshWorldState.new(trial_index + 1)
		world.current_settlement = String(strategy.origin)
		world.day = int(strategy.day)
		world._update_crisis_modifiers()
		var starting_money := world.money
		var buy := _command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": strategy.good, "quantity": strategy.quantity})
		if not buy.ok:
			failures.append("trial %d could not buy its ordinary cargo: %s" % [trial_index + 1, buy.message])
			continue
		total_utilization += float(world.cargo.weight) / float(world.cargo_capacity)
		var depart := _command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": strategy.route, "destination_id": strategy.destination})
		if not depart.ok:
			failures.append("trial %d could not depart: %s" % [trial_index + 1, depart.message])
			continue
		var event_id := String(world.pending_event.get("id", "none"))
		if not world.pending_event.is_empty():
			var resolution := _resolve_safe_event(world)
			if not resolution.ok:
				failures.append("trial %d had no affordable no-loss response: %s" % [trial_index + 1, resolution.message])
				continue
			event_outcomes[event_id] = int(event_outcomes.get(event_id, 0)) + 1
		else:
			event_outcomes.none = int(event_outcomes.none) + 1
		var held_quantity := int(world.cargo.get(String(strategy.good), 0))
		if held_quantity < int(strategy.quantity):
			cargo_loss_trials += 1
		var sale := _command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": strategy.good, "quantity": held_quantity})
		if not sale.ok:
			failures.append("trial %d could not sell its ordinary cargo: %s" % [trial_index + 1, sale.message])
			continue
		var profit := world.money - starting_money
		completed += 1
		profitable += 1 if profit > 0 else 0
		bankruptcies += 1 if world.money < 0 else 0
		total_profit += profit
		total_arrival_day += world.day
		var crisis_key := str(world.crisis_stage)
		crisis_stages[crisis_key] = int(crisis_stages.get(crisis_key, 0)) + 1
		var route_id := String(strategy.route)
		var good_id := String(strategy.good)
		route_usage[route_id] = int(route_usage.get(route_id, 0)) + 1
		good_usage[good_id] = int(good_usage.get(good_id, 0)) + 1
		route_profit[route_id] = int(route_profit.get(route_id, 0)) + profit

	var maximum_route_share := 0.0
	for count in route_usage.values():
		maximum_route_share = maxf(maximum_route_share, float(count) / float(TRIALS))
	var maximum_good_share := 0.0
	for count in good_usage.values():
		maximum_good_share = maxf(maximum_good_share, float(count) / float(TRIALS))
	_expect(completed == TRIALS, "all 100 seeded economy trials should complete")
	_expect(bankruptcies == 0, "the 100 seeded ordinary-trade trials should not create bankruptcy")
	_expect(profitable >= 75, "at least 75% of seeded ordinary-trade trials should remain profitable after disclosed route losses")
	_expect(maximum_route_share <= 0.20, "no route should dominate more than 20% of the balanced trial matrix")
	_expect(maximum_good_share <= 0.40, "no good should dominate more than 40% of the balanced trial matrix")
	_expect(event_outcomes.size() >= 3, "the seeded matrix should exercise multiple event outcomes plus quiet roads")
	if failures.is_empty():
		print("Investment economy matrix: PASS")
		print("100 seeded trials — completed %d; profitable %d; bankruptcies %d; cargo-loss trials %d; mean profit %.2f; mean cargo utilization %.1f%%; mean arrival day %.2f" % [completed, profitable, bankruptcies, cargo_loss_trials, float(total_profit) / TRIALS, total_utilization * 100.0 / TRIALS, float(total_arrival_day) / TRIALS])
		print("Route use: %s" % JSON.stringify(route_usage))
		print("Route net profit: %s" % JSON.stringify(route_profit))
		print("Goods: %s; events: %s" % [JSON.stringify(good_usage), JSON.stringify(event_outcomes)])
		print("Arrival crisis stages: %s" % JSON.stringify(crisis_stages))
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _resolve_safe_event(world: AshWorldState) -> Dictionary:
	var event_id := String(world.pending_event.get("id", ""))
	for choice_value in world.pending_event.get("choices", []):
		var choice: Dictionary = choice_value
		if float(choice.get("cargo_risk", 0.0)) > 0.0:
			continue
		if bool(choice.get("requires_active_contract", false)) or not String(choice.get("requires_assigned_crew_id", "")).is_empty():
			continue
		if int(choice.get("money_cost", 0)) > world.money or int(choice.get("provision_cost", 0)) > world.provisions:
			continue
		var cargo_cost: Dictionary = choice.get("cargo_cost", {})
		if not cargo_cost.is_empty() and int(world.cargo.get(String(cargo_cost.get("good_id", "")), 0)) < int(cargo_cost.get("quantity", 0)):
			continue
		return _command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": event_id, "choice_id": choice.id})
	return {"ok": false, "message": "no safe response"}

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
