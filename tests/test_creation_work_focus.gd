extends SceneTree
const Focus = preload("res://experiments/creation/work_focus.gd")
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
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var session = scene.session
	session.train(); session.transport([0,1,0,2],"predictive"); session.set_mode("predict"); session.begin_prediction()
	while not session.prediction.finished: session.commit_prediction(); session.reveal_prediction()
	session.set_mode("generate"); scene.change_task(8); await settle()
	scene.generate_work(); scene.name_input.text = "实际光纹 Actual saved signal"; scene.keep_work(); await settle()
	var saved: Dictionary = session.data.works[0].duplicate(true)
	var data: String = JSON.stringify(session.data)
	var generated: String = JSON.stringify(session.generated)
	var latest: String = JSON.stringify(scene.latest)
	var file: String = FileAccess.get_file_as_string(session.path)
	for english: bool in [false,true]:
		scene.english = english; scene.works.select(0); scene.focus_work(); await settle()
		check(is_instance_valid(scene.work_focus) and scene.work_focus.visible, "Saved work opens a focus window")
		check(scene.work_focus.canvas.output == saved.output and scene.work_focus.work == saved, "Focus uses actual protected snapshot")
		check(scene.work_focus.transient and scene.work_focus.exclusive, "Focus is modal to its workbench")
		check(scene.work_focus.recipe_label.text.contains(saved.recipe.model_id) and scene.work_focus.recipe_label.text.contains("→"), "Saved model provenance and rules remain available")
		var count: int = saved.output.size()
		check(scene.work_focus.canvas.cell_rect(count-1).end.y <= scene.work_focus.canvas.custom_minimum_size.y, "Every saved output cell is inside scrollable canvas")
		scene.work_focus.select_cell(count-1)
		check(scene.work_focus.canvas.selected == count-1 and str(count) in scene.work_focus.position_label.text, "Last cell can be selected and located")
		scene.signal_view.cursor = 7; scene.playing = true; scene._process(0.5)
		check(scene.signal_view.cursor == 7, "Background playback does not move while focusing")
		var same_window: Window = scene.work_focus
		scene.focus_work()
		check(scene.work_focus == same_window, "Repeated open does not create stacked windows")
		scene.work_focus.dismiss(); await settle()
		check(not is_instance_valid(scene.work_focus), "Closing focus returns to original workbench")
		check(JSON.stringify(session.data)==data and JSON.stringify(session.generated)==generated and JSON.stringify(scene.latest)==latest and FileAccess.get_file_as_string(session.path)==file, "Focus/close does not alter draft, generated output, visible result or disk")
		scene.playing = false
	# Return from exhibition, make an actual controlled B, save and exhibit it.
	scene.change_task(7); await settle()
	scene.pin_creation_a()
	session.data.draft.examples.remove_at(1); scene.edit_draft(); scene.train_model(); scene.generate_work()
	check(scene.creation_report.get("controlled_effect",false), "After viewing, ordinary controlled comparison still works")
	var b: Array = scene.compared_creation.output.duplicate()
	scene.name_input.text = "After focus B"; scene.choose_creation_result(true); await settle()
	check(session.data.works.size()==2 and session.data.works[0]==saved and session.data.works[1].output==b, "Return→compare→save adds B while preserving A")
	scene.works.select(1); scene.focus_work(); await settle()
	check(scene.work_focus.canvas.output==b and scene.work_focus.work.recipe==session.data.works[1].recipe, "Second exhibition shows B with B provenance")
	var escape := InputEventKey.new(); escape.pressed=true; escape.keycode=KEY_ESCAPE
	scene.work_focus._unhandled_key_input(escape); await settle()
	check(not is_instance_valid(scene.work_focus), "Escape returns without replacing the workbench")
	scene.writable = false; scene.focus_work(); await settle()
	check(scene.work_focus.visible and scene.work_focus.canvas.output==b, "Read-only works remain available for focused viewing")
	scene.work_focus.dismiss(); await settle()
	check(session.data.works.size()==2, "Read-only exhibition adds no work or write")
	# Full-size outputs use scroll space, not silent clipping/truncation.
	var long_work: Dictionary = saved.duplicate(true)
	long_work.output = []
	for i: int in 4096: long_work.output.append(i%4)
	var view = Focus.new(); view.configure(long_work,false); scene.add_child(view); view.popup_centered_clamped(Vector2i(1080,620),0.92); await settle()
	check(view.canvas.output.size()==4096 and view.canvas.cell_rect(4095).end.y<=view.canvas.custom_minimum_size.y, "All 4096 valid snapshot cells remain reachable")
	view.select_cell(4095); check(view.canvas.selected==4095, "Maximum output retains final symbol")
	view.dismiss(); await settle()
	var future: Dictionary = saved.duplicate(true); future.recipe = {"version":99,"model":"future representation"}
	view = Focus.new(); view.configure(future,true); scene.add_child(view); view.popup_centered(); await settle()
	check(view.canvas.output==saved.output and not view.recipe_label.text.is_empty(), "Unknown recipe metadata does not block viewing validated output")
	view.dismiss(); await settle()
	for version_key: String in ["sampler_version","prng_version"]:
		future = saved.duplicate(true); future.recipe[version_key] = "future-v99"; future.recipe.initial = [9]
		view = Focus.new(); view.configure(future,true); scene.add_child(view); view.popup_centered(); await settle()
		check(view.canvas.output==saved.output and "cannot be interpreted" in view.recipe_label.text and "Initial passage" not in view.recipe_label.text, "Unknown "+version_key+" preserves snapshot without inventing source metadata")
		view.dismiss(); await settle()
	scene.queue_free(); await settle()
	print("PASS: creation work focus %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
