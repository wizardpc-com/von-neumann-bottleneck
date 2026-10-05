extends RefCounted
## Optional requests over existing measured service results. No progress authority.
const Model = preload("res://experiments/service_plan/model.gd")

static func spec(id: int) -> Dictionary:
	match id:
		0: return {"max_slots":1,"total_cycles":1420,"first_cycles":320,"tolerance":0.000000001}
		1: return {"max_backing":160,"total_cycles":1420,"first_cycles":320,"tolerance":0.000000001}
		2: return {"max_backing":64,"total_cycles":1420,"first_cycles":320,"tolerance":0.02}
	return {}

static func title(id: int, en: bool = false) -> String:
	var zh: Array[String] = ["单槽值守", "档案交接 · 无损", "档案交接 · 紧凑"]
	var english: Array[String] = ["One-slot duty", "Archive handoff · Lossless", "Archive handoff · Compact"]
	if id < 0 or id >= zh.size(): return "Unknown commission" if en else "未知委托"
	return english[id] if en else zh[id]

static func briefing(id: int, en: bool = false) -> String:
	var limits: Dictionary = spec(id)
	if limits.is_empty(): return "Unknown commission." if en else "未知委托。"
	var purpose: Array[String] = [
		"Keep only one resident context while answering every stream promptly." if en else "只保留一个驻留上下文，同时及时回应每条流。",
		"Hand off a small final archive with exact scores and final states." if en else "交接一份小型最终档案，保持分数和最终状态精确。",
		"Hand off a compact final archive within a public quality tolerance." if en else "交接一份紧凑最终档案，满足公开的质量容差。"]
	var text: String = purpose[id] + ("\nThe same fixed 24 requests and machine rules apply; all requests must complete in stream order." if en else "\n仍使用固定24个请求和已有机器规则；必须完整执行，同流保序。")
	text += "\nTotal ≤1420 cycles; every stream's first response ≤320 cycles." if en else "\n总周期≤1420；每条流首响应≤320周期。"
	if limits.has("max_slots"):
		text += " Resident slots ≤1." if en else " 驻留槽≤1。"
	else:
		text += (" Final archive ≤%d B." if en else " 最终档案≤%dB。") % limits.max_backing
	text += ("\nScore error and final-state error each ≤%s." if en else "\n分数误差与最终状态误差分别≤%s。") % ("0.02" if id == 2 else "1e-9")
	text += "\nArchive bytes are the four backing records, including directory entries, after final flush. They differ from cumulative state read/write traffic. The existing 512 B hard capacity remains." if en else "\n档案空间是最终flush后四条外存记录的字节数，含目录项；它不同于累计状态读写流量。仍须满足已有512B硬容量。"
	return text

static func finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0.0

static func positive_integer(value: Variant) -> bool:
	return finite_number(value) and float(value) > 0.0 and float(value) == floor(float(value))

static func valid_metrics(metrics: Dictionary) -> bool:
	if not metrics.get("error") is String or not str(metrics.error).is_empty(): return false
	for key: String in ["total_cycles","all_streams_first_cycle","final_backing_bytes"]:
		if not positive_integer(metrics.get(key)): return false
	for key: String in ["max_error","max_state_error"]:
		if not finite_number(metrics.get(key)): return false
	if not metrics.get("plan") is Dictionary: return false
	if not positive_integer(metrics.plan.get("slots")) or int(metrics.plan.slots) > 4: return false
	if not Model.validate(metrics.plan).is_empty(): return false
	var firsts: Variant = metrics.get("first_stream_cycles")
	if not firsts is Array or firsts.size() != 4: return false
	for first: Variant in firsts:
		if not positive_integer(first) or float(first) > float(metrics.total_cycles): return false
	return float(firsts.max()) == float(metrics.all_streams_first_cycle)

static func accepted(metrics: Dictionary, id: int) -> bool:
	var limits: Dictionary = spec(id)
	if limits.is_empty() or not valid_metrics(metrics): return false
	if metrics.total_cycles > limits.total_cycles or metrics.all_streams_first_cycle > limits.first_cycles: return false
	if metrics.max_error > limits.tolerance or metrics.max_state_error > limits.tolerance: return false
	if limits.has("max_slots") and metrics.plan.slots > limits.max_slots: return false
	if limits.has("max_backing") and metrics.final_backing_bytes > limits.max_backing: return false
	return true

static func feedback(metrics: Dictionary, id: int, en: bool = false) -> String:
	var limits: Dictionary = spec(id)
	if limits.is_empty(): return "Unknown commission." if en else "未知委托。"
	if not valid_metrics(metrics):
		var reason: String = str(metrics.get("error",""))
		return ("No complete valid measurement; rerun the plan." if en else "没有完整有效的实测结果；请重新运行方案。") + (" " + reason if not reason.is_empty() else "")
	var failures: Array[String] = []
	var budgets: Array[Dictionary] = [
		{"name":"Total cycles" if en else "总周期","actual":metrics.total_cycles,"limit":limits.total_cycles},
		{"name":"Latest first response" if en else "最晚首响应","actual":metrics.all_streams_first_cycle,"limit":limits.first_cycles}]
	if limits.has("max_slots"): budgets.append({"name":"Resident slots" if en else "驻留槽","actual":metrics.plan.slots,"limit":limits.max_slots})
	if limits.has("max_backing"): budgets.append({"name":"Final archive B" if en else "最终档案B","actual":metrics.final_backing_bytes,"limit":limits.max_backing})
	for budget: Dictionary in budgets:
		if budget.actual > budget.limit:
			failures.append("%s %d / %d" % [budget.name,budget.actual,budget.limit])
	for key: String in ["max_error","max_state_error"]:
		if metrics[key] > limits.tolerance:
			var name: String = ("Score error" if en else "分数误差") if key == "max_error" else ("Final-state error" if en else "最终状态误差")
			failures.append(name+" "+String.num_scientific(metrics[key])+" / "+String.num_scientific(limits.tolerance))
	return " · ".join(failures) if not failures.is_empty() else ("This measured plan meets the commission." if en else "这份实测方案满足委托。")
