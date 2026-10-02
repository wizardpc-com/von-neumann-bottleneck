extends Control
## Read-only Trace presentation plus local experiment choices; no campaign calls.
const Model = preload("res://experiments/representation/model.gd")
const Inference = preload("res://experiments/intelligent_workload/model.gd")
const Trace = preload("res://src/simulation/simulation_trace.gd")
@export var intelligent: bool = false
var english: bool = false
var stage: int = 0
var order: int = 0
var history: Array[Dictionary] = []
var completed: Array[bool] = [false,false,false]
var codec: OptionButton
var block: OptionButton
var cache: OptionButton
var case_choice: OptionButton
var run_button: Button
var next_button: Button
var mission: Label
var data_label: Label
var status: Label
var summary: Label
var history_list: ItemList
var tree: Tree
var detail: RichTextLabel
var active_trace: Trace
var stage_buttons: Array[Button] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for arg: String in OS.get_cmdline_user_args():
		if arg == "--locale=en": english=true
	build()

func tr2(zh: String,en: String) -> String: return en if english else zh

func label(text: String,parent: Node,size: int = 17) -> Label:
	var node := Label.new(); node.text=text; node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size",size); parent.add_child(node); return node

func button(text: String,parent: Node,action: Callable) -> Button:
	var node := Button.new(); node.text=text; node.custom_minimum_size.y=42
	node.pressed.connect(action); parent.add_child(node); return node

func option(text: String,items: Array[String],parent: Node) -> OptionButton:
	label(text,parent)
	var node := OptionButton.new(); node.custom_minimum_size.y=38
	for item: String in items: node.add_item(item)
	parent.add_child(node); node.item_selected.connect(func(_i: int) -> void: invalidate())
	return node

