extends "res://tests/test_recovery_game_input.gd"
## Test access is a controller fixture, not earned prerequisites. Popup menus
## use Godot windows for deterministic viewport dispatch. Editing, Apply, Run, inspection, review and map return use
## viewport input. No simulation result or completion is injected.
const Templates = preload("res://src/simulation/program_templates.gd")
var completed_loops: Array[String] = []

func tool(id: StringName) -> void:
	await press(ui.instrument_open_buttons[id])
	if not ui.instrument_windows[id].visible: await press(ui.instrument_open_buttons[id])
	await settle()

func program(source: String) -> void:
	await tool(&"program")
	await press(ui.editor)
	check(ui.editor.has_focus(),"Actual editor click owns keyboard focus")
	await key(KEY_A,true); await key(KEY_BACKSPACE)
	check(ui.editor.text.is_empty(),"Select-all and Backspace clear the focused editor; actual="+JSON.stringify(ui.editor.text))
	var lines: PackedStringArray = source.split("\n")
	for i: int in lines.size():
		if i > 0:
			await key(KEY_ENTER)
			# Remove only the editor's automatic indentation on this new empty
			# line, then type the intended source using ordinary keyboard events.
			for indent_step: int in 16:
				if ui.editor.get_caret_column() == 0: break
				await key(KEY_BACKSPACE)
		await type_text(lines[i])
	await settle()
	check(ui.editor.text == source,"Viewport typing preserves the exact intended source; actual="+JSON.stringify(ui.editor.text)+" expected="+JSON.stringify(source))

func prediction() -> void:
	check(ui.official_run_button.disabled and not ui.draft_dirty and ui.applied_program.is_valid(),"Applied valid program awaits its required fresh prediction")
	await tool(&"mission")
	check(ui.prediction_question_label.is_visible_in_tree() and not ui.prediction_question_label.text.is_empty() and ui.prediction_selector.selected == 0,"Mission exposes the prediction question and unselected choice explaining the remaining step")
	var popup: PopupMenu = ui.prediction_selector.get_popup()
	popup.prefer_native_menu = false
	await press(ui.prediction_selector)
	check(popup.visible,"Prediction selector opens its actual menu")
	if not popup.visible: return
	popup.grab_focus(); await create_timer(0.2).timeout
	for attempt: int in popup.item_count+1:
		if popup.get_focused_item() == 1: break
		await prediction_key(popup,KEY_DOWN)
	await prediction_key(popup,KEY_ENTER); await settle()
	await press(ui.prediction_lock_button)
	check(not ui.locked_prediction_id.is_empty(),"Explicit prediction reconfirmation authorizes the newly applied program")

func prediction_key(popup: PopupMenu, code: Key) -> void:
	for down: bool in [true,false]:
		if not is_instance_valid(popup) or not popup.visible: return
		var event := InputEventKey.new()
		event.window_id = popup.get_window_id(); event.keycode = code; event.physical_keycode = code; event.pressed = down
		Input.parse_input_event(event); await process_frame

func run_and_finish(system: bool) -> void:
	if system and ui.locked_prediction_id.is_empty(): await prediction()
	await tool(&"test_bench")
	check(not ui.official_run_button.disabled,"Explicit Run is enabled; status="+ui.status_label.text)
	await press(ui.official_run_button); await settle()
	check(ui.current_trace != null,"Explicit Run produces an actual trace")
	if ui.current_trace == null: return
	await tool(&"profiler")
	if not ui.finish_playback_button.disabled: await press(ui.finish_playback_button)
	await settle()
	check(not ui.playback_running,"Visible Finish completes presentation without replacing its trace")
	if system: check(ui.latest_receipt != null,"Ch1 exposes the actual multi-case receipt")

func host_for(task: String, scene: String) -> void:
	var nav: Node = root.get_node("TaskNavigation")
	nav.from_tree = false; nav.pending = task
	ui = load(scene).instantiate(); root.add_child(ui); current_scene = ui
	await settle(12)

func clear_host() -> void:
	if current_scene != null: current_scene.queue_free()
	current_scene = null; await settle()

