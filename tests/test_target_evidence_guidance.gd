extends SceneTree
## Actual domain models and hosts; optional frames are rendered controller evidence, not OS input.
const Layout = preload("res://src/layout_chapter/layout_catalog.gd")
const Recipe = preload("res://src/layout_chapter/layout_recipe.gd")
const Overlap = preload("res://src/overlap_chapter/overlap_catalog.gd")
const Creation = preload("res://experiments/creation/session.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
var checks: int = 0
var failures: Array[String] = []
var official: Array[Dictionary] = []
var capture: bool = false
var frames: Array[Dictionary] = []
var saved_work: Dictionary = {}
var saved_session_sha: String = ""

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func inventory(path: String) -> Dictionary:
	var files: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return files
	for name: String in directory.get_files(): files[name]=FileAccess.get_sha256(path.path_join(name))
	for name: String in directory.get_directories():
		if name in ["logs","shader_cache","playtest_data","offline_playtest","target-guidance-captures"]: continue
		for child: String in inventory(path.path_join(name)): files[name+"/"+child]=FileAccess.get_sha256(path.path_join(name).path_join(child))
	return files

func protected_state(host: Control) -> Dictionary:
	var save: Dictionary = root.get_node("GlobalSave")._save_snapshot().duplicate(true)
	save.erase("saved_at_utc")
	var nav: Node = root.get_node("TaskNavigation")
	var disk: Dictionary = inventory("user://")
	disk.erase("feedback_drafts_v1.json")
	return {"game":save,"disk":disk,"player_content":root.get_node("GlobalSave").game_player_content.canonical_signature(),"best":root.get_node("PersonalRecords").best.duplicate(true),
		"writer_lock":DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())),"writer_recovery_lock":DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())+".recovering"),
		"layout":root.get_node("LayoutChapter").game_snapshot().duplicate(true),"overlap":root.get_node("OverlapChapter").game_snapshot().duplicate(true),
		"layout_drafts":root.get_node("LayoutChapter").drafts().duplicate(true),"layout_completed":root.get_node("LayoutChapter").completed().duplicate(true),
		"overlap_drafts":root.get_node("OverlapChapter").drafts().duplicate(true),"overlap_completed":root.get_node("OverlapChapter").completed().duplicate(true),
		"selected":nav.selected,"pending":nav.pending,"from_tree":nav.from_tree,
		"design":host.get("design").duplicate(true) if host.get("design") is Dictionary else {},
		"board":host.get("board").duplicate(true) if host.get("board") is Dictionary else {},
		"program":host.editor.text if host.get("editor") != null else ""}

func open_layout(id: String) -> Control:
	root.get_node("TaskNavigation").pending = "chapter_4/"+id
	var host: Control = load("res://src/layout_chapter/layout_chapter.tscn").instantiate()
	root.add_child(host); await settle()
	check(host.level == id,"Real Layout host consumes the requested task "+id)
	return host

func open_overlap(id: String) -> Control:
	root.get_node("TaskNavigation").pending = "chapter_3/"+id
	var host: Control = load("res://src/overlap_chapter/overlap_chapter.tscn").instantiate()
	root.add_child(host); await settle()
	check(host.level == id,"Real Overlap host consumes the requested task "+id)
	return host

func close_host(host: Control) -> void:
	host.queue_free(); await settle()

