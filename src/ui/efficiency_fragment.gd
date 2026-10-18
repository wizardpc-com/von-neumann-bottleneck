extends VBoxContainer
## Optional fiction beside the original comparison chart; all numbers are detached receipts.
signal comparison_requested

class ArchiveImage extends Control:
	var step: int = 0
	var emphasis: float = 1.0
	var media: Texture2D

	func _draw() -> void:
		if media != null and media.get_width() > 0 and media.get_height() > 0:
			var image_size := Vector2(media.get_width(), media.get_height())
			var fitted: Vector2 = image_size * minf(size.x / image_size.x, size.y / image_size.y)
			draw_texture_rect(media, Rect2((size - fitted) / 2.0, fitted), false)
			return
		# An archive metaphor, without bars, clocks or an invented event sequence.
		var center := Vector2(size.x / 2.0, size.y / 2.0)
		var left := center + Vector2(-76, 0)
		var right := center + Vector2(76, 0)
		var blue := Color("7fcbd6")
		var amber := Color("f0c674")
		draw_line(left, right, Color("435267"), 2.0)
		draw_rect(Rect2(center - Vector2(20, 30), Vector2(40, 60)), Color("18283c"))
		draw_rect(Rect2(center - Vector2(20, 30), Vector2(40, 60)), Color("a5b9d0"), false, 2.0)
		for index: int in 3:
			draw_line(center + Vector2(-10, -12 + index * 12), center + Vector2(10, -12 + index * 12), Color("a5b9d0"), 2.0)
		draw_circle(left, 13.0, blue.darkened(0.55 if step == 1 else 0.2 * (1.0 - emphasis)))
		draw_circle(right, 13.0, amber.darkened(0.55 if step == 0 else 0.2 * (1.0 - emphasis)))
		draw_arc(left, 21.0, 0, TAU, 32, blue.darkened(0.6), 1.0)
		draw_arc(right, 21.0, 0, TAU, 32, amber.darkened(0.6), 1.0)

var before: Dictionary = {}
var after: Dictionary = {}
var english: bool = false
var current_draft_differs: bool = false
var reduced_motion: bool = false
var media: Texture2D:
	set(value):
		media = value
		if is_instance_valid(image):
			image.media = value
			image.queue_redraw()
var toggle_button: Button
var body: VBoxContainer
var scope_label: Label
var source_label: Label
var metric_label: Label
var response_label: Label
var image: ArchiveImage
var step_buttons: Array[Button] = []
var chart_button: Button
var step: int = 0
var visual_blend: float = 1.0

func _ready() -> void:
	name = "EfficiencyFragment"
	add_theme_constant_override("separation", 8)
	toggle_button = Button.new()
	toggle_button.name = "ShowEfficiencyFragment"
	toggle_button.toggle_mode = true
	toggle_button.custom_minimum_size.y = 40
	toggle_button.toggled.connect(func(expanded: bool) -> void:
		if expanded and _feedback_active():
			toggle_button.set_pressed_no_signal(false)
			return
		body.visible = expanded)
	toggle_button.toggled.connect(func(expanded: bool) -> void:
		if expanded and body.visible and not get_tree().process_frame.is_connected(_reveal_body):
			get_tree().process_frame.connect(_reveal_body, CONNECT_ONE_SHOT))
	add_child(toggle_button)
	body = VBoxContainer.new()
	body.name = "EfficiencyFragmentBody"
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	scope_label = _label(body, 14)
	source_label = _label(body, 14)
	var choices := HFlowContainer.new()
	body.add_child(choices)
	for index: int in 3:
		var action := Button.new()
		action.name = "EfficiencyStep%d" % index
		action.toggle_mode = true
		action.custom_minimum_size.y = 40
		action.pressed.connect(_select_step.bind(index))
		choices.add_child(action)
		step_buttons.append(action)
	metric_label = _label(body, 16)
	image = ArchiveImage.new()
	image.custom_minimum_size.y = 72
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.media = media
	body.add_child(image)
	response_label = _label(body, 16)
	chart_button = Button.new()
	chart_button.name = "ReturnToMeasuredChart"
	chart_button.custom_minimum_size.y = 40
	chart_button.pressed.connect(func() -> void:
		if _feedback_active(): return
		collapse()
		comparison_requested.emit())
	body.add_child(chart_button)
	collapse()
	hide()

