extends Control
## Editable plan presenter. Never supplies authoritative numerical results.
const Model = preload("res://experiments/service_plan/model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
var plan: Dictionary = Model.initial_plan()
var history: Array[Dictionary] = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var english: bool = false
var task: int = 0
var unlocked: int = 0
var hint_open: bool = false
var selected_group: int = 0
var selected_history: int = -1
var active_trace: Trace
var group_list: ItemList
var history_list: ItemList
var split_at: SpinBox
var move_to: SpinBox
var move_button: Button
var slots: SpinBox
var format_buttons: Array[Button] = []
var task_buttons: Array[Button] = []
var run_button: Button
var language_button: Button
var undo_button: Button
var redo_button: Button
var merge_button: Button
var split_button: Button
var up_button: Button
var down_button: Button
var hint_button: Button
var data_button: Button
var restore_button: Button
var mission: Label
var status: Label
var summary: Label
var detail: RichTextLabel
var tree: Tree

func tr2(zh: String, en: String) -> String: return en if english else zh
func _ready() -> void:
	theme = Theme.new(); InstrumentTheme.apply_to(theme)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
	build()

func label(text: String, parent: Node, size: int = 15) -> Label:
	var node := Label.new(); node.text = text; node.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", size); parent.add_child(node); return node
func button(text: String, parent: Node, action: Callable, id: String = "") -> Button:
	var node := Button.new(); node.text = text; node.name = id if not id.is_empty() else "Action"
	node.custom_minimum_size.y = 32; node.pressed.connect(action); parent.add_child(node); return node

func mission_text() -> String:
	var common: String = tr2("4条流×6次请求；同流保序，每组输入先到、整组算完再响应。脏淘汰和最终flush必须写回。\n", "4 streams × 6 requests; preserve each stream's order. Read group inputs, compute whole group, then respond. Dirty eviction and final flush write back.\n")
	var goals: Array[String] = [tr2("1 · 少搬状态：总≤1420周期，状态读写≤600B，峰值≤350B；分数/最终状态必须精确。", "1 · Move less state: total≤1420 cycles, state reads+writes≤600B, peak≤350B; exact scores/final states."), tr2("2 · 及时服务：总≤1420周期，每流首响应≤320周期；分数/最终状态必须精确。", "2 · Prompt service: total≤1420 cycles, every stream first response≤320; exact scores/final states."), tr2("3 · 同一服务方案：总≤1420，首响应≤320，状态读写≤320B；分数/最终状态误差≤0.02。", "3 · One service plan: total≤1420, first responses≤320, state reads+writes≤320B; score/final-state errors≤0.02.")]
	return common + goals[task] + tr2("\n硬容量512B；decoded状态64B/流，权重64B，最大组72B/项，另计真实编码临时空间。", "\nHard512B: decoded contexts64B/stream, weights64B, largest group72B/request, plus actual encoded temporary bytes.")

func hint_text() -> String:
	return tr2("Hint1 · 查看state_read/write是否同流反复出现，以及D的首响应。合组会省请求，但整组算完才返回。A/B每维相同，C/D每维变化；对照encoded字节和codec费用再选表示。", "Hint1 · Inspect repeated state reads/writes and D's first response. Merging saves setup, but delays responses until the group completes. A/B repeat coordinates; C/D vary. Compare actual encoded bytes and codec costs before choosing storage.")

func build() -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	format_buttons.clear(); task_buttons.clear()
	var background := ColorRect.new(); background.color = Color("0b1720"); background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(background)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 12)
	add_child(margin); var page := VBoxContainer.new(); page.add_theme_constant_override("separation", 6); margin.add_child(page)
	var header := HBoxContainer.new(); page.add_child(header)
	var title := label(tr2("服务方案 · 谁先得到下一次结果？", "Service plan · Who gets the next result?"), header, 22); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	language_button = button("中文 / EN", header, func() -> void: english = not english; build(), "Language")
	button(tr2("退出", "Quit"), header, func() -> void: get_tree().quit(), "Quit")
	var stages := HBoxContainer.new(); page.add_child(stages)
	for index: int in 3:
		var node: Button = button(tr2("任务%d" % (index + 1), "Task%d" % (index + 1)), stages, func() -> void: task = index; build(), "Task%d" % (index + 1))
		node.disabled = index > unlocked; task_buttons.append(node)
	hint_button = button(tr2("看一个线索", "A clue"), stages, func() -> void: hint_open = not hint_open; refresh_mission(), "Hint1")
	data_button = button(tr2("公开数据 / 成本", "Public data / costs"), stages, show_public_data, "PublicData")
	mission = label("", page, 14); refresh_mission()
	status = label(tr2("构造组和顺序，选择逐流表示，再测量。实验进度只在内存。", "Construct groups/order and per-stream storage, then measure. Lab progress is session-only."), page, 14)
	var body := HBoxContainer.new(); body.size_flags_vertical = Control.SIZE_EXPAND_FILL; body.add_theme_constant_override("separation", 14); page.add_child(body)
	var editor := VBoxContainer.new(); editor.custom_minimum_size.x = 430; body.add_child(editor)
	label(tr2("服务组（可拖动）· 从上到下执行", "Drag service groups · execute top to bottom"), editor)
	group_list = preload("res://experiments/service_plan/group_list.gd").new(); group_list.name = "Groups"; group_list.size_flags_vertical = Control.SIZE_EXPAND_FILL; group_list.custom_minimum_size.y = 100; editor.add_child(group_list)
	group_list.tooltip_text = tr2("可将整组拖到目标行；移动后仍需运行核验同流保序。", "Drag a whole group onto its target row; Run still validates stream order.")
	group_list.group_moved.connect(func(source: int, target: int) -> void: edit(Model.move(plan,source,target-source),target))
	group_list.item_selected.connect(func(index: int) -> void: selected_group = index; refresh_actions())
	var motion := HBoxContainer.new(); editor.add_child(motion)
	up_button = button(tr2("上移", "Move up"), motion, func() -> void: edit(Model.move(plan, selected_group, -1), selected_group - 1), "MoveUp")
	down_button = button(tr2("下移", "Move down"), motion, func() -> void: edit(Model.move(plan, selected_group, 1), selected_group + 1), "MoveDown")
	merge_button = button(tr2("合并下一组", "Join next"), motion, func() -> void: edit(Model.merge(plan, selected_group), selected_group), "Merge")
	var destination := HBoxContainer.new(); editor.add_child(destination)
	label(tr2("移到第几组", "Move to group"), destination, 14)
	move_to = SpinBox.new(); move_to.name = "MoveTarget"; move_to.min_value = 1; move_to.max_value = plan.groups.size(); move_to.value = 1; destination.add_child(move_to)
	move_button = button(tr2("移动整组", "Move group"), destination, func() -> void: edit(Model.move(plan, selected_group, int(move_to.value) - 1 - selected_group), int(move_to.value) - 1), "MoveTo")
	var splits := HBoxContainer.new(); editor.add_child(splits)
	label(tr2("第几项后拆", "Split after item"), splits, 14)
	split_at = SpinBox.new(); split_at.name = "SplitBoundary"; split_at.min_value = 1; split_at.max_value = 23; split_at.value = 1; splits.add_child(split_at)
	split_button = button(tr2("拆成两组", "Split group"), splits, func() -> void: edit(Model.split(plan, selected_group, int(split_at.value)), selected_group), "Split")
	var capacity := HBoxContainer.new(); editor.add_child(capacity)
	label(tr2("自动LRU状态槽", "Automatic LRU slots"), capacity)
	slots = SpinBox.new(); slots.name = "Slots"; slots.min_value = 1; slots.max_value = 4; slots.value = plan.slots; capacity.add_child(slots)
	slots.value_changed.connect(func(value: float) -> void:
		var next: Dictionary = plan.duplicate(true); next.slots = int(value); edit(next, selected_group))
	label(tr2("逐流存储 · 点击切换RAW64→RLE64→RAW8→RLE8", "Storage per stream · click RAW64→RLE64→RAW8→RLE8"), editor, 13)
	var formats := HBoxContainer.new(); editor.add_child(formats)
	for stream: int in 4:
		var format: Button = button("", formats, func() -> void:
			var current: int = Model.REPRESENTATIONS.find(plan.representations[stream]); edit(Model.represent(plan, stream, Model.REPRESENTATIONS[(current + 1) % 4]), selected_group), "Format" + char(65 + stream))
		format.size_flags_horizontal = Control.SIZE_EXPAND_FILL; format_buttons.append(format)
	var actions := HBoxContainer.new(); editor.add_child(actions)
	undo_button = button(tr2("撤销", "Undo"), actions, undo, "Undo")
	redo_button = button(tr2("重做", "Redo"), actions, redo, "Redo")
	run_button = button(tr2("运行并记录", "Run and record"), actions, run_current, "Run")
	InstrumentTheme.primary(run_button,Color("50d5ff"))
	var evidence := VBoxContainer.new(); evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence)
	var history_header := HBoxContainer.new(); evidence.add_child(history_header)
	label(tr2("实测历史 · 不随草稿改变", "Measured history · independent of drafts"), history_header).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restore_button = button(tr2("恢复为草稿", "Restore draft"), history_header, restore_history, "Restore")
	history_list = ItemList.new(); history_list.name = "History"; history_list.custom_minimum_size.y = 64; evidence.add_child(history_list); history_list.item_selected.connect(select_run)
	summary = label(tr2("尚未运行。所有目标公开；数值从实际Trace产生。", "No measured run yet. Goals are public; results come from actual Trace."), evidence, 14)
	tree = Tree.new(); tree.name = "Trace"; tree.columns = 3; tree.column_titles_visible = true; tree.hide_root = true
	tree.set_column_title(0, tr2("周期", "Cycle")); tree.set_column_title(1, tr2("费用", "Cost")); tree.set_column_title(2, tr2("事件", "Event")); tree.size_flags_vertical = Control.SIZE_EXPAND_FILL; tree.custom_minimum_size.y = 80; evidence.add_child(tree)
	tree.item_selected.connect(func() -> void:
		var item: TreeItem = tree.get_selected()
		if item != null: detail.text = JSON.stringify(item.get_metadata(0), "  "))
	detail = RichTextLabel.new(); detail.name = "Details"; detail.custom_minimum_size.y = 110; detail.scroll_active = true; evidence.add_child(detail)
	refresh_groups(); refresh_history(); refresh_actions()
	if selected_history >= 0 and selected_history < history.size(): history_list.select(selected_history); select_run(selected_history)