func prepare_existing_work() -> bool:
	var writer = Creation.new()
	var opened: Dictionary = writer.open(Creation.launch_path())
	check(opened.get("ok",false) and opened.get("writable",false),"QA setup owns its isolated creation writer")
	if not opened.get("writable",false): writer.close(); return false
	var trained: Dictionary = writer.train()
	check(trained.get("ok",false),"QA setup actually learns its finite rules")
	if not trained.get("ok",false): writer.close(); return false
	var restored: Dictionary = writer.transport([0,1,0,2],"predictive")
	check(restored.get("ok",false) and restored.get("lossless",false),"QA setup restores real source through the actual codec")
	var connected: Dictionary = writer.set_mode("predict")
	var begun: Dictionary = writer.begin_prediction("practice") if connected.get("ok",false) else {}
	check(begun.get("ok",false),"QA setup connects an actual prefix-only prediction round")
	if not begun.get("ok",false): writer.close(); return false
	for i: int in 4096:
		if writer.prediction.finished: break
		var committed: Dictionary = writer.commit_prediction()
		var revealed: Dictionary = writer.reveal_prediction() if committed.get("ok",false) else {}
		if not revealed.get("ok",false): check(false,"QA prediction must commit before every actual reveal"); writer.close(); return false
	check(writer.prediction.finished,"QA setup completes the actual current-model prediction")
	if not writer.prediction.finished: writer.close(); return false
	connected=writer.set_mode("generate")
	var generated: Dictionary = writer.generate() if connected.get("ok",false) else {}
	check(generated.get("ok",false),"QA setup actually feeds generated output back through the finite model")
	if not generated.get("ok",false): writer.close(); return false
	var kept: Dictionary = writer.save_work("定位前已有的作品 · Before evidence viewing")
	check(kept.get("ok",false),"QA setup saves an immutable output and complete recipe")
	if kept.get("ok",false): saved_work=kept.work.duplicate(true)
	writer.close()
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())),"QA setup releases its writer before either evidence host opens")
	if not kept.get("ok",false): return false
	saved_session_sha=FileAccess.get_sha256(Creation.launch_path())
	var disk: Dictionary=Files.read_session(Creation.launch_path(),Creation.decode)
	check(disk.get("ok",false) and saved_work in disk.get("data",{}).get("works",[]),"Existing-work expectation comes from the actual saved profile")
	print("QA_ONLY: real train/restore/commit-reveal/generate/Keep fixture, not natural journey completion; both guidance hosts must preserve this original work")
	return true

func layout_traffic(english: bool) -> void:
	var host: Control = await open_layout("fields")
	host.design = Layout.starter_design(); host._changed(); await settle(); host._run_all(); await settle()
	check(host.runs.size() == 2,"Both real traffic orders ran")
	for i: int in host.runs.size():
		var run: LayoutRun = host.runs[i]
		var task: Dictionary = Layout.cases("fields")[i]
		var traffic: int = int(run.metrics.ram_read_bytes)+int(run.metrics.ram_write_bytes)
		check(run.passed and not run.metrics.target_met and traffic>int(task.target_bytes),"Fixture has correct output but exceeds actual RAM contract")
		var text: String = host._case_contract_feedback(run,task)
		check(text.contains(str(traffic)) and text.contains(str(task.target_bytes)) and text.contains(str(traffic-int(task.target_bytes))),"Traffic feedback binds actual, public cap and exact gap")
		check(text.contains("Total RAM traffic" if english else "RAM总读写") and not text.contains("Total cycles" if english else "总周期"),"An absent cycle cap is not invented for a traffic failure")
	check(not official.is_empty() and official[-1].payload.result_class=="correct_but_target_unmet","Official aggregate no longer mislabels a traffic failure as slow")
	for record: Dictionary in official[-1].payload.cases:
		check(record.result_class=="correct_but_target_unmet" and record.correct and not record.target_met,"Per-case event retains correct/target values with accurate generic unmet class")
	var before: Dictionary = protected_state(host)
	var signature: String = host.runs[0].canonical_signature()
	var button := host.find_child("LayoutLocateIssue0",true,false) as Button
	check(button != null and not button.disabled,"Original results expose the measured issue action")
	if button == null: await close_host(host); return
	button.pressed.emit(); await settle()
	check(host.case_index==0 and host.trace_filter==0 and not host.trace_list.get_selected_items().is_empty(),"Locate selects the same case and a real unfiltered event")
	check(host.runs[0].canonical_signature()==signature and protected_state(host)==before,"Viewing a traffic witness changes no trace, draft, completion, player content or navigation")
	await capture_host(host,"layout-traffic")
	var matched: LayoutRun = host.runs[0]
	var original_case: String = matched.case_signature
	matched.case_signature = "unmatched-case"
	var focus: Control = root.gui_get_focus_owner()
	host._locate_case_issue(0)
	check(root.gui_get_focus_owner()==focus and host._case_contract_feedback(matched,Layout.cases("fields")[0]).contains("does not match" if english else "不匹配"),"Mismatched evidence does not locate a current issue or move focus")
	matched.case_signature = original_case
	host._move_group(0,host.design.recipe.groups.size()); await settle()
	before = protected_state(host); focus=root.gui_get_focus_owner()
	check(host.stale and button.disabled,"An actual layout edit disables prior issue location")
	host._locate_case_issue(0)
	check(protected_state(host)==before and root.gui_get_focus_owner()==focus,"Stale layout location preserves the new draft and actual focus")
	host._run_all(); await settle()
	check(not host.stale,"A new actual run clears the prior stale marker")
	await close_host(host)

