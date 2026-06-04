class_name Hero
extends CombatUnit

signal hero_dodged
signal hero_killed_enemy(monster: Monster)
signal hero_attacked(target: Monster, damage: int)

var _battle_controller: Node = null
var hp_regen_per_sec: float = 0.0
var regen_low_hp_bonus: float = 1.0
var kill_heal: int = 0
var _regen_tick: float = 0.0

# --- Passive state (set by BattleController._apply_evolution_effect / hybrid) ---
# Wolf - critical hit chain
var crit_pending: bool = false
var crit_mult: float = 2.0
var crit_resets_cd: bool = false

# Bat - dodge-driven offense
var dodge_buff_timer: float = 0.0
var dodge_buff_mult: float = 1.3
var dodge_streak: int = 0
var dodge_streak_per: float = 0.0
var dodge_streak_cap: float = 0.0
var dodge_to_crit: bool = false      # Hybrid 1
var dodge_adds_venom: int = 0        # Hybrid 3 — stacks to apply on next attack after dodge
var _venom_bonus_pending: int = 0    # one-shot, consumed by next landed attack

# Gargoyle - shield
var shield_layers: int = 0
var shield_max_layers: int = 3
var shield_per_layer: int = 5
var shield_regen_interval: float = 0.0
var shield_regen_timer: float = 0.0
var shield_break_reflect: int = 0
var shield_break_heal: int = 0       # Hybrid 4

# Goblin - execute
var execute_chance: float = 0.0
var execute_kill_heal: int = 0
var execute_kill_grants_crit: bool = false  # Hybrid 2

# Slime - symbiosis healing
var symbiosis_heal_chance: float = 0.0
var symbiosis_heal_amount: int = 0
var symbiosis_overflow_to_shield: bool = false

# Skeleton - undead summon
var undead_summon_chance: float = 0.0
var undead_summon_leaves_aura: bool = false
var undead_force_summon: bool = false
var friendly_skeleton_death_heal: int = 0   # Hybrid 7

# Viper - poison
var venom_stacks_per_hit: int = 0
var venom_explode_at_5: bool = false
var venom_explode_damage: int = 15
var venom_explode_spreads: bool = false

# Hybrid 5 - emergency summon
var emergency_summon_enabled: bool = false
var emergency_summon_used: bool = false

var move_speed: float = GameConfig.HERO_MOVE_SPEED
var _locked_target: CombatUnit = null

# Grid movement state
var grid_mode: bool = false
var grid_cell := Vector2i.ZERO
var _grid_path: Array[Vector2i] = []
var _grid_step_timer: float = 0.0
var _grid_step_from := Vector2.ZERO
var _grid_step_to := Vector2.ZERO
var _grid_moving: bool = false
var _grid_speed_mult: float = 1.0
const GRID_STEP_TIME := 0.3

signal arrived_at_cell(cell: Vector2i)
signal path_finished


func _ready() -> void:
	super._ready()
	display_label = "英雄"
	set_physics_process(false)


func setup_hero(stats: CombatStats, controller: Node) -> void:
	_battle_controller = controller
	attack_range = GameConfig.HERO_ATTACK_RANGE
	projectile_speed = GameConfig.HERO_PROJECTILE_SPEED
	_projectile_container = controller.get_projectile_container()
	move_speed = GameConfig.HERO_MOVE_SPEED
	setup_stats(stats, "英雄")


func get_combat_stats() -> CombatStats:
	if base_stats == null:
		return CombatStats.new()
	var stats := base_stats.duplicate_stats()
	if buff_container:
		var mods := buff_container.get_all_modifiers()
		for key in mods.keys():
			match key:
				"attack":
					stats.attack += int(mods[key])
				"defense":
					stats.defense += int(mods[key])
				"attack_speed":
					stats.attack_speed += mods[key]
		stats.attack = maxi(GameConfig.MIN_ATTACK, stats.attack)
		stats.defense = maxi(GameConfig.MIN_DEFENSE, stats.defense)
		stats.attack_speed = maxf(GameConfig.MIN_ATTACK_SPEED, stats.attack_speed)
	stats.hp = base_stats.hp
	stats.max_hp = maxi(stats.max_hp, base_stats.max_hp)
	return stats


