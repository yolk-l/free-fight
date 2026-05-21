class_name EquipmentInventory
extends Node

signal equipment_changed

var slots: Dictionary = {
	&"weapon": null,
	&"armor": null,
}


func equip(item: EquipmentData) -> bool:
	if item == null:
		return false
	var key := item.get_slot_key()
	if not slots.has(key):
		return false
	slots[key] = item
	equipment_changed.emit()
	return true


func get_stat_bonus() -> CombatStats:
	var bonus := CombatStats.zero_bonus()
	for item in slots.values():
		if item is EquipmentData and item.stat_bonus != null:
			bonus.attack += item.stat_bonus.attack
			bonus.max_hp += item.stat_bonus.max_hp
			bonus.defense += item.stat_bonus.defense
			bonus.attack_speed += item.stat_bonus.attack_speed
	return bonus


func get_slot_item(slot_key: StringName) -> EquipmentData:
	return slots.get(slot_key) as EquipmentData
