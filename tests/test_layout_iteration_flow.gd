extends SceneTree
const C = preload("res://src/layout_chapter/layout_catalog.gd")
var failures: Array[String] = []
var checks: int = 0
var completed_loops: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func settle() -> void:
	for frame: int in 10: await process_frame
func stabilize_window() -> void:
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable+1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Five actual rendered frames remain 1280x720")
	# Observe natural opening lifetime; never suppress or remove the overlay.
	for attempt: int in 200:
		if root.get_node_or_null("YiOpening") == null: return
		await create_timer(0.1).timeout
	check(root.get_node_or_null("YiOpening") == null,"Natural opening finishes before interaction")
func capture(label: String) -> void:
	if "--layout-iteration-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await stabilize_window()
	await settle()
	RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1280,720),"Capture retains raw1280x720: "+label)
	var folder: String = "res://.godot/layout-iteration/"
	DirAccess.make_dir_recursive_absolute(folder)
	check(picture.save_png(folder+label+".png") == OK,"Capture saved: "+label)
func key(window: Window, code: Key) -> void:
	for down: bool in [true,false]:
		if not is_instance_valid(window): return
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		event.window_id = window.get_window_id()
		Input.parse_input_event(event); await process_frame
func edit_field_via_ui(host: Control) -> void:
	var choice: OptionButton
	for row: Node in host.tools_box.get_children():
		var is_field: bool = false
		for child: Node in row.get_children():
			if child.get_script() == preload("res://src/layout_chapter/layout_field_chip.gd") and child.field_id == 0: is_field = true
		if is_field:
			for child: Node in row.get_children():
				if child is OptionButton: choice = child
	if choice == null:
		check(false,"Field0 has its actual grouping selector")
		return
	var before: Dictionary = host.design.duplicate(true)
	var popup: PopupMenu = choice.get_popup()
	var target: int = -1
	for index: int in choice.item_count:
		if index != choice.selected and not choice.is_item_disabled(index):
			target = index
			break
	check(target >= 0,"Field selector offers a different legal group")
	popup.prefer_native_menu = false
	await click(choice)
	check(popup.visible,"Actual field grouping selector opens")
	if not popup.visible: return
	popup.grab_focus()
	await create_timer(0.2).timeout
	for attempt: int in popup.item_count+1:
		if popup.get_focused_item() == target: break
		await key(popup,KEY_DOWN)
	check(popup.get_focused_item() == target,"Keyboard focus reaches the visible legal grouping action")
	await key(popup,KEY_ENTER)
	await settle()
	check(host.design != before,"Actual selector choice edits the field grouping")
func click(control: Control) -> void:
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is ScrollContainer: parent.ensure_control_visible(control)
		parent = parent.get_parent()
	await settle()
	check(control.is_visible_in_tree() and root.get_visible_rect().encloses(control.get_global_rect()),"Clicked action visible: "+str(control.name))
	await click_at(control.get_global_rect().get_center())
func click_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new(); motion.position = at; motion.global_position = at
	root.push_input(motion,true)
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at; event.global_position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event,true); await process_frame
	await settle()
func two_columns(host: Control, left: String, right: String, context: String) -> void:
	var a: Control = host.panels[left]
	var b: Control = host.panels[right]
	var bounds := Rect2(Vector2.ZERO,host.workspace.size)
	var geometry: String = " [bounds=%s %s=%s min=%s combined=%s %s=%s min=%s combined=%s]" % [bounds,left,a.get_rect(),a.custom_minimum_size,a.get_combined_minimum_size(),right,b.get_rect(),b.custom_minimum_size,b.get_combined_minimum_size()]
	check(a.visible and b.visible and not a.minimized and not b.minimized,context+": both working columns expanded")
	check(bounds.encloses(a.get_rect()) and bounds.encloses(b.get_rect()) and not a.get_rect().intersects(b.get_rect()),context+": readable columns inside workspace without overlap"+geometry)
	check(a.size.x >= 310 and b.size.x >= 420,context+": no narrow-column workaround")
	for id: String in ["tools","memory","trace","mission"]:
		if id not in [left,right]: check(not host.panels[id].visible,context+": no hidden overlapping third column "+id)
