extends SceneTree
## Cross-feature regression: visible source identity and failed-save atomicity.
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func run() -> void:
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	var session = scene.session
	session.train(); session.transport([0,1,0,2],"predictive"); session.set_mode("predict"); session.begin_prediction()
	while not session.prediction.finished: session.commit_prediction(); session.reveal_prediction()
	session.set_mode("generate"); scene.change_task(7); await settle()
	scene.generate_work(); scene.pin_creation_a()
	session.data.draft.examples.remove_at(1); scene.edit_draft(); scene.train_model(); scene.generate_work(); await settle()
	var index: int = scene.creation_report.first_difference
	check(index>=0, "A/B fixture really differs")
	var a: int = scene.pinned_creation.output[index]
	var b: int = scene.compared_creation.output[index]
	for lane: int in [0,2]:
		var clicked: bool = false
		for cell: Dictionary in scene.signal_view._cells:
			if cell.index == index and cell.lane == lane:
				var click := InputEventMouseButton.new(); click.position = cell.rect.get_center(); click.pressed = true; click.button_index = MOUSE_BUTTON_LEFT
				scene.signal_view._gui_input(click); clicked = true; break
		check(clicked, "Actual cell hit surface exists for lane "+str(lane))
		check(scene.causal_panel.raw_record.get("symbol",-1) == (a if lane == 0 else b), "Click reads evidence from chosen A/B lane "+str(lane))
		check(scene.signal_view.context_lane == lane and scene.signal_view.selected_lane == lane, "Selection/context stay on their source lane")
	var old_raw: Dictionary = scene.causal_panel.raw_record.duplicate(true)
	scene.inspect_cell(index,0); scene.toggle_language(); await settle()
	check(scene.focused_lane == 0 and scene.causal_panel.raw_record.symbol == a, "Language rebuild preserves A source identity")
	scene.name_input.text = "Chosen A"; scene.choose_creation_result(false)
	scene.name_input.text = "Chosen B"; scene.choose_creation_result(true); await settle()
	check(session.data.works.size() == 2, "Both actual chosen works are saved")
	scene.works.select(0); scene.play_work(); await settle()
	check(scene.latest.output == session.data.works[0].output and "protected snapshot" in scene.provenance.text, "Playing A updates protected-snapshot attribution")
	check(str(session.data.works[0].recipe.model_id).substr(0,12) in scene.provenance.text, "Visible A model identity is disclosed")
	check("Current run:" not in scene.costs.text and "Saved snapshots" in scene.costs.text, "Snapshot cannot retain another run’s measured cost")
	check(scene.events.get_root().get_child_count() == 0, "Snapshot has no current-training events impersonating its trace")
	check(scene.rules.get_root().get_first_child().get_metadata(0) == session.data.works[0].recipe.model.rows[0], "Snapshot rule view uses saved model")
	scene.works.select(0); scene.replay_work(); await settle()
	check(("Current run: "+scene.cost_text(scene.latest.cost)) in scene.costs.text and scene.events.get_root().get_child_count()>0, "Replaying A refreshes its actual costs and events")
	check(session.data.works[0].output == scene.latest.output, "Replay leaves protected output unchanged")
	scene.generate_work(); scene.name_input.text = "Rejected attempt"
	var before: String = JSON.stringify(session.data)
	var dirty: bool = session.dirty
	var disk: String = FileAccess.get_file_as_string(session.path)
	var digest: String = session.digest
	session.digest = "external-conflict"
	for attempt: int in 3:
		scene.keep_work()
		check(JSON.stringify(session.data) == before and session.dirty == dirty, "Failed save rolls back works/supports/dirty on retry "+str(attempt))
		check(FileAccess.get_file_as_string(session.path) == disk, "CAS failure leaves original file unchanged")
	session.digest = digest
	scene.keep_work()
	check(session.data.works.size() == 3 and not session.dirty, "Resolved conflict saves once without phantom work slots")
	scene.source_kind = 2; scene.transport("predictive"); await settle()
	scene.inspect_cell(4,1)
	check(scene.signal_view.context_lane == 0 and scene.causal_panel.raw_record.phase == "encode", "Encoding guess is explained by sender truth history, not earlier guesses")
	scene.inspect_cell(4,2)
	check(scene.signal_view.context_lane == 2 and scene.causal_panel.raw_record.phase == "decode" and "actual" in scene.inspector.text, "Receiver explanation uses decoded truth and known actual value")
	scene.transport("raw"); scene.inspect_cell(0,2)
	check(scene.causal_panel.raw_record.kind == "literal_read" and "literal recovery" in scene.inspector.text, "RAW receiver reads literal without a model explanation")
	scene.queue_free(); await settle()
	print("PASS: creation evidence identity %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