func refresh_display() -> void:
	stats_changed.emit()
	_refresh_ui()


func _refresh_ui() -> void:
	if _name_label:
		var suffix := ""
		if shield_layers > 0:
			suffix = "  护盾x%d" % shield_layers
		_name_label.text = display_label + suffix
	if _stat_bar:
		_stat_bar.update_stats(get_combat_stats())


func acquire_target() -> CombatUnit:
	if _battle_controller == null:
		return null
	if _locked_target != null and is_instance_valid(_locked_target) and _locked_target.is_alive():
		return _locked_target
	_locked_target = _battle_controller.get_nearest_monster_to(global_position)
	return _locked_target


func tick_combat(delta: float) -> void:
	if not is_alive():
		return
	_tick_shield_regen(delta)
	_tick_dodge_buff(delta)
	_tick_hp_regen(delta)
	if grid_mode:
		_tick_grid_movement(delta)
		return
	var target := acquire_target()
	if target == null or not is_instance_valid(target):
		return
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range:
		var dir := (target.global_position - global_position).normalized()
		global_position += dir * move_speed * delta
	else:
		try_attack(delta)


func _tick_grid_movement(delta: float) -> void:
	var target := acquire_target()
	if target != null and is_instance_valid(target) and target.is_alive():
		var dist := global_position.distance_to(target.global_position)
		if dist <= attack_range:
			_grid_moving = false
			_grid_path.clear()
			try_attack(delta)
			return
	if _grid_moving:
		var speed_mult := _grid_speed_mult
		if buff_container:
			var slow := buff_container.get_modifier_sum(&"move_speed_mult")
			if slow > 0.0 and slow < 1.0:
				speed_mult *= slow
		var step_time := GRID_STEP_TIME / maxf(0.1, speed_mult)
		_grid_step_timer += delta
		var t := clampf(_grid_step_timer / step_time, 0.0, 1.0)
		global_position = _grid_step_from.lerp(_grid_step_to, t)
		if t >= 1.0:
			_grid_moving = false
			global_position = _grid_step_to
			arrived_at_cell.emit(grid_cell)
	elif not _grid_path.is_empty():
		_start_next_grid_step()


func _start_next_grid_step() -> void:
	if _grid_path.is_empty():
		path_finished.emit()
		return
	var next_cell := _grid_path[0]
	_grid_path.remove_at(0)
	grid_cell = next_cell
	_grid_step_from = global_position
	_grid_step_to = Vector2(
		next_cell.x * DungeonGrid.CELL_SIZE + DungeonGrid.CELL_SIZE * 0.5,
		next_cell.y * DungeonGrid.CELL_SIZE + DungeonGrid.CELL_SIZE * 0.5
	)
	_grid_step_timer = 0.0
	_grid_moving = true


func set_grid_path(path: Array[Vector2i]) -> void:
	_grid_path = path
	if not _grid_moving and not _grid_path.is_empty():
		_start_next_grid_step()


func is_grid_idle() -> bool:
	return not _grid_moving and _grid_path.is_empty()


func _tick_shield_regen(delta: float) -> void:
	if shield_regen_interval <= 0.0:
		return
	if shield_layers >= shield_max_layers:
		shield_regen_timer = 0.0
		return
	shield_regen_timer += delta
	if shield_regen_timer >= shield_regen_interval:
		shield_regen_timer -= shield_regen_interval
		shield_layers = mini(shield_layers + 1, shield_max_layers)
		_refresh_ui()


func _tick_dodge_buff(delta: float) -> void:
	if dodge_buff_timer > 0.0:
		dodge_buff_timer = maxf(0.0, dodge_buff_timer - delta)


