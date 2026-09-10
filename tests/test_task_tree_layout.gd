extends SceneTree
const Layout = preload("res://src/campaign/task_tree_layout.gd")
func _init() -> void: call_deferred("run")
func run() -> void:
	var tasks: Array[Dictionary] = root.get_node("TaskNavigation").tasks()
	# A future region and two tasks require no coordinates or canvas code.
	tasks.append({"key":"future/start","id":"start","region":5,"domain":"future","title":"Future start","dependencies":["chapter_4/mixed"]})
	tasks.append({"key":"future/branch","id":"branch","region":5,"domain":"future","title":"Future branch","dependencies":["future/start"]})
	var plan: Dictionary = Layout.build(tasks)
	var failures: Array[String] = []
	if not plan.errors.is_empty() or plan.positions.size()!=42: failures.append("All 40 current and two future tasks must be laid out")
	var keys: Array = plan.positions.keys()
	for a: int in range(keys.size()):
		var rect := Rect2(plan.positions[keys[a]],Layout.NODE_SIZE)
		if not Rect2(Vector2.ZERO,plan.size).encloses(rect): failures.append("Node outside world")
		for b: int in range(a+1,keys.size()):
			if rect.intersects(Rect2(plan.positions[keys[b]],Layout.NODE_SIZE)): failures.append("Overlapping nodes")
	if Layout.build(tasks).positions!=plan.positions: failures.append("Layout must be deterministic")
	for error: String in failures: push_error(error)
	if failures.is_empty(): print("PASS: automatic task/region DAG, future extension, deterministic non-overlapping nodes")
	quit(0 if failures.is_empty() else 1)
