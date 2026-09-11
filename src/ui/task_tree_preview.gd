extends Control
## A quiet preview of the real prologue dependencies, without navigation or save effects.
const Layout = preload("res://src/campaign/task_tree_layout.gd")
var rows: Array[Dictionary] = []
var positions: Dictionary = {}
var bounds := Rect2()

func _ready() -> void:
	custom_minimum_size.y = 108
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for task: Dictionary in TaskNavigation.tasks():
		if task.region == 0: rows.append(task)
	var layout: Dictionary = Layout.build(rows)
	positions = layout.positions
	for task: Dictionary in rows:
		var rect := Rect2(positions[task.key], Layout.NODE_SIZE)
		bounds = rect if bounds.size == Vector2.ZERO else bounds.merge(rect)
	resized.connect(queue_redraw)

func _draw() -> void:
	if bounds.size == Vector2.ZERO: return
	var scale_factor: float = minf((size.x-30)/bounds.size.x, (size.y-18)/bounds.size.y)
	var offset := (size-bounds.size*scale_factor)/2-bounds.position*scale_factor
	for task: Dictionary in rows:
		var target: Vector2 = offset+(positions[task.key]+Layout.NODE_SIZE/2)*scale_factor
		for dependency: String in task.dependencies:
			if not positions.has(dependency): continue
			var origin: Vector2 = offset+(positions[dependency]+Layout.NODE_SIZE/2)*scale_factor
			var curve := Curve2D.new()
			curve.add_point(origin,Vector2.ZERO,Vector2((target.x-origin.x)/2,0))
			curve.add_point(target,Vector2((origin.x-target.x)/2,0),Vector2.ZERO)
			draw_polyline(curve.tessellate(),Color("386070"),1.5,true)
	for task: Dictionary in rows:
		var at: Vector2 = offset+(positions[task.key]+Layout.NODE_SIZE/2)*scale_factor
		var color := Color("67e8a5") if task.completed else Color("50d5ff") if task.unlocked else Color("486777")
		draw_circle(at,7,color if task.unlocked else Color("102a36"))
		draw_circle(at,7,color,false,1.5,true)
		if task.completed: draw_circle(at,2.5,Color("102a36"))
