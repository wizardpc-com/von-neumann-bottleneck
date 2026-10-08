extends "res://scripts/proxy-player-paths.gd"
## Authored known-answer QA via real viewport/menu input; not novice evidence.
const LayoutCatalogQA = preload("res://src/layout_chapter/layout_catalog.gd")
const LayoutChipQA = preload("res://src/layout_chapter/layout_field_chip.gd")

func layout_selector(first_caption: String) -> OptionButton:
	for option: OptionButton in layout_options():
		if option.item_count > 0 and option.get_item_text(0) == first_caption: return option
	return null

func layout_field_selector(field: int) -> OptionButton:
	for chip: Node in ui.tools_box.find_children("*","Control",true,false):
		if chip.get_script() != LayoutChipQA or int(chip.field_id) != field: continue
		for sibling: Node in chip.get_parent().get_children():
			if sibling is OptionButton: return sibling
	return null

func layout_group_order(group: int) -> OptionButton:
	for row: Node in ui.tools_box.get_children():
		var matches: bool = false
		for child: Node in row.get_children():
			if child is Label and child.text == local_caption("组 ","Group ")+str(group+1): matches = true
		if matches:
			for child: Node in row.get_children():
				if child is OptionButton: return child
	return null

func layout_pick(control: OptionButton, index: int) -> bool:
	check(control != null,"Public layout selector exists for the requested decision")
	if control == null: return false
	await choose(control,index)
	await settle(5)
	return failures.is_empty()

func layout_strategy(index: int) -> bool:
	return await layout_pick(layout_selector(local_caption("直接读取原数据","Read source directly")),index)

func layout_ready_tools() -> void:
	if not ui.panels.tools.visible: await layout_tools()
	# Bring this instrument above the open trace/address windows using its dock.
	await layout_button("布局工具","Layout tools")
	if not ui.panels.tools.visible: await layout_button("布局工具","Layout tools")

func layout_start(task: String) -> bool:
	if not await select_task("chapter_4/"+task): return false
	await press(named_button(ui,text(&"layout.mission.begin")))
	await layout_ready_tools()
	return failures.is_empty()

func layout_earned(task: String) -> bool:
	check(root.get_node("LayoutChapter").completed().has(task),"Actual public controls earn Layout task "+task)
	return failures.is_empty()

func layout_save_named(title: String) -> bool:
	await layout_ready_tools()
	check(ui.scheme_name != null,"Named layout input is available")
	await press(ui.scheme_name); await key(KEY_A,true); await type_text(title)
	await layout_button("保存","Save")
	check(root.get_node("LayoutChapter").named().get(ui.level,{}).has(title),"Real Save action retains named player design "+title)
	return failures.is_empty()

func layout_split_hot_cold() -> bool:
	if not await layout_pick(layout_field_selector(1),1): return false
	if not await layout_pick(layout_field_selector(2),1): return false
	check(ui.design.recipe.groups.size() == 2 and ui.design.recipe.groups[0].fields == [0,3] and ui.design.recipe.groups[1].fields == [1,2],"Public grouping choices produce hot/cold groups without dropping fields")
	return failures.is_empty()

func layout_batch_number(value: int) -> bool:
	var controls: Array[Node] = ui.tools_box.find_children("*","SpinBox",true,false)
	check(controls.size() == 1,"Exactly one visible batch-size control exists")
	if controls.size() != 1: return false
	await edit_number(controls[0],value)
	await settle(5)
	check(int(ui.design.batch) == value,"Real numeric input commits batch size %d"%value)
	return failures.is_empty()

