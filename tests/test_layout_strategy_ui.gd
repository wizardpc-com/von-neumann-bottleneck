extends SceneTree
## Real scene/session and viewport input; no fabricated score or campaign fixture.
const Lab = preload("res://experiments/layout_strategy/lab.gd")
const Scene = preload("res://experiments/layout_strategy/lab.tscn")
const Model = preload("res://experiments/layout_strategy/model.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)

func settle() -> void:
	for frame: int in 10: await process_frame

func key(code: Key, command: bool = false, shift: bool = false, unicode: int = 0) -> void:
	for down: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.unicode = unicode
		event.pressed = down
		event.meta_pressed = command and OS.get_name() == "macOS" and code != KEY_Y
		event.ctrl_pressed = command and (OS.get_name() != "macOS" or code == KEY_Y)
		event.shift_pressed = shift
		root.push_input(event,true)
		await process_frame

func click(control: Control) -> void:
	var at: Vector2 = control.get_global_rect().get_center()
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = down
		root.push_input(event,true)
		await process_frame
	await settle()

func choose(control: OptionButton, index: int) -> void:
	control.select(index)
	control.item_selected.emit(index)
	await settle()

func select_history(host: Control, id: int) -> void:
	host.history_table.grab_focus()
	await settle()
	check(root.gui_get_focus_owner() == host.history_table,"Measured history has keyboard focus")
	var count: int = host.history_table.get_root().get_child_count()
	for step: int in count+1:
		var selected: TreeItem = host.history_table.get_selected()
		if selected != null and int(selected.get_metadata(0)) == id:
			check(int(host.session.selected_entry().id) == id,"Viewport history selection inspects measured run #"+str(id))
			return
		var item: TreeItem = host.history_table.get_root().get_first_child()
		var selected_index: int = -1
		var target_index: int = -1
		var index: int = 0
		while item != null:
			if item == selected: selected_index = index
			if int(item.get_metadata(0)) == id: target_index = index
			index += 1
			item = item.get_next()
		await key(KEY_UP if selected_index > target_index else KEY_DOWN)
	check(false,"Viewport selection reaches measured history #%d; selected=%s focus=%s" % [
		id,host.history_table.get_selected(),root.gui_get_focus_owner()])

func fits(control: Control, description: String) -> void:
	var bounds: Rect2 = control.get_global_rect()
	var visible: Rect2 = root.get_visible_rect()
	check(control.is_visible_in_tree() and visible.grow(1).encloses(bounds),
		description+" fits actual viewport "+str(visible)+"; control "+str(bounds))

func resize_viewport(dimensions: Vector2i) -> void:
	var graphical: bool = DisplayServer.get_name() != "headless"
	root.content_scale_size = dimensions
	# macOS may finish its fullscreen transition after a size assignment.
	# Check the actual image too: texture metadata can precede the native resize.
	var stable_frames: int = 0
	for attempt: int in 40:
		if graphical: root.mode = Window.MODE_WINDOWED
		root.size = dimensions
		await create_timer(0.05).timeout
		var ready: bool = root.size == dimensions
		if graphical:
			await RenderingServer.frame_post_draw
			ready = ready and root.mode == Window.MODE_WINDOWED \
				and root.get_texture().get_image().get_size() == dimensions
		stable_frames = stable_frames+1 if ready else 0
		if stable_frames >= 4: break
	await settle()
	check(root.size == dimensions and stable_frames >= 4,"Root viewport reaches requested size "+str(dimensions))
	if graphical:
		check(root.mode == Window.MODE_WINDOWED and root.get_texture().get_image().get_size() == dimensions,
			"Native render surface reaches requested size "+str(dimensions))

func capture(suffix: String) -> void:
	if "--layout-strategy-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var path: String = "user://layout-strategy-"+suffix+".png"
	var image: Image = root.get_texture().get_image()
	var expected: Vector2i = Vector2i(960,640) if suffix.ends_with("-960") else Vector2i(1280,720)
	check(image.get_size() == expected,"Raw frame dimensions "+suffix+": "+str(image.get_size()))
	check(image.save_png(path) == OK,"Save raw layout strategy frame "+suffix)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func protected_files() -> Dictionary:
	var result: Dictionary = {}
	var save: Node = root.get_node("GlobalSave")
	var paths: Array[String] = [
		str(save.storage_path),str(save.workbench_storage_path),
		"user://layout_challenges_v1.json",str(root.get_node("PersonalRecords").storage_path),
	]
	for path: String in paths:
		result[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	return result

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use scripts/verify-project.py with an isolated QA profile.")
		quit(1)
		return
	check(not Lab.isolated_profile("/tmp/VonNeumannBottleneck") and not Lab.isolated_profile("/tmp/notVonNeumannBottleneckChecks/a"),
		"Ordinary and lookalike profile paths are rejected")
	check(Lab.isolated_profile("C:\\Users\\qa\\AppData\\Roaming\\VonNeumannBottleneckChecks\\lab"),
		"QA guard accepts the corresponding Windows path")
	await settle()
	var state: Node = root.get_node("LayoutChapter")
	var game_before: Dictionary = state.game_snapshot().duplicate(true)
	var test_before: Dictionary = {
		"drafts":state.test_drafts.duplicate(true),"named":state.test_named.duplicate(true),
		"solutions":state.test_solutions.duplicate(true),"bonuses":state.test_bonuses.duplicate(true),
	}
	var files_before: Dictionary = protected_files()
	var mode: StringName = root.get_node("GameMode").current_mode
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await exercise(locale)
	check(state.game_snapshot() == game_before,"Standalone lab preserves all official Game layout state")
	check(state.test_drafts == test_before.drafts and state.test_named == test_before.named and state.test_solutions == test_before.solutions and state.test_bonuses == test_before.bonuses,
		"Standalone lab preserves all official Test layout state")
	check(root.get_node("GameMode").current_mode == mode,"Experiment never changes Game/Test mode")
	check(protected_files() == files_before,"Experiment UI never writes official saves, challenge targets or personal results")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy UI %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func exercise(locale: String) -> void:
	var auto_quit_before: bool = auto_accept_quit
	var host: Control = Scene.instantiate()
	host.notebook_path = "user://layout-strategy-ui-%s-%d/notebook.json" % [locale,Time.get_ticks_usec()]
	root.add_child(host)
	current_scene = host
	await settle()
	await resize_viewport(Vector2i(1280,720))
	var session_id: int = host.session.get_instance_id()
	var starter: Dictionary = Model.starter_plan()
	check(host.session.draft() == starter and host.session.rows().is_empty(),"Fresh scene starts source-only without injected optimized results "+locale)
	check(not auto_accept_quit and host.is_in_group("candidate_quit_owners"),"Scene owns OS-close protection "+locale)
	check(root.min_size == Vector2i(960,640),"Scene offers its declared minimum window "+locale)
	check(host.query_group.editable and not host.record_tile.editable,"A single monotone query has no ineffective tile control "+locale)
	check(host.field_buttons.all(func(button: CheckBox) -> bool: return button.disabled) and host.destination.disabled,
		"Inactive copy choices are visibly unavailable "+locale)
	check(host.public_detail.text.contains("Q8") and host.public_detail.text.contains("160") and host.public_detail.text.contains(Model.MODEL_VERSION),
		"Public workload exposes jobs, copy budget and independent model "+locale)
	await click(host.run_button)
	var original: Dictionary = host.session.selected_entry()
	var first_id: int = int(original.id)
	check(original.correct and original.metrics.first_request_cycles == 307 and original.metrics.total_cycles == 2456,
		"Actual Run button measures the source-only starter "+locale)
	await click(host.baseline_button)
	check(host.session.baseline_id() == first_id,"Comparison is pinned explicitly "+locale)
	host.query_group.value = 8
	host.record_tile.value = 1
	await settle()
	var grouped: Dictionary = host.session.draft()
	check(grouped.query_group == 8 and grouped.record_tile == 1 and host.record_tile.editable,"Independent grouping and tiling edit the real draft "+locale)
	check(host.session.rows().size() == 1 and host.session.is_stale() and host.measured_source.text.contains(str(first_id)),
		"Editing keeps old metrics visibly attached to their historical run "+locale)
	await click(host.run_button)
	var measured: Dictionary = host.session.selected_entry()
	var second_id: int = int(measured.id)
	check(measured.correct and measured.metrics.first_request_cycles == 531 and measured.metrics.total_cycles == 552,
		"Second Run measures the real first-response versus total-work tradeoff "+locale)
	check(host.session.comparison().kind == "tradeoff" and host.comparison_label.text.contains("+224") and host.comparison_label.text.contains("-1904"),
		"Comparison presents signed independent metrics, not a weighted score "+locale)
	await select_history(host,first_id)
	check(host.session.draft() == grouped and host.session.is_stale(),"Inspecting a row preserves the current draft "+locale)
	await click(host.restore_button)
	check(host.session.draft() == starter,"Restore button applies the inspected recipe "+locale)
	host.run_button.grab_focus()
	await key(KEY_Z,true)
	check(host.session.draft() == grouped and host.session.rows().size() == 2,"One keyboard Undo restores the exact pre-restore draft without inventing a run "+locale)
	await key(KEY_Z,true,true)
	check(host.session.draft() == starter,"Keyboard Redo reapplies the recipe restore "+locale)
	await key(KEY_Z,true)
	await settle()
	var spin_text: LineEdit = host.query_group.get_line_edit()
	spin_text.grab_focus()
	await settle()
	check(root.gui_get_focus_owner() == spin_text and spin_text.editable,"Numeric text has editable keyboard focus "+locale)
	spin_text.select_all()
	await key(KEY_7,false,false,55)
	var typed: String = spin_text.text
	await key(KEY_Z,true)
	check(typed.contains("7") and spin_text.text != typed and host.session.draft() == grouped,
		"SpinBox text owns its text Undo and does not undo the recipe %s; typed=%s after=%s value=%s draft=%s expected=%s" % [
			locale,typed,spin_text.text,host.query_group.value,host.session.draft(),grouped])
	host.run_button.grab_focus()
	await settle()
	# Restore the intended grouped draft if SpinBox committed its text on blur.
	if host.session.draft() != grouped:
		host.session.edit(grouped)
		host.refresh()
	await select_history(host,second_id)
	host.tabs.current_tab = 1
	await settle()
	check(host.event_table.get_root().get_child_count() == 16,"Response view contains actual admissions and responses for eight jobs "+locale)
	var response: TreeItem = host.event_table.get_root().get_first_child()
	while response != null:
		var event: Dictionary = host.session.selected_entry().events[int(response.get_metadata(0))]
		if event.kind == "response": break
		response = response.get_next()
	check(response != null,"Actual model response is inspectable "+locale)
	if response != null:
		response.select(0)
		host._event_selected()
		check(host.event_detail.text.contains("531") and host.event_detail.text.contains(str(measured.outputs[0])),
			"Selected response exposes completion cycle and real output "+locale)
	await choose(host.event_filter,1)
	check(host.event_table.get_root().get_child_count() > 0 and host.event_detail.text.contains("MEMORY"),
		"Memory filter reads authoritative transfer events "+locale)
	await capture(locale+"-evidence-1280")
	var batch_rows: Array[Dictionary] = host.session.rows()
	await choose(host.workload_choice,1)
	check(host.session.task_id == "scan_serial" and host.session.draft() == starter and host.session.rows().is_empty(),
		"Serial workload begins with a separate draft and history "+locale)
	check(not host.query_group.editable and not host.record_tile.editable,"Serial request boundary visibly fixes one active query "+locale)
	host.tabs.current_tab = 0
	await click(host.run_button)
	var serial_baseline: int = int(host.session.selected_entry().id)
	await click(host.baseline_button)
	await choose(host.copy_mode,1)
	check(host.session.draft().copy_mode == "full" and not host.field_buttons[0].disabled and host.destination.disabled,
		"Copy fields become active while a one-field destination order stays ineffective "+locale)
	await click(host.run_button)
	var copied: Dictionary = host.session.selected_entry()
	check(copied.correct and copied.metrics.first_request_cycles == 557 and copied.metrics.total_cycles == 1362 and copied.metrics.peak_extra_bytes == 80,
		"Retained physical copy measures actual preparation, responses and scratch "+locale)
	check(host.session.comparison().kind == "tradeoff" and host.session.baseline_id() == serial_baseline,
		"Serial comparison retains its own measured baseline "+locale)
	await click(host.field_buttons[3])
	check(not host.destination.disabled,"Two copied fields make destination layout editable "+locale)
	await choose(host.destination,1)
	await click(host.field_buttons[1])
	await click(host.run_button)
	var failed: Dictionary = host.session.selected_entry()
	check(not failed.correct and failed.metrics.error == "space_limit" and failed.metrics.first_request_cycles == -1,
		"Too-large copies retain a real failed run with unfinished response "+locale)
	check(host.baseline_button.disabled and host.session.comparison().is_empty(),"Failed partial run cannot become or beat a comparison "+locale)
	var failed_row: TreeItem = host.history_table.get_selected()
	check(failed_row != null and failed_row.get_text(1) == "—","An unfinished first response is never shown as zero "+locale)
	var copy_choices: Dictionary = host.session.draft()
	await choose(host.copy_mode,0)
	check(host.session.draft().copy_fields == copy_choices.copy_fields and host.session.draft().recipe == copy_choices.recipe,
		"Disabling copy preserves dormant field and destination choices "+locale)
	await choose(host.workload_choice,0)
	check(host.session.draft() == grouped and host.session.rows() == batch_rows and host.session.baseline_id() == first_id,
		"Returning to the batch preserves its draft, measured rows and baseline "+locale)
	var draft_before_locale: Dictionary = host.session.draft()
	var rows_before_locale: Array[Dictionary] = host.session.rows()
	host.language_button.grab_focus()
	await click(host.language_button)
	check(host.session.get_instance_id() == session_id and host.session.draft() == draft_before_locale and host.session.rows() == rows_before_locale,
		"Language button rebuilds presentation in place without losing work "+locale)
	check(root.gui_get_focus_owner() == host.language_button,"Language rebuild restores its corresponding control focus "+locale)
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()
	await modal_inputs(host,locale)
	await exit_settings_inputs(host,locale)
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()
	host.tabs.current_tab = 0
	await settle()
	for control: Control in [host.run_button,host.undo_button,host.redo_button,host.language_button,host.settings_button,host.exit_button,host.history_table,host.restore_button,host.baseline_button,host.comparison_label]:
		fits(control,"1280 "+str(control.name)+" "+locale)
	await capture(locale+"-compare-1280")
	await resize_viewport(Vector2i(960,640))
	for control: Control in [host.run_button,host.undo_button,host.redo_button,host.language_button,host.settings_button,host.exit_button,host.workload_choice,host.query_group,host.record_tile,host.copy_mode,host.destination,host.copy_note,host.status,host.history_table,host.restore_button,host.baseline_button,host.comparison_label]:
		fits(control,"Minimum "+str(control.name)+" "+locale)
	for control: CheckBox in host.field_buttons: fits(control,"Minimum field choice "+locale)
	await capture(locale+"-compare-960")
	host.tabs.current_tab = 1
	await settle()
	for control: Control in [host.event_source,host.event_filter,host.event_table,host.event_detail]:
		fits(control,"Minimum evidence "+str(control.name)+" "+locale)
	await capture(locale+"-evidence-960")
	host.tabs.current_tab = 2
	await settle()
	fits(host.public_detail,"Minimum public workload "+locale)
	await capture(locale+"-public-960")
	host.exit_button.grab_focus()
	await click(host.exit_button)
	check(host.exit_overlay.visible and root.gui_get_focus_owner() == host.exit_cancel,
		"Exit protects existing work and initially focuses Keep exploring "+locale)
	var before_guard: Dictionary = host.session.draft()
	await key(KEY_Z,true)
	check(host.session.draft() == before_guard,"Exit guard blocks underlying Undo "+locale)
	await key(KEY_F8)
	await settle()
	check(root.get_node("PlaytestMoments").panel.visible and host.exit_overlay.visible,"F8 opens above the leave guard "+locale)
	await key(KEY_ESCAPE)
	await settle()
	check(not root.get_node("PlaytestMoments").panel.visible and host.exit_overlay.visible,
		"First Escape closes feedback and leaves the quit decision intact "+locale)
	await key(KEY_ESCAPE)
	await settle()
	check(not host.exit_overlay.visible and root.gui_get_focus_owner() == host.exit_button and host.session.draft() == before_guard,
		"Cancel returns to the exact Exit focus and preserves work "+locale)
	host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await settle()
	check(host.exit_overlay.visible,"OS-close notification uses the same unsaved-session guard "+locale)
	for control: Control in [host.exit_question,host.exit_cancel,host.exit_save,host.exit_confirm]:
		fits(control,"Minimum quit guard "+locale)
	await capture(locale+"-quit-960")
	await click(host.exit_cancel)
	check(not host.exit_overlay.visible and host.session.get_instance_id() == session_id,"OS-close cancellation returns to the same live session "+locale)
	current_scene = null
	host.queue_free()
	await settle()
	check(auto_accept_quit == auto_quit_before,"Scene releases only its own close guard "+locale)

func modal_inputs(host: Control, locale: String) -> void:
	host.run_button.grab_focus()
	var plan: Dictionary = host.session.draft()
	var rows: Array[Dictionary] = host.session.rows()
	await key(KEY_F10)
	await settle()
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer),"F10 opens existing Settings "+locale)
	if is_instance_valid(mode.settings_layer):
		var resume: Button = mode.settings_layer.find_child("OptionsResumeButton",true,false)
		resume.grab_focus()
		await key(KEY_Z,true)
		await key(KEY_Y,true)
		check(host.session.draft() == plan and host.session.rows() == rows,"Settings blocks workbench Undo and Redo "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(not is_instance_valid(mode.settings_layer) and root.gui_get_focus_owner() == host.run_button,
			"Settings Escape closes only Settings and restores exact focus "+locale)
	await key(KEY_F10)
	await settle()
	if is_instance_valid(mode.settings_layer):
		var choice: OptionButton = mode.settings_layer.find_child("LanguageChoice",true,false)
		choice.select(1 if locale == "zh_CN" else 0)
		choice.item_selected.emit(choice.selected)
		await settle()
		check(current_scene == host and host.session.draft() == plan and host.session.rows() == rows,
			"Real Settings language route retains the active experiment "+locale)
		check(is_instance_valid(mode.settings_layer),"Settings reopens after in-place translation "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(root.gui_get_focus_owner() == host.run_button,"Settings language route restores the corresponding workbench focus "+locale)
	host.history_table.grab_focus()
	var previous: Control = root.gui_get_focus_owner()
	await key(KEY_F8)
	await settle()
	var moments: Node = root.get_node("PlaytestMoments")
	check(moments.panel.visible,"F8 opens the existing ordinary feedback surface "+locale)
	if moments.panel.visible:
		await key(KEY_Z,true)
		check(host.session.draft() == plan and host.session.rows() == rows,"Feedback focus cannot undo the recipe "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(not moments.panel.visible and root.gui_get_focus_owner() == previous and not host.exit_overlay.visible,
			"Feedback Escape returns exact focus without requesting departure "+locale)

func exit_settings_inputs(host: Control, locale: String) -> void:
	var plan: Dictionary = host.session.draft()
	var rows: Array[Dictionary] = host.session.rows()
	var session_id: int = host.session.get_instance_id()
	host.query_group.get_line_edit().grab_focus()
	host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	await settle()
	check(host.exit_overlay.visible and root.gui_get_focus_owner() == host.exit_cancel,
		"OS close protects the focused numeric editor "+locale)
	await key(KEY_F10)
	await settle()
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer),"Settings opens above the exit guard "+locale)
	if is_instance_valid(mode.settings_layer):
		var choice: OptionButton = mode.settings_layer.find_child("LanguageChoice",true,false)
		await choose(choice,1-choice.selected)
		check(is_instance_valid(mode.settings_layer) and host.exit_overlay.visible and current_scene == host,
			"Settings language change preserves both live scene and exit guard "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(not is_instance_valid(mode.settings_layer) and root.gui_get_focus_owner() == host.exit_cancel,
			"Translated Settings returns focus to the visible exit guard "+locale)
		await key(KEY_Z,true)
		check(host.session.draft() == plan and host.session.rows() == rows,"Exit guard after translation blocks underlying Undo "+locale)
		await key(KEY_SPACE)
		await settle()
		check(not host.exit_overlay.visible and root.gui_get_focus_owner() == host.query_group.get_line_edit(),
			"Keyboard cancellation restores the corresponding numeric editor after rebuild "+locale)
		check(host.session.get_instance_id() == session_id and host.session.draft() == plan and host.session.rows() == rows,
			"Exit guard keyboard activation never runs or edits the underlying plan "+locale)
