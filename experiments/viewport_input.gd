extends SceneTree

# Acceptance actions travel through the viewport's real GUI dispatch. Model and
# control reads below are observations; no reference loader or progress setter is used.
var evidence_root: String = "res://.godot/experience/game-input/"
var failures: Array[String] = []
var observations: Array[Dictionary] = []
var ui: Control

func _init() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--evidence-dir="):
			evidence_root = argument.trim_prefix("--evidence-dir=").trim_suffix("/") + "/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_root))
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	observations.append({"ok": ok, "check": message})
	if not ok:
		failures.append(message)
		push_error(message)

func settle(frames: int = 5) -> void:
	for frame: int in range(frames):
		await process_frame

func point(at: Vector2, mask: int = 0, relative: Vector2 = Vector2.ZERO) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	motion.relative = relative
	motion.button_mask = mask
	root.push_input(motion, true)
	await process_frame

func click(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT, shift: bool = false) -> void:
	await point(at)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = button
		event.button_mask = (1 << (button - 1)) if down else 0
		event.pressed = down
		event.shift_pressed = shift
		root.push_input(event, true)
		await process_frame
	await settle(2)

func drag(from: Vector2, to: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	await point(from)
	var event := InputEventMouseButton.new()
	event.position = from
	event.global_position = from
	event.button_index = button
	event.button_mask = 1 << (button - 1)
	event.pressed = true
	root.push_input(event, true)
	await process_frame
	for step: int in range(1, 9):
		await point(from.lerp(to, step / 8.0), 1 << (button - 1), (to - from) / 8.0)
	event = InputEventMouseButton.new()
	event.position = to
	event.global_position = to
	event.button_index = button
	event.pressed = false
	root.push_input(event, true)
	await settle()

func key(code: Key, ctrl: bool = false, shift: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		event.ctrl_pressed = ctrl and OS.get_name() != "macOS"
		event.meta_pressed = ctrl and OS.get_name() == "macOS"
		event.shift_pressed = shift
		root.push_input(event, true)
		await process_frame
	await settle(3)

func type_text(value: String) -> void:
	for character: String in value:
		var event := InputEventKey.new()
		event.unicode = character.unicode_at(0)
		event.pressed = true
		Input.parse_input_event(event)
		await process_frame

func press(control: Control) -> void:
	check(control != null and control.is_visible_in_tree(), "Requested UI control exists and is visible.")
	if control == null or not control.is_visible_in_tree():
		return
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			var scroll := parent as ScrollContainer
			for attempt: int in range(40):
				var rect: Rect2 = control.get_global_rect()
				if scroll.get_global_rect().encloses(rect):
					break
				await click(scroll.get_global_rect().get_center(), MOUSE_BUTTON_WHEEL_UP if rect.position.y < scroll.global_position.y else MOUSE_BUTTON_WHEEL_DOWN)
		parent = parent.get_parent()
	await click(control.get_global_rect().get_center())
	await settle()

func named_button(parent: Node, label: String) -> Button:
	for child: Node in parent.get_children():
		if child is Button and child.is_visible_in_tree() and child.text == label:
			return child as Button
		var found: Button = named_button(child, label)
		if found != null:
			return found
	return null

func text(key_name: StringName) -> String:
	return root.get_node("Localization").text(key_name)

func capture(label: String) -> void:
	if true:
		# A settled or reduced-motion scene need not request another frame.
		# Render the current state explicitly instead of waiting indefinitely.
		RenderingServer.force_draw(false)
		var locale: String = "en" if "--locale=en" in OS.get_cmdline_user_args() else "zh_CN"
		check(root.get_texture().get_image().save_png(evidence_root + locale + "-" + label + ".png") == OK, "The requested evidence frame is saved: " + label)


func popup_key(popup: PopupMenu, code: Key) -> void:
	for down: bool in [true,false]:
		if not is_instance_valid(popup): return
		var event := InputEventKey.new()
		event.keycode=code; event.physical_keycode=code; event.pressed=down
		event.window_id=popup.get_window_id()
		Input.parse_input_event(event)
		await process_frame
	await settle(2)

func choose(control: OptionButton, index: int) -> void:
	var popup: PopupMenu=control.get_popup()
	# macOS native menus cannot receive viewport-injected events; use the
	# same PopupMenu items in its Godot-rendered mode for this proxy only.
	popup.prefer_native_menu = false
	await press(control)
	check(popup.visible,"Visible choice menu opened")
	await popup_key(popup,KEY_HOME)
	for i: int in range(control.item_count+1):
		if popup.get_focused_item()==index: break
		await popup_key(popup,KEY_DOWN)
	print("MENU: ",control.name," focus=",popup.get_focused_item()," want=",index)
	await popup_key(popup,KEY_ENTER)
	if is_instance_valid(control): check(control.selected == index,"Visible selector accepts choice %d" % index)


func _run() -> void:
	quit(0)
