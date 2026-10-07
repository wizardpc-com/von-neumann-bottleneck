extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func select_group(scene: Lab, index: int) -> void:
	scene.group_list.select(index)
	scene.group_list.item_selected.emit(index)

func run() -> void:
	for english: bool in [false,true]:
		var scene := Lab.new(); root.add_child(scene); await process_frame
		scene.english = english; scene.build(); await process_frame
		var locale: String = "en" if english else "zh"
		check(scene.split_button.disabled and not scene.split_at.editable,locale+": singleton has no split operation or editable boundary")
		scene.run_current()
		var measured: String = JSON.stringify(scene.history[0])
		for index: int in 3: scene.merge_button.pressed.emit()
		check(scene.plan.groups[0] == [0,6,12,18] and scene.split_at.max_value == 3,locale+": joining requests exposes only the three internal boundaries")
		scene.split_at.value = 2
		check(not scene.split_button.disabled and scene.split_at.editable,locale+": changing the boundary keeps a valid split ready")
		var four_request_plan: Dictionary = scene.plan.duplicate(true)
		scene.split_button.pressed.emit()
		check(scene.plan.groups[0] == [0,6] and scene.plan.groups[1] == [12,18],locale+": split acts on the entered boundary rather than silently doing nothing")
		scene.undo_button.pressed.emit()
		check(scene.plan == four_request_plan and scene.split_at.max_value == 3,locale+": Undo restores the group and its available boundaries")
		select_group(scene,1); scene.merge_button.pressed.emit()
		check(scene.plan.groups[1] == [1,7],locale+": second group is a two-request editing target")
		select_group(scene,0); scene.split_at.value = 3
		var before_selection: Dictionary = scene.plan.duplicate(true)
		var undo_count: int = scene.undo_stack.size()
		select_group(scene,1)
		check(scene.split_at.max_value == 1 and scene.split_at.value == 1 and not scene.split_button.disabled,locale+": switching from a long group clamps the stale boundary to the pair's only valid split")
		check(scene.plan == before_selection and scene.undo_stack.size() == undo_count,locale+": changing selection and range does not edit the draft")
		scene.split_at.value = 23
		check(scene.split_at.value == 1 and not scene.split_button.disabled,locale+": out-of-range entry cannot leave an enabled invalid split")
		scene.split_button.pressed.emit()
		check(scene.plan.groups[1] == [1] and scene.plan.groups[2] == [7],locale+": the formerly silent pair split now changes the plan")
		check(scene.split_button.disabled and not scene.split_at.editable,locale+": split result immediately disables singleton splitting")
		scene.undo_button.pressed.emit()
		check(scene.plan == before_selection and not scene.split_button.disabled and scene.split_at.max_value == 1,locale+": Undo re-enables the restored pair's valid action")
		scene.redo_button.pressed.emit()
		check(scene.split_button.disabled and not scene.split_at.editable,locale+": Redo refreshes singleton boundary availability")
		check(Model.validate(scene.plan).is_empty(),locale+": split and undo preserve every request and stream dependency")
		check(scene.history.size() == 1 and JSON.stringify(scene.history[0]) == measured,locale+": boundary changes never rerun or alter measured evidence")
		scene.queue_free(); await process_frame
	print(("PASS: " if failures == 0 else "FAIL: ")+"Service split actions: %d checks, %d failures" % [checks,failures])
	quit(1 if failures > 0 else 0)
