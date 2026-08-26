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
	_assert_module_text_clearance(main, &"load_store")
	var graph: GraphEdit = main.get("graph")
	var bridge_definition: Dictionary = main.get("current_level_definition")
	_assert(_all_initial_components_used(bridge_definition), "LOAD/STORE must not pre-place components absent from its task topology.")
	_assert(graph.get_connection_list().size() == 5, "The LOAD/STORE bridge must reuse the sealed computer with an already connected external Test Bench.")
	_assert(not bool(graph.get("branch_edit_enabled")), "The bridge topology must be locked so it is a program/data-flow demonstration, not repeated wiring.")
	_assert((main.get("component_menu_button") as MenuButton).disabled, "A locked demonstration topology must not offer extra component placement.")
	var bridge_snapshot: String = JSON.stringify(main.call("_capture_workbench_snapshot"))
	main.call("_enter_hint_workbench")
	await process_frame
	_assert(
		_canvas_component_ids(main) == _fixed_component_ids(bridge_definition)
		and (main.get("graph") as GraphEdit).get_connection_list().is_empty(),
		"LOAD/STORE Hint stage 1 must show only its necessary external interface."
	)
	main.call("_show_hint_level", 2)
	await process_frame
	_assert(
		_canvas_component_ids(main) == _stage_two_component_ids(bridge_definition)
		and (main.get("graph") as GraphEdit).get_connection_list().size() == 2,
		"LOAD/STORE Hint stage 2 must show only its curated memory-facing slice."
	)
	main.call("_show_hint_level", 3)
	await process_frame
	_assert(
		(main.get("graph") as GraphEdit).get_connection_list().size() == 5
		and main.call("_circuit_from_graph").canonical_signature() == main.get("level_catalog").reference_circuit(&"load_store", main.get("component_library")).canonical_signature(),
		"The final bridge must also expose a truthful read-only level-3 reference workbench."
	)
	main.call("_exit_hint_workbench")
	await process_frame
	graph = main.get("graph")
	_assert(JSON.stringify(main.call("_capture_workbench_snapshot")) == bridge_snapshot, "Leaving the final bridge hint must restore its own default workbench unchanged.")
	main.call("_run_official")
	await _finish_official_sequence(main)
	_assert(bool(completed.get(&"load_store", false)), "The final fixed LOAD/STORE program must complete through the sealed TinyComputer contract.")
	_assert(StringName(main.get("current_phase")) == &"prologue_complete", "Successful LOAD/STORE must finish the construction prologue.")
	var bridge_completion: Control = main.get("level_completion_overlay")
	_assert(
		bridge_completion.visible
		and StringName(bridge_completion.get("current_level_id")) == &"load_store"
		and not String((bridge_completion.get("summary_label") as Label).text).is_empty(),
		"LOAD/STORE completion must automatically summarize its processor-waiting lesson."
	)
	var system_chapter: Node = root.get_node("SystemChapter")
	_assert(
		bool(system_chapter.get("prologue_ready"))
		and String(system_chapter.get("cpu_source_signature")) != "reference-cpu4"
		and String(system_chapter.get("ram_source_signature")) != "reference-ram2x4",
		"Game-mode LOAD/STORE completion must hand verified CPU/RAM provenance to Chapter 1 even before its button is clicked."
	)
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
	_assert_module_text_clearance(main, level_id)
	if level_id in [&"latch", &"register", &"ram"]:
		var storage_label: Label = main.get("storage_state_label")
		_assert(storage_label != null and is_instance_valid(storage_label), "%s must expose a committed-state monitor separate from live port preview." % level_id)
	var definition: Dictionary = main.get("current_level_definition")
	var graph: GraphEdit = main.get("graph")
	_assert(_all_initial_components_used(definition), "%s must not pre-place a component absent from its task topology." % level_id)
	_assert(graph.get_connection_list().is_empty(), "%s must not expose the reference solution to the player." % level_id)
	_assert(not (main.get("component_menu_button") as MenuButton).disabled and not (main.get("component_menu_templates") as Dictionary).is_empty(), "%s must expose a level-authoritative menu for placing additional allowed components." % level_id)
	_assert(not (main.get("component_palette_items") as Dictionary).is_empty(), "%s must expose the same allowed supply as visible draggable palette items." % level_id)
	_assert(_palette_kinds(main) == _expected_palette_kinds(level_id), "%s must expose its explicit suitable component set; expected=%s actual=%s." % [level_id, _expected_palette_kinds(level_id), _palette_kinds(main)])
	_assert_palette_previews_match_canvas(main, level_id)
	if level_id in [&"full_adder", &"alu"]:
		var has_xor: bool = false
		for template_variant: Variant in (main.get("component_menu_templates") as Dictionary).values():
			has_xor = has_xor or StringName(template_variant.kind) == LogicComponentType.KIND_XOR
		_assert(has_xor, "%s must offer the XOR primitive unlocked after Half Adder." % level_id)
	var idle_analysis_count: int = int(main.get("live_analysis_count"))
	for _idle_frame: int in range(2):
		await process_frame
	_assert(int(main.get("live_analysis_count")) == idle_analysis_count, "%s live multi-bit port evaluation must be event-driven rather than recomputed every frame." % level_id)
	var player_snapshot: String = JSON.stringify(main.call("_capture_workbench_snapshot"))
	main.call("_enter_hint_workbench")
	await process_frame
	_assert(
		_canvas_component_ids(main) == _fixed_component_ids(definition)
		and (main.get("graph") as GraphEdit).get_connection_list().is_empty(),
		"%s Hint stage 1 must contain only the level interface and no solution topology." % level_id
	)
	main.call("_show_hint_level", 2)
	await process_frame
	var authored_hint_count: int = (definition.get("hint_partial_wires", []) as Array).size()
	_assert(
		(main.get("graph") as GraphEdit).get_connection_list().size() == authored_hint_count
		and _canvas_component_ids(main) == _stage_two_component_ids(definition),
		"%s Hint stage 2 must show exactly its authored key subcircuit with no unrelated components." % level_id
	)
	for node_variant: Variant in (main.get("component_nodes") as Dictionary).values():
		_assert(not (node_variant as GraphNode).draggable, "%s hint components must remain read-only." % level_id)
	main.call("_show_hint_level", 3)
	await process_frame
	var expected_reference: LogicCircuit = main.get("level_catalog").reference_circuit(level_id, main.get("component_library"))
	_assert(
		main.call("_circuit_from_graph").canonical_signature() == expected_reference.canonical_signature(),
		"%s hint stage 3 must be the same complete topology used by official reference evidence." % level_id
	)
	main.call("_exit_hint_workbench")
	await process_frame
	graph = main.get("graph")
	definition = main.get("current_level_definition")
	_assert(
		JSON.stringify(main.call("_capture_workbench_snapshot")) == player_snapshot
		and (main.get("wire_history") as Array).is_empty(),
		"%s must return from hints to the byte-identical player workbench with no hint history." % level_id
	)
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
	_assert(
		bool(main.get("official_sequence_active"))
		and not bool(main.get("official_passed"))
		and (main.get("prologue_report") as Dictionary).is_empty(),
		"%s official run must withhold its aggregate verdict while the first case is playing." % level_id
	)
	if level_id in [&"latch", &"register", &"ram"]:
		var playback_storage: Label = main.get("storage_state_label")
		_assert(
			playback_storage != null and (
				playback_storage.text.count("0x0") >= 2 if level_id == &"ram" else true
			),
			"%s official playback must begin from its initial committed state." % level_id
		)
	await _finish_official_sequence(main)
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
		var first_state_batch: Dictionary = {}
		for batch: Dictionary in batches:
			var boundary_count: int = 0
			for event: PrologueEvent in batch.get("events", []):
				if event.kind == &"state_transition":
					boundary_count += 1
			if boundary_count > 0 and first_state_batch.is_empty():
				first_state_batch = batch
			saw_state_boundary = saw_state_boundary or boundary_count > 0
			saw_parallel_ram_cells = saw_parallel_ram_cells or boundary_count >= 2
			if boundary_count >= 2:
				parallel_ram_batch = batch
		_assert(saw_state_boundary, "%s playback must animate an explicit state boundary even on HOLD." % level_id)
		if level_id == &"register" and not first_state_batch.is_empty():
			main.call("_show_playback_batch", first_state_batch, 0.82)
			var latch_rows: Array = (main.get("component_row_labels") as Dictionary).get(&"LATCH", [])
			_assert(latch_rows.size() == 2, "The SR latch must display separate Q and NQ output rows.")
			if latch_rows.size() == 2:
				_assert(bool(latch_rows[0].call("output_token_enabled")), "The latch state event must animate its real Q output pin.")
				_assert(not bool(latch_rows[1].call("output_token_enabled")), "The Q state value must not be duplicated onto the opposite NQ output animation.")
		if level_id == &"ram":
			_assert(saw_parallel_ram_cells, "RAM's two Register4 cells must animate their boundary in parallel, not one after another.")
			var final_storage: Label = main.get("storage_state_label")
			_assert(final_storage != null and "0x5" in final_storage.text and "0xC" in final_storage.text, "RAM official sequence must leave M0=0x5 and M1=0xC visible in the committed-state monitor.")
			main.call("_show_playback_batch", parallel_ram_batch, 0.5)
			var nodes: Dictionary = main.get("component_nodes")
			var row_labels: Dictionary = main.get("component_row_labels")
			for component_id: StringName in [&"REG_0", &"REG_1"]:
				var rows: Array = row_labels.get(component_id, [])
				var node := nodes[component_id] as GraphNode
				_assert(not rows.is_empty(), "RAM processing must reuse the displayed %s row surface." % component_id)
				if rows.is_empty():
					continue
				var row: Variant = rows[0]
				_assert(bool(row.get("processing_active")), "RAM processing must animate the actual %s component surface instead of drawing a substitute RAM model." % component_id)
				_assert(StringName(row.call("shape_profile")) == &"register_module", "RAM cells must keep their register/latch silhouette while processing.")
				_assert(node.get_global_rect().has_point(row.get_global_rect().get_center()), "RAM activity must remain inside the displayed %s node after GraphEdit zoom/scroll." % component_id)
			_assert(StringName(main.get("trace_overlay").get("mode")).is_empty(), "A state boundary must not add a detached component halo above the real register surfaces.")
	if level_id == &"cpu":
		_assert_cpu_playback(main)
	main.call("_seal_prologue_component")
	_assert(bool(main.get("sealing")), "%s sealing must begin with the encapsulation effect." % level_id)
	main.call("_finish_encapsulation")
	await process_frame
	_assert(StringName(main.get("current_phase")) == &"prologue_complete", "%s must enter a clear completed state after sealing." % level_id)
	_assert((main.get("component_library") as Dictionary).has(expected_component), "%s must register %s in the reusable library." % [level_id, expected_component])
	_assert(bool((main.get("completed_levels") as Dictionary).get(level_id, false)), "%s must persist as completed for this session." % level_id)
	var completion_overlay: Control = main.get("level_completion_overlay")
	_assert(
		completion_overlay.visible
		and StringName(completion_overlay.get("current_level_id")) == level_id
		and not String((completion_overlay.get("summary_label") as Label).text).is_empty(),
		"%s completion must automatically present a localized learning summary." % level_id
	)


