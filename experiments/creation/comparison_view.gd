extends VBoxContainer
## Read-only view of two frozen runs. Rule lookup never edits either recipe.
const Model = preload("res://experiments/creation/model.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const COLORS := [Color("6ce2de"),Color("eead67"),Color("bcacf0"),Color("8cd793")]
signal side_selected(lane: int, index: int)

var english: bool = false
var first: Dictionary = {}
var second: Dictionary = {}
var report: Dictionary = {}
var context: Array = []
var show_first_difference: bool = true
var context_input: LineEdit
var summary: Label
var side_columns: HBoxContainer
var side_buttons: Array[Button] = []

func words(zh: String, en: String) -> String: return en if english else zh

func _ready() -> void:
	var controls := HBoxContainer.new()
	add_child(controls)
	var difference := Button.new()
	difference.name = "ABFirstDifference"
	difference.text = words("首次分歧", "First difference")
	difference.pressed.connect(func() -> void: show_first_difference = true; refresh_view())
	controls.add_child(difference)
	context_input = LineEdit.new()
	context_input.name = "ABContext"
	context_input.custom_minimum_size.x = 100
	context_input.placeholder_text = words("上下文 A B…（可空）", "Context A B… (empty allowed)")
	context_input.text_submitted.connect(func(_value: String) -> void: inspect_context_input())
	controls.add_child(context_input)
	var inspect := Button.new()
	inspect.name = "ABInspectContext"
	inspect.text = words("查看规则", "Inspect rules")
	inspect.pressed.connect(inspect_context_input)
	controls.add_child(inspect)
	summary = Label.new()
	summary.name = "ABSummary"
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.name = "ABScroll"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(scroll)
	side_columns = HBoxContainer.new()
	side_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(side_columns)
	for side: int in 2:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		side_columns.add_child(column)
		var action := Button.new()
		action.name = "ABSelectA" if side == 0 else "ABSelectB"
		var lane: int = 0 if side == 0 else 2
		action.pressed.connect(_select_side.bind(lane))
		column.add_child(action)
		side_buttons.append(action)
	refresh_view()

func _select_side(lane: int) -> void:
	side_selected.emit(lane,int(report.get("first_difference",-1)))

func configure(a: Dictionary, b: Dictionary, comparison: Dictionary, use_english: bool) -> void:
	if first != a or second != b:
		show_first_difference = true
		context.clear()
	first = a.duplicate(true)
	second = b.duplicate(true)
	report = comparison.duplicate(true)
	english = use_english
	if is_node_ready():
		context_input.placeholder_text = words("上下文 A B…（可空）", "Context A B… (empty allowed)")
		(find_child("ABFirstDifference",true,false) as Button).text = words("首次分歧", "First difference")
		(find_child("ABInspectContext",true,false) as Button).text = words("查看规则", "Inspect rules")
		refresh_view()

func inspect_context_input() -> void:
	var parsed: Dictionary = Catalog.parse_symbols(context_input.text)
	if not parsed.get("ok",false) or parsed.get("symbols",[]).size() > 2:
		summary.text = words("请输入最多两个 A/B/C/D 符号。", "Enter at most two A/B/C/D symbols.")
		return
	select_context(parsed.symbols)

func select_context(value: Array) -> void:
	context = value.duplicate()
	show_first_difference = false
	if is_node_ready():
		context_input.text = Catalog.symbols(context)
		refresh_view()

func refresh_view() -> void:
	if not is_node_ready(): return
	for column: Node in side_columns.get_children():
		for child: Node in column.get_children():
			if child != side_buttons[0] and child != side_buttons[1]:
				column.remove_child(child)
				child.queue_free()
	if first.is_empty() or second.is_empty() or not report.get("ok",false):
		summary.text = words("生成并钉住 A，再生成 B，才能查看两侧证据。", "Generate and pin A, then generate B to inspect both sides.")
		for action: Button in side_buttons:
			action.disabled = true
			action.text = "A" if action == side_buttons[0] else "B"
		return
	var index: int = int(report.get("first_difference",-1))
	var has_difference: bool = index >= 0 and index < first.get("output",[]).size() and index < second.get("output",[]).size()
	if show_first_difference:
		summary.text = words("两份输出相同；可输入上下文查看两份冻结规则。", "Outputs match; enter a context to inspect both frozen rules.") if index < 0 else words("第 %d 格首次不同；之前的输出相同。", "First difference at cell %d; earlier output matches.") % [index+1]
		if index >= 0 and not has_difference: summary.text = words("首次差异在长度边界；没有双方同格输出。", "First difference is a length boundary; there is no two-sided cell.")
		if not report.get("single",false) or not report.get("effective_design",false):
			summary.text += " " + words("条件并非单一有效设计改动，不将差异归因于一项。", "Conditions are not one effective design change; no single-cause claim.")
		elif has_difference and not _event_at(first,index).is_empty() and not _event_at(second,index).is_empty():
			summary.text += " " + words("只改一项；下方取自双方实际生成事件。", "One controlled change; both sides below use recorded generation events.")
	else:
		summary.text = words("在两份冻结模型中查询上下文 [%s]；这不是重新生成。", "Looking up context [%s] in both frozen models; this does not regenerate.") % [Catalog.symbols(context)]
	summary.text += " " + _change_summary()
	for side: int in 2:
		var run: Dictionary = first if side == 0 else second
		var action: Button = side_buttons[side]
		action.disabled = not show_first_difference or not has_difference
		action.text = ("A" if side == 0 else "B") + " · " + str(run.get("recipe",{}).get("model_id","")).substr(0,8) + (" · " + Catalog.symbols([int(run.output[index])]) + words(" · 定位", " · Locate") if has_difference and show_first_difference else "")
		var column := side_columns.get_child(side) as VBoxContainer
		var evidence: Dictionary = {}
		if show_first_difference and has_difference: evidence = _event_at(run,index)
		elif not show_first_difference: evidence = _rule_at(run,context)
		if evidence.is_empty():
			_add_label(column,words("无双方可核对的逐格事件；可查看冻结规则。", "No verifiable event at this cell; inspect frozen rules.") if show_first_difference else words("此配方没有可读取的冻结规则。", "No readable frozen rule in this recipe."))
			continue
		var row_context: Array = evidence.get("context",[])
		var uniform: bool = not show_first_difference and bool(evidence.get("uniform_default",false))
		_add_label(column,(words("默认均匀回退", "Uniform default") if uniform else words("实际采用 [%s]", "Used [%s]") % [Catalog.symbols(row_context)]) + (words(" · 回退", " · fallback") if evidence.get("fallback",0) > 0 else ""))
		if show_first_difference:
			_add_label(column,words("实际输出 ", "Actual output ") + Catalog.symbols([int(evidence.symbol)]))
		else:
			_add_label(column,words("冻结规则计数（不是新的输出）", "Frozen rule counts (not new output)"))
		_add_bars(column,evidence.counts)
	if show_first_difference and has_difference and (_event_at(first,index).is_empty() or _event_at(second,index).is_empty()):
		summary.text += " " + words("至少一侧没有已记录生成事件；不展示推测的逐格原因。", "At least one side lacks a recorded event; no inferred cell cause is shown.")
	if show_first_difference and has_difference and index > 0:
		summary.text += " " + words("之后的差异继承变化后的回灌，不是逐格独立实验。", "Later differences inherit changed feedback; they are not independent tests.")

func _change_summary() -> String:
	var changes: Array = report.get("changes",[])
	if changes.is_empty(): return words("配方条件相同。", "Recipe conditions match.")
	var names: Dictionary = {"examples":words("样例", "examples"),"order":words("记忆", "history"),"sampler":words("采样", "sampling"),"seed":words("种子", "seed"),"initial":words("起始", "initial"),"length":words("长度", "length")}
	if int(report.get("factor_count",0)) != 1:
		var factors := PackedStringArray()
		for change: Dictionary in changes: factors.append(str(names.get(change.key,change.key)))
		return words("变化条件：", "Changed factors: ") + (", " if english else "、").join(factors)
	var change: Dictionary = changes[0]
	var title: String = str(names.get(change.key,change.key))
	if change.key == "examples" and not change.get("passages",[]).is_empty():
		var passage: Dictionary = change.passages[0]
		return title + " " + _passage_preview(passage.before) + " → " + _passage_preview(passage.after)
	return title + " " + str(change.before) + " → " + str(change.after)

func _passage_preview(value: Array) -> String:
	if value.is_empty(): return "∅"
	return Catalog.symbols(value.slice(0,8)) + (" …" if value.size() > 8 else "")

func _event_at(run: Dictionary, index: int) -> Dictionary:
	for event: Dictionary in run.get("events",[]):
		if event.get("kind","") == "feedback_write" and int(event.get("index",-1)) == index and event.get("counts",[]).size() == 4 and event.get("symbol",-1) == run.output[index]:
			return {"context":event.get("before_context",[]).duplicate(),"counts":event.counts.duplicate(),"symbol":event.symbol,"fallback":0}
	return {}

func _rule_at(run: Dictionary, value: Array) -> Dictionary:
	var model: Dictionary = run.get("recipe",{}).get("model",{})
	if model.is_empty(): return {}
	var decision: Dictionary = Model.predict(model,value)
	if decision.get("ok",false):
		decision["uniform_default"] = true
		for row: Dictionary in model.get("rows",[]):
			if row.context == decision.context:
				decision["uniform_default"] = false
				break
	return decision if decision.get("ok",false) else {}

func _add_label(parent: Node, value: String) -> void:
	var item := Label.new()
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.text = value
	parent.add_child(item)

func _add_bars(parent: Node, counts: Array) -> void:
	var total: int = 0
	for count: int in counts: total += count
	for symbol: int in 4:
		var row := HBoxContainer.new()
		parent.add_child(row)
		var name_label := Label.new()
		name_label.text = ["A ●","B ■","C ▲","D ◇"][symbol] + " " + str(counts[symbol])
		name_label.custom_minimum_size.x = 62
		name_label.add_theme_color_override("font_color",COLORS[symbol])
		row.add_child(name_label)
		var bar := ProgressBar.new()
		bar.name = "ABCount" + str(symbol)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.custom_minimum_size.y = 8
		bar.max_value = maxi(1,total)
		bar.value = counts[symbol]
		bar.show_percentage = false
		var fill := StyleBoxFlat.new()
		fill.bg_color = COLORS[symbol]
		bar.add_theme_stylebox_override("fill",fill)
		row.add_child(bar)
