extends Node2D

const HERO_DEFAULT_STATS := preload("res://resources/hero_default.tres")
const DEFAULT_CARD_POOL := preload("res://resources/card_pool_default.tres")
const MONSTER_SCENE := preload("res://scenes/battle/monster_unit.tscn")

var card_hand: CardHand
var _hero: Hero
var _monsters: Array[Monster] = []
var _game_over: bool = false
var _battle_won: bool = false

var _grid: DungeonGrid
var _pathfinder: GridPathfinder
var _renderer: DungeonRenderer
var _camera: DungeonCamera
var _path_preview: PathPreview
var _tile_effects: TileEffectSystem
var _mini_map: MiniMap
var _drop_zone: GridDropZone

var _combo_tracker: ComboTracker
var _evolution_tracker: EvolutionTracker
var _combo_label: Label
var _evolution_label: Label
var _evolution_panel: HBoxContainer
var _evolution_progress_labels: Dictionary = {}
var _hybrid_panel_label: Label
var _combo_hint_label: Label
var _eco_spec_bonus: Dictionary = {}

var _hero_node: Hero
var _monster_container: Node2D
var _projectile_container: Node2D
var _card_hand_node: CardHand
var _next_hand_preview: NextHandPreview
var _deploy_manager: DeployManager
var _loot_system: LootSystem
var _game_over_panel: PanelContainer
var _survival_label: Label
var _top_label: Label

var _survival_time: float = 0.0
var _deploy_count: int = 0
var _kill_count: int = 0
var _boss_monster: Monster = null
var _boss_hp_bar: ProgressBar = null
var _boss_hp_label: Label = null
var _boss_aura_tick: float = 0.0
var _boss_summon_timer: float = 0.0
var _boss_spawned: bool = false
var _pending_loot_cell := Vector2i(-1, -1)

var _tile_info_panel: PanelContainer = null
var _tile_info_title: Label = null
var _tile_info_desc: Label = null
var _tile_info_status: Label = null
var _tile_info_cell := Vector2i(-1, -1)


func _ready() -> void:
	_generate_dungeon()
	_setup_world_nodes()
	_setup_hero()
	_setup_camera()
	_setup_ui()
	_setup_systems()
	_setup_cards()
	_connect_signals()
	if RunManager.in_run:
		_top_label.text = "地下城探索 | 拖拽部署"
	else:
		_top_label.text = "地下城探索 | 拖拽部署"


func _generate_dungeon() -> void:
	var gen := MapGenerator.new()
	_grid = gen.generate()
	_pathfinder = GridPathfinder.new()
	_pathfinder.setup(_grid)


func _setup_world_nodes() -> void:
	_renderer = DungeonRenderer.new()
	_renderer.name = "DungeonRenderer"
	add_child(_renderer)
	_renderer.setup(_grid)

	_path_preview = PathPreview.new()
	_path_preview.name = "PathPreview"
	_path_preview.z_index = 5
	add_child(_path_preview)
	_path_preview.setup(_grid)

	_monster_container = Node2D.new()
	_monster_container.name = "Monsters"
	_monster_container.z_index = 10
	add_child(_monster_container)

	_projectile_container = Node2D.new()
	_projectile_container.name = "Projectiles"
	_projectile_container.z_index = 11
	add_child(_projectile_container)

	var hero_scene := preload("res://scenes/battle/hero_unit.tscn")
	_hero_node = hero_scene.instantiate()
	_hero_node.z_index = 15
	add_child(_hero_node)

	_loot_system = LootSystem.new()
	_loot_system.name = "LootSystem"
	add_child(_loot_system)
	_loot_system.setup()

	_deploy_manager = DeployManager.new()
	_deploy_manager.name = "DeployManager"
	add_child(_deploy_manager)


func _setup_hero() -> void:
	_hero = _hero_node
	var stats: CombatStats
	if HERO_DEFAULT_STATS:
		stats = HERO_DEFAULT_STATS.duplicate_stats()
	else:
		stats = CombatStats.new()
		stats.attack = 10
		stats.max_hp = 150
		stats.hp = 150
		stats.defense = 3
		stats.attack_speed = 1.0
	_hero.setup_hero(stats, self)
	_hero.grid_mode = true
	_hero.grid_cell = _grid.spawn_cell
	_hero.global_position = _grid.cell_to_world(_grid.spawn_cell)
	_hero.arrived_at_cell.connect(_on_hero_arrived_at_cell)
	_hero.path_finished.connect(_on_hero_path_finished)
	_hero.died.connect(_on_hero_died)
	_deploy_manager.setup(_hero, _monster_container, self)


