class_name CardPool
extends Resource

@export var entries: Array[CardPoolEntry] = []


func pick_random() -> StringName:
	if entries.is_empty():
		return &""
	var total_weight := 0.0
	for entry in entries:
		total_weight += entry.weight
	if total_weight <= 0.0:
		return &""
	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in entries:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry.monster_id
	return entries[entries.size() - 1].monster_id
