extends Control

const PerformanceTask = preload("res://src/demo/demo_performance.gd")
const Parser = preload("res://src/simulation/dsl_parser.gd")
const Fullscreen = preload("res://src/ui/fullscreen_button.gd")
const Handbook = preload("res://src/ui/terminology_handbook.gd")
const Foundations = preload("res://src/demo/demo_foundations.gd")
const CircuitBoard = preload("res://src/demo/demo_circuit_board.gd")

var task_id := "d1_cpu"
var stage := 0
var design: Dictionary = {}
var initial_run: Dictionary = {}
var latest_run: Dictionary = {}
var best_run: Dictionary = {}
var completed := false
var hint_stage := 0
var updating := false
var title_label: Label
var goal_label: Label
var status_label: Label
var summary_label: Label
var comparison_label: Label
var specifications: RichTextLabel
var hint_label: Label
var editor: CodeEdit
var address_label: Label
var memory_grid: GridContainer
var data_cells: Array[Label] = []
var selectors: Dictionary = {}
var parts_box: VBoxContainer
var device_row: HBoxContainer
var device_labels: Dictionary = {}
var events_list: ItemList
var event_detail: Label
var run_button: Button
var continue_button: Button
var help_button: Button
var event_indices: Array[int] = []
var event_cursor := -1
var history: Array[Dictionary] = []
var redo_history: Array[Dictionary] = []
var handbook: Control
var circuit_board: Control
var program_content: Control
var replay_button: Button
var replay_speed: OptionButton
var replay_position: HSlider
var replay_controls: HBoxContainer
var detail_scroll: ScrollContainer
var replaying := false
var replay_elapsed := 0.0
var performance_actions: Array[Button] = []


func _ready() -> void:
	_build_interface()
	load_task(DemoProgress.state()["current"], int(DemoProgress.state()["stage"]))


func text(key: String, args: Array = []) -> String:
	return Localization.text(StringName(key), args)


