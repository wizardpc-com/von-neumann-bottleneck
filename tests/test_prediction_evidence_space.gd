extends "res://tests/test_prediction_investigation_context.gd"
## Actual specification and revealed-event reading at the minimum viewport.

func complete_rows() -> int:
	var tree: Tree = ui.events
	var visible: Rect2 = tree.get_global_rect().intersection(root.get_visible_rect())
	var count: int = 0
	for row: TreeItem in tree.get_root().get_children():
		var rect: Rect2 = tree.get_item_area_rect(row)
		var top: float = tree.global_position.y+rect.position.y
		if rect.size.y > 0 and top >= visible.position.y and top+rect.size.y <= visible.end.y: count += 1
	return count

func select_longest_event() -> void:
	var tree: Tree = ui.events
	var target: TreeItem
	var longest: int = -1
	for row: TreeItem in tree.get_root().get_children():
		var length: int = ui.event_text(row.get_metadata(0)).length()
		if length > longest: target = row; longest = length
	check(target != null,"A real revealed event is available for detailed reading")
	if target == null: return
	tree.scroll_to_item(target,true); await settle()
	var row_rect: Rect2 = tree.get_item_area_rect(target)
	var visible: Rect2 = Rect2(tree.global_position+row_rect.position,row_rect.size).intersection(tree.get_global_rect()).intersection(root.get_visible_rect())
	var hit := Vector2(-1,-1)
	for y: int in range(int(visible.position.y)+2,int(visible.end.y)-2,2):
		for x: int in range(int(visible.position.x)+24,int(visible.end.x)-16,8):
			var at := Vector2(x,y)
			if tree.get_item_at_position(at-tree.global_position) == target: hit = at; break
		if hit.x >= 0: break
	check(hit.x >= 0,"The revealed event has a visible actual Tree hit-test point")
	if hit.x < 0: return
	await click(hit)
	check(tree.get_selected() == target and ui.details.text == ui.event_text(target.get_metadata(0)),"Mouse selection opens that revealed event's complete actual details")

func reading_bounds(context: String) -> void:
	var frame: Rect2 = root.get_visible_rect()
	var spec := handle("SpecificationScroll") as ScrollContainer
	var normal := ui.mission.get_theme_font("font") as Font
	var line_height: float = normal.get_height(ui.mission.get_theme_font_size("font_size"))
	check(spec.is_visible_in_tree() and spec.size.y >= line_height,context+": Task and machine has space for complete readable text lines")
	check(frame.encloses(spec.get_global_rect()),context+": specification reading stays inside the viewport")
	check(complete_rows() >= 3,context+": at least three complete revealed event rows fit below the Tree header")
	check(ui.events.size.y >= 120 and ui.details.size.y >= 120 and ui.details.scroll_active,context+": events and scrollable detail each retain a readable area")
	check(not ui.events.get_global_rect().intersects(ui.details.get_global_rect()),context+": event list and details do not overlap")
	for name: String in ["Events","TraceDetails","Step","Run","Restart","StatusScroll"]:
		var control: Control = handle(name)
		check(control.is_visible_in_tree() and frame.encloses(control.get_global_rect()),context+": reading does not displace core controls "+name)
	check(handle("StatusScroll").get_global_rect().encloses(ui.status.get_global_rect()),context+": every actual progress line remains visible")

func _run() -> void:
	if not "VonNeumannBottleneckChecks" in OS.get_user_data_dir():
		push_error("Requires an isolated verification profile"); quit(2); return
	capture_enabled = "--prediction-evidence-capture" in OS.get_cmdline_user_args()
	if capture_enabled and DisplayServer.get_name() == "headless":
		push_error("Evidence capture requires a rendering display"); quit(2); return
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("TaskNavigation").pending = ""
	ProjectSettings.set_setting("game/reduced_motion",true)
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		await new_scene()
		for task: int in 3:
			if ui.task != task: await switch_to(task)
			await choose(ui.rule,1)
			for step: int in 4: await press(handle("Step"))
			prefix_is(4)
			var before: Dictionary = ui.public_observation()
			var signature: String = ui.active_trace.canonical_signature()
			await tab("PredictionRuleTabs",1)
			await tab("PredictionEvidenceTabs",1)
			var context: String = locale+"-task"+str(task)
			reading_bounds(context)
			var spec := handle("SpecificationScroll") as ScrollContainer
			if spec.size.y > 0:
				await point(spec.get_global_rect().get_center())
				for attempt: int in 80:
					var visible: Rect2 = spec.get_global_rect().intersection(ui.mission.get_global_rect())
					if visible.size.y >= ui.mission.get_theme_font("font").get_height(ui.mission.get_theme_font_size("font_size")): break
					await click(spec.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
				check(spec.get_global_rect().intersection(ui.mission.get_global_rect()).size.y >= ui.mission.get_theme_font("font").get_height(ui.mission.get_theme_font_size("font_size")),context+": actual wheel input makes the task specification readable")
				for attempt: int in 80:
					var bar: VScrollBar = spec.get_v_scroll_bar()
					if bar.value >= bar.max_value-bar.page-1: break
					await click(spec.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
				check(spec.get_v_scroll_bar().value > 0,context+": specification scroll reaches the machine explanation")
				var machine := spec.get_child(0).get_child(spec.get_child(0).get_child_count()-1) as Label
				check(machine != null and spec.get_global_rect().intersection(machine.get_global_rect()).size.y >= machine.get_theme_font("font").get_height(machine.get_theme_font_size("font_size")),context+": actual machine-cost text has complete visible lines after scrolling")
			await select_longest_event()
			var detail_scroll: VScrollBar = ui.details.get_v_scroll_bar()
			if detail_scroll.max_value > detail_scroll.page:
				await click(ui.details.get_global_rect().get_center(),MOUSE_BUTTON_WHEEL_DOWN)
				check(detail_scroll.value > 0,context+": long actual event details scroll through ordinary wheel input")
			check(ui.public_observation() == before and ui.active_trace.canonical_signature() == signature,context+": specification and event reading do not reveal future evidence, run again or change rules")
			if capture_enabled:
				await create_timer(6.0).timeout; await fit_window(); await shot(context)
		ui.queue_free(); await settle()
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"prediction evidence space %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
