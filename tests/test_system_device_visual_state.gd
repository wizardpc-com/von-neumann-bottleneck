extends SceneTree

const Surface = preload("res://src/system_lab/system_device_surface.gd")

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var surface := Surface.new()
	surface.configure(&"cpu")
	_assert(not surface.is_computing() and not surface.waiting, "Idle CPU must show no invented work or wait.")
	surface.show_activity(&"compute", 0.5, {"value": 19})
	_assert(surface.is_computing() and not surface.waiting, "A compute event must activate CPU computation.")
	for kind: StringName in [&"read_request", &"ram_read", &"read_data", &"write_request", &"write_data", &"ram_write"]:
		surface.show_activity(kind, 0.5, {"cpu_waiting": true, "index": 7})
		_assert(surface.waiting and not surface.is_computing(), "Memory latency must show a stationary wait rather than computation: %s" % kind)
	surface.show_activity(&"unrecognized", 0.5)
	_assert(not surface.is_computing() and not surface.waiting, "Unknown events must not invent CPU work.")
	surface.clear_activity()
	_assert(not surface.is_computing() and not surface.waiting, "Clearing playback must restore idle CPU.")

	surface.configure(&"ram")
	for kind: StringName in [&"ram_read", &"ram_write"]:
		var details: Dictionary = {"index": 11, "value": 197, "cpu_waiting": true}
		surface.show_activity(kind, 0.6, details)
		details["index"] = 2
		_assert(surface.active_memory_row() == 3 and not surface.waiting, "RAM must use its copied trace address; CPU waiting is not RAM state.")
		_assert(not surface.is_computing(), "RAM accesses must never become CPU computation.")
		surface.show_activity(kind, 0.6)
		_assert(surface.active_memory_row() == -1, "Missing addresses must not highlight guessed RAM cells.")
		surface.show_activity(kind, 0.6, {"index": -1})
		_assert(surface.active_memory_row() == -1, "Invalid addresses must remain unhighlighted.")
	for kind: StringName in [&"compute", &"read_request", &"write_request", &"read_data", &"write_data", &"unrecognized"]:
		surface.show_activity(kind, 0.6, {"index": 11})
		_assert(surface.active_memory_row() == -1, "Only actual RAM events may highlight memory: %s" % kind)
	surface.clear_activity()
	_assert(surface.active_memory_row() == -1, "Cleared RAM playback must leave no active row.")

	surface.configure(&"bus")
	surface.set_bus_bandwidth(4)
	for kind: StringName in [&"read_request", &"write_request", &"unrecognized"]:
		surface.show_activity(kind, 0.8, {"value": 197, "bits_per_cycle": 1, "segments": 8})
		var idle: Dictionary = surface.bus_presentation()
		_assert(not idle["transferring"] and idle["group"] == -1 and idle["width"] == 4, "Requests and unknown events must retain idle capacity without a payload group.")
	for kind: StringName in [&"read_data", &"write_data"]:
		for progress: float in [0.0, 0.5, 1.0]:
			surface.show_activity(kind, progress, {"value": 197, "bits_per_cycle": 2, "segments": 4})
			var payload: Dictionary = surface.bus_presentation()
			_assert(payload["transferring"] and payload["value"] == 197 and payload["width"] == 2 and payload["groups"] == 4, "Bus payload must preserve authoritative word, width and duration in both directions.")
			_assert(payload["group"] >= 0 and payload["group"] < 4, "Playback endpoints must stay inside the real transfer groups.")
	surface.clear_activity()
	var cleared: Dictionary = surface.bus_presentation()
	_assert(not cleared["transferring"] and cleared["group"] == -1 and cleared["width"] == 4, "Clearing bus playback must restore selected hardware capacity.")
	surface.free()
	if failures.is_empty():
		print("PASS: test_system_device_visual_state")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
