extends SceneTree
## Real Session/Host operations in isolated candidate data; rendered input is controller QA.
const Fragment = preload("res://experiments/creation/cpg_connection_fragment.gd")
const Session = preload("res://experiments/creation/session.gd")
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")
var failures: Array[String] = []
var checks: int = 0
var capture: bool = false
var frames: Array[Dictionary] = []

func _init() -> void: call_deferred("run")

func check(value: bool,message: String) -> void:
	checks += 1
	if not value:
		failures.append(message)
		push_error(message)

func settle() -> void:
	for frame: int in 8: await process_frame

func key(code: Key,down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = down
	Input.parse_input_event(event)

func stroke(code: Key) -> void:
	key(code,true); await settle(); key(code,false); await settle()

func activate(action: BaseButton) -> void:
	check(action.is_visible_in_tree() and not action.disabled,"Original action is available: "+str(action.name))
	var ancestor: Node = action.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(action)
		ancestor = ancestor.get_parent()
	await settle()
	check(fully_visible(action),"Actual action fits every ancestor clip: "+str(action.name))
	action.grab_focus()
	if DisplayServer.get_name()=="headless":
		if action.toggle_mode:
			action.button_pressed = not action.button_pressed
		action.pressed.emit()
	else:
		await stroke(KEY_SPACE)
	await settle()

func fully_visible(control: Control) -> bool:
	if not control.is_visible_in_tree(): return false
	var visible_rect: Rect2 = control.get_viewport().get_visible_rect()
	var ancestor: Node = control.get_parent()
	while ancestor != null:
		if ancestor is Control and ancestor.clip_contents: visible_rect = visible_rect.intersection(ancestor.get_global_rect())
		ancestor = ancestor.get_parent()
	return control.size.x>0 and control.size.y>0 and visible_rect.grow(1).encloses(control.get_global_rect())

func profile_files(path: String) -> Dictionary:
	var result: Dictionary = {}
	var directory := DirAccess.open(path)
	if directory == null: return result
	for name: String in directory.get_files(): result[name] = FileAccess.get_sha256(path.path_join(name))
	for name: String in directory.get_directories():
		result[name+"/"] = "directory"
		var children: Dictionary = profile_files(path.path_join(name))
		for child: String in children: result[name+"/"+child] = children[child]
	return result

func authority(host: Control) -> Dictionary:
	var game: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	game.erase("saved_at_utc")
	var nav: Node = root.get_node("TaskNavigation")
	var disk: Dictionary = {}
	for path: String in ["user://savegame_v1.json","user://savegame_v1.json.bak","user://hardware_workbenches_v1.json","user://personal_task_records_v1.json","user://task_navigation.cfg"]:
		disk[path] = FileAccess.get_sha256(path) if FileAccess.file_exists(path) else "absent"
	return {"data":host.session.data.duplicate(true),"dirty":host.session.dirty,
		"transport":host.session.last_transport.duplicate(true),"prediction":host.session.prediction.duplicate(true),
		"generated":host.session.generated.duplicate(true),"undo":host.session.undo_stack.duplicate(true),"redo":host.session.redo_stack.duplicate(true),
		"profile":profile_files(host.session.path.get_base_dir()),"lease":host.session.lease.owns(host.session.path),
		"recovery":DirAccess.dir_exists_absolute(Lease.lock_path(host.session.path)+".recovering"),"game":game,"disk":disk,
		"best":root.get_node("PersonalRecords").best.duplicate(true),
		"nav":{"selected":nav.selected,"pending":nav.pending,"from_tree":nav.from_tree,"last_visited_task":nav.last_visited_task}}

func frame(name: String) -> void:
	if not capture: return
	await RenderingServer.frame_post_draw
	var path: String = "user://cpg-connection-captures/"+name+".png"
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	check(not FileAccess.file_exists(path),"Capture names never overwrite earlier locale/size evidence: "+name)
	if FileAccess.file_exists(path): return
	var image: Image = root.get_texture().get_image()
	check(not image.is_empty() and image.save_png(path)==OK,"Actual CPG frame writes: "+name)
	frames.append({"file":path,"sha256":FileAccess.get_sha256(path),"dimensions":[image.get_width(),image.get_height()]})

func prepare(host: Control,locale: String) -> bool:
	check(host.writable,"Real isolated candidate writer is available")
	if not host.writable: return false
	host.change_task(0); host.train_model(); host.transport("predictive")
	check(host.connection_records.has("transport") and host.session.last_transport.lossless,"Original transport supplies the real detached C observation")
	host.switch_mode("predict"); host.begin_prediction("practice")
	var initial: Dictionary = host.connection_records.prediction
	check(initial.prefix.size()==2 and initial.rows.is_empty() and initial.pending.is_empty(),"Only the original public prefix exists before any commitment")
	check(not initial.has("truth") and not initial.has("_future") and not initial.has("_sequence"),"The fragment never receives a future sequence")
	var draft_at_start: Dictionary = initial.draft.duplicate(true)
	host.session.data.draft.seed += 1; host.edit_draft()
	host.commit_prediction()
	var committed: Dictionary = host.connection_records.prediction.duplicate(true)
	check(committed.rows.is_empty() and committed.prefix==initial.prefix and committed.pending.keys()==["symbol"],"Commit supplies only the submitted symbol; no sealed truth or future row")
	check(committed.draft==draft_at_start and committed.draft!=host.session.data.draft,"A later commit/reveal keeps its original round's draft binding despite edits")
	host.connection_fragment.select_step(1)
	check(host.connection_fragment.summary_label.text.contains("未揭晓" if not host.english else "sealed"),"The committed cell remains explicitly sealed in the candidate copy")
	host.reveal_prediction()
	var revealed: Dictionary = host.connection_records.prediction
	check(revealed.rows.size()==1 and revealed.prefix.size()==3 and revealed.pending.is_empty(),"The actual reveal adds exactly one truth and clears its submitted guess")
	check(revealed.rows[0]==host.session.prediction.rows[0] and committed.rows.is_empty(),"Earlier detached commitment is not rewritten by a later reveal")
	host.continue_prediction()
	check(host.session.prediction.finished and host.connection_records.prediction.rows==host.session.prediction.rows,"The original commit/reveal loop supplies every actually revealed row")
	var prediction: Dictionary = host.connection_records.prediction.duplicate(true)
	host.switch_mode("generate"); host.generate_work()
	check(host.connection_records.has("transport") and host.connection_records.prediction==prediction and host.connection_records.has("generation"),"Mode switches retain independent observations without reconstructing them from permissions")
	host.name_input.text = "连接作品 · Connection "+locale
	host.keep_work(); await settle()
	check(not host.kept_work.is_empty() and host.connection_records.work==host.kept_work,"Saved stage binds only a successful original save transaction")
	check(host.connection_records.generation.recipe==host.kept_work.recipe and host.connection_records.generation.output==host.kept_work.output,"The new work retains this actual generated recipe and output")
	print("SETUP: real candidate Host train / predictive transport / commit-reveal / generation / Keep; not unaided player input")
	return not host.kept_work.is_empty()

func public_boundaries(host: Control) -> void:
	var original: Dictionary = host.connection_records.duplicate(true)
	var fragment: Variant = host.connection_fragment
	fragment.records.transport.input[0] = (int(fragment.records.transport.input[0])+1)%4
	check(host.connection_records==original,"Changing the component's detached copy cannot rewrite Host observations or Session receipts")
	host.refresh()
	var old_work: Dictionary = host.kept_work.duplicate(true)
	var isolated := Fragment.new()
	root.add_child(isolated); await settle()
	isolated.configure({"work":old_work},host.session.data.draft,{},true)
	isolated.select_step(1)
	check(isolated.records.keys()==["work"] and isolated.summary_label.text.contains("No observation"),"An original work and recipe do not fabricate C/P observations")
	var future: Dictionary = old_work.duplicate(true)
	future.recipe = {"version":99,"model":"unknown future recipe"}
	isolated.configure({"work":future},host.session.data.draft,{},true); isolated.select_step(3)
	check(isolated.records.work.output==old_work.output and isolated.summary_label.text.contains("Protected output"),"Unknown recipe metadata remains a protected saved output without inferred runs")
	check(not Session.decode(JSON.stringify({"version":99})).get("ok",false),"The unchanged original decoder rejects an unknown Session version")
	var altered: Dictionary = original.duplicate(true)
	altered.prediction.model_id = "fixture-different-recorded-model"
	altered.prediction.machine.memory_bytes += 1
	isolated.configure(altered,host.session.data.draft,{},true); isolated.select_step(1)
	check(isolated.identity_label.text.contains("different rules") and isolated.identity_label.text.contains("different machines"),"Different recorded identities are never described as one common run")
	check(isolated.locate_button.disabled,"An older independent observation cannot replace the current original evidence")
	var protected_before_destroy: Dictionary = authority(host)
	isolated.toggle_button.grab_focus()
	isolated.toggle_button.button_pressed = true
	check(process_frame.is_connected(isolated._reveal_reading_region),"Expanding attaches the original single delayed reading callback")
	isolated.queue_free()
	isolated._reveal_reading_region()
	await settle()
	check(not is_instance_valid(isolated) and authority(host)==protected_before_destroy,"Destroying a fragment with a pending reveal callback does not run or rewrite anything")
	for kind: String in ["training","memorize","check","check-v2"]:
		host.switch_mode("predict"); host.begin_prediction(kind); host.commit_prediction(); host.reveal_prediction()
		var state: Dictionary = host.connection_records.prediction
		check(state.kind==kind and state.rows.size()==1 and state.rows==host.session.prediction.rows,"Only actual public rows are copied for "+kind)
		host.connection_fragment.select_step(1)
		if kind in ["training","memorize"]:
			check(host.connection_fragment.detail_label.text.contains("不是未见" if not host.english else "not unseen"),"Seen/memory material is not advertised as unseen performance")
		if kind in ["check","check-v2"]:
			host.begin_prediction(kind)
			check(host.connection_records.prediction.seen and host.connection_records.prediction.rows.is_empty(),"Repeated frozen checks preserve seen status without resurrecting old rows")
	# Return through real operations to a complete fresh chain for the visual matrix.
	host.begin_prediction("practice"); host.commit_prediction(); host.reveal_prediction(); host.continue_prediction()
	host.switch_mode("generate"); host.generate_work(); host.name_input.text = "回顾作品 · Review"
	host.keep_work(); await settle()

func matrix(host: Control,locale: String) -> void:
	for dimensions: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080),Vector2i(1600,1000)]:
		root.mode = Window.MODE_WINDOWED; root.size = dimensions; root.content_scale_size = dimensions
		await settle()
		host.causal_tabs.current_tab = 0; host.set_evidence_expanded(false)
		var fragment: Variant = host.connection_fragment
		fragment.collapse()
		var scroll: ScrollContainer = fragment.get_parent().get_parent()
		scroll.scroll_vertical = 0; await settle()
		var before: Dictionary = authority(host)
		var suffix: String = locale+"-"+str(dimensions.x)+"x"+str(dimensions.y)
		check(fully_visible(fragment.toggle_button),"Optional entry is reachable beside original evidence: "+suffix)
		await frame(suffix+"-collapsed")
		await activate(fragment.toggle_button)
		for index: int in 4:
			await activate(fragment.step_buttons[index])
			if DisplayServer.get_name()=="headless":
				# Headless has no focused system Window; only real renderer grades automatic reveal.
				scroll.ensure_control_visible(fragment.summary_label); await settle()
			check(fragment.body.visible and fragment.step==index,"Manual original step selection: "+suffix+" / "+str(index))
			check(fully_visible(fragment.scope_label) and fully_visible(fragment.identity_label) and fully_visible(fragment.summary_label),("Original scroll reaches" if DisplayServer.get_name()=="headless" else "Actual automatic opening retains")+" scope, identity and summary inside ancestor clips: "+suffix+" / "+str(index))
			await frame(suffix+"-step"+str(index))
		check(authority(host)==before,"Pure fold / manual steps preserve Session, original works, disk, locks, game and navigation: "+suffix)
		await activate(fragment.locate_button)
		check(host.causal_tabs.current_tab==3 and host.session.data.works[host.selected_work()].id==fragment.records.work.id and not is_instance_valid(host.work_focus),"Saved location selects the actual original work without opening View or replay")
		check(authority(host)==before,"Saved location changes only the original evidence tab/list selection")
		host.causal_tabs.current_tab = 0
		fragment.select_step(2)
		check(not fragment.locate_button.disabled,"Current actual G evidence can still be located")
		await activate(fragment.locate_button)
		check(host.causal_tabs.current_tab==0 and authority(host)==before,"Original G ledger location has no model, save or progression effect")
		fragment.select_step(0)
		check(fragment.locate_button.disabled,"Original C snapshot cannot overwrite the currently displayed G run")
		fragment.reduced_motion = true; fragment.media = null; fragment.select_step(2); await settle()
		scroll.ensure_control_visible(fragment.image); await settle()
		check(fully_visible(fragment.image),"Deep optional media remains reachable through the original scroll")
		await frame(suffix+"-static-no-media")
		var old_image: Image
		if capture:
			await RenderingServer.frame_post_draw
			old_image = root.get_texture().get_image().get_region(Rect2i(fragment.image.get_global_rect()))
		fragment.media = ImageTexture.new(); await settle()
		check(fragment.media.get_width()==0 and fragment.records.generation.output==host.session.generated.output,"An empty Texture keeps the exact textual/actual result fallback")
		if capture:
			await RenderingServer.frame_post_draw
			var empty_image: Image = root.get_texture().get_image().get_region(Rect2i(fragment.image.get_global_rect()))
			check(old_image.get_data()==empty_image.get_data(),"Null and zero-size Texture produce identical static fallback pixels")
		fragment.media = null; fragment.reduced_motion = false
		var native := Image.create(8,8,false,Image.FORMAT_RGBA8)
		native.fill(Color("50d5ff"))
		fragment.media = ImageTexture.create_from_image(native); await settle()
		check(fragment.image.media==fragment.media and fragment.media.get_width()==8,"A replaceable valid Texture uses the same static media slot")
		fragment.media = null
		check(authority(host)==before,"Media and reduced-motion presentation never change original authority")

