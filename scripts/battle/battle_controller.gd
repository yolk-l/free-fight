extends Node2D

const HERO_DEFAULT_STATS := preload("res://resources/hero_default.tres")
const DEFAULT_CARD_POOL := preload("res://resources/card_pool_default.tres")

var card_hand: CardHand
var _hero: Hero
var _monsters: Array[Monster] = []
var _game_over: bool = false
var _combo_tracker: ComboTracker
var _evolution_tracker: EvolutionTracker
var _terrain_system: TerrainSystem
var _combo_label: Label
var _evolution_label: Label
var _evolution_panel: HBoxContainer
var _evolution_progress_labels: Dictionary = {}
var _hybrid_panel_label: Label

@onready var _hero_node: Hero = $Units/Hero
@onready var _monster_container: Node2D = $Units/Monsters
@onready var _projectile_container: Node2D = $Units/Projectiles
@onready var _card_hand_node: CardHand = $UI/BottomPanel/CardHand
@onready var _next_hand_preview: NextHandPreview = $UI/BottomPanel/NextHandPreview
@onready var _deploy_manager: DeployManager = $DeployManager
@onready var _loot_system: LootSystem = $LootSystem
@onready var _game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var _survival_label: Label = $UI/TopBar/SurvivalLabel
@onready var _top_label: Label = $UI/TopBar/TopLabel
@onready var _drop_zone: BattlefieldDropZone = $UI/BattlefieldDropZone

var _survival_time: float = 0.0
var _deploy_count: int = 0
var _kill_count: int = 0
var _battle_won: bool = false
var _result_panel: PanelContainer
var _progress_label: Label
var _boss_monster: Monster = null
var _boss_hp_bar: ProgressBar = null
var _boss_hp_label: Label = null
var _boss_aura_tick: float = 0.0
var _boss_summon_timer: float = 0.0


func _ready() -> void:
	card_hand = _card_hand_node
	_hero = _hero_node
	_game_over_panel.visible = false
	_style_game_over_panel()
	_setup_hero()
	_deploy_manager.setup(_hero, _monster_container, self)
	_loot_system.setup()
	_terrain_system = TerrainSystem.new()
	_terrain_system.name = "TerrainSystem"
	add_child(_terrain_system)
	move_child(_terrain_system, $Background.get_index() + 1)
	_terrain_system.setup(_hero, self)
	_terrain_system.effect_triggered.connect(_on_terrain_effect_triggered)
	_terrain_system.generate_map_terrain()
	_combo_tracker = ComboTracker.new()
	_combo_tracker.name = "ComboTracker"
	add_child(_combo_tracker)
	_combo_tracker.setup()
	_combo_tracker.pattern_triggered.connect(_on_pattern_triggered)
	_setup_combo_ui()
	_evolution_tracker = EvolutionTracker.new()
	_evolution_tracker.name = "EvolutionTracker"
	add_child(_evolution_tracker)
	_evolution_tracker.setup(DataRegistry.get_all_evolutions())
	_evolution_tracker.evolution_triggered.connect(_on_evolution_triggered)
	_evolution_tracker.kill_count_changed.connect(_on_kill_count_changed)
	_evolution_tracker.hybrid_triggered.connect(_on_hybrid_triggered)
	_setup_evolution_ui()
	_card_hand_node.set_evolution_tracker(_evolution_tracker)
	_card_hand_node.set_card_pool(DEFAULT_CARD_POOL)
	_card_hand_node.set_next_preview(_next_hand_preview)
	_card_hand_node.deal_candidates()
	_deploy_manager.monster_deployed.connect(_on_monster_deployed)
	_drop_zone.set_terrain_system(_terrain_system)
	_drop_zone.card_dropped.connect(_on_card_dropped)
	_hero.died.connect(_on_hero_died)
	var restart_btn: Button = _game_over_panel.get_node_or_null("VBox/BtnRestart")
	var menu_btn: Button = _game_over_panel.get_node_or_null("VBox/BtnMenu")
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
	if _top_label:
		if RunManager.in_run:
			_top_label.text = "第 %d/%d 场 | 拖拽部署" % [RunManager.current_battle + 1, RunManager.TOTAL_BATTLES]
		else:
			_top_label.text = "拖拽部署"
	if RunManager.in_run:
		_setup_progress_ui()
	if RunManager.in_run and RunManager.current_battle > 0:
		_restore_run_state()
	if RunManager.in_run and RunManager.is_boss_battle():
		_setup_boss_battle()
	if RunManager.in_run and RunManager.current_battle == 0 and RunManager.current_boss != null:
		_show_boss_preview()


func _physics_process(delta: float) -> void:
	if _game_over:
		return
	_survival_time += delta
	if _survival_label:
		_survival_label.text = "存活: %ds" % int(_survival_time)
	_refresh_progress_ui()
	_card_hand_node.tick(delta)
	if _hero.buff_container:
		_hero.buff_container.tick(delta)
	if is_instance_valid(_hero) and _hero.is_alive():
		_hero.tick_combat(delta)
	for monster in _monsters:
		if is_instance_valid(monster) and monster.is_alive():
			monster.tick_combat(delta)
	if _terrain_system:
		_terrain_system.process_monsters(delta, _monsters)
		_terrain_system.tick_map_terrain(delta, _monsters)
	if _boss_monster != null:
		_tick_boss_effects(delta)


func register_monster(monster: Monster) -> void:
	_monsters.append(monster)
	monster.set_battle_controller(self)
	monster.died.connect(_on_monster_died.bind(monster))


func get_projectile_container() -> Node2D:
	return _projectile_container


func get_nearest_monster_to(pos: Vector2) -> CombatUnit:
	var nearest: Monster = null
	var best_dist := INF
	for monster in _monsters:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var d := pos.distance_to(monster.global_position)
		if d < best_dist:
			best_dist = d
			nearest = monster
	return nearest