func build() -> void:
	for child: Node in get_children(): remove_child(child); child.queue_free()
	stage_buttons.clear()
	var bg := ColorRect.new(); bg.color=Color("0b1720"); bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	var margin := MarginContainer.new(); margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,18)
	add_child(margin)
	var page := VBoxContainer.new(); page.add_theme_constant_override("separation",12); margin.add_child(page)
	var header := HBoxContainer.new(); page.add_child(header)
	var title := label(tr2("表示实验室 · 少搬，还是多算？","Representation lab · Carry less, compute more?") if not intelligent else tr2("隐藏实验 · 推理也要搬运","Hidden experiment · Inference has a memory bill"),header,25)
	title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	button("中文 / EN",header,func() -> void: english=not english; build())
	button(tr2("退出实验","Quit lab"),header,func() -> void: get_tree().quit())
	label(tr2("隔离原型 · 不计入主线进度 · 模拟周期不是实机测速","Isolated prototype · no campaign progress · model cycles, not measured hardware"),page,14)
	if not intelligent:
		var nav := HBoxContainer.new(); page.add_child(nav)
		for i: int in 3:
			var b := button([tr2("1 · 表示的代价","1 · Cost of representation"),tr2("2 · 换一台机器","2 · Change the machine"),tr2("3 · 只问两处","3 · Ask for two values")][i],nav,func() -> void: stage=i; order=0; build())
			b.disabled=i>0 and not completed[i-1]; b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; stage_buttons.append(b)
	var top := HBoxContainer.new(); page.add_child(top)
	var brief := VBoxContainer.new(); brief.size_flags_horizontal=Control.SIZE_EXPAND_FILL; top.add_child(brief)
	mission=label(mission_text(),brief,18)
	data_label=label("",brief,14)
	var choices := VBoxContainer.new(); choices.custom_minimum_size.x=330; top.add_child(choices)
	if intelligent:
		codec=option(tr2("权重精度（相同 MAC 吞吐）","Weight precision (same MAC throughput)"),["32-bit","8-bit","4-bit","2-bit"],choices)
		block=option(tr2("一批输入数","Inputs per batch"),["1","4","8"],choices)
		cache=option(tr2("权重驻留","Weight residency"),[tr2("每批重新读取","Reload each batch"),tr2("保留权重","Keep weights resident")],choices)
	else:
		var names: Array[String]=[tr2("重复数据 · 慢链路","Runs · slow link")]
		if stage == 1: names.append_array([tr2("重复数据 · 快链路慢解码","Runs · fast link, slow decoder"),tr2("变化数据 · 慢链路","Varied bytes · slow link")])
		if stage == 2: names=[tr2("订单 A · 扫描","Order A · scan"),tr2("订单 B · 点读 0、32","Order B · read 0 and 32")]
		case_choice=option(tr2("工作负载","Workload"),names,choices); case_choice.selected=order
		case_choice.item_selected.connect(func(i: int) -> void: order=i; update_data())
		codec=option(tr2("存储表示","Stored representation"),[tr2("原始字节","Raw bytes"),"RLE"],choices)
		block=option(tr2("独立块（字节）","Independent block (bytes)"),["4","16","64"],choices); block.selected=2
		cache=option(tr2("解码块缓存（LRU）","Decoded-block cache (LRU)"),["1","2"],choices)
	run_button=button(tr2("运行并记下证据","Run and record evidence"),choices,run_current)
	status=label(tr2("先运行当前方案，观察费用分解。","Run the current design and inspect the cost breakdown."),page,16)
	var bottom := HSplitContainer.new(); bottom.size_flags_vertical=Control.SIZE_EXPAND_FILL; page.add_child(bottom)
	var comparisons := VBoxContainer.new(); comparisons.custom_minimum_size.x=410; bottom.add_child(comparisons)
	label(tr2("本实验实际运行 · 选择可复查","Runs in this experiment · select to inspect"),comparisons)
	history_list=ItemList.new(); history_list.custom_minimum_size.y=110; comparisons.add_child(history_list)
	history_list.item_selected.connect(select_run)
	summary=label("",comparisons,16)
	detail=RichTextLabel.new(); detail.size_flags_vertical=Control.SIZE_EXPAND_FILL; detail.custom_minimum_size.y=80; comparisons.add_child(detail)
	var evidence := VBoxContainer.new(); evidence.size_flags_horizontal=Control.SIZE_EXPAND_FILL; bottom.add_child(evidence)
	label(tr2("Trace · 点选实际事件查看字节、运算或输出","Trace · select an event for bytes, operations or outputs"),evidence)
	tree=Tree.new(); tree.columns=3; tree.column_titles_visible=true; tree.set_column_title(0,tr2("起点","Start")); tree.set_column_title(1,tr2("时长","Duration")); tree.set_column_title(2,tr2("操作","Operation")); tree.size_flags_vertical=Control.SIZE_EXPAND_FILL; evidence.add_child(tree)
	tree.item_selected.connect(func() -> void:
		var item: TreeItem=tree.get_selected()
		if item!=null: detail.text=JSON.stringify(item.get_metadata(0),"  "))
	next_button=button(tr2("进入下一个实验","Next experiment"),page,func() -> void: stage+=1; order=0; build())
	next_button.visible=not intelligent and stage<2; next_button.disabled=not completed[stage]
	update_data(); refresh_history()