func refresh_mission() -> void: mission.text = mission_text() + ("\n" + hint_text() if hint_open else "")
func refresh_groups() -> void:
	group_list.clear()
	for index: int in plan.groups.size():
		var tokens: PackedStringArray = []
		for id: int in plan.groups[index]: tokens.append(char(65 + id / 6) + str(id % 6))
		group_list.add_item("%02d   [ %s ]" % [index + 1, "  ".join(tokens)])
	selected_group = clampi(selected_group, 0, plan.groups.size() - 1); group_list.select(selected_group); group_list.ensure_current_is_visible()
	move_to.max_value = plan.groups.size()
	for stream: int in 4: format_buttons[stream].text = char(65 + stream) + ": " + str(plan.representations[stream]).to_upper()
func refresh_actions() -> void:
	up_button.disabled = selected_group == 0; down_button.disabled = selected_group == plan.groups.size() - 1
	merge_button.disabled = down_button.disabled; split_button.disabled = plan.groups[selected_group].size() < 2
	undo_button.disabled = undo_stack.is_empty(); redo_button.disabled = redo_stack.is_empty(); restore_button.disabled = selected_history < 0
func edit(next: Dictionary, selection: int) -> void:
	if next == plan: return
	undo_stack.append(plan.duplicate(true)); redo_stack.clear(); plan = next.duplicate(true); selected_group = selection
	refresh_groups(); refresh_actions(); status.text = tr2("草稿已改；历史不变。运行时核验同流保序和512B容量。", "Draft changed; history preserved. Run validates stream dependencies and512B scratch.")
