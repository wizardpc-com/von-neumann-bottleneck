extends SceneTree
## Real Settings routes must translate in place, not discard live workbench state.
const RepresentationStore = preload("res://experiments/representation_region/session_store.gd")
const ServiceStore = preload("res://experiments/service_plan/session_store.gd")
const PredictionEvent = preload("res://src/simulation/simulation_event.gd")
const PATHS := {
	"representation":"res://experiments/representation_region/region.tscn",
	"service":"res://experiments/service_plan/lab.tscn",
	"prediction":"res://experiments/prediction/lab.tscn",
	"creation":"res://experiments/creation/workbench.tscn",
}
var checks: int = 0
var failures: Array[String] = []
var official_run_count: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 10: await process_frame
func key(code: Key) -> void:
	for pressed: bool in [true,false]:
		var event := InputEventKey.new()
		event.keycode = code; event.physical_keycode = code; event.pressed = pressed
		root.push_input(event,true); await process_frame
	await settle()
func field(scene: Node, handle: String) -> LineEdit:
	return scene.find_child(handle,true,false) as LineEdit

func choose(scene: Node, handle: String, index: int) -> void:
	var choice := scene.find_child(handle,true,false) as OptionButton
	choice.select(index); choice.item_selected.emit(index)

func selected_prediction_event(scene: Node) -> PredictionEvent:
	var row: TreeItem = scene.events.get_selected()
	return row.get_metadata(0) as PredictionEvent if row != null else null

func pending_controls(scene: Node, kind: String) -> Dictionary:
	var handles: Array[String] = []
	match kind:
		"representation": handles.assign(["SplitAt","PublicOrderPreview","RecordedOrder"])
		"service": handles.assign(["MoveTarget","SplitBoundary","Slots","EvidenceTabs"])
		"prediction": handles.assign(["Rule","Confidence","Lookahead","Cooldown","PredictionRuleTabs","PredictionEvidenceTabs"])
		"creation": handles.assign(["Source","Sampler","Seed","Length","DraftTabs","EvidenceTabs"])
	var state: Dictionary = {}
	for handle: String in handles:
		var control: Node = scene.find_child(handle,true,false)
		if control is SpinBox: state[handle] = control.value
		elif control is OptionButton: state[handle] = control.selected
		elif control is TabContainer: state[handle] = control.current_tab
		else: check(false,"Expected real pending control exists: "+kind+"/"+handle)
	if kind == "representation":
		state["selected_block"] = scene.selected_block
		var row: TreeItem = scene.blocks.get_selected()
		state["block_row"] = int(row.get_metadata(0)) if row != null else -1
	elif kind == "service":
		state["selected_group"] = scene.selected_group
		state["group_rows"] = scene.group_list.get_selected_items()
	elif kind == "prediction":
		state["selected_run"] = scene.selected_run
		# A restarted prefix has no selected record. Do not enshrine stale list
		# highlighting as a valid selection after a policy edit/restart.
		if scene.selected_run >= 0: state["history_rows"] = scene.history_list.get_selected_items()
	return state

func snapshot(scene: Node, kind: String) -> Dictionary:
	match kind:
		"representation":
			return {"task":scene.task,"plan":scene.plan.duplicate(true),"dirty":scene.session_dirty,
				"undo":scene.undo_stack.duplicate(true),"redo":scene.redo_stack.duplicate(true),
				"drafts":scene.drafts.duplicate(true),"history":scene.history.duplicate(true),
				"selection":scene.selected_run,"supports":scene.support_plans.duplicate(true)}
		"service":
			return {"task":scene.task,"plan":scene.plan.duplicate(true),"dirty":scene.session_dirty,
				"undo":scene.undo_stack.duplicate(true),"redo":scene.redo_stack.duplicate(true),
				"history":scene.history.duplicate(true),"selection":scene.selected_history,
				"supports":scene.support_plans.duplicate(true)}
		"prediction":
			var recorded_signatures: Array[String] = []
			for record: Dictionary in scene.history: recorded_signatures.append(record.trace.canonical_signature())
			return {"task":scene.task,"policy":scene.policy.duplicate(true),"active_policy":scene.active_policy.duplicate(true),
				"revealed":scene.revealed,"trace":scene.active_trace,"history":scene.history.duplicate(true),
				"trace_signature":scene.active_trace.canonical_signature() if scene.active_trace != null else "",
				"recorded_signatures":recorded_signatures,"source":scene.evidence_source()}
		"creation":
			return {"task":scene.task,"data":scene.session.data.duplicate(true),"dirty":scene.session.dirty,
				"undo":scene.session.undo_stack.duplicate(true),"redo":scene.session.redo_stack.duplicate(true),
				"sample_index":scene.sample_edit_index,"sample_source":scene.sample_edit_source.duplicate(true),
				"inputs":scene._capture_editor_state().inputs,"tabs":scene._capture_editor_state().tabs}
	return {}

