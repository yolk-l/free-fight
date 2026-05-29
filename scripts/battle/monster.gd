class_name Monster
extends CombatUnit

var data: MonsterData
var move_speed: float = 80.0
var _stun_timer: float = 0.0

var is_flying: bool = false
var is_elite: bool = false
var has_resurrection: bool = false
var death_explodes: bool = false
var death_splits: bool = false
var death_poison_puddle: bool = false
var pack_buff: bool = false
var stationary_buff: bool = false
var _stationary_timer: float = 0.0
var _stationary_buff_active: bool = false
var _tombstone_active: bool = false

var _hero: Hero = null
var _battle_controller: Node = null

var _shadow_speed_mult: float = 1.0
var _shadow_attack_bonus: float = 0.0
var _in_shadow_terrain: bool = false

var poison_stacks: int = 0
var poison_tick: float = 0.0


func setup_monster(monster_data: MonsterData, hero: Hero) -> void:
	data = monster_data
	_hero = hero
	if data == null:
		return
	move_speed = data.move_speed
	setup_stats(data.base_stats.duplicate_stats(), data.display_name)
	if _body:
		var tex_path := "res://assets/monsters/%s.png" % str(data.id)
		var tex := load(tex_path) as Texture2D
		if tex:
			_body.texture = tex
	_apply_mechanic_flags()
	set_physics_process(false)


func set_battle_controller(controller: Node) -> void:
	_battle_controller = controller


func mark_elite() -> void:
	is_elite = true
	if base_stats:
		base_stats.attack = int(base_stats.attack * 1.3)
		base_stats.max_hp = int(base_stats.max_hp * 1.3)
		base_stats.hp = base_stats.max_hp
		_refresh_ui()
	if _body:
		_body.scale = Vector2(1.3, 1.3)
		_body.modulate = Color(1.0, 0.85, 0.4)


func _apply_mechanic_flags() -> void:
	if data == null:
		return
	match data.id:
		&"slime":    death_splits = true
		&"bat":      is_flying = true
		&"wolf":     pack_buff = true
		&"goblin":   death_explodes = true
		&"skeleton": has_resurrection = true
		&"gargoyle":
			stationary_buff = true
			_stationary_buff_active = true
		&"viper":    death_poison_puddle = true


func get_combat_stats() -> CombatStats:
	var stats: CombatStats
	if base_stats != null:
		stats = base_stats.duplicate_stats()
	elif data != null and data.base_stats != null:
		stats = data.base_stats.duplicate_stats()
	else:
		stats = CombatStats.new()
	if _shadow_attack_bonus > 0.0:
		stats.attack = int(stats.attack * (1.0 + _shadow_attack_bonus))
	if pack_buff and _battle_controller != null and _has_pack_nearby():
		stats.attack_speed *= 1.5
	if _battle_controller != null and _has_gargoyle_aura():
		stats.defense += 2
	return stats


func _has_gargoyle_aura() -> bool:
	# Stationary gargoyles within 150px grant +2 defense to allies.
	if data != null and data.id == &"gargoyle":
		return false
	var aura_radius := 150.0
	var monsters: Array = _battle_controller.get("_monsters") if "_monsters" in _battle_controller else []
	for m in monsters:
		if m == self or not is_instance_valid(m) or not m.is_alive():
			continue
		if not (m is Monster):
			continue
		if m.data == null or m.data.id != &"gargoyle":
			continue
		if not m._stationary_buff_active:
			continue
		if global_position.distance_to(m.global_position) <= aura_radius:
			return true
	return false


func _has_pack_nearby() -> bool:
	var pack_radius := 200.0
	var monsters: Array = _battle_controller.get("_monsters") if "_monsters" in _battle_controller else []
	for m in monsters:
		if m == self or not is_instance_valid(m) or not m.is_alive():
			continue
		if m is Monster and m.data != null and data != null and m.data.id == data.id:
			if global_position.distance_to(m.global_position) <= pack_radius:
				return true
	return false


func get_effective_move_speed() -> float:
	if _stationary_buff_active or _tombstone_active:
		return 0.0
	return move_speed * _shadow_speed_mult


func apply_shadow_aura(speed_mult: float, atk_bonus: float) -> void:
	_shadow_speed_mult = speed_mult
	_shadow_attack_bonus = atk_bonus
	_in_shadow_terrain = true


func clear_shadow_aura() -> void:
	_shadow_speed_mult = 1.0
	_shadow_attack_bonus = 0.0
	_in_shadow_terrain = false


func acquire_target() -> CombatUnit:
	return _hero if is_instance_valid(_hero) and _hero.is_alive() else null


func stun(duration: float) -> void:
	_stun_timer = maxf(_stun_timer, duration)


func add_poison_stack(amount: int = 1) -> void:
	poison_stacks = clampi(poison_stacks + amount, 0, 5)


func refresh_display() -> void:
	_refresh_ui()


func _die() -> void:
	if _is_dead:
		return
	if has_resurrection and not _tombstone_active:
		_tombstone_active = true
		base_stats.max_hp = 10
		base_stats.hp = 10
		if _body:
			_body.modulate = Color(0.5, 0.5, 0.55)
			_body.scale = _body.scale * 0.7
		stats_changed.emit()
		_refresh_ui()
		return
	super._die()


func tick_combat(delta: float) -> void:
	if not is_alive() or _hero == null:
		return
	_tick_poison(delta)
	if _stun_timer > 0.0:
		_stun_timer -= delta
		return
	if _tombstone_active:
		return
	var dist := global_position.distance_to(_hero.global_position)
	if dist <= GameConfig.ATTACK_RANGE:
		try_attack(delta)


func _tick_poison(delta: float) -> void:
	if poison_stacks <= 0:
		return
	poison_tick += delta
	while poison_tick >= 1.0:
		poison_tick -= 1.0
		take_damage(poison_stacks)
