extends SceneTree
## Static media and existing Home input flow; controller checks are not native OS acceptance.
const HOME: String = "res://src/ui/prototype_hub.tscn"
const HARDWARE: String = "res://src/hardware_foundations/hardware_foundations.tscn"
var checks: int = 0
var failures: Array[String] = []
var capture: bool = false


func _init() -> void: call_deferred("run")


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)


func settle() -> void:
	for frame: int in 8: await process_frame


func key(code: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		Input.parse_input_event(event)
		await settle()


func snapshot() -> Dictionary:
	var value: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	value.erase("saved_at_utc")
	return value


func in_clip(control: Control) -> bool:
	var clip: Rect2 = root.get_visible_rect()
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is Control and (parent as Control).clip_contents:
			clip = clip.intersection((parent as Control).get_global_rect())
		parent = parent.get_parent()
	return control.is_visible_in_tree() and clip.grow(1.0).encloses(control.get_global_rect())


func image(label: String) -> void:
	if not capture: return
	RenderingServer.force_draw(false); await process_frame
	var folder: String = "res://.godot/yi-introduction-captures"
	check(DirAccess.make_dir_recursive_absolute(folder) == OK, "Media evidence directory created")
	check(root.get_texture().get_image().save_png(folder.path_join(label + ".png")) == OK, "Actual media frame saved " + label)


func home() -> Control:
	check(change_scene_to_file(HOME) == OK, "Actual Home opens")
	await settle()
	return current_scene as Control


func run() -> void:
	preload("res://src/lab/lab_features.gd").classic = true # verifies the classic Home/tutorial surfaces
	preload("res://src/lab/lab_features.gd").core_journey = true
	capture = "--yi-media-capture" in OS.get_cmdline_user_args()
	if capture and DisplayServer.get_name() == "headless":
		check(false, "Media capture requires a rendered window"); capture = false
	root.mode = Window.MODE_WINDOWED
	var save: Node = root.get_node("GlobalSave")
	var nav: Node = root.get_node("TaskNavigation")
	root.get_node("GameMode").set_mode(&"game")
	save.configure_for_test("user://yi-media-save.json", "user://yi-media-workbench.json")
	nav.last_visited_task = ""
	var original_motion: Variant = ProjectSettings.get_setting("game/reduced_motion", false)
	var original_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester", false)
	var before: Dictionary = snapshot()
	var original_selection: String = nav.last_visited_task
	var hub: Control
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		hub = await home()
		var intro: Control = hub.yi_introduction
		var default_media: Texture2D = intro.media_texture
		check(default_media != null and default_media.get_size().x > 0, "Bundled abstract media loads in " + locale)
		check(intro.media_caption.text.contains("Candidate") if locale == "en" else intro.media_caption.text.contains("候选"), "Media is explicitly a candidate fictional archive")
		var goal: String = intro.goal_label.text
		for dimensions: Vector2i in [Vector2i(1280,720), Vector2i(1920,1080), Vector2i(1440,900)]:
			root.size = dimensions; root.content_scale_size = dimensions
			for reduced: bool in [false, true]:
				ProjectSettings.set_setting("game/reduced_motion", reduced)
				intro.media_texture = default_media
				intro.present(true); await settle()
				check(intro.media_view.texture == default_media and intro.media_column.visible, "Static media exists at " + str(dimensions))
				check(intro.media_view.mouse_filter == Control.MOUSE_FILTER_IGNORE and intro.media_view.focus_mode == Control.FOCUS_NONE, "Media cannot intercept pointer or keyboard focus")
				check(root.gui_get_focus_owner() == intro.start_button and in_clip(intro.start_button), "Begin remains the focused visible action")
				check(intro.goal_label.get_theme_font_size("font_size") == 16 and in_clip(intro.goal_label), "Original NOT goal stays readable at its original size")
				if not reduced: await image(locale + "-%dx%d-media" % [dimensions.x,dimensions.y])
				await key(KEY_TAB)
				check(root.gui_get_focus_owner() == intro.skip_button and in_clip(intro.skip_button), "Skip remains adjacent and reachable without viewing media")
				var texture_image := Image.create(32,24,false,Image.FORMAT_RGBA8)
				texture_image.fill(Color("d8c997"))
				var replacement: Texture2D = ImageTexture.create_from_image(texture_image)
				intro.media_texture = replacement; await settle()
				check(intro.media_view.texture == replacement and root.gui_get_focus_owner() == intro.skip_button, "Replacing Texture2D preserves the active action")
				intro.media_texture = ImageTexture.new(); await settle()
				check(not intro.media_column.visible and intro.goal_label.text == goal, "An empty Texture2D uses the same text-only fallback")
				intro.media_texture = null; await settle()
				check(not intro.media_column.visible and intro.goal_label.text == goal and intro.skip_button.visible, "Missing media keeps original text and Skip usable")
				if not reduced: await image(locale + "-%dx%d-missing" % [dimensions.x,dimensions.y])
				await key(KEY_ESCAPE)
				check(not intro.visible and not hub.options_overlay.visible, "Escape dismisses only the introduction")
				var replay := hub.find_child("ReplayYiIntroduction",true,false) as Button
				replay.grab_focus(); replay.pressed.emit(); await settle()
				check(intro.visible and not intro.start_button.visible and not intro.skip_button.visible, "Media-free replay retains its original Home-only contract")
				await key(KEY_TAB)
				check(root.gui_get_focus_owner() == intro.close_button and in_clip(intro.close_button), "Replay focus stays on its one available action")
				await key(KEY_ESCAPE)
				check(not intro.visible and root.gui_get_focus_owner() == replay, "Replay restores its actual Home launcher focus")
				check(snapshot() == before and nav.last_visited_task == original_selection, "Media/reduced motion/replay never grant progress or change navigation")
		intro.media_texture = default_media
		for tester: bool in [false,true]:
			ProjectSettings.set_setting("playtest/offline_tester", tester)
			intro.present(true); await settle()
			var prior_focus: Control = root.gui_get_focus_owner()
			await key(KEY_F8)
			var feedback: Node = root.get_node("OfflineFeedback") if tester else root.get_node("PlaytestMoments")
			var panel: Control = feedback.backdrop if tester else feedback.panel
			check(panel.is_visible_in_tree() and intro.visible, "Actual F8 opens the existing channel above media")
			await key(KEY_ESCAPE)
			check(not panel.visible and intro.visible and not paused and root.gui_get_focus_owner() == prior_focus, "First Escape closes feedback and restores intro focus")
			await key(KEY_ESCAPE)
			check(not intro.visible and not hub.options_overlay.visible and snapshot() == before, "Second Escape closes intro without awarding progress")
	ProjectSettings.set_setting("playtest/offline_tester", original_tester)
	ProjectSettings.set_setting("game/reduced_motion", original_motion)
	for use_skip: bool in [false,true]:
		var scenario: String = "skip" if use_skip else "begin"
		save.configure_for_test("user://yi-media-" + scenario + "-save.json", "user://yi-media-" + scenario + "-workbench.json")
		nav.last_visited_task = ""
		hub = await home()
		var primary := hub.find_child("TaskTree",true,false) as Button
		if primary == null: primary = hub.find_child("RecommendedJourneyAction",true,false) as Button
		primary.pressed.emit(); await settle()
		var intro: Control = hub.yi_introduction
		check(intro.visible, "Actual Home route still presents optional context")
		if use_skip: intro.media_texture = null; await key(KEY_TAB)
		await key(KEY_SPACE)
		check(current_scene.scene_file_path == HARDWARE and current_scene.current_level_id == &"tutorial", "Begin or media-free Skip enters the real tutorial")
		check(not current_scene.completed_levels.get(&"tutorial",false), "Entering through media never earns tutorial completion")
		await home()
	print(("PASS: " if failures.is_empty() else "FAIL: ") + "Yi introduction replaceable static media (%d checks)" % checks)
	quit(0 if failures.is_empty() else 1)
