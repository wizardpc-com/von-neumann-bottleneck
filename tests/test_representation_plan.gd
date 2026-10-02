extends SceneTree
const M = preload("res://experiments/representation/plan_model.gd")
const Codec = preload("res://experiments/representation/model.gd")
var failures: Array[String] = []
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func mixed(first_end: int = 16, last_start: int = 48) -> Array[Dictionary]:
	return [{"start":0,"end":first_end,"codec":"rle"},{"start":first_end,"end":last_start,"codec":"raw"},{"start":last_start,"end":64,"codec":"rle"}]
func execute(task: int, plan: Array[Dictionary]) -> Array[RefCounted]:
	var traces: Array[RefCounted] = []
	for spec: Dictionary in M.orders(task): traces.append(M.run(spec,plan))
	return traces
func verify(trace: RefCounted) -> void:
	check(trace.passed,"Legal partition restores exact outputs")
	var m: Dictionary = trace.metrics
	var time: int = 0; var moved: int = 0; var ops: int = 0
	for event: RefCounted in trace.events:
		check(event.cycle == time and event.duration >= 0,"Sequential event timing")
		time += event.duration
		if event.kind == &"transfer":
			moved += int(event.details.bytes)
			check(event.details.bytes == event.details.encoded.size()+event.details.directory.size(),"Transfer includes actual payload and 4B directory")
		if event.kind == &"decode": ops += int(event.details.ops)
	check(time == m.total_cycles,"Event time sum matches measured total")
	check(time == m.request_cycles+m.transfer_cycles+m.decode_cycles+m.consume_cycles,"Named costs sum without speed discounts")
	check(moved == m.traffic_bytes and ops == m.decode_ops,"Event bytes and operations sum")
	var stored: int = 0
	for block: Dictionary in m.blocks:
		stored += int(block.stored_bytes)
		check(Codec.decode(PackedByteArray(block.encoded),str(block.codec)) == block.values,"Every encoded block independently restores")
		check(block.metadata_bytes == 4 and block.directory == [int(block.start)&255,int(block.start)>>8,int(block.end)&255,int(block.end)>>8],"Both codecs pay explicit byte-address directory")
	check(stored == m.stored_bytes,"Stored bytes count every directory/header/pair")
	var independently_expected: Array[int] = []
	for address: int in m.spec.addresses: independently_expected.append(m.spec.data[address])
	check(independently_expected == m.outputs and m.expected == m.outputs,"Every actual request correct in order")
	for access: Dictionary in m.accesses:
		var cache: Dictionary = access.cache_after
		check(cache.used_bytes <= m.spec.cache_bytes,"Finite automatic cache byte budget")
		var size: int = 0
		for key: int in cache.keys: size += int(m.blocks[key].end)-int(m.blocks[key].start)
		check(size == cache.used_bytes and cache.keys.size() == cache.lru.size(),"Observed cache membership agrees with actual decoded sizes")
	check(trace.canonical_signature() == M.run(m.spec,m.plan).canonical_signature(),"Identical authoritative trace on rerun")
func verify_visible_asset(lab: Control, locale: String) -> void:
	var data: Label = lab.find_child("Asset",true,false) as Label
	check(data != null,"Fixed asset display is a nonscrolling Label in "+locale)
	if data == null: return
	var rows: PackedStringArray = data.text.split("\n")
	check(rows.size() == 4 and data.get_line_count() == 4 and data.get_visible_line_count() == 4,"All four asset rows are actually visible in "+locale)
	for i: int in 4:
		check(rows[i] == "%02d–%02d: %s" % [i*16,i*16+15,str(M.asset().slice(i*16,i*16+16))],"Displayed row independently matches immutable byte asset in "+locale)
