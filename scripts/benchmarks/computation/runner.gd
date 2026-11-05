extends SceneTree
## Reproducible API-level timings; full evidence export is outside timed regions.
const Snapshot = preload("res://scripts/benchmarks/computation/snapshot.gd")
const GROUPS: Dictionary = {
	"circuit":"res://scripts/benchmarks/computation/circuit_cases.gd",
	"memory":"res://scripts/benchmarks/computation/memory_cases.gd",
	"workload":"res://scripts/benchmarks/computation/workload_cases.gd",
}
var failures: Array[String] = []
var samples: int = 7
var target_us: int = 20000
var fixed_iterations: Dictionary = {}
var retained: Array[Dictionary] = []
var run_entered: bool = false
var run_finished: bool = false

func _init() -> void:
	call_deferred("_run")

func _process(_delta: float) -> bool:
	# _run is synchronous. A frame with it still unfinished means a script error
	# unwound the call before the receipt/quit path; never leave a hung success.
	if run_entered and not run_finished:
		push_error("Computation benchmark aborted before writing its final receipt.")
		quit(1)
	return false

func option(name: String, fallback: String = "") -> String:
	var prefix: String = "--"+name+"="
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(prefix): return argument.trim_prefix(prefix)
	return fallback

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func freeze_checked(value: Variant, context: String) -> Variant:
	var frozen: Variant = Snapshot.freeze(value)
	check(Snapshot.supported(frozen),context+": unsupported or cyclic evidence")
	return frozen

func _run() -> void:
	run_entered = true
	var isolated: bool = OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/")
	if not isolated:
		push_error("Use an isolated QA profile for computation benchmarks.")
		quit(1)
		return
	var output: String = option("benchmark-output","user://computation-benchmark.json")
	if not output.begins_with("user://") or ".." in output:
		push_error("Benchmark output must be inside the isolated user directory.")
		quit(1)
		return
	samples = clampi(int(option("samples","7")),3,31)
	target_us = clampi(int(option("target-us","20000")),1000,1000000)
	var iteration_path: String = option("iterations-file")
	if not iteration_path.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(iteration_path))
		if parsed is Dictionary:
			fixed_iterations = parsed
		else:
			check(false,"Fixed iteration file is not a dictionary.")
	var requested: PackedStringArray = option("benchmark-group","circuit,memory,workload").split(",")
	var only: PackedStringArray = option("only").split(",",false)
	var entries: Array[Dictionary] = []
	var ids: Dictionary = {}
	for group: String in requested:
		if not GROUPS.has(group):
			check(false,"Unknown benchmark group: "+group)
			continue
		var adapter: Script = load(GROUPS[group])
		if adapter == null or not adapter.can_instantiate():
			check(false,"Cannot load adapter: "+group)
			continue
		for spec: Dictionary in adapter.cases():
			var id: String = str(spec.get("id",""))
			if not only.is_empty() and id not in only: continue
			if id.is_empty() or ids.has(id):
				check(false,"Empty or duplicate benchmark id: "+id)
				continue
			ids[id] = true
			var entry: Dictionary = measure(adapter,spec)
			entries.append(entry)
			print("CASE ",id,": ",entry.get("iterations",0)," iterations/sample; median ",
				entry.get("median_us",0.0)," us; snapshot ",entry.get("snapshot_bytes",0)," bytes")
	# Keep actual earlier results alive through different inputs, then check them.
	# Repeating only A cannot expose a shared result buffer overwritten by B.
	for item: Dictionary in retained:
		check(freeze_checked(item.actual,str(item.id)) == item.expected,
			str(item.id)+": later different inputs mutated retained evidence")
		check(var_to_bytes(item.spec) == item.input_bytes,
			str(item.id)+": later different inputs mutated retained input")
	check(not entries.is_empty(),"No selected computation cases executed.")
	var result: Dictionary = {
		"version":1,"label":option("label","measurement"),
		"engine":Engine.get_version_info(),"os":OS.get_name(),
		"architecture":Engine.get_architecture_name(),"display":DisplayServer.get_name(),
		"processor":OS.get_processor_name(),"processor_count":OS.get_processor_count(),
		"host_label":option("host-label"),"execution_flags":OS.get_cmdline_args(),
		"samples":samples,"target_us":target_us,"cases":entries,"failures":failures,
		"timing_scope":"Actual public API including fresh input/state construction and model-owned serialization; only harness snapshots/hashing/export excluded; retained results remain alive.",
	}
	var file := FileAccess.open(output,FileAccess.WRITE)
	if file == null:
		check(false,"Unable to write benchmark output: "+str(FileAccess.get_open_error()))
	else:
		file.store_string(JSON.stringify(result,"",true,true))
		file.close()
		print("BENCHMARK: "+ProjectSettings.globalize_path(output))
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"computation benchmark %d cases, %d failures" % [entries.size(),failures.size()])
	run_finished = true
	quit(0 if failures.is_empty() else 1)

