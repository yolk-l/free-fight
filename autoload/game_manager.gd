extends Node

const MAIN_MENU_SCENE := "res://scenes/main_menu.tscn"
const BATTLE_SCENE := "res://scenes/battle/dungeon_battle_scene.tscn"
const CODEX_SCENE := "res://scenes/codex/codex_scene.tscn"

var codex_unlocked_monsters: Array[StringName] = []


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func go_to_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)


func go_to_codex() -> void:
	get_tree().change_scene_to_file(CODEX_SCENE)


func unlock_monster(monster_id: StringName) -> void:
	if monster_id not in codex_unlocked_monsters:
		codex_unlocked_monsters.append(monster_id)


func reset_codex_for_debug() -> void:
	codex_unlocked_monsters.clear()
