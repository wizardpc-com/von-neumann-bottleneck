extends RefCounted
## Public history and measured runs only; no future stream/model/catalog access.
var trials: int = 0
var hinted: bool = false
var seen: Dictionary = {}
const BUDGET: int = 7
func decide(observation: Dictionary) -> Dictionary:
	if trials == 0:
		trials += 1
		return {"action":"run", "reason":"Measure the visible starter without requesting unseen addresses."}
	if not hinted:
		hinted = true
		return {"action":"hint1", "reason":"Read the public first hint; do not request future sequence data."}
	if bool(observation.get("goal_met",false)):
		return {"action":"stop", "reason":"Public contract is met; this says nothing about untested streams."}
	if trials >= BUDGET: return {"action":"stop", "reason":"Finite prediction experiment budget reached."}
	var current: Dictionary = observation.get("policy",{})
	seen[JSON.stringify(current)] = true
	var latest: Dictionary = {}
	var runs: Array = observation.get("completed_runs",[])
	if not runs.is_empty(): latest = runs[-1].get("metrics",{})
	var waste: int = int(latest.get("wasted_prediction_bytes",0))
	var ranges: Dictionary = observation.get("control_ranges",{})
	var rules: Array = ranges.get("rule",[])
	var confidences: Array = ranges.get("confidence",[])
	var looks: Array = ranges.get("lookahead",[])
	var pauses: Array = ranges.get("cooldown",[])
	if rules.is_empty() or confidences.is_empty() or looks.is_empty() or pauses.is_empty():
		return {"action":"stop", "reason":"No visible editable policy options."}
	var proposals: Array = []
	if waste > 0:
		# Observed failed speculation motivates evidence threshold and mismatch pause.
		proposals.append({"rule":current.get("rule",rules[0]),"confidence":confidences[-1],"lookahead":looks[0],"cooldown":pauses[-1]})
	for rule: String in rules:
		if rule == "off": continue
		proposals.append({"rule":rule,"confidence":confidences[0],"lookahead":looks[0],"cooldown":pauses[0]})
	for rule: String in rules:
		if rule == "off": continue
		proposals.append({"rule":rule,"confidence":confidences[-1],"lookahead":looks[0],"cooldown":pauses[-1]})
	for option: Dictionary in proposals:
		var id: String = JSON.stringify(option)
		if seen.has(id): continue
		seen[id] = true; trials += 1
		return {"action":"try_policy", "policy":option.duplicate(true), "reason":("Measured unused traffic motivates a stricter evidence gate or mismatch pause. " if waste > 0 else "Compare a rule available in the visible controls. ")+"Inspect actual demand time, fallback and wasted bytes."}
	return {"action":"stop", "reason":"No untried hypothesis in the bounded action vocabulary."}
