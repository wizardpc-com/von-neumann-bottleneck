extends SceneTree
const Code = preload("res://experiments/layout_strategy/challenge_code.gd")
const Model = preload("res://experiments/layout_strategy/model.gd")
const Goals = preload("res://experiments/layout_strategy/goals.gd")
const Session = preload("res://experiments/layout_strategy/session.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
var checks: int = 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)


func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("VonNeumannBottleneckChecks/"):
		push_error("Use an isolated verifier profile for challenge codec checks.")
		quit(1)
		return
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	_roundtrips()
	_dormant_and_ordered_plans()
	_strict_transport()
	_strict_goals_and_plans()
	_current_eligibility()
	_actual_comparisons()
	_comparison_guards()
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	before.erase("saved_at_utc")
	after.erase("saved_at_utc")
	check(before == after,"Codec and comparisons never change official progression.")
	for issue: String in failures: push_error(issue)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout strategy challenge code %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)


func _goal(first: int = -1, copy: int = -1, objective: String = "cycles") -> Dictionary:
	return {"objective":objective,"first_limit":first,"copy_limit":copy}


func _plan(group: int = 1, tile: int = 17, fields: Array = []) -> Dictionary:
	var plan: Dictionary = Model.starter_plan()
	plan.query_group = group
	plan.record_tile = tile
	if not fields.is_empty():
		plan.copy_mode = "full"
		plan.copy_fields = fields.duplicate()
	return plan


func _text(envelope: Dictionary) -> String:
	return Code.PREFIX+JSON.stringify(envelope,"",true)


func _changed(source: Dictionary, key: String, value: Variant) -> Dictionary:
	var changed: Dictionary = source.duplicate(true)
	changed[key] = value
	return changed


func _reject(envelope: Dictionary, reason: String, message: String) -> void:
	var decoded: Dictionary = Code.decode(_text(envelope))
	check(not decoded.ok and decoded.reason == reason,message)


func _attempt(task_id: String, plan: Dictionary) -> Dictionary:
	var session = Session.new()
	session.change_task(task_id)
	var result: Dictionary = session.replay(plan)
	check(result.get("valid",false) and result.has("entry"),"Actual Session measurement exists for "+task_id)
	return result.get("entry",{})


func _same_measurement(entry: Dictionary, task_id: String, plan: Dictionary, label: String) -> void:
	var measured: Dictionary = Model.evaluate(Model.scenario(task_id),plan)
	check(measured.valid and measured.run != null,label+" returns an actual independent run.")
	if not measured.valid or measured.run == null: return
	var trace: LayoutRun = measured.run
	var events: Array[Dictionary] = []
	for event: SimulationEvent in trace.events: events.append(event.to_dictionary())
	check(entry.trace_id == trace.canonical_signature().sha256_text(),label+" preserves complete canonical Trace.")
	check(entry.metrics == trace.metrics and entry.correct == trace.passed,label+" preserves real metrics and correctness.")
	check(entry.outputs == trace.output_values and entry.expected == trace.expected_values,label+" preserves ordered output and expectation.")
	check(entry.events == events and entry.source_map == trace.source_map and entry.scratch_maps == trace.scratch_maps,label+" preserves event and address evidence.")


func _roundtrips() -> void:
	for task_id: String in Model.SCENARIO_IDS:
		for objective: String in ["cycles","traffic"]:
			var plan: Dictionary = _plan(1,4,[0])
			var goal: Dictionary = _goal(-1,-1,objective)
			var original: Dictionary = plan.duplicate(true)
			var exported: Dictionary = Code.create(task_id,plan,goal)
			check(exported.ok and exported.code.to_utf8_buffer().size() <= Code.MAX_BYTES,"Bounded actual export: "+task_id+"/"+objective)
			if not exported.ok: continue
			var decoded: Dictionary = Code.decode(exported.code)
			var inspected: Dictionary = Code.inspect(exported.code)
			check(decoded.ok and inspected.ok,"Decode/replay accepts "+task_id+"/"+objective)
			if not inspected.ok: continue
			check(decoded.envelope == exported.envelope and inspected.envelope == decoded.envelope,"Roundtrip retains exact inputs.")
			check(inspected.entry == exported.entry,"Repeated local replay is deterministic.")
			check(exported.challenge_id == String(exported.code).sha256_text(),"Challenge identity binds the canonical code.")
			check(exported.envelope.keys().size() == Code.ENVELOPE_KEYS.size() and exported.entry.keys().size() == Code.ENTRY_KEYS.size(),"Transport has inputs only and measured entry has the frozen shape.")
			check(exported.envelope.goal.objective == objective,"Selected objective survives transport.")
			check(Code.create(task_id,decoded.envelope.plan,decoded.envelope.goal).code == exported.code,"Re-export keeps canonical byte identity.")
			check(plan == original and goal == _goal(-1,-1,objective),"Export does not edit caller inputs.")
			_same_measurement(inspected.entry,task_id,plan,task_id+"/"+objective)
	var target: Dictionary = Code.create("scan_batch",_plan(),_goal())
	var identities: Array[String] = [target.challenge_id]
	for goal: Dictionary in [_goal(10000),_goal(-1,0),_goal(-1,-1,"traffic")]:
		var other: Dictionary = Code.create("scan_batch",_plan(),goal)
		check(other.ok and other.entry.trace_id == target.entry.trace_id,"Changing a challenge rule preserves its measured recipe.")
		check(other.challenge_id not in identities,"Each objective/cap change binds a distinct challenge.")
		identities.append(other.challenge_id)


