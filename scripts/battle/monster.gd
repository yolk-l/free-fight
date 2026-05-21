class_name Monster
extends CombatUnit

var data: MonsterData
var move_speed: float = 80.0

var _hero: Hero = null


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
	set_physics_process(false)


func get_combat_stats() -> CombatStats:
	if data != null and data.base_stats != null:
		var stats := data.base_stats.duplicate_stats()
		stats.hp = base_stats.hp if base_stats else stats.hp
		return stats
	return super.get_combat_stats()


func acquire_target() -> CombatUnit:
	return _hero if is_instance_valid(_hero) and _hero.is_alive() else null


func tick_combat(delta: float) -> void:
	if not is_alive() or _hero == null:
		return
	var dist := global_position.distance_to(_hero.global_position)
	if dist <= GameConfig.ATTACK_RANGE:
		try_attack(delta)
	else:
		var dir := (_hero.global_position - global_position).normalized()
		global_position += dir * move_speed * delta
