extends SceneTree
## Isolated controller/viewport checks. Captures are real renders of disclosed
## QA routes, not native input, human understanding or a whole-campaign playthrough.
const Dialogues = preload("res://src/lab/chapter_dialogues.gd")
const LabHome = preload("res://src/lab/lab_home.gd")
const Typewriter = preload("res://src/ui/yi_typewriter.gd")
var failures: int = 0
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(text)
func settle() -> void:
	for frame: int in 10: await process_frame
func open_scene(path: String) -> Control:
	root.get_node("TaskNavigation").pending = ""
	var scene: Control = load(path).instantiate()
	root.add_child(scene); await settle()
	return scene
func release(scene: Control) -> void:
	scene.queue_free(); await settle()
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless" or not "--narrative-review-capture" in OS.get_cmdline_user_args(): return
	if "archive-" in name: await create_timer(1.5).timeout
	if "g3-saved" in name: await create_timer(5.5).timeout
	await settle(); RenderingServer.force_draw(false); await process_frame
	var picture: Image = root.get_texture().get_image()
	check(picture.get_size() == Vector2i(1280, 720), "Capture is exactly 1280x720: " + name)
	DirAccess.make_dir_recursive_absolute("res://.godot/narrative-review-captures")
	check(picture.save_png("res://.godot/narrative-review-captures/" + name + ".png") == OK, "Saved " + name)
func press_key(key: Key) -> void:
	for down: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = key; event.physical_keycode = key; event.pressed = down
		root.push_input(event, true); await process_frame
	await settle()

