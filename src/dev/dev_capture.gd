extends Node
## Developer screenshot/route helper. Inert unless launched with user args, e.g.
##   godot --path . -- --dev-shot=C:/tmp/home.png@2.5 --dev-click=640,400@1.0 --dev-quit=3
## Several --dev-shot / --dev-click / --dev-key entries may be given; times are
## seconds after startup. Used for team screenshots and recorded routes only.

var _events: Array[Dictionary] = []
var _elapsed: float = 0.0
var _quit_at: float = -1.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--dev-shot="): _add("shot", arg.trim_prefix("--dev-shot="))
		elif arg.begins_with("--dev-click="): _add("click", arg.trim_prefix("--dev-click="))
		elif arg.begins_with("--dev-move="): _add("move", arg.trim_prefix("--dev-move="))
		elif arg.begins_with("--dev-drag="): _add("drag", arg.trim_prefix("--dev-drag="))
		elif arg.begins_with("--dev-rdrag="): _add("rdrag", arg.trim_prefix("--dev-rdrag="))
		elif arg.begins_with("--dev-key="): _add("key", arg.trim_prefix("--dev-key="))
		elif arg.begins_with("--dev-call="): _add("call", arg.trim_prefix("--dev-call="))
		elif arg.begins_with("--dev-quit="): _quit_at = arg.trim_prefix("--dev-quit=").to_float()
	_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.at) < float(b.at))
	set_process(not _events.is_empty() or _quit_at > 0.0)
	if is_processing() and DisplayServer.get_name() != "headless":
		_force_window.call_deferred()

func _force_window() -> void:
	# Route recordings use a fixed 1280×720 window regardless of saved display settings.
	for frame: int in 3: await get_tree().process_frame
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1280, 720)

func _add(kind: String, spec: String) -> void:
	var at: float = 1.0
	var value: String = spec
	var split: int = spec.rfind("@")
	if split > 0:
		at = spec.substr(split + 1).to_float()
		value = spec.substr(0, split)
	_events.append({"kind": kind, "value": value, "at": at})

func _process(delta: float) -> void:
	_elapsed += delta
	while not _events.is_empty() and float(_events[0].at) <= _elapsed:
		_run(_events.pop_front())
	if _quit_at > 0.0 and _elapsed >= _quit_at:
		get_tree().quit()

func _run(event: Dictionary) -> void:
	var value: String = str(event.value)
	match str(event.kind):
		"shot":
			var image: Image = get_viewport().get_texture().get_image()
			var error: Error = image.save_png(value)
			print("DEV_SHOT ", value, " ", error)
		"click", "move":
			var parts: PackedStringArray = value.split(",")
			var position := Vector2(parts[0].to_float(), parts[1].to_float())
			var motion := InputEventMouseMotion.new()
			motion.position = position; motion.global_position = position
			get_viewport().push_input(motion)
			if str(event.kind) == "click":
				for pressed: bool in [true, false]:
					await get_tree().process_frame
					var button := InputEventMouseButton.new()
					button.button_index = MOUSE_BUTTON_LEFT
					button.pressed = pressed
					button.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
					button.position = position; button.global_position = position
					get_viewport().push_input(button)
		"drag", "rdrag":
			var p: PackedStringArray = value.split(",")
			var from := Vector2(p[0].to_float(), p[1].to_float())
			var to := Vector2(p[2].to_float(), p[3].to_float())
			var index: MouseButton = MOUSE_BUTTON_LEFT if str(event.kind) == "drag" else MOUSE_BUTTON_RIGHT
			var mask: int = MOUSE_BUTTON_MASK_LEFT if index == MOUSE_BUTTON_LEFT else MOUSE_BUTTON_MASK_RIGHT
			_mouse_motion(from, 0)
			await get_tree().process_frame
			_mouse_button(from, index, true, mask)
			for step: int in range(1, 13):
				await get_tree().process_frame
				_mouse_motion(from.lerp(to, step / 12.0), mask)
			await get_tree().process_frame
			_mouse_button(to, index, false, 0)
		"key":
			var code: Key = OS.find_keycode_from_string(value)
			for pressed: bool in [true, false]:
				var key := InputEventKey.new()
				key.keycode = code; key.physical_keycode = code; key.pressed = pressed
				get_viewport().push_input(key)
				await get_tree().process_frame
		"call":
			# group:method — lets a route trigger a documented scene action.
			var pair: PackedStringArray = value.split(":")
			if pair.size() == 2: get_tree().call_group(pair[0], pair[1])


func _mouse_motion(position: Vector2, mask: int) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position; motion.global_position = position; motion.button_mask = mask
	get_viewport().push_input(motion)

func _mouse_button(position: Vector2, index: MouseButton, pressed: bool, mask: int) -> void:
	var button := InputEventMouseButton.new()
	button.button_index = index; button.pressed = pressed; button.button_mask = mask
	button.position = position; button.global_position = position
	get_viewport().push_input(button)
