extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const MarketEconomy = preload("res://src/core/economy.gd")
const AshWorldState = preload("res://src/core/world_state.gd")
const MarketCommandProcessor = preload("res://src/core/market_command_processor.gd")

var failures: Array[String] = []

func _init() -> void:
	_test_runtime_content()
	_test_glasswind_reach_slice()
	_test_base_prices()
	_test_regional_price_spread()
	_test_crisis_changes_water_price()
	_test_capacity_validation()
	_test_explainable_route_preview()
	_test_ordinary_trade_story()
	_test_incident_loss_model()
	_test_command_buy_and_sell()
	_test_market_memory()
	_test_adaptive_relief_response()
	_test_well_commons_interactions()
	_test_settlement_actions()
	_test_reedwatch_relief_contract()
	_test_brine_cross_medicine_escort_contract()
	_test_gatekeepers_chalk_event()
	_test_span_at_cinderford_event()
	_test_last_clean_barrel_event()
	_test_three_riders_no_banner_event()
	_test_nara_vey_crew()
	_test_jorun_pale_crew()
	_test_tess_oryn_crew()
	_test_warden_relationship_threshold()
	_test_arms_trade_proof()
	_test_crisis_progression_and_ending()
	_test_command_validation_and_history()
	_test_depart_command()
	_test_travel_consumes_resources()
	_test_save_round_trip()
	_test_disk_save_sanitization()
	_test_legacy_save_migration()
	if failures.is_empty():
		print("PASS: Market of Ash economy tests")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _test_runtime_content() -> void:
	MarketContent.reset_cache()
	var content := MarketContent.load_runtime()
	_expect(content.ok, "runtime world content should load and validate")
	_expect(MarketContent.content_version() == "1.28.0", "runtime content should expose content version")
	for settlement_id in MarketContent.settlement_ids():
		var identity: Dictionary = MarketContent.settlements().get(settlement_id, {}).get("identity", {})
		_expect(not identity.is_empty() and not String(identity.get("scene_id", "")).is_empty() and not String(identity.get("market_read", "")).is_empty(), "settlement %s should expose its data-driven visual and market identity" % settlement_id)
	var planning := MarketContent.planning_assumptions()
	_expect(int(planning.get("reward_fixture_minutes", 0)) == 10 and float(planning.get("contract_expected_net_min_ratio", 0.0)) == 1.0, "runtime content should expose the ten-minute cross-path reward benchmark")
	_expect(MarketContent.ending_records().size() == 6 and MarketContent.ending("ending_commons_exchange").get("title", "") == "The Wells Belong to Those Who Carry" and MarketContent.ending("ending_night_market_network").get("title", "") == "Beacons Without Licenses" and MarketContent.ending("ending_warden_reserve").get("title", "") == "Order at the Cistern" and MarketContent.ending("ending_free_caravan_routes").get("title", "") == "No Road Owns the Sky" and MarketContent.ending("ending_ash_merchant").get("title", "") == "The Best Margin", "runtime content should expose all stable ending records")
	var memory_rules := MarketContent.market_memory_rules()
	_expect(float(memory_rules.get("pressure_max", 0.0)) == 0.35, "runtime content should expose bounded market-memory rules")
	_expect(float(memory_rules.get("producer_decay_multiplier", 0.0)) == 0.75 and float(memory_rules.get("consumer_decay_multiplier", 0.0)) == 1.5, "runtime content should expose differentiated replenishment rules")
	var ashgate_profile: Dictionary = MarketContent.settlements().get("ashgate", {}).get("trade_profile", {})
	_expect(ashgate_profile.get("produces", {}).has("water") and ashgate_profile.get("consumes", {}).has("scrap"), "runtime content should expose authored production and consumption roles")
	_expect(int(MarketContent.settlement_action_rules().get("visit_slots_per_arrival", 0)) == 2, "runtime content should expose the two-slot visit budget")
	_expect(MarketContent.settlement_action("ashgate_provision_bundle").get("settlement_id", "") == "ashgate", "runtime content should expose the live Ashgate provision action")
	_expect(int(MarketContent.settlement_action("brine_cross_cistern_queue").get("minimum_crisis_stage", 0)) == 1, "runtime content should expose the shortage-gated Brine Cross action")
	_expect(MarketContent.settlement_actions_for("reedwatch").size() == 4, "runtime content should expose the relief shelter and three Well Commons interaction paths")
	_expect(MarketContent.contract("reedwatch_water_relief_01").get("destination_id", "") == "reedwatch", "runtime content should expose the first relief contract")
	_expect(MarketContent.contract("brine_cross_medicine_escort_01").get("destination_id", "") == "brine_cross", "runtime content should expose the regulated escort contract")
	_expect(MarketContent.adaptive_scenario("reedwatch_water_relief").get("contract_id", "") == "reedwatch_water_relief_01", "runtime content should expose the adaptive relief scenario")
	_expect(MarketContent.event("gatekeepers_chalk").get("route_ids", []).has("toll_road"), "runtime content should expose the first Toll Road event")
	_expect(MarketContent.event("span_at_cinderford").get("route_ids", []).has("old_road"), "runtime content should expose the Cinderford span event")
	_expect(MarketContent.event("last_clean_barrel").get("destination_ids", []).has("reedwatch"), "runtime content should expose the shortage settlement event")
	_expect(MarketContent.event("three_riders_no_banner").get("route_ids", []).has("old_road"), "runtime content should expose the suspicious escort event")
	_expect(MarketContent.event("shardwind_tithe").get("route_ids", []).has("glasswind_trace"), "runtime content should expose the Glasswind pressure event")
	_expect(MarketContent.event("causeway_whiteout").get("route_ids", []).has("salt_causeway"), "runtime content should expose the Siltfire causeway event")
	_expect(MarketContent.crew_member("nara_vey").get("role", "") == "Scout", "runtime content should expose Nara Vey's stable crew record")
	_expect(MarketContent.crew_member("jorun_pale").get("role", "") == "Quartermaster", "runtime content should expose Jorun Pale's stable crew record")
	_expect(MarketContent.crew_member("tess_oryn").get("role", "") == "Fixer", "runtime content should expose Tess Oryn's stable crew record")
	_expect(int(MarketContent.faction("wardens").get("trusted_threshold", 0)) == 2, "runtime content should expose the first Warden threshold")
	_expect(int(MarketContent.faction("caravans").get("trusted_threshold", 0)) == 2, "runtime content should expose the Free Caravan threshold")
	_expect(int(MarketContent.faction("glass_consortium").get("trusted_threshold", 0)) == 2, "runtime content should expose Glass Consortium pressure")
	_expect(int(MarketContent.faction("bellkeepers").get("trusted_threshold", 0)) == 2, "runtime content should expose Causeway Bellkeeper pressure")
	_expect(MarketContent.good_ids() == ["grain", "water", "scrap", "medicine", "charcoal", "cloth", "sealed_arms_crate", "saltglass", "dune_spice", "lamp_oil"], "runtime content should expose authored stable good ids")
	_expect(MarketContent.settlements().size() == 11, "runtime content should expose all three regions' eleven settlements")
	_expect(MarketContent.routes().size() == 9, "runtime content should expose nine route families")
	_expect(MarketContent.region("glasswind_reach").get("settlement_ids", []).size() == 3 and MarketContent.region_for_settlement("mirror_wells").get("id", "") == "glasswind_reach", "runtime content should expose the three-settlement Glasswind Reach")
	_expect(MarketContent.region("siltfire_march").get("settlement_ids", []).size() == 3 and MarketContent.region_for_settlement("emberfen_refuge").get("id", "") == "siltfire_march", "runtime content should expose the three-settlement Siltfire March")
	_expect(MarketContent.route_connects("old_road", "ashgate", "reedwatch"), "old road should connect its authored endpoints")
	_expect(not MarketContent.route_connects("old_road", "ashgate", "brine_cross"), "old road should reject destinations outside its authored endpoints")
	_expect(MarketContent.route_connects("toll_road", "ashgate", "cinderford") and MarketContent.route_connects("toll_road", "cinderford", "brine_cross"), "Toll Road should expose Cinderford as a reachable authored stop")
	_expect(MarketContent.destinations_from("ashgate") == ["reedwatch", "cinderford", "brine_cross"], "Ashgate should expose Reedwatch and both Toll Road destinations")
	_expect(MarketContent.destinations_from("cinderford") == ["ashgate", "brine_cross"], "Cinderford should expose both adjacent/full Toll Road connections")
	_expect(MarketContent.destinations_from("hollow_market").has("sunfall_exchange") and MarketContent.destinations_from("sunfall_exchange").has("mirror_wells"), "Glasswind Reach should connect to the Basin and expose its inner road")
	_expect(MarketContent.destinations_from("brine_cross").has("mothlight_quay") and MarketContent.destinations_from("blackreed_post").has("reedwatch") and MarketContent.destinations_from("mothlight_quay").has("emberfen_refuge"), "Siltfire March should connect to both sides of the Basin and its third market")

func _test_glasswind_reach_slice() -> void:
	var sunfall: Dictionary = MarketContent.settlements().get("sunfall_exchange", {})
	var kiln: Dictionary = MarketContent.settlements().get("kiln_rest", {})
	var mirror: Dictionary = MarketContent.settlements().get("mirror_wells", {})
	var context := {"crisis_modifiers": {}, "market_pressure": {}, "adaptive_market_modifiers": {}}
	_expect(MarketEconomy.price_for("saltglass", sunfall, context) < MarketEconomy.price_for("saltglass", kiln, context), "Sunfall saltglass should support an ordinary profitable run to Kiln Rest")
	_expect(MarketEconomy.price_for("dune_spice", mirror, context) < MarketEconomy.price_for("dune_spice", sunfall, context), "Mirror Wells spice should support an ordinary profitable return to Sunfall")
	_expect(MarketEconomy.price_for("lamp_oil", kiln, context) < MarketEconomy.price_for("lamp_oil", mirror, context), "Kiln Rest lamp oil should support an ordinary profitable run to Mirror Wells")
	_expect(MarketContent.contract("mirror_wells_lamp_relief_01").get("origin_id", "") == "sunfall_exchange", "Glasswind Reach should expose its optional beacon contract")
	_expect(MarketContent.adaptive_scenario("mirror_wells_beacon_oil").get("failure_response", {}).get("faction_id", "") == "night_market", "the beacon contract should fail forward into the Night Market")
	var world := AshWorldState.new(41)
	world.current_settlement = "sunfall_exchange"
	world.day = 5
	world._update_crisis_modifiers()
	var buy := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "lamp_oil", "quantity": 3}})
	_expect(buy.ok, "the second region should permit its ordinary lamp-oil trade")
	var depart := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "mirror_run", "destination_id": "mirror_wells"}})
	_expect(depart.ok and world.current_settlement == "mirror_wells" or not world.pending_event.is_empty(), "the second region route should complete or pause at its deterministic event")
	_expect(world.money >= 0 and world.provisions >= 0 and int(world.cargo.get("weight", 0)) <= world.cargo_capacity, "the second-region journey should preserve resource invariants")

func _test_base_prices() -> void:
	_expect(MarketEconomy.base_price("water") == 18, "water base price should be 18")
	_expect(MarketEconomy.base_price("medicine") == 32, "medicine base price should be 32")
	_expect(MarketEconomy.base_price("missing") == 0, "unknown goods should have price 0")

func _test_regional_price_spread() -> void:
	var world := AshWorldState.new(1107)
	var origin := world.settlement("cinderford")
	var destination := world.settlement("reedwatch")
	var origin_price := MarketEconomy.price_for("scrap", origin, {"crisis_modifiers": world.crisis_modifiers})
	var destination_price := MarketEconomy.price_for("scrap", destination, {"crisis_modifiers": world.crisis_modifiers})
	var projected := MarketEconomy.projected_profit("scrap", 2, origin, destination, {"crisis_modifiers": world.crisis_modifiers})
	_expect(destination_price > origin_price, "regional price spread should reward moving scrap from Cinderford to Reedwatch")
	_expect(projected > 0, "a useful distant-market cargo should have positive projected gross profit")
	var explanation := MarketEconomy.explain_price("water", destination, {"crisis_modifiers": {"water": 1.5}})
	_expect(explanation.find("high") >= 0, "price explanation should identify high demand or crisis pressure")

func _test_crisis_changes_water_price() -> void:
	var world := AshWorldState.new(1107)
	var settlement := world.settlement("reedwatch")
	var before := MarketEconomy.price_for("water", settlement, {"crisis_modifiers": world.crisis_modifiers})
	world.crisis_stage = 2
	world._update_crisis_modifiers()
	var after := MarketEconomy.price_for("water", settlement, {"crisis_modifiers": world.crisis_modifiers})
	_expect(after > before, "water should become more expensive during the crisis")

func _test_capacity_validation() -> void:
	var result := MarketEconomy.validate_trade({"weight": 11}, "grain", 2, 12)
	_expect(not result.ok, "trade should fail when cargo capacity is exceeded")
	var valid := MarketEconomy.validate_trade({"weight": 10}, "grain", 2, 12)
	_expect(valid.ok, "trade should pass when cargo fits")
	_expect(int(valid.added_weight) == 2, "trade validation should report added cargo weight")

func _test_explainable_route_preview() -> void:
	var world := AshWorldState.new(1107)
	var origin := world.settlement("ashgate")
	var destination := world.settlement("reedwatch")
	var details := MarketEconomy.price_details("water", destination, {"crisis_modifiers": world.crisis_modifiers})
	_expect(details.ok, "price details should be available for a valid good and settlement")
	_expect(details.reasons.has("local production is limited"), "price details should expose local production pressure")
	_expect(details.reasons.has("Frontier wells run low, so local demand is high for every sealed water load."), "price details should expose authored consumption pressure")
	world.crisis_stage = 2
	world._update_crisis_modifiers()
	var crisis_details := MarketEconomy.price_details("water", destination, {"crisis_modifiers": world.crisis_modifiers})
	_expect(crisis_details.reasons.has("the regional crisis is increasing demand"), "price details should expose crisis pressure")

	var route := world.route("old_road")
	var preview := MarketEconomy.route_profit_preview("water", 2, origin, destination, route, {
		"crisis_modifiers": world.crisis_modifiers,
		"cargo": {"water": 2, "weight": 2},
	})
	_expect(preview.ok, "route profit preview should return a valid forecast")
	_expect(int(preview.purchase_total) == int(preview.origin_price) * 2, "preview should expose the complete purchase total")
	_expect(int(preview.sale_total) == int(preview.destination_price) * 2, "preview should expose the complete expected sale total")
	_expect(int(preview.provision_cost) == int(preview.provisions) * int(preview.provision_value), "preview should expose provisions and their value")
	_expect(preview.loss_model == MarketEconomy.LOSS_MODEL_ONE_EXPOSED_UNIT, "route preview should expose the stable one-unit loss model")
	_expect(preview.loss_good_id == "water" and int(preview.loss_quantity) == 1, "route preview should identify the exposed carried unit")
	_expect(int(preview.loss_unit_value) == int(preview.destination_price), "route preview should value the exposed unit at the destination price")
	_expect(int(preview.expected_loss) == int(round(float(preview.loss_unit_value) * float(preview.risk))), "route preview should calculate expected loss from one exposed unit")
	_expect(not String(preview.risk_source).is_empty(), "route preview should expose the authored risk source")
	_expect(int(preview.expected_net_profit) == int(preview.gross_trade_margin) - int(preview.route_cost) - int(preview.provision_cost) - int(preview.expected_loss) - int(preview.time_cost), "preview net profit should equal the displayed cost breakdown")
	var invalid := MarketEconomy.route_profit_preview("missing", 2, origin, destination, route, {"crisis_modifiers": world.crisis_modifiers})
	_expect(not invalid.ok, "route preview should reject an unknown good")