func run() -> void:
	var initial: Array[Dictionary] = M.initial_plan()
	var a: Array[Dictionary] = M.split(initial,0,16)
	check(initial == M.initial_plan() and a.size() == 2,"Splitting owns draft arrays")
	var b: Array[Dictionary] = M.represent(a,0,"rle")
	check(a[0].codec == "raw" and b[0].codec == "rle","Per-block encoding edits own data")
	check(M.merge(b,0) == [{"start":0,"end":64,"codec":"rle"}],"Merge reencodes full joined interval with left codec")
	check(M.split(initial,0,0) == initial and M.split(initial,0,64) == initial,"Invalid split boundaries rejected")
	var invalid: Array = [[],[{"start":1,"end":64,"codec":"raw"}],[{"start":0,"end":63,"codec":"raw"}],[{"start":0,"end":32,"codec":"raw"},{"start":31,"end":64,"codec":"raw"}],[{"start":0,"end":32,"codec":"raw"},{"start":33,"end":64,"codec":"raw"}],[{"start":0,"end":0,"codec":"raw"}],[{"start":0.0,"end":64,"codec":"raw"}],[{"start":0,"end":64,"codec":"zip"}],[{"start":0}],[2]]
	for plan: Array in invalid:
		var rejected: RefCounted = M.run(M.orders(0)[0],plan)
		check(not rejected.passed and not str(rejected.metrics.error).is_empty() and rejected.events.is_empty(),"Malformed partition rejected before work")
	var too_many: Array = []
	for n: int in 9: too_many.append({"start":n,"end":64 if n == 8 else n+1,"codec":"raw"})
	check(not M.run(M.orders(0)[0],too_many).passed,"At most 8 blocks")
	for first: int in [12,14,15,16,17]:
		for last: int in [47,48,49,52]:
			for task: int in 3:
				for trace: RefCounted in execute(task,mixed(first,last)): verify(trace)
	var baseline: RefCounted = execute(0,initial)[0]
	check(baseline.metrics.total_cycles == 136 and baseline.metrics.stored_bytes == 68,"Explicit-directory raw baseline")
	check(not M.meets(0,[baseline]),"Raw baseline alone fails actual storage budget")
	var full_rle: Array[Dictionary] = [{"start":0,"end":64,"codec":"rle"}]
	var compressed: RefCounted = execute(0,full_rle)[0]
	check(compressed.metrics.stored_bytes > baseline.metrics.stored_bytes and compressed.metrics.total_cycles > baseline.metrics.total_cycles,"Changing center genuinely defeats whole-asset compression")
	var scan_a: Array[Dictionary] = [{"start":0,"end":16,"codec":"rle"},{"start":16,"end":64,"codec":"raw"}]
	check(M.meets(0,execute(0,scan_a)),"Two-block alternative scan solution")
	check(M.meets(0,execute(0,mixed())),"Three-block mixed scan solution")
	for variant: Array[Dictionary] in [mixed(),mixed(14,48),mixed(16,50)]:
		var paired: Array[RefCounted] = execute(2,variant)
		check(M.meets(2,paired),"Different byte boundaries satisfy both measured orders")
		print("PLAN ",variant," => scan=",paired[0].metrics.total_cycles," hotspots=",paired[1].metrics.total_cycles," stored=",paired[0].metrics.stored_bytes)
	var hot: RefCounted = execute(1,initial)[0]
	check(hot.metrics.cache_misses == 6 and hot.metrics.cache_hits == 0 and hot.metrics.peak_cache_bytes == 0,"Oversized decoded block never falsely retained")
	check(hot.metrics.overfetch_values == 62,"Distinct unrequested recovered bytes measured from actual accesses")
	var mixed_hot: RefCounted = execute(1,mixed())[0]
	check(mixed_hot.metrics.total_cycles == 36 and mixed_hot.metrics.cache_hits == 4 and mixed_hot.metrics.cache_misses == 2,"Two finite decoded hotspots fit and reuse automatically")
	var tiny: Array[Dictionary] = [{"start":0,"end":1,"codec":"raw"},{"start":1,"end":16,"codec":"rle"},{"start":16,"end":48,"codec":"raw"},{"start":48,"end":63,"codec":"rle"},{"start":63,"end":64,"codec":"raw"}]
	print("COUNTEREXAMPLE whole_rle scan=",compressed.metrics.total_cycles," hot=",execute(1,full_rle)[0].metrics.total_cycles," tiny scan=",execute(0,tiny)[0].metrics.total_cycles," tinyhot=",execute(1,tiny)[0].metrics.total_cycles," twohot=",execute(1,scan_a)[0].metrics.total_cycles)
	check(M.meets(1,execute(1,tiny)) and not M.meets(2,execute(2,tiny)),"Raw point blocks are legal sparse alternative but request overhead defeats scan")
	var fast: Dictionary = M.orders(0)[0].duplicate(true); fast.bandwidth = 8; fast.decoder = 1
	check(M.run(fast,full_rle).metrics.total_cycles > M.run(fast,initial).metrics.total_cycles,"Real decode work loses on faster link")
	var eviction: Dictionary = M.orders(1)[0].duplicate(true); eviction.addresses = [0,16,0,48,0,16]
	var eviction_plan: Array[Dictionary] = [{"start":0,"end":16,"codec":"raw"},{"start":16,"end":32,"codec":"raw"},{"start":32,"end":48,"codec":"raw"},{"start":48,"end":64,"codec":"raw"}]
	var e: RefCounted = M.run(eviction,eviction_plan); verify(e)
	check(e.metrics.cache_hits == 2 and e.metrics.cache_misses == 4 and e.metrics.accesses[3].evicted == [1],"Hits refresh real LRU; reloading evicted block charged")
	for field: String in ["bandwidth","decoder","latency","cache_bytes","scratch_limit"]:
		var bad: Dictionary = M.orders(0)[0].duplicate(true); bad[field] = -1
		check(not M.run(bad,initial).passed,"Invalid machine rejected")
	var invalid_address: Dictionary = M.orders(0)[0].duplicate(true); invalid_address.addresses = [0,64]
	check(not M.run(invalid_address,initial).passed,"Out-of-range request rejected before partial work")
	check(not M.meets(-1,[baseline]) and not M.meets(2,[baseline]),"Invalid task/evidence count rejected")
	var foreign: Dictionary = M.orders(0)[0].duplicate(true); foreign.bandwidth = 100
	check(not M.meets(0,[M.run(foreign,mixed())]),"A cheaper foreign machine cannot satisfy authored task")
	check(not M.meets(2,[execute(0,mixed())[0],execute(1,mixed(14,48))[0]]),"Paired receipt must bind one shared plan")
	var campaign_before: String = JSON.stringify(root.get_node("LocalityChapter").completed_levels())
	var lab: Control = load("res://experiments/representation/puzzle.tscn").instantiate(); root.add_child(lab); await process_frame
	await process_frame
	check(lab.split_at.get_parent().size.y <= 44,"Inline split controls fit one normal-height row in Chinese")
	verify_visible_asset(lab,"Chinese")
	lab.run_current(); check(not lab.completed[0],"UI baseline does not falsely complete")
	var signature: String = lab.visible_trace.canonical_signature()
	lab.edit_plan(mixed()); check(lab.visible_trace.canonical_signature() == signature,"Editing cannot mutate immutable run/spec/plan")
	lab.undo(); check(lab.plan == initial,"Editor undo restores boundaries/codec")
	lab.redo(); check(lab.plan == mixed(),"Editor redo restores exact mixed plan")
	lab.run_current(); check(lab.completed[0],"Measured mixed scan unlocks task")
	lab.change_task(1); lab.run_current(); check(lab.completed[1],"Real finite-cache result unlocks paired task")
	lab.change_task(2); lab.run_current(); check(lab.completed[2] and lab.history[-1].traces.size() == 2,"Paired task uses one immutable plan on two actual orders")
	lab.select_run(0); check(lab.visible_trace.canonical_signature() == signature,"Older rejected run remains inspectable")
	lab.english = true; lab.build(); await process_frame
	await process_frame
	check(lab.split_at.get_parent().size.y <= 44,"Inline split controls fit one normal-height row in English")
	verify_visible_asset(lab,"English")
	check(lab.run_button.text.begins_with("Run current") and lab.plan == mixed(),"Bilingual rebuild preserves editor and runs")
	check(campaign_before == JSON.stringify(root.get_node("LocalityChapter").completed_levels()),"Experimental evidence cannot award campaign progression")
	lab.queue_free(); await process_frame
	print("PASS: representation plan ",checks," checks" if failures.is_empty() else "FAIL: representation plan "+str(failures))
	quit(0 if failures.is_empty() else 1)
