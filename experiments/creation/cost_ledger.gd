extends RefCounted
## Read-only summaries of resolved transport events. No simulation or timing here.
const Model = preload("res://experiments/creation/model.gd")
const PHASES := ["encode", "transfer", "decode", "output"]
const CODECS := ["raw", "predictive"]

static func identity(source: Array) -> String:
	return JSON.stringify(source).sha256_text()

static func capture(source: Array, model: Dictionary, machine: Dictionary, preparation: Dictionary, raw: Dictionary, predictive: Dictionary, preparation_machine: Dictionary = {}) -> Dictionary:
	return {"source_id":identity(source), "source_length":source.size(),
		"model_id":Model.identity(model) if not model.is_empty() else "",
		"order":int(model.get("order",0)), "machine":machine.duplicate(true),
		"preparation":preparation.duplicate(true), "preparation_machine":preparation_machine.duplicate(true), "results":{"raw":summarize(raw),"predictive":summarize(predictive)}}

static func summarize(result: Dictionary) -> Dictionary:
	if not result.get("ok",false):
		return {"ok":false,"error":str(result.get("error","unknown")),"required_bytes":int(result.get("required_bytes",0))}
	var phases: Dictionary = {}
	for name: String in PHASES: phases[name] = {"cycles":0,"ops":0,"bytes":0,"events":0}
	for event: Dictionary in result.get("events",[]):
		var phase: String = str(event.get("phase",""))
		if not phases.has(phase): phases[phase] = {"cycles":0,"ops":0,"bytes":0,"events":0}
		phases[phase].cycles += int(event.get("cycles",0))
		phases[phase].ops += int(event.get("ops",0))
		phases[phase].bytes += int(event.get("bytes",0))
		phases[phase].events += 1
	return {"ok":true,"lossless":bool(result.get("lossless",false)),
		"cost":result.cost.duplicate(true),"metrics":result.metrics.duplicate(true),
		"model_id":str(result.get("model_id","")),"output_id":identity(result.output),"phases":phases}

static func matches(snapshot: Dictionary, source: Array, model: Dictionary, machine: Dictionary) -> bool:
	if snapshot.is_empty(): return false
	var model_id: String = Model.identity(model) if not model.is_empty() else ""
	return snapshot.source_id == identity(source) and snapshot.model_id == model_id and snapshot.machine == machine

static func total(snapshot: Dictionary, codec: String, metric: String) -> int:
	var result: Dictionary = snapshot.get("results",{}).get(codec,{})
	if not result.get("ok",false): return 0
	if metric == "packet_bytes": return int(result.metrics.packet_bytes)
	return int(result.cost.get(metric,0))

static func cycle_segments(snapshot: Dictionary, codec: String) -> Array:
	var result: Dictionary = snapshot.get("results",{}).get(codec,{})
	var segments: Array = []
	if not result.get("ok",false): return segments
	for phase: String in result.phases:
		segments.append({"phase":phase,"value":int(result.phases[phase].cycles)})
	return segments

static func phase_name(phase: String, english: bool) -> String:
	var names: Dictionary = {"encode":["编码","encode"],"transfer":["传输","transfer"],"decode":["解码","decode"],"output":["输出","output"]}
	return names[phase][1 if english else 0] if names.has(phase) else phase

static func verdict(snapshot: Dictionary, english: bool) -> String:
	var results: Dictionary = snapshot.get("results",{})
	if not results.get("raw",{}).get("ok",false) or not results.get("predictive",{}).get("ok",false):
		return "Both transports must finish before comparing costs." if english else "两种传输都完成后，才能比较成本高低。"
	var packet_delta: int = total(snapshot,"predictive","packet_bytes")-total(snapshot,"raw","packet_bytes")
	var cycle_delta: int = total(snapshot,"predictive","total_cycles")-total(snapshot,"raw","total_cycles")
	var packet: String = ("same packet size" if english else "包大小相同") if packet_delta == 0 else (("%d B smaller" if packet_delta<0 else "%d B larger")%absi(packet_delta) if english else ("少 %d B" if packet_delta<0 else "多 %d B")%absi(packet_delta))
	var cycles: String = ("same total cycles" if english else "总周期相同") if cycle_delta == 0 else (("%d fewer cycles" if cycle_delta<0 else "%d more cycles")%absi(cycle_delta) if english else ("少 %d 周期" if cycle_delta<0 else "多 %d 周期")%absi(cycle_delta))
	return ("Predictive vs RAW: " if english else "预测包相对 RAW：")+packet+"；"+cycles+"。"

