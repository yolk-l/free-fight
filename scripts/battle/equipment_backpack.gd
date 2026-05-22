class_name EquipmentBackpack
extends Node

signal backpack_changed

const MAX_SLOTS := 8

var items: Array = []


func add_item(instance) -> bool:
	if instance == null:
		return false
	if items.size() >= MAX_SLOTS:
		items.remove_at(0)
	items.append(instance)
	backpack_changed.emit()
	return true


func remove_item(index: int):
	if index < 0 or index >= items.size():
		return null
	var item = items[index]
	items.remove_at(index)
	backpack_changed.emit()
	return item


func is_full() -> bool:
	return items.size() >= MAX_SLOTS


func get_item(index: int):
	if index < 0 or index >= items.size():
		return null
	return items[index]


func get_count() -> int:
	return items.size()
