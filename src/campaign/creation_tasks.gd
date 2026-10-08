extends RefCounted
const Session = preload("res://experiments/creation/session.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const SCENE := "res://experiments/creation/workbench.tscn"
static var fingerprint: String = ""
static var saved: Dictionary = {}

static func enabled() -> bool:
	return ProjectSettings.get_setting("candidate/creation_enabled",false) == true or "--creation-journey" in OS.get_cmdline_user_args()

static func key_for(index: int) -> String:
	return "creation/"+str(Catalog.IDS[index]) if index>=0 and index<Catalog.IDS.size() else ""

static func index_for(key: String) -> int:
	var index: int = Catalog.IDS.find(key.get_slice("/",1)) if key.begins_with("creation/") else -1
	return index if index >= 0 and key == key_for(index) else -1

static func build(english: bool) -> Array[Dictionary]:
	var current: String = Files.fingerprint(Session.default_path())
	if saved.is_empty() or current != fingerprint:
		saved = Files.read_session(Session.default_path(),Session.decode); fingerprint = current
	var support: Dictionary = saved.get("data",{}).get("supports",{}) if saved.get("ok",false) else {}
	var rows: Array[Dictionary] = []
	for index: int in Catalog.IDS.size():
		var chapter: int = index / 3
		var region: String = (["Compression · candidate","Content prediction · candidate","Creation · candidate"] if english else ["压缩 · 候选","内容预测 · 候选","创造 · 候选"])[chapter]
		rows.append({"key":key_for(index),"id":Catalog.IDS[index],"domain":"creation","region":8+chapter,
			"title":Catalog.title(index,english),"body":Catalog.goal(index,english),"dependencies":[],
			"recommended_from":["representation/cross_assets"] if index==0 else [key_for(index-1)],
			"unlocked":true,"completed":support.has(Catalog.IDS[index]),"optional":false,"task_index":index,
			"region_title":region,"evidence_status":"saved" if saved.get("ok",false) else "unavailable","progress_source":"saved",
			"eligibility_note":"One machine and rule box; explicit restore → predict → feedback. Earlier circuits are provenance, not this algorithm's executor." if english else "同一机器与规则盒；明确经历复原→预测→回灌。早期电路是构造来路，不冒称执行此算法。",
			"record_metrics":[],"bonus_goals":[]})
	return rows
