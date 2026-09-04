extends SceneTree

const AshWorldState = preload("res://src/core/world_state.gd")
const TradePresenter = preload("res://src/ui/trade_presenter.gd")
const JourneyPresenter = preload("res://src/ui/journey_presenter.gd")
const JourneyPanelView = preload("res://src/ui/journey_panel_view.gd")

var failures: Array[String] = []


func _init() -> void:
	_test_trade_presenter()
	_test_event_presenter()
	_test_arrival_presenter()
	_test_journey_panel_view()
	_test_campaign_debrief_presenter()
	if failures.is_empty():
		print("PASS: Market of Ash presenter tests")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _test_trade_presenter() -> void:
	var world := AshWorldState.new(1107)
	var origin: Dictionary = world.settlement("ashgate")
	var destination: Dictionary = world.settlement("reedwatch")
	var route: Dictionary = world.route("old_road", "ashgate", "reedwatch")
	route["provisions"] = world.route_provision_cost("old_road", "reedwatch")
	var context: Dictionary = world.pricing_context()
	context["cargo"] = {"water": 2, "weight": 2}
	context["route_intelligence"] = world.route_intelligence("old_road")
	var decision_view := TradePresenter.shop_decision_view(world, "water", 2, origin, destination, route, context)
	var decision := TradePresenter.shop_decision_summary_text(world, "water", 2, origin, destination, route, context)
	var forecast := TradePresenter.route_preview_text(world, "water", 2, origin, destination, route, context)
	var comparisons := TradePresenter.route_comparison_views(world, "water", 2, "reedwatch", "old_road", context)
	_expect(decision.contains("ORDINARY TRADE · NO CONTRACT") and decision.contains("expected +") and decision.contains("NEXT — Buy 2 Water"), "trade presenter should summarize the selected ordinary-trade decision and next action")
	_expect(decision_view.get("cargo_label", "") == "WATER ×2" and decision_view.get("journey_label", "") == "ASHGATE → REEDWATCH" and decision_view.get("metrics", {}).get("net", "") == "+14", "trade presenter should expose a scannable cargo, journey, and net-value ticket")
	_expect(String(decision_view.get("road_label", "")).contains("OLD ROAD") and String(decision_view.get("resources_label", "")).contains("HOLD 0/12 → 2/12") and String(decision_view.get("next_label", "")).contains("Buy 2 Water"), "trade ticket should preserve road, capacity, and next-action context")
	_expect(forecast.contains("ROUTE FORECAST — Ashgate to Reedwatch via Old Road") and forecast.contains("Route fee") and forecast.contains("Scout confidence"), "trade presenter should expose the complete selected-route forecast")
	_expect(comparisons.size() == 3, "route comparison should keep every legal Ashgate itinerary visible")
	var selected_count := 0
	for comparison in comparisons:
		selected_count += 1 if bool(comparison.get("selected", false)) else 0
		var text := String(comparison.get("text", ""))
		_expect(text.contains("FEE") and text.contains("DAY") and text.contains("PROV") and text.contains("PLAN Water x2") and text.contains("HELD 0") and text.contains("VALUE") and text.contains("RISK") and text.contains("CONF") and text.contains("NET") and text.contains("IF BOUGHT"), "an unloaded route comparison should expose its hypothetical plan, actual hold, fee, time, provisions, value, risk, confidence, and consequence")
		_expect(String(comparison.get("tooltip", "")).contains("Hypothetical Water x2 forecast") and String(comparison.get("tooltip", "")).contains("empty travel remains legal"), "an unloaded route comparison should explain how to carry the plan without blocking empty travel")
	_expect(selected_count == 1, "route comparison should mark only the existing explicit plan as selected")
	world.cargo = {"water": 2, "weight": 2}
	var loaded_comparisons := TradePresenter.route_comparison_views(world, "water", 2, "reedwatch", "old_road", context)
	for comparison in loaded_comparisons:
		var text := String(comparison.get("text", ""))
		_expect(text.contains("PLAN Water x2") and text.contains("HELD 2") and text.contains("READY") and not text.contains("IF BOUGHT"), "a loaded route comparison should mark the selected plan ready")


