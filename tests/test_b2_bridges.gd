extends SceneTree
## Isolated controller scenario: real capstone runs; no injected result records.
const Dialogues = preload("res://src/lab/chapter_dialogues.gd")
const Artifact = preload("res://src/lab/cinematic_artifact.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
var destination: String = "res://.godot/b2-before"
func _init() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence-dir="): destination = arg.trim_prefix("--evidence-dir=")
	call_deferred("run")
func snap(label: String) -> void:
	await create_timer(1.0).timeout
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		DirAccess.make_dir_recursive_absolute(destination)
		root.get_texture().get_image().save_png(destination.path_join(label + ".png"))
func run() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": root.get_node("Localization").set_locale("en")
	check(Dialogues.for_key("chapter_2/capstone") == Dialogues.DIALOGUES["chapter_2/capstone"], "Missing records retain original dialogue")
	ProjectSettings.set_setting("playtest/offline_tester", true)
	root.size = Vector2i(1280,720)
	root.content_scale_size = Vector2i(1280,720)
	change_scene_to_file("res://src/ui/prototype_hub.tscn")
	await create_timer(4.0).timeout
	var hub: Control = current_scene
	var lab: Control = hub.get_node("Laboratory")
	lab._on_room_action("terminal")
	await create_timer(2.0).timeout
	lab.terminal.message.complete_now()
	await snap("terminal")
	hub._open_journey_journal()
	await snap("journal")
	hub.journey_journal.close()
	root.get_node("TaskNavigation").open_tree()
	await process_frame
	await process_frame
	await snap("map")
	change_scene_to_file("res://src/ui/main.tscn")
	await create_timer(1.0).timeout
	var locality: Control = current_scene
	locality._start_level(&"capstone")
	locality._run_simulation("Official Test Set")
	locality._finish_playback()
	locality._select_judgment(&"repeated_far_fetch")
	locality._select_cache(4,true)
	locality._run_simulation("Official Test Set")
	locality._finish_playback()
	locality._select_cache(1,true)
	locality._select_block_lines(1,true)
	locality._run_simulation("Official Test Set")
	locality._finish_playback()
	locality._show_capstone_summary()
	await snap("completion")
	check(root.get_node("LocalityChapter").game_completed.get(&"capstone",false), "Real runs earn capstone completion")
	var beats: Array = Dialogues.for_key("chapter_2/capstone")
	for language: String in ["zh", "en"]:
		check(beats[0][language].contains("642") and beats[0][language].contains("138"), "Exact real cycle counts in " + language)
	beats[0].zh = "changed"
	check(Dialogues.for_key("chapter_2/capstone")[0].zh != "changed", "Presentation is detached from catalog and records")
	root.get_node("GameMode").set_mode(&"test")
	check(Dialogues.for_key("chapter_2/capstone") == Dialogues.DIALOGUES["chapter_2/capstone"], "Test never quotes Game achievements")
	await Artifact.present_prologue(current_scene, {})
	check(current_scene.get_node_or_null("CinematicArtifact") == null, "Test opens no artifact")
	root.get_node("GameMode").set_mode(&"game")
	change_scene_to_file("res://src/ui/prototype_hub.tscn")
	await create_timer(2.0).timeout
	hub = current_scene
	lab = hub.get_node("Laboratory")
	lab._on_room_action("terminal")
	await create_timer(1.0).timeout
	lab.preview_chapter_dialogue()
	lab.terminal.message.complete_now()
	await snap("dialogue")
	check(lab.terminal.choices.get_child_count() == 2, "Both replies available")
	for choice: Button in lab.terminal.choices.get_children():
		check(choice.size.x > 200 and choice.size.y < 100, "Replies readable at 720p")
	await Artifact.present_prologue(hub, {})
	check(hub.get_node_or_null("CinematicArtifact") == null, "Missing machine evidence opens no artifact")
	await verify_representation()
	print("%s: %d/%d B2 bridge checks" % ["PASS" if failures == 0 else "FAIL",checks-failures,checks])
	quit(0 if failures == 0 else 1)

func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":int(ends[i]),"codec":codecs[i]})
		start = int(ends[i])
	return result

func verify_representation() -> void:
	var region: Control = preload("res://experiments/representation_region/region.gd").new()
	root.add_child(region)
	region.persistent_session = false
	var solutions: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	await Artifact.present_representation(region)
	check(region.get_node_or_null("CinematicArtifact") == null, "Incomplete support opens no artifact")
	for task: int in 5:
		region.change_task(task); region.edit_plan(solutions[task]); region.run_current()
	Artifact.present_representation(region)
	await process_frame
	var dialog: Control = region.get_node_or_null("CinematicArtifact")
	check(dialog != null and dialog.visible, "Five real accepted results open artifact")
	if dialog != null:
		var body: String = dialog.find_child("ArtifactBoundary",true,false).text
		check(body.contains("Temporary") or body.contains("临时"), "Temporary results retain save boundary")
		var panel: Control = dialog.find_child("ArtifactPanel",true,false)
		check(preload("res://src/ui/guide_stage.gd").blocked(self), "Artifact quiets underlying opening and guide")
		check(root.get_visible_rect().encloses(panel.get_global_rect()), "Artifact panel fits the 720p viewport")
		var tiles: BoxContainer = dialog.find_child("ArtifactTiles",true,false)
		check(tiles.get_child_count() == 5, "All five accepted tasks have a tile")
		var evidence: Array[Dictionary] = region.representation_review_evidence()
		for i: int in 5:
			var tile: Control = tiles.get_child(i)
			var text: String = ""
			for label: Node in tile.find_children("*","Label",true,false): text += label.text + "\n"
			for metrics: Dictionary in evidence[i].metrics:
				check(text.contains("%d B" % metrics.stored_bytes) and text.contains(str(metrics.total_cycles)), "Tile quotes revalidated storage and cycles")
			check(panel.get_global_rect().encloses(tile.get_global_rect()), "Tile fits inside card")
		await snap("artifact")
		var enter := InputEventKey.new()
		enter.keycode = KEY_ENTER; enter.pressed = true
		Input.parse_input_event(enter)
	# Parsed input reaches the viewport on a later frame under load; allow a few frames.
	for _frame: int in 5:
		await process_frame
		if region.get_node_or_null("CinematicArtifact") == null: break
	check(region.get_node_or_null("CinematicArtifact") == null, "Dismissal frees artifact and resumes caller")
	Artifact.present_representation(region)
	await process_frame
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE; escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	await process_frame
	check(region.get_node_or_null("CinematicArtifact") == null, "Escape dismisses artifact")
	region.queue_free()