func _test_ordinary_trade_story() -> void:
	var world := AshWorldState.new(1107)
	var route := world.route("old_road", "ashgate", "reedwatch")
	route["provisions"] = world.route_provision_cost("old_road", "reedwatch")
	var context := world.pricing_context()
	context["cargo"] = {"water": 2, "weight": 2}
	var story := MarketEconomy.ordinary_trade_story("water", 2, world.settlement("ashgate"), world.settlement("reedwatch"), route, context)
	_expect(story.ok and bool(story.no_contract_required), "ordinary trade story should explicitly remain independent of contracts")
	_expect(bool(story.origin_is_source) and bool(story.destination_is_consumer), "ordinary trade story should connect an authored source to an authored recurring need")
	_expect(int(story.origin_price) == 15 and int(story.destination_price) == 32 and int(story.unit_spread) == 17, "ordinary trade story should expose the authoritative unit spread")
	_expect(int(story.gross_margin) == 34 and int(story.expected_net_profit) == 14, "ordinary trade story should expose the authoritative load margin and expected net")
	_expect(int(story.reward_vector.capacity_committed) == 2 and int(story.reward_vector.provisions_used) == 1 and int(story.reward_vector.visit_slots) == 0, "ordinary trade should expose its capacity, provisions, and unrestricted visit-slot value separately")
	_expect(String(story.source_reason).contains("cistern releases") and String(story.need_reason).contains("Frontier wells"), "ordinary trade story should carry authored source and need explanations")
	var contract_preview := MarketEconomy.contract_reward_preview(MarketContent.contract("reedwatch_water_relief_01"), world.settlement("ashgate"), world.settlement("reedwatch"), route, world.pricing_context())
	_expect(contract_preview.ok and int(contract_preview.expected_net_profit) == 100, "the rebalanced relief contract should offer a small expected premium over the best ordinary opening")
	_expect(int(contract_preview.reward_vector.capacity_committed) == 4 and int(contract_preview.reward_vector.provisions_used) == 1 and int(contract_preview.reward_vector.standing.get("caravans", 0)) == 1 and int(contract_preview.reward_vector.visit_slots) == 1, "contract value should track hold, provisions, standing, and visit time separately")
	var invalid := MarketEconomy.ordinary_trade_story("missing", 2, world.settlement("ashgate"), world.settlement("reedwatch"), route, context)
	_expect(not invalid.ok, "ordinary trade story should reject an unknown good")

func _test_incident_loss_model() -> void:
	var world := AshWorldState.new(3)
	var destination := world.settlement("reedwatch")
	var context := {"crisis_modifiers": world.crisis_modifiers}
	var water_basis := MarketEconomy.incident_loss_basis({"water": 2, "weight": 2}, destination, context)
	_expect(water_basis.loss_model == MarketEconomy.LOSS_MODEL_ONE_EXPOSED_UNIT, "incident basis should expose the stable model id")
	_expect(water_basis.loss_good_id == "water" and int(water_basis.loss_quantity) == 1, "single-good cargo should expose exactly one unit")
	_expect(int(water_basis.loss_unit_value) == 32, "water incident basis should use the current Reedwatch unit price")
	_expect(MarketEconomy.expected_incident_loss(world.route("old_road"), water_basis) == 11, "Old Road water expected loss should be risk times one unit value")
	var toll_basis := MarketEconomy.incident_loss_basis({"medicine": 3, "weight": 3}, world.settlement("brine_cross"), context)
	_expect(int(toll_basis.loss_unit_value) == 44, "medicine incident basis should use the current Brine Cross unit price")
	_expect(MarketEconomy.expected_incident_loss(world.route("toll_road"), toll_basis) == 4, "Toll Road medicine expected loss should use one unit")
	var mixed_basis := MarketEconomy.incident_loss_basis({"water": 2, "medicine": 1, "weight": 3}, destination, context)
	_expect(mixed_basis.loss_good_id == "medicine" and int(mixed_basis.loss_unit_value) == 52, "mixed cargo should expose the highest destination-value unit")
	var empty_basis := MarketEconomy.incident_loss_basis({"weight": 0}, destination, context)
	_expect(empty_basis.loss_good_id.is_empty() and int(empty_basis.loss_quantity) == 0, "empty cargo should expose no unit")
	_expect(MarketEconomy.expected_incident_loss(world.route("old_road"), empty_basis) == 0, "empty cargo should have zero expected loss")

	world.cargo = {"water": 2, "medicine": 1, "weight": 3}
	world.resolved_event_ids.append("three_riders_no_banner")
	var incident := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(incident.ok and float(incident.state_delta.risk_roll) < float(incident.state_delta.risk), "seeded incident fixture should resolve an Old Road incident")
	_expect(incident.state_delta.loss_good_id == "medicine" and int(incident.state_delta.loss_unit_value) == 52, "incident result should preserve the disclosed loss basis")
	_expect(int(incident.state_delta.expected_loss) == 18, "incident result should preserve the disclosed expected loss")
	_expect(int(world.cargo.get("medicine", 0)) == 0 and int(world.cargo.get("water", 0)) == 2, "incident should remove the same exposed unit chosen by the forecast helper")
	_expect(incident.message.contains("lost 1 medicine worth 52 ashmarks"), "incident result should explain the unit and destination value lost")

	var replay_world := AshWorldState.new(3)
	replay_world.cargo = {"water": 2, "medicine": 1, "weight": 3}
	replay_world.resolved_event_ids.append("three_riders_no_banner")
	var replay := MarketCommandProcessor.execute(replay_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(JSON.stringify(replay) == JSON.stringify(incident), "equivalent seed, state, and departure should reproduce the same incident result")
	var restored_incident_world := AshWorldState.new(0)
	var restored_incident_result := restored_incident_world.load_serialized(world.serialize())
	_expect(restored_incident_result.ok, "incident state should survive save/load")
	_expect(restored_incident_world.command_history.back().state_delta.loss_good_id == "medicine", "save/load should preserve the resolved loss basis in command history")
	_expect(int(restored_incident_world.command_history.back().state_delta.loss_unit_value) == 52, "save/load should preserve the exposed unit value")

	var safe_world := AshWorldState.new(1)
	safe_world.cargo = {"water": 2, "weight": 2}
	var safe_departure := MarketCommandProcessor.execute(safe_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(safe_departure.ok and float(safe_departure.state_delta.risk_roll) >= float(safe_departure.state_delta.risk), "seeded safe fixture should resolve without an incident")
	_expect(safe_departure.state_delta.loss_good_id == "water" and int(safe_departure.state_delta.expected_loss) == 11, "non-incident result should retain the disclosed forecast basis")
	_expect(int(safe_world.cargo.get("water", 0)) == 2, "non-incident departure should preserve exposed cargo")

	var empty_world := AshWorldState.new(3)
	var empty_departure := MarketCommandProcessor.execute(empty_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(empty_departure.ok and int(empty_departure.state_delta.expected_loss) == 0, "zero-cargo departure should remain legal with zero expected loss")
	_expect(String(empty_departure.state_delta.loss_good_id).is_empty(), "zero-cargo departure should record no exposed good")

func _test_command_buy_and_sell() -> void:
	var world := AshWorldState.new(1107)
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "water", "quantity": 2},
	})
	_expect(buy.ok, "buy command should succeed for affordable cargo")
	_expect(world.cargo.get("water", 0) == 2, "buy command should add the requested cargo")
	_expect(world.cargo.get("weight", 0) == 2, "buy command should update cargo weight")
	_expect(int(buy.state_delta.money) < 0, "buy command should report money spent")
	_expect(buy.message.find("Bought 2 water") >= 0, "buy command should return a player-facing message")
	var money_after_buy := world.money
	var sell := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 2},
	})
	_expect(sell.ok, "sell command should succeed when cargo is held")
	_expect(world.money > money_after_buy, "sell command should add current settlement value")
	_expect(world.cargo.get("water", 0) == 0, "sell command should remove sold cargo")
	_expect(world.cargo.get("weight", 0) == 0, "sell command should reduce cargo weight")

func _test_market_memory() -> void:
	var world := AshWorldState.new(1107)
	world.current_settlement = "reedwatch"
	world.cargo = {"water": 4, "weight": 4}
	var destination := world.settlement("reedwatch")
	var before_price := MarketEconomy.price_for("water", destination, world.pricing_context())
	var sale := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 4},
	})
	_expect(sale.ok, "market-memory fixture sale should succeed")
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.16), "four-unit stage-zero delivery should add 16% supply pressure")
	_expect(is_equal_approx(float(sale.state_delta.market_memory.effective_impact), 0.16), "sale result should expose the effective pressure change")
	_expect(sale.message.contains("softened this market's water price pressure by 16%"), "sale result should explain the market-memory effect")
	var after_details := MarketEconomy.price_details("water", destination, world.pricing_context())
	_expect(int(after_details.unit_price) < before_price, "a completed delivery should soften the next local sale price")
	_expect(is_equal_approx(float(after_details.market_memory_modifier), 0.84), "price details should expose the bounded memory multiplier")
	_expect(after_details.reasons.has("your recent deliveries increased local supply"), "price details should explain recent-delivery pressure")
	var latest := world.latest_market_delivery("reedwatch", "water")
	_expect(int(latest.quantity) == 4 and int(latest.day) == 1, "latest delivery should retain visible quantity and day inputs")

	var pressure_before_buy := world.market_pressure_for("reedwatch", "water")
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "water", "quantity": 1},
	})
	_expect(buy.ok, "buy should remain legal after a delivery changes local pressure")
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), pressure_before_buy), "buying must not change local supply pressure")

	world.advance_day(1)
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.115), "consumer demand should replenish delivered water faster than a neutral market")
	world.advance_day(20)
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.0), "market pressure should decay to but never below zero")

	var producer_world := AshWorldState.new(1107)
	producer_world.record_market_delivery("brine_cross", "water", 4)
	producer_world.advance_day(1)
	_expect(is_equal_approx(producer_world.market_pressure_for("brine_cross", "water"), 0.1375), "producer supply should absorb repeat deliveries more slowly than consumer demand")

	var failed_world := AshWorldState.new(1107)
	failed_world.current_settlement = "reedwatch"
	var failed_sale := MarketCommandProcessor.execute(failed_world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 1},
	})
	_expect(not failed_sale.ok, "sale without cargo should fail")
	_expect(failed_world.market_pressure.is_empty() and failed_world.market_delivery_history.is_empty(), "failed sale should not write market memory")
	_expect(not failed_world.record_market_delivery("missing", "water", 1).ok, "unknown settlements should not receive market pressure")
	_expect(not failed_world.record_market_delivery("reedwatch", "missing", 1).ok, "unknown goods should not receive market pressure")
	_expect(not failed_world.record_market_delivery("reedwatch", "water", 1, "invented_mode").ok, "market deliveries should reject unknown source modes")

	var saturated_world := AshWorldState.new(1107)
	saturated_world.current_settlement = "reedwatch"
	saturated_world.cargo_capacity = 20
	saturated_world.cargo = {"water": 12, "weight": 12}
	for _index in range(3):
		var saturated_sale := MarketCommandProcessor.execute(saturated_world, {
			"id": MarketCommandProcessor.SELL_GOODS,
			"inputs": {"good_id": "water", "quantity": 4},
		})
		_expect(saturated_sale.ok, "repeated legal sales should succeed through the command boundary")
	_expect(is_equal_approx(saturated_world.market_pressure_for("reedwatch", "water"), 0.35), "repeated deliveries should clamp at the authored pressure maximum")
	for _index in range(13):
		saturated_world.record_market_delivery("reedwatch", "grain", 1)
	_expect(saturated_world.market_delivery_history.size() == 12, "delivery history should remain bounded to the authored limit")

	var crisis_world := AshWorldState.new(1107)
	crisis_world.current_settlement = "reedwatch"
	crisis_world.crisis_stage = 2
	crisis_world._update_crisis_modifiers()
	crisis_world.cargo = {"water": 4, "weight": 4}
	var crisis_sale := MarketCommandProcessor.execute(crisis_world, {
		"id": MarketCommandProcessor.SELL_GOODS,
		"inputs": {"good_id": "water", "quantity": 4},
	})
	_expect(crisis_sale.ok, "crisis delivery should succeed")
	_expect(is_equal_approx(crisis_world.market_pressure_for("reedwatch", "water"), 0.112), "stage-two crisis should reduce delivery effectiveness without changing the pressure formula")

	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(crisis_world.serialize())
	_expect(restore_result.ok and is_equal_approx(restored.market_pressure_for("reedwatch", "water"), 0.112), "save/load should preserve market pressure")
	_expect(restored.latest_market_delivery("reedwatch", "water") == crisis_world.latest_market_delivery("reedwatch", "water"), "save/load should preserve visible delivery memory")