func chapter_one(locale: String) -> void:
	root.get_node("SystemChapter").reset_test_progress()
	await host_for("chapter_1/cpu_speed","res://src/system_lab/system_lab.tscn")
	var correct: String = ui.current_level_definition.program_source
	var wrong: String = correct.replace("acc += value","acc += 0")
	check(wrong != correct,"Failure experiment changes output computation")
	await program(wrong)
	check(ui.draft_dirty,"Typing leaves an unapplied draft")
	await press(ui.apply_program_button)
	check(ui.applied_program_source == wrong and not ui.draft_dirty,"Apply adopts exactly the typed experiment")
	await run_and_finish(true)
	check(ui.latest_receipt != null and not ui.latest_receipt.all_passed,"Wrong computation yields a real failed receipt")
	check(ui.instrument_windows[&"profiler"].visible and not ui.profiler_labels[&"total_cycles"].text.is_empty(),"Failure remains inspectable in Profiler")
	await operation_capture("ch1-failure-"+locale)
	await program(correct); await press(ui.apply_program_button)
	await run_and_finish(true)
	check(ui.latest_receipt != null and ui.latest_receipt.all_passed,"Correcting and rerunning passes actual cases")
	var draft: String = correct+"\n# unfinished "+locale+"\nacc = ???"
	await program(draft)
	check(ui.draft_dirty and ui.applied_program_source == correct,"New invalid draft leaves the last applied source intact")
	var nav: Node = root.get_node("TaskNavigation")
	nav.from_tree = true; nav.selected = "chapter_1/cpu_speed"
	await press(ui.find_child("ChapterMapButton",true,false)); await settle(12)
	check(current_scene != null and current_scene.scene_file_path == nav.MAP_SCENE,"Map button returns through the real route")
	if current_scene == null or current_scene.scene_file_path != nav.MAP_SCENE: return
	check(current_scene.selected.get("key","") == "chapter_1/cpu_speed","Map retains the exact task")
	await press(current_scene.enter_button); await settle(12)
	ui = current_scene
	if ui == null or ui.scene_file_path != "res://src/system_lab/system_lab.tscn":
		check(false,"Map re-enters Ch1"); return
	check(ui.editor.text == draft and ui.applied_program_source == correct and ui.draft_dirty,"Map roundtrip restores draft and applied source separately")
	completed_loops.append("ch1-"+locale)
	await clear_host()

func chapter_two(locale: String) -> void:
	root.get_node("LocalityChapter").reset_test_progress()
	await host_for("chapter_2/cache_failure","res://src/ui/main.tscn")
	await run_and_finish(false)
	check(ui.current_trace != null and int(ui.current_trace.metrics.total_cycles) == 321,"Observation measures the authored 321-cycle cache failure")
	await tool(&"mission")
	# The chosen diagnosis is explicit input after observing the real trace.
	await press(ui.mission_judgment_buttons[&"replacement"])
	check(ui.mission_review_button.visible and not root.get_node("LocalityChapter").completed_levels().get(&"cache_failure",false),"Correct judgment still requires explicit review")
	await press(ui.mission_review_button); await settle()
	check(root.get_node("LocalityChapter").completed_levels().get(&"cache_failure",false),"Review records the evidence-supported finding")
	check(ui.level_completion_overlay.visible,"Reviewed finding exposes the completion action")
	await press(ui.level_completion_overlay.continue_button); await settle()
	check(ui.chapter_map_host.visible,"Completion returns to the actual chapter map")
	await press(ui.chapter_map.level_buttons[&"access_order"]); await settle(12)
	check(ui.current_level_id == &"access_order","Map enters the paired implementation")
	await program(Templates.ROW_FIRST)
	check(ui.program_dirty,"Implementation remains pending before Apply")
	await press(ui.apply_program_button)
	check(ui.applied_program_source == Templates.ROW_FIRST and not ui.program_dirty,"Apply adopts the typed row-first program")
	await run_and_finish(false)
	check(ui.current_trace != null and int(ui.current_trace.metrics.total_cycles) == 105,"Implementation measures 105 cycles with unchanged hardware")
	await operation_capture("ch2-implementation-"+locale)
	await tool(&"mission"); await press(ui.mission_review_button); await settle()
	check(root.get_node("LocalityChapter").completed_levels().get(&"access_order",false),"Explicit review completes the actual paired implementation")
	completed_loops.append("ch2-"+locale)
	await clear_host()

