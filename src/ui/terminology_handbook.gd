class_name TerminologyHandbook
extends Control

const UiTypographyType = preload("res://src/ui/ui_typography.gd")

const BACKDROP := Color(0.015, 0.027, 0.055, 0.88)
const PANEL := Color("111b2c")
const PANEL_DARK := Color("0b1322")
const ACCENT := Color("50d5ff")
const GOOD := Color("67e8a5")
const MUTED := Color("91a0b9")
const TEXT := Color("e9f0fa")
const ENTRY_BUTTON_WIDTH := 118.0

const CATEGORIES: Array[Dictionary] = [
	{"id": &"basics", "key": &"terminology.category.basics"},
	{"id": &"hardware", "key": &"terminology.category.hardware"},
	{"id": &"system", "key": &"terminology.category.system"},
	{"id": &"locality", "key": &"terminology.category.locality"},
]

const DIRECTORIES: Array[Dictionary] = [
	{"id": &"signals", "category": &"basics", "key": &"terminology.directory.signals", "terms": [&"bit", &"binary", &"signal", &"low_level", &"high_level", &"high_impedance", &"short_circuit"]},
	{"id": &"logic", "category": &"basics", "key": &"terminology.directory.logic", "terms": [&"logic_gate", &"not_gate", &"and_gate", &"or_gate", &"xor_gate", &"nor_gate"]},
	{"id": &"circuit", "category": &"basics", "key": &"terminology.directory.circuit", "terms": [&"input_output", &"port", &"wire", &"junction", &"combinational_loop", &"tick", &"truth_table", &"topology"]},
	{"id": &"testing", "category": &"basics", "key": &"terminology.directory.testing", "terms": [&"test_bench", &"debug_run", &"official_test", &"trace", &"clock_period", &"abstraction", &"encapsulation"]},
	{"id": &"arithmetic", "category": &"hardware", "key": &"terminology.directory.arithmetic", "terms": [&"half_adder", &"sum", &"carry", &"full_adder", &"cin_cout"]},
	{"id": &"processing", "category": &"hardware", "key": &"terminology.directory.processing", "terms": [&"multiplexer", &"alu", &"opcode", &"decoder", &"controller", &"data_path"]},
	{"id": &"storage", "category": &"hardware", "key": &"terminology.directory.storage", "terms": [&"latch", &"sr_latch", &"set_reset", &"d_q", &"register", &"address_write", &"ram"]},
	{"id": &"computer", "category": &"hardware", "key": &"terminology.directory.computer", "terms": [&"cpu", &"bus", &"accumulator", &"load", &"store", &"immediate", &"wraparound"]},
	{"id": &"programs", "category": &"system", "key": &"terminology.directory.programs", "terms": [&"program", &"dsl", &"apply", &"workload"]},
	{"id": &"metrics", "category": &"system", "key": &"terminology.directory.metrics", "terms": [&"cycle", &"latency", &"bandwidth", &"throughput", &"serialization", &"cpu_wait"]},
	{"id": &"diagnosis", "category": &"system", "key": &"terminology.directory.diagnosis", "terms": [&"profiler", &"prediction", &"baseline", &"controlled_change", &"bottleneck", &"hardware_cost", &"before_after", &"deterministic"]},
	{"id": &"cache", "category": &"locality", "key": &"terminology.directory.cache", "terms": [&"cache", &"cache_line", &"hit", &"miss", &"evict", &"fill"]},
	{"id": &"locality", "category": &"locality", "key": &"terminology.directory.locality", "terms": [&"locality", &"spatial_locality", &"temporal_locality", &"access_order", &"row_first", &"column_first"]},
	{"id": &"optimization", "category": &"locality", "key": &"terminology.directory.optimization", "terms": [&"working_set", &"pass", &"work_group", &"blocking", &"tiling", &"data_request"]},
]

