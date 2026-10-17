extends RefCounted
## Read-only, allowlisted snapshot for a locally exported playtest case.

const MAX_STRING := 262144
const MAX_COLLECTION := 20000
const MAX_DEPTH := 24

const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")
const CircuitLiveStateType = preload("res://src/circuit/circuit_live_state.gd")
const LogicCircuitType = preload("res://src/circuit/logic_circuit.gd")
const PrologueResultType = preload("res://src/circuit/prologue_simulation_result.gd")
const DigitalValueType = preload("res://src/circuit/digital_value.gd")
const LogicComponentType = preload("res://src/circuit/logic_component.gd")
const LogicWireType = preload("res://src/circuit/logic_wire.gd")
const SystemTraceType = preload("res://src/system_lab/system_trace.gd")
const SystemTopologyType = preload("res://src/system_lab/system_topology.gd")
const SystemPartType = preload("res://src/system_lab/system_part_spec.gd")
const SystemProgramType = preload("res://src/system_lab/system_program.gd")
const SystemReceiptType = preload("res://src/system_lab/system_run_receipt.gd")
const SimulationTraceType = preload("res://src/simulation/simulation_trace.gd")

const HOSTS := {
	"res://src/hardware_foundations/hardware_foundations.gd": "hardware",
	"res://src/system_lab/system_lab.gd": "system",
	"res://src/ui/main.gd": "locality",
	"res://src/overlap_chapter/overlap_chapter.gd": "overlap",
	"res://src/layout_chapter/layout_chapter.gd": "layout",
	"res://experiments/representation_region/region.gd": "representation",
	"res://experiments/service_plan/lab.gd": "service",
	"res://experiments/prediction/lab.gd": "prediction",
	"res://experiments/creation/workbench.gd": "creation",
	"res://src/campaign/task_tree.gd": "journey_map",
	"res://src/ui/prototype_hub.gd": "hub",
}


static func capture(tree: SceneTree) -> Dictionary:
	var coverage := {"unavailable": [], "truncated": [], "limits": {
		"string_characters": MAX_STRING, "collection_items": MAX_COLLECTION, "nesting_depth": MAX_DEPTH}}
	var scene: Node = tree.current_scene if tree != null else null
	var viewport: Window = _focused_window(tree.root) if tree != null else null
	if viewport == null and tree != null: viewport = tree.root
	var navigation: Node = tree.root.get_node_or_null("TaskNavigation") if tree != null else null
	var save: Node = tree.root.get_node_or_null("GlobalSave") if tree != null else null
	var playtest: Node = tree.root.get_node_or_null("PlaytestData") if tree != null else null
	var focus: Control = viewport.gui_get_focus_owner() if viewport != null else null
	var script_path := _script_path(scene)
	var domain: String = HOSTS.get(script_path, "unrecognized_scene")
	var result := {
		"schema": "offline_context_v1",
		"captured_at_utc": Time.get_datetime_string_from_system(true),
		"build": {"name": ProjectSettings.get_setting("application/config/name", ""),
			"version": ProjectSettings.get_setting("application/config/version", ""),
			"source_commit": ProjectSettings.get_setting("application/config/build_commit", "development"),
			"godot": Engine.get_version_info().get("string", ""), "os": OS.get_name()},
		"scene": {"path": scene.scene_file_path if scene != null else "", "script": script_path},
		"viewport": {"size": viewport.get_visible_rect().size if viewport != null else null,
			"window_mode": viewport.mode if viewport != null else null},
		"focus": {"path": str(focus.get_path()) if focus != null else "",
			"class": focus.get_class() if focus != null else "",
			"name": str(focus.name) if focus != null else ""},
		"task": _clean(playtest.get("current_task_context"), "task", coverage)
			if playtest != null and playtest.get("current_task_context") is Dictionary else {},
		"navigation": _fields(navigation, ["selected", "pending", "last_visited_task", "from_tree",
			"camera", "zoom", "camera_saved"], coverage, "navigation") if navigation != null else {},
		"playtest": _fields(playtest, ["current_visit_id", "latest_run_id", "source_kind"],
			coverage, "playtest") if playtest != null else {},
		"progress_source": "current_memory_not_disk",
		"progress": {},
		"active_domain": {"kind": domain, "state": {}},
		"coverage": coverage,
	}
	if scene == null: coverage.unavailable.append({"path": "scene", "reason": "no_current_scene"})
	if navigation == null: coverage.unavailable.append({"path": "navigation", "reason": "autoload_unavailable"})
	if playtest == null: coverage.unavailable.append({"path": "playtest", "reason": "autoload_unavailable"})
	elif not result.task.is_empty():
		result.task=_clean(playtest.call("task_feedback_context",str(result.task.get("chapter_id","")),str(result.task.get("level_id",""))),"task",coverage)
	if focus == null: coverage.unavailable.append({"path": "focus", "reason": "no_focus_owner"})
	if save != null and save.has_method("_save_snapshot"):
		result.progress = _clean(save.call("_save_snapshot"), "progress", coverage)
	else:
		coverage.unavailable.append({"path": "progress", "reason": "global_save_unavailable"})
	if scene != null:
		if domain == "unrecognized_scene":
			coverage.unavailable.append({"path": "active_domain.state", "reason": "unrecognized_scene", "script": script_path})
		else:
			result.active_domain.state = _capture_domain(scene, domain, coverage)
	return _clean(result, "context", coverage)


