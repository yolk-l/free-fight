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


func deploy_monster_at(monster_id: StringName, global_position: Vector2) -> void:
	if monster_id == &"" or _hero == null or _monster_container == null:
		return
	var data := DataRegistry.get_monster(monster_id)
	if data == null:
		return
	var monster: Monster = MONSTER_SCENE.instantiate()
	_monster_container.add_child(monster)
	monster.global_position = global_position
	monster.setup_monster(data, _hero)
	if _battle_controller:
		_battle_controller.register_monster(monster)
	monster_deployed.emit(monster)
