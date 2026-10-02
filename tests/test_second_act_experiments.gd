extends SceneTree
const M = preload("res://experiments/representation/model.gd")
const I = preload("res://experiments/intelligent_workload/model.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func cost_sum(trace: RefCounted) -> void:
	var time: int=0
	for event: RefCounted in trace.events:
		check(event.cycle==time and event.duration>=0,"Trace is sequential and nonnegative")
		time+=event.duration
	check(time==trace.metrics.total_cycles,"Event costs sum to total")
func run() -> void:
	for varied: bool in [false,true]:
		var values: Array[int]=M.data_set(varied)
		for codec: String in ["raw","rle"]:
			check(M.decode(M.encode(values,codec),codec)==values,"Codec must actually restore all values")
	var long_run: Array[int]=[]; long_run.resize(300); long_run.fill(255)
	check(M.decode(M.encode(long_run,"rle"),"rle")==long_run,"Run count splitting and 16-bit length")
	check(M.decode(PackedByteArray([5,0,0,7]),"rle").is_empty(),"Reject zero-count malformed pair")
	for stage: int in 3:
		for order: int in (3 if stage==1 else 2 if stage==2 else 1):
			var spec: Dictionary=M.scenario(stage,order)
			for codec: String in ["raw","rle"]:
				for size: int in [4,16,64]:
					for cache: int in [1,2]:
						var config: Dictionary={"codec":codec,"block":size,"cache":cache}
						var trace: RefCounted=M.run(spec,config)
						check(trace.canonical_signature()==M.run(spec,config).canonical_signature(),"Deterministic representation trace")
						if size*cache>64: check(not trace.passed,"Scratch capacity is enforced"); continue
						check(trace.passed,"Every legal representation restores actual query outputs")
						cost_sum(trace)
						check(trace.metrics.total_cycles==trace.metrics.request_cycles+trace.metrics.transfer_cycles+trace.metrics.decode_cycles+trace.metrics.consume_cycles,"No hidden cycle discount")
						print("REP ",stage,"/",order," ",config," ",trace.metrics.total_cycles," traffic=",trace.metrics.traffic_bytes)
	var raw: Dictionary={"codec":"raw","block":64,"cache":1}
	var rle: Dictionary={"codec":"rle","block":64,"cache":1}
	check(M.run(M.scenario(0),rle).metrics.total_cycles<M.run(M.scenario(0),raw).metrics.total_cycles,"Compression can beat transfer")
	check(M.run(M.scenario(1,1),rle).metrics.total_cycles>M.run(M.scenario(1,1),raw).metrics.total_cycles,"Decoder cost can defeat compression")
	check(M.run(M.scenario(1,2),rle).metrics.stored_bytes>64,"Changing data genuinely expands RLE")
	var small: Dictionary={"codec":"rle","block":4,"cache":1}
	check(M.run(M.scenario(2,1),small).metrics.total_cycles<M.run(M.scenario(2,1),rle).metrics.total_cycles,"Small blocks reduce point-read decoding")
	check(M.scenario(2,0).decoder==M.scenario(2,1).decoder and M.scenario(2,0).bandwidth==M.scenario(2,1).bandwidth,"Order comparison uses the same machine")
	var revisit: Dictionary=M.scenario(2,1); revisit.addresses=[0,16,0,16]
	var one_slot: RefCounted=M.run(revisit,{"codec":"rle","block":16,"cache":1})
	var two_slots: RefCounted=M.run(revisit,{"codec":"rle","block":16,"cache":2})
	check(one_slot.metrics.cache_misses==4 and two_slots.metrics.cache_misses==2 and one_slot.metrics.outputs==two_slots.metrics.outputs,"Real decoded-cache eviction and reuse")
	var tail: Dictionary=M.scenario(0); tail.data=[3,3,3,2,9]; tail.addresses=[4,0,4]
	check(M.run(tail,small).metrics.outputs==[9,3,9],"Tail block and eviction preserve random reads")
	tail.addresses=[5]; check(not M.run(tail,small).passed,"Invalid address rejected")
	var signatures: Dictionary={}
	for bits: int in [32,8,4,2]:
		for batch: int in [1,4,8]:
			for reuse: bool in [false,true]:
				var config: Dictionary={"bits":bits,"batch":batch,"reuse":reuse}
				var trace: RefCounted=I.run(config)
				check(trace.canonical_signature()==I.run(config).canonical_signature(),"Inference determinism")
				check(trace.passed,"Declared inference configurations execute")
				cost_sum(trace)
				var correct: int=0; var error: float=0; var max_error: float=0
				for n: int in 32:
					var expected: float=I.score(I.samples()[n],I.WEIGHTS)
					var actual: float=I.score(I.samples()[n],I.weights(bits))
					check(is_equal_approx(trace.metrics.outputs[n],actual),"Scores computed from rounded weights, not a quality table")
					correct+=int((actual>=0)==(expected>=0)); error+=absf(actual-expected)/32; max_error=maxf(max_error,absf(actual-expected))
				check(correct==trace.metrics.correct and is_equal_approx(error,trace.metrics.mae) and is_equal_approx(max_error,trace.metrics.max_error),"Quality independently recomputed")
				if signatures.has(bits): check(signatures[bits]==trace.metrics.outputs,"Batching/reuse never changes numerical output")
				else: signatures[bits]=trace.metrics.outputs.duplicate()
				print("INFER ",config," ",trace.metrics)
	var a: RefCounted=I.run({"bits":32,"batch":1,"reuse":false})
	var b: RefCounted=I.run({"bits":32,"batch":4,"reuse":true})
	check(b.metrics.total_cycles<a.metrics.total_cycles and b.metrics.first_result_cycle>a.metrics.first_result_cycle and b.metrics.peak_bytes>a.metrics.peak_bytes,"Batching improves throughput at latency/memory cost")
	check(I.run({"bits":2}).metrics.max_error>I.run({"bits":8}).metrics.max_error,"Reduced precision has measured numerical consequences")
	check(not I.run({"bits":3}).passed,"Unsupported precision rejected")
	var before: String=JSON.stringify(root.get_node("LocalityChapter").completed_levels())
	var lab: Control=load("res://experiments/representation/lab.tscn").instantiate(); root.add_child(lab)
	await process_frame
	lab.run_current(); check(not lab.completed[0],"Raw baseline alone cannot finish experiment")
	lab.codec.select(1); lab.run_current(); check(lab.completed[0],"Real compression improvement enables next experiment")
	var signature: String=lab.active_trace.canonical_signature(); lab.block.select(0); lab.invalidate()
	check(signature==lab.active_trace.canonical_signature(),"UI draft changes cannot mutate recorded trace")
	check(before==JSON.stringify(root.get_node("LocalityChapter").completed_levels()),"Experiment cannot award campaign progress")
	lab.queue_free(); await process_frame
	print("PASS: second-act codecs, measured tradeoffs, inference quality and isolated UI" if failures.is_empty() else "FAIL: second-act experiments")
	quit(0 if failures.is_empty() else 1)
