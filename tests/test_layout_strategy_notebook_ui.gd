extends "res://tests/test_layout_strategy_ui.gd"
## Scene-level retained exploration, real remeasurement, guarded saving and input.
const WriterLease = preload("res://experiments/candidate_session/writer_lease.gd")

class LeaveProbe:
	extends "res://experiments/layout_strategy/lab.gd"
	var leave_count: int = 0
	func _finish_quit() -> void:
		leave_count += 1

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use scripts/verify-project.py for isolated notebook UI checks.")
		quit(1)
		return
	await settle()
	var state: Node = root.get_node("LayoutChapter")
	var game_before: Dictionary = state.game_snapshot().duplicate(true)
	var mode_before: StringName = root.get_node("GameMode").current_mode
	var files_before: Dictionary = protected_files()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await notebook_loop(locale)
	check(state.game_snapshot() == game_before,"Notebook UI grants no campaign completion or official drafts")
	check(root.get_node("GameMode").current_mode == mode_before,"Notebook UI never changes Game/Test mode")
	check(protected_files() == files_before,"Notebook UI preserves official save, challenge and record bytes")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy notebook UI %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func open_notebook(path: String) -> Control:
	var host := LeaveProbe.new()
	host.notebook_path = path
	root.add_child(host)
	current_scene = host
	await settle()
	await resize_viewport(Vector2i(1280,720))
	return host

func notebook_tab(host: Control) -> void:
	host.tabs.current_tab = 3
	await settle()

func row_named(host: Control, title: String) -> Dictionary:
	for row: Dictionary in host.workspace.kept_rows():
		if row.name == title: return row
	return {}

func select_kept(host: Control, title: String) -> void:
	host.notebook_table.grab_focus()
	await settle()
	var count: int = host.notebook_table.get_root().get_child_count()
	for step: int in count+2:
		var selected: TreeItem = host.notebook_table.get_selected()
		if selected != null and str(selected.get_metadata(0)) == title: return
		var item: TreeItem = host.notebook_table.get_root().get_first_child()
		var selected_index: int = -1
		var target_index: int = -1
		var index: int = 0
		while item != null:
			if item == selected: selected_index = index
			if str(item.get_metadata(0)) == title: target_index = index
			index += 1
			item = item.get_next()
		await key(KEY_UP if selected_index > target_index else KEY_DOWN)
	check(false,"Kept recipe is reachable by keyboard: "+title)

func keep_name(host: Control, title: String) -> void:
	host.notebook_name.text = title
	host.notebook_name.text_changed.emit(title)
	await settle()
	await click(host.notebook_keep)

