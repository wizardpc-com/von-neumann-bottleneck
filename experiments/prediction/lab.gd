extends Control
## Session-only evidence viewer. Full hidden stream never enters public_observation.
const Model = preload("res://experiments/prediction/model.gd")
const Catalog = preload("res://experiments/prediction/catalog.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
var english: bool = false
var task: int = 0
var policy: Dictionary = Model.default_policy()
var history: Array[Dictionary] = []
var active_trace: Trace
var active_policy: Dictionary = {}
var revealed: int = 0
var selected_run: int = -1
var rule: OptionButton
var confidence: OptionButton
var lookahead: OptionButton
var cooldown: OptionButton
var history_list: ItemList
var events: Tree
var details: RichTextLabel
var result: Label
var observed: Label
var status: Label
var mission: Label
var step_button: Button

func _ready() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english = true
	build()

func text2(zh: String, en: String) -> String: return en if english else zh

func label(text: String, parent: Node, size: int = 15) -> Label:
	var item := Label.new(); item.text = text; item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",size); parent.add_child(item); return item

func button(text: String, handle: String, parent: Node, action: Callable) -> Button:
	var item := Button.new(); item.name = handle; item.text = text
	item.custom_minimum_size.y = 36; item.pressed.connect(action); parent.add_child(item); return item

func choice(text: String, handle: String, values: Array[String], selected: int, parent: Node) -> OptionButton:
	var box := HBoxContainer.new(); parent.add_child(box)
	var caption: Label = label(text,box); caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var item := OptionButton.new(); item.name = handle; item.custom_minimum_size.x = 195
	for value: String in values: item.add_item(value)
	item.select(selected); box.add_child(item); item.item_selected.connect(func(_index: int) -> void: edit_policy())
	return item

func build() -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	var bg := ColorRect.new(); bg.color = Color("0b1720"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var scroll := ScrollContainer.new(); scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(scroll)
	var margin := MarginContainer.new(); margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for edge: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+edge,14)
	scroll.add_child(margin)
	var page := VBoxContainer.new(); page.size_flags_horizontal = Control.SIZE_EXPAND_FILL; page.add_theme_constant_override("separation",8); margin.add_child(page)
	var top := HBoxContainer.new(); page.add_child(top)
	var title: Label = label(text2("预测工坊 · 从已知历史承担猜测","Prediction workshop · Guess from observed history"),top,24); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("中文 / EN","Language",top,func() -> void: english = not english; build())
	button(text2("退出","Quit"),"Quit",top,func() -> void: get_tree().quit())
	label(text2("隔离实验 · 不保存主线进度 · 未知下一地址 · 所有周期是公开教学模型","Isolated experiment · no campaign saves · next address is unknown · all cycles are teaching model units"),page,13)
	var nav := HBoxContainer.new(); page.add_child(nav)
	for i: int in 3:
		var item: Button = button([text2("1 · 规律流","1 · Regular stream"),text2("2 · 规律改变","2 · Pattern changes"),text2("3 · 交替热点","3 · Alternating hotspots")][i],"Task"+str(i),nav,func() -> void: change_task(i))
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission = label(mission_text(),page,15); mission.name = "Mission"
	button(text2("Hint1 · 看证据","Hint1 · Inspect evidence"),"Hint1",page,func() -> void: status.text = hint_text())
	var body := HBoxContainer.new(); body.add_theme_constant_override("separation",16); page.add_child(body)
	var editor := VBoxContainer.new(); editor.custom_minimum_size.x = 350; editor.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(editor)
	label(text2("构造历史规则（最多保留8个真实请求）","Construct a history rule (last 8 actual demands)"),editor,18)
	rule = choice(text2("规则","Rule"),"Rule",[text2("关闭猜测","Off"),text2("最近步长","Last stride"),text2("双步长循环","Two-stride cycle")],["off","stride","two_stride"].find(str(policy.rule)),editor)
	confidence = choice(text2("所需重复次数","Required repetitions"),"Confidence",["1","2","3"],int(policy.confidence)-1,editor)
	lookahead = choice(text2("预测步长倍数","Stride multiplier"),"Lookahead",["1","2"],int(policy.lookahead)-1,editor)
	cooldown = choice(text2("错猜后暂停请求数","Pause after mismatch"),"Cooldown",["0","2"],0 if int(policy.cooldown)==0 else 1,editor)
	label(text2("最近步长需要至少2个历史点；双步长至少3个。重复次数检验尾部差值模式。倍数改变猜测距离；错猜暂停抑制接下来的猜测。","Last stride needs 2 history points; two-stride needs 3. Repetitions check the trailing delta pattern. Multiplier changes guessed distance; mismatch pause suppresses subsequent guesses."),editor,13)
	label(text2("机器：2槽×4B自动LRU。每请求4周期+搬运2周期；查找1周期；每次真实消费后计算8周期。单总线不可抢占，预测与计算重叠；错误在途请求会阻塞回退。尾部请求必须完成。","Machine: automatic LRU, 2 slots ×4B. Each request costs 4+2 transfer cycles; lookup1; compute8 after each demand. One non-preemptive bus overlaps prediction with compute. Wrong in-flight work blocks fallback; final work must drain."),editor,13)
	var actions := HBoxContainer.new(); editor.add_child(actions)
	step_button = button(text2("揭示下一请求","Reveal next demand"),"Step",actions,step_current)
	button(text2("运行到结束","Run to end"),"Run",actions,run_current)
	button(text2("新一轮","New run"),"Restart",actions,restart)
	observed = label("",editor,15); observed.name = "ObservedHistory"
	status = label("",editor,14); status.name = "Status"
	var evidence := VBoxContainer.new(); evidence.custom_minimum_size.x = 420; evidence.size_flags_horizontal = Control.SIZE_EXPAND_FILL; body.add_child(evidence)
	label(text2("不可变完成记录（编辑规则不会改写旧记录）","Immutable completed runs (edits preserve older receipts)"),evidence,18)
	history_list = ItemList.new(); history_list.name = "History"; history_list.custom_minimum_size.y = 80; evidence.add_child(history_list); history_list.item_selected.connect(select_run)
	result = label("",evidence,14); result.name = "Result"
	events = Tree.new(); events.name = "Events"; events.columns = 3; events.hide_root = true; events.column_titles_visible = true; events.custom_minimum_size.y = 180
	for i: int in 3: events.set_column_title(i,[text2("起点","Start"),text2("时长","Duration"),text2("证据事件","Evidence event")][i])
	evidence.add_child(events)
	details = RichTextLabel.new(); details.name = "TraceDetails"; details.custom_minimum_size.y = 150; evidence.add_child(details)
	events.item_selected.connect(func() -> void:
		var row: TreeItem = events.get_selected()
		if row != null: details.text = event_text(row.get_metadata(0)))
	refresh_history(); refresh()

func mission_text() -> String:
	return [text2("实验1：先记录关闭猜测的基线，再构造一个总周期更低且确实消费了预测数据的方案。逐步揭示历史，再比较等待与流量。","Investigation1: record an Off baseline, then construct a faster rule whose predicted data is actually consumed. Reveal history and compare waiting with traffic."),
	text2("实验2：相同机器，流会改变。记录一个比关闭猜测更慢且有浪费/污染的规则，再修改规则找到不慢于基线的方案。失败也是证据。","Investigation2: same machine, changing stream. Record a rule slower than Off with waste/pollution, then revise it to run no slower than baseline. Failure is evidence."),
	text2("实验3：两个热点交替。比较至少两种不同规则，找到一份错猜造成额外成本的记录和一份不慢于基线的记录。观察有限缓存里发生了什么。","Investigation3: two alternating hotspots. Compare at least two different rules: one with extra costs from wrong guesses, one no slower than baseline. Inspect the finite cache.")][task]

func hint_text() -> String:
	return text2("只比较已观察的地址差值。先留一份关闭猜测记录；在Trace中核对预测发出时的历史、下一次真实请求、在途等待、驱逐与未被使用的搬运。一次变动一个规则条件。","Compare only observed address differences. Keep an Off receipt; inspect the prediction's history, next actual demand, in-flight wait, evictions and unused traffic. Change one rule condition at a time.")

func edit_policy() -> void:
	policy = {"rule":["off","stride","two_stride"][rule.selected],"confidence":confidence.selected+1,"lookahead":lookahead.selected+1,"cooldown":0 if cooldown.selected==0 else 2}
	restart()

func change_task(index: int) -> void:
	task = index; active_trace = null; revealed = 0; selected_run = -1; build()

func restart() -> void:
	active_trace = null; active_policy = {}; revealed = 0; selected_run = -1; refresh()

func _ensure_run() -> void:
	if active_trace != null and revealed < active_trace.metrics.accesses.size() and selected_run < 0: return
	active_policy = policy.duplicate(true); active_trace = Model.run(Catalog.scenario(task),active_policy)
	revealed = 0; selected_run = -1

func step_current() -> void:
	_ensure_run(); revealed += 1
	if revealed == active_trace.metrics.accesses.size(): _record()
	refresh()

func run_current() -> void:
	_ensure_run(); revealed = active_trace.metrics.accesses.size(); _record(); refresh()

func _record() -> void:
	history.append({"task":task,"policy":active_policy.duplicate(true),"trace":active_trace})
	selected_run = history.size()-1; refresh_history()

func refresh_history() -> void:
	history_list.clear()
	for i: int in history.size():
		var row: Dictionary = history[i]
		history_list.add_item("#%d · %d · %s/%d/×%d/pause%d · %d cycles" % [i+1,int(row.task)+1,row.policy.rule,row.policy.confidence,row.policy.lookahead,row.policy.cooldown,row.trace.metrics.total_cycles])
	if selected_run >= 0:
		history_list.select(selected_run)
		history_list.call_deferred("ensure_current_is_visible")

func select_run(index: int) -> void:
	selected_run = index; active_trace = history[index].trace; active_policy = history[index].policy.duplicate(true)
	revealed = active_trace.metrics.accesses.size(); refresh()

func goal_met(index: int) -> bool:
	var baseline: bool = false; var gain: bool = false; var failure: bool = false; var safe: bool = false
	var rules: Dictionary = {}
	for row: Dictionary in history:
		if int(row.task) != index: continue
		var m: Dictionary = row.trace.metrics
		rules[str(row.policy.rule)] = true
		baseline = baseline or str(row.policy.rule)=="off"
		gain = gain or (int(m.total_cycles)<int(m.baseline_cycles) and int(m.useful_prediction_bytes)>0)
		failure = failure or (int(m.total_cycles)>int(m.baseline_cycles) and (int(m.wasted_prediction_bytes)>0 or int(m.pollution_misses)>0))
		safe = safe or (str(row.policy.rule)!="off" and int(m.total_cycles)<=int(m.baseline_cycles))
	if index==0: return baseline and gain
	return failure and safe and (index==1 or rules.size()>=2)

func event_text(event: Event) -> String:
	return "%s · t%d +%d · address%d\n%s" % [event.kind,event.cycle,event.duration,event.address,JSON.stringify(event.details,"  ")]

func refresh() -> void:
	mission.text = mission_text()
	events.clear(); var root: TreeItem = events.create_item()
	result.text = text2("完成运行后才显示总成本与独立基线。","Full costs and independent baseline appear only after the run finishes.")
	observed.text = text2("尚无真实请求。下一地址未知。","No demands observed. Next address unknown.")
	details.text = text2("选择已揭示事件，核对历史与实际成本。","Select a revealed event to inspect history and actual costs.")
	if active_trace != null:
		var addresses: Array[int] = []
		for i: int in revealed: addresses.append(int(active_trace.metrics.accesses[i].address))
		observed.text = text2("已观察请求：%s\n下一地址：未知", "Observed demands: %s\nNext address: unknown") % str(addresses)
		if revealed > 0:
			var d: Dictionary = active_trace.metrics.decisions[revealed-1]
			observed.text += text2("\n历史%s → 猜测%s · %s", "\nHistory%s → guess%s · %s") % [str(d.history),str(d.guess) if int(d.guess)>=0 else text2("无","none"),d.reason]
		var finished: bool = revealed == active_trace.metrics.accesses.size()
		for event: Event in active_trace.events:
			if int(event.details.step)>revealed and not finished: continue
			var row: TreeItem = events.create_item(root)
			row.set_text(0,str(event.cycle)); row.set_text(1,str(event.duration)); row.set_text(2,"%s · %d" % [event.kind,event.address]); row.set_metadata(0,event)
		if finished:
			var m: Dictionary = active_trace.metrics
			observed.text = observed.text.replace(text2("下一地址：未知","Next address: unknown"),text2("本轮结束","Run ended"))
			result.text = text2("总%d = 查找%d + 计算%d + 阻塞%d + 尾部%d\n基线%d周期/%dB · 实际%dB；预测有用%dB/浪费%dB\n回退%d · 排队%d · 在途匹配等待%d · 污染miss%d\n输出%s", "Total%d = lookup%d + compute%d + blocking%d + drain%d\nBaseline%d cycles/%dB · actual%dB; useful%dB/wasted%dB predictions\nFallback%d · queue%d · matching in-flight wait%d · pollution misses%d\nOutputs%s") % [m.total_cycles,m.lookup_cycles,m.compute_cycles,m.blocking_cycles,m.drain_cycles,m.baseline_cycles,m.baseline_traffic_bytes,m.traffic_bytes,m.useful_prediction_bytes,m.wasted_prediction_bytes,m.fallback_cycles,m.queue_wait_cycles,m.inflight_wait_cycles,m.pollution_misses,str(m.outputs)]
	status.text = text2("证据目标已满足；可继续比较其他方案。","Evidence objective met; continue comparing alternatives.") if goal_met(task) else text2("记录基线、失败和修改后的规则；三个流都可自由实验。","Record baseline, failure and a revised rule; all three streams are open.")

func public_observation() -> Dictionary:
	var observed_addresses: Array[int] = []; var decisions: Array[Dictionary] = []; var measured: Array[Dictionary] = []
	if active_trace != null:
		for i: int in revealed:
			observed_addresses.append(int(active_trace.metrics.accesses[i].address))
			decisions.append(active_trace.metrics.decisions[i].duplicate(true))
	for row: Dictionary in history:
		measured.append({"task":row.task,"policy":row.policy.duplicate(true),"metrics":row.trace.metrics.duplicate(true)})
	return {"task":task,"mission":mission_text(),"hint1":hint_text(),"policy":policy.duplicate(true),"control_ranges":{"rule":["off","stride","two_stride"],"confidence":[1,2,3],"lookahead":[1,2],"cooldown":[0,2]},"observed_addresses":observed_addresses,"revealed_decisions":decisions,"completed_runs":measured,"goal_met":goal_met(task)}