func undo() -> void:
	if undo_stack.is_empty(): return
	redo_stack.append(plan.duplicate(true)); plan = undo_stack.pop_back(); slots.set_value_no_signal(plan.slots); refresh_groups(); refresh_actions()
func redo() -> void:
	if redo_stack.is_empty(): return
	undo_stack.append(plan.duplicate(true)); plan = redo_stack.pop_back(); slots.set_value_no_signal(plan.slots); refresh_groups(); refresh_actions()
func run_current() -> void:
	active_trace = Model.run(plan); var events: Array[Dictionary] = []
	for event: RefCounted in active_trace.events: events.append(event.to_dictionary().duplicate(true))
	history.append({"task": task, "metrics": active_trace.metrics.duplicate(true), "events": events, "signature": active_trace.canonical_signature()})
	if history.size() > 80: history.pop_front()
	selected_history = history.size() - 1
	if Model.accepted(active_trace.metrics, task): unlocked = maxi(unlocked, mini(task + 1, 2))
	for index: int in 3: task_buttons[index].disabled = index > unlocked
	refresh_history(); history_list.select(selected_history); history_list.call_deferred("ensure_current_is_visible"); select_run(selected_history); refresh_actions()
func refresh_history() -> void:
	history_list.clear()
	for index: int in history.size():
		var m: Dictionary = history[index].metrics
		history_list.add_item("%d · T%d · %dcyc · state%dB · first%s" % [index + 1, history[index].task + 1, m.total_cycles, m.state_read_bytes + m.state_write_bytes, str(m.first_stream_cycles)])
