extends VBoxContainer
## Presentation only: host owns edits, dirty guards and persistence.
const Designs = preload("res://experiments/candidate_session/designs.gd")
signal remember_requested(design_name: String)
signal restore_requested(index: int)
signal remove_requested(index: int)
var toggle: Button
var content: VBoxContainer
var source: Label
var design_name: LineEdit
var remember_button: Button
var choices: OptionButton
var restore_button: Button
var remove_button: Button
var english: bool = false
var measured_record: Dictionary = {}
var collection: Array[Dictionary] = []

func _ready() -> void:
	name = "DesignShelf"
	toggle = Button.new(); toggle.name = "ToggleDesignShelf"; toggle.toggle_mode = true
	add_child(toggle)
	content = VBoxContainer.new(); content.visible = false; add_child(content)
	toggle.toggled.connect(func(open: bool) -> void: content.visible = open)
	source = Label.new(); source.name = "DesignSource"; source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.add_child(source)
	var naming := HBoxContainer.new(); content.add_child(naming)
	design_name = LineEdit.new(); design_name.name = "DesignName"; design_name.max_length = Designs.NAME_LIMIT
	design_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL; naming.add_child(design_name)
	remember_button = Button.new(); remember_button.name = "RememberDesign"; naming.add_child(remember_button)
	remember_button.pressed.connect(func() -> void: remember_requested.emit(design_name.text))
	design_name.text_submitted.connect(func(value: String) -> void:
		if not remember_button.disabled: remember_requested.emit(value))
	choices = OptionButton.new(); choices.name = "NamedDesigns"; choices.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	choices.fit_to_longest_item = false; choices.clip_text = true
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_child(choices)
	var actions := HBoxContainer.new(); content.add_child(actions)
	restore_button = Button.new(); restore_button.name = "RestoreDesign"; actions.add_child(restore_button)
	remove_button = Button.new(); remove_button.name = "RemoveDesign"; actions.add_child(remove_button)
	restore_button.pressed.connect(func() -> void: restore_requested.emit(choices.selected))
	remove_button.pressed.connect(func() -> void: remove_requested.emit(choices.selected))
	refresh(collection,measured_record,english)

func text2(zh: String, en: String) -> String: return en if english else zh

func refresh(designs: Array[Dictionary], record: Dictionary, use_english: bool) -> void:
	var old_index: int = Designs.index_of(collection,measured_record) if not measured_record.is_empty() else -1
	var new_index: int = Designs.index_of(designs,record) if not record.is_empty() else -1
	var old_name: String = str(collection[old_index].name) if old_index >= 0 else ""
	var new_name: String = str(designs[new_index].name) if new_index >= 0 else ""
	var source_changed: bool = measured_record != record or old_name != new_name
	collection.assign(designs.duplicate(true)); measured_record = record.duplicate(true); english = use_english
	if toggle == null: return
	toggle.text = text2("我的方案 · %d / %d", "My designs · %d / %d") % [designs.size(),Designs.LIMIT]
	var previous: int = choices.selected
	choices.clear()
	for entry: Dictionary in designs: choices.add_item("T%d · %s" % [int(entry.task)+1,entry.name])
	if not designs.is_empty(): choices.select(new_index if source_changed and new_index >= 0 else clampi(previous,0,designs.size()-1))
	restore_button.text = text2("复制到任务草稿", "Copy into task draft")
	remove_button.text = text2("移出收藏", "Remove from collection")
	restore_button.disabled = designs.is_empty(); remove_button.disabled = designs.is_empty()
	remember_button.text = text2("收藏实测方案", "Keep measured plan")
	remember_button.disabled = record.is_empty()
	design_name.placeholder_text = text2("给自己的方案命名", "Name your design")
	if source_changed: design_name.text = new_name
	source.text = text2("选择一条实测记录，再命名收藏。收藏不随历史上限消失；点击保存后可重开。", "Select a measured run, then name and keep it. Collections survive the history limit; Save to keep them after restart.") if record.is_empty() else text2("收藏来源：任务%d的选中实测方案，草稿修改不会混入。复制后须重新运行才产生新成绩。", "Collection source: selected measured plan for task%d; draft edits stay separate. Run the copied draft to produce new results.") % [int(record.task)+1]
