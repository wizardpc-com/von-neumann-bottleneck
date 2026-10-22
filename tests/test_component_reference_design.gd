extends SceneTree
## Expected silhouettes transcribed from the user-supplied 01_all_components.png bundle.
const Style = preload("res://src/hardware_foundations/component_visual_style.gd")
const Row = preload("res://src/hardware_foundations/circuit_module_row.gd")
const Visual = preload("res://src/hardware_foundations/component_visual_layout.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func run() -> void:
	var rect := Rect2(0, 0, 264, 144)
	var alu := PackedVector2Array([Vector2(10,0),Vector2(246,0),Vector2(264,72),Vector2(246,144),Vector2(10,144),Vector2(0,134),Vector2(10,72),Vector2(0,10)])
	var mux := PackedVector2Array([Vector2(0,0),Vector2(264,18),Vector2(264,126),Vector2(0,144)])
	var decoder := PackedVector2Array([Vector2(0,18),Vector2(264,0),Vector2(264,144),Vector2(0,126)])
	for kind: StringName in [&"alu1", &"alu4"]: check(Style.shell(kind, rect) == alu, "ALU keeps the supplied eight-vertex notched shell")
	for kind: StringName in [&"mux4", &"mux2_word"]: check(Style.shell(kind, rect) == mux, "MUX converges toward its output")
	check(Style.shell(&"decoder1_to_2", rect) == decoder, "Decoder expands toward its outputs")
	check(Style.shell(&"control", rect) != decoder and Style.shell(&"control", rect).size() == 8, "Controller uses its chamfered branching-module shell")
	for kind: StringName in [&"half_adder", &"full_adder", &"sr_latch", &"register1", &"register4", &"ram2x4", &"tiny_computer", &"cpu", &"ram", &"bus"]:
		var shell: PackedVector2Array = Style.shell(kind, rect)
		check(shell.size() == 8 and not Geometry2D.triangulate_polygon(shell).is_empty(), "Supplied family keeps a valid chamfered shell: " + String(kind))
		check(shell[0].x == (7.0 if Style.family(kind) == &"storage" else 10.0), "Family corner sizes match reference: " + String(kind))
	for kind: StringName in [&"half_adder", &"full_adder", &"mux4", &"mux2_word", &"alu1", &"alu4", &"sr_latch", &"register1", &"register4", &"ram2x4", &"decoder1_to_2", &"control", &"tiny_computer"]:
		for count: int in [1, 2, 3, 6]:
			var before_right: float = 0.0
			var before_left: float = 0.0
			for index: int in count:
				var row := Row.new()
				root.add_child(row)
				row.configure(kind, "name", "A", "Q", index, count, true, true, 1, 4)
				row.size = Vector2(250,34)
				for corner: Vector2 in row.family_tab_polygon():
					check(Geometry2D.is_point_in_polygon(corner, row._builtin_polygon()), "Family accent stays inside the supplied silhouette")
				var left: PackedVector2Array = row.body_edge_points(0)
				var right: PackedVector2Array = row.body_edge_points(1)
				check(not Geometry2D.triangulate_polygon(row.body_polygon()).is_empty(), "Actual row slice is drawable: " + String(kind))
				if index > 0: check(is_equal_approx(left[0].x, before_left) and is_equal_approx(right[0].x, before_right), "Shared whole-shell slices join without seams")
				before_left = left[-1].x; before_right = right[-1].x
				var mark: Dictionary = row.name_layout()
				check(mark.icon_rect.position.y > mark.rect.end.y and is_equal_approx(mark.center.x, mark.icon_rect.get_center().x), "One centered short name sits above its functional icon")
				check(mark.font_size >= 12, "Normal module names remain readable")
				row.free()
	var snapshot := Visual.freeze("reference-source", {"A":{"x":0,"y":0},"B":{"x":160,"y":180}})
	var frozen := Row.new()
	root.add_child(frozen)
	frozen.configure(&"half_adder", "HA", "A", "SUM", 0, 2, true, true, 1, 1)
	frozen.size = Vector2(250,34)
	frozen.set_visual_snapshot(snapshot, "reference-source")
	check(frozen.visual_bands == snapshot.bands, "Supplied family styling does not replace a player's recorded bands")
	for t: float in [0.0,0.25,0.5,0.75,1.0]:
		check(is_equal_approx(frozen._body_left(t),28.0+frozen._visual_edge(t,0)*6.0), "Frozen left edge retains its recorded sampling")
	frozen.free()
	print(("PASS: " if failures == 0 else "FAIL: ") + "component reference design %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
