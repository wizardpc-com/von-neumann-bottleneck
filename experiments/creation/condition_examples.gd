extends RefCounted
## Public machine conditions, never a verdict or an automatic model/source edit.
## Both are existing workbench options. Only compute throughput differs.
const Model = preload("res://experiments/creation/model.gd")

static func machine(index: int) -> Dictionary:
	var result: Dictionary = Model.default_machine()
	result.cpu_ops_per_cycle = 1 if index <= 0 else 64
	result.bytes_per_cycle = 1
	result.request_cycles = 64
	result.cache_rows = 21
	return result

static func title(index: int, english: bool = false) -> String:
	if english:
		return "A · Compute 1 op/cycle" if index <= 0 else "B · Compute 64 ops/cycle"
	return "A · 计算 1 运算/周期" if index <= 0 else "B · 计算 64 运算/周期"

static func hint(english: bool = false) -> String:
	if english:
		return "Two public machines: bus 1 B/cycle, request 64 cycles, automatic cache 21 rows, RAM 8192 B. Only CPU throughput changes. Keep the source and learned rule box; run both codecs under A, then B. Results depend on your rules and source. Applying a condition does not run or learn."
	return "两台公开机器：通道 1 B/周期、请求 64 周期、自动缓存 21 行、内存 8192 B。只改变计算吞吐。保留原文与学得规则盒，分别在 A、B 下实测两种 codec；结果取决于你的规则与原文。应用条件不会运行或重新学习。"

# Public per-send deadlines. Learning is already prepared and accounted separately.
static func deadline(index: int) -> int:
	return 240000 if index <= 0 else 223000

static func delivery(result: Dictionary, index: int) -> Dictionary:
	if not result.get("ok",false) or not result.get("lossless",false):
		return {"ok":false,"reason":"transport"}
	var cycles: int = int(result.cost.total_cycles)
	return {"ok":cycles <= deadline(index),"cycles":cycles,"budget":deadline(index)}
