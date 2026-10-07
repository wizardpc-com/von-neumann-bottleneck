extends SceneTree
## Native capture: -- --workbench-capture --capture-size=1280x720 (existing deterministic window path).
## UI/measurement boundary checks in the runner's isolated profile.
var failures: int = 0
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func control(scene: Control,id: String) -> Control: return scene.find_child(id,true,false) as Control
func fit_window() -> void:
	# Autoload display preferences restore geometry deferred. Resize only after
	# the actual scene has entered the tree and that restoration has settled.
	if DisplayServer.get_name() != "headless":
		root.mode = Window.MODE_WINDOWED
		await create_timer(1.0).timeout
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.4).timeout
	await settle()
	check(root.size == Vector2i(1280,720),"Actual root window has minimum-window dimensions: "+str(root.size))
	check(root.get_visible_rect().size.is_equal_approx(Vector2(1280,720)),"Logical viewport has minimum-window dimensions: "+str(root.get_visible_rect()))
	if DisplayServer.get_name() != "headless":
		# macOS may report the compositor's fullscreen surface here despite the
		# root viewport and captured texture being 1280x720. Record it separately;
		# this suite verifies rendered pixels, not native window geometry.
		print("DISPLAY_DIAGNOSTIC: ",DisplayServer.window_get_size(),"; viewport ",root.size)
func bounds(scene: Control) -> void:
	var view: Rect2 = root.get_visible_rect()
	check(scene.get_global_rect().is_equal_approx(view),"Real scene fills the logical viewport: "+str(scene.get_global_rect())+" in "+str(view))
	var surface: Control = control(scene,"PredictionSurface")
	check(surface != null,"Workbench surface exists")
	if surface != null: check(surface.get_global_rect().is_equal_approx(view),"Workbench surface fills the logical viewport: "+str(surface.get_global_rect())+" in "+str(view))
	for id: String in ["Step","Run","Restart","Hint1","Language","Rule","Confidence","Lookahead","Cooldown"]:
		var item: Control = control(scene,id)
		check(item != null,"Core operation exists: "+id)
		if item == null: continue
		check(item.is_visible_in_tree() and view.encloses(item.get_global_rect()),"Core operation remains visible: "+id+" "+str(item.get_global_rect()))
		check(item.size.y >= 42,"Comfortable operation height: "+id)
	for id: String in ["TemporaryBoundary","TaskPurpose","FirstOperation","DraftBoundary","RecordedSource","ObservedHistory","Result","Status"]:
		var item: Label = control(scene,id) as Label
		check(item != null,"Explanation label has a unique ID: "+id)
		if item == null or not item.is_visible_in_tree(): continue
		var reading: Control = item.get_parent() as ScrollContainer
		if reading == null: reading = item
		check(view.encloses(reading.get_global_rect()),"Visible reading area stays in window: "+id+" "+str(reading.get_global_rect()))
		check(item.get_theme_font_size("font_size") >= 14,"Readable explanation size: "+id)
func progress_fits(scene: Control,context: String) -> void:
	var label := control(scene,"Status") as Label
	var reading := control(scene,"StatusScroll") as ScrollContainer
	check(label != null and reading != null,context+": progress reading area exists")
	if label == null or reading == null: return
	check(label.text == scene.call("progress_text"),context+": geometry checks the actual progress rather than a clue")
	check(reading.get_global_rect().encloses(label.get_global_rect()),context+": every progress line is visible: "+str(label.get_global_rect())+" in "+str(reading.get_global_rect()))
	check(label.get_minimum_size().y <= reading.size.y,context+": full progress text fits without clipping")
	check(reading.get_v_scroll_bar().max_value <= reading.get_v_scroll_bar().page+1.0,context+": progress needs no scrolling")
func capture(name: String) -> void:
	if not "--workbench-capture" in OS.get_cmdline_user_args(): return
	check(DisplayServer.get_name() != "headless","Workbench captures require a rendering display")
	if DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	await process_frame
	var picture: Image = root.get_texture().get_image()
	check(picture != null,"Rendered workbench image is available: "+name)
	if picture == null: return
	check(picture.get_size() == Vector2i(1280,720),"Capture has actual minimum-window dimensions: "+name+" "+str(picture.get_size()))
	if picture.get_size() != Vector2i(1280,720): return
	var folder: String = "res://.godot/workbench-captures"
	check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder)) == OK,"Capture directory available")
	check(picture.save_png(folder.path_join(name+".png")) == OK,"Rendered workbench capture saved")
