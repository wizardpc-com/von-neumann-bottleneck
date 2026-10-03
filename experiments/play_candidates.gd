extends "res://experiments/candidate_input.gd"
## Known-objective QA. Authored plans belong here, never in unknown-answer policies.
func partition(ends: Array, codecs: Array) -> Array:
	var result: Array = []; var start: int = 0
	for i: int in ends.size():
		result.append({"start":start,"end":ends[i],"codec":codecs[i]}); start = ends[i]
	return result

func representation() -> void:
	await open_scene("res://experiments/representation_region/region.tscn")
	var plans: Array = [partition([16,64],["rle","raw"]),partition([16,24,40,48,64],["rle","rle","raw","rle","rle"]),partition([16,48,64],["rle","rle","rle"]),partition([8,64],["raw","rle"]),partition([18,46,64],["rle","raw","rle"])]
	for task: int in 5:
		await press(handle("Task"+str(task))); await press(handle("Hint1")); await press(handle("Run"))
		check(not ui.public_observation().accepted,"Initial RAW plan does not clear task "+str(task))
		if task == 3:
			await build_partition(partition([64],["rle"])); await press(handle("Run"))
			check(not ui.public_observation().accepted,"Whole RLE fails combined online contracts")
			await capture("region-preparation-counterexample")
		if task == 4:
			await build_partition(partition([20,44,64],["rle","raw","rle"])); await press(handle("Run"))
			check(not ui.public_observation().accepted,"Asset A optimal boundaries do not generalize to B")
			await capture("region-generalization-counterexample")
		await build_partition(plans[task]); await press(handle("Undo")); await press(handle("Redo"))
		check(ui.public_observation().plan == plans[task],"UI undo/redo preserves proposal")
		await press(handle("Run")); check(ui.public_observation().accepted,"Measured candidate task accepted "+str(task))
		if ui.order_choice.item_count > 1: await choose(ui.order_choice,1)
		await tree_row(ui.events,0); await capture("region-task"+str(task+1))

func policy(rule: String, confidence: int = 1, cooldown: int = 0) -> Dictionary:
	return {"rule":rule,"confidence":confidence,"lookahead":1,"cooldown":cooldown}

func prediction() -> void:
	await open_scene("res://experiments/prediction/lab.tscn")
	for task: int in 3:
		await press(handle("Task"+str(task))); await set_prediction(policy("off"))
		await press(handle("Step")); await press(handle("Step"))
		check(ui.public_observation().observed_addresses.size() == 2,"Only observed prefix revealed")
		await capture("prediction-prefix"+str(task)); await press(handle("Run"))
		await set_prediction(policy("stride")); await press(handle("Run"))
		var records: Array = ui.public_observation().completed_runs
		var metrics: Dictionary = records.back().metrics
		check(metrics.total_cycles < metrics.baseline_cycles if task == 0 else metrics.total_cycles > metrics.baseline_cycles,"Prediction gain or genuine reversal "+str(task))
		await capture("prediction-eager"+str(task))
		if task > 0:
			await set_prediction(policy("stride",3,2) if task == 1 else policy("two_stride")); await press(handle("Run"))
		check(ui.public_observation().goal_met,"Prediction evidence contract met "+str(task))
		await tree_row(ui.events,0); await capture("prediction-task"+str(task+1))

func service_draft(grouped: bool, slots: int, formats: Array) -> Dictionary:
	var groups: Array = []
	if grouped:
		for id: int in 24: groups.append([id])
	else:
		for step: int in 6:
			for stream: int in 4: groups.append([stream*6+step])
	return {"groups":groups,"slots":slots,"representations":formats}

func service() -> void:
	await open_scene("res://experiments/service_plan/lab.tscn")
	await press(handle("Run")); await press(handle("Hint1")); await press(handle("PublicData"))
	await capture("service-public-data")
	await build_service(service_draft(true,1,["raw64","raw64","raw64","raw64"])); await press(handle("Run"))
	check(ui.unlocked == 1,"Grouped exact plan unlocks second contract")
	await capture("service-throughput")
	await press(handle("Task2")); await press(handle("Run"))
	check(not ui.status.text.begins_with("Meets") and not ui.status.text.begins_with("满足"),"Grouping violates first-response contract")
	await capture("service-latency-counterexample")
	await build_service(service_draft(false,4,["raw64","raw64","raw64","raw64"])); await press(handle("Run"))
	check(ui.unlocked == 2,"Interleaving and residency satisfy exact latency contract")
	await capture("service-latency")
	await press(handle("Task3"))
	await build_service(service_draft(false,4,["rle64","rle64","rle64","rle64"])); await press(handle("Run"))
	check(ui.active_trace.metrics.state_read_bytes+ui.active_trace.metrics.state_write_bytes > 320,"Uniform RLE exceeds final traffic contract")
	await capture("service-expansion-counterexample")
	await build_service(service_draft(false,4,["rle64","rle64","raw64","raw64"])); await press(handle("Run"))
	check(ui.active_trace.metrics.total_cycles == 1280 and ui.active_trace.metrics.max_error == 0.0,"Lossless mixed service has measured 1280 cycles")
	await tree_row(ui.tree,0); await capture("service-lossless")
	await build_service(service_draft(false,4,["raw8","raw8","raw8","raw8"])); await press(handle("Run"))
	check(ui.active_trace.metrics.max_error > 0.0 and ui.active_trace.metrics.max_error <= 0.02,"Alternative compact service has real bounded numerical error")
	await capture("service-approximate")

func _run() -> void:
	await prepare_window()
	var experiment: String = "representation_region"
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--experiment="): experiment = arg.trim_prefix("--experiment=")
	match experiment:
		"representation_region": await representation()
		"prediction": await prediction()
		"service_plan": await service()
	var file := FileAccess.open(evidence_root+"checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(observations,"\t"))
	print("PASS: known-objective candidate viewport" if failures.is_empty() else "FAIL: known-objective candidate viewport")
	quit(0 if failures.is_empty() else 1)
