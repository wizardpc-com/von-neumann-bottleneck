extends SceneTree
## QA observations from public samples and sequential Session reveals.
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const Session = preload("res://experiments/creation/session.gd")
var errors: Array[String] = []
var profile: String = ""

func _init() -> void:
	call_deferred("run")

func require_result(result: Dictionary, operation: String) -> bool:
	if result.get("ok", false): return true
	errors.append(operation + ": " + str(result.get("error", "unknown")))
	return false

func prediction_run(session: RefCounted, kind: String) -> Dictionary:
	if not require_result(session.begin_prediction(kind), "begin " + kind): return {}
	var cost: Dictionary = {}
	while not session.prediction.finished:
		if not require_result(session.commit_prediction(), "commit " + kind): return {}
		var revealed: Dictionary = session.reveal_prediction()
		if not require_result(revealed, "reveal " + kind): return {}
		cost = revealed.cost.duplicate(true)
	return {"kind": kind, "model_id": session.prediction.model_id,
		"predictor": "fixed-example-position-v1" if kind == "memorize" else "frozen-context-counts-v1",
		"loaded_state_bytes": session.data.model.examples[0].size() if kind == "memorize" else Model.canonical_bytes(session.data.model).size(),
		"hits": session.prediction.hits, "total": session.prediction.total,
		"accuracy": float(session.prediction.hits) / float(session.prediction.total),
		"seen_check_at_start": session.prediction.seen,
		"revealed_source": session.prediction.prefix.duplicate(),
		"rows": session.prediction.rows.duplicate(true), "cost": cost,
		"scope": "revealed complete QA sequence; not a new independent generalization experiment"}

func prepare_session(name: String, order: int, examples: Array) -> RefCounted:
	var session: RefCounted = Session.new()
	var opened: Dictionary = session.open("user://creation-calibration/" + profile + "/" + name + "/session.json")
	if not require_result(opened, "open " + name): return null
	if not opened.get("empty", false):
		errors.append("profile_not_fresh: " + name); session.close(); return null
	session.data.draft.examples = examples.duplicate(true)
	session.data.draft.order = order
	if not require_result(session.train(), "learn " + name): session.close(); return null
	if not require_result(session.transport(Catalog.source(2), "predictive"), "restore " + name): session.close(); return null
	if not require_result(session.set_mode("predict"), "connect prediction " + name): session.close(); return null
	return session

func learning_report() -> Array:
	var rows: Array = []
	var examples: Array = [Catalog.sample(0), Catalog.sample(1)]
	for order: int in [1, 2]:
		var session: RefCounted = prepare_session("history-" + str(order), order, examples)
		if session == null: continue
		var measured: Array = []
		# Training is the first complete selected example; practice and check are
		# their actual Session sequences. Memorize pays to load the complete first
		# example, then indexes it; no finite-context inference runs in that baseline.
		for kind: String in ["training", "practice", "check", "memorize"]:
			measured.append(prediction_run(session, kind))
		rows.append({"order": order, "examples": examples.duplicate(true),
			"model": session.data.model.duplicate(true), "model_id": Model.identity(session.data.model),
			"model_bytes": Model.canonical_bytes(session.data.model).size(),
			"preparation": session.data.training.duplicate(true), "runs": measured,
			"training_scope": "Session training evaluates selected example 0; both examples contribute counts"})
		session.close()
	return rows

func phase_costs(events: Array) -> Dictionary:
	var phases: Dictionary = {}
	for item: Dictionary in events:
		if not phases.has(item.phase): phases[item.phase] = {"cpu_ops": 0, "transfer_bytes": 0, "cycles": 0}
		phases[item.phase].cpu_ops += item.ops
		phases[item.phase].transfer_bytes += item.bytes
		phases[item.phase].cycles += item.cycles
	return phases

