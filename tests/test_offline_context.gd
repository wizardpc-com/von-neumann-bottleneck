extends SceneTree

const Context = preload("res://src/playtest/offline_context.gd")
const CircuitTraceType = preload("res://src/circuit/circuit_trace.gd")
const SystemTraceType = preload("res://src/system_lab/system_trace.gd")
const LayoutRunType = preload("res://src/layout_chapter/layout_run.gd")

var failures: Array[String] = []
var checks := 0


func _init() -> void: call_deferred("run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func coverage() -> Dictionary:
	return {"unavailable": [], "truncated": [], "limits": {}}


func run() -> void:
	var core: Dictionary = Context.capture(self)
	check(core.schema == "offline_context_v1" and core.build.has("source_commit")
		and core.has("task") and core.navigation.has("selected"),
		"Capture separates active task identity from navigation and records source build")
	check(core.progress.has("game") and core.progress.game.has("hardware"),
		"Core progress is a complete in-memory save snapshot")
	check(JSON.parse_string(JSON.stringify(core)) is Dictionary,
		"Capture is JSON data without raw Godot object references")

	var hardware = load("res://src/hardware_foundations/hardware_foundations.gd").new()
	hardware.current_level_id = &"tutorial"
	hardware.current_phase = &"tutorial"
	hardware.current_trace = CircuitTraceType.new()
	hardware.current_trace.errors.append("broken wire")
	var hw: Dictionary = Context._capture_domain(hardware, "hardware", coverage())
	check(hw.current_level_id == "tutorial" and hw.current_trace.errors == ["broken wire"]
		and hw.has("visible_workbench"), "Hardware includes unsaved visible circuit and current errors")
	hardware.free()

	var system = load("res://src/system_lab/system_lab.gd").new()
	system.current_level_id = &"assembly"
	system.current_trace = SystemTraceType.new()
	system.current_trace.metrics = {"total_cycles": 23}
	system.editor = CodeEdit.new(); system.editor.text = "LOAD 0\nSTORE 1"
	system.add_child(system.editor)
	var sy: Dictionary = Context._capture_domain(system, "system", coverage())
	check(sy.visible_program_text == "LOAD 0\nSTORE 1" and sy.current_trace.metrics.total_cycles == 23,
		"System captures unsaved CodeEdit text and current measured trace")
	system.free()

	var locality = load("res://src/ui/main.gd").new()
	locality.current_level_id = &"distant_reads"
	locality.current_cache_lines = 2
	locality.editor = CodeEdit.new(); locality.editor.text = "READ 7"
	locality.add_child(locality.editor)
	var lo: Dictionary = Context._capture_domain(locality, "locality", coverage())
	check(lo.current_cache_lines == 2 and lo.visible_program_text == "READ 7",
		"Locality captures currently displayed parameters and unsaved code")
	locality.free()

	var overlap = load("res://src/overlap_chapter/overlap_chapter.gd").new()
	overlap.board = {"nodes": {"CPU": {"x": 2}}, "wires": []}
	overlap.editor = CodeEdit.new(); overlap.editor.text = "move"
	overlap.add_child(overlap.editor)
	var ov: Dictionary = Context._capture_domain(overlap, "overlap", coverage())
	check(ov.board.nodes.CPU.x == 2 and ov.visible_program_text == "move",
		"Overlap captures editable board and program")
	overlap.free()

	var layout = load("res://src/layout_chapter/layout_chapter.gd").new()
	layout.design = {"kind": "by_record", "block": 2}
	layout.runs.append(LayoutRunType.new())
	layout.scheme_name = LineEdit.new(); layout.scheme_name.text = "my layout"
	layout.add_child(layout.scheme_name)
	var la: Dictionary = Context._capture_domain(layout, "layout", coverage())
	check(la.design.block == 2 and la.visible_scheme_name == "my layout" and la.runs.size() == 1,
		"Layout captures unsaved recipe, visible name, and run evidence")
	layout.free()

	var representation = load("res://experiments/representation_region/region.gd").new()
	representation.plan.clear(); representation.plan.append({"format": "raw", "length": 3})
	representation.session_dirty = true
	var re: Dictionary = Context._capture_domain(representation, "representation", coverage())
	check(re.plan[0].length == 3 and re.session_dirty, "Representation captures unsaved plan")
	representation.free()

	var service = load("res://experiments/service_plan/lab.gd").new()
	service.plan = {"slots": 3, "groups": []}
	service.session_dirty = true
	var se: Dictionary = Context._capture_domain(service, "service", coverage())
	check(se.plan.slots == 3 and se.session_dirty, "Service captures unsaved plan")
	service.free()

	var prediction = load("res://experiments/prediction/lab.gd").new()
	prediction.policy = {"rule": "last"}
	prediction.revealed = 4
	var pr: Dictionary = Context._capture_domain(prediction, "prediction", coverage())
	check(pr.policy.rule == "last" and pr.revealed == 4, "Prediction captures policy and reveal step")
	prediction.free()

	var creation = load("res://experiments/creation/workbench.gd").new()
	creation.session.data.draft.examples = [[0, 1, 2, 3]]
	creation.session.dirty = true
	creation.sample_edit_text = "ABCD"
	creation.name_input = LineEdit.new(); creation.name_input.text = "unfinished work"
	creation.add_child(creation.name_input)
	var cr: Dictionary = Context._capture_domain(creation, "creation", coverage())
	check(cr.session.data.draft.examples == [[0, 1, 2, 3]] and cr.session.dirty
		and cr.sample_edit_text == "ABCD" and cr.visible_name == "unfinished work",
		"Creation captures candidate profile plus pending sample and name edits")
	check(not cr.session.has("path") and not cr.session.has("lease"),
		"Candidate file path and lease are excluded")
	creation.free()

	var report := coverage()
	var unknown := Node.new()
	var unsupported: Variant = Context._clean(unknown, "unknown", report)
	unknown.free()
	check(unsupported.unavailable == "unsupported_object" and report.unavailable.size() == 1,
		"Unknown objects are reported, never stringified as references")
	var limited: Variant = Context._clean("x".repeat(Context.MAX_STRING + 1), "long", report)
	check(limited.length() == Context.MAX_STRING and report.truncated.size() == 1,
		"Truncation is bounded and reported with a path")

	print("PASS: offline context %d checks" % checks if failures.is_empty() else "FAIL: " + str(failures))
	quit(0 if failures.is_empty() else 1)
