extends SceneTree
## Geometry and root-input regression for the physical terminal's feature pages.
var failures: int = 0
var checks: int = 0
var hub: Control
var lab: Control

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func settle(frames: int = 12) -> void:
	for frame: int in frames: await process_frame

func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		root.push_input(event, true)
		await process_frame
	await settle()

func click(control: Control) -> void:
	var display: Control = lab.terminal_pages
	var point: Vector2 = display.get_global_rect().position + control.get_global_rect().get_center() / Vector2(display.resolution) * display.get_global_rect().size
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point; event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event, true)
		await process_frame
	await settle()

func run() -> void:
	ProjectSettings.set_setting("game/reduced_motion", true)
	ProjectSettings.set_setting("playtest/offline_tester", false)
	root.mode = Window.MODE_WINDOWED
	hub = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await settle()
	lab = hub.laboratory
	var pages: Control = lab.terminal_pages
	check(lab.find_child("RoomShortcuts", true, false) == null, "Homepage has no external shortcut toolbar")
	for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1600,900), Vector2i(1280,1024), Vector2i(1920,900)]:
		root.size = dimensions; root.content_scale_size = dimensions
		await settle()
		await key(KEY_F10)
		check(hub.options_overlay.visible and not is_instance_valid(root.get_node("WindowMode").settings_layer), "F10 uses the terminal at " + str(dimensions))
		check(hub.options_overlay.get_viewport() == pages.viewport, "Settings share the terminal viewport")
		check(pages.modulate.a == 1.0, "Terminal page is revealed after camera alignment")
		check(not lab.room.visible and lab.room.viewport.render_target_update_mode == SubViewport.UPDATE_DISABLED, "Fullscreen workspace suspends room rendering")
		check(pages.get_global_rect() == Rect2(Vector2.ZERO, lab.size), "Terminal page fills the viewport")
		check(is_equal_approx(pages.size.x / pages.resolution.x, pages.size.y / pages.resolution.y), "Text scales uniformly at every aspect ratio")
		var panel: Control = hub.options_overlay.find_child("ChapterOptionsPanel",true,false)
		check(panel.docked and panel.position == Vector2.ZERO and panel.size == Vector2(pages.resolution), "Settings fill the terminal without a draggable window")
		await key(KEY_F8)
		check(root.get_node("PlaytestMoments").panel.visible, "F8 opens terminal feedback above Settings")
		await key(KEY_ESCAPE)
		check(not root.get_node("PlaytestMoments").panel.visible and hub.options_overlay.visible, "First Esc closes only feedback")
		await key(KEY_ESCAPE)
		check(not hub.options_overlay.visible and not lab.terminal.confirming(), "Second Esc returns to terminal without also opening Quit")
	root.size = Vector2i(2560,1440); root.content_scale_size = Vector2i(1280,720)
	await settle()
	await key(KEY_F10)
	check(pages.viewport.size == root.size, "Fullscreen pages render at physical resolution")
	check(pages.get_global_rect() == Rect2(Vector2.ZERO, lab.size), "Physical-resolution rendering preserves logical input bounds")
	await key(KEY_ESCAPE)
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	hub._open_journey_journal()
	await settle()
	var journal: Control = hub.journey_journal
	check(journal.get_viewport() == pages.viewport, "Works use the same terminal display")
	await click(journal.reflection_button)
	check(is_instance_valid(journal.reflection_dialog) and journal.reflection_dialog.visible, "Root mouse input opens the nested review")
	var review: Window = journal.reflection_dialog
	check(review.borderless and not review.exclusive and review.size == pages.resolution, "Review is a terminal page without OS exclusivity or window chrome")
	if DisplayServer.get_name() != "headless":
		await key(KEY_F8)
		check(root.get_node("PlaytestMoments").panel.visible and root.get_node("PlaytestMoments").panel.get_viewport() == review, "Nested F8 stays in the active terminal review")
		check(root.get_node("PlaytestMoments").panel.position == Vector2.ZERO and root.get_node("PlaytestMoments").panel.size == Vector2(review.size), "Nested feedback covers the entire previous page")
		await key(KEY_ESCAPE)
		check(not root.get_node("PlaytestMoments").panel.visible and is_instance_valid(review) and review.visible and journal.visible, "Feedback Esc preserves both lower pages")
		ProjectSettings.set_setting("playtest/offline_tester", true)
		await root.get_node("OfflineFeedback").open_panel()
		await settle()
		check(paused and root.get_node("OfflineFeedback").backdrop.get_viewport() == review, "Offline feedback stays in the review and pauses the game")
		await key(KEY_ESCAPE)
		check(not paused and not root.get_node("OfflineFeedback").backdrop.visible and is_instance_valid(review) and review.visible, "Offline feedback Esc restores the review and unpauses")
		ProjectSettings.set_setting("playtest/offline_tester", false)
		await key(KEY_ESCAPE)
		check((not is_instance_valid(review) or not review.visible) and journal.visible, "Review Esc returns only to Works")
	else:
		print("NOT_RUN: nested Window native focus needs graphical rendering")
		review.hide()
	await key(KEY_ESCAPE)
	check(not journal.visible, "Works Esc returns to terminal")
	await key(KEY_ESCAPE)
	check(not lab.room_focus and not lab.terminal.confirming(), "Terminal Esc returns to room without a quit question")
	await key(KEY_ENTER)
	check(lab.room_focus and lab.terminal.visible, "Enter reopens an already-awake terminal")
	await key(KEY_ESCAPE)
	await key(KEY_ESCAPE)
	check(lab.terminal.confirming(), "Room Esc confirms quitting inside terminal")
	await key(KEY_ESCAPE)
	check(not lab.terminal.confirming(), "Quit cancellation returns to terminal")
	print("PASS: terminal pages %d checks" % checks if failures == 0 else "FAIL: terminal pages %d/%d" % [failures,checks])
	quit(0 if failures == 0 else 1)