func _build_interface() -> void:
	var theme_value := Theme.new()
	theme_value.default_font_size = 19
	theme = theme_value
	var background := ColorRect.new()
	background.color = Color("0b1320")
	background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	background.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 12)
	margin.add_child(page)
	var toolbar := HBoxContainer.new()
	page.add_child(toolbar)
	_button(toolbar, "demo.map", _return_to_map)
	title_label = _label(toolbar, "", 25)
	title_label.size_flags_horizontal = SIZE_EXPAND_FILL
	_button(toolbar, "demo.undo", undo)
	_button(toolbar, "demo.redo", redo)
	_button(toolbar, "demo.help", _open_handbook)
	var full := Fullscreen.new()
	toolbar.add_child(full)
	goal_label = _label(page, "")
	goal_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var workspace := HSplitContainer.new()
	workspace.size_flags_vertical = SIZE_EXPAND_FILL
	workspace.split_offset = 1010
	page.add_child(workspace)
	var main := VBoxContainer.new()
	main.size_flags_horizontal = SIZE_EXPAND_FILL
	main.size_flags_stretch_ratio = 2.3
	workspace.add_child(main)
	device_row = HBoxContainer.new()
	device_row.custom_minimum_size.y = 94
	main.add_child(device_row)
	var content := HSplitContainer.new()
	program_content = content
	content.size_flags_vertical = SIZE_EXPAND_FILL
	main.add_child(content)
	circuit_board = CircuitBoard.new()
	circuit_board.size_flags_vertical = SIZE_EXPAND_FILL
	main.add_child(circuit_board)
	circuit_board.design_changed.connect(_circuit_changed)
	circuit_board.inspected.connect(_inspect_component)
	var program_box := VBoxContainer.new()
	program_box.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_child(program_box)
	_label(program_box, text("demo.program"), 20)
	editor = CodeEdit.new()
	editor.name = "Program"
	editor.custom_minimum_size = Vector2(390, 180)
	editor.size_flags_vertical = SIZE_EXPAND_FILL
	editor.gutters_draw_line_numbers = true
	editor.indent_use_spaces = true
	editor.indent_size = 4
	editor.add_theme_font_size_override("font_size", 19)
	editor.add_theme_color_override("font_readonly_color", Color("bcc9d9"))
	editor.text_changed.connect(_program_changed)
	program_box.add_child(editor)
	var data_box := VBoxContainer.new()
	data_box.custom_minimum_size.x = 360
	data_box.size_flags_horizontal = SIZE_EXPAND_FILL
	content.add_child(data_box)
	_label(data_box, text("demo.data"), 20)
	memory_grid = GridContainer.new()
	memory_grid.columns = 4
	data_box.add_child(memory_grid)
	for index: int in range(16):
		var cell := _label(memory_grid, "", 18)
		cell.custom_minimum_size = Vector2(85, 46)
		cell.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		data_cells.append(cell)
	address_label = _label(data_box, "", 18)
	address_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var context_scroll := ScrollContainer.new()
	context_scroll.custom_minimum_size.x = 355
	context_scroll.size_flags_horizontal = SIZE_EXPAND_FILL
	workspace.add_child(context_scroll)
	var context := VBoxContainer.new()
	context.size_flags_horizontal = SIZE_EXPAND_FILL
	context.add_theme_constant_override("separation", 10)
	context_scroll.add_child(context)
	_label(context, text("demo.specs"), 22)
	specifications = RichTextLabel.new()
	specifications.fit_content = true
	specifications.selection_enabled = true
	specifications.custom_minimum_size.y = 180
	context.add_child(specifications)
	parts_box = VBoxContainer.new()
	context.add_child(parts_box)
	help_button = _button(context, "demo.hint", _show_hint)
	hint_label = _label(context, "", 18)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var result_panel := PanelContainer.new()
	page.add_child(result_panel)
	var result_box := VBoxContainer.new()
	result_panel.add_child(result_box)
	var run_row := HBoxContainer.new()
	result_box.add_child(run_row)
	run_button = _button(run_row, "demo.run", run_current)
	run_button.name = "RunCurrent"
	run_button.add_theme_color_override("font_color", Color("76efbb"))
	status_label = _label(run_row, "", 18)
	status_label.size_flags_horizontal = SIZE_EXPAND_FILL
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	continue_button = _button(run_row, "demo.continue", _continue_task)
	continue_button.name = "Continue"
	summary_label = _label(result_box, "", 20)
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	comparison_label = _label(result_box, "", 17)
	comparison_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_scroll = ScrollContainer.new()
	detail_scroll.custom_minimum_size.y = 110
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	result_box.add_child(detail_scroll)
	var detail_box := VBoxContainer.new()
	detail_box.size_flags_horizontal = SIZE_EXPAND_FILL
	detail_scroll.add_child(detail_box)
	replay_controls = HBoxContainer.new()
	detail_box.add_child(replay_controls)
	replay_button = _button(replay_controls, "demo.play", _toggle_replay)
	replay_speed = OptionButton.new()
	for multiplier: int in [1, 2, 4]:
		replay_speed.add_item("%d×" % multiplier)
		replay_speed.set_item_metadata(replay_speed.item_count - 1, multiplier)
	replay_speed.tooltip_text = text("demo.replay_speed")
	replay_controls.add_child(replay_speed)
	replay_position = HSlider.new()
	replay_position.size_flags_horizontal = SIZE_EXPAND_FILL
	replay_position.step = 1
	replay_position.tooltip_text = text("demo.replay_position")
	replay_position.value_changed.connect(func(value: float) -> void:
		_stop_replay()
		_select_event(int(value))
	)
	replay_controls.add_child(replay_position)
	var detail_row := HBoxContainer.new()
	detail_box.add_child(detail_row)
	_button(detail_row, "demo.events", _toggle_events)
	performance_actions.append(_button(detail_row, "demo.next_event", _next_event))
	performance_actions.append(_button(detail_row, "demo.baseline", _inspect_baseline))
	performance_actions.append(_button(detail_row, "demo.wait", _inspect_wait))
	event_detail = _label(detail_row, "", 17)
	event_detail.size_flags_horizontal = SIZE_EXPAND_FILL
	event_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	events_list = ItemList.new()
	events_list.custom_minimum_size.y = 125
	events_list.item_selected.connect(_select_event)
	detail_box.add_child(events_list)
	events_list.hide()
	handbook = Handbook.new()
	add_child(handbook)
	handbook.entry_button.hide()
	handbook.entry_button.visibility_changed.connect(func() -> void:
		if handbook.entry_button.visible:
			handbook.entry_button.call_deferred("hide")
	)


