extends SceneTree
const Replay = preload("res://experiments/service_plan/state_replay.gd")
const Model = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func dictionaries(trace: RefCounted) -> Array:
	var events: Array = []
	for event: RefCounted in trace.events: events.append(event.to_dictionary())
	return events

func present_count(cells: Array) -> int:
	var count: int = 0
	for cell: Dictionary in cells:
		if cell.present: count += 1
	return count

func verify_plan(plan: Dictionary) -> void:
	var trace: RefCounted = Model.run(plan)
	check(trace.passed,"Replay fixture uses a valid measured plan")
	var signature: String = trace.canonical_signature()
	var events: Array = dictionaries(trace)
	var originals: Array = events.duplicate(true)
	var frames: Array[Dictionary] = Replay.build(events)
	check(frames.size() == events.size(),"Every actual event has one source-indexed prefix frame")
	if frames.size() != events.size(): return
	var reads: int = 0
	var writes: int = 0
	var outputs: Array[Dictionary] = []
	var saw_hit: bool = false
	var saw_eviction_write: bool = false
	var saw_flush: bool = false
	var restored_update: bool = false
	var expected_last: Array[int] = [-1,-1,-1,-1]
	for index: int in events.size():
		var event: Dictionary = events[index]
		var d: Dictionary = event.details
		var frame: Dictionary = frames[index]
		var stream: int = int(d.get("stream",-1))
		check(frame.source_index == index and frame.event == event,"Frame retains exact source identity and event")
		check(frame.residents.size() == 4 and frame.backing.size() == 4,"Every prefix has four stream cells")
		if event.kind == "initial_store":
			check(present_count(frame.residents) == 0,"Initial encoded store has no resident states")
			for id: int in 4:
				check(frame.backing[id].state.is_empty() and frame.backing[id].last_request == -1,"Initial payload never invents decoded state or future request")
				check(frame.backing[id].encoded == d.records[id] and frame.backing[id].bytes == d.records[id].size()+2,"Initial archive counts real payload plus directory")
		if event.kind == "state_read":
			reads += int(d.bytes)
			check(frame.backing[stream].encoded == PackedByteArray(d.encoded).slice(2),"Read preserves recorded backing payload without decoding")
		if event.kind == "decode":
			check(frame.residents[stream].state == d.state and frame.residents[stream].bytes == 64 and frame.residents[stream].present,"Decoded state is recorded numeric evidence with64B resident capacity")
			check(frame.residents[stream].last_request == expected_last[stream],"Reload preserves latest known backed request identity")
			if expected_last[stream] >= 0:
				restored_update = true
				check(frame.residents[stream].state == frame.backing[stream].state,"Reloaded state matches actual preceding write, not initial values")
		if event.kind == "state_hit":
			saw_hit = true
			check(frame.residents == frames[index-1].residents and frame.backing == frames[index-1].backing,"Reuse keeps resident values and backing unchanged")
		if event.kind == "compute":
			check(frame.residents[stream].state == d.after and frame.residents[stream].dirty and frame.residents[stream].last_request == d.request_id,"Compute changes only recorded resident state and request")
			check(frame.backing == frames[index-1].backing,"Unsaved computation never changes backing")
		if event.kind == "state_write":
			writes += int(d.bytes)
			expected_last[stream] = frames[index-1].residents[stream].last_request
			check(frame.backing[stream].state == d.state and frame.backing[stream].bytes == d.bytes and frame.backing[stream].encoded == PackedByteArray(d.encoded).slice(2),"Write installs actual numeric state and encoded payload")
			check(frame.residents[stream].present and not frame.residents[stream].dirty,"Write finishes while state still occupies a resident slot")
			if d.reason == "eviction": saw_eviction_write = true
			if d.reason == "flush": saw_flush = true
		if event.kind == "eviction":
			check(not frame.residents[stream].present and frame.residents[stream].state.is_empty() and frame.residents[stream].bytes == 0,"Only eviction releases resident storage")
			check(frame.backing == frames[index-1].backing,"Eviction retains completed backing write")
		if event.kind == "output":
			outputs.append({"request_id":d.request_id,"stream":d.stream,"score":d.score,"error":d.error})
		check(frame.responses == outputs,"Responses appear only in actual output order, never at compute/commit")
		check(frame.state_read_bytes == reads and frame.state_write_bytes == writes,"Prefix traffic counts actual state transfers only")
	var last: Dictionary = frames.back()
	var backing_bytes: int = 0
	for id: int in 4:
		backing_bytes += last.backing[id].bytes
		check(last.backing[id].state == trace.metrics.final_states[id],"Final store uses actual recorded final numeric state")
	check(backing_bytes == trace.metrics.final_backing_bytes,"Final archive space matches authoritative measurements")
	check(reads == trace.metrics.state_read_bytes and writes == trace.metrics.state_write_bytes,"Complete state traffic matches authoritative metrics")
	check(outputs.size() == 24 and saw_flush,"All24 responses and actual final flush remain visible")
	check(present_count(last.residents) == plan.slots,"Final flush does not fabricate eviction")
	if plan.slots == 1: check(saw_eviction_write and restored_update,"One-slot fixture exercises write-before-eviction and restored updates")
	if plan.slots == 4: check(saw_hit,"Four-slot fixture exercises resident reuse")
	var end: int = events.size()/2
	var prefix: Array[Dictionary] = Replay.build(events.slice(0,end))
	check(prefix.back() == frames[end-1],"A prefix projects identically without access to later events")
	check(events == originals and trace.canonical_signature() == signature,"Projection leaves source events and simulation signature untouched")
	check(JSON.stringify(frames) == JSON.stringify(Replay.build(events)),"Repeated projection is deterministic")
	# Mutate output copies to verify source/other frames remain independent.
	frames[0].backing[0].encoded[0] = (int(frames[0].backing[0].encoded[0])+1)%256
	frames[0].event.details.records[0][0] = (int(frames[0].event.details.records[0][0])+1)%256
	frames.back().responses[0].score = -999.0
	check(events == originals,"Frame payload/event/output mutation cannot alter source")
	check(frames[1].backing[0].encoded == originals[0].details.records[0],"Adjacent frames do not share backing payloads")
	check(prefix.back().responses[0].score != -999.0,"Independently built prefixes do not share response dictionaries")

