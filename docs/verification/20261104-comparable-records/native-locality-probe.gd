extends SceneTree
## Creates measured Test fixtures; subsequent actions require native UI input.
## Run only in a copied QA project with a fresh dedicated native-review profile.
const Templates = preload("res://src/simulation/program_templates.gd")
var host: Control
var evidence: Array[Dictionary] = []
var original: Dictionary = {}
var expected_metrics: Dictionary = {}
var expected_signature: String = ""

func _init() -> void: call_deferred("prepare")

func settle() -> void:
	for frame: int in 4: await process_frame

func prepare() -> void:
	if not OS.get_user_data_dir().contains("VonNeumannBottleneckChecks/20261104-round2/native-review") or DisplayServer.get_name() == "headless":
		push_error("This native probe requires a dedicated QA profile and renderer.")
		quit(1)
		return
	root.size = Vector2i(1280,800)
	root.title = "VNB Round2 — isolated native review"
	root.get_node("Localization").set_locale("zh_CN")
	root.get_node("GameMode").set_mode(&"test")
	root.get_node("LocalityChapter").reset_test_progress()
	host = load("res://src/ui/main.tscn").instantiate()
	root.add_child(host)
	await settle()
	host._start_level(&"capstone")
	await settle()
	host._run_simulation("Official Test Set")
	host._finish_playback()
	var baseline: int = host.current_trace.metrics.total_cycles
	host._select_block_lines(1,true)
	host._run_simulation("Official Test Set")
	host._finish_playback()
	expected_metrics = host.current_trace.metrics.duplicate(true)
	expected_signature = host.current_trace.canonical_signature()
	if baseline != 642 or expected_metrics.total_cycles != 138:
		push_error("Native fixture differs from the authored measured workload.")
		quit(1)
		return
	if host.level_completion_overlay.visible: host.level_completion_overlay.dismiss()
	host._select_cache(2,true)
	host._select_block_lines(2,true)
	host.editor.set_block_signals(true)
	host.editor.text = "# native unfinished draft\nacc =\n"
	host.editor.set_caret_line(1)
	host.editor.set_caret_column(4)
	host.editor.set_block_signals(false)
	host._on_program_changed()
	original = host._current_design_draft()
	host._open_instrument(&"profiler",true)
	await settle()
	host.restore_best_button.pressed.connect(record_later.bind("native-load"))
	host.official_run_button.pressed.connect(record_later.bind("native-run"))
	host.undo_restore_best_button.pressed.connect(record_later.bind("native-return"))
	host.finish_playback_button.pressed.connect(record_later.bind("native-finish"))
	await record("fixture-ready")
	print("NATIVE_READY: Actual Test baseline 642; best 138/cost4; invalid draft preserved.")

func record_later(label: String) -> void:
	record.call_deferred(label)

func record(label: String) -> void:
	await settle()
	var draft: Dictionary = host._current_design_draft()
	var row: Dictionary = {
		"action":label,"mode":str(host.workspace_mode),"level":str(host.current_level_id),
		"draft":draft,"returned_exact_draft":draft == original,
		"trace_present":host.current_trace != null,
		"run_disabled":host.official_run_button.disabled,
		"restore_return_visible":host.undo_restore_best_button.visible,
		"best_cycles":host._best_history_record().get("cycles",-1),
	}
	if host.current_trace != null:
		row["metrics"] = host.current_trace.metrics.duplicate(true)
		row["matches_measured_best"] = host.current_trace.metrics == expected_metrics
		row["matches_measured_trace"] = host.current_trace.canonical_signature() == expected_signature
	evidence.append(row)
	var file := FileAccess.open("user://native-observations.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(evidence,"\t"))
	file.close()
	await RenderingServer.frame_post_draw
	var path: String = "user://"+label+".png"
	var error: Error = root.get_texture().get_image().save_png(path)
	print("NATIVE_OBSERVATION: "+JSON.stringify(row))
	print("NATIVE_CAPTURE: "+ProjectSettings.globalize_path(path)+" result="+str(error))
