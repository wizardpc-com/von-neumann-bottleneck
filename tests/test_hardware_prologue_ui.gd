extends SceneTree

const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const ReusableComponentType = preload("res://src/circuit/reusable_component.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://src/hardware_foundations/hardware_foundations.tscn")
	var main: Control = scene.instantiate()
	root.add_child(main)
	for _frame: int in range(4):
		await process_frame

	var library: Dictionary = main.get("component_library")
	var completed: Dictionary = main.get("completed_levels")
	completed[&"tutorial"] = true
	library[&"HalfAdder"] = ReusableComponentType.new(
		&"HalfAdder", LogicComponentType.KIND_HALF_ADDER, &"half_adder", _provenance_circuit()
	)
	completed[&"half_adder"] = true
	main.call("_open_campaign_map")
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"campaign", "Sealed HalfAdder must lead to the session campaign map.")
	var campaign_map: Control = main.get("campaign_map_view")
	_assert(campaign_map != null and is_instance_valid(campaign_map), "Campaign selection must use the central graphical dependency map.")
	_assert(
		StringName(campaign_map.call("level_state", &"full_adder")) == &"unlocked"
		and StringName(campaign_map.call("level_state", &"latch")) == &"unlocked"
		and StringName(campaign_map.call("level_state", &"cpu")) == &"locked",
		"The graphical map must expose both unlocked branches while keeping their CPU merge locked."
	)
	var campaign_buttons: Dictionary = main.get("campaign_level_buttons")
	_assert(
		not (campaign_buttons[&"tutorial"] as Button).disabled
		and not (campaign_buttons[&"half_adder"] as Button).disabled
		and not (campaign_buttons[&"full_adder"] as Button).disabled,
		"Completed Foundations levels must remain replayable while their first dependent construction level unlocks."
	)
	_assert(not (main.get("level_catalog").is_unlocked(&"cpu", completed)), "CPU must remain locked before both construction branches finish.")

	await _solve_and_seal(main, &"full_adder", &"FullAdder")
	_assert(library.has(&"FullAdder"), "Full Adder sealing must add the player's reusable component to the library.")
	await _solve_and_seal(main, &"alu", &"ALU1")
	_assert(library.has(&"ALU4") and (library[&"ALU4"] as ReusableComponent).is_generated_wrapper(), "Passing ALU1 must generate the non-repetitive four-bit ALU4 wrapper.")
	_assert(int((library[&"ALU4"] as ReusableComponent).metadata.get("auto_expanded_bits", 0)) == 4, "ALU4 provenance must record its automatic four-bit expansion.")

	await _solve_and_seal(main, &"latch", &"SRLatch")
	await _solve_and_seal(main, &"register", &"Register1")
	_assert(library.has(&"Register4") and (library[&"Register4"] as ReusableComponent).is_generated_wrapper(), "Passing Register1 must generate Register4 without four repeated wiring tasks.")
	await _solve_and_seal(main, &"ram", &"RAM2x4")
	_assert(main.get("level_catalog").is_unlocked(&"cpu", completed), "ALU and RAM completion must unlock CPU construction.")

	await _solve_and_seal(main, &"cpu", &"TinyComputer")
	_assert(library.has(&"TinyComputer"), "The verified graph-built CPU must seal as the player's TinyComputer.")
	main.call("_open_campaign_map")
	main.call("_start_prologue_level", &"load_store")
	await process_frame
	var graph: GraphEdit = main.get("graph")
	_assert(graph.get_connection_list().size() == 5, "The LOAD/STORE bridge must reuse the sealed computer with an already connected external Test Bench.")
	_assert(not bool(graph.get("branch_edit_enabled")), "The bridge topology must be locked so it is a program/data-flow demonstration, not repeated wiring.")
	_assert((main.get("component_menu_button") as MenuButton).disabled, "A locked demonstration topology must not offer extra component placement.")
	main.call("_run_official")
	await process_frame
	_assert(bool(completed.get(&"load_store", false)), "The final fixed LOAD/STORE program must complete through the sealed TinyComputer contract.")
	_assert(StringName(main.get("current_phase")) == &"prologue_complete", "Successful LOAD/STORE must finish the construction prologue.")
	var bridge_report: Dictionary = main.get("prologue_report")
	_assert(bool(bridge_report.get("passed", false)) and (bridge_report.get("events", []) as Array).size() > 10, "The bridge must expose a deterministic multi-step signal trace, not a hidden completion flag.")
	var first_result = (bridge_report.get("steps", []) as Array)[0]["result"]
	_assert(first_result.observed_values[&"ACC"].value == 3, "LOAD_IMM must visibly place 3 in the accumulator on the first bridge step.")
	main.call("_invalidate_downstream_progress", &"latch")
	_assert(bool(completed.get(&"alu", false)) and not bool(completed.get(&"register", false)) and not bool(completed.get(&"cpu", false)), "Changing an upstream latch design must invalidate only its dependent abstractions, never the independent ALU branch.")
	_assert(not library.has(&"Register4") and not library.has(&"RAM2x4") and not library.has(&"TinyComputer"), "Invalidated downstream components must not survive with stale provenance.")

	main.call("_stop_playback")
	main.queue_free()
	for _cleanup_frame: int in range(10):
		await process_frame
	if failures.is_empty():
		print("PASS: two-branch prologue progression, player-owned sealing, word wrappers, CPU construction, and LOAD/STORE UI tests passed")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		print("FAIL: %d Hardware prologue UI assertion(s) failed" % failures.size())
		quit(1)


