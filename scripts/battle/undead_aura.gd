class_name UndeadAura
extends Node2D

var _battle_controller: Node = null
var _radius: float = 80.0
var _damage_per_sec: int = 3
var _remaining: float = 4.0
var _tick: float = 0.0


func setup(controller: Node, radius: float, dmg: int, duration: float) -> void:
	_battle_controller = controller
	_radius = radius
	_damage_per_sec = dmg
	_remaining = duration
	z_index = -1
	queue_redraw()


func _physics_process(delta: float) -> void:
	_remaining -= delta
	if _remaining <= 0.0:
		queue_free()
		return
	_tick += delta
	while _tick >= 1.0:
		_tick -= 1.0
		_damage_enemies_in_range()
	queue_redraw()


func _damage_enemies_in_range() -> void:
	if _battle_controller == null:
		return
	var monsters: Array = _battle_controller.get("_monsters") if "_monsters" in _battle_controller else []
	for m in monsters:
		if not is_instance_valid(m) or not m.is_alive():
			continue
		if global_position.distance_to(m.global_position) <= _radius:
			m.take_damage(_damage_per_sec)


func _draw() -> void:
	var alpha: float = clampf(_remaining / 4.0, 0.0, 1.0)
	draw_circle(Vector2.ZERO, _radius, Color(0.7, 0.4, 0.9, 0.25 * alpha))
	draw_arc(Vector2.ZERO, _radius, 0, TAU, 32, Color(0.85, 0.6, 1.0, 0.6 * alpha), 1.5)
