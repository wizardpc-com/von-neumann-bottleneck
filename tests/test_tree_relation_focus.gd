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
	check(JSON.stringify(tasks)==before,"Presentation never modifies prerequisite data or availability")
	canvas.queue_free();await process_frame
	print("PASS: test_tree_relation_focus " if failures==0 else "FAIL: test_tree_relation_focus ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