func _test_adaptive_relief_response() -> void:
	var ignored := AshWorldState.new(1107)
	_expect(String(ignored.scenario_state("reedwatch_water_relief").get("state", "")) == "offered", "water relief should begin as an optional offered scenario")
	ignored.advance_day(2)
	_expect(String(ignored.scenario_state("reedwatch_water_relief").get("state", "")) == "offered" and ignored.emergent_faction("well_commons").is_empty(), "ignoring relief before its response day should not apply a hidden penalty")
	ignored.advance_day(1)
	_expect(String(ignored.scenario_state("reedwatch_water_relief").get("state", "")) == "expired", "unaccepted relief should become an historical expired scenario on Day 4")
	_expect(not ignored.emergent_faction("well_commons").is_empty() and ignored.resilience_for("reedwatch") == 1, "expired relief should create the Well Commons and one bounded local resilience point")
	_expect(String(ignored.emergent_faction("well_commons").get("information_id", "")) == "well_commons_exchange_open" and ignored.adaptive_response_summary().contains("ordinary charcoal deliveries"), "the replacement response should expose a durable named trade opportunity")
	var ordinary_context := ignored.pricing_context()
	ordinary_context.erase("adaptive_market_modifiers")
	var adaptive_water := MarketEconomy.price_for("water", ignored.settlement("reedwatch"), ignored.pricing_context())
	var ordinary_water := MarketEconomy.price_for("water", ignored.settlement("reedwatch"), ordinary_context)
	var adaptive_charcoal := MarketEconomy.price_for("charcoal", ignored.settlement("reedwatch"), ignored.pricing_context())
	var ordinary_charcoal := MarketEconomy.price_for("charcoal", ignored.settlement("reedwatch"), ordinary_context)
	_expect(adaptive_water < ordinary_water and adaptive_charcoal > ordinary_charcoal, "Well Commons should stabilize water while opening a charcoal premium")
	_expect(MarketEconomy.price_details("charcoal", ignored.settlement("reedwatch"), ignored.pricing_context()).reasons.has("a local replacement exchange is increasing demand"), "adaptive prices should explain the replacement exchange")
	var blocked_reason := MarketCommandProcessor.contract_acceptance_reason(ignored, MarketContent.contract("reedwatch_water_relief_01"))
	_expect(blocked_reason.contains("offer closed on Day 4") and blocked_reason.contains("Well Commons"), "the stale relief offer should close with a causal replacement explanation")
	ignored.advance_day(2)
	_expect(ignored.resilience_for("reedwatch") == 1, "repeated scenario evaluation must not duplicate the replacement response")
	var adaptive_restored := AshWorldState.new(0)
	var adaptive_restored_result := adaptive_restored.load_serialized(ignored.serialize())
	_expect(adaptive_restored_result.ok and not adaptive_restored.emergent_faction("well_commons").is_empty() and adaptive_restored.resilience_for("reedwatch") == 1, "adaptive scenario and faction state should survive save/load without replaying effects")

	var completed := AshWorldState.new(1)
	MarketCommandProcessor.execute(completed, {"id": MarketCommandProcessor.ACCEPT_CONTRACT, "inputs": {"contract_id": "reedwatch_water_relief_01"}})
	MarketCommandProcessor.execute(completed, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "water", "quantity": 4}})
	MarketCommandProcessor.execute(completed, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}})
	completed.advance_day(2)
	_expect(String(completed.scenario_state("reedwatch_water_relief").get("state", "")) == "resolved" and completed.emergent_faction("well_commons").is_empty(), "completed relief should resolve the scenario without spawning its failure response")

	var failed := AshWorldState.new(1107)
	MarketCommandProcessor.execute(failed, {"id": MarketCommandProcessor.ACCEPT_CONTRACT, "inputs": {"contract_id": "reedwatch_water_relief_01"}})
	failed.advance_day(3)
	_expect(String(failed.scenario_state("reedwatch_water_relief").get("state", "")) == "delayed" and not failed.emergent_faction("well_commons").is_empty(), "overdue accepted relief should trigger the local response before formal resolution")
	MarketCommandProcessor.execute(failed, {"id": MarketCommandProcessor.RESOLVE_CONTRACT, "inputs": {"contract_id": "reedwatch_water_relief_01"}})
	_expect(String(failed.scenario_state("reedwatch_water_relief").get("state", "")) == "failed", "formal late resolution should preserve a distinct failed scenario state")

func _test_well_commons_interactions() -> void:
	var cooperative := AshWorldState.new(1107)
	cooperative.advance_day(3)
	cooperative.current_settlement = "reedwatch"
	var missing_fuel := MarketCommandProcessor.execute(cooperative, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	_expect(not missing_fuel.ok and missing_fuel.reason.contains("need 2 charcoal"), "Commons boiler support should require its disclosed ordinary-trade cargo")
	cooperative.cargo = {"charcoal": 2, "weight": 2}
	var fuel := MarketCommandProcessor.execute(cooperative, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	_expect(fuel.ok and int(cooperative.cargo.get("charcoal", 0)) == 0 and cooperative.resilience_for("reedwatch") == 2, "fueling Commons boilers should consume cargo and strengthen Reedwatch")
	_expect(int(cooperative.reputation.get("caravans", 0)) == 1 and int(cooperative.emergent_faction("well_commons").get("support", 0)) == 1, "boiler support should strengthen Free Caravan and Commons relationships")
	var ledger := MarketCommandProcessor.execute(cooperative, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_open_ledger"}})
	_expect(ledger.ok and cooperative.money == 112 and cooperative.day == 5 and is_equal_approx(float(cooperative.route("dry_cut").risk), 0.52), "publishing the Commons ledger should spend its disclosed resources and reveal safer Dry Cut stations")
	_expect(int(cooperative.emergent_faction("well_commons").get("support", 0)) == 2 and cooperative.known_information.has("commons_ledger_published"), "two cooperation paths should accumulate visible Commons support and information")

	var bypass := AshWorldState.new(1107)
	bypass.advance_day(3)
	bypass.current_settlement = "reedwatch"
	var permit := MarketCommandProcessor.execute(bypass, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_warden_cistern_bypass"}})
	_expect(permit.ok and bypass.money == 110 and int(bypass.reputation.get("wardens", 0)) == 1 and int(bypass.emergent_faction("well_commons").get("support", 0)) == -1, "the Warden permit should provide a disclosed opposition path without closing trade")
	bypass.reset_visit_slots()
	bypass.cargo = {"charcoal": 2, "weight": 2}
	var reconcile := MarketCommandProcessor.execute(bypass, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	_expect(reconcile.ok and int(bypass.emergent_faction("well_commons").get("support", 0)) == 0, "a later cooperation action should reverse prior Commons opposition")
	_expect(MarketEconomy.price_for("charcoal", bypass.settlement("reedwatch"), bypass.pricing_context()) > MarketEconomy.price_for("charcoal", bypass.settlement("ashgate"), bypass.pricing_context()), "the bypass path must preserve a viable ordinary charcoal market")

func _test_settlement_actions() -> void:
	var world := AshWorldState.new(1107)
	_expect(world.visit_slots_remaining == 2, "a fresh settlement visit should start with two action slots")
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "grain", "quantity": 1},
	})
	_expect(buy.ok and world.visit_slots_remaining == 2, "normal trade should not consume a visit slot")
	var money_before := world.money
	var provisions_before := world.provisions
	var first := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "ashgate_provision_bundle"},
	})
	_expect(first.ok, "the live Ashgate provision action should succeed")
	_expect(world.money == money_before - 6 and world.provisions == provisions_before + 4, "the provision action should apply its disclosed money and provision deltas")
	_expect(world.visit_slots_remaining == 1, "the first auxiliary action should consume one visit slot")
	_expect(world.reputation.wardens == 1, "packing Warden rations should apply its named standing gain")
	_expect(int(first.state_delta.visit_slots_remaining) == 1, "action result should expose remaining visit slots")
	var second := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "ashgate_provision_bundle"},
	})
	_expect(second.ok and world.visit_slots_remaining == 0, "a second auxiliary action should consume the final visit slot")
	var blocked_money := world.money
	var blocked_provisions := world.provisions
	var blocked := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "ashgate_provision_bundle"},
	})
	_expect(not blocked.ok and blocked.reason.contains("depart and arrive"), "a third auxiliary action should explain how visit slots recover")
	_expect(world.money == blocked_money and world.provisions == blocked_provisions and world.visit_slots_remaining == 0, "a blocked auxiliary action should not mutate resources or slots")
	_expect(not bool(world.command_history.back().ok), "a blocked auxiliary action should still be recorded")

	var saved_with_slot := AshWorldState.new(1107)
	MarketCommandProcessor.execute(saved_with_slot, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "ashgate_provision_bundle"},
	})
	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(saved_with_slot.serialize())
	_expect(restore_result.ok and restored.visit_slots_remaining == 1, "save/load should preserve the remaining visit budget")

	var arrival := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(arrival.ok and world.visit_slots_remaining == 2, "arriving at a settlement should reset the visit budget")
	_expect(int(arrival.state_delta.visit_slots_remaining) == 2, "departure result should expose the refreshed destination visit budget")
	var unavailable := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "reedwatch_supply_shelter"},
	})
	_expect(not unavailable.ok and unavailable.reason.contains("completed Reedwatch Water Relief"), "gated Reedwatch shelter should explain its contract and crisis requirements")
	var wrong_settlement := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "ashgate_provision_bundle"},
	})
	_expect(not wrong_settlement.ok and wrong_settlement.reason.contains("only available in Ashgate"), "settlement actions should be limited to their authored location")
	var poor_world := AshWorldState.new(1107)
	poor_world.money = 5
	var unaffordable := MarketCommandProcessor.execute(poor_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "ashgate_provision_bundle"},
	})
	_expect(not unaffordable.ok and poor_world.visit_slots_remaining == 2 and poor_world.provisions == 12, "an unaffordable opportunity should not mutate resources or visit slots")

	var brine_world := AshWorldState.new(1107)
	brine_world.current_settlement = "brine_cross"
	var early_cistern := MarketCommandProcessor.execute(brine_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "brine_cross_cistern_queue"},
	})
	_expect(not early_cistern.ok and early_cistern.reason.contains("crisis stage 1"), "Brine Cross cistern queue should explain its crisis-stage gate")
	_expect(brine_world.day == 1 and brine_world.visit_slots_remaining == 2 and brine_world.resilience_for("brine_cross") == 0, "blocked cistern work should not mutate time, slots, or resilience")
	brine_world.advance_day(3)
	var cistern := MarketCommandProcessor.execute(brine_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "brine_cross_cistern_queue"},
	})
	_expect(cistern.ok and brine_world.day == 5 and brine_world.visit_slots_remaining == 1, "shortage-stage cistern work should spend one day and one visit slot")
	_expect(brine_world.resilience_for("brine_cross") == 1 and brine_world.known_information.has("brine_pump_failures"), "cistern work should strengthen Brine Cross and preserve its pump-failure lead")
	var repeated_cistern := MarketCommandProcessor.execute(brine_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "brine_cross_cistern_queue"},
	})
	_expect(not repeated_cistern.ok and repeated_cistern.reason.contains("already complete"), "the one-time cistern investigation should not be farmable")

	var hollow_world := AshWorldState.new(1107)
	hollow_world.current_settlement = "hollow_market"
	var dry_cut_before := float(hollow_world.route("dry_cut").risk)
	var rumor := MarketCommandProcessor.execute(hollow_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "hollow_market_route_rumor"},
	})
	_expect(rumor.ok and hollow_world.money == 114 and hollow_world.visit_slots_remaining == 1, "Hollow Market rumor should spend six ashmarks and one visit slot")
	_expect(hollow_world.known_information.has("dry_cut_water_cache") and is_equal_approx(float(hollow_world.route("dry_cut").risk), dry_cut_before - 0.05), "Hollow Market rumor should preserve its lead and lower Dry Cut exposure")
	var repeated_rumor := MarketCommandProcessor.execute(hollow_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "hollow_market_route_rumor"},
	})
	_expect(not repeated_rumor.ok and repeated_rumor.reason.contains("already complete"), "the one-time Hollow Market rumor should not be farmable")

	var shelter_world := AshWorldState.new(1107)
	shelter_world.current_settlement = "reedwatch"
	shelter_world.advance_day(3)
	var blocked_shelter := MarketCommandProcessor.execute(shelter_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "reedwatch_supply_shelter"},
	})
	_expect(not blocked_shelter.ok and blocked_shelter.reason.contains("completed Reedwatch Water Relief"), "Reedwatch shelter should require the completed relief delivery")
	var shelter_success_world := AshWorldState.new(1107)
	shelter_success_world.current_settlement = "reedwatch"
	shelter_success_world.contract_history.append({"id": "reedwatch_water_relief_01", "status": "completed"})
	shelter_success_world.advance_day(3)
	var shelter := MarketCommandProcessor.execute(shelter_success_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "reedwatch_supply_shelter"},
	})
	_expect(shelter.ok and shelter_success_world.day == 5 and shelter_success_world.resilience_for("reedwatch") == 1, "Reedwatch shelter should spend a day and strengthen local resilience")
	_expect(int(shelter_success_world.reputation.get("caravans", 0)) == 1 and shelter_success_world.known_information.has("reedwatch_supply_shelter_open"), "Reedwatch shelter should grant its named Caravan standing and durable lead")

	var cinder_world := AshWorldState.new(1107)
	var cinder_departure := MarketCommandProcessor.execute(cinder_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "cinderford"},
	})
	_expect(cinder_departure.ok and cinder_world.current_settlement == "cinderford" and cinder_world.money == 114, "Cinderford should be reachable through the six-ashmark Toll Road segment")
	var repair := MarketCommandProcessor.execute(cinder_world, {
		"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION,
		"inputs": {"action_id": "cinderford_repair_bench"},
	})
	_expect(repair.ok and cinder_world.money == 100 and cinder_world.day == 3, "Cinderford repair bench should spend its disclosed money and day")
	_expect(cinder_world.known_information.has("cinderford_repair_ledger") and is_equal_approx(float(cinder_world.route("toll_road", "cinderford", "brine_cross").risk), 0.05), "Cinderford repair work should preserve its ledger and lower segment risk")
	var onward := MarketCommandProcessor.execute(cinder_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(onward.ok and cinder_world.current_settlement == "brine_cross" and int(onward.state_delta.money) == -6, "Cinderford should connect onward to Brine Cross with its segment cost")

func _test_reedwatch_relief_contract() -> void:
	var world := AshWorldState.new(1)
	var accept := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	_expect(accept.ok, "Reedwatch relief contract should be accepted at Ashgate")
	var snapshot := world.active_contract("reedwatch_water_relief_01")
	_expect(int(snapshot.accepted_day) == 1 and int(snapshot.deadline_day) == 3, "accepted contract should freeze its acceptance day and deadline")
	_expect(int(snapshot.quantity) == 4 and int(snapshot.reward) == 180, "accepted contract should snapshot quantity and rebalanced reward")
	_expect(world.visit_slots_remaining == 1 and int(world.cargo.get("water", 0)) == 0, "acceptance should consume one visit slot without creating cargo")
	var duplicate_accept := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	_expect(not duplicate_accept.ok, "an active contract should not be accepted twice")
	var buy := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "water", "quantity": 4},
	})
	_expect(buy.ok, "contract cargo should be bought through normal spot trade")
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(depart.ok and depart.message.contains("Completed Reedwatch Water Relief"), "eligible contract should complete automatically in the arrival result")
	_expect(world.active_contract("reedwatch_water_relief_01").is_empty(), "completed contract should leave the active set")
	_expect(world.contract_history.size() == 1 and world.contract_history.back().status == "completed", "completed contract should be archived once")
	_expect(world.command_history[-2].id == MarketCommandProcessor.RESOLVE_CONTRACT, "automatic arrival completion should be logged through the contract command boundary")
	_expect(int(world.cargo.get("water", 0)) == 0 and world.money == 236, "contract completion should consume four water and pay the frozen reward")
	_expect(is_equal_approx(world.market_pressure_for("reedwatch", "water"), 0.16), "contract delivery should update local market memory")
	_expect(int(world.reputation.get("caravans", 0)) == 1, "relief completion should apply its visible Free Caravan relationship effect")
	var duplicate_completion := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RESOLVE_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	_expect(not duplicate_completion.ok, "a completed contract should not resolve twice")

	var partial_world := AshWorldState.new(1)
	MarketCommandProcessor.execute(partial_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	MarketCommandProcessor.execute(partial_world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "water", "quantity": 3},
	})
	var partial_arrival := MarketCommandProcessor.execute(partial_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(partial_arrival.ok and partial_arrival.message.contains("acquire 1 more water"), "partial on-time delivery should stay active with a concrete recovery instruction")
	_expect(not partial_world.active_contract("reedwatch_water_relief_01").is_empty(), "partial delivery should not consume or fail the contract")

	var capacity_world := AshWorldState.new(1)
	capacity_world.cargo = {"grain": 9, "weight": 9}
	var capacity_block := MarketCommandProcessor.execute(capacity_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	_expect(not capacity_block.ok and capacity_block.reason.contains("4 free cargo space"), "contract acceptance should disclose insufficient cargo capacity")
	_expect(capacity_world.visit_slots_remaining == 2, "blocked contract acceptance should not consume a visit slot")

	var late_world := AshWorldState.new(1)
	MarketCommandProcessor.execute(late_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	late_world.cargo = {"water": 4, "weight": 4}
	late_world.advance_day(3)
	var late_money := late_world.money
	var late := MarketCommandProcessor.execute(late_world, {
		"id": MarketCommandProcessor.RESOLVE_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	_expect(late.ok and late.state_delta.status == "failed", "late contract resolution should produce one deterministic failure outcome")
	_expect(late_world.money == late_money - 8 and int(late_world.cargo.get("water", 0)) == 4, "late failure should charge the bounded penalty while preserving cargo for recovery trade")
	_expect(late_world.contract_history.back().status == "failed", "failed contract should be archived once")
	var duplicate_failure := MarketCommandProcessor.execute(late_world, {
		"id": MarketCommandProcessor.RESOLVE_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	_expect(not duplicate_failure.ok and late_world.contract_history.size() == 1, "a failed contract should not resolve or archive twice")

	var saved_world := AshWorldState.new(1)
	MarketCommandProcessor.execute(saved_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(saved_world.serialize())
	_expect(restore_result.ok and restored.active_contract("reedwatch_water_relief_01") == saved_world.active_contract("reedwatch_water_relief_01"), "save/load should preserve frozen active-contract terms")

func _test_brine_cross_medicine_escort_contract() -> void:
	var blocked_world := AshWorldState.new(1)
	var blocked := MarketCommandProcessor.execute(blocked_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "brine_cross_medicine_escort_01"},
	})
	_expect(not blocked.ok and blocked.reason.contains("requires 1 Ash Wardens standing"), "regulated escort should explain its Warden prerequisite")
	_expect(blocked_world.visit_slots_remaining == 2, "blocked faction prerequisite should preserve visit slots")

	var world := AshWorldState.new(1)
	world.adjust_reputation("wardens", 1)
	var accept := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "brine_cross_medicine_escort_01"},
	})
	_expect(accept.ok, "recognized caravan should accept the Brine Cross medicine escort")
	var snapshot := world.active_contract("brine_cross_medicine_escort_01")
	_expect(int(snapshot.deadline_day) == 3 and int(snapshot.get("success_reputation", {}).get("wardens", 0)) == 1, "regulated escort should freeze its deadline and relationship terms")
	_expect(MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "medicine", "quantity": 2}}).ok, "regulated escort cargo should use normal spot purchase")
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	if not world.pending_event.is_empty():
		depart = MarketCommandProcessor.execute(world, {
			"id": MarketCommandProcessor.RESOLVE_EVENT,
			"inputs": {"event_id": String(world.pending_event.get("id", "")), "choice_id": "pay_posted_toll"},
		})
	_expect(depart.ok and world.active_contract("brine_cross_medicine_escort_01").is_empty(), "on-time medicine escort should resolve through arrival")
	_expect(world.contract_history.back().status == "completed" and int(world.reputation.get("wardens", 0)) >= 2, "escort completion should archive once and cross the recognized-carrier threshold")
	_expect(int(world.cargo.get("medicine", 0)) == 0 and world.money >= 142, "escort completion should consume only committed medicine and leave a positive guaranteed margin")

	var late_world := AshWorldState.new(1)
	late_world.adjust_reputation("wardens", 1)
	MarketCommandProcessor.execute(late_world, {"id": MarketCommandProcessor.ACCEPT_CONTRACT, "inputs": {"contract_id": "brine_cross_medicine_escort_01"}})
	late_world.cargo = {"medicine": 2, "weight": 2}
	late_world.advance_day(3)
	var late := MarketCommandProcessor.execute(late_world, {"id": MarketCommandProcessor.RESOLVE_CONTRACT, "inputs": {"contract_id": "brine_cross_medicine_escort_01"}})
	_expect(late.ok and late.state_delta.status == "failed", "late regulated escort should resolve as a deterministic failure")
	_expect(int(late_world.reputation.get("wardens", 0)) == 0 and int(late_world.cargo.get("medicine", 0)) == 2, "escort failure should withdraw standing while preserving recovery cargo")