func _solve_and_seal(main: Control, level_id: StringName, expected_component: StringName) -> void:
	main.call("_open_campaign_map")
	main.call("_start_prologue_level", level_id)
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"prologue", "%s must open as an editable construction level." % level_id)
	if level_id in [&"latch", &"register", &"ram"]:
		var storage_label: Label = main.get("storage_state_label")
		_assert(storage_label != null and is_instance_valid(storage_label), "%s must expose a committed-state monitor separate from live port preview." % level_id)
	var definition: Dictionary = main.get("current_level_definition")
	var graph: GraphEdit = main.get("graph")
	_assert(graph.get_connection_list().is_empty(), "%s must not expose the reference solution to the player." % level_id)
	_assert(not (main.get("component_menu_button") as MenuButton).disabled and not (main.get("component_menu_templates") as Dictionary).is_empty(), "%s must expose a level-authoritative menu for placing additional allowed components." % level_id)
	var idle_analysis_count: int = int(main.get("live_analysis_count"))
	for _idle_frame: int in range(2):
		await process_frame
	_assert(int(main.get("live_analysis_count")) == idle_analysis_count, "%s live multi-bit port evaluation must be event-driven rather than recomputed every frame." % level_id)
	for source_wire: Dictionary in definition.get("reference_wires", []):
		main.call(
			"_on_connection_request",
			source_wire["from"], int(source_wire.get("from_port", 0)),
			source_wire["to"], int(source_wire.get("to_port", 0))
		)
	await process_frame
	if level_id == &"ram":
		main.call("_run_debug")
		await process_frame
		main.call("_finish_playback")
		var debug_storage: Label = main.get("storage_state_label")
		_assert(debug_storage != null and "0x3" in debug_storage.text, "Running RAM debug input must commit M0=0x3 in the state monitor.")
		main.call("_reset_storage_debug_state")
		await process_frame
		_assert(debug_storage != null and debug_storage.text == String(main.call("_t", &"hardware.storage.state.cleared")), "Reset State must clear temporal debug state without touching visible wires.")
		_assert(graph.get_connection_list().size() == (definition.get("reference_wires", []) as Array).size(), "Reset State must preserve the player's complete RAM topology.")
	main.call("_run_official")
	await process_frame
	_assert(bool(main.get("official_passed")), "%s reference-visible topology must pass every official case." % level_id)
	_assert(String(main.get("passing_topology_signature")) == main.call("_circuit_from_graph").canonical_signature(), "%s evidence must bind to the exact displayed topology." % level_id)
	var batches: Array = main.get("playback_batches")
	_assert(not batches.is_empty(), "%s official run must produce causal playback batches." % level_id)
	if level_id in [&"latch", &"register", &"ram"]:
		var transition_rows: Array = main.get("prologue_case_labels")
		_assert(not transition_rows.is_empty() and "→" in (transition_rows[0] as Label).text, "%s official rows must show the before/after storage transition." % level_id)
	if level_id in [&"latch", &"register", &"ram"]:
		var saw_state_boundary: bool = false
		var saw_parallel_ram_cells: bool = false
		var parallel_ram_batch: Dictionary = {}
		for batch: Dictionary in batches:
			var boundary_count: int = 0
			for event: PrologueEvent in batch.get("events", []):
				if event.kind == &"state_transition":
					boundary_count += 1
			saw_state_boundary = saw_state_boundary or boundary_count > 0
			saw_parallel_ram_cells = saw_parallel_ram_cells or boundary_count >= 2
			if boundary_count >= 2:
				parallel_ram_batch = batch
		_assert(saw_state_boundary, "%s playback must animate an explicit state boundary even on HOLD." % level_id)
		if level_id == &"ram":
			_assert(saw_parallel_ram_cells, "RAM's two Register4 cells must animate their boundary in parallel, not one after another.")
			var playback_storage: Label = main.get("storage_state_label")
			_assert(playback_storage != null and playback_storage.text.count("0x0") >= 2, "Official RAM playback must start from its initial committed state instead of showing the final memory early.")
			main.call("_finish_playback")
			var final_storage: Label = main.get("storage_state_label")
			_assert(final_storage != null and "0x5" in final_storage.text and "0xC" in final_storage.text, "RAM official sequence must leave M0=0x5 and M1=0xC visible in the committed-state monitor.")
			main.call("_show_playback_batch", parallel_ram_batch, 0.5)
			var component_pulses: Array = main.get("trace_overlay").get("component_pulses")
			var nodes: Dictionary = main.get("component_nodes")
			for pulse: Dictionary in component_pulses:
				var component_id := StringName(pulse.get("component_id", &""))
				if component_id not in [&"REG_0", &"REG_1"]:
					continue
				var expected_rect: Rect2 = main.call("_component_overlay_rect", nodes[component_id])
				var actual_rect: Rect2 = pulse.get("rect", Rect2())
				_assert(actual_rect.get_center().is_equal_approx(expected_rect.get_center()), "RAM processing halo must stay centered on the displayed %s node after GraphEdit zoom/scroll." % component_id)
	if level_id == &"cpu":
		_assert_cpu_playback(main)
	main.call("_seal_prologue_component")
	_assert(bool(main.get("sealing")), "%s sealing must begin with the encapsulation effect." % level_id)
	main.call("_finish_encapsulation")
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"prologue_complete", "%s must enter a clear completed state after sealing." % level_id)
	_assert((main.get("component_library") as Dictionary).has(expected_component), "%s must register %s in the reusable library." % [level_id, expected_component])
	_assert(bool((main.get("completed_levels") as Dictionary).get(level_id, false)), "%s must persist as completed for this session." % level_id)


