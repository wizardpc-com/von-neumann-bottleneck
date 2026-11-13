extends SceneTree
## Scripted viewport interaction, not native OS input acceptance.
var failures: Array[String] = []
var checks: int = 0
var completed_loops: Array[String] = []

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame
func point(at: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	root.push_input(event,true)
	await process_frame
func click(control: Control) -> void:
	var at: Vector2 = control.get_global_rect().get_center()
	await point(at)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event,true)
		await process_frame
	await settle()
func hovered(control: Control) -> bool:
	var current: Control = root.gui_get_hovered_control()
	return current == control or current != null and control.is_ancestor_of(current)
func expose_setup_control(control: Control) -> void:
	# Fixture setup may scroll long Mission/Program content; the measured TEST
	# and Run clicks below perform no automatic scroll, focus or geometry repair.
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer:
			parent.ensure_control_visible(control)
		parent = parent.get_parent()
	await settle()

func stabilize_pixels() -> void:
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable + 1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: return
	check(false,"Renderer reaches five stable 1280x720 frames")
func capture(label: String) -> void:
	if "--instrument-recall-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1280,720),"Raw capture size "+label)
	var folder: String = "res://.godot/instrument-recall/"
	DirAccess.make_dir_recursive_absolute(folder)
	check(picture.save_png(folder+label+".png") == OK,"Capture saved "+label)

