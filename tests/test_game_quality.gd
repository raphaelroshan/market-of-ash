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
