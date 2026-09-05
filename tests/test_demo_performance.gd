extends SceneTree

const PerformanceTask = preload("res://src/demo/demo_performance.gd")
var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var cpu := PerformanceTask.initial("d1_cpu")
	var base := PerformanceTask.run("d1_cpu", 0, cpu)
	cpu["cpu"] = "cpu_fast"
	var faster := PerformanceTask.run("d1_cpu", 0, cpu)
	check(base["metrics"]["total_cycles"] == 158, "CPU baseline remains 158 cycles.")
	check(faster["complete"] and faster["metrics"]["total_cycles"] == 134, "Faster CPU reaches 134 cycles.")
	check(base["metrics"]["wait_cycles"] == faster["metrics"]["wait_cycles"], "CPU replacement leaves wait unchanged.")
	check(base["identity"] == faster["identity"], "Comparison binds identical task, data and initial state.")
	cpu["ram"] = "ram_fast"
	check(not PerformanceTask.run("d1_cpu", 0, cpu)["valid"], "Locked hardware cannot enter a comparison.")
	var order := PerformanceTask.initial("d2_order")
	base = PerformanceTask.run("d2_order", 0, order)
	check(base["metrics"]["total_cycles"] == 321 and not base["complete"], "Ineffective cache reference is real.")
	order["source"] = PerformanceTask.ROW_SOURCE
	var row := PerformanceTask.run("d2_order", 0, order)
	check(row["complete"] and row["metrics"]["total_cycles"] == 105, "Changed access order reaches 105 cycles.")
	check(row["metrics"]["ram_bytes_transferred"] == 64, "Repair fetches exactly 64 bytes.")
	check(row["signature"] == PerformanceTask.run("d2_order", 0, order)["signature"], "Receipt replay is deterministic.")
	order["source"] = PerformanceTask.ROW_SOURCE.replace("acc", "total").replace("row", "i").replace("col", "j")
	check(PerformanceTask.run("d2_order", 0, order)["complete"], "Equivalent identifiers are accepted by behavior.")
	order["source"] = PerformanceTask.ROW_SOURCE.replace("store(OUT[0], acc)", "answer = 88\nstore(OUT[0], answer)")
	check(not PerformanceTask.run("d2_order", 0, order)["passed"], "A constant matching the example fails independent inputs.")
	order["source"] = PerformanceTask.ROW_SOURCE.replace("        acc += load(A[row][col])", "        acc += load(A[row][col])\n        discarded = load(A[row][col])")
	check(not PerformanceTask.run("d2_order", 0, order)["passed"], "Repeated reads violate the published workload.")
	for task: String in ["d1_upgrade", "d2_cache", "d2_group", "d2_final"]:
		for stage: int in range(2 if task == "d1_upgrade" else 1):
			print(task, " stage=", stage, " baseline=", PerformanceTask.baseline(task, stage)["metrics"])
	var calibration: Array[Dictionary] = []
	for stage: int in range(2):
		var winners: Array[String] = []
		for cpu_id: String in ["cpu_eco", "cpu_balanced", "cpu_fast"]:
			for ram_id: String in ["ram_slow", "ram_balanced", "ram_fast"]:
				for bus_id: String in ["bus_2", "bus_4", "bus_8"]:
					var design := PerformanceTask.initial("d1_upgrade", stage)
					design.merge({"cpu": cpu_id, "ram": ram_id, "bus": bus_id}, true)
					var run := PerformanceTask.run("d1_upgrade", stage, design)
					if run["valid"]:
						calibration.append({"task": "upgrade", "stage": stage, "design": design, "metrics": run["metrics"], "complete": run["complete"]})
						if run["complete"]:
							winners.append(ram_id if stage == 0 else bus_id)
		check(winners == (["ram_fast"] if stage == 0 else ["bus_8"]), "Each upgrade scenario has a distinct useful part under the one-change constraint.")
	var winning_costs: Array[int] = []
	for source: String in [PerformanceTask.ROW_SOURCE, PerformanceTask.COLUMN_SOURCE]:
		for cache: int in [1, 2, 4]:
			for group: int in [0, 1, 2, 4]:
				var design := PerformanceTask.initial("d2_final")
				design.merge({"source": source, "cache": cache, "group": group}, true)
				var run := PerformanceTask.run("d2_final", 0, design)
				check(run["passed"], "All 24 enumerated legal final schedules preserve outputs and work.")
				calibration.append({"task": "final", "design": design, "metrics": run["metrics"], "complete": run["complete"]})
				if run["complete"] and int(run["metrics"]["hardware_cost"]) not in winning_costs:
					winning_costs.append(int(run["metrics"]["hardware_cost"]))
	check(4 in winning_costs and 13 in winning_costs, "Final task has both hardware and low-cost software solutions.")
	var output := FileAccess.open("res://.godot/redesign/calibration.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(calibration, "\t"))
	output.close()
	if failures.is_empty():
		print("PASS: demo CPU reversal, cache repair, deterministic receipts and workload authority")
	quit(0 if failures.is_empty() else 1)
