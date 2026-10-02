extends SceneTree
const M = preload("res://experiments/intelligent_workload/state_model.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func independent(bits: int, weight_bits: int) -> Dictionary:
	# Separate recurrence/rounding loop: does not use Model.update/quantize/reference.
	var states: Array = []; var scores: Array[float] = []; var weights: Array[float] = []
	for w: float in [0.83, -0.41, 0.17, 0.06, -0.29, 0.71, -0.13, 0.37]:
		var grid: int = (1 << (weight_bits - 1)) - 1 if weight_bits < 32 else 0
		weights.append(roundf(w * grid) / grid if grid > 0 else w)
	for stream: int in 4:
		var state: Array[float] = []
		var grid: int = (1 << (bits - 1)) - 1 if bits < 32 else 0
		for j: int in 8:
			var value: float = float((stream * 5 + j * 3) % 13 - 6) / 12.0
			state.append(roundf(value * grid) / grid if grid > 0 else value)
		for step: int in 6:
			var score: float = 0.0
			for j: int in 8:
				var x: float = float(((stream + 2) * (j * 7 + 5) + step * (j + 3) * 11) % 31 - 15) / 15.0
				var value: float = 0.65 * state[j] + 0.35 * x
				state[j] = roundf(value * grid) / grid if grid > 0 else value
				score += weights[j] * state[j]
			scores.append(score)
		states.append(state)
	return {"states": states, "outputs": scores}

func audit(trace: RefCounted, config: Dictionary) -> void:
	var time: int = 0; var bytes: int = 0; var reads: int = 0; var writes: int = 0
	var final_writes: int = 0; var last_steps: Array[int] = [-1, -1, -1, -1]
	var simulated_store: Array = []; var resident: Dictionary = {}; var lru: Array[int] = []
	var had_flush: bool = false
	for event: RefCounted in trace.events:
		check(event.cycle == time and event.duration >= 0, "Sequential event time")
		time += event.duration
		var d: Dictionary = event.details
		if event.kind in [&"batch_read", &"state_read", &"state_write", &"output"]:
			bytes += int(d.bytes)
			check(event.duration == ceili(float(d.bytes) / 4.0), "Physical transfer cost")
		if event.kind == &"initial_store": simulated_store = d.states.duplicate(true)
		if event.kind == &"state_read":
			check(d.state == simulated_store[d.stream], "Reload receives latest persisted context")
			resident[d.stream] = d.state.duplicate(); reads += 1
		if event.kind == &"eviction":
			check(lru[0] == d.stream, "Automatic least-recently-used victim")
			check(simulated_store[d.stream] == resident[d.stream], "Dirty context written before eviction")
			lru.pop_front(); resident.erase(d.stream)
		if event.kind == &"state_write":
			check(resident[d.stream] == d.state, "Backing write contains current live context")
			simulated_store[d.stream] = d.state.duplicate(); writes += 1
			if d.reason == "flush": final_writes += 1
		if event.kind == &"compute":
			check(d.step == last_steps[d.stream] + 1, "Every stream preserves request order")
			last_steps[d.stream] = d.step
			check(d.before == resident[d.stream], "Recurrence consumes prior context")
			resident[d.stream] = d.after.duplicate(); lru.erase(d.stream); lru.append(d.stream)
			check(resident.size() <= config.slots and d.resident_lru == lru, "Finite slots and deterministic LRU evidence")
		if event.kind == &"flush_begin": had_flush = true
	check(had_flush and final_writes == resident.size(), "Explicit final flush covers every remaining dirty context")
	check(simulated_store == trace.metrics.final_states, "Final state is actually persisted, not discarded")
	check(time == trace.metrics.total_cycles and bytes == trace.metrics.traffic_bytes, "Event costs and bytes sum exactly")
	check(time == trace.metrics.request_cycles + trace.metrics.transfer_cycles + trace.metrics.compute_cycles + trace.metrics.commit_cycles, "No hidden speed reward")
	check(reads == trace.metrics.state_reads and writes == trace.metrics.state_writes, "State traffic metrics count actual events")
	check(trace.metrics.compute_cycles == 24 * 24, "Precision never changes operation throughput")

func run() -> void:
	var exact: Dictionary = independent(32, 32)
	check(M.reference_result() == {"outputs": exact.outputs, "states": exact.states}, "Independent full-precision recurrence reference")
	var after: Array[float] = M.update(M.initial(0), M.input(0, 0), 32)
	check(is_equal_approx(after[0], -0.325 - 0.35 / 3.0), "Hand calculation: A0 first cell uses nonzero initial state")
	for state_bits: int in [32, 8, 4, 2]:
		for weight_bits: int in [32, 8, 4, 2]:
			var expected: Dictionary = independent(state_bits, weight_bits)
			for order: String in ["round_robin", "paired", "grouped"]:
				for slots: int in [1, 2, 4]:
					for batch: int in [1, 2, 4]:
						for reuse: bool in [true, false]:
							var c: Dictionary = {"state_bits": state_bits, "weight_bits": weight_bits, "order": order, "slots": slots, "batch": batch, "reuse": reuse}
							var trace: RefCounted = M.run(c)
							if trace.metrics.reserved_bytes > 256:
								check(not trace.passed and trace.events.is_empty() and trace.metrics.error == "scratch_limit", "Reject oversized scratch before running"); continue
							check(trace.passed, "Legal configuration executes")
							check(trace.metrics.outputs == expected.outputs and trace.metrics.final_states == expected.states, "Actual precision recurrence independent of schedule/residency")
							var max_error: float = 0.0; var mae: float = 0.0; var agreement: int = 0
							for n: int in 24:
								max_error = maxf(max_error, absf(expected.outputs[n] - exact.outputs[n])); mae += absf(expected.outputs[n] - exact.outputs[n]) / 24
								agreement += int((expected.outputs[n] >= 0) == (exact.outputs[n] >= 0))
							check(is_equal_approx(max_error, trace.metrics.max_error) and is_equal_approx(mae, trace.metrics.mae) and agreement == trace.metrics.agreement, "Quality recomputed from actual values")
							var state_error: float = 0.0
							for stream: int in 4:
								for j: int in 8: state_error = maxf(state_error, absf(expected.states[stream][j] - exact.states[stream][j]))
							check(is_equal_approx(state_error, trace.metrics.max_state_error), "Final state error independently recomputed")
							if weight_bits == 32 and batch == 1 and reuse:
								audit(trace, c)
								check(trace.canonical_signature() == M.run(c).canonical_signature(), "Fresh deterministic trace")
	var baseline: RefCounted = M.run({"slots": 1})
	var grouped: RefCounted = M.run({"order": "grouped"})
	var paired: RefCounted = M.run({"order": "paired", "slots": 2, "batch": 2})
	var resident: RefCounted = M.run({"slots": 4})
	var batched: RefCounted = M.run({"order": "grouped", "batch": 2})
	check(baseline.metrics.state_reads == 24 and baseline.metrics.state_writes == 24, "Round-robin one-slot working set thrashes")
	check(grouped.metrics.state_reads == 4 and grouped.metrics.state_writes == 4, "Grouping genuinely saves context transfers")
	check(grouped.metrics.traffic_bytes < baseline.metrics.traffic_bytes and grouped.metrics.all_streams_first_cycle > resident.metrics.all_streams_first_cycle, "Low-traffic grouped order is a poor prompt-response counterexample")
	check(M.accepted(grouped.metrics) and M.accepted(paired.metrics) and M.accepted(resident.metrics, true), "Distinct exact accepted alternatives")
	check(not M.accepted(grouped.metrics, true), "Grouped throughput winner misses public prompt contract")
	check(batched.metrics.total_cycles < grouped.metrics.total_cycles and batched.metrics.first_result_cycle > grouped.metrics.first_result_cycle and batched.metrics.peak_bytes > grouped.metrics.peak_bytes, "Batch throughput/latency/memory tradeoff")
	check(M.run({"slots": 4, "state_bits": 8}).metrics.traffic_bytes < resident.metrics.traffic_bytes and M.run({"state_bits": 2}).metrics.max_state_error > 0.02, "Actual quantized memory/error tradeoff")
	for c: Dictionary in [{"slots": 0}, {"batch": 3}, {"state_bits": 3}, {"weight_bits": 16}, {"order": "reverse"}, {"slots": 1.5}, {"state_bits": "8"}, {"reuse": "false"}]: check(not M.run(c).passed, "Malformed configuration rejected")
	for name: String in ["baseline", "grouped", "paired", "resident", "batched"]:
		var traces: Dictionary = {"baseline": baseline, "grouped": grouped, "paired": paired, "resident": resident, "batched": batched}
		print("STATE ", name, " ", traces[name].metrics)
	var before: String = JSON.stringify(root.get_node("LocalityChapter").completed_levels())
	root.content_scale_size = Vector2i(1280, 720); root.size = Vector2i(1280, 720)
	var lab: Control = load("res://experiments/intelligent_workload/state_lab.tscn").instantiate(); root.add_child(lab); await process_frame
	lab.run_current(); var evidence: String = JSON.stringify(lab.history[0]); var signature: String = lab.active_trace.canonical_signature()
	lab.order.select(2); lab.invalidate(); check(JSON.stringify(lab.history[0]) == evidence and lab.active_trace.canonical_signature() == signature, "Draft changes preserve copied comparison evidence")
	lab.run_current(); lab.active_trace.metrics.outputs[0] = 12345; check(JSON.stringify(lab.history[0]) == evidence and lab.history[1].metrics.outputs[0] != 12345, "History never aliases mutable model evidence")
	await process_frame; await process_frame
	check(lab.tree.get_global_rect().end.y <= 720 and lab.detail.get_global_rect().end.y <= 720, "Chinese 1280x720 evidence stays inside viewport")
	lab.english = true; lab.build(lab.current_config()); check(lab.language_button.text == "中文 / EN" and lab.history.size() == 2 and lab.run_button.text == "Run and record", "Bilingual rebuild preserves evidence and controls")
	await process_frame; await process_frame
	check(lab.tree.get_global_rect().end.y <= 720 and lab.detail.get_global_rect().end.y <= 720, "English 1280x720 evidence stays inside viewport")
	lab.show_public_data(); check(lab.public_window.visible, "Public inputs and reference inspectable before/after run")
	check(before == JSON.stringify(root.get_node("LocalityChapter").completed_levels()), "State experiment cannot award campaign progress")
	lab.queue_free(); await process_frame
	print("PASS: persistent context, explicit writes/flush, precision, schedules and isolated UI (", checks, ")" if failures.is_empty() else "FAIL: persistent context")
	quit(0 if failures.is_empty() else 1)
