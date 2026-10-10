extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for i: int in 8: await process_frame
func capture(name: String) -> void:
	if "--service-number-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	DirAccess.make_dir_recursive_absolute("res://.godot/service-number-captures")
	check(root.get_texture().get_image().save_png("res://.godot/service-number-captures/"+name+".png") == OK,"Actual minimum-size review "+name)
func run() -> void:
	check(Lab.display_number(0.0) == "0", "Exact zero remains zero")
	check(Lab.display_number(0.004695456036745401) == "0.00469546", "Score summary uses six significant digits")
	check(Lab.display_number(0.006157708508183714) == "0.00615771", "State summary uses the same precision")
	check(Lab.display_number(9.999999) == "10", "Rounding carries to the next exponent")
	for value: float in [1e-300, -1e-30, 1e-9, 1e300]:
		var shown: String = Lab.display_number(value)
		check(shown.length() <= 12 and shown.to_float() != 0.0, "Finite nonzero errors remain visible: " + shown)
	check(Lab.display_number(INF) != "0" and Lab.display_number(NAN) != "0", "Nonfinite evidence cannot masquerade as zero")
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var scene := Lab.new(); root.add_child(scene); await settle()
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_size(Vector2i(1280,720)); await create_timer(0.4).timeout; await settle()
	var grouped: Dictionary = Model.initial_plan(); grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	scene.edit(grouped,0); scene.run_current(); scene.continue_service()
	var exact: Dictionary = Model.initial_plan(); exact.slots = 4
	exact.representations = ["rle64","rle64","raw64","raw64"]
	scene.edit(exact,0); scene.run_current(); scene.continue_service()
	var quantized: Dictionary = Model.initial_plan(); quantized.slots = 4
	quantized.representations = ["raw8","raw8","raw8","raw8"]
	scene.edit(quantized,0); scene.run_current()
	check(scene.task == 2 and scene.has_service_closure(), "Actual accepted plans earn three-contract review")
	var m: Dictionary = scene.history[-1].metrics
	check(m.max_error > 0.0 and m.max_state_error > 0.0 and Model.accepted(m,2), "Review includes actual accepted nonzero quantization errors")
	var history_before: String = JSON.stringify(scene.history)
	var supports_before: String = JSON.stringify(scene.support_plans)
	for en: bool in [false,true]:
		scene.english = en; scene.build(); await settle()
		scene.select_run(scene.history.size()-1)
		var bill: String = scene.measured_bill_text(scene.history[-1])
		scene.show_closure(); await settle()
		var review := scene.get_node("ServiceReview") as AcceptDialog
		var content: String = review.find_child("ServiceReviewContent",true,false).text
		for key: String in ["max_error","max_state_error"]:
			var compact: String = Lab.display_number(m[key])
			var full: String = String.num_scientific(m[key])
			check(scene.summary.text.contains(compact) and bill.contains(compact) and content.contains(compact), "Overview, bill and review share readable precision: " + key)
			check(compact == full or not content.contains(full), "Review avoids full-double wrapping: " + key)
		await capture("review-"+("en" if en else "zh"))
		review.hide()
		var boundary: Dictionary = m.duplicate(true); boundary.max_error = 0.020000000001
		var boundary_before: String = JSON.stringify(boundary)
		var feedback: String = scene.measured_feedback(boundary,2)
		check(not Model.accepted(boundary,2) and feedback.contains("over limit" if en else "超限") and feedback.contains(Lab.display_number(boundary.max_error-0.02)), "Rounded equality never hides an actual quality-limit violation")
		check(JSON.stringify(boundary) == boundary_before, "Formatting does not mutate boundary metrics")
	check(JSON.stringify(scene.history) == history_before and JSON.stringify(scene.support_plans) == supports_before, "Bilingual display preserves raw records and protected recipes")
	scene.queue_free(); await process_frame
	print("PASS: test_service_number_display " if failures == 0 else "FAIL: test_service_number_display ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
