extends SceneTree

const MainScene = preload("res://scenes/Main.tscn")

var output_dir := ""
var state_id := "main_menu"
var capture_width := 1280
var capture_height := 720
var minimum_frames := 8
var commit := "unknown"
var scenario := ""

func _init() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output_dir = argument.trim_prefix("--output=")
		elif argument.begins_with("--state="):
			state_id = argument.trim_prefix("--state=")
		elif argument.begins_with("--width="):
			capture_width = maxi(640, int(argument.trim_prefix("--width=")))
		elif argument.begins_with("--height="):
			capture_height = maxi(360, int(argument.trim_prefix("--height=")))
		elif argument.begins_with("--frames="):
			minimum_frames = maxi(1, int(argument.trim_prefix("--frames=")))
		elif argument.begins_with("--commit="):
			commit = argument.trim_prefix("--commit=")
		elif argument.begins_with("--scenario="):
			scenario = argument.trim_prefix("--scenario=")
	call_deferred("_capture_when_ready")

func _capture_when_ready() -> void:
	if output_dir.is_empty():
		_fail("missing --output")
		return
	var directory_error := DirAccess.make_dir_recursive_absolute(output_dir)
	if directory_error != OK and not DirAccess.dir_exists_absolute(output_dir):
		_fail("could not create output directory: %s" % error_string(directory_error))
		return
	var root_window := get_root()
	root_window.size = Vector2i(capture_width, capture_height)
	DisplayServer.window_set_size(Vector2i(capture_width, capture_height))
	var ui: Control = MainScene.instantiate()
	var capture_user_prefix := "user://market_of_ash_agent_qa_%d" % OS.get_process_id()
	ui.save_path = capture_user_prefix + ".save"
	ui.settings_path = capture_user_prefix + ".cfg"
	ui.report_path = capture_user_prefix + ".json"
	ui.autosave_enabled = false
	ui.settings_persistence_enabled = false
	root_window.add_child(ui)
	var stable_frames := 0
	var frames_waited := 0
	for frame_index in range(180):
		await process_frame
		frames_waited = frame_index + 1
		var ready: bool = ui._current_ui_state_id() == state_id and ui.start_game_button != null and ui.start_game_button.is_visible_in_tree()
		stable_frames = stable_frames + 1 if ready else 0
		if stable_frames >= minimum_frames:
			break
	if stable_frames < minimum_frames:
		_fail("state %s did not remain ready for %d frames; actual state was %s" % [state_id, minimum_frames, ui._current_ui_state_id()])
		return
	RenderingServer.force_draw(false)
	await process_frame
	var viewport := root_window.get_viewport()
	var texture := viewport.get_texture()
	if texture == null:
		_fail("viewport texture is unavailable")
		return
	var image := texture.get_image()
	if image == null or image.is_empty():
		_fail("viewport image is empty")
		return
	if image.get_width() != capture_width or image.get_height() != capture_height:
		_fail("capture dimensions were %sx%s, expected %sx%s" % [image.get_width(), image.get_height(), capture_width, capture_height])
		return
	if _is_uniform(image):
		_fail("capture is visually uniform; rendered-frame readiness was not reached")
		return
	var output_path := output_dir.path_join("%s.png" % state_id)
	var save_error := image.save_png(output_path)
	if save_error != OK:
		_fail("could not save %s: %s" % [output_path, error_string(save_error)])
		return
	var manifest := {
		"schema_version": 1,
		"game": "market-of-ash",
		"commit": commit,
		"version": ProjectSettings.get_setting("application/config/version", "unknown"),
		"engine": Engine.get_version_info().get("string", "unknown"),
		"renderer": ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		"locale": OS.get_locale(),
		"scenario": scenario,
		"state_id": state_id,
		"width": capture_width,
		"height": capture_height,
		"frames_waited": frames_waited,
		"path": output_path,
		"input_trace": ["launch", "wait:%s" % state_id],
		"readiness": {"ready": true, "stable_frames": stable_frames, "actual_state": ui._current_ui_state_id()},
		"known_limitations": ["semantic scenario execution remains planned; this capture proves only the release-facing Main Menu readiness state"],
		"valid": true
	}
	_write_manifest(manifest)
	for suffix in [".save", ".save.bak", ".save.tmp", ".cfg", ".json"]:
		var generated_path := ProjectSettings.globalize_path(capture_user_prefix + suffix)
		if FileAccess.file_exists(generated_path):
			DirAccess.remove_absolute(generated_path)
	quit(0)

func _is_uniform(image: Image) -> bool:
	var samples := [Vector2i(0, 0), Vector2i(image.get_width() - 1, 0), Vector2i(0, image.get_height() - 1), Vector2i(image.get_width() - 1, image.get_height() - 1), Vector2i(image.get_width() / 2, image.get_height() / 2)]
	var minimum := 1.0
	var maximum := 0.0
	for point in samples:
		var color := image.get_pixel(point.x, point.y)
		var luminance := color.r * 0.2126 + color.g * 0.7152 + color.b * 0.0722
		minimum = minf(minimum, luminance)
		maximum = maxf(maximum, luminance)
	return maximum - minimum < 0.01

func _write_manifest(payload: Dictionary) -> void:
	var manifest_path := output_dir.path_join("capture-manifest.json")
	var file := FileAccess.open(manifest_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "  "))

func _fail(reason: String) -> void:
	push_error("AGENT_QA_CAPTURE_FAILED: %s" % reason)
	quit(2)
