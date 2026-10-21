extends SceneTree
var checks: int = 0
var failures: int = 0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1;push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var canvas: Control=load("res://src/campaign/task_tree_canvas.gd").new();root.add_child(canvas)
	var tasks: Array[Dictionary]=root.get_node("TaskNavigation").tasks()
	var before: String=JSON.stringify(tasks)
	canvas.configure(tasks)
	for task: Dictionary in tasks:
		canvas.hovered_key=task.key
		check(canvas.relation_to_focus(task.key)=="selected","Hovered task is visual focus")
		for dep: String in task.dependencies:
			check(canvas.relation_to_focus(dep)=="prerequisite","Actual prerequisites are highlighted")
			canvas.hovered_key=dep
			check(canvas.relation_to_focus(task.key)=="unlocks","Reverse relationship is downstream, not prerequisite")
			canvas.hovered_key=task.key
	var journey: Array[Dictionary]=root.get_node("TaskNavigation").journey_tasks()
	canvas.configure(journey)
	for task: Dictionary in journey:
		for dep: String in task.get("recommended_from",[]):
			for source: Dictionary in journey:
				if source.key==dep and source.region!=task.region:
					check(canvas.edge_points(task,dep).size()==6,"Cross-region routes use gutters even when both tasks share a domain")
	for task: Dictionary in journey:
		if task.dependencies.is_empty():continue
		var original: PackedVector2Array=canvas.edge_points(task,task.dependencies[0])
		var cache_size: int=canvas.edge_geometry_cache.size()
		canvas.pan+=Vector2(20,30);canvas.magnification=0.7
		var copy: PackedVector2Array=canvas.edge_points(task,task.dependencies[0])
		check(copy==original and canvas.edge_geometry_cache.size()==cache_size,"Camera movement reuses world-space edge geometry")
		copy[0]+=Vector2(999,999)
		check(canvas.edge_points(task,task.dependencies[0])==original,"Review consumers cannot mutate cached edge geometry")
		break
	var coarse:=PackedVector2Array([Vector2.ZERO,Vector2(100,0)])
	var fine:=PackedVector2Array()
	for x: int in range(0,101,5):fine.append(Vector2(x,0))
	var coarse_dashes: PackedVector2Array=canvas.dash_polyline(coarse,10,7)
	var fine_dashes: PackedVector2Array=canvas.dash_polyline(fine,10,7)
	for x: int in 100:
		var point:=Vector2(float(x)+0.25,0)
		var coarse_visible: bool=false
		var fine_visible: bool=false
		for index: int in range(0,coarse_dashes.size(),2):
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,coarse_dashes[index],coarse_dashes[index+1]))<0.01:coarse_visible=true
		for index: int in range(0,fine_dashes.size(),2):
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point,fine_dashes[index],fine_dashes[index+1]))<0.01:fine_visible=true
		check(coarse_visible==fine_visible,"Recommendation dash phase is independent of tessellation")
	check(canvas.dash_polyline(coarse,0,7).is_empty(),"Invalid dash settings cannot loop forever")
	canvas.configure(tasks)
	check(canvas.edge_geometry_cache.is_empty(),"A new layout invalidates its old edge cache")
	check(JSON.stringify(tasks)==before,"Presentation never modifies prerequisite data or availability")
	canvas.queue_free();await process_frame
	print("PASS: test_tree_relation_focus " if failures==0 else "FAIL: test_tree_relation_focus ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