func run() -> void:
	var localization: Node = root.get_node("Localization")
	var original_locale: String = localization.current_locale()
	var nav: Node = root.get_node("TaskNavigation")
	var original_pending: String = nav.pending; var original_selected: String = nav.selected; var original_from_tree: bool = nav.from_tree
	var original_recent: String = nav.last_visited_task
	var original_auto_quit: bool = auto_accept_quit
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot(); before.erase("saved_at_utc")
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale); nav.pending = ""; nav.from_tree = true
		var packed: PackedScene = load("res://experiments/prediction/lab.tscn")
		var scene: Control = packed.instantiate(); scene.candidate_journey = true
		root.add_child(scene); await settle(); await fit_window()
		var complete_structure: bool = true
		for id: String in ["TemporaryBoundary","TaskPurpose","FirstOperation","DraftBoundary","RecordedSource","ObservedHistory","Result","Status"]:
			var item: Label = control(scene,id) as Label
			check(item != null,"Expected label is unique rather than a colliding tab title: "+id)
			complete_structure = complete_structure and item != null
		if not complete_structure:
			scene.queue_free(); await settle(); quit(1); return
		var step := control(scene,"Step") as Button
		step.grab_focus(); await settle()
		check(step.has_focus() and step.get_theme_color("font_focus_color") == Color("071823"),"Focused primary retains legible dark text")
		check((control(scene,"Rule").get_theme_stylebox("normal") as StyleBoxFlat).bg_color == Color("1b2b37"),"Policy controls share the instrument palette")
		check((control(scene,"Events").get_theme_stylebox("panel") as StyleBoxFlat).bg_color == Color("0b1722"),"Trace tree uses the instrument palette")
		check(control(scene,"TemporaryBoundary").get("text").contains("不保留") if locale == "zh_CN" else control(scene,"TemporaryBoundary").get("text").contains("discarded"),"Temporary lifetime is stated on the workbench")
		check(scene.get("history").is_empty() and scene.get("active_trace") == null,"Opening the presentation creates no measured evidence")
		bounds(scene); await capture("prediction-"+locale+"-initial")
		(control(scene,"Hint1") as Button).pressed.emit(); await settle()
		check((control(scene,"Status") as Label).text == scene.call("hint_text"),"Requested clue is retained in full")
		bounds(scene); await capture("prediction-"+locale+"-hint")
		scene.call("step_current"); await settle()
		var observation: Dictionary = scene.call("public_observation")
		check(observation.observed_addresses == [0] and observation.revealed_decisions.size() == 1 and observation.completed_runs.is_empty(),"Step exposes only the observed prefix, not a completed record")
		check(not (control(scene,"Result") as Label).text.contains("150"),"A prefix does not disclose the final baseline cost")
		var prefix_signature: String = scene.get("active_trace").canonical_signature()
		scene.call("change_task",scene.get("task")); await settle()
		check(scene.get("revealed") == 1 and scene.get("active_trace").canonical_signature() == prefix_signature,"Re-selecting the current investigation never discards its observed prefix")
		check((control(scene,"Task0") as Button).disabled,"Current investigation has no destructive duplicate selection")
		bounds(scene); await capture("prediction-"+locale+"-step")
		scene.call("run_current"); await settle()
		check(scene.get("history").size() == 1 and int(scene.get("history")[0].trace.metrics.total_cycles) == 150,"Completed default run displays the actual known baseline")
		var record_signature: String = scene.get("history")[0].trace.canonical_signature()
		var recorded_policy: Dictionary = scene.get("history")[0].policy.duplicate(true)
		bounds(scene); await capture("prediction-"+locale+"-completed")
		var evidence_tabs := control(scene,"PredictionEvidenceTabs") as TabContainer
		evidence_tabs.current_tab = 1; await settle()
		check(root.get_visible_rect().encloses(control(scene,"Events").get_global_rect()) and root.get_visible_rect().encloses(control(scene,"TraceDetails").get_global_rect()),"Trace and raw detail remain reachable on their evidence page")
		await capture("prediction-"+locale+"-events")
		evidence_tabs.current_tab = 2; await settle()
		check(root.get_visible_rect().encloses(control(scene,"History").get_global_rect()),"Recorded history remains reachable in the minimum window")
		check((control(scene,"History") as ItemList).item_count == 1,"The history page exposes the actual completed record")
		await capture("prediction-"+locale+"-history")
		(control(scene,"Rule") as OptionButton).select(1); scene.call("edit_policy"); await settle()
		check(scene.get("active_trace") == null and scene.get("revealed") == 0 and scene.get("history").size() == 1,"Draft editing resets the current prefix and retains measured history")
		check(scene.get("history")[0].trace.canonical_signature() == record_signature and scene.get("history")[0].policy == recorded_policy,"Draft editing cannot rewrite the recorded policy or trace")
		scene.call("select_run",0); await settle()
		check((control(scene,"RecordedSource") as Label).text.contains("不同") if locale == "zh_CN" else (control(scene,"RecordedSource") as Label).text.contains("differs"),"Older record is explicitly distinguished from the current draft")
		scene.call("request_hub"); await settle()
		var guard := scene.get_node("LeavePredictionDialog") as ConfirmationDialog
		check(guard.visible,"Return still invokes the existing temporary-discard guard")
		guard.hide(); guard.canceled.emit(); await settle()
		check(not scene.get("leave_to_hub") and scene.get("history").size() == 1 and (control(scene,"Step") as Button).has_focus(),"Cancel keeps exploration and restores the main operation focus")
		for index: int in [1,2]:
			scene.call("change_task",index); await settle()
			var purpose: String = (control(scene,"TaskPurpose") as Label).text
			var expected: String = ("基线" if locale == "zh_CN" else "baseline") if index == 1 else ("至少两种" if locale == "zh_CN" else "at least two")
			check(scene.get("task") == index and purpose.contains(expected),"Current investigation retains its explicit objective")
			bounds(scene)
			if index == 2:
				progress_fits(scene,locale+" Investigation3 initial")
				await capture("prediction-"+locale+"-task3-progress")
			scene.call("run_current"); await settle(); bounds(scene)
			(control(scene,"Hint1") as Button).pressed.emit(); await settle(); bounds(scene)
			check((control(scene,"Status") as Label).text == scene.call("hint_text"),"Later investigation retains the complete requested clue")
			await capture("prediction-"+locale+"-task"+str(index+1)+"-hint")
			var rule_tabs := control(scene,"PredictionRuleTabs") as TabContainer
			rule_tabs.current_tab = 1; await settle()
			check((control(scene,"Mission") as Label).text == scene.call("mission_text"),"Full existing task specification remains available")
			check(root.get_visible_rect().encloses(control(scene,"SpecificationScroll").get_global_rect()),"Task specification reading area fits the window")
			check(root.get_visible_rect().encloses(control(scene,"Step").get_global_rect()),"Specification never displaces the main operation")
			await capture("prediction-"+locale+"-task"+str(index+1)+"-spec")
			if index == 2:
				rule_tabs.current_tab = 0
				for rule_index: int in [1,2]:
					(control(scene,"Rule") as OptionButton).select(rule_index)
					scene.call("edit_policy"); scene.call("run_current"); await settle()
				check(scene.call("goal_met",2),"Actual slower and safe rule records earn the Investigation3 objective")
				check((control(scene,"Status") as Label).text.split("\n").size() == 4,"Earned feedback retains all four progress lines")
				bounds(scene); progress_fits(scene,locale+" Investigation3 earned")
				await capture("prediction-"+locale+"-task3-earned")
		scene.queue_free(); await settle()
		check(auto_accept_quit == original_auto_quit,"Workbench exit restores close handling")
	localization.set_locale(original_locale)
	nav.pending = original_pending; nav.selected = original_selected; nav.from_tree = original_from_tree; nav.last_visited_task = original_recent
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); after.erase("saved_at_utc")
	check(after == before,"Workbench presentation grants no campaign completion or model state")
	print("PASS: test_prediction_workbench_presentation " if failures == 0 else "FAIL: test_prediction_workbench_presentation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