const TERMS: Array[Dictionary] = [
	{"id": &"bit", "category": &"basics", "title": &"terminology.term.bit.title", "body": &"terminology.term.bit.body"},
	{"id": &"binary", "category": &"basics", "title": &"terminology.term.binary.title", "body": &"terminology.term.binary.body"},
	{"id": &"signal", "category": &"basics", "title": &"terminology.term.signal.title", "body": &"terminology.term.signal.body"},
	{"id": &"low_level", "category": &"basics", "title": &"terminology.term.low_level.title", "body": &"terminology.term.low_level.body"},
	{"id": &"high_level", "category": &"basics", "title": &"terminology.term.high_level.title", "body": &"terminology.term.high_level.body"},
	{"id": &"high_impedance", "category": &"basics", "title": &"terminology.term.high_impedance.title", "body": &"terminology.term.high_impedance.body"},
	{"id": &"short_circuit", "category": &"basics", "title": &"terminology.term.short_circuit.title", "body": &"terminology.term.short_circuit.body"},
	{"id": &"logic_gate", "category": &"basics", "title": &"terminology.term.logic_gate.title", "body": &"terminology.term.logic_gate.body"},
	{"id": &"not_gate", "category": &"basics", "title": &"terminology.term.not_gate.title", "body": &"terminology.term.not_gate.body"},
	{"id": &"and_gate", "category": &"basics", "title": &"terminology.term.and_gate.title", "body": &"terminology.term.and_gate.body"},
	{"id": &"or_gate", "category": &"basics", "title": &"terminology.term.or_gate.title", "body": &"terminology.term.or_gate.body"},
	{"id": &"xor_gate", "category": &"basics", "title": &"terminology.term.xor_gate.title", "body": &"terminology.term.xor_gate.body"},
	{"id": &"nor_gate", "category": &"basics", "title": &"terminology.term.nor_gate.title", "body": &"terminology.term.nor_gate.body"},
	{"id": &"input_output", "category": &"basics", "title": &"terminology.term.input_output.title", "body": &"terminology.term.input_output.body"},
	{"id": &"port", "category": &"basics", "title": &"terminology.term.port.title", "body": &"terminology.term.port.body"},
	{"id": &"wire", "category": &"basics", "title": &"terminology.term.wire.title", "body": &"terminology.term.wire.body"},
	{"id": &"junction", "category": &"basics", "title": &"terminology.term.junction.title", "body": &"terminology.term.junction.body"},
	{"id": &"combinational_loop", "category": &"basics", "title": &"terminology.term.combinational_loop.title", "body": &"terminology.term.combinational_loop.body"},
	{"id": &"tick", "category": &"basics", "title": &"terminology.term.tick.title", "body": &"terminology.term.tick.body"},
	{"id": &"truth_table", "category": &"basics", "title": &"terminology.term.truth_table.title", "body": &"terminology.term.truth_table.body"},
	{"id": &"topology", "category": &"basics", "title": &"terminology.term.topology.title", "body": &"terminology.term.topology.body"},
	{"id": &"test_bench", "category": &"basics", "title": &"terminology.term.test_bench.title", "body": &"terminology.term.test_bench.body"},
	{"id": &"debug_run", "category": &"basics", "title": &"terminology.term.debug_run.title", "body": &"terminology.term.debug_run.body"},
	{"id": &"official_test", "category": &"basics", "title": &"terminology.term.official_test.title", "body": &"terminology.term.official_test.body"},
	{"id": &"trace", "category": &"basics", "title": &"terminology.term.trace.title", "body": &"terminology.term.trace.body"},
	{"id": &"clock_period", "category": &"basics", "title": &"terminology.term.clock_period.title", "body": &"terminology.term.clock_period.body"},
	{"id": &"abstraction", "category": &"basics", "title": &"terminology.term.abstraction.title", "body": &"terminology.term.abstraction.body"},
	{"id": &"encapsulation", "category": &"basics", "title": &"terminology.term.encapsulation.title", "body": &"terminology.term.encapsulation.body"},

	{"id": &"half_adder", "category": &"hardware", "title": &"terminology.term.half_adder.title", "body": &"terminology.term.half_adder.body"},
	{"id": &"sum", "category": &"hardware", "title": &"terminology.term.sum.title", "body": &"terminology.term.sum.body"},
	{"id": &"carry", "category": &"hardware", "title": &"terminology.term.carry.title", "body": &"terminology.term.carry.body"},
	{"id": &"full_adder", "category": &"hardware", "title": &"terminology.term.full_adder.title", "body": &"terminology.term.full_adder.body"},
	{"id": &"cin_cout", "category": &"hardware", "title": &"terminology.term.cin_cout.title", "body": &"terminology.term.cin_cout.body"},
	{"id": &"multiplexer", "category": &"hardware", "title": &"terminology.term.multiplexer.title", "body": &"terminology.term.multiplexer.body"},
	{"id": &"alu", "category": &"hardware", "title": &"terminology.term.alu.title", "body": &"terminology.term.alu.body"},
	{"id": &"opcode", "category": &"hardware", "title": &"terminology.term.opcode.title", "body": &"terminology.term.opcode.body"},
	{"id": &"latch", "category": &"hardware", "title": &"terminology.term.latch.title", "body": &"terminology.term.latch.body"},
	{"id": &"sr_latch", "category": &"hardware", "title": &"terminology.term.sr_latch.title", "body": &"terminology.term.sr_latch.body"},
	{"id": &"set_reset", "category": &"hardware", "title": &"terminology.term.set_reset.title", "body": &"terminology.term.set_reset.body"},
	{"id": &"d_q", "category": &"hardware", "title": &"terminology.term.d_q.title", "body": &"terminology.term.d_q.body"},
	{"id": &"register", "category": &"hardware", "title": &"terminology.term.register.title", "body": &"terminology.term.register.body"},
	{"id": &"decoder", "category": &"hardware", "title": &"terminology.term.decoder.title", "body": &"terminology.term.decoder.body"},
	{"id": &"address_write", "category": &"hardware", "title": &"terminology.term.address_write.title", "body": &"terminology.term.address_write.body"},
	{"id": &"ram", "category": &"hardware", "title": &"terminology.term.ram.title", "body": &"terminology.term.ram.body"},
	{"id": &"cpu", "category": &"hardware", "title": &"terminology.term.cpu.title", "body": &"terminology.term.cpu.body"},
	{"id": &"bus", "category": &"hardware", "title": &"terminology.term.bus.title", "body": &"terminology.term.bus.body"},
	{"id": &"accumulator", "category": &"hardware", "title": &"terminology.term.accumulator.title", "body": &"terminology.term.accumulator.body"},
	{"id": &"controller", "category": &"hardware", "title": &"terminology.term.controller.title", "body": &"terminology.term.controller.body"},
	{"id": &"data_path", "category": &"hardware", "title": &"terminology.term.data_path.title", "body": &"terminology.term.data_path.body"},
	{"id": &"load", "category": &"hardware", "title": &"terminology.term.load.title", "body": &"terminology.term.load.body"},
	{"id": &"store", "category": &"hardware", "title": &"terminology.term.store.title", "body": &"terminology.term.store.body"},
	{"id": &"immediate", "category": &"hardware", "title": &"terminology.term.immediate.title", "body": &"terminology.term.immediate.body"},
	{"id": &"wraparound", "category": &"hardware", "title": &"terminology.term.wraparound.title", "body": &"terminology.term.wraparound.body"},

	{"id": &"program", "category": &"system", "title": &"terminology.term.program.title", "body": &"terminology.term.program.body"},
	{"id": &"dsl", "category": &"system", "title": &"terminology.term.dsl.title", "body": &"terminology.term.dsl.body"},
	{"id": &"apply", "category": &"system", "title": &"terminology.term.apply.title", "body": &"terminology.term.apply.body"},
	{"id": &"workload", "category": &"system", "title": &"terminology.term.workload.title", "body": &"terminology.term.workload.body"},
	{"id": &"cycle", "category": &"system", "title": &"terminology.term.cycle.title", "body": &"terminology.term.cycle.body"},
	{"id": &"latency", "category": &"system", "title": &"terminology.term.latency.title", "body": &"terminology.term.latency.body"},
	{"id": &"bandwidth", "category": &"system", "title": &"terminology.term.bandwidth.title", "body": &"terminology.term.bandwidth.body"},
	{"id": &"throughput", "category": &"system", "title": &"terminology.term.throughput.title", "body": &"terminology.term.throughput.body"},
	{"id": &"serialization", "category": &"system", "title": &"terminology.term.serialization.title", "body": &"terminology.term.serialization.body"},
	{"id": &"cpu_wait", "category": &"system", "title": &"terminology.term.cpu_wait.title", "body": &"terminology.term.cpu_wait.body"},
	{"id": &"profiler", "category": &"system", "title": &"terminology.term.profiler.title", "body": &"terminology.term.profiler.body"},
	{"id": &"prediction", "category": &"system", "title": &"terminology.term.prediction.title", "body": &"terminology.term.prediction.body"},
	{"id": &"baseline", "category": &"system", "title": &"terminology.term.baseline.title", "body": &"terminology.term.baseline.body"},
	{"id": &"controlled_change", "category": &"system", "title": &"terminology.term.controlled_change.title", "body": &"terminology.term.controlled_change.body"},
	{"id": &"bottleneck", "category": &"system", "title": &"terminology.term.bottleneck.title", "body": &"terminology.term.bottleneck.body"},
	{"id": &"hardware_cost", "category": &"system", "title": &"terminology.term.hardware_cost.title", "body": &"terminology.term.hardware_cost.body"},
	{"id": &"before_after", "category": &"system", "title": &"terminology.term.before_after.title", "body": &"terminology.term.before_after.body"},
	{"id": &"deterministic", "category": &"system", "title": &"terminology.term.deterministic.title", "body": &"terminology.term.deterministic.body"},

	{"id": &"cache", "category": &"locality", "title": &"terminology.term.cache.title", "body": &"terminology.term.cache.body"},
	{"id": &"cache_line", "category": &"locality", "title": &"terminology.term.cache_line.title", "body": &"terminology.term.cache_line.body"},
	{"id": &"hit", "category": &"locality", "title": &"terminology.term.hit.title", "body": &"terminology.term.hit.body"},
	{"id": &"miss", "category": &"locality", "title": &"terminology.term.miss.title", "body": &"terminology.term.miss.body"},
	{"id": &"evict", "category": &"locality", "title": &"terminology.term.evict.title", "body": &"terminology.term.evict.body"},
	{"id": &"fill", "category": &"locality", "title": &"terminology.term.fill.title", "body": &"terminology.term.fill.body"},
	{"id": &"locality", "category": &"locality", "title": &"terminology.term.locality.title", "body": &"terminology.term.locality.body"},
	{"id": &"spatial_locality", "category": &"locality", "title": &"terminology.term.spatial_locality.title", "body": &"terminology.term.spatial_locality.body"},
	{"id": &"temporal_locality", "category": &"locality", "title": &"terminology.term.temporal_locality.title", "body": &"terminology.term.temporal_locality.body"},
	{"id": &"access_order", "category": &"locality", "title": &"terminology.term.access_order.title", "body": &"terminology.term.access_order.body"},
	{"id": &"row_first", "category": &"locality", "title": &"terminology.term.row_first.title", "body": &"terminology.term.row_first.body"},
	{"id": &"column_first", "category": &"locality", "title": &"terminology.term.column_first.title", "body": &"terminology.term.column_first.body"},
	{"id": &"working_set", "category": &"locality", "title": &"terminology.term.working_set.title", "body": &"terminology.term.working_set.body"},
	{"id": &"pass", "category": &"locality", "title": &"terminology.term.pass.title", "body": &"terminology.term.pass.body"},
	{"id": &"work_group", "category": &"locality", "title": &"terminology.term.work_group.title", "body": &"terminology.term.work_group.body"},
	{"id": &"blocking", "category": &"locality", "title": &"terminology.term.blocking.title", "body": &"terminology.term.blocking.body"},
	{"id": &"tiling", "category": &"locality", "title": &"terminology.term.tiling.title", "body": &"terminology.term.tiling.body"},
	{"id": &"data_request", "category": &"locality", "title": &"terminology.term.data_request.title", "body": &"terminology.term.data_request.body"},
]

