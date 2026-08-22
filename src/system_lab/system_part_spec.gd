class_name SystemPartSpec
extends RefCounted

const KIND_CPU: StringName = &"cpu"
const KIND_RAM: StringName = &"ram"
const KIND_BUS: StringName = &"bus"
const VALID_KINDS: Array[StringName] = [KIND_CPU, KIND_RAM, KIND_BUS]

var id: StringName
var kind: StringName
var display_name: String
var word_bits: int = 8
var compute_cycles: int = 0
var access_cycles: int = 0
var bandwidth_bits_per_cycle: int = 0
var hardware_cost: int = 0
var source_signature: String = ""
var metadata: Dictionary = {}


func _init(
		p_id: StringName = &"",
		p_kind: StringName = &"",
		p_display_name: String = "",
		p_hardware_cost: int = 0,
		p_source_signature: String = "",
		p_metadata: Dictionary = {}
	) -> void:
	id = p_id
	kind = p_kind
	display_name = p_display_name
	hardware_cost = p_hardware_cost
	source_signature = p_source_signature
	metadata = p_metadata.duplicate(true)
	compute_cycles = int(metadata.get("compute_cycles", 0))
	access_cycles = int(metadata.get("access_cycles", 0))
	bandwidth_bits_per_cycle = int(metadata.get("bandwidth_bits_per_cycle", 0))
	word_bits = int(metadata.get("word_bits", 8))


func duplicate_spec() -> SystemPartSpec:
	return SystemPartSpec.new(
		id, kind, display_name, hardware_cost, source_signature, metadata
	)


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("System part id must not be empty.")
	if kind not in VALID_KINDS:
		errors.append("System part %s has unknown kind %s." % [id, kind])
	if word_bits != 8:
		errors.append("System part %s must expose the chapter's 8-bit interface." % id)
	if hardware_cost <= 0:
		errors.append("System part %s must have positive hardware cost." % id)
	match kind:
		KIND_CPU:
			if compute_cycles <= 0:
				errors.append("CPU %s must have positive compute cycles." % id)
		KIND_RAM:
			if access_cycles <= 0:
				errors.append("RAM %s must have positive access cycles." % id)
		KIND_BUS:
			if bandwidth_bits_per_cycle not in [2, 4, 8]:
				errors.append("Bus %s must use 2, 4, or 8 bits per cycle." % id)
	return errors


func canonical_signature() -> String:
	return JSON.stringify({
		"id": String(id),
		"kind": String(kind),
		"word_bits": word_bits,
		"compute_cycles": compute_cycles,
		"access_cycles": access_cycles,
		"bandwidth_bits_per_cycle": bandwidth_bits_per_cycle,
		"hardware_cost": hardware_cost,
		"source_signature": source_signature,
		"metadata": metadata,
	})
