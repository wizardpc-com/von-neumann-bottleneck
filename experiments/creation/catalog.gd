extends RefCounted
## Public teaching material. Sealed prediction streams belong to Session.
const IDS := ["C1_restore", "C2_cost", "C3_conditions", "P1_commit", "P2_memory", "P3_check", "G1_feedback", "G2_intent", "G3_keep"]
const TITLES_ZH := ["C1 · 让例外抵达", "C2 · 规则也占位置", "C3 · 值不值得这样搬", "P1 · 下一格尚未抵达", "P2 · 需要记住多少", "P3 · 带着不确定检查", "G1 · 让输出接回输入", "G2 · 按自己的意图改变", "G3 · 留下你的下一段"]
const TITLES_EN := ["C1 · Carry the exceptions", "C2 · Rules take space", "C3 · Is this worth moving?", "P1 · The next cell is sealed", "P2 · How much history?", "P3 · A frozen check", "G1 · Feed output back", "G2 · Change with intent", "G3 · Keep your next passage"]
const GOALS_ZH := [
	"选择样例并学习规则盒，发送预测包。接收端只拿包复原；点选一格，追到预测和真正修正。无损相等即可留下本单元证据。",
	"比较同一原文的 RAW 与预测包。规则表、头部和修正全部计字节；短片段或较大的规则盒可能不划算。",
	"接受两份光纹配送订单：同原文、同规则盒，期限分别240000／223000周期，只有计算吞吐改变。自己选择RAW或预测包，按真实总成本无损送达；新规则可能改变取舍。机器会继续带到后面。",
	"主动接到未揭晓输入。先提交一格预测，再揭晓真值；只显示已见前缀。模型保持冻结，不在揭晓时偷偷学习。",
	"对照最近1项与2项历史：A 后面既可能是 B 也可能是 C。重新学习后再练习，记录哪些上下文被区分，以及规则的代价。",
	"委托：延续同族但未见的光纹。选「稳定规律与例外」样例学习，先调试独立练习，再开独立检查。两项历史能区分 BA/CA，却无法确定 BA 后的稀少 D；只用已揭晓格追因。重复检查标为已见。",
	"主动断开标准下一段，接上自己的输出。选择起始片段，用同一个学得模型延续。此后没有隐藏原文，也没有正确率。",
	"受控设计：固定种子、起始片段、长度和机器，只改变样例、记忆或采样中的一项，再比较规则与实测输出。换种子或起始片段可自由探索，但不算设计证据。也可独立确认保存满意作品；相同输出仍是有效观察。",
	"命名并确认一件实际输出。保存快照和完整配方；播放快照、按配方再生、继续分叉分别操作。你的选择形成结尾。"
]
const GOALS_EN := [
	"Choose examples and learn a rule box, then send a predictive packet. The receiver restores from that packet only. Select a cell to trace the guess and correction. Exact restoration is sufficient evidence.",
	"Compare RAW and predictive packets for the same source. Rules, headers and corrections all count. Short passages or large rule boxes may cost more.",
	"Accept two signal delivery orders: one source and rule box, deadlines 240000 / 223000 cycles, only CPU throughput changes. Choose RAW or predictive for exact delivery under actual total costs; different rules may change the tradeoff. The machine continues into the next chapters.",
	"Connect to sealed input explicitly. Commit one prediction before revealing its truth. Only the observed prefix appears. The frozen model never learns secretly on reveal.",
	"Compare one and two symbols of history: A may lead to B or C. Learn again and practise. Inspect which contexts separate and what their rules cost.",
	"Commission: continue an unseen passage from the same signal family. Learn the stable/exception sample, tune on separate practice, then start its independent check. Two cells distinguish BA/CA but cannot determine the rare D after BA. Trace only revealed cells; repeated checks are labelled seen.",
	"Disconnect the standard continuation and connect your own output. Choose an initial passage and extend it with the same learned model. There is no hidden original or accuracy score.",
	"Controlled design: fix seed, initial passage, length and machine; change exactly one of examples, history or sampling, then compare learned rules and real output. Seed/start variations are free exploration, not design evidence. Keep a chosen work independently; identical output remains a valid observation.",
	"Name and confirm real output. Save its snapshot and full recipe. Play the snapshot, regenerate the recipe, and fork as distinct actions. Your choice forms the ending."
]
const SAMPLE_NAMES_ZH := ["ABAC · 两步规律", "ABAD · 一个分岔", "ABCD · 四色行进", "AABB · 双拍", "ACAD · 另一条路", "ABAC · 稳定规律与稀少例外"]
const SAMPLE_NAMES_EN := ["ABAC · two-step pattern", "ABAD · a branch", "ABCD · four-step walk", "AABB · paired beats", "ACAD · another path", "ABAC · stable history, rare exceptions"]

static func title(index: int, english: bool = false) -> String:
	return (TITLES_EN if english else TITLES_ZH)[clampi(index,0,IDS.size()-1)]

static func goal(index: int, english: bool = false) -> String:
	return (GOALS_EN if english else GOALS_ZH)[clampi(index,0,IDS.size()-1)]

static func sample(index: int) -> Array:
	if index == 5:
		var material: Array = []
		for i: int in 48: material.append([0,1,0,2][i % 4])
		material[31] = 3
		return material
	var motif: Array = [[0,1,0,2],[0,1,0,3],[0,1,2,3],[0,0,1,1],[0,2,0,3]][clampi(index,0,4)]
	var result: Array = []
	for i: int in 24: result.append(motif[i % motif.size()])
	return result

static func source(kind: int) -> Array:
	var result: Array = []
	var count: int = 12 if kind == 2 else 1536
	var state: int = 731
	for i: int in count:
		state = (state * 48271) % 2147483647
		result.append((state % 4) if kind == 1 else [0,1,0,2][i % 4])
	if kind == 0:
		for i: int in [31,87,171,289]: result[i] = 3
	return result

static func symbols(values: Array) -> String:
	var parts := PackedStringArray()
	for value: Variant in values: parts.append(["A","B","C","D"][clampi(int(value),0,3)])
	return " ".join(parts)

static func parse_symbols(text: String) -> Dictionary:
	var result: Array = []
	for token: String in text.to_upper().replace(","," ").replace("\n"," ").split(" ",false):
		if not token in ["A","B","C","D","0","1","2","3"]:
			return {"ok":false,"error":"A B C D / 0 1 2 3"}
		result.append(["A","B","C","D"].find(token) if token in ["A","B","C","D"] else int(token))
	if result.size() > 96: return {"ok":false,"error":"max 96"}
	return {"ok":true,"symbols":result}
