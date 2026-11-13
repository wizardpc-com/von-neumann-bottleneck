extends "res://tests/test_layout_iteration_flow.gd"
## Test task access and an authored recipe are controller fixtures. Actual Run
## creates the records; ranking rows, target pinning, rerun and edits use GUI input.
## This checks the formal Chapter 4 board, not the separate scheduling experiment.

func modal_click(window: Window, control: Control, at: Vector2 = Vector2.INF) -> void:
	var local: Vector2 = control.get_global_rect().get_center() if at == Vector2.INF else at
	var available: bool = window.visible and control.is_visible_in_tree() and Rect2(Vector2.ZERO,Vector2(window.size)).has_point(local)
	check(available,"Modal action is inside the actual ranking window: "+str(control.name))
	if not available: return
	# Embedded Windows are routed by the root viewport in parent coordinates;
	# a direct child push bypasses that route. Native windows use their own id.
	var position: Vector2 = local+Vector2(window.position) if window.is_embedded() else local
	var motion := InputEventMouseMotion.new()
	motion.position = position; motion.global_position = position; motion.window_id = root.get_window_id() if window.is_embedded() else window.get_window_id()
	if window.is_embedded(): root.push_input(motion,true)
	else: Input.parse_input_event(motion)
	await process_frame
	var hovered: Control = window.gui_get_hovered_control()
	var reached: bool = hovered == control or hovered != null and control.is_ancestor_of(hovered)
	check(reached,"Ranking control receives actual pointer: "+str(control.name)+" embedded="+str(window.is_embedded())+" position="+str(window.position)+" local="+str(local)+" hover="+str(hovered))
	if not reached: return
	for down: bool in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = position; event.global_position = position; event.window_id = root.get_window_id() if window.is_embedded() else window.get_window_id()
		event.button_index = MOUSE_BUTTON_LEFT; event.pressed = down
		if window.is_embedded(): root.push_input(event,true)
		else: Input.parse_input_event(event)
		await process_frame
	await settle()

func select_measured(board: Window, id: String) -> void:
	var item: TreeItem = board.table.get_root().get_first_child()
	while item != null and str(item.get_metadata(0)) != id: item = item.get_next()
	check(item != null,"Actual all-case Run supplies ranking row "+id)
	if item == null: return
	var area: Rect2 = board.table.get_item_area_rect(item,0)
	area.position += board.table.global_position
	area = area.intersection(board.table.get_global_rect())
	check(area.has_area(),"Measured ranking row is visibly selectable")
	if not area.has_area(): return
	await modal_click(board,board.table,area.get_center())
	check(board.selected_row().get("id","") == id,"Real row click selects the measured design")

func score_capture(locale: String) -> void:
	if "--layout-score-operation-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle(); RenderingServer.force_draw(false)
	var frame: Image = root.get_texture().get_image()
	check(frame != null and frame.get_size() == Vector2i(1280,720),"Challenge result capture keeps actual 1280x720 pixels")
	if frame == null or frame.get_size() != Vector2i(1280,720): return
	var path: String = "user://layout-score-operation-"+locale+".png"
	check(frame.save_png(path) == OK,"Save actual challenge tie frame")
	print("CAPTURE: "+ProjectSettings.globalize_path(path))

func dispose_host(host: Control) -> void:
	host.queue_free(); current_scene = null; await settle()

func exercise_score(locale: String) -> void:
	var initial_failures: int = failures.size()
	var state: Node = root.get_node("LayoutChapter")
	state.challenge_store = preload("res://src/layout_chapter/layout_challenge_store.gd").new()
	state.test_solutions.clear(); state.test_named.clear(); state.test_drafts.clear()
	root.get_node("Localization").set_locale(locale)
	root.get_node("TaskNavigation").pending = "chapter_4/fields"
	var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host); current_scene = host; await settle()
	await stabilize_window()
	# Only initial recipe preparation is synthetic; do not create a result or
	# inject a best record. Both ranking eligibility and tie come from actual Run.
	host.design = C.reference_solution("fields"); host._changed(); await settle()
	var run_button: Button = host.find_child("LayoutRunAll",true,false)
	await click(run_button)
	check(not host.stale and not host.runs.is_empty() and state.test_solutions.has("fields"),"Actual Run evaluates all cases and earns its own passing best")
	var measured: Array[String] = traces(host)
	var design: Dictionary = host.design.duplicate(true)
	await click(host.score_button)
	var board: Window = host.score_window
	check(board != null and board.visible and board.exclusive,"Rankings opens the actual exclusive modal")
	if board == null or not board.visible:
		await dispose_host(host); return
	await select_measured(board,"best")
	check(not board.challenge_button.disabled,"Measured passing design enables Set target")
	if failures.size() != initial_failures:
		await dispose_host(host); return
	await modal_click(board,board.challenge_button)
	check(not board.visible and not host.personal_challenge.is_empty(),"Pin target releases modal back to editor")
	check(host.design == design and traces(host) == measured,"Setting a target neither edits nor reruns the recipe")
	if failures.size() != initial_failures or not host.personal_challenge.has("row"):
		await dispose_host(host); return
	var target: Dictionary = host.personal_challenge.duplicate(true)
	await click(run_button)
	var verdict: Label = host.results.get_node_or_null("LayoutChallengeResult")
	check(verdict != null and (verdict.text.contains("持平") if locale == "zh_CN" else verdict.text.contains("tied")),"Same real all-case measurement is explicitly a tie")
	check(verdict != null and not verdict.text.contains("beaten") and not verdict.text.contains("挑战成功"),"Tie never claims a beaten target")
	if failures.size() != initial_failures:
		await dispose_host(host); return
	if verdict != null: await click(verdict)
	await score_capture(locale)
	await edit_field_via_ui(host)
	check(host.stale and host.personal_challenge == target,"Actual recipe edit marks results historical and preserves the pinned target")
	if failures.size() != initial_failures:
		await dispose_host(host); return
	await click(run_button)
	check(host.personal_challenge == target,"Rerunning a changed recipe retains exact target identity and metrics")
	await click(host.score_button); await select_measured(board,"challenge")
	check(board.selected_row().get("design",{}) == target.row.design,"Ranking still exposes the original target recipe after edits")
	await modal_click(board,board.close_button)
	check(not board.visible and host.score_button.has_focus(),"Modal Close returns keyboard focus to the ranking entry")
	if failures.size() == initial_failures: completed_loops += 1
	await dispose_host(host)

func run() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks"):
		push_error("Use an isolated verification profile."); quit(2); return
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = root.size
	root.get_node("GameMode").set_mode(&"test")
	ProjectSettings.set_setting("game/reduced_motion",true)
	var before: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	for locale: String in ["zh_CN","en"]:
		await exercise_score(locale)
		if not failures.is_empty(): break
	check(completed_loops == 2,"Both language ranking operation loops reach the end")
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == before,"Test rankings preserve ordinary Game content")
	for failure: String in failures: push_error(failure)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"layout scoreboard operation loop %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)
