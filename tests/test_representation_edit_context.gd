extends SceneTree
## Isolated saved drafts and real measurements exercise redundant edit actions.
const Store = preload("res://experiments/representation_region/session_store.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool,message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func settle() -> void:
	for frame: int in 5: await process_frame
func button(scene: Node,id: String) -> Button: return scene.find_child(id,true,false) as Button
func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var localization: Node = root.get_node("Localization")
	var old_locale: String = localization.current_locale()
	var nav: Node = root.get_node("TaskNavigation")
	var old_pending: String = nav.pending; var old_selected: String = nav.selected
	var old_from_tree: bool = nav.from_tree; var old_recent: String = nav.last_visited_task
	var original_path: String = Store.PATH
	var original_auto_quit: bool = auto_accept_quit
	var campaign: Node = root.get_node("GlobalSave")
	var before: Dictionary = campaign._save_snapshot(); before.erase("saved_at_utc")
	var drafts: Array = []
	for index: int in 5: drafts.append(Model.initial_plan())
	var raw: String = Store.encode(2,drafts,[])
	var prefix: String = "user://representation-edit-context-"+Crypto.new().generate_random_bytes(8).hex_encode()
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		Store.PATH = prefix+"-"+locale+".json"
		check(Store.write_session(raw) == OK,"Isolated saved task fixture installed")
		nav.pending = nav.candidate_key("representation",2); nav.from_tree = true
		var scene = load("res://experiments/representation_region/region.tscn").instantiate()
		scene.persistent_session = true; scene.candidate_journey = true; root.add_child(scene); await settle()
		check(scene.task == 2 and nav.pending.is_empty() and scene.blocks != null,"Same saved/pending task still builds its initial workbench")
		check(not scene.session_dirty and scene.session_notice.contains("Drafts restored" if locale == "en" else "已恢复"),"Initial same-task entry retains its true restore notice")
		var restored_notice: String = scene.session_notice
		var blocks_id: int = scene.blocks.get_instance_id()
		button(scene,"Task2").pressed.emit(); await settle()
		check(scene.blocks.get_instance_id() == blocks_id and scene.status.text == restored_notice and not scene.session_dirty,"Repeated task selection leaves restored UI and clean state intact")

		scene.run_current()
		var history_count: int = scene.history.size()
		var signature: String = scene.history[0].traces[0].canonical_signature()
		var completed: Array = scene.completed.duplicate()
		var supports: Dictionary = scene.support_plans.duplicate(true)
		button(scene,"ToggleDesignShelf").button_pressed = true
		var name_field := scene.find_child("DesignName",true,false) as LineEdit
		name_field.text = "Unsubmitted design name"
		scene.trace_player.seek(2)
		var replay_index: int = scene.trace_player.current
		var shelf_id: int = scene.design_shelf.get_instance_id()
		var feedback: String = scene.status.text
		button(scene,"Task2").pressed.emit(); await settle()
		var current_name := scene.find_child("DesignName",true,false) as LineEdit
		check(scene.design_shelf.get_instance_id() == shelf_id and scene.design_shelf.content.visible and current_name != null and current_name.text == "Unsubmitted design name","Current task click preserves the open collection and unsubmitted name")
		check(scene.trace_player.current == replay_index and scene.status.text == feedback,"Current task click preserves replay position and operation feedback")
		check(scene.session_dirty and scene.history.size() == history_count and scene.history[0].traces[0].canonical_signature() == signature,"Redundant task selection keeps real dirty state and immutable evidence")

		button(scene,"RememberDesign").pressed.emit()
		check(scene.designs.size() == 1 and scene.designs[0].task == 2,"Only explicit naming collects the actual selected measurement")
		scene.edit_plan(Model.split(scene.plan,0,17))
		var cut_plan: Array = scene.plan.duplicate(true)
		scene.edit_plan(Model.initial_plan())
		var undo_count: int = scene.undo_stack.size()
		button(scene,"RestoreDesign").pressed.emit()
		check(scene.undo_stack.size() == undo_count and scene.plan == Model.initial_plan(),"Copying the identical collection plan adds no Undo step")
		check(scene.status.text.contains("already your draft" if locale == "en" else "当前草稿已是") and not scene.status.text.contains("Undo" if locale == "en" else "可撤销"),"Identical copy explains the no-op instead of promising a new undoable restoration")
		button(scene,"Undo").pressed.emit()
		check(scene.plan == cut_plan,"Existing Undo still restores the actual prior edit")
		button(scene,"Undo").pressed.emit(); button(scene,"RestoreDesign").pressed.emit()
		check(scene.undo_stack.is_empty() and button(scene,"Undo").disabled,"Identical copy with no earlier edit does not invent an Undo action")
		scene.save_session()
		check(not scene.session_dirty,"Explicit isolated Save clears the genuine session changes")
		scene.change_task(0); scene.save_session()
		check(scene.task == 0 and not scene.session_dirty,"Another task selection can be explicitly saved")
		button(scene,"RestoreDesign").pressed.emit()
		check(scene.task == 2 and scene.plan == Model.initial_plan() and scene.session_dirty,"Cross-task identical copy still selects its original task and becomes unsaved")
		check(scene.undo_stack.is_empty() and scene.status.text.contains("already your draft" if locale == "en" else "当前草稿已是"),"Cross-task identical copy correctly avoids a fake Undo claim")
		check(Store.read_session().task == 0,"Copy never silently persists the task switch")
		check(scene.history.size() == history_count and scene.history[0].traces[0].canonical_signature() == signature and scene.completed == completed and scene.support_plans == supports,"Copy and undo never rerun, rewrite measured evidence or grant accepted support")
		scene.queue_free(); await settle()
		check(auto_accept_quit == original_auto_quit,"Fixture restores the existing close handler")
	Store.PATH = original_path; localization.set_locale(old_locale)
	nav.pending = old_pending; nav.selected = old_selected; nav.from_tree = old_from_tree; nav.last_visited_task = old_recent
	var after: Dictionary = campaign._save_snapshot(); after.erase("saved_at_utc")
	check(after == before,"Edit context adds no campaign completion or persistent authority")
	print("PASS: test_representation_edit_context " if failures == 0 else "FAIL: test_representation_edit_context ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
