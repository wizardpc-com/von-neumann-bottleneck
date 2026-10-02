extends RefCounted
## Deterministic tiny linear inference workload, not a neural-quality benchmark.
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Costs = preload("res://experiments/representation/model.gd")
const WEIGHTS = [0.83,-0.41,0.17,0.06,-0.29,0.71,-0.13,0.37]

static func samples() -> Array[Array]:
	var result: Array[Array] = []
	for i: int in 32:
		var row: Array = []
		for j: int in 8: row.append(float(((i+3)*(j*7+5)+j*j*11) % 31 - 15)/15.0)
		result.append(row)
	return result

static func weights(bits: int) -> Array[float]:
	var out: Array[float] = []
	var max_int: int = (1 << (bits-1))-1 if bits < 32 else 0
	for value: float in WEIGHTS:
		out.append(roundf(value*max_int)/max_int if bits < 32 else value)
	return out

static func score(input: Array, params: Array) -> float:
	var total: float = 0
	for i: int in input.size(): total += float(input[i])*float(params[i])
	return total

static func run(config: Dictionary) -> Trace:
	var trace := Trace.new()
	trace.test_name = "tiny-linear-v1"
	trace.metrics = {"total_cycles":0,"traffic_bytes":0,"compute_cycles":0,"transfer_cycles":0,"request_cycles":0,
		"peak_bytes":0,"first_result_cycle":0,"correct":0,"samples":32,"max_error":0.0,"mae":0.0,
		"outputs":[],"reference":[],"error":"","config":config.duplicate(true)}
	var bits: int = int(config.get("bits",32)); var batch: int = int(config.get("batch",1))
	var keep: bool = bool(config.get("reuse",false))
	if bits not in [32,8,4,2] or batch not in [1,4,8]: trace.metrics.error="config"; return trace
	# Quantized weights carry a four-byte scale. Inputs/activation workspace is float32.
	var weight_bytes: int = 32 if bits == 32 else 4 + ceili(8.0*bits/8.0)
	var peak: int = weight_bytes + batch*8*4 + batch*4
	trace.metrics.peak_bytes = peak
	if peak > 320: trace.metrics.error="scratch_limit"; return trace
	var params: Array[float] = weights(bits); var inputs: Array[Array] = samples()
	var loaded: bool = false
	for start: int in range(0,inputs.size(),batch):
		var moved: int = batch*8*4 + (0 if keep and loaded else weight_bytes)
		var transfer: int = ceili(float(moved)/4.0)
		Costs.emit(trace,&"request",4,{"batch_start":start})
		Costs.emit(trace,&"transfer",transfer,{"batch_start":start,"bytes":moved,"weight_bytes":0 if keep and loaded else weight_bytes})
		trace.metrics.traffic_bytes += moved; trace.metrics.transfer_cycles += transfer; trace.metrics.request_cycles += 4
		loaded = true
		# Same MAC throughput for every precision: no invented quantized speed multiplier.
		var compute: int = batch*8
		Costs.emit(trace,&"compute",compute,{"batch_start":start,"macs":compute,"stored_weights":params})
		trace.metrics.compute_cycles += compute
		for i: int in range(start,start+batch):
			var value: float = score(inputs[i],params); var reference: float = score(inputs[i],WEIGHTS)
			var error: float = absf(value-reference)
			trace.metrics.outputs.append(value); trace.metrics.reference.append(reference)
			trace.metrics.correct += int((value >= 0) == (reference >= 0))
			trace.metrics.max_error = maxf(trace.metrics.max_error,error); trace.metrics.mae += error/inputs.size()
			Costs.emit(trace,&"output",1,{"sample":i,"input":inputs[i],"score":value,"reference":reference,"absolute_error":error})
			if i == 0: trace.metrics.first_result_cycle = trace.metrics.total_cycles
	trace.metrics.weight_bytes = weight_bytes
	trace.metrics.agreement = float(trace.metrics.correct)/inputs.size()
	# Valid execution is distinct from application quality acceptance.
	trace.passed = true; trace.result_value = trace.metrics.correct; trace.expected_value = inputs.size()
	return trace
