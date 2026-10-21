extends SceneTree
## Geometry acceptance, not graphical/rendering acceptance.
const Row=preload("res://src/hardware_foundations/circuit_module_row.gd")
const Visual=preload("res://src/hardware_foundations/component_visual_layout.gd")
var checks: int=0
var failures: int=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var snapshot: Dictionary=Visual.freeze("geometry-fixture",{"A":{"x":0,"y":0},"B":{"x":120,"y":160}})
	for kind: StringName in [&"alu1",&"mux4",&"decoder1_to_2",&"register4",&"full_adder"]:
		for custom: bool in [false,true]:
			for count: int in [1,2,3,5,6]:
				for index: int in count:
					var row=Row.new();root.add_child(row)
					row.configure(kind,"name","A","B",index,count,true,true,1,4)
					row.size=Vector2(320,38)
					if custom: row.set_visual_snapshot(snapshot,"geometry-fixture")
					var polygon: PackedVector2Array=row.body_polygon()
					check(not Geometry2D.triangulate_polygon(polygon).is_empty(),"Every displayed row is triangulatable")
					for side: int in 2:
						var t: float=(float(index)+0.5)/count
						var pin:=Vector2(row._body_left(t) if side==0 else row._body_right(t),row.size.y/2)
						var edge: PackedVector2Array=row.body_edge_points(side)
						var distance: float=INF
						for segment: int in edge.size()-1:
							distance=minf(distance,pin.distance_to(Geometry2D.get_closest_point_to_segment(pin,edge[segment],edge[segment+1])))
						check(distance<0.001,"Pin ends on actual rendered body boundary, including a mid-row notch")
						check(row.visual_hit_test(pin),"Port/body endpoint stays selectable")
					row.free()
	var reused=Row.new();root.add_child(reused)
	reused.set_visual_snapshot(snapshot,"geometry-fixture")
	reused.configure(&"register4","REG","D","Q",0,1,true,true,4,4)
	check(reused.visual_bands.is_empty(),"Reconfiguring a recycled row cannot retain another component's custom shape")
	reused.free()
	print("PASS: test_component_visual_geometry " if failures==0 else "FAIL: test_component_visual_geometry ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
