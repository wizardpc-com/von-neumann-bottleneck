extends "res://tests/test_layout_strategy_ui.gd"
## Real measured comparisons, source-aware event navigation and observation-only UI.
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")

func _run() -> void:
	if not Lab.isolated_profile(OS.get_user_data_dir()):
		push_error("Use an isolated verification profile.")
		quit(1)
		return
	await settle()
	var official: Node = root.get_node("LayoutChapter")
	var game_before: Dictionary = official.game_snapshot().duplicate(true)
	var mode_before: StringName = root.get_node("GameMode").current_mode
	var files_before: Dictionary = protected_files()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await explanation_exercise(locale)
	check(official.game_snapshot() == game_before,"Comparison inspection preserves official Game layout state")
	check(root.get_node("GameMode").current_mode == mode_before,"Comparison inspection never changes Game/Test mode")
	check(protected_files() == files_before,"Comparison inspection preserves official files and result stores")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout explanation UI %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func observation(host: Control) -> Dictionary:
	var proposal: Dictionary = host.workspace.snapshot()
	var disk: Dictionary = {}
	for path: String in [host.notebook_path,host.challenge_path,host.legacy_notebook_path,host.legacy_challenge_path]:
		disk[path] = FileAccess.get_file_as_bytes(path) if FileAccess.file_exists(path) else null
	return {
		"task":host.session.task_id,"states":host.session._states.duplicate(true),
		"next_id":host.session._next_id,"proposal":proposal,"committed":host.workspace._committed.duplicate(true),
		"dirty":host.workspace.is_dirty(),"targets":host.challenges._targets.duplicate(true),
		"target_committed":host.challenges._committed.duplicate(true),"target_dirty":host.challenges.is_dirty(),
		"notebook_status":host.workspace.storage_status,"challenge_status":host.challenges.storage_status,
		"disk":disk,
	}

func explanation_item(host: Control, kind: String, identity: Variant, metric: String) -> TreeItem:
	var item: TreeItem = host.explanation_table.get_root().get_first_child()
	while item != null:
		var metadata: Dictionary = item.get_metadata(0)
		var matches: bool = metadata.get("kind","") == kind and metadata.get("metric","") == metric
		if matches and (metadata.get("key","") == identity if kind == "phase" else metadata.get("id",-1) == identity):
			return item
		item = item.get_next()
	return null

func pick_explanation(host: Control, kind: String, identity: Variant, metric: String) -> void:
	host.explanation_table.grab_focus()
	await settle()
	var wanted: TreeItem = explanation_item(host,kind,identity,metric)
	check(wanted != null,"Measured explanation row exists: "+str(identity)+"/"+metric)
	if wanted == null: return
	var limit: int = host.explanation_table.get_root().get_child_count()+1
	for step: int in limit:
		if host.explanation_table.get_selected() == wanted:
			check(host._explanation_scope == wanted.get_metadata(0),"Keyboard row choice binds the actual event scope")
			return
		var item: TreeItem = host.explanation_table.get_root().get_first_child()
		var selected_index: int = -1
		var wanted_index: int = -1
		var index: int = 0
		while item != null:
			if item == host.explanation_table.get_selected(): selected_index = index
			if item == wanted: wanted_index = index
			index += 1
			item = item.get_next()
		await key(KEY_UP if selected_index > wanted_index else KEY_DOWN)
	check(false,"Keyboard reaches explanation "+str(identity)+"/"+metric)

func check_row(host: Control, kind: String, identity: Variant, metric: String, a: int, b: int, description: String) -> void:
	var item: TreeItem = explanation_item(host,kind,identity,metric)
	check(item != null and item.get_text(1) == str(a) and item.get_text(2) == str(b)
		and item.get_text(3) == (("+" if a-b > 0 else "")+str(a-b)),description)

func explanation_capture(suffix: String, dimensions: Vector2i) -> void:
	if "--layout-explanation-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	check(image.get_size() == dimensions,"Explanation raw frame size "+suffix+": "+str(image.get_size()))
	var path: String = "user://layout-explanation-"+suffix+".png"
	check(image.save_png(path) == OK,"Save raw comparison frame "+suffix)
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func check_explanation_bounds(host: Control, suffix: String) -> void:
	for control: Control in [host.evidence_mode,host.explanation_heading,host.explanation_plans,
		host.explanation_context,host.explanation_lens,host.explanation_table,host.explanation_note,
		host.inspect_selected,host.inspect_baseline]:
		fits(control,suffix+" "+str(control.name))
	check(host.explanation_table.size.y >= 110,"Comparison rows retain a usable scrolling surface "+suffix)