func _tick_hp_regen(delta: float) -> void:
	var buff_regen := buff_container.get_modifier_sum(&"hp_regen") if buff_container else 0.0
	var total_regen := hp_regen_per_sec + buff_regen
	if total_regen <= 0.0:
		return
	_regen_tick += delta
	while _regen_tick >= 1.0:
		_regen_tick -= 1.0
		var effective := get_combat_stats()
		if base_stats.hp < effective.max_hp:
			var regen := total_regen
			if regen_low_hp_bonus > 1.0:
				var hp_ratio := float(base_stats.hp) / float(effective.max_hp)
				if hp_ratio < 0.3:
					regen *= regen_low_hp_bonus
			base_stats.hp = mini(base_stats.hp + maxi(1, int(ceil(regen))), effective.max_hp)
			_refresh_ui()


func _damage_text_color() -> Color:
	return Color(0.95, 0.35, 0.3)


func _effective_dodge_chance() -> float:
	var d := dodge_chance + (dodge_streak * dodge_streak_per)
	if dodge_streak_cap > 0.0:
		d = minf(d, dodge_chance + dodge_streak_cap)
	return clampf(d, 0.0, 0.95)


func take_damage(amount: int) -> void:
	if _is_dead or base_stats == null:
		return
	if amount <= 0:
		return
	var eff_dodge := _effective_dodge_chance()
	if eff_dodge > 0.0 and randf() < eff_dodge:
		# Dodged
		dodge_streak += 1
		if dodge_buff_mult > 1.0:
			dodge_buff_timer = 5.0
		if dodge_to_crit:
			crit_pending = true
		if dodge_adds_venom > 0:
			_venom_bonus_pending = dodge_adds_venom
		show_floating_number("闪避", Color(0.6, 0.85, 1.0))
		hero_dodged.emit()
		return
	dodge_streak = 0
	if shield_layers > 0:
		var absorb := shield_layers * shield_per_layer
		var absorbed := mini(amount, absorb)
		var layers_consumed := int(ceil(float(absorbed) / float(shield_per_layer)))
		shield_layers = maxi(0, shield_layers - layers_consumed)
		amount -= absorbed
		show_floating_number("-%d 盾" % absorbed, Color(0.6, 0.75, 1.0))
		if shield_break_reflect > 0 and shield_layers == 0:
			_reflect_to_nearest(shield_break_reflect)
		if shield_break_heal > 0 and shield_layers == 0:
			base_stats.hp = mini(base_stats.hp + shield_break_heal, get_combat_stats().max_hp)
			show_floating_number("+%d" % shield_break_heal, Color(0.4, 1.0, 0.5))
		_refresh_ui()
		if amount <= 0:
			stats_changed.emit()
			return
	var actual := maxi(0, amount - flat_damage_reduction)
	if actual <= 0:
		return
	# Symbiosis - chance to heal on hit
	if symbiosis_heal_chance > 0.0 and randf() < symbiosis_heal_chance:
		var heal := symbiosis_heal_amount
		var effective := get_combat_stats()
		var room := effective.max_hp - base_stats.hp
		if heal <= room:
			base_stats.hp += heal
		else:
			base_stats.hp = effective.max_hp
			if symbiosis_overflow_to_shield:
				var overflow := heal - room
				_add_overflow_shield(overflow)
		show_floating_number("+%d" % heal, Color(0.4, 1.0, 0.5))
	# Emergency summon (fatal damage)
	if emergency_summon_enabled and not emergency_summon_used and actual >= base_stats.hp:
		emergency_summon_used = true
		base_stats.hp = 1
		_trigger_emergency_summon()
		show_floating_number("永恒守护!", Color(1.0, 0.85, 0.3))
		stats_changed.emit()
		_refresh_ui()
		return
	base_stats.hp = maxi(0, base_stats.hp - actual)
	show_floating_number("-%d" % actual, _damage_text_color())
	stats_changed.emit()
	_refresh_ui()
	if base_stats.hp <= 0:
		_die()


