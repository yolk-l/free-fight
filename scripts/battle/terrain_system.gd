# Manages both permanent map terrain zones and temporary area effects
# (持续性范围效果, spawned by evolution passives on kill).
class_name TerrainSystem
extends Node2D

const TERRAIN_CELL_SCRIPT := preload("res://scripts/battle/terrain_cell.gd")
const FIELD_LEFT := 40.0
const FIELD_TOP := 50.0
const FIELD_RIGHT := 1240.0
const FIELD_BOTTOM := 560.0
const RENDER_SCALE := 4
const BLEND_RANGE := 40.0
const SEED_MIN_DISTANCE := 120.0
const SEED_COUNT_MIN := 8
const SEED_COUNT_MAX := 12
const POISON_PUDDLE_RADIUS := 60.0
const POISON_PUDDLE_DAMAGE_PER_SEC := 2.0
const POISON_PUDDLE_DURATION := 5.0
const NODE_EXPLOSION_RADIUS := 100.0
const NODE_EXPLOSION_DAMAGE := 12
const THORNS_DAMAGE_PER_SEC := 4.0
const SHADOW_SPEED_MULT := 1.5
const SHADOW_ATTACK_BONUS_PCT := 0.3
const SANCTUARY_STUN_SEC := 2.5

signal effect_triggered(world_pos: Vector2, text: String, color: Color)

var _cells: Array[TerrainCell] = []
var _terrain_seeds: Array[Dictionary] = []
var _terrain_sprite: Sprite2D = null
var _hero: Hero = null
var _battle_controller: Node = null
var _poison_puddles: Array[Dictionary] = []
var _thorns_tick: Dictionary = {}


func setup(hero: Hero, controller: Node) -> void:
	_hero = hero
	_battle_controller = controller


func generate_map_terrain(_count: int = 0) -> void:
	var kinds := MapTerrainType.get_all_kinds()
	var all_kinds := kinds.duplicate()
	all_kinds.shuffle()
	var num_seeds := randi_range(SEED_COUNT_MIN, SEED_COUNT_MAX)
	var positions: Array[Vector2] = []
	var attempts := 0
	while positions.size() < num_seeds and attempts < 500:
		attempts += 1
		var pos := Vector2(
			randf_range(FIELD_LEFT + 30, FIELD_RIGHT - 30),
			randf_range(FIELD_TOP + 20, FIELD_BOTTOM - 20)
		)
		var ok := true
		for p in positions:
			if p.distance_to(pos) < SEED_MIN_DISTANCE:
				ok = false
				break
		if ok:
			positions.append(pos)
	for i in positions.size():
		var kind: int
		if i < all_kinds.size():
			kind = all_kinds[i]
		else:
			kind = kinds[randi() % kinds.size()]
		_terrain_seeds.append({"pos": positions[i], "kind": kind})
	_create_terrain_texture()
	_create_terrain_labels()


func get_map_terrain_at(pos: Vector2) -> int:
	var best_dist := INF
	var best_kind := -1
	for seed_data in _terrain_seeds:
		var d: float = pos.distance_squared_to(seed_data["pos"])
		if d < best_dist:
			best_dist = d
			best_kind = seed_data["kind"]
	return best_kind


func tick_map_terrain(_delta: float, _monsters: Array[Monster]) -> void:
	pass


func _create_terrain_texture() -> void:
	var w := int((FIELD_RIGHT - FIELD_LEFT) / RENDER_SCALE)
	var h := int((FIELD_BOTTOM - FIELD_TOP) / RENDER_SCALE)
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var world_pos := Vector2(
				FIELD_LEFT + (x + 0.5) * RENDER_SCALE,
				FIELD_TOP + (y + 0.5) * RENDER_SCALE
			)
			var best_dist := INF
			var second_dist := INF
			var best_kind := 0
			var second_kind := 0
			for seed_data in _terrain_seeds:
				var d: float = world_pos.distance_to(seed_data["pos"])
				if d < best_dist:
					second_dist = best_dist
					second_kind = best_kind
					best_dist = d
					best_kind = seed_data["kind"]
				elif d < second_dist:
					second_dist = d
					second_kind = seed_data["kind"]
			var col := MapTerrainType.get_color(best_kind)
			var diff := second_dist - best_dist
			if diff < BLEND_RANGE and best_kind != second_kind:
				var t := diff / BLEND_RANGE
				var col2 := MapTerrainType.get_color(second_kind)
				col = col.lerp(col2, (1.0 - t) * 0.5)
			var border_thickness := 6.0
			if diff < border_thickness and best_kind != second_kind:
				col = Color(0.9, 0.9, 0.85, 0.5)
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	_terrain_sprite = Sprite2D.new()
	_terrain_sprite.texture = tex
	_terrain_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_terrain_sprite.centered = false
	_terrain_sprite.scale = Vector2(RENDER_SCALE, RENDER_SCALE)
	_terrain_sprite.position = Vector2(FIELD_LEFT, FIELD_TOP)
	add_child(_terrain_sprite)
	move_child(_terrain_sprite, 0)