func layout_restart_evidence() -> void:
	var state: Node = root.get_node("LayoutChapter")
	var path: String = evidence_root+"layout-restart-expected.json"
	if "--layout-restart-check" in OS.get_cmdline_user_args():
		check(FileAccess.file_exists(path),"Restart expectation from the original actual UI run exists")
		if not FileAccess.file_exists(path): return
		var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		check(expected is Dictionary and expected.get("state") is Dictionary,"Restart expectation is a valid detached state snapshot")
		if not expected is Dictionary or not expected.get("state") is Dictionary: return
		check(JSON.parse_string(JSON.stringify(state.game_snapshot())) == expected.state,"Separate process revalidates all six completions and preserves drafts/named designs exactly")
		if not failures.is_empty(): return
		if not await select_task("chapter_4/mixed"): return
		check(JSON.parse_string(JSON.stringify(ui.design)) == expected.mixed_draft,"Real tree entry restores the exact saved mixed-task draft after restart")
		check(state.named().mixed.has("Layout six-task QA"),"Named saved design survives independent restart")
		await capture("layout-six-restart")
		note("layout","independent-restart","All 6 UI-earned solutions, draft and named design revalidated; no progress injection")
	else:
		var file := FileAccess.open(path,FileAccess.WRITE)
		check(file != null,"Detached restart expectation can be written")
		if file == null: return
		file.store_string(JSON.stringify({"state":state.game_snapshot(),"mixed_draft":ui.design.duplicate(true)},"\t"))
		file.flush(); file.close()
		note("layout","restart-proof-prepared",path+"; run a separate process with --resume=layout --layout-restart-check")

func layout_closeout(final_draft: Dictionary) -> void:
	await press(ui.find_child("LayoutCoreReview",true,false)); await settle(8)
	ui = current_scene
	var review := ui.get_node_or_null("ThemeReflection") as AcceptDialog
	check(review != null and review.visible,"Earned mixed completion opens the actual core review")
	if review == null: return
	await capture("layout-six-earned-core-review")
	# Embedded modal coordinates are local to its Window, not the root viewport.
	# Close through the visible button with the same pointer dispatch as the game.
	if review.is_embedded():
		await click(Vector2(review.position)+review.get_ok_button().get_global_rect().get_center())
	else:
		check(false,"Core-review proxy requires its actual embedded window for root pointer dispatch")
		return
	await settle()
	check(not is_instance_valid(review) or not review.visible,"Actual review Close button dismisses the modal before journey navigation")
	if not failures.is_empty(): return
	if not await select_task("chapter_4/mixed"): return
	check(ui.design == final_draft,"Core review returns through the unified tree to the exact original draft")
	await capture("layout-six-returned-draft")
	await layout_restart_evidence()

