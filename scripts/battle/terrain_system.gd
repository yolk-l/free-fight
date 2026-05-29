# Manages both permanent map terrain zones and temporary area effects
# (持续性范围效果, spawned by evolution passives on kill).
class_name TerrainSystem
extends Node2D

const TERRAIN_CELL_SCRIPT := preload("res://scripts/battle/terrain_cell.gd")
const MAP_ZONE_SCRIPT := preload("res://scripts/battle/map_terrain_zone.gd")
const MIN_SPAWN_X := 500.0
const MAX_SPAWN_X := 1180.0
const MIN_SPAWN_Y := 130.0
const MAX_SPAWN_Y := 480.0
const MIN_CELL_DISTANCE := 150.0
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
var _map_zones: Array[MapTerrainZone] = []
var _hero: Hero = null
var _battle_controller: Node = null
var _poison_puddles: Array[Dictionary] = []
var _thorns_tick: Dictionary = {}
var _brambles_tick: Dictionary = {}

const BRAMBLES_DAMAGE_PER_SEC := 3.0
const MAP_ZONE_MIN_DISTANCE := 180.0


func setup(hero: Hero, controller: Node) -> void:
	_hero = hero
	_battle_controller = controller


func generate_map_terrain(count: int) -> void:
	var kinds := MapTerrainType.get_all_kinds()
	var positions: Array[Vector2] = []
	var attempts := 0
	while positions.size() < count and attempts < 200:
		attempts += 1
		var pos := Vector2(
			randf_range(MIN_SPAWN_X, MAX_SPAWN_X),
			randf_range(MIN_SPAWN_Y, MAX_SPAWN_Y)
		)
		var ok := true
		for p in positions:
			if p.distance_to(pos) < MAP_ZONE_MIN_DISTANCE:
				ok = false
				break
		if ok:
			positions.append(pos)
	for pos in positions:
		var kind: int = kinds[randi() % kinds.size()]
		var zone: MapTerrainZone = MAP_ZONE_SCRIPT.new()
		add_child(zone)
		zone.setup(kind, pos)
		_map_zones.append(zone)


func get_map_terrain_at(pos: Vector2) -> int:
	for zone in _map_zones:
		if zone.contains_point(pos):
			return zone.kind
	return -1


func tick_map_terrain(delta: float, monsters: Array[Monster]) -> void:
	for monster in monsters:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var on_brambles := false
		for zone in _map_zones:
			if zone.kind == MapTerrainType.Kind.BRAMBLES and zone.contains_point(monster.global_position):
				on_brambles = true
				break
		if not on_brambles:
			_brambles_tick.erase(monster.get_instance_id())
			continue
		var key := monster.get_instance_id()
		var t: float = _brambles_tick.get(key, 0.0) + delta
		while t >= 1.0:
			monster.take_damage(int(BRAMBLES_DAMAGE_PER_SEC))
			t -= 1.0
		_brambles_tick[key] = t


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
			randf_range(MIN_SPAWN_X, MAX_SPAWN_X),
			randf_range(MIN_SPAWN_Y, MAX_SPAWN_Y)
		)
		var ok := true
		for p in positions:
			if p.distance_to(pos) < MIN_CELL_DISTANCE:
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
	# Reset SHADOW flags each frame; will be re-applied below if still inside.
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


# Returns the resonance multiplier (1 + bonus) for a monster dying at pos, and
# triggers death-time terrain effects (node explosion, poison puddle).
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


func spawn_poison_puddle(pos: Vector2) -> void:
	_poison_puddles.append({"pos": pos, "remaining": POISON_PUDDLE_DURATION, "tick": 0.0})
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
		var alpha: float = clampf(puddle["remaining"] / POISON_PUDDLE_DURATION, 0.0, 1.0)
		var c := Color(0.3, 0.85, 0.3, 0.35 * alpha)
		draw_circle(puddle["pos"], POISON_PUDDLE_RADIUS, c)
