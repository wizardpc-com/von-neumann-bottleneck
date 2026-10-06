extends RefCounted
## Read-only witnesses from recorded results. No simulation or codec execution.
const Presenter = preload("res://experiments/service_plan/event_presenter.gd")
static func numeric(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func build(metrics: Dictionary, events: Array = []) -> Dictionary:
	if not str(metrics.get("error","invalid")).is_empty(): return {}
	var score: Dictionary = {}; var state: Dictionary = {}
	for index: int in events.size():
		if not events[index] is Dictionary or str(events[index].get("kind","")) != "output": continue
		var details: Variant = events[index].get("details")
		if not details is Dictionary: continue
		var request: int = Presenter.bounded_id(details.get("request_id"),24)
		if request < 0 or not numeric(details.get("score")) or not numeric(details.get("reference")) or not numeric(details.get("error")) or details.error < 0: continue
		if score.is_empty() or float(details.error) > float(score.error) or (float(details.error) == float(score.error) and request < int(score.request_id)):
			score = {"request_id":request,"actual":details.score,"reference":details.reference,"error":details.error,"source_index":index}
	var reference: Variant = metrics.get("reference")
	if reference is Dictionary:
		# Metrics also retain the actual and reference arrays when no event is supplied.
		var outputs: Variant = metrics.get("outputs"); var expected: Variant = reference.get("outputs")
		if score.is_empty() and outputs is Array and expected is Array and outputs.size() == 24 and expected.size() == 24:
			for request: int in 24:
				if not numeric(outputs[request]) or not numeric(expected[request]): continue
				var error: float = absf(float(outputs[request])-float(expected[request]))
				if score.is_empty() or error > float(score.error): score = {"request_id":request,"actual":outputs[request],"reference":expected[request],"error":error,"source_index":-1}
		var actual_states: Variant = metrics.get("final_states"); var expected_states: Variant = reference.get("states")
		if actual_states is Array and expected_states is Array and actual_states.size() == 4 and expected_states.size() == 4:
			for stream: int in 4:
				if not actual_states[stream] is Array or not expected_states[stream] is Array or actual_states[stream].size() != 8 or expected_states[stream].size() != 8: continue
				for coordinate: int in 8:
					var actual: Variant = actual_states[stream][coordinate]; var target: Variant = expected_states[stream][coordinate]
					if not numeric(actual) or not numeric(target): continue
					var error: float = absf(float(actual)-float(target))
					if state.is_empty() or error > float(state.error): state = {"stream":stream,"coordinate":coordinate,"actual":actual,"reference":target,"error":error}
	return {"score":score,"state":state}

static func identity(witness: Dictionary, score: bool) -> String:
	if witness.is_empty(): return ""
	return char(65+int(witness.request_id)/6)+str(int(witness.request_id)%6) if score else char(65+int(witness.stream))+"["+str(int(witness.coordinate))+"]"

static func text(evidence: Dictionary, tolerance: float, en: bool = false) -> String:
	if evidence.is_empty(): return "No valid recorded quality evidence." if en else "没有有效的实测精度依据。"
	var lines: Array[String] = ["Selected measurement; each score and final-state error must be ≤" if en else "所选实测记录；分数与最终状态误差分别必须≤"]
	lines[0] += String.num_scientific(tolerance)
	lines.append("Final-state coordinates use indices 0–7; ties use request/coordinate order." if en else "最终状态坐标使用下标0–7；并列最大误差按请求/坐标顺序定位。")
	for key: String in ["score","state"]:
		var witness: Dictionary = evidence.get(key,{})
		var name: String = ("Score" if en else "分数") if key == "score" else ("Final state" if en else "最终状态")
		if witness.is_empty(): lines.append(name+(": evidence not recorded." if en else "：依据未记录。")); continue
		lines.append("\n"+name+" · "+identity(witness,key == "score"))
		lines.append(("Actual %s · reference %s" if en else "实际%s · 参考%s") % [String.num_scientific(witness.actual),String.num_scientific(witness.reference)])
		lines.append(("Error %s / limit %s · %s" if en else "误差%s / 上限%s · %s") % [String.num_scientific(witness.error),String.num_scientific(tolerance),("Over limit" if en else "超限") if witness.error > tolerance else ("Within limit" if en else "满足")])
	return "\n".join(lines)