func _label(parent: Node, font_size: int) -> Label:
	var result := Label.new()
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.add_theme_font_size_override("font_size", font_size)
	parent.add_child(result)
	return result

func _reveal_body() -> void:
	if not owns_window_focus(): return
	if not body.is_visible_in_tree() or _feedback_active() or get_viewport().gui_get_focus_owner() != toggle_button: return
	var ancestor: Node = get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			# Reveal identity, step choices and the measured value; deeper material can scroll.
			ancestor.ensure_control_visible(metric_label)
			return
		ancestor = ancestor.get_parent()

func _words(zh: String, en: String) -> String:
	return en if english else zh

func set_pair(first: Dictionary, second: Dictionary, use_english: bool) -> void:
	if not _valid_pair(first, second):
		clear_pair()
		return
	var changed: bool = before != first or after != second or english != use_english
	before = first.duplicate(true)
	after = second.duplicate(true)
	english = use_english
	if changed:
		step = 0
		visual_blend = 1.0
		collapse()
	_refresh()
	show()

func clear_pair() -> void:
	before.clear()
	after.clear()
	current_draft_differs = false
	step = 0
	visual_blend = 1.0
	collapse()
	hide()

func collapse() -> void:
	if not is_instance_valid(body): return
	var focused: Control = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	var return_focus: bool = body.is_ancestor_of(focused) if focused != null else false
	body.hide()
	toggle_button.set_pressed_no_signal(false)
	if return_focus and is_visible_in_tree() and not _feedback_active(): toggle_button.grab_focus()

func _valid_pair(first: Dictionary, second: Dictionary) -> bool:
	for record: Dictionary in [first, second]:
		if record.get("level_id", "") != "cpu_speed" or not record.get("all_passed", false): return false
		if not record.get("metrics") is Dictionary or not record.get("part_ids") is Dictionary: return false
		for kind: String in ["cpu", "ram", "bus"]:
			if str(record.part_ids.get(kind, "")).is_empty(): return false
		if int(record.get("total_cases", 0)) <= 0 or record.get("passed_cases") != record.get("total_cases"): return false
		for key: String in ["total_cycles", "cpu_compute_cycles", "cpu_wait_cycles", "hardware_cost"]:
			if not record.metrics.get(key) is int or record.metrics[key] < 0: return false
		if record.metrics.total_cycles <= 0 or record.metrics.cpu_compute_cycles + record.metrics.cpu_wait_cycles != record.metrics.total_cycles: return false
		if str(record.get("program_signature", "")).is_empty() or str(record.get("test_set_signature", "")).is_empty(): return false
	if first.program_signature != second.program_signature or first.test_set_signature != second.test_set_signature or first.total_cases != second.total_cases: return false
	if first.get("source", "") not in ["game", "test"] or first.get("source") != second.get("source"): return false
	if first.part_ids.get("cpu", "") == second.part_ids.get("cpu", ""): return false
	for kind: String in ["ram", "bus"]:
		if first.part_ids.get(kind, "") != second.part_ids.get(kind, ""): return false
	return true

func _feedback_active() -> bool:
	if not is_inside_tree(): return false
	var playtest: Node = get_node_or_null("/root/PlaytestData")
	var feedback: Node = get_node_or_null("/root/OfflineFeedback")
	return (playtest != null and bool(playtest.get("_feedback_visible"))) or (feedback != null and bool(feedback.get("busy")))

func _select_step(index: int) -> void:
	if before.is_empty() or _feedback_active(): return
	step = clampi(index, 0, 2)
	visual_blend = 1.0 if reduced_motion else 0.0
	_refresh()

func owns_window_focus() -> bool:
	if not is_inside_tree() or is_queued_for_deletion(): return false
	var window: Window = get_window()
	if not window.has_focus(): return false
	# A focused embedded modal can leave its native parent reporting focus too.
	for child: Window in window.get_embedded_subwindows():
		if child.visible and child.has_focus(): return false
	return true

