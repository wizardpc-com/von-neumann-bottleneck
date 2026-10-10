extends Window
## Read-only exhibit of a protected saved snapshot; never regenerates or saves.
const Canvas = preload("res://experiments/creation/work_canvas.gd")
const Model = preload("res://experiments/creation/model.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
signal dismissed
var work: Dictionary = {}
var english: bool = false
var canvas: Control
var position_label: Label
var tabs: TabContainer
var close_button: Button
var recipe_label: Label

func words(zh: String, en: String) -> String: return en if english else zh

func configure(snapshot: Dictionary, use_english: bool) -> void:
	work = snapshot.duplicate(true)
	english = use_english

func make_label(value: String, parent: Node, font_size: int = 14) -> Label:
	var result := Label.new()
	result.text = value
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result.add_theme_font_size_override("font_size",font_size)
	parent.add_child(result)
	return result

func _ready() -> void:
	title = words("已保存的光纹作品","Saved signal work")
	min_size = Vector2i(640,420)
	size = Vector2i(1080,620)
	transient = true
	exclusive = true
	close_requested.connect(dismiss)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,16)
	add_child(margin)
	var content := VBoxContainer.new(); margin.add_child(content)
	var header := HBoxContainer.new(); content.add_child(header)
	make_label(str(work.get("name","")),header,24)
	close_button = Button.new(); close_button.name = "CloseWorkFocus"
	close_button.text = words("回到工作台","Back to workbench")
	close_button.pressed.connect(dismiss); header.add_child(close_button)
	make_label(words("这是已保存的实际输出快照。完整光纹可向下滚动；查看不会重新生成、改配方或写存档。", "This is the saved output snapshot. Scroll to view every cell; viewing never regenerates, edits a recipe, or writes a save."),content,13)
	tabs = TabContainer.new(); tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; tabs.use_hidden_tabs_for_min_size = false
	content.add_child(tabs)
	var art := VBoxContainer.new(); art.name = words("完整光纹","Full signal"); tabs.add_child(art)
	position_label = make_label(words("共 %d 格 · A ● / B ■ / C ▲ / D ◇ · 点格子查看位置", "%d cells · A ● / B ■ / C ▲ / D ◇ · select a cell for its position")%work.get("output",[]).size(),art,13)
	var scroll := ScrollContainer.new(); scroll.name = "WorkSnapshotScroll"; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.focus_mode = Control.FOCUS_ALL; art.add_child(scroll)
	canvas = Canvas.new(); canvas.name = "WorkSnapshotCanvas"; canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(canvas); canvas.set_output(work.get("output",[])); canvas.cell_selected.connect(select_cell)
	var source_scroll := ScrollContainer.new(); source_scroll.name = words("配方与来源","Recipe / source"); source_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; source_scroll.focus_mode = Control.FOCUS_ALL; tabs.add_child(source_scroll)
	recipe_label = make_label(recipe_text(),source_scroll,13); recipe_label.name = "WorkSnapshotRecipe"
	close_button.grab_focus()

func recipe_text() -> String:
	var recipe: Dictionary = work.get("recipe",{})
	var model: Dictionary = recipe.get("model",{}) if recipe.get("model",{}) is Dictionary else {}
	var lines := PackedStringArray()
	lines.append(words("保存的作品 ID：", "Saved work ID: ")+str(work.get("id","")))
	lines.append(words("模型 ID：", "Model ID: ")+str(recipe.get("model_id","")))
	if recipe.get("version",0) != 1 or model.get("version",0) != Model.VERSION or recipe.get("sampler_version", "") != "integer-counts-v1" or recipe.get("prng_version", "") != Model.PRNG_VERSION:
		lines.append(words("此配方版本暂不能解释；此页只展示已保存输出，不重新生成或猜测规则。", "This recipe version cannot be interpreted here. Only saved output is shown; no regeneration or guessed rules."))
		return "\n".join(lines)
	lines.append(words("来源作品：", "Parent work: ")+(str(work.get("parent","")) if not str(work.get("parent","")).is_empty() else words("无分叉父作品", "no parent work")))
	lines.append(words("记忆：", "History: ")+str(model.get("order","?"))+" · "+words("种子：", "Seed: ")+str(recipe.get("seed","?"))+" · "+words("采样：", "Sampling: ")+str(recipe.get("sampler","?")))
	lines.append(words("起始片段：", "Initial passage: ")+(Catalog.symbols(recipe.get("initial",[])) if recipe.get("initial",[]) is Array else "?"))
	lines.append(words("机器：", "Machine: ")+JSON.stringify(recipe.get("machine",{})))
	lines.append(words("保存的训练样例：", "Saved training examples:"))
	if model.get("examples",[]) is Array:
		for example: Variant in model.get("examples",[]):
			if example is Array: lines.append(Catalog.symbols(example))
	lines.append(words("保存的规则（上下文 → A/B/C/D 计数）：", "Saved rules (context → A/B/C/D counts):"))
	if model.get("rows",[]) is Array:
		for row: Variant in model.get("rows",[]):
			if row is Dictionary and row.get("context",[]) is Array: lines.append((Catalog.symbols(row.get("context",[])) if not row.get("context",[]).is_empty() else "∅")+" → "+str(row.get("counts",[])))
	lines.append(words("映射：", "Mapping: ")+str(work.get("mapping","")))
	return "\n".join(lines)

func select_cell(index: int) -> void:
	var output: Array = work.get("output",[])
	if index<0 or index>=output.size(): return
	canvas.selected = index; canvas.queue_redraw()
	position_label.text = words("第 %d / %d 格：", "Cell %d / %d: ")%[index+1,output.size()]+Catalog.symbols([output[index]])

func dismiss() -> void:
	hide()
	dismissed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
