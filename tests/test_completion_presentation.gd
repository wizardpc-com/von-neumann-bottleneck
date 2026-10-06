extends SceneTree
## Synthetic snapshots test copy/visibility boundaries, not player playthroughs.
const Presentation = preload("res://experiments/candidate_session/completion_presentation.gd")
const Review = preload("res://experiments/candidate_session/journey_review.gd")
const RepModel = preload("res://experiments/representation_region/model.gd")
const ServiceModel = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)

func full_snapshot() -> Dictionary:
	var rep_rows: Array[Dictionary] = []
	var service_rows: Array[Dictionary] = []
	for task: int in 5:
		rep_rows.append({"task":task,"metrics":[{"preparation_cycles":17+task,"service_cycles":283+task,"total_cycles":300+task*2,"stored_bytes":51+task}]})
	for task: int in 3:
		service_rows.append({"task":task,"metrics":{"total_cycles":1091+task,"state_read_bytes":43+task,"state_write_bytes":29+task,"all_streams_first_cycle":211+task}})
	return {"representation":{"status":"complete","completed":[0,1,2,3,4],"evidence":rep_rows,"error":""},"service":{"status":"complete","completed":[0,1,2],"evidence":service_rows,"error":""},"complete":true}

func partition(ends: Array, codecs: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":int(ends[i]),"codec":codecs[i]})
		start = int(ends[i])
	return result

func run() -> void:
	var snapshot: Dictionary = full_snapshot()
	var before: Dictionary = snapshot.duplicate(true)
	for english: bool in [false,true]:
		var pages: Array[Dictionary] = Presentation.pages(snapshot,english)
		check(pages.size() == 4,"Four bounded stages in both languages")
		var ids: Array[String] = []
		for page: Dictionary in pages:
			ids.append(page.id)
			check(not page.title.is_empty() and not page.body.is_empty(),"Every stage has a title and body")
		check(ids == ["saved_work","representation","service","closure"],"Achievements precede earned closing text")
		check(pages[1].body.contains("17") and pages[1].body.contains("283") and pages[1].body.contains("300") and pages[1].body.contains("51"),"Representation text retains supplied preparation/service/total/storage facts")
		check(pages[2].body.contains("1091") and pages[2].body.contains("72") and pages[2].body.contains("211"),"Service text retains cycles, read-plus-write traffic, and all-stream response facts")
		check(not pages[0].body.contains("1391") and not pages[3].body.contains("1391"),"No combined cross-model cycle total")
		check(pages[3].body.contains("A Thought Within the World"),"Earned closure places theme after results")
		check(pages[3].body.contains("session") if english else pages[3].body.contains("本次会话"),"Optional Prediction is explicitly separate session-only exploration")
		check(snapshot == before,"Formatting never mutates the review snapshot")
		pages[1].body = "edited presentation"
		check(Presentation.pages(snapshot,english)[1].body != "edited presentation","Output pages do not become persistent review state")
		var bridge: Dictionary = Presentation.bridge(english)
		check(bridge.id == "bridge" and not bridge.title.is_empty() and not bridge.body.is_empty(),"Core-to-Representation bridge available in both languages")
		check(not bridge.body.contains("5 / 5") and not bridge.body.contains("3 / 3"),"Bridge asserts no earned progress")

	var partial: Dictionary = full_snapshot()
	partial.representation.status = "partial"
	partial.representation.completed = [4]
	partial.representation.evidence = [partial.representation.evidence[4]]
	partial.complete = false
	for english: bool in [false,true]:
		var pages: Array[Dictionary] = Presentation.pages(partial,english)
		check(pages[1].title.contains("1 / 5") and pages[2].title.contains("3 / 3"),"Independent partial achievement and earned stage are retained")
		check(pages[1].body.contains("308") and not pages[1].body.contains("300"),"Only the actual accepted task is presented")
		check(pages[3].id == "continue" and not pages[3].body.contains("A Thought Within the World"),"Partial result does not show final earned closure")
	partial.complete = true
	check(Presentation.pages(partial,true)[3].id == "continue","Top-level flag cannot override a partial domain")

	for status: String in ["empty","unavailable"]:
		var blocked: Dictionary = full_snapshot()
		blocked.representation.status = status
		blocked.representation.error = "snapshot_changed"
		# Stale metrics alongside the boundary must never leak into achieved copy.
		for english: bool in [false,true]:
			var pages: Array[Dictionary] = Presentation.pages(blocked,english)
			check(not pages[1].body.contains("300"),"Empty/unavailable stage hides stale achievements: "+status)
			if status == "unavailable":
				var unconfirmed: String = "Unconfirmed" if english else "待确认"
				check(pages[1].title.contains(unconfirmed) and not pages[1].title.contains("0 / 5"),"Unreadable domain has unknown progress rather than zero")
				check(pages[0].body.contains(unconfirmed) and not pages[0].body.contains("0 / 5"),"Overview also distinguishes unavailable from empty")
				check(not pages[0].body.contains("revalidated for their tasks") and not pages[0].body.contains("已保存并重新验收的方案"),"Unavailable overview does not assert all saved plans revalidated")
			else: check(pages[1].title.contains("0 / 5") and pages[0].body.contains("0 / 5"),"Empty domain has confirmed zero progress")
			check(pages[2].title.contains("3 / 3") and pages[2].body.contains("1091"),"Other domain's confirmed achievements survive")
			check(pages[3].id == "continue","Unavailable/empty stage cannot earn closure")
			if status == "unavailable": check(pages[1].body.contains("snapshot_changed"),"Unavailable cause stays visible")

	var no_success: Dictionary = full_snapshot()
	no_success.representation = {"status":"partial","completed":[],"evidence":[],"error":""}
	no_success.service = {"status":"partial","completed":[],"evidence":[],"error":""}
	check(Presentation.pages(no_success,true)[1].body.contains("do not yet meet"),"Readable saved runs without success are distinct from missing records")
	check(Presentation.pages(no_success,true)[1].title.contains("0 / 5"),"Readable partial result with no successes remains confirmed zero")
	var drafts := {"draft":RepModel.initial_plan(),"completed":[0,1,2,3,4],"unlocked":5,"complete":true}
	for english: bool in [false,true]:
		check(Presentation.pages(drafts,english)[3].id == "continue","Unrun drafts and progress flags have no presentation authority")
		check(Presentation.pages({},english)[1].title.contains("Unconfirmed" if english else "待确认"),"Unbound launch produces unknown progress")
	for corruption: Variant in [null,42,{"status":"complete","completed":[0,1,2,3,4],"evidence":[]},{"status":"draft","completed":[],"evidence":[]}]:
		var invalid: Dictionary = full_snapshot()
		invalid.representation = corruption
		check(Presentation.pages(invalid,true)[3].id == "continue","Malformed presentation inputs do not invent completion")
	var duplicate: Dictionary = full_snapshot()
	duplicate.representation.evidence[1].task = 0
	check(Presentation.pages(duplicate,true)[1].title.contains("Unconfirmed"),"Duplicate evidence rows make progress unconfirmed")
	var missing_metric: Dictionary = full_snapshot()
	missing_metric.service.evidence[0].metrics.erase("state_read_bytes")
	check(Presentation.pages(missing_metric,true)[2].title.contains("Unconfirmed"),"Missing numeric evidence is unavailable, never substituted with zero")

	# Integration shape: actual existing models produce the review consumed by UI.
	var rep_plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	var grouped: Dictionary = ServiceModel.initial_plan()
	grouped.groups = []
	for id: int in 24: grouped.groups.append([id])
	var timely: Dictionary = ServiceModel.initial_plan()
	timely.slots = 4
	var compact: Dictionary = timely.duplicate(true)
	compact.representations = ["rle64","rle64","raw64","raw64"]
	var service_plans: Array = [grouped,timely,compact]
	var rep_supports: Array = []
	var service_supports: Array = []
	for task: int in 5: rep_supports.append({"task":task,"plan":rep_plans[task]})
	for task: int in 3: service_supports.append({"task":task,"plan":service_plans[task]})
	var evaluated: Dictionary = Review.evaluate({"ok":true,"supports":rep_supports,"runs":[]},{"ok":true,"supports":service_supports,"runs":[]})
	check(evaluated.complete,"Model integration fixture independently meets existing five-plus-three contracts")
	for english: bool in [false,true]:
		var pages: Array[Dictionary] = Presentation.pages(evaluated,english)
		check(pages[3].id == "closure","Current authoritative review shape earns closure in both languages")
		check(pages[1].body.contains(str(evaluated.representation.evidence[4].metrics[0].total_cycles)),"Actual cross-asset task result appears in presentation")
		check(pages[2].body.contains(str(evaluated.service.evidence[2].metrics.all_streams_first_cycle)),"Actual Service all-stream result appears in presentation")
	print("PASS: test_completion_presentation " if failures == 0 else "FAIL: test_completion_presentation ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
