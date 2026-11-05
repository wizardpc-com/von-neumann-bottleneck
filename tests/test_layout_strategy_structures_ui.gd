extends "res://tests/test_layout_strategy_challenge_ui.gd"
## Added request structures, genuine competing goals and explicit legacy copies.
const Names = preload("res://experiments/layout_strategy/challenge_window.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const LEGACY_FIXTURE: String = "res://tests/fixtures/layout_strategy/legacy-scheduling-v1.json"

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use isolated verification for structural scheduling UI.")
		quit(1)
		return
	await settle()
	var official: Node = root.get_node("LayoutChapter")
	var game: Dictionary = official.game_snapshot().duplicate(true)
	var files: Dictionary = protected_files()
	var mode: StringName = root.get_node("GameMode").current_mode
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await structures_loop(locale)
		await invalid_retained_draft(locale)
		await legacy_copy_loop(locale)
		await protected_legacy_loop(locale)
		await empty_legacy_targets(locale)
	check(official.game_snapshot() == game and protected_files() == files,
		"Structural workload UI preserves official Game state and save/record bytes")
	check(root.get_node("GameMode").current_mode == mode,"Structural workload UI preserves Game/Test mode")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy structures UI %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func metric_vector(entry: Dictionary) -> Array[int]:
	var metrics: Dictionary = entry.metrics
	return [int(metrics.first_request_cycles),int(metrics.total_cycles),
		int(metrics.ram_read_bytes)+int(metrics.ram_write_bytes),int(metrics.peak_extra_bytes)]

func task_state(host: Control) -> Dictionary:
	return host.session._states[host.session.task_id].duplicate(true)

func switch_workload(host: Control, id: String) -> void:
	host.tabs.current_tab = 0
	await choose(host.workload_choice,Model.SCENARIO_IDS.find(id))

func keep_measurement(host: Control, title: String) -> void:
	host.tabs.current_tab = 3
	await settle()
	host.notebook_name.text = title
	host.notebook_name.text_changed.emit(title)
	await click(host.notebook_keep)

func kept_row(host: Control, title: String) -> Dictionary:
	for row: Dictionary in host.workspace.kept_rows():
		if row.name == title: return row
	return {}

func history_rank(host: Control, id: int) -> int:
	for row: Dictionary in host.session.ranked_rows():
		if int(row.id) == id: return int(row.rank)
	return -1

func structures_loop(locale: String) -> void:
	var path: String = "user://structures-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var host: Control = await open_host(path)
	var counts: Array[int] = [8,8,9,9,2,8]
	check(Model.SCENARIO_IDS == ["scan_batch","scan_serial","mixed_batch","mixed_serial","scan_pair_serial","split_fields_serial"],
		"Six workloads retain the exact original prefix and append the two fixed structures "+locale)
	for index: int in Model.SCENARIO_IDS.size():
		var id: String = Model.SCENARIO_IDS[index]
		check(host.workload_choice.get_item_text(index) == Names.workload_text(id,host.english),
			"Selector shares its human workload name with challenge routing: "+id+" "+locale)
		check(host._job_count(Model.scenario(id)) == counts[index],"Expanded repeat count stays correct for "+id+" "+locale)
	await switch_workload(host,"scan_pair_serial")
	check(host.workload_note.text.contains("2") and host.public_detail.text.contains("Q2 ·") and not host.public_detail.text.contains("Q3 ·"),
		"The pair publicly exposes exactly two complete requests "+locale)
	check(not host.query_group.editable and not host.record_tile.editable and host.session.draft().query_group == 1,
		"Valid pair serial scheduling leaves ineffective grouping and tiling inactive "+locale)
	check(host.session.goal() == {"objective":"cycles","first_limit":-1,"copy_limit":-1},
		"A new structural workload does not inject its curated challenge goal "+locale)
	await click(host.run_button)
	var direct: Dictionary = host.session.selected_entry()
	check(direct.correct and direct.outputs == [363,363] and metric_vector(direct) == [307,614,544,0],
		"Pair source-only button run measures exact public output and costs "+locale)
	await click(host.baseline_button)
	await keep_measurement(host,"Direct pair")
	await choose(host.copy_mode,1)
	await click(host.run_button)
	var copied: Dictionary = host.session.selected_entry()
	check(copied.correct and copied.outputs == [363,363] and metric_vector(copied) == [557,672,500,80],
		"Pair copying measures its real slower cycles and lower RAM cost "+locale)
	await keep_measurement(host,"Copied pair")
	await click(host.first_cap)
	host.first_limit.value = 600
	await click(host.copy_cap)
	host.copy_limit.value = 80
	await settle()
	var rows_before_goal: Array[Dictionary] = host.session.rows()
	var pair_draft: Dictionary = host.session.draft()
	check(history_rank(host,int(direct.id)) == 1 and history_rank(host,int(copied.id)) == 2
		and kept_row(host,"Direct pair").rank == 1 and kept_row(host,"Copied pair").rank == 2,
		"Cycles rank the measured direct pair ahead under600/80 limits "+locale)
	await choose(host.goal_objective,1)
	check(history_rank(host,int(copied.id)) == 1 and history_rank(host,int(direct.id)) == 2
		and kept_row(host,"Copied pair").rank == 1 and kept_row(host,"Direct pair").rank == 2,
		"RAM ranks the same copied pair ahead under identical600/80 limits "+locale)
	check(host.session.rows() == rows_before_goal and host.session.draft() == pair_draft,
		"The actual objective reversal changes no recipe or measured evidence "+locale)
	check(host.session.comparison().traffic == -44 and host.session.comparison().cycles == 58
		and host.session.comparison().kind == "tradeoff",
		"The pair exposes independent44-byte saving and58-cycle cost "+locale)
	await click(host.notebook_save)
	host.tabs.current_tab = 0
	await settle()
	for control: Control in [host.workload_choice,host.run_button,host.history_table,host.comparison_label]:
		fits(control,"Structural pair1280 "+str(control.name)+" "+locale)
	await structure_frame(locale+"-pair-1280",Vector2i(1280,720))
	var pair_before_challenge: Dictionary = snapshot(host)
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	check(window.starter_button.visible and window.starter_button.name == "CurrentStarter"
		and window.context.starter_task == "scan_pair_serial",
		"Pair exposes one contextual starter with its exact current task "+locale)
	await popup_activate(window,window.starter_button)
	var pair_starter: Dictionary = Code.starter("scan_pair_serial")
	check(window.code_edit.text == pair_starter.code and not window.accept_button.disabled
		and window._preview.envelope.goal == {"objective":"traffic","first_limit":600,"copy_limit":80},
		"Pair starter previews the authentic source plan under its fixed traffic goal "+locale)
	check(snapshot(host) == pair_before_challenge and not host.challenges.target("scan_pair_serial").active,
		"Preview adds no solution, target, measurement or exploration change "+locale)
	await popup_activate(window,window.accept_button)
	check(host.challenges.target("scan_pair_serial").saved and snapshot(host) == pair_before_challenge
		and host._challenge_verdict.status == "improved" and host._challenge_verdict.delta == -44,
		"Explicit pair acceptance compares the actual copied attempt against the original544-byte target "+locale)
	await popup_activate(window,window.close_button)
	await resize_viewport(Vector2i(960,640))
	host.tabs.current_tab = 3
	await settle()
	for control: Control in [host.workload_choice,host.notebook_table,host.goal_objective,host.first_limit,host.copy_limit,host.notebook_note]:
		fits(control,"Structural pair minimum "+str(control.name)+" "+locale)
	await structure_frame(locale+"-pair-notebook-960",Vector2i(960,640))
	var pair_state: Dictionary = task_state(host)
	var pair_kept: Array[Dictionary] = host.workspace.kept_rows()
	await switch_workload(host,"split_fields_serial")
	check(host.session.rows().is_empty() and not host.session.can_undo() and host.session.goal().first_limit == -1
		and not host.challenges.target("split_fields_serial").active,
		"The phased workload starts independent draft, history, Undo, goals and targets "+locale)
	check(host.public_detail.text.contains("Q4 ·") and host.public_detail.text.contains("Q5 ·")
		and host.public_detail.text.contains("Q8 ·") and not host.public_detail.text.contains("Q9 ·"),
		"The phased workload exposes all eight public jobs "+locale)
	var q4: String = ""
	var q5: String = ""
	for line: String in host.public_detail.text.split("\n"):
		if line.begins_with("Q4 ·"): q4 = line
		if line.begins_with("Q5 ·"): q5 = line
	check(q4.contains("Temperature" if host.english else "温度") and q5.contains("Alarm" if host.english else "告警"),
		"The public phase boundary identifies temperature then alarm "+locale)
	await click(host.run_button)
	check(metric_vector(host.session.selected_entry()) == [307,2456,2176,0]
		and host.session.selected_entry().outputs == [363,363,363,363,8,8,8,8],
		"Phased source-only run preserves ordered outputs and exact costs "+locale)
	await choose(host.copy_mode,1)
	await click(host.run_button)
	check(metric_vector(host.session.selected_entry()) == [557,2130,1748,80],
		"Phased temperature-only copy is an actual measured intermediate strategy "+locale)
	await click(host.field_buttons[3])
	await click(host.run_button)
	var record_copy: Dictionary = host.session.selected_entry()
	check(metric_vector(record_copy) == [791,2044,1560,144] and not host.destination.disabled,
		"Two copied fields measure the record-major cost and enable physical layout "+locale)
	await click(host.baseline_button)
	await choose(host.destination,1)
	await click(host.run_button)
	var field_copy: Dictionary = host.session.selected_entry()
	check(metric_vector(field_copy) == [727,1516,1032,144] and field_copy.plan.recipe == Recipe.field_major(),
		"The physical layout selector genuinely measures field-major phase reuse "+locale)
	check(host.session.comparison().cycles == -528 and host.session.comparison().traffic == -528
		and host.session.comparison().peak == 0 and host.session.comparison().kind == "better",
		"Phased comparison explains actual savings at equal copy allocation "+locale)
	await keep_measurement(host,"Phased fields")
	await click(host.first_cap)
	host.first_limit.value = 800
	await click(host.copy_cap)
	host.copy_limit.value = 144
	await click(host.notebook_save)
	host.tabs.current_tab = 0
	await settle()
	for control: Control in [host.workload_choice,host.run_button,host.history_table,host.destination,host.comparison_label]:
		fits(control,"Phased minimum "+str(control.name)+" "+locale)
	await structure_frame(locale+"-phased-960",Vector2i(960,640))
	var split_before_challenge: Dictionary = snapshot(host)
	await click(host.challenge_button)
	check(window.context.starter_task == "split_fields_serial" and window.starter_button.visible,
		"The reused challenge window now offers only the phased starter "+locale)
	await popup_activate(window,window.starter_button)
	var split_starter: Dictionary = Code.starter("split_fields_serial")
	check(window.code_edit.text == split_starter.code and window._preview.envelope.goal == {"objective":"cycles","first_limit":800,"copy_limit":144},
		"The phased starter has its own immutable800/144 cycle rule "+locale)
	await popup_activate(window,window.accept_button)
	check(snapshot(host) == split_before_challenge and host.challenges.target("split_fields_serial").saved
		and host.challenges.target("scan_pair_serial").code == pair_starter.code,
		"Phased acceptance preserves exploration and the independent pair target "+locale)
	window.size = Vector2i(720,540)
	await settle()
	await import_preview(window,pair_starter.code)
	check(window.accept_button.disabled and window.code_message.text.contains(Names.workload_text("scan_pair_serial",host.english)),
		"A new foreign code identifies its pair workload without automatic switching "+locale)
	await import_preview(window,Code.starter("scan_batch").code)
	check(window.accept_button.disabled and window.code_message.text.contains(Names.workload_text("scan_batch",host.english)),
		"An old foreign code still identifies the unchanged batch workload "+locale)
	await import_preview(window,split_starter.code)
	for control: Control in [window.code_edit,window.code_message,window.accept_button,window.back_button]:
		check(window.get_visible_rect().grow(1).encloses(control.get_global_rect()),
			"New starter minimum popup fits "+str(control.name)+" "+locale)
	await structure_frame(locale+"-phased-starter-720",Vector2i(720,540),window)
	await popup_activate(window,window.back_button)
	await popup_activate(window,window.close_button)
	var split_state: Dictionary = task_state(host)
	await switch_workload(host,"scan_pair_serial")
	check(task_state(host) == pair_state and host.workspace.kept_rows() == pair_kept
		and host.challenges.target("scan_pair_serial").code == pair_starter.code,
		"Returning preserves the pair's exact draft, Undo, history, selection, baseline, goal and kept plans "+locale)
	await switch_workload(host,"mixed_batch")
	check(host.query_group.max_value == 9 and host.query_group.editable,
		"Returning to mixed batch restores its true nine-job numeric bound "+locale)
	await pending_number(host.query_group,"999")
	await key(KEY_ENTER,true)
	check(host.session.rows().size() == 1 and host.session.selected_entry().plan.query_group == 9
		and int(host.query_group.value) == 9,
		"Numeric submission after a workload switch commits the visible bound before exactly one run "+locale)
	await click(host.challenge_button)
	check(not window.starter_button.visible and window.starter_button.focus_mode == Control.FOCUS_NONE,
		"A mixed workload has no misleading starter or hidden starter Tab stop "+locale)
	check(not window.target_label.text.contains("starter" if host.english else "入门"),
		"Mixed-workload guidance does not advertise an unavailable starter "+locale)
	await import_preview(window,pair_starter.code)
	check(window.accept_button.disabled and window.code_message.text.contains(Names.workload_text("scan_pair_serial",host.english))
		and host.session.task_id == "mixed_batch",
		"An old workload routes new foreign codes without adopting or switching "+locale)
	await popup_activate(window,window.back_button)
	await popup_activate(window,window.close_button)
	await switch_workload(host,"scan_pair_serial")
	check(task_state(host) == pair_state and int(host.query_group.value) == 1 and not host.record_tile.editable,
		"Mixed numeric editing cannot bleed into the saved pair state "+locale)
	await switch_workload(host,"split_fields_serial")
	check(task_state(host) == split_state and host.session.selected_entry().trace_id == field_copy.trace_id,
		"The phased workload retains its own selected real Trace and editing context "+locale)
	host.run_button.grab_focus()
	await key(KEY_Z,true)
	check(host.session.draft().recipe == Recipe.record_major() and host.session.selected_entry().trace_id == field_copy.trace_id,
		"Per-task Undo restores phased physical layout without replacing measured evidence "+locale)
	await key(KEY_Z,true,true)
	check(task_state(host) == split_state,"Phased Redo restores the complete prior editing state "+locale)
	await close_structure_host(host)

func write_fixture(path: String, text: String) -> bool:
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return false
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file == null: return false
	file.store_string(text)
	file.close()
	return FileAccess.get_file_as_string(path) == text

func open_legacy_host(path: String) -> Control:
	var host := LeaveProbe.new()
	host.notebook_path = path.path_join("notebook-v2.json")
	host.challenge_path = path.path_join("targets-v2.json")
	host.legacy_notebook_path = path.path_join("notebook-v1.json")
	host.legacy_challenge_path = path.path_join("targets-v1.json")
	root.add_child(host)
	current_scene = host
	await settle()
	await resize_viewport(Vector2i(960,640))
	return host

func invalid_retained_draft(locale: String) -> void:
	var path: String = "user://structures-invalid-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var task: Dictionary = Model.scenario("scan_pair_serial")
	var invalid: Dictionary = Model.starter_plan()
	invalid.query_group = 8
	var checkpoint: Dictionary = {"version":2,"active":task.id,"states":{
		task.id:{"model":Model.MODEL_VERSION,"condition":Model.condition_id(task),"task":task,
			"draft":invalid,"goal":{"objective":"cycles","first_limit":-1,"copy_limit":-1},"kept":[]},
	}}
	var original: String = JSON.stringify(checkpoint,"",true)
	check(write_fixture(path.path_join("notebook.json"),original),"Create retained unfinished pair draft fixture "+locale)
	var host: Control = await open_host(path)
	await resize_viewport(Vector2i(960,640))
	check(host.session.draft().query_group == 8 and int(host.query_group.value) == 8
		and host.query_group.get_line_edit().text == "8" and host.query_group.editable and not host.record_tile.editable,
		"Retained invalid serial group stays exactly visible and repairable, with inactive tiling "+locale)
	check(host.group_note.text.contains("1") and host.group_note.text.contains("retained" if host.english else "保留"),
		"The invalid draft explains the actual one-query serial constraint "+locale)
	await click(host.run_button)
	check(host.session.rows().is_empty() and host.session.draft().query_group == 8
		and int(host.query_group.value) == 8 and host.status.text.contains("Not run" if host.english else "未运行"),
		"Running the retained invalid draft rejects its exact visible input without a fabricated result "+locale)
	await structure_frame(locale+"-invalid-draft-960",Vector2i(960,640))
	await pending_number(host.query_group,"1")
	await key(KEY_ENTER,true)
	check(host.session.rows().size() == 1 and metric_vector(host.session.selected_entry()) == [307,614,544,0]
		and host.session.draft().query_group == 1 and not host.query_group.editable and not host.record_tile.editable,
		"Explicit numeric repair runs the genuine serial plan once and restores inactive controls "+locale)
	host.run_button.grab_focus()
	await key(KEY_Z,true)
	check(host.session.draft().query_group == 8 and int(host.query_group.value) == 8 and host.query_group.editable,
		"Undo truthfully restores the retained invalid value rather than silently normalizing it "+locale)
	await click(host.run_button)
	check(host.session.rows().size() == 1 and FileAccess.get_file_as_string(host.notebook_path) == original,
		"Rejected restored input creates no extra run and never rewrites its saved source "+locale)
	await close_structure_host(host)

func legacy_copy_loop(locale: String) -> void:
	var frozen: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LEGACY_FIXTURE))
	var path: String = "user://structures-copy-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var notebook_text: String = frozen.notebook_v1
	var targets_text: String = frozen.targets_v1
	check(write_fixture(path.path_join("notebook-v1.json"),notebook_text)
		and write_fixture(path.path_join("targets-v1.json"),targets_text),
		"Stage actual unchanged old-runtime notebook and target bytes "+locale)
	var host: Control = await open_legacy_host(path)
	check(host.workspace.origin == "legacy" and host.workspace.copy_pending and host.workspace.is_dirty()
		and not host.workspace.has_saved_workspace() and host.session.task_id == "scan_serial",
		"Old notebook restores its active work as an explicitly unsaved new copy "+locale)
	check(host.challenges.origin == "legacy" and host.challenges.copy_pending and host.challenges.is_dirty()
		and host.challenges.target("scan_serial").active and host.challenges.target("scan_serial").pending
		and not host.challenges.target("scan_serial").saved,
		"Old target is genuinely remeasured and pending until a new file is actually written "+locale)
	check(not FileAccess.file_exists(host.notebook_path) and not FileAccess.file_exists(host.challenge_path),
		"Opening both old records creates no destination payload "+locale)
	check(host.storage_label.text.contains("Earlier" if host.english else "上一版")
		and host.notebook_note.text.contains("separate copy" if host.english else "独立副本"),
		"Notebook status distinguishes loaded earlier records from a fresh or saved workspace "+locale)
	check(host.workspace.kept_rows().size() == 2,"Actual old kept recipes are remeasured in the upgraded Notebook "+locale)
	host.tabs.current_tab = 3
	await settle()
	for control: Control in [host.storage_label,host.notebook_table,host.notebook_note,host.notebook_save]:
		fits(control,"Pending copy minimum "+str(control.name)+" "+locale)
	await structure_frame(locale+"-legacy-copy-960",Vector2i(960,640))
	host.tabs.current_tab = 0
	await settle()
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	check(window.storage_label.text.contains("Earlier" if host.english else "上一版")
		and window.retry_button.visible and window.retry_button.text.contains("copy" if host.english else "副本"),
		"Challenge copy has an explicit save action and truthful loaded-earlier status "+locale)
	await popup_activate(window,window.close_button)
	host.request_quit()
	await settle()
	check(host.exit_overlay.visible and host.exit_save.visible and host.exit_target_retry.visible
		and host.exit_question.text.contains("original" if host.english else "原记录"),
		"Exit separately explains two unsaved copies and preserved originals "+locale)
	for control: Control in [host.exit_question,host.exit_save,host.exit_target_retry,host.exit_confirm]:
		fits(control,"Pending copy exit minimum "+str(control.name)+" "+locale)
	await click(host.exit_save)
	check(host.leave_count == 0 and host.exit_overlay.visible and not host.workspace.copy_pending
		and host.workspace.has_saved_workspace() and host.challenges.copy_pending,
		"Save Notebook creates only its destination and keeps the pending target exit decision "+locale)
	check(FileAccess.file_exists(host.notebook_path) and not FileAccess.file_exists(host.challenge_path),
		"Notebook and target copy commits are actual independent writes "+locale)
	await click(host.exit_target_retry)
	check(host.leave_count == 0 and not host.challenges.copy_pending and not host.challenges.is_dirty()
		and host.challenges.target("scan_serial").saved and FileAccess.file_exists(host.challenge_path),
		"Explicit target save creates its separate file and does not itself exit "+locale)
	check(JSON.parse_string(FileAccess.get_file_as_string(host.notebook_path)).version == 2
		and JSON.parse_string(FileAccess.get_file_as_string(host.challenge_path)).version == 2,
		"Both new payloads declare version2 only after their explicit saves "+locale)
	check(FileAccess.get_file_as_string(host.legacy_notebook_path) == notebook_text
		and FileAccess.get_file_as_string(host.legacy_challenge_path) == targets_text,
		"Both old-runtime payloads remain byte-for-byte intact "+locale)
	await click(host.exit_confirm)
	check(host.leave_count == 1,"A final explicit Exit may leave after both copies are saved "+locale)
	await close_structure_host(host)
	host = await open_legacy_host(path)
	check(host.workspace.origin == "current" and host.challenges.origin == "current"
		and not host.workspace.copy_pending and not host.challenges.copy_pending
		and host.workspace.has_saved_workspace() and host.challenges.target("scan_serial").saved,
		"Reopening reads current v2 copies without proposing another migration "+locale)
	await switch_workload(host,"scan_pair_serial")
	check(host.session.rows().is_empty() and host.session.draft() == Model.starter_plan()
		and host.workspace.kept_rows().is_empty() and not host.challenges.target("scan_pair_serial").active,
		"Legacy restoration leaves new structural conditions fresh "+locale)
	await close_structure_host(host)

