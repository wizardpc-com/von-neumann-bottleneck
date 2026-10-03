extends SceneTree
const Board = preload("res://experiments/representation_region/byte_board.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var failures: int = 0
var checks: int = 0
var chosen: int = -1
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func run() -> void:
	var board = Board.new(); root.add_child(board); board.size = Vector2(530,128)
	var data: Array[int] = Model.asset(0)
	var plan: Array[Dictionary] = Model.split(Model.initial_plan(),0,17)
	board.configure(data,plan,0)
	board.block_selected.connect(func(index: int) -> void: chosen = index)
	await process_frame
	for i: int in 64:
		check(board.address_at(board.cell_rect(i).get_center()) == i,"Address-to-cell mapping is exact")
		check(Rect2(Vector2.ZERO,board.size).encloses(board.cell_rect(i)),"Byte fits the narrow editor")
	check(board.address_at(Vector2(-1,0)) == -1,"Outside input rejected")
	check(board.block_at(16) == 0 and board.block_at(17) == 1,"Non-row-aligned partition respected")
	var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true; event.position = board.cell_rect(20).get_center()
	board._gui_input(event); check(chosen == 1,"Byte click selects corresponding partition")
	check(plan[0].end == 17 and data == Model.asset(0),"View does not mutate authored bytes or draft")
	data[0] = 255; plan[0].end = 15
	check(board.values[0] != 255 and board.partitions[0].end == 17,"Board owns a defensive copy")
	board.queue_free(); await process_frame
	var scene = load("res://experiments/representation_region/region.tscn").instantiate(); root.add_child(scene); await process_frame
	check(scene.byte_boards.size() == 1 and scene.byte_boards[0].values == Model.asset(0),"Single asset view shows actual task bytes")
	scene.change_task(4); await process_frame
	check(scene.byte_boards.size() == 2,"Cross-asset task shows both public assets")
	check(scene.byte_boards[0].values != scene.byte_boards[1].values,"Different assets are not silently reused")
	scene.queue_free(); await process_frame
	print("PASS: test_representation_visual " if failures == 0 else "FAIL: test_representation_visual ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
