extends SceneTree
const Lab = preload("res://experiments/service_plan/lab.gd")
const Model = preload("res://experiments/service_plan/model.gd")
const Store = preload("res://experiments/service_plan/session_store.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func select_group(scene: Lab, index: int) -> void:
	scene.group_list.select(index); scene.group_list.item_selected.emit(index)
func selection_is(scene: Lab, index: int) -> bool:
	return scene.selected_group == index and scene.group_list.get_selected_items() == PackedInt32Array([index])
func remove_fixture() -> void:
	# PATH is this suite's nonce file, even when run outside the isolated verifier.
	for suffix: String in ["",".bak",".tmp"]:
		if FileAccess.file_exists(Store.PATH+suffix): DirAccess.remove_absolute(Store.PATH+suffix)
func check_feedback(scene: Lab, english: bool, persistent: bool, context: String) -> void:
	check(scene.status.text.contains("recorded measurements") if english else scene.status.text.contains("旧实测不变"),context+": undo feedback distinguishes the draft from recorded evidence")
	if persistent:
		check(scene.session_dirty and scene.notice_key == "dirty" and scene.status.text.contains("Unsaved" if english else "尚未保存"),context+": the current draft is explicitly unsaved")
	else:
		check(not scene.session_dirty and scene.status.text.contains("Temporary session" if english else "临时会话") and not scene.status.text.contains("save before" if english else "请保存"),context+": temporary feedback does not promise a Save operation")

func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var original_path: String = Store.PATH
	Store.PATH = "user://service-undo-"+Crypto.new().generate_random_bytes(8).hex_encode()+".json"
	for english: bool in [false,true]:
		for persistent: bool in [false,true]:
			remove_fixture()
			var scene := Lab.new(); scene.persistent_session = persistent; root.add_child(scene); await process_frame
			scene.english = english; scene.build(); await process_frame
			var context: String = ("en" if english else "zh")+(" persistent" if persistent else " temporary")
			scene.run_current()
			var recording: String = JSON.stringify(scene.history[0])
			var initial: Dictionary = scene.plan.duplicate(true)
			scene.move_to.value = 24; scene.move_button.pressed.emit()
			var moved: Dictionary = scene.plan.duplicate(true)
			check(selection_is(scene,23) and scene.plan.groups[23] == [0],context+": moving A0 selects its destination")
			var saved_notice: String = ""
			if persistent:
				scene.save_session(); saved_notice = scene.status.text
				check(not scene.session_dirty and Store.read_session().draft == moved,context+": Save actually persists the moved recipe without clearing Undo")
			scene.undo_button.pressed.emit()
			check(scene.plan == initial and selection_is(scene,0) and scene.plan.groups[0] == [0],context+": Undo moves A0 back and restores its original selection")
			check_feedback(scene,english,persistent,context)
			if persistent:
				check(scene.status.text != saved_notice and Store.read_session().draft == moved,context+": Undo replaces stale Save success while retaining the disk snapshot")
				scene.save_session(); saved_notice = scene.status.text
				check(not scene.session_dirty and Store.read_session().draft == initial,context+": saving the undone draft leaves Redo available")
			scene.redo_button.pressed.emit()
			check(scene.plan == moved and selection_is(scene,23),context+": Redo restores A0 at its moved destination")
			check_feedback(scene,english,persistent,context)
			if persistent:
				check(scene.status.text != saved_notice and Store.read_session().draft == initial,context+": Redo replaces Save success without silently saving")
			scene.undo_button.pressed.emit()
			select_group(scene,5); scene.merge_button.pressed.emit()
			var joined: Dictionary = scene.plan.duplicate(true)
			check(scene.plan.groups[5] == [7,13] and selection_is(scene,5),context+": joining B1 and C1 selects their combined group")
			scene.undo_button.pressed.emit()
			check(scene.plan == initial and selection_is(scene,5) and scene.plan.groups[5] == [7],context+": Undo Join restores the original B1 group and selection")
			scene.redo_button.pressed.emit()
			check(scene.plan == joined and selection_is(scene,5) and not scene.split_button.disabled,context+": Redo Join restores the combined group and valid split action")
			scene.split_button.pressed.emit()
			check(scene.plan == initial and selection_is(scene,5),context+": Split selects the first restored part")
			scene.undo_button.pressed.emit()
			check(scene.plan == joined and selection_is(scene,5) and scene.split_at.max_value == 1,context+": Undo Split restores its combined editing target")
			scene.redo_button.pressed.emit()
			check(scene.plan == initial and selection_is(scene,5) and scene.split_button.disabled,context+": Redo Split restores singleton selection and disables another split")

			scene.slots.value = 3; select_group(scene,18)
			var before_restore: Dictionary = scene.plan.duplicate(true)
			scene.restore_button.pressed.emit()
			check(scene.plan == initial and selection_is(scene,0) and scene.slots.value == 1,context+": history restore copies the measured recipe as an unrun draft")
			scene.undo_button.pressed.emit()
			check(scene.plan == before_restore and selection_is(scene,18) and scene.slots.value == 3,context+": Undo history restore recovers the exact prior draft and selected group")
			var redo_size: int = scene.redo_stack.size()
			scene.edit(scene.plan.duplicate(true),0)
			check(scene.redo_stack.size() == redo_size and selection_is(scene,18),context+": an identical-plan no-op preserves Redo and selection")
			scene.unlocked = 1; scene.change_task(1)
			scene.redo_button.pressed.emit()
			check(scene.task == 1 and scene.plan == initial and selection_is(scene,0),context+": rebuilding for a new contract preserves shared draft Redo without undoing the contract switch")
			scene.undo_button.pressed.emit(); scene.format_buttons[0].pressed.emit()
			check(scene.redo_stack.is_empty() and scene.redo_button.disabled and selection_is(scene,18),context+": a new edit after Undo replaces the abandoned Redo branch")
			check(scene.history.size() == 1 and JSON.stringify(scene.history[0]) == recording and scene.support_plans.is_empty(),context+": draft Undo, Redo and restore never mutate history or grant supports")
			check(Model.validate(scene.plan).is_empty(),context+": editor snapshots preserve valid request coverage and stream order")
			if persistent:
				var saved: Dictionary = Store.read_session()
				scene.reload_recovered_session()
				check(scene.plan == saved.draft and scene.undo_stack.is_empty() and scene.redo_stack.is_empty() and not scene.session_dirty,context+": explicit reload restores the saved recipe and clears session-only editing context")
				check(Store.decode(FileAccess.get_file_as_string(Store.PATH)).ok,context+": editor selection snapshots do not alter the existing save format")
			scene.queue_free(); await process_frame; await process_frame
			if persistent:
				var reopened := Lab.new(); reopened.persistent_session = true; root.add_child(reopened); await process_frame
				check(reopened.plan == initial and reopened.undo_stack.is_empty() and reopened.redo_stack.is_empty() and reopened.undo_button.disabled and reopened.redo_button.disabled,context+": fresh reopen retains the saved draft without session Undo or Redo")
				reopened.undo(); reopened.redo()
				check(not reopened.session_dirty,context+": unavailable Undo and Redo do not make a reopened save dirty")
				reopened.queue_free(); await process_frame; await process_frame
			remove_fixture()
	Store.PATH = original_path
	print("PASS: test_service_undo_context " if failures == 0 else "FAIL: test_service_undo_context ",checks," checks, ",failures," failures")
	quit(1 if failures > 0 else 0)
