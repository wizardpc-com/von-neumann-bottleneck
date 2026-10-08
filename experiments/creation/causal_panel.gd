extends VBoxContainer
## Read-only evidence presentation. The host supplies only already-visible records.
const Explanation = preload("res://experiments/creation/explanation.gd")
const COLORS := [Color("6ce2de"),Color("eead67"),Color("bcacf0"),Color("8cd793")]
var english: bool = false
var body: VBoxContainer
var summary_label: Label
var candidates: HBoxContainer
var audit_toggle: CheckButton
var audit_label: Label
var raw_record: Dictionary = {}

func _ready() -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	summary_label = make_label("",body)
	summary_label.name = "CausalSummary"
	candidates = HBoxContainer.new()
	candidates.name = "CausalCandidates"
	body.add_child(candidates)
	body.move_child(candidates,0)
	audit_toggle = CheckButton.new()
	audit_toggle.name = "ToggleRawAudit"
	audit_toggle.text = words("展开原始审计记录", "Show raw audit record")
	body.add_child(audit_toggle)
	audit_label = make_label("",body)
	audit_label.name = "RawAudit"
	audit_label.visible = false
	audit_toggle.toggled.connect(func(show_raw: bool) -> void: audit_label.visible = show_raw)
	clear_evidence()

func words(zh: String, en: String) -> String: return en if english else zh

func make_label(value: String, parent: Node) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(result)
	return result

func clear_evidence() -> void:
	show_evidence(words("选择光纹中的一格，查看这一步实际用了什么规则。", "Select a signal cell to inspect the rule actually used."),{})

func show_evidence(summary: String, record: Dictionary, counts: Array = []) -> void:
	summary_label.text = summary
	raw_record = record.duplicate(true)
	audit_label.text = JSON.stringify(raw_record,"  ") if not raw_record.is_empty() else ""
	audit_toggle.set_pressed_no_signal(false)
	audit_toggle.disabled = raw_record.is_empty()
	audit_label.visible = false
	for child: Node in candidates.get_children():
		candidates.remove_child(child)
		child.queue_free()
	if counts.size() != 4: return
	var total: int = 0
	for count: int in counts: total += count
	for i: int in 4:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		candidates.add_child(column)
		var caption: Label = make_label(["A ●", "B ■", "C ▲", "D ◇"][i]+" · "+str(counts[i]),column)
		caption.add_theme_color_override("font_color",COLORS[i])
		var bar := ProgressBar.new()
		bar.name = "Candidate"+str(i)
		bar.max_value = maxi(1,total)
		bar.value = counts[i]
		bar.show_percentage = false
		bar.custom_minimum_size.y = 12
		bar.tooltip_text = words("该符号计数/权重：", "Symbol count/weight: ")+str(counts[i])+" / "+str(total)
		var fill := StyleBoxFlat.new()
		fill.bg_color = COLORS[i]
		bar.add_theme_stylebox_override("fill",fill)
		column.add_child(bar)
