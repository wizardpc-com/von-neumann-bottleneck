extends SceneTree
const Policy=preload("res://experiments/evidence_proxy/policy.gd")
func _init() -> void:
	var a := Policy.new(); var b := Policy.new()
	var obs: Dictionary={"evidence":"Missing connection", "actions":[{"id":"run","kind":"run","label":"Run"},{"id":"h1","kind":"hint1","label":"Hint1"},{"id":"x","kind":"trial","label":"Large"},{"id":"y","kind":"trial","label":"Small"}]}
	for i: int in 12:
		var poisoned: Dictionary=obs.duplicate(true)
		poisoned["reference_solution"]="DO y"; poisoned["correct_answer"]="x"; poisoned["target_metrics"]={"cycles":1}
		assert(a.decide(obs)==b.decide(poisoned),"Hidden answer fields must not affect policy")
	assert(a.decide(obs).id=="stop")
	var c:=Policy.new(); var d:=Policy.new()
	var other: Dictionary=obs.duplicate(true); other.actions.reverse()
	assert(c.decide(obs).id=="run" and d.decide(other).id=="run")
	var explorer:=Policy.new()
	var trials: Dictionary={"evidence":"", "actions":[{"id":"alpha","kind":"trial","label":"A"},{"id":"beta","kind":"trial","label":"B"}]}
	assert(explorer.decide(trials).id=="beta")
	trials.evidence="Total 50 · Wait 10"; assert(explorer.decide(trials).id=="alpha")
	trials.evidence="Total 90 · Wait 50"; assert(explorer.decide(trials).id=="beta", "Observed faster option is retested, regardless of name")
	print("PASS: bounded observation policy ignores poisoned solution fields")
	quit()