func _assert_cpu_playback(main: Control) -> void:
	var report: Dictionary = main.get("prologue_report")
	var visible_names: Dictionary[String, bool] = {}
	for rows_variant: Variant in (main.get("component_row_labels") as Dictionary).values():
		var rows: Array = rows_variant
		if not rows.is_empty():
			visible_names[String(rows[rows.size() / 2].call("visible_component_name"))] = true
	_assert(
		visible_names.has("Control") and visible_names.has("ALU4")
		and visible_names.has("Register4") and visible_names.has("RAM2x4")
		and visible_names.has("Word Mux"),
		"CPU modules must render their complete function names rather than line-obscured abbreviations."
	)
	var component_kinds: Dictionary[StringName, bool] = {}
	var parallel_component_wave: bool = false
	var word_wire_event: PrologueEvent
	var ram_event: PrologueEvent
	var component_counts_by_wave: Dictionary[String, int] = {}
	for event: PrologueEvent in report.get("events", []):
		var wave_id: String = "%d:%d" % [event.sequence_step, event.visual_step]
		if event.kind == &"component_process":
			component_counts_by_wave[wave_id] = int(component_counts_by_wave.get(wave_id, 0)) + 1
			var component = (main.get("component_catalog") as Dictionary).get(event.component_id)
			if component != null:
				component_kinds[component.kind] = true
				if component.kind == &"ram2x4" and ram_event == null:
					ram_event = event
		elif event.kind == &"wire_signal" and event.value.width == 4 and word_wire_event == null:
			word_wire_event = event
	for component_count: int in component_counts_by_wave.values():
		parallel_component_wave = parallel_component_wave or component_count >= 2
	_assert(component_kinds.has(&"control") and component_kinds.has(&"alu4") and component_kinds.has(&"register4") and component_kinds.has(&"ram2x4"), "CPU playback must give control, ALU, accumulator, and RAM their own processing events.")
	_assert(parallel_component_wave, "Independent CPU components ready on the same tick must animate in one parallel wave.")
	_assert(ram_event != null, "CPU playback must expose a RAM processing event for on-component address feedback.")
	if ram_event != null:
		main.call("_show_playback_batch", {
			"tick": ram_event.tick,
			"visual_step": ram_event.visual_step,
			"events": [ram_event],
		}, 0.5)
		var ram_rows: Array = (main.get("component_row_labels") as Dictionary).get(ram_event.component_id, [])
		_assert(not ram_rows.is_empty(), "The CPU RAM must use a real procedural module surface.")
		if not ram_rows.is_empty():
			var ram_row: Variant = ram_rows[ram_rows.size() / 2]
			_assert(StringName(ram_row.call("shape_profile")) == &"ram_grid", "RAM must use a visible cell-grid silhouette, not a generic text card.")
			_assert(int(ram_row.call("ram_cursor_index")) >= 0, "A known RAM address must light a cursor on the actual RAM grid during processing.")
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


