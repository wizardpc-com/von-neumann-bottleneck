extends RefCounted
## Read-only descriptions of recorded events, never current draft state.
static func words(zh: String, en: String, english: bool) -> String:
	return en if english else zh

static func bounded_id(value: Variant, limit: int) -> int:
	if (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= 0 and value < limit: return int(value)
	return -1

static func identity(details: Dictionary) -> String:
	var request: int = bounded_id(details.get("request_id"),24)
	if request >= 0: return char(65 + request / 6) + str(request % 6)
	var stream: int = bounded_id(details.get("stream"),4)
	return char(65 + stream) if stream >= 0 else ""

static func reason(details: Dictionary, english: bool) -> String:
	match str(details.get("reason","")):
		"eviction": return words("淘汰", "eviction", english)
		"flush": return words("结束写回", "final flush", english)
	return words("原因未记录或未知", "reason missing or unknown", english)

static func title(event: Dictionary, english: bool) -> String:
	var kind: String = str(event.get("kind",""))
	var names: Dictionary = {
		"state_read": ["读入状态","Read state"], "state_hit": ["复用驻留状态","Reuse resident state"],
		"state_write": ["写回状态","Write back state"], "eviction": ["释放状态槽","Evict resident state"],
		"compute": ["更新状态并计算","Update state and compute"], "output": ["返回结果","Return result"],
		"commit": ["提交结果","Commit result"], "encode": ["编码状态","Encode state"],
		"decode": ["解码状态","Decode state"], "quantize": ["量化状态","Quantize state"],
		"request": ["发起搬运请求","Start transfer request"], "weight_read": ["读入权重","Read weights"],
		"group_read": ["读入整组输入","Read group inputs"], "initial_store": ["初始外存","Initial backing store"],
		"final_store": ["最终外存","Final backing store"], "flush_begin": ["开始结束写回","Begin final flush"]}
	var d: Dictionary = event.get("details",{}) if event.get("details",{}) is Dictionary else {}
	var text: String = str(names[kind][1 if english else 0]) if names.has(kind) else words("未知事件", "Unknown event", english)
	var who: String = identity(d)
	if not who.is_empty(): text = who + " · " + text
	if kind == "state_write": text += " (" + reason(d,english) + ")"
	return text

static func summary(event: Dictionary, english: bool) -> String:
	var kind: String = str(event.get("kind",""))
	var d: Dictionary = event.get("details",{}) if event.get("details",{}) is Dictionary else {}
	var lines: PackedStringArray = [title(event,english)]
	match kind:
		"state_read": lines.append(words("状态不在本地槽中，从外存读入。", "State is absent locally; read it from backing storage.",english))
		"state_hit": lines.append(words("状态仍在本地槽中，可复用，无需再次读入；后续运算仍计费。", "State remains resident: reuse it without another state read. Later computation still costs cycles.",english))
		"state_write": lines.append(words("将更新后的状态从本地写回外存；", "Write updated state from local storage to backing storage; ",english)+reason(d,english)+".")
		"eviction": lines.append(words("自动LRU释放此流的本地槽。", "Automatic LRU releases this stream's local slot.",english))
		"compute": lines.append(words("用此请求更新八值状态，并计算分数。", "Update the eight-value state with this request and compute its score.",english))
		"output": lines.append(words("将已计算的分数返回给此请求。", "Return the computed score for this request.",english))
	var evidence: PackedStringArray = []
	for field: String in ["cycle","duration"]:
		if event.has(field): evidence.append((words("起始周期", "Start cycle",english) if field == "cycle" else words("本事件周期", "Event cycles",english))+": "+str(event[field]))
	if d.has("bytes"):
		evidence.append(str(d.bytes)+" B"+(words("（含2B目录项）", " (including 2B directory entry)",english) if kind in ["state_read","state_write"] else ""))
	if d.has("representation"): evidence.append(str(d.representation).to_upper())
	if not evidence.is_empty(): lines.append(" · ".join(evidence))
	if kind in ["state_read","state_hit","state_write","eviction","compute","output","commit","encode","decode","quantize"] and identity(d).is_empty(): lines.append(words("流/请求身份未记录或无效。", "Stream/request identity is missing or invalid.",english))
	return "\n".join(lines)
