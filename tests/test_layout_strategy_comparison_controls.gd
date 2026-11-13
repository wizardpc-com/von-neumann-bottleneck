extends "res://tests/test_layout_strategy_explanation_ui.gd"
## Current comparison controls and uncommitted numbers use real viewport input.
func tab_click(host: Control, index: int) -> void:
	var bar: TabBar = host.tabs.get_tab_bar()
	var at: Vector2 = bar.get_global_transform()*bar.get_tab_rect(index).get_center()
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = at; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event,true); await process_frame
	await settle()

func type_number(control: SpinBox, value: String) -> void:
	await click(control.get_line_edit())
	await key(KEY_A,true)
	for character: String in value: await key(KEY_0+int(character),false,false,character.unicode_at(0))
	await settle()
	check(control.get_line_edit().text == value,"Viewport typing leaves the requested number")

func popup_key(popup: PopupMenu, code: Key) -> void:
	var event := InputEventKey.new()
	event.window_id = popup.get_window_id()
	event.keycode = code; event.physical_keycode = code; event.pressed = true
	Input.parse_input_event(event); await process_frame
	# Enter can dismiss the popup; never send release to a closed window.
	if is_instance_valid(popup) and popup.visible:
		event = InputEventKey.new()
		event.window_id = popup.get_window_id(); event.keycode = code; event.physical_keycode = code
		Input.parse_input_event(event); await process_frame

func choose_objective(control: OptionButton, index: int) -> void:
	var popup: PopupMenu = control.get_popup()
	popup.prefer_native_menu = false
	await click(control)
	check(popup.visible,"Actual objective menu opens")
	if not popup.visible: return
	popup.grab_focus()
	await create_timer(0.2).timeout
	for attempt: int in popup.item_count+1:
		if popup.get_focused_item() == index: break
		await popup_key(popup,KEY_DOWN)
	check(popup.get_focused_item() == index,"Keyboard reaches desired objective")
	await popup_key(popup,KEY_ENTER)
	await settle()

func stable_capture(suffix: String, dimensions: Vector2i) -> void:
	if "--layout-strategy-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 40:
		root.mode = Window.MODE_WINDOWED; root.size = dimensions
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().get_size() == dimensions: stable += 1
		else: stable = 0
		if stable >= 5: break
	check(stable >= 5,"Five consecutive actual pixel frames reach "+str(dimensions))
	await capture(suffix)

func numeric_details(host: Control, control: SpinBox) -> String:
	var pending: Variant = host._pending_numeric
	return " text=%s value=%s name=%s pending=%s bound=%s draft=%s" % [
		control.get_line_edit().text,control.value,control.name,
		str(pending.name) if is_instance_valid(pending) else "null",pending == control,host.session.draft()]

func goal_snapshot(host: Control) -> Dictionary:
	return {"draft":host.session.draft(),"rows":host.session.rows(),"targets":host.challenges._targets.duplicate(true),"next":host.session._next_id}

