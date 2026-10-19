extends PanelContainer
## First-lesson coach: one concrete instruction at a time, anchored on the
## canvas. It mirrors the tutorial's real interaction flags; it never marks a
## step itself. The full briefing stays one click away ("完整说明").

signal briefing_requested

const Palette = preload("res://src/lab/lab_palette.gd")
const STEPS := [
	{"id": "wire", "zh_title": "接线", "en_title": "Wire",
		"zh": "从输入 A 右侧的圆点按住拖到 NOT 左侧的圆点，再从 NOT 右侧拖到灯。",
		"en": "Drag from the dot on the right of input A to the left dot of NOT, then from NOT's right dot to the lamp."},
	{"id": "input", "zh_title": "改变输入", "en_title": "Change the input",
		"zh": "在左下角的测试台里点一下 A，让它在 0 和 1 之间切换。",
		"en": "In the test bench (bottom left), click A to switch it between 0 and 1."},
	{"id": "run", "zh_title": "运行", "en_title": "Run",
		"zh": "按「运行练习电路」，看信号沿线走到灯。NOT 会把输入反过来：A 是 0，灯亮；A 是 1，灯灭。",
		"en": "Press Run and watch the signal travel to the lamp. NOT flips its input: A = 0 lights the lamp, A = 1 turns it off."},
	{"id": "remove", "zh_title": "拆一条线", "en_title": "Remove a wire",
		"zh": "按住右键划过任意一条线，把它拆掉。拆错了也没关系。",
		"en": "Hold the right mouse button and sweep across a wire to remove it. Mistakes are fine."},
	{"id": "reconnect", "zh_title": "接回去", "en_title": "Reconnect",
		"zh": "把刚才拆掉的线重新接上。会改、会重来，就是会搭建。",
		"en": "Connect the removed wire again. Being able to undo and redo is what building means."},
]

const BUILD_STEPS := [
	{"id": "wire", "zh_title": "搭电路", "en_title": "Build",
		"zh": "从右侧「元件」拖出门电路，接到每一个输出上。不确定时可以先只接一个输出试试。",
		"en": "Drag gates from Components on the right and wire every output. Unsure? Wire just one output first."},
	{"id": "debug", "zh_title": "试一试", "en_title": "Try it",
		"zh": "在左侧测试台换几组输入，按「运行当前调试用例」，看输出是否符合你的预期。",
		"en": "Change inputs in the test bench on the left and run the debug case. Does the output match what you expect?"},
	{"id": "official", "zh_title": "正式测试", "en_title": "Official test",
		"zh": "按「逐项运行正式用例」。全部通过后，这个电路就能封装成下一关可用的零件。",
		"en": "Run the official cases. When all pass, this circuit becomes a part you can reuse later."},
]
const BUILD_PRAISE_ZH := ["每个输出都有来源了。", "跑起来了，看看结果对不对。", "全部通过。"]
const BUILD_PRAISE_EN := ["Every output has a source now.", "It runs. Check whether the result is right.", "All cases pass."]
const TUTORIAL_PRAISE_ZH := ["接上了。", "输入变了，结果也会跟着变。", "信号到了。", "拆掉了。", "又接好了。"]
const TUTORIAL_PRAISE_EN := ["Connected.", "The input changed; the result will follow.", "The signal arrived.", "Removed.", "Connected again."]

var steps: Array = STEPS
var praise_zh: Array = TUTORIAL_PRAISE_ZH
var praise_en: Array = TUTORIAL_PRAISE_EN
var goal_text: String = ""
var english: bool = false
var step_label: Label
var instruction: Label
var dots: Array[ColorRect] = []
var praise: Label
var last_states: Array[bool] = []

