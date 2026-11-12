extends SceneTree
## Controller regression: authored Test circuits, real history commands and
## simulator observations. Does not establish native input or campaign success.

var failures: Array[String] = []
var checks: int = 0
var bench: Control


func _init() -> void:
	call_deferred("run")


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func settle() -> void:
	for frame: int in range(8):
		await process_frame


func capture_frame(label: String) -> void:
	if "--history-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		return
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await settle()
	RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame.get_size() == Vector2i(1280, 720), "Capture has the requested raw dimensions")
	var folder: String = "res://.godot/history-context/"
	DirAccess.make_dir_recursive_absolute(folder)
	check(frame.save_png(folder + root.get_node("Localization").current_locale() + "-" + label + ".png") == OK,
		"Capture writes successfully")


func connect_wire(wire: Dictionary) -> void:
	bench._on_connection_request(wire["from"], int(wire.get("from_port", 0)),
		wire["to"], int(wire.get("to_port", 0)))


func run() -> void:
	if not OS.get_user_data_dir().replace("\\", "/").contains("VonNeumannBottleneckChecks/"):
		push_error("Run hardware history checks through the isolated verifier.")
		quit(1)
		return
	root.size = Vector2i(1280, 720)
	root.get_node("GameMode").set_mode(&"test")
	var game_signature: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	bench = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(bench)
	await settle()

	bench._start_campaign_level(&"cpu", false)
	await settle()
	var cpu_wires: Array = bench.current_level_definition.reference_wires
	for index: int in [0, 1, 3, 5]:
		connect_wire(cpu_wires[index])
	check(bench.cpu_stage_index == 1, "CPU fixture completes the first interface stage")
	var stage_one: String = bench.cpu_stage_label.text
	bench._undo_wire()
	check(bench.cpu_stage_index == 0 and bench.cpu_stage_label.text != stage_one,
		"Undo immediately returns CPU guidance to the incomplete stage")
	bench._redo_edit()
	check(bench.cpu_stage_index == 1 and bench.cpu_stage_label.text == stage_one,
		"Redo immediately derives CPU guidance from restored wiring")
	bench._clear_wires()
	check(bench.cpu_stage_index == 0 and bench.cpu_stage_label.text != stage_one,
		"Clearing CPU wiring immediately returns guidance to the incomplete stage")
	await capture_frame("cpu-clear")
	var clear_history_size: int = bench.wire_history.size()
	var clear_snapshot: Dictionary = bench._capture_workbench_snapshot()
	bench._clear_wires()
	check(bench.wire_history.size() == clear_history_size and bench.redo_history.is_empty()
		and bench._capture_workbench_snapshot() == clear_snapshot and bench.cpu_stage_index == 0,
		"Clearing an already empty CPU board leaves topology and history unchanged")
	bench._undo_wire()
	check(bench.cpu_stage_index == 1 and bench.graph.get_connection_list().size() == 4,
		"A single Undo restores the nonempty clear transaction and CPU guidance")

	bench._start_campaign_level(&"ram", false)
	await settle()
	for wire: Dictionary in bench.current_level_definition.reference_wires:
		connect_wire(wire)
	bench._run_debug()
	bench._finish_playback()
	var panel: VBoxContainer = bench.construction_investigation
	check(bench.prologue_live_result != null and bench.prologue_live_result.is_valid()
		and panel.observations.size() == 1, "RAM fixture records a real successful Debug observation")
	var observations: Array = panel.observations.duplicate()
	var debug_text: String = bench.debug_result_label.text
	var node: GraphNode = bench.component_nodes.values()[0]
	bench._on_begin_node_move()
	node.position_offset += Vector2(40, 20)
	bench._on_end_node_move()
	bench._undo_wire()
	check(panel.observations == observations and bench.debug_result_label.text == debug_text, "Undoing presentation-only movement retains valid observations")
	bench._redo_edit()
	check(panel.observations == observations, "Redoing presentation-only movement retains valid observations")
	bench._undo_wire()
	bench._undo_wire()
	check(panel.observations.is_empty() and panel.input_samples.is_empty()
		and panel.output_samples.is_empty() and panel.evidence.text.is_empty(),
		"Undoing circuit wiring clears observations bound to the previous topology")
	check(bench.debug_result_label.text == bench._t(&"hardware.prologue.outputs_empty"),
		"Topology Undo removes the previous Debug output label")
	bench._redo_edit()
	check(panel.observations.is_empty(), "Redo cannot resurrect discarded observations")
	bench._run_debug()
	bench._finish_playback()
	check(panel.observations.size() == 1, "Restored RAM can record fresh simulator evidence")
	var last_wire: Dictionary = bench.current_level_definition.reference_wires.back()
	observations = panel.observations.duplicate()
	connect_wire(last_wire)
	check(panel.observations == observations, "Rejected duplicate connection preserves valid observations")
	bench._on_disconnection_request(&"MISSING", 0, &"ALSO_MISSING", 0)
	check(panel.observations == observations, "No-op disconnection preserves valid observations")
	bench._on_disconnection_request(last_wire["from"], int(last_wire.get("from_port", 0)),
		last_wire["to"], int(last_wire.get("to_port", 0)))
	check(panel.observations.is_empty(), "Successful ordinary disconnection clears old observations")
	connect_wire(last_wire)
	bench._run_debug()
	bench._finish_playback()
	check(panel.observations.size() == 1, "Reconnecting RAM allows fresh observations")
	# Add a free output pin so the next connection is valid and changes topology
	# without using fabricated simulator evidence or disturbing the RAM inputs.
	var component := LogicComponent.new(&"EXTRA_OUT", LogicComponent.KIND_OUTPUT,
		"Extra output", &"EXTRA", false, [], [], [], [], {"width": 4})
	bench._add_catalog_component(component)
	bench._add_component_node(component, Vector2(800, 500))
	bench._on_connection_request(last_wire["from"], int(last_wire.get("from_port", 0)), &"EXTRA_OUT", 0)
	check(panel.observations.is_empty(), "Successful ordinary connection clears old observations")
	bench._run_debug()
	bench._finish_playback()
	check(bench.prologue_live_result.is_valid() and panel.observations.size() == 1,
		"Branched RAM produces real evidence before clearing wires")
	var retained_storage: Dictionary = bench.prologue_runtime_state.duplicate(true)
	bench._clear_wires()
	check(bench.debug_result_label.text == bench._t(&"hardware.prologue.outputs_empty"),
		"Clearing wires removes the previous green Debug output label")
	check(bench.prologue_runtime_state == retained_storage, "Result-label invalidation preserves committed RAM storage")
	check(panel.observations.is_empty() and panel.input_samples.is_empty()
		and panel.output_samples.is_empty() and panel.evidence.text.is_empty(),
		"Clearing all wires removes observations of the previous circuit")
	await capture_frame("ram-clear")
	clear_history_size = bench.wire_history.size()
	bench._clear_wires()
	check(bench.wire_history.size() == clear_history_size and panel.observations.is_empty(),
		"Repeated empty clear does not create another history action")
	bench._undo_wire()
	check(bench.graph.get_connection_list().size() == bench.current_level_definition.reference_wires.size() + 1
		and panel.observations.is_empty(), "Undo restores cleared wiring without resurrecting discarded evidence")

	bench._start_campaign_level(&"tutorial", false)
	await settle()
	connect_wire({"from": &"A_IN", "to": &"NOT_1"})
	connect_wire({"from": &"NOT_1", "to": &"LAMP"})
	var wired_goal: String = bench.mission_summary_button.text
	check(bench.tutorial_created_wire and not bench.tutorial_valid_run,
		"Tutorial fixture has wired but not run its circuit")
	bench._undo_wire()
	check(bench.mission_summary_button.text != wired_goal,
		"Undoing the tutorial output wire restores current wiring guidance")
	await capture_frame("tutorial-undo")
	check(bench.tutorial_created_wire and not bench.tutorial_removed_wire
		and not bench.tutorial_reconnected_wire, "Undo preserves earned actions without granting removal practice")
	bench._redo_edit()
	check(bench.mission_summary_button.text == wired_goal,
		"Redo restores tutorial guidance for the connected circuit")
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == game_signature,
		"Test history checks leave ordinary Game progression unchanged")
	bench.queue_free()
	await settle()
	print("PASS: hardware history context %d checks" % checks if failures.is_empty()
		else "FAIL: hardware history context %d/%d checks" % [failures.size(), checks])
	quit(0 if failures.is_empty() else 1)
