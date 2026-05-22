class_name LootTable
extends Resource

@export var entries: Array[LootEntry] = []


func roll() -> LootEntry:
	if entries.is_empty():
		return null
	var total_weight := 0.0
	for entry in entries:
		total_weight += entry.weight
	if total_weight <= 0.0:
		return null
	var roll := randf() * total_weight
	var cumulative := 0.0
	for entry in entries:
		cumulative += entry.weight
		if roll <= cumulative:
			return entry
	return entries[entries.size() - 1]
