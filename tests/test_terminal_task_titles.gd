extends "res://tests/test_recovery_game_input.gd"
## Live catalog, presentation-only task fixtures. No completion or access is granted.
const Naming = preload("res://src/campaign/journey_naming.gd")
const SHOTS := ["hardware_foundations/tutorial", "hardware_foundations/half_adder", "hardware_foundations/cpu", "representation/interior_hotspots", "representation/dense_sparse", "representation/prepare_once", "representation/cross_assets", "creation/G3_keep"]

func _run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	var locales: Array[String] = ["zh_CN", "en"]
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--locale="): locales = [argument.trim_prefix("--locale=")]
	var records: Array[Dictionary] = []
	for locale: String in locales:
		root.get_node("Localization").set_locale(locale)
		change_scene_to_file("res://src/ui/prototype_hub.tscn")
		await settle(12)
		await create_timer(1.3).timeout
		var terminal: Control = current_scene.laboratory.terminal
		var rows: Array[Dictionary] = root.get_node("TaskNavigation").journey_tasks()
		check(rows.size() == 60, "All sixty real catalog tasks are audited in " + locale)
		var original_completion: Dictionary = root.get_node("GlobalSave").game_player_content.completed_levels.duplicate(true)
		var names: Dictionary = {}
		for task: Dictionary in rows:
			var expected: String = Naming.plain_title(task.title)
			var fixture := {"english":locale == "en", "new_player":false, "next_key":task.key, "next_title":task.title, "completed":0, "total":60}
			terminal.configure(fixture)
			terminal.wake(true)
			await settle(3)
			var action: String = terminal.primary.text
			check(action.get_slice("\n", 1) == expected and not expected.is_empty(), "The complete task name occupies its own button line: " + task.key)
			check(not names.has(expected), "Distinct tasks retain distinct visible names: " + task.key)
			names[expected] = task.key
			check(terminal.primary.tooltip_text == task.title, "The full source title remains available: " + task.key)
			check(terminal.message.text.contains(expected), "Yi names the actual next task: " + task.key)
			check(terminal.get_global_rect().encloses(terminal.primary.get_global_rect()) and root.get_visible_rect().encloses(terminal.primary.get_global_rect()), "The full task action fits the terminal and 720p viewport: " + task.key)
			var font: Font = terminal.primary.get_theme_font("font")
			var font_size: int = terminal.primary.get_theme_font_size("font_size")
			var padding: float = terminal.primary.get_theme_stylebox("normal").get_minimum_size().x
			for line: String in action.split("\n"):
				check(font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x + padding <= terminal.primary.size.x + 0.5, "Button text fits without dropping words: " + task.key + " / " + line)
			var welcome: String = terminal.message.text
			if task.key in SHOTS and "--recovery-capture" in OS.get_cmdline_user_args():
				await click(terminal.message.get_global_rect().get_center())
				await capture(str(task.key).replace("/", "-"))
			fixture["response"] = {"task":task}
			terminal.configure(fixture)
			check(terminal.message.text.contains(expected), "The ordinary completion response retains the task name: " + task.key)
			records.append({"locale":locale,"key":task.key,"title":task.title,"name":expected,"button":action,"welcome":welcome,"completion":terminal.message.text})
		check(root.get_node("GlobalSave").game_player_content.completed_levels == original_completion, "Title fixtures do not award or modify progression in " + locale)
	var file := FileAccess.open(evidence_root + "task-title-audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "\t"))
	await finish()
