extends Control

const Fullscreen = preload("res://src/ui/fullscreen_button.gd")
var start_button: Button
var continue_button: Button
var level_buttons: Dictionary = {}

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 60)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 16)
	margin.add_child(page)
	var heading := Label.new()
	heading.text = Localization.text(&"demo.menu.title")
	heading.add_theme_font_size_override("font_size", 36)
	page.add_child(heading)
	var subtitle := Label.new()
	subtitle.text = Localization.text(&"demo.menu.subtitle")
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(subtitle)
	var actions := HBoxContainer.new()
	page.add_child(actions)
	start_button = _button(actions, &"demo.menu.start", func() -> void: open_task("dp_select", 0))
	continue_button = _button(actions, &"demo.menu.continue", func() -> void: open_task(DemoProgress.state()["current"], int(DemoProgress.state()["stage"])))
	continue_button.disabled = not DemoProgress.has_progress()
	_button(actions, &"demo.menu.workshop", func() -> void: get_tree().change_scene_to_file("res://src/hardware_foundations/hardware_foundations.tscn"))
	actions.add_child(Fullscreen.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(scroll)
	var levels := VBoxContainer.new()
	levels.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(levels)
	for id: String in DemoProgress.IDS:
		var unlocked: bool = DemoProgress.unlocked(id)
		var button := _button(levels, StringName("demo.task." + id + ".title"), func() -> void: open_task(id))
		button.disabled = not unlocked
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if DemoProgress.task_complete(id):
			button.text += "   ✓"
		elif not unlocked:
			button.text += "   " + Localization.text(&"demo.menu.locked_short")
			var index: int = DemoProgress.IDS.find(id)
			button.visible = index > 0 and DemoProgress.unlocked(DemoProgress.IDS[index - 1])
		level_buttons[id] = button
	var note := Label.new()
	note.text = Localization.text(&"demo.menu.workshop_note")
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	page.add_child(note)
	if not DemoProgress.warning.is_empty():
		var warning := Label.new()
		warning.text = Localization.text(StringName(DemoProgress.warning))
		warning.modulate = Color("ffbd80")
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		page.add_child(warning)
	var footer := HBoxContainer.new()
	page.add_child(footer)
	_button(footer, &"demo.menu.legacy", func() -> void: get_tree().change_scene_to_file("res://src/ui/prototype_hub.tscn"))
	_button(footer, &"demo.menu.export", func() -> void:
		var path: String = PlaytestData.export_current_session()
		note.text = Localization.text(&"playtest.export.success", [path]) if not path.is_empty() else Localization.text(&"playtest.export.failed", [PlaytestData.last_error])
	)
	_button(footer, &"hub.options.quit", func() -> void: get_tree().quit())

func _button(parent: Node, key: StringName, action: Callable) -> Button:
	var button := Button.new()
	button.text = Localization.text(key)
	button.add_theme_font_size_override("font_size", 22)
	button.custom_minimum_size = Vector2(150, 46)
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func open_task(id: String, stage: int = -1) -> void:
	if DemoProgress.enter(id, stage):
		get_tree().change_scene_to_file("res://src/demo/demo_workbench.tscn")
