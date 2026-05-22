class_name LootEntry
extends Resource

enum DropType { EQUIPMENT, NOTHING }

@export var drop_type: DropType = DropType.NOTHING
@export var weight: float = 1.0
@export var equipment_id: StringName = &""