func _setup_camera() -> void:
	_camera = DungeonCamera.new()
	_camera.name = "DungeonCamera"
	add_child(_camera)
	_camera.setup(_hero, DungeonGrid.GRID_W, DungeonGrid.GRID_H, DungeonGrid.CELL_SIZE)
	_camera.make_current()


func _setup_ui() -> void:
	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)

	var top_bar := HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.offset_left = 20
	top_bar.offset_top = 8
	top_bar.offset_right = 1060
	top_bar.offset_bottom = 40
	ui.add_child(top_bar)

	_top_label = Label.new()
	_top_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.85))
	_top_label.add_theme_font_size_override("font_size", 13)
	_top_label.text = "地下城探索"
	top_bar.add_child(_top_label)

	_survival_label = Label.new()
	_survival_label.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
	_survival_label.add_theme_font_size_override("font_size", 14)
	_survival_label.text = "探索: 0s"
	_survival_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	top_bar.add_child(_survival_label)

	_mini_map = MiniMap.new()
	_mini_map.name = "MiniMap"
	_mini_map.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_mini_map.position = Vector2(1090, 8)
	ui.add_child(_mini_map)
	_mini_map.setup(_grid, _hero)

	_drop_zone = GridDropZone.new()
	_drop_zone.name = "GridDropZone"
	ui.add_child(_drop_zone)
	_drop_zone.setup(_grid, _pathfinder, _hero, _camera)
	_drop_zone.set_path_preview(_path_preview)

	var bottom_bg := ColorRect.new()
	bottom_bg.color = Color(0.08, 0.08, 0.12, 0.9)
	bottom_bg.offset_left = 0
	bottom_bg.offset_top = 570
	bottom_bg.offset_right = 1280
	bottom_bg.offset_bottom = 720
	bottom_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bottom_bg)

	var bottom_panel := VBoxContainer.new()
	bottom_panel.name = "BottomPanel"
	bottom_panel.offset_left = 20
	bottom_panel.offset_top = 578
	bottom_panel.offset_right = 1260
	bottom_panel.offset_bottom = 710
	bottom_panel.add_theme_constant_override("separation", 6)
	ui.add_child(bottom_panel)

	_card_hand_node = CardHand.new()
	_card_hand_node.name = "CardHand"
	_card_hand_node.add_theme_constant_override("separation", 8)
	var card_title := Label.new()
	card_title.name = "Title"
	card_title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	card_title.add_theme_font_size_override("font_size", 13)
	card_title.text = "候选"
	_card_hand_node.add_child(card_title)
	bottom_panel.add_child(_card_hand_node)

	_next_hand_preview = NextHandPreview.new()
	_next_hand_preview.name = "NextHandPreview"
	_next_hand_preview.add_theme_constant_override("separation", 6)
	var next_title := Label.new()
	next_title.name = "Title"
	next_title.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	next_title.add_theme_font_size_override("font_size", 11)
	next_title.text = "下一批"
	_next_hand_preview.add_child(next_title)
	bottom_panel.add_child(_next_hand_preview)

	_game_over_panel = PanelContainer.new()
	_game_over_panel.name = "GameOverPanel"
	_game_over_panel.visible = false
	_game_over_panel.offset_left = 390
	_game_over_panel.offset_top = 220
	_game_over_panel.offset_right = 890
	_game_over_panel.offset_bottom = 460
	var go_style := StyleBoxFlat.new()
	go_style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	go_style.border_color = Color(0.9, 0.25, 0.2, 0.8)
	go_style.set_border_width_all(3)
	go_style.set_corner_radius_all(12)
	go_style.set_content_margin_all(24)
	_game_over_panel.add_theme_stylebox_override("panel", go_style)

	var go_vbox := VBoxContainer.new()
	go_vbox.name = "VBox"
	go_vbox.add_theme_constant_override("separation", 20)
	_game_over_panel.add_child(go_vbox)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	go_vbox.add_child(spacer)

	var go_title := Label.new()
	go_title.name = "Title"
	go_title.add_theme_color_override("font_color", Color(0.95, 0.3, 0.25))
	go_title.add_theme_font_size_override("font_size", 32)
	go_title.text = "GAME OVER"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_title)

	var go_msg := Label.new()
	go_msg.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	go_msg.add_theme_font_size_override("font_size", 14)
	go_msg.text = "英雄已阵亡"
	go_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_vbox.add_child(go_msg)

	var restart_btn := Button.new()
	restart_btn.text = "重新开始"
	restart_btn.custom_minimum_size = Vector2(200, 44)
	restart_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	restart_btn.pressed.connect(_on_restart_pressed)
	go_vbox.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.custom_minimum_size = Vector2(200, 44)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(_on_menu_pressed)
	go_vbox.add_child(menu_btn)

	ui.add_child(_game_over_panel)

	_tile_info_panel = PanelContainer.new()
	_tile_info_panel.name = "TileInfoPanel"
	_tile_info_panel.visible = false
	_tile_info_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ti_style := StyleBoxFlat.new()
	ti_style.bg_color = Color(0.06, 0.06, 0.1, 0.92)
	ti_style.border_color = Color(0.5, 0.55, 0.7, 0.6)
	ti_style.set_border_width_all(2)
	ti_style.set_corner_radius_all(6)
	ti_style.set_content_margin_all(10)
	_tile_info_panel.add_theme_stylebox_override("panel", ti_style)
	var ti_vbox := VBoxContainer.new()
	ti_vbox.add_theme_constant_override("separation", 4)
	ti_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tile_info_panel.add_child(ti_vbox)
	_tile_info_title = Label.new()
	_tile_info_title.add_theme_font_size_override("font_size", 14)
	_tile_info_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ti_vbox.add_child(_tile_info_title)
	_tile_info_desc = Label.new()
	_tile_info_desc.add_theme_font_size_override("font_size", 12)
	_tile_info_desc.add_theme_color_override("font_color", Color(0.75, 0.78, 0.85))
	_tile_info_desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ti_vbox.add_child(_tile_info_desc)
	_tile_info_status = Label.new()
	_tile_info_status.add_theme_font_size_override("font_size", 11)
	_tile_info_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ti_vbox.add_child(_tile_info_status)
	ui.add_child(_tile_info_panel)


