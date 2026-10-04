extends SceneTree
const C = preload("res://src/circuit/logic_component.gd")
const DV = preload("res://src/circuit/digital_value.gd")
const Result = preload("res://src/circuit/prologue_simulation_result.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message); push_error(message)
func run() -> void:
	root.get_node("GameMode").set_mode(&"test")
	var hardware: Control = load("res://src/hardware_foundations/hardware_foundations.tscn").instantiate()
	root.add_child(hardware)
	for frame: int in 4: await process_frame
	hardware._start_prologue_level(&"alarm",false)
	for locale: String in ["en","zh_CN"]:
		TranslationServer.set_locale(locale)
		check(hardware._storage_action_text({&"CLEAR":0,&"FAULT":1}) == hardware._t(&"hardware.storage.action.set"),"Alarm FAULT must say SET " + locale)
		check(hardware._storage_action_text({&"CLEAR":1,&"FAULT":1}) == hardware._t(&"hardware.storage.action.reset"),"Alarm CLEAR has priority " + locale)
		check(hardware._storage_action_text({&"CLEAR":0,&"FAULT":0}) == hardware._t(&"hardware.storage.action.hold"),"Alarm idle HOLD " + locale)
		var result := Result.new()
		result.observed_values[&"ALARM"] = DV.high()
		check(hardware._storage_state_text(result).contains("ALARM=1"),"Alarm uses observed result " + locale)
		result.observed_values.clear()
		check(not hardware._storage_state_text(result).contains("ALARM=0"),"Missing observation never manufactures zero " + locale)
	# Explicit synthetic topology fixtures, never campaign completion evidence.
	hardware._apply_workbench_snapshot(hardware._build_hint_snapshot(3))
	hardware._create_graph(); hardware._build_component_nodes(); hardware._load_pending_workbench_wires()
	var circuit: LogicCircuit = hardware._circuit_from_graph()
	var report: Dictionary = hardware.prologue_simulator.run_sequence(circuit, hardware.current_level_definition.official_steps)
	check(report.passed and report.steps.size() == 64,"Alarm real official sequence retains 64 passing cases")
	var previous: String = hardware._storage_initial_state_text()
	for i: int in report.steps.size():
		hardware.official_sequence_index = i
		hardware.official_sequence_previous_storage_state = previous
		hardware.official_sequence_pending_result = {"step":report.steps[i]}
		hardware._reveal_prologue_official_case()
		var current: String = hardware._storage_state_text(report.steps[i].result)
		check(hardware.prologue_case_labels[i].text.contains(previous) and hardware.prologue_case_labels[i].text.contains(current),"Case row chains real state " + str(i))
		previous = current
	var prior: Dictionary = {}
	var incoming: LogicWire
	for wire: LogicWire in circuit.wires:
		if wire.to_component == &"ALARM": incoming = wire
	prior[Result.output_key(incoming.from_component,incoming.from_port)] = DV.high()
	hardware._prepare_storage_playback_state({},prior)
	check(hardware.storage_state_label.text.contains("ALARM=1"),"Prior uses exact connected source output")
	hardware._prepare_storage_playback_state({},{})
	check(hardware.storage_state_label.text.contains("ALARM=—"),"Missing prior is not fabricated as reset zero")
	var result := Result.new()
	result.observed_values[&"ALARM"] = DV.low()
	hardware._play_prologue_events(report.events,result,{},prior)
	check(hardware.storage_state_label.text.contains("ALARM=1"),"Playback retains real previous committed observation")
	hardware._finish_playback()
	check(hardware.storage_state_label.text.contains("ALARM=0"),"Playback end publishes actual current observation")
	hardware._toggle_playback()
	check(hardware.storage_state_label.text.contains("ALARM=1"),"Replay restores prior observation")
	hardware._finish_playback(); hardware._step_playback()
	check(hardware.storage_state_label.text.contains("ALARM=1"),"Step replay restores prior observation")
	result.observed_values[&"ALARM"] = DV.high_z()
	hardware._update_storage_monitor(result)
	check(hardware.storage_state_label.text.contains(DV.high_z().display_text()),"Real high impedance is preserved")
	result.errors.append("synthetic invalid circuit")
	result.observed_values.clear()
	hardware._play_prologue_events([],result,{},prior)
	check(hardware.storage_state_label.text.contains("ALARM=—"),"Blocked missing-result playback never keeps stale known state")
	result.observed_values[&"ALARM"] = DV.high()
	hardware._play_prologue_events([],result,{},prior)
	check(hardware.storage_state_label.text.contains("ALARM=1") and hardware.storage_state_label.text.begins_with(hardware._t(&"exploration.alarm.observed",[""])),"Blocked observed data is labeled observed, not committed")
	var snapshot: Dictionary = hardware._build_hint_snapshot(3)
	for item: Dictionary in snapshot.components:
		if String(item.id) == "MEMORY": item.id = "PLAYER_LATCH"
	for wire: Dictionary in snapshot.wires:
		if String(wire.from) == "MEMORY": wire.from = "PLAYER_LATCH"
		if String(wire.to) == "MEMORY": wire.to = "PLAYER_LATCH"
		if String(wire.to) == "ALARM": wire.from_port = 1
	hardware._apply_workbench_snapshot(snapshot)
	hardware._create_graph(); hardware._build_component_nodes(); hardware._load_pending_workbench_wires()
	prior = {Result.output_key(&"PLAYER_LATCH",0):DV.low(),Result.output_key(&"PLAYER_LATCH",1):DV.high()}
	hardware._prepare_storage_playback_state({},prior)
	check(hardware.storage_state_label.text.contains("ALARM=1"),"Renamed latch and nonzero output port retain exact prior evidence")
	var junction := C.new(&"PLAYER_ROUTE",C.KIND_JUNCTION,"Route")
	snapshot.components.append(junction.to_dictionary())
	for wire: Dictionary in snapshot.wires:
		if String(wire.to) == "ALARM": wire.to = "PLAYER_ROUTE"
	snapshot.wires.append({"from":"PLAYER_ROUTE","from_port":0,"to":"ALARM","to_port":0})
	hardware._apply_workbench_snapshot(snapshot)
	hardware._create_graph(); hardware._build_component_nodes(); hardware._load_pending_workbench_wires()
	prior[Result.output_key(&"PLAYER_ROUTE",0)] = DV.high_z()
	hardware._prepare_storage_playback_state({},prior)
	check(hardware.storage_state_label.text.contains("ALARM="+DV.high_z().display_text()),"Routing takes its own prior evidence, not an upstream inferred state")
	hardware.queue_free(); await process_frame
	var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
	root.add_child(main)
	for frame: int in 4: await process_frame
	for locale: String in ["en","zh_CN"]:
		TranslationServer.set_locale(locale)
		main._start_level(&"two_orders")
		main._run_official(); await process_frame
		check(main.parts_summary_label.text.contains("24"),"Parts exposes actual budget " + locale)
		check(main.latest_receipt.all_passed,"Baseline output correct " + locale)
		check(main.test_status_label.get_theme_color("font_color") == main.WARNING,"Baseline over-cycle summary warns " + locale)
		var budget: Label = main.official_result_box.get_child(0).get_node_or_null("OrderBudget")
		check(budget != null,"Separate visible order target " + locale)
		main._stop_playback()
		set_parts(main,{&"cpu":&"cpu_fast",&"ram":&"ram_slow",&"bus":&"bus_4"})
		main._run_official(); await process_frame
		check(main.latest_receipt.metrics.hardware_cost == 24 and main.test_status_label.get_theme_color("font_color") == main.GOOD,"Cost boundary 24 and 62 cycles qualify " + locale)
		var signature: String = main.latest_receipt.canonical_signature()
		main._refresh_order_result()
		check(main.latest_receipt.canonical_signature() == signature,"Presentation preserves receipt " + locale)
		main._stop_playback(); main._select_order(1)
		set_parts(main,{&"cpu":&"cpu_eco",&"ram":&"ram_fast",&"bus":&"bus_4"})
		main._run_official(); await process_frame
		check(main.test_status_label.get_theme_color("font_color") == main.GOOD,"Independent move order qualifies " + locale)
		check(main.official_result_box.get_child(0).get_node_or_null("OrderBudget") != null,"16-output compact case keeps visible limits " + locale)
		check(root.get_node("SystemChapter").completed_levels().get(&"two_orders",false),"Synthetic test earned both orders " + locale)
		main._stop_playback(); main._select_order(0)
		set_parts(main,{&"cpu":&"cpu_balanced",&"ram":&"ram_balanced",&"bus":&"bus_4"})
		main._run_official(); await process_frame
		check(main.latest_receipt.all_passed and main.latest_receipt.case_metrics[0].total_cycles == 86 and main.test_status_label.get_theme_color("font_color") == main.WARNING,"Historical complete does not greenlight failed current rerun " + locale)
		check(root.get_node("SystemChapter").completed_levels().get(&"two_orders",false),"Historical completion remains retained " + locale)
		main._stop_playback()
		set_parts(main,{&"cpu":&"cpu_fast",&"ram":&"ram_fast",&"bus":&"bus_8"})
		main._run_official(); await process_frame
		check(main.latest_receipt.all_passed and main.latest_receipt.metrics.hardware_cost == 39 and main.test_status_label.get_theme_color("font_color") == main.WARNING,"Fast over-cost order warns " + locale)
		main._stop_playback()
		main.editor.text = "acc = 0\nstore(OUTPUT[0], acc)"
		main._apply_program(); main._run_official(); await process_frame
		var debug_text: String = main.test_status_label.text
		main._refresh_order_result()
		check(not main.latest_receipt.all_passed and main.test_status_label.text == debug_text,"Wrong-output custom debug stays unchanged " + locale)
		main._stop_playback()
	main.queue_free(); await process_frame
	print("PASS: alarm and order feedback" if failures.is_empty() else "FAIL: alarm and order feedback")
	quit(0 if failures.is_empty() else 1)

func set_parts(main: Control, parts: Dictionary) -> void:
	for kind: StringName in parts:
		var selector: OptionButton = main.part_selectors[kind]
		for i: int in selector.item_count:
			if selector.get_item_metadata(i) == parts[kind]:
				main._on_part_selected(i,kind)
				break
