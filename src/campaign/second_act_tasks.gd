extends RefCounted
## Read-only task presentation. Existing domain models revalidate saved recipes.
const Context = preload("res://experiments/candidate_session/context.gd")
const Review = preload("res://experiments/candidate_session/journey_review.gd")
const Files = preload("res://experiments/candidate_session/files.gd")
const IDS := {"representation":["mixed_scan","interior_hotspots","dense_sparse","prepare_once","cross_assets"],"service":["move_state","prompt_response","one_plan"],"prediction":["regular","changed","alternating"]}
const SCENES := {"representation":"res://experiments/representation_region/region.tscn","service":"res://experiments/service_plan/lab.tscn","prediction":"res://experiments/prediction/lab.tscn"}
static var cached_fingerprints: Dictionary = {}
static var cached_review: Dictionary = {}
static var cached_resume_tasks: Dictionary = {}

static func enabled() -> bool:
	return Context.configured_journey() or "--candidate-journey" in OS.get_cmdline_user_args()

static func paths() -> Dictionary:
	var primary: String = str(ProjectSettings.get_setting("candidate/primary_domain",""))
	var profile: String = str(ProjectSettings.get_setting("candidate/profile",""))
	var directory: String = OS.get_user_data_dir()
	if not Context.configured_journey_for(true,primary,profile,directory): return {}
	return {"representation":Context.resolve_path("representation",primary,profile,directory),"service":Context.resolve_path("service",primary,profile,directory)}

static func saved_review() -> Dictionary:
	var locations: Dictionary = paths()
	if locations.is_empty():
		cached_resume_tasks.clear(); cached_review.clear(); cached_fingerprints.clear()
		return {}
	var fingerprints := {"paths":locations.duplicate(true),"representation":Files.fingerprint(locations.representation),"service":Files.fingerprint(locations.service)}
	if cached_review.is_empty() or fingerprints != cached_fingerprints:
		cached_review = Review.read_pair(locations.representation,locations.service)
		cached_fingerprints = fingerprints.duplicate(true)
		cached_resume_tasks.clear()
		for domain: String in ["representation","service"]:
			if str(cached_review.get(domain,{}).get("status","unavailable")) in ["empty","unavailable"]: continue
			var saved: Dictionary = Review.read_saved(locations[domain],domain == "representation")
			if saved.get("ok",false) and not saved.get("empty",false) and str(saved.get("digest","")) == str(cached_review.get("digests",{}).get(domain,"")):
				cached_resume_tasks[domain] = int(saved.task)
	return cached_review.duplicate(true)

static func saved_resume_target() -> String:
	var review: Dictionary = saved_review()
	var domains: Array = ["representation","service"] if str(review.get("representation",{}).get("status","")) != "complete" else ["service","representation"]
	var rows: Array[Dictionary] = build(review,false)
	for domain: String in domains:
		if not cached_resume_tasks.has(domain): continue
		var target_index: int = int(cached_resume_tasks[domain])
		if domain == "service":
			var available_index: int = 0
			for row: Dictionary in rows:
				if row.domain == domain and row.unlocked: available_index = maxi(available_index,int(row.task_index))
			target_index = mini(target_index,available_index)
		var key: String = key_for(domain,target_index)
		for row: Dictionary in rows:
			if row.key == key and row.unlocked: return key
	return ""

static func key_for(domain: String,index: int) -> String:
	if not IDS.has(domain) or index < 0 or index >= IDS[domain].size(): return ""
	return domain+"/"+str(IDS[domain][index])

static func index_for(key: String) -> int:
	var domain: String = key.get_slice("/",0)
	var index: int = IDS[domain].find(key.get_slice("/",1)) if IDS.has(domain) else -1
	return index if index >= 0 and key == key_for(domain,index) else -1

