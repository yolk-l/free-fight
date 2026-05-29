extends Node

var monsters: Dictionary = {}
var evolutions: Array[EvolutionPath] = []


func _ready() -> void:
	_load_resources("res://resources/monsters/", monsters)
	_load_evolutions("res://resources/evolutions/")


func _load_resources(folder: String, target: Dictionary) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		push_warning("DataRegistry: cannot open %s" % folder)
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var res: Resource = load(folder.path_join(file_name))
			if res != null and res.get("id") != null:
				target[res.id] = res


func get_monster(id: StringName) -> MonsterData:
	return monsters.get(id) as MonsterData


func get_all_monster_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for key in monsters.keys():
		ids.append(key as StringName)
	return ids


func get_random_monster_id() -> StringName:
	var keys: Array[StringName] = get_all_monster_ids()
	if keys.is_empty():
		return &""
	return keys[randi() % keys.size()]


func get_all_evolutions() -> Array[EvolutionPath]:
	return evolutions


func _load_evolutions(folder: String) -> void:
	var dir := DirAccess.open(folder)
	if dir == null:
		return
	for file_name in dir.get_files():
		if file_name.ends_with(".tres"):
			var res := load(folder.path_join(file_name))
			if res is EvolutionPath:
				evolutions.append(res)