func _finish_official_sequence(main: Control) -> void:
	var frame_guard: int = 0
	while bool(main.get("official_sequence_active")) and frame_guard < 128:
		if bool(main.get("playback_running")):
			main.call("_finish_playback")
		await process_frame
		frame_guard += 1
	_assert(
		not bool(main.get("official_sequence_active")),
		"The official case sequence must reach its aggregate verdict without stalling."
	)


func _assert_module_text_clearance(main: Control, level_id: StringName) -> void:
	for rows_variant: Variant in (main.get("component_row_labels") as Dictionary).values():
		var rows: Array = rows_variant
		if rows.is_empty():
			continue
		var row: Control = rows[rows.size() / 2]
		var name: String = String(row.call("visible_component_name"))
		var layout: Dictionary = row.call("name_layout")
		var name_rect: Rect2 = layout.get("rect", Rect2())
		var safe_rect: Rect2 = layout.get("safe_rect", Rect2())
		var icon_rect: Rect2 = layout.get("icon_rect", Rect2())
		_assert(
			String(layout.get("text", "")) == name
			and safe_rect.encloses(name_rect)
			and name_rect.size.x > 4.0,
			"%s %s must keep its complete name inside the row's port-free safe region; safe=%s name=%s." % [level_id, name, safe_rect, name_rect]
		)
		_assert(
			not icon_rect.has_area() or (
				safe_rect.encloses(icon_rect) and not icon_rect.intersects(name_rect)
			),
			"%s %s must keep its function glyph separate from its name." % [level_id, name]
		)
		for port_layout: Dictionary in row.call("port_label_layouts"):
			var port_rect: Rect2 = port_layout.get("rect", Rect2())
			_assert(
				not row.call("function_mark_rect").intersects(port_rect.grow(2.0)),
				"%s %s must keep port text clear of its function glyph and complete name." % [level_id, name]
			)


