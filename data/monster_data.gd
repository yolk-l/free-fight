class_name MonsterData
extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var base_stats: CombatStats
@export var wireframe_color: Color = Color.LIME_GREEN
@export var move_speed: float = 80.0
@export var hold_penalty: HoldPenaltyStats
@export var hold_bleed_per_sec: float = 0.0
