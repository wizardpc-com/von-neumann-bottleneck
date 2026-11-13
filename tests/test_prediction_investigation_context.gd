extends "res://experiments/candidate_input.gd"
## Investigation navigation resumes observed evidence, never an unearned receipt.
const Model = preload("res://experiments/prediction/model.gd")
class Probe extends "res://experiments/prediction/lab.gd":
	var departures: int = 0
	func finish_leave() -> void: departures += 1

var capture_enabled: bool = false
func fit_window() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	if capture_enabled:
		var stable: int = 0
		for attempt: int in 60:
			DisplayServer.window_set_size(Vector2i(1280,720))
			root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
			await create_timer(0.1).timeout
			RenderingServer.force_draw(false)
			var frame: Image = root.get_texture().get_image()
			stable = stable+1 if frame != null and frame.get_size() == Vector2i(1280,720) else 0
			if stable >= 5: break
		check(stable >= 5,"Actual rendered window settles at 1280x720")
	await settle()
func shot(label: String) -> void:
	if not capture_enabled: return
	await fit_window()
	RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame != null and frame.get_size() == Vector2i(1280,720),"Capture retains actual full viewport dimensions")
	if frame != null: check(frame.save_png(evidence_root+label+".png") == OK,"Unmodified investigation viewport saved: "+label)
func tab(handle_name: String,index: int) -> void:
	var tabs := ui.find_child(handle_name,true,false) as TabContainer
	var bar: TabBar = tabs.get_tab_bar()
	await click(bar.global_position+bar.get_tab_rect(index).get_center())
	check(tabs.current_tab == index,"Viewport tab selection reaches requested context")
func select_first_event() -> void:
	var tree: Tree = ui.events
	var first: TreeItem = tree.get_root().get_first_child()
	check(first != null,"An actually revealed event row is available for selection")
	if first == null: return
	tree.scroll_to_item(first,true)
	await settle()
	var row_rect: Rect2 = tree.get_item_area_rect(first)
	var focused: Control = root.gui_get_focus_owner()
	var tabs := ui.find_child("PredictionEvidenceTabs",true,false) as TabContainer
	print("EVENT TREE GEOMETRY ",JSON.stringify({"tree_rect":str(tree.get_global_rect()),"row_rect":str(row_rect),"tree_size":str(tree.size),"tab":tabs.current_tab,"visible":tree.is_visible_in_tree(),"viewport":str(root.get_visible_rect()),"focus":str(focused.get_path()) if focused != null else "none"}))
	# Tree item widths may exceed the visible clipped columns. Hit-test only
	# points inside the observed viewport, then dispatch an ordinary mouse click.
	var hit: Vector2 = Vector2(-1,-1)
	var visible: Rect2 = Rect2(tree.global_position+row_rect.position,row_rect.size).intersection(tree.get_global_rect()).intersection(root.get_visible_rect())
	for y: int in range(int(visible.position.y)+2,int(visible.end.y)-2,2):
		for x: int in range(int(visible.position.x)+24,int(visible.end.x)-16,8):
			var candidate := Vector2(x,y)
			if tree.get_item_at_position(candidate-tree.global_position) == first:
				hit = candidate
				break
		if hit.x >= 0: break
	print("EVENT TREE HIT ",str(hit)," local=",str(hit-tree.global_position)," selected_before=",str(tree.get_selected()))
	check(hit.x >= 0,"First revealed row has an actual Tree hit-test point inside the viewport")
	if hit.x < 0: return
	await click(hit)
	print("EVENT TREE CLICK selected=",str(tree.get_selected())," expected=",str(first)," focus=",str(root.gui_get_focus_owner()))
	check(tree.get_selected() == first,"Actual row click selects the first revealed event")
func switch_to(index: int) -> void:
	await press(handle("Task"+str(index)))
	check(ui.task == index,"Visible investigation action reaches requested task")
