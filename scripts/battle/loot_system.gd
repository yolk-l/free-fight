class_name LootSystem
extends Node

var _backpack = null
var _loot_table: LootTable = null


func setup(backpack, loot_table: LootTable) -> void:
	_backpack = backpack
	_loot_table = loot_table


func on_monster_died(monster: Monster) -> void:
	if monster.data != null:
		GameManager.unlock_monster(monster.data.id)
	if _loot_table == null or _backpack == null:
		return
	var entry := _loot_table.roll()
	if entry == null or entry.drop_type == LootEntry.DropType.NOTHING:
		return
	if entry.drop_type == LootEntry.DropType.EQUIPMENT:
		_generate_equipment(entry.equipment_id)


func _generate_equipment(specific_id: StringName = &"") -> void:
	var equip_id := specific_id
	if equip_id == &"":
		var ids := DataRegistry.get_all_equipment_ids()
		if ids.is_empty():
			return
		equip_id = ids[randi() % ids.size()]
	var data := DataRegistry.get_equipment(equip_id)
	if data == null:
		return
	var quality := EquipmentQuality.roll_quality()
	var affix := EquipmentAffix.roll_affix(data.slot_type)
	var instance = EquipmentInstance.create(data, quality, affix)
	if _backpack.add_item(instance):
		GameManager.unlock_equipment(equip_id)
