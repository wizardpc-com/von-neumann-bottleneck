extends Control
## Separate playable context experiment. History is copied evidence, never campaign authority.
const Model = preload("res://experiments/intelligent_workload/state_model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
var english: bool = false
var history: Array[Dictionary] = []
var active_trace: Trace
var order: OptionButton
var slots: OptionButton
var batch: OptionButton
var state_precision: OptionButton
var weight_precision: OptionButton
var residency: OptionButton
var contract: OptionButton
var run_button: Button
var data_button: Button
var language_button: Button
var history_list: ItemList
var tree: Tree
var detail: RichTextLabel
var summary: Label
var status: Label
var public_window: Window

func tr2(zh: String, en: String) -> String: return en if english else zh

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
	build()

func label(text: String, parent: Node, size: int = 16) -> Label:
	var node := Label.new(); node.text = text; node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size); parent.add_child(node); return node

func button(text: String, parent: Node, action: Callable) -> Button:
	var node := Button.new(); node.text = text; node.custom_minimum_size.y = 36
	node.pressed.connect(action); parent.add_child(node); return node

func option(text: String, items: Array[String], parent: Node) -> OptionButton:
	var box := VBoxContainer.new(); box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; parent.add_child(box)
	label(text, box, 14)
	var node := OptionButton.new(); node.custom_minimum_size.y = 34
	for item: String in items: node.add_item(item)
	box.add_child(node); node.item_selected.connect(func(_index: int) -> void: invalidate()); return node