func _dormant_and_ordered_plans() -> void:
	var dormant: Dictionary = _plan(1,4)
	dormant.copy_fields = [3,1]
	dormant.recipe = {"groups":[{"fields":[3,1],"order":"field"},{"fields":[2,0],"order":"record"}],"block":64}
	var original: Dictionary = dormant.duplicate(true)
	for task_id: String in Model.SCENARIO_IDS:
		var canonical: Dictionary = Code.create(task_id,_plan(1,4),_goal())
		var variant: Dictionary = Code.create(task_id,dormant,_goal())
		check(variant.ok and variant.code == canonical.code,"Dormant copy choices have one transport identity for "+task_id)
		check(variant.entry.plan == _plan(1,4),"No-copy transport reconstructs starter copy defaults.")
		_same_measurement(variant.entry,task_id,dormant,"Dormant "+task_id)
		var noncanonical: Dictionary = canonical.envelope.duplicate(true)
		noncanonical.plan = dormant.duplicate(true)
		_reject(noncanonical,"format","Decode refuses alternate dormant copy spellings.")
	check(dormant == original,"Canonical transport never edits dormant notebook choices.")
	var empty_fields: Dictionary = _plan()
	empty_fields.copy_fields = []
	check(Code.create("scan_batch",empty_fields,_goal()).code == Code.create("scan_batch",_plan(),_goal()).code,"Valid empty dormant field selection has the same code.")
	var advanced: Dictionary = _plan(1,3,[3,0])
	advanced.recipe = {"groups":[{"fields":[1,2],"order":"record"},{"fields":[3,0],"order":"field"}],"block":3}
	var exported: Dictionary = Code.create("mixed_serial",advanced,_goal())
	check(exported.ok,"Existing advanced physical recipe is transportable.")
	if not exported.ok: return
	check(exported.envelope.plan == Model.normalize_plan(advanced),"Copied field order and physical group order remain semantic.")
	_same_measurement(exported.entry,"mixed_serial",advanced,"Advanced copied layout")
	var reordered: Dictionary = advanced.duplicate(true)
	reordered.copy_fields = [0,3]
	var other: Dictionary = Code.create("mixed_serial",reordered,_goal())
	check(other.ok and other.code != exported.code and other.entry.trace_id != exported.entry.trace_id,"Reordering actual source-copy reads changes identity and Trace.")