func _label(parent: Node, value: String, font_size: int = 19) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Node, key: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text(key)
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func load_task(id: String, task_stage: int = 0) -> void:
	if not DemoProgress.enter(id, task_stage):
		return
	task_id = id
	_stop_replay()
	stage = task_stage
	var foundation := id.begins_with("dp_")
	design = DemoProgress.draft(id, stage)
	if design.is_empty():
		design = Foundations.initial(id, stage, DemoProgress.accepted_design(id, stage - 1) if stage > 0 else {}) if foundation else PerformanceTask.initial(id, stage)
	initial_run = {} if foundation else PerformanceTask.baseline(id, stage)
	latest_run = {}
	best_run = {}
	var accepted: Dictionary = DemoProgress.accepted_design(id, stage)
	if not foundation and not accepted.is_empty():
		var restored: Dictionary = DemoProgress.verify(id, stage, accepted)
		if restored.get("complete", false):
			best_run = restored
	completed = DemoProgress.stage_complete(id, stage)
	hint_stage = 0
	history.clear()
	redo_history.clear()
	hint_label.text = ""
	events_list.clear()
	events_list.hide()
	detail_scroll.scroll_vertical = 0
	event_detail.text = ""
	event_indices.clear()
	program_content.visible = not foundation
	circuit_board.visible = foundation
	device_row.visible = not foundation
	replay_controls.visible = not foundation
	replay_button.disabled = true
	replay_position.editable = false
	for action: Button in performance_actions:
		action.visible = not foundation
	updating = true
	if foundation:
		circuit_board.load_design(design)
	else:
		editor.text = design.get("source", "")
		editor.editable = PerformanceTask.editable_program(id)
	updating = false
	title_label.text = text("demo.task." + id + ".title")
	if DemoProgress.stages(id) > 1:
		title_label.text += " · " + text("demo.stage", [stage + 1, DemoProgress.stages(id)])
	goal_label.text = text("demo.task." + id + ".goal")
	specifications.text = text("demo.task." + id + ".specs")
	if DemoProgress.stages(id) > 1:
		specifications.text += "\n\n" + text("demo.task." + id + ".stage" + str(stage))
	_rebuild_choices()
	if not foundation:
		_refresh_machine()
		_refresh_preview()
	status_label.text = text("demo.ready")
	_refresh_result()
	DemoProgress.remember(id, stage, design)
	PlaytestData.level_started(&"demo", StringName(task_id))


func _circuit_changed(updated: Dictionary) -> void:
	var semantic_change: bool = design.get("circuit", {}) != updated.get("circuit", {})
	_push_history()
	design = updated
	DemoProgress.remember(task_id, stage, design)
	if semantic_change:
		_mark_dirty()
	PlaytestData.record_modification(&"demo", StringName(task_id), &"topology" if semantic_change else &"layout")


func _inspect_component(part: LogicComponent) -> void:
	var ports: Array[String] = []
	for index: int in range(part.input_count()):
		ports.append("→ %s · %d bit" % [part.input_port_name(index), part.input_width(index)])
	for index: int in range(part.output_count()):
		ports.append("← %s · %d bit" % [part.output_port_name(index), part.output_width(index)])
	hint_label.text = part.display_name + " · " + text("demo.standard") + "\n" + text("demo.component." + String(part.kind)) + "\n" + "\n".join(ports)