func controls_exercise(locale: String) -> void:
	var host: Control = Lab.new()
	host.notebook_path = "user://comparison-controls-%s-%d/notebook.json" % [locale,Time.get_ticks_usec()]
	root.add_child(host); current_scene = host
	await settle()
	await resize_viewport(Vector2i(1280,720))
	await click(host.run_button)
	await click(host.baseline_button)
	host.query_group.value = 8
	host.record_tile.value = 1
	await click(host.run_button)
	var before: Dictionary = observation(host)
	await type_number(host.query_group,"7")
	await click(host.explanation_button)
	check(host.query_group.get_line_edit().text == "7" and host.session.draft().query_group == 8,"Explanation preserves an uncommitted number")
	var caret: int = host.query_group.get_line_edit().caret_column
	await click(host.language_button)
	check(host.query_group.get_line_edit().text == "7" and host.query_group.value == 8 and host._pending_numeric == host.query_group,"Language rebuild retains pending numeric text and its new control binding"+numeric_details(host,host.query_group))
	check(host.query_group.get_line_edit().caret_column == caret,"Language rebuild retains pending editor caret")
	check(root.gui_get_focus_owner() == host.language_button,"Language action retains its own focus without stealing it for pending text")
	check(observation(host) == before,"Language does not submit, measure, save or change pending draft state")
	# Two queued presentation rebuilds must not let the first control's restore win.
	host.reload_localized_scene()
	host.reload_localized_scene()
	await settle()
	check(host.query_group.get_line_edit().text == "7" and host._pending_numeric == host.query_group and observation(host) == before,"Repeated rebuilds restore only the live pending editor"+numeric_details(host,host.query_group))
	await click(host.run_button)
	check(host.session.draft().query_group == 7 and host.session.rows().size() == before.states.scan_batch.runs.size()+1,"Run explicitly commits retained number and measures once after language rebuild"+numeric_details(host,host.query_group))
	# API timing boundary, not a claimed user click: Run may precede queued layout restoration.
	host.query_group.value = 8
	await settle()
	await type_number(host.query_group,"7")
	var immediate_runs: int = host.session.rows().size()
	host.reload_localized_scene()
	host.run_current()
	await settle()
	check(host.session.draft().query_group == 7 and host.session.rows().size() == immediate_runs+1 and host._pending_numeric == null and host.query_group.get_line_edit().text == "7","API Run before deferred restore commits once and prevents stale pending replay"+numeric_details(host,host.query_group))
	# Clicking Language while a numeric editor still owns focus is also observation-only.
	await type_number(host.query_group,"6")
	await key(KEY_LEFT,false,true)
	var selected_from: int = host.query_group.get_line_edit().get_selection_from_column()
	var selected_to: int = host.query_group.get_line_edit().get_selection_to_column()
	var direct_before: Dictionary = observation(host)
	await click(host.language_button)
	check(host.query_group.get_line_edit().text == "6" and host.session.draft().query_group == 7 and observation(host) == direct_before,"Direct Language click preserves focused pending input without committing"+numeric_details(host,host.query_group))
	check(host.query_group.get_line_edit().has_selection() and host.query_group.get_line_edit().get_selection_from_column() == selected_from and host.query_group.get_line_edit().get_selection_to_column() == selected_to,"Direct Language click preserves the pending selection")
	await click(host.language_button)
	await click(host.run_button)
	check(host.session.draft().query_group == 6,"Run still commits after direct-language preservation"+numeric_details(host,host.query_group))
	# Restore the requested locale through the same public language control.
	await click(host.language_button)
	await tab_click(host,0)
	check(host.goal_objective.is_visible_in_tree() and host.first_limit.is_visible_in_tree() and host.copy_limit.is_visible_in_tree(),"Compare exposes the single objective and cap controls alongside recent rankings")
	var goal_controls: Array = [host.goal_objective,host.first_cap,host.first_limit,host.copy_cap,host.copy_limit]
	var identities: Array = []
	for control: Control in goal_controls: identities.append(control.get_instance_id())
	if host.goal_objective.is_visible_in_tree():
		var measured_before: Dictionary = goal_snapshot(host)
		await click(host.first_cap)
		await type_number(host.first_limit,"307")
		await key(KEY_ENTER)
		await settle()
		check(host.session.goal().first_limit == 307 and host.session.ranked_rows()[0].metrics.first_request_cycles == 307,"Editing Q1 on Compare immediately ranks the eligible boundary result")
		check(host.history_table.get_root().get_first_child().get_text(5) == "#1","The visible recent ranking refreshes without another Run")
		await choose_objective(host.goal_objective,1)
		check(host.session.goal().objective == "traffic" and host.history_table.get_column_title(5).contains("RAM"),"Keyboard objective choice updates the visible rank heading")
		check(goal_snapshot(host) == measured_before,"Goal edits do not change drafts, measured runs or challenge targets")
		check(host.workspace.is_dirty(),"Changed personal conditions remain explicitly unsaved")
	# A pending limit also survives inspection and language without changing the goal.
	await tab_click(host,3)
	if not host.first_cap.button_pressed: await click(host.first_cap)
	var old_limit: int = int(host.session.goal().first_limit)
	await type_number(host.first_limit,"531")
	await tab_click(host,1)
	var limit_before: Dictionary = observation(host)
	await click(host.language_button)
	check(host.first_limit.get_line_edit().text.contains("531") and int(host.session.goal().first_limit) == old_limit and host._pending_numeric == host.first_limit,"Hidden goal editor survives language after Evidence inspection without committing")
	check(observation(host) == limit_before,"Hidden pending goal preserves session, evidence and file state")
	await click(host.language_button)
	# Public workload is also read-only inspection, including a directly focused goal editor.
	await tab_click(host,3)
	await type_number(host.first_limit,"407")
	var public_before: Dictionary = observation(host)
	var public_runs: int = host.session.rows().size()
	await tab_click(host,2)
	check(host.tabs.current_tab == 2 and not host.first_limit.is_visible_in_tree(),"Public workload hides the goal strip after a direct numeric edit")
	check(host.first_limit.get_line_edit().text == "407" and host._pending_numeric == host.first_limit and observation(host) == public_before,"Direct Public tab browsing retains pending goal text without committing any session or dirty state")
	await click(host.public_detail)
	check(observation(host) == public_before and host.first_limit.get_line_edit().text == "407","Reading public workload leaves pending goal and measurements untouched")
	await click(host.run_button)
	check(host.session.goal().first_limit == 407 and host.session.rows().size() == public_runs+1,"Explicit Run commits the goal retained through Public browsing and measures once")
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(960,640)]:
		await resize_viewport(dimensions)
		for index: int in [0,3]:
			await tab_click(host,index)
			for control: Control in [host.goal_objective,host.first_cap,host.first_limit,host.copy_cap,host.copy_limit,host.run_button]:
				fits(control,"Shared comparison control "+locale+" "+str(dimensions))
			fits(host.history_table if index == 0 else host.notebook_table,"Rank table "+locale+" "+str(dimensions))
			if index == 3: fits(host.notebook_save,"Notebook save remains available")
			await stable_capture(locale+("-compare" if index == 0 else "-notebook")+("-960" if dimensions.x == 960 else "-1280"),dimensions)
	for index: int in [1,2]:
		await tab_click(host,index)
		check(not host.goal_objective.is_visible_in_tree() and not host.first_limit.is_visible_in_tree(),"Evidence and Public hide personal editing controls")
	await tab_click(host,3)
	for index: int in goal_controls.size():
		# Language rebuild replaces the whole UI; switching pages must not.
		goal_controls[index] = [host.goal_objective,host.first_cap,host.first_limit,host.copy_cap,host.copy_limit][index]
		identities[index] = goal_controls[index].get_instance_id()
	await tab_click(host,0)
	for index: int in goal_controls.size(): check(goal_controls[index].get_instance_id() == identities[index] and goal_controls[index].is_visible_in_tree(),"Tab switches reuse the exact same goal controls")
	check(host.interface.find_children("GoalObjective","OptionButton",true,false).size() == 1,"Only one objective control exists")
	host.queue_free(); await settle()

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()): push_error("Use isolated verification profile."); quit(1); return
	await settle()
	var official: Dictionary = root.get_node("LayoutChapter").game_snapshot().duplicate(true)
	var files: Dictionary = protected_files()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await controls_exercise(locale)
	check(root.get_node("LayoutChapter").game_snapshot() == official and protected_files() == files,"Standalone UI preserves official progression and files")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout comparison controls %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
