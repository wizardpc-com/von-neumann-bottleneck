extends SceneTree

var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func settle() -> void:
	for frame: int in 12: await process_frame

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/terminal-mode-previews")
	root.get_texture().get_image().save_png("res://.godot/terminal-mode-previews/" + name + ".png")

func run() -> void:
	ProjectSettings.set_setting("game/reduced_motion", true)
	var mode: Node = root.get_node("GameMode")
	var save: Node = root.get_node("GlobalSave")
	var signature: String = save.game_player_content.canonical_signature()
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1280,800)]:
			root.size = dimensions
			var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
			root.add_child(hub); await settle()
			var lab: Control = hub.laboratory
			var terminal: Control = lab.terminal
			if locale == "zh_CN" and dimensions == Vector2i(1280,720):
				check(terminal.asleep(), "A fresh visit keeps the existing standby terminal")
			lab.open_terminal(); await create_timer(0.5).timeout; await settle()
			check(terminal.mode_picker.is_visible_in_tree(), "Mode choices are visible when the terminal is opened")
			check(terminal.primary.is_visible_in_tree(), "The original Start/Continue card remains visible")
			check(terminal.primary.custom_minimum_size == Vector2(600,88), "The existing primary card keeps its dimensions")
			var bounds: Rect2 = terminal.get_global_rect()
			for item: Control in [terminal.game_mode_button, terminal.test_mode_button, terminal.mode_note, terminal.primary, terminal.secondary]:
				check(bounds.encloses(item.get_global_rect()), "Terminal content fits in %s %s: %s" % [locale,dimensions,item.name])
			check(terminal.game_mode_button.button_pressed and not terminal.test_mode_button.button_pressed, "Game is initially selected")
			await capture("%s-%dx%d-game" % [locale,dimensions.x,dimensions.y])
			terminal.test_mode_button.pressed.emit(); await settle()
			check(mode.is_test_mode() and terminal.test_mode_button.button_pressed and not terminal.game_mode_button.button_pressed, "The terminal selects the real Test mode")
			check(not mode.developer_tools_enabled(), "Test selection grants no developer capture tools")
			check(save.game_player_content.canonical_signature() == signature, "Test selection preserves real Game progress")
			await capture("%s-%dx%d-test" % [locale,dimensions.x,dimensions.y])
			mode.set_mode(mode.MODE_GAME); await settle()
			check(terminal.game_mode_button.button_pressed, "An external mode change updates terminal selection")
			terminal.test_mode_button.pressed.emit(); terminal.game_mode_button.pressed.emit(); await settle()
			check(not mode.is_test_mode() and save.game_player_content.canonical_signature() == signature, "Returning to Game preserves genuine player results")
			terminal.play_dialogue([{"zh":"对话", "en":"Conversation", "replies":[]}]); await settle()
			check(not terminal.mode_picker.is_visible_in_tree(), "Story dialogue owns the terminal without mode controls")
			terminal._end_dialogue(); await settle()
			check(terminal.mode_picker.is_visible_in_tree(), "Mode controls return with the existing main menu")
			hub.queue_free(); await settle()
	root.get_node("Localization").set_locale("zh_CN")
	print(("PASS: " if failures == 0 else "FAIL: ") + "terminal modes %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
