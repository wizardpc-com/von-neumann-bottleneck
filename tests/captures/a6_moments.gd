extends SceneTree
## Presentation fixture: Test workbench; catalog completion copy; real representation runs.
var destination: String = "res://.godot/a6-before"
func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): destination = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")
func snap(key: String) -> void:
	await create_timer(0.35).timeout
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(destination)
	root.get_texture().get_image().save_png(destination.path_join(key + ".png"))
func run() -> void:
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1600,900)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": root.get_node("Localization").set_locale("en")
	ProjectSettings.set_setting("game/yi_text_speed", "instant")
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("TaskNavigation").pending = "chapter_4/fields"
	change_scene_to_file("res://src/layout_chapter/layout_chapter.tscn")
	await create_timer(2.0).timeout
	var opening = preload("res://src/ui/yi_opening.gd").present(self,&"chapter_4",&"fields",true)
	await snap("opening")

	preload("res://src/ui/yi_opening.gd").dismiss()
	var help: Control = load("res://src/ui/yi_help_card.gd").new()
	current_scene.add_child(help)
	help.english = root.get_node("Localization").current_locale() == "en"
	help.position = Vector2(24,150)
	help.size.x = 460
	var context: Dictionary = preload("res://src/ui/mission_narrative_catalog.gd").task_context(&"chapter_4",&"fields",help.english)
	help.present(str(context.action), [{"id":"close","zh":"关闭","en":"Close"}])
	await snap("help")
	for card in root.find_children("YiHelpCard","",true,false): card.close()
	help.queue_free()
	var overlay: Control = load("res://src/ui/level_completion_overlay.gd").new()
	current_scene.add_child(overlay)
	var en: bool = root.get_node("Localization").current_locale() == "en"
	overlay.present(&"fields","","Fields inspected" if en else "字段读取检查完成", "", &"chapter_4",false)
	await create_timer(0.8).timeout
	await snap("completion")
	overlay.dismiss()
	preload("res://src/ui/ui_cue.gd").met(current_scene,true)
	await snap("repeat")
	current_scene.queue_free()
	await process_frame
	root.get_node("GameMode").set_mode(&"game")
	var region: Control = load("res://experiments/representation_region/region.gd").new()
	root.add_child(region)
	region.persistent_session = false
	var solutions: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for task: int in 5:
		region.change_task(task); region.edit_plan(solutions[task]); region.run_current()
	preload("res://src/lab/cinematic_artifact.gd").present_representation(region)
	preload("res://src/ui/yi_opening.gd").dismiss()
	await snap("artifact")
	region.get_node("CinematicArtifact").dismissed.emit()
	region.queue_free()
	await process_frame
	var creation: Control = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(creation)
	await create_timer(1.0).timeout
	preload("res://src/ui/ui_cue.gd").met(creation, true)
	var cue: Control = creation.get_node("UiMetCue")
	cue.set_process(false)
	# Reproduce the W5 caller's immediate placement without changing its source.
	cue.position = creation.provenance.global_position - creation.global_position + Vector2(creation.provenance.size.x - cue.size.x - 16, 0)
	await snap("creation-repeat-local")
	cue.set_process(true)
	await snap("creation-repeat")
	var safe: bool = is_equal_approx(cue.get_global_rect().end.x, root.get_visible_rect().size.x - 16.0)
	for node: Node in get_nodes_in_group(&"workbench_nav"):
		if node is Control and node.is_visible_in_tree():
			safe = safe and cue.get_global_rect().position.y >= node.get_global_rect().end.y + 10.0
	for button: Node in creation.find_children("*", "BaseButton", true, false):
		if button.is_visible_in_tree(): safe = safe and not cue.get_global_rect().intersects(button.get_global_rect())
	print("W5 local placement yields to safe canvas anchor: ", safe)
	creation.queue_free()
	await process_frame
	quit(0 if safe else 1)
func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":int(ends[i]),"codec":codecs[i]})
		start = int(ends[i])
	return result
