extends SceneTree
## Real tutorial/controller setup; Window timing and captures require a renderer.

const Session = preload("res://experiments/creation/session.gd")
var Reflection: Script
var Journal: Script
var checks: int = 0
var failures: Array[String] = []
var capture: bool = false


func _init() -> void: call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in 8: await process_frame


func key(code: Key, full_input: bool = false) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = down
		if full_input: Input.parse_input_event(event)
		else: root.push_input(event, true)
		await settle()


func inventory(path: String) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return result
	for name: String in directory.get_files(): result[name] = FileAccess.get_sha256(path.path_join(name))
	for name: String in directory.get_directories():
		var children: Dictionary = inventory(path.path_join(name))
		for child: String in children:
			result[name + "/" + child] = children[child]
	return result


func protected_files() -> Dictionary:
	var save: Node = root.get_node("GlobalSave")
	var files: Dictionary = inventory(Session.default_path().get_base_dir())
	for path: String in [save.storage_path, save.storage_path + ".bak", save.workbench_storage_path]:
		files[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return files


func state() -> Dictionary:
	var data: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	data.erase("saved_at_utc")
	return data


func open_reflection(configure_first: bool = true) -> Variant:
	var dialog: Variant = Reflection.new()
	var keys: Array[StringName] = [&"theme.entry", &"theme.build"]
	var translate: Callable = root.get_node("Localization").text
	if configure_first: dialog.configure(keys, translate)
	root.add_child(dialog)
	if not configure_first: dialog.configure(keys, translate)
	dialog.popup_centered(Vector2i(650, 480))
	await settle()
	return dialog


func capture_frame(dialog: AcceptDialog, name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path := "user://first-light-captures/" + name + ".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(dialog.get_texture().get_image().save_png(path) == OK, "Actual Reflection frame saves:" + name)


func run() -> void:
	Reflection = load("res://src/ui/theme_reflection.gd")
	Journal = load("res://src/ui/journey_journal.gd")
	capture = DisplayServer.get_name() != "headless" and "--first-light-capture" in OS.get_cmdline_user_args()
	var save: Node = root.get_node("GlobalSave")
	var nav: Node = root.get_node("TaskNavigation")
	var mode: Node = root.get_node("GameMode")
	var localization: Node = root.get_node("Localization")
	var old_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester", false)
	var old_motion: Variant = ProjectSettings.get_setting("game/reduced_motion", false)
	var old_creation: Variant = ProjectSettings.get_setting("candidate/creation_enabled", false)
	ProjectSettings.set_setting("candidate/creation_enabled", true)
	ProjectSettings.set_setting("game/reduced_motion", false)
	mode.set_mode(&"game")
	save.configure_for_test("user://first-light-save.json", "user://first-light-workbench.json")
	for before_tree: bool in [true, false]:
		var fresh: Variant = await open_reflection(before_tree)
		check(is_instance_valid(fresh.first_light) and not fresh.first_light.visible, "Fresh/CPU prose alone cannot reveal playback; configure order:" + str(before_tree))
		fresh.first_light.play()
		check(not fresh.first_light.has_started, "Click-time source guard rejects an unearned illustration")
		fresh.queue_free(); await settle()
	ProjectSettings.set_setting("playtest/offline_tester", true)
	var accessible: Variant = await open_reflection(false)
	check(not accessible.first_light.visible and not save.game_player_content.completed_levels.get(&"tutorial", false), "Tester-open entries grant neither playback nor completion")
	accessible.queue_free(); await settle()
	ProjectSettings.set_setting("playtest/offline_tester", false)
	check(nav.enter("hardware_foundations/tutorial"), "Real navigation selects the original tutorial")
	await settle()
	var host: Variant = current_scene
	var ready: bool = is_instance_valid(host) and host.current_level_id == &"tutorial" and is_instance_valid(host.input_a_button)
	check(ready, "Actual tutorial controller is ready")
	if not ready: quit(1); return
	if host.mission_briefing_active: host._start_building_from_briefing()
	host._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
	host._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	host.input_a_button.button_pressed = true
	host._run_debug()
	host._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
	check(not save.game_player_content.completed_levels.get(&"tutorial", false), "Four real operations cannot unlock the retrospective")
	host._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
	await settle()
	check(save.game_player_content.completed_levels.get(&"tutorial", false), "Real reconnect earns the source tutorial completion")
	host._dismiss_level_completion(); host._save_active_workbench()
	check(save.save_game(true), "Earned source and circuit save before read-only replay")
	# Actual isolated C/P/G work, not a fake history record or bytes-only substitute.
	var writer: Variant = Session.new()
	check(writer.open(Session.default_path()).writable, "Fixture opens an isolated candidate writer")
	check(writer.train().ok and writer.transport([0, 1, 0, 2], "predictive").ok, "Fixture learns and restores real input")
	writer.set_mode("predict"); writer.begin_prediction("practice")
	while not writer.prediction.finished: writer.commit_prediction(); writer.reveal_prediction()
	writer.set_mode("generate")
	check(writer.generate().ok and writer.save_work("First light protected work").ok, "Fixture saves a real protected generated work")
	writer.close()
	var before: Dictionary = protected_files()
	var before_state: Dictionary = state()
	var before_navigation := {"pending": nav.pending, "selected": nav.selected}
	var stale: Variant = await open_reflection()
	mode.set_mode(&"test")
	stale.first_light.play_button.pressed.emit()
	check(not stale.first_light.has_started, "A visible stale entry rechecks mode at the instant of its click")
	stale.queue_free(); await settle()
	var testing: Variant = await open_reflection()
	check(not testing.first_light.visible, "Test model rejects playback even with prior game completion")
	testing.queue_free(); await settle()
	mode.set_mode(&"game")
	for locale: String in ["zh_CN", "en"]:
		localization.set_locale(locale)
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1440, 900)]:
			root.size = dimensions; root.content_scale_size = dimensions
			var dialog: Variant = await open_reflection(locale == "zh_CN")
			var light: Variant = dialog.first_light
			check(light.visible and not light.playing and not light.has_started and not light.scene_body.visible, "Earned replay stays optional and does not autoplay")
			var scroll: ScrollContainer = dialog.body_column.get_parent()
			scroll.ensure_control_visible(light.play_button); await settle()
			check(scroll.get_global_rect().encloses(light.play_button.get_global_rect()), "Native playback control is reachable within the original scroll clip")
			light.play_button.grab_focus()
			if DisplayServer.get_name() != "headless": await key(KEY_SPACE, true)
			else: light.play_button.pressed.emit()
			check(light.has_started and light.scene_body.visible and light.preview_texture == null, "Actual play control reveals a missing-texture procedural fallback")
			await settle()
			if DisplayServer.get_name() != "headless":
				check(scroll.get_global_rect().encloses(light.canvas.get_global_rect()), "Real Play automatically reveals the main illustration without a QA scroll")
				check(scroll.get_global_rect().encloses(light.skip_button.get_global_rect()), "Real Play automatically reveals Skip without a QA scroll")
				check(dialog.gui_get_focus_owner() == light.play_button, "Automatic reveal retains the player's Play-button focus")
			await capture_frame(dialog, locale + "-" + str(dimensions.x) + "-playing")
			if DisplayServer.get_name() != "headless" and locale == "zh_CN" and dimensions.x == 1280:
				await create_timer(light.DURATION + 0.08).timeout
				check(not light.playing and light.elapsed == light.DURATION, "Natural renderer playback ends once at about three seconds without looping")
				light.play_button.pressed.emit()
			light.skip_button.pressed.emit()
			check(not light.playing and light.elapsed == light.DURATION and light.caption.text.contains("1 →" if locale == "en" else "输入1"), "Skip reaches static correct NOT output and all native captions")
			check(light.caption.text.contains("output 0" if locale == "en" else "输出0") and light.caption.text.contains("civilization" if locale == "en" else "文明测量"), "Captions distinguish output0 from narrative light/energy measurement")
			await settle()
			scroll.ensure_control_visible(light.skip_button); await settle()
			check(scroll.get_global_rect().encloses(light.skip_button.get_global_rect()), "Skip remains reachable by scrolling at each language/window size")
			check(scroll.get_global_rect().encloses(light.caption.get_global_rect()), "All static native captions fit their original scroll viewport")
			await capture_frame(dialog, locale + "-" + str(dimensions.x) + "-static")
			var image := Image.create(8, 8, false, Image.FORMAT_RGBA8)
			image.fill(Color("47767c"))
			var replacement := ImageTexture.create_from_image(image)
			light.preview_texture = replacement
			light.play_button.pressed.emit(); light.skip_button.pressed.emit()
			check(light.canvas.illustration == replacement, "An optional actual Texture2D can replace the visual while native captions remain")
			light.preview_texture = null
			light.play_button.pressed.emit(); light.skip_button.pressed.emit()
			check(light.canvas.illustration == null, "Missing replacement returns to the procedural fallback without loading external paths")
			var fallback_pixels := PackedByteArray()
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				fallback_pixels = dialog.get_texture().get_image().get_data()
			light.preview_texture = ImageTexture.new()
			light.play_button.pressed.emit(); light.skip_button.pressed.emit()
			check(light.canvas.illustration.get_width() == 0 and light.caption.visible, "A non-null empty Texture2D retains the fallback and native captions")
			if DisplayServer.get_name() != "headless":
				await settle(); await RenderingServer.frame_post_draw
				check(dialog.get_texture().get_image().get_data() == fallback_pixels, "Actual empty-texture frame exactly matches the procedural null-texture fallback")
			light.preview_texture = null
			ProjectSettings.set_setting("game/reduced_motion", true)
			light.play_button.pressed.emit()
			check(not light.playing and light.elapsed == light.DURATION, "Reduced motion replay immediately presents the equivalent static ending")
			ProjectSettings.set_setting("game/reduced_motion", false)
			light.play_button.pressed.emit()
			check(light.playing and light.elapsed == 0.0, "Replay starts only after a new explicit action")
			if DisplayServer.get_name() != "headless":
				await create_timer(0.08).timeout
				check(light.elapsed > 0.0 and light.elapsed < light.DURATION, "Focused actual Window advances the short animation")
				ProjectSettings.set_setting("game/reduced_motion", true)
				await settle()
				check(not light.playing and light.elapsed == light.DURATION, "Enabling reduced motion during playback stops at the static ending")
			ProjectSettings.set_setting("game/reduced_motion", false)
			dialog.queue_free(); await settle()
		check(protected_files() == before and state() == before_state, "Both configure orders, replay and language/size changes preserve original profiles and work bytes")
	if DisplayServer.get_name() != "headless":
		# Changing game mode returns the tutorial to the real map scene.
		var lifecycle_host: Node = current_scene
		var host_ready: bool = is_instance_valid(lifecycle_host) and lifecycle_host.is_inside_tree() and not lifecycle_host.is_queued_for_deletion()
		check(host_ready, "Journal lifecycle uses the current real scene after mode navigation")
		if not host_ready:
			quit(1)
			return
		await window_lifecycle(lifecycle_host)
		var departing: Variant = await open_reflection()
		departing.first_light.play_button.grab_focus()
		departing.first_light.play_button.pressed.emit()
		departing.first_light.play_button.pressed.emit()
		var pending_player: WeakRef = weakref(departing.first_light)
		departing.queue_free(); await settle()
		check(pending_player.get_ref() == null, "Destroying the Window before its one-shot reveal leaves no pending player or receiver")
	else: print("NOT_RUN: first-light renderer/focus/F8/lifecycle; run without --headless and with --capture-size=1280x720 --first-light-capture")
	check(protected_files() == before and state() == before_state, "Window playback/feedback/close never rewrites game, workbench, candidate or saved works")
	check(nav.pending == before_navigation.pending and nav.selected == before_navigation.selected, "Retrospective never changes navigation pending or selection")
	ProjectSettings.set_setting("playtest/offline_tester", old_tester)
	ProjectSettings.set_setting("game/reduced_motion", old_motion)
	ProjectSettings.set_setting("candidate/creation_enabled", old_creation)
	print(("PASS" if failures.is_empty() else "FAIL") + ": first light " + str(checks) + " checks; real tutorial/CPG controller setup, no native-input claim")
	quit(0 if failures.is_empty() else 1)


