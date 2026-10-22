extends SceneTree
## Real scene transitions with viewport keys; QA saves contain no earned results.
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 12) -> void:
	for frame: int in frames: await process_frame
func key(code: Key, echo: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code
		event.pressed = down; event.echo = echo and down
		root.push_input(event, true); await process_frame
	await settle()
func home() -> void:
	root.get_node("TaskNavigation").from_tree = false
	change_scene_to_file("res://src/ui/prototype_hub.tscn"); await settle()
	await create_timer(0.4).timeout
func enter_terminal() -> void:
	await create_timer(0.4).timeout
	var lab: Control = current_scene.laboratory
	lab.terminal.wake(true); await settle()
	check(lab.next_key == "hardware_foundations/tutorial", "New-player terminal is bound to the first lesson")
	check(lab.terminal.primary.text.contains("第一条线路") or lab.terminal.primary.text.contains("first line"), "Terminal advertises the first lesson")
	lab.terminal.message.complete_now(); lab.terminal.primary.grab_focus()
	await key(KEY_ENTER); await create_timer(0.15).timeout; await settle()
	check(current_scene.scene_file_path == "res://src/hardware_foundations/hardware_foundations.tscn", "Terminal Enter opens the advertised hardware workbench")
	check(root.get_node("TaskNavigation").selected == "hardware_foundations/tutorial", "Terminal enters the advertised task instead of the previous visit")

func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", true)
	var nav: Node = root.get_node("TaskNavigation")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		await home()
		# Work wall intentionally opens the saved-work task (internal G3).
		(current_scene.laboratory.find_child("WorkFrame", true, false) as Button).pressed.emit()
		await create_timer(0.15).timeout; await settle()
		check(current_scene.scene_file_path == "res://experiments/creation/workbench.tscn" and current_scene.task == 8, "Work wall opens G3 / 10-3")
		await key(KEY_ESCAPE)
		check(current_scene.scene_file_path == nav.MAP_SCENE, "Creation Esc returns to its journey map")
		await key(KEY_ESCAPE)
		check(current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn", "Map Esc returns to the laboratory once")
		await enter_terminal()
		await home()
		(current_scene.laboratory.find_child("JourneyBoard", true, false) as Button).pressed.emit()
		await create_timer(0.15).timeout; await settle()
		check(current_scene.scene_file_path == nav.MAP_SCENE, "Journey board opens the real map")
		check(nav.enter("creation/C2_cost"), "Map task is available")
		await settle()
		check(current_scene.task == 1, "Map enters the chosen creation task")
		await key(KEY_ESCAPE); await key(KEY_ESCAPE)
		await enter_terminal()
		# A held Esc must not take the next map step.
		await home(); nav.open_tree(); await settle()
		await key(KEY_ESCAPE, true)
		check(current_scene.scene_file_path == nav.MAP_SCENE, "Map ignores key repeat")
		await key(KEY_ESCAPE)
		check(not current_scene.laboratory.terminal.confirming(), "Scene-changing Esc does not also ask to quit")
	# Prerequisite access is an explicit fixture; no completion is awarded.
	root.get_node("GameMode").set_mode(&"test")
	check(nav.enter("chapter_4/fields"), "Layout fixture opens")
	await settle()
	var layout: Control = current_scene
	var before: Dictionary = layout.design.duplicate(true)
	layout._hint_advance(); await settle()
	root.get_node("WindowMode").open_settings(); await settle()
	await key(KEY_ESCAPE)
	check(current_scene == layout and layout.hint_layer.visible and not is_instance_valid(root.get_node("WindowMode").settings_layer), "Settings Esc closes only settings above Layout Hint")
	layout._hint_request(); await settle()
	var guarded_escape := InputEventKey.new()
	guarded_escape.keycode = KEY_ESCAPE; guarded_escape.pressed = true
	layout._input(guarded_escape)
	check(layout.confirmation.visible and layout.hint_layer.visible and current_scene == layout, "The native hint confirmation owns Escape before the underlying Hint")
	layout.confirmation.hide(); await settle()
	await key(KEY_ESCAPE)
	check(current_scene == layout and not layout.hint_layer.visible, "Layout Esc closes Hint before leaving")
	await key(KEY_ESCAPE, true)
	check(current_scene == layout, "Layout ignores Esc repeat")
	check(layout.design == before, "Closing Hint preserves the design")
	await key(KEY_ESCAPE)
	check(current_scene.scene_file_path == nav.MAP_SCENE, "Layout Esc returns to the map")
	if current_scene != null: current_scene.queue_free(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "lab terminal routing %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
