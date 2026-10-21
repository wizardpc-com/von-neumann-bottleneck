extends SceneTree
const Visual = preload("res://src/hardware_foundations/component_visual_layout.gd")
const Reusable = preload("res://src/circuit/reusable_component.gd")
var checks: int = 0
var failures: int = 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	# Explicit geometric fixtures, not user works or proof of circuit validation.
	var compact := {"A":{"x":0,"y":0},"B":{"x":120,"y":0}}
	var stepped := {"A":{"x":0,"y":0},"B":{"x":120,"y":160}}
	var first: Dictionary = Visual.freeze("verified-source",compact)
	var second: Dictionary = Visual.freeze("verified-source",stepped)
	check(Visual.is_valid(first,"verified-source"),"Valid bounded visual snapshot")
	check(first.bands != second.bands,"Same identity different layout makes different body")
	var shifted := {"B":{"x":1120,"y":-40},"A":{"x":1000,"y":-40}}
	check(Visual.freeze("verified-source",shifted)==first,"Translation and insertion order invariant")
	var jittered := {"A":{"x":0,"y":0},"B":{"x":121,"y":1}}
	check(Visual.freeze("verified-source",jittered)==first,"Sub-grid editing jitter keeps the same footprint")
	var roundtrip: Dictionary = JSON.parse_string(JSON.stringify(second))
	check(Visual.is_valid(roundtrip,"verified-source"),"JSON restart representation accepted")
	var rect := Rect2(0,0,240,160)
	var polygon: PackedVector2Array = Visual.outline(second,"verified-source",rect)
	check(polygon.size()>=4,"Single body outline generated")
	check(not Geometry2D.triangulate_polygon(polygon).is_empty(),"Outline is triangulatable")
	for point: Vector2 in polygon:
		check(point.x>=0 and point.x<=240 and point.y>=0 and point.y<=160,"Outline bounded")
	check(Geometry2D.is_point_in_polygon(Vector2(120,80),polygon),"Central label/click area stays solid")
	check(Visual.outline(second,"different-source",rect).is_empty(),"Source mismatch fails closed")
	check(Visual.freeze("",compact).is_empty(),"No verified source means no snapshot")
	check(Visual.freeze("source",{"bad":{"x":NAN}}).is_empty(),"NaN rejected")
	check(Visual.freeze("source",{"bad":{"x":"0"}}).is_empty(),"Unexpected coordinate type rejected")
	check(Visual.freeze("source",{"bad":{"w":-1}}).is_empty(),"Invalid dimensions rejected")
	check(Visual.freeze("source",{7:{"x":0,"y":0}}).is_empty(),"Invalid component identity type rejected")
	for layout: Dictionary in [
		{"one":{"x":0,"y":0,"w":1,"h":1}},
		{"left":{"x":-10000,"y":0},"right":{"x":10000,"y":0}},
		{"top":{"x":0,"y":-10000},"bottom":{"x":0,"y":10000}},
		{"a":{"x":0,"y":0},"b":{"x":1000,"y":500},"c":{"x":-1000,"y":1000}}
	]:
		var sample: Dictionary = Visual.freeze("boundary",layout)
		check(Visual.is_valid(sample,"boundary"),"Extreme/sparse layout remains bounded")
		var shape: PackedVector2Array = Visual.outline(sample,"boundary",rect)
		check(not Geometry2D.triangulate_polygon(shape).is_empty(),"Extreme/sparse envelope remains a single drawable body")
		check(Geometry2D.is_point_in_polygon(Vector2(120,80),shape),"Sparse construction retains safe middle grip")
	check(Visual.outline({},"source",rect).is_empty(),"Legacy/derived absent layout falls back")
	var definition := Reusable.new()
	var before: String = definition.canonical_signature()
	definition.visual_snapshot = Visual.freeze("source",compact)
	check(definition.canonical_signature()==before,"Presentation does not enter logic signature")
	var copy = definition.duplicate_component_definition()
	check(copy.visual_snapshot == definition.visual_snapshot,"Duplicate retains frozen presentation")
	copy.visual_snapshot.clear()
	check(not definition.visual_snapshot.is_empty(),"Duplicate does not alias source presentation")
	var corrupt: Dictionary = first.duplicate(true)
	corrupt.bands[0] = [4,8]
	check(not Visual.is_valid(corrupt,"verified-source"),"Unrelated outline cannot replace recorded occupancy")
	corrupt = first.duplicate(true)
	corrupt.cells[0] = NAN
	check(not Visual.is_valid(corrupt,"verified-source"),"Nonfinite serialized cells are rejected without conversion errors")
	corrupt = first.duplicate(true)
	corrupt.cells[0] = 1.0e100
	check(not Visual.is_valid(corrupt,"verified-source"),"Out-of-range finite cells reject before integer conversion")
	corrupt = first.duplicate(true)
	corrupt.bands[0][0] = -1.0e100
	check(not Visual.is_valid(corrupt,"verified-source"),"Out-of-range finite edges reject before integer conversion")
	corrupt = first.duplicate(true)
	corrupt.layout_digest = "not-the-footprint"
	check(not Visual.is_valid(corrupt,"verified-source"),"Footprint checksum mismatch falls back")
	var random:=RandomNumberGenerator.new()
	random.seed=20261022
	for sample_index: int in 250:
		var placements: Dictionary={}
		var translated: Dictionary={}
		for part_index: int in random.randi_range(1,32):
			var item: Dictionary={"x":random.randi_range(-1500,1500),"y":random.randi_range(-1500,1500),"w":random.randi_range(1,400),"h":random.randi_range(1,400)}
			placements[str(part_index)]=item
			translated[str(part_index)]={"x":item.x+4096,"y":item.y-4096,"w":item.w,"h":item.h}
		var sample: Dictionary=Visual.freeze("seeded-layout-fixture",placements)
		check(Visual.is_valid(sample,"seeded-layout-fixture"),"Seeded geometry remains valid")
		check(Visual.freeze("seeded-layout-fixture",translated)==sample,"Seeded geometry is translation invariant")
		var shape: PackedVector2Array=Visual.outline(sample,"seeded-layout-fixture",rect)
		check(not Geometry2D.triangulate_polygon(shape).is_empty(),"Seeded envelope is drawable")
		check(Geometry2D.is_point_in_polygon(rect.get_center(),shape),"Seeded envelope keeps the central grip")
	print("PASS: test_component_visual_layout " if failures==0 else "FAIL: test_component_visual_layout ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
