class_name LootSystem
extends Node

const LOOT_SCENE := preload("res://scenes/battle/loot_drop.tscn")

const CHANCE_EQUIPMENT := 0.3
const CHANCE_CARD := 0.5

var _hero: Hero = null
var _card_hand: CardHand = null
var _loot_container: Node2D = null


func setup(hero: Hero, card_hand: CardHand, loot_container: Node2D) -> void:
	_hero = hero
	_card_hand = card_hand
	_loot_container = loot_container


func on_monster_died(monster: Monster) -> void:
	if monster.data != null:
		GameManager.unlock_monster(monster.data.id)
	var roll := randf()
	if roll < CHANCE_EQUIPMENT:
		_spawn_equipment(monster.global_position)
	elif roll < CHANCE_EQUIPMENT + CHANCE_CARD:
		_spawn_card(monster.global_position, monster.data.id if monster.data else DataRegistry.get_random_monster_id())


func _spawn_equipment(pos: Vector2) -> void:
	var ids := DataRegistry.get_all_equipment_ids()
	if ids.is_empty():
		return
	var equip_id: StringName = ids[randi() % ids.size()]
	var drop: LootDrop = LOOT_SCENE.instantiate()
	_loot_container.add_child(drop)
	drop.global_position = pos
	drop.setup_equipment(equip_id)
	drop.picked_up.connect(_on_loot_picked)


func _spawn_card(pos: Vector2, monster_id: StringName) -> void:
	var drop: LootDrop = LOOT_SCENE.instantiate()
	_loot_container.add_child(drop)
	drop.global_position = pos
	drop.setup_card(monster_id)
	drop.picked_up.connect(_on_loot_picked)


func _on_loot_picked(drop: LootDrop) -> void:
	if drop.drop_type == LootDrop.DropType.EQUIPMENT:
		var equip := DataRegistry.get_equipment(drop.equipment_id)
		if equip and _hero and _hero.inventory:
			if _hero.inventory.equip(equip):
				GameManager.unlock_equipment(equip.id)
	elif drop.drop_type == LootDrop.DropType.CARD and _card_hand:
		_card_hand.add_card(drop.monster_card_id)
