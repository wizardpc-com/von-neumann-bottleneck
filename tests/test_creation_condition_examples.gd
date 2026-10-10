extends SceneTree
## Actual codecs on the actual UI material; no substitute source or cost model.
const Examples = preload("res://experiments/creation/condition_examples.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func run() -> void:
	var a: Dictionary = Examples.machine(0)
	var b: Dictionary = Examples.machine(1)
	check(Model.machine_error(a).is_empty() and Model.machine_error(b).is_empty(),"Both teaching machines are legal")
	var changed: Array[String] = []
	for key: String in a:
		if a[key] != b[key]: changed.append(key)
	check(changed == ["cpu_ops_per_cycle"],"Exactly CPU throughput changes")
	var detached: Dictionary = Examples.machine(0)
	detached.memory_bytes = 64
	check(Examples.machine(0).memory_bytes == 8192,"Applying a condition owns its own machine dictionary")
	var source: Array = Catalog.source(0)
	check(source.size() == 1536,"Use the actual regular UI source including exceptions")
	for spec: Array in [[[Catalog.sample(0),Catalog.sample(1)],1],[[Catalog.sample(0)],2]]:
		var learned: Dictionary = Model.learn(spec[0],int(spec[1]),Model.default_machine())
		check(learned.ok,"Public examples learn without a machine preset changing them")
		if not learned.ok: continue
		var identity: String = Model.identity(learned.model)
		var raw_a: Dictionary = Codec.run_transport(source,learned.model,a,"raw")
		var pred_a: Dictionary = Codec.run_transport(source,learned.model,a,"predictive")
		var raw_b: Dictionary = Codec.run_transport(source,learned.model,b,"raw")
		var pred_b: Dictionary = Codec.run_transport(source,learned.model,b,"predictive")
		for measured: Dictionary in [raw_a,pred_a,raw_b,pred_b]:
			check(measured.ok and measured.get("lossless",false) and measured.get("output",[]) == source,"Both codecs restore the same UI source under both conditions")
		if not raw_a.ok or not pred_a.ok or not raw_b.ok or not pred_b.ok: continue
		check(pred_a.cost.total_cycles > raw_a.cost.total_cycles + 1000,"Slow compute makes the predictive run measurably dearer")
		check(pred_b.cost.total_cycles + 1000 < raw_b.cost.total_cycles,"Fast compute reverses actual cost by more than 1000 cycles")
		check(raw_a.packet == raw_b.packet and pred_a.packet == pred_b.packet,"Machine changes execution costs, never packet content")
		check(pred_a.metrics.packet_bytes < raw_a.metrics.packet_bytes,"The same smaller packet remains smaller on both machines")
		check(Model.identity(learned.model) == identity,"Comparison never edits the learned rule box")
		print("CONDITIONS order=%d source=%d RAW=%d B predictive=%d B A=%d/%d cycles B=%d/%d cycles"%[int(spec[1]),source.size(),raw_a.metrics.packet_bytes,pred_a.metrics.packet_bytes,raw_a.cost.total_cycles,pred_a.cost.total_cycles,raw_b.cost.total_cycles,pred_b.cost.total_cycles])
	print("PASS: creation condition examples %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