static func build(review: Dictionary,english: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var rep_catalog: Script = preload("res://experiments/representation_region/catalog.gd")
	var service_titles: Array = ["Move less state","Prompt service","One service plan"] if english else ["少搬状态","及时服务","同一服务方案"]
	var prediction_titles: Array = ["Regular stream","Pattern changes","Alternating hotspots"] if english else ["规律流","规律改变","交替热点"]
	var service: Dictionary = review.get("service",{})
	var service_available: int = 0
	if str(service.get("status","unavailable")) != "unavailable":
		for index: int in service.get("completed",[]): service_available = maxi(service_available,mini(index+1,2))
	for domain: String in ["representation","service","prediction"]:
		var item: Dictionary = review.get(domain,{})
		var status: String = "session" if domain == "prediction" else str(item.get("status","unavailable"))
		for index: int in IDS[domain].size():
			var title: String = rep_catalog.title(index,english) if domain == "representation" else service_titles[index] if domain == "service" else prediction_titles[index]
			var body: String
			var recommended: Array[String] = []
			if domain == "representation":
				body = (["Serve a mixed64-byte asset scan with a block representation under public time and storage limits.","Serve repeated interior reads while meeting whole-asset storage and transfer limits.","One partition serves both a full scan and repeated endpoint reads; each order starts cold.","Serve a short read and eight cold scans. Account for source reads, encoding and writes during shared online preparation.","One partition and encoding choice serves two different public assets and their orders."] if english else ["为64字节混合资产的扫描安排分块表示，满足公开时间与存储限制。","为重复内部点读安排表示，同时满足整份资产存储与搬运限制。","同一划分服务完整扫描与重复端点点读；每份订单从空缓存开始。","服务一次短读与八次冷扫描；共同在线准备包含源读取、编码与写入。","同一划分与编码选择服务两份不同的公开资产和各自订单。"])[index]
				recommended.assign(["chapter_3/synthesis","chapter_4/mixed"] if index == 0 else [key_for(domain,index-1)])
			elif domain == "service":
				body = (["Arrange retained state and request groups; compare real state transfers.","Preserve each stream's order while meeting first-response limits.","One plan meets traffic, response and quality contracts."] if english else ["安排状态驻留与请求分组，比较真实状态搬运。","保留同流顺序，同时满足首次响应限制。","同一方案同时满足搬运、响应与质量合同。"])[index]
				recommended.assign([key_for("representation",4)] if index == 0 else [key_for(domain,index-1)])
			else:
				body = "Optional investigation. Compare observed history, useful predictions and the cost of wrong guesses. Work lasts only in the open workshop; leaving discards it." if english else "可选调查。比较已知历史、有效预测与猜错的成本。探索只保留在当前工作台，离开后丢弃。"
				recommended.assign(["chapter_3/prefetch"] if index == 0 else [key_for(domain,index-1)])
			var region: int = 5 if domain == "representation" else 6 if domain == "service" else 7
			var region_title: String = ({"representation":"Representation","service":"State and service","prediction":"Prediction · optional"} if english else {"representation":"表示 · 改变承载","service":"持续状态与服务","prediction":"预测 · 可选探索"})[domain]
			var eligibility: String = ""
			if domain == "service":
				if status == "unavailable": eligibility = "Saved work could not be confirmed. Enter contract1 to inspect and recover the original save before later contracts can be located reliably." if english else "已保存成果无法确认。请进入合同1检查并恢复原档，再确认后续合同的可用范围。"
				elif index == 0: eligibility = "Contract1 is independently available. Representation and Prediction are not prerequisites." if english else "合同1可独立进入；表示与预测不是前置。"
				elif index == 1: eligibility = "Contract2 becomes available after a saved accepted contract1 plan. Existing valid later support also retains the original workbench's access." if english else "已保存的合同1达标方案使合同2可用；已有有效后续支持方案也沿原工作台规则保留进入资格。"
				else: eligibility = "Contract3 becomes available after a saved accepted contract2 plan, or remains available through its own valid saved support. Representation and Prediction are not prerequisites." if english else "已保存的合同2达标方案使合同3可用；合同3自身有效已保存支持也保留资格。表示与预测不是前置。"
			result.append({"key":key_for(domain,index),"id":str(IDS[domain][index]),"domain":domain,"region":region,"title":title,"body":body,"dependencies":[],"recommended_from":recommended,"unlocked":domain != "service" or index <= service_available,"completed":domain != "prediction" and status != "unavailable" and index in item.get("completed",[]),"optional":domain == "prediction","task_index":index,"evidence_status":status,"progress_source":"session" if domain == "prediction" else "saved","region_title":region_title,"eligibility_note":eligibility,"record_metrics":[],"bonus_goals":[]})
	return result
