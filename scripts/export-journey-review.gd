extends SceneTree
## Exports production map geometry and current fresh-profile contracts for design review.
func _init() -> void: call_deferred("run")
func point(v: Vector2) -> Array: return [v.x,v.y]
func run() -> void:
	var directory: String="res://.godot/journey-review"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):directory=arg.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var nav: Node=root.get_node("TaskNavigation")
	var canvas: Control=load("res://src/campaign/task_tree_canvas.gd").new()
	root.add_child(canvas)
	var output: Dictionary={"status":"production geometry review, not a game screenshot","locales":{}}
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		var rows: Array[Dictionary]=nav.journey_tasks()
		canvas.configure(rows)
		var record: Dictionary={"size":point(canvas.world_size),"nodes":[],"regions":[],"edges":[]}
		for region: int in canvas.region_rects:
			var rect: Rect2=canvas.region_rects[region]
			record.regions.append({"region":region,"position":point(rect.position),"size":point(rect.size),"color":"#"+canvas._color(region).to_html(false)})
		for row: Dictionary in rows:
			record.nodes.append({"key":row.key,"title":row.title,"region":row.region,"position":point(canvas.positions[row.key]),"size":point(canvas.NODE_SIZE),"optional":row.optional,"unlocked":row.unlocked,"completed":row.completed})
			for recommended: bool in [false,true]:
				for dep: String in row.get("recommended_from",[]) if recommended else row.dependencies:
					var points: Array=[]
					for at: Vector2 in canvas.edge_points(row,dep):points.append(point(at))
					record.edges.append({"from":dep,"to":row.key,"recommended":recommended,"points":points})
		output.locales[locale]=record
	var file:=FileAccess.open(directory.path_join("map.json"),FileAccess.WRITE)
	if file==null:push_error("Cannot write journey review");quit(1);return
	file.store_string(JSON.stringify(output,"\t"));file.close()
	print("PASS: exported actual journey geometry in two locales")
	canvas.queue_free();await process_frame;quit(0)