func layout_path() -> void:
	if "--layout-restart-check" in OS.get_cmdline_user_args():
		await layout_restart_evidence()
		return
	if "--layout-closeout" in OS.get_cmdline_user_args():
		var state: Node = root.get_node("LayoutChapter")
		for task: String in LayoutCatalogQA.IDS:
			if not layout_earned(task): return
		check(state.named().get("mixed",{}).has("Layout six-task QA"),"Closeout resumes the actual named design saved during the previous six-task run")
		if not failures.is_empty(): return
		if not await select_task("chapter_4/mixed"): return
		var resumed_draft: Dictionary = state.named().mixed["Layout six-task QA"].duplicate(true)
		check(ui.design == resumed_draft,"Closeout tree entry restores the actual final draft matching its named saved design")
		if not failures.is_empty(): return
		note("layout","closeout-resume","Uses six independently revalidated UI-earned solutions and the actual named final draft; no rerun or injected progress")
		await layout_closeout(resumed_draft)
		return
	if not await layout_start("fields"): return
	check(ui.design.recipe.groups.size() == 1,"QA fields path starts with the existing one-group draft")
	if not failures.is_empty(): return
	if not await layout_pick(layout_group_order(0),0): return
	await layout_run("fields-record-order-fails")
	check(ui.runs.size() == 2 and not ui.runs[0].metrics.target_met and not ui.runs[1].metrics.target_met,"Record-major really misses the temperature traffic targets")
	await layout_ready_tools()
	if not await layout_pick(layout_group_order(0),1): return
	await layout_run("fields-field-order-pass")
	if not layout_earned("fields"): return

	if not await layout_start("records"): return
	await press(ui.find_child("LayoutCopyPrevious",true,false)); await settle()
	await layout_run("records-copied-field-order-fails")
	check(not ui.runs[0].metrics.target_met,"Copied temperature-oriented layout is unsuitable for sparse whole-record inspection")
	await layout_ready_tools()
	if not await layout_pick(layout_group_order(0),0): return
	await layout_run("records-record-order-pass")
	if not layout_earned("records"): return

	if not await layout_start("hot_cold"): return
	await press(ui.find_child("LayoutCopyPrevious",true,false)); await settle()
	if not await layout_split_hot_cold(): return
	await layout_run("hot-cold-grouped-pass")
	if not layout_earned("hot_cold"): return

	if not await layout_start("relocation"): return
	var order := ui.find_child("LayoutOrderChoice",true,false) as OptionButton
	if not await layout_pick(order,0): return
	if not await layout_strategy(0): return
	if not await layout_pick(ui.find_child("LayoutOrderChoice",true,false),1): return
	if not await layout_strategy(0): return
	await layout_run("relocation-direct-both-counterexample")
	var direct_a: int = int(ui.runs[0].metrics.total_cycles)
	var direct_b: int = int(ui.runs[1].metrics.total_cycles)
	check(ui.runs[0].metrics.target_met and not ui.runs[1].metrics.target_met,"Direct source meets one-off order A but misses repeated order B")
	await layout_ready_tools()
	if not await layout_pick(ui.find_child("LayoutOrderChoice",true,false),0): return
	if not await layout_strategy(1): return
	if not await layout_pick(layout_group_order(0),1): return
	if not await layout_pick(ui.find_child("LayoutOrderChoice",true,false),1): return
	if not await layout_strategy(1): return
	if not await layout_pick(layout_group_order(0),1): return
	await layout_run("relocation-copy-both-counterexample")
	check(int(ui.runs[0].metrics.total_cycles) > direct_a and int(ui.runs[1].metrics.total_cycles) < direct_b,"Real preparation cost reverses benefit between one-off and repeated queries")
	check(not ui.runs[0].metrics.target_met and ui.runs[1].metrics.target_met,"Copying both orders loses A despite helping B")
	await layout_ready_tools()
	if not await layout_pick(ui.find_child("LayoutOrderChoice",true,false),0): return
	if not await layout_strategy(0): return
	await layout_run("relocation-independent-orders-pass")
	if not layout_earned("relocation"): return

	if not await layout_start("batches"): return
	await press(ui.find_child("LayoutCopyPrevious",true,false)); await settle()
	check(ui.design.recipe == root.get_node("LayoutChapter").completed().relocation.orders.B.recipe,"Public copy action carries the actual previous B layout")
	if not await layout_strategy(1): return
	await layout_run("batches-full-copy-space-failure")
	check(ui.runs[0].metrics.error == "space_limit" and int(ui.runs[0].metrics.required_extra_bytes) > 48 and int(ui.runs[0].metrics.peak_extra_bytes) == 0,"Full copy requests more than 48 B and fails before allocating or copying")
	await layout_ready_tools()
	if not await layout_strategy(2): return
	if not await layout_batch_number(4): return
	await layout_run("batches-four-records-pass")
	check(int(ui.runs[0].metrics.peak_extra_bytes) <= 48 and ui.runs[0].scratch_maps[-1].cells.size() == 1,"Finite batches include a real one-record tail")
	if not layout_earned("batches"): return

	if not await layout_start("mixed"): return
	await press(ui.find_child("LayoutCopyPrevious",true,false)); await settle()
	check(ui.design.recipe.groups[0].fields == [0,3],"Mixed task starts from the player's previously earned hot group")
	if not await layout_strategy(2): return
	var alarm: Button = named_button(ui,local_caption("复制 告警","Copy Alarm"))
	check(alarm != null,"Public alarm-copy selector is available")
	if alarm == null: return
	if not alarm.button_pressed: await press(alarm); await settle()
	if not await layout_batch_number(4): return
	await layout_run("mixed-common-design-pass")
	if not layout_earned("mixed"): return
	for task: String in LayoutCatalogQA.IDS:
		if not layout_earned(task): return
	if not await layout_save_named("Layout six-task QA"): return
	var final_draft: Dictionary = ui.design.duplicate(true)
	if not await layout_batch_number(5): return
	await layout_button("撤销","Undo")
	check(ui.design == final_draft,"Public Undo restores the saved final design exactly")
	await layout_button("重做","Redo")
	check(int(ui.design.batch) == 5,"Public Redo restores the alternative batch draft")
	await layout_button("撤销","Undo")
	check(ui.design == final_draft,"Final Undo keeps the accepted four-record design")
	await layout_closeout(final_draft)
