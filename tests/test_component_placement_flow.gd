extends SceneTree
## Headless placement geometry/input checks; native pointer fluidity needs playtesting.
const Graph = preload("res://src/hardware_foundations/circuit_graph_edit.gd")
var checks: int = 0
var failures: int = 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _init() -> void: call_deferred("run")
func run() -> void:
	var graph = Graph.new()
	root.add_child(graph)
	graph.size = Vector2(1000,700)
	graph.branch_edit_enabled = true
	await process_frame
	var footprint := Vector2(180,96)
	var pointer := Vector2(325.25,284.75)
	for factor: float in [0.5,0.82,1.0,1.5]:
		graph.zoom = factor
		graph.scroll_offset = Vector2(93.5,67.25)
		var expected: Vector2 = (pointer+graph.scroll_offset)/graph.zoom-footprint*0.5
		graph.snapping_enabled = false
		check(graph.graph_position_for_local_pointer(pointer,footprint).is_equal_approx(expected),"Disabled snapping preserves fractional placement at every zoom")
		graph.snapping_enabled = true
		graph.snapping_distance = 20
		var snapped := Vector2(snappedf(expected.x,20),snappedf(expected.y,20))
		check(graph.graph_position_for_local_pointer(pointer,footprint).is_equal_approx(snapped),"Preview snaps in graph coordinates after scroll and zoom")
		var ghost := Control.new()
		graph.set_component_placement_preview(true,ghost,footprint)
		var motion := InputEventMouseMotion.new()
		motion.position = pointer
		graph._gui_input(motion)
		check(ghost.visible and ghost.position.is_equal_approx(snapped*graph.zoom-graph.scroll_offset),"Pointer motion moves the snapped child ghost immediately without waiting for graph draw")
		check(ghost.scale.is_equal_approx(Vector2.ONE*graph.zoom),"Ghost retains actual footprint at zoom")
		graph.placement_has_pointer = false
		graph._draw_component_placement_preview()
		check(not ghost.visible,"Pointer exclusion hides the ghost without altering placement state")
		graph.set_component_placement_preview(false)
		check(not graph.component_placement_enabled and not graph.placement_has_pointer,"Cancellation clears the armed preview")
	graph.free()
	await process_frame
	print("PASS: test_component_placement_flow " if failures==0 else "FAIL: test_component_placement_flow ",checks," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