func layout_space_and_cycles(english: bool) -> void:
	var host: Control = await open_layout("batches")
	host.design = Layout.starter_design(); host.design.strategy="full"; host.design.copy_fields=[0,1,2,3]
	host._changed(); await settle(); host._run_all(); await settle()
	var run: LayoutRun = host.runs[0]
	var task: Dictionary = Layout.cases("batches")[0]
	var text: String = host._case_contract_feedback(run,task)
	check(run.metrics.error=="space_limit" and int(run.metrics.peak_extra_bytes)==0 and int(run.metrics.ram_write_bytes)==0,"Real rejected allocation is not measured copied memory or traffic")
	check(text.contains(str(run.metrics.required_extra_bytes)) and text.contains(str(task.scratch_limit)) and text.contains(str(int(run.metrics.required_extra_bytes)-int(task.scratch_limit))),"Space request/cap/gap are read from the real preflight and contract")
	var before: Dictionary = protected_state(host)
	host._locate_case_issue(0); await settle()
	var row: int = host.trace_list.get_selected_items()[0] if not host.trace_list.get_selected_items().is_empty() else -1
	check(row>=0 and run.events[host.trace_indices[row]].kind==&"error","Space location selects the real no-address stopping event")
	check(host.source_view.selected_address==-1 and host.copy_view.selected_address==-1 and protected_state(host)==before,"Rejected allocation creates no fake address, draft edit or completion")
	await close_host(host)
	host = await open_layout("hot_cold")
	host.design=Layout.starter_design(); host._changed(); await settle(); host._run_all(); await settle()
	var slow: bool = false
	for i: int in host.runs.size():
		run=host.runs[i]; task=Layout.cases("hot_cold")[i]
		if run.passed and int(run.metrics.total_cycles)>int(task.target_cycles):
			slow=true; text=host._case_contract_feedback(run,task)
			check(text.contains(str(int(run.metrics.total_cycles)-int(task.target_cycles))) and text.contains("Total cycles" if english else "总周期"),"Correct-but-slow feedback uses the actual cycle difference")
	check(slow,"The actual unchanged starter produces a cycle-contract failure")
	await close_host(host)

func overlap_cases(english: bool) -> void:
	var host: Control = await open_overlap("backpressure")
	host.board=Overlap.buffer_board(2)
	# Fixed timing is legal on the first workload but misses the changed workload.
	host.editor.text=Overlap.buffer_program().replace("consume A\nfree A","consume A\ntick 8\nfree A")
	host._changed(); host._run_official(); await settle()
	var tasks: Array[Dictionary] = Overlap.cases("backpressure")
	check(host.runs[0].passed and int(host.runs[0].metrics.total_cycles)<=int(tasks[0].target),"Actual first workload meets its original contract")
	check(host.runs[1].passed and int(host.runs[1].metrics.total_cycles)>int(tasks[1].target),"Actual second workload has correct output but exceeds its own target")
	check(host.case_select.selected==1 and host.trace==host.runs[1] and host.trace.test_name==str(tasks[1].name),"First unmet case, dropdown, trace and name all agree")
	var gap: int = int(host.trace.metrics.total_cycles)-int(tasks[1].target)
	check(host.metrics.text.contains(("Over by %d cycles." if english else "超出 %d 周期。")%gap),"Selected second case reports its exact cycle gap")
	var before: Dictionary = protected_state(host)
	host.locate_issue_button.pressed.emit(); await settle()
	check(not host.events.get_selected_items().is_empty() and int(host.scrub.value)==int(host.events.get_item_metadata(host.events.get_selected_items()[0])),"Performance location synchronizes actual event row and playback cycle")
	check(protected_state(host)==before,"Locating a slow witness preserves code, board, all earned state and navigation")
	# An inconsistent read-only receipt must not be presented as a performance pass.
	var passed: bool = host.trace.passed
	host.trace.passed=false; host._select_run(1)
	check(host.metrics.text.contains("Output was not verified" if english else "输出尚未通过核验"),"An unverified output is distinct from a correct-but-slow receipt")
	host.trace.passed=passed; host._select_run(1)
	await close_host(host)
	host=await open_overlap("buffers"); host.board=Overlap.buffer_board(1)
	host.editor.text="# first batch\nfetch A 0\nconsume A\nidle\n"; host._changed(); host._run_official(); await settle()
	check(host.trace.metrics.error=="not_ready" and int(host.trace.metrics.error_line)==3,"Real early consumption retains source line3")
	before=protected_state(host)
	host.locate_issue_button.pressed.emit(); await settle()
	check(host.editor.get_caret_line()==2 and root.gui_get_focus_owner()==host.editor,"Locate focuses the actual original offending code line")
	var selected: PackedInt32Array = host.events.get_selected_items()
	check(not selected.is_empty() and host.events.get_item_text(selected[0]).contains(host._t("error.not_ready")),"Locate selects the actual not-ready stopping event")
	check(protected_state(host)==before,"Locating a runtime failure changes no original player state")
	await capture_host(host,"overlap-stop")
	var position: Variant = host.board.nodes.A.x
	host.board.nodes.A.x=float(position)+1.0
	var caret: int = host.editor.get_caret_line()
	var focus: Control = root.gui_get_focus_owner()
	check(not host._recorded_issue_is_current(),"Board identity mismatch is rejected even with unchanged code and stale flag")
	host._locate_recorded_issue()
	check(host.editor.get_caret_line()==caret and root.gui_get_focus_owner()==focus,"Mismatched board cannot jump to a current source line")
	host.board.nodes.A.x=position
	var edits: Dictionary = {"signals":0}
	host.editor.text_changed.connect(func() -> void: edits.signals+=1)
	host.editor.set_caret_line(host.editor.get_line_count()-1)
	host.editor.set_caret_column(host.editor.get_line(host.editor.get_caret_line()).length())
	host.editor.insert_text_at_caret("# changed\n"); await settle()
	check(int(edits.signals)>0,"The actual CodeEdit insertion emits its editing signal")
	print("GUIDANCE_EDIT_SIGNAL: ",root.get_node("Localization").current_locale()," ",edits.signals," stale=",host.trace_stale," disabled=",host.locate_issue_button.disabled)
	check(host.trace_stale and host.locate_issue_button.disabled,"Program editing disables old issue location")
	before=protected_state(host); caret=host.editor.get_caret_line(); focus=root.gui_get_focus_owner()
	host._locate_recorded_issue()
	check(protected_state(host)==before and host.editor.get_caret_line()==caret and root.gui_get_focus_owner()==focus,"Stale issue action cannot relabel or focus the edited program")
	host._run_official(); await settle()
	check(host._recorded_issue_is_current() and not host.locate_issue_button.disabled,"Rerun binds the new program and board for issue location")
	if DisplayServer.get_name()!="headless": await feedback_guard(host)
	await close_host(host)

