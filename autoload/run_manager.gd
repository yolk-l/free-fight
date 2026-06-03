extends Node

const HEAL_BETWEEN_BATTLES := 0.2

const KILL_STAT_GAIN := {
	&"slime":    {"max_hp": 2.0},
	&"bat":      {"attack_speed": 0.03},
	&"wolf":     {"attack": 0.4},
	&"goblin":   {"attack": 0.6},
	&"skeleton": {"defense": 0.25},
	&"gargoyle": {"defense": 0.5},
	&"viper":    {"armor_penetration": 0.25},
}

const TOTAL_BATTLES := 1
const MIN_BATTLE_TIME := 0.0
const DIFFICULTY_MULTIPLIERS := [1.0]
const KILL_REQUIREMENTS := [0]

var in_run: bool = false
var current_battle: int = 0
var current_boss: BossData = null
var total_kills: int = 0
var run_survival_time: float = 0.0

var saved_hero_stats: CombatStats = null
var saved_kill_counts: Dictionary = {}
var saved_evolutions: Dictionary = {}
var saved_active_hybrids: Dictionary = {}

var saved_dodge_chance: float = 0.0
var saved_execute_multiplier: float = 1.0
var saved_execute_hp_threshold: float = 0.3
var saved_flat_damage_reduction: int = 0
var saved_armor_penetration: int = 0
var saved_hp_regen: float = 0.0
var saved_regen_low_hp_bonus: float = 1.0
var saved_kill_heal: int = 0

var stat_gain_attack: float = 0.0
var stat_gain_defense: float = 0.0
var stat_gain_attack_speed: float = 0.0
var stat_gain_armor_penetration: float = 0.0
var stat_gain_max_hp: float = 0.0


func start_run() -> void:
	in_run = true
	current_battle = 0
	total_kills = 0
	run_survival_time = 0.0
	saved_hero_stats = null
	saved_kill_counts.clear()
	saved_evolutions.clear()
	saved_active_hybrids.clear()
	saved_dodge_chance = 0.0
	saved_execute_multiplier = 1.0
	saved_execute_hp_threshold = 0.3
	saved_flat_damage_reduction = 0
	saved_armor_penetration = 0
	saved_hp_regen = 0.0
	saved_regen_low_hp_bonus = 1.0
	saved_kill_heal = 0
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


func get_total_stat_gains() -> Dictionary:
	return {
		"attack": int(floor(stat_gain_attack)),
		"defense": int(floor(stat_gain_defense)),
		"attack_speed": stat_gain_attack_speed,
		"armor_penetration": int(floor(stat_gain_armor_penetration)),
		"max_hp": int(floor(stat_gain_max_hp)),
	}


func get_difficulty_for_distance(dist_from_spawn: int) -> float:
	if dist_from_spawn <= 10:
		return 1.0
	elif dist_from_spawn <= 20:
		return 1.3
	elif dist_from_spawn <= 30:
		return 1.6
	else:
		return 2.0

const BOSS_DIFFICULTY := 2.5


func save_battle_state(_hero: Node, _evolution_tracker: Node, _survival_time: float, _kill_count: int) -> void:
	pass


func next_battle() -> void:
	GameManager.go_to_battle()


func get_difficulty_multiplier() -> float:
	return 1.0


func is_last_battle() -> bool:
	return true


func is_boss_battle() -> bool:
	return false


func get_kill_requirement() -> int:
	return 0


func end_run(_victory: bool) -> void:
	in_run = false
	GameManager.go_to_main_menu()
