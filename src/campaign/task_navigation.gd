extends Node
## Transient navigation only. Completion remains owned by the existing chapter states.
const SCENES := {"hardware_foundations": "res://src/hardware_foundations/hardware_foundations.tscn",
	"chapter_1": "res://src/system_lab/system_lab.tscn", "chapter_2": "res://src/ui/main.tscn",
	"chapter_3": "res://src/overlap_chapter/overlap_chapter.tscn", "chapter_4":"res://src/layout_chapter/layout_chapter.tscn"}
const SecondAct = preload("res://src/campaign/second_act_tasks.gd")
const MAP_SCENE := "res://src/campaign/task_tree.tscn"
var pending: String = ""
var selected: String = "hardware_foundations/tutorial"
var from_tree: bool = false
var camera: Vector2 = Vector2.ZERO
var camera_view_size: Vector2 = Vector2.ZERO
var zoom: float = 0.55
var camera_saved: bool = false

func tasks() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var hardware := preload("res://src/hardware_foundations/prologue_level_catalog.gd").new()
	var state: Dictionary = GlobalSave.game_player_content.completed_levels
	for id: StringName in hardware.level_ids():
		var deps: Array = hardware.dependencies(id)
		result.append(_task("hardware_foundations",String(id),0,Localization.text(hardware.title_key(id)),
			Localization.text(hardware.description_key(id)),deps,hardware.is_unlocked(id,state),bool(state.get(id,false)),
			String(hardware.level_branch_id(id)).ends_with("exploration")))
	var system := preload("res://src/system_lab/system_level_catalog.gd").new()
	for id: StringName in system.level_ids():
		result.append(_task("chapter_1",String(id),1,Localization.text(system.title_key(id)),
			Localization.text(system.description_key(id)),system.dependencies(id),
			system.is_unlocked(id,SystemChapter.completed_levels(),SystemChapter.prologue_ready),
			bool(SystemChapter.completed_levels().get(id,false)),id in [&"read_once",&"two_orders"]))
	var locality := preload("res://src/locality_chapter/locality_level_catalog.gd").new()
	for id: StringName in locality.level_ids():
		result.append(_task("chapter_2",String(id),2,Localization.text(locality.title_key(id)),
			Localization.text(locality.description_key(id)),locality.dependencies(id),
			locality.is_unlocked(id,LocalityChapter.completed_levels(),LocalityChapter.chapter_unlocked()),
			bool(LocalityChapter.completed_levels().get(id,false)),false))
	var overlap = preload("res://src/overlap_chapter/overlap_catalog.gd")
	for id: String in overlap.IDS:
		result.append(_task("chapter_3",id,3,Localization.text(StringName("overlap."+id+".title")),
			Localization.text(StringName("overlap."+id+".goal")),overlap.DEPS[id],
			overlap.unlocked(id,OverlapChapter.completed(),OverlapChapter.chapter_unlocked()),
			OverlapChapter.completed().has(id),false))
	var layout = preload("res://src/layout_chapter/layout_catalog.gd")
	for id: String in layout.IDS:
		result.append(_task("chapter_4",id,4,layout.title(id),layout.goal(id),layout.DEPS[id],
			layout.unlocked(id,LayoutChapter.completed(),LayoutChapter.chapter_unlocked()),LayoutChapter.completed().has(id),false))
	for task: Dictionary in result:
		if task.body.is_empty() and task.id in ["tutorial","half_adder"]:
			task.body = Localization.text(StringName("hardware.prologue.map.%s_description"%task.id))
		match task.key:
			"chapter_1/assembly": task.dependencies.append("hardware_foundations/load_store")
			"chapter_2/distant_reads": task.dependencies.append("chapter_1/bottleneck")
			"chapter_3/arrival": task.dependencies.append("chapter_2/capstone")
			"chapter_4/fields": task.dependencies.append("chapter_2/capstone")
	for task: Dictionary in result:
		task["region_title_key"]="tree.region."+str(task.region)
		task["record_metrics"]=["passed_cases"] if task.domain=="hardware_foundations" else ["cycles","cost"] if task.domain=="chapter_1" else ["cycles","ram_read_bytes","ram_write_bytes","peak_extra_bytes"] if task.domain=="chapter_4" else ["cycles"]
		task["bonus_goals"]=[]
		match task.key:
			"chapter_2/capstone": task.bonus_goals.append({"id":"economical","complete":not LocalityChapter.economical_design.is_empty()})
			"chapter_3/distance", "chapter_3/synthesis": task.bonus_goals.append({"id":task.id,"complete":OverlapChapter.bonus_status(task.id).complete})
			"chapter_4/mixed":
				for id: String in ["space","flow"]: task.bonus_goals.append({"id":id,"complete":LayoutChapter.game_bonuses.has(id)})
	return result

func _task(domain: String,id: String,region: int,title: String,body: String,deps: Array,available: bool,done: bool,optional: bool) -> Dictionary:
	var dependencies: Array[String] = []
	for dep: Variant in deps: dependencies.append(domain+"/"+String(dep))
	return {"key":domain+"/"+id,"id":id,"domain":domain,"region":region,"title":title,"body":body,
		"dependencies":dependencies,"unlocked":available or GameMode.is_test_mode(),"completed":done,"optional":optional}

func candidate_journey_enabled() -> bool: return SecondAct.enabled()