func _style_game_over_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.9, 0.25, 0.2, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 8
	_game_over_panel.add_theme_stylebox_override("panel", style)


func _setup_hero() -> void:
	var stats: CombatStats
	if RunManager.in_run and RunManager.saved_hero_stats != null:
		# Restored from previous battle: stats already include accumulated gains.
		stats = RunManager.saved_hero_stats.duplicate_stats()
	elif HERO_DEFAULT_STATS:
		stats = HERO_DEFAULT_STATS.duplicate_stats()
	else:
		stats = CombatStats.new()
		stats.attack = 10
		stats.max_hp = 150
		stats.hp = 150
		stats.defense = 3
		stats.attack_speed = 1.0
	_hero.setup_hero(stats, self)


func _restore_run_state() -> void:
	_hero.dodge_chance = RunManager.saved_dodge_chance
	_hero.execute_multiplier = RunManager.saved_execute_multiplier
	_hero.execute_hp_threshold = RunManager.saved_execute_hp_threshold
	_hero.flat_damage_reduction = RunManager.saved_flat_damage_reduction
	_hero.armor_penetration = RunManager.saved_armor_penetration
	_hero.hp_regen_per_sec = RunManager.saved_hp_regen
	_hero.regen_low_hp_bonus = RunManager.saved_regen_low_hp_bonus
	_hero.kill_heal = RunManager.saved_kill_heal
	if _evolution_tracker:
		_evolution_tracker.restore_state(RunManager.saved_kill_counts, RunManager.saved_evolutions)
		_evolution_tracker.restore_hybrids(RunManager.saved_active_hybrids)
		for h in _evolution_tracker.get_active_hybrid_list():
			_apply_hybrid_effect(h.id)
	_refresh_evolution_ui()
	_refresh_hybrid_ui()


func _check_battle_win() -> void:
	if _game_over or _battle_won:
		return
	if not RunManager.in_run:
		return
	if RunManager.is_boss_battle():
		if _boss_monster != null and not is_instance_valid(_boss_monster):
			_boss_monster = null
		if _boss_monster == null and is_instance_valid(_hero) and _hero.is_alive():
			_on_battle_won()
		return
	if _survival_time < RunManager.MIN_BATTLE_TIME:
		return
	if _kill_count < RunManager.get_kill_requirement():
		return
	var alive_count := 0
	for monster in _monsters:
		if is_instance_valid(monster) and monster.is_alive():
			alive_count += 1
	if alive_count == 0 and is_instance_valid(_hero) and _hero.is_alive():
		_on_battle_won()


func _on_battle_won() -> void:
	_battle_won = true
	set_physics_process(false)
	RunManager.save_battle_state(_hero, _evolution_tracker, _survival_time, _kill_count)
	_show_result_panel(true)