func _strict_transport() -> void:
	var exported: Dictionary = Code.starter("scan_batch")
	var envelope: Dictionary = exported.envelope
	check(Code.decode(" \t\n"+exported.code+"\r\n").ok,"Clipboard whitespace is stripped after bounding.")
	var padding: int = Code.MAX_BYTES-String(exported.code).to_utf8_buffer().size()
	check(Code.decode(" ".repeat(padding)+exported.code).ok,"Exactly4096 clipboard bytes are accepted.")
	check(Code.decode(" ".repeat(padding+1)+exported.code).reason == "size","Oversize whitespace is rejected before trimming.")
	check(Code.decode("界".repeat(1500)).reason == "size","Byte bound counts UTF-8 rather than glyphs.")
	for raw: String in ["","VNB4C1:{}","https://example.invalid/code","{}"]:
		check(Code.decode(raw).reason == "prefix","Unrelated and formal challenge inputs have no experiment authority.")
	check(Code.decode("VNBSC2:{}").reason == "version","Unknown experimental prefix version is explicit.")
	for raw: String in ["VNBSC1:{","VNBSC1:[]","VNBSC1:null","VNBSC1:{}x","VNBSC1:"+ "[".repeat(17)+"]".repeat(17)]:
		check(Code.decode(raw).reason == "format","Malformed/root/deep JSON input is rejected.")
	for key: String in Code.ENVELOPE_KEYS:
		var missing: Dictionary = envelope.duplicate(true)
		missing.erase(key)
		_reject(missing,"format","No absent envelope field defaults: "+key)
	for key: String in ["score","cycles","trace","correct","rank","author","source","path"]:
		_reject(_changed(envelope,key,1),"format","External "+key+" cannot carry authority.")
	for value: Variant in [0,2,1.5,true,"1",null]:
		_reject(_changed(envelope,"v",value),"version","Version must be exact supported integer1.")
	for value: Variant in ["unknown","",7,true,null]:
		_reject(_changed(envelope,"task",value),"task","Task must name a fixed current workload.")
	for value: Variant in ["","x".repeat(81),"bad\nmodel","bad model","模型",7,true,null]:
		_reject(_changed(envelope,"model",value),"format","Model identifier is a bounded printable token.")
	for value: Variant in ["A".repeat(64),"g".repeat(64),"0".repeat(63),7,true,null]:
		_reject(_changed(envelope,"condition",value),"format","Condition requires lowercase64hex.")
	var stale: Dictionary = _changed(envelope,"model","previous-experiment")
	check(Code.decode(_text(stale)).ok and Code.inspect(_text(stale)).reason == "stale","Old model code remains transportable but cannot be current.")
	stale = _changed(envelope,"condition","0".repeat(64))
	check(Code.decode(_text(stale)).ok and Code.inspect(_text(stale)).reason == "stale","Old full conditions cannot be relabeled by task ID.")
	stale.model = "x".repeat(80)
	check(Code.decode(_text(stale)).ok,"Maximum supported model-token length remains readable.")
	var duplicate: String = String(exported.code).replace('"v":1','"v":1,"v":1')
	check(Code.decode(duplicate).reason == "format","Duplicate top-level JSON keys are rejected.")
	duplicate = String(exported.code).replace('"query_group":1','"query_group":1,"query_group":1')
	check(Code.decode(duplicate).reason == "format","Duplicate nested JSON keys are rejected.")
	check(Code.decode(String(exported.code).replace('"v":1','"v":1.0')).reason == "format","Alternate integral spelling is noncanonical.")
	check(Code.decode(String(exported.code).replace('"query_group":1','"query_group":1e0')).reason == "format","Exponent spelling cannot hide normalization.")
	check(Code.decode(Code.PREFIX+JSON.stringify(envelope,"\t",true)).reason == "format","Prettified payload is outside the canonical transport.")
	check(Code.decode(Code.PREFIX+JSON.stringify(envelope,"",false)).reason == "format","Alternate envelope key order is rejected.")
	var escaped: Dictionary = _changed(envelope,"model",'model"\\[{}]')
	check(Code.decode(_text(escaped)).ok,"Depth bound respects escaped quotes and brackets inside model strings.")
	var maximal: Dictionary = envelope.duplicate(true)
	maximal.model = "x".repeat(80)
	maximal.goal = _goal(Goals.MAX_LIMIT,Goals.MAX_LIMIT,"traffic")
	maximal.plan = _plan(16,64,[3,2,1,0])
	maximal.plan.recipe = {"groups":[{"fields":[3],"order":"record"},{"fields":[2],"order":"field"},{"fields":[1],"order":"record"},{"fields":[0],"order":"field"}],"block":64}
	check(_text(maximal).to_utf8_buffer().size() < Code.MAX_BYTES and Code.decode(_text(maximal)).ok,"Maximum bounded input shape fits the transport without truncation.")


