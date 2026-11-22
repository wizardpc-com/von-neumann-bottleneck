extends "res://tests/test_creation_workbench.gd"
## A real confirmed legal work closes creation; output variation is optional.
const Session = preload("res://experiments/creation/session.gd")

func prepare(path: String) -> RefCounted:
	var session = Session.new()
	check(session.open(path).get("writable",false),"Fresh owned choice fixture opens")
	session.data.draft.examples = [[0,0,0,0]]
	session.data.draft.order = 0
	check(session.train().ok and session.transport([0,0],"predictive").ok,"Real repeated sample learns and restores")
	check(session.set_mode("predict").ok and session.begin_prediction("practice").ok,"Same learned rules enter prediction")
	while not session.prediction.finished:
		check(session.commit_prediction().ok and session.reveal_prediction().ok,"Prediction commits before truth")
	check(session.set_mode("generate").ok,"Real prediction permits feedback generation")
	session.data.draft.initial = [0]; session.data.draft.length = 12; session.data.draft.sampler = "max"
	return session

func contracts() -> void:
	var session = prepare("user://choice/rollback.json")
	check(session.generate().ok,"Legal repeated work generated")
	session.complete("G2_intent",{"different_output":true,"passed":true})
	check(not session.data.supports.has("G2_intent"),"Unconfirmed generation and arbitrary UI flags cannot complete G2")
	var before: Dictionary = session.data.duplicate(true)
	var saved_bytes: String = FileAccess.get_file_as_string(session.path) if FileAccess.file_exists(session.path) else ""
	session.lease.release()
	check(not session.save_work("Uncommitted choice").ok,"Lost writer cannot confirm a work")
	check(session.data.works == before.works and session.data.supports == before.supports and session.dirty,"Failed save rolls back works/G2/G3 and retains prior dirty exploration")
	check((FileAccess.get_file_as_string(session.path) if FileAccess.file_exists(session.path) else "") == saved_bytes,"Failed confirmation cannot alter the saved file")
	session.close()

	session = prepare("user://choice/repeat.json")
	check(session.generate().ok,"Repeated legal output generated once")
	var output: Array = session.generated.output.duplicate()
	session.data.draft.seed += 1
	check(session.generate().ok and session.generated.output == output,"Deterministic repeated work stays identical across seeds")
	session.complete("G2_intent")
	check(not session.data.supports.has("G2_intent"),"Multiple identical generations alone remain unconfirmed")
	check(session.save_work("Repetition is my choice").ok,"Repeated work may be selected without an aesthetic score")
	check(session.data.supports.has("G2_intent") and session.data.supports.has("G3_keep"),"Confirmed repeated work closes G2 and G3 together")
	check(session.data.supports.G2_intent.output == output and session.data.supports.G2_intent.recipe == session.data.works[0].recipe,"Completion points to the actual selected output and complete recipe")
	var chosen: Dictionary = session.data.works[0].duplicate(true)
	session.close()
	var reopened = Session.new(); check(reopened.open("user://choice/repeat.json").get("writable",false),"Chosen repeated work reopens")
	check(reopened.data.works[0] == chosen and reopened.replay_work(0).get("matches",false) and reopened.data.supports.has("G2_intent"),"Reopen preserves confirmed choice and exact reproducibility")
	var observer = Session.new(); check(not observer.open("user://choice/repeat.json").get("writable",false),"Concurrent observer cannot become a confirming writer")
	observer.data.mode = "generate"; observer.generate()
	var observer_data: Dictionary = observer.data.duplicate(true)
	check(not observer.save_work("Readonly choice").ok and observer.data == observer_data,"Readonly confirmation rolls back without adding work or progress")
	observer.close(); reopened.close()

	# Historical generation-only G2 was a verified recipe, not a causal proof.
	# Preserve its completion/payload without reinterpreting it or clearing progress.
	session = prepare("user://choice/legacy-source.json"); session.generate()
	var legacy: Dictionary = session.data.duplicate(true)
	legacy.supports.G2_intent = {"kind":"generation","recipe":session.generated.recipe.duplicate(true),"output":session.generated.output.duplicate()}
	check(Session.decode(JSON.stringify(legacy)).ok,"Legacy verified unkept G2 remains readable")
	var file := FileAccess.open("user://choice/legacy.json",FileAccess.WRITE); file.store_string(JSON.stringify(legacy)); file.close(); session.close()
	var restored = Session.new(); check(restored.open("user://choice/legacy.json").get("writable",false),"Legacy choice profile opens safely")
	check(restored.data.supports == legacy.supports and restored.data.works.is_empty(),"Legacy progress is retained without manufacturing a chosen work")
	check(restored.save() == OK and Session.decode(FileAccess.get_file_as_string(restored.path)).data.supports == legacy.supports,"Legacy payload can be saved without a forced migration")
	restored.close()
	var broken: Dictionary = legacy.duplicate(true); broken.supports.G2_intent.output[0] = 3
	check(not Session.decode(JSON.stringify(broken)).ok,"Legacy compatibility still rejects a fabricated output")
	var future: Dictionary = legacy.duplicate(true); future.version = 2
	check(not Session.decode(JSON.stringify(future)).ok,"Future format cannot gain consent through compatibility")