func mission_text() -> String:
	if intelligent:
		return tr2("固定线性判别器，32 个公开输入，8 个权重。\n要求：总周期 ≤620、首个输出 ≤80、峰值 ≤200 B、最大分数误差 ≤0.02。\n改变精度、批量与驻留，寻找满足全部条件的方案。逐项检查输出；标签相同不代表数值相同。\n质量只对这32个输入有意义，不是智能或意识评分。", "Fixed linear classifier: 32 public inputs, 8 weights.\nMeet all limits: total ≤620 cycles, first output ≤80, peak ≤200 B, max score error ≤0.02.\nChange precision, batching and residency. Inspect individual outputs: matching labels do not imply matching scores.\nQuality describes only these 32 inputs, not intelligence or consciousness.")
	return [tr2("同一份不可变数据，必须逐字节还原。\n先测原始方案，再找到比原始64字节块更快的表示。\nRLE保存(count,value)；每块2B头、4B目录。解码操作=输出字节+run数。编码发生在离线制备阶段，本次测量只从已存储资产读取。", "Restore the immutable data exactly.\nMeasure raw first, then beat raw 64-byte blocks.\nRLE stores (count,value), with a 2B header and 4B directory per block. Decode work=output bytes+runs. Assets are encoded offline; this experiment times reads of an already stored asset."),
	tr2("换机器，再换数据。\n分别记录原始与RLE：慢链路、快链路慢解码、变化数据。找出一次压缩更快和一次压缩更慢的真实对照。保持对照的块大小与缓存相同。", "Change the machine, then the data.\nRecord raw and RLE for the slow link, fast link/slow decoder, and varied data. Find both a compression win and a loss. Hold block size and cache capacity fixed within each comparison."),
	tr2("同一资产，两份订单：扫描全部与只取0、32。\n分别为订单A找到 ≤100 周期、订单B ≤32 周期的正确方案。先试两种块大小再决定；编码、解码、过量读取都可在Trace中核对。\n缓存容量上限64B；比较相同机器上的两份订单。", "One asset, two orders: scan all bytes or read only 0 and 32.\nFind an exact plan ≤100 cycles for A and ≤32 for B. Compare at least two block sizes before deciding; Trace exposes encoding, decoding and overfetch.\nDecoded cache budget: 64B. Test how block size affects point reads.")][stage]

func update_data() -> void:
	if intelligent:
		data_label.text="W = "+str(Inference.WEIGHTS)+"\n"+tr2("输入与逐项参考分数在运行后的 Trace/output 中公开。链路4 B/cycle，请求4周期，1 MAC/cycle，scratch硬上限320B。","Inputs and per-sample reference scores are exposed in Trace/output after a run. Link 4 B/cycle, request 4 cycles, 1 MAC/cycle, hard scratch limit 320B.")
	else:
		var spec: Dictionary=Model.scenario(stage,order)
		data_label.text=tr2("数据 ","Data ")+str(spec.data)+"\n"+tr2("请求地址 ","Addresses ")+str(spec.addresses)+"\n"+tr2("链路 %d B/cycle · 解码 %d ops/cycle · 每次请求 %d cycles · scratch ≤64B","Link %d B/cycle · decode %d ops/cycle · request %d cycles · scratch ≤64B") % [spec.bandwidth,spec.decoder,spec.latency]

func invalidate() -> void:
	if status!=null: status.text=tr2("方案已变；旧记录仍可复查，请重新运行。","Design changed; old runs remain inspectable. Run again.")

func current_config() -> Dictionary:
	if intelligent: return {"bits":[32,8,4,2][codec.selected],"batch":[1,4,8][block.selected],"reuse":cache.selected==1}
	return {"codec":["raw","rle"][codec.selected],"block":[4,16,64][block.selected],"cache":cache.selected+1}

func run_current() -> void:
	var config: Dictionary=current_config()
	var trace: Trace=Inference.run(config) if intelligent else Model.run(Model.scenario(stage,order),config)
	history.append({"stage":stage,"order":order,"config":config,"trace":trace})
	if history.size()>100: history.pop_front()
	refresh_history(); history_list.select(history_list.item_count-1); select_run(history_list.item_count-1)
	if intelligent:
		var m: Dictionary=trace.metrics
		var accepted: bool=trace.passed and m.total_cycles<=620 and m.first_result_cycle<=80 and m.peak_bytes<=200 and m.max_error<=0.02
		status.text=tr2("全部约束成立；继续比较其他取舍。","All constraints met; keep comparing alternatives.") if accepted else tr2("尚未满足全部约束。比较耗时、峰值和实际输出误差。","Not all constraints met. Compare time, peak memory and actual output errors.")
	else:
		completed[stage]=completed[stage] or stage_ready()
		status.text=tr2("证据已成立；可以继续试其他方案。","Evidence established; further experiments remain open.") if completed[stage] else tr2("记录已保存。对照当前目标与分项费用，选择下一次实验。","Run recorded. Compare the objective and cost breakdown before the next trial.")
		next_button.disabled=not completed[stage]
		for i: int in stage_buttons.size(): stage_buttons[i].disabled=i>0 and not completed[i-1]