static func _script_path(node: Node) -> String:
	if node == null or node.get_script() == null: return ""
	return str(node.get_script().resource_path)


static func _focused_window(node: Node) -> Window:
	if node == null: return null
	for child: Node in node.get_children():
		var found: Window = _focused_window(child)
		if found != null: return found
	return node if node is Window and node.visible and node.has_focus() else null


static func _capture_domain(host: Node, kind: String, coverage: Dictionary) -> Dictionary:
	var names: Array[String] = []
	match kind:
		"hardware": names = ["current_phase", "current_level_id", "active_workbench_namespace", "active_workbench_name", "current_circuit", "current_trace", "live_state", "official_report", "prologue_live_result", "prologue_report", "prologue_runtime_state", "prologue_prior_outputs", "board_has_explicit_run", "official_passed", "playback_index", "playback_running", "clock_period_seconds", "official_sequence_active", "official_sequence_index", "official_sequence_results", "active_component", "active_connection", "hint_mode", "hint_level", "tutorial_created_wire", "tutorial_changed_input", "tutorial_removed_wire", "tutorial_reconnected_wire", "tutorial_valid_run"]
		"system": names = ["current_level_id", "current_topology", "selected_part_ids", "level_sessions", "active_mode", "draft_dirty", "locked_prediction_id", "applied_program", "applied_program_source", "latest_receipt", "latest_official_traces", "current_trace", "playback_index", "playback_running", "clock_period_seconds", "highlighted_source_line", "revealed_breakdown_receipt_signature"]
		"locality": names = ["current_level_id", "current_goal_met", "current_cache_lines", "current_bypass_cache", "current_pass_count", "current_block_lines", "selected_judgment", "run_history", "active_connections", "program_dirty", "applied_program_source", "last_executed_source", "last_run_receipt_text", "current_trace", "playback_index", "playback_running", "clock_period_seconds", "focused_instrument", "highlighted_source_line", "workspace_mode"]
		"overlap": names = ["level", "board", "armed", "runs", "trace", "playing", "trace_stale", "dirty", "hint_level", "undo_stack", "redo_stack"]
		"layout": names = ["level", "design", "runs", "case_index", "trace_filter", "stale", "building", "hint_tier", "undo_stack", "redo_stack"]
		"representation": names = ["task", "plan", "drafts", "history", "designs", "support_plans", "completed", "selected_block", "selected_run", "visible_trace", "preview_order", "session_dirty", "save_blocked", "persistent_session", "session_version", "candidate_journey", "details_expanded", "undo_stack", "redo_stack"]
		"service": names = ["task", "plan", "history", "designs", "support_plans", "selected_group", "selected_history", "selected_event_index", "active_trace", "unlocked", "session_dirty", "save_blocked", "persistent_session", "session_version", "candidate_journey", "commission_mode", "public_raw", "event_raw", "comparison_baseline", "undo_stack", "redo_stack"]
		"prediction": names = ["task", "policy", "history", "active_trace", "active_policy", "revealed", "selected_run", "candidate_journey"]
		"creation": names = ["task", "commission", "commission_model", "commission_receipts", "source_kind", "codec", "latest", "records", "comparison", "pinned_creation", "compared_creation", "creation_report", "playing", "status_text", "kept_work", "focused_cell", "focused_lane", "focused_source", "observation_anchor", "inspected_context", "inspected_counts", "sample_edit_index", "sample_edit_source", "sample_edit_selection", "sample_edit_text", "creation_intent", "prediction_recipe", "transport_comparisons", "selected_cost_comparison", "writable"]
		"journey_map": names = ["selected", "current_region"]
		"hub": names = ["candidate_journey", "completion_story_page", "settings_only"]
	var state := _fields(host, names, coverage, "active_domain.state")
	match kind:
		"hardware":
			if host.has_method("_capture_workbench_snapshot"):
				state["visible_workbench"] = _clean(host.call("_capture_workbench_snapshot"), "active_domain.state.visible_workbench", coverage)
			else: coverage.unavailable.append({"path": "active_domain.state.visible_workbench", "reason": "snapshot_method_unavailable"})
		"system":
			if host.has_method("_capture_system_editor_snapshot"):
				state["visible_editor"] = _clean(host.call("_capture_system_editor_snapshot"), "active_domain.state.visible_editor", coverage)
			else: coverage.unavailable.append({"path": "active_domain.state.visible_editor", "reason": "snapshot_method_unavailable"})
			var choices := {}
			var selectors: Dictionary = host.get("part_selectors")
			for key: Variant in selectors:
				var selector: OptionButton = selectors[key]
				if selector != null: choices[str(key)] = selector.get_selected_id()
			state["visible_part_choices"] = choices
			var order: OptionButton = host.get("order_selector")
			state["visible_order_choice"] = order.get_selected_id() if order != null else null
		"locality":
			state["visible_graph"] = _graph(host.get("graph"), coverage, "active_domain.state.visible_graph")
			var inputs := []
			for input: SpinBox in host.get("debug_inputs"):
				inputs.append(input.value if input != null else null)
			state["visible_debug_inputs"] = inputs
		"overlap":
			state["visible_graph"] = _graph(host.get("graph"), coverage, "active_domain.state.visible_graph")
		"prediction":
			for key: String in ["rule", "confidence", "lookahead", "cooldown"]:
				var control: OptionButton = host.get(key)
				state["visible_" + key] = control.get_selected_id() if control != null else null
				if control == null: coverage.unavailable.append({"path": "active_domain.state.visible_" + key, "reason": "control_unavailable"})
		"representation":
			state["visible_split_at"] = _spin_value(host.get("split_at"))
			state["visible_recorded_order"] = _option_id(host.get("order_choice"))
		"service":
			for key: String in ["split_at", "move_to", "slots"]:
				state["visible_" + key] = _spin_value(host.get(key))
		"creation":
			var session: Object = host.get("session")
			if session != null:
				state["session"] = _fields(session, ["data", "dirty", "error", "prediction", "generated", "last_transport", "digest", "_frozen", "_prediction_machine", "_prediction_events", "_transport_model", "_prediction_model", "_transport_runs", "_prediction_runs", "_draft_anchor", "undo_stack", "redo_stack"], coverage, "active_domain.state.session")
			else: coverage.unavailable.append({"path": "active_domain.state.session", "reason": "session_unavailable"})
			state["visible_name"] = _control_text(host.get("name_input"), coverage, "active_domain.state.visible_name")
	if kind in ["system", "locality", "overlap"]:
		state["visible_program_text"] = _control_text(host.get("editor"), coverage, "active_domain.state.visible_program_text")
	if kind == "layout": state["visible_scheme_name"] = _control_text(host.get("scheme_name"), coverage, "active_domain.state.visible_scheme_name")
	if kind == "journey_map":
		state["search_query"] = _control_text(host.get("search"), coverage, "active_domain.state.search_query")
		var canvas: Control = host.get("canvas")
		state["canvas"] = _fields(canvas, ["pan", "magnification", "query", "hovered_key"], coverage, "active_domain.state.canvas") if canvas != null else {}
	return state