func run() -> void:
	root.get_node("TaskNavigation").pending = ""
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout
	contracts()
	var packed: PackedScene = load("res://experiments/creation/workbench.tscn")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var scene: Control = packed.instantiate(); root.add_child(scene); await settle()
		var opened: Dictionary = scene.session.open("user://choice/rendered-"+locale+".json")
		scene.writable = opened.get("writable",false)
		check(scene.writable,"Bilingual UI uses a fresh writable choice profile")
		if not scene.writable: scene.queue_free(); quit(1); return
		scene.train_model(); scene.source_kind = 2; scene.transport("predictive")
		scene.switch_mode("predict"); scene.begin_prediction("practice")
		while not scene.session.prediction.finished: scene.commit_prediction(); scene.reveal_prediction()
		scene.change_task(7); await settle(); await press(scene,"ToGenerate")
		# The physical feedback switch opens G1. Select G2 after that real switch.
		scene.change_task(7); await settle()
		root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout
		check(scene.task == 7,"Choice is exercised in the actual G2 task after feedback switching")
		await press(scene,"Generate")
		check(scene.comparison.size() == 1 and not scene.session.data.supports.has("G2_intent"),"First legal work has no compulsory second-run mark")
		var first: Array = scene.latest.output.duplicate()
		await capture("g2-first-"+locale)
		scene.name_input.text = "One work is enough · "+locale
		await press(scene,"KeepCurrent")
		check(scene.session.data.works.size() == 1 and scene.session.data.works[0].output == first and scene.session.data.supports.has("G2_intent") and scene.session.data.supports.has("G3_keep"),"Actual Keep click closes G2 with one legal chosen work")
		await capture("g2-chosen-"+locale)
		scene.session.data.supports.erase("G2_intent") # Independent regression of the old automatic UI condition.
		var seed := control(scene,"Seed") as SpinBox
		seed.value += 891
		await press(scene,"Generate")
		check(scene.comparison.size() == 2 and scene.comparison[0].output != scene.comparison[1].output,"Seed-only variation creates two actually different outputs")
		check(not scene.session.data.supports.has("G2_intent"),"Seed-only different outputs cannot create an unconfirmed G2 mark")
		var earlier: Dictionary = scene.session.generated.duplicate(true)
		scene.session.data.draft.examples.append([3,1,3,1])
		scene.session.data.draft.order = (int(earlier.recipe.model.order)+1)%3
		scene.edit_draft()
		var initial := control(scene,"Initial") as LineEdit
		initial.text = "3, 2"
		initial.text_changed.emit(initial.text)
		seed.value += 1
		await press(scene,"Generate")
		var later: Dictionary = scene.session.generated.duplicate(true)
		var live_draft: Dictionary = scene.session.data.draft.duplicate(true)
		var expected_recipe: Dictionary = earlier.recipe.duplicate(true)
		expected_recipe.seed += 1
		expected_recipe.initial = [3,2]
		check(scene.pinned_creation.is_empty() and later.recipe == expected_recipe
			and scene.signal_view.lanes[0] == earlier.output and scene.signal_view.lanes[2] == later.output
			and scene.session.data.works.size() == 1,
			"Two actual runs use the frozen model while newer examples and history await learning")
		var title := "Chosen earlier variation · "+locale
		var initial_title := title if locale == "en" else ""
		scene.name_input.text = initial_title
		var custom := control(scene,"CustomExample") as LineEdit
		custom.text = "B D"
		var before_choice: PackedByteArray = FileAccess.get_file_as_bytes(scene.session.path)
		await press(scene,"KeepCreationA")
		check(scene.task == 8 and scene.latest.recipe == earlier.recipe and scene.signal_view.lanes[2] == earlier.output
			and scene.signal_view.lanes[0] == later.output and scene.session.data.works.size() == 1
			and scene.name_input.has_focus() and scene.name_input.text == initial_title and not scene.session.data.supports.has("G2_intent"),
			"Choosing the earlier run for naming brings it forward, retains the later run and awards nothing")
		custom = control(scene,"CustomExample") as LineEdit
		check(custom.text == "B D" and (control(scene,"Initial") as LineEdit).text == "3, 2"
			and scene.session.generated == earlier and scene.session.data.draft == live_draft
			and scene.signal_view.lanes[1] == earlier.recipe.initial,
			"Naming preserves editor text and later controls while the signal shows the earlier frozen input")
		custom.text = ""
		scene.request_saved_draft_leave()
		check(scene.leave_dialog.visible,"Leaving while naming offers a return to editing")
		scene.leave_dialog.get_cancel_button().pressed.emit()
		scene.leave_dialog.hide()
		await settle()
		check(FileAccess.get_file_as_bytes(scene.session.path) == before_choice and scene.session.data.draft == live_draft,
			"Selection and cancel leave the previous save bytes and editable draft intact")
		await press(scene,"SaveDraft")
		var reader = Session.new()
		var reopened: Dictionary = reader.open(scene.session.path)
		check(reopened.get("ok",false) and reader.data.works.size() == 1 and not reader.data.supports.has("G2_intent")
			and reader.data.draft == live_draft and reader.data.model == later.recipe.model and reader.generated.is_empty(),
			"A fresh reader sees the later draft and unlearned edits without a kept selection")
		reader.close()
		await capture("g3-earlier-selected-"+locale)
		scene.name_input.text = title
		await press(scene,"KeepCurrent")
		var protected_work: Dictionary = scene.session.data.works[-1].duplicate(true)
		check(protected_work.output == earlier.output and protected_work.recipe == earlier.recipe
			and protected_work.training == earlier.training and protected_work.parent == earlier.parent_work and protected_work.name == title
			and scene.session.data.draft == live_draft
			and scene.session.data.supports.G2_intent.recipe == earlier.recipe
			and not scene.session.data.supports.G2_intent.has("comparison"),
			"Keeping the earlier run saves its exact recipe and output as a free choice without a controlled receipt")
		reopened = reader.open(scene.session.path)
		check(reopened.get("ok",false) and reader.data.works.size() == 2 and reader.data.works[1] == protected_work
			and reader.data.draft == live_draft and reader.replay_work(1).get("matches",false),
			"Keep writes the selected frozen work and later editable draft together in the same save")
		reader.close()
		scene.name_input.text = "Chosen later variation · "+locale
		await press(scene,"KeepCreationB")
		check(scene.latest.recipe == later.recipe and scene.session.data.works.size() == 2,
			"Choosing the later run also waits for explicit Keep even with a title present")
		await press(scene,"KeepCurrent")
		check(scene.session.data.works.size() == 3 and scene.session.data.works[-1].recipe == later.recipe
			and scene.session.data.works[1] == protected_work,
			"The later run can still be kept without rerunning or overwriting the earlier work")
		(control(scene,"Works") as ItemList).select(1)
		await press(scene,"ReplayWork")
		check(scene.latest.get("matches",false) and scene.latest.output == earlier.output
			and scene.session.data.works[1] == protected_work,
			"Replaying the selected earlier work reproduces its protected output")
		var path: String = scene.session.path
		scene.queue_free(); await settle()
		scene = packed.instantiate(); root.add_child(scene); await settle()
		scene.writable = scene.session.open(path).get("writable",false)
		scene._clear_replaced_exploration(); scene.build(); await settle()
		check(scene.writable and scene.latest.is_empty() and scene.session.data.draft == live_draft
			and scene.session.data.works[1] == protected_work and scene.session.replay_work(1).get("matches",false),
			"Reopened workbench resumes pending edits even when a saved work matches the later generation recipe")
		await check_fork_and_retraining(scene,protected_work)
		scene.queue_free(); await settle()
	print("PASS: creation choice completion checks=",checks) if failures==0 else print("FAIL: choice completion failures=",failures," / ",checks)
	quit(0 if failures==0 else 1)

