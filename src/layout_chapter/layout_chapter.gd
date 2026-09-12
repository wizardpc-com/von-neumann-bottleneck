extends Control
const C = preload("res://src/layout_chapter/layout_catalog.gd")
const R = preload("res://src/layout_chapter/layout_recipe.gd")
const S = preload("res://src/layout_chapter/layout_simulator.gd")
const Instrument = preload("res://src/ui/floating_instrument_panel.gd")
const Memory = preload("res://src/layout_chapter/layout_memory_view.gd")
const Chip = preload("res://src/layout_chapter/layout_field_chip.gd")
var level: String = ""
var design: Dictionary = {}
var workspace: Control
var panels: Dictionary = {}
var tools_box: VBoxContainer
var title: Label
var status: Label
var source_view: Control
var copy_view: Control
var results: VBoxContainer
var runs: Array[LayoutRun] = []
var trace_indices: Array[int] = []
var trace_filter: int = 1
var trace_list: ItemList
var case_index: int = 0
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var names: OptionButton
var scheme_name: LineEdit
var hint_tier: int = 0
var hint_layer: Control
var confirmation: ConfirmationDialog
var completion: LevelCompletionOverlay
var stale: bool = true
var building: bool = false

func _ready() -> void:
	var skin := Theme.new()
	skin.default_font_size = 18
	preload("res://src/ui/instrument_theme.gd").apply_to(skin)
	theme = skin
	var background := preload("res://src/ui/technical_backdrop.gd").new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,14)
	add_child(margin)
	var root := VBoxContainer.new()
	margin.add_child(root)
	var header := HBoxContainer.new()
	root.add_child(header)
	title = _label(_l("第四章 · 各就其位","Chapter 4 · A Place for Everything"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size",25)
	header.add_child(title)
	_button(header,_l("任务树","Task tree"),_leave)
	_button(header,_l("全屏","Fullscreen"),WindowMode.toggle_fullscreen)
	header.add_child(PlaytestMoments.make_button())
	var dock := HFlowContainer.new()
	root.add_child(dock)
	for entry: Array in [["tools","布局工具","Layout tools"],["mission","任务","Mission"],["memory","内存","Memory"],["trace","运行记录","Trace"],["manual","图解规则","Illustrated rules"]]:
		_button(dock,_l(entry[1],entry[2]),_toggle.bind(entry[0]))
	_button(dock,_l("运行全部订单","Run all cases"),_run_all)
	_button(dock,_l("撤销","Undo"),_undo.bind(false))
	_button(dock,_l("重做","Redo"),_undo.bind(true))
	_button(dock,"Hint",_hint_request)
	status = _label(_l("拖动字段组合布局；运行后查看真实地址与搬运记录。","Group fields, run, and inspect real addresses and transfers."))
	root.add_child(status)
	workspace = Control.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(workspace)
	confirmation = ConfirmationDialog.new()
	confirmation.title=_l("查看下一层提示","Reveal next hint")
	confirmation.ok_button_text=_l("确认查看","Reveal")
	confirmation.cancel_button_text=_l("暂不查看","Not yet")
	confirmation.confirmed.connect(_hint_advance)
	confirmation.canceled.connect(func() -> void: PlaytestData.record_hint_action(&"chapter_4",StringName(level),mini(3,hint_tier+1),&"cancel"))
	add_child(confirmation)
	completion = preload("res://src/ui/level_completion_overlay.gd").new()
	completion.questionnaire_enabled = PlaytestData.questionnaires_enabled()
	completion.continue_requested.connect(_leave)
	completion.feedback_submitted.connect(PlaytestData.submit_level_feedback)
	add_child(completion)
	var requested: StringName = TaskNavigation.consume("chapter_4")
	if requested.is_empty():
		for id: String in C.IDS:
			if C.unlocked(id,LayoutChapter.completed(),LayoutChapter.chapter_unlocked(),GameMode.is_test_mode()) and not LayoutChapter.completed().has(id): requested = StringName(id); break
	if requested.is_empty() and LayoutChapter.chapter_unlocked(): requested = &"fields"
	if requested.is_empty(): _leave(); return
	_open(String(requested))

func _open(id: String) -> void:
	if not C.unlocked(id,LayoutChapter.completed(),LayoutChapter.chapter_unlocked(),GameMode.is_test_mode()): _leave(); return
	level = id
	PlaytestData.level_started(&"chapter_4",StringName(id))
	design = LayoutChapter.drafts().get(id,C.starter_design()).duplicate(true)
	if id == "relocation" and not design.has("orders"): design.orders = {"A":C.starter_design(),"B":C.starter_design()}
	title.text = "4-%d · %s" % [C.IDS.find(id)+1,C.title(id)]
	tools_box = _box(_panel("tools",Localization.text(&"layout.tools.window_title"),Vector2(10,10),Vector2(375,590)))
	var memory_box: VBoxContainer = _box(_panel("memory",_l("地址视图","Address view"),Vector2(405,10),Vector2(575,600)))
	var memory_tabs := HBoxContainer.new(); memory_box.add_child(memory_tabs)
	_button(memory_tabs,_l("源数据","Source"),func() -> void: source_view.show(); copy_view.hide())
	_button(memory_tabs,_l("临时副本","Scratch copy"),func() -> void:
		if _current().strategy != "direct": _refresh_memory(); source_view.hide(); copy_view.show())
	source_view = Memory.new(); memory_box.add_child(source_view)
	copy_view = Memory.new(); memory_box.add_child(copy_view); copy_view.hide()
	results = _box(_panel("trace",_l("运行与比较","Runs and comparison"),Vector2(1005,10),Vector2(570,610)))
	_build_mission()
	_build_manual()
	_rebuild_tools()
	_refresh_memory()
	panels.trace.hide(); panels.manual.hide(); panels.memory.hide()
	workspace.move_child(panels.mission,-1)

func _current() -> Dictionary:
	return design.orders[["A","B"][case_index]] if level == "relocation" else design

func _rebuild_tools() -> void:
	building = true
	for child: Node in tools_box.get_children():
		tools_box.remove_child(child)
		child.queue_free()
	var current: Dictionary = _current()
	if level == "relocation":
		_option(tools_box,[_l("订单 A · 只查一次","Order A · once"),_l("订单 B · 反复八次","Order B · eight times")],case_index,func(i: int) -> void: case_index=i; _rebuild_tools(); _refresh_memory())
	if C.IDS.find(level)>=3:
		tools_box.add_child(_label(_l("查询前的整理","Preparation before queries")))
		var strategies: Array = ["direct","full"] if level == "relocation" else ["direct","full","batch"]
		var captions: Array = [_l("直接读取原数据","Read source directly"),_l("复制所选字段后查询","Copy selected fields first")]
		if strategies.size()==3: captions.append(_l("分批复制并查询","Copy and query in batches"))
		_option(tools_box,captions,maxi(0,strategies.find(current.strategy)),func(i: int) -> void: _remember(); _current().strategy=strategies[i]; _changed())
		if current.strategy != "direct":
			var copy_grid := GridContainer.new(); copy_grid.columns=2; tools_box.add_child(copy_grid)
			for f: int in range(4):
				var tick := CheckButton.new(); tick.text=_l("复制 ","Copy ")+_field(f); tick.button_pressed=current.copy_fields.has(f)
				copy_grid.add_child(tick)
				tick.toggled.connect(func(on: bool) -> void:
					if not on and _current().copy_fields.size()==1: tick.set_pressed_no_signal(true); return
					_remember()
					if on: _current().copy_fields.append(f)
					else: _current().copy_fields.erase(f)
					_changed())
			if current.strategy == "batch":
				var batch := SpinBox.new(); batch.min_value=1; batch.max_value=64; batch.step=1; batch.value=current.batch
				batch.prefix=_l("每批 ","Batch "); tools_box.add_child(batch)
				batch.value_changed.connect(func(v: float) -> void: _remember(); _current().batch=int(v); _changed(false))
	tools_box.add_child(_label(_l("拖到另一字段前可重排或加入其分组。\n也可用右侧分组选项；不会丢失任何字段。","Drag before a field to reorder or join its group.\nOr choose a group on the right; all fields are retained."),true))
	for g: int in range(current.recipe.groups.size()):
		var heading := HBoxContainer.new(); tools_box.add_child(heading)
		heading.add_child(_label(_l("组 ","Group ")+str(g+1)))
		_option(heading,[_l("记录挨着放","By record"),_l("相同字段挨着放","By field")],0 if current.recipe.groups[g].order == "record" else 1,func(i: int) -> void:
			_remember(); _current().recipe.groups[g].order = "record" if i == 0 else "field"; _changed())
		for field: int in current.recipe.groups[g].fields:
			var row := HBoxContainer.new(); tools_box.add_child(row)
			var chip := Chip.new(); chip.field_id=field; chip.text=_field(field)+" · 4 B"; chip.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			chip.add_theme_color_override("font_color",Memory.COLORS[field]); chip.custom_minimum_size.y=38
			chip.field_dropped.connect(_drop_field); row.add_child(chip)
			chip.drag_started.connect(func() -> void: PlaytestData.record_action(&"chapter_4",StringName(level),&"layout_drag_attempt"))
			chip.drag_released.connect(func(source: int, at: Vector2, payload: Dictionary) -> void: call_deferred("_finish_field_drop",source,at,payload))
			var choices: Array = []
			for n: int in range(current.recipe.groups.size()): choices.append(_l("组 ","Group ")+str(n+1))
			if current.recipe.groups.size()<4: choices.append(_l("新组","New group"))
			_option(row,choices,g,func(i: int) -> void: _move_group(field,i))
	var block_row := HBoxContainer.new(); tools_box.add_child(block_row)
	block_row.visible = C.IDS.find(level)>=2
	block_row.add_child(_label(_l("每块记录数","Records / block")))
	var blocks: Array = [0,1,2,4,8,16]
	_option(block_row,[_l("全部","All"),"1","2","4","8","16"],maxi(0,blocks.find(int(current.recipe.block))),func(i: int) -> void: _remember(); _current().recipe.block=blocks[i]; _changed())
	var names_row := HBoxContainer.new(); tools_box.add_child(names_row)
	scheme_name = LineEdit.new(); scheme_name.placeholder_text=_l("为自己的方案命名","Name your design"); scheme_name.max_length=40; scheme_name.size_flags_horizontal=Control.SIZE_EXPAND_FILL; names_row.add_child(scheme_name)
	_button(names_row,_l("保存","Save"),_save_named)
	names = OptionButton.new(); names.add_item(_l("选择已保存方案","Choose a saved design")); tools_box.add_child(names)
	for key: String in LayoutChapter.named().get(level,{}): names.add_item(key)
	names.item_selected.connect(func(i: int) -> void:
		if i<=0: return
		_remember(); design=LayoutChapter.named()[level][names.get_item_text(i)].duplicate(true); _changed())
	var previous: String = {"records":"fields","hot_cold":"records","batches":"relocation","mixed":"hot_cold"}.get(level,"")
	if not previous.is_empty() and LayoutChapter.completed().has(previous):
		_button(tools_box,_l("复制我的上一关布局","Copy my previous layout"),func() -> void:
			_remember(); _current().recipe=LayoutChapter.completed()[previous].recipe.duplicate(true); _changed())
	building = false

func _move_group(field: int, target: int) -> void:
	_remember()
	var groups: Array = _current().recipe.groups
	if target == groups.size(): groups.append({"fields":[],"order":"record"})
	for group: Dictionary in groups: group.fields.erase(field)
	groups[target].fields.append(field)
	for i: int in range(groups.size()-1,-1,-1):
		if groups[i].fields.is_empty(): groups.remove_at(i)
	_changed()
func _finish_field_drop(source: int, at: Vector2, payload: Dictionary) -> void:
	if bool(payload.get("committed",false)): return
	for row: Node in tools_box.get_children():
		for chip: Node in row.get_children():
			if chip.get_script() == Chip and chip.is_visible_in_tree() and chip.get_global_rect().has_point(at):
				payload.committed=true
				_drop_field(source,chip.field_id)
				return
func _drop_field(source: int, target: int) -> void:
	if source == target: return
	_remember()
	var groups: Array = _current().recipe.groups
	for group: Dictionary in groups: group.fields.erase(source)
	for group: Dictionary in groups:
		if group.fields.has(target): group.fields.insert(group.fields.find(target),source)
	for i: int in range(groups.size()-1,-1,-1):
		if groups[i].fields.is_empty(): groups.remove_at(i)
	_changed()
func _remember() -> void:
	undo_stack.append(design.duplicate(true)); redo_stack.clear()
	if undo_stack.size()>80: undo_stack.pop_front()
func _undo(redo: bool) -> void:
	var from: Array[Dictionary] = redo_stack if redo else undo_stack
	var to: Array[Dictionary] = undo_stack if redo else redo_stack
	if from.is_empty() or is_instance_valid(hint_layer) and hint_layer.visible: return
	to.append(design.duplicate(true)); design=from.pop_back()
	_changed(true,false)
	PlaytestData.record_action(&"chapter_4",StringName(level),&"redo" if redo else &"undo")
func _changed(rebuild: bool = true, record: bool = true) -> void:
	stale=true
	LayoutChapter.store_draft(level,design)
	status.text=_l("布局已改变 · 请重新运行；旧结果不会作为当前成绩。","Design changed · run again; previous results are stale.")
	if record: PlaytestData.record_action(&"chapter_4",StringName(level),&"layout_edit",{"recipe_digest":S.design_signature(_current()),"strategy":str(_current().strategy),"batch":int(_current().batch),"group_count":_current().recipe.groups.size(),"block":int(_current().recipe.get("block",0)),"copy_field_count":_current().copy_fields.size()})
	_refresh_memory()
	if rebuild: call_deferred("_rebuild_tools")
func _save_named() -> void:
	if LayoutChapter.save_named(level,scheme_name.text.strip_edges(),design):
		status.text=_l("方案已保存；以后修改不会覆盖这个副本。","Design saved; later edits won't overwrite this copy.")
		_rebuild_tools()
func _refresh_memory() -> void:
	source_view.show()
	var task: Dictionary = C.cases(level)[case_index]
	var recipe: Dictionary = _current().recipe if task.native_layout else R.record_major()
	source_view.configure(R.mapping(recipe,task.records.size()),task.records,_l("源数据 · 所有字段都在这里","Source · every field is retained"))
	copy_view.hide()
	if not task.native_layout and _current().strategy != "direct":
		var count: int = mini(task.records.size(),int(_current().batch)) if _current().strategy == "batch" else task.records.size()
		copy_view.configure(R.mapping(_current().recipe,count,R.align_line(task.records.size()*16+16),_current().copy_fields),task.records,_l("临时区预览 · 运行时才实际复制","Scratch preview · copied only when running"))
		copy_view.show()

func _begin_arranging() -> void:
	panels.mission.hide()
	panels.memory.show_instrument()

func _build_mission() -> void:
	var box: VBoxContainer = _box(_panel("mission",Localization.text(&"layout.mission.window_title"),Vector2(405,10),Vector2(780,590)))
	_button(box,Localization.text(&"layout.mission.begin"),_begin_arranging)
	box.add_child(_label(C.goal(level),true))
	if level == "mixed": box.add_child(_label(_l("可选目标（不挡通关）：两单总流量 ≤ 1300 B；或临时峰值 ≤ 16 B。可以用不同命名方案分别追求。","Optional goals: total traffic across both cases ≤ 1300 B; or peak scratch ≤ 16 B. Different named designs can pursue each goal."),true))
	if level == "hot_cold": box.add_child(_label(_l("新工具：每块记录数。分组决定哪些字段在一起；分块决定一次把多少条记录排在一起。可以先分组，再尝试 2 或 4 条一块。","New tool: records per block. Groups choose neighboring fields; blocks choose how many records to arrange at once. Group first, then try blocks of 2 or 4."),true))
	if level == "relocation": box.add_child(_label(_l("新工具：复制整理。源数据的排法固定；工具里的布局现在决定临时副本。订单 A 与 B 各有一份独立方案，用左侧订单选择切换。所有准备时间和写入都计入目标。","New tool: copying. The source is fixed; your layout now describes scratch data. Orders A and B keep separate designs, selected on the left. Preparation and writes count toward the target."),true))
	if level in ["batches","mixed"]: box.add_child(_label(_l("分批顺序：复制一批 → 在这一批上做完所有查询与重复 → 释放 → 下一批。所有逻辑记录和输出顺序都保留；尾批只处理剩余记录。","Batch order: copy → finish all queries and repetitions on this batch → release → next. Preserve all records and output order; process only remaining records in the tail."),true))
	box.add_child(_label(Localization.text(&"layout.mission.read_grid"),true))
	for task: Dictionary in C.cases(level):
		var text: String = _l("订单 ","Case ")+task.name+" · %d " % task.records.size()+_l("条记录","records")
		for q: Dictionary in task.queries:
			var fields: Array[String] = []
			for f: int in q.fields: fields.append(_field(f))
			text += "\n"+(_l("求和：","Sum: ") if q.kind == "sum" else _l("逐项输出：","Output: "))+" + ".join(fields)+" ×%d" % int(q.get("repeat",1))
			text += _l(" · 全部记录"," · all records") if q.get("indices",[]).is_empty() else " · #"+str(q.indices)
		if task.target_cycles>0: text += "\n"+_l("总周期 ≤ ","Total cycles ≤ ")+str(task.target_cycles)
		if task.target_bytes>0: text += "\n"+_l("RAM 总流量 ≤ ","Total RAM traffic ≤ ")+str(task.target_bytes)+" B"
		if not task.native_layout: text += " · "+_l("临时空间 ≤ ","Scratch ≤ ")+str(task.scratch_limit)+" B"
		box.add_child(_label(text,true))
	box.add_child(_label(Localization.text(&"layout.mission.cache_rules"),true))
	_button(box,Localization.text(&"layout.mission.begin"),_begin_arranging)
var shared_handbook: TerminologyHandbook

func _build_manual() -> void:
	var box: VBoxContainer = _box(_panel("manual",_l("图解规则 · 本关先学这些","Illustrated rules · learn these first"),Vector2(480,35),Vector2(670,580)))
	box.add_child(_label(_l("记录身份 → 字段分组 → 实际地址 → 16 B 搬运 → 查询结果","Record identity → field groups → physical addresses → 16 B transfer → result"),true))
	_button(box,_l("打开术语手册 · 本关推荐","Open handbook · recommended for this task"),func() -> void:
		if not is_instance_valid(shared_handbook):
			shared_handbook=TerminologyHandbook.new(); shared_handbook.standalone_entry=false; add_child(shared_handbook)
		shared_handbook.set_lesson("layout",level); shared_handbook.open_handbook())
	var diagram := Memory.new(); box.add_child(diagram)
	diagram.configure(R.mapping(R.record_major(),2),C.records(2),_l("同一条记录的四个字段，共 16 B","Four fields of one record occupy 16 B"))
	box.add_child(_label(_l("组：让选中的字段待在同一片地址里。组内按记录，先放一条记录的所有字段；按字段，先放这一字段的所有记录。每块限制上述排列一次处理多少条记录。\n缓存自动管理，只有两行。读取先花 1 周期查缓存；未命中再花 16 周期搬回一行。每个查询值另花 1 周期计算，最终每个结果花 1 周期输出。","A group occupies one address region. By record puts a record's fields together; by field puts each field's records together. Blocks limit records per repetition.\nCache manages two lines automatically. A read costs 1 lookup cycle; a miss adds 16 cycles to fill a line. Each query value adds 1 compute cycle; each final result adds 1 output cycle."),true))
	if C.IDS.find(level)>=3:
		box.add_child(_label(_l("复制不是免费换布局：原数据始终保留，临时区先分配再逐值读取、写入。每写 4 B 花 9 周期，直写 RAM，不自动装入缓存。准备、查询和最终输出全部计时；临时区对齐与空隙也占空间。","Copying is not free: retain the source, allocate scratch, read and write each value. A 4 B write costs 9 cycles and writes through to RAM without allocating a cache line. Preparation, queries and final output all count; padding occupies scratch too."),true))
	if C.IDS.find(level)>=4:
		box.add_child(_label(_l("分批：复制这一批 → 对这批完成所有公开查询和重复次数 → 释放 → 下一批。最后一批只处理余数；记录输出仍按题目顺序归位。","Batch: copy → perform all public queries and repetitions for this batch → release → next batch. The tail processes only remaining records; outputs retain public query order."),true))

func _run_all() -> void:
	if level.is_empty() or is_instance_valid(hint_layer) and hint_layer.visible: return
	_begin_arranging()
	LayoutChapter.store_draft(level,design)
	var report: Dictionary = C.evaluate(level,design)
	runs = report.runs; stale=false
	for child: Node in results.get_children(): child.free()
	var case_rows: Array[Dictionary] = []
	var baseline: Dictionary = C.evaluate(level,C.starter_design())
	var best: Dictionary = C.evaluate(level,LayoutChapter.completed()[level]) if LayoutChapter.completed().has(level) else {}
	for i: int in range(runs.size()):
		var run: LayoutRun = runs[i]
		var m: Dictionary = run.metrics
		var caption: String = _l("订单 ","Case ")+run.test_name+" · "+(_l("达标","Target met") if m.target_met else _l("输出正确，尚未达标","Correct output, target unmet") if run.passed else _l("运行未完成：","Incomplete: ")+(_l("临时空间不足","Insufficient scratch space") if m.error == "space_limit" else str(m.error)))
		caption += "\n"+_l("周期：准备 %d + 查询 %d + 输出 %d = %d","Cycles: prepare %d + query %d + output %d = %d") % [m.prepare_cycles,m.query_cycles,m.output_cycles,m.total_cycles]
		caption += "\n"+_l("RAM 读取 %d B · 写入 %d B · 临时峰值 %d B","RAM read %d B · write %d B · scratch peak %d B") % [m.ram_read_bytes,m.ram_write_bytes,m.peak_extra_bytes]
		if m.error == "space_limit": caption += "\n"+_l("这次申请需要 %d B；尚未分配或复制。","This allocation needs %d B; no allocation or copy occurred.") % int(m.required_extra_bytes)
		caption += "\n"+_l("初始方案 %d 周期","Initial design: %d cycles") % int(baseline.runs[i].metrics.total_cycles)
		if not best.is_empty(): caption += " · "+_l("我的已达标最佳 %d","My passing best: %d") % int(best.runs[i].metrics.total_cycles)
		results.add_child(_label(caption,true))
		var outputs := _label(_l("实际输出：","Actual: ")+str(run.output_values)+"\n"+_l("预期输出：","Expected: ")+str(run.expected_values),true)
		outputs.hide(); results.add_child(outputs)
		_button(results,_l("展开／收起逐项输出","Show / hide exact outputs"),func() -> void: outputs.visible=not outputs.visible)
		case_rows.append({"name":run.test_name,"passed":run.passed,"correct":run.passed,"target_met":m.target_met,"result_class":"target_met" if m.target_met else "correct_but_slow" if run.passed else "space_limit" if m.error=="space_limit" else "runtime_error","metrics":m.duplicate(true)})
		_button(results,_l("查看订单 ","Inspect case ")+run.test_name,_select_trace.bind(i))
	_option(results,[_l("全部步骤","All steps"),_l("数据搬运","Transfers"),_l("批次边界与尾批","Batch boundaries and tail"),_l("结果输出","Outputs")],trace_filter,func(i: int) -> void: trace_filter=i; _select_trace(case_index))
	trace_list = ItemList.new(); trace_list.custom_minimum_size=Vector2(420,260); results.add_child(trace_list)
	trace_list.item_selected.connect(_trace_selected)
	var all_correct: bool = true
	for run: LayoutRun in runs: all_correct=all_correct and run.passed
	PlaytestData.record_official_run(&"chapter_4",StringName(level),report.passed,{"strategy":str(design.get("strategy","direct")),"case_count":runs.size(),"cases":case_rows,"correct":all_correct,"target_met":report.passed,"result_class":"target_met" if report.passed else "correct_but_slow" if all_correct else "runtime_error","cycles":LayoutChapter.cost(report),"model_version":S.MODEL_VERSION,"case_set_version":("layout-v1:"+level+JSON.stringify(C.cases(level))).sha256_text(),"recipe_digest":S.design_signature(design)})
	_select_trace(case_index)
	_toggle("trace",true)
	status.text=_l("全部订单达标 · 可以继续探索另一份方案。","All cases passed · try another design.") if report.passed else _l("查看结果：输出、时间与空间分别核对，再修改布局。","Inspect output, time and space separately, then adjust the layout.")
	if report.passed:
		var was_done: bool = LayoutChapter.completed().has(level)
		if LayoutChapter.record_pass(level,design) and not was_done:
			PlaytestData.level_completed(&"chapter_4",StringName(level),{"cycles":LayoutChapter.cost(report)})
			# Completion never changes the design or automatically starts another task.
			_button(results,_l("已完成 · 返回任务树选择下一站","Completed · choose the next task"),_leave)
func _select_trace(index: int) -> void:
	if runs.is_empty(): return
	case_index=index
	var active: LayoutRun = runs[index]
	source_view.show()
	source_view.configure(active.source_map,C.cases(level)[index].records,_l("此轮实际源地址","Source addresses in this run")+(_l(" · 历史结果"," · previous run") if stale else ""))
	copy_view.hide()
	if level == "relocation": call_deferred("_rebuild_tools")
	trace_list.clear(); trace_indices.clear()
	var run: LayoutRun = runs[index]
	for event_index: int in range(run.events.size()):
		var event: SimulationEvent = run.events[event_index]
		if trace_filter == 1 and event.kind not in [&"fill",&"write",&"allocate",&"release",&"error"]: continue
		if trace_filter == 2 and event.kind not in [&"allocate",&"release",&"error"]: continue
		if trace_filter == 3 and event.kind not in [&"output",&"error"]: continue
		trace_indices.append(event_index)
		var phase: String = {"prepare":_l("准备","Prepare"),"query":_l("查询","Query"),"output":_l("输出","Output")}.get(event.details.get("stage",""),"")
		var action: String = {"lookup":_l("查缓存","Lookup"),"fill":_l("搬回一行","Fill line"),"read":_l("读取值","Read value"),"compute":_l("计算","Compute"),"write":_l("写入副本","Write copy"),"allocate":_l("分配空间","Allocate"),"release":_l("释放空间","Release"),"evict":_l("替换缓存行","Evict line"),"output":_l("交付结果","Output"),"error":_l("停止：错误","Stop: error")}.get(String(event.kind),String(event.kind))
		trace_list.add_item("%d · %s · %s · @%d · %d B" % [event.cycle,phase,action,event.address,int(event.details.get("bytes",0))])
	PlaytestData.record_trace_action(&"chapter_4",StringName(level),&"case_selected")
func _trace_selected(index: int) -> void:
	if runs.is_empty(): return
	var event: SimulationEvent = runs[case_index].events[trace_indices[index]]
	source_view.highlight(event)
	for map: Dictionary in runs[case_index].scratch_maps:
		var record: int = int(event.details.get("record",-1))
		var last_record: int = int(map.first_record)
		for cell: Dictionary in map.cells: last_record=maxi(last_record,int(map.first_record)+int(cell.record))
		if record>=int(map.first_record) and record<=last_record:
			copy_view.configure(map,C.cases(level)[case_index].records,_l("这一批实际复制到的临时区","Actual scratch addresses for this batch")+" · #%d–%d" % [map.first_record,last_record]); copy_view.show(); source_view.hide(); break
	copy_view.highlight(event)
	PlaytestData.record_trace_action(&"chapter_4",StringName(level),&"step")

func _hint_request() -> void:
	PlaytestData.record_hint_action(&"chapter_4",StringName(level),mini(3,hint_tier+1),&"request")
	if hint_tier == 0: _hint_advance(); return
	confirmation.dialog_text=_l("下一层会揭示局部分组关系。是否继续？","The next tier reveals part of a grouping. Continue?") if hint_tier==1 else _l("将显示完整参考方案，只读且不会写入你的布局。是否继续？","Show the complete reference on a read-only canvas? Your layout stays intact.")
	confirmation.popup_centered(Vector2i(570,180))
func _hint_advance() -> void:
	hint_tier=mini(3,hint_tier+1)
	PlaytestData.record_hint(&"chapter_4",StringName(level),hint_tier)
	if is_instance_valid(hint_layer): hint_layer.free()
	hint_layer=PanelContainer.new(); hint_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(hint_layer)
	var margin := MarginContainer.new(); hint_layer.add_child(margin)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,36)
	var column := VBoxContainer.new(); column.add_theme_constant_override("separation",20); margin.add_child(column)
	column.add_child(_label("Hint %d · " % hint_tier+_l("独立只读画布","Independent read-only canvas")))
	_button(column,_l("回到自己的方案","Return to my design"),func() -> void: hint_layer.hide())
	var clues: Array = [
		_l("追踪一条查询：每次带回的四格里，几格真的用到了？","Follow a query: how many of the four fetched cells are used?"),
		_l("让同一次查询会一起使用的字段靠近。复制题还要先比较重复次数和准备时间。","Keep fields used together near each other. For copying, compare repetition count against preparation time."),
		_l("这只是一个有效方案，分组、顺序和批量仍可能有别的解法。","This is one valid design; other groupings, orders and batch sizes can work.")]
	column.add_child(_label(clues[hint_tier-1],true))
	if hint_tier>=1:
		var ref: Dictionary = C.reference_solution(level)
		if level == "relocation": ref=ref.orders[["A","B"][case_index]]
		var sc := ScrollContainer.new(); sc.size_flags_vertical=Control.SIZE_EXPAND_FILL; column.add_child(sc)
		var view := Memory.new(); sc.add_child(view)
		view.configure(R.mapping(ref.recipe if hint_tier==3 else R.record_major(),2 if hint_tier<3 else C.cases(level)[case_index].records.size(),0,C.cases(level)[case_index].queries[0].fields if hint_tier==2 else [0,1,2,3]),C.cases(level)[case_index].records,_l("局部关系（只显示两条）","Partial relation (two records)") if hint_tier==2 else _l("原始记录 · 先看同一次查询需要谁","Original records · what does one query need?") if hint_tier==1 else _l("完整分组与顺序","Complete grouping and order"))
		if hint_tier==3 and C.IDS.find(level)>=3:
			var fields: Array[String] = []
			for f: int in ref.copy_fields: fields.append(_field(f))
			column.add_child(_label((_l("直接读取源数据","Read source directly") if ref.strategy == "direct" else _l("复制：","Copy: ")+" + ".join(fields))+(_l(" · 每批 %d 条"," · %d records / batch") % int(ref.batch) if ref.strategy == "batch" else _l(" · 整批整理"," · full copy") if ref.strategy == "full" else ""),true))
	if hint_tier<3: _button(column,_l("请求下一层","Request next tier"),_hint_request)
func _leave() -> void:
	if not level.is_empty():
		LayoutChapter.store_draft(level,design)
		PlaytestData.level_exited(&"chapter_4",StringName(level))
	get_tree().call_deferred("change_scene_to_file","res://src/campaign/task_tree.tscn")
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_ESCAPE and is_instance_valid(hint_layer) and hint_layer.visible: hint_layer.hide(); get_viewport().set_input_as_handled(); return
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit: return
	if event.is_command_or_control_pressed() and event.keycode == KEY_Z: _undo(event.shift_pressed); get_viewport().set_input_as_handled()
func _panel(id: String, caption: String, at: Vector2, dimensions: Vector2) -> FloatingInstrumentPanel:
	var panel := Instrument.new(); panel.custom_minimum_size=Vector2(280,190); panel.setup(StringName(id),caption)
	panel.position=at; panel.size=dimensions; workspace.add_child(panel); panels[id]=panel
	panel.close_requested.connect(func(_id: StringName) -> void: panel.hide())
	panel.focus_requested.connect(func(_id: StringName) -> void: workspace.move_child(panel,-1))
	call_deferred("_settle",panel,dimensions)
	return panel
func _settle(panel: FloatingInstrumentPanel, dimensions: Vector2) -> void:
	await get_tree().process_frame; await get_tree().process_frame
	if is_instance_valid(panel): panel.size=dimensions; panel.fit_to_parent()
func _toggle(id: String, force: bool = false) -> void:
	if not panels.has(id): return
	panels[id].visible = true if force else not panels[id].visible
	if panels[id].visible: workspace.move_child(panels[id],-1); panels[id].fit_to_parent(); PlaytestData.record_tool_opened(&"chapter_4",StringName(level),StringName(id))
func _box(panel: FloatingInstrumentPanel) -> VBoxContainer:
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_AUTO if panel.instrument_id in [&"memory", &"manual"] else ScrollContainer.SCROLL_MODE_DISABLED; panel.content_host.add_child(scroll)
	var box := VBoxContainer.new(); box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; box.add_theme_constant_override("separation",12); scroll.add_child(box); return box
func _label(text: String, wrap: bool = false) -> Label:
	var label := Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF; return label
func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new(); button.text=text; button.custom_minimum_size.y=36; button.pressed.connect(action); parent.add_child(button); return button
func _option(parent: Node, values: Array, selected: int, action: Callable) -> OptionButton:
	var option := OptionButton.new(); parent.add_child(option)
	for value: String in values: option.add_item(value)
	option.select(selected); option.item_selected.connect(action); return option
func _l(zh: String, en: String) -> String: return zh if Localization.current_locale().begins_with("zh") else en
func _field(index: int) -> String: return _l(Memory.NAMES[index],Memory.EN_NAMES[index])