func prepare_work(scene: Node, kind: String, review_record: bool) -> String:
	match kind:
		"representation":
			scene.save_session()
			check(not scene.save_blocked and FileAccess.file_exists(RepresentationStore.PATH),"Representation fixture has a writable saved baseline")
			var next: Array[Dictionary] = scene.plan.duplicate(true)
			next[0].codec = "rle" if next[0].codec == "raw" else "raw"
			scene.edit_plan(next)
			scene.split_at.value = 16; scene.split_button.pressed.emit()
			var block: TreeItem = scene.blocks.get_root().get_child(1)
			block.select(0); scene.blocks.item_selected.emit()
			scene.split_at.value = 24
			choose(scene,"PublicOrderPreview",1)
			scene.run_current()
			check(scene.session_dirty and not scene.undo_stack.is_empty() and not scene.history.is_empty(),"Representation fixture has an unsaved edit and real measured history")
			check(scene.selected_block == 1 and scene.split_at.value == 24 and not scene.split_button.disabled,"Representation fixture has a valid unapplied split inside the selected right block")
			return RepresentationStore.PATH
		"service":
			scene.save_session()
			check(not scene.save_blocked and FileAccess.file_exists(ServiceStore.PATH),"Service fixture has a writable saved baseline")
			scene.slots.value = 2 if scene.plan.slots != 2 else 3
			check(int(scene.slots.value) == int(scene.plan.slots),"Service fixture edits slots through the actual control so UI and model agree")
			scene.group_list.select(1); scene.group_list.item_selected.emit(1)
			for merged: int in 2: scene.merge_button.pressed.emit()
			scene.run_current()
			scene.move_to.value = 4; scene.split_at.value = 2
			scene.evidence_tabs.current_tab = 2
			check(scene.session_dirty and not scene.undo_stack.is_empty() and not scene.history.is_empty(),"Service fixture has an unsaved edit and real measured history")
			check(scene.selected_group == 1 and scene.plan.groups[1].size() == 3 and scene.split_at.value == 2 and not scene.split_button.disabled and scene.move_to.value <= scene.move_to.max_value,"Service fixture has a valid unapplied split and move, not an out-of-range stale selection")
			return ServiceStore.PATH
		"prediction":
			scene.run_current()
			choose(scene,"Rule",2); choose(scene,"Confidence",1)
			choose(scene,"Lookahead",1); choose(scene,"Cooldown",1)
			scene.step_current(); scene.step_current()
			check(scene.has_session_work() and scene.revealed == 2,"Prediction fixture has a partially revealed real run")
			if review_record:
				scene.history_list.select(0); scene.history_list.item_selected.emit(0)
				check(scene.selected_run == 0 and scene.active_policy != scene.policy,"Prediction fixture reviews a real older record without replacing the revised draft")
			(scene.find_child("PredictionRuleTabs",true,false) as TabContainer).current_tab = 1
			(scene.find_child("PredictionEvidenceTabs",true,false) as TabContainer).current_tab = 1
			var event_rows: TreeItem = scene.events.get_root()
			check(event_rows != null and event_rows.get_child_count() > 1,"Prediction fixture exposes multiple real revealed events")
			if event_rows != null and event_rows.get_child_count() > 1:
				# Select a non-first visible event, not an unseen future event or a
				# stale row from the prefix replaced by reviewing an older record.
				var event_row: TreeItem = event_rows.get_child(event_rows.get_child_count()-1)
				var event: PredictionEvent = event_row.get_metadata(0) as PredictionEvent
				check(event != null and scene.active_trace.events.has(event) and int(event.details.step) <= scene.revealed,"Prediction fixture selects an authoritative event within the actually revealed prefix")
				event_row.select(0); scene.events.item_selected.emit()
				check(selected_prediction_event(scene) == event and scene.details.text == scene.event_text(event),"Prediction fixture opens the selected event's real detail through the existing Tree signal")
		"creation":
			check(scene.session.save() == OK,"Creation fixture has a writable saved baseline")
			choose(scene,"Source",2); choose(scene,"Sampler",1)
			(scene.find_child("Seed",true,false) as SpinBox).value = 41
			(scene.find_child("Length",true,false) as SpinBox).value = 64
			scene.begin_sample_edit(0)
			field(scene,"SampleEditText").text = "A X pending"
			field(scene,"Initial").text = "A X initial"
			field(scene,"CustomExample").text = "unsubmitted custom example"
			field(scene,"WorkName").text = "unsubmitted work title"
			(scene.find_child("DraftTabs",true,false) as TabContainer).current_tab = 2
			(scene.find_child("ExpandEvidence",true,false) as Button).pressed.emit()
			(scene.find_child("EvidenceTabs",true,false) as TabContainer).current_tab = 1
			check(scene.has_pending_sample_text() and not scene.valid_initial_input(),"Creation fixture contains both protected invalid inputs")
			return scene.session.path
	return ""

