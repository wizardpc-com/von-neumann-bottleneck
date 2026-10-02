extends SceneTree
const Profile = preload("res://src/ui/trace_ambience_profile.gd")
const Player = preload("res://src/ui/trace_ambience_player.gd")
const Event = preload("res://src/simulation/simulation_event.gd")
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func check(value: bool, message: String) -> void:
	if not value: failures.append(message)
func _run() -> void:
	var profile = Profile.new()
	var events: Array = [Event.new(&"compute",0,8),Event.new(&"compute",2,4),Event.new(&"transfer",4,8),Event.new(&"compute",2,0)]
	profile.configure(events,&"overlap",12)
	check(profile.sample(12,12).is_equal_approx(Vector3(2.0/3,2.0/3,1.0/3)), "Union and actual intersection prevent double counting")
	check(profile.sample(0)==Vector3.ZERO and profile.sample(4).z==0, "No future or zero-duration event announces overlap")
	events[0].duration=1
	check(is_equal_approx(profile.sample(12,12).x,2.0/3), "Profile owns interval copies")
	var solution: Dictionary = Catalog.reference_solution("buffers")
	var report: Dictionary = Catalog.evaluate("buffers",solution.board,solution.program)
	check(report.passed, "Real double-buffer reference succeeds")
	var trace: SimulationTrace = report.runs[0]
	var signature: String = trace.canonical_signature()
	profile.configure(trace.events,&"overlap",trace.metrics.total_cycles)
	var density: Vector3 = profile.sample(trace.metrics.total_cycles,trace.metrics.total_cycles)
	check(is_equal_approx(density.z * trace.metrics.total_cycles,trace.metrics.overlap), "Overlap audio mapping agrees with authoritative metrics")
	var settings: Node = root.get_node("WindowMode")
	settings.set_ambience(true,0.3,false)
	var player = Player.new(); root.add_child(player)
	player.focused = true # Headless fixture explicitly simulates a focused window.
	player.configure(trace.events,&"overlap",trace.metrics.total_cycles)
	player.advance(12,true); player._process(1.0)
	check(player.envelope.length()>0 and player.voices.size()==3, "Three bounded voices respond to activity")
	player.advance(2,true)
	check(player.envelope==Vector3.ZERO, "Seeking backwards resets envelopes without replaying missed events")
	player.advance(12,false); player._process(3.0)
	check(player.target==Vector3.ZERO, "Paused playback fades to silence")
	settings.set_ambience(true,0.3,true)
	player.advance(12,true); player._process(1.0)
	player._lose_focus()
	check(player.envelope==Vector3.ZERO and not player.voices[0].playing, "Background silence is immediate")
	settings.set_ambience(false,0.3,false); player._process(1.0)
	check(not player.voices[1].playing, "Mute does not leave a running voice")
	check(trace.canonical_signature()==signature, "Play, seek, pause, reduced dynamics, focus and mute cannot change Trace or metrics")
	var bus: int = AudioServer.get_bus_index("Ambience")
	check(bus>=0 and AudioServer.is_bus_mute(bus), "Independent ambience bus follows settings")
	check(AudioServer.get_bus_index("Effects") != bus, "Effects volume remains independent")
	player.queue_free(); await process_frame
	await create_timer(0.1).timeout
	check(trace.canonical_signature()==signature, "Scene destruction preserves authoritative evidence")
	root.get_node("GameMode").set_mode(&"test")
	var system: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(system)
	for frame: int in 4: await process_frame
	system._start_level(&"cpu_speed")
	system.prediction_selector.select(1); system._lock_prediction(); system._run_official()
	var system_signature: String = system.current_trace.canonical_signature()
	var receipt_signature: String = system.latest_receipt.canonical_signature()
	system._process(0.1); system._toggle_pause(); system._process(0.1)
	check(system.trace_ambience != null and not system.trace_ambience.active, "System scene sends paused playback to ambience")
	system._play_trace(system.current_trace)
	check(system.current_trace.canonical_signature()==system_signature and system.latest_receipt.canonical_signature()==receipt_signature, "System playback retains authoritative Trace and receipt")
	var voices_count := 0
	for child: Node in system.get_children():
		if child.name == "TraceAmbience": voices_count += 1
	check(voices_count==1, "Replays reuse one scene-owned director")
	system._play_trace(null)
	check(not system.trace_ambience.active,"Clearing a trace stops sound safely")
	system.queue_free(); await process_frame
	var overlap: Control = load("res://src/overlap_chapter/overlap_chapter.tscn").instantiate()
	root.add_child(overlap)
	for frame: int in 4: await process_frame
	overlap._open_level("buffers")
	overlap.board=solution.board.duplicate(true); overlap.editor.text=solution.program
	overlap._run_official()
	check(overlap.trace_ambience != null, "Double-buffer scene installs ambience from its actual trace")
	var overlap_signature: String = overlap.trace.canonical_signature()
	overlap.playing=true; overlap.scrub.value=12; overlap._process(0.01)
	overlap.trace_stale=true; overlap._process(0.01)
	check(not overlap.trace_ambience.active and overlap.trace.canonical_signature()==overlap_signature, "Stale overlap results stop ambience without changing evidence")
	overlap.queue_free(); await process_frame
	settings.set_ambience(false,0.3,false)
	if failures.is_empty(): print("PASS: interval unions, overlap, independent audio lifecycle and immutable simulation")
	else:
		for failure: String in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