func _test_event_presenter() -> void:
	var world := AshWorldState.new(1107)
	var pending := {
		"id": "presenter_fixture",
		"title": "A blocked road",
		"setup": "A toll keeper waits.",
		"origin_id": "ashgate",
		"destination_id": "reedwatch",
		"route_id": "old_road",
		"stakes": "Pay or risk the cargo.",
		"loss_basis": {"loss_quantity": 1, "loss_good_id": "water", "loss_unit_value": 30},
		"choices": [
			{"id": "pay", "label": "Pay", "money_cost": 999, "outcome": "The road opens."},
			{"id": "cross", "label": "Cross", "cargo_risk": 0.4, "outcome": "The caravan presses on."},
		],
	}
	var view := JourneyPresenter.event_view(world, pending)
	var choices: Array = view.get("choices", [])
	_expect(view.get("title", "") == "A blocked road" and String(view.get("stakes", "")).contains("Highest cargo-loss chance: 40%"), "event presenter should expose authored identity and maximum stated danger")
	_expect(view.get("threat_label", "") == "THREAT · UP TO 40% CARGO LOSS" and String(view.get("exposed_label", "")).contains("WATER x1") and String(view.get("road_label", "")).contains("OLD ROAD"), "event presenter should expose a scannable threat, cargo, and road dossier")
	_expect(String(view.get("decision_label", "")).contains("Pay or risk the cargo") and String(view.get("rules_label", "")).contains("Only the costs and consequences written here"), "event dossier should preserve the authored dilemma and explicit terms boundary")
	_expect(choices.size() == 2 and bool(choices[0].get("disabled", false)) and String(choices[0].get("blocked_reason", "")).contains("999 ashmarks"), "event presenter should keep unaffordable choices visible with the exact blocker")
	_expect(not bool(choices[1].get("disabled", true)) and String(choices[1].get("text", "")).contains("MANEUVER / RISK ROLL 40%"), "event presenter should label available risky tactics consistently")


func _test_arrival_presenter() -> void:
	var world := AshWorldState.new(1107)
	var record := {
		"origin_id": "ashgate",
		"destination_id": "reedwatch",
		"choice_id": "wait",
		"choices": [{"id": "wait", "label": "Wait for daylight", "days": 1, "outcome": "The caravan reaches the wells."}],
		"outcome": {"money": 0, "provisions": 0, "cargo": {}, "day": 1, "current_settlement": "reedwatch", "cargo_risk": 0.0},
	}
	var comparison := JourneyPresenter.conflict_outcome_comparison(world, record)
	_expect(comparison.contains("JOURNEY RESULT") and comparison.contains("CHOICE — WAIT / CERTAIN") and comparison.contains("+1 days") and comparison.contains("arrived at Reedwatch"), "arrival presenter should compare the disclosed plan with the authoritative result")
	var certain_receipt := JourneyPresenter.conflict_outcome_receipt(record)
	_expect(certain_receipt.get("state", "") == "certain" and certain_receipt.get("kicker", "") == "PLAN HELD" and String(certain_receipt.get("detail", "")).contains("never placed cargo at risk"), "certain outcomes should produce a concise plan-held receipt")
	record["loss_basis"] = {"loss_good_id": "medicine", "loss_quantity": 1, "loss_unit_value": 52}
	record["outcome"] = {"cargo_risk": 0.45, "resolution_roll": 0.24, "cargo": {"medicine": -1, "weight": -1}}
	var loss_receipt := JourneyPresenter.conflict_outcome_receipt(record)
	_expect(loss_receipt.get("state", "") == "loss" and loss_receipt.get("title", "") == "Medicine x1 lost" and String(loss_receipt.get("detail", "")).contains("Road roll 24") and String(loss_receipt.get("detail", "")).contains("risk 45"), "realized cargo risk should produce a compact, factual loss receipt")
	record["outcome"] = {"cargo_risk": 0.45, "resolution_roll": 0.76, "cargo": {}}
	var safe_receipt := JourneyPresenter.conflict_outcome_receipt(record)
	_expect(safe_receipt.get("state", "") == "safe" and safe_receipt.get("kicker", "") == "RISK AVOIDED" and String(safe_receipt.get("title", "")).contains("arrived intact"), "avoided cargo risk should produce a compact intact-cargo receipt")