func _rebuild_choices() -> void:
	for child: Node in parts_box.get_children():
		child.free()
	selectors.clear()
	var allowed: Dictionary = {} if task_id.begins_with("dp_") else PerformanceTask.choices(task_id, stage)
	for key: String in allowed:
		_label(parts_box, text("demo.part." + key), 18)
		var selector := OptionButton.new()
		for value: Variant in allowed[key]:
			selector.add_item(choice_text(key, value))
			selector.set_item_metadata(selector.item_count - 1, value)
			if value == design[key]:
				selector.select(selector.item_count - 1)
		selector.item_selected.connect(func(index: int) -> void: change_option(key, selector.get_item_metadata(index)))
		parts_box.add_child(selector)
		selectors[key] = selector


func choice_text(key: String, value: Variant) -> String:
	if key in ["cpu", "ram", "bus"]:
		return text("demo.part." + String(value))
	if key == "bypass":
		return text("demo.direct" if bool(value) else "demo.cached")
	if key == "cache":
		return text("demo.cache_lines", [value, PerformanceTask.LocalCore.CACHE_COSTS[int(value)]])
	return text("demo.group.all") if int(value) == 0 else text("demo.group.lines", [value])


func change_option(key: String, value: Variant) -> void:
	_push_history()
	design[key] = value
	if selectors.has(key):
		var selector: OptionButton = selectors[key]
		for index: int in range(selector.item_count):
			if selector.get_item_metadata(index) == value:
				selector.select(index)
	_mark_dirty()
	_refresh_machine()
	_refresh_preview()
	PlaytestData.record_modification(&"demo", StringName(task_id), StringName(key))


func _program_changed() -> void:
	if updating:
		return
	_push_history()
	design["source"] = editor.text
	_mark_dirty()
	_refresh_preview()
	PlaytestData.record_modification(&"demo", StringName(task_id), &"program")


func _mark_dirty() -> void:
	_stop_replay()
	_clear_event_focus()
	DemoProgress.remember(task_id, stage, design)
	status_label.text = text("demo.draft")
	if not DemoProgress.warning.is_empty():
		status_label.text += " " + text(DemoProgress.warning)
	_refresh_result()


func _push_history() -> void:
	history.append(design.duplicate(true))
	if history.size() > 80:
		history.pop_front()
	redo_history.clear()


func undo() -> void:
	if history.is_empty():
		return
	redo_history.append(design.duplicate(true))
	design = history.pop_back()
	_restore_design_ui()


func redo() -> void:
	if redo_history.is_empty():
		return
	history.append(design.duplicate(true))
	design = redo_history.pop_back()
	_restore_design_ui()


func _restore_design_ui() -> void:
	if task_id.begins_with("dp_"):
		circuit_board.load_design(design)
		_mark_dirty()
		return
	updating = true
	editor.text = design["source"]
	updating = false
	_rebuild_choices()
	_refresh_preview()
	_refresh_machine()
	_mark_dirty()


func run_current() -> void:
	_stop_replay()
	var candidate: Dictionary = DemoProgress.verify(task_id, stage, design.duplicate(true))
	if not candidate.get("valid", false):
		status_label.text = text(candidate["error"])
		if candidate.has("diagnostics") and not candidate["diagnostics"].is_empty():
			var diagnostic: Dictionary = candidate["diagnostics"][0]
			status_label.text += " " + text(diagnostic["key"], diagnostic["args"])
		return
	latest_run = candidate
	design = candidate["design"].duplicate(true)
	DemoProgress.remember(task_id, stage, design)
	if task_id.begins_with("dp_"):
		completed = completed or candidate["complete"]
		if candidate["complete"]:
			DemoProgress.record_run(candidate)
		status_label.text = text("demo.success" if candidate["complete"] else "demo.wrong")
		_refresh_result()
		_show_sequence(candidate)
		return
	if candidate["passed"] and (best_run.is_empty() or _better(candidate, best_run)):
		best_run = candidate
	var just_completed: bool = not completed and candidate["complete"]
	completed = completed or candidate["complete"]
	status_label.text = text("demo.success" if candidate["complete"] else ("demo.target_pending" if candidate["passed"] else "demo.wrong"))
	if not candidate.get("failure_reason", "").is_empty():
		status_label.text += " " + text(candidate["failure_reason"])
	PlaytestData.record_official_run(&"demo", StringName(task_id), candidate["passed"], { "content_version": PerformanceTask.VERSION, "total_cycles": candidate["metrics"]["total_cycles"]})
	if candidate["complete"] and candidate == best_run:
		DemoProgress.record_run(candidate)
	if just_completed:
		PlaytestData.level_completed(&"demo", StringName(task_id))
	_refresh_result()
	_populate_events(candidate)


