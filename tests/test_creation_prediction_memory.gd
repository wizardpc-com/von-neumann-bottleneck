extends SceneTree
## Prediction residency agrees with the actual bounded learned rule table.
const Session = preload("res://experiments/creation/session.gd")
const Model = preload("res://experiments/creation/model.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	var session = Session.new()
	session.data.draft.examples = [[0,1,0,1]]
	session.data.draft.order = 0
	session.data.draft.machine.cache_rows = 21
	check(session.train().ok,"Actual order-zero training succeeds")
	var required: int = Model.canonical_bytes(session.data.model).size()+12*2+16+mini(21,session.data.model.rows.size())*11
	check(session.transport([0,1,0,1],"predictive").ok,"Actual predictive transport restores the inherited rules")
	session.data.draft.machine.memory_bytes = required
	check(session.set_mode("predict").ok,"Actual restored model enters prediction")
	check(session.begin_prediction("practice").ok,"Exact actual residency budget starts prediction with 21 cache slots")
	check(session.commit_prediction().ok,"Exact-budget prediction commits a causal guess")
	var old_round: Dictionary = session.prediction.duplicate(true)
	session.data.draft.machine.memory_bytes = required-1
	var rejected: Dictionary = session.begin_prediction("practice")
	check(not rejected.ok and rejected.error == "memory_limit","One byte below actual residency rejects the new round")
	check(session.prediction == old_round,"Rejected round preserves the existing pending guess and prefix")
	check(session.reveal_prediction().ok,"Pending guess remains revealable after rejected switch")
	check(session.prediction_evidence().cost.peak_bytes == required,"Later machine edits do not change the frozen round's residency")
	while not session.prediction.finished:
		check(session.commit_prediction().ok,"Remaining exact-budget causal commit succeeds")
		check(session.reveal_prediction().ok,"Remaining exact-budget reveal succeeds")
	session.complete("P1_commit")
	session.data.draft.machine.memory_bytes = required
	check(Session.decode(JSON.stringify(session.data)).ok,"Completed exact-budget prediction support round-trips through strict decode")
	check(session.set_mode("generate").ok,"Actual finished prediction enters generation")
	session.data.draft.length = 12
	check(session.generate().ok,"Same bounded machine can generate its short legal output")
	var legacy: Dictionary = session.data.duplicate(true)
	var support: Dictionary = legacy.supports.P1_commit
	var old_peak: int = Model.canonical_bytes(support.model).size()+12*2+16+21*11
	support.machine.memory_bytes = old_peak
	for row: Dictionary in support.rows: row.cost.peak_bytes = old_peak
	check(Session.decode(JSON.stringify(legacy)).ok,"Strict conservative historical peak remains readable when its machine could hold it")
	var tampered: Dictionary = legacy.duplicate(true)
	tampered.supports.P1_commit.rows[0].cost.total_cycles += 1
	check(not Session.decode(JSON.stringify(tampered)).ok,"Historical peak compatibility cannot accept changed non-peak costs")
	var mixed: Dictionary = legacy.duplicate(true)
	mixed.supports.P1_commit.rows[0].cost.peak_bytes = required
	check(not Session.decode(JSON.stringify(mixed)).ok,"One round cannot mix old and current residency conventions")
	var undersized: Dictionary = legacy.duplicate(true)
	undersized.supports.P1_commit.machine.memory_bytes = old_peak-1
	check(not Session.decode(JSON.stringify(undersized)).ok,"Historical residency exceeding its own machine is rejected")
	print("PASS: creation prediction memory" if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
