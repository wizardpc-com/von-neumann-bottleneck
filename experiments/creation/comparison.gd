extends RefCounted
## Read-only comparison of actual generation snapshots, never a new simulation.
## A recipe change is evidence of conditions, not evidence of artistic intention.
const Model = preload("res://experiments/creation/model.gd")
const DESIGN_VERSION := "controlled-design-v1"

static func passage_changes(first: Array, second: Array) -> Array[Dictionary]:
	# Minimum passage insertions/removals/replacements. Removing the first
	# passage must not falsely count every shifted passage as another edit.
	var grid: Array = []
	for i: int in first.size()+1:
		var row: Array[int] = []
		for j: int in second.size()+1: row.append(j if i == 0 else i if j == 0 else 0)
		grid.append(row)
	for i: int in range(1,first.size()+1):
		for j: int in range(1,second.size()+1):
			grid[i][j] = mini(mini(grid[i-1][j]+1,grid[i][j-1]+1),grid[i-1][j-1]+(0 if first[i-1] == second[j-1] else 1))
	var result: Array[Dictionary] = []
	var i: int = first.size()
	var j: int = second.size()
	while i > 0 or j > 0:
		if i > 0 and j > 0 and first[i-1] == second[j-1]:
			i -= 1; j -= 1
		elif i > 0 and j > 0 and grid[i][j] == grid[i-1][j-1]+1:
			result.push_front({"kind":"replace","a":i,"b":j,"before":first[i-1].duplicate(),"after":second[j-1].duplicate()})
			i -= 1; j -= 1
		elif i > 0 and grid[i][j] == grid[i-1][j]+1:
			result.push_front({"kind":"remove","a":i,"b":0,"before":first[i-1].duplicate(),"after":[]})
			i -= 1
		else:
			result.push_front({"kind":"add","a":0,"b":j,"before":[],"after":second[j-1].duplicate()})
			j -= 1
	return result

static func example_edits(first: Array, second: Array) -> int:
	return passage_changes(first,second).size()

static func passage_preview(symbols: Array) -> String:
	var parts := PackedStringArray()
	for symbol: int in symbols.slice(0,24): parts.append(["A","B","C","D"][symbol])
	return " ".join(parts)+(" … (%d)" % symbols.size() if symbols.size()>24 else "")

static func compare(first: Dictionary, second: Dictionary) -> Dictionary:
	if not first.has("recipe") or not second.has("recipe") or not first.has("output") or not second.has("output"):
		return {"ok":false,"error":"generation_required"}
	var a: Dictionary = first.recipe
	var b: Dictionary = second.recipe
	var changes: Array[Dictionary] = []
	var factors: int = 0
	var edits: int = example_edits(a.model.examples,b.model.examples)
	if edits > 0:
		changes.append({"key":"examples","before":a.model.examples.duplicate(true),"after":b.model.examples.duplicate(true),"edits":edits,"passages":passage_changes(a.model.examples,b.model.examples)})
		factors += edits
	for key: String in ["order"]:
		if a.model[key] != b.model[key]:
			changes.append({"key":key,"before":a.model[key],"after":b.model[key]})
			factors += 1
	for key: String in ["seed","initial","length","sampler","version","sampler_version","prng_version"]:
		if a[key] != b[key]:
			changes.append({"key":key,"before":a[key],"after":b[key]})
			factors += 1
	for key: String in a.machine:
		if a.machine[key] != b.machine.get(key):
			changes.append({"key":key,"before":a.machine[key],"after":b.machine.get(key)})
			factors += 1
	# Model identity also changes as a consequence of examples/history. Do not
	# double-count it as a second knob; unexplained rule changes remain explicit.
	if a.model_id != b.model_id and edits == 0 and a.model.order == b.model.order:
		changes.append({"key":"rules","before":a.model_id,"after":b.model_id})
		factors += 1
	var divergence: int = -1
	var mismatches: Array[int] = []
	for i: int in maxi(first.output.size(),second.output.size()):
		if i >= first.output.size() or i >= second.output.size() or first.output[i] != second.output[i]:
			if divergence < 0: divergence = i
			mismatches.append(i)
	var fixed: bool = a.seed == b.seed and a.initial == b.initial and a.length == b.length
	var single: bool = fixed and factors == 1 and str(changes[0].key) in ["examples","order","sampler"]
	var rules_changed: bool = a.model.order != b.model.order or a.model.rows != b.model.rows
	var effective_design: bool = single and (rules_changed or a.sampler != b.sampler)
	return {"ok":true,"changes":changes,"factor_count":factors,"fixed":fixed,"single":single,
		"first_difference":divergence,"mismatches":mismatches,"different":divergence >= 0,
		"model_changed":a.model_id != b.model_id,
		"controlled_effect":effective_design and divergence >= 0,
		"rules_changed":rules_changed,"effective_design":effective_design,
		"design_version":DESIGN_VERSION,"observation":effective_design,
		"seed_only":factors == 1 and str(changes[0].key) == "seed",
		"first_difference_evidence":difference_evidence(first,second,divergence),
		"later_independent_causality":false}