func journey_tasks() -> Array[Dictionary]:
	var result: Array[Dictionary] = tasks()
	if candidate_journey_enabled(): result.append_array(SecondAct.build(SecondAct.saved_review(),Localization.current_locale() == "en"))
	return result

func enter(key: String) -> bool:
	for task: Dictionary in journey_tasks():
		if task.key != key or not task.unlocked: continue
		var previous := {"selected":selected,"pending":pending,"from_tree":from_tree}
		selected = key; pending = key; from_tree = true
		var destination: String = SCENES.get(task.domain,SecondAct.SCENES.get(task.domain,""))
		if get_tree().change_scene_to_file(destination) != OK:
			selected = previous.selected; pending = previous.pending; from_tree = previous.from_tree
			return false
		PlaytestData.record_map_action(&"task_start",key)
		return true
	return false

func candidate_key(domain: String,index: int) -> String: return SecondAct.key_for(domain,index)

func enter_candidate(domain: String,index: int) -> bool:
	var key: String = SecondAct.key_for(domain,index)
	return not key.is_empty() and enter(key)

func consume(domain: String) -> StringName:
	if pending.get_slice("/",0) != domain: return &""
	var id := StringName(pending.get_slice("/",1))
	call_deferred("_clear_pending",pending)
	return id

func _clear_pending(expected: String) -> void:
	if pending == expected: pending = ""

func take_pending(domain: String) -> int:
	if pending.get_slice("/",0) != domain: return -1
	var index: int = SecondAct.index_for(pending)
	pending = ""
	return index

func return_to_tree() -> bool:
	if not from_tree or not pending.is_empty(): return false
	get_tree().call_deferred("change_scene_to_file",MAP_SCENE)
	return true

func open_tree() -> bool:
	prepare_continue()
	return get_tree().change_scene_to_file(MAP_SCENE) == OK

func _resume_target() -> Dictionary:
	var available: Array[Dictionary] = journey_tasks()
	for task: Dictionary in available:
		if task.key == last_visited_task and task.unlocked: return task
	if candidate_journey_enabled():
		var saved_target: String = SecondAct.saved_resume_target()
		for task: Dictionary in available:
			if task.key == saved_target and task.unlocked: return task
	for task: Dictionary in available:
		if task.unlocked and not task.completed: return task
	return available[0] if not available.is_empty() else {}

func _temporary_resume(task: Dictionary) -> bool:
	var domain: String = str(task.get("domain",""))
	return domain == "prediction" or (domain in ["representation","service"] and SecondAct.paths().is_empty())

func has_resume() -> bool:
	if _temporary_resume(_resume_target()): return false
	for task: Dictionary in journey_tasks():
		if task.key == last_visited_task and task.unlocked: return true
	if candidate_journey_enabled() and not SecondAct.saved_resume_target().is_empty(): return true
	return GlobalSave.has_resume_progress()

func resume_title() -> String: return str(_resume_target().get("title",""))
func next_task_title() -> String:
	var task: Dictionary = _resume_target()
	var title: String = str(task.get("title",""))
	if _temporary_resume(task): title += " · "+("临时探索，离开后不保留" if Localization.current_locale() != "en" else "temporary; not retained after leaving")
	return title

func home_action_text() -> String:
	var task: Dictionary = _resume_target()
	if _temporary_resume(task):
		if str(task.get("domain","")) == "prediction": return "重新探索预测" if Localization.current_locale() != "en" else "Reopen Prediction"
		return "重新打开临时工作台" if Localization.current_locale() != "en" else "Reopen temporary workshop"
	return ("继续旅程" if has_resume() else "开始旅程") if Localization.current_locale() != "en" else ("Continue journey" if has_resume() else "Start journey")

func start_or_continue() -> bool:
	var task: Dictionary = _resume_target()
	if task.is_empty(): return false
	camera_saved = false
	return enter(task.key)

# Separate navigation preferences never participate in progression or manifest restore.
var last_visited_task: String = ""
const NAVIGATION_PATH := "user://task_navigation.cfg"
func _ready() -> void:
	var settings := ConfigFile.new()
	if settings.load(NAVIGATION_PATH)==OK:
		var candidate: Variant = settings.get_value("navigation","last_visited_task","")
		if candidate is String and candidate.length()<100: last_visited_task=candidate

func remember_visit(domain: String, id: String) -> void:
	if GameMode.is_test_mode(): return
	var key: String = domain+"/"+id
	for task: Dictionary in tasks():
		if task.key==key and task.unlocked:
			# Direct next-task actions bypass enter(); follow the task actually opened.
			# A matching tree selection keeps its existing pan/zoom on return.
			if selected != key:
				selected = key
				camera_saved = false
			if key==last_visited_task: return
			last_visited_task=key
			var settings := ConfigFile.new()
			settings.set_value("navigation","last_visited_task",key)
			settings.save(NAVIGATION_PATH)
			return

func remember_candidate_visit(domain: String,index: int) -> void:
	# The host records what it actually opened; saved eligibility is checked at entry.
	if not candidate_journey_enabled(): return
	var key: String = SecondAct.key_for(domain,index)
	if key.is_empty(): return
	if selected != key: selected = key; camera_saved = false
	if GameMode.is_test_mode() or key == last_visited_task: return
	last_visited_task = key
	var settings := ConfigFile.new()
	settings.set_value("navigation","last_visited_task",key)
	settings.save(NAVIGATION_PATH)

func prepare_continue() -> void:
	var task: Dictionary = _resume_target()
	if not task.is_empty(): selected = task.key; camera_saved = false