func _test_gatekeepers_chalk_event() -> void:
	var trigger_world := AshWorldState.new(1)
	var buy := MarketCommandProcessor.execute(trigger_world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "medicine", "quantity": 2},
	})
	_expect(buy.ok, "event trigger fixture should load valuable cargo")
	var depart := MarketCommandProcessor.execute(trigger_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(depart.ok and not trigger_world.pending_event.is_empty(), "eligible deterministic Toll Road trip should pause at Gatekeeper's Chalk")
	_expect(trigger_world.current_settlement == "ashgate", "pending event should keep the caravan at its origin until resolution")
	_expect(depart.state_delta.pending_event.id == "gatekeepers_chalk", "departure result should expose the pending event snapshot")
	_expect(int(trigger_world.money) == 40 and int(trigger_world.provisions) == 11 and trigger_world.day == 2, "base route costs should remain spent while the event is pending")
	var blocked_during_event_money := trigger_world.money
	var blocked_during_event := MarketCommandProcessor.execute(trigger_world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "grain", "quantity": 1},
	})
	_expect(not blocked_during_event.ok and trigger_world.money == blocked_during_event_money, "pending event should block unrelated commands without mutation")
	var pay := MarketCommandProcessor.execute(trigger_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "pay_posted_toll"},
	})
	_expect(pay.ok and trigger_world.current_settlement == "brine_cross", "paying the toll should complete arrival")
	_expect(trigger_world.money == 34 and trigger_world.visit_slots_remaining == 2, "pay choice should charge six ashmarks and refresh destination visit slots")
	_expect(trigger_world.pending_event.is_empty() and trigger_world.has_resolved_event("gatekeepers_chalk"), "resolved event should clear pending state and suppress repeats")
	_expect(trigger_world.event_history.size() == 1 and trigger_world.event_history.back().choice_id == "pay_posted_toll", "event history should record the chosen outcome once")
	var repeat := MarketCommandProcessor.execute(trigger_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "pay_posted_toll"},
	})
	_expect(not repeat.ok and trigger_world.event_history.size() == 1, "resolved events should reject duplicate resolution")
	trigger_world.cargo = {"medicine": 2, "weight": 2}
	var return_trip := MarketCommandProcessor.execute(trigger_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "ashgate"},
	})
	_expect(return_trip.ok and trigger_world.pending_event.is_empty(), "a resolved one-time event should not trigger again")

	var no_trigger_world := AshWorldState.new(2)
	no_trigger_world.cargo = {"medicine": 2, "weight": 2}
	var no_trigger := MarketCommandProcessor.execute(no_trigger_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(no_trigger.ok and no_trigger_world.pending_event.is_empty() and no_trigger_world.current_settlement == "brine_cross", "eligible no-trigger seed should complete normal arrival")
	var low_value_world := AshWorldState.new(1)
	low_value_world.cargo = {"grain": 1, "weight": 1}
	var low_value := MarketCommandProcessor.execute(low_value_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(low_value.ok and low_value_world.pending_event.is_empty(), "low-value cargo without a contract should not trigger the Toll Road event")
	var contract_relevant_world := AshWorldState.new(1)
	MarketCommandProcessor.execute(contract_relevant_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	var contract_relevant_departure := MarketCommandProcessor.execute(contract_relevant_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(contract_relevant_departure.ok and not contract_relevant_world.pending_event.is_empty(), "an active contract should make the Toll Road event relevant even without cargo")

	var low_money_world := AshWorldState.new(1)
	low_money_world.money = 12
	low_money_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(low_money_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	var blocked_pay := MarketCommandProcessor.execute(low_money_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "pay_posted_toll"},
	})
	_expect(not blocked_pay.ok and not low_money_world.pending_event.is_empty(), "unaffordable toll choice should remain blocked without clearing the event")
	var wait := MarketCommandProcessor.execute(low_money_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "wait_for_stamped_review"},
	})
	_expect(wait.ok and low_money_world.current_settlement == "brine_cross" and low_money_world.day == 3, "stamped review should remain an always-available recovery choice")

	var detour_world := AshWorldState.new(6)
	detour_world.money = 100
	detour_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(detour_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	var detour := MarketCommandProcessor.execute(detour_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "take_dust_detour"},
	})
	_expect(detour.ok and detour_world.day == 3 and detour_world.provisions == 10, "detour should consume one extra day and provision")
	_expect(int(detour_world.cargo.get("medicine", 0)) == 1, "detour loss seed should remove the disclosed exposed unit")
	var low_provision_world := AshWorldState.new(1)
	low_provision_world.money = 100
	low_provision_world.provisions = 1
	low_provision_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(low_provision_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	var blocked_detour := MarketCommandProcessor.execute(low_provision_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "take_dust_detour"},
	})
	_expect(not blocked_detour.ok and not low_provision_world.pending_event.is_empty(), "low provisions should block the detour while preserving the pending choice")

	var saved_pending := detour_world.event_history[0].duplicate(true)
	var pending_world := AshWorldState.new(1)
	pending_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(pending_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	var pending_save := pending_world.serialize()
	var restored_pending := AshWorldState.new(0)
	var pending_restore := restored_pending.load_serialized(pending_save)
	_expect(pending_restore.ok and restored_pending.pending_event == pending_world.pending_event, "mid-event save/load should preserve the full pending choice")
	var restored_wait := MarketCommandProcessor.execute(restored_pending, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "wait_for_stamped_review"},
	})
	_expect(restored_wait.ok and restored_pending.current_settlement == "brine_cross", "restored pending event should resolve to the saved destination")
	var replay_pending := AshWorldState.new(0)
	replay_pending.load_serialized(pending_save)
	var replay_wait := MarketCommandProcessor.execute(replay_pending, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "wait_for_stamped_review"},
	})
	_expect(JSON.stringify(replay_wait) == JSON.stringify(restored_wait), "same saved event and choice should reproduce the same result")
	_expect(saved_pending.choice_id == "take_dust_detour", "detour history fixture should preserve its selected choice")

