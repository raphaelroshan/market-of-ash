class_name TutorialDirector
extends RefCounted

const VERSION := 2

const STEP_BUY_WATER := "buy_water"
const STEP_PLAN_REEDWATCH := "plan_reedwatch"
const STEP_ROAD_DECISION := "road_decision"
const STEP_ENTER_REEDWATCH := "enter_reedwatch"
const STEP_SELL_WATER := "sell_water"
const STEP_BUY_GRAIN := "buy_grain"
const STEP_RETURN_ASHGATE := "return_ashgate"
const STEP_ENTER_ASHGATE := "enter_ashgate"
const STEP_SELL_GRAIN := "sell_grain"
const STEP_REVIEW_OPTIONAL_WORK := "review_optional_work"
const STEP_RECRUIT_CREW := "recruit_crew"
const STEP_ASSIGN_CREW := "assign_crew"
const STEP_REVIEW_OUTLOOK := "review_outlook"
const STEP_COMPLETE := "complete"

var enabled := false
var intro_seen := false
var completed := false
var outlook_seen := false
var optional_work_seen := false
var current_step := ""
var completed_steps: Array[String] = []

func start() -> void:
	enabled = true
	intro_seen = true
	completed = false
	outlook_seen = false
	optional_work_seen = false
	current_step = STEP_BUY_WATER
	completed_steps.clear()

func skip() -> void:
	enabled = false
	intro_seen = true
	completed = false
	current_step = ""

func mark_outlook_seen() -> void:
	outlook_seen = true

func mark_optional_work_seen() -> void:
	optional_work_seen = true

func refresh(world, presentation_state: String, arrival_pending: bool) -> void:
	if not enabled or completed or world == null:
		return
	var next_step := _derive_step(world, presentation_state, arrival_pending)
	if next_step != current_step:
		if not current_step.is_empty() and current_step != STEP_COMPLETE and not completed_steps.has(current_step):
			completed_steps.append(current_step)
		current_step = next_step
	if current_step == STEP_COMPLETE:
		completed = true
		enabled = false

func _derive_step(world, presentation_state: String, arrival_pending: bool) -> String:
	var held_water := int(world.cargo.get("water", 0))
	var held_grain := int(world.cargo.get("grain", 0))
	var bought_water := _successful_quantity(world, "buy_goods", "water", "ashgate")
	var sold_water := _successful_quantity(world, "sell_goods", "water", "reedwatch")
	var sold_grain := _successful_quantity(world, "sell_goods", "grain", "ashgate")
	var relief_status := _contract_status(world, "reedwatch_water_relief_01")
	var water_delivered := sold_water > 0 or relief_status == "completed"

	if world.current_settlement == "ashgate" and bought_water == 0 and held_water < 4:
		return STEP_BUY_WATER
	if world.current_settlement == "ashgate" and held_water >= 4 and presentation_state in ["settlement_shop", "departure_desk"]:
		return STEP_PLAN_REEDWATCH
	if presentation_state in ["route_travel", "route_event"]:
		return STEP_ROAD_DECISION
	if arrival_pending and world.current_settlement == "reedwatch":
		return STEP_ENTER_REEDWATCH
	if world.current_settlement == "reedwatch" and held_water > 0 and not water_delivered:
		return STEP_SELL_WATER
	if world.current_settlement == "reedwatch" and water_delivered and held_grain < 4:
		return STEP_BUY_GRAIN
	if world.current_settlement == "reedwatch" and held_grain >= 4 and presentation_state in ["settlement_shop", "departure_desk"]:
		return STEP_RETURN_ASHGATE
	if arrival_pending and world.current_settlement == "ashgate":
		return STEP_ENTER_ASHGATE
	if world.current_settlement == "ashgate" and held_grain > 0:
		return STEP_SELL_GRAIN
	if world.current_settlement == "ashgate" and sold_grain > 0 and not optional_work_seen:
		return STEP_REVIEW_OPTIONAL_WORK
	if world.current_settlement == "ashgate" and sold_grain > 0 and world.recruited_crew.is_empty():
		return STEP_RECRUIT_CREW
	if world.current_settlement == "ashgate" and not world.recruited_crew.is_empty() and world.assigned_crew.is_empty():
		return STEP_ASSIGN_CREW
	if world.current_settlement == "ashgate" and not world.assigned_crew.is_empty() and not outlook_seen:
		return STEP_REVIEW_OUTLOOK
	if outlook_seen:
		return STEP_COMPLETE
	return current_step

