extends Control
## The terminal screen inside the laboratory. It is the game's main menu: one
## clear next action, Yi's short message, and a small row of other functions.

signal action(id: String)

const Palette = preload("res://src/lab/lab_palette.gd")

var english: bool = false
var response: Dictionary = {}
var state: Dictionary = {}
var _asleep: bool = true
var sleep_view: VBoxContainer
var awake_view: VBoxContainer
var message: Label
var primary: Button
var secondary: HBoxContainer
var archive_button: Button
var progress_label: Label
var cursor: Label
var header_label: Label
var language_button: Button
var sleep_hint: Label
var _time: float = 0.0

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_PASS
	theme = Theme.new()
	theme.default_font_size = 16
	_build()

func asleep() -> bool:
	return _asleep

func configure(values: Dictionary) -> void:
	state = values
	english = bool(values.get("english", false))
	response = values.get("response", {})
	if message != null: _compose()

func set_fragment_count(opened: int, unread: int) -> void:
	if archive_button == null: return
	archive_button.text = ("档案 %d" if not english else "Archive %d") % opened
	if unread > 0: archive_button.text += " ·" + ("新" if not english else "new")

func _build() -> void:
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right"]: margin.add_theme_constant_override("margin_" + side, 22)
	margin.add_theme_constant_override("margin_top", 16); margin.add_theme_constant_override("margin_bottom", 16)
	add_child(margin)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	var stack := Control.new(); stack.mouse_filter = Control.MOUSE_FILTER_PASS; margin.add_child(stack)
	sleep_view = VBoxContainer.new(); sleep_view.name = "TerminalSleep"
	sleep_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sleep_view.alignment = BoxContainer.ALIGNMENT_CENTER
	sleep_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_child(sleep_view)
	cursor = _label(sleep_view, "▍", 26, Palette.ACCENT)
	cursor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sleep_hint = _label(sleep_view, "", 15, Palette.TERM_MUTED); sleep_hint.name = "SleepHint"
	sleep_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	awake_view = VBoxContainer.new(); awake_view.name = "TerminalAwake"
	awake_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	awake_view.add_theme_constant_override("separation", 9)
	awake_view.hide(); stack.add_child(awake_view)
	var header := HBoxContainer.new(); awake_view.add_child(header)
	header_label = _label(header, "", 13, Palette.TERM_MUTED); header_label.name = "TerminalHeader"
	header_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress_label = _label(header, "", 13, Palette.TERM_MUTED)
	progress_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	progress_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	language_button = _button(header, "EN", "language", false); language_button.name = "TerminalLanguage"
	language_button.custom_minimum_size = Vector2(44, 24); language_button.add_theme_font_size_override("font_size", 12)
	var rule := ColorRect.new(); rule.color = Palette.with_alpha(Palette.TERM_EDGE, 0.9); rule.custom_minimum_size.y = 1
	awake_view.add_child(rule)
	message = _label(awake_view, "", 17, Palette.TERM_TEXT); message.name = "YiMessage"
	message.size_flags_vertical = Control.SIZE_EXPAND_FILL
	message.add_theme_constant_override("line_spacing", 5)
	primary = _button(awake_view, "", "start", true); primary.name = "TerminalPrimary"
	primary.custom_minimum_size.y = 44; primary.add_theme_font_size_override("font_size", 17)
	secondary = HBoxContainer.new(); secondary.add_theme_constant_override("separation", 6)
	awake_view.add_child(secondary)
	var labels: Array = [["旅程", "Journey", "journey"], ["档案", "Archive", "archive"], ["手册", "Handbook", "handbook"], ["设置", "Settings", "settings"], ["退出", "Quit", "quit"]]
	for entry: Array in labels:
		var button := _button(secondary, "", str(entry[2]), false)
		button.name = "Terminal" + str(entry[2]).capitalize()
		button.set_meta("zh", entry[0]); button.set_meta("en", entry[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size.y = 32
		button.add_theme_font_size_override("font_size", 14)
		if str(entry[2]) == "archive": archive_button = button
	_compose()

func _compose() -> void:
	var zh: bool = not english
	sleep_hint.text = "壹 · 学习程序 · 待机\n点击屏幕，或按 Enter" if zh else "Yi · learning program · standby\nClick the screen or press Enter"
	header_label.text = "壹 · 学习程序" if zh else "Yi · learning program"
	language_button.text = "EN" if zh else "中文"
	progress_label.text = ("%d / %d" % [int(state.get("completed", 0)), int(state.get("total", 0))]) if int(state.get("total", 0)) > 0 else ""
	for button: Node in secondary.get_children():
		(button as Button).text = str(button.get_meta("en" if english else "zh"))
	set_fragment_count(int(state.get("fragments", 0)), 0)
	var navigation: Node = get_node_or_null("/root/TaskNavigation")
	var next_title: String = str(navigation.next_task_title()) if navigation != null else ""
	if bool(state.get("new_player", true)):
		message.text = "你好，我是壹。\n这台终端里有一套学习程序，留给愿意亲手弄明白计算的人。\n我们从一盏灯开始。" if zh else "Hello. I am Yi.\nThis terminal holds a learning program, left for anyone who wants to understand computing with their own hands.\nWe begin with one lamp."
		primary.text = "开始 · 接通第一条线路" if zh else "Begin · connect the first line"
		return
	var target_title: String = str(state.get("next_title", ""))
	if not target_title.is_empty() and str(state.get("next_key", "")) != str(navigation.next_task_key() if navigation != null else ""):
		primary.text = ("继续 · " if zh else "Continue · ") + _shorten(target_title, 18)
		next_title = target_title
	else:
		primary.text = (str(navigation.home_action_text()) if navigation != null else ("继续" if zh else "Continue"))
		if not next_title.is_empty(): primary.text += " · " + _shorten(next_title, 18)
	if not response.is_empty():
		var task: Dictionary = response.get("task", {})
		var title: String = str(task.get("title", ""))
		if bool(response.get("first_light", false)):
			message.text = "灯亮过，也灭过。两次都是对的。\n那条线是你接上的，不是我替你算出来的。\n档案架上多了一页，想看的时候可以去看。" if zh else "The lamp lit, and went dark. Both were correct.\nYou connected that line; I did not compute it for you.\nThere is a new page on the archive shelf when you want it."
			return
		if response.has("chapter"):
			message.text = str(response.chapter.en if english else response.chapter.zh)
			if int(response.get("fragments", 0)) > 0:
				message.text += "\n" + ("档案架上多了一页记录。" if zh else "A new record waits on the archive shelf.")
			return
		var lines_zh: Array[String] = ["「%s」完成了。\n这次结果来自你刚才搭起的结构，不是我的保佑。", "「%s」通过了。\n你可以回去再改它，也可以继续往前走。", "记下了：「%s」。\n下一步，通常比这一步多一个条件。"]
		var lines_en: Array[String] = ["\"%s\" is complete.\nThat result came from the structure you just built, not from my blessing.", "\"%s\" passes.\nYou can go back and refine it, or keep going.", "Recorded: \"%s\".\nThe next step usually adds one more condition."]
		var pick: int = absi(title.hash()) % lines_zh.size()
		message.text = (lines_en[pick] if english else lines_zh[pick]) % _shorten(title, 16)
		if int(response.get("fragments", 0)) > 0:
			message.text += "\n" + ("档案架上多了一页记录。" if zh else "A new record waits on the archive shelf.")
		return
	message.text = ("欢迎回来。\n下一项是「%s」。" if zh else "Welcome back.\nNext up: \"%s\".") % _shorten(next_title, 18)

func wake(instant: bool = false) -> void:
	if not _asleep:
		_focus_primary(); return
	_asleep = false
	sleep_view.hide(); awake_view.show()
	if instant:
		message.visible_ratio = 1.0
		_focus_primary(); return
	awake_view.modulate.a = 0.0
	message.visible_ratio = 0.0
	var tween := create_tween()
	tween.tween_property(awake_view, "modulate:a", 1.0, 0.25)
	tween.tween_property(message, "visible_ratio", 1.0, clampf(message.text.length() * 0.028, 0.4, 2.2))
	_focus_primary()

func release_focus_inside() -> void:
	var owner_control: Control = get_viewport().gui_get_focus_owner()
	if owner_control != null and is_ancestor_of(owner_control): owner_control.release_focus()

func _focus_primary() -> void:
	if primary != null and primary.is_visible_in_tree(): primary.call_deferred("grab_focus")

func _process(delta: float) -> void:
	_time += delta
	if cursor != null and _asleep: cursor.modulate.a = 0.35 + 0.65 * (0.5 + 0.5 * sin(_time * 3.2))

func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press != null and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
		if _asleep: wake(); accept_event()
		elif message.visible_ratio < 1.0: message.visible_ratio = 1.0; accept_event()

func _shorten(text: String, limit: int) -> String:
	var clean: String = text.get_slice(" · ", 0) if text.length() > limit and text.find(" · ") > 0 else text
	return clean if clean.length() <= limit else clean.substr(0, limit - 1) + "…"

func _label(parent: Node, text: String, font_size: int, color: Color) -> Label:
	var node := Label.new(); node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	parent.add_child(node)
	return node

func _button(parent: Node, text: String, id: String, strong: bool) -> Button:
	var node := Button.new(); node.text = text
	node.focus_mode = Control.FOCUS_ALL
	var fill: Color = Palette.ACCENT if strong else Palette.TERM_PANEL
	var edge: Color = Palette.ACCENT if strong else Palette.TERM_EDGE
	for pair: Array in [["normal", fill, edge], ["hover", fill.lightened(0.12) if strong else Palette.TERM_SCREEN_LIFT, Palette.ACCENT], ["pressed", fill.darkened(0.12), Palette.ACCENT], ["focus", Color.TRANSPARENT, Palette.ACCENT]]:
		var box := StyleBoxFlat.new()
		box.bg_color = pair[1]; box.border_color = pair[2]
		box.set_border_width_all(1 if str(pair[0]) != "focus" else 2)
		box.set_corner_radius_all(8 if strong else 6)
		box.content_margin_left = 10; box.content_margin_right = 10
		box.draw_center = str(pair[0]) != "focus"
		node.add_theme_stylebox_override(str(pair[0]), box)
	var ink: Color = Palette.TERM_SCREEN if strong else Palette.TERM_TEXT
	for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		node.add_theme_color_override(color_name, ink)
	node.pressed.connect(func() -> void: action.emit(id))
	parent.add_child(node)
	return node
