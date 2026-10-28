extends SceneTree

var failures: int = 0
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func run() -> void:
	var diagram_type: GDScript = load("res://src/ui/terminology_diagram.gd")
	var handbook: GDScript = load("res://src/ui/terminology_handbook.gd")
	var diagram: Control = diagram_type.new()
	root.add_child(diagram)
	await process_frame
	var signature: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	var model: GDScript = load("res://experiments/creation/model.gd")
	for id: StringName in diagram_type.LESSON_DIAGRAM_IDS:
		diagram.set_diagram(id)
		var count: int = diagram.example_count()
		check(count == (2 if id == &"packet_cost" else 3), "%s has its lesson pages" % id)
		for page: int in count:
			var example: Dictionary = diagram.lesson_example()
			check(not example.note.is_empty(), "%s labels its schematic" % id)
			if id == &"context_history":
				var learned: Dictionary = model.learn([[0,1,0,2]],page,model.default_machine())
				var prefix: Array = [] if page == 0 else [0] if page == 1 else [1,0]
				check(learned.ok, "bounded ABAC learning succeeds")
				var prediction: Dictionary = model.predict(learned.model,prefix)
				check(prediction.counts == example.counts, "history page agrees with actual ABAC successor counts")
			if id == &"frozen_check":
				check(example.seen == (page > 0), "check becomes seen at first reveal")
			diagram.advance_example(1)
		check(diagram.example_step == 0, "%s pages wrap" % id)
	for id: StringName in diagram_type.CONCEPT_IDS:
		var mapped: bool = false
		for term: Dictionary in handbook.TERMS:
			if term.id == id: mapped = term.get("diagram",&"") == id
		check(mapped, "%s is bound to its actual Handbook entry" % id)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		for width: int in [320,600]:
			diagram.size = Vector2(width,248)
			for id: StringName in diagram_type.CONCEPT_IDS:
				diagram.set_diagram(id)
				await process_frame
				check(diagram.visible and diagram.example_count() == 1 and not diagram.has_logic_inputs(), "%s is a static explanatory diagram" % id)
				if id in [&"port",&"high_impedance",&"short_circuit"]: continue
				var example: Dictionary = diagram.concept_example()
				check(example.steps.size() == 4 and not str(example.note).is_empty(), "%s has a complete relationship sketch" % id)
				var boxes: Array[Rect2] = diagram.concept_boxes()
				for index: int in 4:
					check(Rect2(Vector2.ZERO,diagram.size).encloses(boxes[index]), "%s box fits at %d" % [id,width])
					for row: int in 2:
						var height: float = 30.0 if row == 0 else 35.0
						var layout: Dictionary = diagram.wrapped_text_layout(Rect2(0,0,boxes[index].size.x-10,height),str(example.steps[index][row]),14 if row == 0 else 13)
						check(layout.measured.y <= height+1.0, "%s %s text fits at %d" % [locale,id,width])
				var footer: Dictionary = diagram.wrapped_text_layout(Rect2(14,212,width-28,34),str(example.note),13)
				check(footer.measured.y <= 35, "%s footer fits at %d" % [id,width])
				if DisplayServer.get_name() != "headless": RenderingServer.force_draw(false)
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == signature, "Reading every diagram grants no progress or components")
	diagram.queue_free(); await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ")+"handbook diagrams %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