func objective() -> Dictionary:
	var objectives := {
		STEP_BUY_WATER: {"chapter": "BUY WHERE SUPPLY IS STRONG", "title": "Buy four Water", "body": "Ashgate water is cheap; Reedwatch's low wells pay more. Load four units—no contract needed.", "section": "trade"},
		STEP_PLAN_REEDWATCH: {"chapter": "CHOOSE THE ROAD", "title": "Plan Reedwatch by the Old Road", "body": "At Departure, compare fee, provisions, days, and the cargo at risk. Choose the Old Road when ready.", "section": "departure"},
		STEP_ROAD_DECISION: {"chapter": "ON THE ROAD", "title": "Follow the road, then choose", "body": "The caravan stops before any encounter. Continue when ready, then weigh each response against the load.", "section": "road"},
		STEP_ENTER_REEDWATCH: {"chapter": "ARRIVAL", "title": "Count what reached Reedwatch", "body": "Read what the road cost and what arrived. Then enter Reedwatch.", "section": "arrival"},
		STEP_SELL_WATER: {"chapter": "SELL WHERE NEED IS REAL", "title": "Sell the Water in Reedwatch", "body": "You paid 15 each in Ashgate. Sell the surviving Water and watch Reedwatch's price respond to new supply.", "section": "trade"},
		STEP_BUY_GRAIN: {"chapter": "RETURN TRADE", "title": "Buy four Grain for Ashgate", "body": "Reedwatch grows Grain that Ashgate needs. Load four units for the return road.", "section": "trade"},
		STEP_RETURN_ASHGATE: {"chapter": "RETURN TRADE", "title": "Plan the road back to Ashgate", "body": "The Old Road is familiar, but your cargo and its consequences have changed. Compare it before leaving.", "section": "departure"},
		STEP_ENTER_ASHGATE: {"chapter": "HOME ROAD", "title": "Bring the caravan into Ashgate", "body": "No encounter is still a journey. Read the arrival, then enter Ashgate.", "section": "arrival"},
		STEP_SELL_GRAIN: {"chapter": "CLOSE THE LOOP", "title": "Sell the Grain that arrived", "body": "Sell the Grain and read the changed local price. Useful cargo should pay in both directions.", "section": "trade"},
		STEP_REVIEW_OPTIONAL_WORK: {"chapter": "OPTIONAL WORK", "title": "Compare an assignment", "body": "The Job Board trades flexibility for pay, deadlines, and standing. Compare one offer; accepting is optional.", "section": "assignments"},
		STEP_RECRUIT_CREW: {"chapter": "PEOPLE CHANGE ROUTES", "title": "Recruit one crew member", "body": "Each specialist changes one road decision and carries a limit. Recruit the one who fits your next route.", "section": "crew"},
		STEP_ASSIGN_CREW: {"chapter": "PEOPLE CHANGE ROUTES", "title": "Assign the new crew member", "body": "Spend the second visit action to prepare one road. Crew changes information, provisions, or event choices—not combat power.", "section": "crew"},
		STEP_REVIEW_OUTLOOK: {"chapter": "THE WIDER BASIN", "title": "Open Town Outlook", "body": "Town Outlook shows the water crisis, local resilience, faction standing, arms pressure, and possible futures.", "section": "outlook"},
		STEP_COMPLETE: {"chapter": "TUTORIAL COMPLETE", "title": "The caravan is yours", "body": "Trade, contracts, crew, roads, and politics now share one campaign. Choose the next promise you will make to the road.", "section": "outlook"},
	}
	return Dictionary(objectives.get(current_step, {}))

func serialize() -> Dictionary:
	return {
		"version": VERSION,
		"enabled": enabled,
		"intro_seen": intro_seen,
		"completed": completed,
		"outlook_seen": outlook_seen,
		"optional_work_seen": optional_work_seen,
		"current_step": current_step,
		"completed_steps": completed_steps.duplicate(),
	}

func load_serialized(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		skip()
		return
	var record: Dictionary = data
	enabled = bool(record.get("enabled", false))
	intro_seen = bool(record.get("intro_seen", false))
	completed = bool(record.get("completed", false))
	outlook_seen = bool(record.get("outlook_seen", false))
	optional_work_seen = bool(record.get("optional_work_seen", false))
	current_step = String(record.get("current_step", STEP_BUY_WATER if enabled else ""))
	completed_steps.clear()
	var saved_steps: Variant = record.get("completed_steps", [])
	if typeof(saved_steps) == TYPE_ARRAY:
		for step_value in saved_steps:
			var step_id := String(step_value)
			if not completed_steps.has(step_id):
				completed_steps.append(step_id)

func _contract_status(world, contract_id: String) -> String:
	if world.active_contracts.has(contract_id):
		return "active"
	for outcome in world.contract_history:
		if String(outcome.get("contract_id", outcome.get("id", ""))) == contract_id:
			return String(outcome.get("status", "completed"))
	return ""

func _successful_quantity(world, command_id: String, good_id: String, settlement_id: String) -> int:
	var quantity := 0
	for record in world.command_history:
		if not bool(record.get("ok", false)) or String(record.get("id", "")) != command_id:
			continue
		var inputs: Dictionary = record.get("inputs", {})
		if String(inputs.get("good_id", "")) != good_id:
			continue
		var delta: Dictionary = record.get("state_delta", {})
		var recorded_settlement := String(delta.get("settlement_id", inputs.get("settlement_id", "")))
		if recorded_settlement.is_empty():
			recorded_settlement = String(record.get("settlement_id", ""))
		if recorded_settlement.is_empty() or recorded_settlement == settlement_id:
			quantity += int(inputs.get("quantity", 0))
	return quantity
