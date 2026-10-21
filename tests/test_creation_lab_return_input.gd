extends "res://tests/test_recovery_game_input.gd"
## Real saved profile and laboratory routing. Learning/prediction preparation
## uses controllers; save, departure, terminal and work-wall actions use GUI input.
const CREATION := "res://experiments/creation/workbench.tscn"
const HUB := "res://src/ui/prototype_hub.tscn"
const MAP := "res://src/campaign/task_tree.tscn"

func arrive(path: String) -> bool:
	var deadline: int = Time.get_ticks_msec() + 8000
	while (current_scene == null or current_scene.scene_file_path != path) and Time.get_ticks_msec() < deadline:
		await process_frame
	var reached: bool = current_scene != null and current_scene.scene_file_path == path
	check(reached, "The actual scene transition reaches " + path)
	await settle(12)
	if reached and path == HUB: await create_timer(1.3).timeout
	return reached

func window_press(window: Window, control: Button) -> void:
	await settle()
	check(control.is_visible_in_tree() and window.get_visible_rect().encloses(control.get_global_rect()), "The departure choice is visible inside its own window.")
	check(window.is_embedded(), "The game uses an embedded departure window.")
	await click(Vector2(window.position) + control.get_global_rect().get_center())

func dialog_shot(window: Window) -> void:
	if "--recovery-capture" not in OS.get_cmdline_user_args(): return
	RenderingServer.force_draw(false)
	var locale: String = root.get_node("Localization").current_locale()
	check(window.get_texture().get_image().save_png(evidence_root + locale + "-leave-choice.png") == OK, "The actual departure window is captured separately from the main viewport.")

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	change_scene_to_file(HUB)
	if not await arrive(HUB): await finish(); return
	var lab: Control = current_scene.laboratory
	check(lab.works.is_empty() and lab.terminal.response.is_empty(), "A fresh laboratory has no work and no earned work response.")
	await press(lab.find_child("WorkFrame", true, false))
	if not await arrive(CREATION): await finish(); return
	ui = current_scene
	check(ui.task == 8 and ui.session.data.works.is_empty(), "The actual work wall opens the empty G3 workbench.")
	ui.train_model()
	ui.source_kind = 2
	ui.transport("predictive")
	ui.switch_mode("predict")
	ui.begin_prediction("practice")
	while not ui.session.prediction.finished:
		ui.commit_prediction()
		ui.reveal_prediction()
	ui.switch_mode("generate")
	ui.change_task(8)
	await settle()
	await press(ui.find_child("Generate", true, false))
	check(ui.session.dirty and not ui.session.data.supports.has("G3_keep"), "The actual generated output remains unkept.")
	var generated: Dictionary = ui.latest.duplicate(true)
	await key(KEY_ESCAPE)
	check(ui.leave_dialog.visible and current_scene == ui, "Leaving an unsaved draft opens the existing departure choice.")
	check(ui.leave_dialog.dialog_text.contains("not yet a saved work" if ui.english else "尚未保存为作品"), "Departure feedback distinguishes an unkept output from the draft save.")
	check(ui.leave_dialog.get_ok_button().text.contains("draft" if ui.english else "草稿"), "The confirmation button names the draft it actually saves.")
	await dialog_shot(ui.leave_dialog)
	await window_press(ui.leave_dialog, ui.leave_dialog.get_cancel_button())
	check(not ui.leave_dialog.visible and current_scene == ui and ui.session.data.works.is_empty(), "Keep editing returns to the actual output without saving or leaving.")
	await key(KEY_ESCAPE)
	await window_press(ui.leave_dialog, ui.leave_dialog.get_ok_button())
	if not await arrive(MAP): await finish(); return
	await key(KEY_ESCAPE)
	if not await arrive(HUB): await finish(); return
	lab = current_scene.laboratory
	check(lab.works.is_empty() and lab.terminal.response.get("chapter", {}) != lab.CHAPTER_RESPONSES["creation/G3_keep"], "Saving the draft and leaving creates no work-wall entry or saved-work response.")
	await click(lab.terminal.message.get_global_rect().get_center())
	await capture("draft-return")
	await press(lab.find_child("WorkFrame", true, false))
	if not await arrive(CREATION): await finish(); return
	ui = current_scene
	check(ui.session.data.works.is_empty() and not ui.session.data.supports.has("G3_keep") and not ui.can_keep_visible_work(), "Reopening the draft does not turn the unsaved generation into a protected work.")
	await press(ui.find_child("Generate", true, false))
	check(ui.latest.output == generated.output and ui.latest.recipe == generated.recipe, "The saved draft regenerates its original output and recipe before Keep.")
	await press(ui.name_input)
	await type_text("A passage to return to")
	await press(ui.find_child("KeepCurrent", true, false))
	check(ui.session.data.works.size() == 1 and ui.session.data.supports.has("G3_keep"), "Naming and explicitly keeping earns one actual saved work.")
	if ui.session.data.works.is_empty(): await finish(); return
	var work: Dictionary = ui.session.data.works[0].duplicate(true)
	var path: String = ui.session.path
	var saved_bytes: String = FileAccess.get_file_as_string(path)
	await key(KEY_ESCAPE)
	if not await arrive(MAP): await finish(); return
	await key(KEY_ESCAPE)
	if not await arrive(HUB): await finish(); return
	lab = current_scene.laboratory
	check(lab.works.size() == 1 and lab.works[0] == work, "The laboratory reads the actual protected work from the same profile.")
	check(lab.terminal.response.has("chapter") and lab.terminal.response.chapter == lab.CHAPTER_RESPONSES["creation/G3_keep"], "The actual earned G3 support selects Yi's work response without a presentation fixture.")
	check(not lab.terminal.asleep() and lab.terminal.primary.is_visible_in_tree() and not lab.terminal.in_dialogue(), "Returning wakes the terminal and offers navigation without required dialogue choices.")
	await click(lab.terminal.message.get_global_rect().get_center())
	await capture("earned-work-response")
	check(FileAccess.get_file_as_string(path) == saved_bytes, "Reading Yi's response does not rewrite the work or its completion support.")
	await press(lab.find_child("WorkFrame", true, false))
	if not await arrive(CREATION): await finish(); return
	ui = current_scene
	check(ui.task == 8 and ui.latest.get("kind", "") == "snapshot" and ui.latest.work == work, "Clicking the work wall reopens that exact saved output and recipe.")
	await create_timer(5.5).timeout
	await capture("work-wall-reopened")
	await key(KEY_ESCAPE)
	if not await arrive(MAP): await finish(); return
	await key(KEY_ESCAPE)
	if not await arrive(HUB): await finish(); return
	lab = current_scene.laboratory
	check(lab.terminal.response.is_empty() and not lab.terminal.in_dialogue(), "Revisiting the same work does not replay its earned response as a new achievement.")
	check(FileAccess.get_file_as_string(path) == saved_bytes and lab.works[0] == work, "The complete laboratory round trip preserves the work and its saved file.")
	await click(lab.terminal.message.get_global_rect().get_center())
	await capture("quiet-return")
	await finish()