func window_lifecycle(host: Node) -> void:
	var journal: Variant = Journal.new()
	host.add_child(journal)
	var feedback: Node = root.get_node("OfflineFeedback")
	var moments: Node = root.get_node("PlaytestMoments")
	for tester: bool in [false, true]:
		ProjectSettings.set_setting("playtest/offline_tester", tester)
		journal.open(); journal.reflection_button.grab_focus(); await key(KEY_SPACE)
		var dialog: Variant = journal.reflection_dialog
		var light: Variant = dialog.first_light
		var scroll: ScrollContainer = dialog.body_column.get_parent()
		scroll.ensure_control_visible(light.play_button); await settle()
		light.play_button.grab_focus()
		var original_scroll: int = scroll.scroll_vertical
		light.play_button.pressed.emit(); light.play_button.pressed.emit()
		var capture_hold: float = light.elapsed
		# Same-frame controller timing fixture, before the one-shot reveal callback.
		if tester:
			feedback.open_panel()
			check(feedback.busy and paused, "Immediate offline feedback enters its real pre-draw capture wait")
		else: moments.toggle()
		await settle()
		check(light.elapsed == capture_hold and scroll.scroll_vertical == original_scroll, "Rapid Play followed by feedback cannot move the captured scene or deferred scroll")
		var top_focus: Control = dialog.gui_get_focus_owner()
		check(is_instance_valid(top_focus) and (feedback.panel.is_ancestor_of(top_focus) if tester else moments.panel.is_ancestor_of(top_focus)), "Pending reveal cannot steal feedback focus")
		await key(KEY_ESCAPE, true)
		check(is_instance_valid(dialog) and dialog.visible and dialog.gui_get_focus_owner() == light.play_button, "Same-frame feedback closes alone and restores original Play focus")
		light.play_button.grab_focus(); await key(KEY_SPACE, true)
		check(light.playing and light.elapsed > 0.0, "Actual Journal Reflection starts the earned replay:" + str(tester))
		await key(KEY_F8, true)
		check(dialog.visible and root.get_node("PlaytestData")._feedback_visible, "Real F8 opens the existing top layer during playback")
		check(feedback.backdrop.visible if tester else moments.panel.visible, "F8 chooses only the existing expected feedback channel")
		var held: float = light.elapsed
		await create_timer(0.12, true).timeout
		check(light.elapsed == held and light.playing, "Feedback explicitly pauses the always-process illustration")
		await key(KEY_ESCAPE, true)
		check(is_instance_valid(dialog) and dialog.visible and dialog.gui_get_focus_owner() == light.play_button, "First Escape closes feedback alone and returns exact playback-button focus")
		await create_timer(0.08).timeout
		check(light.elapsed > held, "Playback resumes after feedback without changing completion")
		var blocker := AcceptDialog.new()
		root.add_child(blocker); blocker.popup_centered(Vector2i(320, 160)); await settle()
		held = light.elapsed; await create_timer(0.12).timeout
		check(not dialog.has_focus() and light.elapsed == held, "Another real Window pauses playback on focus loss")
		blocker.queue_free(); await settle()
		dialog.grab_focus(); await settle()
		dialog.hide(); held = light.elapsed; await create_timer(0.12).timeout
		check(light.elapsed == held, "Hidden Reflection retains a paused frame")
		dialog.popup_centered(Vector2i(650, 480)); await settle()
		light.play_button.pressed.emit()
		check(light.playing, "Lifecycle closes during an explicitly restarted animation")
		var reference: WeakRef = weakref(light)
		await key(KEY_ESCAPE, true)
		check(not is_instance_valid(dialog) and reference.get_ref() == null and journal.visible, "Closing during replay destroys its temporary Control without a residual player")
		check(root.gui_get_focus_owner() == journal.reflection_button, "Reflection close restores original Journal launcher focus")
		await key(KEY_ESCAPE)
		check(not journal.visible, "Final Escape returns to the actual host")
	journal.queue_free(); await settle()
