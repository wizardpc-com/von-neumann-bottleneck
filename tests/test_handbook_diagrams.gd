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