func _show_result_panel(victory: bool) -> void:
	_result_panel = PanelContainer.new()
	_result_panel.name = "BattleResultPanel"
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.8, 0.4, 0.8) if victory else Color(0.9, 0.25, 0.2, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	_result_panel.add_theme_stylebox_override("panel", style)
	_result_panel.position = Vector2(340, 160)
	_result_panel.size = Vector2(600, 400)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_result_panel.add_child(vbox)
	var title := Label.new()
	title.text = "第 %d 场战斗完成!" % (RunManager.current_battle + 1) if victory else "Run 失败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5) if victory else Color(0.95, 0.3, 0.25))
	vbox.add_child(title)
	var stats_text := Label.new()
	stats_text.text = "存活: %ds | 击杀: %d | 部署: %d" % [int(_survival_time), _kill_count, _deploy_count]
	stats_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_text.add_theme_font_size_override("font_size", 14)
	stats_text.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(stats_text)
	if victory and _hero and _hero.base_stats:
		var hp_label := Label.new()
		hp_label.text = "英雄 HP: %d (回复 +%d%%)" % [_hero.base_stats.hp, int(RunManager.HEAL_BETWEEN_BATTLES * 100)]
		hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hp_label.add_theme_font_size_override("font_size", 12)
		hp_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		vbox.add_child(hp_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	if victory and not RunManager.is_last_battle():
		var next_btn := Button.new()
		next_btn.text = "继续下一场 (%d/%d)" % [RunManager.current_battle + 2, RunManager.TOTAL_BATTLES]
		next_btn.custom_minimum_size = Vector2(200, 40)
		next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		next_btn.pressed.connect(func(): RunManager.next_battle())
		vbox.add_child(next_btn)
	elif victory:
		var win_label := Label.new()
		win_label.text = "Run 通关!"
		win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		win_label.add_theme_font_size_override("font_size", 20)
		win_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		vbox.add_child(win_label)
	var menu_btn := Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.custom_minimum_size = Vector2(200, 40)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func(): RunManager.end_run(false); GameManager.go_to_main_menu())
	vbox.add_child(menu_btn)
	$UI.add_child(_result_panel)


func _on_card_dropped(monster_id: StringName, drop_position: Vector2) -> void:
	if _game_over:
		return
	var is_elite := _card_hand_node.is_consumed_elite(monster_id)
	if not _card_hand_node.consume_card(monster_id):
		return
	var monster: Monster = _deploy_manager.deploy_monster_at(monster_id, drop_position)
	if monster and is_elite:
		monster.mark_elite()


func _on_monster_deployed(monster: Monster) -> void:
	_deploy_count += 1
	if _combo_tracker and monster.data:
		_combo_tracker.on_monster_deployed(monster.data.id, monster)
	_apply_map_terrain_on_deploy(monster)
	_refresh_combo_hint()


func _apply_map_terrain_on_deploy(monster: Monster) -> void:
	if _terrain_system == null or monster.data == null:
		return
	var kind := _terrain_system.get_map_terrain_at(monster.global_position)
	if kind < 0:
		return
	var mid := monster.data.id
	var pos := monster.global_position
	match kind:
		MapTerrainType.Kind.GRASSLAND:
			if mid == &"wolf":
				monster.pack_range = 400.0
				_show_floating_text(pos, "草原: 群感增强!", Color(0.45, 0.7, 0.3))
			elif mid == &"goblin":
				monster.explosion_radius = 120.0
				_show_floating_text(pos, "草原: 爆炸扩散!", Color(0.45, 0.7, 0.3))
		MapTerrainType.Kind.DESERT:
			if mid == &"slime":
				monster.death_splits = false
				_show_floating_text(pos, "沙漠: 无法分裂", Color(0.85, 0.75, 0.4))
			elif mid == &"gargoyle":
				monster.aura_radius = 225.0
				_show_floating_text(pos, "沙漠: 光环扩展!", Color(0.85, 0.75, 0.4))
			elif mid == &"viper":
				monster.poison_puddle_duration_mult = 2.0
				_show_floating_text(pos, "沙漠: 毒液浓缩!", Color(0.85, 0.75, 0.4))
		MapTerrainType.Kind.MOUNTAIN:
			if mid == &"goblin":
				monster.explosion_damage = 12
				_show_floating_text(pos, "山地: 爆炸增伤!", Color(0.55, 0.5, 0.45))
			elif mid == &"skeleton":
				monster.resurrection_hp = 20
				_show_floating_text(pos, "山地: 复活增强!", Color(0.55, 0.5, 0.45))
			elif mid == &"gargoyle":
				monster.aura_def_bonus = 4
				_show_floating_text(pos, "山地: 防御光环↑!", Color(0.55, 0.5, 0.45))
		MapTerrainType.Kind.LAKE:
			if mid == &"slime":
				monster.split_count = 3
				_show_floating_text(pos, "湖泊: 多重分裂!", Color(0.3, 0.55, 0.85))
			elif mid == &"bat":
				monster.is_flying = false
				_show_floating_text(pos, "湖泊: 失去飞行!", Color(0.3, 0.55, 0.85))
			elif mid == &"viper":
				monster.death_poison_puddle = false
				_show_floating_text(pos, "湖泊: 毒素稀释", Color(0.3, 0.55, 0.85))
		MapTerrainType.Kind.FOREST:
			if mid == &"wolf":
				monster.pack_aspd_mult = 3.0
				_show_floating_text(pos, "森林: 群攻速↑!", Color(0.2, 0.5, 0.25))
			elif mid == &"skeleton":
				monster.skip_tombstone = true
				_show_floating_text(pos, "森林: 速复活!", Color(0.2, 0.5, 0.25))


func _on_monster_died(_unit: CombatUnit, monster: Monster) -> void:
	_loot_system.on_monster_died(monster)
	var death_pos := monster.global_position
	var resonance_mult := 1.0
	if _terrain_system != null:
		resonance_mult = _terrain_system.on_monster_died(monster, death_pos)
	_handle_death_mechanics(monster, death_pos)
	if monster.data and RunManager.in_run:
		_apply_kill_stat_gain(monster.data.id)
		if monster.is_elite:
			_apply_kill_stat_gain(monster.data.id)
	if _evolution_tracker and monster.data:
		var count_gain: int = int(round(resonance_mult))
		var bonus_count: int = 2 if monster.is_elite else 1
		var eco_bonus: int = _eco_spec_bonus.get(monster.data.id, 0)
		if eco_bonus > 0:
			_eco_spec_bonus[monster.data.id] = 0
		_evolution_tracker.on_monster_killed(monster.data.id, count_gain * bonus_count + eco_bonus)
	if is_instance_valid(_hero):
		var predator_tier: int = _evolution_tracker.active_evolutions.get(&"predator", 0)
		if predator_tier >= 1:
			_apply_predator_kill_buff(predator_tier)
		_maybe_summon_undead(death_pos)
		if monster.data:
			_maybe_summon_terrain(monster.data.id, death_pos)
		if _hero.execute_kill_heal > 0:
			# Heal-on-kill from brutal T3 (only fires on real kills; we assume any kill counts).
			var eff := _hero.get_combat_stats()
			_hero.base_stats.hp = mini(_hero.base_stats.hp + _hero.execute_kill_heal, eff.max_hp)
			_hero.refresh_display()
	if is_instance_valid(_hero) and _hero.is_alive() and _hero.kill_heal > 0:
		var effective := _hero.get_combat_stats()
		_hero.base_stats.hp = mini(_hero.base_stats.hp + _hero.kill_heal, effective.max_hp)
		_hero.refresh_display()
	_monsters.erase(monster)
	_kill_count += 1
	_show_kill_milestone(_kill_count, death_pos)
	_check_battle_win()


func _on_terrain_effect_triggered(world_pos: Vector2, text: String, color: Color) -> void:
	_show_floating_text(world_pos, text, color)


func _show_floating_text(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	label.position = world_pos - Vector2(20, 20)
	label.size = Vector2(60, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 36.0, 0.9)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.9)
	tween.tween_callback(label.queue_free)


func _show_kill_milestone(count: int, pos: Vector2) -> void:
	var text := ""
	var color := Color(1.0, 0.95, 0.5)
	match count:
		1:
			text = "首杀!"
			color = Color(0.3, 1.0, 0.5)
		3:
			text = "连杀 x3!"
			color = Color(0.4, 0.9, 1.0)
		5:
			text = "连杀 x5!"
			color = Color(1.0, 0.85, 0.2)
		10:
			text = "10 杀!"
			color = Color(1.0, 0.6, 0.2)
	if text.is_empty():
		return
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.position = pos - Vector2(40, 40)
	label.size = Vector2(80, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	var tween := create_tween()
	tween.parallel().tween_property(label, "position:y", label.position.y - 50.0, 1.2)
	tween.parallel().tween_property(label, "scale", Vector2(1.3, 1.3), 0.15)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.1)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.tween_callback(label.queue_free)


func _show_stat_gain_text(stat_delta: Dictionary) -> void:
	if not is_instance_valid(_hero):
		return
	var parts: PackedStringArray = []
	if stat_delta["attack"] != 0:
		parts.append("攻+%d" % stat_delta["attack"])
	if stat_delta["defense"] != 0:
		parts.append("防+%d" % stat_delta["defense"])
	if absf(stat_delta["attack_speed"]) > 0.001:
		parts.append("速+%.2f" % stat_delta["attack_speed"])
	if stat_delta["armor_penetration"] != 0:
		parts.append("穿+%d" % stat_delta["armor_penetration"])
	if stat_delta["max_hp"] != 0:
		parts.append("HP+%d" % stat_delta["max_hp"])
	if parts.is_empty():
		return
	_hero.show_floating_number(" ".join(parts), Color(0.5, 1.0, 0.7))


func _maybe_summon_terrain(monster_id: StringName, pos: Vector2) -> void:
	if _hero == null or _terrain_system == null:
		return
	var config = _hero.summon_terrain_on_kill.get(monster_id)
	if config == null:
		return
	var chance: float = config.get("chance", 0.0)
	if chance <= 0.0 or randf() >= chance:
		return
	var kind: int = config.get("kind", 0)
	var duration: float = config.get("duration", 6.0)
	_terrain_system.spawn_terrain_at(kind, pos, duration)
	_show_floating_text(pos, "+" + TerrainType.get_display_name(kind), Color(0.85, 0.9, 1.0))


func _maybe_summon_undead(pos: Vector2) -> void:
	if not is_instance_valid(_hero):
		return
	var should_summon: bool = _hero.undead_force_summon or randf() < _hero.undead_summon_chance
	if not should_summon:
		return
	spawn_friendly_skeletons(1, pos, 5.0)


func spawn_friendly_skeletons(count: int, center: Vector2, duration: float) -> void:
	for i in count:
		var s := FriendlySkeleton.new()
		s.name = "FriendlySkeleton"
		_monster_container.add_child(s)
		var offset := Vector2(randf_range(-30, 30), randf_range(-30, 30))
		s.global_position = center + offset
		s.setup(_hero, self, duration, _hero.friendly_skeleton_death_heal, _hero.undead_summon_leaves_aura)


func _handle_death_mechanics(monster: Monster, pos: Vector2) -> void:
	if monster.death_explodes:
		_trigger_goblin_explosion(pos, monster)
	if monster.death_splits:
		_spawn_slime_splits(pos, monster.split_count)
	if monster.death_poison_puddle and _terrain_system:
		var dur := TerrainSystem.POISON_PUDDLE_DURATION * monster.poison_puddle_duration_mult
		_terrain_system.spawn_poison_puddle(pos, dur)


func _trigger_goblin_explosion(pos: Vector2, source: Monster) -> void:
	var radius := source.explosion_radius
	var damage := source.explosion_damage
	for m in _monsters:
		if m == source or not is_instance_valid(m) or not m.is_alive():
			continue
		if pos.distance_to(m.global_position) <= radius:
			m.take_damage(damage)
	if is_instance_valid(_hero) and _hero.is_alive() and pos.distance_to(_hero.global_position) <= radius:
		_hero.take_damage(damage)


func _spawn_slime_splits(pos: Vector2, count: int = 2) -> void:
	var data := DataRegistry.get_monster(&"slime")
	if data == null:
		return
	for i in count:
		var small_data: MonsterData = data.duplicate()
		small_data.base_stats = data.base_stats.duplicate_stats()
		small_data.base_stats.attack = 1
		small_data.base_stats.max_hp = 5
		small_data.base_stats.hp = 5
		var monster: Monster = preload("res://scenes/battle/monster_unit.tscn").instantiate()
		_monster_container.add_child(monster)
		monster.global_position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		monster.setup_monster(small_data, _hero)
		monster.death_splits = false  # prevent infinite split chain
		if monster._body:
			monster._body.scale = Vector2(0.4, 0.4)
		register_monster(monster)


func _apply_kill_stat_gain(monster_id: StringName, multiplier: float = 1.0) -> void:
	if not is_instance_valid(_hero) or _hero.base_stats == null:
		return
	var delta := RunManager.apply_kill_gain(monster_id, multiplier)
	var changed := false
	if delta["attack"] != 0:
		_hero.base_stats.attack += int(delta["attack"])
		changed = true
	if delta["defense"] != 0:
		_hero.base_stats.defense += int(delta["defense"])
		changed = true
	if absf(delta["attack_speed"]) > 0.0001:
		_hero.base_stats.attack_speed += float(delta["attack_speed"])
		changed = true
	if delta["armor_penetration"] != 0:
		_hero.armor_penetration += int(delta["armor_penetration"])
		changed = true
	if delta["max_hp"] != 0:
		var hp_delta := int(delta["max_hp"])
		_hero.base_stats.max_hp += hp_delta
		_hero.base_stats.hp = mini(_hero.base_stats.hp + hp_delta, _hero.base_stats.max_hp)
		changed = true
	if changed:
		_hero.refresh_display()
		_show_stat_gain_text(delta)


func _apply_predator_kill_buff(_tier: int) -> void:
	# v5: 击杀后下次攻击必暴击 (replaces old aspd buff).
	if is_instance_valid(_hero):
		_hero.crit_pending = true


func _on_hero_died(_unit: CombatUnit) -> void:
	if _game_over:
		return
	_game_over = true
	_stop_monster_activity()
	set_physics_process(false)
	if RunManager.in_run:
		_show_result_panel(false)
	else:
		_game_over_panel.visible = true


func _stop_monster_activity() -> void:
	for monster in _monsters:
		if is_instance_valid(monster):
			monster.set_physics_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _game_over:
		_on_restart_pressed()


func _setup_evolution_ui() -> void:
	_evolution_panel = HBoxContainer.new()
	_evolution_panel.name = "EvolutionPanel"
	_evolution_panel.position = Vector2(10, 42)
	_evolution_panel.add_theme_constant_override("separation", 6)
	$UI.add_child(_evolution_panel)
	for progress in _evolution_tracker.get_all_progress():
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.7, 0.5))
		lbl.text = ""
		lbl.visible = false
		_evolution_panel.add_child(lbl)
		_evolution_progress_labels[progress["path_id"]] = lbl
	_evolution_label = Label.new()
	_evolution_label.name = "EvolutionLabel"
	_evolution_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_evolution_label.add_theme_font_size_override("font_size", 28)
	_evolution_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	_evolution_label.position = Vector2(440, 90)
	_evolution_label.size = Vector2(400, 50)
	_evolution_label.visible = false
	$UI.add_child(_evolution_label)
	_hybrid_panel_label = Label.new()
	_hybrid_panel_label.name = "HybridPanelLabel"
	_hybrid_panel_label.position = Vector2(10, 62)
	_hybrid_panel_label.add_theme_font_size_override("font_size", 12)
	_hybrid_panel_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3, 0.9))
	_hybrid_panel_label.visible = false
	$UI.add_child(_hybrid_panel_label)