static func describe(snapshot: Dictionary, english: bool) -> String:
	if snapshot.is_empty(): return "Run a locked RAW / predictive comparison first." if english else "先运行一次锁定条件的 RAW／预测包对照。"
	var lines := PackedStringArray()
	lines.append(verdict(snapshot,english))
	var machine: Dictionary = snapshot.machine
	lines.append(("Frozen conditions" if english else "本次冻结条件")+": N=%d · source %s · model %s · order %d"%[snapshot.source_length,str(snapshot.source_id).substr(0,10),str(snapshot.model_id).substr(0,10),snapshot.order])
	lines.append("CPU %d ops/cycle · bus %d B/cycle · req %d cycles · cache %d rows · RAM %d B"%[machine.cpu_ops_per_cycle,machine.bytes_per_cycle,machine.request_cycles,machine.cache_rows,machine.memory_bytes])
	for codec: String in CODECS:
		var result: Dictionary = snapshot.results[codec]
		if not result.ok:
			lines.append(codec+": "+("not completed" if english else "未完成")+" · "+result.error+(" · "+str(result.required_bytes)+" B" if result.required_bytes>0 else ""))
			continue
		lines.append("%s · %s · %d cycles · %d ops · %d B %s · %d B %s"%[codec,"lossless" if result.lossless else "MISMATCH",result.cost.total_cycles,result.cost.cpu_ops,result.cost.transfer_bytes,"total traffic" if english else "总搬运",result.cost.peak_bytes,"peak" if english else "峰值"])
		for phase: String in result.phases:
			var row: Dictionary = result.phases[phase]
			lines.append("  %s: %d cycles / %d ops / %d B"%[phase_name(phase,english),row.cycles,row.ops,row.bytes])
		var metrics: Dictionary = result.metrics
		lines.append(("  Packet" if english else "  实际包")+": %d B = %d header + %d model + %d payload + %d checksum"%[metrics.packet_bytes,metrics.header_bytes,metrics.model_bytes,metrics.payload_bytes,metrics.checksum_bytes])
	if not snapshot.preparation.is_empty():
		lines.append(("Recorded learning, shown separately (not repeated per send): " if english else "已记录学习，单列且不按每次发送重复收费：")+str(snapshot.preparation.total_cycles)+" cycles")
	if not snapshot.get("preparation_machine",{}).is_empty():
		var prepared_on: Dictionary = snapshot.preparation_machine
		lines.append(("Learning machine: " if english else "历史学习机器：")+"CPU %d / bus %d / req %d / cache %d / RAM %d B"%[prepared_on.cpu_ops_per_cycle,prepared_on.bytes_per_cycle,prepared_on.request_cycles,prepared_on.cache_rows,prepared_on.memory_bytes])
	if not snapshot.preparation.is_empty() and snapshot.results.predictive.get("ok",false):
		var first_use: int = int(snapshot.preparation.total_cycles)+total(snapshot,"predictive","total_cycles")
		lines.append(("From scratch, predictive learning + this send = " if english else "若从零开始，预测路径的学习＋本次发送＝")+str(first_use)+(" cycles. RAW requires no learned model." if english else " 周期。RAW 不需要学得模型。"))
	lines.append("Packet bytes and cycles use separate scales. Total traffic also includes local rule/data reads and writes. Sequential event costs; playback speed has no effect." if english else "包字节与周期使用不同标尺。总搬运还包含本地规则／数据读写。周期取自顺序事件，播放快慢不影响结果。")
	return "\n".join(lines)