func settings_action(reset: bool, locale: String) -> void:
	var mode: Node = root.get_node("WindowMode")
	if not is_instance_valid(mode.settings_layer): await key(KEY_F10)
	check(is_instance_valid(mode.settings_layer),"F10 opens the actual workbench Settings")
	if not is_instance_valid(mode.settings_layer): return
	var settings: Control = mode.settings_layer.get_child(0)
	if reset:
		var action: Button = settings.find_child("ResetPresentation",true,false)
		action.pressed.emit(); await settle()
		var dialog: ConfirmationDialog = settings.find_child("ResetPresentationConfirm",true,false)
		check(dialog.visible,"Restore defaults requests its existing confirmation")
		dialog.hide(); dialog.confirmed.emit()
	else:
		var choice: OptionButton = settings.find_child("LanguageChoice",true,false)
		var index: int = 1 if locale == "en" else 0
		choice.select(index); choice.item_selected.emit(index)
	await settle()

func enter_from_tree(kind: String, prefix: String) -> Control:
	var navigation: Node = root.get_node("TaskNavigation")
	check(change_scene_to_file(navigation.MAP_SCENE) == OK,prefix+"Actual journey tree opens")
	await settle()
	if current_scene == null or current_scene.scene_file_path != navigation.MAP_SCENE: return null
	var key_name: String = navigation.candidate_key(kind,0)
	current_scene._select(key_name)
	var enter_button: Button = current_scene.enter_button
	check(current_scene.selected.get("key","") == key_name and not enter_button.disabled,prefix+"First task is legally reachable through the real task tree")
	if enter_button.disabled: return null
	enter_button.pressed.emit()
	await settle()
	check(current_scene != null and current_scene.scene_file_path == PATHS[kind],prefix+"Tree entry opens the intended workbench")
	if current_scene == null or current_scene.scene_file_path != PATHS[kind]: return null
	check(navigation.pending.is_empty() and navigation.from_tree,prefix+"Workbench consumes tree entry once and keeps its return route")
	return current_scene as Control

func discard_and_return(scene: Node, kind: String, prefix: String) -> void:
	var action := scene.find_child("Journey" if kind == "creation" else "CandidateHome",true,false) as Button
	check(action != null and (action.text.contains("Journey map") or action.text.contains("旅程地图")),prefix+"Visible return action promises the journey map")
	if action == null: return
	action.pressed.emit()
	await settle()
	var guards: Array[String] = []
	match kind:
		"representation": guards.assign(["UnsavedSessionDialog"])
		"service": guards.assign(["UnsavedServiceDialog"])
		"prediction": guards.assign(["LeavePredictionDialog"])
		"creation": guards.assign(["PendingSampleProtection","PendingInitialProtection","LeaveProtection"])
	for handle: String in guards:
		if not is_instance_valid(scene):
			check(false,prefix+"Departure waits for the existing protection: "+handle)
			return
		var dialog := scene.find_child(handle,true,false) as ConfirmationDialog
		check(dialog != null and dialog.visible,prefix+"Departure waits for the existing protection: "+handle)
		if dialog == null or not dialog.visible: return
		dialog.hide()
		if handle in ["PendingSampleProtection","PendingInitialProtection","LeavePredictionDialog"]:
			dialog.confirmed.emit()
		else:
			dialog.custom_action.emit(&"discard")
		await settle()