func _on_evolution_triggered(path_id: StringName, tier: int) -> void:
	_apply_evolution_effect(path_id, tier)
	_refresh_evolution_ui()
	var path_name := ""
	var tier_name := ""
	for p in DataRegistry.get_all_evolutions():
		if p.path_id == path_id:
			path_name = p.display_name
			match tier:
				1: tier_name = p.tier1_name
				2: tier_name = p.tier2_name
				3: tier_name = p.tier3_name
			break
	_show_evolution_text("演化! %s %s - %s" % [path_name, _roman(tier), tier_name])


func _apply_evolution_effect(path_id: StringName, tier: int) -> void:
	match path_id:
		&"predator":
			# Wolf - critical chain.
			match tier:
				1:
					_hero.crit_mult = 2.0
				2:
					_hero.crit_mult = 2.5
					_set_summon_terrain(&"wolf", TerrainType.Kind.RESONANCE_ALTAR, 0.35, 6.0)
				3:
					_hero.crit_mult = 2.5
					_hero.crit_resets_cd = true
					_set_summon_terrain(&"wolf", TerrainType.Kind.RESONANCE_ALTAR, 0.6, 8.0)
		&"shadow":
			# Bat - dodge tree.
			match tier:
				1:
					_hero.dodge_chance = 0.2
				2:
					_hero.dodge_chance = 0.2
					_hero.dodge_buff_mult = 1.3
					_set_summon_terrain(&"bat", TerrainType.Kind.SANCTUARY, 0.35, 6.0)
				3:
					_hero.dodge_chance = 0.2
					_hero.dodge_buff_mult = 1.3
					_hero.dodge_streak_per = 0.05
					_hero.dodge_streak_cap = 0.4
					_set_summon_terrain(&"bat", TerrainType.Kind.SANCTUARY, 0.6, 8.0)
		&"fortress":
			# Gargoyle - shield generation.
			match tier:
				1:
					_hero.shield_max_layers = 3
					_hero.shield_per_layer = 5
					_hero.shield_regen_interval = 5.0
				2:
					_hero.shield_regen_interval = 3.0
					_set_summon_terrain(&"gargoyle", TerrainType.Kind.RESONANCE_NODE, 0.35, 6.0)
				3:
					_hero.shield_regen_interval = 3.0
					_hero.shield_break_reflect = 10
					_set_summon_terrain(&"gargoyle", TerrainType.Kind.RESONANCE_NODE, 0.6, 8.0)
		&"brutal":
			# Goblin - probability execute.
			match tier:
				1:
					_hero.execute_chance = 0.3
					_hero.execute_multiplier = 1.5
					_hero.execute_hp_threshold = 0.3
				2:
					_hero.execute_chance = 0.5
					_hero.execute_hp_threshold = 0.35
					_set_summon_terrain(&"goblin", TerrainType.Kind.THORNS, 0.35, 6.0)
				3:
					_hero.execute_kill_heal = 5
					_set_summon_terrain(&"goblin", TerrainType.Kind.THORNS, 0.6, 8.0)
		&"symbiosis":
			# Slime - heal on hit.
			match tier:
				1:
					_hero.symbiosis_heal_chance = 0.25
					_hero.symbiosis_heal_amount = 5
				2:
					_hero.symbiosis_heal_chance = 0.4
					_hero.symbiosis_heal_amount = 8
					_set_summon_terrain(&"slime", TerrainType.Kind.RESONANCE_ALTAR, 0.35, 6.0)
				3:
					_hero.symbiosis_heal_chance = 0.4
					_hero.symbiosis_heal_amount = 8
					_hero.symbiosis_overflow_to_shield = true
					_set_summon_terrain(&"slime", TerrainType.Kind.RESONANCE_ALTAR, 0.6, 8.0)
		&"undead":
			# Skeleton - chance to summon ally.
			match tier:
				1: _hero.undead_summon_chance = 0.2
				2:
					_hero.undead_summon_chance = 0.4
					_set_summon_terrain(&"skeleton", TerrainType.Kind.SHADOW, 0.35, 6.0)
				3:
					_hero.undead_summon_chance = 0.4
					_hero.undead_summon_leaves_aura = true
					_set_summon_terrain(&"skeleton", TerrainType.Kind.SHADOW, 0.6, 8.0)
		&"venom":
			# Viper - poison stacks.
			match tier:
				1: _hero.venom_stacks_per_hit = 1
				2:
					_hero.venom_stacks_per_hit = 1
					_hero.venom_explode_at_5 = true
					_set_summon_terrain(&"viper", TerrainType.Kind.POISON_LAND, 0.5, 6.0)
				3:
					_hero.venom_stacks_per_hit = 1
					_hero.venom_explode_at_5 = true
					_hero.venom_explode_spreads = true
					_set_summon_terrain(&"viper", TerrainType.Kind.POISON_LAND, 0.8, 8.0)
	_hero.refresh_display()