var entry_button: Button
var modal: ColorRect
var title_label: Label
var subtitle_label: Label
var search_edit: LineEdit
var category_selector: OptionButton
var term_tree: Tree
var result_count_label: Label
var detail_category_label: Label
var detail_title_label: Label
var detail_body_label: RichTextLabel
var footer_label: Label
var close_button: Button
var visible_term_ids: Array[StringName] = []
var visible_term_items: Dictionary = {}


static func has_term(term_id: StringName) -> bool:
	for term: Dictionary in TERMS:
		if StringName(term.get("id", &"")) == term_id:
			return true
	return false


func _ready() -> void:
	name = "TerminologyHandbook"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 900
	_build_theme()
	_build_interface()
	Localization.locale_changed.connect(_on_locale_changed)
	_refresh_localized_copy()


func open_handbook(term_id: StringName = &"") -> void:
	modal.show()
	entry_button.hide()
	_refresh_terms(term_id)
	search_edit.grab_focus()


func close_handbook() -> void:
	modal.hide()
	entry_button.show()
	entry_button.grab_focus()


func is_open() -> bool:
	return modal != null and modal.visible


func handle_escape(event: InputEvent) -> bool:
	if not is_open() or not event is InputEventKey:
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo or key_event.keycode != KEY_ESCAPE:
		return false
	close_handbook()
	return true


