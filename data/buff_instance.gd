class_name BuffInstance
extends RefCounted

var def: BuffDef
var stacks: int = 1
var remaining_sec: float = 0.0
var remaining_count: int = 0
var source_id: StringName = &""


static func create(buff_def: BuffDef, source: StringName = &"") -> BuffInstance:
	var inst := BuffInstance.new()
	inst.def = buff_def
	inst.stacks = 1
	inst.source_id = source
	match buff_def.duration_type:
		BuffDef.DurationType.TIMED:
			inst.remaining_sec = buff_def.duration_sec
		BuffDef.DurationType.COUNTED:
			inst.remaining_count = buff_def.duration_count
	return inst


func get_modifier(key: StringName) -> float:
	return def.modifiers.get(key, 0.0) * stacks


func is_expired() -> bool:
	match def.duration_type:
		BuffDef.DurationType.TIMED:
			return remaining_sec <= 0.0
		BuffDef.DurationType.COUNTED:
			return remaining_count <= 0
	return false