func _setup_systems() -> void:
	_tile_effects = TileEffectSystem.new()

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

	_tile_effects.setup(_grid, _hero, _evolution_tracker)
	_tile_effects.effect_applied.connect(_on_tile_effect)


func _setup_cards() -> void:
	card_hand = _card_hand_node
	_card_hand_node.set_evolution_tracker(_evolution_tracker)
	_card_hand_node.set_card_pool(DEFAULT_CARD_POOL)
	_card_hand_node.set_next_preview(_next_hand_preview)
	_card_hand_node.deal_candidates()


func _connect_signals() -> void:
	_deploy_manager.monster_deployed.connect(_on_monster_deployed)
	_drop_zone.card_dropped.connect(_on_card_dropped)
	_drop_zone.tile_clicked.connect(_on_tile_clicked)


func _physics_process(delta: float) -> void:
	if _game_over:
		return
	_survival_time += delta
	if _survival_label:
		_survival_label.text = "探索: %ds | 击杀: %d" % [int(_survival_time), _kill_count]
	_card_hand_node.tick(delta)
	if _hero.buff_container:
		_hero.buff_container.tick(delta)
	if is_instance_valid(_hero) and _hero.is_alive():
		_hero.tick_combat(delta)
	for monster in _monsters:
		if is_instance_valid(monster) and monster.is_alive():
			monster.tick_combat(delta)
	if _boss_monster != null:
		_tick_boss_effects(delta)
	if _mini_map:
		_mini_map.set_monsters(_monsters)
	_auto_find_target()