func _create_terrain_labels() -> void:
	for seed_data in _terrain_seeds:
		var kind: int = seed_data["kind"]
		var pos: Vector2 = seed_data["pos"]
		var label := Label.new()
		label.text = MapTerrainType.get_display_name(kind)
		label.add_theme_font_size_override("font_size", 13)
		label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
		label.add_theme_constant_override("outline_size", 4)
		label.position = pos - Vector2(28, 20)
		label.size = Vector2(56, 20)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(label)
		var hint := MapTerrainType.get_effect_hint(kind)
		if not hint.is_empty():
			var hint_label := Label.new()
			hint_label.text = hint
			hint_label.add_theme_font_size_override("font_size", 10)
			hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
			hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.6))
			hint_label.add_theme_constant_override("outline_size", 3)
			hint_label.position = pos - Vector2(65, 4)
			hint_label.size = Vector2(130, 36)
			hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
			add_child(hint_label)


func generate(count: int) -> void:
	for cell in _cells:
		cell.queue_free()
	_cells.clear()
	var kinds := TerrainType.get_all_kinds()
	var positions: Array[Vector2] = []
	var attempts := 0
	while positions.size() < count and attempts < 200:
		attempts += 1
		var pos := Vector2(
			randf_range(FIELD_LEFT, FIELD_RIGHT),
			randf_range(FIELD_TOP, FIELD_BOTTOM)
		)
		var ok := true
		for p in positions:
			if p.distance_to(pos) < 150.0:
				ok = false
				break
		if ok:
			positions.append(pos)
	for pos in positions:
		var kind: int = kinds[randi() % kinds.size()]
		var cell: TerrainCell = TERRAIN_CELL_SCRIPT.new()
		add_child(cell)
		cell.setup(kind, pos)
		cell.expired.connect(_on_cell_expired)
		_cells.append(cell)


func spawn_terrain_at(kind: int, pos: Vector2, duration: float) -> TerrainCell:
	var cell: TerrainCell = TERRAIN_CELL_SCRIPT.new()
	add_child(cell)
	cell.setup(kind, pos, duration)
	cell.expired.connect(_on_cell_expired)
	_cells.append(cell)
	cell.pulse()
	return cell


func _on_cell_expired(cell: TerrainCell) -> void:
	_cells.erase(cell)


func process_monsters(delta: float, monsters: Array[Monster]) -> void:
	for monster in monsters:
		if is_instance_valid(monster) and monster.is_alive() and monster._in_shadow_terrain:
			monster.clear_shadow_aura()
	for monster in monsters:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		if monster.is_flying:
			continue
		for cell in _cells:
			if not cell.contains_point(monster.global_position):
				continue
			_apply_enter_effect(monster, cell)
			_apply_tick_effect(monster, cell, delta)
			_apply_continuous_effect(monster, cell)
	_tick_poison_puddles(delta)


func _apply_enter_effect(monster: Monster, cell: TerrainCell) -> void:
	if cell.is_visited(monster):
		return
	cell.mark_visited(monster)
	match cell.kind:
		TerrainType.Kind.SANCTUARY:
			monster.stun(SANCTUARY_STUN_SEC)
			cell.pulse()
			effect_triggered.emit(cell.global_position, "眩晕!", Color(1.0, 0.95, 0.4))