func check_fork_and_retraining(scene: Control, parent: Dictionary) -> void:
	scene.works.select(1)
	scene.fork_work()
	await press(scene,"SaveDraft")
	var path: String = scene.session.path
	scene.writable = scene.session.open(path).get("writable",false)
	scene._clear_replaced_exploration(); scene.build(); await settle()
	check(scene.writable and scene.latest.is_empty() and scene.comparison.is_empty()
		and scene.session.data.parent_work == parent.id and scene.next_step().action == "generate",
		"Reopening the unkept fork restores its parent and asks for a fresh generation")
	scene.generate_work()
	var child: Dictionary = scene.session.generated.duplicate(true)
	check(child.recipe == parent.recipe and child.output == parent.output and child.parent_work == parent.id
		and not scene.visible_generation_saved(),"A fork that reproduces its protected parent still needs its own Keep")
	(control(scene,"Seed") as SpinBox).value += 1
	scene.generate_work()
	var later: Dictionary = scene.session.generated.duplicate(true)
	var draft: Dictionary = scene.session.data.draft.duplicate(true)
	scene.name_input.text = "Child of earlier work"
	await press(scene,"KeepCreationA")
	check(scene.session.data.parent_work == parent.id and scene.session.data.works.size() == 3
		and scene.next_step().action == "keep","Selecting the identical child cannot finish on the parent's saved work")
	await press(scene,"KeepCurrent")
	var saved: Dictionary = scene.session.data.works[-1]
	check(saved.parent == parent.id and saved.recipe == child.recipe and saved.training == child.training
		and saved.output == child.output and scene.session.data.draft == draft and scene.session.data.works[1] == parent,
		"Explicit Keep saves the earlier child's frozen run under the fork and retains its later draft")
	var reader = Session.new()
	var opened: Dictionary = reader.open(scene.session.path)
	check(opened.get("ok",false) and reader.data.works.size() == 4 and reader.data.works[-1] == saved and reader.data.draft == draft
		and reader.data.parent_work == parent.id and reader.replay_work(3).get("matches",false),
		"An independent reopen replays the confirmed child and restores the later fork draft")
	reader.close()
	# Learn Y and return to X without generating Y. X has the original rule ID
	# but its full frozen model now records Y as its training parent.
	var order: int = later.recipe.model.order
	scene.session.data.draft.order = (order+1)%3
	scene.edit_draft(); scene.train_model()
	scene.session.data.draft.order = order
	scene.edit_draft(); scene.train_model(); scene.generate_work()
	var replacement: Dictionary = scene.session.generated.duplicate(true)
	check(scene.comparison[0] == later and replacement.recipe.model_id == later.recipe.model_id
		and replacement.recipe.model != later.recipe.model and replacement.parent_work == later.parent_work,
		"Retraining produces two adjacent real runs with equal rule IDs and different frozen models")
	var before: Dictionary = scene.session.data.duplicate(true)
	scene.choose_creation_result(false)
	check((control(scene,"KeepCreationA") as Button).disabled and (control(scene,"KeepCreationB") as Button).disabled
		and scene.session.generated == replacement and scene.latest.recipe == replacement.recipe and scene.session.data == before,
		"Recent selection cannot replace the current run with another model sharing its ID")
