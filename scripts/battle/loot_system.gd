class_name LootSystem
extends Node


func setup() -> void:
	pass


func on_monster_died(monster: Monster) -> void:
	if monster.data != null:
		GameManager.unlock_monster(monster.data.id)
