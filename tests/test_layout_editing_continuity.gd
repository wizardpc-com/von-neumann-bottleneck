extends SceneTree
var failures: Array[String] = []
var checks: int = 0
const PENDING: String = "尚未保存 / Draft name"
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func open_host(id: String) -> Control:
	root.get_node("TaskNavigation").pending = "chapter_4/"+id
	var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host)
	current_scene = host
	await settle()
	return host
func close_host(host: Control) -> void:
	host.queue_free()
	current_scene = null
	await settle()
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(1); return
	root.get_node("GameMode").set_mode(&"test")
	var state: Node = root.get_node("LayoutChapter")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for id: String in ["fields","relocation"]:
			var host: Control = await open_host(id)
			check(host.scheme_name.text.is_empty(),"New task has no other task's pending name "+id+locale)
			var named_before: Dictionary = state.named().duplicate(true)
			var completed_before: Dictionary = state.completed().duplicate(true)
			host.scheme_name.text = PENDING
			host.scheme_name.grab_focus()
			host.scheme_name.caret_column = 4
			host.scheme_name.select(1,4)
			host._rebuild_tools()
			await settle()
			check(host.scheme_name.has_focus() and host.scheme_name.caret_column == 4 and host.scheme_name.get_selection_from_column() == 1 and host.scheme_name.get_selection_to_column() == 4,"Rebuild retains active name editor caret and selection "+id+locale)
			host.scheme_name.text = PENDING
			host.score_button.grab_focus()
			host._rebuild_tools()
			await settle()
			check(host.score_button.has_focus(),"Name rebuild does not steal another control's focus "+id+locale)
			host.scheme_name.text = PENDING
			host._move_group(0,host._current().recipe.groups.size())
			await settle()
			check(host.scheme_name.text == PENDING,"Field edit preserves pending name "+id+locale)
			host.scheme_name.text = PENDING
			host._undo(false)
			await settle()
			check(host.scheme_name.text == PENDING,"Undo preserves pending name "+id+locale)
			host.scheme_name.text = PENDING
			host._undo(true)
			await settle()
			check(host.scheme_name.text == PENDING,"Redo preserves pending name "+id+locale)
			check(state.named() == named_before and state.completed() == completed_before,"Editing name and layout neither names a save nor grants completion "+id+locale)
			host.scheme_name.text = PENDING
			host._run_all()
			await settle()
			check(host.scheme_name.text == PENDING,"Run preserves pending name "+id+locale)
			if id == "relocation":
				host.scheme_name.text = PENDING
				host._select_trace(1)
				await settle()
				check(host.scheme_name.text == PENDING,"Inspecting other order preserves pending name "+locale)
				host.scheme_name.text = PENDING
				var choice: OptionButton = host.find_child("LayoutOrderChoice",true,false)
				choice.select(0)
				choice.item_selected.emit(0)
				await settle()
				check(host.scheme_name.text == PENDING,"Switching editable order preserves pending name "+locale)
			check(state.named() == named_before,"Run and inspection do not implicitly name a save "+id+locale)
			host.scheme_name.text = PENDING+locale
			host._save_named()
			await settle()
			check(host.scheme_name.text.is_empty(),"Explicit successful save clears pending name "+id+locale)
			check(state.named().get(id,{}).has(PENDING+locale),"Explicit save keeps the exact name "+id+locale)
			host.scheme_name.text = "Do not carry to next task"
			await close_host(host)
		var next: Control = await open_host("records")
		check(next.scheme_name.text.is_empty(),"Switching tasks cannot carry unsaved name "+locale)
		await close_host(next)
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout editing continuity %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