func _auto_find_target() -> void:
	if not is_instance_valid(_hero) or not _hero.is_alive():
		return
	if not _hero.is_grid_idle():
		return
	if _pending_loot_cell != Vector2i(-1, -1):
		var loot_cell := _pending_loot_cell
		_pending_loot_cell = Vector2i(-1, -1)
		if _hero.grid_cell == loot_cell:
			_hero.set_grid_path([loot_cell])
		else:
			var path := _pathfinder.find_path(_hero.grid_cell, loot_cell)
			if path.size() > 1:
				path.remove_at(0)
				_hero.set_grid_path(path)
		return
	var nearest: Monster = null
	var best_dist := 999999
	for monster in _monsters:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var cell := _grid.world_to_cell(monster.global_position)
		var d := _pathfinder.get_path_length(_hero.grid_cell, cell)
		if d < best_dist:
			best_dist = d
			nearest = monster
	if nearest == null:
		return
	var target_cell := _grid.world_to_cell(nearest.global_position)
	var path := _pathfinder.find_path(_hero.grid_cell, target_cell)
	if path.size() > 1:
		path.remove_at(0)
		_hero.set_grid_path(path)
		_hero._locked_target = nearest


func _on_hero_arrived_at_cell(cell: Vector2i) -> void:
	var newly_revealed := _grid.reveal_around(cell.x, cell.y, GameConfig.HERO_VISION_RADIUS)
	if not newly_revealed.is_empty():
		_renderer.reveal_cells(newly_revealed)
	var result := _tile_effects.apply_tile_effect(cell)
	if not result.is_empty():
		if result.has("revealed"):
			_renderer.reveal_cells(result["revealed"])
		if DungeonTileType.is_one_shot(_grid.get_tile(cell.x, cell.y)):
			_renderer.mark_tile_used(cell)
		if result.has("teleport_to"):
			var dest: Vector2i = result["teleport_to"]
			_hero.grid_cell = dest
			_hero.global_position = _grid.cell_to_world(dest)
			_hero._grid_path.clear()
			_hero._grid_moving = false
			var tp_revealed := _grid.reveal_around(dest.x, dest.y, GameConfig.HERO_VISION_RADIUS)
			if not tp_revealed.is_empty():
				_renderer.reveal_cells(tp_revealed)
		if result.get("boss_gate", false) and not _boss_spawned:
			_spawn_boss()


func _on_hero_path_finished() -> void:
	pass


func _on_tile_effect(cell: Vector2i, text: String, color: Color) -> void:
	var world_pos := _grid.cell_to_world(cell)
	_show_floating_text(world_pos, text, color)


func _on_card_dropped(monster_id: StringName, grid_cell: Vector2i) -> void:
	if _game_over:
		return
	var is_elite := _card_hand_node.is_consumed_elite(monster_id)
	if not _card_hand_node.consume_card(monster_id):
		return
	var world_pos := _grid.cell_to_world(grid_cell)
	_grid.set_occupied(grid_cell.x, grid_cell.y, true)
	var monster: Monster = _deploy_manager.deploy_monster_at(monster_id, world_pos)
	if monster and is_elite:
		monster.mark_elite()
	if monster:
		var dist := _grid.get_path_distance_to_spawn(grid_cell.x, grid_cell.y)
		var mult := RunManager.get_difficulty_for_distance(dist)
		if mult > 1.0 and monster.base_stats:
			monster.base_stats.attack = int(monster.base_stats.attack * mult)
			monster.base_stats.hp = int(monster.base_stats.hp * mult)
			monster.base_stats.max_hp = int(monster.base_stats.max_hp * mult)
			monster._refresh_ui()


func _on_monster_deployed(monster: Monster) -> void:
	_deploy_count += 1
	if _combo_tracker and monster.data:
		_combo_tracker.on_monster_deployed(monster.data.id, monster)
	_refresh_combo_hint()


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