static func caption(report: Dictionary, english: bool = false) -> String:
	if not report.get("ok",false): return "Pin A, then generate B." if english else "先钉住 A，再生成 B。"
	var lines := PackedStringArray()
	if not report.fixed:
		lines.append("Seed, initial passage or length changed: this is not a controlled A/B comparison." if english else "种子、起始片段或长度已变：这不是固定条件的 A/B 对照。")
	elif report.factor_count == 0:
		lines.append("Recipe conditions match; this is a repeat run." if english else "配方条件相同；这是重复运行。")
	elif report.single:
		lines.append("One controlled change; seed, initial passage and length are fixed." if english else "只改一项；种子、起始片段与长度固定。")
	else:
		lines.append("%d conditions changed; do not attribute the result to one change." % report.factor_count if english else "%d 项条件改变；不能把差异归因于其中一项。" % report.factor_count)
	if report.get("single",false) and not report.get("effective_design",false):
		lines.append("Example provenance changed, but learned rule rows are identical; this is not structural-design evidence." if english else "样例来源改变，但学到的规则行相同；这不构成结构修改证据。")
	var names: Dictionary = {"examples":["训练样例","examples"],"order":["记忆长度","history"],"seed":["随机种子","random seed"],"initial":["起始片段","initial passage"],"length":["总长度","length"],"sampler":["采样规则","sampling"],"rules":["模型规则","model rules"],"cpu_ops_per_cycle":["CPU吞吐","CPU throughput"],"bytes_per_cycle":["带宽","bandwidth"],"request_cycles":["请求周期","request cycles"],"memory_bytes":["内存预算","memory budget"],"cache_rows":["缓存行","cache rows"]}
	for change: Dictionary in report.changes:
		var name: String = names.get(change.key,[change.key,change.key])[1 if english else 0]
		if change.key == "examples":
			lines.append("%s: %d → %d (%d passage edits)" % [name,change.before.size(),change.after.size(),change.edits] if english else "%s：%d → %d 段（%d 段增删或替换）" % [name,change.before.size(),change.after.size(),change.edits])
			for passage: Dictionary in change.passages:
				var before: String = "A[%d] %s" % [passage.a,passage_preview(passage.before)] if passage.a > 0 else "∅"
				var after: String = "B[%d] %s" % [passage.b,passage_preview(passage.after)] if passage.b > 0 else "∅"
				lines.append(before+" → "+after)
		else: lines.append("%s: %s → %s" % [name,str(change.before),str(change.after)])
	if report.first_difference >= 0:
		lines.append("First difference: cell %d (counting from 1)." % (report.first_difference+1) if english else "首次分歧：第 %d 格（从 1 计数）。" % (report.first_difference+1))
		var evidence: Dictionary = report.get("first_difference_evidence",{})
		for key: String in ["a","b"]:
			var side: Dictionary = evidence.get(key,{})
			if side.get("kind","") == "generated":
				lines.append("%s context %s · counts %s · %s" % [key.to_upper(),passage_preview(side.context),str(side.counts),str(side.sampler)] if english else "%s 上下文 %s · 计数 %s · %s" % [key.to_upper(),passage_preview(side.context),str(side.counts),str(side.sampler)])
		lines.append("Later differences inherit changed feedback; they are not independent per-cell causal tests." if english else "后续差异继承已改变的回灌上下文；不能视作逐格独立的因果检验。")
	else:
		lines.append("Outputs match. This change did not alter this generated passage; other seeds or starts may differ." if english else "输出相同。本次改动未改变这段生成；其他种子或起始片段仍可能不同。")
	lines.append("Different is not better. A seed change alone is not evidence of an intended effect." if english else "不同不代表更好。仅随机种子改变，不算意图效果的证据。")
	return "\n".join(lines)

## First differing output has a shared output prefix in a controlled comparison.
## Later positions inherit divergent feedback and are not independent interventions.
static func difference_evidence(first: Dictionary, second: Dictionary, index: int) -> Dictionary:
	if index < 0: return {}
	var sides: Array[Dictionary] = []
	for snapshot: Dictionary in [first,second]:
		var side: Dictionary = {"index":index,"model_id":snapshot.recipe.model_id,"sampler":snapshot.recipe.sampler,
			"sampler_version":snapshot.recipe.sampler_version,"prng_version":snapshot.recipe.prng_version}
		if index >= snapshot.output.size():
			side["kind"] = "length_boundary"
		elif index < snapshot.recipe.initial.size():
			side["kind"] = "initial"; side["symbol"] = snapshot.output[index]
		else:
			# Use the authoritative generation's recorded feedback event. Saved
			# snapshots omit events; deterministic recipe replay supplies them.
			var events: Array = snapshot.get("events",[])
			if events.is_empty():
				var r: Dictionary = snapshot.recipe
				var replay: Dictionary = Model.generate(r.model,r.initial,int(r.length),int(r.seed),str(r.sampler),r.machine)
				events = replay.get("events",[])
			for event: Dictionary in events:
				if event.kind == "feedback_write" and int(event.index) == index:
					side["kind"] = "generated"; side["symbol"] = event.symbol
					side["context"] = event.before_context.duplicate()
					side["counts"] = event.counts.duplicate()
					break
		sides.append(side)
	return {"index":index,"a":sides[0],"b":sides[1],
		"shared_prefix":first.output.slice(0,index) == second.output.slice(0,index)}