func _assert_cpu_playback(main: Control) -> void:
	var report: Dictionary = main.get("prologue_report")
	var component_kinds: Dictionary[StringName, bool] = {}
	var parallel_component_wave: bool = false
	var word_wire_event: PrologueEvent
	for batch: Dictionary in main.get("playback_batches"):
		var component_count: int = 0
		for event: PrologueEvent in batch.get("events", []):
			if event.kind == &"component_process":
				component_count += 1
				var component = (main.get("component_catalog") as Dictionary).get(event.component_id)
				if component != null:
					component_kinds[component.kind] = true
			elif event.kind == &"wire_signal" and event.value.width == 4 and word_wire_event == null:
				word_wire_event = event
		parallel_component_wave = parallel_component_wave or component_count >= 2
	_assert(component_kinds.has(&"control") and component_kinds.has(&"alu4") and component_kinds.has(&"register4") and component_kinds.has(&"ram2x4"), "CPU playback must give control, ALU, accumulator, and RAM their own processing events.")
	_assert(parallel_component_wave, "Independent CPU components ready on the same tick must animate in one parallel wave.")
	_assert(word_wire_event != null, "CPU playback must include a four-bit data word moving over a displayed connection.")
	if word_wire_event != null:
		var expected_path: PackedVector2Array = main.call(
			"_connection_curve", word_wire_event.from_component, word_wire_event.from_port,
			word_wire_event.to_component, word_wire_event.to_port
		)
		main.call("_show_playback_batch", {
			"tick": word_wire_event.tick,
			"visual_step": word_wire_event.visual_step,
			"events": [word_wire_event],
		}, 0.5)
		var pulses: Array = main.get("trace_overlay").get("wire_pulses")
		_assert(not pulses.is_empty() and _paths_equal(pulses[0]["path"], expected_path), "Four-bit animation must follow the exact currently rendered connection curve.")
		_assert(not pulses.is_empty() and String(pulses[0].get("display", "")).begins_with("0x"), "A word animation must display its multi-bit value instead of collapsing it to a binary dot.")
	_assert(bool(report.get("passed", false)), "Animation inspection must not influence the already computed CPU result.")


func _provenance_circuit() -> LogicCircuit:
	var circuit := LogicCircuitType.new()
	circuit.add_component(LogicComponentType.new(&"SOURCE", LogicComponentType.KIND_INPUT, "SOURCE", &"A", true))
	circuit.add_component(LogicComponentType.new(&"PROBE", LogicComponentType.KIND_OUTPUT, "PROBE", &"SUM", true))
	circuit.connect_ports(&"SOURCE", 0, &"PROBE", 0)
	return circuit


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _paths_equal(left: PackedVector2Array, right: PackedVector2Array) -> bool:
	if left.size() != right.size():
		return false
	for index: int in range(left.size()):
		if not left[index].is_equal_approx(right[index]):
			return false
	return true
