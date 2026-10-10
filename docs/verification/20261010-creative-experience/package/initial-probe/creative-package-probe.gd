extends Node
const Catalog = preload("res://experiments/creation/catalog.gd")
var checks: Dictionary = {}
func settle() -> void:
	for frame: int in 6: await get_tree().process_frame
func _ready() -> void:
	checks.isolated = OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/package-")
	if not checks.isolated: get_tree().quit(1); return
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	get_tree().root.get_node("TaskNavigation").pending = ""
	get_tree().root.add_child(scene); await settle()
	scene.change_task(7); await settle()
	scene.session.data.draft.examples = [Catalog.sample(0),Catalog.sample(1)]
	scene.session.data.draft.order = 2; scene.session.data.draft.seed = 17
	scene.session.data.draft.initial = [0,1]; scene.session.data.draft.length = 64
	scene.session.data.draft.sampler = "weighted"
	scene.edit_draft(); scene.rebuild_editor_preserving_inputs(); await settle()
	scene.train_model(); scene.generate_work(); scene.pin_creation_a(); await settle()
	var a: Dictionary = scene.pinned_creation.duplicate(true)
	var model: Dictionary = scene.session.data.model.duplicate(true)
	checks.actual_pinned_a = a.get("output",[]).size() == 64
	var intent := scene.find_child("CreationIntent",true,false) as LineEdit
	intent.text = "Package QA: less B, more C"; intent.text_changed.emit(intent.text)
	checks.exported_transient_intent = scene.creation_intent == intent.text and not JSON.stringify(scene.session.data).contains(intent.text) and scene.pinned_creation == a
	scene.begin_sample_edit(1); await settle()
	var entry := scene.find_child("SampleEditText",true,false) as LineEdit
	checks.exported_editor_opens = entry != null and entry.text == Catalog.symbols(Catalog.sample(1))
	entry.text = Catalog.symbols(Catalog.sample(4)); entry.text_changed.emit(entry.text)
	scene.apply_sample_edit(); await settle()
	checks.one_passage_replaced = scene.session.data.draft.examples == [Catalog.sample(0),Catalog.sample(4)]
	checks.no_silent_learning = scene.session.data.model == model and scene.pinned_creation == a
	scene.train_model(); scene.generate_work(); await settle()
	checks.real_rule_change = scene.session.data.model != model
	checks.controlled_effect = scene.creation_report.get("controlled_effect",false)
	checks.actual_twelve_changes = scene.creation_report.get("mismatches",[]).size() == 12 and scene.creation_report.get("first_difference",-1) == 9
	checks.pinned_a_preserved = scene.pinned_creation == a
	scene.name_input.text = "Actual package · edited B"
	scene.choose_creation_result(true); await settle()
	checks.saved_b = scene.session.data.works.size() == 1 and scene.session.replay_work(0).get("matches",false)
	var saved: Array = scene.session.data.works.duplicate(true)
	checks.controlled_receipt = scene.session.design_provenance().get("source","") == "controlled-design-v1"
	scene.works.select(0); scene.focus_work(); await settle()
	var view = scene.work_focus
	checks.exported_focus = is_instance_valid(view)
	view.mapping_choice.select(2); view.static_overview = false; view.seek(64); await settle()
	view.size = Vector2i(640,420); await settle()
	var point: Vector2 = view.canvas.phrase_point(63)
	checks.compact_actual_cursor = point.y >= view.snapshot_scroll.scroll_vertical and point.y <= view.snapshot_scroll.scroll_vertical+view.snapshot_scroll.size.y
	checks.exact_snapshot_mapping = view.canvas.viewing_mapping == "light-phrases-v1" and view.work == saved[0] and view.canvas.output == saved[0].output
	view.static_overview = true; view.snapshot_scroll.scroll_vertical = 0; view.size = Vector2i(1080,620); await settle()
	checks.static_resize_preserves_scroll = view.snapshot_scroll.scroll_vertical == 0
	view.select_cell(9); checks.actual_event_available = view.evidence_label.text.contains("feedback_write")
	view.dismiss(); await settle()
	checks.exhibition_preserves_works = scene.session.data.works == saved
	checks.still_forty_core_tasks = get_tree().root.get_node("TaskNavigation").tasks().size() == 40
	checks.package_game_only = not get_tree().root.get_node("GameMode").developer_tools_enabled()
	var passed: bool = true
	for value: bool in checks.values(): passed = passed and value
	print("CREATIVE_PACKAGE_CHECKS ",JSON.stringify(checks))
	var file := FileAccess.open("user://creative_package_result.json",FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(checks)); file.close()
	scene.queue_free(); await settle()
	get_tree().quit(0 if passed else 1)
