class_name DigitalValue
extends RefCounted

const KNOWN: int = 0
const HIGH_Z: int = 1
const CONFLICT: int = 2

var width: int = 1
var value: int = 0
var state: int = KNOWN


func _init(p_width: int = 1, p_value: int = 0, p_state: int = KNOWN) -> void:
	width = clampi(p_width, 1, 32)
	state = p_state
	value = p_value & mask_for_width(width) if state == KNOWN else 0


static func known(p_width: int, p_value: int) -> DigitalValue:
	return DigitalValue.new(p_width, p_value, KNOWN)


static func low(p_width: int = 1) -> DigitalValue:
	return DigitalValue.new(p_width, 0, KNOWN)


static func high() -> DigitalValue:
	return DigitalValue.new(1, 1, KNOWN)


static func high_z(p_width: int = 1) -> DigitalValue:
	return DigitalValue.new(p_width, 0, HIGH_Z)


static func conflict(p_width: int = 1) -> DigitalValue:
	return DigitalValue.new(p_width, 0, CONFLICT)


static func from_variant(p_width: int, source: Variant) -> DigitalValue:
	if source is DigitalValue:
		var digital := source as DigitalValue
		if digital.width != p_width:
			return conflict(p_width)
		return digital.duplicate_value()
	if source is bool:
		return known(p_width, 1 if bool(source) else 0)
	if source is int or source is float:
		return known(p_width, int(source))
	return high_z(p_width)


static func resolve(drivers: Array[DigitalValue], p_width: int) -> DigitalValue:
	if drivers.is_empty():
		return low(p_width)
	var active_value: DigitalValue = null
	for driver: DigitalValue in drivers:
		if driver == null or driver.width != p_width or driver.state == CONFLICT:
			return conflict(p_width)
		if driver.state == HIGH_Z:
			continue
		if active_value == null:
			active_value = driver
		elif active_value.value != driver.value:
			return conflict(p_width)
	return high_z(p_width) if active_value == null else active_value.duplicate_value()


static func mask_for_width(p_width: int) -> int:
	var safe_width: int = clampi(p_width, 1, 32)
	if safe_width == 32:
		return 0xFFFFFFFF
	return (1 << safe_width) - 1


func is_known() -> bool:
	return state == KNOWN


func is_high_z() -> bool:
	return state == HIGH_Z


func is_conflict() -> bool:
	return state == CONFLICT


func bit() -> bool:
	return state == KNOWN and (value & 1) == 1


func duplicate_value() -> DigitalValue:
	return DigitalValue.new(width, value, state)


func equals(other: DigitalValue) -> bool:
	return other != null and width == other.width and value == other.value and state == other.state


func display_text() -> String:
	if state == HIGH_Z:
		return "Z"
	if state == CONFLICT:
		return "SHORT"
	if width == 1:
		return str(value)
	var digits: int = maxi(1, int(ceil(float(width) / 4.0)))
	return "0x" + ("%X" % value).pad_zeros(digits)


func canonical_signature() -> String:
	return "%d:%d:%d" % [width, state, value]


func to_dictionary() -> Dictionary:
	return {"width": width, "state": state, "value": value}