func _test_span_at_cinderford_event() -> void:
	var premium_world := AshWorldState.new(3)
	premium_world.cargo = {"scrap": 2, "weight": 2}
	var premium_depart := MarketCommandProcessor.execute(premium_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(premium_depart.ok and premium_world.pending_event.get("id", "") == "span_at_cinderford", "repair material should trigger the deterministic Cinderford span event")
	_expect(int(premium_world.pending_event.get("material_basis", {}).get("quantity", 0)) == 2, "span event should freeze two disclosed repair-material units")
	var premium := MarketCommandProcessor.execute(premium_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "sell_materials_at_premium"},
	})
	_expect(premium.ok and premium_world.current_settlement == "reedwatch", "premium material sale should complete destination arrival")
	_expect(premium_world.money == 146 and int(premium_world.cargo.get("scrap", 0)) == 0, "premium material sale should remove two units and pay thirty ashmarks")
	_expect(premium_world.route_conditions.is_empty(), "private material sale should not improve the public route")

	var patch_world := AshWorldState.new(6)
	patch_world.cargo = {"scrap": 1, "charcoal": 1, "weight": 2}
	MarketCommandProcessor.execute(patch_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(int(patch_world.pending_event.material_basis.goods.get("scrap", 0)) == 1 and int(patch_world.pending_event.material_basis.goods.get("charcoal", 0)) == 1, "mixed repair cargo should freeze a stable scrap-then-charcoal basis")
	var patched := MarketCommandProcessor.execute(patch_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "reserve_materials_for_span"},
	})
	_expect(patched.ok and patch_world.day == 3, "public span reservation should cost one extra day")
	_expect(int(patch_world.cargo.get("scrap", 0)) == 0 and int(patch_world.cargo.get("charcoal", 0)) == 0, "public span reservation should consume the frozen mixed material basis")
	_expect(String(patch_world.route("old_road").get("condition", {}).get("id", "")) == "cinderford_span_patched", "public reservation should persist the patched-span route condition")
	_expect(is_equal_approx(float(patch_world.route("old_road").risk), 0.25), "patched span should lower later Old Road risk by ten percentage points")
	var restored_patch := AshWorldState.new(0)
	var restored_patch_result := restored_patch.load_serialized(patch_world.serialize())
	_expect(restored_patch_result.ok and is_equal_approx(float(restored_patch.route("old_road").risk), 0.25), "save/load should preserve the patched route forecast")
	patch_world.cargo = {"medicine": 1, "weight": 1}
	var patched_return := MarketCommandProcessor.execute(patch_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "ashgate"},
	})
	_expect(patched_return.ok and int(patch_world.cargo.get("medicine", 0)) == 1 and is_equal_approx(float(patched_return.state_delta.risk_roll), 0.26), "patched span should preserve cargo on a roll that the original 35% risk would lose")
	var unpatched_comparison := AshWorldState.new(6)
	unpatched_comparison.current_settlement = "reedwatch"
	unpatched_comparison.day = 3
	unpatched_comparison.resolved_event_ids.append("span_at_cinderford")
	unpatched_comparison.cargo = {"medicine": 1, "weight": 1}
	var unpatched_return := MarketCommandProcessor.execute(unpatched_comparison, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "ashgate"},
	})
	_expect(unpatched_return.ok and int(unpatched_comparison.cargo.get("medicine", 0)) == 0, "the same deterministic roll should lose cargo at the original Old Road risk")

	var message_world := AshWorldState.new(3)
	message_world.cargo = {"charcoal": 2, "weight": 2}
	message_world.provisions = 2
	MarketCommandProcessor.execute(message_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var message := MarketCommandProcessor.execute(message_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "carry_repair_message"},
	})
	_expect(message.ok and message_world.provisions == 0 and message_world.day == 3, "repair message should consume one extra provision and day after base travel")
	_expect(is_equal_approx(float(message_world.route("old_road").risk), 0.30), "surveyed span should lower later Old Road risk by five percentage points")

	var low_provision_world := AshWorldState.new(3)
	low_provision_world.cargo = {"scrap": 2, "weight": 2}
	low_provision_world.provisions = 1
	MarketCommandProcessor.execute(low_provision_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var blocked_message := MarketCommandProcessor.execute(low_provision_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "carry_repair_message"},
	})
	_expect(not blocked_message.ok and not low_provision_world.pending_event.is_empty(), "low provisions should block the repair message without clearing the event")
	low_provision_world.cargo = {"weight": 0}
	var blocked_materials := MarketCommandProcessor.execute(low_provision_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "reserve_materials_for_span"},
	})
	_expect(not blocked_materials.ok and not low_provision_world.pending_event.is_empty(), "missing frozen materials should block contribution without mutation")
	var turn_back := MarketCommandProcessor.execute(low_provision_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "turn_back_with_cargo"},
	})
	_expect(turn_back.ok and low_provision_world.current_settlement == "ashgate" and low_provision_world.day == 3, "turn-back recovery should return to the origin after one extra day")
	_expect(low_provision_world.has_resolved_event("span_at_cinderford"), "turn-back recovery should resolve the one-time event")
	var intact_turnback_world := AshWorldState.new(3)
	intact_turnback_world.cargo = {"scrap": 2, "weight": 2}
	MarketCommandProcessor.execute(intact_turnback_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	MarketCommandProcessor.execute(intact_turnback_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "turn_back_with_cargo"},
	})
	_expect(int(intact_turnback_world.cargo.get("scrap", 0)) == 2 and int(intact_turnback_world.cargo.get("weight", 0)) == 2, "turn-back recovery should preserve the full repair-material load")

	var ineligible_world := AshWorldState.new(3)
	ineligible_world.cargo = {"grain": 2, "weight": 2}
	var ineligible := MarketCommandProcessor.execute(ineligible_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(ineligible.ok and ineligible_world.pending_event.is_empty(), "cargo without repair materials should not trigger the span event")
	var no_trigger_world := AshWorldState.new(2)
	no_trigger_world.cargo = {"scrap": 2, "weight": 2}
	var no_trigger := MarketCommandProcessor.execute(no_trigger_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(no_trigger.ok and no_trigger_world.pending_event.is_empty() and no_trigger_world.current_settlement == "reedwatch", "eligible no-trigger seed should complete normal Old Road arrival")

	var replay_world := AshWorldState.new(3)
	replay_world.cargo = {"scrap": 2, "weight": 2}
	MarketCommandProcessor.execute(replay_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var pending_save := replay_world.serialize()
	var restored_replay := AshWorldState.new(0)
	restored_replay.load_serialized(pending_save)
	var restored_result := MarketCommandProcessor.execute(restored_replay, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "reserve_materials_for_span"},
	})
	var equivalent_replay := AshWorldState.new(0)
	equivalent_replay.load_serialized(pending_save)
	var equivalent_result := MarketCommandProcessor.execute(equivalent_replay, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "span_at_cinderford", "choice_id": "reserve_materials_for_span"},
	})
	_expect(JSON.stringify(restored_result) == JSON.stringify(equivalent_result), "saved span event and choice should replay deterministically")

func _test_last_clean_barrel_event() -> void:
	var peak_world := AshWorldState.new(4)
	peak_world.crisis_stage = 1
	peak_world._update_crisis_modifiers()
	peak_world.cargo = {"water": 2, "weight": 2}
	var peak_depart := MarketCommandProcessor.execute(peak_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(peak_depart.ok and peak_world.pending_event.get("id", "") == "last_clean_barrel", "shortage-stage water cargo should trigger The Last Clean Barrel")
	var frozen_trade_basis: Dictionary = peak_world.pending_event.get("trade_basis", {}).duplicate(true)
	_expect(int(frozen_trade_basis.get("quantity", 0)) == 2 and int(frozen_trade_basis.get("premium_per_unit", 0)) == 6, "barrel event should freeze its exact two-unit premium basis")
	var expected_payout := int(frozen_trade_basis.get("premium_total", 0))
	var peak := MarketCommandProcessor.execute(peak_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "sell_barrels_at_peak"},
	})
	_expect(peak.ok and peak_world.money == 116 + expected_payout, "emergency sale should pay the frozen destination price plus twelve ashmarks total premium")
	_expect(int(peak_world.cargo.get("water", 0)) == 0 and is_equal_approx(peak_world.market_pressure_for("reedwatch", "water"), 0.068), "emergency sale should remove two water and write crisis-adjusted delivery memory")

	var share_world := AshWorldState.new(4)
	share_world.crisis_stage = 1
	share_world._update_crisis_modifiers()
	share_world.cargo = {"water": 2, "weight": 2}
	MarketCommandProcessor.execute(share_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var share := MarketCommandProcessor.execute(share_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "share_barrels_fairly"},
	})
	_expect(share.ok and share_world.money == 116 and int(share_world.cargo.get("water", 0)) == 0, "fair distribution should consume water without granting hidden cash")
	_expect(share_world.resilience_for("reedwatch") == 2 and is_equal_approx(share_world.market_pressure_for("reedwatch", "water"), 0.068), "fair distribution should strengthen bounded resilience and soften local scarcity")
	_expect(share_world.reputation.caravans == 1, "fair distribution should apply its named Free Caravan standing gain")
	share_world.adjust_settlement_resilience("reedwatch", 20)
	_expect(share_world.resilience_for("reedwatch") == 10, "settlement resilience should clamp at ten")
	var restored_share := AshWorldState.new(0)
	var restored_share_result := restored_share.load_serialized(share_world.serialize())
	_expect(restored_share_result.ok and restored_share.resilience_for("reedwatch") == 10, "save/load should preserve bounded settlement resilience")

	var contract_world := AshWorldState.new(4)
	contract_world.crisis_stage = 1
	contract_world._update_crisis_modifiers()
	MarketCommandProcessor.execute(contract_world, {
		"id": MarketCommandProcessor.ACCEPT_CONTRACT,
		"inputs": {"contract_id": "reedwatch_water_relief_01"},
	})
	contract_world.cargo = {"water": 4, "weight": 4}
	MarketCommandProcessor.execute(contract_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var honor := MarketCommandProcessor.execute(contract_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "honor_relief_commitment"},
	})
	_expect(honor.ok and contract_world.contract_history.size() == 1 and contract_world.contract_history.back().status == "completed", "commitment choice should preserve cargo for normal arrival contract completion")
	_expect(int(contract_world.cargo.get("water", 0)) == 0 and contract_world.money == 296, "completed relief commitment should pay its frozen reward after base route cost")

	var no_contract_world := AshWorldState.new(4)
	no_contract_world.crisis_stage = 1
	no_contract_world._update_crisis_modifiers()
	no_contract_world.cargo = {"water": 2, "weight": 2}
	MarketCommandProcessor.execute(no_contract_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var blocked_contract := MarketCommandProcessor.execute(no_contract_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "honor_relief_commitment"},
	})
	_expect(not blocked_contract.ok and not no_contract_world.pending_event.is_empty(), "contract response should be blocked without a matching active commitment")
	no_contract_world.cargo = {"weight": 0}
	var blocked_sale := MarketCommandProcessor.execute(no_contract_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "sell_barrels_at_peak"},
	})
	_expect(not blocked_sale.ok and not no_contract_world.pending_event.is_empty(), "missing frozen water should block the emergency sale without clearing the event")
	no_contract_world.cargo = {"water": 2, "weight": 2}
	var sealed := MarketCommandProcessor.execute(no_contract_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "keep_barrels_sealed"},
	})
	_expect(sealed.ok and no_contract_world.current_settlement == "reedwatch" and int(no_contract_world.cargo.get("water", 0)) == 2, "sealed-cargo recovery should preserve water for ordinary spot trade")

	var wrong_stage_world := AshWorldState.new(4)
	wrong_stage_world.cargo = {"water": 2, "weight": 2}
	var wrong_stage := MarketCommandProcessor.execute(wrong_stage_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(wrong_stage.ok and wrong_stage_world.pending_event.is_empty(), "Last Clean Barrel should not trigger before the shortage starts")
	var no_trigger_world := AshWorldState.new(1)
	no_trigger_world.crisis_stage = 1
	no_trigger_world._update_crisis_modifiers()
	no_trigger_world.cargo = {"water": 2, "weight": 2}
	var no_trigger := MarketCommandProcessor.execute(no_trigger_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(no_trigger.ok and no_trigger_world.pending_event.is_empty(), "eligible no-trigger seed should complete normal arrival during the shortage")

	var replay_world := AshWorldState.new(4)
	replay_world.crisis_stage = 1
	replay_world._update_crisis_modifiers()
	replay_world.cargo = {"water": 2, "weight": 2}
	MarketCommandProcessor.execute(replay_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var pending_save := replay_world.serialize()
	var restored_replay := AshWorldState.new(0)
	restored_replay.load_serialized(pending_save)
	var restored_result := MarketCommandProcessor.execute(restored_replay, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "share_barrels_fairly"},
	})
	var equivalent_replay := AshWorldState.new(0)
	equivalent_replay.load_serialized(pending_save)
	var equivalent_result := MarketCommandProcessor.execute(equivalent_replay, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "share_barrels_fairly"},
	})
	_expect(JSON.stringify(restored_result) == JSON.stringify(equivalent_result), "saved barrel event and choice should replay deterministically")

func _test_three_riders_no_banner_event() -> void:
	var pay_world := AshWorldState.new(5)
	pay_world.cargo = {"medicine": 2, "weight": 2}
	var pay_depart := MarketCommandProcessor.execute(pay_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(pay_depart.ok and pay_world.pending_event.get("id", "") == "three_riders_no_banner", "high-value exposed cargo should trigger Three Riders, No Banner")
	_expect(pay_world.pending_event.loss_basis.get("loss_good_id", "") == "medicine", "escort event should freeze the disclosed exposed cargo unit")
	var pay := MarketCommandProcessor.execute(pay_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "pay_for_escort"},
	})
	_expect(pay.ok and pay_world.money == 106 and int(pay_world.cargo.get("medicine", 0)) == 2, "paid escort should charge ten ashmarks and preserve cargo")

	var low_money_world := AshWorldState.new(5)
	low_money_world.money = 4
	low_money_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(low_money_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var blocked_pay := MarketCommandProcessor.execute(low_money_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "pay_for_escort"},
	})
	_expect(not blocked_pay.ok and not low_money_world.pending_event.is_empty(), "unaffordable escort should remain blocked without clearing the event")

	var solo_world := AshWorldState.new(5)
	solo_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(solo_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var solo := MarketCommandProcessor.execute(solo_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "cross_without_escort"},
	})
	_expect(solo.ok and is_equal_approx(float(solo.state_delta.outcome.resolution_roll), 0.24), "solo crossing should use the frozen deterministic resolution roll")
	_expect(int(solo_world.cargo.get("medicine", 0)) == 1, "solo loss seed should remove exactly the disclosed medicine unit")
	var safe_solo_world := AshWorldState.new(3)
	safe_solo_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(safe_solo_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var safe_solo := MarketCommandProcessor.execute(safe_solo_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "cross_without_escort"},
	})
	_expect(safe_solo.ok and is_equal_approx(float(safe_solo.state_delta.outcome.resolution_roll), 0.62) and int(safe_solo_world.cargo.get("medicine", 0)) == 2, "solo safe seed should preserve cargo above the disclosed 45% risk")
	var repeated_solo := MarketCommandProcessor.execute(safe_solo_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "cross_without_escort"},
	})
	_expect(not repeated_solo.ok and safe_solo_world.event_history.size() == 1, "resolved escort should reject duplicate resolution")

	var medicine_world := AshWorldState.new(5)
	medicine_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(medicine_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var medicine_passage := MarketCommandProcessor.execute(medicine_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "trade_medicine_for_passage"},
	})
	_expect(medicine_passage.ok and int(medicine_world.cargo.get("medicine", 0)) == 1, "medicine passage should consume exactly one medicine and avoid the cargo roll")
	var missing_medicine_world := AshWorldState.new(5)
	missing_medicine_world.cargo = {"cloth": 4, "weight": 4}
	MarketCommandProcessor.execute(missing_medicine_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var blocked_medicine := MarketCommandProcessor.execute(missing_medicine_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "trade_medicine_for_passage"},
	})
	_expect(not blocked_medicine.ok and not missing_medicine_world.pending_event.is_empty(), "medicine passage should show a recoverable block when the good is absent")
	var wait := MarketCommandProcessor.execute(missing_medicine_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "wait_and_read_the_tracks"},
	})
	_expect(wait.ok and missing_medicine_world.day == 3 and missing_medicine_world.known_information.has("three_riders_sponsor_mark"), "wait recovery should cost one day and record the sponsor lead")
	_expect(missing_medicine_world.reputation.caravans == 1, "sharing the rider warning should grant one named Free Caravan standing point")
	_expect(not missing_medicine_world.record_information("three_riders_sponsor_mark") and missing_medicine_world.known_information.size() == 1, "known information should not duplicate")
	var restored_information := AshWorldState.new(0)
	var restored_information_result := restored_information.load_serialized(missing_medicine_world.serialize())
	_expect(restored_information_result.ok and restored_information.known_information.has("three_riders_sponsor_mark"), "save/load should preserve the rider sponsor lead")

	var low_value_world := AshWorldState.new(5)
	low_value_world.cargo = {"grain": 2, "weight": 2}
	var low_value := MarketCommandProcessor.execute(low_value_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(low_value.ok and low_value_world.pending_event.is_empty(), "low-value cargo should not trigger the suspicious escort")
	var wrong_route_world := AshWorldState.new(5)
	wrong_route_world.resolved_event_ids.append("gatekeepers_chalk")
	wrong_route_world.cargo = {"medicine": 2, "weight": 2}
	var wrong_route := MarketCommandProcessor.execute(wrong_route_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(wrong_route.ok and wrong_route_world.pending_event.is_empty(), "regulated Toll Road travel should not trigger the unmarked escort")
	var no_trigger_world := AshWorldState.new(1)
	no_trigger_world.cargo = {"medicine": 2, "weight": 2}
	var no_trigger := MarketCommandProcessor.execute(no_trigger_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(no_trigger.ok and no_trigger_world.pending_event.is_empty(), "eligible no-trigger seed should complete normal exposed-route arrival")

	var replay_world := AshWorldState.new(5)
	replay_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(replay_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	var pending_save := replay_world.serialize()
	var restored_replay := AshWorldState.new(0)
	restored_replay.load_serialized(pending_save)
	var restored_result := MarketCommandProcessor.execute(restored_replay, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "cross_without_escort"},
	})
	var equivalent_replay := AshWorldState.new(0)
	equivalent_replay.load_serialized(pending_save)
	var equivalent_result := MarketCommandProcessor.execute(equivalent_replay, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "three_riders_no_banner", "choice_id": "cross_without_escort"},
	})
	_expect(JSON.stringify(restored_result) == JSON.stringify(equivalent_result), "saved escort event and solo choice should replay deterministically")

