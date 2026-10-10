extends SceneTree
## Continuation stays equivalent to manual authoritative commit/reveal operations.
const Session = preload("res://experiments/creation/session.gd")
const Model = preload("res://experiments/creation/model.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func run() -> void:
	root.get_node("TaskNavigation").pending = ""
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	scene.session.data = Session.fresh()
	scene.session.train()
	scene.session.data.mode = "predict"
	scene.change_task(3)
	scene.begin_prediction("practice")
	var identity: String = Model.identity(scene.session.data.model)
	var button: Button = scene.find_child("ContinuePrediction",true,false)
	check(button != null and button.disabled,"Remainder requires the first manual commit/reveal")
	scene.continue_prediction(false)
	check(scene.session.prediction.rows.is_empty(),"Guard rejects continuation before manual evidence")
	scene.commit_prediction()
	check(scene.signal_view.lanes[0].size()==2 and scene.session.prediction.rows.is_empty(),"Initial commit still exposes no future truth")
	var pending_evidence: Dictionary = scene.session.prediction_evidence()
	var has_reveal: bool = false
	for event: Dictionary in pending_evidence.events:
		check(event.phase == "predict", "Prediction events belong to the frozen prediction run")
		if event.kind == "reveal": has_reveal = true
	check(not has_reveal,"Pending evidence contains no unobserved reveal")
	var protected_events: Array = pending_evidence.events.duplicate(true)
	pending_evidence.events.clear()
	pending_evidence.recipe.model.clear()
	var fresh_evidence: Dictionary = scene.session.prediction_evidence()
	check(fresh_evidence.events == protected_events and Model.identity(fresh_evidence.recipe.model)==identity,"Evidence events and model are detached deep copies")
	scene.reveal_prediction()
	check(not button.disabled,"First revealed cell enables continuation")
	scene.inspect_cell(2,2)
	scene.commit_prediction()
	var sealed: Dictionary = scene.session.prediction.duplicate(true)
	scene.continue_prediction(false)
	check(scene.session.prediction==sealed and button.disabled,"A pending manual guess must be revealed before continuation")
	scene.reveal_prediction()
	var baseline = Session.new()
	baseline.data = Session.fresh(); baseline.train(); baseline.data.mode = "predict"
	baseline.begin_prediction("practice")
	while not baseline.prediction.finished:
		baseline.commit_prediction(); baseline.reveal_prediction()
	scene.continue_prediction(true)
	var stopped: Array = scene.session.prediction.rows
	check(not stopped.is_empty() and not stopped[-1].correct,"Until mismatch stops on a revealed mismatch")
	check(scene.focused_cell==stopped[-1].index and scene.signal_view.selected==stopped[-1].index,"Mismatch has an actionable causal focus")
	var stop_count: int = stopped.size()
	check(stopped==baseline.prediction.rows.slice(0,stop_count),"Stopped rows and costs match the manual prefix exactly")
	var focus: int = scene.focused_cell
	scene.continue_prediction(false)
	check(scene.session.prediction.finished and scene.session.prediction.rows==baseline.prediction.rows,"Remainder preserves exact manual results and per-cell costs")
	check(scene.focused_cell==focus,"Finishing remainder retains the causal focus")
	check(Model.identity(scene.session.data.model)==identity,"Continuation never trains the frozen rules")
	check(scene.session.data.supports.has("P1_commit") and scene.records.size()==1,"Completion grants existing evidence once")
	scene.continue_prediction(false)
	check(scene.records.size()==1 and button.disabled,"Finished continuation cannot duplicate evidence")
	check(scene.session.set_mode("generate").ok,"Completed continuation unlocks the existing feedback path")
	scene.queue_free(); await settle()
	print("PASS: creation prediction flow %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
