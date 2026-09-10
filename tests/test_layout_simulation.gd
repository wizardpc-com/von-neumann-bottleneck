extends SceneTree
const R = preload("res://src/layout_chapter/layout_recipe.gd")
const C = preload("res://src/layout_chapter/layout_catalog.gd")
const S = preload("res://src/layout_chapter/layout_simulator.gd")
var failures: Array[String] = []
func _init() -> void: call_deferred("_run")
func _run() -> void:
	var designs: Dictionary = {"records":C.starter_design(),"fields":C.starter_design(),"hot":C.starter_design(),"reverse_hot":C.starter_design(),"full":C.starter_design(),"batch4":C.starter_design(),"batch8":C.starter_design(),"hotfull":C.starter_design(),"hotbatch":C.starter_design()}
	designs.fields.recipe = R.field_major()
	designs.hot.recipe = {"groups":[{"fields":[0,3],"order":"record"},{"fields":[1,2],"order":"record"}],"block":0}
	designs.reverse_hot.recipe = {"groups":[{"fields":[3,0],"order":"field"},{"fields":[2,1],"order":"record"}],"block":2}
	for key: String in ["full","batch4","batch8","hotfull","hotbatch"]:
		designs[key].recipe = R.field_major() if key in ["full","batch4","batch8"] else designs.hot.recipe
		designs[key].strategy = "full" if key in ["full","hotfull"] else "batch"
		designs[key].batch = 8 if key == "batch8" else 4
		if key in ["hotfull","hotbatch"]: designs[key].copy_fields = [0,3]
	for id: String in C.IDS:
		check(C.evaluate(id,C.reference_solution(id)).passed,"public targets accept the authored solution "+id)
		for key: String in designs:
			var d: Dictionary = designs[key]
			if id in ["fields","records","hot_cold"] and d.strategy != "direct": continue
			for task: Dictionary in C.cases(id):
				var t: LayoutRun = S.new().run(task,d)
				print("MEASURE %s/%s/%s cycles=%d bytes=%d peak=%d passed=%s error=%s" % [id,task.name,key,t.metrics.total_cycles,t.metrics.ram_read_bytes+t.metrics.ram_write_bytes,t.metrics.peak_extra_bytes,t.passed,t.metrics.error])
				check(t.canonical_signature() == S.new().run(task,d).canonical_signature(),"deterministic trace "+id+key)
				check(t.metrics.total_cycles == t.metrics.prepare_cycles+t.metrics.query_cycles+t.metrics.output_cycles,"phase accounting")
				if t.metrics.error != "space_limit": check(t.passed,"logical values including ordered tail "+id+key)
	var source: Dictionary = C.cases("fields")[0]
	var a: LayoutRun = S.new().run(source,designs.records)
	var b: LayoutRun = S.new().run(source,designs.fields)
	check(a.metrics.ram_read_bytes == 128 and b.metrics.ram_read_bytes == 32,"independent 8-record cold-cache example: 128 B vs 32 B")
	check(a.metrics.total_cycles == 145 and b.metrics.total_cycles == 49,"8 reads + 8 arithmetic + fills + output")
	for n: int in [1,3,8,17,64]:
		for block: int in [0,1,2,4,7,16,64]:
			var recipe: Dictionary = designs.reverse_hot.recipe.duplicate(true)
			recipe.block = block
			var mapping: Dictionary = R.mapping(recipe,n)
			check(mapping.addresses.size() == n*4,"each logical cell mapped")
			var unique: Dictionary = {}
			for address: int in mapping.addresses.values(): unique[address] = true
			check(unique.size() == n*4,"no address aliasing, including partial blocks")
	var invalid: Dictionary = C.starter_design(); invalid.recipe.groups[0].fields = [0,0,2,3]
	check(not S.new().run(source,invalid).passed,"duplicate field rejected")
	check(not S.new().run(source,{"recipe":"invalid"}).passed,"malformed input rejected before signature")
	var changed: Dictionary = source.duplicate(true); changed.records[0][0] += 1
	check(S.new().run(changed,designs.fields).output_values[0] == b.output_values[0]+1,"logical data changes results independently of mapping")
	var limited: LayoutRun = S.new().run(C.cases("batches")[0],designs.full)
	check(limited.metrics.error == "space_limit" and limited.metrics.peak_extra_bytes == 0 and limited.metrics.ram_write_bytes == 0,"failed allocation isn't actual space or traffic")
	var packed: LayoutRun = S.new().run(C.cases("batches")[0],designs.batch4)
	check(packed.metrics.ram_write_bytes == 17*4 and packed.scratch_maps.size() == 5,"17 records copied once, 4+4+4+4+1")
	check(C.evaluate("hot_cold",designs.reverse_hot).passed,"blocked reversed-field alternative is valid")
	check(C.evaluate("mixed",designs.hotfull).passed and C.evaluate("mixed",designs.hotbatch).passed,"synthesis accepts full and batched copies")
	if failures.is_empty(): print("PASS: layout mapping, real flow, copy costs, bounds, tails and determinism")
	for issue: String in failures: push_error(issue)
	quit(0 if failures.is_empty() else 1)
func check(ok: bool, message: String) -> void:
	if not ok: failures.append(message)