func _test_nara_vey_crew() -> void:
	var world := AshWorldState.new(1)
	var baseline_risk := float(world.route("old_road").risk)
	_expect(world.route_intelligence("old_road").status == "unavailable", "route forecast should identify Nara as unavailable before recruitment")
	var blocked_assign := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": "nara_vey"},
	})
	_expect(not blocked_assign.ok and world.visit_slots_remaining == 2, "assigning unrecruited Nara should fail without consuming a visit slot")
	var poor_world := AshWorldState.new(1)
	poor_world.money = 19
	var blocked_recruit := MarketCommandProcessor.execute(poor_world, {
		"id": MarketCommandProcessor.RECRUIT_CREW,
		"inputs": {"crew_id": "nara_vey"},
	})
	_expect(not blocked_recruit.ok and poor_world.money == 19 and poor_world.visit_slots_remaining == 2, "Nara's recruitment cost should block cleanly when unaffordable")
	var recruit := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RECRUIT_CREW,
		"inputs": {"crew_id": "nara_vey"},
	})
	_expect(recruit.ok and world.is_crew_recruited("nara_vey") and world.money == 100 and world.visit_slots_remaining == 1, "recruiting Nara should charge twenty ashmarks and one visit slot")
	_expect(world.route_intelligence("old_road").status == "stale", "recruited but unassigned Nara should show a stale route report")
	var assign := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": "nara_vey"},
	})
	_expect(assign.ok and world.assigned_crew == "nara_vey" and world.visit_slots_remaining == 0, "assigning Nara should consume the remaining visit slot")
	var informed := world.route_intelligence("old_road")
	_expect(informed.status == "scout_informed" and String(informed.detail).contains("unmarked riders"), "same-day Nara assignment should expose the authored Old Road warning")
	_expect(is_equal_approx(float(world.route("old_road").risk), baseline_risk), "Nara's information should not silently guarantee or alter route safety")
	world.advance_day(1)
	_expect(world.route_intelligence("old_road").status == "stale", "Nara's report should become stale after the day advances")
	var restored := AshWorldState.new(0)
	var restored_result := restored.load_serialized(world.serialize())
	_expect(restored_result.ok and restored.is_crew_recruited("nara_vey") and restored.assigned_crew == "nara_vey", "save/load should preserve Nara's recruited and assigned state")
	_expect(restored.route_intelligence("old_road").status == "stale", "save/load should preserve the age of Nara's report")
	var cinderford_scout_world := AshWorldState.new(1)
	cinderford_scout_world.recruited_crew.append("nara_vey")
	cinderford_scout_world.current_settlement = "cinderford"
	var cinderford_assignment := MarketCommandProcessor.execute(cinderford_scout_world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": "nara_vey"},
	})
	_expect(cinderford_assignment.ok and cinderford_scout_world.visit_slots_remaining == 1 and cinderford_scout_world.route_intelligence("toll_road").status == "scout_informed", "reachable Cinderford should support a Toll Road scout assignment")
	_expect(world.route_intelligence("missing").status == "unavailable", "route intelligence should handle a missing route safely")

func _test_jorun_pale_crew() -> void:
	var world := AshWorldState.new(1)
	var recruit := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RECRUIT_CREW,
		"inputs": {"crew_id": "jorun_pale"},
	})
	_expect(recruit.ok and world.money == 102 and world.visit_slots_remaining == 1, "recruiting Jorun should charge eighteen ashmarks and one visit slot")
	var move_to_reedwatch := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(move_to_reedwatch.ok and world.current_settlement == "reedwatch" and world.visit_slots_remaining == 2, "Jorun fixture should reach Reedwatch with a refreshed visit budget")
	_expect(world.route_provision_cost("dry_cut") == 2, "unassigned Jorun should not change Dry Cut provisions")
	var assign := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": "jorun_pale"},
	})
	_expect(assign.ok and world.route_intelligence("dry_cut").status == "logistics_informed", "same-day Jorun assignment should produce a logistics-informed Dry Cut plan")
	_expect(world.route_provision_cost("dry_cut") == 1, "Jorun should reduce a two-provision route by one without reaching zero")
	_expect(world.route_provision_cost("old_road") == 1, "Jorun should never reduce a route below one provision")
	var provisions_before := world.provisions
	var dry_cut := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "dry_cut", "destination_id": "hollow_market"},
	})
	_expect(dry_cut.ok and int(dry_cut.state_delta.provisions) == -1 and world.provisions == provisions_before - 1, "Jorun's forecasted provision saving should match travel resolution")
	_expect(world.day == 4 and world.route_intelligence("dry_cut").status == "stale", "Jorun should save provisions without shortening travel time, and the report should then become stale")

func _test_tess_oryn_crew() -> void:
	var unavailable_world := AshWorldState.new(1)
	unavailable_world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(unavailable_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	var blocked_challenge := MarketCommandProcessor.execute(unavailable_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "challenge_chalk_ledger"},
	})
	_expect(not blocked_challenge.ok and unavailable_world.reputation.wardens == 0 and unavailable_world.known_information.is_empty(), "Tess's negotiation option should block without assignment and preserve state")

	var world := AshWorldState.new(1)
	var recruit := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RECRUIT_CREW,
		"inputs": {"crew_id": "tess_oryn"},
	})
	var assign := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.ASSIGN_CREW,
		"inputs": {"crew_id": "tess_oryn"},
	})
	_expect(recruit.ok and assign.ok and world.money == 98 and world.visit_slots_remaining == 0, "Tess recruitment and assignment should consume their stated money and slots")
	world.cargo = {"medicine": 2, "weight": 2}
	MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	var challenge := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "gatekeepers_chalk", "choice_id": "challenge_chalk_ledger"},
	})
	_expect(challenge.ok and world.current_settlement == "brine_cross" and world.day == 3, "Tess should turn the ledger challenge into a safe one-day arrival")
	_expect(world.reputation.wardens == -1 and world.known_information.has("gatekeeper_invented_tolls"), "Tess's named negotiation should record both its Warden cost and information result")
	_expect(world.assigned_crew == "tess_oryn" and world.route_intelligence("toll_road").status == "stale", "travel should retain Tess's assignment while aging her route note")

func _test_warden_relationship_threshold() -> void:
	var world := AshWorldState.new(1)
	_expect(world.faction_status("wardens").tier == "Unregistered" and int(world.route("toll_road").cost) == 12, "below-threshold Warden standing should retain the full Toll Road fee")
	world.adjust_reputation("wardens", 2)
	var trusted := world.faction_status("wardens")
	_expect(trusted.tier == "Recognized carrier" and int(trusted.next_threshold) == 2, "threshold status should expose the recognized tier and cutoff")
	_expect(int(world.route("toll_road").cost) == 9 and String(world.route("toll_road").faction_effect).contains("3 fewer"), "recognized Warden standing should apply and explain the three-ashmark Toll Road discount")
	world.money = 20
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "toll_road", "destination_id": "brine_cross"},
	})
	_expect(depart.ok and world.money == 11 and int(depart.state_delta.money) == -9, "discounted Toll Road forecast and travel resolution should charge the same fee")
	world.adjust_reputation("wardens", 100)
	_expect(world.reputation.wardens == 10 and int(world.route("toll_road").cost) == 9, "above-threshold standing should clamp and retain the bounded discount")
	world.adjust_reputation("wardens", -100)
	_expect(world.reputation.wardens == -10 and int(world.route("toll_road").cost) == 12, "low standing should clamp and remove the permit discount")
	var caravan_world := AshWorldState.new(1)
	_expect(caravan_world.faction_status("caravans").tier == "Unknown trader" and int(caravan_world.route("old_road").cost) == 4, "below-threshold Caravan standing should retain the full Old Road fee")
	caravan_world.adjust_reputation("caravans", 2)
	_expect(caravan_world.faction_status("caravans").tier == "Known road-sharer" and int(caravan_world.route("old_road").cost) == 2, "Free Caravan threshold should discount only the Old Road by two ashmarks")
	_expect(int(caravan_world.route("toll_road").cost) == 12 and is_equal_approx(float(caravan_world.route("old_road").risk), 0.35), "Free Caravan standing should not alter Warden fees or exposed-route risk")

func _test_arms_trade_proof() -> void:
	var blocked_world := AshWorldState.new(1)
	var blocked := MarketCommandProcessor.execute(blocked_world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "ashgate_cinder_rider_arms_sale"}})
	_expect(not blocked.ok and blocked_world.arms_escalation == 0 and blocked_world.visit_slots_remaining == 2, "arms offer should block without cargo and preserve all state")
	var world := AshWorldState.new(1)
	var buy := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "sealed_arms_crate", "quantity": 1}})
	_expect(buy.ok and int(world.cargo.get("sealed_arms_crate", 0)) == 1, "the single arms good should use the normal cargo purchase boundary")
	var sale := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "ashgate_cinder_rider_arms_sale"}})
	_expect(sale.ok and world.money == 157 and int(world.cargo.get("sealed_arms_crate", 0)) == 0, "named arms sale should remove one crate and pay eighty-two ashmarks")
	_expect(world.arms_escalation == 2 and world.reputation.wardens == -1 and world.reputation.caravans == -1, "arms sale should expose and apply its bounded escalation and faction costs")
	_expect(sale.message.contains("Reedwatch Water Relief"), "arms result should name the viable non-arms alternative")
	var recovery := MarketCommandProcessor.execute(world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "ashgate_public_manifest_audit"}})
	_expect(recovery.ok and world.arms_escalation == 1 and world.money == 145 and world.day == 2, "public manifest audit should spend its stated resources and lower escalation by one")
	_expect(world.known_information.has("public_manifest_audit") and world.arms_trade_history.size() == 2, "arms recovery should record its public information and named history")
	var quiet_world := AshWorldState.new(1)
	var unnecessary := MarketCommandProcessor.execute(quiet_world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "ashgate_public_manifest_audit"}})
	_expect(not unnecessary.ok and quiet_world.money == 120 and quiet_world.visit_slots_remaining == 2, "unnecessary de-escalation should block without mutation")
	var inspected := AshWorldState.new(1)
	inspected.arms_escalation = 2
	inspected.cargo = {"sealed_arms_crate": 1, "weight": 2}
	_expect(int(inspected.route("toll_road").cost) == 17 and String(inspected.route("toll_road").arms_effect).contains("+5"), "noticed arms traffic should disclose the Toll Road inspection surcharge")
	inspected.adjust_reputation("wardens", 2)
	_expect(int(inspected.route("toll_road").cost) == 14, "Warden permit discount and arms inspection surcharge should compose deterministically")
	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(world.serialize())
	_expect(restore_result.ok and restored.arms_escalation == 1 and restored.arms_trade_history.size() == 2, "save/load should preserve arms escalation and its named sale/recovery history")