func transport_report() -> Dictionary:
	var machine: Dictionary = Model.default_machine()
	var learned: Dictionary = Model.learn([Catalog.sample(0), Catalog.sample(1)], 2, machine)
	if not require_result(learned, "cost model"): return {}
	var source: Array = Catalog.source(0)
	var narrow: Dictionary = machine.duplicate(true)
	narrow.cpu_ops_per_cycle = 64; narrow.bytes_per_cycle = 1; narrow.cache_rows = 21
	var request_limited: Dictionary = narrow.duplicate(true)
	request_limited.request_cycles = 64
	var cases: Array = []
	for selected: Dictionary in [machine, narrow, request_limited]:
		var raw: Dictionary = Codec.run_transport(source, learned.model, selected, "raw")
		var predictive: Dictionary = Codec.run_transport(source, learned.model, selected, "predictive")
		if not require_result(raw, "RAW transport") or not require_result(predictive, "predictive transport"): continue
		var winner: String = "tie"
		if raw.cost.total_cycles < predictive.cost.total_cycles: winner = "raw"
		elif predictive.cost.total_cycles < raw.cost.total_cycles: winner = "predictive"
		cases.append({"machine": selected.duplicate(true), "winner": winner,
			"raw": {"metrics": raw.metrics.duplicate(true), "cost": raw.cost.duplicate(true), "phases": phase_costs(raw.events), "packet": Array(raw.packet), "lossless": raw.lossless},
			"predictive": {"metrics": predictive.metrics.duplicate(true), "cost": predictive.cost.duplicate(true), "phases": phase_costs(predictive.events), "packet": Array(predictive.packet), "lossless": predictive.lossless}})
	var reversal: bool = false
	if not cases.is_empty():
		for item: Dictionary in cases:
			if item.winner != "tie" and cases[0].winner != "tie" and item.winner != cases[0].winner: reversal = true
	return {"model": learned.model.duplicate(true), "model_id": Model.identity(learned.model),
		"source_kind": 0, "source": source, "preparation": learned.cost.duplicate(true),
		"cases": cases, "winner_reversal": reversal,
		"scope": "same model and source; public machine configurations vary several fields, not a single-variable causal claim"}

func works_report() -> Dictionary:
	var session: RefCounted = prepare_session("works", 2, [Catalog.sample(0), Catalog.sample(1)])
	if session == null: return {}
	if prediction_run(session, "practice").is_empty(): session.close(); return {}
	if not require_result(session.set_mode("generate"), "connect generation"): session.close(); return {}
	session.data.draft.initial = [0, 1]
	session.data.draft.seed = 17
	session.data.draft.length = 64
	session.data.draft.sampler = "weighted"
	if not require_result(session.generate(), "generate first work"): session.close(); return {}
	var first: Dictionary = session.save_work("ABAC 与分岔")
	if not require_result(first, "save first work"): session.close(); return {}
	# Same seed/context/order/length/machine, one selected example changes.
	session.data.draft.examples = [Catalog.sample(0), Catalog.sample(4)]
	if not require_result(session.train(), "change selected example"): session.close(); return {}
	if not require_result(session.transport(Catalog.source(2), "predictive"), "restore changed model"): session.close(); return {}
	if not require_result(session.set_mode("predict"), "predict changed model"): session.close(); return {}
	if prediction_run(session, "practice").is_empty(): session.close(); return {}
	if not require_result(session.set_mode("generate"), "generate changed model"): session.close(); return {}
	if not require_result(session.generate(), "generate second work"): session.close(); return {}
	var second: Dictionary = session.save_work("ABAC 与另一条路")
	if not require_result(second, "save second work"): session.close(); return {}
	var replay_first: Dictionary = session.replay_work(0)
	var replay_second: Dictionary = session.replay_work(1)
	var differences: Array = []
	for index: int in first.work.output.size():
		if first.work.output[index] != second.work.output[index]: differences.append(index)
	var result: Dictionary = {"works": [first.work.duplicate(true), second.work.duplicate(true)],
		"same_seed": first.work.recipe.seed == second.work.recipe.seed,
		"changed": "selected example 1: ABAD to ACAD; other generation settings fixed",
		"different_positions": differences, "snapshots_differ": not differences.is_empty(),
		"recipe_replay_matches": [replay_first.get("matches", false), replay_second.get("matches", false)],
		"scope": "observable symbol/shape differences; no aesthetic score or claim of human preference"}
	session.close()
	return result

func run() -> void:
	var directory: String = OS.get_user_data_dir().replace("\\", "/")
	if not directory.contains("VonNeumannBottleneckChecks/"):
		push_error("Calibration requires an isolated verifier project/profile")
		quit(2); return
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--calibration-profile="): profile = argument.trim_prefix("--calibration-profile=")
	if profile.is_empty() or profile.length() > 64 or not profile.is_valid_filename() or profile.contains(".."):
		push_error("Pass a distinct --calibration-profile=<name>")
		quit(2); return
	var report: Dictionary = {"version": 1, "profile": profile, "engine": Engine.get_version_info(),
		"status": "computed QA observations", "learning": learning_report(),
		"transport": transport_report(), "creation": works_report(), "errors": errors}
	var output: String = "res://.godot/creation-calibration.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output).get_base_dir())
	var file: FileAccess = FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Could not write calibration report"); quit(1); return
	file.store_string(JSON.stringify(report, "\t")); file.close()
	print("CALIBRATION: " + output)
	print("WINNER_REVERSAL: ", report.transport.get("winner_reversal", false))
	print("WORK_SNAPSHOTS_DIFFER: ", report.creation.get("snapshots_differ", false))
	if not errors.is_empty(): print("FAIL: ", errors)
	else: print("PASS: creation calibration observed current public materials")
	quit(0 if errors.is_empty() else 1)