static func _spin_value(value: Variant) -> Variant:
	return value.value if value is SpinBox else null


static func _option_id(value: Variant) -> Variant:
	return value.get_selected_id() if value is OptionButton else null


static func _control_text(control: Variant, coverage: Dictionary, path: String) -> Variant:
	if control is TextEdit or control is LineEdit: return _clean(control.text, path, coverage)
	coverage.unavailable.append({"path": path, "reason": "control_unavailable"})
	return null


static func _graph(graph: Variant, coverage: Dictionary, path: String) -> Dictionary:
	if not graph is GraphEdit:
		coverage.unavailable.append({"path": path, "reason": "graph_unavailable"})
		return {}
	var positions := {}
	for child: Node in graph.get_children():
		if child is GraphNode: positions[str(child.name)] = child.position_offset
	return _clean({"connections": graph.get_connection_list(), "positions": positions,
		"scroll_offset": graph.scroll_offset, "zoom": graph.zoom}, path, coverage)


static func _fields(source: Object, names: Array[String], coverage: Dictionary, path: String) -> Dictionary:
	var result := {}
	if source == null: return result
	var available := {}
	for property: Dictionary in source.get_property_list(): available[str(property.name)] = true
	for name: String in names:
		if available.has(name): result[name] = _clean(source.get(name), path + "." + name, coverage)
		else: coverage.unavailable.append({"path": path + "." + name, "reason": "field_unavailable"})
	return result