func prefix_is(count: int) -> void:
	var public: Dictionary = ui.public_observation()
	check(ui.revealed == count and public.observed_addresses.size() == count and public.revealed_decisions.size() == count,"Public evidence retains exactly the observed prefix")
	if ui.active_trace == null:
		check(count == 0 and public.evidence_source.is_empty(),"Empty context has no invented measurement source")
		return
	if public.observed_addresses.size() != count or public.revealed_decisions.size() != count: return
	for index: int in count:
		check(public.observed_addresses[index] == ui.active_trace.metrics.accesses[index].address and public.revealed_decisions[index] == ui.active_trace.metrics.decisions[index],"Revealed evidence matches the original authoritative trace")
	if count < ui.active_trace.metrics.accesses.size():
		check(public.evidence_source.run_index == -1 and public.evidence_source.task == ui.task,"Partial source belongs to the current investigation, not a completed record")
		check(not public.has("metrics") and not public.has("events") and not public.evidence_source.has("metrics"),"Partial public whitelist does not expose hidden metrics or events")
		check(ui.result.text == ui.text2("完成运行后才显示总成本与独立基线。","Full costs and independent baseline appear only after the run finishes."),"Partial result keeps final costs hidden")
		for row: TreeItem in ui.events.get_root().get_children():
			check(int(row.get_metadata(0).details.step) <= count,"Visible event belongs to the revealed prefix")
func cancel_leave() -> void:
	var dialog := ui.get_node_or_null("LeavePredictionDialog") as ConfirmationDialog
	check(dialog != null and dialog.visible and ui.departures == 0,"Inactive investigation work still requires an explicit discard decision")
	if dialog != null:
		dialog.hide(); dialog.canceled.emit(); await settle()
func new_scene() -> void:
	var scene := Probe.new(); scene.candidate_journey = true
	root.add_child(scene); current_scene = scene; ui = scene
	scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await fit_window()
