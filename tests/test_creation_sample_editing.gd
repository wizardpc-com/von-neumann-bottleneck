extends SceneTree
## Edit an actual selected passage, learn its rules, and choose a protected output.
const Session = preload("res://experiments/creation/session.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
class LeaveProbe:
	extends "res://experiments/creation/workbench.gd"
	var leave_calls: int = 0
	func finish_leave() -> void: leave_calls += 1
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func field(scene: Control, handle: String) -> LineEdit:
	return scene.find_child(handle,true,false) as LineEdit
func press(scene: Control, handle: String) -> void:
	# Rebuilt Containers must establish their scroll range before revealing a row.
	await settle()
	var action := scene.find_child(handle,true,false) as Button
	check(action != null and not action.disabled,"Available sample action "+handle)
	if action == null or action.disabled: return
	var ancestor: Node = action.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(action)
		ancestor = ancestor.get_parent()
	await settle()
	if DisplayServer.get_name() == "headless": action.pressed.emit()
	else:
		var point: Vector2 = action.get_global_rect().get_center()
		check(root.get_visible_rect().has_point(point),"Sample action fits viewport "+handle)
		var motion := InputEventMouseMotion.new(); motion.position = point; root.push_input(motion,true)
		for down: bool in [true,false]:
			var event := InputEventMouseButton.new(); event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
			root.push_input(event,true); await process_frame
	await settle()
func counts(model: Dictionary, context: Array) -> Array:
	for row: Dictionary in model.rows:
		if row.context == context: return row.counts
	return []
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or "--creation-sample-edit-capture" not in OS.get_cmdline_user_args(): return
	await settle(); RenderingServer.force_draw(false); await process_frame
	DirAccess.make_dir_recursive_absolute("res://.godot/creation-sample-edit-captures")
	check(root.get_texture().get_image().save_png("res://.godot/creation-sample-edit-captures/"+name+".png") == OK,"Capture sample editing "+name)
func run() -> void:
	var enabled: Variant = ProjectSettings.get_setting("candidate/creation_enabled",false)
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await exercise(locale)
	ProjectSettings.set_setting("candidate/creation_enabled",enabled)
	print("PASS: creation sample editing %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
func exercise(locale: String) -> void:
	root.get_node("TaskNavigation").pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	scene.set_script(LeaveProbe)
	root.add_child(scene); await settle()
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	scene.session.close()
	var path: String = "user://creation-sample-editing/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	check(scene.session.open(path).writable,"Own isolated sample-edit profile")
	scene.session.data.draft.order = 2; scene.edit_draft(); scene.train_model()
	scene.transport("predictive"); scene.switch_mode("predict"); scene.begin_prediction("practice")
	scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.change_task(7); scene.generate_work()
	scene.name_input.text = "Protected A "+locale; scene.keep_work()
	check(scene.session.data.works.size() == 1,"Keep actual baseline before editing")
	var protected_a: Dictionary = scene.session.data.works[0].duplicate(true)
	var baseline_model: Dictionary = scene.session.data.model.duplicate(true)
	var baseline: Dictionary = scene.session.generated.duplicate(true)
	var unchanged_first: Array = scene.session.data.draft.examples[0].duplicate()
	scene.pin_creation_a()
	var intent_text: String = "让这段少一些B，多一些C"
	field(scene,"CreationIntent").text = intent_text
	field(scene,"CreationIntent").text_changed.emit(intent_text)
	check(scene.session.generated == baseline and not scene.session.dirty,"Intent text never edits executable recipe or saved state")
	check(scene.creation_caption.text.contains(intent_text),"Optional intent is visible without an outcome judgment")
	(scene.find_child("DraftTabs",true,false) as TabContainer).current_tab = 0
	await press(scene,"EditExample1")
	check(field(scene,"SampleEditText").text == Catalog.symbols(Catalog.sample(1)),"Edit opens the actual second passage")
	await press(scene,"ApplySampleEdit")
	check(scene.session.generated == baseline and not scene.session.dirty and scene.pinned_creation == baseline,"Unchanged replacement preserves current run and does not create a draft edit")
	await press(scene,"EditExample1")
	field(scene,"SampleEditText").text = Catalog.symbols(Catalog.sample(4))
	await capture("replacement-"+locale)
	await press(scene,"ApplySampleEdit")
	check(scene.session.data.draft.examples == [unchanged_first,Catalog.sample(4)],"Replace changes precisely one passage in place")
	check(scene.session.data.model == baseline_model and scene.pinned_creation == baseline,"Unlearned edit preserves learned model and full pinned A")
	check(scene.session.generated.is_empty() and not scene.can_keep_visible_work(),"Edited draft cannot keep an older run under the new recipe")
	check(scene.session.data.works[0] == protected_a,"Edit cannot rewrite protected A")
	await press(scene,"Train")
	check(counts(baseline_model,[2,0]) == [0,5,0,0] and counts(scene.session.data.model,[2,0]) == [0,5,0,6],"Real CA successor counts gain six D examples")
	check(not scene.latest.rule_changes.is_empty(),"Explicit learning produces actual recounted rule differences")
	await press(scene,"Generate")
	check(scene.creation_report.single and scene.creation_report.controlled_effect,"One passage edit produces a controlled observed effect")
	check(scene.creation_report.mismatches.size() == 12 and scene.creation_report.first_difference == 9,"Actual fixed-seed output differs at twelve cells, first cell ten")
	check(scene.pinned_creation == baseline and scene.session.data.works[0] == protected_a,"Learning and B generation keep complete A evidence and saved snapshot intact")
	check(scene.session.generated.recipe.seed == 17 and scene.session.generated.recipe.initial == [0,1] and scene.session.generated.recipe.length == 64,"B retains fixed seed, initial context and length")
	scene.name_input.text = "Chosen B "+locale
	scene.choose_creation_result(true); await settle()
	check(scene.session.data.works.size() == 2 and scene.session.replay_work(1).get("matches",false),"Chosen B saves and independently replays actual edited output")
	check(scene.session.data.works[0] == protected_a and scene.session.design_provenance().source == "controlled-design-v1","Keep B protects A and saves revalidated controlled design evidence")
	var protected_works: Array = scene.session.data.works.duplicate(true)
	scene.restore_draft_history(false); await settle()
	check(scene.session.data.works == protected_works and field(scene,"CreationIntent").text == intent_text,"Undo preserves protected works and unjudged session intent")
	check(not JSON.stringify(scene.session.data).contains(intent_text),"Intent is absent from persistent session format")
	# Invalid/unsubmitted text survives ordinary rebuilds without changing the draft.
	(scene.find_child("DraftTabs",true,false) as TabContainer).current_tab = 0
	await press(scene,"EditExample1")
	var draft_before: Dictionary = scene.session.data.draft.duplicate(true)
	var model_before: Dictionary = scene.session.data.model.duplicate(true)
	for invalid: String in ["","A X","   "]:
		field(scene,"SampleEditText").text = invalid
		await press(scene,"ApplySampleEdit")
		check(scene.session.data.draft == draft_before and scene.session.data.model == model_before and scene.sample_edit_index == 1,"Invalid replacement preserves draft/model and open editor")
	var too_long := PackedStringArray()
	for i: int in 97: too_long.append("A")
	field(scene,"SampleEditText").text = " ".join(too_long)
	await press(scene,"ApplySampleEdit")
	check(scene.session.data.draft == draft_before and field(scene,"SampleEditText").text.split(" ").size() == 97,"Oversize replacement retains text and legal draft")
	field(scene,"SampleEditText").text = "A X"
	await press(scene,"Language"); await press(scene,"Next"); await press(scene,"Previous")
	check(field(scene,"SampleEditText").text == "A X" and field(scene,"CreationIntent").text == intent_text and scene.sample_edit_index == 1,"Language and task navigation retain pending sample text, target and intent")
	(scene.find_child("DraftTabs",true,false) as TabContainer).current_tab = 0
	await capture("invalid-"+locale)
	await press(scene,"CancelSampleEdit")
	check(scene.session.data.draft == draft_before and scene.sample_edit_index == -1,"Cancel leaves actual passage unchanged")
	await press(scene,"EditExample1")
	var maximum := PackedStringArray()
	for i: int in 96: maximum.append("C")
	field(scene,"SampleEditText").text = " ".join(maximum)
	await press(scene,"ApplySampleEdit")
	check(scene.session.data.draft.examples[1].size() == 96,"Published ninety-six-cell boundary accepts a legal replacement")
	# At the existing capacity, replacement is still one passage rather than Add.
	var full: Array = []
	for i: int in 16: full.append([0,1])
	scene.session.data.draft.examples = full; scene.edit_draft(); scene.rebuild_editor_preserving_inputs()
	await press(scene,"EditExample15")
	var editor_scroll: Node = field(scene,"SampleEditText").get_parent()
	while not editor_scroll is ScrollContainer: editor_scroll = editor_scroll.get_parent()
	check((editor_scroll as ScrollContainer).get_global_rect().encloses(field(scene,"SampleEditText").get_global_rect()),"Opening passage sixteen reveals the complete entry before another action scrolls")
	check(root.gui_get_focus_owner() == field(scene,"SampleEditText"),"Deferred edit reveal focuses its real text field")
	field(scene,"SampleEditText").text = "C D"
	await press(scene,"ApplySampleEdit")
	check(scene.session.data.draft.examples.size() == 16 and scene.session.data.draft.examples[15] == [2,3] and scene.session.data.draft.examples[0] == [0,1],"Full sixteen-passage selection accepts in-place replacement")
	# A duplicate shifted into the same slot still cannot authorize a stale edit.
	await press(scene,"EditExample1")
	field(scene,"SampleEditText").text = "D C"
	await press(scene,"RemoveExample0")
	var after_remove: Array = scene.session.data.draft.examples.duplicate(true)
	await press(scene,"ApplySampleEdit")
	check(scene.session.data.draft.examples == after_remove and field(scene,"SampleEditText").text == "D C","Removal refuses stale target even when an identical passage shifts into its position")
	await press(scene,"CancelSampleEdit")
	await press(scene,"EditExample0")
	field(scene,"SampleEditText").text = "B D"
	scene.writable = false; scene.rebuild_editor_preserving_inputs()
	check((scene.find_child("ApplySampleEdit",true,false) as Button).disabled and not field(scene,"SampleEditText").editable,"Read-only profile disables committing and changing sample text")
	scene.apply_sample_edit()
	check(scene.session.data.draft.examples == after_remove and field(scene,"SampleEditText").text == "B D","Direct read-only apply refuses mutation and preserves unsubmitted text")
	check(scene.session.data.works == protected_works,"All invalid, capacity, stale and read-only edits retain both chosen works")
	scene.writable = true; scene.cancel_sample_edit(); await settle()
	await exercise_leave_protection(scene)
	scene.queue_free(); await settle()

func exercise_leave_protection(scene: LeaveProbe) -> void:
	check(scene.session.save() == OK and not scene.session.dirty,"Pending-text departure starts from a clean actual profile")
	var saved_bytes: String = FileAccess.get_file_as_string(scene.session.path)
	await press(scene,"EditExample0")
	for to_hub: bool in [true,false]:
		for text: String in ["C D","A X"]:
			field(scene,"SampleEditText").text = text
			if to_hub: scene.request_leave(true)
			else: scene._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
			await settle()
			check(scene.sample_leave_dialog.visible and not scene.leave_dialog.visible and scene.leave_calls == 0,"Clean Home/OS close guards both legal and illegal unsubmitted sample text")
			check(scene.leaving_to_hub == to_hub and not scene.session.dirty,"Pending text guard preserves requested route without masquerading as a saved draft edit")
			scene.sample_leave_dialog.hide(); scene.sample_leave_dialog.canceled.emit(); await settle()
			check(field(scene,"SampleEditText").text == text and root.gui_get_focus_owner() == field(scene,"SampleEditText") and scene.leave_calls == 0,"Return to editing retains pending text and restores its keyboard focus")
	check(FileAccess.get_file_as_string(scene.session.path) == saved_bytes,"Departure cancellation never writes unsubmitted text")
	scene.save_draft()
	check(scene.has_pending_sample_text() and FileAccess.get_file_as_string(scene.session.path) == saved_bytes,"Save draft leaves pending text unsubmitted and the saved format unchanged")
	for to_hub: bool in [true,false]:
		var calls_before: int = scene.leave_calls
		scene.request_leave(to_hub)
		scene.sample_leave_dialog.hide(); scene.sample_leave_dialog.confirmed.emit(); await settle()
		check(scene.leave_calls == calls_before+1 and scene.leaving_to_hub == to_hub and not scene.has_pending_sample_text(),"Explicit pending-text discard permits the selected clean departure")
		await press(scene,"EditExample0")
		field(scene,"SampleEditText").text = "A X"
		scene.session.data.draft.seed += 1; scene.edit_draft()
		calls_before = scene.leave_calls
		scene.request_leave(to_hub)
		scene.sample_leave_dialog.hide(); scene.sample_leave_dialog.confirmed.emit(); await settle()
		check(scene.leave_dialog.visible and scene.session.dirty and scene.leave_calls == calls_before and not scene.has_pending_sample_text(),"Discarding transient text still requires the existing dirty-draft decision")
		scene.leave_dialog.hide(); scene.leave_dialog.canceled.emit(); await settle()
		check(scene.leave_calls == calls_before and scene.session.dirty,"Cancel of the ordinary draft guard continues editing without departure")
		check(scene.session.save() == OK,"Reset only the explicit test draft before the next departure check")
		await press(scene,"EditExample0"); field(scene,"SampleEditText").text = "C D"
	scene.cancel_sample_edit(); await settle()
	await press(scene,"EditExample0")
	var noop_calls: int = scene.leave_calls
	scene.request_leave(true); await settle()
	check(scene.leave_calls == noop_calls+1 and not scene.sample_leave_dialog.visible and not scene.has_pending_sample_text(),"Opening an unchanged passage adds no departure ceremony")