func key(code: Key) -> void:
	for down: bool in [true,false]:
		var event:=InputEventKey.new(); event.keycode=code; event.physical_keycode=code; event.pressed=down
		Input.parse_input_event(event); await settle()

func click(control: Control) -> void:
	var clip: Rect2 = root.get_visible_rect()
	var parent: Node = control.get_parent()
	while parent != null:
		if parent is Control and parent.clip_contents: clip=clip.intersection(parent.get_global_rect())
		parent=parent.get_parent()
	check(control.is_visible_in_tree() and clip.grow(1).encloses(control.get_global_rect()),"Actual guidance action is reachable inside all viewport/scroll clips")
	for down: bool in [true,false]:
		var event:=InputEventMouseButton.new(); event.position=control.get_global_rect().get_center(); event.global_position=event.position
		event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		root.push_input(event,true); await process_frame
	await settle()

func feedback_guard(host: Control) -> void:
	var feedback: Node = root.get_node("OfflineFeedback")
	var moments: Node = root.get_node("PlaytestMoments")
	var old: Variant = ProjectSettings.get_setting("playtest/offline_tester",false)
	for tester: bool in [false,true]:
		ProjectSettings.set_setting("playtest/offline_tester",tester)
		host.locate_issue_button.grab_focus(); await key(KEY_F8)
		var panel: Control = feedback.panel if tester else moments.panel
		check(feedback.backdrop.visible if tester else moments.panel.visible,"Actual F8 retains the existing role channel over guidance")
		var focus: Control = root.gui_get_focus_owner()
		host._locate_recorded_issue()
		check(root.gui_get_focus_owner()==focus and panel.is_ancestor_of(focus),"Guidance cannot steal feedback's actual focus")
		await key(KEY_ESCAPE)
		check(not (feedback.backdrop.visible if tester else moments.panel.visible) and root.gui_get_focus_owner()==host.locate_issue_button,"First actual Escape closes feedback and restores the original guidance action")
	ProjectSettings.set_setting("playtest/offline_tester",old)

