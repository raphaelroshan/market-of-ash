extends SceneTree

const GameQualityMetrics = preload("res://tools/game_quality_metrics.gd")

var failures: Array[String] = []

func _init() -> void:
	var metrics := GameQualityMetrics.evaluate()
	var safe: Dictionary = metrics.safe_opening
	_expect(is_equal_approx(float(safe.completion_rate), 1.0), "the guided first expedition must complete across all deterministic seeds")
	_expect(int(safe.minimum_money) >= 60 and int(safe.minimum_provisions) >= 9, "the guided first expedition must preserve a credible recovery floor")

	var opening: Dictionary = metrics.opening_variety
	_expect(int(opening.positive_strategy_count) >= 3 and int(opening.good_count) >= 3, "the opening must expose at least three positive cargo strategies")
	_expect(int(opening.route_count) >= 2, "the opening must include viable choices on both regulated and exposed roads")

	var patterns: Dictionary = metrics.trade_pattern_families
	_expect(int(patterns.fixture_count) >= 3 and bool(patterns.all_viable), "staple, repair, medicine, and industrial trade patterns must remain viable without contracts")
	for result in patterns.results:
		_expect(not bool(result.requires_contract) and int(result.expected_net_profit) > 0, "ordinary trade fixture %s must stay independent and profitable" % String(result.family))

	var parity: Dictionary = metrics.contract_parity
	_expect(bool(parity.passed), "the best ordinary opening must retain at least 70% of the accessible relief contract's expected value")

	var reward_balance: Dictionary = metrics.path_reward_balance
	_expect(bool(reward_balance.passed), "the ten-minute reward fixture must keep the contract attractive without eclipsing ordinary trade")
	_expect(bool(reward_balance.all_dimensions_tracked), "ordinary, contract, civic, and faction paths must report cash, provisions, hold, standing, time, and visit slots separately")
	_expect(bool(reward_balance.non_cash_paths_are_explicit), "civic and faction paths must expose their non-cash resilience and support rewards")

	var adaptive: Dictionary = metrics.adaptive_failure_recovery
	_expect(adaptive.scenario_state == "expired" and bool(adaptive.faction_active), "ignored relief must causally create the Well Commons replacement actor")
	_expect(int(adaptive.reedwatch_resilience) == 1 and bool(adaptive.offer_closed), "the replacement response must change durable state and close the stale offer")
	_expect(bool(adaptive.new_trade_viable) and int(adaptive.replacement_charcoal_net) > 0, "the failure response must create a profitable contract-free charcoal trade that was not viable before")

	var faction_agency: Dictionary = metrics.replacement_faction_agency
	_expect(int(faction_agency.cooperation_paths_completed) >= 2 and int(faction_agency.cooperative_support) == 2, "the Well Commons must expose two distinct executable cooperation paths")
	_expect(bool(faction_agency.opposition_path_completed) and int(faction_agency.opposed_support) == -1, "the Well Commons must expose a disclosed Warden bypass or opposition path")
	_expect(bool(faction_agency.reconciliation_completed) and int(faction_agency.reconciled_support) == 0 and bool(faction_agency.ordinary_trade_open), "Commons pressure must be reversible without closing ordinary trade")

	var adaptive_ending: Dictionary = metrics.adaptive_ending
	_expect(bool(adaptive_ending.commands_completed), "the alternate ending fixture must use the ordinary buy, travel, sell, and settlement-action command path")
	_expect(bool(adaptive_ending.passed) and adaptive_ending.scenario_state in ["expired", "failed"], "scenario failure followed by ordinary Commons trade must reach its authored alternate ending")
	_expect(int(adaptive_ending.delivery_quantity) >= 4 and int(adaptive_ending.delivery_day) >= int(adaptive_ending.activation_day), "the Commons ending must require a post-activation ordinary charcoal delivery")

	var world_states: Dictionary = metrics.world_state_variety
	_expect(int(world_states.choice_count) >= 3, "changing market and access state must rotate the best visible trade across at least three choices")
	_expect(int(world_states.route_count) >= 2, "no one route may dominate every tested world state")

	var recovery: Dictionary = metrics.cargo_loss_recovery
	_expect(bool(recovery.cargo_loss_observed), "the quality sweep must exercise a real command-path cargo loss")
	_expect(bool(recovery.recovered) and int(recovery.recovery_trips) <= 3, "the caravan must recover its starting cash within three outbound trades after one cargo loss")
	_expect(int(recovery.minimum_money) > 0 and int(recovery.ending_provisions) > 0, "cargo-loss recovery must avoid a money or provision death spiral")

	var preparation: Dictionary = metrics.preparation_overhead
	_expect(bool(preparation.tutorial_setup_ok), "the tutorial preparation sequence must remain executable")
	_expect(int(preparation.commands_through_first_trade) <= 2, "the tutorial must reach meaningful trade within two authoritative commands")

	if failures.is_empty():
		print("PASS: Market of Ash game-quality gates")
		print("QUALITY_METRICS=" + JSON.stringify(metrics))
		quit(0)
	else:
		print("QUALITY_METRICS=" + JSON.stringify(metrics))
		for failure in failures:
			push_error(failure)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