func _better(left: Dictionary, right: Dictionary) -> bool:
	var a: Dictionary = left["metrics"]
	var b: Dictionary = right["metrics"]
	return a["total_cycles"] < b["total_cycles"] or (a["total_cycles"] == b["total_cycles"] and a["hardware_cost"] < b["hardware_cost"])


func _refresh_result() -> void:
	continue_button.disabled = not completed
	if task_id.begins_with("dp_"):
		summary_label.text = text("demo.foundation_result", [latest_run.get("case_count", 0)]) if not latest_run.is_empty() else text("demo.foundation_ready")
		comparison_label.text = text("demo.foundation_boundary")
		return
	var base: Dictionary = initial_run.get("metrics", {})
	comparison_label.text = text("demo.initial_summary", [base.get("total_cycles", 0), base.get("compute_cycles", 0), base.get("wait_cycles", 0)])
	if latest_run.is_empty():
		summary_label.text = text("demo.no_run")
		if not best_run.is_empty():
			comparison_label.text += "   " + text("demo.restored_best", [best_run["metrics"]["total_cycles"], best_run["metrics"]["hardware_cost"]])
		return
	var metrics: Dictionary = latest_run["metrics"]
	summary_label.text = text("demo.result", [metrics["total_cycles"], metrics["compute_cycles"], metrics["wait_cycles"], metrics["hardware_cost"], latest_run["case_count"]])
	var trace: Variant = latest_run["traces"][latest_run.get("display_case", 0)]
	summary_label.text += "\n" + text("demo.output", [str(trace.output_data) if trace is SystemTrace else str(trace.result_value), str(trace.expected_output) if trace is SystemTrace else str(trace.expected_value)])
	comparison_label.text += "   " + text("demo.delta", [int(base["total_cycles"]) - int(metrics["total_cycles"])])
	if not best_run.is_empty():
		comparison_label.text += "   " + text("demo.best", [best_run["metrics"]["total_cycles"], best_run["metrics"]["hardware_cost"]])
	if PerformanceTask.is_system(task_id):
		comparison_label.text += "\n" + text("demo.system_breakdown", [metrics["ram_service_cycles"], metrics["bus_transfer_cycles"], metrics["bus_control_cycles"]])
	else:
		comparison_label.text += "\n" + text("demo.local_breakdown", [metrics["ram_bytes_transferred"], metrics["cache_hits"], metrics["cache_misses"]])
	if latest_run["design"] != design:
		summary_label.text = text("demo.previous") + " " + summary_label.text