func run() -> void:
	check(Replay.build([]).is_empty(),"Empty input claims no recorded frame")
	var one: Dictionary = Model.initial_plan()
	var four: Dictionary = Model.initial_plan(); four.slots = 4; four.representations = ["rle64","rle64","raw64","raw64"]
	var compact: Dictionary = Model.initial_plan(); compact.slots = 4; compact.representations = ["raw8","rle8","raw8","rle8"]
	for plan: Dictionary in [one,four,compact]: verify_plan(plan)
	var events: Array = dictionaries(Model.run(one))
	for malformed: Variant in [null,42,{"kind":"decode","details":[]},{"kind":"decode","details":{"stream":4,"state":[0,0,0,0,0,0,0,0]}},{"kind":"decode","details":{"stream":-1,"state":[0,0,0,0,0,0,0,0]}},{"kind":"output","details":{"stream":0,"request_id":24,"score":0.0,"error":0.0}},{"kind":"output","details":{"stream":1,"request_id":0,"score":0.0,"error":0.0}},{"kind":"decode","details":{"stream":0,"state":[NAN,0,0,0,0,0,0,0]}},{"kind":"decode","details":{"stream":0,"state":[]}},{"kind":"state_read","details":{"stream":0,"bytes":3,"encoded":[2,0,9]}},{"kind":"state_write","details":{"stream":0,"bytes":3,"encoded":[1,0,256],"state":[0,0,0,0,0,0,0,0]}},{"kind":"initial_store","details":{"records":[PackedByteArray([1])]}}]:
		var broken: Array = events.duplicate(true); broken.append(malformed)
		check(Replay.build(broken).is_empty(),"Malformed source refuses the whole projection without out-of-range access")
	var unknown: Array[Dictionary] = Replay.build([{"kind":"future_event","details":{}}])
	check(unknown.size() == 1 and unknown[0].responses.is_empty() and present_count(unknown[0].residents) == 0,"Unknown event is retained without invented state or response")
	print("PASS: test_service_state_replay " if failures == 0 else "FAIL: test_service_state_replay ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