func _set_summon_terrain(monster_id: StringName, kind: int, chance: float, duration: float) -> void:
	_hero.summon_terrain_on_kill[monster_id] = {
		"kind": kind,
		"chance": chance,
		"duration": duration,
	}


func _on_kill_count_changed(_monster_type: StringName, _count: int) -> void:
	_refresh_evolution_ui()
	if _card_hand_node:
		_card_hand_node.refresh_displays()


func _refresh_evolution_ui() -> void:
	for progress in _evolution_tracker.get_all_progress():
		var lbl: Label = _evolution_progress_labels.get(progress["path_id"])
		if lbl == null:
			continue
		var tier: int = progress["tier"]
		var count: int = progress["count"]
		if count == 0 and tier == 0:
			lbl.visible = false
			continue
		lbl.visible = true
		if tier >= 1 and progress["next_threshold"] > 0:
			lbl.text = "%s%s %d/%d" % [progress["display_name"], _roman(tier), count, progress["next_threshold"]]
			lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		elif tier >= 1:
			lbl.text = "%s%s MAX" % [progress["display_name"], _roman(tier)]
			lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		else:
			lbl.text = "%s %d/%d" % [progress["display_name"], count, progress["next_threshold"]]
			lbl.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85, 0.8))


func _show_evolution_text(text: String) -> void:
	if _evolution_label == null:
		return
	_evolution_label.text = text
	_evolution_label.visible = true
	_evolution_label.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(_evolution_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_evolution_label.set.bind("visible", false))