func exercise(kind: String, locale: String, reset: bool) -> void:
	var localization: Node = root.get_node("Localization")
	localization.set_locale(locale)
	var navigation: Node = root.get_node("TaskNavigation")
	var prefix: String = kind+" / "+locale+" / "+("defaults" if reset else "language")+": "
	var scene: Control = await enter_from_tree(kind,prefix)
	if scene == null: return
	var path: String = prepare_work(scene,kind,locale == "en")
	await settle()
	var original_id: int = scene.get_instance_id()
	var before: Dictionary = snapshot(scene,kind)
	var controls_before: Dictionary = pending_controls(scene,kind)
	var prediction_event: PredictionEvent = selected_prediction_event(scene) if kind == "prediction" else null
	var reward_signature: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	var runs_before: int = official_run_count
	var saved_bytes: String = FileAccess.get_file_as_string(path) if not path.is_empty() else ""
	var target: String = "zh_CN" if reset else ("en" if locale == "zh_CN" else "zh_CN")
	await settings_action(reset,target)
	check(navigation.pending.is_empty(),prefix+"In-place localization leaves no unconsumed scene-entry request")
	check(navigation.from_tree,prefix+"In-place localization preserves the task-tree origin")
	var after: Node = current_scene
	check(after != null and after.get_instance_id() == original_id,prefix+"Settings keeps the same live workbench and writer lease")
	if after != null:
		check(after.english == (target == "en"),prefix+"Workbench renders the selected language")
		var translated_action: Button = after.find_child("SaveDraft" if kind == "creation" else "Run",true,false)
		var translated_word: String = ("Save" if kind == "creation" else "Run") if target == "en" else ("保存" if kind == "creation" else "运行")
		check(translated_action != null and translated_action.text.contains(translated_word),prefix+"Actual workbench controls use the selected language")
		check(snapshot(after,kind) == before,prefix+"Draft, unsubmitted text, undo and exploration remain intact")
		var controls_after: Dictionary = pending_controls(after,kind)
		for handle: String in controls_before:
			check(controls_after.get(handle) == controls_before[handle],prefix+"Pending control or valid view selection remains intact: "+handle)
		if kind == "prediction":
			check(prediction_event != null and selected_prediction_event(after) == prediction_event,prefix+"Prediction keeps the exact selected revealed Event instance")
			# Structured event IDs and JSON are deliberately language-neutral;
			# reproduce the existing detail, not the translated empty-selection hint.
			check(prediction_event != null and after.details.text == after.event_text(prediction_event),prefix+"Prediction regenerates the selected event detail instead of losing the viewing position")
			var event_tabs := after.find_child("PredictionEvidenceTabs",true,false) as TabContainer
			check(event_tabs.current_tab == 1 and event_tabs.get_tab_title(1) == ("Event details" if target == "en" else "事件详情") and after.events.get_column_title(2) == ("Evidence event" if target == "en" else "证据事件"),prefix+"The selected event detail page and evidence heading use the target language")
			check(after.active_trace == before.trace and after.active_trace.canonical_signature() == before.trace_signature and after.revealed == before.revealed,prefix+"Prediction keeps the same authoritative Trace and revealed prefix without recomputing evidence")
			check(official_run_count == runs_before,prefix+"Prediction localization records no new official run")
			check(root.get_node("GlobalSave").game_player_content.canonical_signature() == reward_signature,prefix+"Prediction localization grants no Game completion or component rewards")
			check(after.recorded_source.text == after.source_caption(),prefix+"Prediction labels the preserved evidence source in the selected language")
			if after.selected_run >= 0:
				check(after.recorded_source.text.contains("differs" if target == "en" else "不同"),prefix+"Older measurement remains distinct from the revised draft")
	check(localization.current_locale() == target,prefix+"Shared locale matches the explicit selection")
	if not path.is_empty(): check(FileAccess.get_file_as_string(path) == saved_bytes,prefix+"Language does not implicitly save or overwrite profile bytes")
	var mode: Node = root.get_node("WindowMode")
	check(is_instance_valid(mode.settings_layer),prefix+"Translated Settings remains open")
	if is_instance_valid(mode.settings_layer):
		var choice: OptionButton = mode.settings_layer.find_child("LanguageChoice",true,false)
		check(choice.selected == (1 if target == "en" else 0),prefix+"Rebuilt Settings shows the selected locale")
		(mode.settings_layer.find_child("OptionsResumeButton",true,false) as Button).pressed.emit()
		await settle()
	check(not is_instance_valid(mode.settings_layer),prefix+"Return closes only Settings")
	if current_scene != null: await discard_and_return(current_scene,kind,prefix)
	check(current_scene != null and current_scene.scene_file_path == navigation.MAP_SCENE,prefix+"Journey map button actually returns to the task tree, not the laboratory")
	if not path.is_empty(): check(FileAccess.get_file_as_string(path) == saved_bytes,prefix+"Explicitly discarded fixture work never overwrites the saved profile")
	if current_scene != null:
		current_scene.queue_free(); current_scene = null
	await settle()

func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	root.get_node("PlaytestData").official_result.connect(func(_result: Dictionary) -> void: official_run_count += 1)
	var game_completion: Dictionary = root.get_node("GlobalSave").game_player_content.completed_levels.duplicate(true)
	var original_representation: String = RepresentationStore.PATH
	var original_service: String = ServiceStore.PATH
	var directory: String = "user://late-settings-"+Crypto.new().generate_random_bytes(8).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	RepresentationStore.PATH = directory+"/representation.json"
	ServiceStore.PATH = directory+"/service.json"
	for kind: String in PATHS:
		for locale: String in ["zh_CN","en"]:
			await exercise(kind,locale,false)
			await exercise(kind,locale,true)
	RepresentationStore.PATH = original_representation
	ServiceStore.PATH = original_service
	check(root.get_node("GlobalSave").game_player_content.completed_levels == game_completion,"Real tree and Settings routes never fabricate Game completion")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"late Settings localization %d checks, %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
