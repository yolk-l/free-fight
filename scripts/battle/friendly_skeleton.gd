class_name FriendlySkeleton
extends Node2D

const HP := 20
const ATTACK := 4
const ATTACK_RANGE := 60.0
const ATTACK_INTERVAL := 1.0
const MOVE_SPEED := 80.0
const AURA_RADIUS := 80.0
const AURA_DAMAGE_PER_SEC := 3
const AURA_DURATION := 4.0

var hp: int = HP
var _hero: Hero = null
var _battle_controller: Node = null
var _duration: float = 5.0
var _leaves_aura: bool = false
var _heal_on_death: int = 0
var _attack_timer: float = 0.0
var _body: ColorRect = null
var _label: Label = null
var _is_dead: bool = false


func setup(hero: Hero, controller: Node, duration: float, heal_on_death: int, leaves_aura: bool) -> void:
	_hero = hero
	_battle_controller = controller
	_duration = duration
	_heal_on_death = heal_on_death
	_leaves_aura = leaves_aura
	_build_visual()
	set_physics_process(true)


func _build_visual() -> void:
	_body = ColorRect.new()
	_body.color = Color(0.85, 0.85, 0.7, 0.85)
	_body.size = Vector2(28, 28)
	_body.position = Vector2(-14, -14)
	_body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body)
	_label = Label.new()
	_label.text = "亡灵"
	_label.position = Vector2(-22, -32)
	_label.size = Vector2(44, 14)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.7))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return
	_duration -= delta
	if _duration <= 0.0:
		_die()
		return
	var target := _find_target()
	if target == null:
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= ATTACK_RANGE:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_attack_timer = ATTACK_INTERVAL
			target.take_damage(ATTACK)
	else:
		var dir := (target.global_position - global_position).normalized()
		global_position += dir * MOVE_SPEED * delta


func _find_target() -> Monster:
	if _battle_controller == null or _hero == null:
		return null
	var monsters: Array = _battle_controller.get("_monsters") if "_monsters" in _battle_controller else []
	var nearest: Monster = null
	var best := INF
	for m in monsters:
		if not is_instance_valid(m) or not m.is_alive() or not (m is Monster):
			continue
		var d := global_position.distance_to(m.global_position)
		if d < best:
			best = d
			nearest = m
	return nearest


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true
	if _heal_on_death > 0 and is_instance_valid(_hero) and _hero.is_alive():
		var eff := _hero.get_combat_stats()
		_hero.base_stats.hp = mini(_hero.base_stats.hp + _heal_on_death, eff.max_hp)
		_hero.refresh_display()
	if _leaves_aura and _battle_controller != null:
		_spawn_death_aura()
	queue_free()


func _spawn_death_aura() -> void:
	var aura := UndeadAura.new()
	aura.name = "UndeadAura"
	_battle_controller.add_child(aura)
	aura.global_position = global_position
	aura.setup(_battle_controller, AURA_RADIUS, AURA_DAMAGE_PER_SEC, AURA_DURATION)
