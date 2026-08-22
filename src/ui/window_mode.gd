extends Node

signal window_mode_changed(fullscreen: bool)

const DESIGN_SIZE := Vector2i(1600, 900)
const MINIMUM_WINDOWED_SIZE := Vector2i(960, 540)

var _windowed_size: Vector2i = DESIGN_SIZE
var _windowed_position: Vector2i = Vector2i.ZERO
var _has_windowed_rect: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if _display_is_headless():
		return
	if _is_deterministic_capture():
		call_deferred("_configure_capture_window")
	else:
		call_deferred("_emit_current_mode")


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var requested: bool = (
		key_event.keycode == KEY_F11
		or (key_event.keycode == KEY_ENTER and key_event.alt_pressed)
	)
	if not requested:
		return
	toggle_fullscreen()
	get_viewport().set_input_as_handled()


func is_fullscreen() -> bool:
	if _display_is_headless():
		return false
	return DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN,
	]


func toggle_fullscreen() -> void:
	if _display_is_headless():
		return
	if is_fullscreen():
		_leave_fullscreen()
	else:
		_enter_fullscreen()


func _enter_fullscreen() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_WINDOWED:
		_windowed_size = DisplayServer.window_get_size()
		_windowed_position = DisplayServer.window_get_position()
		_has_windowed_rect = true
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	call_deferred("_emit_current_mode")


func _leave_fullscreen() -> void:
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	var maximum := Vector2i(
		maxi(MINIMUM_WINDOWED_SIZE.x, int(float(usable.size.x) * 0.9)),
		maxi(MINIMUM_WINDOWED_SIZE.y, int(float(usable.size.y) * 0.9))
	)
	var target := Vector2i(
		clampi(_windowed_size.x, mini(MINIMUM_WINDOWED_SIZE.x, usable.size.x), mini(maximum.x, usable.size.x)),
		clampi(_windowed_size.y, mini(MINIMUM_WINDOWED_SIZE.y, usable.size.y), mini(maximum.y, usable.size.y))
	)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(target)
	var centered: Vector2i = usable.position + (usable.size - target) / 2
	if _has_windowed_rect and usable.has_point(_windowed_position):
		centered = Vector2i(
			clampi(_windowed_position.x, usable.position.x, usable.end.x - target.x),
			clampi(_windowed_position.y, usable.position.y, usable.end.y - target.y)
		)
	DisplayServer.window_set_position(centered)
	call_deferred("_emit_current_mode")


func _configure_capture_window() -> void:
	var capture_size: Vector2i = _requested_capture_size()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(capture_size)
	var screen: int = DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
	DisplayServer.window_set_position(usable.position + (usable.size - capture_size) / 2)
	_emit_current_mode()


func _emit_current_mode() -> void:
	window_mode_changed.emit(is_fullscreen())


func _is_deterministic_capture() -> bool:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture"):
			return true
	return false


func _requested_capture_size() -> Vector2i:
	for argument: String in OS.get_cmdline_user_args():
		if not argument.begins_with("--capture-size="):
			continue
		var dimensions: PackedStringArray = argument.trim_prefix("--capture-size=").to_lower().split("x")
		if dimensions.size() != 2 or not dimensions[0].is_valid_int() or not dimensions[1].is_valid_int():
			continue
		var candidate := Vector2i(int(dimensions[0]), int(dimensions[1]))
		if candidate.x >= MINIMUM_WINDOWED_SIZE.x and candidate.y >= MINIMUM_WINDOWED_SIZE.y:
			return candidate
	return DESIGN_SIZE


func _display_is_headless() -> bool:
	return DisplayServer.get_name() == "headless"