func _on_monster_died(_unit: CombatUnit, monster: Monster) -> void:
	_loot_system.on_monster_died(monster)
	var death_pos := monster.global_position
	var death_cell := _grid.world_to_cell(death_pos)
	_grid.set_occupied(death_cell.x, death_cell.y, false)
	_pending_loot_cell = death_cell
	_handle_death_mechanics(monster, death_pos)

	var resonance_mult := 1.0
	if _tile_effects.consume_resonance_crystal():
		resonance_mult = 2.0
		_show_floating_text(death_pos, "共鸣×2!", Color(0.7, 0.4, 0.9))

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
			_hero.crit_pending = true
		_maybe_summon_undead(death_pos)
		if _hero.execute_kill_heal > 0:
			var eff := _hero.get_combat_stats()
			_hero.base_stats.hp = mini(_hero.base_stats.hp + _hero.execute_kill_heal, eff.max_hp)
			_hero.refresh_display()

	if is_instance_valid(_hero) and _hero.is_alive() and _hero.kill_heal > 0:
		var effective := _hero.get_combat_stats()
		_hero.base_stats.hp = mini(_hero.base_stats.hp + _hero.kill_heal, effective.max_hp)
		_hero.refresh_display()

	_monsters.erase(monster)
	_kill_count += 1
	if is_instance_valid(_hero) and _hero.buff_container:
		_hero.buff_container.notify_event(&"kill")
	_show_kill_milestone(_kill_count, death_pos)

	if monster == _boss_monster:
		_boss_monster = null
		_on_boss_defeated()


func _handle_death_mechanics(monster: Monster, pos: Vector2) -> void:
	if monster.death_explodes:
		_trigger_goblin_explosion(pos, monster)
	if monster.death_splits:
		_spawn_slime_splits(pos, monster.split_count)
	if monster.death_poison_puddle:
		var cell := _grid.world_to_cell(pos)
		_grid.set_tile(cell.x, cell.y, DungeonTileType.Kind.POISON_SWAMP)
		_renderer.update_tile_visual(cell, DungeonTileType.Kind.POISON_SWAMP)
		_grid.used[cell.y][cell.x] = false


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
	var source_cell := _grid.world_to_cell(pos)
	var offsets: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	offsets.shuffle()
	var spawned := 0
	for offset in offsets:
		if spawned >= count:
			break
		var tc: Vector2i = source_cell + offset
		if not _grid.is_passable(tc.x, tc.y) or _grid.is_occupied(tc.x, tc.y):
			continue
		var small_data: MonsterData = data.duplicate()
		small_data.base_stats = data.base_stats.duplicate_stats()
		small_data.base_stats.attack = 1
		small_data.base_stats.max_hp = 5
		small_data.base_stats.hp = 5
		var monster: Monster = MONSTER_SCENE.instantiate()
		_monster_container.add_child(monster)
		monster.global_position = _grid.cell_to_world(tc)
		monster.setup_monster(small_data, _hero)
		monster.death_splits = false
		if monster._body:
			monster._body.scale = Vector2(0.4, 0.4)
		_grid.set_occupied(tc.x, tc.y, true)
		register_monster(monster)
		spawned += 1


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


# --- Boss ---

func _spawn_boss() -> void:
	_boss_spawned = true
	var boss := RunManager.current_boss
	if boss == null:
		return
	_boss_monster = MONSTER_SCENE.instantiate()
	_monster_container.add_child(_boss_monster)
	_boss_monster.global_position = _grid.cell_to_world(_grid.boss_cell)
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
	_grid.set_occupied(_grid.boss_cell.x, _grid.boss_cell.y, true)
	register_monster(_boss_monster)
	_setup_boss_hp_bar(boss)
	_show_floating_text(_grid.cell_to_world(_grid.boss_cell), "Boss 出现!", Color(0.95, 0.3, 0.2))


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


func _boss_summon(monster_id: StringName) -> void:
	if monster_id == &"":
		return
	var data := DataRegistry.get_monster(monster_id)
	if data == null:
		return
	var offsets := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
					Vector2i(1, 1), Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1)]
	offsets.shuffle()
	var spawn_cell := _grid.boss_cell
	for offset in offsets:
		var tc: Vector2i = _grid.boss_cell + offset
		if _grid.is_passable(tc.x, tc.y) and not _grid.is_occupied(tc.x, tc.y):
			spawn_cell = tc
			break
	var monster: Monster = MONSTER_SCENE.instantiate()
	_monster_container.add_child(monster)
	monster.global_position = _grid.cell_to_world(spawn_cell)
	monster.setup_monster(data, _hero)
	var mult := RunManager.BOSS_DIFFICULTY
	if mult > 1.0 and monster.base_stats:
		monster.base_stats.attack = int(monster.base_stats.attack * mult)
		monster.base_stats.hp = int(monster.base_stats.hp * mult)
		monster.base_stats.max_hp = int(monster.base_stats.max_hp * mult)
		monster._refresh_ui()
	_grid.set_occupied(spawn_cell.x, spawn_cell.y, true)
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


