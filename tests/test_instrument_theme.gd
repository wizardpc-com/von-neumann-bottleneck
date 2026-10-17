extends SceneTree

const ThemeType = preload("res://src/ui/instrument_theme.gd")
const BackdropType = preload("res://src/ui/technical_backdrop.gd")
const Typography = preload("res://src/ui/ui_typography.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for light: bool in [false, true]:
		_check_palette(light)
	var primary := Button.new()
	ThemeType.primary(primary)
	_check(_contrast(primary.get_theme_color("font_color"), (primary.get_theme_stylebox("normal") as StyleBoxFlat).bg_color) >= 4.5, "Primary action text remains readable.")
	_check(_contrast(primary.get_theme_color("font_hover_pressed_color"), (primary.get_theme_stylebox("hover_pressed") as StyleBoxFlat).bg_color) >= 4.5, "Held primary action text remains readable under the pointer.")
	_check(_contrast((primary.get_theme_stylebox("focus") as StyleBoxFlat).border_color, (primary.get_theme_stylebox("normal") as StyleBoxFlat).bg_color) >= 3.0, "Primary action focus remains visible on its bright fill.")
	_check(_contrast(primary.get_theme_color("font_disabled_color"), (primary.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color) >= 4.5, "Disabled primary action remains readable.")
	primary.free()
	if "--theme-capture" in OS.get_cmdline_user_args():
		await _capture_comparison()
	if failures.is_empty():
		print("PASS: shared instrument contrast, focus, selection and comparison geometry")
	else:
		for failure: String in failures:
			push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _check_palette(light: bool) -> void:
	var shared := Theme.new()
	ThemeType.apply_to(shared, light)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var foreground: Color = shared.get_color("font_disabled_color" if state == "disabled" else "font_color", "Button")
		var box: StyleBoxFlat = shared.get_stylebox(state, "Button")
		_check(_contrast(foreground, box.bg_color) >= 4.5, "%s %s text contrast" % ["light" if light else "dark", state])
	var focus: StyleBoxFlat = shared.get_stylebox("focus", "Button")
	var idle: StyleBoxFlat = shared.get_stylebox("normal", "Button")
	_check(focus.bg_color.a == 0.0 and focus.border_width_left == 2, "Keyboard focus is an outline that leaves state visible.")
	_check(_contrast(focus.border_color, idle.bg_color) >= 3.0, "Focus outline has sufficient contrast.")
	var selected: StyleBoxFlat = shared.get_stylebox("selected", "ItemList")
	_check(selected.border_width_left > selected.border_width_right, "Selection has a non-color edge marker.")
	_check(_contrast(shared.get_color("font_selected_color", "ItemList"), selected.bg_color) >= 4.5, "Selected list text remains readable.")
	var pressed: StyleBoxFlat = shared.get_stylebox("pressed", "Button")
	_check(pressed.border_width_left > idle.border_width_left, "Pressed/toggled buttons have a non-color edge marker.")
	_check(pressed.get_content_margin(SIDE_LEFT) == idle.get_content_margin(SIDE_LEFT), "State changes preserve content geometry.")
	var focused_window: StyleBoxFlat = shared.get_stylebox("embedded_border", "Window")
	var unfocused_window: StyleBoxFlat = shared.get_stylebox("embedded_unfocused_border", "Window")
	_check(focused_window.content_margin_top == unfocused_window.content_margin_top and focused_window.expand_margin_top == unfocused_window.expand_margin_top, "Window focus changes preserve title geometry.")


func _contrast(foreground: Color, background: Color) -> float:
	var front: float = foreground.srgb_to_linear().get_luminance()
	var back: float = background.srgb_to_linear().get_luminance()
	return (maxf(front, back) + 0.05) / (minf(front, back) + 0.05)


func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func _capture_comparison() -> void:
	var locale := "zh_CN"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-size="):
			var dimensions: PackedStringArray = argument.trim_prefix("--capture-size=").split("x")
			root.size = Vector2i(int(dimensions[0]), int(dimensions[1]))
		if argument.begins_with("--capture-locale="):
			locale = argument.trim_prefix("--capture-locale=")
	var english: bool = locale == "en"
	var matching_rects: Array[Rect2] = []
	for light: bool in [false, true]:
		var page := Control.new()
		root.add_child(page)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		page.theme = Theme.new()
		ThemeType.apply_to(page.theme, light)
		var backdrop := BackdropType.new()
		backdrop.light = light
		page.add_child(backdrop)
		var inset := MarginContainer.new()
		page.add_child(inset)
		inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		for side: String in ["left", "top", "right", "bottom"]:
			inset.add_theme_constant_override("margin_" + side, 32)
		var surface := PanelContainer.new()
		inset.add_child(surface)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 12)
		surface.add_child(column)
		var heading := Label.new()
		heading.text = "Same circuit · two readings" if english else "同一电路 · 两种读法"
		heading.add_theme_font_size_override("font_size", Typography.TITLE_SIZE)
		column.add_child(heading)
		var description := Label.new()
		description.text = "A = 1   B = 0   →   AND = 0    |    1 bit / 4 bits" if english else "A = 1   B = 0   →   与门 = 0    |    1 位 / 4 位"
		column.add_child(description)
		var focused: Button
		for index: int in range(4):
			var button := Button.new()
			button.text = (["Run test", "Selected · trace 1", "Keyboard focus", "Unavailable · connect input"] if english else ["运行测试", "已选择 · 轨迹 1", "键盘焦点", "暂不可用 · 请连接输入"])[index]
			button.custom_minimum_size.y = Typography.CONTROL_HEIGHT
			button.toggle_mode = index == 1
			button.button_pressed = index == 1
			button.disabled = index == 3
			column.add_child(button)
			if index == 2:
				focused = button
		var input := LineEdit.new()
		input.text = "0101 → 5"
		input.custom_minimum_size.y = Typography.CONTROL_HEIGHT
		column.add_child(input)
		var list := ItemList.new()
		list.custom_minimum_size.y = 100
		list.add_item("[1 bit]  A = 1")
		list.add_item("[4 bits]  DATA = 0101")
		list.select(1)
		column.add_child(list)
		focused.grab_focus()
		for _frame: int in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var rect := Rect2(surface.global_position, surface.size)
		_check(Rect2(Vector2.ZERO, Vector2(root.size)).encloses(rect), "Comparison panel fits viewport.")
		if matching_rects.is_empty():
			matching_rects.append(rect)
		else:
			_check(matching_rects[0] == rect, "Palette comparison uses matching panel geometry.")
		var path: String = "user://night-theme-%s-%s-%dx%d.png" % ["light" if light else "dark", locale, root.size.x, root.size.y]
		_check(root.get_texture().get_image().save_png(path) == OK, "Comparison screenshot saved.")
		print("THEME_CAPTURE: ", ProjectSettings.globalize_path(path))
		page.queue_free()
		await process_frame