func operation_capture(label: String) -> void:
	if "--core-operation-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame != null and frame.get_size() == Vector2i(1280,720),label+": unchanged raw capture is 1280x720")
	if frame == null or frame.get_size() != Vector2i(1280,720): return
	var path: String = "user://core-operation-"+label+".png"
	check(frame.save_png(path) == OK,label+": capture saved")
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func stable_viewport() -> void:
	var dimensions := Vector2i(1280,720)
	root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
	await settle(10)
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for attempt: int in 60:
		root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
		DisplayServer.window_set_size(dimensions)
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var frame: Image = root.get_texture().get_image()
		stable = stable+1 if frame != null and frame.get_size() == dimensions else 0
		if stable >= 5: return
	check(false,"Actual 1280x720 renderer stabilizes before any operation; size="+str(root.size)+" mode="+str(root.mode))

func default_scale_cpu() -> void:
	await host_for("hardware_foundations/cpu","res://src/hardware_foundations/hardware_foundations.tscn")
	ui._start_campaign_level(&"cpu",false); ui._finish_mission_briefing(); await settle(12)
	# Controller entry only. Unlike small-logical-canvas stress fixtures, retain
	# the shipped design scale while resizing the physical window.
	for requested: Vector2i in [Vector2i(1280,720),Vector2i(960,640)]:
		root.content_scale_size = Vector2i(1600,900); root.mode = Window.MODE_WINDOWED; root.size = requested
		await settle(12)
		if DisplayServer.get_name() != "headless":
			var stable: int = 0
			for attempt: int in 60:
				await create_timer(0.1).timeout; RenderingServer.force_draw(false)
				var frame: Image = root.get_texture().get_image()
				stable = stable+1 if frame != null and frame.get_size() == root.size else 0
				if stable >= 5: break
			check(stable >= 5,"CPU actual physical window stabilizes, including any native minimum clamp")
		print("CPU_DEFAULT_SCALE ",JSON.stringify({"requested":str(requested),"actual":str(root.size),"minimum":str(root.min_size),"design":str(root.content_scale_size),"logical":str(root.get_visible_rect())}))
		var controls: Array[Control] = [ui.hub_button,ui.pause_button,ui.trace_step_button,ui.clock_period_control]
		var settings: Button = ui.fullscreen_button.get_parent().find_child("InLevelSettings",true,false)
		check(settings != null and settings.is_visible_in_tree(),"Default CPU header exposes its actual Settings entry")
		for child: Node in ui.fullscreen_button.get_parent().get_children():
			if child is Button and child.is_visible_in_tree() and child != ui.hub_button: controls.append(child)
		for child: Node in ui.editor_toolbar.find_child("EditingTools",true,false).get_children():
			if child is Button and child.is_visible_in_tree(): controls.append(child)
		for control: Control in controls:
			check(root.get_visible_rect().encloses(control.get_global_rect()),"Default scale keeps CPU control inside viewport: "+str(control.name))
			await point(control.get_global_rect().get_center())
			var hovered: Control = root.gui_get_hovered_control()
			check(hovered == control or hovered != null and control.is_ancestor_of(hovered),"Default scale CPU control receives actual pointer: "+str(control.name))
		if requested.x == 960 and "--core-operation-capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless":
			RenderingServer.force_draw(false)
			var frame: Image = root.get_texture().get_image()
			check(frame.get_size() == root.size,"CPU scale capture retains actual physical size")
			var path: String = "user://core-operation-cpu-default-scale.png"
			check(frame.save_png(path) == OK,"CPU scale capture saved without resize")
			print("CAPTURE: "+ProjectSettings.globalize_path(path))
	await clear_host()

func _run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(2); return
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = root.size
	if OS.get_name() == "macOS": await create_timer(1.0).timeout
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("game/reduced_motion",true)
	var original: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await stable_viewport()
		await chapter_one(locale)
		if not failures.is_empty(): break
		await chapter_two(locale)
		if not failures.is_empty(): break
	check(completed_loops == ["ch1-zh_CN","ch2-zh_CN","ch1-en","ch2-en"],"All four continuous input loops reach their end")
	if failures.is_empty(): await default_scale_cpu()
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == original,"Test operation loops preserve ordinary Game content")
	print("Core chapter operation checks: %d; failures: %d" % [observations.size(),failures.size()])
	if failures.is_empty(): print("PASS: core chapter operation loop")
	quit(0 if failures.is_empty() else 1)
