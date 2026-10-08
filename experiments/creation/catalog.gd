extends RefCounted
## Public teaching material. Sealed prediction streams belong to Session.
const IDS := ["C1_restore", "C2_cost", "C3_conditions", "P1_commit", "P2_memory", "P3_check", "G1_feedback", "G2_intent", "G3_keep"]
const TITLES_ZH := ["C1 · 让例外抵达", "C2 · 规则也占位置", "C3 · 值不值得这样搬", "P1 · 下一格尚未抵达", "P2 · 需要记住多少", "P3 · 带着不确定检查", "G1 · 让输出接回输入", "G2 · 按自己的意图改变", "G3 · 留下你的下一段"]
const TITLES_EN := ["C1 · Carry the exceptions", "C2 · Rules take space", "C3 · Is this worth moving?", "P1 · The next cell is sealed", "P2 · How much history?", "P3 · A frozen check", "G1 · Feed output back", "G2 · Change with intent", "G3 · Keep your next passage"]
const GOALS_ZH := [
	"选择样例并学习规则盒，发送预测包。接收端只拿包复原；点选一格，追到预测和真正修正。无损相等即可留下本单元证据。",
	"比较同一原文的 RAW 与预测包。规则表、头部和修正全部计字节；短片段或较大的规则盒可能不划算。",
	"沿用原文与规则盒，只改一项机器条件，再实测两种表示。观察真实阶段：少搬字节是否足以抵偿编码与解码？机器会继续带到后面。",
	"主动接到未揭晓输入。先提交一格预测，再揭晓真值；只显示已见前缀。模型保持冻结，不在揭晓时偷偷学习。",
	"对照最近1项与2项历史：A 后面既可能是 B 也可能是 C。重新学习后再练习，记录哪些上下文被区分，以及规则的代价。",
	"练习可以调试；冻结检查独立开始。只用已见数据解释失败；看过检查答案会如实标记。检查不是通用泛化证明。",
	"主动断开标准下一段，接上自己的输出。选择起始片段，用同一个学得模型延续。此后没有隐藏原文，也没有正确率。",
	"可以固定随机种子，改样例、起始片段、记忆或采样，比较来路与光纹。也可直接确认保存满意的合法作品；不要求两次输出不同。",
	"命名并确认一件实际输出。保存快照和完整配方；播放快照、按配方再生、继续分叉分别操作。你的选择形成结尾。"
]
const GOALS_EN := [
	"Choose examples and learn a rule box, then send a predictive packet. The receiver restores from that packet only. Select a cell to trace the guess and correction. Exact restoration is sufficient evidence.",
	"Compare RAW and predictive packets for the same source. Rules, headers and corrections all count. Short passages or large rule boxes may cost more.",
	"Keep the source and rule box; change one machine condition, then measure both representations. Inspect real phases: does less traffic repay encoding and decoding? This machine continues into the next chapters.",
	"Connect to sealed input explicitly. Commit one prediction before revealing its truth. Only the observed prefix appears. The frozen model never learns secretly on reveal.",
	"Compare one and two symbols of history: A may lead to B or C. Learn again and practise. Inspect which contexts separate and what their rules cost.",
	"Practice permits debugging; begin a separate frozen check. Explain errors using revealed data. Seen check answers are labelled. A check is no universal generalization proof.",
	"Disconnect the standard continuation and connect your own output. Choose an initial passage and extend it with the same learned model. There is no hidden original or accuracy score.",
	"You may fix a seed and compare changes to examples, initial context, history or sampling. Or confirm and keep one legal work you like; two different outputs are not required.",
	"Name and confirm real output. Save its snapshot and full recipe. Play the snapshot, regenerate the recipe, and fork as distinct actions. Your choice forms the ending."
]
const SAMPLE_NAMES_ZH := ["ABAC · 两步规律", "ABAD · 一个分岔", "ABCD · 四色行进", "AABB · 双拍", "ACAD · 另一条路"]
const SAMPLE_NAMES_EN := ["ABAC · two-step pattern", "ABAD · a branch", "ABCD · four-step walk", "AABB · paired beats", "ACAD · another path"]

static func title(index: int, english: bool = false) -> String:
	return (TITLES_EN if english else TITLES_ZH)[clampi(index,0,IDS.size()-1)]

static func goal(index: int, english: bool = false) -> String:
	return (GOALS_EN if english else GOALS_ZH)[clampi(index,0,IDS.size()-1)]

static func sample(index: int) -> Array:
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