func _on_boss_defeated() -> void:
	_battle_won = true
	set_physics_process(false)
	_show_victory_panel()


func _show_victory_panel() -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.15, 0.95)
	style.border_color = Color(0.3, 0.8, 0.4, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	panel.position = Vector2(340, 160)
	panel.size = Vector2(600, 350)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)
	var title := Label.new()
	title.text = "通关!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	vbox.add_child(title)
	var stats := Label.new()
	stats.text = "探索时间: %ds | 击杀: %d | 部署: %d" % [int(_survival_time), _kill_count, _deploy_count]
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox.add_child(stats)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	var menu_btn := Button.new()
	menu_btn.text = "返回主菜单"
	menu_btn.custom_minimum_size = Vector2(200, 44)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu_btn.pressed.connect(func(): RunManager.end_run(true))
	vbox.add_child(menu_btn)
	$UI.add_child(panel)


# --- Combo ---

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
	var kill_count: int = int(payload.get("kill_count", 2))
	match effect:
		"hero_aspd":
			_add_combo_buff(&"combo_aspd", "联动:攻速", kill_count, {"attack_speed": float(value)})
		"hero_attack":
			_add_combo_buff(&"combo_atk", "联动:攻击", kill_count, {"attack": float(value)})
		"hero_defense":
			_add_combo_buff(&"combo_def", "联动:防御", kill_count, {"defense": float(value)})
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
			var duration: float = payload.get("duration", 4.0)
			aura.setup(self, 80.0, 3, duration)


func _add_combo_buff(buff_id: StringName, name_text: String, kill_count: int, mods: Dictionary) -> void:
	if _hero.buff_container == null:
		return
	var buff := BuffDef.new()
	buff.id = buff_id
	buff.display_name = name_text
	buff.duration_type = BuffDef.DurationType.COUNTED
	buff.duration_count = kill_count
	buff.trigger_event = &"kill"
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


# --- Evolution ---

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
			match tier:
				1: _hero.crit_mult = 2.0
				2: _hero.crit_mult = 2.5
				3:
					_hero.crit_mult = 2.5
					_hero.crit_resets_cd = true
		&"shadow":
			match tier:
				1: _hero.dodge_chance = 0.2
				2:
					_hero.dodge_chance = 0.2
					_hero.dodge_buff_mult = 1.3
				3:
					_hero.dodge_chance = 0.2
					_hero.dodge_buff_mult = 1.3
					_hero.dodge_streak_per = 0.05
					_hero.dodge_streak_cap = 0.4
		&"fortress":
			match tier:
				1:
					_hero.shield_max_layers = 3
					_hero.shield_per_layer = 5
					_hero.shield_regen_interval = 5.0
				2: _hero.shield_regen_interval = 3.0
				3:
					_hero.shield_regen_interval = 3.0
					_hero.shield_break_reflect = 10
		&"brutal":
			match tier:
				1:
					_hero.execute_chance = 0.3
					_hero.execute_multiplier = 1.5
					_hero.execute_hp_threshold = 0.3
				2:
					_hero.execute_chance = 0.5
					_hero.execute_hp_threshold = 0.35
				3: _hero.execute_kill_heal = 5
		&"symbiosis":
			match tier:
				1:
					_hero.symbiosis_heal_chance = 0.25
					_hero.symbiosis_heal_amount = 5
				2:
					_hero.symbiosis_heal_chance = 0.4
					_hero.symbiosis_heal_amount = 8
				3:
					_hero.symbiosis_heal_chance = 0.4
					_hero.symbiosis_heal_amount = 8
					_hero.symbiosis_overflow_to_shield = true
		&"undead":
			match tier:
				1: _hero.undead_summon_chance = 0.2
				2: _hero.undead_summon_chance = 0.4
				3:
					_hero.undead_summon_chance = 0.4
					_hero.undead_summon_leaves_aura = true
		&"venom":
			match tier:
				1: _hero.venom_stacks_per_hit = 1
				2:
					_hero.venom_stacks_per_hit = 1
					_hero.venom_explode_at_5 = true
				3:
					_hero.venom_stacks_per_hit = 1
					_hero.venom_explode_at_5 = true
					_hero.venom_explode_spreads = true
	_hero.refresh_display()


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
	var hname := ""
	for h in HybridEvolution.get_all():
		if h.id == hybrid_id:
			hname = h.display_name
			break
	_show_evolution_text("混合演化! %s" % hname)


