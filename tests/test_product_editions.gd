extends SceneTree
## Edition access is separate from earned completion; run in isolated QA only.
const Mode = preload("res://src/game/game_mode.gd")
const Identity = preload("res://src/game/build_identity.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message)

func run() -> void:
	check(OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"), "Isolated QA profile required")
	if not failures.is_empty():
		quit(1)
		return
	var mode: Node = root.get_node("GameMode")
	var save: Node = root.get_node("GlobalSave")
	var navigation: Node = root.get_node("TaskNavigation")
	var signature: String = save.game_player_content.canonical_signature()
	var prior: Variant = ProjectSettings.get_setting("game/edition", null)
	for edition: String in ["game", "test"]:
		ProjectSettings.set_setting("game/edition", edition)
		var probe := Mode.new()
		root.add_child(probe)
		var expected: StringName = &"test" if edition == "test" else &"game"
		check(probe.current_mode == expected, "Edition selects its actual startup mode")
		check(probe.edition_locked() and not probe.developer_tools_enabled(), "Edition is locked without developer cheats")
		check(not probe.set_mode(&"game" if edition == "test" else &"test"), "Opposite mode cannot be selected")
		check(probe.set_mode(expected), "Current mode remains accepted")
		check(probe.capture_arguments().is_empty(), "Edition rejects developer capture arguments")
		check(preload("res://experiments/creation/session.gd").launch_path(PackedStringArray(["--creation-profile=user://wrong-profile.json"])) == "user://creation-candidate/session.json", "Edition refuses developer save path overrides")
		probe.queue_free()
		mode.current_mode = expected
		mode.mode_changed.emit(expected)
		var tasks: Array = navigation.journey_tasks()
		check(tasks.size() == 60, "Both editions include exactly sixty tasks")
		var unlocked: int = 0
		var completed: int = 0
		for task: Dictionary in tasks:
			if task.unlocked: unlocked += 1
			if task.completed: completed += 1
		check(unlocked == 60 if edition == "test" else unlocked < 60, "Only Test bypasses entrance prerequisites")
		check(completed == 0, "Entrance access does not create completion")
		var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub)
		for frame: int in 8: await process_frame
		var terminal: Control = hub.find_child("TerminalModePicker", true, false)
		check(terminal != null and not terminal.visible, "Released terminal hides mode switching")
		hub.call("_open_options_menu")
		check(hub.find_child("SettingsGameMode", true, false) == null, "Released settings hide mode switching")
		check(hub.find_child("EditionBuildIdentity", true, false) != null, "Support page exposes exact build identity")
		check(Identity.snapshot().edition == edition, "Diagnostics identify the edition")
		hub.queue_free()
		for frame: int in 8: await process_frame
		if edition == "test":
			var service: Control = load("res://experiments/service_plan/lab.tscn").instantiate()
			root.add_child(service)
			for frame: int in 8: await process_frame
			check(service.persistent_session and not service.save_blocked, "Test Edition can retain real service recipes in its own profile")
			service.save_session()
			check(service.notice_key == "saved", "Explicit Test Edition service save succeeds")
			service.queue_free()
			for frame: int in 8: await process_frame
		check(save.game_player_content.canonical_signature() == signature, "Access and settings never grant Game rewards")
	ProjectSettings.set_setting("game/edition", prior)
	mode.current_mode = &"game"
	mode.mode_changed.emit(&"game")
	check(mode.set_mode(&"test") and mode.set_mode(&"game"), "Source development keeps explicit mode switching")
	if failures.is_empty(): print("PASS: product editions ", checks, " checks")
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
