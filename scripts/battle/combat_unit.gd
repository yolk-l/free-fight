class_name CombatUnit
extends Node2D

signal died(unit: CombatUnit)
signal stats_changed

const PROJECTILE_SCENE := preload("res://scenes/battle/projectile.tscn")

@export var display_label: String = "Unit"

var base_stats: CombatStats
var attack_range: float = GameConfig.ATTACK_RANGE
var projectile_speed: float = 0.0
var _projectile_container: Node2D = null
var _attack_timer: float = 0.0
var _is_dead: bool = false

@onready var _body: Sprite2D = $Body
@onready var _name_label: Label = $NameLabel
@onready var _stat_bar: StatBar = $StatBar
@onready var buff_container: BuffContainer = $BuffContainer


func _ready() -> void:
	if buff_container:
		buff_container.buffs_changed.connect(_on_buffs_changed)
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
	if global_position.distance_to(target.global_position) > attack_range:
		return
	_attack_timer -= delta
	if _attack_timer > 0.0:
		return
	var stats := get_combat_stats()
	_attack_timer = stats.get_attack_interval()
	var damage := maxi(1, stats.attack - target.get_combat_stats().defense)
	if projectile_speed > 0.0 and _projectile_container != null:
		_fire_projectile(target, damage)
	else:
		target.take_damage(damage)


func _fire_projectile(target: CombatUnit, damage: int) -> void:
	var proj: Projectile = PROJECTILE_SCENE.instantiate()
	_projectile_container.add_child(proj)
	proj.global_position = global_position
	proj.setup(target, damage, projectile_speed, _get_projectile_color())


func _get_projectile_color() -> Color:
	return Color(0.95, 0.85, 0.3)


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


func _on_buffs_changed() -> void:
	stats_changed.emit()
	_refresh_ui()
