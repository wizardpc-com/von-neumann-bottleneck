extends SceneTree
## Geometry contracts from the supplied source/sink reference silhouettes.
const Symbol = preload("res://src/hardware_foundations/circuit_component_symbol.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var symbol := Symbol.new()
	root.add_child(symbol)
	symbol.size = Vector2(148, 60)
	for width: int in [1, 4, 8]:
		symbol.configure(&"input", "A", 60, width)
		var source: PackedVector2Array = symbol.terminal_body()
		check(Geometry2D.convex_hull(source).size() == source.size() + 1, "Source remains a convex tag")
		check(source[2].x > source[1].x and source[2].x > source[3].x, "Source point faces its output")
		symbol.configure(&"output", "SUM", 60, width)
		var sink: PackedVector2Array = symbol.terminal_body()
		check(not Geometry2D.triangulate_polygon(sink).is_empty(), "Notched output has a valid rendered polygon")
		check(sink[4].x > sink[0].x and sink[4].x < sink[1].x, "Sink has an inward left notch rather than an outward arrow")
		check(not Geometry2D.is_point_in_polygon(Vector2(53, 25), sink), "Left notch leaves the inlet cutout empty")
		check(Geometry2D.is_point_in_polygon(Vector2(73, 30), sink), "Sink retains its central value area")
		check(symbol.visual_hit_test(Vector2.ZERO + Vector2(0, 30), 0), "Real input-port lead stays selectable")
		symbol.configure(&"junction", "", 60, width)
		check(symbol.visual_hit_test(Vector2(74, 37), 0), "Circular junction body stays selectable above the lead")
		check(not symbol.visual_hit_test(Vector2(81, 37), 0), "Junction hit area excludes square-only corners at every width")
	for kind: StringName in [&"and", &"or", &"xor", &"not", &"nor"]:
		symbol.configure(kind, "", 60)
		check(symbol.gate_label() == String(kind).to_upper(), "Gate identity remains explicit: " + String(kind))
	symbol.free()
	print(("PASS: " if failures == 0 else "FAIL: ") + "reference symbols %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
