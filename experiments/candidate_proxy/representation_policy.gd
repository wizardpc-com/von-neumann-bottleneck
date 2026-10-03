extends RefCounted
## Bounded constructive hypotheses from PUBLIC bytes and requests only.
## No model/catalog imports, scene access, file IO or reference solution.
var trials: int = 0
var hinted: bool = false
var candidates: Array = []
var seen: Dictionary = {}
const BUDGET: int = 6

func decide(observation: Dictionary) -> Dictionary:
	if trials == 0:
		trials += 1
		return {"action":"run", "reason":"Measure the visible starting plan before editing."}
	if not hinted:
		hinted = true
		return {"action":"hint1", "reason":"Read only the first evidence hint after the baseline."}
	if bool(observation.get("accepted", false)):
		return {"action":"stop", "reason":"The public result reports acceptance; no optimum claim."}
	if trials >= BUDGET:
		return {"action":"stop", "reason":"Finite hypothesis budget exhausted; retain the failed evidence."}
	if candidates.is_empty():
		candidates = hypotheses(observation.get("assets", []), observation.get("orders", []))
	var current: String = JSON.stringify(observation.get("plan", []))
	seen[current] = true
	while not candidates.is_empty():
		var proposal: Dictionary = candidates.pop_front()
		var signature: String = JSON.stringify(proposal.plan)
		if seen.has(signature): continue
		seen[signature] = true
		trials += 1
		return {"action":"try_plan", "plan":proposal.plan.duplicate(true), "reason":proposal.reason}
	return {"action":"stop", "reason":"No further supported byte-derived hypothesis; this policy cannot infer a richer design."}

func hypotheses(assets: Array, orders: Array) -> Array:
	if assets.is_empty() or not assets[0] is Array or assets[0].is_empty(): return []
	var n: int = assets[0].size()
	for values: Variant in assets:
		if not values is Array or values.size() != n: return []
	var result: Array = []
	result.append({"plan":[{"start":0,"end":n,"codec":"rle"}], "reason":"Try one encoded block to measure actual compression and recovery cost."})
	var boundaries: Array[int] = [0,n]
	# Detect long equal-value runs in every visible asset, without a target partition.
	for values: Array in assets:
		var start: int = 0
		while start < n:
			var end: int = start + 1
			while end < n and values[end] == values[start]: end += 1
			if end - start >= 4:
				if not boundaries.has(start): boundaries.append(start)
				if not boundaries.has(end): boundaries.append(end)
			start = end
	boundaries.sort()
	if boundaries.size() <= 9:
		result.append({"plan":partition(assets,boundaries), "reason":"Separate observed long runs from changing bytes, using the same boundaries for all visible assets."})
	var sparse: Array = []
	for order: Variant in orders:
		if not order is Array: continue
		var unique: Array = []
		for address: Variant in order:
			if address is int and address >= 0 and address < n and not unique.has(address): unique.append(address)
		if not unique.is_empty() and (sparse.is_empty() or unique.size() < sparse.size()): sparse = unique
	if not sparse.is_empty() and sparse.size() <= 3:
		var islands: Array[int] = [0,n]
		for address: int in sparse:
			if not islands.has(address): islands.append(address)
			if not islands.has(address + 1): islands.append(address + 1)
		islands.sort()
		result.append({"plan":partition(assets,islands), "reason":"Isolate the few publicly requested addresses; measure extra directories against overfetch and preparation."})
	var quarters: Array[int] = [0]
	for i: int in range(1,4):
		var cut: int = n*i/4
		if cut > 0 and not quarters.has(cut): quarters.append(cut)
	quarters.append(n)
	result.append({"plan":partition(assets,quarters), "reason":"Try coarse equal regions as a limited generalization hypothesis, then measure the actual cost."})
	return result

func partition(assets: Array, boundaries: Array[int]) -> Array:
	var plan: Array = []
	for i: int in range(boundaries.size()-1):
		var begin: int = boundaries[i]; var end: int = boundaries[i+1]
		var encoded_worst: int = 0
		for values: Array in assets:
			var runs: int = 1
			for j: int in range(begin+1,end):
				if values[j] != values[j-1]: runs += 1
			encoded_worst = maxi(encoded_worst,2+2*runs)
		plan.append({"start":begin,"end":end,"codec":"rle" if encoded_worst < end-begin else "raw"})
	return plan