func feedback(host: Control,tester: bool) -> void:
	if DisplayServer.get_name()=="headless":
		print("NOT_RUN: real CPG F8, focus and ancestor Window input require renderer")
		return
	var offline: Node = root.get_node("OfflineFeedback")
	var moments: Node = root.get_node("PlaytestMoments")
	ProjectSettings.set_setting("playtest/offline_tester",tester)
	offline.toolbar.visible = tester
	host.causal_tabs.current_tab = 0; host.set_evidence_expanded(true)
	var fragment: Variant = host.connection_fragment
	fragment.collapse(); await settle(); await activate(fragment.toggle_button)
	fragment.step_buttons[1].grab_focus(); await stroke(KEY_SPACE)
	var before: Dictionary = authority(host)
	var scroll: ScrollContainer = fragment.get_parent().get_parent()
	var previous_scroll: int = scroll.scroll_vertical
	var previous_step: int = fragment.step
	var previous_pause: bool = paused
	key(KEY_F8,true); await process_frame; await RenderingServer.frame_pre_draw
	check(fragment.feedback_active(),"Real accepted F8 has priority over manual CPG actions")
	if tester: check(offline.busy and not root.get_node("PlaytestData")._feedback_visible,"Tester CPG guard is exercised at actual pre-overlay capture-busy boundary")
	fragment.select_step(2)
	check(fragment.step==previous_step and scroll.scroll_vertical==previous_scroll,"Busy capture cannot advance or scroll the independent observations")
	key(KEY_F8,false); await settle()
	var panel: Control = offline.panel if tester else moments.panel
	check((offline.backdrop.visible if tester else moments.panel.visible) and panel.is_visible_in_tree() and panel.get_viewport()==root and panel.is_ancestor_of(root.gui_get_focus_owner()),"Actual role feedback owns the original viewport and focus")
	check(paused if tester else paused==previous_pause,"Original role feedback pause semantics remain")
	await frame(("en" if host.english else "zh_CN")+"-"+("tester" if tester else "ordinary")+"-feedback")
	await stroke(KEY_ESCAPE)
	check(not panel.is_visible_in_tree() and fragment.body.visible and root.gui_get_focus_owner()==fragment.step_buttons[1] and paused==previous_pause,"First Escape closes feedback only and returns the exact original step focus")
	check(authority(host)==before,"Both feedback channels preserve the whole original Session/game/works/navigation authority")
	await stroke(KEY_ESCAPE)
	check(not fragment.body.visible and root.gui_get_focus_owner()==fragment.toggle_button,"Second genuine-focus Escape collapses only the optional CPG fragment")
	await activate(fragment.toggle_button)
	host.train_button.grab_focus(); await stroke(KEY_ESCAPE)
	check(fragment.body.visible,"Escape outside the fragment does not steal the original Host input")
	fragment.collapse(); await settle()
	fragment.toggle_button.grab_focus(); await settle()
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value); await settle()
	var pending_scroll: int = scroll.scroll_vertical
	fragment.toggle_button.button_pressed = true
	check(process_frame.is_connected(fragment._reveal_reading_region),"Actual toggle schedules one pending reading reveal before Window focus moves")
	var blocker := Window.new()
	blocker.title = "QA focus boundary"
	root.add_child(blocker)
	var other := Button.new(); other.text = "Other window"; blocker.add_child(other)
	blocker.popup_centered(Vector2i(240,100)); blocker.grab_focus(); other.grab_focus(); await settle()
	check(blocker.has_focus() and not root.has_focus(),"A real separate Window owns focus for the loss-of-focus boundary")
	check(scroll.scroll_vertical==pending_scroll,"Pending automatic reveal never scrolls the original reading region after same-frame Window focus leaves")
	var escape := InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = true
	fragment._unhandled_key_input(escape)
	check(fragment.body.visible and authority(host)==before,"An unfocused fragment cannot collapse or change authority")
	blocker.queue_free(); await settle()
	fragment.collapse()

