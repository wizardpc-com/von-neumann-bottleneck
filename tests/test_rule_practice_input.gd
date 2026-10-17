extends SceneTree
## Synthetic viewport input and optional rendered evidence, not OS or novice testing.
## Tutorial completion below is an availability fixture, never a played solution.

const HARDWARE := "res://src/hardware_foundations/hardware_foundations.tscn"
var failures: Array[String] = []
var checks: int = 0
var capture_enabled: bool = false


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in 6:
		await process_frame


func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()


func click(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()


func wheel(scroll: ScrollContainer, direction: MouseButton) -> void:
	var point: Vector2 = scroll.get_global_rect().get_center()
	for tick: int in 8:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = direction
		event.pressed = true
		root.push_input(event, true)
		await process_frame
	await settle()


func capture(name: String) -> void:
	if not capture_enabled:
		return
	await RenderingServer.frame_post_draw
	var folder := "res://.godot/polish/rule-practice/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	check(root.get_texture().get_image().save_png(folder + name + ".png") == OK,
		"Rendered isolated-rule evidence saves: " + name)


func check_state(view: Variant, expected: Array, message: String) -> void:
	check(view.logic_example().outputs == expected, message)
	check(view.input_buttons[0].button_pressed == (int(view.logic_example().a) == 1),
		"A's displayed selection follows the actual example value")
	if view.diagram_id != &"gate_not":
		check(view.input_buttons[1].button_pressed == (int(view.logic_example().b) == 1),
			"B's displayed selection follows the actual example value")


func run() -> void:
	capture_enabled = "--rule-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var save: Node = root.get_node("GlobalSave")
	var localization: Node = root.get_node("Localization")
	var offline: Node = root.get_node("OfflineFeedback")
	var old_offline: Variant = ProjectSettings.get_setting("playtest/offline_tester", false)
	ProjectSettings.set_setting("playtest/offline_tester", true)
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://rule-practice-save.json", "user://rule-practice-workbench.json")
	save.game_player_content.completed_levels[&"tutorial"] = true
	print("FIXTURE: isolated tutorial completion opens AND/half-adder rules; no lesson was played or earned by this suite.")
	check(change_scene_to_file(HARDWARE) == OK, "Actual hardware host loads")
	await settle()
	var host: Variant = current_scene
	if host == null or host.scene_file_path != HARDWARE:
		quit(1)
		return
	var handbook: Variant = host.terminology_handbook
	var view: Variant = handbook.detail_diagram
	var signature: String = save.game_player_content.canonical_signature()
	var board: Dictionary = host._capture_workbench_snapshot().duplicate(true)
	var completed: Dictionary = host.completed_levels.duplicate(true)
	for locale: String in ["zh_CN", "en"]:
		localization.set_locale(locale)
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1440, 900)]:
			root.size = dimensions
			root.content_scale_size = dimensions
			await settle()
			for term: StringName in [&"not_gate", &"and_gate", &"half_adder"]:
				handbook.open_handbook(term)
				await settle()
				check(handbook.is_open() and view.visible and handbook.is_term_unlocked(term),
					"Requested real handbook entry is available: %s %s %s" % [locale, dimensions, term])
				var a: Button = view.input_buttons[0]
				var b: Button = view.input_buttons[1]
				var scroll: ScrollContainer = handbook.detail_scroll_container
				scroll.ensure_control_visible(a)
				await settle()
				check(scroll.get_global_rect().encloses(a.get_global_rect()) and root.get_visible_rect().encloses(a.get_global_rect()),
					"A can be reached through the handbook's detail scroll")
				await click(a)
				check(int(view.logic_example().a) == 1, "Viewport click changes A from 0 to 1")
				check(root.gui_get_focus_owner() == a, "Actual pointer click gives A keyboard focus")
				if term == &"not_gate":
					check_state(view, [0], "NOT 1 produces 0 rather than a universally lit lamp")
					await key(KEY_SPACE)
					check_state(view, [1], "Focused NOT input toggles by Space")
					await key(KEY_SPACE)
					check_state(view, [0], "Second Space restores NOT 1 to 0")
					await key(KEY_TAB)
					check(root.gui_get_focus_owner() != a and root.gui_get_focus_owner() != null,
						"Tab leaves NOT input through the existing handbook focus order")
				else:
					check(int(view.logic_example().b) == 0, "Changing A preserves independent B")
					check_state(view, [0] if term == &"and_gate" else [1, 0], "Mixed inputs follow their actual rule")
					if dimensions == Vector2i(1280, 720):
						await capture("%s-%s-mixed" % [locale, term])
					scroll.ensure_control_visible(b)
					await settle()
					await click(b)
					check(int(view.logic_example().a) == 1 and int(view.logic_example().b) == 1,
						"Actual B click preserves A and selects both high")
					check_state(view, [1] if term == &"and_gate" else [0, 1], "Both-high outputs match AND / half-adder")
					await click(a)
					check(int(view.logic_example().a) == 0 and int(view.logic_example().b) == 1,
						"Actual A click does not change B")
					await key(KEY_TAB)
					check(root.gui_get_focus_owner() == b, "Tab travels from A to B without test-installed focus links")
					await key(KEY_SPACE)
					check(int(view.logic_example().a) == 0 and int(view.logic_example().b) == 0,
						"Space on B changes B alone")
					await click(a)
					await click(b)
				if dimensions == Vector2i(1280, 720):
					await capture("%s-%s-active" % [locale, term])
				var before_scroll: int = scroll.scroll_vertical
				await wheel(scroll, MOUSE_BUTTON_WHEEL_DOWN)
				check(scroll.scroll_vertical > before_scroll or scroll.get_v_scroll_bar().max_value <= scroll.size.y,
					"Wheel reaches deeper rule/definition content when it overflows")
				scroll.ensure_control_visible(a)
				await settle()
				check(scroll.get_global_rect().encloses(a.get_global_rect()), "Input remains reachable after exploring deeper rules")
				await click(a)
				var focused: Control = root.gui_get_focus_owner()
				var value_before_feedback: Dictionary = view.logic_example().duplicate(true)
				# parse_input_event updates Input's action state, which the real F8 poll reads.
				for down: bool in [true, false]:
					var event := InputEventKey.new()
					event.keycode = KEY_F8
					event.physical_keycode = KEY_F8
					event.pressed = down
					Input.parse_input_event(event)
					await settle()
				check(offline.backdrop.visible and paused and handbook.is_open(), "Actual F8 action opens feedback over the handbook and pauses")
				await key(KEY_ESCAPE)
				check(not offline.backdrop.visible and not paused and handbook.is_open(), "Escape closes feedback before the handbook")
				check(root.gui_get_focus_owner() == focused and view.logic_example() == value_before_feedback,
					"Feedback returns the actual prior focus and isolated example state")
				await key(KEY_ESCAPE)
				check(not handbook.is_open(), "Next Escape returns to the existing circuit host")
				check(save.game_player_content.canonical_signature() == signature and host.completed_levels == completed,
					"Rule practice and feedback grant no player-content or completion changes")
				check(host._capture_workbench_snapshot() == board, "Actual player circuit survives every rule practice untouched")
	ProjectSettings.set_setting("playtest/offline_tester", old_offline)
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "isolated rule practice viewport input (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)