func _on_hybrid_triggered(hybrid_id: StringName) -> void:
	_apply_hybrid_effect(hybrid_id)
	_refresh_hybrid_ui()
	var name := ""
	for h in HybridEvolution.get_all():
		if h.id == hybrid_id:
			name = h.display_name
			break
	_show_evolution_text("混合演化! %s" % name)


func _apply_hybrid_effect(hybrid_id: StringName) -> void:
	# v5 mechanics-based hybrids; effects layer on top of base evolution passives.
	match hybrid_id:
		&"predator_shadow":   # 暗夜猎手: 闪避后下次攻击必暴击
			_hero.dodge_to_crit = true
		&"predator_brutal":   # 嗜血猛兽: 处决击杀必暴击
			_hero.execute_kill_grants_crit = true
		&"shadow_venom":      # 暗影毒刺: 闪避后下次攻击叠 2 层毒
			_hero.dodge_adds_venom = 2
		&"fortress_symbiosis":  # 不动如山: 护盾破碎回血 5
			_hero.shield_break_heal = 5
		&"fortress_undead":   # 永恒守护: 受致命伤召唤 2 骷髅(一次性)
			_hero.emergency_summon_enabled = true
		&"brutal_venom":      # 毒裁者: 毒引爆伤害提升至 25
			_hero.venom_explode_damage = 25
		&"undead_symbiosis":  # 生死融合: 友方骷髅死亡回血 5
			_hero.friendly_skeleton_death_heal = 5
		&"predator_undead":   # 亡灵猎手: 击杀必召唤骷髅
			_hero.undead_force_summon = true
	_hero.refresh_display()


func _refresh_hybrid_ui() -> void:
	if _hybrid_panel_label == null:
		return
	var hybrids := _evolution_tracker.get_active_hybrid_list()
	if hybrids.is_empty():
		_hybrid_panel_label.visible = false
		return
	var names: PackedStringArray = []
	for h in hybrids:
		names.append(h.display_name)
	_hybrid_panel_label.text = "混合: " + ", ".join(names)
	_hybrid_panel_label.visible = true


func _setup_combo_ui() -> void:
	_combo_label = Label.new()
	_combo_label.name = "ComboLabel"
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 24)
	_combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_combo_label.anchors_preset = Control.PRESET_CENTER_TOP
	_combo_label.position = Vector2(540, 60)
	_combo_label.size = Vector2(200, 40)
	_combo_label.visible = false
	$UI.add_child(_combo_label)
	_combo_hint_label = Label.new()
	_combo_hint_label.name = "ComboHintLabel"
	_combo_hint_label.add_theme_font_size_override("font_size", 11)
	_combo_hint_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5, 0.75))
	_combo_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
	_combo_hint_label.add_theme_constant_override("outline_size", 2)
	_combo_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_hint_label.visible = false
	$UI/BottomPanel.add_child(_combo_hint_label)


var _eco_spec_bonus: Dictionary = {}  # monster_id -> pending extra kill count for next kill
var _combo_hint_label: Label = null


func _on_pattern_triggered(kind: int, payload: Dictionary) -> void:
	match kind:
		ComboTracker.PatternKind.ECO_SPEC:
			var mid: StringName = payload.get("monster_id", &"")
			if mid != &"":
				_eco_spec_bonus[mid] = _eco_spec_bonus.get(mid, 0) + 2
			_show_combo_text("生态专精: %s" % str(mid))
		ComboTracker.PatternKind.DUO_COMBO:
			_apply_duo_combo(payload)
			_show_combo_text(payload.get("name", "联动"))
		ComboTracker.PatternKind.DENSE_DEPLOY:
			_promote_random_elite()
			_show_combo_text("密集部署!")