func _palette_kinds(main: Control) -> Array[StringName]:
	var unique: Dictionary[StringName, bool] = {}
	for template_variant: Variant in (main.get("component_menu_templates") as Dictionary).values():
		var template: LogicComponent = template_variant
		unique[template.kind] = true
	var result: Array[StringName] = []
	for kind: StringName in unique:
		result.append(kind)
	result.sort()
	return result


func _assert_palette_previews_match_canvas(main: Control, level_id: StringName) -> void:
	var templates: Dictionary = main.get("component_menu_templates")
	var items: Dictionary = main.get("component_palette_items")
	for key: String in items:
		var template: LogicComponent = templates[key]
		var item: Control = items[key]
		var preview: Control = item.get("component_preview") as Control
		var preview_node: GraphNode
		if preview != null:
			preview_node = preview.get_child(0) as GraphNode
		_assert(
			preview_node != null
			and preview_node.custom_minimum_size.is_equal_approx(main.call("_component_node_size", template)),
			"%s palette item %s must use the canvas component footprint instead of a name-only placeholder." % [level_id, template.kind]
		)
	if level_id != &"register":
		return
	var latch_key: String = ""
	for key: String in templates:
		if (templates[key] as LogicComponent).kind == LogicComponentType.KIND_SR_LATCH:
			latch_key = key
			break
	_assert(not latch_key.is_empty(), "Register must expose SRLatch in the component palette.")
	if latch_key.is_empty():
		return
	var latch_template: LogicComponent = templates[latch_key]
	var palette_preview: Control = (items[latch_key] as Control).get("component_preview") as Control
	var palette_node: GraphNode = palette_preview.get_child(0) as GraphNode
	var placement_preview: Control = main.call("_create_component_placement_ghost", latch_template)
	var placement_node: GraphNode = placement_preview.get_child(0) as GraphNode
	var canvas_node: GraphNode = (main.get("component_nodes") as Dictionary)[&"LATCH"] as GraphNode
	_assert(
		_component_visual_signature(palette_node) == _component_visual_signature(canvas_node)
		and _component_visual_signature(placement_node) == _component_visual_signature(canvas_node),
		"SRLatch must use one identical row, port, state, and shape presentation in the palette, placement ghost, and placed canvas node."
	)
	placement_preview.free()