func _build_theme() -> void:
	var handbook_theme := Theme.new()
	handbook_theme.default_font_size = UiTypographyType.BODY_SIZE
	for control_type: String in ["Label", "Button", "LineEdit", "OptionButton", "Tree"]:
		handbook_theme.set_color("font_color", control_type, TEXT)
	handbook_theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	handbook_theme.set_color("font_selected_color", "Tree", TEXT)
	handbook_theme.set_color("font_hovered_color", "Tree", TEXT)
	handbook_theme.set_constant("separation", "VBoxContainer", 12)
	handbook_theme.set_constant("separation", "HBoxContainer", 14)
	handbook_theme.set_stylebox("panel", "PanelContainer", _stylebox(PANEL, 12, 1, Color("31425f"), 18.0))
	handbook_theme.set_stylebox("normal", "Button", _stylebox(Color("26334a"), 8, 1, Color("3a4d69"), 10.0))
	handbook_theme.set_stylebox("hover", "Button", _stylebox(Color("30435f"), 8, 2, ACCENT, 10.0))
	handbook_theme.set_stylebox("pressed", "Button", _stylebox(Color("17283e"), 8, 2, ACCENT, 10.0))
	handbook_theme.set_stylebox("normal", "LineEdit", _stylebox(PANEL_DARK, 8, 1, Color("31425f"), 10.0))
	handbook_theme.set_stylebox("focus", "LineEdit", _stylebox(PANEL_DARK, 8, 2, ACCENT, 10.0))
	handbook_theme.set_stylebox("panel", "Tree", _stylebox(PANEL_DARK, 8, 1, Color("263750"), 8.0))
	handbook_theme.set_stylebox("selected", "Tree", _stylebox(Color("1d4258"), 6, 1, ACCENT, 6.0))
	handbook_theme.set_stylebox("selected_focus", "Tree", _stylebox(Color("1d4258"), 6, 2, ACCENT, 6.0))
	theme = handbook_theme