func explanation_exercise(locale: String) -> void:
	var host: Control = Scene.instantiate()
	var prefix: String = "user://layout-explanation-%s-%d/" % [locale,Time.get_ticks_usec()]
	host.notebook_path = prefix+"notebook.json"
	host.challenge_path = prefix+"targets.json"
	host.legacy_notebook_path = prefix+"legacy-notebook.json"
	host.legacy_challenge_path = prefix+"legacy-targets.json"
	root.add_child(host)
	current_scene = host
	await settle()
	await resize_viewport(Vector2i(1280,720))
	check(host.explanation_button.disabled,"No missing baseline can be explained "+locale)
	host.change_task("scan_pair_serial")
	await click(host.run_button)
	var direct: Dictionary = host.session.selected_entry()
	await click(host.baseline_button)
	await choose(host.copy_mode,1)
	await click(host.run_button)
	var copied: Dictionary = host.session.selected_entry()
	check(copied.metrics.total_cycles == 672 and direct.metrics.total_cycles == 614,
		"Fixture uses the real current two-scan measurements "+locale)
	check(host.workspace.keep_selected("Measured copy"),"Explicit fixture keeps a real recipe "+locale)
	var target: Dictionary = Code.starter("scan_pair_serial")
	check(host.challenges.accept(str(target.code),"scan_pair_serial").ok,"Explicit fixture retains a current target "+locale)
	host.session.set_goal({"objective":"traffic","first_limit":600,"copy_limit":80})
	host.refresh()
	check(host.save_workspace(),"Explicit fixture saves the stated comparison goal "+locale)
	var before: Dictionary = observation(host)
	await click(host.explanation_button)
	check(host.tabs.current_tab == 1 and host._explaining and host.explanation_view.visible and not host.raw_view.visible,
		"Direct Compare action opens explanation inside existing Evidence "+locale)
	check(host._explanation.ok and host.explanation_heading.text.contains(str(copied.id))
		and host.explanation_heading.text.contains(str(direct.id)) and host.explanation_heading.text.contains("−"),
		"Both actual run IDs and selected-minus-baseline direction are visible "+locale)
	check(host.explanation_plans.text.contains("Temperature" if locale == "en" else "温度")
		and host.explanation_plans.text.contains("no copy" if locale == "en" else "不复制"),
		"Both measured plans are presented independently from the editor "+locale)
	check(host.explanation_context.text.contains("600") and host.explanation_context.text.contains("80")
		and host.explanation_context.text.contains("RAM"),"Actual goal objective and caps remain visible "+locale)
	check_row(host,"phase","prepare","cycles",442,0,"Preparation cost is real442 versus0 "+locale)
	check_row(host,"phase","query","cycles",228,612,"Query saving is real384 cycles "+locale)
	check_row(host,"phase","total","cycles",672,614,"Stage cycles reconcile to total+58 "+locale)
	check_row(host,"phase","total","ram_bytes",500,544,"Actual RAM difference is−44B "+locale)
	check_row(host,"phase","prepare","payload",68,0,"Copied payload is68B "+locale)
	check_row(host,"phase","prepare","allocation",80,0,"Allocated copy is separately80B "+locale)
	check(observation(host) == before,"Opening and reading costs preserves all gameplay and file state "+locale)
	check_explanation_bounds(host,"1280 "+locale)
	await explanation_capture(locale+"-costs-1280",Vector2i(1280,720))
	await resize_viewport(Vector2i(960,640))
	check_explanation_bounds(host,"960 "+locale)
	await explanation_capture(locale+"-costs-960",Vector2i(960,640))

	await choose(host.explanation_lens,1)
	check_row(host,"phase","total","lookups",51,34,"Cache reads exclude17 writes from the68 requests metric "+locale)
	check_row(host,"phase","total","hits",24,0,"Read hit count is24 "+locale)
	check_row(host,"phase","total","fills",27,34,"Real fills are27 versus34 "+locale)
	check_row(host,"phase","prepare","writes",17,0,"Preparation counts17 actual writes separately from reads "+locale)
	check_row(host,"phase","total","writes",17,0,"Total request accounting keeps17 writes separate from51 reads "+locale)
	check_row(host,"phase","prepare","ram_write_bytes",68,0,"Preparation RAM writes remain separate from allocation "+locale)
	await explanation_capture(locale+"-cache-960",Vector2i(960,640))
	await pick_explanation(host,"phase","query","fills")
	await click(host.inspect_baseline)
	check(host._inspecting_comparison and host._event_entry().id == direct.id
		and host.session.selected_entry().id == copied.id and host.session.baseline_id() == direct.id,
		"Baseline event navigation changes only the inspector source "+locale)
	check(host.event_source.text.contains(str(direct.id)) and host.event_scope.text.contains("Query" if locale == "en" else "查询"),
		"Raw inspector visibly identifies baseline and query scope "+locale)
	await choose(host.event_filter,1)
	var event_item: TreeItem = host.event_table.get_root().get_first_child()
	var saw_zero_transfer: bool = false
	while event_item != null:
		var index: int = int(event_item.get_metadata(0))
		var actual: Dictionary = direct.events[index]
		check(actual.details.stage == "query","Baseline scope preserves actual query event index "+locale)
		var ram: int = int(actual.details.get("bytes",0)) if actual.kind in ["fill","write"] else 0
		check(event_item.get_text(4) == str(ram),"RAM B reports only actual fill/write transfer "+locale)
		if actual.kind == "evict":
			saw_zero_transfer = saw_zero_transfer or ram == 0 and int(actual.details.bytes) == 16
		event_item = event_item.get_next()
	check(saw_zero_transfer,"Clean eviction retains16 event bytes but transfers0 RAM B "+locale)
	for control: Control in [host.event_navigation,host.event_back,host.event_side_choice,
		host.event_scope,host.event_source,host.event_filter,host.event_table,host.event_detail]:
		fits(control,"Baseline original events "+locale)
	await explanation_capture(locale+"-baseline-events-960",Vector2i(960,640))
	await choose(host.event_side_choice,0)
	check(host._event_entry().id == copied.id and host.session.selected_entry().id == copied.id,
		"Changing event side retains selected-run authority "+locale)
	check(observation(host) == before,"Phase/cache filters and both raw sides leave gameplay and disk unchanged "+locale)

	await click(host.event_back)
	await choose(host.explanation_lens,2)
	check_row(host,"job",0,"completion",557,307,"Q1 is the public first request completion "+locale)
	check_row(host,"job",1,"admission",557,307,"Serial Q2 admits after the previous actual response "+locale)
	check_row(host,"job",1,"completion",672,614,"Q2 completion uses real output timing "+locale)
	check_row(host,"job",1,"elapsed",115,307,"Elapsed is completion minus admission "+locale)
	await explanation_capture(locale+"-requests-960",Vector2i(960,640))
	await pick_explanation(host,"job",1,"completion")
	await click(host.inspect_selected)
	await choose(host.event_filter,0)
	check(host.event_table.get_root().get_child_count() == 2,"Q2 request view contains its actual admission and response "+locale)
	var response: TreeItem = host.event_table.get_root().get_first_child()
	while response != null:
		if copied.events[int(response.get_metadata(0))].kind == "response": break
		response = response.get_next()
	check(response != null,"Selected-side actual response remains inspectable "+locale)
	if response != null:
		response.select(0)
		host._event_selected()
		check(host.event_detail.text.contains("672") and host.event_detail.text.contains("363"),
			"Response drill-down exposes original timing and output "+locale)
	await choose(host.event_side_choice,1)
	host.event_side_choice.grab_focus()
	var session_id: int = host.session.get_instance_id()
	root.get_node("Localization").set_locale("en" if locale == "zh_CN" else "zh_CN")
	host.reload_localized_scene()
	await settle()
	check(host._inspecting_comparison and host._event_entry().id == direct.id
		and host.session.get_instance_id() == session_id and observation(host) == before,
		"Locale rebuild preserves the bound baseline inspector and all measured/gameplay state "+locale)
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()
	await explanation_modals(host,locale)
	root.get_node("Localization").set_locale(locale)
	host.reload_localized_scene()
	await settle()
	check(observation(host) == before,"Settings/F8 and translation do not mutate the measured comparison "+locale)

	await click(host.event_back)
	var evidence_before_goal: Dictionary = host._explanation.duplicate(true)
	host.session.set_goal({"objective":"cycles","first_limit":306,"copy_limit":0})
	host.refresh()
	check(host._explanation == evidence_before_goal and host.explanation_context.text.contains("306")
		and host.explanation_context.text.contains("outside" if locale == "en" else "超限"),
		"Goal changes update eligibility context without changing measured accounting "+locale)
	host.session.set_baseline(int(copied.id))
	host._refresh_history()
	check(host._explanation.ok and host._explanation.phases[-1].delta.cycles == 0
		and host.explanation_heading.text.count(str(copied.id)) == 2,
		"Changing baseline rebinds to a truthful same-run zero comparison "+locale)
	host.session.set_baseline(int(direct.id))
	host._refresh_history()
	host.change_task("split_fields_serial")
	check(not host._explanation.get("ok",false) and not host._inspecting_comparison
		and host.explanation_table.get_root().get_child_count() == 0,
		"Condition change clears the previous pair instead of relabeling its totals "+locale)
	host.change_task("scan_pair_serial")
	check(host._explanation.ok and host._explanation.selected.id == copied.id,
		"Returning to a condition restores its own measured pair "+locale)

	# A failed allocation remains visible only as raw evidence, never a zero-cost win.
	var invalid: Dictionary = host.session.draft()
	invalid.copy_fields = [0,1,3]
	host.session.edit(invalid)
	host.refresh()
	await click(host.run_button)
	check(not host.session.selected_entry().correct and host.explanation_button.disabled
		and not host._explanation.get("ok",false),"Failed result cannot receive a completed comparison "+locale)
	await choose(host.evidence_mode,0)
	await choose(host.event_filter,2)
	check(host.raw_view.visible and host.event_table.get_root().get_child_count() > 0,
		"Failed allocation keeps access to its original partial events "+locale)
	await explanation_capture(locale+"-failed-events-960",Vector2i(960,640))

	await pending_number_exercise(host,locale)
	current_scene = null
	host.queue_free()
	await settle()

