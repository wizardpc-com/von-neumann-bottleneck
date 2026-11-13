extends "res://experiments/viewport_input.gd"
## Existing public command text remains beside the actual editable program.
const Catalog = preload("res://src/overlap_chapter/overlap_catalog.gd")

func reference_key(level: String) -> StringName:
	return StringName("overlap.commands."+("arrival" if level == "arrival" else "cache" if level in ["prefetch","distance"] else "both" if level == "synthesis" else "buffer"))

func settle_window() -> void:
	if DisplayServer.get_name() == "headless": return
	var stable: int = 0
	for frame: int in 60:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
		DisplayServer.window_set_size(Vector2i(1280,720))
		await create_timer(0.1).timeout
		RenderingServer.force_draw(false)
		var picture: Image = root.get_texture().get_image()
		stable = stable+1 if picture != null and picture.get_size() == Vector2i(1280,720) else 0
		if stable >= 5: break
	check(stable >= 5,"Actual reference window stabilizes at 1280x720")

func run_button() -> Button:
	return named_button(ui.panels.program,root.get_node("Localization").text(&"overlap.run"))

func check_layout(reference: Label, context: String) -> void:
	var frame: Rect2 = root.get_visible_rect()
	var body: Rect2 = ui.panels.program.content_host.get_global_rect()
	for control: Control in [ui.panels.program,ui.editor,reference,run_button()]:
		check(control != null and control.is_visible_in_tree() and frame.encloses(control.get_global_rect()),context+": program, full reference and Run fit the viewport")
	check(body.encloses(reference.get_global_rect()) and body.encloses(run_button().get_global_rect()),context+": reference and Run are not clipped by their panel")
	check(reference.get_theme_font_size("font_size") == 14 and ui.editor.get_theme_font_size("font_size") == 19,context+": reference and editor keep their existing font sizes")
	check(reference.get_visible_line_count() == reference.get_line_count(),context+": every reference line is visible together")
	check(not reference.get_global_rect().intersects(ui.editor.get_global_rect()) and not reference.get_global_rect().intersects(run_button().get_global_rect()),context+": reference does not overlap editing or execution")
	if ui.experiment_note.visible:
		check(body.encloses(ui.experiment_note.get_global_rect()) and frame.encloses(ui.experiment_note.get_global_rect()),context+": expanded experiment guidance also fits without clipping")
		check(not ui.experiment_note.get_global_rect().intersects(reference.get_global_rect()),context+": expanded experiment guidance does not cover the reference")
	for action: Node in ui.panels.program.find_children("*","Button",true,false):
		check(action.text not in ["←","→"],context+": command lookup requires no paging buttons")

func take_capture(context: String) -> void:
	if DisplayServer.get_name() == "headless" or "--overlap-reference-capture" not in OS.get_cmdline_user_args(): return
	await settle_window()
	# Allow the ordinary opening guidance to leave naturally before capturing.
	await create_timer(6.0).timeout; await settle_window()
	RenderingServer.force_draw(false)
	var picture: Image = root.get_texture().get_image()
	check(picture != null and picture.get_size() == Vector2i(1280,720),context+": screenshot has actual 1280x720 pixels")
	if picture != null: check(picture.save_png(evidence_root+context+".png") == OK,context+": unmodified instruction reference capture is saved")

func _run() -> void:
	if not "VonNeumannBottleneckChecks" in OS.get_user_data_dir():
		push_error("Requires an isolated verification profile"); quit(2); return
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("TaskNavigation").pending = ""
	ProjectSettings.set_setting("game/reduced_motion",true)
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var game_before: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		ui = load("res://src/overlap_chapter/overlap_chapter.tscn").instantiate()
		root.add_child(ui); current_scene = ui; await settle(8)
		await settle_window()
		for level: String in Catalog.IDS:
			ui._open_level(level,false); await settle(8)
			ui._toggle("program",true); await settle(8)
			var context: String = locale+"-"+level
			var reference := ui.find_child("OverlapInstructionReference",true,false) as Label
			check(reference != null,context+": all current commands have one visible reference instead of a paged card")
			if reference == null: continue
			check(reference.text == root.get_node("Localization").text(reference_key(level)),context+": reference reuses exactly the existing localized command text")
			check_layout(reference,context)
			var original: String = ui.editor.text
			var board_before_run: Dictionary = ui.board.duplicate(true)
			await press(run_button()); await settle(8)
			# Exercise the existing experiment presenter after a real run, without
			# installing a reference solution or fabricating completion.
			ui._continue_experiment(); await settle(8)
			check(ui.experiment_note.visible and not ui.experiment_note.text.is_empty(),context+": existing experiment action expands its actual guidance")
			check_layout(reference,context+" expanded experiment")
			var signatures: Array[String] = []
			for trace: SimulationTrace in ui.runs: signatures.append(trace.canonical_signature())
			var completed: Dictionary = root.get_node("OverlapChapter").completed().duplicate(true)
			await press(ui.editor)
			var last: int = ui.editor.get_line_count()-1
			ui.editor.set_caret_line(last); ui.editor.set_caret_column(ui.editor.get_line(last).length())
			await key(KEY_ENTER); await type_text("# reference lookup"); await settle()
			var edited: String = original+"\n# reference lookup"
			check(ui.editor.text == edited and ui.trace_stale,context+": actual typing edits the program and marks old evidence stale")
			# Run saves the actual graph layout before evaluating it. Bind lookup's
			# invariants after that legitimate setup, immediately before reading.
			var board: Dictionary = ui.board.duplicate(true)
			var lookup_source: String = ui.editor.text
			var caret: Vector2i = Vector2i(ui.editor.get_caret_line(),ui.editor.get_caret_column())
			await click(reference.get_global_rect().get_center()); await settle()
			var after_caret: Vector2i = Vector2i(ui.editor.get_caret_line(),ui.editor.get_caret_column())
			print("REFERENCE_LOOKUP ",JSON.stringify({"context":context,"layout_changed_before_lookup":board_before_run != board,"program_unchanged":ui.editor.text == lookup_source,"board_unchanged":ui.board == board,"caret_before":str(caret),"caret_after":str(after_caret)}))
			if ui.board != board: print("LOOKUP_BOARD_CHANGE ",JSON.stringify({"context":context,"before":board,"after":ui.board}))
			if ui.editor.text != lookup_source: print("LOOKUP_PROGRAM_CHANGE ",JSON.stringify({"context":context,"before":lookup_source,"after":ui.editor.text}))
			check(ui.editor.text == lookup_source and ui.editor.text == edited,context+": reading the reference preserves the complete edited program")
			check(ui.board == board,context+": reading the reference preserves the exact current board")
			check(after_caret == caret,context+": reading the reference preserves the editor caret")
			check(root.get_node("OverlapChapter").completed() == completed and ui.runs.size() == signatures.size(),context+": lookup creates no run or completion")
			for index: int in signatures.size(): check(ui.runs[index].canonical_signature() == signatures[index],context+": lookup leaves the complete measured Trace unchanged")
			check_layout(reference,context+" after editing")
			await take_capture(context)
			await press(run_button()); await settle(8)
			check(ui.trace.program_source == edited and not ui.trace_stale,context+": the original Run action still executes the current program")
		ui.queue_free(); current_scene = null; await settle(8)
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == game_before,"Instruction lookup never changes earned Game circuit content")
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"overlap instruction reference %d checks, %d failures" % [observations.size(),failures.size()])
	quit(0 if failures.is_empty() else 1)
