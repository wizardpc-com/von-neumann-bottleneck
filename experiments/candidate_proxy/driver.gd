extends "res://experiments/candidate_input.gd"
## UI actuator; pure policies receive only the explicitly copied public dictionary.
const RepresentationPolicy = preload("res://experiments/candidate_proxy/representation_policy.gd")
const PredictionPolicy = preload("res://experiments/candidate_proxy/prediction_policy.gd")
const ServicePolicy = preload("res://experiments/candidate_proxy/service_policy.gd")
var journal: Array[Dictionary] = []
var outcomes: Array[Dictionary] = []

func observation(kind: String) -> Dictionary:
	var source: Dictionary = ui.public_observation()
	var keys: Array = []
	match kind:
		"representation_region": keys = ["mission","hint","assets","orders","plan","accepted","public_goals","machine"]
		"prediction": keys = ["mission","hint1","policy","control_ranges","observed_addresses","revealed_decisions","goal_met"]
		"service_plan": keys = ["mission","hint1","draft","formats","rules","public_data"]
	var out: Dictionary = {}
	for key_name: String in keys: out[key_name] = source.get(key_name)
	if kind == "prediction":
		out.completed_runs = []
		for record: Dictionary in source.completed_runs:
			if record.task != source.task: continue
			var metrics: Dictionary = record.metrics.duplicate(true)
			for key_name: String in ["accesses","decisions","outputs"]: metrics.erase(key_name)
			out.completed_runs.append({"policy":record.policy.duplicate(true),"metrics":metrics})
	elif kind == "representation_region":
		out.measured = []
		for record: Dictionary in source.measured:
			var runs: Array = []
			for entry: Dictionary in record.runs:
				var m: Dictionary = entry.metrics.duplicate(true)
				for key_name: String in ["spec","blocks","accesses","outputs","expected"]: m.erase(key_name)
				runs.append(m)
			out.measured.append({"plan":record.plan,"runs":runs,"accepted":record.accepted})
	else:
		out.slot_range = [int(ui.slots.min_value),int(ui.slots.max_value)]
		out.accepted = ui.status.text.begins_with("Meets current task") or ui.status.text.begins_with("满足当前任务")
		out.measured = []
		for record: Dictionary in source.measured:
			var m: Dictionary = record.metrics.duplicate(true)
			for key_name: String in ["reference","outputs","final_states","response_cycles"]: m.erase(key_name)
			out.measured.append(m)
	return out.duplicate(true)

func save_journal() -> void:
	var file := FileAccess.open(evidence_root+"unknown-answer.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"boundary":"public observation only; bounded authored heuristics, not human novice", "decisions":journal,"outcomes":outcomes},"\t"))

func run_domain(kind: String, scene: String, count: int) -> void:
	await open_scene(scene)
	for task_index: int in count:
		var task_button: Button = handle("Task"+str(task_index if kind != "service_plan" else task_index+1))
		if task_button.disabled:
			outcomes.append({"domain":kind,"task":task_index,"accepted":false,"stop":"Previous task remains locked after bounded policy stall; no unlock bypass."})
			save_journal(); break
		await press(task_button)
		var policy: RefCounted = RepresentationPolicy.new() if kind == "representation_region" else (PredictionPolicy.new() if kind == "prediction" else ServicePolicy.new())
		if kind == "prediction":
			await press(handle("Step")); await press(handle("Step"))
			var prefix: Dictionary = ui.public_observation()
			check(prefix.observed_addresses.size() == 2, "Step reveals exactly the observed prefix")
			await capture(kind+"-"+str(task_index)+"-prefix")
		for attempt: int in 10:
			var obs: Dictionary = observation(kind)
			var decision: Dictionary = policy.decide(obs)
			journal.append({"domain":kind,"task":task_index,"observation":obs,"decision":decision})
			save_journal(); print("PROXY ",kind," task",task_index," ",decision.action," ",decision.reason)
			if decision.action == "stop": break
			match decision.action:
				"hint1":
					await press(handle("Hint1"))
					if kind == "service_plan": await press(handle("PublicData"))
				"run": await press(handle("Run"))
				"try_plan": await build_partition(decision.plan); await press(handle("Run"))
				"try_policy": await set_prediction(decision.policy); await press(handle("Run"))
				"try_service": await build_service(decision.plan); await press(handle("Run"))
			await settle(8)
			if attempt == 0: await capture(kind+"-"+str(task_index)+"-baseline")
		var final_obs: Dictionary = observation(kind)
		outcomes.append({"domain":kind,"task":task_index,"accepted":bool(final_obs.get("accepted",final_obs.get("goal_met",false))),"observation":final_obs})
		await capture(kind+"-"+str(task_index)+"-stop"); save_journal()

func _run() -> void:
	await prepare_window()
	var requested: String = "representation_region"
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--experiment="): requested = argument.trim_prefix("--experiment=")
	match requested:
		"representation_region": await run_domain(requested,"res://experiments/representation_region/region.tscn",5)
		"prediction": await run_domain(requested,"res://experiments/prediction/lab.tscn",3)
		"service_plan": await run_domain(requested,"res://experiments/service_plan/lab.tscn",3)
	var file := FileAccess.open(evidence_root+"checks.json",FileAccess.WRITE); file.store_string(JSON.stringify(observations,"\t"))
	print("PASS: candidate proxy actuator; bounded outcomes ", outcomes.map(func(x: Dictionary) -> bool: return bool(x.accepted)) if failures.is_empty() else ["ACTUATOR FAILURE"])
	quit(0 if failures.is_empty() else 1)
