class_name LogicSignal
extends RefCounted

const LOW: int = 0
const HIGH: int = 1
const HIGH_Z: int = 2
const CONFLICT: int = 3


static func from_bool(value: bool) -> int:
	return HIGH if value else LOW


static func is_binary(state: int) -> bool:
	return state == LOW or state == HIGH


static func to_bool(state: int) -> bool:
	return state == HIGH


static func has_binary_conflict(states: Array[int]) -> bool:
	var saw_low: bool = false
	var saw_high: bool = false
	for state: int in states:
		saw_low = saw_low or state == LOW
		saw_high = saw_high or state == HIGH
	return saw_low and saw_high


static func resolve_driver_states(states: Array[int]) -> int:
	if states.is_empty():
		return LOW
	var saw_low: bool = false
	var saw_high: bool = false
	for state: int in states:
		if state == CONFLICT:
			return CONFLICT
		saw_low = saw_low or state == LOW
		saw_high = saw_high or state == HIGH
	if saw_low and saw_high:
		return CONFLICT
	if saw_high:
		return HIGH
	if saw_low:
		return LOW
	return HIGH_Z


static func evaluate_gate(kind: StringName, inputs: Array[int]) -> int:
	for state: int in inputs:
		if state == CONFLICT:
			return CONFLICT
	match kind:
		&"and":
			if inputs.has(LOW):
				return LOW
			return HIGH if not inputs.is_empty() and not inputs.has(HIGH_Z) else HIGH_Z
		&"or":
			if inputs.has(HIGH):
				return HIGH
			return LOW if not inputs.is_empty() and not inputs.has(HIGH_Z) else HIGH_Z
		&"xor":
			if inputs.is_empty() or inputs.has(HIGH_Z):
				return HIGH_Z
			var high_count: int = 0
			for state: int in inputs:
				high_count += 1 if state == HIGH else 0
			return HIGH if high_count % 2 == 1 else LOW
		&"not":
			if inputs.is_empty() or inputs[0] == HIGH_Z:
				return HIGH_Z
			return LOW if inputs[0] == HIGH else HIGH
		&"output", &"lamp", &"junction":
			return inputs[0] if not inputs.is_empty() else HIGH_Z
	return HIGH_Z


static func label(state: int) -> String:
	match state:
		LOW: return "0"
		HIGH: return "1"
		HIGH_Z: return "Z"
		CONFLICT: return "SHORT"
	return "?"
