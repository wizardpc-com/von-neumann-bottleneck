extends "res://tests/test_recovery_game_input.gd"
## Real model preparation; continuing, forking, generation and Keep use viewport input.
const Context = preload("res://experiments/candidate_session/context.gd")

func action(id: String) -> void:
	await press(ui.find_child(id,true,false))

func type_field(control: LineEdit, value: String) -> void:
	await press(control)
	await key(KEY_A,true)
	await type_text(value)
	await settle()

func check_guide(expected: String, label: String) -> void:
	check(ui.next_step().action == expected and ui.next_step_button.text == ui.next_step().button,label+": guide follows current intent; actual="+str(ui.next_step().action))
	check(ui.next_step_button.is_visible_in_tree() and root.get_visible_rect().encloses(ui.next_step_button.get_global_rect()),label+": primary action fits viewport")

func editing_generation(label: String) -> void:
	check_guide("generate",label)
	# On the negative control, measure through the still-available existing action
	# so the rest of the lifecycle can be audited without invoking the wrong guide.
	await action("NextStepAction" if ui.next_step().action == "generate" else "Generate")
	check(ui.can_keep_visible_work(),label+": explicit generation produces an actual keepable result")

func set_length(length: int) -> void:
	var spin := ui.find_child("Length",true,false) as SpinBox
	await type_field(spin.get_line_edit(),str(length))
	await key(KEY_ENTER)
	await settle()
	check(ui.session.data.draft.length == length,"Explicit recipe length edit is applied")

func fit_capture_window() -> void:
	if "--recovery-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720)
		root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var frame: Image = root.get_texture().get_image()
		stable = stable+1 if frame != null and frame.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Five rendered frames confirm 1280x720 capture")

func shot(label: String) -> void:
	if "--recovery-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	# Size settles before actions; taking evidence must not resize/reset scrolling.
	await point(Vector2(5,5))
	await settle(12)
	RenderingServer.force_draw(false)
	check(root.get_texture().get_image().get_size() == Vector2i(1280,720),"Capture preserves actual 1280x720 viewport")
	if label == "g2-name-request":
		check_name_visible("At capture")
	await capture(label)

func check_name_visible(label: String) -> void:
	var name_scroll: ScrollContainer
	var ancestor: Node = ui.name_input.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: name_scroll = ancestor; break
		ancestor = ancestor.get_parent()
	check(ui.name_input.has_focus() and name_scroll != null and name_scroll.get_global_rect().encloses(ui.name_input.get_global_rect()),label+": G2 empty-name Keep reveals its focused name within the actual scroll viewport")

func saved_view_action() -> String:
	return "finish_journey" if Context.full_journey() else "works"

func reopen_saved_profile(path: String, label: String) -> void:
	await action("SaveDraft")
	var data: Dictionary = ui.session.data.duplicate(true)
	var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
	ui.queue_free(); await settle()
	ui = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(ui); current_scene = ui
	await settle(12)
	ui.session.close()
	var opened: Dictionary = ui.session.open(path)
	ui.writable = bool(opened.get("writable",false))
	ui._clear_replaced_exploration()
	ui.build()
	await settle(12)
	check(ui.writable and not ui.session.dirty and ui.session.data == data and FileAccess.get_file_as_bytes(path) == bytes,label+": fresh host reads the exact explicitly saved profile without rewriting it")