func notebook_loop(locale: String) -> void:
	var path: String = "user://notebook-ui-%s-%d/notebook.json" % [locale,Time.get_ticks_usec()]
	var host: Control = await open_notebook(path)
	var starter: Dictionary = host.session.draft()
	var session_id: int = host.session.get_instance_id()
	check(not host.workspace.has_saved_workspace() and
		(host.storage_label.text.contains("新工作区") or host.storage_label.text.contains("New workspace")),
		"A pristine absent notebook is not falsely labelled saved "+locale)
	await click(host.run_button)
	var first: Dictionary = host.session.selected_entry()
	await click(host.baseline_button)
	host.query_group.value = 8
	host.record_tile.value = 1
	await settle()
	var grouped: Dictionary = host.session.draft()
	check(host.session.is_stale(),"Notebook fixture starts with measured selection different from edited draft "+locale)
	await notebook_tab(host)
	check(not host.first_cap.button_pressed and not host.copy_cap.button_pressed,
		"Initial goal has no extra response or copy cap "+locale)
	check(not host.first_limit.editable and not host.copy_limit.editable and
		(host.goal_summary.text.contains("不限") or host.goal_summary.text.contains("no cap")),
		"Unchecked goal caps are visibly unlimited, not zero "+locale)
	await keep_name(host,"早回应 / Early response")
	var early: Dictionary = row_named(host,"早回应 / Early response")
	check(not early.is_empty() and early.plan == starter and host.session.draft() == grouped,
		"Keep selected retains the real selected recipe, not the different editor "+locale)
	check(early.metrics.first_request_cycles == 307 and early.metrics.total_cycles == 2456,
		"Kept starter is locally remeasured with authentic response and total "+locale)
	check(FileAccess.file_exists(path) and not host.workspace.is_dirty(),"Keeping saves the full draft/goal/notebook proposal "+locale)
	var persisted: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(Model.normalize_plan(persisted.states.scan_batch.draft) == grouped,"Keeping includes the separately edited draft "+locale)
	await click(host.run_button)
	await keep_name(host,"分组 / Grouped")
	var compact: Dictionary = row_named(host,"分组 / Grouped")
	check(compact.metrics.first_request_cycles == 531 and compact.metrics.total_cycles == 552,
		"Grouped kept recipe preserves the real competing response/total result "+locale)
	var before_goal: Dictionary = host.session.draft()
	var before_rows: Array[Dictionary] = host.session.rows()
	await click(host.first_cap)
	host.first_limit.value = 307
	await settle()
	check(host.session.goal().first_limit == 307 and not row_named(host,"分组 / Grouped").eligible,
		"An inclusive307 Q1 cap excludes the actual531 response "+locale)
	check(row_named(host,"早回应 / Early response").eligible and row_named(host,"早回应 / Early response").rank == 1,
		"Equality with the real response cap is eligible "+locale)
	check(host.comparison_label.text.contains("不满足") or host.comparison_label.text.contains("outside"),
		"Raw comparison clearly marks a selected run outside the active goal "+locale)
	host.first_limit.value = 531
	await settle()
	check(row_named(host,"分组 / Grouped").eligible and row_named(host,"分组 / Grouped").rank == 1,
		"Relaxed531 cap admits the lower552 total "+locale)
	await click(host.copy_cap)
	host.copy_limit.value = 0
	await settle()
	check(host.session.goal().copy_limit == 0 and row_named(host,"分组 / Grouped").eligible,
		"An enabled zero copy cap is a real limit and accepts source-only work "+locale)
	await choose(host.goal_objective,1)
	check(host.session.draft() == before_goal and host.session.rows() == before_rows,
		"Goal editing and objective sorting neither edit the plan nor invent runs "+locale)
	check(host.workspace.is_dirty(),"Changed goal is explicitly unsaved "+locale)
	check(host.history_table.get_column_title(5).contains("RAM"),"Recent ranking visibly identifies the selected RAM objective "+locale)
	await click(host.notebook_save)
	check(not host.workspace.is_dirty(),"Save workspace persists current goal without creating a run "+locale)
	host.notebook_name.grab_focus()
	host.notebook_name.select_all()
	await key(KEY_A,false,false,97)
	await key(KEY_B,false,false,98)
	var typed: String = host.notebook_name.text
	await key(KEY_Z,true)
	check(typed.contains("a") and typed.contains("b") and host.notebook_name.text != typed and host.session.draft() == before_goal,
		"Name text owns its text Undo without undoing the plan "+locale)
	host.notebook_name.clear()
	await select_kept(host,"早回应 / Early response")
	check(host.session.selected_entry().plan == starter and host.session.draft() == grouped and host.session.is_stale(),
		"Selecting a kept recipe executes real evidence while preserving the draft "+locale)
	check(host.status.text.contains("所选运行不同") or host.status.text.contains("differs from the selected run"),
		"A measured draft is described as different from selection, not falsely unmeasured "+locale)
	check(host.session.selected_entry().trace_id == first.trace_id,"Fresh kept replay reproduces the actual canonical Trace "+locale)
	await click(host.notebook_restore)
	check(host.session.draft() == starter and host.tabs.current_tab == 0,"Continue improving explicitly restores and returns to editing "+locale)
	host.run_button.grab_focus()
	await key(KEY_Z,true)
	check(host.session.draft() == grouped,"One Undo restores the exact draft before a kept-plan restore "+locale)
	await notebook_tab(host)
	var retained_before: Array[Dictionary] = host.workspace.kept_rows()
	host.notebook_name.text = "稍后保留 / Keep later"
	host.language_button.grab_focus()
	await click(host.language_button)
	check(host.session.get_instance_id() == session_id and host.workspace.kept_rows() == retained_before and host.session.draft() == grouped,
		"Language rebuild preserves kept recipes, goals and the same live session "+locale)
	check(host.tabs.current_tab == 3 and root.gui_get_focus_owner() == host.language_button,"Notebook locale rebuild keeps page and focus "+locale)
	check(host.notebook_name.text == "稍后保留 / Keep later","Language rebuild preserves the unsubmitted Unicode plan name "+locale)
	host.notebook_name.clear()
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()
	await notebook_modals(host,locale)
	for control: Control in [host.goal_objective,host.first_cap,host.first_limit,host.copy_cap,host.copy_limit,host.goal_summary,
			host.notebook_table,host.notebook_restore,host.notebook_remove,host.notebook_name,host.notebook_keep,host.notebook_save,host.notebook_note]:
		fits(control,"Notebook1280 "+str(control.name)+" "+locale)
	await notebook_capture(locale+"-notebook-1280",Vector2i(1280,720))
	await resize_viewport(Vector2i(960,640))
	for control: Control in [host.run_button,host.storage_label,host.goal_objective,host.first_cap,host.first_limit,host.copy_cap,host.copy_limit,host.goal_summary,
			host.notebook_table,host.notebook_restore,host.notebook_remove,host.notebook_name,host.notebook_keep,host.notebook_save,host.notebook_note]:
		fits(control,"Notebook minimum "+str(control.name)+" "+locale)
	await notebook_capture(locale+"-notebook-960",Vector2i(960,640))
	await select_kept(host,"分组 / Grouped")
	var before_remove: Dictionary = host.session.draft()
	var before_remove_rows: Array[Dictionary] = host.session.rows()
	await click(host.notebook_remove)
	check(host.exit_overlay.visible and not host.exit_save.visible,"Removing a kept recipe asks explicitly and offers no exit-save action "+locale)
	await key(KEY_ESCAPE)
	check(not host.exit_overlay.visible and root.gui_get_focus_owner() == host.notebook_remove and host.workspace.kept_rows().size() == 2,
		"Cancel removal keeps the recipe and returns exact focus "+locale)
	await click(host.notebook_remove)
	await click(host.exit_confirm)
	check(host.workspace.kept_rows().size() == 1 and host.session.draft() == before_remove and host.session.rows() == before_remove_rows,
		"Confirmed removal saves only the intended notebook change, preserving draft and evidence "+locale)
	check(not host.workspace.is_dirty() and host.leave_count == 0,"Remove confirmation never exits the lab "+locale)
	var saved_goal: Dictionary = host.session.goal()
	var saved_raw: PackedByteArray = FileAccess.get_file_as_bytes(path)
	host.query_group.value = 7
	await settle()
	var draft_at_failure: Dictionary = host.session.draft()
	var writer_path: String = path+".writer/notebook.json"
	var lease := WriterLease.new(writer_path)
	check(lease.owns(writer_path),"Acquire an actual competing notebook writer fixture "+locale)
	await click(host.notebook_save)
	check(host.workspace.storage_status == "write_failed" and host.workspace.storage_reason == "busy" and host.workspace.is_dirty(),
		"A real competing writer keeps the current proposal visibly unsaved "+locale)
	check(FileAccess.get_file_as_bytes(path) == saved_raw,"Failed UI save preserves original disk bytes "+locale)
	check(host.notebook_recover.visible,"Writer recovery is reachable only for actual contention "+locale)
	await click(host.notebook_recover)
	check(host.workspace.storage_reason == "busy" and lease.owns(writer_path),"Recovery cannot steal a live writer "+locale)
	host.exit_button.grab_focus()
	await click(host.exit_button)
	check(host.exit_overlay.visible and host.exit_save.visible,"Unsaved exit offers Save and exit "+locale)
	await click(host.exit_save)
	check(host.leave_count == 0 and host.exit_overlay.visible and host.session.draft() == draft_at_failure,
		"Save and exit cannot quit after a failed real write "+locale)
	await notebook_capture(locale+"-save-failure-960",Vector2i(960,640))
	lease.release()
	await click(host.exit_save)
	check(host.leave_count == 1 and not host.workspace.is_dirty(),"Save and exit leaves only after the proposal reaches disk "+locale)
	current_scene = null
	host.queue_free()
	await settle()
	host = await open_notebook(path)
	await notebook_tab(host)
	check(host.session.draft() == draft_at_failure and host.session.goal() == saved_goal and host.workspace.kept_rows().size() == 1,
		"A fresh scene/store resumes exact saved draft, goal and retained recipe "+locale)
	check(host.session.rows().is_empty() and not host.session.can_undo(),"Reopening does not fabricate historical runs or cross-session Undo "+locale)
	await select_kept(host,"早回应 / Early response")
	check(host.session.selected_entry().trace_id == first.trace_id,"Reopened recipe produces the same actual Trace on inspection "+locale)
	host.exit_button.grab_focus()
	await click(host.exit_button)
	check(host.exit_overlay.visible and not host.exit_save.visible and host.leave_count == 0,
		"A saved workspace exit explains only transient history and does not claim unsaved drafts "+locale)
	await click(host.exit_cancel)
	current_scene = null
	host.queue_free()
	await settle()