func _run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Requires isolated verification profile"); quit(2); return
	capture_enabled = "--prediction-context-capture" in OS.get_cmdline_user_args()
	if capture_enabled and DisplayServer.get_name() == "headless":
		push_error("Prediction context capture requires a rendering display"); quit(2); return
	var localization: Node = root.get_node("Localization")
	var original_locale: String = localization.current_locale()
	root.get_node("TaskNavigation").pending = ""
	ProjectSettings.set_setting("game/reduced_motion",true)
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot(); before.erase("saved_at_utc")
	for initial_task: int in [0,2]:
		root.get_node("TaskNavigation").pending = root.get_node("TaskNavigation").candidate_key("prediction",initial_task)
		await new_scene()
		check(ui.task == initial_task and root.get_node("TaskNavigation").pending.is_empty(),"Ready consumes initial pending investigation including zero")
		var cached: Variant = ui.get("investigation_contexts")
		check(cached is Dictionary and cached.is_empty() and not ui.has_session_work(),"Initial navigation does not cache an unvisited default investigation")
		check(ui.active_trace == null and ui.history.is_empty() and ui.public_observation().observed_addresses.is_empty(),"Initial pending navigation creates no observation or receipt")
		ui.queue_free(); await settle()
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		await new_scene()
		await choose(ui.rule,1)
		for step: int in 4: await press(handle("Step"))
		prefix_is(4)
		var first_public: Dictionary = ui.public_observation()
		var first_trace: RefCounted = ui.active_trace
		var first_signature: String = first_trace.canonical_signature()
		await tab("PredictionRuleTabs",1)
		await tab("PredictionEvidenceTabs",1)
		await select_first_event()
		var event_row: TreeItem = ui.events.get_selected()
		check(event_row != null,"Viewport keyboard selects a revealed event")
		var selected_event: RefCounted = event_row.get_metadata(0) if event_row != null else null
		await shot(locale+"-first-prefix")
		await switch_to(1)
		check(ui.policy == first_public.policy and ui.active_trace == null and ui.revealed == 0 and ui.history.is_empty(),"First visit carries the rule but no observations or receipts")
		await choose(ui.confidence,1)
		for step: int in 2: await press(handle("Step"))
		var second_public: Dictionary = ui.public_observation()
		var second_trace: RefCounted = ui.active_trace
		await switch_to(0)
		check(ui.public_observation() == first_public and ui.active_trace == first_trace,"Returning restores exact original policy, trace and four-step public evidence")
		if ui.active_trace != first_trace or ui.revealed != 4:
			# Old-runtime negative control stops this scenario after its real failure.
			ui.queue_free(); await settle()
			continue
		check(ui.find_child("PredictionRuleTabs",true,false).current_tab == 1 and ui.find_child("PredictionEvidenceTabs",true,false).current_tab == 1,"Returning restores both investigation tab selections")
		event_row = ui.events.get_selected()
		check(event_row != null and event_row.get_metadata(0) == selected_event and ui.details.text == ui.event_text(selected_event),"Returning restores only the previously visible selected event")
		prefix_is(4)
		await shot(locale+"-returned-prefix")
		# Shared language rebuild must preserve the same context too.
		await press(handle("Language"))
		check(ui.active_trace == first_trace and ui.revealed == 4,"Language rebuild keeps the resumed trace and reveal count")
		await press(handle("Language"))
		await press(handle("Step"))
		prefix_is(5)
		check(ui.active_trace == first_trace and ui.history.is_empty() and first_trace.canonical_signature() == first_signature,"Next reveal advances once without rerunning, recording or mutating the trace")
		await switch_to(1)
		check(ui.public_observation() == second_public and ui.active_trace == second_trace,"Second investigation resumes its own independently edited two-step context")
		await shot(locale+"-second-prefix")
		await press(handle("Restart")); prefix_is(0)
		await choose(ui.rule,0)
		check(ui.policy == Model.default_policy() or ui.policy.rule == "off","Current investigation can be reset to a nonpredicting rule")
		await choose(ui.confidence,0)
		check(ui.policy == Model.default_policy() and ui.active_trace == null and ui.history.is_empty() and ui.has_session_work(),"Inactive partial evidence keeps the discard guard even when current task is empty/default")
		await press(handle("CandidateHome")); await cancel_leave()
		await switch_to(0); prefix_is(5)
		await switch_to(1); prefix_is(0)
		check(ui.active_trace == null,"Explicit New run cannot resurrect a discarded prefix after navigation")
		await switch_to(0)
		await choose(ui.lookahead,1); prefix_is(0)
		await switch_to(1); await switch_to(0); prefix_is(0)
		check(ui.policy.lookahead == 2 and ui.active_trace == null,"An explicit policy edit invalidates only its own prefix without later resurrection")
		await press(handle("Run"))
		check(ui.history.size() == 1 and ui.selected_run == 0,"Only completing the explicit run records measured evidence")
		var record_signature: String = ui.history[0].trace.canonical_signature()
		await switch_to(1)
		await tab("PredictionEvidenceTabs",2)
		await item_row(ui.history_list,0)
		var foreign_public: Dictionary = ui.public_observation()
		check(foreign_public.task == 1 and foreign_public.evidence_source.task == 0 and foreign_public.evidence_source.run_index == 0 and foreign_public.policy.rule == "off","Cross-investigation history keeps its original source and the current editable rule")
		await switch_to(2)
		check(ui.active_trace == null and ui.revealed == 0,"First visit never inherits viewed foreign measurement")
		await switch_to(1)
		check(ui.public_observation() == foreign_public and ui.recorded_source.text.contains("differs" if ui.english else "不同"),"Returning to old-record review preserves full already-seen evidence and honest source caption")
		await shot(locale+"-foreign-record")
		check(ui.history.size() == 1 and ui.history[0].trace.canonical_signature() == record_signature,"All navigation and review preserve immutable receipts without duplicates")
		ui.queue_free(); await settle()
		# A separate history-free fixture covers an inactive unrun draft alone.
		await new_scene(); await choose(ui.rule,1); await switch_to(1); await choose(ui.rule,0)
		check(ui.history.is_empty() and ui.active_trace == null and ui.policy == Model.default_policy() and ui.has_session_work(),"Inactive unrun policy alone is recognized as session work")
		await press(handle("Quit")); await cancel_leave()
		await switch_to(0)
		check(ui.policy.rule == "stride" and ui.active_trace == null,"Cancel and return preserve the unrun draft without inventing evidence")
		ui.queue_free(); await settle()
	localization.set_locale(original_locale)
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot(); after.erase("saved_at_utc")
	check(after == before,"Temporary investigation contexts never mutate campaign save authority")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"prediction investigation context %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
