extends SceneTree
## The actual laboratory terminal must host a saved-work Window without stalling.
## Stage output is bounded; use an external process timeout if a frame never returns.
const Session = preload("res://experiments/creation/session.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var checks: int = 0
var failures: Array[String] = []
var stage_count: int = 0
var fixture: Dictionary = {}
var profile_path: String = ""
var profile_bytes: String = ""
var game_signature: String = ""
var hub: Control
var journal: Control
var pages: Control
var observed_window: Window

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func stage(label: String) -> void:
	# Never print a whole work, Trace, or unbounded stream of layout events.
	if stage_count >= 24: return
	stage_count += 1
	var state := {"stage":label,"ticks_ms":Time.get_ticks_msec(),
		"static_bytes":OS.get_static_memory_usage(),"nodes":get_node_count()}
	if is_instance_valid(observed_window):
		state["window"] = {"visible":observed_window.visible,"exclusive":observed_window.exclusive,
			"embedded":observed_window.is_embedded(),"size":str(observed_window.size),
			"position":str(observed_window.position),"ready":observed_window.is_node_ready()}
	print("LAB_WORK_STAGE ",JSON.stringify(state))

func settle(frames: int = 8) -> void:
	for frame: int in frames: await process_frame

func prepare_saved_work() -> bool:
	profile_path = Session.launch_path()
	# The verifier gives this suite its own user directory. Refuse to overwrite
	# any existing profile or interrupted transaction if run outside that setup.
	check(Files.transaction_paths(profile_path).is_empty(),"Fixture starts with no existing creation profile or transaction")
	if not Files.transaction_paths(profile_path).is_empty(): return false
	var writer = Session.new()
	var opened: Dictionary = writer.open(profile_path)
	check(opened.get("writable",false),"Fixture acquires its isolated creation writer")
	if not opened.get("writable",false): writer.close(); return false
	writer.data.draft.length = 16
	var trained: Dictionary = writer.train()
	check(trained.get("ok",false),"Fixture learns a real bounded model")
	if not trained.get("ok",false): writer.close(); return false
	var restored: Dictionary = writer.transport([0,1,0,2],"predictive")
	check(restored.get("ok",false),"Fixture actually restores a predictive packet")
	if not restored.get("ok",false): writer.close(); return false
	var mode: Dictionary = writer.set_mode("predict")
	var started: Dictionary = writer.begin_prediction("practice") if mode.get("ok",false) else {}
	check(started.get("ok",false),"Fixture starts an eligible real practice prediction")
	if not started.get("ok",false): writer.close(); return false
	for step: int in 32:
		if writer.prediction.finished: break
		var committed: Dictionary = writer.commit_prediction()
		var revealed: Dictionary = writer.reveal_prediction() if committed.get("ok",false) else {}
		if not revealed.get("ok",false): break
	check(writer.prediction.finished,"Fixture completes its bounded practice without fabricating eligibility")
	if not writer.prediction.finished: writer.close(); return false
	mode = writer.set_mode("generate")
	var generated: Dictionary = writer.generate() if mode.get("ok",false) else {}
	check(generated.get("ok",false) and generated.get("output",[]).size() == 16,"Fixture generates a small actual 16-cell work")
	if not generated.get("ok",false): writer.close(); return false
	var kept: Dictionary = writer.save_work("Terminal snapshot fixture")
	check(kept.get("ok",false),"Fixture explicitly keeps its actual output through the existing save path")
	if not kept.get("ok",false): writer.close(); return false
	fixture = kept.work.duplicate(true)
	writer.close()
	check(not DirAccess.dir_exists_absolute(Lease.lock_path(profile_path)),"Fixture releases the writer before read-only Journal access")
	var saved: Dictionary = Files.read_session(profile_path,Session.decode)
	check(saved.get("ok",false) and saved.get("data",{}).get("works",[]) == [fixture],"Production decoder validates the sole saved fixture")
	profile_bytes = FileAccess.get_file_as_string(profile_path)
	return saved.get("ok",false)

func observe_child(node: Node) -> void:
	if not node is Window or node.name != "JournalWorkFocus": return
	observed_window = node as Window
	stage("work-focus-entered-tree")
	observed_window.ready.connect(func() -> void: stage("work-focus-ready"),CONNECT_ONE_SHOT)

func finish() -> void:
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"laboratory saved-work window %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	stage("start")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	ProjectSettings.set_setting("game/reduced_motion",true)
	ProjectSettings.set_setting("playtest/offline_tester",false)
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	game_signature = root.get_node("GlobalSave").game_player_content.canonical_signature()
	if not prepare_saved_work(): finish(); return
	stage("valid-work-saved")
	hub = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await settle()
	stage("laboratory-ready")
	check(is_instance_valid(hub.laboratory) and hub.laboratory.terminal_pages != null,"Actual laboratory supplies its production terminal viewport")
	if not is_instance_valid(hub.laboratory) or hub.laboratory.terminal_pages == null: finish(); return
	pages = hub.laboratory.terminal_pages
	hub._open_journey_journal()
	await settle()
	journal = hub.journey_journal
	check(journal.visible and journal.get_viewport() == pages.viewport,"Actual Journal is mounted inside LabTerminalPages, not a root-only substitute")
	check(not journal.work_view_button.disabled and journal.work_selector.item_count == 1,"Journal finds the one actual saved work")
	check(not root.get_node("PlaytestData")._feedback_visible and not root.get_node("OfflineFeedback").busy and not paused,"No feedback lock or paused tree masks the saved-work action")
	journal.child_entered_tree.connect(observe_child)
	stage("before-open-work")
	# Emit the real button signal: its existing callback invokes _open_work.
	journal.work_view_button.pressed.emit()
	stage("after-open-work-return")
	await process_frame
	stage("first-process-frame")
	await process_frame
	stage("second-process-frame")
	await settle()
	stage("window-settled")
	var exhibit: Window = journal.work_focus
	check(is_instance_valid(exhibit) and exhibit.visible,"Saved-work action returns and opens a visible WorkFocus")
	if not is_instance_valid(exhibit): finish(); return
	check(exhibit == observed_window and exhibit.get_parent() == journal,"The actual observed WorkFocus remains a child of its Journal")
	check(exhibit.is_embedded() and exhibit in pages.viewport.get_embedded_subwindows(),"WorkFocus is embedded in the actual terminal viewport")
	check(exhibit.borderless and not exhibit.exclusive,"Terminal WorkFocus has no OS chrome or exclusivity that blocks parent input")
	check(exhibit.position == Vector2i.ZERO and exhibit.size == pages.resolution,"Saved-work review fits the terminal page, not an offscreen native window")
	check(exhibit.get("work") == fixture and exhibit.get("canvas").output == fixture.output,"Viewer presents the exact saved output and provenance")
	check(exhibit.get("evidence").is_empty() and exhibit.get("fork_button").disabled,"Journal viewer supplies neither invented replay evidence nor editable fork")
	check(FileAccess.get_file_as_string(profile_path) == profile_bytes,"Opening the terminal viewer never rewrites the saved work")
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == game_signature,"Saved-work viewing grants no Game completion or component reward")
	exhibit.get("close_button").pressed.emit()
	await settle()
	stage("viewer-closed")
	check(not is_instance_valid(journal.work_focus) and journal.visible,"Closing the actual viewer returns to the same Journal")
	check(pages.viewport.gui_get_focus_owner() == journal.work_view_button,"Closing restores the actual terminal Journal action focus")
	check(FileAccess.get_file_as_string(profile_path) == profile_bytes,"Closing the viewer preserves the original saved bytes")
	finish()
