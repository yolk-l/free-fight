class_name BuffContainer
extends Node

signal buffs_changed

var _buffs: Array[BuffInstance] = []


func add_buff(def: BuffDef, source_id: StringName = &"") -> void:
	if def == null:
		return
	var existing := _find_buff_by_id_and_source(def.id, source_id)
	if existing != null:
		if existing.stacks < def.max_stacks:
			existing.stacks += 1
			_refresh_duration(existing)
			buffs_changed.emit()
		elif def.duration_type == BuffDef.DurationType.TIMED:
			existing.remaining_sec = def.duration_sec
			buffs_changed.emit()
		elif def.duration_type == BuffDef.DurationType.COUNTED:
			existing.remaining_count = def.duration_count
			buffs_changed.emit()
		return
	var inst := BuffInstance.create(def, source_id)
	_buffs.append(inst)
	buffs_changed.emit()


func remove_buff_by_source(source_id: StringName) -> void:
	if source_id == &"":
		return
	var changed := false
	var i := _buffs.size() - 1
	while i >= 0:
		if _buffs[i].source_id == source_id:
			_buffs.remove_at(i)
			changed = true
		i -= 1
	if changed:
		buffs_changed.emit()


func remove_buff_by_id(buff_id: StringName) -> void:
	if buff_id == &"":
		return
	var changed := false
	var i := _buffs.size() - 1
	while i >= 0:
		if _buffs[i].def.id == buff_id:
			_buffs.remove_at(i)
			changed = true
		i -= 1
	if changed:
		buffs_changed.emit()


func tick(delta: float) -> void:
	var changed := false
	var i := _buffs.size() - 1
	while i >= 0:
		var inst := _buffs[i]
		if inst.def.duration_type == BuffDef.DurationType.TIMED:
			inst.remaining_sec -= delta
			if inst.remaining_sec <= 0.0:
				_buffs.remove_at(i)
				changed = true
		i -= 1
	if changed:
		buffs_changed.emit()


func notify_event(event: StringName) -> void:
	if event == &"":
		return
	var changed := false
	var i := _buffs.size() - 1
	while i >= 0:
		var inst := _buffs[i]
		if inst.def.duration_type == BuffDef.DurationType.COUNTED and inst.def.trigger_event == event:
			inst.remaining_count -= 1
			if inst.remaining_count <= 0:
				_buffs.remove_at(i)
				changed = true
		i -= 1
	if changed:
		buffs_changed.emit()


func get_modifier_sum(key: StringName) -> float:
	var total := 0.0
	for inst in _buffs:
		total += inst.get_modifier(key)
	return total


func get_all_modifiers() -> Dictionary:
	var result := {}
	for inst in _buffs:
		for key in inst.def.modifiers.keys():
			var val: float = inst.get_modifier(StringName(key))
			if result.has(key):
				result[key] += val
			else:
				result[key] = val
	return result


func has_buff(buff_id: StringName) -> bool:
	for inst in _buffs:
		if inst.def.id == buff_id:
			return true
	return false


func get_bleed_per_sec() -> float:
	return get_modifier_sum(&"bleed_per_sec")


func get_buffs() -> Array[BuffInstance]:
	return _buffs


func clear_all() -> void:
	if _buffs.is_empty():
		return
	_buffs.clear()
	buffs_changed.emit()


func _find_buff_by_id_and_source(buff_id: StringName, source_id: StringName) -> BuffInstance:
	for inst in _buffs:
		if inst.def.id == buff_id and inst.source_id == source_id:
			return inst
	return null


func _refresh_duration(inst: BuffInstance) -> void:
	match inst.def.duration_type:
		BuffDef.DurationType.TIMED:
			inst.remaining_sec = inst.def.duration_sec
		BuffDef.DurationType.COUNTED:
			inst.remaining_count = inst.def.duration_count
