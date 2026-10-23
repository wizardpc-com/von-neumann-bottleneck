extends Node

const Region = preload("res://experiments/representation_region/region.gd")
const Cinematic = preload("res://src/ui/cinematic_player.gd")
const EVIDENCE := "E:/VNB/game/docs/verification/20261023-chapter5-cinematic"
var checks: int = 0
var failures: int = 0
var finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(20.0, true).timeout.connect(func() -> void:
		if not finished:
			push_error("CHAPTER5_GPU watchdog exceeded 20 seconds")
			get_tree().quit(1))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print("CHAPTER5_GPU ", "PASS " if ok else "FAIL ", message)
	if not ok:
		failures += 1
		push_error(message)

func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = 0
	for index: int in ends.size():
		result.append({"start":start,"end":int(ends[index]),"codec":codecs[index]})
		start = int(ends[index])
	return result

func screenshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	check(not image.is_empty(), "GPU framebuffer contains an image")
	check(image.save_png(EVIDENCE.path_join(filename)) == OK, "Screenshot saved: " + filename)

func has_modal(node: Node) -> bool:
	for child: Node in node.get_children():
		if child is Window and (child as Window).visible:
			return true
		if has_modal(child): return true
	return false

func run() -> void:
	var user_dir: String = OS.get_user_data_dir().replace("\\", "/")
	print("CHAPTER5_GPU user_dir=", user_dir, " display=", DisplayServer.get_name())
	check(user_dir.contains("Chapter5CinematicGpuChecks/"), "Explicit isolated QA user directory")
	check(DisplayServer.get_name() != "headless", "Ordinary GPU display")
	check(not Cinematic.automated_launch(), "Real presenter accepts ordinary Game launch")
	check(not FileAccess.file_exists(Cinematic.HISTORY_PATH), "Fresh isolated cinematic history")
	if failures > 0:
		get_tree().quit(1)
		return
	ProjectSettings.set_setting("game/full_journey", true)
	var effects_bus: int = AudioServer.get_bus_index(&"Effects")
	check(effects_bus >= 0, "Effects audio bus exists")
	if effects_bus >= 0: AudioServer.set_bus_mute(effects_bus, true)
	var mode: Node = get_node("/root/GameMode")
	mode.set_mode(&"game")
	var region := Region.new()
	region.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(region)
	await get_tree().process_frame
	check(region.candidate_journey and region.persistent_session, "Real full-journey persistent region")
	check(region.writer_lease != null and region.writer_lease.held, "Isolated session writer lease acquired")
	var solutions: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for task: int in 5:
		region.change_task(task)
		region.edit_plan(solutions[task])
		if task == 4: region.save_blocked = true
		region.run_current()
		check(region.completed[task] and bool(region.history[-1].accepted), "Real accepted run T%d" % task)
		if task < 4:
			await get_tree().process_frame
			check(get_tree().get_nodes_in_group("cinematic_playback").is_empty(), "Partial chapter does not play")
	var selected: int = region.selected_run
	var result_text: String = region.status.text
	await get_tree().create_timer(1.25, true).timeout
	var players: Array[Node] = get_tree().get_nodes_in_group("cinematic_playback")
	check(players.size() == 1, "Fifth accepted run opens actual cinematic")
	check(get_tree().paused, "Cinematic pauses the scene tree")
	check(not region.can_process(), "Cinematic pauses actual region processing")
	if players.size() != 1:
		get_tree().quit(1)
		return
	var player: CinematicPlayer = players[0] as CinematicPlayer
	check(player.clip_id == &"chapter5_complete", "Correct chapter5 clip")
	check(player.video.bus == &"Effects", "Actual video routes to muted QA Effects bus")
	check(player.video.is_playing() and not player.video.paused and player.video.stream_position > 0.25, "Actual video playback advances while tree is paused")
	var history := ConfigFile.new()
	check(history.load(Cinematic.HISTORY_PATH) == OK and bool(history.get_value("watched", "chapter5_complete", false)), "Watching record consumed chapter5")
	check(region.selected_run == selected and selected == 4 and region.status.text == result_text and not result_text.is_empty(), "Selected accepted result retained during CG")
	check(region.save_blocked and region.session_dirty, "Blocked writer retains unsaved result during CG")
	await screenshot("godot-playback.png")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	get_viewport().push_input(escape, true)
	await get_tree().process_frame
	escape = InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = false
	get_viewport().push_input(escape, true)
	await get_tree().process_frame
	check(not get_tree().paused and get_tree().get_nodes_in_group("cinematic_playback").is_empty(), "Viewport Escape skips and restores pause state")
	check(region.can_process(), "Skipping restores region processing")
	check(is_instance_valid(region) and region.is_inside_tree() and region.visible and not has_modal(get_tree().root), "Region remains visible without a modal")
	check(region.selected_run == selected and region.status.text == result_text and region.session_dirty and region.save_blocked, "Skip retains selected result and unsaved blocked session")
	await screenshot("result-after.png")
	region.run_current()
	await get_tree().process_frame
	await get_tree().process_frame
	check(get_tree().get_nodes_in_group("cinematic_playback").is_empty() and not get_tree().paused, "Repeating accepted run does not replay CG")
	check(region.history.size() == 6 and region.selected_run == 5 and region.session_dirty, "Repeated run remains in the real region")
	finished = true
	print("CHAPTER5_GPU_RESULT checks=", checks, " failures=", failures)
	get_tree().quit(1 if failures > 0 else 0)