func _strict_goals_and_plans() -> void:
	var envelope: Dictionary = Code.create("scan_batch",_plan(1,4,[0]),_goal()).envelope
	for value: Variant in [null,[],0,"goal",true]:
		_reject(_changed(envelope,"goal",value),"limits","Goal must be an explicit object.")
	for key: String in Goals.KEYS:
		var missing: Dictionary = envelope.goal.duplicate(true)
		missing.erase(key)
		_reject(_changed(envelope,"goal",missing),"limits","Missing goal field is not unlimited: "+key)
	for value: Variant in ["space","first",1,true,null]:
		_reject(_changed(envelope,"goal",_changed(envelope.goal,"objective",value)),"limits","Objective cannot silently fall back to cycles.")
	for key: String in ["first_limit","copy_limit"]:
		for value: Variant in [-2,Goals.MAX_LIMIT+1,0.5,true,"80",null]:
			_reject(_changed(envelope,"goal",_changed(envelope.goal,key,value)),"limits","Caps are bounded integers: "+key)
		for value: Variant in [INF,NAN]:
			check(Code.create("scan_batch",_plan(),_changed(_goal(),key,value)).reason == "limits","In-memory nonfinite cap cannot export.")
	_reject(_changed(envelope,"goal",_changed(envelope.goal,"score",0)),"limits","Nested goal cannot accept a claimed score.")
	for value: Variant in [null,[],0,"plan",true]:
		_reject(_changed(envelope,"plan",value),"plan","Plan must be an explicit object.")
	var plan: Dictionary = envelope.plan
	for key: String in Model.PLAN_KEYS:
		var missing: Dictionary = plan.duplicate(true)
		missing.erase(key)
		_reject(_changed(envelope,"plan",missing),"plan","Missing plan field cannot default: "+key)
	for key: String in ["score","source","orders","future"]:
		_reject(_changed(envelope,"plan",_changed(plan,key,{})),"plan","Unknown nested plan field is rejected: "+key)
	for value: Variant in ["direct","batch","",1,true,null]:
		_reject(_changed(envelope,"plan",_changed(plan,"copy_mode",value)),"plan","Copy mode must match existing model.")
	for key: String in ["query_group","record_tile"]:
		var bound: int = Model.MAX_JOBS if key == "query_group" else Recipe.MAX_RECORDS
		for value: Variant in [0,bound+1,0.5,true,"1",null]:
			_reject(_changed(envelope,"plan",_changed(plan,key,value)),"plan","Plan integer bounds are strict: "+key)
	for value: Variant in [[],[0,0],[4],[-1],[0.5],[true],"0",[0,1,2,3,0]]:
		_reject(_changed(envelope,"plan",_changed(plan,"copy_fields",value)),"plan","Real copied-field subset must be nonempty, unique and bounded.")
	for value: Variant in [-1,65,0.5,true,"0",null]:
		var modified: Dictionary = plan.duplicate(true)
		modified.recipe.block = value
		_reject(_changed(envelope,"plan",modified),"plan","Physical block bound does not default.")
	for recipe: Variant in [
		null,[],{"groups":plan.recipe.groups},{"block":0},
		{"groups":plan.recipe.groups,"block":0,"future":1},
		{"groups":[],"block":0},
		{"groups":[{"fields":[0,0,2,3],"order":"record"}],"block":0},
		{"groups":[{"fields":[0,1,2],"order":"record"}],"block":0},
		{"groups":[{"fields":[0,1,2,3],"order":"record","extra":1}],"block":0},
		{"groups":[{"fields":[0,1,2,3],"order":7}],"block":0},
		{"groups":[{"fields":[0,1,2,true],"order":"field"}],"block":0},
	]:
		_reject(_changed(envelope,"plan",_changed(plan,"recipe",recipe)),"plan","Recipe partition/groups/order reject silent normalization.")
	check(Code.create("unknown",_plan(),_goal()).reason == "task","Create cannot invent workloads.")
	check(Code.create("scan_batch",_changed(_plan(),"record_tile",INF),_goal()).reason == "plan","Nonfinite plan cannot export.")