func notebook_modals(host: Control, locale: String) -> void:
	var plan: Dictionary = host.session.draft()
	var goal: Dictionary = host.session.goal()
	host.notebook_name.grab_focus()
	await key(KEY_F8)
	await settle()
	var moments: Node = root.get_node("PlaytestMoments")
	check(moments.panel.visible,"Notebook name editor can open ordinary F8 feedback "+locale)
	await key(KEY_Z,true)
	await key(KEY_ESCAPE)
	await settle()
	check(not moments.panel.visible and root.gui_get_focus_owner() == host.notebook_name and host.session.draft() == plan,
		"Feedback returns exact notebook editor focus and preserves recipe "+locale)
	await key(KEY_F10)
	await settle()
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer),"Notebook name editor can open F10 Settings "+locale)
	await key(KEY_Z,true)
	await key(KEY_ESCAPE)
	await settle()
	check(not is_instance_valid(mode.settings_layer) and root.gui_get_focus_owner() == host.notebook_name and host.session.goal() == goal,
		"Settings returns exact notebook editor focus and preserves goal "+locale)

func notebook_capture(suffix: String, expected: Vector2i) -> void:
	if "--layout-notebook-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == expected,"Notebook raw frame dimensions "+suffix+": "+str(image.get_size()))
	var path: String = "user://layout-notebook-"+suffix+".png"
	check(image.save_png(path) == OK,"Save raw notebook frame "+suffix)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))
