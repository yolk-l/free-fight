class_name ComboTracker
extends Node

signal pattern_triggered(pattern_kind: int, payload: Dictionary)

enum PatternKind {
	ECO_SPEC,       # 4s 内同种连铺 3 只
	DUO_COMBO,      # 异种联动 (last 2 deploy ids matches a duo recipe)
	DENSE_DEPLOY,   # 4s 内部署 4 只（任意种）
}

const DUO_RECIPES := [
	{"seq": [&"wolf", &"bat"],         "name": "暗夜突袭", "effect": "hero_aspd",    "value": 0.3, "kill_count": 2},
	{"seq": [&"goblin", &"slime"],     "name": "暴怒之欲", "effect": "hero_attack",  "value": 3.0, "kill_count": 2},
	{"seq": [&"gargoyle", &"skeleton"],"name": "不朽壁垒", "effect": "hero_defense", "value": 3.0, "kill_count": 2},
	{"seq": [&"viper", &"slime"],      "name": "毒沼蔓延", "effect": "poison_all",   "value": 1},
	{"seq": [&"skeleton", &"viper"],   "name": "亡者瘟疫", "effect": "summon_aura",  "value": 0,   "duration": 4.0},
]

var _deploy_history: Array[Dictionary] = []


func setup(_legacy_recipes = []) -> void:
	# v5: legacy recipes ignored; patterns are hard-coded above.
	pass


func on_monster_deployed(monster_id: StringName, monster: Monster) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_deploy_history.append({"id": monster_id, "time": now, "monster": monster})
	_prune_expired(now)
	_check_patterns(monster)


func _prune_expired(now: float) -> void:
	while not _deploy_history.is_empty():
		if now - _deploy_history[0]["time"] > GameConfig.COMBO_WINDOW_SEC:
			_deploy_history.remove_at(0)
		else:
			break


func _check_patterns(last_monster: Monster) -> void:
	# Dense deploy: 4 deploys within window.
	if _deploy_history.size() >= 4:
		pattern_triggered.emit(PatternKind.DENSE_DEPLOY, {"name": "密集部署"})
		_deploy_history.clear()
		return
	# Eco spec: last 3 same monster id.
	if _deploy_history.size() >= 3:
		var last_id = _deploy_history[-1]["id"]
		if _deploy_history[-2]["id"] == last_id and _deploy_history[-3]["id"] == last_id:
			pattern_triggered.emit(PatternKind.ECO_SPEC, {"monster_id": last_id, "name": "生态专精"})
			_deploy_history.clear()
			return
	# Duo combos: last two deploys form a known pair.
	if _deploy_history.size() >= 2:
		var seq: Array = [_deploy_history[-2]["id"], _deploy_history[-1]["id"]]
		for recipe in DUO_RECIPES:
			if recipe["seq"] == seq:
				var payload: Dictionary = recipe.duplicate()
				payload["last_monster"] = last_monster
				pattern_triggered.emit(PatternKind.DUO_COMBO, payload)
				_deploy_history.clear()
				return


func get_last_deployed_id() -> StringName:
	if _deploy_history.is_empty():
		return &""
	return _deploy_history[-1]["id"]


func get_possible_combos(candidate_id: StringName) -> Array[String]:
	var results: Array[String] = []
	if candidate_id == &"":
		return results
	var last := get_last_deployed_id()
	if last != &"":
		for recipe in DUO_RECIPES:
			if recipe["seq"][0] == last and recipe["seq"][1] == candidate_id:
				results.append(recipe["name"])
	if _deploy_history.size() >= 2:
		if _deploy_history[-1]["id"] == candidate_id and _deploy_history[-2]["id"] == candidate_id:
			results.append("生态专精")
	var window_count := _deploy_history.size()
	if window_count >= 3:
		results.append("密集部署")
	return results
