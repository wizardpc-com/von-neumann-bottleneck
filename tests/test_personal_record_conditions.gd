extends SceneTree
## Actual model results, real controller signals, and isolated journal files.
const Identity = preload("res://src/playtest/task_identity.gd")
const Service = preload("res://experiments/service_plan/model.gd")
const LocalityCore = preload("res://src/simulation/simulation_core.gd")
const Parser = preload("res://src/simulation/dsl_parser.gd")
const Templates = preload("res://src/simulation/program_templates.gd")
const SystemCatalog = preload("res://src/system_lab/system_level_catalog.gd")
var failures: Array[String] = []
var checks: int = 0
var captured: Dictionary = {}

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 3: await process_frame
func capture(event: Dictionary) -> void: captured = event.duplicate(true)
func record_event(chapter: String, level: String, details: Dictionary) -> Dictionary:
	var payload: Dictionary = Identity.metadata(chapter,level)
	payload.merge(details,true)
	payload["passed"] = true
	return {"event":"official_run","mode":"game","payload":payload}
func isolated(name: String) -> Node:
	# Autoload-dependent scripts are loaded after SceneTree startup, as in the app.
	var instance: Node = load("res://src/playtest/personal_records.gd").new()
	instance.storage_path = "user://record-condition-tests/"+name+".json"
	instance._load_records()
	return instance
