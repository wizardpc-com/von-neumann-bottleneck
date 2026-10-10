extends SceneTree
## Geometry and real index routing for the detached saved-output viewing mapping.
const Focus = preload("res://experiments/creation/work_focus.gd")
const Canvas = preload("res://experiments/creation/work_canvas.gd")
const Model = preload("res://experiments/creation/model.gd")
var failures: Array[String] = []
var checks: int = 0
var clicked: int = -1
var located: int = -1

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)
func settle() -> void:
	for frame: int in 6: await process_frame

func run() -> void:
	var symbols: Array = [0,0,0,3,2,1,0,1,2,3,0,0,1,2,3,2,1,0,3]
	var canvas = Canvas.new(); root.add_child(canvas)
	canvas.set_output(symbols)
	canvas.cell_selected.connect(func(index: int) -> void: clicked = index)
	canvas.set_presentation(Canvas.PHRASE_MAPPING,-1)
	for width: int in [580,980]:
		canvas.size.x = width; canvas.update_layout()
		check(canvas.columns == 16,"Phrase grouping is stable across widths")
		for index: int in symbols.size():
			var expected_row: int = index/16
			var point: Vector2 = canvas.phrase_point(index)
			check(is_equal_approx(point.y,expected_row*180.0+48.0+symbols[index]*28.0),"Actual symbol selects its fixed lane %d"%index)
			check(canvas.index_at_position(point) == index,"Glyph click retains exact output index %d"%index)
			check(canvas.cell_rect(index).end.x <= width and canvas.cell_rect(index).end.y <= canvas.custom_minimum_size.y,"Output geometry remains inside scroll surface %d"%index)
		check(canvas.phrase_point(0).y == canvas.phrase_point(1).y and canvas.phrase_point(1).y == canvas.phrase_point(2).y,"Repeated saved symbols make a plateau")
		check(canvas.phrase_point(3).y > canvas.phrase_point(2).y,"An actual symbol change makes a lane transition")
		check(canvas.index_at_position(Vector2(10,50)) == -1 and canvas.index_at_position(Vector2(40,175)) == -1,"Lane legend and phrase gutter are not output cells")
		check(canvas.index_at_position(Vector2(width-20,230)) == -1,"Empty final phrase slots cannot select fabricated output")
	var click := InputEventMouseButton.new(); click.pressed = true; click.button_index = MOUSE_BUTTON_LEFT
	click.position = canvas.phrase_point(17); canvas._gui_input(click)
	check(clicked == 17 and canvas.selected == 17,"Pointer handler emits the actual saved index across a phrase break")
	var long_output: Array = []
	for index: int in 4096: long_output.append(index%4)
	canvas.set_output(long_output); canvas.size.x = 580; canvas.update_layout()
	check(canvas.output.size() == 4096 and canvas.index_at_position(canvas.phrase_point(4095)) == 4095,"Maximum output retains all4096 symbols and last-cell hit")
	check(canvas.cell_rect(4095).end.y <= canvas.custom_minimum_size.y,"Maximum output remains vertically reachable")
	canvas.queue_free(); await settle()

	var trained: Dictionary = Model.learn([[0,1,0,2,0,1,0,3]],1,Model.default_machine())
	var record: Dictionary = Model.generate(trained.model,[0],64,7,"weighted",Model.default_machine())
	var snapshot: Dictionary = {"id":"phrases-fixture","name":"同一件真实作品 / The same saved work","output":record.output.duplicate(),"recipe":record.recipe.duplicate(true),"mapping":"light-shapes-v1","parent":""}
	var saved_before: String = JSON.stringify(snapshot)
	var record_before: String = JSON.stringify(record)
	for english: bool in [false,true]:
		var view = Focus.new(); view.configure(snapshot,english,record); root.add_child(view)
		view.size = Vector2i(640,420); view.show(); await settle()
		view.mapping_choice.select(2); view.sync_presentation(); await settle()
		check(view.canvas.viewing_mapping == Canvas.PHRASE_MAPPING and view.work.mapping == "light-shapes-v1","Phrase mapping is independent of protected saved mapping")
		check(view.canvas.revealed == -1 and view.canvas.output == record.output,"Static phrase view contains complete actual output")
		var row_width: float = view.controls.get_theme_constant("h_separation")*(view.controls.get_child_count()-1)
		for control: Control in view.controls.get_children():
			row_width += control.get_combined_minimum_size().x
			var rect: Rect2 = control.get_global_rect()
			check(rect.position.x >= 0 and rect.end.x <= view.size.x and rect.end.y <= view.size.y,"Bilingual minimum window keeps control visible: "+control.name)
		# Short localized captions may naturally fit; require reflow only for overflow.
		var needs_wrap: bool = row_width > view.controls.size.x
		var last_on_next_row: bool = view.mapping_choice.position.y >= view.play_button.position.y+view.play_button.size.y
		check(view.controls.size.x <= 608 and (not needs_wrap or last_on_next_row),"Minimum window reflows controls when actual caption widths require it")
		print("Composition controls %s: row minimum %.1f / available %.1f; wrapped %s"%["en" if english else "zh",row_width,view.controls.size.x,last_on_next_row])
		check(view.tabs.size.y > 90,"Wrapped controls retain an appreciable scroll viewport")
		view.size = Vector2i(1080,620); await settle()
		view.static_overview = false; view.reduced_motion = true; view.seek(64); await settle()
		var last_rect: Rect2 = view.canvas.cell_rect(63)
		var visible_top: int = view.snapshot_scroll.scroll_vertical
		check(visible_top > 0 and last_rect.position.y >= visible_top and last_rect.end.y <= visible_top+view.snapshot_scroll.size.y,"Explicit reduced-motion seek follows the actual last cell into the scroll viewport")
		view.playing = false; view.size = Vector2i(640,420); await settle()
		var last_point: Vector2 = view.canvas.phrase_point(63)
		visible_top = view.snapshot_scroll.scroll_vertical
		check(view.cursor == 64 and last_point.y >= visible_top and last_point.y <= visible_top+view.snapshot_scroll.size.y,"Shrinking a stopped dynamic view keeps its actual last glyph visible")
		view.static_overview = true; view.sync_presentation(); await settle()
		check(view.snapshot_scroll.scroll_vertical == visible_top,"Static overview preserves the viewer’s scroll position")
		view.snapshot_scroll.scroll_vertical = 0; view.sync_presentation(); await settle()
		check(view.snapshot_scroll.scroll_vertical == 0,"Static overview never steals a manually chosen scroll position")
		view.size = Vector2i(1080,620); await settle()
		check(view.snapshot_scroll.scroll_vertical == 0,"Static expansion preserves manual scroll without following the cursor")
		view.size = Vector2i(640,420); await settle()
		check(view.snapshot_scroll.scroll_vertical == 0,"Static shrink preserves manual scroll without following the cursor")
		view.reduced_motion = false
		view.canvas.cell_selected.connect(func(index: int) -> void: clicked = index)
		click.position = view.canvas.phrase_point(20); view.canvas._gui_input(click)
		check(clicked == 20 and view.cursor == 21 and view.canvas.selected == 20,"Phrase selection routes to the same focus cursor")
		view.request_evidence.connect(func(index: int) -> void: located = index)
		view.explanation_button.pressed.emit()
		check(located == 20 and "feedback_write" in view.evidence_label.text,"Actual matching generation evidence follows selected phrase cell")
		view.seek(0); view.speed = 4; view.playing = true; view._process(0.5)
		check(view.cursor == 2 and view.canvas.revealed == 2,"Phrase playback reveals true sequential output at viewing tempo")
		view.reduced_motion = true; view._process(20)
		check(view.cursor == 2,"Reduced motion stops auto-advance in the new composition")
		view.playing = false; view.static_overview = true; view.sync_presentation()
		check(view.canvas.revealed == -1 and view.cursor == 2,"Reduced motion retains complete static output and evidence cursor")
		view.mapping_choice.select(0); view.sync_presentation()
		check(view.canvas.viewing_mapping == "light-trace-v1","Legacy trace remains at selector0")
		view.mapping_choice.select(1); view.sync_presentation()
		check(view.canvas.viewing_mapping == "light-shapes-v1","Saved original mapping remains at selector1")
		check(JSON.stringify(snapshot) == saved_before and JSON.stringify(record) == record_before and view.work == snapshot,"Composition/tempo/selection never change snapshot, recipe, costs or events")
		view.dismiss(); await settle()
	print("PASS: creation exhibition composition %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
