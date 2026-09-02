extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")
const JourneyPresenter = preload("res://src/ui/journey_presenter.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_bellkeeper_standing_changes_causeway_terms()
	_test_night_market_agency_and_ending()
	_test_night_market_ending_rejects_wrong_delivery_modes()
	if failures.is_empty():
		print("MA-EA-4 faction and ending smoke: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _test_bellkeeper_standing_changes_causeway_terms() -> void:
	var world := AshWorldState.new(1)
	world.current_settlement = "mothlight_quay"
	world.cargo = {"medicine": 2, "weight": 2}
	var base_cost := int(world.route("salt_causeway").get("cost", 0))
	var base_risk := float(world.route("salt_causeway").get("risk", 0.0))
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mothlight_bell_chart"}), "fund the Bellkeeper chart")
	_expect(int(world.reputation.get("bellkeepers", 0)) == 1 and float(world.route("salt_causeway").get("risk", 1.0)) < base_risk, "the chart should build Bellkeeper standing and reduce route risk")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "salt_causeway", "destination_id": "brine_cross"}), "depart with a charted bell line")
	_expect(world.pending_event.get("id", "") == "causeway_whiteout", "the standing fixture should encounter the whiteout")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "causeway_whiteout", "choice_id": "hire_bell_keeper"}), "hire the Bellkeeper guide")
	_expect(int(world.reputation.get("bellkeepers", 0)) == 2, "the guide should reach Bellkeeper trusted standing")
	_expect(world.faction_status("bellkeepers").get("tier", "") == "Bell-line regular", "trusted Bellkeeper standing should expose its authored tier")
	_expect(int(world.route("salt_causeway").get("cost", 0)) == base_cost - 2, "Bellkeeper trust should discount only the Salt Causeway by two ashmarks")
	_expect(int(world.route("old_road").get("cost", 0)) == 4, "Bellkeeper trust should not alter unrelated roads")
	var restored := AshWorldState.new(0)
	_expect_ok(restored.load_serialized(world.serialize()), "restore Bellkeeper standing")
	_expect(int(restored.reputation.get("bellkeepers", 0)) == 2 and int(restored.route("salt_causeway").get("cost", 0)) == base_cost - 2, "save/load should preserve the fourth faction's route effect")

	var opposed := AshWorldState.new(1)
	opposed.current_settlement = "brine_cross"
	opposed.cargo = {"medicine": 2, "weight": 2}
	_expect_ok(_command(opposed, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "salt_causeway", "destination_id": "mothlight_quay"}), "enter the whiteout without prior standing")
	_expect_ok(_command(opposed, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "causeway_whiteout", "choice_id": "follow_the_fading_bells"}), "ignore the Bellkeeper line")
	_expect(int(opposed.reputation.get("bellkeepers", 0)) == -1 and opposed.current_settlement == "mothlight_quay", "the risky rejection should cost standing but still arrive")

func _test_night_market_agency_and_ending() -> void:
	var world := AshWorldState.new(7)
	world.advance_day(7)
	world.current_settlement = "mirror_wells"
	world.cargo = {"lamp_oil": 2, "weight": 2}
	world.reset_visit_slots()
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mirror_wells_night_beacons"}), "support the independent beacons")
	_expect(int(world.emergent_faction("night_market").get("support", 0)) == 1 and world.resilience_for("mirror_wells") == 2, "beacon support should strengthen the replacement actor and settlement")
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mirror_wells_consortium_license"}), "oppose the Night Market through licensing")
	_expect(int(world.emergent_faction("night_market").get("support", 0)) == 0 and int(world.reputation.get("glass_consortium", 0)) == 0, "the license should reverse support without closing the market")
	world.reset_visit_slots()
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mirror_wells_signal_ledger"}), "reconcile through the public signal ledger")
	_expect(int(world.emergent_faction("night_market").get("support", 0)) == 1 and world.known_information.has("night_market_signal_ledger"), "the later cooperation path should restore support and record its route knowledge")
	world.cargo = {"saltglass": 4, "weight": 4}
	_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "saltglass", "quantity": 4}), "make the qualifying ordinary saltglass delivery")
	_expect(int(world.emergent_faction("night_market").get("ordinary_deliveries", {}).get("saltglass", 0)) == 4, "the replacement actor should retain durable ordinary-delivery credit")
	world.advance_day(10 - world.day)
	_expect(world.ending_id == "ending_night_market_network", "Night Market support and ordinary saltglass should reach its alternate ending")
	var debrief := JourneyPresenter.campaign_debrief(world)
	_expect(String(debrief.get("text", "")).contains("Beacons Without Licenses") and String(debrief.get("text", "")).contains("Causeway Bellkeepers") and String(debrief.get("replay_experiment", "")).contains("licensed beacon delivery"), "the debrief should expose the new ending, fourth faction, and replay contrast")

func _test_night_market_ending_rejects_wrong_delivery_modes() -> void:
	var preactivation := AshWorldState.new(7)
	preactivation.record_market_delivery("mirror_wells", "saltglass", 4)
	preactivation.advance_day(7)
	preactivation.current_settlement = "mirror_wells"
	preactivation.cargo = {"lamp_oil": 2, "weight": 2}
	preactivation.reset_visit_slots()
	_expect_ok(_command(preactivation, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mirror_wells_night_beacons"}), "support Night Market after an early delivery")
	preactivation.advance_day(10 - preactivation.day)
	_expect(preactivation.ending_id != "ending_night_market_network", "saltglass delivered before Night Market activation must not satisfy the ending")

	var transferred := AshWorldState.new(7)
	transferred.advance_day(7)
	transferred.record_market_delivery("mirror_wells", "saltglass", 4, "event_trade")
	transferred.current_settlement = "mirror_wells"
	transferred.cargo = {"lamp_oil": 2, "weight": 2}
	transferred.reset_visit_slots()
	_expect_ok(_command(transferred, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "mirror_wells_night_beacons"}), "support Night Market after an event transfer")
	transferred.advance_day(10 - transferred.day)
	_expect(transferred.ending_id != "ending_night_market_network", "event or contract transfers must not count as ordinary Night Market trade")

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, context: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [context, String(result.get("message", "command failed"))])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
