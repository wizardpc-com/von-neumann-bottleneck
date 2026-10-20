extends SceneTree
## Real viewport input; slow typing is a timing fixture, not a gameplay change.
const Opening = preload("res://src/ui/yi_opening.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
const LabState = preload("res://src/lab/lab_state.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 5) -> void:
	for frame: int in frames: await process_frame
func capture(name: String) -> void:
	if "--polish-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	RenderingServer.force_draw(false)
	var folder: String = "res://.godot/polish-captures/"
	DirAccess.make_dir_recursive_absolute(folder)
	check(root.get_texture().get_image().save_png(folder + name + ".png") == OK, "Rendered capture " + name)
func input_key(code: Key, unicode: int = 0) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.unicode = unicode; event.pressed = down
		root.push_input(event, true); await process_frame

func run() -> void:
	root.size = Vector2i(1280, 720)
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		ProjectSettings.set_setting("game/reduced_motion", false)
		for keyboard: bool in [true, false]:
			root.get_node("TaskNavigation").pending = "creation/C1_restore"
			var bench: Control = load("res://experiments/creation/workbench.tscn").instantiate()
			root.add_child(bench); current_scene = bench; await settle()
			Opening.dismiss(); await settle(2); Opening.reset_shown(); Typewriter.reset_seen()
			var opening: CanvasLayer = Opening.present(self, &"creation", &"C1_restore", true)
			await settle(2)
			opening.body._speed = 5.0
			await create_timer(0.7).timeout
			check(opening.body.is_playing(), "The real opening line is still typing before input")
			var before: Dictionary = bench.session.data.duplicate(true)
			if keyboard:
				var entry := bench.find_child("CustomExample", true, false) as LineEdit
				entry.text = "A B"; entry.caret_column = entry.text.length(); entry.grab_focus()
				await input_key(KEY_Q, 81)
				check(entry.text == "A BQ", "The opening never consumes typed input")
			else:
				var action := bench.find_child("ExpandEvidence", true, false) as Button
				var point: Vector2 = action.get_global_rect().get_center()
				for down: bool in [true, false]:
					var event := InputEventMouseButton.new()
					event.position = point; event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
					root.push_input(event, true); await process_frame
				check(bench.evidence_expanded, "The opening never consumes a workbench click")
			await create_timer(0.65).timeout
			check(not is_instance_valid(opening), "Starting work dismisses the opening without waiting for typing")
			check(bench.session.data == before, "Dismissing the opening changes no model, draft, work or completion")
			if keyboard: capture(locale + "-typing")
			Opening.dismiss(); bench.queue_free(); await settle()

		ProjectSettings.set_setting("game/reduced_motion", true)
		LabState._visits = 0
		var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(hub); current_scene = hub; await settle()
		var terminal: Control = hub.laboratory.terminal
		check(is_equal_approx(hub.laboratory.modulate.a, 1.0), "Reduced-motion laboratory appears without a room fade")
		check(terminal.asleep(), "Reduced-motion room starts on standby")
		terminal._process(0.0)
		var alpha: float = terminal.cursor.modulate.a
		terminal._process(0.4)
		check(is_equal_approx(alpha, terminal.cursor.modulate.a), "Reduced motion keeps the standby indicator steady")
		terminal.wake()
		check(is_equal_approx(terminal.awake_view.modulate.a, 1.0), "Reduced-motion wake shows the terminal immediately")
		check(not terminal.message.is_playing(), "Reduced-motion terminal text stays immediate")
		await settle(2)
		capture(locale + "-reduced-wake")
		hub.queue_free(); await settle()
		var returning: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
		root.add_child(returning); current_scene = returning; await settle()
		check(not returning.laboratory.zooming and is_zero_approx(returning.laboratory.fade.modulate.a), "Reduced-motion return has no arrival fade or input delay")
		returning.queue_free(); await settle()

		Opening.reset_shown(); Typewriter.reset_seen()
		var opening: CanvasLayer = Opening.present(self, &"creation", &"C1_restore", true)
		await settle(2)
		opening._life = 0.1
		opening.card.modulate.a = 0.0
		opening._process(0.01)
		var hovered: bool = opening.card.get_global_rect().grow(8).has_point(opening.card.get_global_mouse_position())
		check(is_equal_approx(opening.card.modulate.a, 0.15 if hovered else 1.0), "Reduced-motion opening changes opacity without an animated fade")
		opening._life = 0.7
		await input_key(KEY_Q, 81); await settle(2)
		check(not is_instance_valid(opening), "Reduced-motion input dismisses the opening without a closing fade")
		Opening.dismiss(); await settle()
	print(("PASS: " if failures == 0 else "FAIL: ") + "terminal presentation polish %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
