extends SceneTree
## Rendered known-answer demonstration, not native input or novice acceptance.
const Service = preload("res://experiments/service_plan/model.gd")
var output: String
var captures: Array[String] = []

func _init() -> void: call_deferred("run")

func settle() -> void:
	for frame: int in 8: await process_frame

func fit(scene: Control) -> void:
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mode = Window.MODE_WINDOWED
	await create_timer(1.0).timeout
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	await create_timer(0.4).timeout
	await settle()

func capture(name: String) -> void:
	await settle()
	RenderingServer.force_draw(false)
	var image: Image = root.get_texture().get_image()
	if image.get_size() != Vector2i(1280,720) or image.save_png(output.path_join(name+".png")) != OK:
		push_error("Capture failed: "+name); quit(1); return
	captures.append(name+".png")

func run() -> void:
	if DisplayServer.get_name() == "headless" or not OS.get_user_data_dir().replace("\\", "/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Requires rendered engine and isolated QA profile"); quit(1); return
	output = ProjectSettings.globalize_path("res://.godot/representative-captures")
	DirAccess.make_dir_recursive_absolute(output)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var rep = load("res://experiments/representation_region/region.gd").new()
		root.add_child(rep); await fit(rep)
		rep.change_task(3); rep.run_current()
		await capture(locale+"-preparation-baseline")
		rep.change_task(4); rep.run_current()
		await capture(locale+"-cross-asset-baseline")
		# Existing accepted recipes for rendering the earned handoff only.
		var plans: Array = [
			[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}],
			[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":24,"codec":"rle"},{"start":24,"end":40,"codec":"raw"},{"start":40,"end":48,"codec":"rle"},{"start":48,"end":64,"codec":"rle"}],
			[{"start":0,"end":16,"codec":"rle"},{"start":16,"end":48,"codec":"rle"},{"start":48,"end":64,"codec":"rle"}],
			[{"start":0,"end":8,"codec":"raw"},{"start":8,"end":64,"codec":"rle"}],
			[{"start":0,"end":18,"codec":"rle"},{"start":18,"end":46,"codec":"raw"},{"start":46,"end":64,"codec":"rle"}]]
		for task: int in 5:
			rep.change_task(task)
			var plan: Array[Dictionary] = []; plan.assign(plans[task])
			rep.edit_plan(plan); rep.run_current()
		if rep.representation_review_evidence().size() != 5:
			push_error("Representation fixture no longer meets contracts"); quit(1); return
		rep.candidate_journey = true; rep.show_closure()
		await capture(locale+"-earned-representation-handoff")
		rep.queue_free(); await settle()
		var lab = load("res://experiments/service_plan/lab.gd").new()
		root.add_child(lab); await fit(lab)
		await capture(locale+"-service-entry")
		var grouped: Dictionary = Service.initial_plan(); grouped.groups = []
		for id: int in 24: grouped.groups.append([id])
		lab.edit(grouped,0); lab.run_current()
		await capture(locale+"-state-reuse")
		lab.change_task(1)
		await capture(locale+"-response-handoff")
		lab.run_current()
		await capture(locale+"-waiting-evidence")
		var prompt: Dictionary = Service.initial_plan(); prompt.slots = 4
		lab.edit(prompt,0); lab.run_current()
		lab.response_chart.step_response()
		await capture(locale+"-first-response")
		lab.show_response_history()
		await capture(locale+"-matching-state-evidence")
		lab.queue_free(); await settle()
	var file := FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"kind":"rendered_model_fixture","native_input":false,"novice_acceptance":false,"saved_player_progress":false,"size":[1280,720],"captures":captures},"  "))
	print("PASS: representative experience renders; authored fixtures only. "+output)
	quit(0)
