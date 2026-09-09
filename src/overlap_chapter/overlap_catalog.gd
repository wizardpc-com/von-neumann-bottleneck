class_name OverlapCatalog
extends RefCounted

const Simulator = preload("res://src/overlap_chapter/overlap_simulator.gd")
const IDS: Array[String] = ["arrival", "buffers", "backpressure", "prefetch", "distance", "synthesis"]
const DEPS := {"arrival": [], "buffers": ["arrival"], "backpressure": ["buffers"],
	"prefetch": ["arrival"], "distance": ["prefetch"], "synthesis": ["backpressure", "distance"]}
const BUFFER_COMMANDS := ["fetch", "ready", "consume", "idle", "free", "tick"]
const CACHE_COMMANDS := ["prefetch", "read", "idle", "tick"]


static func unlocked(id: String, completed: Dictionary, chapter_ready: bool, test: bool = false) -> bool:
	if not IDS.has(id): return false
	if test: return true
	if not chapter_ready: return false
	for dependency: String in DEPS[id]:
		if not completed.has(dependency): return false
	return true


static func cases(id: String) -> Array[Dictionary]:
	var base: Dictionary = {"name": "standard", "values": [3, 7, 2, 9], "compute": [4, 4, 4, 4],
		"transfer": 6, "budget": 2, "target": 28, "work": 0, "commands": BUFFER_COMMANDS}
	match id:
		"arrival":
			base.merge({"values": [3], "compute": [4], "budget": 1, "work": 4,
				"target": 10, "commands": ["fetch", "ready", "consume", "idle", "work"]}, true)
		"backpressure":
			base.merge({"compute": [9, 2, 8, 3], "transfer": 4, "target": 28}, true)
		"prefetch":
			base.merge({"budget": 1, "commands": CACHE_COMMANDS}, true)
		"distance":
			base.merge({"compute": [10, 2, 9, 3], "transfer": 4, "target": 30,
				"budget": 1, "commands": CACHE_COMMANDS}, true)
		"synthesis":
			base.merge({"budget": 2, "commands": BUFFER_COMMANDS + CACHE_COMMANDS}, true)
	var result: Array[Dictionary] = [base]
	if id == "backpressure":
		var second: Dictionary = base.duplicate(true)
		second.merge({"name": "changing", "values": [0, 15, 1, 8], "compute": [2, 10, 3, 7], "target": 32}, true)
		result.append(second)
	if id == "synthesis":
		var bandwidth: Dictionary = base.duplicate(true)
		bandwidth.merge({"name": "bandwidth", "values": [9, 1, 8, 0], "compute": [1, 1, 1, 1], "transfer": 8, "target": 33}, true)
		result.append(bandwidth)
	return result


static func terminal_board() -> Dictionary:
	return {"nodes": {"TRANSFER": {"kind": "transfer", "x": 60, "y": 120},
		"COMPUTE": {"kind": "compute", "x": 840, "y": 120}}, "wires": []}


static func buffer_board(count: int) -> Dictionary:
	var board: Dictionary = terminal_board()
	for index: int in range(count):
		var id: String = String.chr(65 + index)
		board.nodes[id] = {"kind": "buffer", "x": 380, "y": 40 + index * 210}
		board.wires.append_array([["TRANSFER", 0, id, 0], [id, 0, "COMPUTE", 0],
			[id, 1, "COMPUTE", 1], [id, 2, "TRANSFER", 0]])
	return board


static func cache_board(capacity: int = 1) -> Dictionary:
	var board: Dictionary = terminal_board()
	board.nodes.CACHE = {"kind": "cache", "capacity": capacity, "x": 400, "y": 160}
	board.wires = [["TRANSFER", 0, "CACHE", 0], ["CACHE", 0, "COMPUTE", 0]]
	return board


static func seed(id: String) -> Dictionary:
	match id:
		"arrival": return buffer_board(1)
		"backpressure": return buffer_board(2)
		"prefetch", "distance": return cache_board()
	return terminal_board()


static func starter(id: String) -> String:
	match id:
		"arrival": return "# 0 = first batch / 第一批\nfetch A 0\nconsume A\nidle\n"
		"buffers": return serial_program()
		"backpressure": return buffer_program().replace("free A", "tick 4").replace("free B", "tick 4")
		"prefetch": return "read 0\nidle\nread 1\nidle\nread 2\nidle\nread 3\nidle\n"
		"distance": return "prefetch 0\nprefetch 1\nprefetch 2\nprefetch 3\nread 0\nidle\nread 1\nidle\nread 2\nidle\nread 3\nidle\n"
	return "# Choose buffers or Cache / 自己选件与安排请求\n"


static func serial_program() -> String:
	var result: String = ""
	for batch: int in range(4): result += "fetch A %d\nready A\nconsume A\nidle\n" % batch
	return result


static func buffer_program() -> String:
	return "fetch A 0\nfetch B 1\nready A\nconsume A\nfree A\nfetch A 2\nready B\nidle\nconsume B\nfree B\nfetch B 3\nready A\nidle\nconsume A\nready B\nidle\nconsume B\nidle\n"


static func cache_program() -> String:
	return "prefetch 0\nprefetch 1\nread 0\nidle\nprefetch 2\nread 1\nidle\nprefetch 3\nread 2\nidle\nread 3\nidle\n"


static func reference_solution(id: String) -> Dictionary:
	if id == "arrival": return {"board": buffer_board(1), "program": "fetch A 0\nwork 4\nready A\nconsume A\nidle\n"}
	if id in ["prefetch", "distance"]: return {"board": cache_board(), "program": cache_program()}
	return {"board": buffer_board(2), "program": buffer_program()}


static func evaluate(id: String, board: Dictionary, program: String) -> Dictionary:
	var runs: Array[SimulationTrace] = []
	var passed: bool = IDS.has(id)
	if not passed: return {"passed": false, "runs": runs}
	for workload: Dictionary in cases(id):
		var trace: SimulationTrace = Simulator.new().run(program, board, workload)
		trace.test_name = String(workload.name)
		runs.append(trace)
		passed = passed and trace.passed and int(trace.metrics.total_cycles) <= int(workload.target)
	return {"passed": passed, "runs": runs}
