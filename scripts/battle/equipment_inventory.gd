class_name EquipmentInventory
extends Node

signal equipment_changed

var slots: Dictionary = {
	&"weapon": null,
	&"armor": null,
}


func equip(instance) -> bool:
	if instance == null or instance.base_data == null:
		return false
	var key = instance.get_slot_key()
	if not slots.has(key):
		return false
	slots[key] = instance
	equipment_changed.emit()
	return true


func get_stat_bonus() -> CombatStats:
	var bonus := CombatStats.zero_bonus()
	for item in slots.values():
		if item != null:
			var item_bonus = item.get_stat_bonus()
			bonus.attack += item_bonus.attack
			bonus.max_hp += item_bonus.max_hp
			bonus.defense += item_bonus.defense
			bonus.attack_speed += item_bonus.attack_speed
	return bonus


func get_slot_item(slot_key: StringName):
	return slots.get(slot_key)
