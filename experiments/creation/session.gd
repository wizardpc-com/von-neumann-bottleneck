extends RefCounted
## Candidate state only; protected works never depend on mutable editor controls.
const Model = preload("res://experiments/creation/model.gd")
const Comparison = preload("res://experiments/creation/comparison.gd")
const Codec = preload("res://experiments/creation/codec.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const WriterRetry = preload("res://experiments/candidate_session/writer_retry.gd")
const UNITS := ["C1_restore","C2_cost","C3_conditions","P1_commit","P2_memory","P3_check","G1_feedback","G2_intent","G3_keep"]
const MAX_DRAFT_HISTORY := 24
var data: Dictionary = fresh()
var dirty: bool = false
var error: String = ""
var prediction: Dictionary = {}
var generated: Dictionary = {}
var last_transport: Dictionary = {}
var path: String = ""
var digest: String = ""
var lease: RefCounted
var _future: Array = []
var _frozen: Dictionary = {}
var _prediction_machine: Dictionary = {}
var _prediction_events: Array = []
var _transport_model: String = ""
var _prediction_model: String = ""
var _transport_runs: Array = []
var _prediction_runs: Array = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []
var _draft_anchor: Dictionary = {}
var _readable_profile: bool = false

func _init() -> void:
	_draft_anchor = _draft_snapshot()

static func default_path() -> String:
	return "user://creation-candidate/session.json"

static func launch_path(arguments: PackedStringArray = []) -> String:
	var selected_path: String = ""
	var launch_arguments: PackedStringArray = OS.get_cmdline_user_args() if arguments.is_empty() else arguments
	for argument: String in launch_arguments:
		if argument.begins_with("--creation-profile="):
			selected_path = argument.trim_prefix("--creation-profile=")
	return default_path() if selected_path.is_empty() else selected_path

static func fresh() -> Dictionary:
	var a: Array = []; var b: Array = []
	for index: int in 24:
		a.append([0,1,0,2][index%4]); b.append([0,1,0,3][index%4])
	return {"version":1,"task":0,"mode":"compress","draft":{"machine":Model.default_machine(),
		"examples":[a,b],"order":1,"initial":[0,1],
		"length":64,"seed":17,"sampler":"weighted"},"model":{},"training":{},"works":[],
		"supports":{},"seen_checks":[],"parent_work":""}

func open(save_path: String = "") -> Dictionary:
	close()
	_reset_exploration()
	path = default_path() if save_path.is_empty() else save_path
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var loaded: Dictionary = Files.read_session(path,decode)
	if not loaded.ok:
		if loaded.has("readonly_works"):
			data = fresh(); data.works = loaded.readonly_works
			error = "raw_restore_readonly" if loaded.get("reason", "") == "raw_restore_evidence" else "incompatible_readonly"
			return {"ok":true,"writable":false,"readonly":true,"error":error}
		error = str(loaded.get("error","read")); return loaded
	data = fresh() if loaded.get("empty",false) else loaded.data
	digest = str(loaded.get("digest",""))
	lease = Lease.new(path)
	dirty = false; error = ""
	_restore_permissions()
	_readable_profile = true; _draft_anchor = _draft_snapshot()
	return {"ok":true,"writable":lease.owns(path),"empty":loaded.get("empty",false)}

func close() -> void:
	if lease != null: lease.release(); lease = null

func _reset_exploration() -> void:
	data = fresh(); dirty = false; error = ""; digest = ""
	prediction.clear(); generated.clear(); last_transport.clear()
	_future.clear(); _frozen.clear(); _prediction_machine.clear(); _prediction_events.clear()
	_transport_model = ""; _prediction_model = ""
	_transport_runs.clear(); _prediction_runs.clear()
	undo_stack.clear(); redo_stack.clear(); _readable_profile = false
	_draft_anchor = _draft_snapshot()

static func _read_profile(save_path: String) -> Dictionary:
	return Files.read_session(save_path,decode)

## Normal retry preserves the live exploration. Reload is only for an explicitly
## confirmed replacement; the UI must confirm that choice before passing true.
func retry_writer(reload_saved: bool = false) -> Dictionary:
	if path.is_empty(): return {"ok":false,"writable":false,"reason":"unreadable"}
	if lease != null and lease.owns(path): return _accept_writer(lease,reload_saved,true)
	var expected: String = digest
	if reload_saved:
		var disk: Dictionary = _read_profile(path)
		if not disk.ok: return {"ok":false,"writable":false,"reason":"unreadable"}
		expected = str(disk.get("digest",""))
	var acquired: Dictionary = WriterRetry.attempt(path,expected,_read_profile)
	if not acquired.ok: return {"ok":false,"writable":false,"reason":acquired.reason}
	return _accept_writer(acquired.lease,reload_saved)

## Reclaim only the exact owner proven stopped by the existing native lease API.
## A readable changed file still requires a separately confirmed reload.
func recover_writer(expected_token: String, reload_saved: bool = false) -> Dictionary:
	if path.is_empty(): return {"ok":false,"writable":false,"reason":"unreadable"}
	if lease != null and lease.owns(path): return _accept_writer(lease,reload_saved,true)
	var disk: Dictionary = _read_profile(path)
	if not disk.ok and disk.get("error","") != "recovery":
		return {"ok":false,"writable":false,"reason":"unreadable"}
	var acquired: Dictionary = Lease.recover_and_acquire(path,expected_token)
	if acquired.get("error",ERR_ALREADY_IN_USE) != OK:
		return {"ok":false,"writable":false,"reason":"busy"}
	return _accept_writer(acquired.lease,reload_saved,true)

func _accept_writer(acquired: RefCounted, reload_saved: bool, allow_recovery: bool = false) -> Dictionary:
	# Re-read while holding ownership. Neither a stale display nor a pre-acquisition
	# read can authorize replacing newer, unknown or interrupted profile bytes.
	var disk: Dictionary = _read_profile(path)
	if not disk.ok:
		if allow_recovery and disk.get("error","") == "recovery":
			lease = acquired
			return {"ok":true,"writable":false,"reason":"recovery","choices":disk.get("choices",[]).duplicate(true),"fingerprint":disk.get("fingerprint","")}
		acquired.release()
		return {"ok":false,"writable":false,"reason":"unreadable"}
	if not reload_saved and str(disk.get("digest","")) != digest:
		acquired.release()
		return {"ok":false,"writable":false,"reason":"changed"}
	lease = acquired
	if reload_saved:
		_reset_exploration()
		data = fresh() if disk.get("empty",false) else disk.data.duplicate(true)
		digest = str(disk.get("digest",""))
		_restore_permissions()
		_readable_profile = true; _draft_anchor = _draft_snapshot()
	return {"ok":true,"writable":true,"reason":""}

func save() -> Error:
	if path.is_empty() or lease == null: return ERR_UNCONFIGURED
	var raw: String = JSON.stringify(data)
	if raw.to_utf8_buffer().size() > Files.MAX_BYTES: error = "size"; return ERR_OUT_OF_MEMORY
	var result: Error = Files.write_session(raw,path,digest,decode,lease)
	if result == OK: digest = raw.sha256_text(); dirty = false; error = ""
	else: error = "save:" + str(result)
	return result

func recover(source: String, fingerprint: String) -> Error:
	if lease == null: lease = Lease.new(path)
	var result: Error = Files.recover_session(path,source,fingerprint,decode,lease)
	if result == OK: open(path)
	return result

func mark_dirty() -> void:
	_record_draft_change()
	dirty = true; generated = {}

func _draft_snapshot() -> Dictionary:
	return {"draft":data.draft.duplicate(true),"model":data.model.duplicate(true),"training":data.training.duplicate(true),"parent_work":data.parent_work,"mode":data.mode,"transport_model":_transport_model,"prediction_model":_prediction_model}

func _record_draft_change() -> void:
	var current: Dictionary = _draft_snapshot()
	if current == _draft_anchor: return
	if _readable_profile and lease != null and lease.owns(path):
		undo_stack.append(_draft_anchor.duplicate(true))
		if undo_stack.size() > MAX_DRAFT_HISTORY: undo_stack.pop_front()
		redo_stack.clear()
	_draft_anchor = current

func can_undo() -> bool:
	return _readable_profile and lease != null and lease.owns(path) and not undo_stack.is_empty()

func can_redo() -> bool:
	return _readable_profile and lease != null and lease.owns(path) and not redo_stack.is_empty()

func _history_writable() -> bool:
	if not _readable_profile or lease == null or not lease.owns(path): return false
	var disk: Dictionary = _read_profile(path)
	return disk.get("ok",false) and str(disk.get("digest","")) == digest

func undo_draft() -> Dictionary:
	return _restore_draft_step(undo_stack,redo_stack)

func redo_draft() -> Dictionary:
	return _restore_draft_step(redo_stack,undo_stack)

func _restore_draft_step(source: Array[Dictionary], destination: Array[Dictionary]) -> Dictionary:
	# This operation is transient: no save, works, supports or seen-check flags are
	# in its snapshots. A future/changed file cannot authorize restoring permissions.
	if not _history_writable(): return {"ok":false,"error":"readonly"}
	if source.is_empty(): return {"ok":false,"error":"history_empty"}
	destination.append(_draft_snapshot())
	if destination.size() > MAX_DRAFT_HISTORY: destination.pop_front()
	var restored: Dictionary = source.pop_back()
	for key: String in ["draft","model","training","parent_work","mode"]:
		data[key] = restored[key].duplicate(true) if restored[key] is Dictionary else restored[key]
	_transport_model = str(restored.transport_model); _prediction_model = str(restored.prediction_model)
	_clear_active_run()
	_draft_anchor = _draft_snapshot(); dirty = true
	return {"ok":true}

func _clear_active_run() -> void:
	prediction.clear(); generated.clear(); last_transport.clear()
	_future.clear(); _frozen.clear(); _prediction_machine.clear(); _prediction_events.clear()

func train() -> Dictionary:
	var previous: String = Model.identity(data.model) if not data.model.is_empty() else ""
	var result: Dictionary = Model.learn(data.draft.examples,int(data.draft.order),data.draft.machine,previous)
	if not result.ok: error = str(result.error); return result
	if previous == Model.identity(result.model): result.model.parent = data.model.get("parent","")
	data.model = result.model.duplicate(true)
	data.training = {"cost":result.cost.duplicate(true),"events":result.events.slice(0,16),"model_id":Model.identity(data.model),"machine":data.draft.machine.duplicate(true)}
	prediction.clear(); _future.clear(); generated.clear(); last_transport.clear()
	_transport_model = ""; _prediction_model = ""; dirty = true
	_record_draft_change()
	return result

func transport(symbols: Array, codec: String) -> Dictionary:
	var result: Dictionary = Codec.run_transport(symbols,data.model,data.draft.machine,codec)
	if result.ok:
		last_transport = result.duplicate(true)
		last_transport["source"] = symbols.duplicate()
		last_transport["machine"] = data.draft.machine.duplicate(true)
		last_transport["codec"] = codec
		last_transport["preparation"] = data.training.get("cost",{}).duplicate(true)
		_transport_runs.append({"kind":"transport","model":data.model.duplicate(true),"machine":data.draft.machine.duplicate(true),"source":symbols.duplicate(),"codec":codec})
		if _transport_runs.size()>8: _transport_runs.pop_front()
		if result.lossless and codec == "predictive" and not data.model.is_empty() and result.get("model_id", "") == Model.identity(data.model):
			_transport_model = Model.identity(data.model)
			_draft_anchor.transport_model = _transport_model
	return last_transport.duplicate(true) if result.ok else result

func set_mode(mode: String) -> Dictionary:
	if mode not in ["compress","predict","generate"]: return {"ok":false,"error":"mode"}
	var identity: String = Model.identity(data.model) if not data.model.is_empty() else ""
	if mode == "predict" and (identity.is_empty() or _transport_model != identity): return {"ok":false,"error":"restore_first"}
	if mode == "generate" and (identity.is_empty() or _prediction_model != identity): return {"ok":false,"error":"predict_first"}
	data.mode = mode; dirty = true
	_draft_anchor.mode = mode
	return {"ok":true,"model_id":identity}

func begin_prediction(kind: String = "practice") -> Dictionary:
	if data.mode != "predict" or data.model.is_empty(): return {"ok":false,"error":"mode"}
	if kind not in ["practice","check","training","memorize","practice-v2","check-v2"]: return {"ok":false,"error":"kind"}
	# Build and validate a complete candidate before replacing the active round.
	# A rejected switch must preserve its old pending guess, truth and cost state.
	var next_model: Dictionary = data.model.duplicate(true)
	var next_machine: Dictionary = data.draft.machine.duplicate(true)
	var next_future: Array = _sequence(kind,next_model)
	if next_future.size() < 3: return {"ok":false,"error":"short_example"}
	var required: int = next_model.examples[0].size()+next_future.size()*2+16 if kind == "memorize" else _prediction_peak(next_model,next_machine,next_future.size())
	if required > next_machine.memory_bytes: return {"ok":false,"error":"memory_limit","required_bytes":required}
	_frozen = next_model; _prediction_machine = next_machine; _future = next_future
	prediction = {"prefix":_future.slice(0,2),"rows":[],"pending":{},"finished":false,"kind":kind,
		"seen":not _check_id(kind).is_empty() and _check_id(kind) in data.seen_checks,"total":_future.size()-2,"hits":0,"model_id":Model.identity(_frozen)}
	_prediction_events = [{"phase":"predict","kind":"model_load","ops":Model.canonical_bytes(_frozen).size(),"bytes":Model.canonical_bytes(_frozen).size(),"cycles":0}]
	if kind == "memorize": _prediction_events = [Model.event("predict","example_load",_frozen.examples[0].size(),_frozen.examples[0].size())]
	return {"ok":true,"state":prediction.duplicate(true)}

func commit_prediction() -> Dictionary:
	if prediction.is_empty() or prediction.finished or not prediction.pending.is_empty(): return {"ok":false,"error":"prediction_state"}
	var result: Dictionary
	if prediction.kind == "memorize":
		var position: int = prediction.prefix.size()
		var example: Array = _frozen.examples[0]
		var symbol: int = int(example[position]) if position<example.size() else 0
		var counts: Array = [0,0,0,0]; counts[symbol] = 1
		result = {"ok":true,"symbol":symbol,"counts":counts,"context":[],"fallback":int(position>=example.size()),
			"events":[Model.event("predict","memorized_position",1,1,{"index":position,"symbol":symbol})]}
	else: result = Model.predict(_frozen,prediction.prefix)
	if not result.ok: return result
	prediction.pending = result.duplicate(true)
	_prediction_events.append_array(result.events.duplicate(true))
	return result.duplicate(true)

func reveal_prediction() -> Dictionary:
	if prediction.is_empty() or prediction.pending.is_empty(): return {"ok":false,"error":"commit_first"}
	var index: int = prediction.prefix.size()
	var truth: int = int(_future[index])
	var guess: Dictionary = prediction.pending
	var row := {"index":index,"predicted":int(guess.symbol),"truth":truth,"correct":int(guess.symbol)==truth,
		"context":guess.context.duplicate(),"counts":guess.counts.duplicate()}
	_prediction_events.append({"phase":"predict","kind":"reveal","ops":2,"bytes":1,"cycles":0,"index":index,"symbol":truth})
	var peak: int = _frozen.examples[0].size()+_future.size()*2+16 if prediction.kind == "memorize" else _prediction_peak(_frozen,_prediction_machine,_future.size())
	var cost: Dictionary = Model.summarize(_prediction_events,_prediction_machine,peak)
	row["cost"] = cost.duplicate(true)
	prediction.rows.append(row); prediction.prefix.append(truth); prediction.pending = {}
	if row.correct: prediction.hits += 1
	if not _check_id(prediction.kind).is_empty() and _check_id(prediction.kind) not in data.seen_checks: data.seen_checks.append(_check_id(prediction.kind)); dirty = true
	prediction.finished = prediction.prefix.size() == _future.size()
	if prediction.finished and prediction.kind != "memorize":
		_prediction_model = prediction.model_id
		_draft_anchor.prediction_model = _prediction_model
		_prediction_runs.append({"kind":"prediction","model":_frozen.duplicate(true),"machine":_prediction_machine.duplicate(true),"check":prediction.kind,"rows":prediction.rows.duplicate(true)})
		if _prediction_runs.size()>8: _prediction_runs.pop_front()
	return {"ok":true,"row":row.duplicate(true),"finished":prediction.finished,"cost":cost}

static func _prediction_peak(model: Dictionary, machine: Dictionary, sequence_length: int) -> int:
	# Cache capacity cannot reserve rows absent from this finite frozen model.
	return Model.canonical_bytes(model).size()+sequence_length*2+16+mini(int(machine.cache_rows),model.rows.size())*11

func prediction_evidence() -> Dictionary:
	# Detached presentation evidence contains only events already committed/revealed.
	# Summarize a copy so inspecting costs cannot mutate the active trace or cache.
	if prediction.is_empty(): return {}
	var events: Array = _prediction_events.duplicate(true)
	var peak: int = _frozen.examples[0].size()+_future.size()*2+16 if prediction.kind == "memorize" else _prediction_peak(_frozen,_prediction_machine,_future.size())
	return {"events":events,"cost":Model.summarize(events,_prediction_machine,peak),
		"recipe":{"model":_frozen.duplicate(true),"model_id":prediction.model_id,"machine":_prediction_machine.duplicate(true)}}

func generate() -> Dictionary:
	if data.mode != "generate" or data.model.is_empty(): return {"ok":false,"error":"mode"}
	var d: Dictionary = data.draft
	var result: Dictionary = Model.generate(data.model,d.initial,int(d.length),int(d.seed),str(d.sampler),d.machine)
	if result.ok:
		generated = result.duplicate(true)
		generated["training"] = data.training.duplicate(true)
		generated["parent_work"] = data.parent_work
	return result

func save_work(title: String, receipt: Dictionary = {}) -> Dictionary:
	if title.strip_edges().is_empty() or title.length()>80: return {"ok":false,"error":"name"}
	if generated.is_empty() or not generated.get("ok",false): return {"ok":false,"error":"generate_first"}
	if data.works.size() >= 12: return {"ok":false,"error":"work_limit"}
	if not receipt.is_empty() and (not _valid_design_receipt(receipt) or not _receipt_contains(receipt,generated)):
		return {"ok":false,"error":"design_evidence"}
	var work := {"name":title.strip_edges(),"output":generated.output.duplicate(),"recipe":generated.recipe.duplicate(true),
		"mapping":"light-shapes-v1","parent":str(generated.parent_work),"training":generated.training.duplicate(true)}
	work["id"] = JSON.stringify(work).sha256_text()
	var previous_works: Array = data.works.duplicate(true)
	var previous_supports: Dictionary = data.supports.duplicate(true)
	var previous_dirty: bool = dirty
	data.works.append(work); dirty = true
	complete("G2_intent",{})
	complete("G3_keep",{})
	if not receipt.is_empty(): data.supports.G2_intent["comparison"] = receipt.duplicate(true)
	elif previous_supports.get("G2_intent",{}).has("comparison"):
		data.supports.G2_intent = previous_supports.G2_intent.duplicate(true)
	var saved: Error = save()
	if saved != OK:
		data.works = previous_works
		data.supports = previous_supports
		dirty = previous_dirty
	return {"ok":saved == OK,"work":work.duplicate(true),"error":"" if saved == OK else error}

func play_work(index: int) -> Dictionary:
	if index<0 or index>=data.works.size(): return {"ok":false,"error":"work_index"}
	var work: Dictionary = data.works[index].duplicate(true)
	return {"ok":true,"output":work.output.duplicate(),"work":work}

func replay_work(index: int) -> Dictionary:
	var saved: Dictionary = play_work(index)
	if not saved.ok: return saved
	var recipe: Dictionary = saved.work.recipe
	var compatible: Dictionary = _validate_recipe(recipe)
	if not compatible.ok: return {"ok":false,"error":"recipe_version","output":saved.output}
	var result: Dictionary = _run_recipe(recipe)
	if result.ok: result["matches"] = result.output == saved.output
	return result

static func _run_recipe(recipe: Dictionary) -> Dictionary:
	return Model.generate(recipe.model,recipe.initial,int(recipe.length),int(recipe.seed),str(recipe.sampler),recipe.machine)

func fork_work(index: int) -> Dictionary:
	if not _history_writable(): return {"ok":false,"error":"readonly"}
	var replay: Dictionary = replay_work(index)
	if not replay.ok or not replay.get("matches",false): return {"ok":false,"error":"incompatible_recipe"}
	var work: Dictionary = data.works[index]
	var r: Dictionary = work.recipe
	data.model = r.model.duplicate(true)
	data.draft = {"machine":r.machine.duplicate(true),"examples":r.model.examples.duplicate(true),"order":int(r.model.order),
		"initial":r.initial.duplicate(),"length":int(r.length),"seed":int(r.seed),"sampler":r.sampler}
	data.training = work.training.duplicate(true); data.parent_work = work.id; data.mode = "generate"
	_record_draft_change(); _clear_active_run(); dirty = true
	return {"ok":true,"parent":work.id}

func complete(unit_id: String, _evidence: Dictionary = {}) -> void:
	if unit_id not in UNITS: return
	var support: Dictionary = {}
	if unit_id.begins_with("C") and not last_transport.is_empty() and last_transport.get("lossless",false):
		if unit_id == "C1_restore" and (last_transport.get("codec", "") != "predictive" or last_transport.get("model_id", "") != Model.identity(data.model)): return
		support = {"kind":"transport","model":data.model.duplicate(true),"machine":last_transport.machine.duplicate(true),
			"source":last_transport.source.duplicate(),"codec":last_transport.codec}
	elif unit_id.begins_with("P") and prediction.get("finished",false) and prediction.kind != "memorize":
		if unit_id == "P3_check" and prediction.kind not in ["check","check-v2"]: return
		support = {"kind":"prediction","model":_frozen.duplicate(true),"machine":_prediction_machine.duplicate(true),"check":prediction.kind,"rows":prediction.rows.duplicate(true)}
	elif unit_id.begins_with("G") and not generated.is_empty():
		support = {"kind":"generation","recipe":generated.recipe.duplicate(true),"output":generated.output.duplicate()}
		if unit_id in ["G2_intent","G3_keep"] and not _kept(data.works,support): return
	if not support.is_empty() and unit_id not in ["C2_cost","C3_conditions","P2_memory"]: data.supports[unit_id] = support; dirty = true
	if unit_id in ["C2_cost","C3_conditions","P2_memory"]:
		var runs: Array = _prediction_runs if unit_id == "P2_memory" else _transport_runs
		for first: int in runs.size():
			for second: int in range(first+1,runs.size()):
				if _comparable(unit_id,runs[first],runs[second]):
					data.supports[unit_id] = {"kind":"comparison","unit":unit_id,"runs":[runs[first].duplicate(true),runs[second].duplicate(true)]}
					dirty = true; return

func _restore_permissions() -> void:
	_transport_model = ""; _prediction_model = ""
	var current: String = Model.identity(data.model) if not data.model.is_empty() else ""
	for support: Dictionary in data.supports.values():
		if support.kind == "transport" and support.codec == "predictive" and Model.identity(support.model) == current: _transport_model = current
		elif support.kind == "prediction" and Model.identity(support.model) == current: _prediction_model = current
		elif support.kind == "comparison":
			for run: Dictionary in support.runs:
				if run.kind == "transport" and run.codec == "predictive" and Model.identity(run.model) == current: _transport_model = current
				elif run.kind == "prediction" and Model.identity(run.model) == current: _prediction_model = current

static func _comparable(unit: String, a: Dictionary, b: Dictionary) -> bool:
	if unit == "P2_memory":
		return a.kind == "prediction" and b.kind == "prediction" and a.check == b.check and a.machine == b.machine and a.model.examples == b.model.examples and a.model.order != b.model.order
	if a.kind != "transport" or b.kind != "transport" or a.source != b.source or Model.identity(a.model) != Model.identity(b.model): return false
	if unit == "C2_cost": return a.codec != b.codec and a.machine == b.machine
	if unit == "C3_conditions":
		if a.codec != b.codec or a.machine == b.machine: return false
		var left: Dictionary = Codec.run_transport(a.source,a.model,a.machine,a.codec)
		var right: Dictionary = Codec.run_transport(b.source,b.model,b.machine,b.codec)
		return left.get("ok",false) and right.get("ok",false) and left.cost != right.cost
	return false

static func _check_id(kind: String) -> String:
	if kind in ["check","memorize"]: return "check-v1"
	if kind == "check-v2": return "check-v2"
	return ""

static func _sequence(kind: String, model: Dictionary) -> Array:
	if kind == "practice-v2": return [0,1,0,2,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,2]
	if kind == "check-v2": return [0,2,0,1,0,2,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,2,0,1]
	if kind == "training": return model.examples[0].duplicate() if not model.get("examples",[]).is_empty() else []
	if kind == "practice": return [0,1,0,2,0,1,0,2,0,1,0,3]
	if kind in ["check","memorize"]: return [0,2,0,1,0,2,0,1,0,2,0,1,0,2,0,1]
	return []

static func _keys(value: Dictionary, allowed: Array) -> bool:
	if value.size() != allowed.size(): return false
	for key: Variant in value:
		if key not in allowed: return false
	return true

static func decode(raw: String) -> Dictionary:
	if raw.to_utf8_buffer().size()>Files.MAX_BYTES: return {"ok":false,"error":"size"}
	var value: Variant = _integers(JSON.parse_string(raw))
	if not value is Dictionary: return {"ok":false,"error":"parse"}
	if value.get("version") != 1: return {"ok":false,"error":"version"}
	if not _keys(value,["version","task","mode","draft","model","training","works","supports","seen_checks","parent_work"]): return {"ok":false,"error":"schema"}
	if not value.task is int or value.task<0 or value.task>=UNITS.size(): return {"ok":false,"error":"schema"}
	if value.mode not in ["compress","predict","generate"] or not value.parent_work is String: return {"ok":false,"error":"schema"}
	if not value.draft is Dictionary or not _keys(value.draft,["machine","examples","order","initial","length","seed","sampler"]): return {"ok":false,"error":"schema"}
	var d: Dictionary = value.draft
	if not d.machine is Dictionary or not _keys(d.machine,["cpu_ops_per_cycle","bytes_per_cycle","request_cycles","memory_bytes","cache_rows"]): return {"ok":false,"error":"schema"}
	if not Model.machine_error(d.machine).is_empty(): return {"ok":false,"error":"schema"}
	if not d.examples is Array or d.examples.size()>16 or not d.initial is Array or d.initial.size()>4096: return {"ok":false,"error":"schema"}
	for sequence: Variant in d.examples+[d.initial]:
		if not sequence is Array or sequence.size()>4096: return {"ok":false,"error":"schema"}
		for symbol: Variant in sequence:
			if not symbol is int or symbol<0 or symbol>3: return {"ok":false,"error":"schema"}
	for key: String in ["order","length","seed"]:
		if not d[key] is int: return {"ok":false,"error":"schema"}
	if d.order<0 or d.order>2 or d.length<0 or d.length>4096 or d.seed<1 or d.seed>2147483646 or d.sampler not in ["weighted","max"]: return {"ok":false,"error":"schema"}
	if not value.model is Dictionary or not value.training is Dictionary or not value.supports is Dictionary or not value.works is Array or value.works.size()>12 or not value.seen_checks is Array: return {"ok":false,"error":"schema"}
	if not value.model.is_empty() and not Model.validate(value.model).is_empty(): return {"ok":false,"error":"schema"}
	if not _valid_training(value.model,value.training): return {"ok":false,"error":"schema"}
	for seen: Variant in value.seen_checks:
		if seen not in ["check-v1","check-v2"]: return {"ok":false,"error":"schema"}
	var incompatible: bool = false
	for work: Variant in value.works:
		if not work is Dictionary or not _keys(work,["id","name","output","recipe","mapping","parent","training"]): return {"ok":false,"error":"schema"}
		if not work.output is Array or work.output.size()>4096 or not work.recipe is Dictionary or not work.name is String or not work.id is String or not work.parent is String or not work.training is Dictionary or work.mapping != "light-shapes-v1": return {"ok":false,"error":"schema"}
		if not Model.symbols_error(work.output).is_empty() or work.name.is_empty() or work.name.length()>80: return {"ok":false,"error":"schema"}
		var result: Dictionary = _validate_recipe(work.recipe)
		if not result.ok:
			if result.error == "version": incompatible = true; continue
			return result
		var original: Dictionary = work.duplicate(true); original.erase("id")
		if JSON.stringify(original).sha256_text() != work.id: return {"ok":false,"error":"schema"}
		var reproduced: Dictionary = _run_recipe(work.recipe)
		if not reproduced.ok or reproduced.output != work.output: return {"ok":false,"error":"schema"}
		if not _valid_training(work.recipe.model,work.training): return {"ok":false,"error":"schema"}
	if incompatible: return {"ok":false,"error":"version","readonly_works":value.works.duplicate(true)}
	var legacy_raw_restore: bool = false
	for id: Variant in value.supports:
		if id not in UNITS or not value.supports[id] is Dictionary: return {"ok":false,"error":"schema"}
		var support: Dictionary = value.supports[id]
		if id in ["C2_cost","C3_conditions","P2_memory"] and support.get("kind") != "comparison": return {"ok":false,"error":"schema"}
		if support.get("kind") == "comparison":
			if not _keys(support,["kind","unit","runs"]) or support.unit != id or id not in ["C2_cost","C3_conditions","P2_memory"] or not support.runs is Array or support.runs.size()!=2: return {"ok":false,"error":"schema"}
			for run: Variant in support.runs:
				if not run is Dictionary or run.get("kind") not in ["transport","prediction"]: return {"ok":false,"error":"schema"}
				var fixture: Dictionary = fresh()
				fixture.seen_checks = value.seen_checks.duplicate()
				if run.kind == "transport":
					if not _valid_transport_support(run): return {"ok":false,"error":"schema"}
				else:
					fixture.supports["P1_commit"] = run
					if not decode(JSON.stringify(fixture)).ok: return {"ok":false,"error":"schema"}
			if not _comparable(id,support.runs[0],support.runs[1]): return {"ok":false,"error":"schema"}
			continue
		if support.get("kind") == "transport":
			if not str(id).begins_with("C"): return {"ok":false,"error":"schema"}
			if not _valid_transport_support(support): return {"ok":false,"error":"schema"}
			if id == "C1_restore" and support.codec != "predictive": legacy_raw_restore = true
		elif support.get("kind") == "prediction":
			if not str(id).begins_with("P"): return {"ok":false,"error":"schema"}
			if not _keys(support,["kind","model","machine","check","rows"]) or not support.model is Dictionary or not support.rows is Array or not support.machine is Dictionary: return {"ok":false,"error":"schema"}
			if support.check not in ["practice","training","check","practice-v2","check-v2"] or (id == "P3_check" and support.check not in ["check","check-v2"]): return {"ok":false,"error":"schema"}
			if not _check_id(support.check).is_empty() and _check_id(support.check) not in value.seen_checks: return {"ok":false,"error":"schema"}
			if not Model.validate(support.model).is_empty() or not Model.machine_error(support.machine).is_empty(): return {"ok":false,"error":"schema"}
			var sequence: Array = _sequence(str(support.check),support.model)
			if sequence.size()<3 or support.rows.size()!=sequence.size()-2: return {"ok":false,"error":"schema"}
			var model_bytes: int = Model.canonical_bytes(support.model).size()
			var checked_events: Array = [{"phase":"predict","kind":"model_load","ops":model_bytes,"bytes":model_bytes,"cycles":0}]
			var peak: int = _prediction_peak(support.model,support.machine,sequence.size())
			var legacy_peak: int = model_bytes+sequence.size()*2+16+int(support.machine.cache_rows)*11
			var recorded_peak: int = -1
			if peak > support.machine.memory_bytes: return {"ok":false,"error":"schema"}
			for index: int in support.rows.size():
				var row: Variant = support.rows[index]
				if not row is Dictionary or not _keys(row,["index","predicted","truth","correct","context","counts","cost"]): return {"ok":false,"error":"schema"}
				var decision: Dictionary = Model.predict(support.model,sequence.slice(0,index+2))
				if row.index != index+2 or row.truth != sequence[index+2] or row.predicted != decision.symbol or row.context != decision.context or row.counts != decision.counts or row.correct != (row.predicted == row.truth): return {"ok":false,"error":"schema"}
				checked_events.append_array(decision.events)
				checked_events.append({"phase":"predict","kind":"reveal","ops":2,"bytes":1,"cycles":0,"index":index+2,"symbol":sequence[index+2]})
				var current_cost: Dictionary = Model.summarize(checked_events,support.machine,peak)
				if row.cost != current_cost:
					# Preserve strictly replayed v1 rounds recorded with the old full-
					# capacity bound. No other cost, insufficient memory or mixed
					# accounting can pass through this compatibility exception.
					if legacy_peak > support.machine.memory_bytes or row.cost != Model.summarize(checked_events,support.machine,legacy_peak): return {"ok":false,"error":"schema"}
				if recorded_peak >= 0 and int(row.cost.peak_bytes) != recorded_peak: return {"ok":false,"error":"schema"}
				recorded_peak = int(row.cost.peak_bytes)
		elif support.get("kind") == "generation":
			if not str(id).begins_with("G"): return {"ok":false,"error":"schema"}
			if not (_keys(support,["kind","recipe","output"]) or (id == "G2_intent" and _keys(support,["kind","recipe","output","comparison"]))) or not support.recipe is Dictionary: return {"ok":false,"error":"schema"}
			var valid: Dictionary = _validate_recipe(support.recipe)
			if not valid.ok: return valid
			var result: Dictionary = _run_recipe(support.recipe)
			if not result.ok or result.output != support.output: return {"ok":false,"error":"schema"}
			if support.has("comparison") and support.comparison is Dictionary and support.comparison.get("version", "") != Comparison.DESIGN_VERSION:
				return {"ok":false,"error":"version","readonly_works":value.works.duplicate(true)}
			if support.has("comparison") and (not support.comparison is Dictionary or not _valid_design_receipt(support.comparison) or not _receipt_contains(support.comparison,support) or not _kept(value.works,support)): return {"ok":false,"error":"schema"}
			if id == "G3_keep" and not _kept(value.works,support): return {"ok":false,"error":"schema"}
		else: return {"ok":false,"error":"schema"}
	if legacy_raw_restore:
		# All works and other supports were checked above. Preserve the original
		# profile read-only; never reinterpret RAW as valid restoration evidence.
		return {"ok":false,"error":"schema","reason":"raw_restore_evidence","readonly_works":value.works.duplicate(true)}
	return {"ok":true,"data":value,"task":int(value.task)}

static func _valid_transport_support(support: Dictionary) -> bool:
	if not _keys(support,["kind","model","machine","source","codec"]): return false
	if not support.model is Dictionary or not support.machine is Dictionary or not support.source is Array or not support.codec is String: return false
	var restored: Dictionary = Codec.run_transport(support.source,support.model,support.machine,support.codec)
	return restored.get("ok",false) and restored.get("lossless",false)

static func _kept(works: Array, support: Dictionary) -> bool:
	for work: Dictionary in works:
		if work.recipe == support.recipe and work.output == support.output: return true
	return false

static func _validate_recipe(recipe: Dictionary) -> Dictionary:
	if recipe.get("version") != 1: return {"ok":false,"error":"version"}
	if not _keys(recipe,["version","model","model_id","machine","initial","length","seed","sampler","sampler_version","prng_version"]): return {"ok":false,"error":"schema"}
	if recipe.sampler_version != "integer-counts-v1" or recipe.prng_version != Model.PRNG_VERSION: return {"ok":false,"error":"version"}
	for key: String in ["model","machine","initial","length","seed","sampler"]:
		if not recipe.has(key): return {"ok":false,"error":"schema"}
	if not recipe.model is Dictionary or not recipe.machine is Dictionary or not recipe.initial is Array or not recipe.length is int or not recipe.seed is int or not recipe.sampler is String: return {"ok":false,"error":"schema"}
	if recipe.model.get("version") != Model.VERSION: return {"ok":false,"error":"version"}
	if not Model.validate(recipe.model).is_empty(): return {"ok":false,"error":"schema"}
	if recipe.model_id != Model.identity(recipe.model): return {"ok":false,"error":"schema"}
	if recipe.model.get("examples",[]).is_empty(): return {"ok":false,"error":"schema"}
	# Provenance replay checks the learned rules, not whether today's generation
	# machine could hold all historical training inputs simultaneously.
	var preparation_machine: Dictionary = Model.default_machine()
	preparation_machine.memory_bytes = 65536
	var learned: Dictionary = Model.learn(recipe.model.examples,int(recipe.model.order),preparation_machine)
	if not learned.ok or Model.identity(learned.model) != recipe.model_id: return {"ok":false,"error":"schema"}
	return {"ok":true}

static func _valid_training(model: Dictionary, training: Dictionary) -> bool:
	if model.is_empty(): return training.is_empty()
	if not _keys(training,["cost","events","model_id","machine"]) or not training.machine is Dictionary: return false
	if not model.get("examples") is Array or model.examples.is_empty(): return false
	var measured: Dictionary = Model.learn(model.examples,int(model.order),training.machine)
	return measured.get("ok",false) and training.model_id == Model.identity(model) and Model.identity(measured.model) == training.model_id and measured.cost == training.cost and measured.events.slice(0,16) == training.events

static func _integers(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floor(value) and abs(value)<9007199254740992.0: return int(value)
	if value is Array:
		for index: int in value.size(): value[index] = _integers(value[index])
	elif value is Dictionary:
		for key: Variant in value: value[key] = _integers(value[key])
	return value

## Optional evidence deepens the existing confirmed-choice G2 without revoking it.
static func design_receipt(first: Dictionary, second: Dictionary) -> Dictionary:
	if not first.has("recipe") or not first.has("output") or not second.has("recipe") or not second.has("output"): return {"ok":false,"error":"generation_required"}
	var receipt: Dictionary = {"version":Comparison.DESIGN_VERSION,
		"a":{"recipe":first.recipe.duplicate(true),"output":first.output.duplicate()},
		"b":{"recipe":second.recipe.duplicate(true),"output":second.output.duplicate()}}
	return {"ok":true,"receipt":receipt} if _valid_design_receipt(receipt) else {"ok":false,"error":"controlled_design_required"}

static func _valid_design_receipt(receipt: Dictionary) -> bool:
	if not _keys(receipt,["version","a","b"]) or receipt.version != Comparison.DESIGN_VERSION: return false
	for key: String in ["a","b"]:
		if not receipt[key] is Dictionary or not _keys(receipt[key],["recipe","output"]): return false
		var snapshot: Dictionary = receipt[key]
		if not snapshot.recipe is Dictionary or not snapshot.output is Array or not _validate_recipe(snapshot.recipe).ok: return false
		var replay: Dictionary = _run_recipe(snapshot.recipe)
		if not replay.get("ok",false) or replay.output != snapshot.output: return false
	return Comparison.compare(receipt.a,receipt.b).get("effective_design",false)

static func _receipt_contains(receipt: Dictionary, snapshot: Dictionary) -> bool:
	for key: String in ["a","b"]:
		if receipt[key].recipe == snapshot.recipe and receipt[key].output == snapshot.output: return true
	return false

func design_provenance() -> Dictionary:
	var support: Dictionary = data.supports.get("G2_intent",{})
	if support.is_empty(): return {"source":"none","observation":false,"observed_change":false}
	if support.has("comparison"):
		var report: Dictionary = Comparison.compare(support.comparison.a,support.comparison.b)
		return {"source":Comparison.DESIGN_VERSION,"observation":true,"observed_change":report.different,"report":report}
	return {"source":"confirmed-choice-no-comparison" if _kept(data.works,support) else "legacy-generation",
		"observation":false,"observed_change":false}
