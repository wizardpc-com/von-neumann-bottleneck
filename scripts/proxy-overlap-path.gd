extends "res://scripts/proxy-player-paths.gd"
## Known-answer viewport QA of all six timing tasks; no native/novice claim.
const Timing = preload("res://src/overlap_chapter/overlap_catalog.gd")

func timing_return() -> bool:
	check(ui.completion.visible,"Earned timing task exposes its visible continuation")
	if not ui.completion.visible: return false
	await press(ui.completion.continue_button)
	await settle(8)
	check(on_task_tree(),"Timing completion returns to the real unified journey")
	return on_task_tree()

func timing_cases(id: String) -> bool:
	var cases: Array[Dictionary] = Timing.cases(id)
	check(ui.runs.size() == cases.size(),"Official timing run contains every public case: "+id)
	if ui.runs.size() != cases.size(): return false
	for index: int in cases.size():
		var run: SimulationTrace = ui.runs[index]
		check(run.passed and str(run.metrics.error).is_empty() and int(run.metrics.total_cycles) <= int(cases[index].target),"Real timing output and cycle contract pass: %s case%d"%[id,index+1])
		check(run.metrics.outputs.size() == cases[index].values.size() and run.result_value == run.expected_value,"Actual outputs cover all public batches: %s case%d"%[id,index+1])
	if not failures.is_empty(): return false
	# The success overlay covers the case chooser on the first accepted run.
	# All workloads above are observed from their authoritative completed traces;
	# do not click through that modal or dismiss it through a private method.
	if ui.completion.visible:
		await capture(id+"-all-cases-completed")
		return true
	for index: int in cases.size():
		await choose(ui.case_select,index)
		check(ui.trace == ui.runs[index],"Visible case chooser selects the recorded timing trace")
		await capture(id+"-case"+str(index+1))
	return failures.is_empty()

func place_timing_buffers() -> bool:
	check(ui.board.nodes.size() == 2,"Final timing construction begins with only its public terminals")
	if ui.board.nodes.size() != 2: return false
	for id: String in ui.panels:
		if id != "toolbox" and ui.panels[id].visible: await press(ui.panels[id].find_child("CloseButton",true,false))
	var palette: Control
	for item: Node in ui.panels.toolbox.find_children("*","",true,false):
		if item.get_script()==preload("res://src/hardware_foundations/component_palette_item.gd") and item.template_key == "buffer":
			palette = item; break
	check(palette != null,"Buffer palette offers real final-machine construction")
	if palette == null: return false
	for at: Vector2 in [Vector2(510,320),Vector2(510,580)]:
		await drag(palette.get_global_rect().get_center(),at)
	check(ui.board.nodes.has("A") and ui.board.nodes.has("B"),"Final machine receives two buffers by actual palette drag")
	if not ui.board.nodes.has("A") or not ui.board.nodes.has("B"): return false
	await press(ui.panels.toolbox.find_child("CloseButton",true,false))
	for id: String in ["A","B"]:
		await overlap_wire("TRANSFER",id,0,0)
		await overlap_wire(id,"COMPUTE",0,0)
		await overlap_wire(id,"COMPUTE",1,1)
		await overlap_wire(id,"TRANSFER",2,0)
	return failures.is_empty()

