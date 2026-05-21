class_name CombatStats
extends Resource

@export var attack: int = 10
@export var max_hp: int = 100
@export var hp: int = 100
@export var defense: int = 0
@export var attack_speed: float = 1.0


func duplicate_stats() -> CombatStats:
	var copy := CombatStats.new()
	copy.attack = attack
	copy.max_hp = max_hp
	copy.hp = hp
	copy.defense = defense
	copy.attack_speed = attack_speed
	return copy


func get_attack_interval() -> float:
	if attack_speed <= 0.0:
		return 1.0
	return 1.0 / attack_speed


func apply_bonus(bonus: CombatStats) -> CombatStats:
	var result := duplicate_stats()
	if bonus == null:
		return result
	result.attack += bonus.attack
	result.max_hp += bonus.max_hp
	result.hp = mini(result.hp + bonus.max_hp, result.max_hp)
	result.defense += bonus.defense
	result.attack_speed += bonus.attack_speed
	return result


static func zero_bonus() -> CombatStats:
	var bonus := CombatStats.new()
	bonus.attack = 0
	bonus.max_hp = 0
	bonus.hp = 0
	bonus.defense = 0
	bonus.attack_speed = 0.0
	return bonus


func merge_penalty_from(other: CombatStats) -> void:
	if other == null:
		return
	attack += other.attack
	defense += other.defense
	attack_speed += other.attack_speed


func apply_penalty(penalty: CombatStats) -> CombatStats:
	var result := duplicate_stats()
	if penalty == null:
		return result
	result.attack = maxi(GameConfig.MIN_ATTACK, result.attack + penalty.attack)
	result.defense = maxi(GameConfig.MIN_DEFENSE, result.defense + penalty.defense)
	result.attack_speed = maxf(GameConfig.MIN_ATTACK_SPEED, result.attack_speed + penalty.attack_speed)
	return result
