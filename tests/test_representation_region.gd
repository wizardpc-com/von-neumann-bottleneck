extends SceneTree
const M = preload("res://experiments/representation_region/model.gd")
const C = preload("res://experiments/representation_region/catalog.gd")
const Codec = preload("res://experiments/representation/model.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func partition(bounds: Array, codecs: Array) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []; var start: int = 0
	for i: int in bounds.size():
		plan.append({"start":start,"end":bounds[i],"codec":codecs[i]}); start = int(bounds[i])
	return plan
func execute(task: int, plan: Array) -> Array[RefCounted]:
	var out: Array[RefCounted] = []
	for spec: Dictionary in M.orders(task): out.append(M.run(spec,plan))
	return out
func verify(trace: RefCounted) -> void:
	check(trace.passed,"Exact requested values restored")
	var m: Dictionary = trace.metrics
	var time: int = 0; var reads: int = 0; var writes: int = 0; var moved: int = 0; var encoding: int = 0
	for event: RefCounted in trace.events:
		check(event.cycle == time and event.duration >= 0,"Monotone synchronous Trace")
		time += event.duration
		if event.kind == &"prepare_source_read": reads += int(event.details.bytes)
		if event.kind == &"prepare_write":
			writes += int(event.details.bytes)
			check(event.details.bytes == event.details.encoded.size()+4,"Prepared writes include real directory and actual encoded payload")
		if event.kind == &"transfer": moved += int(event.details.bytes)
		if event.kind == &"encode":
			encoding += int(event.details.ops)
			check(Codec.decode(PackedByteArray(event.details.encoded),"rle") == event.details.values,"Prepared payload actually restores source")
	check(time == m.total_cycles and time == m.preparation_cycles+m.service_cycles,"Preparation and serving conserve total time")
	check(m.service_cycles == m.request_cycles+m.transfer_cycles+m.decode_cycles+m.consume_cycles,"Serving cost conservation")
	check(m.total_traffic_bytes == reads+writes+moved,"All-stage traffic includes preparation and service")
	check(reads == m.source_read_bytes and writes == m.prepared_write_bytes and moved == m.traffic_bytes and encoding == m.encode_ops,"Actual phase traffic/work conserved")
	check(not m.spec.online or m.stored_bytes == 64+writes and m.peak_preparation_bytes == m.stored_bytes,"Online retained source and actual writes count in final storage and peak")
	var expected: Array = []
	for client: int in m.spec.clients:
		for address: int in m.spec.addresses: expected.append(m.spec.data[address])
	check(m.outputs == expected and m.expected == expected,"Independent complete ordered oracle across all clients")
	for access: Dictionary in m.accesses: check(access.cache_after.used_bytes <= m.spec.cache_bytes,"Automatic finite decoded cache")
	check(trace.canonical_signature() == M.run(m.spec,m.plan).canonical_signature(),"Fresh deterministic Trace")
func run() -> void:
	var solutions: Array[Array] = [
		[partition([16,64],["rle","raw"]),partition([14,48,64],["rle","raw","rle"])],
		[partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([12,24,40,52,64],["rle","rle","raw","rle","rle"])],
		[partition([16,48,64],["rle","rle","rle"]),partition([15,32,49,64],["rle","rle","rle","rle"])],
		[partition([8,64],["raw","rle"]),partition([12,64],["raw","rle"])],
		[partition([18,46,64],["rle","raw","rle"]),partition([19,46,64],["rle","raw","rle"])] ]
	for task: int in 5:
		for plan: Array in solutions[task]:
			var traces: Array = execute(task,plan)
			check(M.meets(task,traces),"Alternative public-goal solution for task"+str(task))
			for trace: RefCounted in traces: verify(trace)
			print("REGION QA task",task," plan",plan," metrics",traces.map(func(t: RefCounted) -> Array: return [t.metrics.total_cycles,t.metrics.stored_bytes,t.metrics.traffic_bytes,t.metrics.preparation_cycles]))
	check(not M.meets(-1,[]) and not M.meets(5,[]) and not M.meets(0,[{}]),"Invalid task and fabricated Trace safely rejected")
	var old: Array[Dictionary] = partition([16,48,64],["rle","raw","rle"])
	check(not M.meets(1,execute(1,old)) and not M.meets(2,execute(2,old)) and not M.meets(3,execute(3,old)) and not M.meets(4,execute(4,old)),"Old three-task plan cannot trivially clear new constraints")
	var raw: Array = execute(3,M.initial_plan()); var rle: Array = execute(3,partition([64],["rle"]))
	check(raw[0].metrics.total_cycles < rle[0].metrics.total_cycles and raw[1].metrics.total_cycles > rle[1].metrics.total_cycles,"Real preparation amortization reverses RAW/RLE ranking")
	check(not M.meets(3,raw) and not M.meets(3,rle),"Neither whole RAW nor whole RLE clears both public service goals")
	print("REVERSAL raw",raw.map(func(t: RefCounted) -> int: return t.metrics.total_cycles)," rle",rle.map(func(t: RefCounted) -> int: return t.metrics.total_cycles))
	check(not M.meets(4,execute(4,partition([20,44,64],["rle","raw","rle"]))),"Optimizing AssetA alone fails shifted AssetB runs")
	var pair: Array = execute(4,solutions[4][0]); var other: Array = execute(4,solutions[4][1]); pair[1] = other[1]
	check(not M.meets(4,pair),"Cannot splice different plans across orders")
	var wrong: Dictionary = M.orders(4)[0].duplicate(true); wrong.data[0] = 99
	check(not M.meets(4,[M.run(wrong,solutions[4][0]),other[1]]),"Evidence bound to authored asset/spec")
	for bad: Array in [[],[{"start":1,"end":64,"codec":"raw"}],[{"start":0.0,"end":64,"codec":"raw"}],[{"start":0,"end":64,"codec":"zip"}],[{}]]:
		var rejected: RefCounted = M.run(M.orders(3)[0],bad)
		check(not rejected.passed and rejected.events.is_empty(),"Invalid plans rejected before online preparation")
	for field: String in ["encoder","clients","online"]:
		var invalid: Dictionary = M.orders(3)[0].duplicate(true); invalid[field] = -1
		check(not M.run(invalid,M.initial_plan()).passed,"Reject invalid preparation machine")
	var scene: PackedScene = load("res://experiments/representation_region/region.tscn")
	var ui: Control = scene.instantiate(); root.add_child(ui); await process_frame
	for name: String in ["Blocks","SplitAt","Split","Merge","Raw","RLE","Undo","Redo","Run","Task4","Mission","Hint1","Asset","History","Events","TraceDetails"]: check(ui.find_child(name,true,false) != null,"Public control "+name)
	check(ui.public_observation().latest == {} and ui.public_observation().assets.size() == 1,"Unrun observation reveals no measured answer")
	ui.edit_plan(solutions[0][0]); ui.run_current(); var signature: String = ui.history[0].traces[0].canonical_signature()
	ui.change_task(3); ui.edit_plan(solutions[3][0]); ui.run_current(); ui.change_task(0)
	check(ui.plan == solutions[0][0],"Per-task draft restored")
	ui.edit_plan(M.initial_plan()); ui.undo(); check(ui.plan == solutions[0][0],"Per-task undo preserved")
	check(ui.history[0].traces[0].canonical_signature() == signature,"Historical Trace immutable after edits/navigation")
	for viewport: Vector2i in [Vector2i(1600,900),Vector2i(1280,720)]:
		root.size = viewport; ui.size = Vector2(viewport); await process_frame
		for english: bool in [false,true]:
			ui.english = english; ui.build(); await process_frame
			for button: Button in ui.task_buttons:
				check(button.get_global_rect().end.x <= viewport.x and button.get_global_rect().end.y <= viewport.y,"Task navigation stays in supported viewport")
			check(ui.find_child("EditorScroll",true,false).size.x >= 530 and ui.find_child("EvidenceScroll",true,false).size.x >= 430,"Both bounded columns remain usable")
	for english: bool in [false,true]:
		ui.english = english
		for task: int in 5:
			ui.change_task(task); await process_frame
			check(not ui.mission.text.is_empty() and ui.public_observation().hint.length() > 10,"Bilingual public mission and Hint1")
			check(ui.public_observation().assets.size() == M.orders(task).size(),"Every asset/order publicly inspectable")
	for repeat: int in 8: ui.run_current()
	await process_frame; await process_frame
	check(ui.history_list.get_v_scroll_bar().value > 0, "New measured result scrolls into view after history grows")
	check(ui.history_list.get_item_text(ui.history_list.item_count-1).contains("T5"), "Cross-task history identifies its task")
	ui.queue_free(); await process_frame
	print("PASS: test_representation_region: " if failures.is_empty() else "FAIL: test_representation_region: ",checks," checks, ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
