extends SceneTree
## Empty temporary workbenches: no model runs, saved recipes or completion fixtures.
## Runtime loading leaves autoload compilation to the normal project importer.
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 8: await process_frame
func open_workbench(path: String) -> Control:
	var script: Script = load(path)
	var scene = script.new()
	if path != "res://experiments/prediction/lab.gd": scene.persistent_session = false
	scene.candidate_journey = false
	root.add_child(scene)
	await settle()
	return scene
func close_workbench(scene: Control) -> void:
	scene.queue_free()
	await settle()
func is_english(scene: Control) -> bool:
	return scene.get("english") == true
func run_caption(scene: Control) -> String:
	var control := scene.find_child("Run",true,false) as Button
	return control.text if control != null else ""
func progress() -> Dictionary:
	var snapshot: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	snapshot.erase("saved_at_utc")
	return snapshot

func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var localization: Node = root.get_node("Localization")
	var original_locale: String = localization.current_locale()
	var original_auto_quit: bool = auto_accept_quit
	var before: Dictionary = progress()
	var paths: Array[String] = ["res://experiments/representation_region/region.gd","res://experiments/service_plan/lab.gd","res://experiments/prediction/lab.gd"]
	for locale: String in ["en","zh_CN"]:
		for index: int in paths.size():
			localization.set_locale(locale)
			var scene: Control = await open_workbench(paths[index])
			var expected_english: bool = locale == "en"
			check(is_english(scene) == expected_english,"Shared language inherited on entry: "+paths[index]+" / "+locale)
			check(not run_caption(scene).is_empty(),"Language check observes actual Run control")
			check(run_caption(scene).contains("Run") if expected_english else run_caption(scene).contains("运行"),"Run control uses inherited language")
			if index != 2: check(not scene.get("persistent_session"),"Language check stays in a temporary workbench")
			check(scene.get("history").is_empty(),"Language entry creates no measured evidence")
			check(scene.has_method("toggle_language"),"Workbench offers the shared-language toggle")
			if scene.has_method("toggle_language"): scene.call("toggle_language")
			await settle()
			expected_english = not expected_english
			check(is_english(scene) == expected_english,"Toggle changes workbench language")
			check(localization.current_locale() == ("en" if expected_english else "zh_CN"),"Toggle publishes the shared language for the next stage")
			check(run_caption(scene).contains("Run") if expected_english else run_caption(scene).contains("运行"),"Toggle rebuilds actual controls in the selected language")
			check(scene.get("history").is_empty(),"Toggle creates no measured run or completion evidence")
			await close_workbench(scene)
			var next_path: String = paths[(index+1)%paths.size()]
			var next: Control = await open_workbench(next_path)
			check(is_english(next) == expected_english,"Next stage retains the toggled language: "+next_path)
			check(run_caption(next).contains("Run") if expected_english else run_caption(next).contains("运行"),"Next stage's actual Run control retains the language")
			check(next.get("history").is_empty(),"Next-stage entry remains unrun")
			await close_workbench(next)
			check(auto_accept_quit == original_auto_quit,"Temporary scene transitions restore window-close behavior")
	localization.set_locale(original_locale)
	check(progress() == before,"Language entry/toggle/navigation grants no campaign progress or saved plan")
	print("PASS: test_candidate_language_navigation " if failures == 0 else "FAIL: test_candidate_language_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