func loop(system: bool, locale: String) -> void:
	var label: String = ("chapter1-" if system else "chapter2-")+locale
	root.get_node("Localization").set_locale(locale)
	root.get_node("TaskNavigation").pending = "chapter_1/cpu_speed" if system else "chapter_2/access_order"
	var host: Control = load("res://src/system_lab/system_lab.tscn" if system else "res://src/ui/main.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	await settle(12)
	await stabilize_pixels()
	await settle()
	if system and host.locked_prediction_id.is_empty():
		# Use the actual selector/confirmation path; do not inject a locked answer.
		host.prediction_selector.select(1)
		host.prediction_selector.item_selected.emit(1)
		await expose_setup_control(host.prediction_lock_button)
		await click(host.prediction_lock_button)
		check(not host.locked_prediction_id.is_empty(),"Explicit prediction confirmation "+label)
	if host.draft_dirty if system else host.program_dirty:
		await click(host.instrument_open_buttons[&"program"])
		await expose_setup_control(host.apply_program_button)
		await click(host.apply_program_button)
	check(not host.draft_dirty if system else not host.program_dirty,"Program already applied or explicitly applied "+label)
	# Ch2's legacy Notebook window has no toolbar button: its concepts are now
	# in Handbook. Access Order exposes Program as the third real tool entry.
	var ids: Array[StringName] = [&"test_bench",&"profiler",&"history" if system else &"program"]
	for id: StringName in ids:
		if not host.instrument_open_buttons.has(id) or not host.instrument_windows.has(id):
			check(false,"Missing real toolbar/window fixture entry "+String(id)+" "+label)
			host.queue_free()
			current_scene = null
			await settle()
			return
		if not host.instrument_open_buttons[id].is_visible_in_tree():
			check(false,"Fixture toolbar entry is unavailable "+String(id)+" "+label)
			host.queue_free()
			current_scene = null
			await settle()
			return
		# An explicit Apply setup may already have opened Program.
		if host.instrument_windows[id].visible:
			await click(host.instrument_open_buttons[id])
			if host.instrument_windows[id].visible:
				await click(host.instrument_open_buttons[id])
		await click(host.instrument_open_buttons[id])
		check(host.instrument_windows[id].visible,"Toolbar opens "+String(id)+" "+label)
	var area: Control = host.desktop_host if system else host.instrument_host
	# Legal manually arranged rectangles isolate recall from automatic docking.
	# All three cover the same region, including the Run button.
	for id: StringName in ids:
		var panel: Control = host.instrument_windows[id]
		panel.set_minimized(false)
		panel.position = Vector2(maxf(12,area.size.x-650),12)
		panel.size = Vector2(620,area.size.y-24)
		panel.fit_to_parent(12)
		host._focus_instrument(id)
	await settle()
	var geometry: Dictionary = {}
	for id: StringName in ids:
		var panel: Control = host.instrument_windows[id]
		geometry[id] = panel.get_rect()
		check(Rect2(Vector2.ZERO,area.size).encloses(panel.get_rect()),"Fixture rectangle is legal "+String(id)+" "+label)
	var test: Control = host.instrument_windows[&"test_bench"]
	var action: Button = host.official_run_button
	check(not action.disabled,"Run is legitimately enabled "+label)
	check(test.get_global_rect().encloses(action.get_global_rect()),"Run fits inside Test Bench "+label)
	await point(action.get_global_rect().get_center())
	check(not hovered(action),"Higher tool really intercepts Run before recall "+label)
	var draft: String = host.editor.text
	var applied: String = host.applied_program_source
	var history: Array = host.editor_history.duplicate(true) if system else host.run_history.duplicate(true)
	var state: Node = root.get_node("SystemChapter" if system else "LocalityChapter")
	var completed: Dictionary = state.completed_levels().duplicate(true)
	var trace: Variant = host.current_trace
	var prediction: StringName = host.locked_prediction_id if system else &""
	capture(label+"-covered")
	await click(host.instrument_open_buttons[&"test_bench"])
	check(test.visible and not test.minimized and host.instrument_open_buttons[&"test_bench"].button_pressed,"Single TEST click recalls without hiding "+label)
	for id: StringName in ids:
		check(host.instrument_windows[id].get_rect() == geometry[id] and host.instrument_windows[id].visible,"Recall preserves geometry and independent visibility "+String(id)+" "+label)
	check(host.editor.text == draft and host.applied_program_source == applied,"Recall neither edits nor applies a program "+label)
	check((host.editor_history if system else host.run_history) == history and state.completed_levels() == completed and host.current_trace == trace,"Recall preserves history, completion and measured trace "+label)
	check(not system or host.locked_prediction_id == prediction,"Recall preserves prediction "+label)
	await point(action.get_global_rect().get_center())
	check(hovered(action),"Run receives pointer after recall "+label)
	capture(label+"-recalled")
	# Test the close toggle before running can introduce any completion overlay.
	await click(host.instrument_open_buttons[&"test_bench"])
	check(not test.visible and not host.instrument_open_buttons[&"test_bench"].button_pressed,"Uncovered second TEST click closes "+label)
	await click(host.instrument_open_buttons[&"test_bench"])
	check(test.visible and test.get_rect() == geometry[&"test_bench"],"Reopening retains user geometry "+label)
	var presses: Array[int] = [0]
	action.pressed.connect(func() -> void: presses[0] += 1)
	await click(action)
	check(presses[0] == 1,"Real Run click reaches button exactly once "+label)
	check(host.current_trace != null and host.current_trace != trace,"Run produces a fresh actual Trace "+label)
	if system:
		check(not host.latest_official_traces.is_empty() and host.latest_receipt != null,"Ch1 Run produces official cases and receipt "+label)
	else:
		check(host.current_trace != null and host.current_trace.test_name == "Official Test Set" and host.run_history.size() > history.size(),"Ch2 Run produces official history "+label)
	check(host.editor.text == draft and host.applied_program_source == applied,"Explicit Run does not silently apply a different draft "+label)
	completed_loops.append(label)
	host.queue_free()
	current_scene = null
	await settle()

func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(2); return
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN","en"]:
		await loop(true,locale)
		await loop(false,locale)
	# A GDScript runtime error can abort one coroutine without aborting SceneTree.
	# Never report PASS unless every complete mouse/Run scenario reached its end.
	check(completed_loops == ["chapter1-zh_CN","chapter2-zh_CN","chapter1-en","chapter2-en"],"All four scenarios complete without an aborted coroutine")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"chapter instrument recall %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