func overlap_path() -> void:
	if "--overlap-restart-check" in OS.get_cmdline_user_args():
		await timing_restart_check()
		return
	# Inherited first two tasks retain the early-consume and serial-two-buffer
	# counterexamples, and all actual palette placement / typed scheduling input.
	await super.overlap_path()
	if not failures.is_empty() or not on_task_tree(): return
	for id: String in ["prefetch","distance","backpressure","synthesis"]:
		if not await stage_task("chapter_3/"+id,"OverlapChapterWorkbench"): return
		check(not root.get_node("OverlapChapter").completed().has(id),"Timing task is not pre-earned in this QA branch: "+id)
		if not failures.is_empty(): return
		if id == "synthesis" and not await place_timing_buffers(): return
		if id != "synthesis":
			await overlap_run(id+"-starter-counterexample")
			check(not root.get_node("OverlapChapter").completed().has(id),"Public starter cannot clear this timing contract: "+id)
			if id == "distance":
				check(int(ui.trace.metrics.queue_wait)>0 and int(ui.trace.metrics.evictions)>0,"Eager prefetch pays real bounded-queue wait and eviction costs")
			elif id == "backpressure":
				check(ui.runs.size()==2 and str(ui.runs[0].metrics.error)=="overwrite","Fixed-delay reuse exposes actual overwrite under changing computation")
			else:
				check(ui.trace.passed and int(ui.trace.metrics.overlap)==0 and int(ui.trace.metrics.total_cycles)>28,"Serialized cache reads are correct but miss the public timing target")
			if not failures.is_empty(): return
		await overlap_tool("program")
		await replace_program(Timing.cache_program() if id in ["prefetch","distance"] else Timing.buffer_program())
		await overlap_run(id+"-accepted-schedule")
		check(root.get_node("OverlapChapter").completed().has(id),"Typed schedule earns actual timing gate: "+id)
		if not await timing_cases(id): return
		if id == "distance":
			check(root.get_node("OverlapChapter").bonus_status(id).complete,"Demand-paced prefetch retains real no-repeat-transfer evidence")
		if id != "synthesis":
			if not await timing_return(): return
	var state: Node = root.get_node("OverlapChapter")
	for id: String in Timing.IDS:
		check(state.completed().has(id),"Complete timing route earns every original task: "+id)
	check(state.drafts().has("synthesis"),"Final typed machine remains a retained player draft")
	var draft_before: Dictionary = state.drafts().get("synthesis",{}).duplicate(true)
	check(ui.completion.visible and ui.completion.primary_action_button.visible,"Final timing success exposes its actual path-review action")
	if not failures.is_empty(): return
	await press(ui.completion.primary_action_button)
	await settle(12)
	ui = current_scene
	check(ui != null and ui.name == "PrototypeHub","Final path review returns through the actual Home route")
	if ui == null or ui.name != "PrototypeHub": return
	var review := ui.get_node_or_null("ThemeReflection") as AcceptDialog
	check(review != null and review.visible,"Earned timing path review is visible and reopenable")
	check(state.drafts().get("synthesis",{}) == draft_before,"Opening path review preserves the actual final machine and program")
	if review == null: return
	await capture("timing-complete-path-review")
	if review.is_embedded(): await click(Vector2(review.position)+review.get_ok_button().get_global_rect().get_center())
	else: await press(review.get_ok_button())
	check(not is_instance_valid(review) or not review.visible,"Path review closes through actual visible input")
	var persisted: bool = root.get_node("GlobalSave").save_game()
	check(persisted,"All six UI-earned timing results and final draft persist to isolated QA save")
	if not persisted or not failures.is_empty(): return
	var expected := FileAccess.open(evidence_root+"overlap-restart-expected.json",FileAccess.WRITE)
	check(expected != null,"Independent restart expectation can be written to the evidence folder")
	if expected == null: return
	expected.store_string(JSON.stringify({"snapshot":state.game_snapshot(),"final":state.drafts().get("synthesis",{}).duplicate(true)},"\t"))
	expected.flush()
	check(expected.get_error() == OK,"Actual earned timing snapshot is written without an I/O error")
	expected.close()

func timing_restart_check() -> void:
	# GlobalSave.load_game above this route has revalidated the real QA save.
	# The detached expectation comes only from the previous UI-earned process.
	var path: String = evidence_root+"overlap-restart-expected.json"
	check(FileAccess.file_exists(path),"Restart has the previous process's earned timing expectation")
	if not FileAccess.file_exists(path): return
	var decoded: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(decoded is Dictionary and decoded.has("snapshot") and decoded.has("final"),"Restart expectation is a complete detached timing snapshot")
	if not decoded is Dictionary or not decoded.has("snapshot") or not decoded.has("final"): return
	var state: Node = root.get_node("OverlapChapter")
	for id: String in Timing.IDS:
		check(state.completed().has(id),"Independent restart revalidates earned timing task: "+id)
	check(JSON.parse_string(JSON.stringify(state.game_snapshot())) == decoded.snapshot,"Restart retains all actual timing solutions, drafts, routes, and distance evidence")
	if not failures.is_empty(): return
	if not await stage_task("chapter_3/synthesis","OverlapChapterWorkbench"): return
	check(JSON.parse_string(JSON.stringify(ui.board)) == decoded.final.get("board",{}),"Real TaskTree entry restores the exact final machine draft")
	check(ui.editor.text == str(decoded.final.get("program","")),"Real TaskTree entry restores the exact typed final program")
	check(ui.core_review_button.visible,"Restored final work exposes its real path-review control")
	if not failures.is_empty(): return
	await capture("timing-restart-final-draft")
	await press(ui.core_review_button)
	await settle(12)
	ui = current_scene
	check(ui != null and ui.name == "PrototypeHub","Restart path review follows its real Home route")
	if ui == null or ui.name != "PrototypeHub": return
	var review := ui.get_node_or_null("ThemeReflection") as AcceptDialog
	check(review != null and review.visible,"Restart reopens the earned path review through visible input")
	if review == null or not review.visible: return
	await capture("timing-restart-path-review")
	if review.is_embedded(): await click(Vector2(review.position)+review.get_ok_button().get_global_rect().get_center())
	else: await press(review.get_ok_button())
	check(not is_instance_valid(review) or not review.visible,"Restart review closes through its visible control")
	check(JSON.parse_string(JSON.stringify(state.game_snapshot())) == decoded.snapshot,"Review and return preserve every earned timing result and draft")
	if not failures.is_empty(): return
	check(root.get_node("GlobalSave").save_game(),"Independent restart saves the revalidated timing work successfully")
	check(JSON.parse_string(JSON.stringify(state.game_snapshot())) == decoded.snapshot,"Saving restored timing work does not alter its earned evidence")
