extends SceneTree
const Explanation = preload("res://experiments/creation/explanation.gd")
const Model = preload("res://experiments/creation/model.gd")
const Codec = preload("res://experiments/creation/codec.gd")
var failures: int = 0
var checks: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func _init() -> void:
	var machine: Dictionary = Model.default_machine()
	var learned: Dictionary = Model.learn([[0,1,0,2],[0,1,0,3]],1,machine)
	var decision: Dictionary = Model.predict(learned.model,[0])
	var frozen: String = JSON.stringify(decision)
	for english: bool in [false,true]:
		var pending: String = Explanation.prediction(decision,[0],false,english)
		check(pending.contains("A:0 B:2 C:1 D:1"),"Actual successor counts")
		check(pending.contains("Actual value not yet revealed" if english else "实际尚未揭晓"),"No truth invented before reveal")
		check(pending.contains("A→B→C→D"),"Deterministic tie rule")
		var row: Dictionary = {"predicted":1,"truth":3,"context":[0],"counts":[0,2,1,1]}
		var summary: String = Explanation.prediction(row,[0,1,0],false,english)
		check(summary.contains("B → Actual D" if english else "B → 实际 D"),"Mismatch names both symbols")
		check(summary.contains("next context" if english else "下一步上下文"),"Revealed truth feeds next context")
		var baseline: String = Explanation.prediction(row,[0],true,english)
		check(baseline.contains("Position baseline" if english else "按位置背诵") and not baseline.contains("A:0"),"Position baseline is not a learned rule")
		check(Explanation.audit(summary,row,english).ends_with(JSON.stringify(row)),"Original audit preserved")
		var transport: Dictionary = Codec.run_transport([0,3,0,1],learned.model,machine)
		check(transport.ok,"Real transport fixture")
		for event: Dictionary in transport.events:
			if event.kind != "residual_write": continue
			var text: String = Explanation.cell(event,transport.events,transport.output.slice(0,event.index),english)
			var expected: String = "A:4 B:2 C:1 D:1" if event.index == 2 else "A:0 B:2 C:1 D:1"
			check(text.contains(expected),"Trace supplies correct row counts, including fallback")
			check(text.contains(("2 correction bits" if english else "2 个修正位") if not event.match else ("no correction symbol" if english else "无修正符号")),"Actual match/correction explained")
		var generated: Dictionary = Model.generate(learned.model,[0],8,17,"weighted",machine)
		for event: Dictionary in generated.events:
			if event.kind != "feedback_write": continue
			var text: String = Explanation.cell(event,generated.events,generated.output.slice(0,event.index),english)
			check(text.contains("Count-weighted sampling" if english else "按计数加权抽样"),"Actual sampler used")
			check(text.contains("no target answer" if english else "没有标准答案"),"Generation does not invent truth")
		var literal: String = Explanation.cell({"kind":"literal_write","symbol":2},[],[],english)
		check(literal.contains("no model prediction" if english else "没有模型预测"),"RAW and seed not misattributed")
	var fallback: Dictionary = Model.predict(learned.model,[3])
	check(Explanation.prediction(fallback,[3],false,false).contains("∅ 不看上下文"),"Unseen context shows actual fallback rule")
	var empty_model: Dictionary = Model.learn([[]],1,machine)
	var uniform: Dictionary = Model.predict(empty_model.model,[0])
	check(Explanation.prediction(uniform,[0],false,false).contains("A:1 B:1 C:1 D:1"),"Uniform default weights are not invented counts")
	check(JSON.stringify(decision) == frozen,"Explanation does not mutate model output")
	print("%s: creation explanation checks=%d failures=%d" % ["PASS" if failures == 0 else "FAIL",checks,failures])
	quit(0 if failures == 0 else 1)
