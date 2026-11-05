extends SceneTree
## Separate public calls diagnose repeated host work; these timings are not
## additive profiler attribution and never change modeled event costs.
const Model = preload("res://experiments/creation/model.gd")
const Catalog = preload("res://experiments/creation/catalog.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	if not OS.get_user_data_dir().replace("\\","/").contains("/VonNeumannBottleneckChecks/"):
		push_error("Use an isolated QA profile.")
		quit(1)
		return
	var learned: Dictionary = Model.learn([Catalog.source(1).slice(0,256)],2,Model.default_machine())
	if not learned.ok:
		push_error("Profile learning failed: "+str(learned))
		quit(1)
		return
	var cases: Array[Dictionary] = []
	for length: int in [64,1024,4096]:
		var samples: Array[Dictionary] = []
		for repeat_index: int in 3:
			var started: int = Time.get_ticks_usec()
			var run: Dictionary = Model.generate(learned.model,[0,1],length,987,"weighted",Model.default_machine())
			var full_us: int = Time.get_ticks_usec()-started
			if not run.ok or run.output.size() != length:
				push_error("Profile generation did not complete.")
				quit(1)
				return
			var validation_us: int = 0
			var prefix_us: int = 0
			var prediction_us: int = 0
			var rule_reads: int = 0
			for index: int in range(2,length):
				# Prefix creation is outside these component timings.
				var prefix: Array = run.output.slice(0,index)
				started = Time.get_ticks_usec()
				var error: String = Model.validate(learned.model)
				validation_us += Time.get_ticks_usec()-started
				if not error.is_empty():
					push_error("Frozen valid model rejected.")
					quit(1)
					return
				started = Time.get_ticks_usec()
				error = Model.symbols_error(prefix)
				prefix_us += Time.get_ticks_usec()-started
				if not error.is_empty():
					push_error("Generated prefix rejected.")
					quit(1)
					return
				started = Time.get_ticks_usec()
				var decision: Dictionary = Model.predict(learned.model,prefix)
				prediction_us += Time.get_ticks_usec()-started
				if not decision.ok:
					push_error("Public prediction rejected generated prefix.")
					quit(1)
					return
				for item: Dictionary in decision.events:
					if item.kind == "rule_read": rule_reads += 1
			samples.append({"generate_us":full_us,"separate_validate_us":validation_us,
				"separate_prefix_validate_us":prefix_us,"separate_public_predict_us":prediction_us,
				"predictions":length-2,"rule_reads":rule_reads,"events":run.events.size(),
				"output_sha256":JSON.stringify(run.output).sha256_text(),"cost":run.cost})
		cases.append({"length":length,"samples":samples})
		print("PROFILE length=",length," samples=",JSON.stringify(samples))
	var file := FileAccess.open("user://creation-profile.json",FileAccess.WRITE)
	if file == null:
		push_error("Cannot write profile receipt.")
		quit(1)
		return
	file.store_string(JSON.stringify({"engine":Engine.get_version_info(),"processor":OS.get_processor_name(),
		"scope":"Separate API timings over actual generated prefixes; not additive attribution; full generation includes all events and costs.",
		"cases":cases},"",true,true))
	file.close()
	print("PASS: creation hotspot profile ",ProjectSettings.globalize_path("user://creation-profile.json"))
	quit()
