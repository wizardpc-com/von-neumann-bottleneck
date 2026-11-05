extends SceneTree
const Code = preload("res://src/layout_chapter/layout_challenge_code.gd")
const Board = preload("res://src/layout_chapter/layout_scoreboard.gd")
const Catalog = preload("res://src/layout_chapter/layout_catalog.gd")
var failures: Array[String] = []
var checks: int = 0

func _init() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func text(envelope: Dictionary) -> String: return Code.PREFIX+JSON.stringify(envelope,"",true)
func rejects(envelope: Dictionary, reason: String, message: String) -> void:
	var decoded: Dictionary = Code.decode(text(envelope))
	check(not decoded.ok and decoded.reason == reason,message)
func changed(source: Dictionary, key: String, value: Variant) -> Dictionary:
	var copy: Dictionary = source.duplicate(true)
	copy[key] = value
	return copy

func run() -> void:
	var before: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	for task: String in Catalog.IDS:
		var design: Dictionary = Catalog.reference_solution(task)
		var untouched: Dictionary = design.duplicate(true)
		for objective: String in ["cycles","traffic","space"]:
			var source: Array[Dictionary] = [{"id":"original","title":"","design":design}]
			var expected: Dictionary = Board.build_rows(task,source,objective)[0]
			var encoded: Dictionary = Code.encode(task,design,objective)
			check(encoded.ok and encoded.code.to_utf8_buffer().size() <= Code.MAX_BYTES,"Eligible "+task+" exports a bounded "+objective+" recipe.")
			if not encoded.ok: continue
			var inspected: Dictionary = Code.inspect(encoded.code,task)
			check(inspected.ok,"Actual "+task+" code remeasures as an eligible target.")
			if not inspected.ok: continue
			for metric: String in ["cycles","traffic","peak","condition_id","recipe_id"]:
				check(inspected.row[metric] == expected[metric],"Round-trip "+task+" preserves actual "+metric+".")
			check(inspected.row.cases == expected.cases,"Round-trip "+task+" preserves every actual trace signature and output.")
			check(inspected.challenge.objective == objective,"Chosen objective survives "+task+" transport.")
			check(Code.encode(task,inspected.design,objective).code == encoded.code,"Canonical "+task+" code is stable on re-export.")
		check(design == untouched,"Encoding never changes the caller's "+task+" design.")
	var exported: Dictionary = Code.encode("mixed",Catalog.reference_solution("mixed"),"cycles")
	var envelope: Dictionary = exported.challenge
	check(Code.decode(" \n"+exported.code+"\r\n").ok,"Surrounding copy/paste whitespace is permitted within the size bound.")
	check(Code.decode("x".repeat(Code.MAX_BYTES+1)).reason == "size","Oversized unparsed text is refused first.")
	check(Code.decode("界".repeat(Code.MAX_BYTES/2)).reason == "size","Bound counts UTF-8 bytes, not only displayed characters.")
	check(Code.decode("VNB4C2:{}").reason == "version","Unknown future prefix is explicit.")
	for raw: String in ["","https://example.invalid/recipe","VNB4C1:{","VNB4C1:[]"]:
		check(not Code.decode(raw).ok,"Malformed or unrelated text cannot become a recipe.")
	for field: String in Code.ENVELOPE_FIELDS:
		var missing: Dictionary = envelope.duplicate(true); missing.erase(field)
		rejects(missing,"format","Missing envelope field "+field+" is rejected.")
	for field: String in ["score","cycles","rank","passed","program_source","path"]:
		rejects(changed(envelope,field,1),"format","External "+field+" cannot add authority or hidden content.")
	for value: Variant in [0,2,1.5,true,"1",null]:
		rejects(changed(envelope,"v",value),"version","Unsupported version type/value is rejected.")
	for value: Variant in ["unknown","",7,true]:
		rejects(changed(envelope,"task",value),"task","Unknown task cannot select invented cases.")
	for value: Variant in ["ram","",7,true]:
		rejects(changed(envelope,"objective",value),"objective","Unknown objective cannot fall back to cycles.")
	for value: Variant in ["","x".repeat(81),"bad\nmodel",7,true]:
		rejects(changed(envelope,"model",value),"model","Invalid model identifier is rejected.")
	for value: Variant in ["A".repeat(64),"x".repeat(64),"0".repeat(63),7,true]:
		rejects(changed(envelope,"condition",value),"condition","Invalid condition digest is rejected.")
	var stale: Dictionary = changed(envelope,"model","older-layout-model")
	check(Code.decode(text(stale)).ok and Code.inspect(text(stale)).reason == "model","Supported stale models stay structurally readable but cannot become current targets.")
	stale = changed(envelope,"condition","0".repeat(64))
	check(Code.decode(text(stale)).ok and Code.inspect(text(stale)).reason == "condition","Supported stale workloads remain readable without current comparison.")
	var wrong_task: Dictionary = Code.inspect(exported.code,"fields")
	check(wrong_task.reason == "wrong_task" and wrong_task.task == "mixed","A different task is identified without silent navigation or relabeling.")
	var duplicate: String = exported.code.replace('"v":1','"v":1,"v":1')
	check(Code.decode(duplicate).reason == "format","Duplicate JSON keys are rejected by canonical equality.")
	check(Code.decode(exported.code.replace('"v":1','"v":1.0')).reason == "format","Noncanonical number spelling cannot hide normalization.")
	check(Code.decode(Code.PREFIX+JSON.stringify(envelope,"\t",true)).reason == "format","Only generated canonical payloads are accepted.")
	var pure: Dictionary = envelope.design
	for field: String in Code.DESIGN_FIELDS:
		var missing: Dictionary = pure.duplicate(true); missing.erase(field)
		rejects(changed(envelope,"design",missing),"recipe","No external "+field+" default is manufactured.")
	for field: String in ["score","orders","source"]:
		rejects(changed(envelope,"design",changed(pure,field,{})),"recipe","Unknown nested design "+field+" is rejected.")
	for value: Variant in [0,65,1.5,true,"4",null]:
		rejects(changed(envelope,"design",changed(pure,"batch",value)),"recipe","Batch must be an explicit finite bounded integer.")
	for value: Variant in ["unknown",7,true]:
		rejects(changed(envelope,"design",changed(pure,"strategy",value)),"recipe","Invalid strategy type/value is rejected.")
	for value: Variant in [[],[0,0],[4],[-1],[0.5],[true],"0",[0,1,2,3,0]]:
		rejects(changed(envelope,"design",changed(pure,"copy_fields",value)),"recipe","Copy field bounds and uniqueness are strict.")
	var recipe: Dictionary = pure.recipe
	for value: Variant in [-1,65,0.5,true,"0",null]:
		var modified: Dictionary = pure.duplicate(true)
		modified.recipe = changed(recipe,"block",value)
		rejects(changed(envelope,"design",modified),"recipe","Block must be an explicit finite bounded integer.")
	for modified_recipe: Dictionary in [
		{"groups":recipe.groups},{"block":0},
		{"groups":recipe.groups,"block":0,"future":1},
		{"groups":[],"block":0},
		{"groups":[{"fields":[0,0,2,3],"order":"record"}],"block":0},
		{"groups":[{"fields":[0,1,2],"order":"record"}],"block":0},
		{"groups":[{"fields":[0,1,2,3],"order":"record","hidden":1}],"block":0},
		{"groups":[{"fields":[0,1,2,3],"order":7}],"block":0},
		{"groups":[{"fields":[0,1,2,true],"order":"record"}],"block":0},
	]:
		var modified: Dictionary = pure.duplicate(true); modified.recipe = modified_recipe
		rejects(changed(envelope,"design",modified),"recipe","Recipe partition and group fields reject silent normalization.")
	var native: Dictionary = Code.encode("fields",Catalog.reference_solution("fields"),"traffic").challenge
	native.design.strategy = "full"
	rejects(native,"recipe","Native layouts cannot import a copy strategy.")
	native = Code.encode("fields",Catalog.reference_solution("fields"),"traffic").challenge
	native.design = Catalog.starter_design()
	check(Code.decode(text(native)).ok and Code.inspect(text(native)).reason == "ineligible","Structurally valid slower recipe cannot pretend to meet original targets.")
	check(Code.encode("fields",Catalog.starter_design(),"cycles").reason == "ineligible","Export also recomputes original eligibility.")
	check(Code.encode("unknown",{},"cycles").reason == "task" and Code.encode("mixed",Catalog.reference_solution("mixed"),"unknown").reason == "objective","Encoder rejects invented task and objective.")
	var relocation: Dictionary = Catalog.reference_solution("relocation")
	var original_code: Dictionary = Code.encode("relocation",relocation,"cycles")
	check(original_code.ok and original_code.challenge.design.keys() == ["orders"],"Relocation sends actual A/B only, without an unexecuted root recipe.")
	var different_root: Dictionary = relocation.duplicate(true)
	different_root.recipe = Catalog.reference_solution("mixed").recipe
	different_root.batch = 61
	check(Code.encode("relocation",different_root,"cycles").code == original_code.code,"Unused relocation root choices do not change the exported challenge.")
	for order: String in ["A","B"]:
		var missing: Dictionary = original_code.challenge.duplicate(true)
		missing.design.orders.erase(order)
		rejects(missing,"recipe","Missing relocation "+order+" cannot fall back silently.")
	var extra_order: Dictionary = original_code.challenge.duplicate(true)
	extra_order.design.orders["C"] = Catalog.starter_design()
	rejects(extra_order,"recipe","Unknown relocation orders are rejected.")
	var nested_order: Dictionary = original_code.challenge.duplicate(true)
	nested_order.design.orders.A["orders"] = {}
	rejects(nested_order,"recipe","Nested order containers are rejected.")
	var swapped: Dictionary = original_code.challenge.duplicate(true)
	swapped.design.orders = {"A":swapped.design.orders.B,"B":swapped.design.orders.A}
	var swapped_result: Dictionary = Code.decode(text(swapped))
	check(swapped_result.ok,"Both swapped recipes remain structurally representable.")
	var swapped_rows: Array[Dictionary] = [{"id":"swap","title":"","design":swapped_result.design}]
	check(Board.build_rows("relocation",swapped_rows)[0].recipe_id != original_code.row.recipe_id,"A/B order binding changes actual executed recipe identity.")
	var after: Dictionary = root.get_node("GlobalSave")._save_snapshot()
	before.erase("saved_at_utc"); after.erase("saved_at_utc")
	check(before == after,"Encoding, inspecting and rejecting recipes never changes progress.")
	print(("PASS" if failures.is_empty() else "FAIL"),": layout challenge code ",checks," checks")
	quit(0 if failures.is_empty() else 1)