func _refresh_machine() -> void:
	for child: Node in device_row.get_children():
		child.free()
	device_labels.clear()
	var devices := ["CPU", "Bus", "RAM"] if PerformanceTask.is_system(task_id) or bool(design.get("bypass", false)) else ["CPU", "Cache", "Bus", "RAM"]
	for index: int in range(devices.size()):
		if index > 0:
			_label(device_row, "⇄", 26)
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = SIZE_EXPAND_FILL
		device_row.add_child(panel)
		var device: String = devices[index]
		var details: String = text("demo.standard")
		if PerformanceTask.is_system(task_id):
			details = text("demo.part." + String(design[device.to_lower()]))
		elif device == "Cache":
			details = text("demo.cache_lines", [design["cache"], PerformanceTask.LocalCore.CACHE_COSTS[int(design["cache"])]])
		var label := _label(panel, device + (" · " + text("demo.standard") if PerformanceTask.is_system(task_id) else "") + "\n" + details, 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		device_labels[device.to_upper()] = label


func _refresh_preview() -> void:
	var system := PerformanceTask.is_system(task_id)
	memory_grid.visible = not system
	if system:
		address_label.text = text("demo.system_routes")
		return
	var data := PerformanceTask.LocalCore.official_data_copy()
	for index: int in range(16):
		data_cells[index].text = "%d\n@%d" % [data[index], index]
	var program := Parser.parse(editor.text)
	if not program.is_valid():
		address_label.text = text("demo.preview_invalid")
		return
	var preview: SimulationTrace = PerformanceTask.LocalCore.new().run_workload(program, data, int(design["cache"]), "preview", PerformanceTask.passes(task_id), int(design["group"]), bool(design["bypass"]))
	var addresses: Array[int] = []
	var schedule: Array[String] = []
	for event: SimulationEvent in preview.events:
		if event.kind == &"request":
			if addresses.size() < 32:
				addresses.append(event.address)
			var group: int = int(event.details.get("work_group_index", -1)) + 1
			var pass_index: int = int(event.details.get("pass_index", 0)) + 1
			var label: String = text("demo.schedule_group", [group, pass_index]) if group > 0 else text("demo.schedule_pass", [pass_index])
			if schedule.is_empty() or schedule.back() != label:
				schedule.append(label)
	address_label.text = text("demo.addresses", [str(addresses)]) + "\n" + " → ".join(schedule)


func _populate_events(receipt: Dictionary) -> void:
	_stop_replay()
	_clear_event_focus()
	events_list.clear()
	event_indices.clear()
	event_cursor = -1
	event_detail.text = text("demo.inspect")
	var case_index: int = int(receipt.get("display_case", 0))
	var trace: Variant = receipt["traces"][case_index]
	if trace is SimulationTrace:
		var data: Array = PerformanceTask.locality_cases()[case_index]
		for index: int in range(16):
			data_cells[index].text = "%d\n@%d" % [data[index], index]
	if not receipt["passed"]:
		event_detail.text = text("demo.failed_case", [case_index + 1])
	for index: int in range(trace.events.size()):
		var event: Variant = trace.events[index]
		if event.kind in [&"request", &"cache_hit", &"cache_miss", &"cache_evict", &"cache_fill", &"ram_access", &"read_request", &"write_request", &"ram_read", &"ram_write", &"read_data", &"write_data", &"compute", &"store_result"]:
			event_indices.append(index)
			events_list.add_item(_event_text(event))
	events_list.set_meta("receipt", receipt)
	replay_button.disabled = event_indices.is_empty()
	replay_position.editable = not event_indices.is_empty()
	replay_position.max_value = maxi(0, event_indices.size() - 1)
	replay_position.set_value_no_signal(0)


func _event_text(event: Variant) -> String:
	return text("demo.event", [event.cycle, text("demo.event." + String(event.kind)), event.duration, event.source_line])


func _clear_event_focus() -> void:
	for label: Label in device_labels.values():
		label.modulate = Color.WHITE
	for cell: Label in data_cells:
		cell.modulate = Color.WHITE
	for line: int in range(editor.get_line_count()):
		editor.set_line_background_color(line, Color.TRANSPARENT)
	if design.has("cache") and device_labels.has("CACHE"):
		device_labels["CACHE"].text = "Cache\n" + text("demo.cache_lines", [design["cache"], PerformanceTask.LocalCore.CACHE_COSTS[int(design["cache"])]])


func _select_event(index: int) -> void:
	if index < 0 or index >= event_indices.size():
		return
	event_cursor = index
	replay_position.set_value_no_signal(index)
	events_list.select(index)
	events_list.ensure_current_is_visible()
	var receipt: Dictionary = events_list.get_meta("receipt")
	var trace: Variant = receipt["traces"][receipt.get("display_case", 0)]
	var event: Variant = trace.events[event_indices[index]]
	event_detail.text = (text("demo.reference") if receipt == initial_run else text("demo.snapshot")) + " " + _event_text(event)
	for device: String in device_labels:
		device_labels[device].modulate = Color.WHITE
	for device: StringName in event.route_devices:
		if receipt["design"] == design and device_labels.has(String(device).to_upper()):
			device_labels[String(device).to_upper()].modulate = Color("76efbb")
	for cell: Label in data_cells:
		cell.modulate = Color.WHITE
	if event is SimulationEvent:
		if event.address >= 0 and event.address < data_cells.size():
			data_cells[event.address].modulate = Color("76efbb")
		var resident: Array[int] = []
		for prior_index: int in range(event_indices[index] + 1):
			var prior: SimulationEvent = trace.events[prior_index]
			if prior.kind == &"cache_evict":
				resident.erase(prior.cache_line)
			elif prior.kind == &"cache_fill" and prior.cache_line not in resident:
				resident.append(prior.cache_line)
		var details: Dictionary = event.details
		if receipt["design"] == design and device_labels.has("CACHE"):
			device_labels["CACHE"].text = "Cache\n" + text("demo.cache_lines", [design["cache"], PerformanceTask.LocalCore.CACHE_COSTS[int(design["cache"])]]) + "\n" + text("demo.resident_lines", [str(resident)])
		event_detail.text += "\n" + text("demo.resident", [str(resident), int(details.get("pass_index", 0)) + 1, int(details.get("work_group_index", -1)) + 1])
		if details.has("line_values"):
			event_detail.text += " " + text("demo.fetched_line", [int(details.get("line_base_address", 0)), str(details["line_values"])])
	if receipt["design"]["source"] == editor.text and event.source_line > 0:
		for line: int in range(editor.get_line_count()):
			editor.set_line_background_color(line, Color.TRANSPARENT)
		editor.set_caret_line(event.source_line - 1)
		editor.set_line_background_color(event.source_line - 1, Color("264452"))
	PlaytestData.record_trace_action(&"demo", StringName(task_id), &"inspect_event")


func _next_event() -> void:
	_stop_replay()
	if event_indices.is_empty():
		return
	event_cursor = (event_cursor + 1) % event_indices.size()
	events_list.select(event_cursor)
	events_list.ensure_current_is_visible()
	_select_event(event_cursor)


func _toggle_replay() -> void:
	if replaying:
		_stop_replay()
		return
	if event_indices.is_empty():
		return
	if event_cursor < 0 or event_cursor >= event_indices.size() - 1:
		_select_event(0)
	replaying = true
	replay_elapsed = 0.0
	replay_button.text = text("demo.pause")


func _stop_replay() -> void:
	replaying = false
	replay_elapsed = 0.0
	if replay_button != null:
		replay_button.text = text("demo.play")


func _process(delta: float) -> void:
	if not replaying or handbook.is_open():
		return
	replay_elapsed += delta * float(replay_speed.get_selected_metadata())
	if replay_elapsed < 0.6:
		return
	replay_elapsed = 0.0
	if event_cursor + 1 >= event_indices.size():
		_stop_replay()
	else:
		_select_event(event_cursor + 1)


func _open_handbook() -> void:
	_stop_replay()
	handbook.experience_notes.clear()
	var legacy_terms := {&"cpu_wait": &"cpu_wait", &"controlled_comparison": &"controlled_change", &"bottleneck": &"bottleneck", &"cache": &"cache", &"hit": &"hit", &"miss": &"miss", &"locality": &"locality", &"working_set": &"working_set", &"blocking": &"blocking"}
	for concept: StringName in legacy_terms:
		if LocalityChapter.concept_unlocked(concept):
			handbook.experience_notes[legacy_terms[concept]] = text("demo.legacy_experience") + "\n" + text("chapter2.notebook.%s.body" % concept) + "\n\n"
	var topics := {
		"dp_select": [&"multiplexer", &"data_path"],
		"dp_store": [&"register", &"ram", &"load", &"store"],
		"d1_cpu": [&"cpu_wait", &"cpu", &"baseline"],
		"d1_upgrade": [&"latency", &"bandwidth", &"bus"],
		"d2_cache": [&"cache", &"hit", &"miss"],
		"d2_order": [&"access_order", &"cache_line"],
		"d2_group": [&"working_set", &"work_group", &"blocking", &"pass"],
		"d2_final": [&"hardware_cost", &"before_after"],
	}
	for id: String in topics:
		for index: int in range(DemoProgress.stages(id)):
			if not DemoProgress.stage_complete(id, index):
				continue
			var accepted: Dictionary = DemoProgress.verify(id, index, DemoProgress.accepted_design(id, index))
			if not accepted.get("complete", false):
				continue
			var note: String = text("demo.experience", [text("demo.task." + id + ".title"), index + 1, accepted["case_count"]])
			if not id.begins_with("dp_"):
				var base: Dictionary = PerformanceTask.baseline(id, index)["metrics"]
				var metrics: Dictionary = accepted["metrics"]
				note += "\n" + text("demo.experience_metrics", [base["total_cycles"], metrics["total_cycles"], base["wait_cycles"], metrics["wait_cycles"], metrics["hardware_cost"]])
			for term: StringName in topics[id]:
				handbook.experience_notes[term] = String(handbook.experience_notes.get(term, "")) + note + "\n"
	handbook.open_handbook(topics[task_id][0])


func _toggle_events() -> void:
	events_list.visible = not events_list.visible


func _inspect_baseline() -> void:
	if initial_run.is_empty():
		return
	_populate_events(initial_run)
	events_list.show()
	event_detail.text = text("demo.reference")


func _inspect_wait() -> void:
	if latest_run.is_empty() or task_id.begins_with("dp_"):
		return
	_populate_events(latest_run)
	events_list.show()
	var trace: Variant = latest_run["traces"][0]
	for index: int in range(event_indices.size()):
		if trace.events[event_indices[index]].kind in [&"ram_read", &"ram_access", &"read_data"]:
			events_list.select(index)
			_select_event(index)
			break


func _show_hint() -> void:
	hint_stage = mini(3, hint_stage + 1)
	hint_label.text = text("demo.task." + task_id + ".hint" + str(hint_stage))
	PlaytestData.record_hint(&"demo", StringName(task_id), hint_stage)


func _show_sequence(receipt: Dictionary) -> void:
	var sequence: Dictionary = receipt["sequence"]
	var rows: Array[String] = []
	for step: Dictionary in sequence["steps"]:
		var outputs: Array[String] = []
		for comparison: Dictionary in step["comparisons"]:
			outputs.append("%s: %s → %s" % [comparison["name"], comparison["expected"].display_text(), comparison["actual"].display_text()])
		rows.append(text("demo.sequence_row", [step["index"] + 1, str(step["inputs"]), "; ".join(outputs)]))
		if not step["passed"]:
			break
	events_list.clear()
	for row: String in rows:
		events_list.add_item(row)
	events_list.show()
	event_detail.text = text("demo.success" if receipt["complete"] else "demo.wrong")
	PlaytestData.record_official_run(&"demo", StringName(task_id), receipt["passed"], {"stage": stage, "content_version": Foundations.VERSION})
	if receipt["complete"]:
		PlaytestData.level_completed(&"demo", StringName(task_id), {"stage": stage})


func _continue_task() -> void:
	if not completed:
		return
	PlaytestData.level_exited(&"demo", StringName(task_id), &"continue")
	if stage + 1 < DemoProgress.stages(task_id):
		load_task(task_id, stage + 1)
		return
	var index: int = DemoProgress.IDS.find(task_id)
	if index + 1 < DemoProgress.IDS.size():
		load_task(DemoProgress.IDS[index + 1])
	else:
		_return_to_map()


func _return_to_map() -> void:
	PlaytestData.level_exited(&"demo", StringName(task_id), &"map")
	get_tree().change_scene_to_file("res://src/demo/demo_menu.tscn")


func _input(event: InputEvent) -> void:
	if handbook != null and handbook.handle_escape(event):
		handbook.entry_button.hide()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F5:
		run_current()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE and replaying:
		_stop_replay()
		get_viewport().set_input_as_handled()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.ctrl_pressed and event.keycode == KEY_Z:
			redo() if event.shift_pressed else undo()
			get_viewport().set_input_as_handled()
		elif event.ctrl_pressed and event.keycode == KEY_Y:
			redo()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_return_to_map()
