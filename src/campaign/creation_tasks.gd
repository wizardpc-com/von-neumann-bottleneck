extends RefCounted
const Session = preload("res://experiments/creation/session.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const Context = preload("res://experiments/candidate_session/context.gd")
const SCENE := "res://experiments/creation/workbench.tscn"
static var fingerprint: String = ""
static var cached_path: String = ""
static var saved: Dictionary = {}

static func enabled() -> bool:
	return ProjectSettings.get_setting("candidate/creation_enabled",false) == true or Context.full_journey() or "--creation-journey" in OS.get_cmdline_user_args()

static func key_for(index: int) -> String:
	return "creation/"+str(Catalog.IDS[index]) if index>=0 and index<Catalog.IDS.size() else ""

static func index_for(key: String) -> int:
	var index: int = Catalog.IDS.find(key.get_slice("/",1)) if key.begins_with("creation/") else -1
	return index if index >= 0 and key == key_for(index) else -1

static func build(english: bool, arguments: PackedStringArray = []) -> Array[Dictionary]:
	var path: String = Session.launch_path(arguments)
	var current: String = Files.fingerprint(path)
	if saved.is_empty() or path != cached_path or current != fingerprint:
		saved = Files.read_session(path,Session.decode); fingerprint = current; cached_path = path
	var support: Dictionary = saved.get("data",{}).get("supports",{}) if saved.get("ok",false) else {}
	var rows: Array[Dictionary] = []
	for index: int in Catalog.IDS.size():
		var chapter: int = index / 3
		var region: String = (["Compression","Content prediction","Creation"] if english else ["压缩","内容预测","创造"])[chapter]
		rows.append({"key":key_for(index),"id":Catalog.IDS[index],"domain":"creation","region":8+chapter,
			"title":Catalog.title(index,english),"body":Catalog.goal(index,english),"dependencies":[],
			"recommended_from":["representation/cross_assets"] if index==0 else [key_for(index-1)],
			"unlocked":true,"completed":support.has(Catalog.IDS[index]),"optional":false,"task_index":index,
			"region_title":region,"evidence_status":"saved" if saved.get("ok",false) else "unavailable","progress_source":"saved",
			"eligibility_note":"One machine, one rule box: restore first, then predict, then feed the output back in." if english else "同一台机器、同一个规则盒：先复原，再预测，最后把输出接回输入。",
			"record_metrics":[],"bonus_goals":[]})
	return rows