func _ready() -> void:
	name = "TutorialCoach"
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 120
	var box := StyleBoxFlat.new()
	box.bg_color = Palette.with_alpha(Palette.TERM_PANEL, 0.97)
	box.border_color = Palette.ACCENT_DEEP; box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	box.shadow_color = Color(0, 0, 0, 0.35); box.shadow_size = 12; box.shadow_offset = Vector2(0, 4)
	box.content_margin_left = 20; box.content_margin_right = 20; box.content_margin_top = 14; box.content_margin_bottom = 14
	add_theme_stylebox_override("panel", box)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation", 8); add_child(column)
	var header := HBoxContainer.new(); header.add_theme_constant_override("separation", 10); column.add_child(header)
	var mark := Label.new(); mark.text = "壹" if not english else "Yi"
	mark.add_theme_color_override("font_color", Palette.ACCENT); mark.add_theme_font_size_override("font_size", 14)
	header.add_child(mark)
	step_label = Label.new(); step_label.name = "CoachStep"
	step_label.add_theme_color_override("font_color", Palette.TERM_TEXT); step_label.add_theme_font_size_override("font_size", 16)
	step_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(step_label)
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation", 6); header.add_child(row)
	for index: int in 5:
		var dot := ColorRect.new(); dot.custom_minimum_size = Vector2(22, 6)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = Palette.TERM_EDGE; row.add_child(dot); dots.append(dot)
	var more := Button.new(); more.name = "CoachBriefing"; more.flat = true
	more.text = "完整说明" if not english else "Full briefing"
	more.add_theme_font_size_override("font_size", 13)
	more.add_theme_color_override("font_color", Palette.TERM_MUTED)
	more.pressed.connect(func() -> void: briefing_requested.emit())
	header.add_child(more)
	instruction = Label.new(); instruction.name = "CoachInstruction"
	instruction.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	instruction.add_theme_color_override("font_color", Palette.TERM_TEXT)
	instruction.add_theme_font_size_override("font_size", 18)
	instruction.add_theme_constant_override("line_spacing", 4)
	column.add_child(instruction)
	praise = Label.new(); praise.name = "CoachPraise"
	praise.add_theme_color_override("font_color", Palette.GOOD); praise.add_theme_font_size_override("font_size", 15)
	praise.modulate.a = 0.0
	column.add_child(praise)

func set_english(value: bool) -> void:
	english = value

## Switch between the first lesson and the generic build → try → test guide.
func use_steps(build_guide: bool, goal: String = "") -> void:
	steps = BUILD_STEPS if build_guide else STEPS
	praise_zh = BUILD_PRAISE_ZH if build_guide else TUTORIAL_PRAISE_ZH
	praise_en = BUILD_PRAISE_EN if build_guide else TUTORIAL_PRAISE_EN
	goal_text = goal
	last_states.clear()
	for index: int in dots.size(): dots[index].visible = index < steps.size()

func update_states(states: Array[bool]) -> void:
	var newly: int = -1
	for index: int in states.size():
		if states[index] and (last_states.size() <= index or not last_states[index]) and not last_states.is_empty():
			newly = index
	last_states = states.duplicate()
	var next: int = states.find(false)
	var completed: int = states.count(true)
	for index: int in dots.size():
		if index >= states.size(): continue
		dots[index].color = Palette.ACCENT if states[index] else (Palette.with_alpha(Palette.ACCENT, 0.35) if index == next else Palette.TERM_EDGE)
	if next < 0:
		if steps == STEPS:
			step_label.text = "五步都完成了" if not english else "All five steps done"
			instruction.text = "灯亮过，也灭过——两次都是对的。" if not english else "The lamp lit and went dark. Both were correct."
		else:
			step_label.text = "完成了" if not english else "Done"
			instruction.text = "可以封装它，继续下一项。" if not english else "Seal it and move on."
	else:
		var step: Dictionary = steps[next]
		step_label.text = ("第 %d / %d 步 · %s" if not english else "Step %d / %d · %s") % [completed + 1, steps.size(), str(step.en_title if english else step.zh_title)]
		instruction.text = str(step.en if english else step.zh)
		if not goal_text.is_empty(): instruction.text = goal_text + "\n" + instruction.text
	# Shrink to the new text; width is held by custom_minimum_size.
	call_deferred("reset_size")
	if newly >= 0:
		praise.text = "✓  " + str(praise_en[newly] if english else praise_zh[newly])
		var tween := create_tween()
		praise.modulate.a = 1.0
		tween.tween_interval(2.2)
		tween.tween_property(praise, "modulate:a", 0.0, 0.6)
		var flash := create_tween()
		flash.tween_property(self, "modulate", Color(1.15, 1.25, 1.2), 0.12)
		flash.tween_property(self, "modulate", Color.WHITE, 0.4)
