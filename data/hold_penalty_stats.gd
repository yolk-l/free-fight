class_name HoldPenaltyStats
extends Resource

## 手牌持仓负面；字段默认 0，避免复用 CombatStats 时继承 attack=10 等基准值。
@export var attack: int = 0
@export var defense: int = 0
@export var attack_speed: float = 0.0


func merge_into(sum: CombatStats) -> void:
	sum.attack += attack
	sum.defense += defense
	sum.attack_speed += attack_speed