func _build_interface() -> void:
	entry_button = Button.new()
	entry_button.name = "TerminologyButton"
	entry_button.custom_minimum_size = Vector2(ENTRY_BUTTON_WIDTH, UiTypographyType.TOOL_BUTTON_HEIGHT)
	entry_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	entry_button.offset_left = -132.0
	entry_button.offset_top = -56.0
	entry_button.offset_right = -14.0
	entry_button.offset_bottom = -12.0
	entry_button.add_theme_stylebox_override("normal", _stylebox(Color("26334a"), 7, 1, Color("354866"), 10.0))
	entry_button.add_theme_stylebox_override("hover", _stylebox(Color("30435f"), 7, 1, ACCENT, 10.0))
	entry_button.add_theme_stylebox_override("pressed", _stylebox(Color("17283e"), 7, 1, ACCENT, 10.0))
	entry_button.pressed.connect(open_handbook)
	add_child(entry_button)

	modal = ColorRect.new()
	modal.name = "TerminologyModal"
	modal.color = BACKDROP
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	modal.hide()
	add_child(modal)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var shell := PanelContainer.new()
	shell.custom_minimum_size = Vector2(1180.0, 710.0)
	center.add_child(shell)
	var shell_box := VBoxContainer.new()
	shell.add_child(shell_box)

	var header := HBoxContainer.new()
	shell_box.add_child(header)
	var heading_box := VBoxContainer.new()
	heading_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading_box)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	title_label.add_theme_color_override("font_color", ACCENT)
	heading_box.add_child(title_label)
	subtitle_label = Label.new()
	subtitle_label.add_theme_color_override("font_color", MUTED)
	heading_box.add_child(subtitle_label)
	close_button = Button.new()
	close_button.custom_minimum_size = Vector2(104.0, 44.0)
	close_button.pressed.connect(close_handbook)
	header.add_child(close_button)

	var filter_row := HBoxContainer.new()
	shell_box.add_child(filter_row)
	search_edit = LineEdit.new()
	search_edit.name = "TerminologySearch"
	search_edit.clear_button_enabled = true
	search_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_edit.text_changed.connect(func(_text: String) -> void: _refresh_terms())
	filter_row.add_child(search_edit)
	category_selector = OptionButton.new()
	category_selector.name = "TerminologyCategory"
	category_selector.custom_minimum_size.x = 245.0
	category_selector.item_selected.connect(func(_index: int) -> void: _refresh_terms())
	filter_row.add_child(category_selector)

	var content_row := HBoxContainer.new()
	content_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell_box.add_child(content_row)
	var list_box := VBoxContainer.new()
	list_box.custom_minimum_size.x = 355.0
	list_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_row.add_child(list_box)
	term_tree = Tree.new()
	term_tree.name = "TerminologyEntries"
	term_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	term_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	term_tree.hide_root = true
	term_tree.select_mode = Tree.SELECT_SINGLE
	term_tree.item_selected.connect(_on_term_selected)
	list_box.add_child(term_tree)
	result_count_label = Label.new()
	result_count_label.add_theme_color_override("font_color", MUTED)
	list_box.add_child(result_count_label)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_panel.add_theme_stylebox_override("panel", _stylebox(PANEL_DARK, 10, 1, Color("263750"), 22.0))
	content_row.add_child(detail_panel)
	var detail_box := VBoxContainer.new()
	detail_panel.add_child(detail_box)
	detail_category_label = Label.new()
	detail_category_label.add_theme_color_override("font_color", GOOD)
	detail_box.add_child(detail_category_label)
	detail_title_label = Label.new()
	detail_title_label.add_theme_font_size_override("font_size", UiTypographyType.TITLE_SIZE)
	detail_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_box.add_child(detail_title_label)
	var divider := HSeparator.new()
	detail_box.add_child(divider)
	detail_body_label = RichTextLabel.new()
	detail_body_label.name = "TerminologyDefinition"
	detail_body_label.bbcode_enabled = false
	detail_body_label.fit_content = false
	detail_body_label.scroll_active = true
	detail_body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_body_label.add_theme_font_size_override("normal_font_size", UiTypographyType.BODY_SIZE)
	detail_body_label.add_theme_color_override("default_color", TEXT)
	detail_box.add_child(detail_body_label)

	footer_label = Label.new()
	footer_label.add_theme_color_override("font_color", MUTED)
	footer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	shell_box.add_child(footer_label)