func clear_boundaries(host: Control) -> void:
	var saved: Array = host.session.data.works.duplicate(true)
	var seen: Array = host.session.data.seen_checks.duplicate()
	var supports: Dictionary = host.session.data.supports.duplicate(true)
	host.session.data.draft.seed += 1; host.edit_draft()
	check(not host.connection_records.is_empty(),"Draft editing preserves detached original observations instead of rewriting their numbers")
	host.connection_fragment.select_step(2)
	check(host.connection_fragment.summary_label.text.contains("草稿已不同" if not host.english else "draft differs"),"Changed draft is explicitly different from the original G record")
	host.restore_draft_history(false); await settle()
	check(host.connection_records.is_empty() and host.connection_fragment.records.is_empty(),"Real Undo clears all active C/P/G/saved-stage presentation bindings")
	host.restore_draft_history(true); await settle()
	check(host.connection_records.is_empty() and host.session.data.works==saved and host.session.data.seen_checks==seen and host.session.data.supports==supports,"Real Redo cannot resurrect observations, undo seen answers or rewrite protected works")
	host.works.select(0); host.fork_work(); await settle()
	check(host.connection_records.is_empty() and host.session.data.works==saved,"Actual fork begins a clean observation view and preserves old works")
	host.train_model(); await settle()
	check(host.connection_records.is_empty(),"Explicit new learning leaves no old C/P/G fragment")
	host.transport("predictive")
	check(host.connection_records.has("transport"),"A real new run after clearing creates a new independent observation")
	host.save_draft(); host.retry_writer(true); await settle()
	check(host.connection_records.is_empty() and host.session.data.works==saved,"Actual saved-profile reload clears replaced exploration without losing works")

