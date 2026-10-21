extends "res://tests/test_recovery_game_input.gd"
## Preparation uses real controller operations; G3 acceptance uses viewport input.
## Each run uses a fresh isolated profile. No campaign-wide playthrough is claimed.

func action(id: String) -> void:
	await press(ui.find_child(id, true, false))

func shot(label: String) -> void:
	if "--recovery-capture" in OS.get_cmdline_user_args():
		await create_timer(6.0).timeout
		await capture(label)

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	change_scene_to_file("res://experiments/creation/workbench.tscn")
	await settle(12)
	ui = current_scene
	check(ui.writable and ui.session.data.works.is_empty(), "Preparation starts with a fresh writable profile and no works.")
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
	await settle(12)
	await action("Generate")
	check(ui.latest.get("kind", "") == "generation" and ui.can_keep_visible_work(), "The visible Generate button produces an actual savable result.")
	var output: Array = ui.latest.output.duplicate()
	var recipe: Dictionary = ui.latest.recipe.duplicate(true)
	check(not ui.session.data.supports.has("G3_keep"), "Generation does not grant Keep completion.")
	await action("SaveDraft")
	check(not ui.session.dirty and ui.session.data.works.is_empty() and not ui.session.data.supports.has("G3_keep"), "Save draft writes the draft without keeping a work or granting G3.")
	check(ui.provenance.text.contains("draft saved" if ui.english else "草稿已保存"), "The persistent status identifies the draft as what was saved.")
	check(ui.status.text.contains("name and save" if ui.english else "命名后保存为作品"), "Draft-save feedback points to the separate work-saving action.")
	await shot("draft-only")
	var tabs: TabContainer = ui.find_child("EvidenceTabs", true, false)
	var tab_bar: TabBar = tabs.get_tab_bar()
	await click(tab_bar.get_global_transform() * tab_bar.get_tab_rect(0).get_center())
	check(tabs.current_tab == 0, "The player can choose Measurements before attempting to save.")
	var previous_tab: int = tabs.current_tab
	await action("KeepCurrent")
	check(ui.session.data.works.is_empty() and not ui.saved_work_closure.visible, "Empty-name rejection creates no work or successful-save closure.")
	check(tabs.current_tab == previous_tab and ui.name_input.has_focus(), "G3 keeps the current evidence tab and focuses the visible bottom name field.")
	check(root.get_visible_rect().encloses(ui.name_input.get_global_rect()), "The focused name field fits the 720p viewport.")
	await shot("name-required")
	await type_text("x".repeat(81))
	await action("KeepCurrent")
	check(ui.session.data.works.is_empty() and not ui.session.data.supports.has("G3_keep") and ui.status.text.contains("80"), "An overlong name reports the existing limit without granting completion.")
	await press(ui.name_input)
	await key(KEY_A, true)
	await type_text("My first passage")
	await action("KeepCurrent")
	check(ui.session.data.works.size() == 1 and ui.session.data.supports.has("G3_keep"), "Correcting the name and clicking Keep earns the existing G3 transaction.")
	if ui.session.data.works.is_empty():
		await finish()
		return
	var kept: Dictionary = ui.session.data.works[0].duplicate(true)
	check(kept.output == output and kept.recipe == recipe and kept.name == "My first passage", "The named saved work contains the exact visible output and recipe.")
	check(ui.saved_work_closure.visible and not is_instance_valid(ui.work_focus), "Successful save offers viewing without forcing a modal.")
	await shot("kept")
	await action("ViewKeptWork")
	check(is_instance_valid(ui.work_focus) and ui.work_focus.work == kept, "The visible view action opens the actual kept work.")
	# Embedded window input has its own viewport; existing work-focus tests cover it.
	ui.work_focus.dismiss()
	await settle()
	var save_path: String = ui.session.path
	change_scene_to_file("res://experiments/creation/workbench.tscn")
	await settle(12)
	ui = current_scene
	check(ui.session.path == save_path and ui.session.data.works[0] == kept, "Reopening reads the exact saved work from disk.")
	check(ui.latest.get("kind", "") == "snapshot" and not ui.can_keep_visible_work(), "Reopening shows the saved snapshot without pretending it is a new generation.")
	check(ui.status.text.contains("last saved work" if ui.english else "上次保存的作品"), "The opening status describes the restored work rather than asking the player to learn again.")
	await shot("reopened")
	# Exercise the shelf limit through real transactions, without altering its size.
	ui.generate_work()
	for index: int in range(11):
		check(ui.session.save_work("Shelf fixture %d" % index).get("ok", false), "The disclosed shelf fixture saves through the original transaction.")
	ui.refresh()
	await settle()
	await press(ui.name_input)
	await type_text("Thirteenth work")
	var before: Array = ui.session.data.works.duplicate(true)
	await action("KeepCurrent")
	check(ui.session.data.works == before and ui.session.data.works.size() == 12, "Full-shelf rejection preserves all twelve saved works.")
	check(ui.status.text.contains("12") and ui.status.text.contains("No new work" if ui.english else "未新增作品"), "Full-shelf feedback describes this rejected save, even when an earlier work has the same output.")
	await shot("shelf-full")
	await finish()
