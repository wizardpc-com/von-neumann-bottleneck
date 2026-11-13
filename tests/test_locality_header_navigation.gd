extends SceneTree
## Header geometry and real navigation input; no simulation or layout replacement.
const SCENE := "res://src/ui/main.tscn"
var checks: int = 0
var failures: Array[String] = []
var completed_locales: Array[String] = []

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle(frames: int = 6) -> void:
	for frame: int in frames: await process_frame
func point(control: Control) -> bool:
	var event := InputEventMouseMotion.new()
	event.position = control.get_global_rect().get_center(); event.global_position = event.position
	root.push_input(event, true); await process_frame
	var hovered: Control = root.gui_get_hovered_control()
	return hovered == control or hovered != null and control.is_ancestor_of(hovered)
func click(control: Control) -> void:
	check(await point(control), "Actual pointer reaches " + str(control.name))
	var position: Vector2 = control.get_global_rect().get_center()
	for down: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position; event.global_position = position
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		root.push_input(event, true); await process_frame
	await settle()
func pixel_state(dimensions: Vector2i, picture: Image = null) -> String:
	return JSON.stringify({"requested":str(dimensions),"mode":root.mode,
		"display_mode":DisplayServer.window_get_mode(),"window_size":str(root.size),
		"display_size":str(DisplayServer.window_get_size()),"content_scale_size":str(root.content_scale_size),
		"image_size":str(picture.get_size()) if picture != null else "unavailable"})
func resize(dimensions: Vector2i) -> void:
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = dimensions
	root.size = dimensions
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(dimensions)
	await settle(10)
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	var picture: Image
	for attempt: int in 60:
		# Native startup/fullscreen transitions can finish after the first request.
		# Reassert the actual window mode as well as its size on every attempt.
		root.mode = Window.MODE_WINDOWED
		root.size = dimensions; root.content_scale_size = dimensions
		DisplayServer.window_set_size(dimensions)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		picture = root.get_texture().get_image()
		var matches: bool = picture != null and picture.get_size() == dimensions \
			and root.mode == Window.MODE_WINDOWED and root.size == dimensions \
			and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED
		stable = stable + 1 if matches else 0
		if stable >= 5:
			print("PIXEL_STATE stable: " + pixel_state(dimensions,picture))
			return
	check(false, "Stable actual pixels: " + pixel_state(dimensions,picture))
func header_buttons(host: Control) -> Array[Control]:
	var map: Button = host.find_child("Chapter2MapButton", true, false)
	var settings: Button = host.find_child("InLevelSettings", true, false)
	var hub: Button
	if map != null:
		for child: Node in map.get_parent().get_children():
			if child is Button and child.text == host._t(&"common.prototype_hub"): hub = child
	check(map != null and settings != null and hub != null, "Real deferred Settings, Journey and Laboratory entries exist")
	var result: Array[Control] = []
	if map != null: result.append(map)
	if host.mode_selector.option_button != null: result.append(host.mode_selector.option_button)
	if hub != null: result.append(hub)
	if settings != null: result.append(settings)
	return result
func geometry(host: Control, label: String) -> void:
	var controls: Array[Control] = header_buttons(host)
	var viewport: Rect2 = Rect2(Vector2.ZERO, Vector2(root.content_scale_size))
	var rectangles: Array[Rect2] = []
	for control: Control in controls:
		var rectangle: Rect2 = control.get_global_rect()
		check(control.is_visible_in_tree() and viewport.encloses(rectangle), label + ": complete visible navigation " + str(control.name))
		check(control.size.x + 0.1 >= control.get_combined_minimum_size().x, label + ": navigation keeps natural text width " + str(control.name))
		for previous: Rect2 in rectangles:
			check(not rectangle.intersects(previous), label + ": navigation rectangles do not overlap")
		rectangles.append(rectangle)
		check(await point(control), label + ": navigation pointer hits " + str(control.name))
	check(host.chapter_title_label.get_theme_font_size("font_size") == 19 and host.chapter_subtitle_label.get_theme_font_size("font_size") == 16 and host.status_label.get_theme_font_size("font_size") == 14, label + ": original typography retained")
	var run: Button = host.instrument_open_buttons[&"test_bench"]
	var run_hit: bool = await point(run)
	check(run.is_visible_in_tree() and viewport.encloses(run.get_global_rect()) and run_hit, label + ": main Run toolbar entry remains reachable")