func _apply_hybrid_effect(hybrid_id: StringName) -> void:
	match hybrid_id:
		&"predator_shadow": _hero.dodge_to_crit = true
		&"predator_brutal": _hero.execute_kill_grants_crit = true
		&"shadow_venom": _hero.dodge_adds_venom = 2
		&"fortress_symbiosis": _hero.shield_break_heal = 5
		&"fortress_undead": _hero.emergency_summon_enabled = true
		&"brutal_venom": _hero.venom_explode_damage = 25
		&"undead_symbiosis": _hero.friendly_skeleton_death_heal = 5
		&"predator_undead": _hero.undead_force_summon = true
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


# --- Utility ---

func _show_floating_text(world_pos: Vector2, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("outline_size", 4)
	label.position = world_pos - Vector2(30, 20)
	label.size = Vector2(80, 18)
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


func _roman(tier: int) -> String:
	match tier:
		1: return "I"
		2: return "II"
		3: return "III"
		_: return str(tier)


func _on_hero_died(_unit: CombatUnit) -> void:
	if _game_over:
		return
	_game_over = true
	set_physics_process(false)
	_game_over_panel.visible = true


func _on_restart_pressed() -> void:
	if RunManager.in_run:
		RunManager.start_run()
	else:
		GameManager.go_to_battle()


func _on_menu_pressed() -> void:
	if RunManager.in_run:
		RunManager.end_run(false)
	GameManager.go_to_main_menu()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _game_over:
		_on_restart_pressed()


func _on_tile_clicked(cell: Vector2i, screen_pos: Vector2) -> void:
	if _game_over:
		return
	if not _grid.in_bounds(cell.x, cell.y) or not _grid.is_revealed(cell.x, cell.y):
		_hide_tile_info()
		return
	var kind := _grid.get_tile(cell.x, cell.y)
	if cell == _tile_info_cell or kind == DungeonTileType.Kind.WALL or kind == DungeonTileType.Kind.EMPTY:
		_hide_tile_info()
		return
	_show_tile_info(cell, kind, screen_pos)


func _show_tile_info(cell: Vector2i, kind: int, screen_pos: Vector2) -> void:
	_tile_info_cell = cell
	var name_text := DungeonTileType.get_display_name(kind)
	var desc_text := DungeonTileType.get_description(kind)
	var tile_color := DungeonTileType.get_color(kind).lightened(0.3)
	_tile_info_title.text = name_text
	_tile_info_title.add_theme_color_override("font_color", tile_color)
	_tile_info_desc.text = desc_text
	var status_text := ""
	var status_color := Color(0.5, 0.55, 0.65)
	if _grid.is_used(cell.x, cell.y) and DungeonTileType.is_one_shot(kind):
		status_text = "已使用"
		status_color = Color(0.5, 0.5, 0.5)
	elif not DungeonTileType.is_one_shot(kind) and kind != DungeonTileType.Kind.SPAWN_POINT:
		status_text = "可重复触发"
		status_color = Color(0.4, 0.8, 0.5)
	else:
		status_text = "一次性"
		status_color = Color(0.85, 0.75, 0.4)
	if _grid.is_occupied(cell.x, cell.y):
		status_text += " | 有怪物"
	_tile_info_status.text = status_text
	_tile_info_status.add_theme_color_override("font_color", status_color)
	var px := clampf(screen_pos.x - 80, 8, 1100)
	var py := clampf(screen_pos.y - 90, 8, 500)
	_tile_info_panel.position = Vector2(px, py)
	_tile_info_panel.visible = true


func _hide_tile_info() -> void:
	_tile_info_panel.visible = false
	_tile_info_cell = Vector2i(-1, -1)
