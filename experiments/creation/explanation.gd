extends RefCounted
## Presentation only: consume recorded observations; never run a predictor or read a hidden target.
static func words(zh: String, en: String, english: bool) -> String:
	return en if english else zh

static func symbols(values: Array) -> String:
	var parts := PackedStringArray()
	for value: int in values: parts.append(["A", "B", "C", "D"][value] if value >= 0 and value < 4 else "?")
	return " · ".join(parts) if not parts.is_empty() else "∅"

static func counts_text(counts: Array, english: bool) -> String:
	if counts.size() != 4: return words("计数未记录", "Counts not recorded", english)
	return words("后继计数/权重", "Successor counts/weights", english) + " A:%d B:%d C:%d D:%d" % [counts[0], counts[1], counts[2], counts[3]]

static func rule_text(record: Dictionary, english: bool) -> String:
	var context: Array = record.get("context", [])
	var context_text: String = symbols(context) if not context.is_empty() else words("∅ 不看上下文", "∅ no context", english)
	return words("使用规则", "Rule used", english) + " [" + context_text + "] → " + counts_text(record.get("counts", []), english)

static func prediction(record: Dictionary, prefix: Array, memorize: bool, english: bool) -> String:
	var lines := PackedStringArray()
	lines.append(words("已见末尾", "Observed suffix", english) + " [" + symbols(prefix.slice(maxi(0, prefix.size() - 2))) + "]")
	if memorize:
		lines.append(words("按位置背诵：取首个训练样例的同位置，越界用 A；不使用上下文计数。", "Position baseline: read the same index of the first example; use A beyond it. No context-count rule.", english))
	else:
		lines.append(rule_text(record, english))
		lines.append(words("取最大计数；并列按 A→B→C→D。", "Take the largest count; break ties A→B→C→D.", english))
	var predicted: int = int(record.get("predicted", record.get("symbol", -1)))
	var outcome: String = words("预测 ", "Prediction ", english) + symbols([predicted])
	if record.has("truth"):
		outcome += words(" → 实际 ", " → Actual ", english) + symbols([int(record.truth)])
		outcome += words("；命中", "; match", english) if predicted == int(record.truth) else words("；未命中，实际值进入下一步上下文", "; mismatch, actual value enters the next context", english)
	else:
		outcome += words(" → 实际尚未揭晓", " → Actual value not yet revealed", english)
	lines.append(outcome)
	return "\n".join(lines)

static func cell(record: Dictionary, trace: Array, prefix: Array, english: bool) -> String:
	var kind: String = str(record.get("kind", ""))
	var symbol: int = int(record.get("actual", record.get("symbol", -1)))
	if kind in ["literal_write", "literal_read", "seed_write"]:
		return (words("直接读取恢复 ", "Direct literal recovery ", english) if kind == "literal_read" else words("直接写入 ", "Direct write ", english)) + symbols([symbol]) + words("；此格没有模型预测。", "; no model prediction for this cell.", english)
	var lines := PackedStringArray()
	lines.append(words("已见末尾", "Observed suffix", english) + " [" + symbols(prefix.slice(maxi(0, prefix.size() - 2))) + "]")
	if kind == "feedback_write":
		lines.append(rule_text({"context": record.get("before_context", []), "counts": record.get("counts", [])}, english))
		lines.append(words("按计数加权抽样", "Count-weighted sampling", english) if record.get("sampler", "") == "weighted" else words("取最大计数；并列按 A→B→C→D", "Largest count; ties A→B→C→D", english))
		lines.append(words("生成 ", "Generated ", english) + symbols([symbol]) + words(" → 回灌为下一步上下文；没有标准答案，也不自动训练。", " → fed into the next context; no target answer and no automatic training.", english))
	else:
		var decision: Dictionary = {}
		for item: Dictionary in trace:
			if item.get("kind", "") == "successor_select" and item.get("index", -1) == record.get("index", -2) and item.get("phase", "") == record.get("phase", ""):
				decision = item
				break
		lines.append(rule_text(decision, english) if not decision.is_empty() else words("规则计数未记录；不从当前模型补算。", "Rule counts not recorded; not recomputed from the current model.", english))
		lines.append(words("预测 ", "Prediction ", english) + symbols([int(record.get("predicted", -1))]) + words(" → 实际 ", " → Actual ", english) + symbols([symbol]))
		lines.append(words("一致：写入 1 个匹配位，无修正符号。", "Match: 1 match bit, no correction symbol.", english) if record.get("match", false) else words("不一致：写入 1 个标记位 + 2 个修正位，恢复实际值。", "Mismatch: 1 flag bit + 2 correction bits restore the actual value.", english))
	return "\n".join(lines)

