class_name CampaignBranchDefinition
extends RefCounted

var id: StringName
var title_key: StringName
var order: int


func _init(
		p_id: StringName,
		p_title_key: StringName,
		p_order: int
	) -> void:
	id = p_id
	title_key = p_title_key
	order = p_order


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if id.is_empty():
		errors.append("Campaign branch id must not be empty.")
	if title_key.is_empty():
		errors.append("Campaign branch %s must declare a title localization key." % id)
	if order < 0:
		errors.append("Campaign branch %s must use a non-negative order." % id)
	return errors