static func _clean(value: Variant, path: String, coverage: Dictionary, depth: int = 0) -> Variant:
	if depth > MAX_DEPTH:
		coverage.truncated.append({"path": path, "reason": "nesting_depth", "limit": MAX_DEPTH})
		return {"truncated": "nesting_depth"}
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT: return value
		TYPE_STRING, TYPE_STRING_NAME:
			var text_value := str(value)
			if text_value.length() <= MAX_STRING: return text_value
			coverage.truncated.append({"path": path, "reason": "string_characters", "actual": text_value.length(), "limit": MAX_STRING})
			return text_value.substr(0, MAX_STRING)
		TYPE_VECTOR2, TYPE_VECTOR2I: return {"x": value.x, "y": value.y}
		TYPE_COLOR: return {"r": value.r, "g": value.g, "b": value.b, "a": value.a}
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_BYTE_ARRAY:
			var output: Array = []
			var size: int = value.size()
			if size > MAX_COLLECTION: coverage.truncated.append({"path": path, "reason": "collection_items", "actual": size, "limit": MAX_COLLECTION})
			for index: int in range(mini(size, MAX_COLLECTION)):
				output.append(_clean(value[index], "%s[%d]" % [path, index], coverage, depth + 1))
			return output
		TYPE_DICTIONARY:
			var output := {}
			var keys: Array = value.keys()
			keys.sort_custom(func(a: Variant, b: Variant) -> bool: return str(a) < str(b))
			if keys.size() > MAX_COLLECTION: coverage.truncated.append({"path": path, "reason": "collection_items", "actual": keys.size(), "limit": MAX_COLLECTION})
			for index: int in range(mini(keys.size(), MAX_COLLECTION)):
				var key: Variant = keys[index]
				output[str(key)] = _clean(value[key], path + "." + str(key), coverage, depth + 1)
			return output
		TYPE_OBJECT:
			var known: Variant = _known_object(value)
			if known != null: return _clean(known, path, coverage, depth + 1)
			var script: Script = value.get_script() if value is Object else null
			var script_name: String = script.resource_path if script != null else value.get_class()
			coverage.unavailable.append({"path": path, "reason": "unsupported_object", "type": script_name})
			return {"unavailable": "unsupported_object", "type": script_name}
		_:
			coverage.unavailable.append({"path": path, "reason": "unsupported_variant", "type": type_string(typeof(value))})
			return {"unavailable": "unsupported_variant", "type": type_string(typeof(value))}