func explanation_modals(host: Control, locale: String) -> void:
	host.event_table.grab_focus()
	await settle()
	check(root.gui_get_focus_owner() == host.event_table and host.event_table.is_visible_in_tree(),
		"The actual visible event inspector owns keyboard focus "+locale)
	var before: Dictionary = observation(host)
	await key(KEY_F10)
	await settle()
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer),"F10 opens Settings above comparison evidence "+locale)
	if is_instance_valid(mode.settings_layer):
		var resume: Button = mode.settings_layer.find_child("OptionsResumeButton",true,false)
		resume.grab_focus()
		await key(KEY_Z,true)
		await key(KEY_Y,true)
		check(observation(host) == before,"Settings blocks underlying comparison edits "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(not is_instance_valid(mode.settings_layer) and root.gui_get_focus_owner() == host.event_table,
			"Settings Escape restores the visible original-event inspector "+locale)
	await key(KEY_F10)
	await settle()
	if is_instance_valid(mode.settings_layer):
		var choice: OptionButton = mode.settings_layer.find_child("LanguageChoice",true,false)
		await choose(choice,1-choice.selected)
		check(current_scene == host and is_instance_valid(mode.settings_layer) and observation(host) == before,
			"Settings language rebuild preserves the actual measured pair "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(root.gui_get_focus_owner() == host.event_table,
			"Translated Settings restores the corresponding visible event inspector "+locale)
	await key(KEY_F8)
	await settle()
	var moments: Node = root.get_node("PlaytestMoments")
	check(moments.panel.visible,"F8 opens ordinary feedback above the comparison "+locale)
	if moments.panel.visible:
		await key(KEY_Z,true)
		check(observation(host) == before,"Feedback does not undo the underlying plan "+locale)
		await key(KEY_ESCAPE)
		await settle()
		check(not moments.panel.visible and root.gui_get_focus_owner() == host.event_table and not host.exit_overlay.visible,
			"Feedback Escape returns exact visible-event focus without requesting departure "+locale)

func pending_number_exercise(host: Control, locale: String) -> void:
	host.change_task("scan_batch")
	host.tabs.current_tab = 0
	host.run_current()
	host.set_baseline()
	var grouped: Dictionary = host.session.draft()
	grouped.query_group = 8
	grouped.record_tile = 1
	host.session.edit(grouped)
	host.refresh()
	host.run_current()
	var first: Dictionary = host.session.selected_entry()
	var text: LineEdit = host.query_group.get_line_edit()
	text.grab_focus()
	await settle()
	text.select_all()
	await key(KEY_7,false,false,55)
	var pending: String = text.text
	check(pending == "7" and host.session.draft().query_group == 8,
		"Real key input leaves7 visibly pending over committed group8 "+locale)
	var before: Dictionary = observation(host)
	await click(host.explanation_button)
	check(host.session.draft() == grouped and host.query_group.value == 8
		and host.query_group.get_line_edit().text == pending and host._pending_numeric == host.query_group,
		"Mouse explanation preserves pending numeric text without committing on focus loss %s; value=%s text=%s pending=%s draft=%s expected=%s" % [
			locale,host.query_group.value,host.query_group.get_line_edit().text,
			host._pending_numeric == host.query_group,host.session.draft(),grouped])
	check(observation(host) == before,"Pending-number inspection changes no draft, Undo, history, goal, target or file "+locale)
	await choose(host.explanation_lens,1)
	await pick_explanation(host,"phase","total","hits")
	await click(host.inspect_baseline)
	check(observation(host) == before,"Event browsing also preserves pending editor and underlying state "+locale)
	await click(host.run_button)
	check(host.session.draft().query_group == 7 and host.session.rows().size() == before.states.scan_batch.runs.size()+1
		and host.session.selected_entry().id != first.id,
		"Explicit later Run commits the retained pending number and measures exactly once "+locale)
	var dormant: Dictionary = Model.starter_plan()
	dormant.copy_fields = [1,3]
	dormant.recipe = Recipe.field_major()
	check(not host._plan_text(dormant).contains("Alarm" if locale == "en" else "告警")
		and not host._plan_text(dormant).contains("field-major" if locale == "en" else "字段排列"),
		"Source-only plan descriptions suppress dormant copy settings "+locale)
