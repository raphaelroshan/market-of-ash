extends RefCounted

const DEFAULT_SETTLEMENT := {
	"market_accent": "#80634d",
	"motif": "gate",
	"arrival_treatment": "lantern_welcome",
	"sky": "#30251f",
	"ground": "#443327",
}

const SETTLEMENT_STYLES := {
	"ashgate": {"market_accent": "#8f5742", "motif": "gate", "arrival_treatment": "warden_bells"},
	"brine_cross": {"market_accent": "#557b79", "motif": "brine", "arrival_treatment": "cistern_queue"},
	"cinderford": {"market_accent": "#8d684b", "motif": "forge", "arrival_treatment": "forge_glow"},
	"hollow_market": {"market_accent": "#796985", "motif": "lanterns", "arrival_treatment": "lantern_welcome"},
	"reedwatch": {"market_accent": "#71835c", "motif": "reeds", "arrival_treatment": "water_witness"},
	"sunfall_exchange": {"market_accent": "#a66f50", "motif": "glass", "arrival_treatment": "sealed_shards"},
	"kiln_rest": {"market_accent": "#a15f3f", "motif": "kiln", "arrival_treatment": "kiln_fires"},
	"mirror_wells": {"market_accent": "#78658f", "motif": "mirrors", "arrival_treatment": "beacon_reflection"},
	"mothlight_quay": {"market_accent": "#6f8b72", "motif": "quay", "arrival_treatment": "resin_lamps"},
	"blackreed_post": {"market_accent": "#65765a", "motif": "watchtower", "arrival_treatment": "watch_fires"},
}

const REGION_STYLES := {
	"five_well_basin": {"map_accent": "#c47c52", "ground_pattern": "dry_well_grid", "risk_symbol": "broken_ring"},
	"glasswind_reach": {"map_accent": "#9f8bc0", "ground_pattern": "glass_shard_grid", "risk_symbol": "split_shard"},
	"siltfire_march": {"map_accent": "#7fb5ab", "ground_pattern": "reed_channel_grid", "risk_symbol": "warning_bell"},
}

const ROUTE_STYLES := {
	"old_road": {"scene_id": "ashen_milestones", "title": "ASHEN MILESTONES", "waypoint": "The broken mileposts", "texture": "milestone_crosses", "sky": "#40332b", "ground": "#251b17", "road": "#5a4030", "accent": "#c47c52"},
	"toll_road": {"scene_id": "warden_causeway", "title": "WARDEN CAUSEWAY", "waypoint": "The next inspection post", "texture": "toll_posts", "sky": "#33383a", "ground": "#202425", "road": "#655f50", "accent": "#e6c58d"},
	"dry_cut": {"scene_id": "saltwind_cut", "title": "SALTWIND CUT", "waypoint": "The wind-carved marker", "texture": "wind_ridges", "sky": "#3a4141", "ground": "#2b2924", "road": "#665f4e", "accent": "#7d9ca4"},
	"glasswind_trace": {"scene_id": "glasswind_shards", "title": "GLASSWIND TRACE", "waypoint": "The wrapped marker", "texture": "glass_shards", "sky": "#46372f", "ground": "#2d211c", "road": "#72513c", "accent": "#d19a64"},
	"mirror_run": {"scene_id": "mirror_night_road", "title": "MIRROR RUN", "waypoint": "The last beacon", "texture": "mirror_beacons", "sky": "#302d40", "ground": "#24212c", "road": "#554a63", "accent": "#9f8bc0"},
	"emberglass_byway": {"scene_id": "emberglass_ventway", "title": "FURNACE VENTWAY", "waypoint": "The cooling vent", "texture": "ember_vents", "sky": "#4a2e29", "ground": "#2d201c", "road": "#684033", "accent": "#cf7348"},
	"salt_causeway": {"scene_id": "brine_bell_causeway", "title": "SALT CAUSEWAY", "waypoint": "The next bell marker", "texture": "causeway_bells", "sky": "#314643", "ground": "#263934", "road": "#65746a", "accent": "#7fb5ab"},
	"reedline_track": {"scene_id": "blackreed_marsh_track", "title": "REEDLINE TRACK", "waypoint": "The raised watch fire", "texture": "reed_marks", "sky": "#30372d", "ground": "#252c22", "road": "#4f593e", "accent": "#879765"},
}

const BAZAAR_SECTION_ACCENTS := {
	"trade": "#c46f45",
	"assignments": "#c6a15b",
	"information": "#6f9b87",
	"crew": "#9a795f",
	"outlook": "#788aa3",
}

static func settlement_style(settlement_id: String, authored_identity: Dictionary = {}) -> Dictionary:
	var style := DEFAULT_SETTLEMENT.duplicate(true)
	style.merge(SETTLEMENT_STYLES.get(settlement_id, {}), true)
	for key in ["scene_id", "caption", "market_read", "map_cell", "sky", "ground", "tint", "landmark"]:
		if authored_identity.has(key):
			style[key] = authored_identity[key]
	style["market_accent"] = String(style.get("tint", style.get("market_accent", DEFAULT_SETTLEMENT.market_accent)))
	style["motif"] = String(style.get("landmark", style.get("motif", DEFAULT_SETTLEMENT.motif)))
	return style

static func region_style(region_id: String) -> Dictionary:
	return Dictionary(REGION_STYLES.get(region_id, REGION_STYLES.five_well_basin)).duplicate(true)

static func route_style(route_id: String) -> Dictionary:
	var fallback := {"scene_id": "basin_road", "title": "BASIN ROAD", "waypoint": "The road ahead", "texture": "plain_track", "sky": "#40352b", "ground": "#241c17", "road": "#594635", "accent": "#c7b49a"}
	var style := fallback.duplicate(true)
	style.merge(ROUTE_STYLES.get(route_id, {}), true)
	for color_key in ["sky", "ground", "road", "accent"]:
		style[color_key] = Color(String(style[color_key]))
	return style

static func route_color(route_id: String) -> Color:
	return Color(String(ROUTE_STYLES.get(route_id, {}).get("accent", "#705746")))

static func route_texture(route_id: String) -> String:
	return String(ROUTE_STYLES.get(route_id, {}).get("texture", "plain_track"))

static func risk_cue(risk: float) -> Dictionary:
	if risk >= 0.5:
		return {"tier": "severe", "label": "HIGH EXPOSURE", "color": Color("#d86f4c"), "glyph": "triangle"}
	if risk >= 0.3:
		return {"tier": "guarded", "label": "GUARDED", "color": Color("#d4aa62"), "glyph": "diamond"}
	return {"tier": "stable", "label": "LOW EXPOSURE", "color": Color("#76a897"), "glyph": "ring"}

static func arrival_treatment(settlement_id: String) -> String:
	return String(SETTLEMENT_STYLES.get(settlement_id, DEFAULT_SETTLEMENT).get("arrival_treatment", "lantern_welcome"))