func _component_visual_signature(node: GraphNode) -> String:
	if node == null:
		return ""
	var rows: Array[Dictionary] = []
	var symbols: Array[Dictionary] = []
	var state_labels: Array[Dictionary] = []
	for child: Node in node.get_children():
		if child is CircuitModuleRow:
			var row := child as CircuitModuleRow
			rows.append({
				"kind": String(row.component_kind),
				"component": row.visible_component_name(),
				"input": row.input_label,
				"output": row.output_label,
				"index": row.row_index,
				"count": row.row_count,
				"has_input": row.has_input,
				"has_output": row.has_output,
				"input_width": row.input_width,
				"output_width": row.output_width,
				"shape": String(row.shape_profile()),
				"position": row.position,
				"size": row.size,
			})
		elif child is CircuitComponentSymbol:
			var symbol := child as CircuitComponentSymbol
			symbols.append({
				"kind": String(symbol.component_kind),
				"label": symbol.terminal_label,
				"height": symbol.display_height,
				"shape": String(symbol.shape_profile()),
				"position": symbol.position,
				"size": symbol.size,
			})
		elif child is Label:
			var label := child as Label
			state_labels.append({
				"text": label.text,
				"height": label.custom_minimum_size.y,
				"position": label.position,
				"size": label.size,
			})
	return JSON.stringify({
		"size": node.custom_minimum_size,
		"rows": rows,
		"symbols": symbols,
		"state": state_labels,
	})


func _canvas_component_ids(main: Control) -> Array[StringName]:
	var result: Array[StringName] = []
	for component_id: StringName in (main.get("component_catalog") as Dictionary):
		result.append(component_id)
	result.sort()
	return result


func _fixed_component_ids(definition: Dictionary) -> Array[StringName]:
	var result: Array[StringName] = []
	for component: LogicComponent in definition.get("components", []):
		if component.fixed_terminal:
			result.append(component.id)
	result.sort()
	return result


func _stage_two_component_ids(definition: Dictionary) -> Array[StringName]:
	var included: Dictionary[StringName, bool] = {}
	for wire: Dictionary in definition.get("hint_partial_wires", []):
		included[StringName(wire.get("from", &""))] = true
		included[StringName(wire.get("to", &""))] = true
	for component_id: Variant in definition.get("hint_context_components", []):
		included[StringName(component_id)] = true
	var result: Array[StringName] = []
	for component_id: StringName in included:
		if not component_id.is_empty():
			result.append(component_id)
	result.sort()
	return result


func _all_initial_components_used(definition: Dictionary) -> bool:
	var used: Dictionary[StringName, bool] = {}
	for wire: Dictionary in definition.get("reference_wires", []):
		used[StringName(wire.get("from", &""))] = true
		used[StringName(wire.get("to", &""))] = true
	for component: LogicComponent in definition.get("components", []):
		if not used.has(component.id):
			return false
	return true


func _expected_palette_kinds(level_id: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	match level_id:
		&"full_adder": result = [&"and", &"half_adder", &"not", &"or", &"xor"]
		&"alu": result = [&"and", &"full_adder", &"mux4", &"not", &"or", &"xor"]
		&"latch": result = [&"nor"]
		&"register": result = [&"and", &"not", &"sr_latch"]
		&"ram": result = [&"decoder1_to_2", &"mux2_word", &"register4"]
		&"cpu": result = [&"alu4", &"constant", &"control", &"mux2_word", &"ram2x4", &"register4"]
	result.sort()
	return result


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
