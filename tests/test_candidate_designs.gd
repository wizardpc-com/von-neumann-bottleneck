extends SceneTree
const Designs = preload("res://experiments/candidate_session/designs.gd")
const Rep = preload("res://experiments/representation_region/session_store.gd")
const Service = preload("res://experiments/service_plan/session_store.gd")
const RepModel = preload("res://experiments/representation_region/model.gd")
const ServiceModel = preload("res://experiments/service_plan/model.gd")
var checks: int = 0
var failures: int = 0

func _init() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1; push_error(message)

func run() -> void:
	var records: Array[Dictionary] = [{"task":0,"plan":RepModel.initial_plan()},{"task":0,"plan":ServiceModel.initial_plan()}]
	var rep_drafts: Array = []
	for i: int in 5: rep_drafts.append(RepModel.initial_plan())
	for domain: int in 2:
		var store: GDScript = Rep if domain == 0 else Service
		var draft: Variant = rep_drafts if domain == 0 else ServiceModel.initial_plan()
		var record: Dictionary = records[domain]
		var empty: Array[Dictionary] = []
		var kept: Dictionary = Designs.remember(empty,record,"  我的第一版 · First attempt  ")
		check(kept.ok and kept.designs[0].name == "我的第一版 · First attempt","Names trim edges and keep Unicode")
		var original: Variant = record.plan.duplicate(true)
		if domain == 0: record.plan[0].codec = "rle"
		else: record.plan.slots = 4
		check(kept.designs[0].plan == original,"Collection owns detached plan, not mutable draft")
		record.plan = original
		var designs: Array[Dictionary] = []; designs.assign(kept.designs)
		var renamed: Dictionary = Designs.remember(designs,record,"Renamed")
		check(renamed.ok and renamed.designs.size() == 1 and renamed.designs[0].name == "Renamed" and designs[0].name != "Renamed","Renaming same plan changes one detached entry")
		for invalid: String in ["", "   ", "bad\nname", "bad\tname", "x".repeat(49), "bad"+char(127)]:
			check(not Designs.remember(designs,record,invalid).ok,"Invalid player name refused without mutation")
		var legacy: String = store.encode(0,draft,[record])
		check(JSON.parse_string(legacy).schema == 2 and store.decode(legacy).designs.is_empty(),"Empty collection leaves schema2 bytes shape")
		var schema1: Dictionary = JSON.parse_string(legacy); schema1.schema = 1; schema1.erase("supports")
		check(store.decode(JSON.stringify(schema1)).ok and store.decode(JSON.stringify(schema1)).designs.is_empty(),"Schema1 still reads with no designs")
		var raw: String = store.encode(0,draft,[record],[],designs)
		var decoded: Dictionary = store.decode(raw)
		check(JSON.parse_string(raw).schema == 3 and decoded.ok and decoded.designs == designs,"Schema3 keeps only plan identity and name")
		for mutation: Dictionary in [{"schema":4},{"accepted":true},{"designs":[{"task":0,"name":"Fake","plan":original,"accepted":true}]},{"designs":[{"task":0.5,"name":"Fake","plan":original}]},{"designs":[{"task":5,"name":"Fake","plan":original}]},{"designs":[{"task":0,"name":" bad ","plan":original}]},{"designs":[{"task":0,"name":"Fake","plan":{}}]},{"designs":[designs[0],designs[0]]}]:
			var changed: Dictionary = JSON.parse_string(raw); changed.merge(mutation,true)
			check(not store.decode(JSON.stringify(changed)).ok,"Unknown format, authority injection or malformed collection refused")
		var full: Array[Dictionary] = []
		for i: int in Designs.LIMIT:
			var varied: Variant = RepModel.split(RepModel.initial_plan(),0,i+1) if domain == 0 else ServiceModel.initial_plan()
			if domain == 1:
				varied.slots = i%4+1
				varied.representations[0] = ServiceModel.REPRESENTATIONS[(i/4)%4]
				varied.representations[1] = "rle64"
			full.append({"task":i%3,"plan":varied,"name":"Design%d" % i})
		check(not Designs.remember(full,record,"Overflow").ok,"Full collection cannot silently drop another design")
		check(Designs.remember(full,full[0],"Rename at limit").ok,"Renaming at capacity remains possible")
		var oversized: Dictionary = JSON.parse_string(raw); oversized.designs = full.duplicate(true); oversized.designs.append(designs[0])
		check(not store.decode(JSON.stringify(oversized)).ok,"Oversized collection refused")
		var path: String = "user://named-designs-domain%d.json" % domain
		check(store.write_session(legacy,path) == OK,"Owned legacy candidate fixture installed")
		check(store.write_session(raw,path,legacy.sha256_text()) == OK,"Explicit save writes collection transactionally")
		check(FileAccess.get_file_as_string(path+".bak") == legacy and store.read_session(path).designs == designs,"Previous candidate bytes preserved and named collection read back")
		var future: Dictionary = JSON.parse_string(raw); future.schema = 4
		var file := FileAccess.open(path,FileAccess.WRITE); file.store_string(JSON.stringify(future)); file.close()
		var before: String = FileAccess.get_file_as_string(path)
		check(store.read_session(path).get("error") == "version","Future main is not bypassed by older backup")
		check(store.write_session(raw,path,before.sha256_text()) != OK and FileAccess.get_file_as_string(path) == before,"Unknown future bytes never overwritten")
	print("PASS: test_candidate_designs " if failures == 0 else "FAIL: test_candidate_designs ",checks," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