func _test_crisis_progression_and_ending() -> void:
	var progression := AshWorldState.new(1)
	_expect(MarketContent.crisis_stage(0).get("label", "") == "Ordinary pressure", "crisis content should expose the opening stage")
	progression.advance_day(3)
	_expect(progression.day == 4 and progression.crisis_stage == 1, "day four should enter Thin wells")
	_expect(is_equal_approx(float(progression.route("old_road").risk), 0.40), "Thin wells should visibly raise Old Road exposure by five points")
	progression.advance_day(3)
	_expect(progression.day == 7 and progression.crisis_stage == 2, "day seven should enter Empty reservoir")
	_expect(is_equal_approx(float(progression.route("old_road").risk), 0.45) and int(progression.route("toll_road").cost) == 14, "Empty reservoir should alter both exposed and regulated route tradeoffs")
	progression.advance_day(3)
	_expect(progression.day == 10 and progression.crisis_stage == 3 and progression.ending_id.is_empty(), "day ten should enter Settlement decision without granting an unearned ending")
	_expect(is_equal_approx(float(progression.route("old_road").risk), 0.50) and int(progression.route("toll_road").cost) == 16, "Settlement decision should expose the authored peak route pressure")
	var composition_world := AshWorldState.new(1)
	composition_world.advance_day(6)
	composition_world.set_route_condition("old_road", {"id": "test_patch", "risk_delta": -0.10, "cost_delta": 0, "description": "Test repair."})
	composition_world.adjust_reputation("wardens", 2)
	composition_world.arms_escalation = 2
	composition_world.cargo = {"sealed_arms_crate": 1, "weight": 2}
	_expect(is_equal_approx(float(composition_world.route("old_road").risk), 0.35), "authored repairs and crisis exposure should compose on the same route")
	_expect(int(composition_world.route("toll_road").cost) == 16, "crisis toll, Warden discount, and arms inspection surcharge should compose deterministically")
	var ending_world := AshWorldState.new(1)
	ending_world.contract_history.append({"id": "reedwatch_water_relief_01", "status": "completed"})
	ending_world.settlement_resilience["reedwatch"] = 2
	ending_world.arms_escalation = 1
	ending_world.advance_day(9)
	_expect(ending_world.crisis_stage == 3 and ending_world.ending_id == "open_routes_relief", "qualified day-ten state should reach the deterministic relief ending")
	_expect(ending_world.ending_summary.contains("public reserve holds"), "ending should preserve its authored regional summary")
	var commons_world := AshWorldState.new(1107)
	commons_world.advance_day(3)
	commons_world.resolved_event_ids = ["span_at_cinderford", "three_riders_no_banner"]
	_expect(MarketCommandProcessor.execute(commons_world, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "charcoal", "quantity": 6}}).ok, "Commons ending fixture should buy ordinary charcoal after the failed offer")
	_expect(MarketCommandProcessor.execute(commons_world, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}}).ok and commons_world.pending_event.is_empty(), "Commons ending fixture should reach Reedwatch through normal travel")
	_expect(MarketCommandProcessor.execute(commons_world, {"id": MarketCommandProcessor.SELL_GOODS, "inputs": {"good_id": "charcoal", "quantity": 4}}).ok, "Commons ending fixture should record a normal market delivery")
	_expect(MarketCommandProcessor.execute(commons_world, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}}).ok, "Commons ending fixture should turn the remaining cargo into local support")
	for index in range(12):
		commons_world.record_market_delivery("ashgate", "grain", 1)
	_expect(commons_world.latest_market_delivery("reedwatch", "charcoal").is_empty() and int(commons_world.emergent_faction("well_commons").get("ordinary_deliveries", {}).get("charcoal", 0)) == 4, "Commons delivery credit should survive eviction from the bounded market log")
	var restored_commons := AshWorldState.new(0)
	_expect(restored_commons.load_serialized(commons_world.serialize()).ok and int(restored_commons.emergent_faction("well_commons").get("ordinary_deliveries", {}).get("charcoal", 0)) == 4, "save/load should preserve durable Commons ordinary-delivery credit")
	restored_commons.advance_day(10 - restored_commons.day)
	_expect(restored_commons.ending_id == "ending_commons_exchange" and restored_commons.ending_summary.contains("ordinary charcoal runs"), "failed relief followed by ordinary trade and Commons support should reach the replacement ending")
	var premature_commons := AshWorldState.new(1107)
	premature_commons.record_market_delivery("reedwatch", "charcoal", 4)
	premature_commons.advance_day(3)
	premature_commons.current_settlement = "reedwatch"
	premature_commons.cargo = {"charcoal": 2, "weight": 2}
	MarketCommandProcessor.execute(premature_commons, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	premature_commons.advance_day(10 - premature_commons.day)
	_expect(premature_commons.ending_id != "ending_commons_exchange", "charcoal delivered before Commons activation must not satisfy the alternate ending")
	var contract_transfer_commons := AshWorldState.new(1107)
	contract_transfer_commons.advance_day(3)
	contract_transfer_commons.record_market_delivery("reedwatch", "charcoal", 4, "contract")
	contract_transfer_commons.current_settlement = "reedwatch"
	contract_transfer_commons.cargo = {"charcoal": 2, "weight": 2}
	MarketCommandProcessor.execute(contract_transfer_commons, {"id": MarketCommandProcessor.USE_SETTLEMENT_ACTION, "inputs": {"action_id": "reedwatch_commons_boiler_fuel"}})
	contract_transfer_commons.advance_day(10 - contract_transfer_commons.day)
	_expect(contract_transfer_commons.ending_id != "ending_commons_exchange", "contract or event transfers must not count as ordinary trade for the Commons ending")
	var warden_world := AshWorldState.new(1)
	warden_world.adjust_reputation("wardens", 3)
	warden_world.advance_day(9)
	_expect(warden_world.ending_id == "ending_warden_reserve", "a high-Warden low-Caravan state should reach the regulated reserve ending")
	_expect(warden_world.ending_summary.contains("regulated margins"), "Warden ending should explain its supply, access, escalation, and trade-style result")
	var priority_world := AshWorldState.new(1)
	priority_world.contract_history.append({"id": "reedwatch_water_relief_01", "status": "completed"})
	priority_world.settlement_resilience["reedwatch"] = 2
	priority_world.adjust_reputation("wardens", 3)
	priority_world.advance_day(9)
	_expect(priority_world.ending_id == "open_routes_relief", "the ordered ending rules should prefer completed shared relief when multiple predicates match")
	var caravan_world := AshWorldState.new(1)
	caravan_world.adjust_reputation("caravans", 2)
	caravan_world.advance_day(9)
	_expect(caravan_world.ending_id == "ending_free_caravan_routes", "a high-Caravan low-Warden state should reach the open-road ending")
	_expect(caravan_world.ending_summary.contains("public information"), "Free Caravan ending should explain its supply, access, escalation, and trade-style result")
	var merchant_world := AshWorldState.new(1)
	merchant_world.money = 220
	merchant_world.advance_day(9)
	_expect(merchant_world.ending_id == "ending_ash_merchant", "a wealthy low-resilience state should reach the profit-first ending")
	_expect(merchant_world.ending_summary.contains("concentrated profit"), "merchant ending should explain its supply, access, escalation, and trade-style result")
	var decision_world := AshWorldState.new(3)
	decision_world.day = 9
	decision_world.money = 220
	decision_world.cargo = {"water": 2, "weight": 2}
	decision_world.reputation["caravans"] = 1
	decision_world.resolved_event_ids.append("three_riders_no_banner")
	var decision_departure := MarketCommandProcessor.execute(decision_world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(decision_departure.ok and decision_world.pending_event.get("id", "") == "last_clean_barrel", "day-ten decision fixture should pause at the final public-water choice")
	_expect(decision_world.ending_id.is_empty(), "crossing the ending day during travel should not lock an outcome before the pending decision")
	var decision_resolution := MarketCommandProcessor.execute(decision_world, {
		"id": MarketCommandProcessor.RESOLVE_EVENT,
		"inputs": {"event_id": "last_clean_barrel", "choice_id": "share_barrels_fairly"},
	})
	_expect(decision_resolution.ok and decision_world.ending_id == "ending_free_caravan_routes", "the final route decision should determine the eligible ending before it is recorded")
	var restored := AshWorldState.new(0)
	var restore_result := restored.load_serialized(ending_world.serialize())
	_expect(restore_result.ok and restored.ending_id == ending_world.ending_id and restored.ending_summary == ending_world.ending_summary, "save/load should preserve the reached ending")

func _test_command_validation_and_history() -> void:
	var world := AshWorldState.new(1107)
	var money_before := world.money
	var invalid := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "unknown", "quantity": 1},
	})
	_expect(not invalid.ok, "buy command should reject unknown goods")
	_expect(world.money == money_before, "rejected command should not mutate money")
	_expect(world.command_history.size() == 1, "command history should record rejected commands")
	_expect(not bool(world.command_history[0].ok), "rejected command history should preserve failure state")
	var unknown := MarketCommandProcessor.execute(world, {"id": "invent_profit", "inputs": {}})
	_expect(not unknown.ok, "processor should reject unsupported commands")
	_expect(world.command_history.size() == 2, "unsupported commands should also be recorded")

func _test_depart_command() -> void:
	var world := AshWorldState.new(1107)
	var money_before := world.money
	var provisions_before := world.provisions
	var blocked := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "brine_cross"},
	})
	_expect(not blocked.ok, "depart command should reject a destination outside the authored route endpoints")
	_expect(blocked.reason.find("does not connect") >= 0, "blocked departure should explain the route-endpoint mismatch")
	_expect(world.current_settlement == "ashgate", "blocked departure should not move the caravan")
	_expect(world.money == money_before, "blocked departure should not charge the route cost")
	_expect(world.provisions == provisions_before, "blocked departure should not consume provisions")
	_expect(world.command_history.size() == 1 and not world.command_history.back().ok, "blocked departure should be recorded as a failed command")
	var depart := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.DEPART_ROUTE,
		"inputs": {"route_id": "old_road", "destination_id": "reedwatch"},
	})
	_expect(depart.ok, "depart command should allow an authored route endpoint")
	_expect(world.current_settlement == "reedwatch", "depart command should move the caravan to the connected endpoint")
	_expect(world.money == money_before - 4, "depart command should charge the route cost")
	_expect(world.provisions == provisions_before - 1, "depart command should consume route provisions")
	_expect(depart.state_delta.get("route_id", "") == "old_road", "depart command should identify the resolved route")
	_expect(world.command_history.back().id == MarketCommandProcessor.DEPART_ROUTE, "departure should be recorded with a stable command id")

func _test_travel_consumes_resources() -> void:
	var world := AshWorldState.new(1107)
	var money_before := world.money
	var provisions_before := world.provisions
	var result := world.travel("old_road")
	_expect(result.ok, "old road travel should succeed from the starting state")
	_expect(world.money == money_before - 4, "travel should charge route cost")
	_expect(world.provisions == provisions_before - 1, "travel should consume route provisions")

func _test_save_round_trip() -> void:
	var world := AshWorldState.new(42)
	world.money = 77
	world.crisis_stage = 2
	world._update_crisis_modifiers()
	var command := MarketCommandProcessor.execute(world, {
		"id": MarketCommandProcessor.BUY_GOODS,
		"inputs": {"good_id": "grain", "quantity": 1},
	})
	_expect(command.ok, "save fixture purchase should succeed")
	world.money = 77
	var restored := AshWorldState.new(0)
	var restored_result := restored.load_serialized(world.serialize())
	_expect(restored_result.ok, "current-version save should load")
	_expect(restored.seed == 42, "save should preserve seed")
	_expect(restored.money == 77, "save should preserve money")
	_expect(restored.crisis_stage == 2, "save should preserve crisis stage")
	_expect(restored.command_history.size() == 1, "save should preserve command history")
	_expect(restored.serialize().save_version == AshWorldState.SAVE_VERSION, "serialized state should declare the current save version")
	_expect(restored.serialize().content_version == "1.28.0", "serialized state should declare the content version")
	var oversized_history_save := AshWorldState.new(43).serialize()
	for index in range(105):
		oversized_history_save.command_history.append({"id": "test_%d" % index, "inputs": {}, "day": 1, "ok": true, "message": "", "state_delta": {}})
	var bounded_history_world := AshWorldState.new(0)
	var bounded_history_result := bounded_history_world.load_serialized(oversized_history_save)
	_expect(bounded_history_result.ok, "a structurally valid save with excess command history should load")
	_expect(bounded_history_world.command_history.size() == AshWorldState.MAX_COMMAND_HISTORY, "load should restore no more than the runtime command-history bound")
	_expect(bounded_history_world.command_history.front().id == "test_5" and bounded_history_world.command_history.back().id == "test_104", "load should retain the newest bounded command-history records")
	var bounded_log_source := AshWorldState.new(44)
	for index in range(205):
		bounded_log_source.add_log("entry_%d" % index)
	_expect(bounded_log_source.log.size() == AshWorldState.MAX_LOG_ENTRIES and bounded_log_source.log.front() == "entry_5", "runtime campaign logs should retain only their newest bounded entries")
	var oversized_log_save := AshWorldState.new(45).serialize()
	for index in range(205):
		oversized_log_save.log.append("saved_entry_%d" % index)
	var bounded_log_world := AshWorldState.new(0)
	var bounded_log_result := bounded_log_world.load_serialized(oversized_log_save)
	_expect(bounded_log_result.ok and bounded_log_world.log.size() == AshWorldState.MAX_LOG_ENTRIES, "load should restore no more than the campaign-log bound")
	_expect(bounded_log_world.log.front() == "saved_entry_5" and bounded_log_world.log.back() == "saved_entry_204", "load should retain the newest bounded campaign-log entries")

