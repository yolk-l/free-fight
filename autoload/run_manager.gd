extends Node

const KILL_STAT_GAIN := {
	&"slime":    {"max_hp": 2.0},
	&"bat":      {"attack_speed": 0.03},
	&"wolf":     {"attack": 0.4},
	&"goblin":   {"attack": 0.6},
	&"skeleton": {"defense": 0.25},
	&"gargoyle": {"defense": 0.5},
	&"viper":    {"armor_penetration": 0.25},
}

const BOSS_DIFFICULTY := 2.5

var in_run: bool = false
var current_boss: BossData = null
var total_kills: int = 0

var stat_gain_attack: float = 0.0
var stat_gain_defense: float = 0.0
var stat_gain_attack_speed: float = 0.0
var stat_gain_armor_penetration: float = 0.0
var stat_gain_max_hp: float = 0.0


func start_run() -> void:
	in_run = true
	total_kills = 0
	stat_gain_attack = 0.0
	stat_gain_defense = 0.0
	stat_gain_attack_speed = 0.0
	stat_gain_armor_penetration = 0.0
	stat_gain_max_hp = 0.0
	var bosses := BossData.get_all()
	current_boss = bosses[randi() % bosses.size()]
	GameManager.go_to_battle()


func apply_kill_gain(monster_id: StringName, multiplier: float = 1.0) -> Dictionary:
	var gains: Dictionary = KILL_STAT_GAIN.get(monster_id, {})
	var delta := {"attack": 0, "defense": 0, "attack_speed": 0.0, "armor_penetration": 0, "max_hp": 0}
	if gains.is_empty():
		return delta
	for key in gains.keys():
		var v: float = gains[key] * multiplier
		match key:
			"attack":
				var before := int(floor(stat_gain_attack))
				stat_gain_attack += v
				delta["attack"] = int(floor(stat_gain_attack)) - before
			"defense":
				var before := int(floor(stat_gain_defense))
				stat_gain_defense += v
				delta["defense"] = int(floor(stat_gain_defense)) - before
			"attack_speed":
				stat_gain_attack_speed += v
				delta["attack_speed"] = v
			"armor_penetration":
				var before := int(floor(stat_gain_armor_penetration))
				stat_gain_armor_penetration += v
				delta["armor_penetration"] = int(floor(stat_gain_armor_penetration)) - before
			"max_hp":
				var before := int(floor(stat_gain_max_hp))
				stat_gain_max_hp += v
				delta["max_hp"] = int(floor(stat_gain_max_hp)) - before
	return delta


func get_difficulty_for_distance(dist_from_spawn: int) -> float:
	if dist_from_spawn <= 10:
		return 1.0
	elif dist_from_spawn <= 20:
		return 1.3
	elif dist_from_spawn <= 30:
		return 1.6
	else:
		return 2.0


func end_run(_victory: bool) -> void:
	in_run = false
	GameManager.go_to_main_menu()
