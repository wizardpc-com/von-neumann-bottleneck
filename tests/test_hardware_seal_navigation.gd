extends SceneTree
## Known-reference fixture exercises real official verification and timed sealing.
## Signals below exercise UI callbacks, not native pointer acceptance.
const Component = preload("res://src/circuit/logic_component.gd")
const Circuit = preload("res://src/circuit/logic_circuit.gd")
const Reusable = preload("res://src/circuit/reusable_component.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)

func prerequisite_source() -> LogicCircuit:
	# Same prerequisite provenance fixture as test_hardware_prologue_ui.
	# HalfAdder's legacy entry has no catalog reference_circuit implementation.
	var circuit := Circuit.new()
	circuit.add_component(Component.new(&"SOURCE",Component.KIND_INPUT,"SOURCE",&"A",true))
	circuit.add_component(Component.new(&"PROBE",Component.KIND_OUTPUT,"PROBE",&"SUM",true))
	circuit.connect_ports(&"SOURCE",0,&"PROBE",0)
	return circuit

func abort_fixture() -> void:
	print("FAIL: test_hardware_seal_navigation fixture ",checks," checks, ",failures," failures")
	quit(1)

func run() -> void:
	root.get_node("GameMode").set_mode(&"game")
	root.get_node("TaskNavigation").from_tree = false
	var main: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(main)
	for frame: int in 4: await process_frame
	# Only the prerequisite is supplied. FullAdder must earn its own complete verdict.
	main.player_content.mark_completed(&"tutorial")
	var prerequisite: LogicCircuit = prerequisite_source()
	main.player_content.install_reusable(&"half_adder",Reusable.new(&"HalfAdder",Component.KIND_HALF_ADDER,&"half_adder",prerequisite),main.level_catalog)
	check(main.component_library.has(&"HalfAdder") and main.level_catalog.is_unlocked(&"full_adder",main.completed_levels),"Working prerequisite fixture unlocks FullAdder")
	if failures > 0: abort_fixture(); return
	main._start_campaign_level(&"full_adder",false)
	await process_frame
	check(main.current_level_id == &"full_adder" and not main.component_library.has(&"FullAdder"),"FullAdder opens without an earned reusable reward")
	check(not main.current_level_definition.get("reference_wires",[]).is_empty(),"FullAdder startup supplies the official topology fixture")
	if failures > 0: abort_fixture(); return
	check(main._create_named_workbench("Alternate"),"Create a genuine alternate board before sealing")
	check(main._switch_workbench("default"),"Return to the source board before official verification")
	if failures > 0: abort_fixture(); return
	for wire: Dictionary in main.current_level_definition.reference_wires:
		main._on_connection_request(wire.from,int(wire.get("from_port",0)),wire.to,int(wire.get("to_port",0)))
	main._run_official()
	var frames: int = 0
	while main.official_sequence_active and frames < 128:
		if main.playback_running: main._finish_playback()
		await process_frame; frames += 1
	check(not main.official_sequence_active and main.official_passed,"Actual FullAdder official cases earn the aggregate pass")
	if failures > 0: abort_fixture(); return
	var source_signature: String = main._circuit_from_graph().canonical_signature()
	check(main.passing_topology_signature == source_signature,"Official verdict binds to the displayed source topology")
	main._show_level_completion(&"full_adder")
	main.level_completion_overlay.primary_action_button.pressed.emit()
	check(main.sealing and not main.level_completion_overlay.visible,"Real primary Seal begins timed encapsulation and exposes the workbench")
	if failures > 0: abort_fixture(); return
	var graph_id: int = main.graph.get_instance_id()
	var pending = main.pending_sealed_circuit
	var definition: Dictionary = main.current_level_definition.duplicate(true)
	var boards: Dictionary = main.workbench_store.manifest_snapshot()
	# These are the toolbar/Mission/menu callbacks that previously replaced the board.
	var map_callback_found: bool = false
	for button: Node in main.editor_toolbar.find_children("*","Button",true,false):
		if button is Button and button.text == main._t(&"hardware.toolbar.level_map"):
			map_callback_found = true
			button.pressed.emit()
	check(map_callback_found,"Exercise the actual toolbar map callback during sealing")
	main._open_campaign_map()
	main.hint_button.pressed.emit()
	main._show_new_workbench_dialog()
	check(not main.workbench_name_dialog.visible,"New-board dialog cannot interrupt pending encapsulation")
	check(not main._create_named_workbench("Interrupted"),"Named-board creation refuses to replace the verified pending source")
	check(not main._switch_workbench("Alternate"),"Named-board switching refuses to replace the verified pending source")
	main._start_campaign_level(&"tutorial",false)
	main._start_prologue_level(&"full_adder",false)
	main._return_to_prototype_hub()
	check(main.is_inside_tree() and main.current_level_id == &"full_adder" and main.current_phase == &"prologue" and not main.hint_mode,"Navigation attempts retain the source scene and editable domain during sealing")
	check(main.graph.get_instance_id() == graph_id and main.current_level_definition == definition and main.pending_sealed_circuit == pending and main.sealing_level_id == &"full_adder","Navigation attempts preserve graph identity, definition and the verified pending snapshot")
	check(main.workbench_store.manifest_snapshot() == boards and main.active_workbench_name == "default","Navigation attempts preserve named-board contents and selection")
	check(main.status_label.text == main._t(&"hardware.status.sealing"),"Blocked navigation presents the existing sealing status")
	var deadline: int = Time.get_ticks_msec()+5000
	while main.sealing and Time.get_ticks_msec() < deadline: await process_frame
	check(not main.sealing and main.current_phase == &"prologue_complete","The real presentation timer finishes encapsulation after blocked navigation")
	check(main.component_library.has(&"FullAdder") and main.completed_levels.get(&"full_adder",false),"The verified FullAdder reward is installed and earned normally")
	if not main.component_library.has(&"FullAdder"): abort_fixture(); return
	if main.component_library.has(&"FullAdder"):
		check(main.component_library[&"FullAdder"].source_signature == source_signature,"Installed reward retains the exact officially verified source")
	check(not main.component_library.has(&""),"No empty reward is introduced")
	main._dismiss_level_completion(); main._open_campaign_map()
	check(main.current_phase == &"campaign","Map navigation becomes available after encapsulation finishes")
	main._start_campaign_level(&"full_adder",false)
	check(main._switch_workbench("Alternate"),"Named-board switching becomes available after encapsulation")
	check(main._create_named_workbench("After sealing"),"Named-board creation becomes available after encapsulation")
	main.hint_button.pressed.emit()
	check(main.hint_mode and main.current_phase == &"hint","Hint becomes available after encapsulation")
	main._exit_hint_workbench()
	check(not main.hint_mode and main.component_library[&"FullAdder"].source_signature == source_signature,"Leaving Hint preserves the earned verified component")
	main.queue_free(); await process_frame
	print("PASS: test_hardware_seal_navigation " if failures == 0 else "FAIL: test_hardware_seal_navigation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
