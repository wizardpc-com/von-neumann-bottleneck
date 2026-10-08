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
		scene.session.data.draft.seed += 891; scene.edit_draft(); await press(scene,"Generate")
		check(scene.comparison.size() == 2 and scene.comparison[0].output != scene.comparison[1].output,"Seed-only variation creates two actually different outputs")
		check(not scene.session.data.supports.has("G2_intent"),"Seed-only different outputs cannot create an unconfirmed G2 mark")
		scene.name_input.text = "Chosen variation · "+locale; await press(scene,"KeepCurrent")
		check(scene.session.data.supports.G2_intent.output == scene.session.data.works[-1].output,"Chosen variation is legitimate when actually selected")
		scene.queue_free(); await settle()
	print("PASS: creation choice completion checks=",checks) if failures==0 else print("FAIL: choice completion failures=",failures," / ",checks)
	quit(0 if failures==0 else 1)
