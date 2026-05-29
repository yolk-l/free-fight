class_name DeployManager
extends Node

signal monster_deployed(monster: Monster)

const MONSTER_SCENE := preload("res://scenes/battle/monster_unit.tscn")

var _hero: Hero = null
var _monster_container: Node2D = null
var _battle_controller: Node = null


func setup(hero: Hero, monster_container: Node2D, controller: Node) -> void:
	_hero = hero
	_monster_container = monster_container
	_battle_controller = controller


func deploy_monster_at(monster_id: StringName, pos: Vector2) -> Monster:
	if monster_id == &"" or _hero == null or _monster_container == null:
		return null
	var data := DataRegistry.get_monster(monster_id)
	if data == null:
		return null
	var monster: Monster = MONSTER_SCENE.instantiate()
	_monster_container.add_child(monster)
	monster.global_position = pos
	monster.setup_monster(data, _hero)
	if RunManager.in_run:
		var mult := RunManager.get_difficulty_multiplier()
		if mult > 1.0 and monster.base_stats:
			monster.base_stats.attack = int(monster.base_stats.attack * mult)
			monster.base_stats.hp = int(monster.base_stats.hp * mult)
			monster.base_stats.max_hp = int(monster.base_stats.max_hp * mult)
			monster._refresh_ui()
	if _battle_controller:
		_battle_controller.register_monster(monster)
	monster_deployed.emit(monster)
	return monster
