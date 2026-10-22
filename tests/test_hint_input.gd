extends SceneTree
## Viewport input checks; floating-panel overlap is an explicit layout fixture.
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame
func key(code: Key, echo: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code
		event.pressed = down; event.echo = down and echo
		root.push_input(event, true); await process_frame
	await settle()
func click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point; root.push_input(motion, true)
	await process_frame
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down; root.push_input(event, true)
		await process_frame
	await settle()
func capture(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--hint-input-capture"): return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://.godot/hint-input")
	root.get_texture().get_image().save_png("res://.godot/hint-input/" + name + ".png")

func run() -> void:
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"game")
	root.get_node("TaskNavigation").from_tree = false
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		var bench: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
		root.add_child(bench); current_scene = bench; await settle(12)
		bench._show_tutorial(true); await settle(12)
		var before: String = JSON.stringify(bench._capture_workbench_snapshot())
		await click(bench.hint_button)
		var card: Control = bench.yi_help_card
		check(card != null and card.is_visible_in_tree(), locale + ": pointer opens help")
		if card == null:
			bench.queue_free(); await settle(); continue
		await click(card.close_button)
		check(not card.visible, locale + ": pointer closes help")
		bench._show_desktop_window(&"components")
		await settle()
		bench.palette_search.text = "NOT"
		bench.palette_search.grab_focus()
		check(root.gui_get_focus_owner() == bench.palette_search, locale + ": search focus fixture is active")
		await key(KEY_F1)
		check(card.visible and bench.palette_search.text == "NOT", locale + ": F1 works with search focus and preserves text")
		card.close()
		await key(KEY_F1, true)
		check(not card.visible, locale + ": key repeat does not reopen help")
		await click(bench.hint_button)
		# Put a real instrument over the card, then repeatedly focus it as in play.
		var window: Control = bench.desktop_windows[&"test_bench"]
		window.position = card.position
		for index: int in 40: bench._focus_desktop_window(&"test_bench")
		await settle()
		# Help lives in the docked level guide above the canvas, so a focused
		# instrument can neither cover it nor take its clicks.
		var docked: bool = bench.tutorial_coach != null and bench.tutorial_coach.help_slot.is_ancestor_of(card)
		check(docked and not card.get_global_rect().intersects(window.get_global_rect()), locale + ": help stays clear of repeatedly focused instruments")
		await capture(locale + "-help-over-instrument")
		await click(bench.hint_button)
		await click(card.close_button)
		check(not card.visible, locale + ": reopened help receives pointer above an instrument")
		card.close()
		bench._close_desktop_window(&"test_bench")
		bench._close_desktop_window(&"components")
		await click(bench.hint_button)
		var more: Button = card.find_child("YiHelp_more", true, false)
		if more != null: await click(more)
		check(bench.hint_mode and not card.visible, locale + ": More enters the read-only hint canvas")
		if not bench.hint_mode: bench._enter_hint_workbench()
		await settle()
		await key(KEY_F1)
		check(bench.pending_hint_level == 2 and bench.hint_confirmation.visible, locale + ": F1 requests tier 2 confirmation")
		if bench.pending_hint_level == 0: bench._request_next_hint()
		await key(KEY_ESCAPE)
		check(bench.hint_mode and bench.hint_level == 1 and not bench.hint_confirmation.visible, locale + ": Esc cancels only the spoiler confirmation")
		await click(bench.hint_button)
		check(bench.pending_hint_level == 2, locale + ": pointer requests the same tier 2 confirmation")
		await click(bench.hint_confirm_button)
		check(bench.hint_level == 2, locale + ": confirmed tier 2 is revealed")
		await key(KEY_F1)
		check(bench.pending_hint_level == 3, locale + ": F1 requests tier 3 confirmation")
		if bench.pending_hint_level == 0: bench._request_next_hint()
		await click(bench.hint_confirm_button)
		check(bench.hint_level == 3 and bench.hint_button.disabled, locale + ": final tier is disabled")
		await key(KEY_F1)
		check(bench.hint_level == 3 and bench.pending_hint_level == 0, locale + ": F1 respects the final tier")
		await key(KEY_ESCAPE)
		check(not bench.hint_mode and JSON.stringify(bench._capture_workbench_snapshot()) == before, locale + ": leaving hints preserves the player's board")
		card.close()
		await key(KEY_F10)
		await key(KEY_F1)
		check(not card.visible, locale + ": Settings blocks underlying help")
		await key(KEY_ESCAPE)
		card.close()
		bench._show_new_workbench_dialog(); await settle()
		await key(KEY_F1)
		check(bench.workbench_name_dialog.visible and not card.visible, locale + ": naming dialog blocks underlying help")
		bench._hide_new_workbench_dialog()
		bench.queue_free(); await settle()
	print("PASS: test_hint_input " if failures == 0 else "FAIL: test_hint_input ", checks, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
