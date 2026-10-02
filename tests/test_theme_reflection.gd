extends SceneTree
const Reflection = preload("res://src/ui/theme_reflection.gd")
const Overlap = preload("res://src/overlap_chapter/overlap_catalog.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _run() -> void:
	check(Reflection.milestones({},{},{},{},{}).size()==1,"Fresh players see no unearned findings")
	var hardware := {&"cpu":true}; var system := {&"cpu_speed":true}; var locality := {&"nearby_storage":true}
	var solution: Dictionary = Overlap.reference_solution("buffers")
	var temporal := {"buffers":solution,"synthesis":{}}
	var spatial := {"relocation":{},"mixed":{}}
	var snapshot: String = JSON.stringify([hardware,system,locality,temporal,spatial])
	var only_time: Array[StringName] = Reflection.milestones(hardware,system,locality,temporal,{})
	var only_space: Array[StringName] = Reflection.milestones(hardware,system,locality,{},spatial)
	check(&"theme.time_path" in only_time and &"theme.ending" not in only_time and &"theme.other_path" in only_time,"Time path alone never closes both paths")
	check(&"theme.position_path" in only_space and &"theme.ending" not in only_space,"Position path can finish first")
	check(&"theme.overlap" not in Reflection.milestones({},{},{},{"buffers":{}},{}),"A marker without actual positive-overlap evidence cannot reveal overlap prose")
	var keys: Array[StringName] = Reflection.milestones(hardware,system,locality,temporal,spatial)
	check(&"theme.ending" in keys and &"theme.overlap" in keys and &"theme.other_path" not in keys,"Joint closure follows both terminal tasks and verified overlap")
	check(JSON.stringify([hardware,system,locality,temporal,spatial])==snapshot,"Reflection cannot mutate progression or stored designs")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var dialog = Reflection.new();dialog.configure(keys,root.get_node("Localization").text);root.add_child(dialog)
		dialog.popup_centered(Vector2i(640,500))
		for frame: int in 3: await process_frame
		check(dialog.visible and dialog.get_ok_button().text!= "theme.close","Reopenable bilingual reflection exposes a close action")
		dialog.hide();dialog.queue_free();await process_frame
	if failures.is_empty():print("PASS: earned reflections, either branch order, joint ending and immutable progression")
	else:
		for failure: String in failures:push_error(failure)
	quit(0 if failures.is_empty() else 1)
