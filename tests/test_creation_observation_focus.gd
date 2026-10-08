extends SceneTree
## Focus survives controlled reruns without exposing a sealed prediction target.
const Session = preload("res://experiments/creation/session.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func finish_prediction(scene) -> void:
	while not scene.session.prediction.finished:
		scene.commit_prediction()
		scene.reveal_prediction()
func run() -> void:
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	scene.session.data = Session.fresh()
	scene.english = false; scene.build()
	scene.train_model(); scene.transport("predictive"); await settle()
	scene.signal_view.page = 3
	scene.inspect_cell(150,2)
	scene.session.data.draft.machine.cpu_ops_per_cycle = 16
	scene.edit_draft(); scene.transport("predictive"); await settle()
	check(scene.focused_cell == 150 and scene.signal_view.selected == 150,"Same source and rules retain selected cell after CPU change")
	check(scene.signal_view.page == 3,"Same-source controlled transport retains page")
	scene.session.data.draft.order = 2
	scene.edit_draft(); scene.train_model(); await settle()
	check(scene.observation_anchor.cell == 150 and scene.focused_cell == -1,"Training retains anchor without inventing output cells")
	check(scene.causal_panel.summary_label.text.contains("保留第 151 格"),"Training compares the previously observed context's actual counts")
	scene.transport("predictive"); await settle()
	check(scene.focused_cell == 150 and scene.signal_view.page == 3,"Memory retraining returns to the same source cell and page")
	scene.compare_transport(); await settle()
	check(scene.focused_cell == 150,"Locked codec comparison retains source focus")
	scene.source_kind = 2; scene.transport("predictive"); await settle()
	check(scene.focused_cell == 11 and scene.signal_view.page == 0,"Short changed source clamps to a visible cell and page")
	check(scene.inspector.text.contains("输入已改变") and scene.causal_panel.summary_label.text.contains("不是同输入"),"Changed input explicitly disclaims same-input causal equivalence")
	scene.switch_mode("predict"); scene.change_task(4); scene.begin_prediction("practice")
	finish_prediction(scene); scene.inspect_cell(7,2)
	var frozen_prefix: Array = scene.session.prediction.prefix.duplicate()
	scene.session.data.draft.order = 1
	scene.edit_draft(); scene.train_model(); scene.begin_prediction("practice"); await settle()
	check(scene.observation_anchor.cell == 7 and scene.focused_cell == 1,"P2 anchor waits while only two seed cells are visible")
	check(scene.signal_view.selected < scene.session.prediction.prefix.size(),"Restart never selects a future truth cell")
	check(scene.inspector.text.contains("尚未揭晓"),"Waiting for focus explains the sealed boundary")
	while scene.session.prediction.prefix.size() <= 7:
		scene.commit_prediction()
		check(scene.signal_view.selected < scene.session.prediction.prefix.size(),"Pending guess never exposes a future truth selection")
		scene.reveal_prediction()
	check(scene.focused_cell == 7 and scene.signal_view.selected == 7,"Same P2 passage restores target focus only once revealed")
	check(scene.session.prediction.prefix == frozen_prefix.slice(0,8),"Focus restoration does not change actual prefix truth")
	finish_prediction(scene)
	scene.switch_mode("generate"); scene.generate_work(); scene.inspect_cell(10,2)
	var original_initial: Array = scene.latest.recipe.initial.duplicate()
	scene.session.data.draft.examples.remove_at(1)
	scene.edit_draft(); scene.train_model(); scene.generate_work(); await settle()
	check(scene.focused_cell == 10 and scene.latest.recipe.initial == original_initial,"Changed examples with fixed initial retain generated-cell focus")
	scene.session.data.draft.initial = [1,0]
	scene.edit_draft(); scene.generate_work(); await settle()
	check(scene.focused_cell == 10 and scene.inspector.text.contains("输入已改变"),"Changed initial passage is visible but labelled as a different input")
	# Lane 0 presents a frozen reference, not the current B recipe. Programmatic
	# draft changes exercise this boundary even though the pinned UI locks initial.
	scene.pin_creation_a(); scene.inspect_cell(10,0)
	var frozen_a: Dictionary = scene.pinned_creation.duplicate(true)
	var frozen_a_identity: Dictionary = scene.observation_anchor.identity.duplicate(true)
	scene.session.data.draft.initial = [0,1]
	scene.edit_draft(); scene.generate_work(); await settle()
	check(scene.pinned_creation == frozen_a and scene.signal_view.lanes[0] == frozen_a.output,"Changing B initial never changes the A lane's actual frozen source")
	check(scene.focused_lane == 0 and scene.focused_cell == 10 and scene.observation_anchor.identity == frozen_a_identity,"Selected A identity and focus follow A, independently of B initial")
	check(not scene.inspector.text.contains("输入已改变"),"Unchanged frozen A is not falsely labelled a changed input when B changes")
	# Previous counts come from the selected frozen A, even after current B learns other rules.
	scene.session.data.draft.order = 0
	scene.edit_draft(); scene.train_model(); scene.generate_work(); scene.inspect_cell(10,0)
	var a_counts: Array = Session.Model.predict(frozen_a.recipe.model,frozen_a.output.slice(0,10)).counts
	check(scene.observation_anchor.counts == a_counts,"Observed A stores its frozen counts rather than current B's rules")
	scene.session.data.draft.order = 2
	scene.edit_draft(); scene.train_model(); await settle()
	check(scene.causal_panel.summary_label.text.contains(str(a_counts)+" →"),"Retraining compares selected A counts with the new model, never substituting B")
	scene.generate_work()
	# Without a pin, lane 0 follows the previous actual run. A moving reference
	# must not become a same-source comparison merely because its initial matches.
	scene.clear_creation_comparison()
	scene.session.data.draft.seed = 99
	scene.edit_draft(); scene.generate_work(); scene.inspect_cell(10,0)
	var old_reference: Dictionary = scene.comparison[0].duplicate(true)
	var old_reference_identity: Dictionary = scene.observation_anchor.identity.duplicate(true)
	scene.session.data.draft.seed = 999
	scene.edit_draft(); scene.generate_work(); await settle()
	check(old_reference.recipe.initial == scene.comparison[0].recipe.initial and old_reference.recipe.seed != scene.comparison[0].recipe.seed,"Sliding references deliberately retain initial but change the frozen recipe")
	check(scene.signal_view.lanes[0] == scene.comparison[0].output,"Reference lane displays the new previous run, not an inferred A")
	check(scene.observation_anchor.identity != old_reference_identity,"Replacing the frozen reference changes its identity even with identical initial")
	check(scene.inspector.text.contains("输入已改变"),"Changed reference is explicitly marked as a different source")
	check(scene.failure_text({"error":"work_limit"}).contains("12") and scene.failure_text({"error":"name"}).contains("80"),"Save failures explain actual capacity and naming limits")
	scene.queue_free(); await settle()
	print("PASS: creation observation focus %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
