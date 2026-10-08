extends SceneTree
## Transient draft history never rewinds protected works, supports or seen checks.
const Session = preload("res://experiments/creation/session.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 8: await process_frame
func capture(name: String) -> void:
	if "--creation-contract-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute("res://.godot/creation-contract-captures")
	check(root.get_texture().get_image().save_png("res://.godot/creation-contract-captures/"+name+".png") == OK,"Actual viewport capture "+name)
func click(scene: Control, name: String) -> void:
	var action := scene.find_child(name,true,false) as Button
	check(action != null and action.is_visible_in_tree() and not action.disabled,"Enabled visible draft action "+name)
	if action == null or action.disabled: return
	if DisplayServer.get_name() == "headless":
		action.grab_focus(); action.pressed.emit()
	else:
		var point: Vector2 = action.get_global_rect().get_center()
		check(root.get_visible_rect().has_point(point),"Draft action fits viewport "+name)
		for down: bool in [true,false]:
			var event := InputEventMouseButton.new(); event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
			root.push_input(event,true); await process_frame
	await settle()
	var focus: Control = root.gui_get_focus_owner()
	check(focus != null and str(focus.name) == name,"Restored draft action retains keyboard focus "+name)
func write_raw(path: String, raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Isolated fixture is writable")
	if file != null: file.store_string(raw); file.close()
func prepare(session: Variant) -> void:
	check(session.train().ok and session.transport([0,1,0,2],"predictive").ok,"Prepare learned model and restored source")
	session.complete("C1_restore"); session.set_mode("predict"); session.begin_prediction("check")
	while not session.prediction.finished: session.commit_prediction(); session.reveal_prediction()
	session.complete("P3_check"); session.set_mode("generate"); session.generate()
func run() -> void:
	var path: String = "user://creation-undo/"+Crypto.new().generate_random_bytes(8).hex_encode()+"/session.json"
	var session = Session.new(); check(session.open(path).writable,"Undo profile owns its isolated writer")
	check(not session.can_undo() and not session.can_redo(),"Fresh profile has no history")
	prepare(session); check(session.save_work("Protected original").ok,"Keep actual fixture work")
	var protected_works: Array = session.data.works.duplicate(true)
	var protected_supports: Dictionary = session.data.supports.duplicate(true)
	var seen: Array = session.data.seen_checks.duplicate()
	var baseline: Dictionary = session.data.draft.duplicate(true)
	session.data.draft.seed += 3; session.mark_dirty(); var edited: Dictionary = session.data.draft.duplicate(true)
	session.generate()
	check(session.undo_draft().ok and session.data.draft == baseline,"Seed edit undoes to actual prior draft")
	check(session.generated.is_empty() and session.prediction.is_empty() and session.last_transport.is_empty(),"Undo clears executable/current result bindings")
	check(session.data.works == protected_works and session.data.supports == protected_supports and session.data.seen_checks == seen,"Undo cannot erase protected output, completion or seen answers")
	check(session.redo_draft().ok and session.data.draft == edited,"Redo restores changed draft")
	check(session.fork_work(0).ok and session.data.parent_work == protected_works[0].id,"Saved work forks into a transient draft")
	check(session.undo_draft().ok and session.data.draft == edited and session.data.parent_work == "","Fork undo returns to previous draft and parent")
	check(session.redo_draft().ok and session.data.parent_work == protected_works[0].id,"Fork redo restores exact saved recipe lineage")
	var learned_model: Dictionary = session.data.model.duplicate(true)
	session.data.draft.order = 2; session.mark_dirty(); check(session.train().ok,"Retraining is an explicit draft step")
	check(session.undo_draft().ok and session.data.model == learned_model and session.data.draft.order == 2,"Undo learning restores model while retaining preceding untrained order edit")
	check(session.undo_draft().ok and session.data.draft.order == 1,"Separate order edit is undoable")
	check(session.redo_draft().ok and session.data.draft.order == 2,"Order edit can be redone")
	session.data.draft.sampler = "max"; session.mark_dirty()
	check(not session.can_redo(),"A new edit discards the redo branch")
	for i: int in 40: session.data.draft.seed += 1; session.mark_dirty()
	check(session.undo_stack.size() == Session.MAX_DRAFT_HISTORY,"Draft history is bounded to24 steps")
	check(session.data.works == protected_works and session.data.supports == protected_supports,"Many draft edits never evict protected work/supports")
	# Save refusal keeps draft and both history stacks; it never rewrites future bytes.
	var data_before: String = JSON.stringify(session.data)
	var undo_before: String = JSON.stringify(session.undo_stack)
	var redo_before: String = JSON.stringify(session.redo_stack)
	var future: Dictionary = Session.fresh(); future.version=999
	var future_raw: String = JSON.stringify(future); write_raw(path,future_raw)
	check(session.save() != OK and session.dirty,"Failed save retains dirty exploration")
	check(JSON.stringify(session.data)==data_before and JSON.stringify(session.undo_stack)==undo_before and JSON.stringify(session.redo_stack)==redo_before,"Failed write preserves draft/history")
	check(not session.undo_draft().ok and not session.fork_work(0).ok,"Future main cannot authorize history permissions or a fork")
	check(JSON.stringify(session.data)==data_before and JSON.stringify(session.undo_stack)==undo_before and FileAccess.get_file_as_string(path)==future_raw,"Future refusals preserve data, history and exact future bytes")
	session.close(); session.open(path)
	check(session.undo_stack.is_empty() and session.redo_stack.is_empty() and not session.can_undo(),"Future read-only open clears transient history")
	session.close()
	# Fresh UI edits/fork history remain independent of readonly viewing and labels.
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle(); root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720); root.content_scale_size=Vector2i(1280,720); await settle()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	for english: bool in [false,true]:
		scene.english=english; scene.change_task(8); prepare(scene.session); scene.generate_work()
		scene.name_input.text="Undo UI protected "+str(english); scene.keep_work(); await settle()
		var kept: Dictionary=scene.kept_work.duplicate(true)
		var previous_seed: int=int(scene.session.data.draft.seed)
		scene.session.data.draft.seed += 12; scene.edit_draft(); scene.generate_work()
		var old_records: Array=scene.records.duplicate(true)
		var old_file: String=FileAccess.get_file_as_string(scene.session.path)
		scene.name_input.text="Unsubmitted title"; (scene.find_child("CustomExample",true,false) as LineEdit).text="A D A C"
		await click(scene,"UndoDraft")
		check(int(scene.session.data.draft.seed)==previous_seed and scene.latest.is_empty() and scene.session.generated.is_empty(),"Actual Undo restores seed and clears current display")
		check(int((scene.find_child("Seed",true,false) as SpinBox).value)==previous_seed and (scene.find_child("Order",true,false) as OptionButton).selected==int(scene.session.data.draft.order),"Restored public recipe controls match the undone draft")
		check(scene.signal_view.captions[2].contains("Generate my recipe" if english else "按我的配方生成"),"Restored connected generation draft asks to run rather than reconnect")
		check(scene.name_input.text=="Unsubmitted title" and (scene.find_child("CustomExample",true,false) as LineEdit).text=="A D A C","Undo retains unsubmitted title and sample")
		check(scene.records==old_records and scene.session.data.works[-1]==kept and FileAccess.get_file_as_string(scene.session.path)==old_file,"Undo preserves historic measurements, kept work and saved bytes")
		await capture("undo-"+("en" if english else "zh"))
		await click(scene,"RedoDraft")
		check(int(scene.session.data.draft.seed)==previous_seed+12 and scene.latest.is_empty(),"Actual Redo restores recipe without reviving stale output")
		scene.toggle_language(); await settle()
		check(scene.latest.is_empty() and scene.kept_work.is_empty(),"Language rebuild cannot resurrect a saved snapshot after draft restoration")
		scene.toggle_language(); await settle()
		# Invalid Initial text is not a draft step and must not be silently discarded.
		var initial := scene.find_child("Initial",true,false) as LineEdit
		initial.text="A X"; initial.text_changed.emit(initial.text)
		await click(scene,"UndoDraft")
		check((scene.find_child("Initial",true,false) as LineEdit).text=="A X" and not scene.valid_initial_input(),"Undo retains invalid unsubmitted Initial and keeps execution blocked")
		(scene.find_child("Initial",true,false) as LineEdit).text="A B"
		scene.refresh(); scene.works.select(scene.session.data.works.size()-1); scene.fork_work(); await settle()
		check(scene.session.data.parent_work==kept.id and scene.session.can_undo(),"UI fork is independently undoable")
		await click(scene,"UndoDraft")
		check(scene.session.data.works[-1]==kept and scene.session.data.supports.has("G3_keep"),"Undo fork cannot rewind protected closure support")
		scene.writable=false; scene.refresh()
		check((scene.find_child("UndoDraft",true,false) as Button).disabled and (scene.find_child("RedoDraft",true,false) as Button).disabled,"Read-only UI disables undo and redo")
		scene.writable=true; scene.refresh()
		scene.session.close(); check(scene.session.retry_writer(true).writable,"Confirmed reload reacquires current saved profile")
		scene._clear_replaced_exploration(); scene.build(); await settle()
		check(not scene.session.can_undo() and not scene.session.can_redo(),"Confirmed reload clears undo/redo rather than reviving discarded draft history")
	scene.queue_free(); await settle()
	print("PASS: creation draft undo %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