func _apply_tick_effect(monster: Monster, cell: TerrainCell, delta: float) -> void:
	match cell.kind:
		TerrainType.Kind.THORNS:
			var key := monster.get_instance_id()
			var t: float = _thorns_tick.get(key, 0.0) + delta
			var ticked := false
			while t >= 1.0:
				monster.take_damage(int(THORNS_DAMAGE_PER_SEC))
				t -= 1.0
				ticked = true
			_thorns_tick[key] = t
			if ticked:
				cell.pulse()
				effect_triggered.emit(monster.global_position, "-%d" % int(THORNS_DAMAGE_PER_SEC), Color(0.95, 0.5, 0.3))


func _apply_continuous_effect(monster: Monster, cell: TerrainCell) -> void:
	if cell.kind == TerrainType.Kind.SHADOW:
		if not monster._in_shadow_terrain:
			cell.pulse()
			effect_triggered.emit(monster.global_position, "暗影!", Color(0.7, 0.4, 1.0))
		monster.apply_shadow_aura(SHADOW_SPEED_MULT, SHADOW_ATTACK_BONUS_PCT)


func on_monster_died(monster: Monster, pos: Vector2) -> float:
	var multiplier := 1.0
	for cell in _cells:
		if not cell.contains_point(pos):
			continue
		match cell.kind:
			TerrainType.Kind.RESONANCE_ALTAR:
				multiplier *= 2.0
				cell.pulse()
				effect_triggered.emit(pos, "+共鸣!", Color(0.85, 0.5, 1.0))
			TerrainType.Kind.RESONANCE_NODE:
				_trigger_node_explosion(pos, monster)
				cell.pulse()
				effect_triggered.emit(pos, "爆炸 %d!" % NODE_EXPLOSION_DAMAGE, Color(0.4, 0.8, 1.0))
			TerrainType.Kind.POISON_LAND:
				_spawn_poison_puddle(pos)
				cell.pulse()
				effect_triggered.emit(pos, "毒池!", Color(0.4, 1.0, 0.5))
	_thorns_tick.erase(monster.get_instance_id())
	return multiplier


func _trigger_node_explosion(pos: Vector2, source: Monster) -> void:
	if _battle_controller == null:
		return
	var monsters: Array = _battle_controller.get("_monsters") if "_monsters" in _battle_controller else []
	for m in monsters:
		if m == source or not is_instance_valid(m) or not m.is_alive():
			continue
		if pos.distance_to(m.global_position) <= NODE_EXPLOSION_RADIUS:
			m.take_damage(NODE_EXPLOSION_DAMAGE)


func _spawn_poison_puddle(pos: Vector2) -> void:
	spawn_poison_puddle(pos)


func spawn_poison_puddle(pos: Vector2, duration: float = POISON_PUDDLE_DURATION) -> void:
	_poison_puddles.append({"pos": pos, "remaining": duration, "max_duration": duration, "tick": 0.0})
	queue_redraw()


func _tick_poison_puddles(delta: float) -> void:
	if _poison_puddles.is_empty():
		return
	var changed := false
	var i := _poison_puddles.size() - 1
	while i >= 0:
		var puddle: Dictionary = _poison_puddles[i]
		puddle["remaining"] -= delta
		puddle["tick"] += delta
		while puddle["tick"] >= 1.0:
			puddle["tick"] -= 1.0
			if _hero != null and _hero.is_alive():
				if puddle["pos"].distance_to(_hero.global_position) <= POISON_PUDDLE_RADIUS:
					_hero.take_damage(int(POISON_PUDDLE_DAMAGE_PER_SEC))
		if puddle["remaining"] <= 0.0:
			_poison_puddles.remove_at(i)
			changed = true
		else:
			_poison_puddles[i] = puddle
		i -= 1
	if changed or not _poison_puddles.is_empty():
		queue_redraw()


func _draw() -> void:
	for puddle in _poison_puddles:
		var max_dur: float = puddle.get("max_duration", POISON_PUDDLE_DURATION)
		var alpha: float = clampf(puddle["remaining"] / max_dur, 0.0, 1.0)
		var c := Color(0.3, 0.85, 0.3, 0.35 * alpha)
		draw_circle(puddle["pos"], POISON_PUDDLE_RADIUS, c)
