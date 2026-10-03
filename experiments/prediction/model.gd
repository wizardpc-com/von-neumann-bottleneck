extends RefCounted
const Trace = preload("res://src/simulation/simulation_trace.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
const Predictor = preload("res://experiments/prediction/predictor.gd")
const Catalog = preload("res://experiments/prediction/catalog.gd")
const Cache = preload("res://experiments/representation/decoded_cache.gd")
const FETCH_CYCLES: int = 6
const LINE_BYTES: int = 4

static func default_policy() -> Dictionary:
	return {"rule":"off","confidence":1,"lookahead":1,"cooldown":0}

static func valid_policy(policy: Dictionary) -> bool:
	return policy.get("rule") is String and policy.get("rule") in ["off","stride","two_stride"] and policy.get("confidence") is int and policy.get("confidence") in [1,2,3] and policy.get("lookahead") is int and policy.get("lookahead") in [1,2] and policy.get("cooldown") is int and policy.get("cooldown") in [0,2]

static func run(spec: Dictionary, policy: Dictionary) -> Trace:
	var trace: Trace = _execute(spec,policy)
	if not trace.passed: return trace
	var baseline: Trace = _execute(spec,default_policy())
	trace.metrics.baseline_cycles = baseline.metrics.total_cycles
	trace.metrics.baseline_traffic_bytes = baseline.metrics.traffic_bytes
	trace.metrics.pollution_misses = 0
	for i: int in trace.metrics.accesses.size():
		var pollution: bool = not bool(trace.metrics.accesses[i].hit) and bool(baseline.metrics.accesses[i].hit)
		trace.metrics.accesses[i].pollution = pollution
		if pollution: trace.metrics.pollution_misses += 1
	for event: Event in trace.events:
		if event.kind == &"demand": event.details.pollution = trace.metrics.accesses[int(event.details.step)-1].pollution
	return trace

static func _event(trace: Trace, kind: StringName, cycle: int, duration: int, address: int, step: int, details: Dictionary = {}) -> void:
	var evidence: Dictionary = details.duplicate(true); evidence.step = step
	var source: StringName = &"CPU"
	var target: StringName = &"Cache"
	if kind==&"prediction": source=&"Predictor"; target=&"Bus"
	elif kind==&"request": source=&"Predictor" if bool(details.get("speculative",false)) else &"CPU"; target=&"RAM"
	elif kind==&"transfer": source=&"RAM"; target=&"Cache"
	elif kind==&"fill": source=&"Bus"
	elif kind==&"demand": source=&"Cache"; target=&"CPU"
	elif kind==&"compute": target=&"CPU"
	elif kind in [&"wait",&"drain"]: target=&"Bus"
	trace.add_event(Event.new(kind,cycle,duration,source,target,address,address/4,int(details.get("value",0)),String(kind),0,[],evidence))

static func _finish_job(trace: Trace, state: Dictionary, cache: Cache, until: int, step: int) -> void:
	if state.job.is_empty() or int(state.job.finish) > until: return
	var job: Dictionary = state.job
	var evicted: Array[int] = cache.put(int(job.address)/4,[Catalog.value_at(int(job.address))],LINE_BYTES)
	for key: int in evicted:
		if state.speculative.has(key): state.speculative.erase(key)
	if bool(job.speculative): state.speculative[int(job.address)/4] = int(job.id)
	_event(trace,&"fill",int(job.finish),0,int(job.address),step,{"speculative":job.speculative,"evicted":evicted,"cache":cache.snapshot(),"job_id":job.id,"value":Catalog.value_at(int(job.address))})
	trace.metrics.evictions += evicted.size()
	trace.metrics.peak_cache_bytes = maxi(int(trace.metrics.peak_cache_bytes),int(cache.snapshot().used_bytes))
	state.job = {}

static func _start_job(trace: Trace, state: Dictionary, address: int, speculative: bool, step: int) -> void:
	var id: int = int(state.next_id); state.next_id += 1
	state.job = {"address":address,"finish":int(state.clock)+FETCH_CYCLES,"speculative":speculative,"id":id}
	trace.metrics.request_cycles += 4; trace.metrics.transfer_cycles += 2
	trace.metrics.traffic_bytes += LINE_BYTES
	if speculative:
		trace.metrics.prediction_bytes += LINE_BYTES
		state.issued.append(id)
	else: trace.metrics.demand_bytes += LINE_BYTES
	_event(trace,&"request",int(state.clock),4,address,step,{"speculative":speculative,"job_id":id})
	_event(trace,&"transfer",int(state.clock)+4,2,address,step,{"speculative":speculative,"bytes":LINE_BYTES,"job_id":id})

static func _execute(spec: Dictionary, policy: Dictionary) -> Trace:
	var trace := Trace.new(); trace.test_name = str(spec.get("name","custom"))
	trace.program_source = JSON.stringify(policy)
	trace.metrics = {"error":"","total_cycles":0,"lookup_cycles":0,"compute_cycles":0,"blocking_cycles":0,"queue_wait_cycles":0,"fallback_cycles":0,"inflight_wait_cycles":0,"drain_cycles":0,"request_cycles":0,"transfer_cycles":0,"traffic_bytes":0,"prediction_bytes":0,"demand_bytes":0,"useful_prediction_bytes":0,"wasted_prediction_bytes":0,"cache_hits":0,"cache_misses":0,"inflight_matches":0,"wrong_guesses":0,"evictions":0,"peak_cache_bytes":0,"outputs":[],"accesses":[],"decisions":[]}
	if not valid_policy(policy) or not spec.get("addresses") is Array or not spec.get("compute_gap") is int or spec.get("compute_gap") < 0 or spec.get("compute_gap") > 32 or not spec.get("cache_slots") is int or spec.get("cache_slots") not in [1,2]:
		trace.metrics.error = "invalid_configuration"; return trace
	var addresses: Array = spec.addresses
	if addresses.is_empty() or addresses.size() > 64: trace.metrics.error = "invalid_stream"; return trace
	for raw: Variant in addresses:
		if not raw is int or int(raw) < 0 or int(raw) > 124 or int(raw) % 4 != 0: trace.metrics.error = "invalid_address"; return trace
	trace.cache_capacity_lines = int(spec.cache_slots)
	var cache := Cache.new(); cache.configure(int(spec.cache_slots),int(spec.cache_slots)*LINE_BYTES)
	var predictor := Predictor.new(); predictor.configure(policy)
	var state: Dictionary = {"clock":0,"job":{},"next_id":0,"issued":[],"used":{},"speculative":{}}
	for i: int in addresses.size():
		var address: int = int(addresses[i]); var step: int = i+1
		var arrived: int = int(state.clock)
		state.clock += 1; trace.metrics.lookup_cycles += 1
		_finish_job(trace,state,cache,int(state.clock),step)
		var hit: bool = cache.has(address/4)
		var before: Dictionary = cache.snapshot()
		var path: String = "hit" if hit else "fallback"
		if hit: trace.metrics.cache_hits += 1
		else:
			trace.metrics.cache_misses += 1
			if not state.job.is_empty():
				var matching: bool = int(state.job.address) == address
				var wait: int = int(state.job.finish)-int(state.clock)
				_event(trace,&"wait",int(state.clock),wait,address,step,{"reason":"matching_inflight" if matching else "bus_occupied","job_address":state.job.address})
				trace.metrics.blocking_cycles += wait
				if matching: trace.metrics.inflight_wait_cycles += wait; trace.metrics.inflight_matches += 1; path = "inflight"
				else: trace.metrics.queue_wait_cycles += wait
				state.clock += wait; _finish_job(trace,state,cache,int(state.clock),step)
			if not cache.has(address/4):
				_start_job(trace,state,address,false,step)
				trace.metrics.blocking_cycles += FETCH_CYCLES; trace.metrics.fallback_cycles += FETCH_CYCLES
				state.clock += FETCH_CYCLES; _finish_job(trace,state,cache,int(state.clock),step)
		var fetched: Array[int] = cache.fetch(address/4)
		if fetched.size()!=1:
			trace.metrics.error = "missing_fetched_value"; return trace
		if state.speculative.has(address/4): state.used[int(state.speculative[address/4])] = true
		var value: int = fetched[0]
		var expected: int = Catalog.value_at(address)
		trace.metrics.outputs.append(value); trace.result_value += value; trace.expected_value += expected
		if value!=expected: trace.metrics.error = "incorrect_fetched_value"; return trace
		var access: Dictionary = {"step":step,"address":address,"value":value,"hit":hit,"path":path,"arrived":arrived,"ready":state.clock,"cache_before":before,"cache_after":cache.snapshot()}
		trace.metrics.accesses.append(access)
		_event(trace,&"demand",int(state.clock),0,address,step,access)
		var decision: Dictionary = predictor.observe(address)
		if bool(decision.mismatch): trace.metrics.wrong_guesses += 1
		decision.step = step; decision.issued = false
		if int(decision.guess) >= 0:
			if cache.has(int(decision.guess)/4): decision.issue_reason = "already_cached"
			elif not state.job.is_empty(): decision.issue_reason = "bus_busy"
			else: decision.issued = true; decision.issue_reason = "issued"; _start_job(trace,state,int(decision.guess),true,step)
		trace.metrics.decisions.append(decision.duplicate(true))
		_event(trace,&"prediction",int(state.clock),0,int(decision.guess),step,decision)
		_event(trace,&"compute",int(state.clock),int(spec.compute_gap),address,step,{"value":value})
		state.clock += int(spec.compute_gap); trace.metrics.compute_cycles += int(spec.compute_gap)
		_finish_job(trace,state,cache,int(state.clock),step)
	var drain: int = 0 if state.job.is_empty() else maxi(0,int(state.job.finish)-int(state.clock))
	if drain > 0:
		_event(trace,&"drain",int(state.clock),drain,-1,addresses.size()+1)
		state.clock += drain; trace.metrics.drain_cycles = drain; _finish_job(trace,state,cache,int(state.clock),addresses.size()+1)
	trace.metrics.total_cycles = int(state.clock)
	trace.metrics.useful_prediction_bytes = state.used.size()*LINE_BYTES
	trace.metrics.wasted_prediction_bytes = trace.metrics.prediction_bytes-trace.metrics.useful_prediction_bytes
	trace.passed = trace.result_value == trace.expected_value
	return trace
