extends SceneTree

const MarketContent = preload("res://src/core/market_content.gd")
const VisualRegistry = preload("res://src/ui/visual_registry.gd")

var failures: Array[String] = []

func _init() -> void:
	var arrival_treatments: Dictionary = {}
	for settlement_id in MarketContent.settlement_ids():
		var settlement: Dictionary = MarketContent.settlements().get(settlement_id, {})
		var style := VisualRegistry.settlement_style(settlement_id, settlement.get("identity", {}))
		_expect(not String(style.get("motif", "")).is_empty(), "%s needs an authored settlement motif" % settlement_id)
		_expect(not String(style.get("market_accent", "")).is_empty(), "%s needs an authored market accent" % settlement_id)
		_expect(not String(style.get("arrival_treatment", "")).is_empty(), "%s needs an authored arrival treatment" % settlement_id)
		arrival_treatments[String(style.get("arrival_treatment", ""))] = true
	_expect(arrival_treatments.size() >= 8, "the settlement set should not collapse to repeated arrival styling")

	for region_id in MarketContent.regions().keys():
		var region_style := VisualRegistry.region_style(String(region_id))
		_expect(not String(region_style.get("ground_pattern", "")).is_empty(), "%s needs a map-ground pattern" % region_id)
		_expect(not String(region_style.get("risk_symbol", "")).is_empty(), "%s needs a regional risk symbol" % region_id)

	var route_textures: Dictionary = {}
	for route_id in MarketContent.routes().keys():
		var style := VisualRegistry.route_style(String(route_id))
		_expect(not String(style.get("scene_id", "")).is_empty(), "%s needs a road scene" % route_id)
		_expect(not String(style.get("texture", "")).is_empty(), "%s needs a route texture" % route_id)
		_expect(style.get("accent") is Color, "%s needs a parsed route accent" % route_id)
		route_textures[String(style.get("texture", ""))] = true
	_expect(route_textures.size() == MarketContent.routes().size(), "each authored road should retain a distinct texture vocabulary")

	_expect(VisualRegistry.risk_cue(0.1).tier == "stable", "low risk should use the stable cue")
	_expect(VisualRegistry.risk_cue(0.35).tier == "guarded", "medium risk should use the guarded cue")
	_expect(VisualRegistry.risk_cue(0.6).tier == "severe", "high risk should use the severe cue")

	if failures.is_empty():
		print("Visual registry: PASS")
	else:
		for failure in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
