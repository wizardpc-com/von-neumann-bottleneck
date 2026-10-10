extends SceneTree
## Completed measurements survive draft edits, but source location binds to trace text.
var checks: int = 0
var failures: Array[String] = []

func _init() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 6: await process_frame

func next_source_event(main: Control) -> int:
	for index: int in range(main.playback_index,main.current_trace.events.size()):
		if main.current_trace.events[index].source_line > 0: return index
	return -1

func step_to_source(main: Control) -> bool:
	var index: int = next_source_event(main)
	if index < 0: return false
	while main.playback_index <= index: main._step_playback()
	return true

func run() -> void:
	var mode: Node = root.get_node("GameMode")
	var chapter: Node = root.get_node("SystemChapter")
	mode.set_mode(&"test")
	for locale: String in ["zh_CN","en"]:
		root.get_node("Localization").set_locale(locale)
		chapter.reset_test_progress()
		var main: Control = load("res://src/system_lab/system_lab.tscn").instantiate()
		root.add_child(main); await settle()
		main._start_level(&"cpu_speed")
		main.prediction_selector.select(1); main._lock_prediction()
		main._run_official()
		main.playback_running = false
		check(main.current_trace != null and main.latest_receipt != null,locale+": actual official run produces trace and measured receipt")
		if main.current_trace == null or main.latest_receipt == null:
			main.queue_free(); await settle(); continue
		var trace = main.current_trace
		var trace_signature: String = trace.canonical_signature()
		var receipt_signature: String = main.latest_receipt.canonical_signature()
		var measured_metrics: Dictionary = trace.metrics.duplicate(true)
		var history: String = main.history_label.get_parsed_text()
		var source: String = trace.program_source
		check(step_to_source(main) and main.highlighted_source_line >= 0,locale+": real playback locates an actual executed source line")
		check(main.editor.editable,locale+": the actual Program editor permits this player edit")
		main.editor.set_caret_line(0); main.editor.set_caret_column(0)
		main.editor.insert_text_at_caret("# inserted through CodeEdit\n")
		await process_frame
		check(main.editor.text == "# inserted through CodeEdit\n"+source and main.draft_dirty,locale+": real insertion emits text_changed and leaves the executed source unapplied")
		check(main.highlighted_source_line == -1,locale+": real insertion clears tracked source location")
		var clear_backgrounds: bool = true
		for line: int in main.editor.get_line_count():
			clear_backgrounds = clear_backgrounds and main.editor.get_line_background_color(line).is_equal_approx(Color.TRANSPARENT)
		check(clear_backgrounds,locale+": insertion leaves no source background on a shifted line")
		var inserted_caret: int = main.editor.get_caret_line()
		var inserted_column: int = main.editor.get_caret_column()
		check(step_to_source(main),locale+": old trace can still step after real insertion")
		check(main.highlighted_source_line == -1 and main.editor.get_caret_line() == inserted_caret and main.editor.get_caret_column() == inserted_column,locale+": source event leaves the real insertion caret untouched")
		check(main.current_trace == trace and trace.canonical_signature() == trace_signature and trace.metrics == measured_metrics,locale+": real insertion preserves authoritative trace and metrics")
		check(main.latest_receipt.canonical_signature() == receipt_signature and main.history_label.get_parsed_text() == history,locale+": real insertion preserves accepted evidence and cost history")
		main.editor.text = source; main._on_program_changed()
		check(step_to_source(main) and main.highlighted_source_line >= 0,locale+": actual executed text can be located after restoring the inserted draft")
		for draft: String in ["# inserted draft line\n"+source,source.replace("acc += value","acc += 1")]:
			main.editor.text = draft; main._on_program_changed()
			main.editor.set_caret_line(main.editor.get_line_count()-1)
			var caret: int = main.editor.get_caret_line()
			check(main.highlighted_source_line == -1,locale+": changing draft clears the old source location")
			check(step_to_source(main),locale+": old trace still supports an actual source event step")
			check(main.highlighted_source_line == -1 and main.editor.get_caret_line() == caret,locale+": old event cannot highlight different draft text or move its caret")
			check(main.current_trace == trace and trace.canonical_signature() == trace_signature and trace.metrics == measured_metrics,locale+": draft editing preserves authoritative trace and measured metrics")
			check(main.latest_receipt.canonical_signature() == receipt_signature and main.history_label.get_parsed_text() == history,locale+": draft editing preserves accepted receipt and cost history")
			main.editor.text = source; main._on_program_changed()
			check(step_to_source(main) and main.highlighted_source_line >= 0,locale+": restoring exact executed text permits source location again")
		main.queue_free(); await settle()
	print("PASS: system trace source binding %d checks"%checks if failures.is_empty() else "FAIL: "+str(failures))
	quit(0 if failures.is_empty() else 1)
