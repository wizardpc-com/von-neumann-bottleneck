extends SceneTree
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
const Session = preload("res://experiments/creation/session.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func repeated(symbols: Array, copies: int) -> Array:
	var output: Array = []
	for i: int in copies: output.append_array(symbols)
	return output

func reseal(packet: PackedByteArray) -> PackedByteArray:
	var body: PackedByteArray = packet.slice(0,packet.size()-32)
	body.append_array(Model.digest(body))
	return body

func account(result: Dictionary, label: String) -> void:
	var cycles: int = 0
	var operations: int = 0
	var traffic: int = 0
	for event: Dictionary in result.events:
		cycles += int(event.cycles)
		operations += int(event.ops)
		traffic += int(event.bytes)
	check(result.cost.total_cycles == cycles and result.cost.cpu_ops == operations and result.cost.transfer_bytes == traffic,label+" costs are actual event sums")

func learning_and_feedback(machine: Dictionary) -> Dictionary:
	var examples: Array = [repeated([0,1],12)]
	var learned: Dictionary = Model.learn(examples,1,machine)
	check(learned.ok,"Training a selected complete example succeeds")
	if not learned.ok: return {}
	account(learned,"training")
	var model: Dictionary = learned.model
	var identity: String = Model.identity(model)
	examples[0][1] = 3
	check(Model.identity(model) == identity and model.examples[0][1] == 1,"Learned snapshot owns its example bytes independently")
	var different: Dictionary = Model.learn([repeated([0,2],12)],1,machine,identity)
	check(different.ok and Model.identity(different.model) != identity and different.model.parent == identity,"Changing training example creates a real child model")
	check(Model.predict(model,[0]).symbol == 1 and Model.predict(different.model,[0]).symbol == 2,"Changed example changes actual successor")
	var separate: Dictionary = Model.learn([[0],[1]],1,machine)
	check(separate.ok and Model.predict(separate.model,[0]).context.is_empty(),"Independent examples do not invent an end-to-start transition")
	var first: Array = [0,1,0,1,0,1,0,1]
	var second: Array = [0,1,0,1,3,3,3,3]
	for index: int in 5:
		check(Model.predict(model,first.slice(0,index)) == Model.predict(model,second.slice(0,index)),"Unrevealed suffix cannot change committed prefix prediction")
	for truth: int in [3,2,3,0]:
		Model.predict(model,first)
		first.append(truth)
	check(Model.identity(model) == identity,"Revealing truth moves history without training frozen rules")
	var generated: Dictionary = Model.generate(model,[0],16,71,"max",machine)
	var changed: Dictionary = Model.generate(different.model,[0],16,71,"max",machine)
	check(generated.ok and generated.output == repeated([0,1],8),"Generator feeds its own output into the learned alternating successor")
	check(changed.ok and changed.output == repeated([0,2],8),"Selected learned model changes actual generated work")
	account(generated,"generation")
	var varied: Dictionary = Model.learn([[0,0,1,2,3]],0,machine)
	var sampled: Dictionary = Model.generate(varied.model,[],32,987,"weighted",machine)
	check(sampled.ok and sampled.output == Model.generate(varied.model,[],32,987,"weighted",machine).output and sampled.output != Model.generate(varied.model,[],32,988,"weighted",machine).output,"Dedicated versioned random state reproduces and changes actual output")
	var recipe: Dictionary = sampled.recipe.duplicate(true)
	check(Model.generate(recipe.model,recipe.initial,recipe.length,recipe.seed,recipe.sampler,recipe.machine).output == sampled.output and recipe.model.examples == varied.model.examples,"Complete generation recipe owns reproducible model and training snapshots")
	check(not Model.generate(recipe.model,[0,1],2,17,"weighted",recipe.machine).ok,"A work cannot be only the supplied seed without a model-generated symbol")
	check(Model.identity(model) == identity,"Generation does not train on its own output")
	print("CALIBRATION generation parent=",identity," first=",generated.output," child=",changed.output," cycles=",generated.cost.total_cycles)
	return model

func packages(model: Dictionary, machine: Dictionary) -> void:
	for source: Array in [[],[3],repeated([0,1],16),[3,3,2,0,1,3,2,2,0]]:
		for mode: String in ["raw","predictive"]:
			var encoded: Dictionary = Codec.encode(source,model,machine,mode)
			check(encoded.ok,"Legal "+mode+" input produces a real packet")
			if not encoded.ok: continue
			var receiver: Dictionary = Codec.decode(encoded.packet.duplicate(),machine)
			check(receiver.ok and receiver.output == source,"Receiver reconstructs only from "+mode+" packet, including empty/mismatch histories")
			check(encoded.metrics.packet_bytes == encoded.packet.size(),"Reported transfer packet counts all actual header/model/payload/integrity bytes")
			if mode == "raw": check(encoded.metrics.payload_bits == source.size()*2,"RAW comparison uses the same fair two-bit symbols")
			account(encoded,"encode "+mode)
			account(receiver,"decode "+mode)
			var damaged: PackedByteArray = encoded.packet.duplicate()
			damaged[damaged.size()-1] = damaged[-1] ^ 1
			check(not Codec.decode(damaged,machine).ok and not Codec.decode(encoded.packet.slice(0,encoded.packet.size()-1),machine).ok,"Integrity damage and truncation are rejected")
	var bytes: PackedByteArray = Model.canonical_bytes(model)
	check(Model.from_bytes(bytes).ok and Model.identity(Model.from_bytes(bytes).model) == Model.identity(model),"Canonical frozen rules recover without the training file")
	check(not Model.from_bytes(bytes.slice(0,bytes.size()-1)).ok,"Truncated frozen rules are rejected")
	check(not Codec.encode([4],model,machine).ok,"Out-of-alphabet input is rejected")
	var broken: PackedByteArray = PackedByteArray([255,0,1])
	check(not Codec.decode(broken,machine).ok,"Unknown format cannot fall back to an external answer")
	var raw: PackedByteArray = Codec.encode([3],model,machine,"raw").packet
	var wrong_padding: PackedByteArray = raw.duplicate(); wrong_padding[20] = wrong_padding[20] | 1
	check(not Codec.decode(reseal(wrong_padding),machine).ok,"Nonzero unused payload padding is rejected even with a valid checksum")
	var unknown: PackedByteArray = raw.duplicate(); unknown[4] = 2
	check(not Codec.decode(reseal(unknown),machine).ok,"Future packet version remains rejected after valid integrity")
	var beyond_limit: PackedByteArray = raw.duplicate(); beyond_limit[8] = 1; beyond_limit[9] = 16
	check(not Codec.decode(reseal(beyond_limit),machine).ok,"Declared sequence beyond public bounds is rejected")
	var missing_model: PackedByteArray = Codec.encode([0,1],model,machine).packet
	for index: int in range(12,16): missing_model[index] = 0
	check(not Codec.decode(reseal(missing_model),machine).ok,"Predictive packet cannot borrow a missing model from elsewhere")
	var empty_rule: PackedByteArray = Codec.encode([0,1],model,machine).packet
	for index: int in range(61,69): empty_rule[index] = 0
	check(not Codec.decode(reseal(empty_rule),machine).ok,"Malformed carried rule counts are rejected rather than repaired silently")

func cost_counterexamples(machine: Dictionary) -> void:
	var trained: Dictionary = Model.learn([repeated([0],16)],0,machine)
	if not trained.ok: check(false,"Counterexample model learns"); return
	var model: Dictionary = trained.model
	var short_raw: Dictionary = Codec.run_transport([0],model,machine,"raw")
	var short_predictive: Dictionary = Codec.run_transport([0],model,machine,"predictive")
	check(short_raw.ok and short_predictive.ok and short_predictive.metrics.packet_bytes > short_raw.metrics.packet_bytes,"Short sample loses after real model and metadata overhead")
	var source: Array = repeated([0],4096)
	var raw: Dictionary = Codec.run_transport(source,model,machine,"raw")
	var predictive: Dictionary = Codec.run_transport(source,model,machine,"predictive")
	check(raw.ok and predictive.ok and predictive.metrics.packet_bytes < raw.metrics.packet_bytes,"Long repeated sample actually compresses relative to packed RAW")
	check(predictive.cost.total_cycles > raw.cost.total_cycles,"A smaller packet can run slower because real rule computation remains")
	var narrow: Dictionary = machine.duplicate(true)
	narrow.bytes_per_cycle = 1
	narrow.cpu_ops_per_cycle = 64
	narrow.request_cycles = 64
	var narrow_run: Dictionary = Codec.run_transport(source,model,narrow,"predictive")
	var narrow_raw: Dictionary = Codec.run_transport(source,model,narrow,"raw")
	check(narrow_run.ok and narrow_run.output == predictive.output and narrow_run.cost != predictive.cost,"Inherited machine throughput changes actual execution while preserving output")
	check(narrow_raw.ok and narrow_run.cost.total_cycles < narrow_raw.cost.total_cycles,"Real request latency reverses the measured codec preference")
	var too_small: Dictionary = machine.duplicate(true); too_small.memory_bytes = 64
	var refused: Dictionary = Model.learn([source],2,too_small)
	check(not refused.ok and refused.error == "memory_limit" and refused.required_bytes > 64,"Legal finite memory refuses real training state instead of pruning silently")
	account(raw,"RAW transport"); account(predictive,"predictive transport")
	print("CALIBRATION short raw/predictive bytes=",short_raw.metrics.packet_bytes,"/",short_predictive.metrics.packet_bytes,"; long bytes=",raw.metrics.packet_bytes,"/",predictive.metrics.packet_bytes," cycles=",raw.cost.total_cycles,"/",predictive.cost.total_cycles,"; high-request-latency RAW/predictive cycles=",narrow_raw.cost.total_cycles,"/",narrow_run.cost.total_cycles)

func session_contract() -> void:
	var session := Session.new()
	check(session.open("user://creation-contract/session.json").ok,"Independent candidate profile opens")
	session.complete("G3_keep",{"passed":true})
	check(session.data.supports.is_empty() and not session.set_mode("generate").ok,"UI success flags cannot create supported completion or skip feedback modes")
	check(session.train().ok and session.transport([0,1,0,2],"predictive").lossless,"Live session trains and recovers an actual carried model")
	var identity: String = Model.identity(session.data.model)
	check(session.set_mode("predict").ok and session.begin_prediction("check").ok,"Recovered model enters the frozen-check mode")
	check(not session.reveal_prediction().ok and session.prediction.rows.is_empty(),"Truth cannot be revealed before a committed prediction")
	var committed: Dictionary = session.commit_prediction()
	check(committed.ok and not committed.has("truth") and session.prediction.prefix.size() == 2 and session.prediction.rows.is_empty(),"Commit exposes neither future truth nor final metrics")
	var chosen: int = committed.symbol; committed.symbol = (chosen+1)%4
	check(session.reveal_prediction().row.predicted == chosen,"Editing returned observation cannot change the already locked prediction")
	while not session.prediction.finished:
		check(session.commit_prediction().ok and session.reveal_prediction().ok,"Each remaining step commits before revealing truth")
	check(Model.identity(session.data.model) == identity,"Frozen check leaves sample-derived model unchanged")
	session.complete("P3_check")
	var original_support: Dictionary = session.data.supports.P3_check.duplicate(true)
	check(session.begin_prediction("check").state.seen,"A replayed revealed check is honestly marked already seen")
	check(session.set_mode("generate").ok and session.generate().ok,"Same checked model enters output feedback")
	session.complete("G3_keep")
	check(not session.data.supports.has("G3_keep"),"Generated output alone cannot claim a saved work")
	var kept: Dictionary = session.save_work("QA model-owned pattern")
	check(kept.ok and kept.work.recipe.model_id == identity,"Kept work owns the actual inherited model")
	if kept.ok:
		var snapshot: Array = kept.work.output.duplicate()
		session.data.draft.initial = [3]; session.mark_dirty()
		check(session.play_work(0).output == snapshot and session.replay_work(0).matches,"Changing live controls leaves saved output and complete recipe unchanged")
		var future: Dictionary = session.data.duplicate(true); future.works[0].recipe.version = 99
		var future_raw: String = JSON.stringify(future)
		var future_path: String = "user://creation-contract/future-recipe.json"
		var file := FileAccess.open(future_path,FileAccess.WRITE); file.store_string(future_raw); file.close()
		var reader := Session.new(); var status: Dictionary = reader.open(future_path)
		check(status.ok and not status.writable and reader.play_work(0).output == snapshot,"Future recipe keeps its output snapshot accessible read-only")
		check(not reader.replay_work(0).ok and reader.save() != OK and FileAccess.get_file_as_string(future_path) == future_raw,"Incompatible recipe cannot regenerate, overwrite or relabel the saved work")
		reader.close()
		future = session.data.duplicate(true); future.works[0].recipe.model.version = 2
		future_raw = JSON.stringify(future); future_path = "user://creation-contract/future-model.json"
		file = FileAccess.open(future_path,FileAccess.WRITE); file.store_string(future_raw); file.close()
		reader = Session.new(); status = reader.open(future_path)
		check(status.ok and not status.writable and reader.play_work(0).output == snapshot,"Future nested model version preserves its existing work snapshot read-only")
		check(not reader.replay_work(0).ok and reader.save() != OK and FileAccess.get_file_as_string(future_path) == future_raw,"Future model recipe cannot replay or rewrite the original saved bytes")
		reader.close()
		future = session.data.duplicate(true); future.works[0].recipe.future_feedback = "unknown"
		check(not Session.decode(JSON.stringify(future)).ok,"Unknown recipe fields cannot be stripped through a normal save")
		future = session.data.duplicate(true); future.works[0].recipe.model.erase("examples")
		check(not Session.decode(JSON.stringify(future)).ok,"A source digest alone cannot replace the full recipe's immutable example content")
		future = session.data.duplicate(true); future.works[0].recipe.model.examples = []
		var renamed: Dictionary = future.works[0].duplicate(true); renamed.erase("id")
		future.works[0].id = JSON.stringify(renamed).sha256_text()
		check(not Session.decode(JSON.stringify(future)).ok,"A valid work digest with empty training content still fails complete recipe provenance")
		future = session.data.duplicate(true); future.works[0].recipe.machine.future_feedback = 1
		renamed = future.works[0].duplicate(true); renamed.erase("id")
		future.works[0].id = JSON.stringify(renamed).sha256_text()
		check(not Session.decode(JSON.stringify(future)).ok,"Future machine fields cannot claim compatibility by resealing the work digest")
	var forged: Dictionary = session.data.duplicate(true)
	forged.supports.P3_check = original_support.duplicate(true)
	forged.supports.P3_check.rows[0].predicted = (int(forged.supports.P3_check.rows[0].predicted)+1)%4
	check(not Session.decode(JSON.stringify(forged)).ok,"Tampered saved prediction evidence cannot grant current-model progress")
	forged = session.data.duplicate(true); forged.supports.P3_check = original_support.duplicate(true)
	forged.supports.P3_check.rows[0].cost.total_cycles += 1
	check(not Session.decode(JSON.stringify(forged)).ok,"Tampered saved prediction cost ledger must fail independent revalidation")
	forged = session.data.duplicate(true); forged.works = []
	check(not Session.decode(JSON.stringify(forged)).ok,"Saved-work completion cannot survive removing its actual work snapshot")
	forged = session.data.duplicate(true); forged.seen_checks = []
	check(not Session.decode(JSON.stringify(forged)).ok,"A retained revealed check cannot be relabelled as unseen")
	check(session.set_mode("predict").ok and session.begin_prediction("training").ok,"Training-support counterexample uses a real completed model prediction")
	finish_prediction(session); session.complete("P1_commit")
	check(Session.decode(JSON.stringify(session.data)).ok,"Actual training prediction remains legal P1 support")
	forged = session.data.duplicate(true); forged.supports.P3_check = forged.supports.P1_commit.duplicate(true)
	check(not Session.decode(JSON.stringify(forged)).ok,"Renaming genuine training support cannot award an independent check")
	session.close()

func finish_prediction(session: RefCounted) -> void:
	var legal: bool = true
	while not session.prediction.finished:
		legal = session.commit_prediction().ok and session.reveal_prediction().ok and legal
	check(legal,"Comparison records come from complete commit/reveal execution")

func comparison_contract() -> void:
	var session := Session.new()
	check(session.train().ok and session.transport([0,1,0,2],"predictive").ok,"Comparison fixture executes an actual learned predictive transport")
	session.complete("C2_cost"); session.complete("C3_conditions")
	check(not session.data.supports.has("C2_cost") and not session.data.supports.has("C3_conditions"),"One transport cannot masquerade as a codec or machine comparison")
	check(session.transport([0,1,0,2],"raw").ok,"Fair RAW comparison really executes")
	session.complete("C2_cost")
	check(session.data.supports.get("C2_cost",{}).get("kind","") == "comparison","Same source/model/machine with different codecs earns measured comparison support")
	session.data.draft.machine.cpu_ops_per_cycle = 1
	check(session.transport([0,1,0,2],"predictive").ok,"Changed machine runs the same actual predictive job")
	session.complete("C3_conditions")
	check(session.data.supports.get("C3_conditions",{}).get("kind","") == "comparison","Different measured machine cost earns conditions support")
	var forged: Dictionary = session.data.duplicate(true)
	forged.supports.C2_cost.runs[1].source.append(3)
	check(not Session.decode(JSON.stringify(forged)).ok,"Editing one saved comparison input invalidates its same-input claim")
	check(session.set_mode("predict").ok and session.begin_prediction("practice").ok,"First memory comparison uses the restored one-symbol model")
	finish_prediction(session); var first_hits: int = session.prediction.hits
	session.complete("P2_memory")
	check(not session.data.supports.has("P2_memory"),"One completed prediction is insufficient for a memory comparison")
	session.data.draft.order = 2
	check(session.train().ok and session.transport([0,1,0,2],"predictive").ok,"Longer-context model is actually learned and carried through recovery")
	check(session.set_mode("predict").ok and session.begin_prediction("practice").ok,"Second memory comparison uses the same authored practice")
	finish_prediction(session); var second_hits: int = session.prediction.hits
	session.complete("P2_memory")
	check(session.data.supports.get("P2_memory",{}).get("kind","") == "comparison" and Session.decode(JSON.stringify(session.data)).ok,"Same examples/machine/check and changed order retains independently revalidatable memory evidence")
	forged = session.data.duplicate(true); forged.supports.P2_memory.runs[1].check = "check"
	check(not Session.decode(JSON.stringify(forged)).ok,"Different practice/check sources cannot be relabelled as a controlled memory comparison")
	print("CALIBRATION memory order1/order2 same-practice hits=",first_hits,"/",second_hits," of ",session.prediction.total)

func failed_round_and_raw_contract() -> void:
	var session = Session.new()
	check(session.train().ok, "Regression model learns")
	check(session.transport([0,1,0,2],"raw").ok, "RAW still transports losslessly")
	session.complete("C1_restore")
	check(not session.data.supports.has("C1_restore") and not session.set_mode("predict").ok, "RAW neither earns C1 nor restores a predictive model")
	var forged: Dictionary = session.data.duplicate(true)
	forged.supports.C1_restore = session._transport_runs[0].duplicate(true)
	check(not Session.decode(JSON.stringify(forged)).ok, "Saved RAW cannot masquerade as C1 model restoration")
	check(session.transport([0,1,0,2],"predictive").ok, "Predictive packet restores model")
	session.complete("C2_cost")
	var decoded: Dictionary = Session.decode(JSON.stringify(session.data))
	check(decoded.ok, "RAW remains legitimate in saved codec comparison")
	var restored = Session.new()
	restored.data = decoded.data
	restored._restore_permissions()
	check(restored.set_mode("predict").ok, "Predictive member of saved comparison restores permission")
	check(session.set_mode("predict").ok and session.begin_prediction("check").ok, "Check round begins")
	while session.prediction.prefix.size() < 12:
		session.commit_prediction(); session.reveal_prediction()
	session.commit_prediction()
	var before: Dictionary = session.prediction.duplicate(true)
	var future: Array = session._future.duplicate()
	var model: Dictionary = session._frozen.duplicate(true)
	var machine: Dictionary = session._prediction_machine.duplicate(true)
	var events: Array = session._prediction_events.duplicate(true)
	session.data.draft.machine.cache_rows = 21; session.data.draft.machine.memory_bytes = 256
	var failed: Dictionary = session.begin_prediction("practice")
	check(not failed.ok and failed.error == "memory_limit", "Practice switch rejects insufficient memory")
	check(session.prediction == before and session._future == future and session._frozen == model and session._prediction_machine == machine and session._prediction_events == events, "Rejected switch atomically preserves all active round state")
	var revealed: Dictionary = session.reveal_prediction()
	check(revealed.ok and revealed.row.index == 12 and revealed.row.truth == future[12], "Pending old guess reveals safely against old truth")
	finish_prediction(session)
	check(session.prediction.finished, "Preserved round can finish after failed switch")
	session.data.draft.machine = Model.default_machine()
	check(session.begin_prediction("practice").ok and session.prediction.prefix.size() == 2 and session.prediction.pending.is_empty(), "Successful retry cleanly replaces old round")
	finish_prediction(session)
	check(session.set_mode("generate").ok, "Completed prediction permits generation")
	session.data.draft.examples = [[0,3,0,3,0,3]]
	check(session.train().ok and session.data.mode == "generate" and session.generate().ok, "G2 still permits explicit example retraining during generation")

func run() -> void:
	var machine: Dictionary = Model.default_machine()
	var model: Dictionary = learning_and_feedback(machine)
	if not model.is_empty(): packages(model,machine); cost_counterexamples(machine)
	failed_round_and_raw_contract()
	session_contract()
	comparison_contract()
	print("PASS: creation contract %d checks" % checks if failures.is_empty() else "FAIL: creation contract "+str(failures))
	quit(0 if failures.is_empty() else 1)