func measure(adapter: Script, spec: Dictionary) -> Dictionary:
	var id: String = str(spec.id)
	var original_input: PackedByteArray = var_to_bytes(spec)
	var start: int = Time.get_ticks_usec()
	var original: Variant = adapter.run_case(spec)
	var cold_us: int = Time.get_ticks_usec()-start
	check(original != null,id+": actual simulator returned null")
	var expected: Variant = freeze_checked(original,id)
	for issue: String in adapter.validate_case(spec,original):
		check(false,id+": "+issue)
	var encoded: String = JSON.stringify(expected,"",true,true)
	check(var_to_bytes(spec) == original_input,id+": initial simulation changed its input")
	# Repeat and JSON-restored input must retain every output, cost, state and event.
	var restored: Variant = JSON.parse_string(JSON.stringify(spec,"",true,true))
	check(restored is Dictionary,id+": input has a JSON representation")
	if restored is Dictionary:
		var restored_before: PackedByteArray = var_to_bytes(restored)
		var json_result: Variant = adapter.run_case(restored)
		check(freeze_checked(json_result,id) == expected,id+": JSON-restored input changed complete evidence")
		check(var_to_bytes(restored) == restored_before,id+": simulation changed JSON-restored input")
	for repeat_index: int in 3:
		var repeated: Variant = adapter.run_case(spec)
		check(freeze_checked(repeated,id) == expected,id+": individual repeat changed complete evidence")
	check(freeze_checked(original,id) == expected,id+": later execution mutated a retained result")
	var iterations: int = clampi(int(ceil(float(target_us)/maxi(cold_us,1))),1,256)
	if fixed_iterations.has(id):
		iterations = clampi(int(fixed_iterations[id]),1,10000)
	var durations: Array[int] = []
	var per_call: Array[float] = []
	for sample: int in samples:
		var last: Variant = null
		start = Time.get_ticks_usec()
		for iteration: int in iterations:
			last = adapter.run_case(spec)
		var elapsed: int = Time.get_ticks_usec()-start
		durations.append(elapsed)
		per_call.append(float(elapsed)/iterations)
		check(freeze_checked(last,id) == expected,id+": timed batch changed complete evidence at sample "+str(sample))
		check(var_to_bytes(spec) == original_input,id+": timed batch changed input")
	check(freeze_checked(original,id) == expected,id+": batches mutated the retained original evidence")
	retained.append({"id":id,"actual":original,"expected":expected,"spec":spec,"input_bytes":original_input})
	var ordered: Array[float] = per_call.duplicate()
	ordered.sort()
	return {
		"id":id,"subsystem":str(spec.get("subsystem","")),"description":str(spec.get("description","")),
		"input":spec,"iterations":iterations,"cold_us":cold_us,
		"durations_us":durations,"per_call_us":per_call,
		"median_us":ordered[ordered.size()/2],"min_us":ordered.front(),"max_us":ordered.back(),
		"snapshot_bytes":encoded.to_utf8_buffer().size(),"snapshot_sha256":encoded.sha256_text(),
		"snapshot":expected,
	}