func _current_eligibility() -> void:
	var group2: Dictionary = _plan(2,1)
	check(Code.create("scan_batch",group2,_goal(339,0)).ok,"Measured Q1 exactly339 satisfies inclusive cap.")
	check(Code.create("scan_batch",group2,_goal(338,0)).reason == "limits","One cycle less excludes otherwise correct target.")
	var copied: Dictionary = _plan(1,17,[0])
	check(Code.create("scan_serial",copied,_goal(557,80)).ok,"Measured copied Q1/space satisfy exact557/80 caps.")
	check(Code.create("scan_serial",copied,_goal(556,80)).reason == "limits","Preparation counts in target Q1.")
	check(Code.create("scan_serial",copied,_goal(557,79)).reason == "limits","One byte below actual allocation excludes target.")
	check(Code.create("scan_batch",_plan(),_goal(0,-1)).reason == "limits","Zero response cap is not unlimited.")
	check(Code.create("scan_batch",_plan(),_goal(-1,0)).ok,"Zero copied bytes admits actual source-only target.")
	var failed: Dictionary = Code.create("scan_serial",_plan(1,17,[0,1,2,3]),_goal())
	check(not failed.ok and failed.reason == "incomplete" and "incomplete" in failed.exclusions,"Zero-cycle allocation failure never exports as a target.")
	var serial: Dictionary = Code.starter("scan_serial").envelope
	serial.plan.query_group = 2
	check(Code.decode(_text(serial)).ok and Code.inspect(_text(serial)).reason == "plan","Structural decode does not silently clamp illegal serial grouping.")
	var oversized_group: Dictionary = Code.starter("scan_batch").envelope
	oversized_group.plan.query_group = 16
	check(Code.decode(_text(oversized_group)).ok and Code.inspect(_text(oversized_group)).reason == "plan","Current job-count validation happens before measuring.")
	for task_id: String in ["scan_batch","scan_serial"]:
		var starter: Dictionary = Code.starter(task_id)
		check(starter.ok and starter.entry.plan == Model.starter_plan(),"Opt-in starter uses ordinary source input for "+task_id)
		check(starter.entry.metrics.first_request_cycles == 307 and starter.entry.metrics.total_cycles == 2456,"Starter metrics are actual direct measurements.")
	for task_id: String in ["mixed_batch","mixed_serial","unknown"]:
		check(Code.starter(task_id).reason == "task","No invented built-in target for "+task_id)


func _actual_comparisons() -> void:
	var target: Dictionary = Code.starter("scan_batch")
	var direct: Dictionary = _attempt("scan_batch",_plan())
	var grouped: Dictionary = _attempt("scan_batch",_plan(2,1))
	var result: Dictionary = Code.compare(target,grouped)
	check(result.status == "improved" and result.delta == -1088 and result.exclusions.is_empty(),"Actual339/1368 grouped run improves the350/0 starter by1088 cycles.")
	result = Code.compare(target,direct)
	check(result.status == "tied" and result.delta == 0,"Exact target replay ties without awarding a strict improvement.")
	var better_target: Dictionary = Code.create("scan_batch",_plan(2,1),_goal(350,0))
	result = Code.compare(better_target,direct)
	check(result.status == "behind" and result.delta == 1088,"Positive actual objective delta means behind.")
	result = Code.compare(target,_attempt("scan_batch",_plan(3,1)))
	check(result.status == "outside" and result.exclusions == ["first"] and not result.has("delta"),"Lower total cannot bypass target Q1 cap.")
	var capped: Dictionary = Code.create("scan_batch",_plan(),_goal(338,0))
	check(Code.compare(capped,grouped).status == "outside","One-cycle-below envelope excludes the same measured attempt.")
	capped = Code.create("scan_batch",_plan(),_goal(339,0))
	check(Code.compare(capped,grouped).status == "improved","Exact boundary admits the same measured attempt.")
	var serial: Dictionary = Code.starter("scan_serial")
	var copied: Dictionary = _attempt("scan_serial",_plan(1,17,[0]))
	result = Code.compare(serial,copied)
	check(result.status == "improved" and result.delta == -1094,"Actual copied serial target improvement is measured under600/80.")
	capped = Code.create("scan_serial",_plan(),_goal(556,79))
	result = Code.compare(capped,copied)
	check(result.status == "outside" and result.exclusions == ["first","copy"] and not result.has("delta"),"Independent immutable caps remain visible.")
	var mixed: Dictionary = Code.create("mixed_batch",_plan(4,1),_goal(600,0,"traffic"))
	result = Code.compare(mixed,_attempt("mixed_batch",_plan(5,1)))
	check(result.status == "improved" and result.delta == -32,"RAM challenge compares actual read plus write bytes.")
	var objective_tie: Dictionary = Code.create("scan_batch",_plan(4,1),_goal())
	var later_response: Dictionary = _attempt("scan_batch",_plan(7,1))
	result = Code.compare(objective_tie,later_response)
	check(later_response.metrics.first_request_cycles > objective_tie.entry.metrics.first_request_cycles and result.status == "tied" and result.delta == 0,"Objective ties do not add an undeclared Q1 tiebreak.")
	var session = Session.new()
	session.edit(_plan(2,1))
	var measured: Dictionary = session.run_current().entry
	session.set_goal(_goal(0,0,"traffic"))
	var before: Dictionary = session._states.duplicate(true)
	var original_target: Dictionary = target.duplicate(true)
	var original_attempt: Dictionary = measured.duplicate(true)
	check(Code.compare(target,measured).status == "improved","Personal Notebook filter cannot redefine an accepted target.")
	check(session._states == before and target == original_target and measured == original_attempt,"Comparison preserves session selection/Undo/goals and both input objects.")
	result = Code.compare(target,_attempt("scan_serial",_plan()))
	check(result.status == "unavailable" and "condition" in result.exclusions and not result.has("delta"),"Equal-looking batch/serial metrics cannot cross full conditions.")
	result = Code.compare(serial,_attempt("scan_serial",_plan(1,17,[0,1,2,3])))
	check(result.status == "unavailable" and not result.has("delta"),"Incomplete zero-cycle copy never beats a target.")


