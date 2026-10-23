extends SceneTree

const Workbench = preload("res://experiments/creation/workbench.gd")
const Cinematic = preload("res://src/ui/cinematic_player.gd")

class ProfileSession:
	extends "res://experiments/creation/session.gd"
	var profile_path: String
	var fail_save: bool = false
	func open(_save_path: String = "") -> Dictionary:
		return super.open(profile_path)
	func save() -> Error:
		if fail_save:
			error = "save:injected_failure"
			return ERR_CANT_CREATE
		return super.save()

class ObservedWorkbench:
	extends "res://experiments/creation/workbench.gd"
	var presentations: int = 0
	var result_ready: bool = false
	func _present_ending_cinematic() -> void:
		presentations += 1
		result_ready = not kept_work.is_empty() and kept_work == session.data.works[-1] \
			and selected_work() == session.data.works.size()-1 and not session.dirty \
			and session.data.supports.has("G3_keep")

var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle() -> void:
	for frame: int in 4: await process_frame

func make(path: String, observed: bool = true) -> Control:
	root.get_node("TaskNavigation").pending = ""
	var scene: Control = ObservedWorkbench.new() if observed else Workbench.new()
	var profile := ProfileSession.new()
	profile.profile_path = path
	scene.session = profile
	root.add_child(scene)
	return scene

func prepare_generation(scene: Control) -> void:
	scene.train_model(); scene.transport("predictive"); scene.switch_mode("predict"); scene.change_task(3)
	scene.begin_prediction("practice"); scene.commit_prediction(); scene.reveal_prediction(); scene.continue_prediction(false)
	scene.switch_mode("generate"); scene.change_task(6); scene.generate_work()
	check(scene.can_keep_visible_work(),"Ending fixture uses a real learned model, prediction and generated work")

func history_bytes() -> PackedByteArray:
	return FileAccess.get_file_as_bytes(Cinematic.HISTORY_PATH) if FileAccess.file_exists(Cinematic.HISTORY_PATH) else PackedByteArray()

func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run ending cinematic checks through the isolated verifier.")
		quit(1)
		return
	ProjectSettings.set_setting("game/full_journey",true)
	var base: String = "user://ending-cinematic/"+Crypto.new().generate_random_bytes(8).hex_encode()
	var path: String = base.path_join("session.json")
	var before_history: PackedByteArray = history_bytes()
	var history_existed: bool = FileAccess.file_exists(Cinematic.HISTORY_PATH)
	var scene: Control = make(path)
	await settle()
	prepare_generation(scene)
	scene.name_input.text = "Chapter10 first work"; scene.keep_work(); await settle()
	check(scene.presentations == 0 and scene.session.data.supports.has("G3_keep"),"Keeping in task6 earns original supports without playing the ending")
	scene.change_task(7); scene.generate_work(); scene.name_input.text = "Chapter10 choice"; scene.keep_work(); await settle()
	check(scene.presentations == 0 and scene.session.data.works.size() == 2,"Keeping in task7 does not play the last-task cinematic")
	scene.queue_free(); await settle()

	scene = make(path); await settle()
	check(scene.presentations == 0 and scene.session.data.supports.has("G3_keep"),"Loading an existing G3 support does not automatically play the new film")
	scene.change_task(8); scene.generate_work(); scene.name_input.text = ""
	scene.keep_work(); await settle()
	check(scene.presentations == 0 and scene.session.data.works.size() == 2,"An unnamed last-task work cannot trigger an ending")
	var before_file: PackedByteArray = FileAccess.get_file_as_bytes(path)
	var before_data: Dictionary = scene.session.data.duplicate(true)
	scene.name_input.text = "Final saved work"; scene.session.fail_save = true
	scene.keep_work(); await settle()
	check(scene.presentations == 0 and scene.session.data == before_data and FileAccess.get_file_as_bytes(path) == before_file,"Failed work save rolls back and never requests an ending")
	scene.session.fail_save = false
	scene.keep_work()
	check(scene.presentations == 0,"Successful Keep finishes its UI refresh before requesting playback")
	await settle()
	check(scene.presentations == 1 and scene.result_ready,"An explicit successful task8 Keep presents after the saved work and selection refresh")
	check(scene.session.data.works.size() == 3,"The ending hook adds no extra saved work")
	scene.queue_free(); await settle()

	scene = make(path); await settle()
	check(scene.presentations == 0,"Reloading a completed final-task profile never autoplays the ending")
	scene.generate_work(); scene.name_input.text = "Another explicit final choice"; scene.keep_work(); await settle()
	check(scene.presentations == 1 and scene.result_ready,"A new deliberate task8 Keep can request the film for a pre-existing completed profile")
	scene.queue_free(); await settle()

	ProjectSettings.set_setting("game/full_journey",false)
	scene = make(base.path_join("standalone.json")); await settle()
	prepare_generation(scene); scene.change_task(8); scene.generate_work()
	scene.name_input.text = "Standalone work"; scene.keep_work(); await settle()
	check(scene.presentations == 0 and scene.session.data.works.size() == 1,"Standalone creation retains its ordinary Keep without a journey ending")
	scene.queue_free(); await settle()

	ProjectSettings.set_setting("game/full_journey",true)
	scene = make(base.path_join("automated.json"),false); await settle()
	prepare_generation(scene); scene.change_task(8); scene.generate_work()
	scene.name_input.text = "Automated final work"; scene.keep_work(); await settle()
	scene._present_ending_cinematic(); scene._present_ending_cinematic(); await settle()
	check(get_nodes_in_group("cinematic_playback").is_empty() and not paused,"Automated Keep and repeated presenter calls do not open a cinematic")
	var mode: Node = root.get_node("GameMode")
	var previous_mode: StringName = mode.current_mode
	mode.set_mode(&"test"); scene._present_ending_cinematic(); await settle()
	check(get_nodes_in_group("cinematic_playback").is_empty(),"Test mode suppresses ending playback")
	mode.set_mode(previous_mode)
	check(history_bytes() == before_history and FileAccess.file_exists(Cinematic.HISTORY_PATH) == history_existed,"Automation and Test never consume or rewrite ending history")
	scene.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ")+"ending cinematic %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
