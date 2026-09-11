extends Node

signal window_mode_changed(fullscreen: bool)
signal window_mode_changing

const DESIGN_SIZE := Vector2i(1600, 900)
const MINIMUM_WINDOWED_SIZE := Vector2i(1280, 720)
var frame_limit: int = 60
var sound_enabled: bool = true
var sound_volume: float = 0.7
var reopen_settings: bool = false

var _windowed_size: Vector2i = DESIGN_SIZE
var _windowed_position: Vector2i = Vector2i.ZERO
var _has_windowed_rect: bool = false


func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load("user://presentation.cfg")==OK:
		ProjectSettings.set_setting("game/reduced_motion",bool(settings.get_value("display","reduced_motion",false)))
		frame_limit=int(settings.get_value("display","frame_limit",60))
		sound_enabled=bool(settings.get_value("audio","enabled",true))
		sound_volume=clampf(float(settings.get_value("audio","volume",0.7)),0.0,1.0)
	if not is_finite(sound_volume): sound_volume=0.7
	_apply_sound()
	if frame_limit not in [0,60,120]: frame_limit=60
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	if _display_is_headless():
		return
	Engine.max_fps=frame_limit
	get_window().focus_entered.connect(func() -> void: Engine.max_fps=frame_limit)
	get_window().focus_exited.connect(func() -> void: Engine.max_fps=15)
	if _is_deterministic_capture():
		call_deferred("_configure_capture_window")
	else:
		call_deferred("_configure_minimum_window")
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
	window_mode_changing.emit()
	get_viewport().gui_cancel_drag()
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
	var preferred: Vector2i = _windowed_size
	if not _has_windowed_rect and OS.get_name() == "macOS":
		# Window dimensions are pixels; the initial design size is in display points.
		preferred = Vector2i(Vector2(DESIGN_SIZE) * DisplayServer.screen_get_scale(screen))
	var target := Vector2i(
		clampi(preferred.x, mini(_minimum_pixels().x, usable.size.x), mini(maximum.x, usable.size.x)),
		clampi(preferred.y, mini(_minimum_pixels().y, usable.size.y), mini(maximum.y, usable.size.y))
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

func set_reduced_motion(value: bool) -> void:
	ProjectSettings.set_setting("game/reduced_motion",value)
	var settings := ConfigFile.new(); settings.load("user://presentation.cfg"); settings.set_value("display","reduced_motion",value)
	settings.save("user://presentation.cfg")

func _minimum_pixels() -> Vector2i:
	var scale: float = DisplayServer.screen_get_scale(DisplayServer.window_get_current_screen()) if OS.get_name()=="macOS" else 1.0
	return Vector2i(Vector2(MINIMUM_WINDOWED_SIZE)*scale)
func _configure_minimum_window() -> void:
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
	var preferred: Vector2i = _minimum_pixels()
	DisplayServer.window_set_min_size(Vector2i(mini(preferred.x,int(usable.size.x*0.9)),mini(preferred.y,int(usable.size.y*0.9))))
func set_frame_limit(value: int) -> void:
	if value not in [0,60,120]: return
	frame_limit=value
	if not _display_is_headless(): Engine.max_fps=value
	var settings := ConfigFile.new(); settings.load("user://presentation.cfg")
	settings.set_value("display","frame_limit",value); settings.save("user://presentation.cfg")

func _apply_sound() -> void:
	var index: int = AudioServer.get_bus_index("Effects")
	if index<0:
		AudioServer.add_bus(); index=AudioServer.bus_count-1
		AudioServer.set_bus_name(index,"Effects")
	AudioServer.set_bus_mute(index,not sound_enabled or sound_volume<=0)
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(0.0001,sound_volume)))

func set_sound(enabled: bool, volume: float) -> void:
	if not is_finite(volume): return
	sound_enabled=enabled; sound_volume=clampf(volume,0.0,1.0); _apply_sound()
	var settings := ConfigFile.new(); settings.load("user://presentation.cfg")
	settings.set_value("audio","enabled",sound_enabled); settings.set_value("audio","volume",sound_volume)
	settings.save("user://presentation.cfg")

func reset_presentation() -> void:
	set_reduced_motion(false); set_frame_limit(60); set_sound(true,0.7)
	get_node("/root/Localization").set_preferred_locale("zh_CN")
