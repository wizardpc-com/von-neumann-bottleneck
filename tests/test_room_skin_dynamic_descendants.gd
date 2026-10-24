extends SceneTree
## Room-origin styling must not recursively decorate its own generated rules.
## The synchronous guard stops the production node_added listener before an
## unbounded call_deferred chain can monopolize the same idle cycle.
const PageSkin = preload("res://src/lab/room_page_skin.gd")
const Session = preload("res://experiments/creation/session.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const RULE_LIMIT: int = 40
const ORIGINAL_INK := Color("6ce2de")
const ORIGINAL_GROUND := Color("0b1722")
var checks: int = 0
var failures: Array[String] = []
var hub: Control
var lab: Control
var page: Control
var phase: String = ""
var added_nodes: int = 0
var added_rules: int = 0
var max_rule_depth: int = 0
var guard_tripped: bool = false
var work: Dictionary = {}
var saved_bytes: String = ""
var profile_path: String = ""

func _init() -> void: call_deferred("run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)

func settle() -> void:
	for frame: int in 6: await process_frame

func rule_count() -> int:
	var total: int = 0
	for node: Node in page.find_children("*","Control",true,false):
		if node.name == PageSkin.RULE_NAME: total += 1
	return total

func report_stage(label: String) -> void:
	print("ROOM_SKIN_STAGE ",JSON.stringify({"phase":phase,"stage":label,
		"added_nodes":added_nodes,"added_rules":added_rules,"max_rule_depth":max_rule_depth,
		"guard_tripped":guard_tripped,"rules_now":rule_count()}))

func observe_added(node: Node) -> void:
	if not is_instance_valid(page) or not page.is_ancestor_of(node): return
	added_nodes += 1
	if node.name != PageSkin.RULE_NAME: return
	added_rules += 1
	var depth: int = 0
	var ancestor: Node = node
	while ancestor != null and ancestor != page:
		depth += 1
		ancestor = ancestor.get_parent()
	max_rule_depth = maxi(max_rule_depth,depth)
	if added_rules < RULE_LIMIT or guard_tripped: return
	guard_tripped = true
	var listener := Callable(lab,"_on_node_added")
	if node_added.is_connected(listener): node_added.disconnect(listener)
	# Earlier finite callbacks may still finish, but cannot enqueue descendants
	# through the disconnected listener. A tripped guard is always a failure.
	check(false,phase+": production skin listener generated 40 rules; synchronous guard stopped recursive scheduling")
	report_stage("guard-disconnected-listener")

func begin_phase(label: String) -> void:
	phase = label; added_nodes = 0; added_rules = 0; max_rule_depth = 0; guard_tripped = false
	page.open()
	# This is the actual room-object path missing from root-only Journal tests.
	var before: Array[Control] = []
	lab._dress_pages("works",before)
	report_stage("room-page-dressed")

func make_probe() -> Dictionary:
	var panel := PanelContainer.new(); panel.name = "LateStyleProbe"
	var style := StyleBoxFlat.new(); style.bg_color = ORIGINAL_GROUND
	style.set_border_width_all(3); style.border_color = ORIGINAL_INK
	panel.add_theme_stylebox_override("panel",style)
	var label := Label.new(); label.name = "LateStyleLabel"; label.text = "Late content"
	label.add_theme_color_override("font_color",ORIGINAL_INK)
	panel.add_child(label)
	return {"panel":panel,"label":label,"style":style}

func check_restored(probe: Dictionary, context: String) -> void:
	check(probe.label.get_theme_color("font_color").is_equal_approx(ORIGINAL_INK),context+": original explicit text color is restored")
	check(probe.panel.get_theme_stylebox("panel") == probe.style and probe.style.bg_color.is_equal_approx(ORIGINAL_GROUND),context+": original StyleBox resource and color are preserved")
	check(not probe.panel.has_meta(PageSkin.META) and not probe.label.has_meta(PageSkin.META),context+": no stale skin restore metadata remains")

func prepare_work() -> bool:
	profile_path = Session.launch_path()
	check(Files.transaction_paths(profile_path).is_empty(),"Saved-work fixture refuses any pre-existing creation profile or transaction")
	if not Files.transaction_paths(profile_path).is_empty(): return false
	var writer = Session.new()
	var opened: Dictionary = writer.open(profile_path)
	if not opened.get("writable",false): check(false,"Fixture writer is writable"); writer.close(); return false
	writer.data.draft.length = 16
	var trained: Dictionary = writer.train()
	var restored: Dictionary = writer.transport([0,1,0,2],"predictive") if trained.get("ok",false) else {}
	var mode: Dictionary = writer.set_mode("predict") if restored.get("ok",false) else {}
	var started: Dictionary = writer.begin_prediction("practice") if mode.get("ok",false) else {}
	if not started.get("ok",false): check(false,"Fixture reaches a real prediction practice"); writer.close(); return false
	for step: int in 32:
		if writer.prediction.finished: break
		var committed: Dictionary = writer.commit_prediction()
		var revealed: Dictionary = writer.reveal_prediction() if committed.get("ok",false) else {}
		if not revealed.get("ok",false): break
	mode = writer.set_mode("generate") if writer.prediction.finished else {}
	var generated: Dictionary = writer.generate() if mode.get("ok",false) else {}
	var kept: Dictionary = writer.save_work("Dynamic room snapshot") if generated.get("ok",false) else {}
	check(kept.get("ok",false),"Actual learn/restore/predict/generate/keep creates the saved-work fixture")
	if kept.get("ok",false): work = kept.work.duplicate(true)
	writer.close()
	if work.is_empty(): return false
	var decoded: Dictionary = Files.read_session(profile_path,Session.decode)
	check(decoded.get("ok",false) and decoded.get("data",{}).get("works",[]) == [work] and work.output.size() == 16,"Production decoder validates the one bounded saved work")
	saved_bytes = FileAccess.get_file_as_string(profile_path)
	return decoded.get("ok",false)

func finish() -> void:
	if is_instance_valid(lab): lab._clear_skins()
	if node_added.is_connected(observe_added): node_added.disconnect(observe_added)
	print(("PASS: " if failures.is_empty() else "FAIL: ")+"room skin dynamic descendants %d checks, %d failures" % [checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = root.size
	ProjectSettings.set_setting("game/reduced_motion",true)
	ProjectSettings.set_setting("playtest/offline_tester",false)
	ProjectSettings.set_setting("candidate/creation_enabled",true)
	var earned_before: String = root.get_node("GlobalSave").game_player_content.canonical_signature()
	if not prepare_work(): finish(); return
	hub = load("res://src/ui/prototype_hub.tscn").instantiate()
	root.add_child(hub); current_scene = hub
	await settle()
	lab = hub.laboratory
	check(is_instance_valid(lab) and lab.terminal_pages != null,"Actual laboratory supplies the terminal page host")
	if not is_instance_valid(lab) or lab.terminal_pages == null: finish(); return
	hub._open_journey_journal(); await settle()
	page = hub.journey_journal
	check(page.get_viewport() == lab.terminal_pages.viewport,"Actual Journal is mounted inside the laboratory terminal")
	# Connect before _dress_pages installs the production listener so a limit
	# disconnects it synchronously, not in the already-starved deferred queue.
	node_added.connect(observe_added)
	begin_phase("late-control")
	var probe: Dictionary = make_probe()
	page.add_child(probe.panel)
	await settle()
	report_stage("late-control-settled")
	check(not guard_tripped,"Adding one late subtree never trips the recursive-rule guard")
	check(rule_count() == 1 and page.get_node_or_null(PageSkin.RULE_NAME) != null,"Only the page root owns one accent rule after dynamic content arrives")
	check(probe.label.get_theme_color("font_color").is_equal_approx(PageSkin.role_color(ORIGINAL_INK,PageSkin.skin("works"),true)),"Late text receives the room's role-based color")
	check(probe.panel.get_theme_stylebox("panel") != probe.style and probe.style.bg_color.is_equal_approx(ORIGINAL_GROUND),"Late panel receives a copied skin without mutating its original StyleBox")
	lab._clear_skins(); await settle()
	check_restored(probe,"Normal clear")
	check(rule_count() == 0,"Clear removes all generated decoration, not just a top rule above hidden recursive descendants")
	probe.panel.queue_free(); await settle()

	begin_phase("saved-work-window")
	page.work_view_button.pressed.emit()
	await settle()
	report_stage("work-window-settled")
	check(not guard_tripped,"Actual WorkFocus construction under a room-dressed Journal has bounded decoration")
	check(rule_count() == 1,"WorkFocus descendants never acquire per-control or recursive accent rules")
	var exhibit: Window = page.work_focus
	check(is_instance_valid(exhibit) and exhibit.visible and exhibit.is_embedded(),"Actual saved-work window opens and frames continue after room-origin styling")
	if is_instance_valid(exhibit):
		check(exhibit.get("work") == work and exhibit.get("canvas").output == work.output,"Room styling leaves the saved snapshot unchanged")
		var cross_window_overrides: int = 0
		for control: Node in exhibit.find_children("*", "Control", true, false):
			if control.has_meta(PageSkin.META): cross_window_overrides += 1
		check(cross_window_overrides == 0,"Independent saved-work Window retains its own complete theme rather than dark ground with room-colored text")
		PageSkin.apply(page,"works")
		cross_window_overrides = 0
		for control: Node in exhibit.find_children("*", "Control", true, false):
			if control.has_meta(PageSkin.META): cross_window_overrides += 1
		check(cross_window_overrides == 0,"Repeated page styling never crosses an already-open child Window")
		exhibit.get("close_button").pressed.emit(); await settle()
	check(not is_instance_valid(page.work_focus) and page.visible,"Closing the viewer preserves its room-dressed Journal")
	lab._clear_skins(); await settle()
	check(rule_count() == 0,"Closing and clearing the room view removes its last accent rule")

	begin_phase("close-before-deferred-style")
	probe = make_probe()
	page.add_child(probe.panel)
	# A real close leaves the mounted page alive; pending node-added callbacks
	# must not recolor it after the room adapter has reverted its presentation.
	page.close(); lab._clear_skins()
	await settle()
	report_stage("closed-page-deferred-queue-drained")
	check(not guard_tripped and rule_count() == 0,"Queued style work cannot recreate decoration after close/revert")
	check_restored(probe,"Close before deferred callback")
	probe.panel.queue_free(); await settle()
	check(FileAccess.get_file_as_string(profile_path) == saved_bytes,"All room styling and viewer operations preserve saved profile bytes")
	check(root.get_node("GlobalSave").game_player_content.canonical_signature() == earned_before,"Presentation-only room styling grants no Game completion or components")
	finish()
