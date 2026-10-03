extends SceneTree
const M = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func grouped(slots: int = 1, count: int = 1) -> Dictionary:
	var plan: Dictionary = M.initial_plan(); plan.slots = slots; plan.groups = []
	for stream: int in 4:
		for start: int in range(0, 6, count):
			var group: Array = []
			for step: int in range(start, mini(6, start + count)): group.append(stream * 6 + step)
			plan.groups.append(group)
	return plan

func independent(representations: Array) -> Dictionary:
	var states: Array = []; var outputs: Array = []
	for stream: int in 4:
		var q: bool = str(representations[stream]).ends_with("8"); var state: Array[float] = []
		for j: int in 8:
			var k: int = 0 if stream < 2 else j
			var value: float = float((stream * 5 + k * 3) % 13 - 6) / 12.0
			state.append(roundf(value * 127.0) / 127.0 if q else value)
		for step: int in 6:
			var score: float = 0.0
			for j: int in 8:
				var k: int = 0 if stream < 2 else j
				var x: float = float(((stream + 2) * (k * 7 + 5) + step * (k + 3) * 11) % 31 - 15) / 15.0
				var value: float = 0.65 * state[j] + 0.35 * x
				state[j] = roundf(value * 127.0) / 127.0 if q else value
				score += [0.83, -0.41, 0.17, 0.06, -0.29, 0.71, -0.13, 0.37][j] * state[j]
			outputs.append(score)
		states.append(state.duplicate())
	return {"states": states, "outputs": outputs}

func audit(trace: RefCounted) -> void:
	var time: int = 0; var traffic: int = 0; var measured_peak: int = 0; var store: Array = []; var live: Dictionary = {}; var lru: Array = []; var flush: int = 0
	for event: RefCounted in trace.events:
		check(event.cycle == time and event.duration >= 0, "Contiguous deterministic event times"); time += event.duration
		var d: Dictionary = event.details
		if event.kind == &"initial_store": store = d.records.duplicate(true)
		if event.kind in [&"weight_read", &"group_read", &"state_read", &"state_write", &"output"]:
			traffic += d.bytes; check(event.duration == ceili(float(d.bytes) / 4.0), "Actual transferred byte cost")
		if event.kind == &"state_read": check(d.encoded == M.record(store[d.stream]), "Reads latest physical persisted bytes")
		if event.kind == &"decode":
			live[d.stream] = d.state.duplicate()
			measured_peak = maxi(measured_peak, trace.metrics.workspace_bytes + live.size() * 64 + store[d.stream].size() + 2)
		if event.kind == &"encode":
			measured_peak = maxi(measured_peak, trace.metrics.workspace_bytes + live.size() * 64 + d.encoded.size())
		if event.kind == &"state_write":
			check(d.state == live[d.stream], "Dirtywrite contains current numerical state")
			check(d.encoded[0] + 256 * d.encoded[1] == d.encoded.size() - 2, "Actual two-byte length directory")
			store[d.stream] = PackedByteArray(d.encoded.slice(2))
			check(M.unpack(store[d.stream], d.representation) == live[d.stream], "Every persisted codec write roundtrips")
			if d.reason == "flush": flush += 1
		if event.kind == &"eviction":
			check(lru[0] == d.stream and M.unpack(store[d.stream], trace.metrics.plan.representations[d.stream]) == live[d.stream], "LRU writes before eviction")
			lru.pop_front(); live.erase(d.stream)
		if event.kind == &"compute":
			check(d.before == live[d.stream], "Next recurrence consumes real resident state")
			live[d.stream] = d.after.duplicate(); lru.erase(d.stream); lru.append(d.stream)
			check(lru == d.lru and live.size() <= trace.metrics.plan.slots, "Actual finite LRU residency")
	check(flush == live.size() and flush == trace.metrics.flush_writes, "Finalflush covers all remaining dirty states")
	check(time == trace.metrics.total_cycles and traffic == trace.metrics.traffic_bytes, "Event resource sums")
	check(time == trace.metrics.request_cycles + trace.metrics.transfer_cycles + trace.metrics.compute_cycles + trace.metrics.commit_cycles + trace.metrics.codec_cycles, "No unexplained compute speed multiplier")
	check(measured_peak == trace.metrics.peak_bytes, "Peak independently rebuilt from actual resident and encoding buffers")
	check(trace.metrics.compute_cycles == 576 and trace.metrics.peak_bytes <= 512, "Same compute throughput and hard finite scratch")
	for stream: int in 4: check(M.unpack(store[stream], trace.metrics.plan.representations[stream]) == trace.metrics.final_states[stream], "Finalstates read from persisted bytes")