func _comparison_guards() -> void:
	var target: Dictionary = Code.starter("scan_batch")
	var valid: Dictionary = _attempt("scan_batch",_plan(2,1))
	for key: String in Code.ENTRY_KEYS:
		var missing: Dictionary = valid.duplicate(true)
		missing.erase(key)
		var result: Dictionary = Code.compare(target,missing)
		check(result.status == "unavailable" and not result.has("delta"),"Missing attempt evidence is unavailable: "+key)
	for mutation: Dictionary in [
		{"key":"task_id","value":"scan_serial"},{"key":"condition_id","value":"0".repeat(64)},
		{"key":"trace_id","value":""},{"key":"plan","value":{}},
		{"key":"correct","value":"true"},{"key":"correct","value":false},
		{"key":"metrics","value":[]},{"key":"events","value":[]},
		{"key":"outputs","value":[]},{"key":"expected","value":[999]},
		{"key":"source_map","value":[]},{"key":"scratch_maps","value":{}},
	]:
		var attempt: Dictionary = _changed(valid,mutation.key,mutation.value)
		var result: Dictionary = Code.compare(target,attempt)
		check(result.status == "unavailable" and not result.has("delta"),"Malformed/incomplete attempt cannot rank: "+mutation.key)
	for mutation: Dictionary in [
		{"key":"total_cycles","value":1.5},{"key":"total_cycles","value":INF},
		{"key":"ram_read_bytes","value":-1},{"key":"ram_write_bytes","value":true},
		{"key":"first_request_cycles","value":-1},{"key":"first_request_cycles","value":NAN},
		{"key":"error","value":"failed"},{"key":"result_class","value":"partial"},
		{"key":"response_cycles","value":[1]},{"key":"admission_cycles","value":[0]},
	]:
		var attempt: Dictionary = valid.duplicate(true)
		attempt.metrics[mutation.key] = mutation.value
		var result: Dictionary = Code.compare(target,attempt)
		check(result.status == "unavailable" and not result.has("delta"),"Goals rejects invalid actual-summary shape: "+mutation.key)
	for mutation: Dictionary in [
		{"key":"ok","value":false},{"key":"ok","value":1},
		{"key":"code","value":null},{"key":"code","value":"VNB4C1:{}"},
		{"key":"envelope","value":{}},{"key":"challenge_id","value":"0".repeat(64)},
		{"key":"entry","value":null},
	]:
		var bad: Dictionary = _changed(target,mutation.key,mutation.value)
		var result: Dictionary = Code.compare(bad,valid)
		check(result.status == "unavailable" and not result.has("delta"),"Invalid target context cannot rank: "+mutation.key)
	var mismatched: Dictionary = target.duplicate(true)
	mismatched.entry.plan = _plan(2,1)
	check(Code.compare(mismatched,valid).status == "unavailable","Target entry must bind the transported recipe.")
	mismatched = target.duplicate(true)
	mismatched.entry.condition_id = "0".repeat(64)
	check(Code.compare(mismatched,valid).status == "unavailable","Target entry must bind the current full condition.")
	mismatched = target.duplicate(true)
	mismatched.envelope.model = "old-model"
	mismatched.code = _text(mismatched.envelope)
	mismatched.challenge_id = String(mismatched.code).sha256_text()
	check(Code.compare(mismatched,valid).status == "unavailable","A previously inspected target cannot survive a model mismatch.")
