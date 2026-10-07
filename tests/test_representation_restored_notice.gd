extends SceneTree
## Isolated saved recipes exercise notices; authored solutions are not player evidence.
const Store = preload("res://experiments/representation_region/session_store.gd")
const Model = preload("res://experiments/representation_region/model.gd")
var checks: int = 0
var failures: int = 0
func _init() -> void: call_deferred("run")
func check(ok: bool,message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
func write_raw(path: String,raw: String) -> void:
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file != null,"Isolated fixture can be written")
	if file != null: file.store_string(raw); file.close()
func settle() -> void:
	for frame: int in 3: await process_frame
func enter(nav: Node,index: int):
	nav.pending = nav.candidate_key("representation",index); nav.from_tree = true
	var scene = load("res://experiments/representation_region/region.tscn").instantiate()
	scene.persistent_session = true; scene.candidate_journey = true
	root.add_child(scene)
	return scene
func same_notice(scene,context: String) -> void:
	var notice: String = scene.session_notice
	var dirty: bool = scene.session_dirty
	var blocked: bool = scene.save_blocked
	var plan: Array = scene.plan.duplicate(true)
	scene.change_task(scene.task)
	check(scene.session_notice == notice and scene.status.text == notice,context+": same task keeps the real notice")
	check(scene.session_dirty == dirty and scene.save_blocked == blocked and scene.plan == plan,context+": same task preserves dirty state, save authority and draft")
func run() -> void:
	root.size = Vector2i(1280,720); root.content_scale_size = Vector2i(1280,720)
	var localization: Node = root.get_node("Localization")
	var old_locale: String = localization.current_locale()
	var nav: Node = root.get_node("TaskNavigation")
	var old_pending: String = nav.pending; var old_selected: String = nav.selected
	var old_from_tree: bool = nav.from_tree; var old_recent: String = nav.last_visited_task
	var campaign: Node = root.get_node("GlobalSave")
	var before: Dictionary = campaign._save_snapshot(); before.erase("saved_at_utc")
	var old_path: String = Store.PATH
	var base: String = "user://representation-notice-"+Crypto.new().generate_random_bytes(8).hex_encode()
	check(DirAccess.make_dir_recursive_absolute(base) == OK,"Independent fixture directory exists")
	var drafts: Array = []
	for index: int in 5: drafts.append(Model.initial_plan())
	var raw: String = Store.encode(2,drafts,[])
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		Store.PATH = base.path_join(locale+"-saved.json"); write_raw(Store.PATH,raw)
		var scene = enter(nav,2); await settle()
		check(scene.task == 2 and nav.pending.is_empty() and not scene.session_dirty,"Saved target is restored and consumed without becoming dirty")
		check(FileAccess.get_file_as_string(Store.PATH) == raw,"Same-target reentry never rewrites the saved profile")
		check(scene.session_notice.contains("已恢复") if locale == "zh_CN" else scene.session_notice.contains("Drafts restored"),"Same saved target reports actual restore, not an unsaved selection")
		same_notice(scene,"Restored saved target")
		scene.change_task(3)
		check(scene.session_dirty and scene.session_notice.contains("未保存" if locale == "zh_CN" else "unsaved"),"A genuinely different task selection still requires Save")
		same_notice(scene,"Real dirty selection")
		scene.save_session()
		check(not scene.session_dirty and Store.read_session().task == 3,"Explicit Save persists the changed task")
		same_notice(scene,"Saved selection")
		scene.edit_plan(Model.split(scene.plan,0,17))
		var edited: Array = scene.plan.duplicate(true)
		scene.change_task(scene.task)
		check(scene.session_dirty and scene.plan == edited and scene.undo_stack.size() == 1,"Same task keeps actual draft edits and undo history dirty")
		# A real digest conflict supplies the existing save failure notice.
		write_raw(Store.PATH,Store.encode(1,drafts,[])); scene.save_session()
		check(scene.session_dirty and scene.session_notice.contains("保存失败" if locale == "zh_CN" else "Save failed"),"Real write conflict keeps the unsaved exploration and reports failure")
		same_notice(scene,"Failed Save")
		scene.queue_free(); await settle()
		Store.PATH = base.path_join(locale+"-writer.json"); write_raw(Store.PATH,raw)
		var owner = Store.Lease.new(Store.PATH)
		check(owner.held,"External fixture owner holds the candidate writer lease")
		scene = enter(nav,2); await settle()
		check(scene.save_blocked and scene.session_notice.contains("禁止保存" if locale == "zh_CN" else "saving is blocked"),"Same-target entry retains real writer protection")
		same_notice(scene,"Writer protection")
		scene.queue_free(); await settle(); owner.release()
		Store.PATH = base.path_join(locale+"-recovery.json"); write_raw(Store.PATH,raw)
		write_raw(Store.PATH+".tmp.interrupted",Store.encode(1,drafts,[]))
		scene = enter(nav,0); await settle()
		check(scene.save_blocked and not scene.recovery_state.is_empty(),"Interrupted snapshot retains the original recovery state")
		same_notice(scene,"Recovery protection")
		scene.queue_free(); await settle()
	Store.PATH = old_path
	# Reuse the existing five-task valid fixtures only to verify the actual button caption.
	for locale: String in ["zh_CN","en"]:
		localization.set_locale(locale)
		for journey: bool in [false,true]:
			var scene = load("res://experiments/representation_region/region.tscn").instantiate()
			scene.candidate_journey = journey; root.add_child(scene); await settle()
			var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
			for index: int in 5:
				scene.change_task(index); scene.edit_plan(plans[index]); scene.run_current()
			var review := scene.find_child("CompletedRegionReview",true,false) as Button
			check(review.visible and scene.status.text.contains(review.text),"All-complete feedback names the actual localized review action")
			check(not scene.status.text.contains("下方") and not scene.status.text.contains("below"),"Completion guidance has no obsolete layout direction")
			scene.queue_free(); await settle()
	localization.set_locale(old_locale)
	nav.pending = old_pending; nav.selected = old_selected; nav.from_tree = old_from_tree; nav.last_visited_task = old_recent
	var after: Dictionary = campaign._save_snapshot(); after.erase("saved_at_utc")
	check(before == after,"Representation notices and review wording grant no campaign progress")
	print("PASS: test_representation_restored_notice " if failures == 0 else "FAIL: test_representation_restored_notice ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
func partition(ends: Array,codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []; var start: int = 0
	for index: int in ends.size():
		result.append({"start":start,"end":int(ends[index]),"codec":str(codecs[index])}); start = int(ends[index])
	return result