func _refresh_localized_copy() -> void:
	entry_button.text = _t(&"terminology.button")
	entry_button.tooltip_text = _t(&"terminology.button.tooltip")
	title_label.text = _t(&"terminology.title")
	subtitle_label.text = _t(&"terminology.subtitle")
	close_button.text = _t(&"terminology.close")
	search_edit.placeholder_text = _t(&"terminology.search.placeholder")
	footer_label.text = _t(&"terminology.footer")
	var selected_category: StringName = _selected_category()
	category_selector.clear()
	category_selector.add_item(_t(&"terminology.category.all"))
	category_selector.set_item_metadata(0, &"")
	for category: Dictionary in CATEGORIES:
		category_selector.add_item(_t(category["key"]))
		category_selector.set_item_metadata(category_selector.item_count - 1, category["id"])
	for index: int in range(category_selector.item_count):
		if StringName(category_selector.get_item_metadata(index)) == selected_category:
			category_selector.select(index)
			break
	_refresh_terms()


func _refresh_terms(preferred_term_id: StringName = &"") -> void:
	if term_tree == null:
		return
	var previous_term_id: StringName = preferred_term_id
	var previous_item: TreeItem = term_tree.get_selected()
	if previous_term_id.is_empty() and previous_item != null:
		previous_term_id = StringName(previous_item.get_metadata(0))
	var query: String = search_edit.text.strip_edges().to_lower()
	var category_id: StringName = _selected_category()
	term_tree.clear()
	visible_term_ids.clear()
	visible_term_items.clear()
	var root_item: TreeItem = term_tree.create_item()
	for category: Dictionary in CATEGORIES:
		var current_category_id: StringName = category["id"]
		if not category_id.is_empty() and current_category_id != category_id:
			continue
		var category_item: TreeItem
		for directory: Dictionary in DIRECTORIES:
			if StringName(directory["category"]) != current_category_id:
				continue
			var matching_terms: Array[Dictionary] = []
			for term_id: StringName in directory["terms"]:
				var term: Dictionary = _term_definition(term_id)
				if term.is_empty() or not _term_matches(term, query):
					continue
				matching_terms.append(term)
			if matching_terms.is_empty():
				continue
			if category_item == null:
				category_item = term_tree.create_item(root_item)
				category_item.set_text(0, _t(category["key"]))
				category_item.set_selectable(0, false)
				category_item.set_custom_color(0, ACCENT)
				category_item.set_collapsed(false)
			var directory_item: TreeItem = term_tree.create_item(category_item)
			directory_item.set_text(0, "%s  (%d)" % [_t(directory["key"]), matching_terms.size()])
			directory_item.set_selectable(0, false)
			directory_item.set_custom_color(0, GOOD)
			directory_item.set_collapsed(query.is_empty())
			for term: Dictionary in matching_terms:
				var term_id: StringName = term["id"]
				var term_item: TreeItem = term_tree.create_item(directory_item)
				term_item.set_text(0, _t(term["title"]))
				term_item.set_metadata(0, term_id)
				visible_term_ids.append(term_id)
				visible_term_items[term_id] = term_item
	if visible_term_ids.is_empty():
		result_count_label.text = _t(&"terminology.result_count", [0, TERMS.size()])
		_show_empty_detail()
		return
	result_count_label.text = _t(&"terminology.result_count", [visible_term_ids.size(), TERMS.size()])
	var selected_term_id: StringName = previous_term_id
	if not visible_term_items.has(selected_term_id):
		selected_term_id = visible_term_ids[0]
	var selected_item: TreeItem = visible_term_items[selected_term_id]
	selected_item.select(0)
	var ancestor: TreeItem = selected_item.get_parent()
	while ancestor != null and ancestor != root_item:
		ancestor.set_collapsed(false)
		ancestor = ancestor.get_parent()
	term_tree.scroll_to_item(selected_item, true)
	_show_term(selected_term_id)


