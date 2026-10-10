extends Window
## Read-only exhibit of a protected saved snapshot; never regenerates or saves.
const Canvas = preload("res://experiments/creation/work_canvas.gd")
const Model = preload("res://experiments/creation/model.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
signal dismissed
signal request_evidence(index: int)
signal request_fork
const VIEW_MAPPING: String = "light-trace-v1"
var cursor: int = 0
var playing: bool = false
var speed: float = 4.0
var reduced_motion: bool = false
var static_overview: bool = true
var elapsed: float = 0.0
var evidence: Dictionary = {}
var timeline: HSlider
var play_button: Button
var evidence_label: Label
var explanation_button: Button
var fork_button: Button
var overview_button: CheckButton
var motion_button: CheckButton
var controls: HFlowContainer
var mapping_choice: OptionButton
var closing_label: Label
var work: Dictionary = {}
var english: bool = false
var canvas: Control
var position_label: Label
var tabs: TabContainer
var close_button: Button
var recipe_label: Label
var snapshot_scroll: ScrollContainer

func words(zh: String, en: String) -> String: return en if english else zh

func configure(snapshot: Dictionary, use_english: bool, record: Dictionary = {}) -> void:
	work = snapshot.duplicate(true)
	english = use_english
	cursor = work.get("output",[]).size()
	set_evidence(record)

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
	var name_label: Label = make_label(str(work.get("name","")),header,24)
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.clip_text = true
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.tooltip_text = name_label.text
	close_button = Button.new(); close_button.name = "CloseWorkFocus"
	close_button.text = words("回到工作台","Back to workbench")
	close_button.pressed.connect(dismiss); header.add_child(close_button)
	make_label(words("同一份已保存输出 · 播放节奏不是计算耗时 · A ● / B ■ / C ▲ / D ◇", "The saved output · playback tempo is not computation time · A ● / B ■ / C ▲ / D ◇"),content,13)
	build_controls(content)
	tabs = TabContainer.new(); tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL; tabs.use_hidden_tabs_for_min_size = false
	content.add_child(tabs)
	var art := VBoxContainer.new(); art.name = words("欣赏光纹","Appreciation"); tabs.add_child(art)
	position_label = make_label(words("共 %d 格 · A ● / B ■ / C ▲ / D ◇ · 点格子查看位置", "%d cells · A ● / B ■ / C ▲ / D ◇ · select a cell for its position")%work.get("output",[]).size(),art,13)
	snapshot_scroll = ScrollContainer.new(); snapshot_scroll.name = "WorkSnapshotScroll"
	snapshot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	snapshot_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; snapshot_scroll.focus_mode = Control.FOCUS_ALL; art.add_child(snapshot_scroll)
	canvas = Canvas.new(); canvas.name = "WorkSnapshotCanvas"; canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL; snapshot_scroll.add_child(canvas); canvas.set_output(work.get("output",[])); canvas.cell_selected.connect(select_cell)
	canvas.set_presentation(VIEW_MAPPING,cursor)
	# Resizing can move the current glyph out of view without moving the cursor.
	snapshot_scroll.resized.connect(func() -> void: follow_cursor.call_deferred())
	canvas.resized.connect(func() -> void: follow_cursor.call_deferred())
	closing_label = make_label(words("世界的结构，也成为你表达的材料。", "The world’s structures become material for your expression.")+"  A Thought Within the World",art,13)
	var explanation_scroll := ScrollContainer.new(); explanation_scroll.name = words("解释与定位","Explanation")
	explanation_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	explanation_scroll.focus_mode = Control.FOCUS_ALL; tabs.add_child(explanation_scroll)
	var explanation := VBoxContainer.new(); explanation.size_flags_horizontal = Control.SIZE_EXPAND_FILL; explanation_scroll.add_child(explanation)
	evidence_label = make_label("",explanation,14)
	explanation_button = add_button(words("回到实际生成证据","Locate actual generation evidence"),explanation,func() -> void: request_evidence.emit(maxi(0,cursor-1)))
	fork_button = add_button(words("从这件作品分叉继续改","Fork this work and continue"),explanation,func() -> void: request_fork.emit())
	var source_scroll := ScrollContainer.new(); source_scroll.name = words("配方与来源","Recipe / source"); source_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; source_scroll.focus_mode = Control.FOCUS_ALL; tabs.add_child(source_scroll)
	recipe_label = make_label(recipe_text(),source_scroll,13); recipe_label.name = "WorkSnapshotRecipe"
	sync_presentation()
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
	playing = false
	static_overview = false
	seek(index+1)

func add_button(value: String, parent: Node, action: Callable) -> Button:
	var result := Button.new()
	result.text = value
	result.pressed.connect(action)
	parent.add_child(result)
	return result

func build_controls(parent: Node) -> void:
	controls = HFlowContainer.new(); controls.name = "ExhibitionControls"
	controls.add_theme_constant_override("h_separation",8)
	controls.add_theme_constant_override("v_separation",4)
	parent.add_child(controls)
	play_button = add_button(words("播放","Play"),controls,toggle_play)
	add_button(words("单步","Step"),controls,step)
	overview_button = CheckButton.new(); overview_button.text = words("静态总览","Static overview"); overview_button.button_pressed = true; controls.add_child(overview_button)
	overview_button.toggled.connect(func(value: bool) -> void: static_overview = value; playing = false; sync_presentation())
	motion_button = CheckButton.new(); var motion: CheckButton = motion_button; motion.text = words("减少动态","Reduced motion"); controls.add_child(motion)
	motion.toggled.connect(func(value: bool) -> void:
		reduced_motion = value
		if value: playing = false
		sync_presentation())
	var tempo := OptionButton.new(); controls.add_child(tempo)
	for caption: String in ["1×", "2×", "4×"]: tempo.add_item(caption)
	tempo.item_selected.connect(func(index: int) -> void: speed = [4.0,8.0,16.0][index])
	mapping_choice = OptionButton.new(); controls.add_child(mapping_choice)
	mapping_choice.add_item(words("光迹 v1","Light trace v1"))
	mapping_choice.add_item(words("原光纹 v1","Original shapes v1") if work.get("mapping","") == "light-shapes-v1" else words("光纹查看 v1","Shapes v1 viewing"))
	mapping_choice.add_item(words("四轨光句 v1","Four-lane phrases v1"))
	mapping_choice.tooltip_text = words("查看构图可切换；不会改写作品的保存映射。", "Switch viewing composition without rewriting the work’s saved mapping.")
	mapping_choice.item_selected.connect(func(_index: int) -> void: sync_presentation())
	timeline = HSlider.new(); timeline.name = "ExhibitionTimeline"; timeline.min_value = 0; timeline.max_value = work.get("output",[]).size(); timeline.step = 1; timeline.value = cursor; parent.add_child(timeline)
	timeline.value_changed.connect(func(value: float) -> void: playing = false; static_overview = false; seek(int(value)))

func set_evidence(record: Dictionary) -> bool:
	evidence = {}
	if record.get("output",[]) != work.get("output",[]) or record.get("recipe",{}) != work.get("recipe",{}) or not record.get("events") is Array:
		if evidence_label != null: sync_presentation()
		return false
	evidence = record.duplicate(true)
	if evidence_label != null: sync_presentation()
	return true

func seek(position: int) -> void:
	cursor = clampi(position,0,work.get("output",[]).size())
	elapsed = 0.0
	sync_presentation()

func step() -> void:
	playing = false
	static_overview = false
	seek(mini(cursor+1,work.get("output",[]).size()))

func toggle_play() -> void:
	static_overview = false
	if reduced_motion: step(); return
	if cursor >= work.get("output",[]).size(): seek(0)
	playing = not playing
	sync_presentation()

func _process(delta: float) -> void:
	if not playing or reduced_motion: return
	elapsed += delta*speed
	var advance: int = int(elapsed)
	if advance == 0: return
	elapsed -= advance
	cursor = mini(cursor+advance,work.get("output",[]).size())
	if cursor >= work.get("output",[]).size(): playing = false
	sync_presentation()

func sync_presentation() -> void:
	if canvas == null: return
	var output: Array = work.get("output",[])
	canvas.selected = cursor-1
	var mappings: Array[String] = [VIEW_MAPPING,"light-shapes-v1",Canvas.PHRASE_MAPPING]
	canvas.set_presentation(mappings[mapping_choice.selected],-1 if static_overview else cursor)
	timeline.set_value_no_signal(cursor)
	overview_button.set_pressed_no_signal(static_overview)
	motion_button.set_pressed_no_signal(reduced_motion)
	play_button.text = words("暂停","Pause") if playing else words("播放","Play")
	position_label.text = words("第 %d / %d 格", "Cell %d / %d")%[cursor,output.size()]+(" · "+Catalog.symbols([output[cursor-1]]) if cursor > 0 else "")
	position_label.text += " · "+canvas.viewing_mapping
	if canvas.viewing_mapping == Canvas.PHRASE_MAPPING:
		position_label.text += words(" · A–D 固定四轨，16格一行；连线表示顺序。", " · Fixed A–D lanes; 16 cells per viewing row. Lines show sequence order.")
	if work.get("mapping","") != "light-shapes-v1":
		position_label.text += words(" · 原保存映射暂不支持；这是另一种查看方式。", " · Saved mapping unsupported; this is an alternate view.")
	closing_label.visible = static_overview or cursor == output.size()
	var lines := PackedStringArray([words("作品：","Work: ")+str(work.get("id","")),position_label.text,words("保存映射：","Saved mapping: ")+str(work.get("mapping",""))+" · "+words("查看映射：","Viewing mapping: ")+canvas.viewing_mapping])
	var found: bool = false
	for item: Dictionary in evidence.get("events",[]):
		if item.get("kind","") in ["seed_write","feedback_write"] and int(item.get("index",-1)) == cursor-1 and cursor > 0 and item.get("symbol",-1) == output[cursor-1]:
			found = true
			lines.append(words("实际记录：","Recorded event: ")+str(item.kind))
			if item.kind == "seed_write": lines.append(words("这是配方中的起始片段。","This symbol belongs to the recipe’s initial passage."))
			else:
				lines.append(words("此前上下文：","Before context: ")+Catalog.symbols(item.get("before_context",[])))
				lines.append(words("A/B/C/D 计数：","A/B/C/D counts: ")+str(item.get("counts",[]))+" · "+str(item.get("sampler","")))
			lines.append(words("回灌后上下文：","Feedback context: ")+Catalog.symbols(item.get("context",[])))
			break
	if not found: lines.append(words("此格尚无经核对的生成事件；可请求返回证据。", "No verified generation event is available for this cell; request its evidence."))
	evidence_label.text = "\n".join(lines)
	explanation_button.disabled = evidence.is_empty()
	# Layout/range changes settle before following. Static appreciation keeps its scroll.
	follow_cursor.call_deferred()

func follow_cursor() -> void:
	if static_overview or cursor <= 0 or not is_instance_valid(snapshot_scroll): return
	var rect: Rect2 = canvas.cell_rect(cursor-1)
	var visible_height: float = snapshot_scroll.size.y
	var top: float = snapshot_scroll.scroll_vertical
	if rect.size.y > visible_height:
		# A very short viewport still centers the actual glyph, not an empty lane.
		var point: Vector2 = canvas.phrase_point(cursor-1) if canvas.viewing_mapping == Canvas.PHRASE_MAPPING else rect.get_center()
		if point.y < top+8 or point.y > top+visible_height-8:
			snapshot_scroll.scroll_vertical = maxi(0,roundi(point.y-visible_height/2))
	elif rect.position.y < top:
		snapshot_scroll.scroll_vertical = maxi(0,floori(rect.position.y-6))
	elif rect.end.y > top+visible_height:
		snapshot_scroll.scroll_vertical = ceili(rect.end.y-visible_height+6)

func dismiss() -> void:
	hide()
	dismissed.emit()
	queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismiss()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE: toggle_play()
		elif event.keycode == KEY_RIGHT: step()
		elif event.keycode == KEY_LEFT: playing = false; static_overview = false; seek(cursor-1)
		else: return
		get_viewport().set_input_as_handled()