func protected_legacy_loop(locale: String) -> void:
	var path: String = "user://structures-protected-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var notebook_text: String = "{\"version\":99,\"active\":\"scan_serial\",\"states\":{}}"
	var targets_text: String = "{\"version\":99,\"targets\":{}}"
	check(write_fixture(path.path_join("notebook-v1.json"),notebook_text)
		and write_fixture(path.path_join("targets-v1.json"),targets_text),"Stage protected earlier sources "+locale)
	var host: Control = await open_legacy_host(path)
	check(host.workspace.storage_status == "read_only" and host.workspace.origin == "legacy"
		and not host.workspace.copy_pending and host.session.task_id == "scan_batch",
		"Protected earlier notebook adopts no partial active state or pending copy "+locale)
	check(host.challenges.storage_status == "read_only" and host.challenges.origin == "legacy"
		and not host.challenges.copy_pending and not host.challenges.target("scan_batch").active,
		"Protected earlier targets are distinct from loaded valid targets "+locale)
	check(host.storage_label.text.contains("protected" if host.english else "保护")
		and host.notebook_note.text.contains("earlier" if host.english else "上一版"),
		"Protected source provenance is visible in Notebook status "+locale)
	await switch_workload(host,"scan_pair_serial")
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	await popup_activate(window,window.starter_button)
	await popup_activate(window,window.accept_button)
	var target: Dictionary = host.challenges.target("scan_pair_serial")
	check(target.active and target.pending and not target.saved
		and host.challenges.storage_status == "read_only" and not window.retry_button.visible,
		"Acceptance remains temporary over a protected old source and offers no futile retry "+locale)
	check(window.storage_label.text.contains("protected" if host.english else "保护")
		and window.storage_label.text.contains("Earlier" if host.english else "上一版")
		and window.storage_label.text.contains("temporary" if host.english else "本次"),
		"Source protection takes priority over temporary target feedback "+locale)
	window.size = Vector2i(720,540)
	await settle()
	check(window.main_scroll.get_global_rect().end.y <= window.size.y,
		"Protected earlier-target message remains within the minimum scroll surface "+locale)
	await structure_frame(locale+"-protected-source-720",Vector2i(720,540),window)
	await popup_activate(window,window.close_button)
	host.request_quit()
	await settle()
	check(host.exit_overlay.visible and not host.exit_target_retry.visible
		and host.exit_question.text.contains("protected" if host.english else "保护"),
		"Protected-copy exit explains protection without a misleading target save "+locale)
	for control: Control in [host.exit_question,host.exit_save,host.exit_confirm,host.exit_cancel]:
		fits(control,"Protected earlier-source exit minimum "+str(control.name)+" "+locale)
	await click(host.exit_save)
	check(host.leave_count == 0 and host.exit_overlay.visible
		and not FileAccess.file_exists(host.notebook_path) and not FileAccess.file_exists(host.challenge_path),
		"Save and exit cannot overwrite protected sources or manufacture destination success "+locale)
	check(FileAccess.get_file_as_string(host.legacy_notebook_path) == notebook_text
		and FileAccess.get_file_as_string(host.legacy_challenge_path) == targets_text,
		"Protected source bytes survive preview, acceptance and exit-save attempts "+locale)
	await click(host.exit_cancel)
	await close_structure_host(host)

func empty_legacy_targets(locale: String) -> void:
	var path: String = "user://structures-empty-copy-ui-%s-%d" % [locale,Time.get_ticks_usec()]
	var original: String = JSON.stringify({"version":1,"targets":{}},"",true)
	check(write_fixture(path.path_join("targets-v1.json"),original),"Stage intentionally empty earlier target map "+locale)
	var host: Control = await open_legacy_host(path)
	check(host.challenges.copy_pending and host.challenges.is_dirty() and not host.challenges.target("scan_batch").pending,
		"An empty earlier map still needs an explicit copy without inventing a pending target "+locale)
	await click(host.challenge_button)
	var window: Window = host.challenge_window
	check(window.retry_button.visible and window.storage_label.text.contains("copy" if host.english else "副本"),
		"Empty-map copy is visibly savable in the challenge window "+locale)
	await popup_activate(window,window.retry_button)
	check(FileAccess.file_exists(host.challenge_path) and not host.challenges.copy_pending
		and JSON.parse_string(FileAccess.get_file_as_string(host.challenge_path)).targets.is_empty()
		and FileAccess.get_file_as_string(host.legacy_challenge_path) == original,
		"Explicit empty-map copy creates a real v2 file while preserving the v1 map "+locale)
	await popup_activate(window,window.close_button)
	await close_structure_host(host)

func structure_frame(suffix: String, expected: Vector2i, window: Window = null) -> void:
	if "--layout-structures-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image() if window == null else window.get_texture().get_image()
	check(image.get_size() == expected,"Structural raw frame dimensions "+suffix+": "+str(image.get_size()))
	var path: String = "user://layout-structures-"+suffix+".png"
	check(image.save_png(path) == OK,"Save structural raw frame "+suffix)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func close_structure_host(host: Control) -> void:
	current_scene = null
	host.queue_free()
	await settle()