func traces(host: Control) -> Array[String]:
	var result: Array[String] = []
	for trace: LayoutRun in host.runs: result.append(trace.canonical_signature())
	return result
func expected(host: Control) -> Array[String]:
	var result: Array[String] = []
	for trace: LayoutRun in C.evaluate(host.level,host.design).runs: result.append(trace.canonical_signature())
	return result
func historical_map(host: Control, context: String) -> void:
	var trace: LayoutRun = host.runs[host.case_index]
	check(host.source_view.mapping == trace.source_map,context+": source map comes from actual measured run")
	var view: Control = host.copy_view if host.copy_view.visible else host.source_view
	check(view.title.contains("历史结果") or view.title.contains("previous run"),context+": visible map explicitly identifies historical evidence")
	if host.copy_view.visible:
		var selection: PackedInt32Array = host.trace_list.get_selected_items()
		check(not selection.is_empty(),context+": scratch evidence has a selected event")
		if not selection.is_empty():
			check(host.copy_view.mapping == host._scratch_at_event(trace,host.trace_indices[selection[0]]),context+": scratch map is the allocation at the selected recorded event")
func loop(id: String, locale: String) -> void:
	root.get_node("TaskNavigation").pending = "chapter_4/"+id
	var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host); current_scene = host
	await settle()
	await stabilize_window()
	two_columns(host,"tools","memory",id+locale+" entry")
	host.panels.tools.close_requested.emit(&"tools"); await settle()
	check(not host.panels.tools.visible and host.panels.memory.visible,"Tools close leaves address preview before first run")
	check(host.panels.memory.size.x >= host.workspace.size.x-16,"Single address preview uses available width")
	await click(host.find_child("LayoutTool_tools",true,false))
	host.panels.memory.close_requested.emit(&"memory"); await settle()
	check(not host.panels.memory.visible and host.panels.tools.visible,"Memory close leaves editor before first run")
	await click(host.find_child("LayoutTool_memory",true,false))
	two_columns(host,"tools","memory",id+locale+" recall preview")
	host.design = C.reference_solution(id)
	host._changed(); await settle()
	host.scheme_name.text = "Unsubmitted "+id
	var run_button: Button = host.find_child("LayoutRunAll",true,false)
	var before: Array[String] = expected(host)
	await click(run_button)
	two_columns(host,"tools","trace",id+locale+" run")
	check(traces(host) == before,"All original case Trace/metrics/output identities preserved "+id+locale)
	check(not host.return_to_editing.visible,"No redundant continue action in editing mode")
	# Edit through the existing field grouping action without reopening tools.
	var name: String = host.scheme_name.text
	if id == "fields": await edit_field_via_ui(host)
	else: host._move_group(0,host._current().recipe.groups.size())
	await settle()
	two_columns(host,"tools","trace",id+locale+" edit")
	check(host.stale and host.result_context.visible and traces(host) == before,"Editing retains explicitly historical measured results")
	check(host.scheme_name.text == name,"Iteration retains unsaved name")
	host.panels.tools.close_requested.emit(&"tools"); await settle()
	two_columns(host,"memory","trace",id+locale+" stale close editor")
	historical_map(host,id+locale+" stale close editor")
	host.panels.trace.close_requested.emit(&"trace"); await settle()
	two_columns(host,"tools","memory",id+locale+" stale preview")
	host.panels.tools.close_requested.emit(&"tools"); await settle()
	two_columns(host,"memory","trace",id+locale+" stale preview to evidence")
	historical_map(host,id+locale+" stale preview to evidence")
	check(traces(host) == before and host.stale,"Returning to historical map never remeasures")
	await click(host.return_to_editing)
	before = expected(host)
	await click(run_button)
	two_columns(host,"tools","trace",id+locale+" rerun")
	check(traces(host) == before and not host.stale and not host.result_context.visible,"Rerun replaces stale evidence with original model results")
	if id == "fields": await capture(locale+"-fields-edit-results")
	var target_case: int = 1
	var state: Node = root.get_node("LayoutChapter")
	var named: Dictionary = state.named().duplicate(true)
	var completed: Dictionary = state.completed().duplicate(true)
	var design: Dictionary = host.design.duplicate(true)
	var undo: Array = host.undo_stack.duplicate(true)
	var filter: int = host.trace_filter
	await click(host.find_child("LayoutInspectCase"+str(target_case),true,false))
	two_columns(host,"memory","trace",id+locale+" inspect")
	check(host.case_index == target_case and host.return_to_editing.visible,"Explicit inspection selects order and exposes return")
	check(host.panels.trace.content_host.get_global_rect().encloses(host.return_to_editing.get_global_rect()),"Return action stays visible without scrolling back to the top")
	if id == "relocation": await capture(locale+"-relocation-inspect")
	await click(host.return_to_editing)
	two_columns(host,"tools","trace",id+locale+" return")
	check(host.case_index == target_case and host.trace_filter == filter and host.scheme_name.text == name,"Returning preserves order, filter and name")
	if id == "relocation": await capture(locale+"-relocation-return")
	check(host.design == design and host.undo_stack == undo and traces(host) == before and state.named() == named and state.completed() == completed,"Inspection/return neither edits, runs, saves names nor awards progress")
	# Actual ItemList selection uses the user-event path, unlike internal Run setup.
	if host.trace_list.item_count > 0:
		var scroll: ScrollContainer = host.results.get_parent()
		scroll.ensure_control_visible(host.trace_list)
		host.trace_list.select(0); host.trace_list.ensure_current_is_visible()
		await settle()
		host.trace_list.deselect_all()
		await click_at(host.trace_list.global_position+host.trace_list.get_item_rect(0).get_center())
		await settle()
		two_columns(host,"memory","trace",id+locale+" event")
		await click(host.return_to_editing)
	for tool: String in ["memory","tools","trace","trace","mission","mission"]:
		await click(host.find_child("LayoutTool_"+tool,true,false))
		check(host.panels.tools.visible or host.panels.memory.visible or host.panels.trace.visible,"Toolbar never leaves an empty workspace: "+tool)
	await click(host.find_child("LayoutTool_tools",true,false))
	two_columns(host,"tools","trace",id+locale+" toolbar return")
	host.panels.tools.close_requested.emit(&"tools"); await settle()
	two_columns(host,"memory","trace",id+locale+" close editor")
	host.panels.memory.close_requested.emit(&"memory"); await settle()
	two_columns(host,"tools","trace",id+locale+" close evidence")
	host.panels.trace.close_requested.emit(&"trace"); await settle()
	two_columns(host,"tools","memory",id+locale+" close results")
	await click(host.find_child("LayoutTool_trace",true,false))
	host.panels.tools.set_minimized(true)
	await click(host.find_child("LayoutTool_tools",true,false))
	two_columns(host,"tools","trace",id+locale+" restore minimized editor")
	host.panels.trace.set_minimized(true)
	await click(host.find_child("LayoutTool_trace",true,false))
	check(host.panels.trace.visible and not host.panels.trace.minimized,"Actual Trace toggle recalls minimized results")
	await click(host.find_child("LayoutTool_memory",true,false))
	host.panels.memory.set_minimized(true)
	await click(host.find_child("LayoutTool_memory",true,false))
	check(host.panels.memory.visible and not host.panels.memory.minimized,"Actual Memory toggle recalls minimized evidence")
	await click(host.find_child("LayoutTool_mission",true,false))
	host.panels.mission.set_minimized(true)
	await click(host.find_child("LayoutTool_mission",true,false))
	check(host.panels.mission.visible and not host.panels.mission.minimized,"Actual Mission toggle recalls minimized instructions")
	completed_loops += 1
	host.queue_free(); current_scene = null; await settle()
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use isolated QA profile"); quit(2); return
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	root.get_node("GameMode").set_mode(&"test")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for id: String in C.IDS: await loop(id,locale)
	check(completed_loops == C.IDS.size()*2,"Every task and locale completes without an aborted coroutine")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout iteration flow %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