func build(config: Dictionary = {}) -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	var background := ColorRect.new(); background.color = Color("0b1720")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var page := VBoxContainer.new(); page.add_theme_constant_override("separation", 8); margin.add_child(page)
	var header := HBoxContainer.new(); page.add_child(header)
	var title := label(tr2("状态实验 · 下一次还记得什么？", "Context lab · What survives the next request?"), header, 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_button = button("中文 / EN", header, func() -> void:
		var draft: Dictionary = current_config(); english = not english; build(draft))
	button(tr2("退出实验", "Quit lab"), header, func() -> void: get_tree().quit())
	label(tr2("隔离原型 · 无正式进度 · 固定数值递推，不是 Transformer · 周期为公开简化模型", "Isolated prototype · no campaign progress · numerical recurrence, not a Transformer · public teaching cycles"), page, 13)
	label(tr2("4条流，各6次输入；h = 0.65h + 0.35x，输出 = w·h。所有请求在0周期就绪，各流内部保序。\n上下文起初在外存；LRU缺失读入，脏淘汰写回，结束必须flush。量化每次更新真的舍入；所有精度每请求24次运算。\n吞吐目标：总≤1040周期、峰值≤200B、分数和最终状态误差≤0.02。及时响应另要求每条流首响应≤240周期。", "4 streams × 6 inputs: h = 0.65h + 0.35x; output = w·h. All requests ready at cycle 0; preserve each stream's order.\nContexts start in backing memory. LRU misses read; dirty eviction writes; ending requires flush. Actual rounding each update; 24 ops/request at every precision.\nThroughput: total≤1040 cycles, peak≤200B, score and final-state error≤0.02. Prompt service also needs every stream's first response≤240 cycles."), page, 15)
	var controls := GridContainer.new(); controls.columns = 3; controls.add_theme_constant_override("h_separation", 16); page.add_child(controls)
	order = option(tr2("处理次序（只重排不同流）", "Order (reorders independent streams)"), [tr2("轮转 A B C D", "Round-robin A B C D"), tr2("成对 A/B 再 C/D", "Paired A/B then C/D"), tr2("分组 A 完成后 B…", "Grouped: finish A, then B…")], controls)
	slots = option(tr2("自动LRU上下文槽", "Automatic LRU context slots"), ["1", "2", "4"], controls)
	batch = option(tr2("每批请求数（输入+结果36B/项）", "Batch requests (input+result 36B each)"), ["1", "2", "4"], controls)
	state_precision = option(tr2("上下文存储精度", "Context storage precision"), ["32-bit", "8-bit", "4-bit", "2-bit"], controls)
	weight_precision = option(tr2("权重存储精度", "Weight storage precision"), ["32-bit", "8-bit", "4-bit", "2-bit"], controls)
	residency = option(tr2("权重驻留", "Weight residency"), [tr2("驻留到结束", "Resident until end"), tr2("每批重新读取", "Reload each batch")], controls)
	var actions := HBoxContainer.new(); page.add_child(actions)
	contract = option(tr2("服务约束（同一工作负载）", "Service contract (same workload)"), [tr2("吞吐", "Throughput"), tr2("及时响应", "Prompt service")], actions)
	contract.item_selected.connect(func(_i: int) -> void:
		if history_list.get_selected_items().size() > 0: select_run(history_list.get_selected_items()[0]))
	run_button = button(tr2("运行并记录", "Run and record"), actions, run_current)
	data_button = button(tr2("公开输入 / 初态 / 参考", "Public inputs / initial / reference"), actions, show_public_data)
	status = label(tr2("先测轮转/1槽，再比较分组、驻留容量和批量。", "Measure round-robin/1 slot, then compare grouping, residency and batching."), page, 14)
	var bottom := HSplitContainer.new(); bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL; page.add_child(bottom)
	var left := VBoxContainer.new(); left.custom_minimum_size.x = 430; bottom.add_child(left)
	label(tr2("实际运行历史 · 选择旧方案复查", "Recorded runs · select a design to inspect"), left)
	history_list = ItemList.new(); history_list.custom_minimum_size.y = 72; left.add_child(history_list); history_list.item_selected.connect(select_run)
	summary = label("", left, 14)
	detail = RichTextLabel.new(); detail.size_flags_vertical = Control.SIZE_EXPAND_FILL; detail.custom_minimum_size.y = 60; left.add_child(detail)
	var right := VBoxContainer.new(); right.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bottom.add_child(right)
	label(tr2("Trace · 点选读取 / 运算 / 淘汰 / flush", "Trace · select read / compute / eviction / flush"), right)
	tree = Tree.new(); tree.columns = 3; tree.column_titles_visible = true
	tree.set_column_title(0, tr2("周期", "Cycle")); tree.set_column_title(1, tr2("时长", "Cost")); tree.set_column_title(2, tr2("事件", "Event")); tree.size_flags_vertical = Control.SIZE_EXPAND_FILL; right.add_child(tree)
	tree.item_selected.connect(func() -> void:
		var item: TreeItem = tree.get_selected()
		if item != null: detail.text = JSON.stringify(item.get_metadata(0), "  "))
	if not config.is_empty(): restore_config(config)
	refresh_history()
	if not history.is_empty(): history_list.select(history.size() - 1); select_run(history.size() - 1)

func current_config() -> Dictionary:
	return {"order": ["round_robin", "paired", "grouped"][order.selected], "slots": [1, 2, 4][slots.selected], "batch": [1, 2, 4][batch.selected], "state_bits": [32, 8, 4, 2][state_precision.selected], "weight_bits": [32, 8, 4, 2][weight_precision.selected], "reuse": residency.selected == 0, "prompt": contract.selected == 1}

func restore_config(config: Dictionary) -> void:
	order.select(["round_robin", "paired", "grouped"].find(config.order)); slots.select([1, 2, 4].find(config.slots)); batch.select([1, 2, 4].find(config.batch))
	state_precision.select([32, 8, 4, 2].find(config.state_bits)); weight_precision.select([32, 8, 4, 2].find(config.weight_bits))
	residency.select(0 if config.reuse else 1); contract.select(1 if config.prompt else 0)

func invalidate() -> void:
	if status != null: status.text = tr2("方案已变；历史证据不变，请重新运行。", "Design changed; recorded evidence remains. Run again.")

func run_current() -> void:
	active_trace = Model.run(current_config())
	# No mutable Trace object is retained by the comparison list.
	var events: Array[Dictionary] = []
	for event: RefCounted in active_trace.events: events.append(event.to_dictionary().duplicate(true))
	history.append({"metrics": active_trace.metrics.duplicate(true), "events": events, "signature": active_trace.canonical_signature()})
	if history.size() > 80: history.pop_front()
	refresh_history(); history_list.select(history.size() - 1); select_run(history.size() - 1)

func refresh_history() -> void:
	history_list.clear()
	for i: int in history.size():
		var m: Dictionary = history[i].metrics; var c: Dictionary = m.config
		history_list.add_item("%d · %s / S%d / B%d / h%d w%d · %d cyc" % [i + 1, c.order, c.slots, c.batch, c.state_bits, c.weight_bits, m.total_cycles])

func select_run(index: int) -> void:
	var record: Dictionary = history[index]; var m: Dictionary = record.metrics
	var prompt: bool = contract.selected == 1
	if not str(m.error).is_empty():
		status.text = tr2("执行拒绝：", "Execution rejected: ") + str(m.error) + tr2("（scratch硬上限256B）", " (hard scratch limit 256B)")
	else:
		status.text = tr2("满足当前服务约束。继续比较其他方案。", "Meets this service contract. Keep comparing alternatives.") if Model.accepted(m, prompt) else tr2("未满足当前服务约束；复查费用、响应和实际误差。", "Does not meet this contract; inspect costs, responses and actual errors.")
	summary.text = tr2("总%d周期 · %dB · 峰值%dB（预留%dB）\n费用 请求%d + 搬运%d + 运算%d + 提交%d\n首%d · A/B/C/D %s\n读%d / 写%d（flush%d）· 命中%d\n分数误差%.5f · 状态误差%.5f · 外存%dB", "Total %d cyc · %dB · peak %dB (reserved %dB)\nCosts request %d + transfer %d + compute %d + commit %d\nFirst %d · A/B/C/D %s\nReads %d / writes %d (flush %d) · hits %d\nScore error %.5f · state error %.5f · backing %dB") % [m.total_cycles, m.traffic_bytes, m.peak_bytes, m.reserved_bytes, m.request_cycles, m.transfer_cycles, m.compute_cycles, m.commit_cycles, m.first_result_cycle, str(m.first_stream_cycles), m.state_reads, m.state_writes, m.flush_writes, m.state_hits, m.max_error, m.max_state_error, m.get("backing_state_bytes", 0)]
	tree.clear(); var root_item: TreeItem = tree.create_item(); tree.hide_root = true
	for event: Dictionary in record.events:
		var row: TreeItem = tree.create_item(root_item); row.set_text(0, str(event.cycle)); row.set_text(1, str(event.duration)); row.set_text(2, event.kind); row.set_metadata(0, event.details.duplicate(true))
	detail.text = JSON.stringify({"config": m.config, "final_states": m.final_states, "reference_states": m.reference_states}, "  ")

func show_public_data() -> void:
	if is_instance_valid(public_window): public_window.queue_free()
	public_window = Window.new(); public_window.title = tr2("公开数值和成本", "Public values and costs"); public_window.size = Vector2i(760, 520); public_window.transient = true
	add_child(public_window); public_window.close_requested.connect(public_window.queue_free)
	var text := RichTextLabel.new(); text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); public_window.add_child(text)
	var rows: Array[Dictionary] = []
	for stream: int in Model.STREAMS:
		var values: Array = []
		for step: int in Model.STEPS: values.append(Model.input(stream, step))
		rows.append({"stream": stream, "initial": Model.initial(stream), "inputs": values})
	text.text = tr2("h'=Q(0.65h+0.35x), score=w·h'；请求4周期，链路4B/周期；每次24运算。\n初态已在外存（离线制备）；32位模式不舍入；低精度初态和每次更新均舍入到[-1,1]均匀网格。\n", "h'=Q(0.65h+0.35x), score=w·h'; request 4 cycles, link 4B/cycle; 24 operations each.\nInitial contexts already in backing memory (offline preparation). 32-bit mode unrounded; lower precision rounds initial and every update on uniform [-1,1] grid.\n") + JSON.stringify({"weights": Model.Linear.WEIGHTS, "streams": rows, "reference": Model.reference_result()}, "  ")
	public_window.popup_centered()
