extends SceneTree
## Real Control geometry checks in headless mode, not pixel/native acceptance.
var checks: int = 0
var failures: Array[String] = []
func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for i: int in 6: await process_frame
func run() -> void:
	var scene = load("res://experiments/creation/workbench.tscn").instantiate()
	root.add_child(scene); await settle()
	root.mode = Window.MODE_WINDOWED; root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	for english: bool in [false,true]:
		scene.english = english; scene.build(); await settle()
		scene.source_kind = 2; scene.train_model(); scene.transport("predictive"); scene.inspect_cell(4); await settle()
		var collapsed_height: float = scene.causal_panel.size.y
		var raw: Dictionary = scene.causal_panel.raw_record.duplicate(true)
		var data: String = JSON.stringify(scene.session.data)
		scene.signal_view.page = 0; scene.signal_view.cursor = 4; scene.playing = true
		scene.set_evidence_expanded(true); await settle()
		check(not scene.signal_area.visible and not scene.playing, "Reading expansion pauses and hides presentation only")
		check(scene.causal_panel.size.y >= 300 and scene.causal_panel.size.y>collapsed_height+200, "Causal details gain a useful minimum-window reading area")
		check(scene.causal_panel.summary_label.text.begins_with("Cell 5" if english else "第 5 格"), "Expanded details preserve selected position in their own text")
		check(scene.causal_panel.raw_record == raw and JSON.stringify(scene.session.data) == data, "Reading mode cannot mutate evidence or draft")
		check(root.get_visible_rect().encloses(scene.causal_panel.get_global_rect()) and root.get_visible_rect().encloses(scene.evidence_toggle.get_global_rect()), "Expanded panel and return control remain within viewport")
		check(scene.signal_view.cursor == 4 and scene.signal_view.selected == 4, "Hidden presentation retains cursor and selection")
		scene.set_evidence_expanded(false); await settle()
		check(scene.signal_area.visible and scene.signal_view.cursor == 4 and scene.signal_view.selected == 4, "Returning to signal preserves position")
		scene.change_task(1); await settle()
		scene.compare_transport(); await settle()
		check(scene.evidence_expanded and scene.cost_comparison_page.size.y>=300, "New paired comparison opens expanded ledger")
		check(scene.cost_comparison_page.get_global_rect().encloses(scene.cost_comparison_view.get_global_rect()), "Cycle and packet bars are visible together without scrolling")
		print("GEOMETRY locale=",english," causalCollapsed=",collapsed_height," ledgerExpanded=",scene.cost_comparison_page.size," bars=",scene.cost_comparison_view.get_global_rect())
		scene.change_task(6); await settle()
		check(not scene.evidence_expanded and scene.signal_area.visible, "Changing task restores signal presentation")
	scene.queue_free(); await settle()
	print("PASS: creation evidence reading %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