func _term_matches(term: Dictionary, query: String) -> bool:
	if query.is_empty():
		return true
	var directory_name: String = _directory_name_for_term(term["id"])
	var haystack := "%s\n%s\n%s\n%s\n%s" % [
		_t(term["title"]),
		_t(term["body"]),
		_category_name(term["category"]),
		directory_name,
		String(term["id"]),
	]
	return query in haystack.to_lower()


func _term_definition(term_id: StringName) -> Dictionary:
	for term: Dictionary in TERMS:
		if StringName(term["id"]) == term_id:
			return term
	return {}


func _directory_name_for_term(term_id: StringName) -> String:
	for directory: Dictionary in DIRECTORIES:
		if term_id in directory["terms"]:
			return _t(directory["key"])
	return ""


func _on_term_selected() -> void:
	var selected_item: TreeItem = term_tree.get_selected()
	if selected_item == null:
		return
	var term_id := StringName(selected_item.get_metadata(0))
	if term_id.is_empty():
		return
	_show_term(term_id)


func _show_term(term_id: StringName) -> void:
	for term: Dictionary in TERMS:
		if StringName(term["id"]) != term_id:
			continue
		var category_name: String = _category_name(term["category"])
		var directory_name: String = _directory_name_for_term(term_id)
		detail_category_label.text = category_name if directory_name.is_empty() else "%s  ·  %s" % [category_name, directory_name]
		detail_title_label.text = _t(term["title"])
		detail_body_label.text = _t(term["body"])
		detail_body_label.scroll_to_line(0)
		return
	_show_empty_detail()


func _show_empty_detail() -> void:
	detail_category_label.text = ""
	detail_title_label.text = _t(&"terminology.empty.title")
	detail_body_label.text = _t(&"terminology.empty.body")


func _selected_category() -> StringName:
	if category_selector == null or category_selector.item_count == 0:
		return &""
	return StringName(category_selector.get_item_metadata(category_selector.selected))


func _category_name(category_id: StringName) -> String:
	for category: Dictionary in CATEGORIES:
		if StringName(category["id"]) == category_id:
			return _t(category["key"])
	return _t(&"terminology.category.all")


func _on_locale_changed(_locale: String) -> void:
	_refresh_localized_copy()


func _t(key: StringName, arguments: Array = []) -> String:
	return Localization.text(key, arguments)


func _stylebox(
	color: Color,
	radius: int,
	border_width: int = 0,
	border_color: Color = Color.TRANSPARENT,
	content_margin: float = 10.0
	) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_width_left = border_width
	box.border_width_top = border_width
	box.border_width_right = border_width
	box.border_width_bottom = border_width
	box.border_color = border_color
	box.content_margin_left = content_margin
	box.content_margin_right = content_margin
	box.content_margin_top = content_margin
	box.content_margin_bottom = content_margin
	return box
