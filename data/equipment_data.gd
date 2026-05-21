class_name EquipmentData
extends Resource

enum SlotType { WEAPON, ARMOR }

@export var id: StringName = &""
@export var display_name: String = ""
@export var slot_type: SlotType = SlotType.WEAPON
@export var stat_bonus: CombatStats


func get_slot_key() -> StringName:
	return &"weapon" if slot_type == SlotType.WEAPON else &"armor"