func run() -> void:
	check(OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"), "Requires isolated QA data")
	if failures > 0: quit(1); return
	root.size = Vector2i(1280, 720); root.content_scale_size = Vector2i(1280, 720)
	var save: Node = root.get_node("GlobalSave")
	save.configure_for_test("user://narrative-review-save.json", "user://narrative-review-board.json")
	var rows: Array = root.get_node("TaskNavigation").journey_tasks()
	var keys: Array[String] = []
	for row: Dictionary in rows: keys.append(str(row.key))
	var mapping := FileAccess.open("res://docs/verification/20261021-narrative/task-mapping.csv", FileAccess.READ)
	mapping.get_csv_line()
	var mapped: Array[String] = []
	while not mapping.eof_reached():
		var fields: PackedStringArray = mapping.get_csv_line()
		if fields.size() < 2: continue
		check(fields[1] in keys and not fields[1] in mapped, "Unique real task mapping: " + fields[0])
		mapped.append(fields[1])
	check(mapped.size() == 60 and keys.size() == 60, "All 60 real tasks mapped")
	for locale: String in ["zh_CN", "en"]:
		root.get_node("Localization").set_locale(locale)
		ProjectSettings.set_setting("game/reduced_motion", false)
		ProjectSettings.set_setting(Typewriter.SPEED_SETTING, "slow")
		Typewriter._seen.clear()
		var hub: Control = await open_scene("res://src/ui/prototype_hub.tscn")
		var terminal: Control = hub.get_node("Laboratory").terminal
		terminal.wake(true); terminal.message.complete_now(); await settle()
		await capture(locale + "-invitation")
		var before: Dictionary = save._save_snapshot(); before.erase("saved_at_utc")
		for key: String in Dialogues.DIALOGUES:
			terminal.play_dialogue(Dialogues.for_key(key)); await settle()
			check(terminal.message.is_playing() and terminal.dialogue_skip.is_visible_in_tree(), "Return is available while typing")
			terminal.dialogue_skip.grab_focus()
			await press_key(KEY_ENTER)
			check(not terminal.in_dialogue() and terminal.primary.is_visible_in_tree(), "One Enter on Return exits while typing")
			terminal.message.complete_now(); await settle()
			check(terminal.choices.get_child_count() == 0 and not terminal.choices.visible, "A later finished signal cannot revive old replies")
		terminal.play_dialogue(Dialogues.for_key("chapter_2/capstone"))
		terminal.message.complete_now(); await settle()
		await capture(locale + "-chapter-response")
		check(terminal.choices.get_child_count() == 2, "Optional replies still available")
		(terminal.choices.get_child(1) as Button).pressed.emit(); await settle()
		terminal.dialogue_skip.pressed.emit(); await settle()
		terminal.message.complete_now(); await settle()
		check(not terminal.in_dialogue() and terminal.choices.get_child_count() == 0, "Leaving an answer discards its pending continuation")
		ProjectSettings.set_setting("game/reduced_motion", true)
		terminal.play_dialogue(Dialogues.for_key("chapter_3/synthesis")); await settle()
		check(not terminal.message.is_playing() and terminal.dialogue_skip.visible, "Reduced motion keeps immediate exit")
		terminal.ask_quit(); await settle()
		terminal.cancel_quit(); await settle()
		check(terminal.in_dialogue() and terminal.dialogue_skip.is_visible_in_tree(), "Cancel quit returns to the skippable conversation")
		terminal.dialogue_skip.pressed.emit(); await settle()
		var after: Dictionary = save._save_snapshot(); after.erase("saved_at_utc")
		check(before == after, "Reading, replying and skipping grant no progression")
		var archive: Control = hub.get_node("Laboratory/LabArchive")
		archive.present(locale == "en"); await settle()
		# Reader fixture: display a locked draft without granting its completion.
		archive._show("keep_a_record"); await settle()
		check(archive.note_label.text.contains("候选" if locale == "zh_CN" else "awaiting confirmation"), "Unconfirmed archive is visibly a story draft")
		await capture(locale + "-archive-candidate-fixture")
		archive._show("first_light"); await settle()
		check(not archive.note_label.text.contains("候选" if locale == "zh_CN" else "awaiting confirmation"), "Verified journey note is distinguished from a story draft")
		await capture(locale + "-archive-note-fixture")
		await release(hub)
		root.get_node("GameMode").set_mode(&"test")
		var hardware: Control = await open_scene("res://src/hardware_foundations/hardware_foundations.tscn")
		hardware._show_tutorial(true); await settle()
		await capture(locale + "-not-start")
		hardware._on_connection_request(&"A_IN", 0, &"NOT_1", 0)
		hardware._on_connection_request(&"NOT_1", 0, &"LAMP", 0)
		hardware.input_a_button.button_pressed = true
		hardware._run_debug()
		hardware._on_disconnection_request(&"NOT_1", 0, &"LAMP", 0)
		check(not hardware.completed_levels.get(&"tutorial", false), "Four tutorial actions still do not complete")
		hardware._on_connection_request(&"NOT_1", 0, &"LAMP", 0); await settle()
		check(hardware.completed_levels.get(&"tutorial", false), "Five actions still complete with one real run")
		await capture(locale + "-not-earned")
		hardware._start_campaign_level(&"half_adder", false); await settle()
		check(hardware.tutorial_coach.praise_row.modulate.a == 0.0, "New task does not inherit previous step praise")
		hardware.tutorial_coach.find_child("CoachBriefing", true, false).pressed.emit(); await settle()
		check(hardware.desktop_windows[&"task"].z_index > hardware.tutorial_coach.z_index, "Full briefing appears above the guide that opened it")
		await capture(locale + "-half-adder")
		await release(hardware)
		root.get_node("SystemChapter").reset_test_progress()
		var system: Control = await open_scene("res://src/system_lab/system_lab.tscn")
		system._start_level(&"cpu_speed"); await settle()
		system.prediction_selector.select(1); system._lock_prediction()
		system._run_official(); system._finish_playback(); await settle()
		check(not root.get_node("SystemChapter").completed_levels().get(&"cpu_speed", false), "Baseline alone remains incomplete")
		system._open_instrument(&"mission"); await settle()
		await capture(locale + "-cpu-baseline")
		system.part_selectors[&"cpu"].select(1); system._on_part_selected(1, &"cpu")
		system._run_official(); system._finish_playback(); await settle()
		check(root.get_node("SystemChapter").completed_levels().get(&"cpu_speed", false), "Real controlled comparison completes")
		system._open_instrument(&"mission"); await settle()
		check(system.size.x <= root.size.x, "Completed comparison fits the 720p viewport width")
		await capture(locale + "-cpu-comparison")
		system._start_level(&"bottleneck")
		system._run_official(); system._finish_playback(); await settle()
		check(system.latest_receipt.all_passed, "Bottleneck view has an actual valid official run")
		system._open_instrument(&"mission"); await settle()
		await capture(locale + "-bottleneck-evidence")
		await release(system)
		var locality: Control = await open_scene("res://src/ui/main.tscn")
		locality._start_level(&"access_order"); await settle()
		# The second locale can restore the first locale's accepted program.
		locality.column_strategy_button.pressed.emit()
		locality.apply_program_button.pressed.emit()
		locality._run_simulation("Official Test Set"); locality._finish_playback(); await settle()
		check(locality.current_trace.passed and not locality.current_goal_met, "Correct but slow access order remains insufficient")
		locality._open_instrument(&"mission"); await settle()
		await capture(locale + "-access-order-before")
		locality.row_strategy_button.pressed.emit()
		locality.apply_program_button.pressed.emit()
		locality._run_simulation("Official Test Set"); locality._finish_playback(); await settle()
		check(locality.current_trace.passed and locality.current_goal_met, "Applied row-first program meets the real target")
		locality._open_instrument(&"mission"); await settle()
		await capture(locale + "-access-order-after")
		await release(locality)
		var creation: Control = await open_scene("res://experiments/creation/workbench.tscn")
		var opened: Dictionary = creation.session.open("user://narrative-creation-" + locale + ".json")
		creation.writable = bool(opened.get("writable", false))
		check(creation.writable, "Creation has its own writable QA profile")
		creation.train_model(); creation.source_kind = 2; creation.transport("predictive")
		creation.switch_mode("predict"); creation.begin_prediction("practice")
		while not creation.session.prediction.finished: creation.commit_prediction(); creation.reveal_prediction()
		creation.switch_mode("generate"); creation.change_task(8); creation.generate_work(); await settle()
		check(not creation.session.data.supports.has("G3_keep"), "Generation alone grants no saved work")
		creation.name_input.text = ""
		creation.keep_work(); await settle()
		check(creation.session.data.works.is_empty(), "Unnamed output is not saved")
		await capture(locale + "-g3-name-required")
		creation.name_input.text = "Narrative QA " + locale
		creation.keep_work(); await settle()
		check(creation.session.data.works.size() == 1 and creation.session.data.supports.has("G3_keep"), "Original Keep transaction earns G3")
		var work: Dictionary = creation.session.data.works[0].duplicate(true)
		check(creation.session.replay_work(0).get("matches", false), "Saved recipe reproduces the output")
		await capture(locale + "-g3-saved")
		await release(creation)
		creation = await open_scene("res://experiments/creation/workbench.tscn")
		creation.session.open("user://narrative-creation-" + locale + ".json")
		check(creation.session.data.works[0] == work, "Reopening preserves the exact saved work and recipe")
		await release(creation)
		hub = await open_scene("res://src/ui/prototype_hub.tscn")
		terminal = hub.get_node("Laboratory").terminal
		# Presentation fixture only: actual Keep above was earned in a separate QA profile.
		terminal.configure({"english": locale == "en", "new_player": false,
			"response": {"chapter": LabHome.CHAPTER_RESPONSES["creation/G3_keep"]}})
		terminal.wake(true); terminal.message.complete_now(); await settle()
		await capture(locale + "-work-response-fixture")
		await release(hub)
		root.get_node("GameMode").set_mode(&"game")
	print(("PASS: " if failures == 0 else "FAIL: ") + "narrative review %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
