extends RefCounted
## Exact typed value evidence for differential computation measurements.
## Objects expose every script variable, including complete event arrays.
## Output dictionary order and alias topology are normalized away. Separate
## retained-result tests check mutation, not arbitrary alias-graph equivalence.

static func freeze(value: Variant, depth: int = 0) -> Variant:
	if depth > 64:
		return {"@unsupported":"depth"}
	match typeof(value):
		TYPE_NIL,TYPE_BOOL,TYPE_STRING:
			return value
		TYPE_INT:
			# JSON numbers cannot preserve every signed 64-bit integer.
			return {"@int":str(value)}
		TYPE_FLOAT:
			var bytes := PackedByteArray()
			bytes.resize(8)
			bytes.encode_double(0,value)
			return {"@float64":bytes.hex_encode()}
		TYPE_STRING_NAME:
			return {"@string_name":str(value)}
		TYPE_DICTIONARY:
			var pairs: Array[Dictionary] = []
			for key: Variant in value:
				var frozen_key: Variant = freeze(key,depth+1)
				pairs.append({"key":frozen_key,"value":freeze(value[key],depth+1)})
			pairs.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
				return JSON.stringify(a.key,"",true,true) < JSON.stringify(b.key,"",true,true))
			return {"@dictionary":pairs,
				"key_type":_container_type(value.get_typed_key_builtin(),value.get_typed_key_class_name(),value.get_typed_key_script()),
				"value_type":_container_type(value.get_typed_value_builtin(),value.get_typed_value_class_name(),value.get_typed_value_script())}
		TYPE_ARRAY:
			var elements: Array = []
			for element: Variant in value: elements.append(freeze(element,depth+1))
			return {"@array":elements,
				"element_type":_container_type(value.get_typed_builtin(),value.get_typed_class_name(),value.get_typed_script())}
		TYPE_OBJECT:
			if value == null: return null
			var script: Script = value.get_script()
			if script == null:
				return {"@unsupported":value.get_class()}
			var fields: Dictionary = {}
			for property: Dictionary in value.get_property_list():
				if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
					fields[str(property.name)] = freeze(value.get(property.name),depth+1)
			return {"@script":script.resource_path,"fields":fields}
		TYPE_PACKED_BYTE_ARRAY,TYPE_PACKED_INT32_ARRAY,TYPE_PACKED_INT64_ARRAY,\
		TYPE_PACKED_FLOAT32_ARRAY,TYPE_PACKED_FLOAT64_ARRAY,TYPE_PACKED_STRING_ARRAY:
			var elements: Array = []
			for element: Variant in value: elements.append(freeze(element,depth+1))
			return {"@packed":type_string(typeof(value)),"values":elements}
		TYPE_VECTOR2,TYPE_VECTOR2I,TYPE_VECTOR3,TYPE_VECTOR3I,TYPE_VECTOR4,TYPE_VECTOR4I,\
		TYPE_RECT2,TYPE_RECT2I,TYPE_TRANSFORM2D,TYPE_TRANSFORM3D,TYPE_PLANE,TYPE_QUATERNION,\
		TYPE_AABB,TYPE_BASIS,TYPE_PROJECTION,TYPE_COLOR,TYPE_NODE_PATH,\
		TYPE_PACKED_VECTOR2_ARRAY,TYPE_PACKED_VECTOR3_ARRAY,TYPE_PACKED_VECTOR4_ARRAY,TYPE_PACKED_COLOR_ARRAY:
			return {"@value":type_string(typeof(value)),"bytes":var_to_bytes(value).hex_encode()}
		_:
			return {"@unsupported":type_string(typeof(value))}

static func _container_type(builtin: int, class_name_value: StringName, script: Variant) -> Dictionary:
	return {"builtin":builtin,"class":str(class_name_value),
		"script":script.resource_path if script is Script else ""}

static func supported(frozen: Variant) -> bool:
	if frozen is Dictionary:
		if frozen.has("@unsupported"): return false
		for child: Variant in frozen.values():
			if not supported(child): return false
	elif frozen is Array:
		for child: Variant in frozen:
			if not supported(child): return false
	return true

static func canonical(value: Variant) -> String:
	return JSON.stringify(freeze(value),"",true,true)
