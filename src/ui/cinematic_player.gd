class_name CinematicPlayer
extends CanvasLayer

signal finished

const HISTORY_PATH: String = "user://cinematics.cfg"
const FILES: Dictionary = {
	&"opening": "res://assets/cinematics/opening.ogv",
	&"prologue_complete": "res://assets/cinematics/prologue_complete.ogv",
	&"chapter5_complete": "res://assets/cinematics/chapter5_complete.ogv",
	&"journey_complete": "res://assets/cinematics/journey_complete.ogv",
}
const DURATIONS: Dictionary = {&"opening": 45.74, &"prologue_complete": 52.37, &"chapter5_complete": 62.44, &"journey_complete": 36.34}
static var _consumed: Dictionary = {}

var clip_id: StringName
var video: VideoStreamPlayer
var skip_button: Button
var _was_paused: bool = false
var _owns_pause: bool = false
var _finished: bool = false


static func automated_launch() -> bool:
	if DisplayServer.get_name() == "headless":
		return true
	var arguments: PackedStringArray = OS.get_cmdline_args()
	arguments.append_array(OS.get_cmdline_user_args())
	for argument: String in arguments:
		if argument == "--script" or argument.begins_with("--capture") or argument.begins_with("--dev-"):
			return true
	var tree := Engine.get_main_loop() as SceneTree
	return tree != null and tree.root.get_node("GameMode").is_test_mode()


static func new_player(save_path: String, workbench_path: String) -> bool:
	for path: String in [save_path, workbench_path, "user://lab_state.cfg", "user://task_navigation.cfg"]:
		for suffix: String in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(path + suffix):
				return false
	return true


static func take_once(id: StringName) -> bool:
	if not FILES.has(id) or _consumed.has(id):
		return false
	var history := ConfigFile.new()
	history.load(HISTORY_PATH)
	if bool(history.get_value("watched", String(id), false)):
		return false
	# Consume before playback: skipping or closing the first session must not replay it.
	_consumed[id] = true
	history.set_value("watched", String(id), true)
	if history.save(HISTORY_PATH) != OK:
		push_warning("Could not save cinematic viewing history.")
	return true


static func present_once(host: Node, id: StringName) -> CinematicPlayer:
	if automated_launch() or not host.get_tree().get_nodes_in_group("cinematic_playback").is_empty():
		return null
	var recovery: Window = host.get_node("/root/GlobalSave").get("_failure_dialog") as Window
	if is_instance_valid(recovery) and recovery.visible:
		return null
	if not take_once(id):
		return null
	var player := CinematicPlayer.new()
	player.clip_id = id
	host.add_child(player)
	return player


func _ready() -> void:
	layer = 3000
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("cinematic_playback")
	_was_paused = get_tree().paused
	_owns_pause = true
	get_tree().paused = true
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	var background := ColorRect.new()
	background.color = Color.BLACK
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(background)
	var aspect := AspectRatioContainer.new()
	aspect.ratio = 16.0 / 9.0
	aspect.stretch_mode = AspectRatioContainer.STRETCH_FIT
	aspect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(aspect)
	video = VideoStreamPlayer.new()
	video.expand = true
	video.bus = &"Effects"
	video.loop = false
	video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	aspect.add_child(video)
	video.finished.connect(_finish)
	skip_button = Button.new()
	skip_button.text = "跳过 · Esc" if TranslationServer.get_locale().begins_with("zh") else "Skip · Esc"
	skip_button.add_theme_font_size_override("font_size", 16)
	skip_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_button.offset_left = -168
	skip_button.offset_top = -64
	skip_button.offset_right = -24
	skip_button.offset_bottom = -24
	skip_button.pressed.connect(_finish)
	screen.add_child(skip_button)
	skip_button.call_deferred("grab_focus")
	var path: String = FILES.get(clip_id, "")
	if path.is_empty() or not ResourceLoader.exists(path):
		call_deferred("_finish")
		return
	video.stream = load(path) as VideoStream
	if video.stream == null:
		call_deferred("_finish")
		return
	video.play()
	# A broken decoder must not trap the player on a black screen.
	var watchdog := Timer.new()
	watchdog.one_shot = true
	watchdog.wait_time = float(DURATIONS[clip_id]) + 5.0
	watchdog.timeout.connect(_finish)
	add_child(watchdog)
	watchdog.start()


func _input(event: InputEvent) -> void:
	if _finished or not event is InputEventKey:
		return
	var key := event as InputEventKey
	if key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if key.pressed and not key.echo:
			_finish()
	elif key.keycode not in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_TAB, KEY_F11] and not (
		OS.get_name() == "macOS" and key.keycode == KEY_F and key.meta_pressed and key.ctrl_pressed
	):
		get_viewport().set_input_as_handled()


func _finish() -> void:
	if _finished:
		return
	_finished = true
	video.stop()
	visible = false
	remove_from_group("cinematic_playback")
	get_tree().paused = _was_paused
	_owns_pause = false
	finished.emit()


func _exit_tree() -> void:
	if _owns_pause:
		get_tree().paused = _was_paused