func _test_disk_save_sanitization() -> void:
	var source := AshWorldState.new(42)
	var disk_data: Variant = JSON.parse_string(JSON.stringify(source.serialize()))
	_expect(typeof(disk_data) == TYPE_DICTIONARY, "serialized campaign should parse back into a save object")
	if typeof(disk_data) != TYPE_DICTIONARY:
		return
	disk_data["cargo"] = {"water": 99.0, "unknown_good": 4.0, "weight": -12.0}
	disk_data["reputation"] = {"wardens": 999.0, "caravans": -999.0, "unknown_faction": 7.0}
	var restored := AshWorldState.new(0)
	var result := restored.load_serialized(disk_data)
	_expect(result.ok, "disk-parsed numeric values should load through normalization")
	_expect(int(restored.cargo.get("water", 0)) == 12 and int(restored.cargo.get("weight", 0)) == 12, "loaded cargo should be recomputed and bounded by hold capacity")
	_expect(not restored.cargo.has("unknown_good"), "loaded cargo should discard unknown good IDs")
	_expect(int(restored.reputation.get("wardens", 0)) == 10 and int(restored.reputation.get("caravans", 0)) == -10, "loaded reputation should clamp to authored faction bounds")
	_expect(not restored.reputation.has("unknown_faction"), "loaded reputation should discard unknown faction IDs")
	var invalid_shape: Dictionary = source.serialize()
	invalid_shape["command_history"] = "not-a-list"
	var rejected_shape := AshWorldState.new(0).load_serialized(invalid_shape)
	_expect(not rejected_shape.ok and rejected_shape.reason.contains("command_history must be a list"), "load should reject structurally invalid JSON before typed restoration")
	var invalid_bounds: Dictionary = source.serialize()
	invalid_bounds["day"] = -4
	var rejected_bounds := AshWorldState.new(0).load_serialized(invalid_bounds)
	_expect(not rejected_bounds.ok and rejected_bounds.reason.contains("day must be at least 1"), "load should reject impossible campaign bounds")
	var invalid_reference: Dictionary = source.serialize()
	invalid_reference["current_settlement"] = "missing_town"
	var rejected_reference := AshWorldState.new(0).load_serialized(invalid_reference)
	_expect(not rejected_reference.ok and rejected_reference.reason.contains("unknown current settlement"), "load should reject unknown authoritative references")
	var invalid_contract: Dictionary = source.serialize()
	invalid_contract["active_contracts"] = {"invented_contract": {"id": "invented_contract", "status": "active"}}
	var rejected_contract := AshWorldState.new(0).load_serialized(invalid_contract)
	_expect(not rejected_contract.ok and rejected_contract.reason.contains("invalid active contract"), "load should reject unknown active-contract references")
	var accepted_contract_world := AshWorldState.new(1107)
	_expect(MarketCommandProcessor.execute(accepted_contract_world, {"id": MarketCommandProcessor.ACCEPT_CONTRACT, "inputs": {"contract_id": "reedwatch_water_relief_01"}}).ok, "contract-integrity fixture should accept authored terms")
	var forged_contract_save: Dictionary = accepted_contract_world.serialize()
	forged_contract_save["active_contracts"]["reedwatch_water_relief_01"]["reward"] = 999999
	var rejected_forged_contract := AshWorldState.new(0).load_serialized(forged_contract_save)
	_expect(not rejected_forged_contract.ok and rejected_forged_contract.reason.contains("authored reward"), "load should reject a current-content contract with a forged reward")
	var invalid_scenario: Dictionary = source.serialize()
	invalid_scenario["scenario_states"] = {"invented_scenario": {"id": "invented_scenario", "state": "offered", "updated_day": 1}}
	var rejected_scenario := AshWorldState.new(0).load_serialized(invalid_scenario)
	_expect(not rejected_scenario.ok and rejected_scenario.reason.contains("invalid adaptive scenario"), "load should reject unknown adaptive-scenario references")
	var invalid_emergent_faction: Dictionary = source.serialize()
	invalid_emergent_faction["emergent_factions"] = {"invented_faction": {"id": "invented_faction", "scenario_id": "reedwatch_water_relief", "activated_day": 1}}
	var rejected_emergent_faction := AshWorldState.new(0).load_serialized(invalid_emergent_faction)
	_expect(not rejected_emergent_faction.ok and rejected_emergent_faction.reason.contains("invalid emergent faction"), "load should reject emergent factions that do not match authored responses")
	var inconsistent_emergent_faction: Dictionary = source.serialize()
	inconsistent_emergent_faction["emergent_factions"] = {"well_commons": {"id": "well_commons", "scenario_id": "reedwatch_water_relief", "activated_day": 1}}
	var rejected_inconsistent_faction := AshWorldState.new(0).load_serialized(inconsistent_emergent_faction)
	_expect(not rejected_inconsistent_faction.ok and rejected_inconsistent_faction.reason.contains("does not match its adaptive scenario state"), "load should reject an emergent faction attached to an untriggered scenario")
	var invalid_support_world := AshWorldState.new(1107)
	invalid_support_world.advance_day(3)
	var invalid_support_save: Dictionary = invalid_support_world.serialize()
	invalid_support_save["emergent_factions"]["well_commons"]["support"] = 99
	var rejected_support := AshWorldState.new(0).load_serialized(invalid_support_save)
	_expect(not rejected_support.ok and rejected_support.reason.contains("invalid support state"), "load should reject out-of-bounds emergent-faction support")
	var invalid_deliveries_save: Dictionary = invalid_support_world.serialize()
	invalid_deliveries_save["emergent_factions"]["well_commons"]["ordinary_deliveries"] = {"missing_good": 4}
	var rejected_deliveries := AshWorldState.new(0).load_serialized(invalid_deliveries_save)
	_expect(not rejected_deliveries.ok and rejected_deliveries.reason.contains("invalid ordinary deliveries"), "load should reject unknown durable Commons delivery goods")
	var oversized_deliveries_save: Dictionary = invalid_support_world.serialize()
	oversized_deliveries_save["emergent_factions"]["well_commons"]["ordinary_deliveries"] = {"charcoal": 1000001}
	var rejected_oversized_deliveries := AshWorldState.new(0).load_serialized(oversized_deliveries_save)
	_expect(not rejected_oversized_deliveries.ok and rejected_oversized_deliveries.reason.contains("invalid ordinary deliveries"), "load should reject unbounded durable Commons delivery totals")
	var invalid_interaction_save: Dictionary = invalid_support_world.serialize()
	invalid_interaction_save["emergent_factions"]["well_commons"]["interaction_ids"] = ["invented_interaction"]
	var rejected_interaction := AshWorldState.new(0).load_serialized(invalid_interaction_save)
	_expect(not rejected_interaction.ok and rejected_interaction.reason.contains("invalid interaction"), "load should reject unknown emergent-faction interaction history")
	var invalid_pending: Dictionary = source.serialize()
	invalid_pending["pending_event"] = {"id": "invented_event", "choices": []}
	invalid_pending["journey_context"] = {"origin_id": "ashgate", "destination_id": "reedwatch", "route_id": "old_road"}
	var rejected_pending := AshWorldState.new(0).load_serialized(invalid_pending)
	_expect(not rejected_pending.ok and rejected_pending.reason.contains("invalid pending event"), "load should reject pending events that cannot be resolved")
	var orphaned_journey: Dictionary = source.serialize()
	orphaned_journey["journey_context"] = {"origin_id": "ashgate", "destination_id": "reedwatch", "route_id": "old_road"}
	var rejected_orphan := AshWorldState.new(0).load_serialized(orphaned_journey)
	_expect(not rejected_orphan.ok and rejected_orphan.reason.contains("incomplete pending journey"), "load should reject an orphaned journey that could soft-lock navigation")
	var pending_source := AshWorldState.new(1107)
	_expect(MarketCommandProcessor.execute(pending_source, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "medicine", "quantity": 2}}).ok, "pending-save fixture should buy its exposed cargo")
	_expect(MarketCommandProcessor.execute(pending_source, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "toll_road", "destination_id": "brine_cross"}}).ok and not pending_source.pending_event.is_empty(), "pending-save fixture should reach its route decision")
	var tampered_choice_save: Dictionary = pending_source.serialize()
	var tampered_choices: Array = tampered_choice_save["pending_event"]["choices"]
	tampered_choices[0]["money_reward"] = 9999
	var rejected_choice := AshWorldState.new(0).load_serialized(tampered_choice_save)
	_expect(not rejected_choice.ok and rejected_choice.reason.contains("authored choices"), "load should reject a pending event whose serialized reward differs from authored content")
	var water_pending_source := AshWorldState.new(1107)
	water_pending_source.crisis_stage = 1
	water_pending_source._update_crisis_modifiers()
	_expect(MarketCommandProcessor.execute(water_pending_source, {"id": MarketCommandProcessor.BUY_GOODS, "inputs": {"good_id": "water", "quantity": 2}}).ok, "trade-basis fixture should buy its shortage cargo")
	_expect(MarketCommandProcessor.execute(water_pending_source, {"id": MarketCommandProcessor.DEPART_ROUTE, "inputs": {"route_id": "old_road", "destination_id": "reedwatch"}}).ok and water_pending_source.pending_event.get("id", "") == "last_clean_barrel", "trade-basis fixture should reach the shortage event")
	var tampered_trade_save: Dictionary = water_pending_source.serialize()
	tampered_trade_save["pending_event"]["trade_basis"]["premium_total"] = 9999
	var rejected_trade := AshWorldState.new(0).load_serialized(tampered_trade_save)
	_expect(not rejected_trade.ok and rejected_trade.reason.contains("invalid trade value"), "load should reject a pending event with a forged frozen premium")

func _test_legacy_save_migration() -> void:
	var legacy_world := AshWorldState.new(42)
	var legacy_save := legacy_world.serialize()
	legacy_save.erase("save_version")
	legacy_save.erase("content_version")
	legacy_save.erase("command_history")
	legacy_save.erase("market_pressure")
	legacy_save.erase("market_delivery_history")
	var migrated := AshWorldState.new(0)
	var migration_result := migrated.load_serialized(legacy_save)
	_expect(migration_result.ok, "legacy save without version metadata should migrate")
	_expect(int(migration_result.migrated_from) == 0, "legacy save should report its source version")
	_expect(migrated.command_history.is_empty(), "legacy save migration should initialize empty command history")
	_expect(migrated.market_pressure.is_empty() and migrated.market_delivery_history.is_empty(), "legacy save migration should initialize empty market memory")
	_expect(migrated.visit_slots_remaining == 2, "legacy save migration should initialize the visit budget")
	var version_one_save := legacy_world.serialize()
	version_one_save["save_version"] = 1
	version_one_save.erase("market_pressure")
	version_one_save.erase("market_delivery_history")
	var migrated_v1 := AshWorldState.new(0)
	var migration_v1_result := migrated_v1.load_serialized(version_one_save)
	_expect(migration_v1_result.ok and int(migration_v1_result.migrated_from) == 1, "version-one saves should migrate to the market-memory schema")
	_expect(migrated_v1.serialize().save_version == AshWorldState.SAVE_VERSION, "version-one migration should produce the current save version")
	var version_two_save := legacy_world.serialize()
	version_two_save["save_version"] = 2
	version_two_save.erase("visit_slots_remaining")
	var migrated_v2 := AshWorldState.new(0)
	var migration_v2_result := migrated_v2.load_serialized(version_two_save)
	_expect(migration_v2_result.ok and int(migration_v2_result.migrated_from) == 2, "version-two saves should migrate to the visit-budget schema")
	_expect(migrated_v2.visit_slots_remaining == 2, "version-two migration should initialize the visit budget")
	var version_three_save := legacy_world.serialize()
	version_three_save["save_version"] = 3
	version_three_save.erase("active_contracts")
	version_three_save.erase("contract_history")
	var migrated_v3 := AshWorldState.new(0)
	var migration_v3_result := migrated_v3.load_serialized(version_three_save)
	_expect(migration_v3_result.ok and int(migration_v3_result.migrated_from) == 3, "version-three saves should migrate to the contract schema")
	_expect(migrated_v3.active_contracts.is_empty() and migrated_v3.contract_history.is_empty(), "version-three migration should initialize empty contract state")
	var version_four_save := legacy_world.serialize()
	version_four_save["save_version"] = 4
	version_four_save.erase("journey_context")
	version_four_save.erase("pending_event")
	version_four_save.erase("resolved_event_ids")
	version_four_save.erase("event_history")
	var migrated_v4 := AshWorldState.new(0)
	var migration_v4_result := migrated_v4.load_serialized(version_four_save)
	_expect(migration_v4_result.ok and int(migration_v4_result.migrated_from) == 4, "version-four saves should migrate to the event schema")
	_expect(migrated_v4.pending_event.is_empty() and migrated_v4.event_history.is_empty(), "version-four migration should initialize empty event state")
	var version_five_save := legacy_world.serialize()
	version_five_save["save_version"] = 5
	version_five_save.erase("route_conditions")
	var migrated_v5 := AshWorldState.new(0)
	var migration_v5_result := migrated_v5.load_serialized(version_five_save)
	_expect(migration_v5_result.ok and int(migration_v5_result.migrated_from) == 5, "version-five saves should migrate to the route-condition schema")
	_expect(migrated_v5.route_conditions.is_empty(), "version-five migration should initialize empty route conditions")
	var version_six_save := legacy_world.serialize()
	version_six_save["save_version"] = 6
	version_six_save.erase("settlement_resilience")
	var migrated_v6 := AshWorldState.new(0)
	var migration_v6_result := migrated_v6.load_serialized(version_six_save)
	_expect(migration_v6_result.ok and int(migration_v6_result.migrated_from) == 6, "version-six saves should migrate to the settlement-resilience schema")
	_expect(migrated_v6.settlement_resilience.is_empty(), "version-six migration should initialize empty settlement resilience")
	var version_seven_save := legacy_world.serialize()
	version_seven_save["save_version"] = 7
	version_seven_save.erase("known_information")
	var migrated_v7 := AshWorldState.new(0)
	var migration_v7_result := migrated_v7.load_serialized(version_seven_save)
	_expect(migration_v7_result.ok and int(migration_v7_result.migrated_from) == 7, "version-seven saves should migrate to the known-information schema")
	_expect(migrated_v7.known_information.is_empty(), "version-seven migration should initialize empty known information")
	var version_eight_save := legacy_world.serialize()
	version_eight_save["save_version"] = 8
	version_eight_save.erase("recruited_crew")
	version_eight_save.erase("assigned_crew")
	version_eight_save.erase("crew_reports")
	var migrated_v8 := AshWorldState.new(0)
	var migration_v8_result := migrated_v8.load_serialized(version_eight_save)
	_expect(migration_v8_result.ok and int(migration_v8_result.migrated_from) == 8, "version-eight saves should migrate to the crew schema")
	_expect(migrated_v8.recruited_crew.is_empty() and migrated_v8.assigned_crew.is_empty() and migrated_v8.crew_reports.is_empty(), "version-eight migration should initialize empty crew state")
	var version_nine_save := legacy_world.serialize()
	version_nine_save["save_version"] = 9
	version_nine_save.erase("arms_escalation")
	version_nine_save.erase("arms_trade_history")
	var migrated_v9 := AshWorldState.new(0)
	var migration_v9_result := migrated_v9.load_serialized(version_nine_save)
	_expect(migration_v9_result.ok and int(migration_v9_result.migrated_from) == 9, "version-nine saves should migrate to the arms-escalation schema")
	_expect(migrated_v9.arms_escalation == 0 and migrated_v9.arms_trade_history.is_empty(), "version-nine migration should initialize quiet arms state")
	var version_ten_save := legacy_world.serialize()
	version_ten_save["save_version"] = 10
	version_ten_save.erase("ending_id")
	version_ten_save.erase("ending_summary")
	var migrated_v10 := AshWorldState.new(0)
	var migration_v10_result := migrated_v10.load_serialized(version_ten_save)
	_expect(migration_v10_result.ok and int(migration_v10_result.migrated_from) == 10, "version-ten saves should migrate to the ending schema")
	_expect(migrated_v10.ending_id.is_empty() and migrated_v10.ending_summary.is_empty(), "version-ten migration should initialize an unresolved ending")
	var version_eleven_save := legacy_world.serialize()
	version_eleven_save["save_version"] = 11
	version_eleven_save.erase("scenario_states")
	version_eleven_save.erase("emergent_factions")
	version_eleven_save["day"] = 4
	var migrated_v11 := AshWorldState.new(0)
	var migration_v11_result := migrated_v11.load_serialized(version_eleven_save)
	_expect(migration_v11_result.ok and int(migration_v11_result.migrated_from) == 11, "version-eleven saves should migrate to the adaptive-scenario schema")
	_expect(String(migrated_v11.scenario_state("reedwatch_water_relief").get("state", "")) == "expired" and not migrated_v11.emergent_faction("well_commons").is_empty(), "a Day 4 legacy save should causally initialize its replacement response")
	var previous_content_save := legacy_world.serialize()
	previous_content_save["content_version"] = "1.25.0"
	previous_content_save["recruited_crew"] = ["nara_vey", "tess_oryn"]
	previous_content_save["assigned_crew"] = "tess_oryn"
	previous_content_save["crew_reports"] = {
		"toll_road": {"crew_id": "tess_oryn", "observed_day": 1, "note": "Legacy route note."}
	}
	var upgraded_content := AshWorldState.new(0)
	var upgraded_content_result := upgraded_content.load_serialized(previous_content_save)
	_expect(upgraded_content_result.ok and int(upgraded_content_result.migrated_from) == AshWorldState.SAVE_VERSION, "a save from content 1.25.0 should load without a schema migration")
	_expect(upgraded_content.is_crew_recruited("nara_vey") and upgraded_content.assigned_crew == "tess_oryn", "the content update should preserve the prior roster and assignment")
	_expect(upgraded_content.serialize().content_version == "1.28.0" and not MarketContent.crew_member("mara_voss").is_empty() and not MarketContent.crew_member("orin_bell").is_empty(), "the upgraded save should adopt current content while exposing the new optional specialists")
	var future_save := legacy_world.serialize()
	future_save["save_version"] = AshWorldState.SAVE_VERSION + 1
	var rejected := AshWorldState.new(0).load_serialized(future_save)
	_expect(not rejected.ok, "future save versions should be rejected safely")
