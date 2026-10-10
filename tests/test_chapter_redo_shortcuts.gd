extends SceneTree
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func key(code: Key, control: bool = true, shift: bool = false, pressed: bool = true, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code
	event.meta_pressed = control and code == KEY_Z and OS.get_name() == "macOS"
	event.ctrl_pressed = control and not event.meta_pressed
	event.shift_pressed = shift
	event.pressed = pressed; event.echo = echo
	root.push_input(event,true)
	await process_frame
func snapshot(host: Control, overlap: bool) -> Dictionary:
	return (host.board if overlap else host.design).duplicate(true)
func unfocus() -> void:
	var focused: Control = root.gui_get_focus_owner()
	if focused != null: focused.release_focus()
func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	for overlap: bool in [true,false]:
		var domain: String = "Overlap" if overlap else "Layout"
		var nav: Node = root.get_node("TaskNavigation")
		if overlap: root.get_node("OverlapChapter").test_drafts.erase("buffers")
		else: root.get_node("LayoutChapter").test_drafts.erase("fields")
		nav.pending = "chapter_3/buffers" if overlap else "chapter_4/fields"
		var host: Control = load("res://src/overlap_chapter/overlap_chapter.tscn" if overlap else "res://src/layout_chapter/layout_chapter.tscn").instantiate()
		root.add_child(host); await settle()
		var original: Dictionary = snapshot(host,overlap)
		if overlap: host._add_part("buffer",Vector2(500,300))
		else: host._drop_field(0,2)
		await settle(); unfocus()
		var edited: Dictionary = snapshot(host,overlap)
		check(edited != original,domain+": actual starter editing creates reversible work")
		await key(KEY_Z)
		check(snapshot(host,overlap) == original,domain+": viewport Ctrl/Cmd+Z undoes the actual edit")
		await key(KEY_Y,false)
		await key(KEY_Y,true,false,false)
		await key(KEY_Y,true,false,true,true)
		check(snapshot(host,overlap) == original and host.redo_stack.size() == 1,domain+": bare Y, key release and echo cannot consume redo")
		var input := LineEdit.new(); input.position = Vector2(20,20); input.size = Vector2(200,40)
		host.add_child(input); input.grab_focus(); await process_frame
		await key(KEY_Y)
		check(snapshot(host,overlap) == original and host.redo_stack.size() == 1,domain+": viewport Ctrl+Y gives focused text priority")
		input.release_focus(); input.queue_free(); await process_frame
		await key(KEY_Y)
		check(snapshot(host,overlap) == edited and host.redo_stack.is_empty(),domain+": viewport Ctrl+Y exactly restores the edited snapshot")
		await key(KEY_Z); await key(KEY_Z,true,true)
		check(snapshot(host,overlap) == edited,domain+": existing Ctrl/Cmd+Shift+Z still restores the same work")
		await key(KEY_Z)
		if overlap: host._show_hint(1)
		else: host._hint_advance()
		await settle(); unfocus(); await key(KEY_Y)
		check(snapshot(host,overlap) == original and host.redo_stack.size() == 1,domain+": open read-only Hint blocks design redo")
		host.queue_free(); await settle()
	print("PASS: chapter redo shortcuts %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
