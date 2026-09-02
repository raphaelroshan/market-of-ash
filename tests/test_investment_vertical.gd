extends SceneTree

const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")
const JourneyPresenter = preload("res://src/ui/journey_presenter.gd")
const EVALUATION_PATH_ID := "gpt56_clean_investment_vertical"
const EVALUATION_SEED := 1107

var failures: Array[String] = []

func _init() -> void:
	var ordinary_world := _ordinary_trade_only_path()
	_expect(ordinary_world.money > 120 and ordinary_world.arms_escalation == 0, "the ordinary-trade-only control path should finish profitably without black-market pressure")
	_expect(ordinary_world.active_contracts.is_empty() and ordinary_world.contract_history.is_empty(), "the ordinary-trade-only control path must remain contract-free")

	var world := AshWorldState.new(EVALUATION_SEED)

	_expect_ok(_command(world, MarketCommandProcessor.RECRUIT_CREW, {"crew_id": "nara_vey"}), "recruit the opening route scout")
	_expect_ok(_command(world, MarketCommandProcessor.ASSIGN_CREW, {"crew_id": "nara_vey"}), "assign the opening route scout")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "water", "quantity": 4}), "buy the ordinary Water load")
	world = _checkpoint(world, "purchased cargo")

	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "commit the first authored road")
	_expect(String(world.pending_event.get("id", "")) == "three_riders_no_banner", "the investment journey should reach its authored road encounter")
	world = _checkpoint(world, "pending route event")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "three_riders_no_banner", "choice_id": "pay_for_escort"}), "choose the certain escort response")
	_expect(world.current_settlement == "reedwatch" and world.pending_event.is_empty(), "the resolved event should reach Reedwatch")
	world = _checkpoint(world, "arrival after event")

	_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "water", "quantity": 4}), "sell Water into Reedwatch demand")
	_expect(world.market_pressure_for("reedwatch", "water") > 0.0, "the ordinary sale should leave a visible market memory")
	world = _checkpoint(world, "changed destination market")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "grain", "quantity": 4}), "load the return Grain trade")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "return to Ashgate with useful cargo")
	world = _resolve_pending(world)
	var held_grain := int(world.cargo.get("grain", 0))
	_expect(held_grain > 0, "the return road should preserve a sellable Grain load")
	if held_grain > 0:
		_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "grain", "quantity": held_grain}), "close the ordinary trade circuit")
	world = _checkpoint(world, "completed ordinary circuit")

	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "sealed_arms_crate", "quantity": 2}), "acquire the optional restricted load")
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_cinder_rider_arms_sale"}), "take the optional black-market offer")
	_expect(world.arms_escalation == 2 and int(world.cargo.get("sealed_arms_crate", 0)) == 1, "the side deal should leave both profit and visible inspection pressure")
	_expect(int(world.route("toll_road", "ashgate", "brine_cross").get("cost", 0)) == 17, "carrying the remaining crate should expose the Toll Road inspection surcharge")
	world = _checkpoint(world, "black-market consequence")
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_public_manifest_audit"}), "use the named non-combat recovery")
	_expect(world.arms_escalation == 1 and int(world.route("toll_road", "ashgate", "brine_cross").get("cost", 0)) == 12, "the public audit should restore ordinary Toll Road terms")
	world = _checkpoint(world, "black-market recovery")

	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "brine_cross"}), "test the recovered official corridor")
	world = _resolve_pending(world)
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "toll_road", "destination_id": "ashgate"}), "return under Warden oversight")
	world = _resolve_pending(world)
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_provision_bundle"}), "buy the first transparent Warden service")
	_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_provision_bundle"}), "buy the second transparent Warden service")
	var advance_destinations := ["reedwatch", "ashgate", "reedwatch", "ashgate"]
	for destination_id in advance_destinations:
		_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": destination_id}), "advance the authored campaign to its regional outcome")
		world = _resolve_pending(world)
		if world.current_settlement == "ashgate":
			while int(world.reputation.get("wardens", 0)) < 3 and world.visit_slots_remaining > 0:
				_expect_ok(_command(world, MarketCommandProcessor.USE_SETTLEMENT_ACTION, {"action_id": "ashgate_provision_bundle"}), "cross the recognized-carrier threshold")

	_expect(world.day == 10 and world.ending_id == "ending_warden_reserve", "the complete journey should reach the regulated terminal regional outcome (day %d, money %d, Wardens %d, Caravans %d, arms %d, ending %s)" % [world.day, world.money, int(world.reputation.get("wardens", 0)), int(world.reputation.get("caravans", 0)), world.arms_escalation, world.ending_id])
	world = _checkpoint(world, "terminal outcome")
	var debrief := JourneyPresenter.campaign_debrief(world)
	var receipt := String(debrief.get("text", ""))
	_expect(receipt.contains("CAMPAIGN DEBRIEF") and receipt.contains("Order at the Cistern"), "the terminal receipt should name the reached ending")
	_expect(receipt.contains("Nara Vey") and receipt.contains("CREW & SIDE DEALS"), "the terminal receipt should remember the authored crew identity")
	_expect(receipt.contains("Cinder Rider broker") and receipt.contains("public manifest audit"), "the terminal receipt should disclose the optional arms choice and its recovery")
	_expect(receipt.contains("arms pressure 1/6") and receipt.contains("EVENT DECISIONS") and receipt.contains("Three Riders, No Banner"), "the terminal receipt should connect political pressure and road consequence")
	_expect(int(debrief.get("route_count", 0)) >= 6 and int(debrief.get("event_count", 0)) >= 1 and int(debrief.get("service_count", 0)) >= 5, "the receipt should summarize the complete journey rather than a single transaction")

	if failures.is_empty():
		print("Investment creative vertical: PASS (%s, seed %d)" % [EVALUATION_PATH_ID, EVALUATION_SEED])
	else:
		for failure in failures:
			push_error(failure)
		printerr("Investment creative vertical: FAIL (%d)" % failures.size())
	quit(0 if failures.is_empty() else 1)

