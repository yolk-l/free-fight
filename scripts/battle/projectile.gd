class_name Projectile
extends Node2D

var target: CombatUnit
var damage: int
var speed: float

@onready var _body: Sprite2D = $Body


func setup(t: CombatUnit, dmg: int, spd: float, color: Color) -> void:
	target = t
	damage = dmg
	speed = spd
	if _body:
		_body.modulate = color


func _physics_process(delta: float) -> void:
	if target == null or not is_instance_valid(target) or not target.is_alive():
		queue_free()
		return
	var dir := (target.global_position - global_position).normalized()
	global_position += dir * speed * delta
	if global_position.distance_to(target.global_position) < 10.0:
		target.take_damage(damage)
		queue_free()