static func audit(summary: String, record: Dictionary, english: bool) -> String:
	return summary + "\n\n" + words("原始审计记录：", "Raw audit record:", english) + JSON.stringify(record)

static func rule_changes(before: Dictionary, after: Dictionary) -> Array:
	# Counts are compared between frozen models, never inferred from draft controls.
	var old_rows: Dictionary = {}
	var new_rows: Dictionary = {}
	for row: Dictionary in before.get("rows",[]): old_rows[symbols(row.context)] = row
	for row: Dictionary in after.get("rows",[]): new_rows[symbols(row.context)] = row
	var keys: Array = old_rows.keys()
	for key: String in new_rows:
		if key not in keys: keys.append(key)
	keys.sort()
	var changes: Array = []
	for key: String in keys:
		var old: Dictionary = old_rows.get(key,{"context":new_rows[key].context,"counts":[0,0,0,0]}) if not old_rows.has(key) else old_rows[key]
		var next: Dictionary = new_rows.get(key,{"context":old.context,"counts":[0,0,0,0]})
		if old.counts != next.counts:
			changes.append({"context":old.context.duplicate(),"before":old.counts.duplicate(),"after":next.counts.duplicate(),"removed":not new_rows.has(key)})
	return changes

static func training(changes: Array, english: bool) -> String:
	var lines := PackedStringArray([words("本次重新统计所选样例；以下对照上次学得规则，不是向旧计数累加。", "Selected examples were recounted. Compared with the previous learned rules; not added to their old counts.", english)])
	if changes.is_empty(): lines.append(words("规则计数没有变化。", "Rule counts did not change.", english))
	for row: Dictionary in changes:
		var parts := PackedStringArray()
		for i: int in 4:
			if row.before[i] != row.after[i]: parts.append(["A","B","C","D"][i]+" "+str(row.before[i])+"→"+str(row.after[i]))
		lines.append("["+symbols(row.context)+"] "+", ".join(parts)+(words("（规则移除）", " (rule removed)", english) if row.removed else ""))
	return "\n".join(lines)

static func selection(index: int, record: Dictionary, context: Array, english: bool) -> String:
	var line: String = words("第 ","Cell ",english)+str(index+1)+words(" 格 · 青框上下文 ["," · teal context [",english)+symbols(context)+"]"
	if record.get("kind","") in ["literal_write","literal_read","seed_write"]:
		return line+(words(" → 直接恢复 "," → literal recovery ",english) if record.get("kind","") == "literal_read" else words(" → 直接写入 "," → direct write ",english))+symbols([int(record.symbol)])
	if record.get("kind","") == "feedback_write":
		return line+words(" → 生成 "," → generated ",english)+symbols([int(record.symbol)])+words(" → 回灌"," → feedback",english)
	if record.is_empty(): return words("已选第 ","Selected cell ",english)+str(index+1)+words(" 格 · 仅有快照"," · snapshot only",english)
	var predicted: int = int(record.get("predicted",record.get("symbol",-1)))
	line += words(" → 预测 "," → prediction ",english)+symbols([predicted])
	if record.has("truth") or record.has("actual") or record.get("kind", "") == "residual_read":
		var actual: int = int(record.get("truth",record.get("actual",record.get("symbol",-1))))
		line += words(" → 实际 "," → actual ",english)+symbols([actual])
		if actual != predicted: line += words("（修正）"," (corrected)",english)
	else: line += words(" → 尚未揭晓"," → unrevealed",english)
	return line
