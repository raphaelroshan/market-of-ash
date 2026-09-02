extends RefCounted

static func snapshot(world, travel_phase: String, waypoint_label: String, arrival_pending: bool, committed_journey_message: String, last_outcome_text: String) -> Dictionary:
	var settlement_name := String(world.settlement(world.current_settlement).get("name", "Unknown settlement"))
	var actively_traveling := travel_phase in ["moving_out", "moving_in"]
	var road_waiting := travel_phase == "road"
	var state := "planning"
	var map_hint := "Choose a settlement. HERE = current location; JOB = available assignment; ASSIGNED = accepted work."
	var event_text := ""
	var departure_status := "COMMITMENT CHECK — The map only shows legal corridors. Returning to the shop preserves this plan and spends nothing."
	var caravan_context := "CARAVAN AT REST\nNEXT — Choose a destination and compare its roads."
	if actively_traveling:
		state = "departure" if travel_phase == "moving_out" else "arrival_approach"
		map_hint = "%s — The caravan is crossing the committed road. Presentation cannot change resolved costs or risk." % waypoint_label
		event_text = "The caravan is moving through the selected corridor.\nNEXT — Watch for the road stop before any encounter or arrival."
		departure_status = "ON THE ROAD — %s. No additional choice is being resolved yet." % waypoint_label
		caravan_context = "JOURNEY — %s\nNEXT — Watch the road and continue at the travel stop." % waypoint_label
	elif road_waiting:
		state = "road"
		map_hint = "%s — Continue when you are ready to reveal the next road event or arrival." % waypoint_label
		event_text = "MID-ROUTE — The caravan has reached a readable road stop.\nNEXT — Inspect the route, then continue the journey."
		departure_status = "ROAD VIEW — %s. Inspect the corridor, then continue to the next authored encounter or arrival." % waypoint_label
		caravan_context = "JOURNEY — %s\nNEXT — Watch the road and continue at the travel stop." % waypoint_label
	elif not world.pending_event.is_empty():
		state = "event"
		map_hint = "Road encounter. Review the visible stakes and choose one available response."
		departure_status = "ROUTE DECISION — Travel is paused until you choose. Costs already paid remain spent; each option states whether you continue or return."
		caravan_context = "ROADSIDE DECISION — %s\nNEXT — Choose what the caravan will spend or risk." % String(world.pending_event.get("title", "Route encounter"))
	elif arrival_pending:
		state = "arrival"
		map_hint = "Journey complete. Review the outcome, then enter the destination bazaar."
		if last_outcome_text.is_empty() and not committed_journey_message.is_empty():
			event_text = "%s\nNEXT — Review the result, then choose Enter %s to trade at the destination." % [committed_journey_message, settlement_name]
		departure_status = "ARRIVAL REPORT — %s\nReview the factual journey receipt above, then enter the settlement to trade again." % settlement_name
		caravan_context = "ARRIVAL\nNEXT — Review the journey result, then enter the settlement."
	return {
		"state": state,
		"actively_traveling": actively_traveling,
		"road_waiting": road_waiting,
		"map_hint": map_hint,
		"event_text": event_text,
		"departure_status": departure_status,
		"caravan_context": caravan_context,
		"enter_action": "Enter %s" % settlement_name,
	}