func measured_feedback(metrics: Dictionary, contract: int) -> String:
	if contract < 0 or contract > 2: return tr2("未知任务。", "Unknown task.")
	if not str(metrics.error).is_empty(): return tr2("拒绝：", "Rejected: ")+str(metrics.error)
	if Model.accepted(metrics,contract): return tr2("当前任务约束成立；可以继续比较自己的其他方案。", "Current task limits met; keep comparing your own alternatives.")
	var failures: Array[String] = []
	var budgets: Array[Dictionary] = [{"name":tr2("总周期", "Total cycles"),"actual":int(metrics.total_cycles),"limit":1420}]
	if contract == 0:
		budgets.append({"name":tr2("峰值空间B", "Peak space B"),"actual":int(metrics.peak_bytes),"limit":350})
	if contract != 1:
		budgets.append({"name":tr2("状态读写B", "State traffic B"),"actual":int(metrics.state_read_bytes)+int(metrics.state_write_bytes),"limit":600 if contract == 0 else 320})
	if contract > 0:
		budgets.append({"name":tr2("最晚首响应周期", "Latest first response"),"actual":int(metrics.all_streams_first_cycle),"limit":320})
	for budget: Dictionary in budgets:
		if budget.actual > budget.limit: failures.append(tr2("%s %d / 上限%d，超出%d", "%s %d / limit%d, over by%d") % [budget.name,budget.actual,budget.limit,budget.actual-budget.limit])
	var tolerance: float = 0.02 if contract == 2 else 0.000000001
	for key: String in ["max_error","max_state_error"]:
		if float(metrics[key]) > tolerance:
			var name: String = tr2("分数误差", "Score error") if key == "max_error" else tr2("最终状态误差", "Final-state error")
			failures.append(name+" "+String.num_scientific(float(metrics[key]))+" / "+String.num_scientific(tolerance))
	return " · ".join(failures) if not failures.is_empty() else tr2("证据未满足当前任务。", "Evidence does not meet this task.")