func exercise(locale: String) -> void:
	root.get_node("TaskNavigation").pending = ""
	ui = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(ui); current_scene = ui
	await settle(12)
	ui.session.close()
	var path: String = "user://creation-continue/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	check(ui.session.open(path).writable,"Own isolated writable creation profile")
	ui._clear_replaced_exploration()
	ui.change_task(0)
	ui.train_model()
	ui.source_kind = 2
	ui.transport("predictive")
	ui.switch_mode("predict")
	ui.begin_prediction("practice")
	ui.commit_prediction(); ui.reveal_prediction(); ui.continue_prediction()
	ui.switch_mode("generate")
	ui.change_task(7)
	await settle(12)
	await action("Generate")
	check(ui.can_keep_visible_work(),"Real learning, transport and prediction authorize generation")
	# Exploratory G2 check: no helper scrolls the name into view after Keep.
	await action("KeepCurrent")
	await settle(12)
	check_name_visible("After Keep")
	await shot("g2-name-request")
	# Keep must reveal and focus this field itself; typing does not scroll it.
	await type_text("Original "+locale)
	await settle()
	check(ui.name_input.text == "Original "+locale,"Typing after G2 Keep reaches the revealed name without helper scrolling")
	await action("KeepCurrent")
	check(ui.session.data.works.size() == 1,"First actual Keep saves one protected work")
	ui.change_task(8); await settle(12)
	var first: Dictionary = ui.session.data.works[0].duplicate(true)
	var saved_bytes: String = FileAccess.get_file_as_string(path)
	check_guide(saved_view_action(),"Kept result")
	await action("ViewKeptWork")
	check(is_instance_valid(ui.work_focus) and ui.work_focus.work == first,"View opens the actual saved snapshot")
	if is_instance_valid(ui.work_focus):
		var window: Window = ui.work_focus
		var close: Button = ui.work_focus.close_button
		await click(Vector2(window.position)+close.get_global_rect().get_center())
		await settle()
	check_guide(saved_view_action(),"Read-only viewing returns to saved-work closure")
	check(FileAccess.get_file_as_string(path) == saved_bytes and ui.session.data.works[0] == first,"Viewing neither rewrites the file nor changes protected work")
	await action("ContinueCreation")
	check(ui.session.data.parent_work == first.id and ui.session.generated.is_empty() and ui.session.dirty,"Edit this work creates an actual unsaved child draft")
	check_guide("generate","Continue editing saved work")
	await shot("continue-draft")
	await set_length(65)
	await editing_generation("Changed child recipe")
	check_guide("keep","New child output")
	await type_field(ui.name_input,"Child "+locale)
	await action("NextStepAction" if ui.next_step().action == "keep" else "KeepCurrent")
	check(ui.session.data.works.size() == 2 and ui.session.data.works[0] == first and ui.session.data.works[1].parent == first.id,"Following the main action keeps a child and preserves its parent")
	check_guide(saved_view_action(),"Kept child returns to closure")
	await reopen_saved_profile(path,"Kept child profile")
	check(ui.latest.get("kind","") == "snapshot","Ordinary saved-work reopen still shows its protected snapshot")
	check_guide(saved_view_action(),"Ordinary saved-work reopen retains closure")
	await action("ForkWork")
	var second: Dictionary = ui.session.data.works[1].duplicate(true)
	check(ui.session.data.parent_work == second.id and ui.session.generated.is_empty(),"Fork uses the selected protected recipe")
	check_guide("generate","Explicit Fork")
	await reopen_saved_profile(path,"Saved untouched fork")
	check_guide("generate","Reopened untouched fork")
	check(ui.latest.is_empty(),"Reopening a saved child draft does not replace it with its parent's snapshot")
	await set_length(66)
	await reopen_saved_profile(path,"Saved edited fork")
	check_guide("generate","Reopened edited fork")
	await editing_generation("Forked recipe")
	check(ui.session.data.works[0] == first and ui.session.data.works[1] == second,"Fork and generation preserve both earlier saved works")
	await shot("fork-generated")
	ui.queue_free(); await settle()

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	await fit_capture_window()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await exercise(locale)
	finish()

func finish() -> void:
	var path: String = evidence_root + "creation-continue-guidance.json"
	var file := FileAccess.open(path,FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"scope":"Prepared real-model targeted UI; not a full ordinary Game playthrough", "observations":observations,"failures":failures},"\t"))
		file.close()
	else:
		failures.append("Could not write creation guidance evidence: "+path)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"creation continue guidance %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
