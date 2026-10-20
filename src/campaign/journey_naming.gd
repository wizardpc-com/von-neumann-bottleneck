extends RefCounted
## One naming scheme for chapters and tasks, used by the journey map, the task
## list, workbench headers and the completion card (team UI brief 2026-10-20 §1):
##   chapters: 序章 → 第一章 → 第二章 …
##   prologue tasks: 序章·关卡名     main tasks: 1-1 关卡名     side tasks: 1-4-1 关卡名
## Only presentation changes; task keys, IDs and progress stay as they are.

const ZH_NUMBERS: Array[String] = ["", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
const PREFIX := "^(序章\\s*[·：:]\\s*|Prologue\\s*[·:]\\s*|[A-Z]?\\d+\\s*·\\s*|\\d+-\\d+(-\\d+)?\\s+)"


static func english() -> bool:
	# Looked up at run time so test scripts can preload this before autoloads exist.
	var localization: Node = _autoload("Localization")
	return localization != null and str(localization.current_locale()) == "en"


static func _autoload(node_name: String) -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null(node_name) if tree != null else null


## "序章" / "第一章" (or "Prologue" / "Chapter 1").
static func chapter_ordinal(region: int) -> String:
	if region <= 0: return "Prologue" if english() else "序章"
	if english(): return "Chapter %d" % region
	return "第%s章" % (ZH_NUMBERS[region] if region < ZH_NUMBERS.size() else str(region))


## The chapter's own name without any older "01 " style number.
static func chapter_name(raw: String) -> String:
	var clean: String = raw.strip_edges()
	var number := RegEx.create_from_string("^\\d+\\s+")
	clean = number.sub(clean, "")
	var prologue := RegEx.create_from_string("^(序章|第\\s*\\d+\\s*章|Prologue|Chapter\\s*\\d+)\\s*[·：:]?\\s*")
	return prologue.sub(clean, "")


static func chapter_title(region: int, raw: String) -> String:
	var name: String = chapter_name(raw)
	return chapter_ordinal(region) + (" · " + name if not name.is_empty() else "")


static func plain_title(title: String) -> String:
	return RegEx.create_from_string(PREFIX).sub(title.strip_edges(), "")


## Number every task: main tasks count up in journey order within their
## chapter; a side task takes the number of the main task it branches from.
static func numbers(rows: Array) -> Dictionary:
	var result: Dictionary = {}
	var main_index: Dictionary = {}
	var side_count: Dictionary = {}
	var regions: Dictionary = {}
	for task: Dictionary in rows:
		var region: int = int(task.region)
		if region <= 0 or (bool(task.get("optional", false)) and _parent(task, rows) != ""): continue
		regions[region] = int(regions.get(region, 0)) + 1
		main_index[str(task.key)] = int(regions[region])
		result[str(task.key)] = "%d-%d" % [region, int(regions[region])]
	for task: Dictionary in rows:
		var key: String = str(task.key)
		if int(task.region) <= 0 or result.has(key): continue
		var parent: String = _parent(task, rows)
		side_count[parent] = int(side_count.get(parent, 0)) + 1
		result[key] = "%s-%d" % [str(result.get(parent, str(task.region))), int(side_count[parent])]
	return result


static func _parent(task: Dictionary, rows: Array) -> String:
	for dependency: Variant in task.get("dependencies", []):
		for other: Dictionary in rows:
			if str(other.key) == str(dependency) and int(other.region) == int(task.region) and not bool(other.get("optional", false)):
				return str(other.key)
	return ""


## "序章·接线教程" / "1-3-1 一取再用".
static func task_label(task: Dictionary, numbering: Dictionary) -> String:
	var title: String = plain_title(str(task.get("title", "")))
	if int(task.get("region", 0)) <= 0:
		return ("Prologue · " if english() else "序章·") + title
	return str(numbering.get(str(task.key), "")) + " " + title


## Label for one task key using the live journey (for headers and cards).
static func label_for(key: String) -> String:
	var navigation: Node = _autoload("TaskNavigation")
	if navigation == null: return ""
	var rows: Array[Dictionary] = navigation.journey_tasks()
	var numbering: Dictionary = numbers(rows)
	for task: Dictionary in rows:
		if str(task.key) == key: return task_label(task, numbering)
	return ""


## Chapter title for the region a task key belongs to.
static func chapter_for(key: String) -> String:
	var navigation: Node = _autoload("TaskNavigation")
	if navigation == null: return ""
	for task: Dictionary in navigation.journey_tasks():
		if str(task.key) == key:
			var raw: String = str(task.get("region_title", ""))
			if raw.is_empty(): raw = str(_autoload("Localization").text(StringName("tree.region." + str(task.region))))
			return chapter_title(int(task.region), raw)
	return ""
