extends SceneTree
## Round 2 of the 2026-10-20 art pass: the laboratory is the final page (Quit
## and Esc ask on the terminal screen), the threshold between the room and the
## terminal world, the terminal world's own canvas colours, the regrouped
## Settings and the new room objects that show only real progress.
const Passage = preload("res://src/ui/terminal_passage.gd")
const Palette = preload("res://src/lab/lab_palette.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame
func escape(target: Node) -> void:
	var key := InputEventKey.new(); key.keycode = KEY_ESCAPE; key.physical_keycode = KEY_ESCAPE; key.pressed = true
	target.call("_unhandled_key_input", key)

func run() -> void:
	root.size = Vector2i(1280, 720)
	ProjectSettings.set_setting("game/reduced_motion", false)
	var hub: Control = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub; await settle(12)
	var lab: Control = hub.get_node("Laboratory")
	var terminal: Control = lab.terminal
	var quits: Array[bool] = []
	lab.quit_requested.connect(func() -> void: quits.append(true))

	# Esc on standby asks on the terminal itself; a second Esc returns.
	check(terminal.asleep(), "Terminal starts on standby")
	escape(hub); await settle(2)
	check(terminal.confirming() and terminal.quit_view.visible and not terminal.awake_view.visible, "Esc in the laboratory shows the quit question on the terminal")
	check(not hub.options_overlay.visible, "Esc in the laboratory does not open Settings")
	check(root.gui_get_focus_owner() == terminal.quit_yes, "The question focuses the Yes button")
	check(terminal.quit_title.text == "要退出游戏吗？" and terminal.quit_yes.text == "是，退出", "The question is plain and named")
	check(quits.is_empty(), "Asking never quits by itself")
	escape(hub); await settle(2)
	check(not terminal.confirming() and terminal.awake_view.visible and not terminal.quit_view.visible, "A second Esc returns to the terminal menu")

	# The terminal's Quit button asks the same question; No keeps the player here.
	(terminal.find_child("TerminalQuit", true, false) as Button).pressed.emit(); await settle(2)
	check(terminal.confirming(), "Quit on the terminal asks first")
	terminal.quit_no.pressed.emit(); await settle(2)
	check(not terminal.confirming() and quits.is_empty(), "No returns without quitting")
	(terminal.find_child("TerminalQuit", true, false) as Button).pressed.emit(); await settle(2)
	terminal.quit_yes.pressed.emit(); await settle(2)
	check(quits.size() == 1, "Yes requests the real quit (save, then exit)")

	# Settings quit from the laboratory also confirms on the terminal.
	terminal.cancel_quit(); await settle(2)
	hub.call("_open_options_menu"); await settle(4)
	check(hub.options_overlay.visible, "Settings still opens from the terminal")
	check(hub.find_child("SettingsCard_interface", true, false) != null and hub.find_child("SettingsCard_audio", true, false) != null, "Settings is grouped into titled cards")
	for name: String in ["LanguageChoice", "YiTextSpeed", "OptionsFullscreenButton", "ReducedMotion", "FrameLimit", "SoundEnabled", "SoundVolume", "ResetPresentation", "ExportDiagnostics"]:
		check(hub.find_child(name, true, false) != null, "Settings keeps " + name)
	var quits_before: int = quits.size()
	hub.options_quit_button.pressed.emit(); await settle(3)
	check(not hub.options_overlay.visible and terminal.confirming() and quits.size() == quits_before, "Settings quit in the laboratory closes Settings and asks on the terminal")
	escape(hub); await settle(2)

	# The room's new objects only reflect real progress.
	check(lab.status_next.begins_with("序章") and lab.status_chapter == "序章", "The status display names the real next task (%s)" % lab.status_next)
	check(lab.completed_keys.is_empty(), "A new player has no inked rules or tray parts")
	var keys: Array[String] = []
	for row: Dictionary in root.get_node("TaskNavigation").journey_tasks(): keys.append(str(row.key))
	for line: Dictionary in lab.RECORD_LINES:
		check(str(line.requires) in keys, "Record board line belongs to a real task: " + str(line.requires))
	for part: Array in lab.TRAY_PARTS:
		check(str(part[0]) in keys, "Tray part belongs to a real task: " + str(part[0]))
	check(not Rect2(lab.STATUS_RECT).intersects(lab.SCREEN_RECT) and not Rect2(lab.BOARD_RECT).intersects(lab.MONITOR_RECT), "Status display and record board stay clear of the terminal")
	check(lab.STATUS_RECT.size.x * lab.STATUS_RECT.size.y < lab.SCREEN_RECT.size.x * lab.SCREEN_RECT.size.y * 0.15, "The terminal stays the visual centre; the status display is small")
	hub.queue_free(); await settle()

	# The threshold: leaving marks a pending arrival that the next terminal scene takes once.
	Passage.pending_arrival_msec = -1
	check(not Passage.take_pending_arrival(), "No arrival without a departure")
	Passage.mark_departure()
	check(Passage.take_pending_arrival(), "A departure is taken by the next terminal backdrop")
	check(not Passage.take_pending_arrival(), "An arrival plays only once")
	Passage.pending_arrival_msec = Time.get_ticks_msec() - Passage.ARRIVE_WINDOW_MS - 10
	check(not Passage.take_pending_arrival(), "A stale departure is ignored")

	# The terminal world: canvases share the deep field, not a neutral grey sheet.
	var skin := Theme.new()
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	var field: StyleBoxFlat = skin.get_stylebox("panel", "GraphEdit") as StyleBoxFlat
	check(field != null and field.bg_color.b > field.bg_color.r and field.bg_color.get_luminance() < 0.08, "Machine canvases use the terminal's deep blue-black field")
	var light := Theme.new()
	preload("res://src/ui/instrument_theme.gd").apply_to(light, true)
	check(not light.has_stylebox("panel", "GraphEdit"), "The light comparison theme keeps its own canvas")
	# Two worlds: the room is warm daylight, the terminal cool and dark.
	check(Palette.LAB_WALL.r >= Palette.LAB_WALL.b and Palette.DESK_TOP.r > Palette.DESK_TOP.b, "Laboratory surfaces lean warm")
	check(Palette.TERM_SCREEN.b > Palette.TERM_SCREEN.r and Palette.TERM_SCREEN.get_luminance() < 0.1, "The terminal leans cool and dark")
	print(("PASS: " if failures == 0 else "FAIL: ") + "two worlds %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