func _ordinary_trade_only_path() -> AshWorldState:
	var world := AshWorldState.new(EVALUATION_SEED)
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "water", "quantity": 4}), "ordinary control: buy Water")
	world = _checkpoint(world, "ordinary control purchase")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "reedwatch"}), "ordinary control: depart for Reedwatch")
	_expect(String(world.pending_event.get("id", "")) == "three_riders_no_banner", "ordinary control should reach the disclosed road contact")
	_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": "three_riders_no_banner", "choice_id": "pay_for_escort"}), "ordinary control: buy certain passage")
	world = _checkpoint(world, "ordinary control arrival")
	_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "water", "quantity": 4}), "ordinary control: sell Water")
	_expect(world.market_pressure_for("reedwatch", "water") > 0.0, "ordinary control sale should change the destination market")
	_expect_ok(_command(world, MarketCommandProcessor.BUY_GOODS, {"good_id": "grain", "quantity": 4}), "ordinary control: buy return Grain")
	_expect_ok(_command(world, MarketCommandProcessor.DEPART_ROUTE, {"route_id": "old_road", "destination_id": "ashgate"}), "ordinary control: return to Ashgate")
	world = _resolve_pending(world)
	var grain_quantity := int(world.cargo.get("grain", 0))
	_expect(grain_quantity > 0, "ordinary control should arrive with a sellable Grain load")
	if grain_quantity > 0:
		_expect_ok(_command(world, MarketCommandProcessor.SELL_GOODS, {"good_id": "grain", "quantity": grain_quantity}), "ordinary control: sell return Grain")
	return _checkpoint(world, "ordinary-trade-only success")

func _checkpoint(world: AshWorldState, phase: String) -> AshWorldState:
	var serialized := world.serialize()
	var restored := AshWorldState.new(0)
	var result := restored.load_serialized(serialized)
	_expect(bool(result.get("ok", false)), "%s should restore from its deterministic save" % phase)
	var canonical := restored.serialize()
	var restored_again := AshWorldState.new(0)
	var canonical_result := restored_again.load_serialized(canonical)
	_expect(bool(canonical_result.get("ok", false)) and JSON.stringify(restored_again.serialize()) == JSON.stringify(canonical), "%s should preserve canonical state across repeated restore" % phase)
	return restored

func _resolve_pending(world: AshWorldState) -> AshWorldState:
	if world.pending_event.is_empty():
		return world
	var event_id := String(world.pending_event.get("id", ""))
	var choice_id := ""
	match event_id:
		"last_clean_barrel":
			choice_id = "sell_barrels_at_peak"
		"gatekeepers_chalk":
			choice_id = "pay_posted_toll"
		_:
			var choices: Array = world.pending_event.get("choices", [])
			if not choices.is_empty():
				choice_id = String(choices[0].get("id", ""))
	_expect(not choice_id.is_empty(), "pending event %s should expose a recoverable response" % event_id)
	if not choice_id.is_empty():
		_expect_ok(_command(world, MarketCommandProcessor.RESOLVE_EVENT, {"event_id": event_id, "choice_id": choice_id}), "resolve %s" % event_id)
	return _checkpoint(world, "resolved %s" % event_id)

func _command(world: AshWorldState, command_id: String, inputs: Dictionary) -> Dictionary:
	return MarketCommandProcessor.execute(world, {"id": command_id, "inputs": inputs})

func _expect_ok(result: Dictionary, context: String) -> void:
	_expect(bool(result.get("ok", false)), "%s: %s" % [context, String(result.get("reason", "command failed"))])

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