func write(path: String, text: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(text)
	file.close()
func grouped_service(count: int) -> Dictionary:
	var plan: Dictionary = Service.initial_plan()
	plan.groups = []
	for stream: int in 4:
		for start: int in range(0,6,count):
			var group: Array = []
			for step: int in range(start,mini(6,start+count)): group.append(stream*6+step)
			plan.groups.append(group)
	return plan

func run() -> void:
	DirAccess.make_dir_recursive_absolute("user://record-condition-tests")
	var mode: Node = root.get_node("GameMode")
	var store: Node = root.get_node("PlaytestData")
	var records: Node = isolated("measurements")
	records.best.clear(); records.conditions.clear(); records.legacy.clear()
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	mode.set_mode(&"game")
	var telemetry: bool = store.telemetry_enabled
	store.telemetry_enabled = false
	store.official_result.connect(capture)
	var baseline: RefCounted = Service.run(grouped_service(1))
	var resident: RefCounted = Service.run(grouped_service(2))
	check(Service.accepted(baseline.metrics,0) and Service.accepted(resident.metrics,0) and resident.metrics.total_cycles < baseline.metrics.total_cycles,"Real accepted service plans supply different correct cycle measurements.")
	store.record_official_run(&"service",&"move_state",Service.accepted(baseline.metrics,0),{"total_cycles":baseline.metrics.total_cycles})
	check(captured.payload.model_version == Service.VERSION and captured.payload.case_set_version != "unspecified","Telemetry-disabled local signal receives authored model and case identity.")
	records._observe(captured)
	check(records.best["service/move_state"].cycles == baseline.metrics.total_cycles,"total_cycles is normalized from the real service trace.")
	store.record_official_run(&"service",&"move_state",Service.accepted(resident.metrics,0),{"total_cycles":resident.metrics.total_cycles})
	records._observe(captured)
	store.record_official_run(&"service",&"move_state",Service.accepted(baseline.metrics,0),{"total_cycles":baseline.metrics.total_cycles})
	records._observe(captured)
	check(records.best["service/move_state"].cycles == resident.metrics.total_cycles,"A slower same-condition run cannot replace the observed minimum.")
	check(records.conditions["service/move_state"].size() == 1,"One workload produces one condition bucket.")
	var invalid: Dictionary = captured.duplicate(true)
	for bad_metrics: Dictionary in [{},{"cycles":-1},{"cycles":0.5},{"cycles":NAN},{"cycles":1,"total_cycles":2},{"total_cycles":"0"}]:
		invalid.payload.erase("cycles"); invalid.payload.erase("total_cycles")
		invalid.payload.merge(bad_metrics,true)
		records._observe(invalid)
	check(records.best["service/move_state"].cycles == resident.metrics.total_cycles,"Missing, fractional, nonfinite and conflicting metrics never become zero or a record.")
	var other: Dictionary = captured.duplicate(true)
	other.payload.model_version = "different-model"
	records._observe(other)
	check(records.conditions["service/move_state"].size() == 2,"Changed model creates a distinct condition without overwriting the old minimum.")
	var original_condition: String = records._condition_id(captured.payload)
	check(records.conditions["service/move_state"][original_condition].cycles == resident.metrics.total_cycles,"Previous-model observed minimum stays recoverable.")
	other.payload.case_set_version = "different-workload"
	records._observe(other)
	check(records.conditions["service/move_state"].size() == 3,"Changed workload stays separate even under the same model.")
	records._observe(captured)
	check(records.best["service/move_state"].cycles == resident.metrics.total_cycles and records.best["service/move_state"].model_version == Service.VERSION,"Returning to an earlier condition selects its retained minimum even after a slower run.")
	other.mode = "test"
	other.payload.case_set_version = "test-only-workload"
	records._observe(other)
	check(records.conditions["service/move_state"].size() == 3,"Test observations never enter Game historical conditions.")
	for domain: String in ["creation","prediction"]:
		records._observe(record_event(domain,"exploration",{"total_cycles":1}))
		check(not records.best.has(domain+"/exploration"),"Heterogeneous or temporary "+domain+" results are not durable cycle rankings.")
	var unknown: Dictionary = record_event("chapter_3","arrival",{"cycles":321,"model_version":"unspecified","case_set_version":"old-workload"})
	records._observe(unknown)
	check(records.legacy.has("chapter_3/arrival") and not records.conditions.has("chapter_3/arrival"),"Incomplete identity remains historical instead of receiving a guessed current contract.")
	var core := LocalityCore.new()
	for passes: int in [1,2]:
		var trace: SimulationTrace = core.run_workload(Parser.parse(Templates.ROW_FIRST),LocalityCore.official_data_copy(),1,"Official Test Set",passes,0,false)
		check(trace.passed,"Real locality pass-count workload is correct.")
		records._observe(record_event("chapter_2","nearby_storage",{
			"cycles":trace.metrics.total_cycles,
			"model_version":root.get_node("LocalityChapter").workspace_version(),
			"case_set_version":JSON.stringify([LocalityCore.official_data_copy(),passes]).sha256_text()
		}))
	check(records.conditions["chapter_2/nearby_storage"].size() == 2,"One-pass and two-pass locality measurements never compete.")
	var reloaded: Node = isolated("measurements")
	check(reloaded.conditions == records.conditions and reloaded.best == records.best,"Schema-1 extension survives a real JSON disk round trip.")
	check(reloaded.legacy["chapter_3/arrival"].model_version == "unspecified","Reload cannot fabricate provenance for historical observations.")
	var legacy_path: String = "user://record-condition-tests/legacy.json"
	var legacy_record: Dictionary = {"cycles":17,"case_set_version":"old-cases"}
	write(legacy_path,JSON.stringify({"schema_version":1,"best":{"chapter_1/assembly":legacy_record}}))
	var legacy: Node = isolated("legacy")
	check(legacy.legacy["chapter_1/assembly"] == legacy_record and legacy.conditions.is_empty(),"Original schema-1 records remain readable as historical data.")
	legacy._observe(record_event("chapter_1","assembly",{"cycles":33,"case_set_version":"current-cases"}))
	check(legacy.legacy["chapter_1/assembly"] == legacy_record,"New identified measurements preserve the displaced old summary.")
	for entry: Dictionary in [
		{"name":"future","text":JSON.stringify({"schema_version":99,"best":{},"valuable":"future"})},
		{"name":"corrupt","text":"{valuable unfinished player history"},
		{"name":"unknown","text":JSON.stringify({"schema_version":1,"best":{},"future_feature":{}})},
	]:
		var path: String = "user://record-condition-tests/"+entry.name+".json"
		write(path,entry.text)
		var guarded: Node = isolated(entry.name)
		guarded._observe(record_event("service","move_state",{"total_cycles":resident.metrics.total_cycles}))
		check(not guarded.disk_write_allowed and guarded.storage_status == "read_only","Unsupported "+entry.name+" history becomes read-only.")
		check(FileAccess.get_file_as_string(path) == entry.text,"Unsupported "+entry.name+" original bytes survive an observation.")
		guarded.free()
	nested_history_checks(records,record_event("service","move_state",{"total_cycles":resident.metrics.total_cycles}))
	var failed: Node = isolated("write-failure")
	failed.storage_path = "user://record-condition-tests/missing-directory/no-file.json"
	failed._observe(record_event("service","move_state",{"total_cycles":resident.metrics.total_cycles}))
	check(failed.storage_status == "write_failed" and not failed.last_error.is_empty(),"A real failed temporary-file open exposes write failure.")
	failed.storage_path = "user://record-condition-tests/retry.json"
	failed._observe(record_event("service","move_state",{"total_cycles":resident.metrics.total_cycles}))
	check(failed.storage_status == "ready" and FileAccess.file_exists(failed.storage_path),"An identical observation can retry a failed write.")
	var blocked_path: String = "user://record-condition-tests/destination-directory"
	DirAccess.make_dir_recursive_absolute(blocked_path)
	write(blocked_path+"/preserved.txt","keep")
	failed.storage_path = blocked_path
	check(not failed._save_records() and failed.storage_status == "write_failed","A real failed atomic rename is reported.")
	check(FileAccess.get_file_as_string(blocked_path+"/preserved.txt") == "keep","Failed atomic replacement preserves the existing destination.")
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	before.erase("saved_at_utc"); after.erase("saved_at_utc")
	check(before == after,"Recording and reloading summaries never grants player progress.")
	await verify_system_producer(records)
	store.official_result.disconnect(capture)
	store.telemetry_enabled = telemetry
	records.free(); reloaded.free(); legacy.free(); failed.free()
	print(("PASS" if failures.is_empty() else "FAIL"),": personal record conditions, real measurements, producer qualification and protected persistence — ",checks," checks")
	quit(0 if failures.is_empty() else 1)

func nested_history_checks(records: Node, measurement: Dictionary) -> void:
	var summary: Dictionary = records.conditions["service/move_state"].values()[0].duplicate(true)
	var signature: String = records._condition_id(summary)
	var valid: Dictionary = {
		"schema_version":1,"best":{"service/move_state":summary.duplicate(true)},
		"legacy":{"chapter_1/assembly":{"cycles":17}},
		"conditions":{"service/move_state":{}},
	}
	valid.conditions["service/move_state"][signature] = summary.duplicate(true)
	var fixtures: Array[Dictionary] = []
	for field: String in ["best","legacy"]:
		var task: String = "service/move_state" if field == "best" else "chapter_1/assembly"
		var malformed: Dictionary = valid.duplicate(true)
		malformed[field][task] = []
		fixtures.append({"name":field+"-entry-array","history":malformed})
		var unsupported: Dictionary = valid.duplicate(true)
		unsupported[field][task]["future_record"] = {"valuable":"retain"}
		fixtures.append({"name":field+"-unsupported-field","history":unsupported})
		var mismatch: Dictionary = valid.duplicate(true)
		mismatch[field][task]["level_id"] = "different-task"
		fixtures.append({"name":field+"-identity-mismatch","history":mismatch})
	var bucket_shape: Dictionary = valid.duplicate(true)
	bucket_shape.conditions["service/move_state"] = []
	fixtures.append({"name":"condition-bucket-array","history":bucket_shape})
	var entry_shape: Dictionary = valid.duplicate(true)
	entry_shape.conditions["service/move_state"][signature] = []
	fixtures.append({"name":"condition-entry-array","history":entry_shape})
	var unsupported_condition: Dictionary = valid.duplicate(true)
	unsupported_condition.conditions["service/move_state"][signature]["future_record"] = true
	fixtures.append({"name":"condition-unsupported-field","history":unsupported_condition})
	var nested_summary: Dictionary = valid.duplicate(true)
	nested_summary.best["service/move_state"]["metrics"] = {"cycles":1}
	fixtures.append({"name":"nested-summary-would-be-flattened","history":nested_summary})
	var wrong_identity: Dictionary = valid.duplicate(true)
	wrong_identity.conditions["service/move_state"][signature]["chapter_id"] = "chapter_1"
	fixtures.append({"name":"condition-task-identity-mismatch","history":wrong_identity})
	for invalid_signature: String in ["incorrect-signature",""]:
		var wrong_signature: Dictionary = valid.duplicate(true)
		wrong_signature.conditions["service/move_state"].clear()
		wrong_signature.conditions["service/move_state"][invalid_signature] = summary.duplicate(true)
		fixtures.append({"name":"condition-"+("empty" if invalid_signature.is_empty() else "wrong")+"-signature","history":wrong_signature})
	var missing_identity: Dictionary = valid.duplicate(true)
	missing_identity.conditions["service/move_state"][signature].erase("model_version")
	fixtures.append({"name":"condition-missing-identity","history":missing_identity})
	for invalid_cycles: Variant in ["17",17.5,-1]:
		var bad_metric: Dictionary = valid.duplicate(true)
		bad_metric.legacy["chapter_1/assembly"]["cycles"] = invalid_cycles
		fixtures.append({"name":"historical-cycle-"+str(invalid_cycles),"history":bad_metric})
	var conflicting_cycles: Dictionary = valid.duplicate(true)
	conflicting_cycles.legacy["chapter_1/assembly"]["total_cycles"] = 18
	fixtures.append({"name":"historical-conflicting-cycles","history":conflicting_cycles})
	var bad_key: Dictionary = valid.duplicate(true)
	bad_key.best["chapter_1/"] = {"cycles":17}
	fixtures.append({"name":"empty-task-identity","history":bad_key})
	var truncated_identity: Dictionary = valid.duplicate(true)
	truncated_identity.conditions["service/move_state"][signature]["model_version"] = "x".repeat(81)
	fixtures.append({"name":"overlong-condition-identity","history":truncated_identity})
	for field: String in ["best","legacy","conditions"]:
		var oversized: Dictionary = valid.duplicate(true)
		oversized[field].clear()
		for index: int in 101:
			oversized[field]["chapter_1/fixture_%d" % index] = {} if field == "conditions" else {"cycles":17}
		fixtures.append({"name":"oversized-"+field,"history":oversized})
	var boundary: Dictionary = valid.duplicate(true)
	for index: int in 98:
		boundary.best["chapter_1/fixture_%d" % index] = {"cycles":17}
	for index: int in 7:
		var alternate: Dictionary = summary.duplicate(true)
		alternate.case_set_version = "loaded-workload-%d" % index
		boundary.conditions["service/move_state"][records._condition_id(alternate)] = alternate
	var too_many_conditions: Dictionary = boundary.duplicate(true)
	var ninth: Dictionary = summary.duplicate(true)
	ninth.case_set_version = "loaded-ninth-workload"
	too_many_conditions.conditions["service/move_state"][records._condition_id(ninth)] = ninth
	fixtures.append({"name":"oversized-condition-bucket","history":too_many_conditions})
	var too_many_tasks: Dictionary = boundary.duplicate(true)
	too_many_tasks.legacy["chapter_1/extra-legacy-task"] = {"cycles":17}
	fixtures.append({"name":"oversized-combined-task-keys","history":too_many_tasks})
	for fixture: Dictionary in fixtures:
		var path: String = "user://record-condition-tests/"+fixture.name+".json"
		var original: String = JSON.stringify(fixture.history)
		write(path,original)
		var guarded: Node = isolated(fixture.name)
		guarded._observe(measurement)
		check(not guarded.disk_write_allowed and guarded.storage_status == "read_only","Nested "+fixture.name+" history is read-only after a real measured observation.")
		check(FileAccess.get_file_as_string(path) == original,"Nested "+fixture.name+" original bytes are preserved.")
		guarded.free()
	write("user://record-condition-tests/history-boundary.json",JSON.stringify(boundary))
	var loaded: Node = isolated("history-boundary")
	check(loaded.disk_write_allowed and loaded.storage_status == "ready" and loaded.best.size() == 99 and loaded.conditions["service/move_state"].size() == 8,"Exactly 100 distinct task keys and eight conditions remain supported with legacy summaries.")
	var boundary_bytes: String = FileAccess.get_file_as_string(loaded.storage_path)
	var overflow: Dictionary = measurement.duplicate(true)
	overflow.payload.level_id = "new-task-over-capacity"
	loaded._observe(overflow)
	check(not loaded.best.has("service/new-task-over-capacity") and FileAccess.get_file_as_string(loaded.storage_path) == boundary_bytes,"A new task cannot exceed the combined loaded history bound or write an unreadable future file.")
	var current: Dictionary = measurement.duplicate(true)
	current.payload.case_set_version = "boundary-new-measured-workload"
	loaded._observe(current)
	check(loaded.storage_status == "ready" and FileAccess.get_file_as_string(loaded.storage_path) != boundary_bytes,"An existing task can still save a new measured condition at the loaded history bounds.")
	var boundary_reload: Node = isolated("history-boundary")
	check(boundary_reload.storage_status == "ready" and boundary_reload.conditions == loaded.conditions,"Saving at the boundary preserves a readable supported history.")
	boundary_reload.free()
	loaded.free()
	var live: Node = isolated("live-condition-eviction")
	var first_signature: String = ""
	for index: int in 9:
		var observed: Dictionary = measurement.duplicate(true)
		observed.payload.case_set_version = "live-workload-%d" % index
		if index == 0: first_signature = live._condition_id(observed.payload)
		live._observe(observed)
	check(live.storage_status == "ready" and live.conditions["service/move_state"].size() == 8 and not live.conditions["service/move_state"].has(first_signature),"Nine new valid observations still apply normal eight-condition eviction.")
	var live_reload: Node = isolated("live-condition-eviction")
	check(live_reload.storage_status == "ready" and live_reload.conditions == live.conditions,"Normally evicted valid condition history remains writable after reload.")
	live_reload.free()
	live.free()

func verify_system_producer(records: Node) -> void:
	var mode: Node = root.get_node("GameMode")
	mode.set_mode(&"test")
	root.get_node("SystemChapter").reset_test_progress()
	var host: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(host); await settle()
	host._start_level(&"cpu_speed")
	host.editor.text = str(host.current_level_definition.program_source).replace("store(OUTPUT[0], acc)","acc += 0\nstore(OUTPUT[0], acc)")
	host._on_program_changed(); host._apply_program()
	host.prediction_selector.select(1); host._lock_prediction()
	host.part_selectors[&"cpu"].select(1); host._on_part_selected(1,&"cpu")
	captured.clear()
	host._run_official(); host._finish_playback(); await settle()
	check(host.latest_receipt != null and host.latest_receipt.all_passed,"Actual custom authored-program-task run remains numerically correct.")
	check(not captured.is_empty() and captured.payload.qualified_for_progression == false,"Actual controller marks the custom observation as debug-only.")
	if not captured.is_empty():
		var event: Dictionary = captured.duplicate(true)
		event.mode = "game"
		records._observe(event)
	check(not records.best.has("chapter_1/cpu_speed"),"Debug-only output cannot enter accepted personal records.")
	var catalog := SystemCatalog.new()
	var accepted: Dictionary = {}
	for cpu: StringName in [&"cpu_eco",&"cpu_balanced",&"cpu_fast"]:
		for ram: StringName in [&"ram_slow",&"ram_balanced",&"ram_fast"]:
			for bus: StringName in [&"bus_2",&"bus_4",&"bus_8"]:
				var parts: Dictionary = {&"cpu":cpu,&"ram":ram,&"bus":bus}
				for order: String in ["compute","move"]:
					var source: String = SystemCatalog.PROGRAM_CPU if order == "compute" else SystemCatalog.PROGRAM_COPY
					var receipt: SystemRunReceipt = catalog.replay_application(&"two_orders",source,parts)
					if catalog.completion_status(&"two_orders",[receipt]).progress == 1:
						accepted[order] = parts.duplicate(true)
	check(accepted.size() == 2,"Real application enumeration finds accepted distinct order machines.")
	host._start_level(&"two_orders")
	var case_signatures: Array[String] = []
	for index: int in 2:
		var order: String = ["compute","move"][index]
		host._select_order(index)
		host.selected_part_ids.clear()
		for kind: StringName in accepted[order]:
			host.selected_part_ids[kind] = StringName(accepted[order][kind])
		host._populate_part_selectors()
		host.current_topology = host._topology_from_graph()
		captured.clear()
		host._run_official(); host._finish_playback(); await settle()
		check(not captured.is_empty() and captured.payload.passed,"Actual "+order+" controller run meets its authored target.")
		if index == 1: check(not host.run_comparison.visible,"Changing the executed order suppresses an incomparable immediate cycle delta.")
		if not captured.is_empty():
			case_signatures.append(captured.payload.case_set_version)
			var event: Dictionary = captured.duplicate(true)
			event.mode = "game"
			records._observe(event)
	check(case_signatures.size() == 2 and case_signatures[0] != case_signatures[1],"Actual compute and move controller events describe their executed workload separately.")
	check(records.conditions.get("chapter_1/two_orders",{}).size() == 2,"Both accepted orders retain independent cycle records.")
	host.queue_free(); await settle()
