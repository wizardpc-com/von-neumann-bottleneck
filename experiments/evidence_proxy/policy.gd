extends RefCounted
## Information boundary: only this plain dictionary enters the bounded policy.
## No Nodes, files, catalogs, reference solutions, target metrics or task IDs.
var trials: int = 0
var seen: Dictionary = {}
var read_hint: bool = false
var ran: bool = false
var last_evidence: String = ""
var prior_id: String = ""
var best_id: String = ""
var best_cycles: int = 2147483647
var confirmed_best: bool = false
const BUDGET = 8

func decide(observation: Dictionary) -> Dictionary:
	# Deliberately whitelist fields. Extra/poisoned fields cannot affect decisions.
	var evidence: String=str(observation.get("evidence",""))
	var actions: Array=observation.get("actions",[])
	var changed: bool=not evidence.is_empty() and evidence!=last_evidence
	last_evidence=evidence
	var pattern := RegEx.new(); pattern.compile("Total ([0-9]+)")
	var measured: RegExMatch=pattern.search(evidence)
	if measured!=null and not prior_id.is_empty():
		var cycles: int=int(measured.get_string(1))
		if cycles<best_cycles: best_cycles=cycles; best_id=prior_id
	if trials>=BUDGET: return {"id":"stop","reason":"Finite experiment budget exhausted; no solution claim."}
	trials+=1
	if not ran:
		for action: Dictionary in actions:
			if action.kind=="run":
				ran=true; return {"id":action.id,"reason":"Measure the visible starter before choosing a change."}
	if not read_hint:
		for action: Dictionary in actions:
			if action.kind=="hint1":
				read_hint=true; return {"id":action.id,"reason":"First run did not supply a construction procedure; consult only Hint1."}
	# An enabled one-variable lever can be compared without knowing the answer.
	# Prefer the last visible option, then work backwards; never target a named size.
	for i: int in range(actions.size()-1,-1,-1):
		var action: Dictionary=actions[i]
		if action.kind=="trial" and not seen.has(action.label):
			seen[action.label]=true
			prior_id=str(action.id)
			return {"id":action.id,"reason":("New public evidence observed. " if changed else "")+"Hold other controls fixed and measure untried visible option: "+str(action.label)}
	if not best_id.is_empty() and not confirmed_best:
		confirmed_best=true
		return {"id":best_id,"reason":"Recheck the lowest measured public Total: %d cycles. This is observed best, not a claimed global optimum." % best_cycles}
	return {"id":"stop","reason":"No untried supported experiment. This policy cannot infer wiring or a diagnosis from prose; report a bounded stall, not a level defect."}
