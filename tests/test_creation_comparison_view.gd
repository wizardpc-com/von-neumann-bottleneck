extends SceneTree
## Frozen-event and rendered UI checks; viewport input is not native OS acceptance.
const Model = preload("res://experiments/creation/model.gd")
const Comparison = preload("res://experiments/creation/comparison.gd")
const View = preload("res://experiments/creation/comparison_view.gd")
const Session = preload("res://experiments/creation/session.gd")
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame
func generated(samples: Array, order: int = 1, seed: int = 17, sampler: String = "max") -> Dictionary:
	var machine: Dictionary = Model.default_machine()
	var learned: Dictionary = Model.learn(samples,order,machine)
	return Model.generate(learned.model,[0],16,seed,sampler,machine)
func capture(name: String) -> void:
	if "--comparison-view-capture" not in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless": return
	await settle()
	RenderingServer.force_draw(false)
	await process_frame
	var folder: String = "res://.godot/creation-comparison-captures"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	check(root.get_texture().get_image().save_png(folder.path_join(name+".png")) == OK,"Captured "+name)

func run() -> void:
	var a: Dictionary = generated([[0,1,0,3]]) # ABAD
	var b: Dictionary = generated([[0,2,0,3]]) # ACAD
	var report: Dictionary = Comparison.compare(a,b)
	check(a.ok and b.ok and report.single and report.effective_design and report.first_difference == 1,"ABAD→ACAD has a fixed first differing generated cell")
	var view := View.new()
	root.add_child(view); await settle()
	view.configure(a,b,report,false); await settle()
	check(view.summary.text.contains("第 2 格") and not view.side_buttons[0].disabled and not view.side_buttons[1].disabled,"Both actual first-difference cells are accessible")
	check(view.summary.text.contains("A B A D → A C A D") and view.side_buttons[0].text.contains(a.recipe.model_id.substr(0,8)) and view.side_buttons[1].text.contains(b.recipe.model_id.substr(0,8)),"Actual intervention and both frozen model identities stay beside the bars")
	check(view.side_columns.get_child(0).find_child("ABCount1",true,false).value == 1 and view.side_columns.get_child(1).find_child("ABCount2",true,false).value == 1,"A/B bars use recorded B/C successor counts")
	var selected: Array = []
	view.side_selected.connect(func(lane: int, index: int) -> void: selected.append([lane,index]))
	view.side_buttons[0].pressed.emit(); view.side_buttons[1].pressed.emit()
	check(selected == [[0,1],[2,1]],"Both buttons route to the actual A/B cell")
	view.select_context([0]); await settle()
	check(view.summary.text.contains("冻结模型") and view.side_columns.get_child(0).find_child("ABCount1",true,false).value == 1 and view.side_columns.get_child(1).find_child("ABCount2",true,false).value == 1,"Player-selected context compares frozen rule rows without generating")
	view.select_context([3,3]); await settle()
	check((view.side_columns.get_child(0).get_child(1) as Label).text.contains("回退") and (view.side_columns.get_child(1).get_child(1) as Label).text.contains("回退"),"Unseen context exposes both actual fallbacks")
	view.context_input.text = "A B C"
	view.inspect_context_input()
	check(view.summary.text.contains("最多两个"),"Invalid context does not produce a fabricated rule")
	var equal_a: Dictionary = generated([[0,1,0,1]])
	var equal_b: Dictionary = generated([[0,1,0,1],[0,1,0,1]])
	view.configure(equal_a,equal_b,Comparison.compare(equal_a,equal_b),false); await settle()
	check(view.summary.text.contains("输出相同") and view.side_buttons[0].disabled,"Equal output has no invented first difference")
	view.select_context([0]); await settle()
	check(view.side_columns.get_child(0).find_child("ABCount1",true,false).value == 2 and view.side_columns.get_child(1).find_child("ABCount1",true,false).value == 4,"Equal output still exposes changed frozen counts")
	var multi: Dictionary = generated([[0,2,0,3]],2,17,"weighted")
	view.configure(a,multi,Comparison.compare(a,multi),false); await settle()
	check(view.summary.text.contains("不将差异归因于一项") and view.summary.text.contains("样例") and view.summary.text.contains("记忆") and view.summary.text.contains("采样"),"Multiple changed factors are named without a single-cause claim")
	var seed_only: Dictionary = generated([[0,1,0,3]],1,891,"weighted")
	var same_recipe_weighted: Dictionary = generated([[0,1,0,3]],1,17,"weighted")
	view.configure(same_recipe_weighted,seed_only,Comparison.compare(same_recipe_weighted,seed_only),false); await settle()
	check(view.summary.text.contains("不将差异归因于一项"),"Only a random seed change is not an intended causal intervention")
	var absent: Dictionary = b.duplicate(true)
	absent.erase("events")
	view.configure(a,absent,Comparison.compare(a,absent),false); await settle()
	check(view.summary.text.contains("没有已记录生成事件") and view.side_columns.get_child(1).find_child("ABCount2",true,false) == null,"Missing event cannot become an inferred per-cell count")
	view.select_context([0]); await settle()
	check(view.side_columns.get_child(1).find_child("ABCount2",true,false).value == 1,"Missing event still permits frozen-rule lookup")
	view.queue_free(); await settle()
	var packed: PackedScene = load("res://experiments/creation/workbench.tscn")
	for locale: String in ["zh_CN","en"]:
		var scene = packed.instantiate()
		root.add_child(scene); await settle()
		root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(Vector2i(1280,720)); await settle()
		scene.session.data = Session.fresh()
		scene.english = locale == "en"
		scene.session.data.mode = "generate"
		scene.task = 7
		scene.pinned_creation = a.duplicate(true)
		scene.compared_creation = b.duplicate(true)
		scene.creation_report = report.duplicate(true)
		scene.latest = b.duplicate(true); scene.latest.kind = "generation"
		scene.build(); await settle()
		scene.show_creation_difference(); await settle()
		check(scene.causal_tabs.current_tab == scene.creation_comparison_view.get_index(),"First difference opens the A/B view")
		check(scene.evidence_expanded and not scene.signal_area.visible,"A/B evidence gets the reading area rather than a clipped strip")
		check(root.get_visible_rect().encloses(scene.find_child("ModeActions",true,false).get_global_rect()),"Main action stays within 1280×720")
		check(root.get_visible_rect().encloses(scene.creation_comparison_view.get_global_rect()),"A/B tab stays within 1280×720")
		var ab_scroll: ScrollContainer = scene.creation_comparison_view.find_child("ABScroll",true,false) as ScrollContainer
		for side: int in 2:
			for symbol: int in 4:
				var bar: Control = scene.creation_comparison_view.side_columns.get_child(side).find_child("ABCount"+str(symbol),true,false) as Control
				check(bar != null and ab_scroll.get_global_rect().encloses(bar.get_global_rect()),"All A/B count bars visible without scrolling: %d/%d"%[side,symbol])
		await capture("ab-first-"+locale)
		scene.creation_comparison_view.select_context([0]); await settle()
		await capture("ab-context-"+locale)
		scene.creation_comparison_view.side_buttons[0].pressed.emit(); await settle()
		check(scene.focused_lane == 0 and scene.focused_cell == 1,"A action locates frozen A cell through workbench")
		scene.show_creation_comparison(); await settle()
		check(scene.causal_tabs.current_tab == scene.creation_comparison_view.get_index(),"A/B panel remains reachable after cell inspection")
		scene.queue_free(); await settle()
	print("PASS: creation comparison view %d checks" % checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