func run() -> void:
	check(M.reference_result() == independent(["raw64", "raw64", "raw64", "raw64"]), "Independent exact recurrence reference")
	for representation: String in M.REPRESENTATIONS:
		for stream: int in 4:
			var values: Array = M.initial(stream)
			for j: int in 8: values[j] = M.rounded(values[j], representation)
			check(M.unpack(M.pack(values, representation), representation) == values, "Actual bytes roundtrip " + representation)
	var baseline: Dictionary = M.initial_plan(); var resident: Dictionary = baseline.duplicate(true); resident.slots = 4
	var mixed: Dictionary = resident.duplicate(true); mixed.representations = ["rle8", "rle8", "raw64", "raw64"]
	var all8: Dictionary = resident.duplicate(true); all8.representations = ["raw8", "raw8", "raw8", "raw8"]
	var lossless: Dictionary = resident.duplicate(true); lossless.representations = ["rle64", "rle64", "raw64", "raw64"]
	var rle64: Dictionary = resident.duplicate(true); rle64.representations = ["rle64", "rle64", "rle64", "rle64"]
	var rle8: Dictionary = all8.duplicate(true); rle8.representations = ["rle8", "rle8", "rle8", "rle8"]
	var cases: Dictionary = {"baseline": baseline, "grouped": grouped(), "grouped2": grouped(1, 2), "resident": resident, "lossless": lossless, "rle64": rle64, "mixed": mixed, "all8": all8, "rle8": rle8}
	for name: String in cases:
		var plan: Dictionary = cases[name]; var trace: RefCounted = M.run(plan)
		check(trace.passed, "Valid constructed plan executes " + name)
		check(trace.metrics.outputs == independent(plan.representations).outputs and trace.metrics.final_states == independent(plan.representations).states, "Independent represented recurrence " + name)
		var full: Dictionary = independent(["raw64", "raw64", "raw64", "raw64"])
		var max_score: float = 0.0; var max_state: float = 0.0
		for id: int in 24: max_score = maxf(max_score, absf(trace.metrics.outputs[id] - full.outputs[id]))
		for stream: int in 4:
			for j: int in 8: max_state = maxf(max_state, absf(trace.metrics.final_states[stream][j] - full.states[stream][j]))
		check(max_score == trace.metrics.max_error and max_state == trace.metrics.max_state_error, "Quality metrics independently recomputed")
		audit(trace); check(trace.canonical_signature() == M.run(plan).canonical_signature(), "Repeat run trace determinism")
		print("SERVICE ", name, " ", {"cycles": trace.metrics.total_cycles, "traffic": trace.metrics.traffic_bytes, "state_bytes": trace.metrics.state_read_bytes + trace.metrics.state_write_bytes, "firsts": trace.metrics.first_stream_cycles, "peak": trace.metrics.peak_bytes, "error": trace.metrics.max_error, "state_error": trace.metrics.max_state_error})
	for pattern: int in 256:
		var digits: int = pattern; var representations: Array = []
		for stream: int in 4:
			representations.append(M.REPRESENTATIONS[digits % 4]); digits = digits / 4
		var expected: Dictionary = independent(representations)
		for capacity: int in [1, 2, 4]:
			var variant: Dictionary = baseline.duplicate(true); variant.slots = capacity; variant.representations = representations.duplicate()
			var execution: RefCounted = M.run(variant)
			check(execution.passed and execution.metrics.outputs == expected.outputs and execution.metrics.final_states == expected.states, "All256 format combinations preserve represented recurrence across residency")
	var bad: Array[Dictionary] = []
	var plan: Dictionary = M.move(baseline, 4, -4); bad.append(plan)
	plan = baseline.duplicate(true); plan.groups[0][0] = 1; bad.append(plan)
	plan = baseline.duplicate(true); plan.groups.pop_back(); bad.append(plan)
	plan = M.merge(M.merge(M.merge(resident, 0), 0), 0); bad.append(plan)
	plan = baseline.duplicate(true); plan.slots = 1.5; bad.append(plan)
	for invalid: Dictionary in bad:
		var rejected: RefCounted = M.run(invalid); check(not rejected.passed and rejected.events.is_empty(), "Invalid dependency/schema/scratch rejected before events")
	check(M.split(M.merge(baseline, 0), 0, 1) == baseline, "Player merge/split reversible")
	var exact_group: RefCounted = M.run(grouped()); var exact_resident: RefCounted = M.run(resident)
	check(M.accepted(exact_group.metrics, 0) and M.accepted(M.run(grouped(1, 2)).metrics, 0) and not M.accepted(exact_resident.metrics, 0), "Different constructed throughput plans accepted")
	check(not M.accepted(exact_group.metrics, 1) and M.accepted(exact_resident.metrics, 1), "Grouping traffic winner is prompt response counterexample")
	check(M.accepted(M.run(mixed).metrics, 2) and M.accepted(M.run(all8).metrics, 2), "Mixed and uniform precision alternatives accepted")
	check(M.run(rle8).metrics.traffic_bytes > M.run(all8).metrics.traffic_bytes and M.run(rle8).metrics.total_cycles > M.run(all8).metrics.total_cycles, "Genuine RLE expansion and conversion overhead")
	var repeated: Array = []; repeated.resize(8); repeated.fill(0.25)
	check(M.pack(repeated, "rle8").size() < M.pack(repeated, "raw8").size(), "Actual repeated signedbyte compression benefit")
	check(M.accepted(M.run(lossless).metrics, 2), "Lossless mixed constructed alternative meets final task")
	check(not M.accepted(M.run(lossless).metrics, -1) and not M.accepted(M.run(lossless).metrics, 3), "Unknown task rejected")
	var zeroes: Array = [0.0, -0.0, 0.0, -0.0, 0.0, -0.0, 0.0, -0.0]
	check(M.pack(M.unpack(M.pack(zeroes, "rle64"), "rle64"), "raw64") == M.pack(zeroes, "raw64"), "WordRLE preserves signedzero actual IEEE bytes")
	check(not M.accepted(M.run(all8).metrics, 1), "Real Q8 errors reject exact quality contract")
	check(M.run(all8).metrics.max_error > 0.0 and M.run(all8).metrics.max_state_error > 0.0, "Actual persistent precision errors are nonzero")
	var campaign_before: String = JSON.stringify(root.get_node("LocalityChapter").completed_levels())
	root.content_scale_size = Vector2i(1280, 720); root.size = Vector2i(1280, 720)
	var lab: Control = load("res://experiments/service_plan/lab.tscn").instantiate(); root.add_child(lab)
	await process_frame; await process_frame
	check(lab.public_observation().measured.is_empty(), "Public observation never runs hidden candidate simulations")
	lab.run_current(); var record_before: String = JSON.stringify(lab.history[0])
	check(lab.status.text.contains("784") and lab.status.text.contains("2568"),"Baseline failure reports exact cycle and state-traffic excess")
	check(lab.measured_feedback(M.run(resident).metrics,0).contains("108"),"Cache residency reports its actual peak budget excess")
	check(lab.measured_feedback(M.run(all8).metrics,1).contains("误差"),"Exact-quality failure remains visible for quantized storage")
	check(lab.measured_feedback(M.run(lossless).metrics,2).contains("约束成立"),"Final-contract feedback makes no nonexistent next-task promise")
	var payload: Dictionary = lab.group_list.drag_payload(4)
	var target_position: Vector2 = lab.group_list.get_item_rect(1).get_center()
	check(lab.group_list._can_drop_data(target_position,payload),"Own group can be dragged to another visible row")
	lab.group_list._drop_data(target_position,payload)
	check(lab.plan.groups[1] == [1] and lab.selected_group == 1,"Dragging moves the chosen whole group to the target index")
	check(JSON.stringify(lab.history[0]) == record_before,"Group dragging preserves recorded evidence")
	check(not lab.group_list._can_drop_data(target_position,payload),"Stale source label is refused after reorder")
	check(not lab.group_list._can_drop_data(target_position,{"service_group_source":0}),"Foreign drag payload is refused")
	lab.undo(); check(lab.plan == baseline,"Dragged edit can be undone")
	lab.edit(M.merge(lab.plan, 0), 0); check(JSON.stringify(lab.history[0]) == record_before, "Editing group leaves measured history immutable")
	lab.undo(); check(lab.plan == baseline, "UI undo restores constructed plan")
	lab.redo(); check(lab.plan.groups[0].size() == 2, "UI redo restores merge")
	lab.run_current(); lab.active_trace.metrics.outputs[0] = 9876
	check(JSON.stringify(lab.history[0]) == record_before and lab.history[1].metrics.outputs[0] != 9876, "History deep copies mutable Trace")
	lab.selected_history = 0; lab.restore_history(); check(lab.plan == baseline, "Restore measured plan as new editable draft")
	for locale: bool in [false, true]:
		lab.english = locale; lab.build(); await process_frame; await process_frame
		for node: Control in [lab.group_list, lab.tree, lab.detail, lab.run_button, lab.format_buttons[3]]:
			check(node.get_global_rect().position.x >= 0 and node.get_global_rect().end.x <= 1280 and node.get_global_rect().end.y <= 720, "Bilingual1280x720 evidence and controls stay inside viewport")
		lab.hint_open = true; lab.refresh_mission(); await process_frame; await process_frame
		check(lab.detail.get_global_rect().end.y <= 720, "Hint remains inside1280x720 viewport")
	lab.show_public_data(); check(lab.detail.text.contains("streams"), "Actual initial states and inputs inspectable")
	lab.plan = grouped(); lab.task = 0; lab.run_current(); check(lab.unlocked == 1, "Actual accepted Trace unlocks next experimental contract")
	check(campaign_before == JSON.stringify(root.get_node("LocalityChapter").completed_levels()), "No formal campaign authority")
	for repeat: int in 8: lab.run_current()
	await process_frame; await process_frame
	check(lab.history_list.get_v_scroll_bar().value > 0, "Latest measured history scrolls into view")
	lab.queue_free(); await process_frame
	print("PASS: service plan (", checks, ")" if failures.is_empty() else "FAIL: service plan")
	quit(0 if failures.is_empty() else 1)