func _test_journey_panel_view() -> void:
	var world := AshWorldState.new(1107)
	var departure := JourneyPanelView.snapshot(world, "moving_out", "LEAVING ASHGATE", false, "", "")
	_expect(departure.state == "departure" and departure.panel_title == "ON THE ROAD" and String(departure.map_hint).contains("Passage is paid") and String(departure.departure_status).contains("committed until the next stop"), "departure view should communicate committed travel in caravan language")
	var road := JourneyPanelView.snapshot(world, "road", "ROAD STOP — THE BROKEN MILEPOSTS", false, "", "")
	_expect(road.state == "road" and road.panel_title == "ROAD STOP" and String(road.event_text).contains("MID-ROUTE") and String(road.caravan_context).begins_with("ROAD STOP — THE BROKEN MILEPOSTS"), "road view should provide an explicit player-controlled pause without repeating a generic journey label")
	world.pending_event = {"title": "Three Riders, No Banner"}
	var event := JourneyPanelView.snapshot(world, "encounter", "ENCOUNTER", false, "", "")
	_expect(event.state == "event" and event.panel_title == "ROADSIDE DECISION" and String(event.caravan_context).contains("Three Riders, No Banner"), "event view should name the authored contact under a distinct roadside heading")
	world.pending_event.clear()
	world.current_settlement = "reedwatch"
	var arrival := JourneyPanelView.snapshot(world, "arrived", "ARRIVED", true, "Pay 10 ashmarks; you arrive at Reedwatch.", "")
	_expect(arrival.state == "arrival" and arrival.panel_title == "ARRIVED AT REEDWATCH" and arrival.enter_action == "Enter Reedwatch" and String(arrival.departure_status).contains("ARRIVAL — Reedwatch") and String(arrival.caravan_context).begins_with("JOURNEY COMPLETE"), "arrival view should expose a distinct handoff and destination action")


func _test_campaign_debrief_presenter() -> void:
	var world := AshWorldState.new(1107)
	world.money = 146
	world.provisions = 10
	world.day = 10
	world.ending_id = "open_routes_relief"
	world.ending_summary = "Shared deliveries kept the wells open."
	world.reputation["caravans"] = 2
	world.settlement_resilience["reedwatch"] = 2
	world.command_history = [
		{"id": "buy_goods", "ok": true, "day": 1, "inputs": {"good_id": "water", "quantity": 2}, "state_delta": {"money": -30, "cargo": {"water": 2}}},
		{"id": "depart_route", "ok": true, "day": 2, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}, "state_delta": {"money": -4, "provisions": -1, "day": 1}},
		{"id": "sell_goods", "ok": true, "day": 2, "inputs": {"good_id": "water", "quantity": 2}, "state_delta": {"money": 60, "cargo": {"water": -2}}},
	]
	world.event_history = [{"title": "The Last Clean Barrel", "choice_id": "share", "choices": [{"id": "share", "label": "Share the barrels"}]}]
	var debrief := JourneyPresenter.campaign_debrief(world)
	var text := String(debrief.get("text", ""))
	_expect(text.contains("CAMPAIGN DEBRIEF") and text.contains("ROUTE TIMELINE") and text.contains("Old Road → Reedwatch"), "campaign debrief should reconstruct the route timeline")
	_expect(text.contains("CARGO & CASH") and text.contains("TIME & PROVISIONS") and text.contains("EVENT DECISIONS"), "campaign debrief should compose resource and event evidence")
	_expect(text.contains("REGIONAL CONSEQUENCES") and text.contains("CAUSAL LESSON") and text.contains("REPLAY EXPERIMENT") and text.contains("Seed 1107 fixes world rolls"), "campaign debrief should explain consequences and propose a reproducible alternative experiment")
