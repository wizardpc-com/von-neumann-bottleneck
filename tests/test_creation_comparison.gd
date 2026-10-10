extends SceneTree
## Deterministic evidence + controller checks, not native/visual acceptance.
const Model = preload("res://experiments/creation/model.gd")
const Session = preload("res://experiments/creation/session.gd")
const Compare = preload("res://experiments/creation/comparison.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func generation(examples: Array, order: int = 1, seed: int = 17, sampler: String = "weighted") -> Dictionary:
	var machine: Dictionary = Model.default_machine()
	var learned: Dictionary = Model.learn(examples,order,machine)
	return Model.generate(learned.model,[0,1],64,seed,sampler,machine)
func pure_checks() -> void:
	var samples: Array = Session.fresh().draft.examples
	var a: Dictionary = generation(samples)
	var b: Dictionary = generation([samples[0]])
	var report: Dictionary = Compare.compare(a,b)
	check(report.ok and report.fixed and report.single and report.controlled_effect,"One removed passage gives a controlled actual effect")
	check(report.changes.size() == 1 and report.changes[0].key == "examples" and report.changes[0].edits == 1,"Derived model identity is not double-counted as a second knob")
	check(report.first_difference >= 2 and a.output.slice(0,report.first_difference) == b.output.slice(0,report.first_difference),"First divergence is located after exactly equal prefix")
	check(a.output[report.first_difference] != b.output[report.first_difference],"Located divergence really differs")
	check(Compare.caption(report).contains("首次分歧") and Compare.caption(report,true).contains("First difference"),"Both locales explain the first divergence")
	check(Compare.caption(report,true).contains("A[2]"),"Removed passage is identified by actual A position")
	var again: Dictionary = generation(samples)
	check(Compare.compare(a,again).factor_count == 0 and not Compare.compare(a,again).different,"Same recipe reproduces same output")
	var seed: Dictionary = generation(samples,1,891)
	var random_report: Dictionary = Compare.compare(a,seed)
	check(random_report.different and not random_report.fixed and not random_report.controlled_effect,"Only seed change is not an intended controlled effect")
	var multi: Dictionary = generation([samples[0]],2,17,"max")
	check(Compare.compare(a,multi).factor_count == 3 and not Compare.compare(a,multi).single,"Examples + order + sampler are three changes")
	check(Compare.caption(Compare.compare(a,multi),true).contains("3 conditions"),"Multi-variable report does not claim one cause")
	var equal_a: Dictionary = generation([[0,1,0,1,0,1]],1,17,"max")
	var equal_b: Dictionary = generation([[0,1,0,1,0,1],[0,1,0,1]],1,17,"max")
	var equal: Dictionary = Compare.compare(equal_a,equal_b)
	check(equal.single and not equal.different and equal.first_difference == -1,"One real example change can leave this output unchanged")
	check(Compare.caption(equal,true).contains("did not alter this generated passage"),"Equal output is an observation, not a failed work")
	check(Compare.example_edits([[0],[1],[2]],[[1],[2]]) == 1,"Removing first example does not count shifted survivors")
	check(Compare.example_edits([[0],[1]],[[1],[0]]) == 2,"Swapping independent examples is visibly multiple edits")
	check(Compare.example_edits([[0],[1]],[[0],[2]]) == 1,"One replacement remains one edit")
	check(Compare.example_edits([],[[0]]) == 1 and Compare.example_edits([[0]],[]) == 1,"Insertion/removal boundary")
	check(Compare.example_edits([],[]) == 0,"Empty lists are comparable")
	var length: Dictionary = a.duplicate(true)
	length.output.append(0); length.recipe.length += 1
	check(Compare.compare(a,length).first_difference == 64 and not Compare.compare(a,length).fixed,"Unequal lengths locate first absent cell without indexing beyond output")
	var machine: Dictionary = a.duplicate(true)
	machine.recipe.machine.cache_rows += 1
	check(Compare.compare(a,machine).changes[0].key == "cache_rows" and not Compare.compare(a,machine).single,"Machine changes are disclosed, not called a creative knob")
	var start: Dictionary = a.duplicate(true)
	start.recipe.initial = [1,0]
	check(not Compare.compare(a,start).fixed,"Changed initial context is not silently treated as fixed")
	check(not Compare.compare({},{}).ok,"Missing runs have no comparison")
func run() -> void:
	if "--comparison-reopen" in OS.get_cmdline_user_args():
		var path: String = ""
		for argument: String in OS.get_cmdline_user_args():
			if argument.begins_with("--creation-profile="): path = argument.trim_prefix("--creation-profile=")
		check(not path.is_empty(),"Reopen uses an explicit isolated profile")
		var reopened = Session.new()
		var opened: Dictionary = reopened.open(path) if not path.is_empty() else {"ok":false}
		check(opened.get("ok",false),"Separate process can reopen A/B saved works")
		if opened.get("ok",false):
			check(reopened.data.works.size() == 2,"Both explicitly chosen works persisted")
			for index: int in reopened.data.works.size():
				check(reopened.replay_work(index).get("matches",false),"Separate-process recipe replay matches chosen work %d" % index)
			reopened.close()
		print("PASS: creation comparison reopen %d checks" % checks if failures.is_empty() else "FAIL: "+str(failures))
		quit(0 if failures.is_empty() else 1)
		return
	pure_checks()
	var packed: PackedScene = load("res://experiments/creation/workbench.tscn")
	for english: bool in [false,true]:
		var scene = packed.instantiate()
		root.add_child(scene); await settle()
		root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
		check(scene.pinned_creation.is_empty(),"Temporary A/B snapshots do not silently resume from a saved draft")
		scene.english = english
		var session = scene.session
		# A dedicated isolated profile is required. Reset only its in-memory fixture.
		session.data = Session.fresh()
		check(session.train().ok and session.transport([0,1,0,2],"predictive").ok,"Learn and restore actual rules")
		check(session.set_mode("predict").ok and session.begin_prediction("practice").ok,"Connect real prediction")
		while not session.prediction.finished:
			session.commit_prediction(); session.reveal_prediction()
		check(session.set_mode("generate").ok,"Connect real feedback")
		scene.change_task(7); await settle()
		check(scene.find_child("PinCreationAQuick",true,false).disabled,"Pin unavailable without a visible generated run")
		scene.generate_work(); await settle()
		var original: Dictionary = session.generated.duplicate(true)
		scene.pin_creation_a(); await settle()
		check(scene.pinned_creation == original and scene.compared_creation.is_empty(),"A pins full actual run including recipe/training")
		check(not scene.find_child("Initial",true,false).editable and not scene.find_child("Seed",true,false).editable and not scene.find_child("Length",true,false).editable,"Initial/seed/length controls lock after pin")
		session.data.draft.examples.remove_at(1); scene.edit_draft(); scene.train_model(); scene.generate_work(); await settle()
		var b: Dictionary = session.generated.duplicate(true)
		check(scene.pinned_creation == original and b.output != original.output,"Retraining and B generation never mutate A")
		scene.pin_creation_a()
		check(scene.pinned_creation == original and scene.compared_creation == b,"Repeated pin cannot replace A or erase B without ending comparison")
		check(scene.creation_report.single and scene.creation_report.first_difference >= 0,"Workbench uses actual frozen recipes for report")
		for id: String in ["SignalView","Status","Generate","PinCreationAQuick","KeepCurrent"]:
			var node: Control = scene.find_child(id,true,false)
			check(root.get_visible_rect().encloses(node.get_global_rect()),"1280×720 mathematical bounds: "+id)
		check(scene.find_child("CreationComparisonCaption",true,false).text.contains("One controlled change" if english else "只改一项"),"Visible localized comparison summary is grounded in actual conditions")
		check(scene.signal_view.lanes[0] == original.output and scene.signal_view.lanes[2] == b.output,"Signal shows frozen A beside actual B")
		scene.change_task(3); await settle()
		scene.show_creation_difference(); await settle()
		check(scene.task == 7 and scene.signal_view.lanes[2] == b.output,"First-difference action returns from prediction view to actual B")
		check(scene.signal_view.cursor == scene.creation_report.first_difference and not scene.playing,"First-difference action pauses and locates actual cell")
		check(scene.signal_view.corrections == scene.creation_report.mismatches,"Difference marks reflect exact A/B mismatches")
		scene.build(); await settle()
		check(scene.pinned_creation == original and not scene.find_child("Seed",true,false).editable,"Rebuild/locale UI retains pin and locks")
		scene.change_task(3); await settle()
		scene.name_input.text = "Chosen A"; scene.choose_creation_result(false); await settle()
		check(scene.task == 8,"Keeping a comparison result opens creation save unit even from another mode view")
		check(session.data.works.size() == 1 and session.data.works[0].output == original.output and session.data.works[0].recipe == original.recipe,"Keep A saves A output with A complete recipe")
		check(session.replay_work(0).get("matches",false),"Saved A independently regenerates exactly")
		check(scene.compared_creation == b,"Keeping A retains B for later choice")
		scene.name_input.text = "Chosen B"; scene.choose_creation_result(true); await settle()
		check(session.data.works.size() == 2 and session.data.works[1].output == b.output and session.data.works[1].recipe == b.recipe,"Keep B saves B output and B recipe separately")
		check(session.replay_work(1).get("matches",false) and session.data.works[0].output == original.output,"Saved B replays; A saved snapshot remains intact")
		check(Session.decode(JSON.stringify(session.data)).ok,"Existing session schema accepts both chosen works unchanged")
		var frozen_a: Dictionary = scene.pinned_creation.duplicate(true)
		session.data.draft.sampler = "max"; scene.edit_draft(); scene.generate_work(); await settle()
		check(scene.pinned_creation == frozen_a and scene.creation_report.factor_count == 2,"Repeated B updates keep original A and disclose all changed conditions")
		scene.clear_creation_comparison(); await settle()
		check(scene.pinned_creation.is_empty() and scene.compared_creation.is_empty() and scene.find_child("Seed",true,false).editable,"Ending comparison unlocks controls and drops only temporary snapshots")
		check(session.data.works.size() == 2,"Ending comparison does not delete chosen works")
		scene.works.select(0); scene.play_work()
		check(scene.find_child("PinCreationA",true,false).disabled,"Snapshot playback refreshes pin availability immediately")
		scene.pin_creation_a()
		check(scene.pinned_creation.is_empty(),"Viewing a saved snapshot cannot accidentally pin hidden generated B")
		scene.generate_work(); scene.pin_creation_a(); scene.works.select(0); scene.fork_work(); await settle()
		check(scene.pinned_creation.is_empty(),"Explicit saved-work fork starts a new comparison boundary")
		scene.queue_free(); await settle()
	print("PASS: creation comparison %d checks" % checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