static func _known_object(value: Object) -> Variant:
	if value is LogicComponentType or value is LogicWireType or value is DigitalValueType:
		return value.to_dictionary()
	if value is LogicCircuitType:
		return {"components": value.components, "wires": value.wires}
	if value is CircuitTraceType:
		return {"events": value.events, "outputs": value.outputs, "errors": value.errors,
			"error_specs": value.error_specs, "metrics": value.metrics,
			"topology_signature": value.topology_signature, "input_values": value.input_values}
	if value is CircuitLiveStateType:
		return {"topology_signature": value.topology_signature, "input_values": value.input_values,
			"input_states": value.input_states, "output_states": value.output_states,
			"wire_states": value.wire_states, "output_ticks": value.output_ticks,
			"component_ticks": value.component_ticks, "observed_states": value.observed_states,
			"evaluation_order": value.evaluation_order, "cyclic_components": value.cyclic_components,
			"shorted_inputs": value.shorted_inputs, "incoming_by_input": value.incoming_by_input,
			"outgoing_by_output": value.outgoing_by_output, "valid_wires": value.valid_wires,
			"errors": value.errors, "error_specs": value.error_specs}
	if value is PrologueResultType:
		return {"topology_signature": value.topology_signature, "external_inputs": value.external_inputs,
			"input_values": value.input_values, "output_values": value.output_values,
			"wire_values": value.wire_values, "observed_values": value.observed_values,
			"runtime_state": value.runtime_state, "events": value.events, "errors": value.errors,
			"error_specs": value.error_specs, "settle_ticks": value.settle_ticks, "settled": value.settled}
	if value is SystemPartType:
		return {"id": value.id, "kind": value.kind, "display_name": value.display_name,
			"word_bits": value.word_bits, "compute_cycles": value.compute_cycles,
			"access_cycles": value.access_cycles, "bandwidth_bits_per_cycle": value.bandwidth_bits_per_cycle,
			"hardware_cost": value.hardware_cost, "source_signature": value.source_signature,
			"metadata": value.metadata}
	if value is SystemTopologyType:
		return {"parts": value.parts, "connections": value.connections}
	if value is SystemProgramType:
		return {"source": value.source, "errors": value.errors, "error_specs": value.error_specs}
	if value is SystemTraceType:
		return {"events": value.events, "metrics": value.metrics, "output_data": value.output_data,
			"expected_output": value.expected_output, "passed": value.passed,
			"program_source": value.program_source, "program_signature": value.program_signature,
			"topology_signature": value.topology_signature, "test_name": value.test_name}
	if value is SystemReceiptType:
		return {"level_id": value.level_id, "program_signature": value.program_signature,
			"topology_signature": value.topology_signature, "test_set_signature": value.test_set_signature,
			"part_ids": value.part_ids, "metrics": value.metrics, "case_metrics": value.case_metrics,
			"trace_signatures": value.trace_signatures, "passed_cases": value.passed_cases,
			"total_cases": value.total_cases, "all_passed": value.all_passed,
			"diagnosed_bottleneck": value.diagnosed_bottleneck}
	if value is SimulationTraceType:
		var result := {"events": value.events, "metrics": value.metrics, "result_value": value.result_value,
			"expected_value": value.expected_value, "passed": value.passed,
			"cache_capacity_lines": value.cache_capacity_lines, "test_name": value.test_name,
			"loop_order": value.loop_order, "program_source": value.program_source}
		if value is LayoutRun:
			result["output_values"] = value.output_values
			result["expected_values"] = value.expected_values
			result["source_map"] = value.source_map
			result["scratch_maps"] = value.scratch_maps
			result["recipe_signature"] = value.recipe_signature
			result["case_signature"] = value.case_signature
			result["model_version"] = value.model_version
		return result
	if value is CircuitEvent or value is PrologueEvent or value is SystemEvent or value is SimulationEvent:
		return value.to_dictionary()
	return null