func select_run(index: int) -> void:
	selected_history = index; var record: Dictionary = history[index]; var m: Dictionary = record.metrics
	status.text = measured_feedback(m,task)
	summary.text = tr2("总%d周期 · 全部%dB · 状态读写%dB · 峰值%dB\n费用 请求%d / 搬运%d / 运算%d / 提交%d / 编码%d\nA/B/C/D首响应%s · 读%d / 写%d (flush%d)\n分数误差%.6f · 最终状态误差%.6f · 外存%d→%dB", "Total%dcyc · all%dB · state%dB · peak%dB\nCosts request%d / transfer%d / compute%d / commit%d / codec%d\nA/B/C/D first%s · reads%d / writes%d (flush%d)\nScore error%.6f · state error%.6f · backing%d→%dB") % [m.total_cycles, m.traffic_bytes, m.state_read_bytes + m.state_write_bytes, m.peak_bytes, m.request_cycles, m.transfer_cycles, m.compute_cycles, m.commit_cycles, m.codec_cycles, str(m.first_stream_cycles), m.state_reads, m.state_writes, m.flush_writes, m.max_error, m.max_state_error, m.initial_backing_bytes, m.final_backing_bytes]
	tree.clear(); var root_item: TreeItem = tree.create_item()
	for event: Dictionary in record.events:
		var row: TreeItem = tree.create_item(root_item); row.set_text(0, str(event.cycle)); row.set_text(1, str(event.duration)); row.set_text(2, event.kind); row.set_metadata(0, event.details.duplicate(true))
	detail.text = JSON.stringify({"plan": m.plan, "final_states": m.final_states}, "  "); refresh_actions()
func restore_history() -> void:
	if selected_history < 0: return
	edit(history[selected_history].metrics.plan.duplicate(true), 0); slots.set_value_no_signal(plan.slots)
func show_public_data() -> void:
	var streams: Array = []
	for stream: int in 4:
		var values: Array = []
		for step: int in 6: values.append(Model.input(stream, step))
		streams.append({"stream": char(65 + stream), "initial": Model.initial(stream), "inputs": values})
	detail.text = tr2("每请求24运算；链路4B/周期，请求4周期；pack/unpack 8ops，RLE另加8值+run数；RLE64以8字节整值为run，RLE8以字节为run，8ops/周期。Q8每次更新另8ops。RAW64无损；Q8真实舍入。\n", "24ops/request; link4B/cycle, setup4cycles; pack/unpack8ops, RLE adds8values+run count; RLE64 runs8byte values, RLE8 runsbytes at8ops/cycle. Q8 adds8rounding ops/update. RAW64 lossless; Q8 actual rounding.\n") + JSON.stringify({"streams": streams, "weights": Model.WEIGHTS}, "  ")
func public_observation() -> Dictionary:
	var public_data: Array = []
	for stream: int in 4:
		var inputs: Array = []
		for step: int in 6: inputs.append({"id": stream * 6 + step, "token": char(65 + stream) + str(step), "values": Model.input(stream, step)})
		public_data.append({"stream": char(65 + stream), "initial": Model.initial(stream), "requests": inputs})
	var observations: Array = []
	for record: Dictionary in history:
		var m: Dictionary = record.metrics
		observations.append({"task": record.task, "plan": m.plan.duplicate(true), "metrics": m.duplicate(true), "trace": record.events.duplicate(true)})
	return {"mission": mission_text(), "hint1": hint_text(), "public_data": public_data, "weights": Model.WEIGHTS.duplicate(), "task": task, "unlocked": unlocked, "draft": plan.duplicate(true), "selected_group": selected_group, "formats": Model.REPRESENTATIONS.duplicate(), "streams": [{"name": "A", "coordinates": "repeated"}, {"name": "B", "coordinates": "repeated"}, {"name": "C", "coordinates": "varied"}, {"name": "D", "coordinates": "varied"}], "rules": {"stream_steps": 6, "all_ready": 0, "link_bytes_per_cycle": 4, "setup_cycles": 4, "decoded_context_bytes": 64, "scratch_bytes": 512, "compute_ops": 24}, "measured": observations, "actions": ["select_group", "merge", "split", "move_up", "move_down", "move_to", "set_slots", "cycle_format", "undo", "redo", "run", "restore", "task", "hint", "data"]}
