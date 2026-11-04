extends SceneTree
var failures: int = 0
var checks: int = 0
var capture: String = ""
func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--d1-capture="): capture = arg.trim_prefix("--d1-capture=")
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
func settle() -> void:
	for frame: int in 12: await process_frame
func key(code: Key, unicode: int = 0, ctrl: bool = false, shift: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = unicode
		event.ctrl_pressed = ctrl
		event.shift_pressed = shift
		event.pressed = down
		root.push_input(event)
		await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	for route: String in ["chapter_3/arrival", "chapter_1/assembly"]:
		check(root.get_node("TaskNavigation").enter(route), route + " opens")
		await settle()
		var host: Control = current_scene
		if route.begins_with("chapter_3"): host._toggle("program", true)
		else: host._open_instrument(&"program")
		await settle()
		var editor: CodeEdit = host.editor
		editor.grab_focus()
		editor.select_all()
		await key(KEY_X, 120)
		check(editor.text == "x", route + " viewport Unicode replaces selection")
		await key(KEY_A, 0x4e2d)
		check(editor.text.contains("\u4e2d") and editor.text.contains("x"), route + " committed Chinese Unicode inserts")
		var committed: String = editor.text
		await key(KEY_B)
		check(editor.text == committed, route + " keycode-only injection does not insert text")
		await create_timer(2.2).timeout
		check(root.gui_get_focus_owner() == editor and editor.text == committed, route + " autosave retains focus and text")
		if DisplayServer.get_name() != "headless":
			var clipboard: String = DisplayServer.clipboard_get()
			var long_text: String = "\u4e2d\u6587 input ".repeat(512)
			DisplayServer.clipboard_set(long_text)
			editor.select_all()
			await key(KEY_V, 0, true)
			check(editor.text == long_text, route + " real clipboard pastes long Chinese text exactly")
			await key(KEY_UP, 0, true, true)
			check(editor.get_caret_line() >= 0, route + " long wrapped Chinese Ctrl+Shift+Up retains legal caret")
			DisplayServer.clipboard_set(clipboard)
			if not capture.is_empty():
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture + ("overlap.png" if route.begins_with("chapter_3") else "system.png"))
		editor.deselect()
		editor.set_caret_line(0)
		editor.set_caret_column(0)
		await key(KEY_UP, 0, true, true)
		check(editor.get_caret_line() >= 0, route + " Ctrl+Shift+Up at first line retains legal caret")
		await key(KEY_A, 0, true)
		await key(KEY_BACKSPACE)
		await key(KEY_UP, 0, true, true)
		check(editor.get_caret_line() == 0, route + " empty editor retains line zero")
	print("D1 checks: ", checks, ", failures: ", failures)
	quit(1 if failures else 0)
