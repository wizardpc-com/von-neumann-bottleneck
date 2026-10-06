extends SceneTree
const Store = preload("res://experiments/representation_region/session_store.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var failures: int = 0
var checks: int = 0
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)
func button(scene: Node, handle: String) -> Button:
	return scene.find_child(handle,true,false) as Button
func name_design(scene: Node, label: String) -> void:
	(scene.find_child("DesignName",true,false) as LineEdit).text = label
	button(scene,"RememberDesign").pressed.emit()

func run() -> void:
	var original_path: String = Store.PATH
	Store.PATH = "user://representation-design-shelf.json"
	var plans: Array = []
	for i: int in 5: plans.append(Model.initial_plan())
	check(Store.write_session(Store.encode(0,plans,[])) == OK,"Isolated empty candidate fixture installed")
	var campaign: Node = root.get_node("GlobalSave")
	var campaign_before: Dictionary = campaign._save_snapshot(); campaign_before.erase("saved_at_utc")
	var scene = load("res://experiments/representation_region/region.tscn").instantiate()
	scene.persistent_session = true; root.add_child(scene); await process_frame
	check(scene.designs.is_empty() and button(scene,"RememberDesign").disabled,"An unrun draft has no collectible measured source")
	check(not scene.design_shelf.content.visible,"Collection starts collapsed beside history, preserving primary evidence")
	scene.remember_design("Unrun draft")
	check(scene.designs.is_empty(),"Direct naming also refuses an absent measured record")
	button(scene,"ToggleDesignShelf").button_pressed = true
	check(scene.design_shelf.content.visible,"Collection foldout can be opened without running")
	scene.run_current()
	var original_plan: Array = scene.history[0].plan.duplicate(true)
	var original_signature: String = scene.history[0].traces[0].canonical_signature()
	scene.edit_plan(Model.split(scene.plan,0,17)); scene.run_current()
	scene.edit_plan(Model.represent(scene.plan,0,"rle"))
	var dirty_draft: Array = scene.plan.duplicate(true)
	scene.select_run(0)
	check(scene.recorded_plan_label.text.contains("与当前草稿不同"),"Chosen old measurement is visibly distinct from the dirty draft")
	var history_before: int = scene.history.size()
	var completed_before: Array = scene.completed.duplicate()
	var supports_before: Dictionary = scene.support_plans.duplicate(true)
	name_design(scene,"  RAW before cut  ")
	check(scene.designs.size() == 1 and scene.designs[0].name == "RAW before cut","Naming trims the player label")
	check(scene.designs[0].task == 0 and scene.designs[0].plan == original_plan,"Naming captures the selected old measurement, never the latest run or dirty draft")
	check(scene.plan == dirty_draft and scene.history.size() == history_before,"Naming preserves editable draft and measurement count")
	check(scene.session_dirty,"Naming participates in the explicit Save lifecycle")
	check(scene.history[0].traces[0].canonical_signature() == original_signature,"Naming never mutates recorded authoritative evidence")
	name_design(scene,"RAW reference")
	check(scene.designs.size() == 1 and scene.designs[0].name == "RAW reference","Renaming the same measured task/plan updates one collection entry")
	scene.remember_design("bad"+String.chr(127))
	check(scene.designs[0].name == "RAW reference" and scene.status.text.contains("控制字符"),"Invalid names leave the collection unchanged and explain the constraint")
	button(scene,"Language").pressed.emit(); await process_frame
	var choices: OptionButton = scene.find_child("NamedDesigns",true,false)
	check(choices.item_count == 1 and choices.get_item_text(0).contains("RAW reference"),"Player label survives language rebuilding")
	scene.remember_design("")
	check(scene.status.text.contains("1–48") and scene.status.text.contains("characters"),"Name errors are localized in English")
	scene.save_session()
	check(not scene.session_dirty and Store.read_session().designs == scene.designs,"Explicit Save persists the named alternative")

	scene.change_task(1)
	scene.edit_plan(Model.split(scene.plan,0,19))
	var departing_draft: Array = scene.plan.duplicate(true)
	button(scene,"RestoreDesign").pressed.emit()
	check(scene.task == 0 and scene.plan == original_plan,"Copy routes the named design to its original task")
	check(scene.drafts[1].plan == departing_draft,"Cross-task copy retains the departing task draft")
	check(scene.completed == completed_before and scene.support_plans == supports_before and scene.history.size() == history_before,"Copy grants neither task completion, support nor a new measurement")
	check(scene.designs[0].plan == original_plan,"Copy preserves the collected immutable plan")
	button(scene,"Undo").pressed.emit()
	check(scene.plan == dirty_draft,"Undo restores the draft displaced by named-design copy")
	check(scene.designs[0].plan == original_plan and scene.history[0].plan == original_plan,"Undo and draft edits remain separate from collection/history ownership")
	button(scene,"RestoreDesign").pressed.emit()
	var undo_size: int = scene.undo_stack.size()
	button(scene,"RestoreDesign").pressed.emit()
	check(scene.undo_stack.size() == undo_size,"Copying an identical design adds no fake Undo step")

	scene.change_task(1)
	for i: int in 101: scene.run_current()
	check(scene.history.size() == 100,"Measured comparisons still obey their existing rolling cap")
	var retained_old_run: bool = false
	for recorded: Dictionary in scene.history:
		if int(recorded.task) == 0 and recorded.plan == original_plan: retained_old_run = true
	check(not retained_old_run and scene.designs[0].plan == original_plan,"Named alternative survives after its measured source leaves rolling history")
	scene.save_session()
	var saved: Dictionary = Store.read_session()
	check(saved.ok and saved.runs.size() == 100 and saved.designs.size() == 1,"Save retains capped comparisons and independent named collection")
	check(saved.supports.is_empty(),"A collected unmet plan is never serialized as protected success")
	scene.queue_free(); await process_frame
	scene = load("res://experiments/representation_region/region.tscn").instantiate()
	scene.persistent_session = true; root.add_child(scene); await process_frame
	check(scene.designs == saved.designs and scene.history.size() == 100,"Independent scene restart reloads labels and plans after history truncation")
	choices = scene.find_child("NamedDesigns",true,false)
	check(choices.get_item_text(0).contains("RAW reference"),"Reopened UI identifies the saved player label")
	check(scene.completed == completed_before and scene.support_plans.is_empty(),"Restored collection cannot grant recomputed success")
	button(scene,"RemoveDesign").pressed.emit()
	check(scene.designs.is_empty() and scene.session_dirty,"Removal is a local unsaved collection edit")
	check(Store.read_session().designs.size() == 1 and scene.history.size() == 100,"Removal preserves saved bytes and performed records until Save")
	scene.confirm_recovery(scene.reload_recovered_session)
	var replace := scene.get_node_or_null("ReplaceUnsavedRecovery") as ConfirmationDialog
	check(replace != null and replace.visible and scene.designs.is_empty(),"Reload requires the existing explicit decision before replacing unsaved removal")
	if replace != null: replace.canceled.emit()
	await process_frame
	check(scene.designs.is_empty() and scene.session_dirty,"Canceling reload retains the local removal")
	scene.confirm_recovery(scene.reload_recovered_session)
	replace = scene.get_node_or_null("ReplaceUnsavedRecovery") as ConfirmationDialog
	if replace != null: replace.confirmed.emit()
	await process_frame
	check(scene.designs == saved.designs and not scene.session_dirty,"Confirmed reload replaces local collection changes from saved state")
	button(scene,"RemoveDesign").pressed.emit(); scene.save_session()
	check(Store.read_session().designs.is_empty() and not scene.session_dirty,"Explicit Save persists removal")
	scene.reload_recovered_session()
	check(scene.designs.is_empty(),"Reload clears prior collection before reading an empty saved collection")
	var campaign_after: Dictionary = campaign._save_snapshot(); campaign_after.erase("saved_at_utc")
	check(campaign_before == campaign_after,"Collection lifecycle never changes core campaign progress")
	scene.queue_free(); await process_frame
	Store.PATH = original_path
	print("PASS: test_representation_design_shelf " if failures == 0 else "FAIL: test_representation_design_shelf ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
