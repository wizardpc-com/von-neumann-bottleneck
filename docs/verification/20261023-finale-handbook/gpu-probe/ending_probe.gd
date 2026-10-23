extends Node

const Workbench = preload("res://experiments/creation/workbench.gd")
const Cinematic = preload("res://src/ui/cinematic_player.gd")
const CreationTasks = preload("res://src/campaign/creation_tasks.gd")
const EVIDENCE := "E:/VNB/game/docs/verification/20261023-finale-handbook"
const PROFILE := "user://ending-gpu/session.json"

class ProfileSession:
	extends "res://experiments/creation/session.gd"
	var profile_path: String
	func open(_save_path: String = "") -> Dictionary:
		return super.open(profile_path)

var checks: int = 0
var failures: int = 0
var finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().create_timer(30.0,true).timeout.connect(func() -> void:
		if not finished:
			push_error("ENDING_GPU watchdog exceeded 30 seconds")
			get_tree().quit(1))
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	print("ENDING_GPU ","PASS " if ok else "FAIL ",message)
	if not ok: failures += 1; push_error(message)

func settle(frames: int = 5) -> void:
	for frame: int in frames: await get_tree().process_frame

func screenshot(filename: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	check(not image.is_empty(),"GPU framebuffer contains an image")
	check(image.save_png(EVIDENCE.path_join(filename)) == OK,"Screenshot saved: "+filename)

func make_workbench() -> Control:
	get_node("/root/TaskNavigation").pending = ""
	var scene: Control = Workbench.new()
	var profile := ProfileSession.new(); profile.profile_path = PROFILE
	scene.session = profile
	scene.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(scene)
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return scene

func prepare_generation(scene: Control) -> void:
	scene.train_model()
	scene.transport("predictive")
	scene.switch_mode("predict"); scene.change_task(3)
	scene.begin_prediction("practice")
	scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.change_task(6); scene.generate_work()
	check(scene.can_keep_visible_work(),"Actual learning, transport, commit/reveal and generation produce a saveable work")

func no_playback() -> bool:
	return get_tree().get_nodes_in_group("cinematic_playback").is_empty() and not get_tree().paused

func run() -> void:
	var user_dir: String = OS.get_user_data_dir().replace("\\","/")
	print("ENDING_GPU user_dir=",user_dir," display=",DisplayServer.get_name())
	check(user_dir.contains("FinaleCinematicGpuChecks/"),"Explicit isolated QA user directory")
	check(DisplayServer.get_name() != "headless","Ordinary GPU display")
	check(not FileAccess.file_exists(PROFILE) and not FileAccess.file_exists(Cinematic.HISTORY_PATH),"Fresh isolated work profile and viewing history")
	if failures > 0: get_tree().quit(1); return
	get_node("/root/GameMode").set_mode(&"game")
	ProjectSettings.set_setting("game/full_journey",true)
	ProjectSettings.set_setting("game/reduced_motion",true)
	check(not Cinematic.automated_launch(),"Ordinary Game launch enables the real cinematic presenter")
	var effects: int = AudioServer.get_bus_index(&"Effects")
	check(effects >= 0,"Effects audio bus exists")
	if effects >= 0: AudioServer.set_bus_mute(effects,true)
	if failures > 0: get_tree().quit(1); return
	var scene: Control = make_workbench()
	await settle()
	check(scene.writable and scene.session.path == PROFILE,"Real session acquires the isolated profile")
	prepare_generation(scene)
	scene.change_task(7); scene.generate_work()
	scene.name_input.text = "GPU task7 choice"; scene.keep_work()
	await settle()
	check(scene.session.data.works.size() == 1 and not scene.session.dirty and FileAccess.file_exists(PROFILE),"Task7 Keep persists the actual work")
	check(no_playback(),"Task7 save does not play the ending")
	scene.change_task(8); scene.generate_work()
	scene.name_input.text = "GPU final choice"; scene.keep_work()
	check(no_playback(),"Task8 Keep completes its saved UI before deferred presentation")
	check(scene.session.data.works.size() == 2 and not scene.session.dirty,"Task8 Keep commits exactly one new work")
	var saved: Dictionary = scene.kept_work.duplicate(true)
	var selected: int = scene.selected_work()
	var disk: PackedByteArray = FileAccess.get_file_as_bytes(PROFILE)
	await get_tree().create_timer(1.25,true).timeout
	var players: Array[Node] = get_tree().get_nodes_in_group("cinematic_playback")
	check(players.size() == 1 and get_tree().paused and not scene.can_process(),"Real ending pauses the actual workbench")
	if players.size() != 1: get_tree().quit(1); return
	var movie: CinematicPlayer = players[0] as CinematicPlayer
	check(movie.clip_id == &"journey_complete","Final task presents the correct clip")
	check(movie.video.is_playing() and movie.video.stream_position > 0.25 and movie.video.bus == &"Effects","Actual muted GPU video advances during tree pause")
	check(scene.kept_work == saved and scene.selected_work() == selected and selected == 1,"Saved work and selection remain intact during the film")
	var history := ConfigFile.new()
	check(history.load(Cinematic.HISTORY_PATH) == OK and bool(history.get_value("watched","journey_complete",false)),"Viewing history records the ending before playback")
	await screenshot("ending-playback.png")
	for down: bool in [true,false]:
		var escape := InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = down
		get_viewport().push_input(escape,true); await get_tree().process_frame
	await settle()
	check(no_playback() and scene.can_process(),"Viewport Escape skips and restores workbench processing")
	check(scene.kept_work == saved and scene.selected_work() == selected and not scene.session.dirty,"Skipping restores the selected protected work")
	check(FileAccess.get_file_as_bytes(PROFILE) == disk,"Playback and skip do not rewrite the work profile")
	await screenshot("ending-saved-work.png")
	scene.generate_work(); scene.name_input.text = "GPU another choice"; scene.keep_work()
	await settle()
	check(no_playback() and scene.session.data.works.size() == 3,"Another successful task8 Keep does not replay the ending")
	scene.queue_free(); await settle()
	Cinematic._consumed.clear()
	CreationTasks.saved.clear(); CreationTasks.cached_path = ""; CreationTasks.fingerprint = ""
	scene = make_workbench(); await settle()
	check(scene.writable and scene.task == 8 and scene.session.data.works.size() == 3,"Fresh session reloads all protected works on the final task")
	check(no_playback(),"Reload after clearing process caches never autoplays")
	prepare_generation(scene)
	scene.change_task(8); scene.generate_work(); scene.name_input.text = "GPU reloaded choice"; scene.keep_work()
	await settle()
	check(no_playback() and scene.session.data.works.size() == 4,"Persisted viewing history prevents replay after cache reset and another real Keep")
	scene.queue_free(); await settle()
	finished = true
	print("ENDING_GPU_RESULT checks=",checks," failures=",failures)
	get_tree().quit(1 if failures > 0 else 0)