func _add_overflow_shield(extra: int) -> void:
	# Convert overflow heal into "shield_per_layer" worth of layers.
	if extra <= 0:
		return
	var new_layers := int(ceil(float(extra) / float(shield_per_layer)))
	shield_layers = mini(shield_layers + new_layers, shield_max_layers + 4)
	_refresh_ui()


func _reflect_to_nearest(damage: int) -> void:
	if _battle_controller == null:
		return
	var target = _battle_controller.get_nearest_monster_to(global_position)
	if target != null and is_instance_valid(target) and target.is_alive():
		target.take_damage(damage)


func _trigger_emergency_summon() -> void:
	if _battle_controller and _battle_controller.has_method("spawn_friendly_skeletons"):
		_battle_controller.spawn_friendly_skeletons(2, global_position, 8.0)


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
	var total_pen := armor_penetration
	if buff_container:
		total_pen += int(buff_container.get_modifier_sum(&"armor_penetration"))
	var target_def := target.get_combat_stats().defense
	if total_pen > 0:
		target_def = maxi(0, target_def - total_pen)
	var damage := maxi(1, stats.attack - target_def)
	var did_crit := false
	if crit_pending:
		damage = int(damage * crit_mult)
		crit_pending = false
		did_crit = true
	var did_execute := false
	if execute_chance > 0.0 and target.base_stats != null:
		var hp_ratio := float(target.base_stats.hp) / float(maxi(1, target.base_stats.max_hp))
		if hp_ratio < execute_hp_threshold and randf() < execute_chance:
			damage = int(damage * execute_multiplier)
			did_execute = true
	elif execute_multiplier > 1.0 and target.base_stats != null:
		# Legacy execute path (not gated by chance) when only multiplier is set.
		var hp_ratio := float(target.base_stats.hp) / float(maxi(1, target.base_stats.max_hp))
		if hp_ratio < execute_hp_threshold:
			damage = int(damage * execute_multiplier)
	if dodge_buff_timer > 0.0:
		damage = int(damage * dodge_buff_mult)
		dodge_buff_timer = 0.0
	hero_attacked.emit(target, damage)
	if projectile_speed > 0.0 and _projectile_container != null:
		_fire_projectile(target, damage)
	else:
		target.take_damage(damage)
	if target is Monster:
		if venom_stacks_per_hit > 0:
			target.add_poison_stack(venom_stacks_per_hit)
		if _venom_bonus_pending > 0:
			target.add_poison_stack(_venom_bonus_pending)
			_venom_bonus_pending = 0
		if buff_container and buff_container.has_buff(&"venom_coating"):
			target.add_poison_stack(2)
		if venom_explode_at_5:
			_check_venom_explode(target)
	if buff_container:
		buff_container.notify_event(&"attack")
	if did_crit and crit_resets_cd:
		_attack_timer = 0.0
	if did_execute and execute_kill_grants_crit and target is Monster:
		if target.base_stats and target.base_stats.hp <= 0:
			crit_pending = true


func _check_venom_explode(target) -> void:
	if not venom_explode_at_5:
		return
	if target.poison_stacks < 5:
		return
	target.take_damage(venom_explode_damage)
	if venom_explode_spreads and _battle_controller:
		_spread_venom(target)
	target.poison_stacks = 0


func _spread_venom(source: Monster) -> void:
	var monsters: Array = _battle_controller.get("_monsters") if "_monsters" in _battle_controller else []
	var nearest: Array[Monster] = []
	var by_dist: Array = []
	for m in monsters:
		if m == source or not is_instance_valid(m) or not m.is_alive():
			continue
		if m is Monster:
			by_dist.append({"m": m, "d": source.global_position.distance_to(m.global_position)})
	by_dist.sort_custom(func(a, b): return a["d"] < b["d"])
	for i in mini(2, by_dist.size()):
		var m: Monster = by_dist[i]["m"]
		m.add_poison_stack(2)
