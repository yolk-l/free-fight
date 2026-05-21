class_name CombatUnit
extends Node2D

signal died(unit: CombatUnit)
signal stats_changed

@export var display_label: String = "Unit"

var base_stats: CombatStats
var _attack_timer: float = 0.0
var _is_dead: bool = false

@onready var _body: Sprite2D = $Body
@onready var _name_label: Label = $NameLabel
@onready var _stat_bar: StatBar = $StatBar


func _ready() -> void:
	if base_stats != null:
		_refresh_ui()


func setup_stats(stats: CombatStats, label_text: String = "") -> void:
	base_stats = stats.duplicate_stats()
	if label_text != "":
		display_label = label_text
	_refresh_ui()


func get_combat_stats() -> CombatStats:
	if base_stats == null:
		return CombatStats.new()
	return base_stats.duplicate_stats()


func acquire_target() -> CombatUnit:
	return null


func take_damage(amount: int) -> void:
	if _is_dead or base_stats == null:
		return
	base_stats.hp = maxi(0, base_stats.hp - amount)
	stats_changed.emit()
	_refresh_ui()
	if base_stats.hp <= 0:
		_die()


func try_attack(delta: float) -> void:
	if _is_dead:
		return
	var target := acquire_target()
	if target == null or not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) > GameConfig.ATTACK_RANGE:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	var stats := get_combat_stats()
	_attack_timer = stats.get_attack_interval()
	var damage := maxi(1, stats.attack - target.get_combat_stats().defense)
	target.take_damage(damage)


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	died.emit(self)
	set_physics_process(false)
	set_process(false)
	queue_free()


func _refresh_ui() -> void:
	if _name_label:
		_name_label.text = display_label
	if _stat_bar and base_stats != null:
		_stat_bar.update_stats(base_stats)


func is_alive() -> bool:
	return not _is_dead and base_stats != null and base_stats.hp > 0