func _apply_duo_combo(payload: Dictionary) -> void:
	if not is_instance_valid(_hero):
		return
	var effect: String = payload.get("effect", "")
	var value = payload.get("value", 0)
	var duration: float = payload.get("duration", 3.0)
	match effect:
		"hero_aspd":
			_add_combo_buff(&"combo_aspd", "联动:攻速", duration, {"attack_speed": float(value)})
		"hero_attack":
			_add_combo_buff(&"combo_atk", "联动:攻击", duration, {"attack": float(value)})
		"hero_defense":
			_add_combo_buff(&"combo_def", "联动:防御", duration, {"defense": float(value)})
		"poison_all":
			for m in _monsters:
				if is_instance_valid(m) and m.is_alive() and (m is Monster):
					m.add_poison_stack(int(value))
		"summon_aura":
			var monster: Monster = payload.get("last_monster")
			var pos: Vector2 = monster.global_position if (monster and is_instance_valid(monster)) else _hero.global_position
			var aura := UndeadAura.new()
			aura.name = "UndeadAuraCombo"
			add_child(aura)
			aura.global_position = pos
			aura.setup(self, 80.0, 3, duration)


func _add_combo_buff(buff_id: StringName, name_text: String, duration: float, mods: Dictionary) -> void:
	if _hero.buff_container == null:
		return
	var buff := BuffDef.new()
	buff.id = buff_id
	buff.display_name = name_text
	buff.duration_type = BuffDef.DurationType.TIMED
	buff.duration_sec = duration
	buff.modifiers = mods
	_hero.buff_container.add_buff(buff, &"combo")


func _promote_random_elite() -> void:
	var candidates: Array[Monster] = []
	for m in _monsters:
		if is_instance_valid(m) and m.is_alive() and (m is Monster) and not m.is_elite:
			candidates.append(m)
	if candidates.is_empty():
		return
	var chosen: Monster = candidates[randi() % candidates.size()]
	chosen.mark_elite()


func _show_combo_text(text: String) -> void:
	if _combo_label == null:
		return
	_combo_label.text = text + " combo!"
	_combo_label.visible = true
	_combo_label.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	tween.tween_interval(1.0)
	tween.tween_property(_combo_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(_combo_label.set.bind("visible", false))


func _refresh_combo_hint() -> void:
	if _combo_hint_label == null or _combo_tracker == null:
		return
	var last_id := _combo_tracker.get_last_deployed_id()
	if last_id == &"":
		_combo_hint_label.visible = false
		return
	var last_data := DataRegistry.get_monster(last_id)
	var last_name: String = last_data.display_name if last_data else str(last_id)
	var hints: PackedStringArray = []
	for recipe in ComboTracker.DUO_RECIPES:
		if recipe["seq"][0] == last_id:
			var next_data := DataRegistry.get_monster(recipe["seq"][1])
			var next_name: String = next_data.display_name if next_data else str(recipe["seq"][1])
			hints.append("+%s=%s" % [next_name, recipe["name"]])
	if hints.is_empty():
		_combo_hint_label.text = "上次: %s" % last_name
	else:
		_combo_hint_label.text = "上次: %s | %s" % [last_name, " ".join(hints)]
	_combo_hint_label.visible = true


func _setup_progress_ui() -> void:
	_progress_label = Label.new()
	_progress_label.name = "ProgressLabel"
	_progress_label.add_theme_font_size_override("font_size", 12)
	_progress_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.6))
	_progress_label.position = Vector2(900, 4)
	_progress_label.size = Vector2(360, 20)
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	$UI.add_child(_progress_label)


func _refresh_progress_ui() -> void:
	if _progress_label == null or not RunManager.in_run:
		return
	var req_kills := RunManager.get_kill_requirement()
	var time_left := maxf(0.0, RunManager.MIN_BATTLE_TIME - _survival_time)
	if _kill_count >= req_kills and time_left <= 0.0:
		_progress_label.text = "清除剩余怪物即可过关"
		_progress_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		var parts: Array[String] = []
		if _kill_count < req_kills:
			parts.append("击杀: %d/%d" % [_kill_count, req_kills])
		if time_left > 0.0:
			parts.append("时间: %ds" % int(ceil(time_left)))
		_progress_label.text = " | ".join(parts)


func _roman(tier: int) -> String:
	match tier:
		1: return "I"
		2: return "II"
		3: return "III"
		_: return str(tier)


func _on_restart_pressed() -> void:
	if RunManager.in_run:
		RunManager.start_run()
	else:
		GameManager.go_to_battle()


func _on_menu_pressed() -> void:
	if RunManager.in_run:
		RunManager.end_run(false)
	GameManager.go_to_main_menu()