func capture_host(host: Control, label: String) -> void:
	if not capture: return
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1440,900)]:
		root.size=dimensions; root.content_scale_size=dimensions; await settle()
		var action: Button
		if label.begins_with("layout"):
			host._toggle("trace",true)
			action=host.find_child("LayoutLocateIssue0",true,false) as Button
		else:
			host._toggle("trace",true)
			action=host.locate_issue_button
		await settle()
		var scroll: ScrollContainer=action.get_parent().get_parent() as ScrollContainer
		if scroll != null: scroll.ensure_control_visible(action)
		await settle(); await click(action)
		await settle()
		var panel: Control = host.panels.trace
		check(root.get_visible_rect().grow(1).encloses(panel.get_global_rect()),"Evidence panel fits actual "+label+str(dimensions))
		var directory: String = "user://target-guidance-captures"
		check(DirAccess.make_dir_recursive_absolute(directory)==OK,"Capture directory available")
		var path: String = directory+"/%s-%s-%dx%d.png"%[root.get_node("Localization").current_locale(),label,dimensions.x,dimensions.y]
		await RenderingServer.frame_post_draw
		check(root.get_texture().get_image().save_png(path)==OK,"Actual guidance frame captured")
		frames.append({"path":ProjectSettings.globalize_path(path),"sha256":FileAccess.get_sha256(path),"label":label,"locale":root.get_node("Localization").current_locale(),"size":[dimensions.x,dimensions.y]})

func legal_alternatives() -> void:
	var reverse: Dictionary = Layout.starter_design()
	reverse.recipe={"groups":[{"fields":[3,0],"order":"field"},{"fields":[2,1],"order":"record"}],"block":2}
	check(Layout.evaluate("hot_cold",reverse).passed,"Original reversed-field/block alternative remains legal")
	var full: Dictionary = Layout.reference_solution("mixed"); full.strategy="full"
	var batch: Dictionary = full.duplicate(true); batch.strategy="batch"; batch.batch=4
	check(Layout.evaluate("mixed",full).passed and Layout.evaluate("mixed",batch).passed,"Both full and batch copying retain the unchanged main acceptance")
	check(Overlap.evaluate("synthesis",Overlap.buffer_board(2),Overlap.buffer_program()).passed,"Original Buffer synthesis route remains accepted without hints")
	check(Overlap.evaluate("synthesis",Overlap.cache_board(),Overlap.cache_program()).passed,"Alternative Cache synthesis remains accepted without hints")

func run() -> void:
	capture="--target-guidance-capture" in OS.get_cmdline_user_args()
	if capture and DisplayServer.get_name()=="headless": check(false,"Capture requires a real renderer"); capture=false
	root.mode=Window.MODE_WINDOWED; root.size=Vector2i(1280,720); root.content_scale_size=root.size
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("PlaytestData").official_result.connect(func(value: Dictionary) -> void: official.append(value.duplicate(true)))
	if not prepare_existing_work(): quit(1); return
	var save: Dictionary=root.get_node("GlobalSave")._save_snapshot().duplicate(true); save.erase("saved_at_utc")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await layout_traffic(locale=="en")
		await layout_space_and_cycles(locale=="en")
		await overlap_cases(locale=="en")
	legal_alternatives()
	var after: Dictionary=root.get_node("GlobalSave")._save_snapshot().duplicate(true); after.erase("saved_at_utc")
	check(save==after,"Test-mode runs and all guidance actions award no ordinary player progress")
	var disk: Dictionary=Files.read_session(Creation.launch_path(),Creation.decode)
	check(FileAccess.get_sha256(Creation.launch_path())==saved_session_sha and disk.get("ok",false) and saved_work in disk.get("data",{}).get("works",[]),"Both hosts, locating and actual feedback preserve the existing work, recipe and exact session bytes")
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())) and not DirAccess.dir_exists_absolute(Lease.lock_path(Creation.launch_path())+".recovering"),"No guidance path acquires or recovers a candidate writer")
	if capture:
		check(frames.size()==12,"Two languages / three sizes / two actual guidance hosts produced twelve frames")
		var receipt:=FileAccess.open("user://target-guidance-captures/receipt.json",FileAccess.WRITE)
		if receipt != null: receipt.store_string(JSON.stringify({"grade":"actual rendered controller on isolated test-mode hosts, not OS input or newcomer completion","frames":frames,"checks":checks,"failures":failures},"  ")); receipt.close()
	elif DisplayServer.get_name()=="headless": print("NOT_RUN: rendered viewport / actual F8 focus checks / frame captures in headless")
	else: print("NOT_RUN: optional frame captures; pass --target-guidance-capture to record them")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"target evidence guidance %d checks"%checks)
	quit(0 if failures.is_empty() else 1)