func _process(delta: float) -> void:
	if not is_instance_valid(body) or not body.is_visible_in_tree() or _feedback_active() or not owns_window_focus(): return
	if reduced_motion: visual_blend = 1.0
	else: visual_blend = minf(1.0, visual_blend + delta * 4.0)
	image.emphasis = visual_blend
	image.queue_redraw()

func _refresh() -> void:
	if not is_instance_valid(body) or before.is_empty(): return
	toggle_button.text = _words("时间留在哪里 · 候选片段", "Where time remains · candidate fragment")
	chart_button.text = _words("回看原比较图", "Return to measured chart")
	scope_label.text = _words("候选虚构意象 · 原聚合记录，非事件回放", "Candidate fiction · original aggregate records, not an event replay")
	scope_label.tooltip_text = _words("学习程序内的虚构档案意象，不代表文明历史或现实节能。", "A fictional archive image inside the learning program, not civilization history or real-world energy savings.")
	var source: String = _words("测试记录 · 不代表普通旅程成果", "Test records · not ordinary journey progress") if before.get("source", "") == "test" else _words("原运行记录 · 查看不会产生新进度", "Original run records · viewing grants no progress")
	source_label.text = source + "\n" + _words("同程序、同测试集 · 各 %d 个测试 · CPU %s → %s", "Same program and test set · %d cases each · CPU %s → %s") % [before.total_cases, before.get("part_name", "?"), after.get("part_name", "?")]
	if current_draft_differs:
		source_label.text += "\n" + _words("当前草稿不同；这里仍是原方案记录。", "Current draft differs; the original records stay unchanged.")
	source_label.tooltip_text = _words("记录 A / B（始终对应当时方案）", "Records A / B (their original configurations)") + "\n" + JSON.stringify([before, after], "  ")
	var captions: Array[String] = [_words("1 · 观察计算", "1 · Computation"), _words("2 · 观察等待", "2 · Waiting"), _words("3 · 一起比较", "3 · Compare together")]
	for index: int in step_buttons.size():
		step_buttons[index].text = captions[index]
		step_buttons[index].set_pressed_no_signal(index == step)
	var metric: String = ["cpu_compute_cycles", "cpu_wait_cycles", "total_cycles"][step]
	var title: String = [_words("计算", "Compute"), _words("等待", "Wait"), _words("总周期", "Total cycles")][step]
	var initial: int = before.metrics[metric]
	var measured: int = after.metrics[metric]
	var difference: int = measured - initial
	metric_label.text = "%s: %d → %d · Δ %s%d" % [title, initial, measured, "+" if difference >= 0 else "", difference]
	if step == 2:
		metric_label.text += "\n" + _words("机器成本：%d → %d（不是跨测试相加）", "Machine cost: %d → %d (not summed across tests)") % [before.metrics.hardware_cost, after.metrics.hardware_cost]
	var observation: String
	if difference < 0: observation = _words("这两条记录里，这一项少了 %d 周期。", "In these two records, this component used %d fewer cycles.") % -difference
	elif difference > 0: observation = _words("这两条记录里，这一项多了 %d 周期；它没有被画成改进。", "In these two records, this component used %d more cycles; it is not presented as an improvement.") % difference
	else: observation = _words("这两条记录里，这一项没有变化。", "In these two records, this component did not change.")
	var reply: String = [
		_words("壹留下的候选讯息：先看计算，再看等待。让一部分更快，并不能替另一部分作答。", "Candidate message left by Yi: inspect computation, then waiting. Speeding one part does not answer for the other."),
		_words("壹留下的候选讯息：留在档案里的等待也值得被看见。接下来可以带着这份观察，探索数据的复用。", "Candidate message left by Yi: the waiting retained in a record deserves attention too. Carry this observation into data reuse."),
		_words("壹留下的候选讯息：你可以选择新的安排，也可以保留不变的观察。档案留下条件与代价，不替后来者作决定。", "Candidate message left by Yi: choose another arrangement, or keep an unchanged observation. The archive retains conditions and costs, leaving later choices open.")
	][step]
	response_label.text = observation + "\n" + reply
	image.step = step
	image.emphasis = visual_blend
	image.queue_redraw()