func run() -> void:
	capture = DisplayServer.get_name()!="headless" and "--cpg-connection-capture" in OS.get_cmdline_user_args()
	var nav: Node = root.get_node("TaskNavigation")
	var locale: Node = root.get_node("Localization")
	var offline: Node = root.get_node("OfflineFeedback")
	var original_tester: Variant = ProjectSettings.get_setting("playtest/offline_tester",false)
	var original_toolbar: bool = offline.toolbar.visible
	var original_motion: Variant = ProjectSettings.get_setting("game/reduced_motion",false)
	var packed: PackedScene = load("res://experiments/creation/workbench.tscn")
	for language: String in ["zh_CN","en"]:
		locale.set_locale(language)
		ProjectSettings.set_setting("playtest/offline_tester",false); offline.toolbar.hide()
		nav.pending = ""; nav.from_tree = false
		var host: Control = packed.instantiate()
		root.add_child(host); await settle()
		if not await prepare(host,language): host.queue_free(); await settle(); break
		await public_boundaries(host)
		await matrix(host,language)
		root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720); await settle()
		await feedback(host,false); await feedback(host,true)
		ProjectSettings.set_setting("playtest/offline_tester",false); offline.toolbar.hide()
		await clear_boundaries(host)
		host.queue_free(); await settle()
		check(not DirAccess.dir_exists_absolute(Lease.lock_path(Session.launch_path())),"Real Host close releases only its own isolated writer")
	ProjectSettings.set_setting("playtest/offline_tester",original_tester); offline.toolbar.visible = original_toolbar
	ProjectSettings.set_setting("game/reduced_motion",original_motion)
	if capture:
		var receipt_path: String = "user://cpg-connection-captures/receipt.json"
		var file := FileAccess.open(receipt_path,FileAccess.WRITE)
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":frames,"scope":"real isolated candidate Host operations and rendered controller input; no native or unaided play claim"},"\t")); file.close()
	print("PASS: CPG connection fragment %d checks"%checks if failures.is_empty() else "FAIL: CPG connection fragment "+str(failures))
	quit(0 if failures.is_empty() else 1)
