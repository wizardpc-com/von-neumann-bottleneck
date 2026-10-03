extends RefCounted
## Construct grouping/residency/representation hypotheses from public requests only.
var trials: int = 0
var hinted: bool = false
var seen: Dictionary = {}
const BUDGET: int = 6
func decide(observation: Dictionary) -> Dictionary:
	if trials == 0:
		trials += 1
		return {"action":"run", "reason":"Measure the current constructed service plan."}
	if not hinted:
		hinted = true
		return {"action":"hint1", "reason":"Read Hint1 and open public numerical data/costs before editing."}
	if bool(observation.get("accepted",false)):
		return {"action":"stop", "reason":"Public result meets this contract; do not infer optimality."}
	if trials >= BUDGET: return {"action":"stop", "reason":"Finite service-plan hypothesis budget exhausted."}
	var draft: Dictionary = observation.get("draft",{}).duplicate(true)
	if not draft.has("groups") or not draft.has("representations"): return {"action":"stop","reason":"No editable public service draft."}
	seen[JSON.stringify(draft)] = true
	var ids: Array = []
	for group: Array in draft.groups: ids.append_array(group)
	var steps: int = int(observation.get("rules",{}).get("stream_steps",1))
	var range_slots: Array = observation.get("slot_range",[draft.slots,draft.slots])
	var proposals: Array = []
	var grouped: Dictionary = draft.duplicate(true); grouped.groups = []
	ids.sort()
	for id: int in ids: grouped.groups.append([id])
	grouped.slots = range_slots[0]
	proposals.append({"plan":grouped,"reason":"After measured state traffic, cluster consecutive requests of each stream while preserving dependencies; compare delayed other streams."})
	var interleaved: Dictionary = draft.duplicate(true); interleaved.groups = []
	ids.sort_custom(func(a: int,b: int) -> bool: return a % steps < b % steps if a % steps != b % steps else a < b)
	for id: int in ids: interleaved.groups.append([id])
	interleaved.slots = range_slots[-1]
	proposals.append({"plan":interleaved,"reason":"Compare interleaving with more resident contexts: exchange memory for earlier responses without changing numerical precision."})
	var formats: Array = observation.get("formats",[])
	if formats.has("rle64"):
		var all_runs: Dictionary = interleaved.duplicate(true)
		for i: int in all_runs.representations.size(): all_runs.representations[i] = "rle64"
		proposals.append({"plan":all_runs,"reason":"Measure lossless run encoding on every stream; do not assume every numerical record compresses."})
		var mixed: Dictionary = interleaved.duplicate(true)
		var streams: Array = observation.get("public_data",[])
		for i: int in mini(streams.size(),mixed.representations.size()):
			var rows: Array = [streams[i].get("initial",[])]
			for request: Dictionary in streams[i].get("requests",[]): rows.append(request.get("values",[]))
			var repeated: bool = not rows.is_empty()
			for row: Array in rows:
				if row.is_empty(): repeated = false
				for value: Variant in row:
					if value != row[0]: repeated = false
			mixed.representations[i] = "rle64" if repeated else "raw64"
		proposals.append({"plan":mixed,"reason":"Use observed repeated coordinates to propose local lossless encodings; keep varied records raw and measure the result."})
	for proposal: Dictionary in proposals:
		var signature: String = JSON.stringify(proposal.plan)
		if seen.has(signature): continue
		seen[signature] = true; trials += 1
		return {"action":"try_service", "plan":proposal.plan.duplicate(true), "reason":proposal.reason}
	return {"action":"stop", "reason":"No further supported public-data hypothesis; report a bounded stall."}
