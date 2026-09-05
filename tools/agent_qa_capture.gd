extends SceneTree

var output_dir := ""
var state_id := "boot"
var capture_width := 1280
var capture_height := 720
var minimum_frames := 8

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
	for _frame in range(minimum_frames):
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
		"state_id": state_id,
		"width": capture_width,
		"height": capture_height,
		"frames_waited": minimum_frames,
		"path": output_path,
		"valid": true
	}
	_write_manifest(manifest)
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