func _show_boss_preview() -> void:
	set_physics_process(false)
	var boss := RunManager.current_boss
	if boss == null:
		set_physics_process(true)
		return
	var overlay := ColorRect.new()
	overlay.name = "BossPreviewOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(overlay)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.98)
	style.border_color = boss.wireframe_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(280, 80)
	panel.size = Vector2(720, 500)
	overlay.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	var header := Label.new()
	header.text = "本次挑战目标"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	vbox.add_child(header)
	var name_label := Label.new()
	name_label.text = boss.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", boss.wireframe_color)
	vbox.add_child(name_label)
	var desc_label := Label.new()
	desc_label.text = boss.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.72, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc_label)
	var stats_label := Label.new()
	stats_label.text = "HP: %d  |  攻击: %d  |  防御: %d  |  攻速: %.1f" % [
		boss.base_stats.max_hp, boss.base_stats.attack, boss.base_stats.defense, boss.base_stats.attack_speed
	]
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(stats_label)
	var sep1 := HSeparator.new()
	sep1.add_theme_constant_override("separation", 8)
	vbox.add_child(sep1)
	var traits_header := Label.new()
	traits_header.text = "特性"
	traits_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	traits_header.add_theme_font_size_override("font_size", 16)
	traits_header.add_theme_color_override("font_color", Color(0.95, 0.6, 0.3))
	vbox.add_child(traits_header)
	for t in boss.traits:
		var trait_label := Label.new()
		trait_label.text = "  %s — %s" % [t["name"], t["desc"]]
		trait_label.add_theme_font_size_override("font_size", 13)
		trait_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.7))
		vbox.add_child(trait_label)
	var sep2 := HSeparator.new()
	sep2.add_theme_constant_override("separation", 8)
	vbox.add_child(sep2)
	var hint_label := Label.new()
	hint_label.text = boss.counter_hint
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.4, 0.85, 0.5))
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(hint_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	vbox.add_child(spacer)
	var start_btn := Button.new()
	start_btn.text = "开始挑战"
	start_btn.custom_minimum_size = Vector2(200, 45)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.pressed.connect(func():
		overlay.queue_free()
		set_physics_process(true)
	)
	vbox.add_child(start_btn)


func _setup_boss_battle() -> void:
	var boss := RunManager.current_boss
	if boss == null:
		return
	var monster_scene := preload("res://scenes/battle/monster_unit.tscn")
	_boss_monster = monster_scene.instantiate()
	_monster_container.add_child(_boss_monster)
	_boss_monster.global_position = Vector2(1000, 300)
	var boss_stats := boss.base_stats.duplicate_stats()
	_boss_monster.base_stats = boss_stats
	_boss_monster.move_speed = boss.move_speed
	_boss_monster.display_label = boss.display_name
	_boss_monster._hero = _hero
	_boss_monster.flat_damage_reduction = boss.flat_damage_reduction
	_boss_monster._refresh_ui()
	if _boss_monster.has_node("Body"):
		var body: Sprite2D = _boss_monster.get_node("Body")
		body.modulate = boss.wireframe_color
		body.scale = Vector2(1.8, 1.8)
	register_monster(_boss_monster)
	_setup_boss_hp_bar(boss)
	if _top_label:
		_top_label.text = "Boss战! %s | 拖拽部署" % boss.display_name


func _setup_boss_hp_bar(boss: BossData) -> void:
	var bar_container := HBoxContainer.new()
	bar_container.name = "BossHPBarContainer"
	bar_container.position = Vector2(340, 18)
	bar_container.add_theme_constant_override("separation", 8)
	var boss_name := Label.new()
	boss_name.text = boss.display_name
	boss_name.add_theme_font_size_override("font_size", 14)
	boss_name.add_theme_color_override("font_color", boss.wireframe_color)
	bar_container.add_child(boss_name)
	_boss_hp_bar = ProgressBar.new()
	_boss_hp_bar.custom_minimum_size = Vector2(250, 20)
	_boss_hp_bar.max_value = boss.base_stats.max_hp
	_boss_hp_bar.value = boss.base_stats.hp
	_boss_hp_bar.show_percentage = false
	var bar_style := StyleBoxFlat.new()
	bar_style.bg_color = Color(0.15, 0.15, 0.2)
	bar_style.set_corner_radius_all(4)
	_boss_hp_bar.add_theme_stylebox_override("background", bar_style)
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.85, 0.2, 0.15)
	fill_style.set_corner_radius_all(4)
	_boss_hp_bar.add_theme_stylebox_override("fill", fill_style)
	bar_container.add_child(_boss_hp_bar)
	_boss_hp_label = Label.new()
	_boss_hp_label.text = "%d/%d" % [boss.base_stats.hp, boss.base_stats.max_hp]
	_boss_hp_label.add_theme_font_size_override("font_size", 12)
	_boss_hp_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.8))
	bar_container.add_child(_boss_hp_label)
	$UI.add_child(bar_container)


func _tick_boss_effects(delta: float) -> void:
	var boss := RunManager.current_boss
	if boss == null:
		return
	if boss.aura_bleed > 0.0 and is_instance_valid(_boss_monster) and _boss_monster.is_alive():
		if is_instance_valid(_hero) and _hero.is_alive():
			_boss_aura_tick += delta
			while _boss_aura_tick >= 1.0:
				_boss_aura_tick -= 1.0
				_hero.take_damage(maxi(1, int(ceil(boss.aura_bleed))))
	if boss.regen_per_sec > 0.0 and is_instance_valid(_boss_monster) and _boss_monster.is_alive():
		if _boss_monster.base_stats != null:
			var heal := boss.regen_per_sec * delta
			_boss_monster.base_stats.hp = mini(
				_boss_monster.base_stats.hp + int(ceil(heal)),
				_boss_monster.base_stats.max_hp
			)
	if boss.summon_interval > 0.0 and is_instance_valid(_boss_monster) and _boss_monster.is_alive():
		_boss_summon_timer += delta
		if _boss_summon_timer >= boss.summon_interval:
			_boss_summon_timer -= boss.summon_interval
			_boss_summon(boss.summon_monster_id)
	_refresh_boss_hp_bar()
	_check_battle_win()


func _boss_summon(monster_id: StringName) -> void:
	if monster_id == &"":
		return
	var data := DataRegistry.get_monster(monster_id)
	if data == null:
		return
	var monster_scene := preload("res://scenes/battle/monster_unit.tscn")
	var monster: Monster = monster_scene.instantiate()
	_monster_container.add_child(monster)
	monster.global_position = _boss_monster.global_position + Vector2(randi_range(-60, 60), randi_range(-40, 40))
	monster.setup_monster(data, _hero)
	var mult := RunManager.get_difficulty_multiplier()
	if mult > 1.0 and monster.base_stats:
		monster.base_stats.attack = int(monster.base_stats.attack * mult)
		monster.base_stats.hp = int(monster.base_stats.hp * mult)
		monster.base_stats.max_hp = int(monster.base_stats.max_hp * mult)
		monster._refresh_ui()
	register_monster(monster)


func _refresh_boss_hp_bar() -> void:
	if _boss_hp_bar == null:
		return
	if is_instance_valid(_boss_monster) and _boss_monster.base_stats:
		_boss_hp_bar.value = _boss_monster.base_stats.hp
		if _boss_hp_label:
			_boss_hp_label.text = "%d/%d" % [_boss_monster.base_stats.hp, _boss_monster.base_stats.max_hp]
	else:
		_boss_hp_bar.value = 0
		if _boss_hp_label:
			_boss_hp_label.text = "0"