func capture(label: String, dimensions: Vector2i) -> void:
	if "--locality-header-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	var matches: bool = picture != null and picture.get_size() == dimensions
	check(matches, label + ": raw dimensions " + pixel_state(dimensions,picture))
	# A failed size gate remains a failed test; never label a different raw frame
	# as the requested resolution or resize the image to manufacture a pass.
	if not matches: return
	print("PIXEL_STATE capture " + label + ": " + pixel_state(dimensions,picture))
	var path: String = "user://locality-header-" + label + ".png"
	check(picture.save_png(path) == OK, label + ": save raw capture")
	print("CAPTURE: " + ProjectSettings.globalize_path(path))
func make_host() -> Control:
	root.get_node("TaskNavigation").from_tree = false
	root.get_node("TaskNavigation").pending = "chapter_2/access_order"
	var host: Control = load(SCENE).instantiate()
	root.add_child(host); current_scene = host
	await settle(12)
	return host
func retained(expected_draft: String, expected_applied: String, label: String) -> void:
	var saved: Dictionary = root.get_node("LocalityChapter").workspace_for(&"access_order")
	check(saved.get("draft_source") == expected_draft and saved.get("applied_source") == expected_applied, label + ": separate raw draft and applied source retained")
func navigation(host: Control, locale: String) -> void:
	host._start_level(&"access_order"); await settle()
	var source: String = host.applied_program_source
	var draft: String = source + "\n# keep unfinished " + locale + "\nacc = ???\n"
	host.editor.text = draft; host._on_program_changed(); await settle()
	var controls: Array[Control] = header_buttons(host)
	if controls.size() != 4: return
	await click(controls[3])
	var layer: CanvasLayer = root.get_node("WindowMode").settings_layer
	check(is_instance_valid(layer), locale + ": Settings click opens its actual layer")
	if is_instance_valid(layer):
		var resume: Button = layer.find_child("OptionsResumeButton", true, false)
		check(resume != null, locale + ": Settings has its existing Return action")
		if resume != null: await click(resume)
	check(not is_instance_valid(root.get_node("WindowMode").settings_layer), locale + ": Settings Return closes layer")
	check(host.editor.text == draft and host.applied_program_source == source and host.program_dirty, locale + ": Settings preserves unapplied text")
	var nav: Node = root.get_node("TaskNavigation")
	nav.from_tree = true; nav.selected = "chapter_2/access_order"
	await click(controls[0]); await settle(12)
	check(current_scene != null and current_scene.scene_file_path == nav.MAP_SCENE, locale + ": Journey button uses existing map route")
	retained(draft, source, locale + " map")
	if current_scene == null or current_scene.scene_file_path != nav.MAP_SCENE: return
	current_scene._select("chapter_2/access_order"); await settle()
	await click(current_scene.enter_button); await settle(12)
	check(current_scene != null and current_scene.scene_file_path == SCENE, locale + ": selected task returns to Chapter 2")
	if current_scene == null or current_scene.scene_file_path != SCENE: return
	host = current_scene
	check(host.editor.text == draft and host.applied_program_source == source and host.program_dirty, locale + ": returning restores separate draft and applied program")
	controls = header_buttons(host)
	if controls.size() != 4: return
	await click(controls[2]); await settle(12)
	check(current_scene != null and current_scene.scene_file_path == "res://src/ui/prototype_hub.tscn", locale + ": Laboratory button follows existing scene route")
	retained(draft, source, locale + " laboratory")
	completed_locales.append(locale)
func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(2); return
	root.get_node("GameMode").set_mode(&"test")
	var state: Node = root.get_node("LocalityChapter")
	var original_game: Dictionary = state.game_snapshot().duplicate(true)
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		state.reset_test_progress()
		var host: Control = await make_host()
		for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(960,640), Vector2i(1600,900), Vector2i(1280,720)]:
			await resize(dimensions)
			for level_id: StringName in host.catalog.level_ids():
				host._start_level(level_id)
				# Stress only the existing clipping lane; never replace the task title or actions.
				host._set_status(host._t(&"chapter2.status.map").repeat(12), Color.WHITE)
				await settle()
				await geometry(host, locale + " " + str(dimensions) + " " + String(level_id))
			if dimensions.x in [960, 1280]:
				host._start_level(&"access_order"); await settle()
				# The repeated 1280 resize verifies recovery; keep only one raw image per size.
				if dimensions.x == 960 or not host.has_meta("header_1280_captured"):
					await capture(locale + "-" + str(dimensions.x), dimensions)
					if dimensions.x == 1280: host.set_meta("header_1280_captured", true)
		await navigation(host, locale)
		if current_scene != null:
			current_scene.queue_free(); current_scene = null
		await settle()
	check(completed_locales == ["zh_CN", "en"], "Both complete navigation loops finish without an aborted coroutine")
	check(state.game_snapshot() == original_game, "Test header and route checks do not alter Game progress or workspaces")
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "locality header/navigation %d checks, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