func stage_ready() -> bool:
	var rows: Array[Dictionary]=[]
	for row: Dictionary in history:
		if row.stage==stage and row.trace.passed: rows.append(row)
	if stage==0:
		var raw: bool=false; var better: bool=false
		var baseline: int=Model.run(Model.scenario(0),{"codec":"raw","block":64,"cache":1}).metrics.total_cycles
		for row: Dictionary in rows:
			raw=raw or row.config.codec=="raw"
			better=better or int(row.trace.metrics.total_cycles)<baseline
		return raw and better
	if stage==1:
		var win: bool=false; var loss: bool=false; var cases: Dictionary={}
		for a: Dictionary in rows:
			for b: Dictionary in rows:
				if a.order==b.order and a.config.block==b.config.block and a.config.cache==b.config.cache and a.config.codec=="raw" and b.config.codec=="rle":
					cases[a.order]=true
					win=win or b.trace.metrics.total_cycles<a.trace.metrics.total_cycles
					loss=loss or b.trace.metrics.total_cycles>a.trace.metrics.total_cycles
		return win and loss and cases.size()==3
	var sizes: Dictionary={}; var orders: Dictionary={}
	for row: Dictionary in rows:
		sizes[row.config.block]=true
		if int(row.trace.metrics.total_cycles)<=(100 if row.order==0 else 32): orders[row.order]=true
	return sizes.size()>=2 and orders.size()==2

func refresh_history() -> void:
	if history_list==null: return
	history_list.clear()
	for i: int in history.size():
		var row: Dictionary=history[i]
		if row.stage!=stage: continue
		var config_text: String = "%db / batch%d / keep=%s" % [row.config.bits,row.config.batch,str(row.config.reuse)] if intelligent else "%s / %dB / cache%d" % [row.config.codec,row.config.block,row.config.cache]
		var line: String="%d · %d cycles · %s · %s" % [row.order+1,row.trace.metrics.total_cycles,config_text,tr2("已执行","executed") if row.trace.passed else row.trace.metrics.error]
		history_list.add_item(line); history_list.set_item_metadata(history_list.item_count-1,i); history_list.set_item_tooltip(history_list.item_count-1,line)

func select_run(index: int) -> void:
	if index<0: return
	var row: Dictionary=history[history_list.get_item_metadata(index)]
	active_trace=row.trace
	var m: Dictionary=active_trace.metrics
	summary.text=tr2("已记录的结果（不随当前控件改变）\n","Recorded result (independent of current controls)\n")
	if intelligent:
		summary.text+="%d cycles · first %d · %d B traffic\npeak %d B · label %d/32\nMAE %.5f · max error %.5f" % [m.total_cycles,m.first_result_cycle,m.traffic_bytes,m.peak_bytes,m.correct,m.mae,m.max_error]
	else:
		summary.text+="%d cycles = request %d + transfer %d + decode %d + consume %d\nStored %d B · moved %d B · decoded %d values\nScratch %d B · %d misses / %d hits" % [m.total_cycles,m.request_cycles,m.transfer_cycles,m.decode_cycles,m.consume_cycles,m.stored_bytes,m.traffic_bytes,m.decoded_values,m.scratch_bytes,m.cache_misses,m.cache_hits]
	if not str(m.error).is_empty(): summary.text+="\n"+str(m.error)
	tree.clear(); var root_item: TreeItem=tree.create_item(); tree.hide_root=true
	for event: RefCounted in active_trace.events:
		var item: TreeItem=tree.create_item(root_item)
		item.set_text(0,str(event.cycle)); item.set_text(1,str(event.duration)); item.set_text(2,String(event.kind)+" "+str(event.details.get("address",event.details.get("batch_start",""))))
		item.set_metadata(0,event.to_dictionary())
	detail.text=tr2("输出预览（前4项）：","Output preview (first 4): ")+str(m.outputs.slice(0,4))+"\n"+tr2("点选右侧事件，检查完整输入、字节或逐项输出。","Select a Trace event to inspect its full input, bytes or output.")
