class_name MapGenerator
extends RefCounted

const MIN_ROOM_SIZE := 5
const MAX_ROOM_SIZE := 8
const ROOM_COUNT_MIN := 4
const ROOM_COUNT_MAX := 6
const CORRIDOR_WIDTH := 2
const REVEAL_RADIUS := 3


func generate() -> DungeonGrid:
	var grid := DungeonGrid.new()
	var rooms := _place_rooms(grid)
	grid.rooms = rooms
	_connect_rooms(grid, rooms)
	_place_spawn(grid, rooms)
	_place_boss(grid, rooms)
	_place_teleporters(grid, rooms)
	_populate_tile_effects(grid)
	grid.reveal_around(grid.spawn_cell.x, grid.spawn_cell.y, REVEAL_RADIUS)
	return grid


func _place_rooms(grid: DungeonGrid) -> Array[Rect2i]:
	var rooms: Array[Rect2i] = []
	var attempts := 0
	var target := randi_range(ROOM_COUNT_MIN, ROOM_COUNT_MAX)
	while rooms.size() < target and attempts < 400:
		attempts += 1
		var w := randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var h := randi_range(MIN_ROOM_SIZE, MAX_ROOM_SIZE)
		var x := randi_range(1, DungeonGrid.GRID_W - w - 1)
		var y := randi_range(1, DungeonGrid.GRID_H - h - 1)
		var room := Rect2i(x, y, w, h)
		var overlaps := false
		for existing in rooms:
			if room.grow(2).intersects(existing):
				overlaps = true
				break
		if overlaps:
			continue
		rooms.append(room)
		_carve_room(grid, room)
	return rooms


func _carve_room(grid: DungeonGrid, room: Rect2i) -> void:
	for y in range(room.position.y, room.end.y):
		for x in range(room.position.x, room.end.x):
			grid.set_tile(x, y, DungeonTileType.Kind.EMPTY)


func _connect_rooms(grid: DungeonGrid, rooms: Array[Rect2i]) -> void:
	if rooms.size() < 2:
		return
	var connected: Array[int] = [0]
	var unconnected: Array[int] = []
	for i in range(1, rooms.size()):
		unconnected.append(i)
	while not unconnected.is_empty():
		var best_from := -1
		var best_to := -1
		var best_dist := INF
		for ci in connected:
			for ui in unconnected:
				var d := _room_center(rooms[ci]).distance_to(_room_center(rooms[ui]))
				if d < best_dist:
					best_dist = d
					best_from = ci
					best_to = ui
		if best_to < 0:
			break
		_carve_corridor(grid, _room_center(rooms[best_from]), _room_center(rooms[best_to]))
		connected.append(best_to)
		unconnected.erase(best_to)


func _room_center(room: Rect2i) -> Vector2i:
	return Vector2i(room.position.x + room.size.x / 2, room.position.y + room.size.y / 2)


func _carve_corridor(grid: DungeonGrid, from: Vector2i, to: Vector2i) -> void:
	var x := from.x
	var y := from.y
	var dir_x := 1 if to.x > from.x else -1
	var dir_y := 1 if to.y > from.y else -1
	if randi() % 2 == 0:
		while x != to.x:
			_carve_corridor_segment(grid, x, y)
			x += dir_x
		while y != to.y:
			_carve_corridor_segment(grid, x, y)
			y += dir_y
	else:
		while y != to.y:
			_carve_corridor_segment(grid, x, y)
			y += dir_y
		while x != to.x:
			_carve_corridor_segment(grid, x, y)
			x += dir_x
	_carve_corridor_segment(grid, to.x, to.y)


func _carve_corridor_segment(grid: DungeonGrid, cx: int, cy: int) -> void:
	for dy in CORRIDOR_WIDTH:
		for dx in CORRIDOR_WIDTH:
			var nx: int = cx + dx
			var ny: int = cy + dy
			if grid.in_bounds(nx, ny):
				if grid.get_tile(nx, ny) == DungeonTileType.Kind.WALL:
					grid.set_tile(nx, ny, DungeonTileType.Kind.EMPTY)


func _place_spawn(grid: DungeonGrid, rooms: Array[Rect2i]) -> void:
	if rooms.is_empty():
		return
	var best_idx := 0
	var best_score := INF
	for i in rooms.size():
		var c := _room_center(rooms[i])
		var score: float = c.x + c.y * 0.5
		if score < best_score:
			best_score = score
			best_idx = i
	var spawn_room := rooms[best_idx]
	var cx := spawn_room.position.x + spawn_room.size.x / 2
	var cy := spawn_room.position.y + spawn_room.size.y / 2
	grid.spawn_cell = Vector2i(cx, cy)
	grid.set_tile(cx, cy, DungeonTileType.Kind.SPAWN_POINT)


func _place_boss(grid: DungeonGrid, rooms: Array[Rect2i]) -> void:
	if rooms.is_empty():
		return
	var best_idx := 0
	var best_dist := 0.0
	var spawn := Vector2(grid.spawn_cell)
	for i in rooms.size():
		var c := _room_center(rooms[i])
		var d := spawn.distance_to(Vector2(c))
		if d > best_dist:
			best_dist = d
			best_idx = i
	var boss_room := rooms[best_idx]
	var cx := boss_room.position.x + boss_room.size.x / 2
	var cy := boss_room.position.y + boss_room.size.y / 2
	grid.boss_cell = Vector2i(cx, cy)
	grid.set_tile(cx, cy, DungeonTileType.Kind.BOSS_GATE)


func _place_teleporters(grid: DungeonGrid, rooms: Array[Rect2i]) -> void:
	if rooms.size() < 3:
		return
	var candidates: Array[int] = []
	for i in rooms.size():
		var c := _room_center(rooms[i])
		if c == grid.spawn_cell or c == grid.boss_cell:
			continue
		candidates.append(i)
	if candidates.size() < 2:
		return
	candidates.shuffle()
	var r0 := rooms[candidates[0]]
	var r1 := rooms[candidates[1]]
	var p0 := Vector2i(r0.position.x + 1, r0.position.y + 1)
	var p1 := Vector2i(r1.position.x + 1, r1.position.y + 1)
	grid.set_tile(p0.x, p0.y, DungeonTileType.Kind.TELEPORTER)
	grid.set_tile(p1.x, p1.y, DungeonTileType.Kind.TELEPORTER)
	grid.teleporter_pairs.append([p0, p1])


func _populate_tile_effects(grid: DungeonGrid) -> void:
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			if grid.get_tile(x, y) != DungeonTileType.Kind.EMPTY:
				continue
			var cell := Vector2i(x, y)
			if cell == grid.spawn_cell or cell == grid.boss_cell:
				continue
			var dist := grid.get_path_distance_to_spawn(x, y)
			var kind := _roll_tile_for_distance(dist)
			if kind != DungeonTileType.Kind.EMPTY:
				grid.set_tile(x, y, kind)
	_place_vision_towers(grid)


func _roll_tile_for_distance(dist: int) -> int:
	var empty_weight: float
	var positive_weight: float
	var negative_weight: float
	var mystery_weight: float
	var treasure_weight: float
	if dist <= 5:
		empty_weight = 70.0
		positive_weight = 25.0
		negative_weight = 0.0
		mystery_weight = 5.0
		treasure_weight = 0.0
	elif dist <= 15:
		empty_weight = 55.0
		positive_weight = 18.0
		negative_weight = 12.0
		mystery_weight = 12.0
		treasure_weight = 3.0
	elif dist <= 25:
		empty_weight = 45.0
		positive_weight = 15.0
		negative_weight = 20.0
		mystery_weight = 15.0
		treasure_weight = 5.0
	else:
		empty_weight = 40.0
		positive_weight = 12.0
		negative_weight = 25.0
		mystery_weight = 15.0
		treasure_weight = 8.0

	var total := empty_weight + positive_weight + negative_weight + mystery_weight + treasure_weight
	var roll := randf() * total
	roll -= empty_weight
	if roll < 0.0:
		return DungeonTileType.Kind.EMPTY
	roll -= treasure_weight
	if roll < 0.0:
		return DungeonTileType.Kind.TREASURE_CHEST
	roll -= positive_weight
	if roll < 0.0:
		var positives := [
			DungeonTileType.Kind.HEAL_SPRING,
			DungeonTileType.Kind.POWER_ALTAR,
			DungeonTileType.Kind.IRON_ALTAR,
			DungeonTileType.Kind.RESONANCE_CRYSTAL,
		]
		return positives[randi() % positives.size()]
	roll -= negative_weight
	if roll < 0.0:
		var negatives := [
			DungeonTileType.Kind.POISON_SWAMP,
			DungeonTileType.Kind.TRAP,
			DungeonTileType.Kind.CURSED_GROUND,
			DungeonTileType.Kind.SLOW_MUD,
		]
		return negatives[randi() % negatives.size()]
	return DungeonTileType.Kind.MYSTERY


func _place_vision_towers(grid: DungeonGrid) -> void:
	var placed := 0
	var attempts := 0
	while placed < 3 and attempts < 100:
		attempts += 1
		var x := randi_range(2, DungeonGrid.GRID_W - 3)
		var y := randi_range(2, DungeonGrid.GRID_H - 3)
		if grid.get_tile(x, y) == DungeonTileType.Kind.EMPTY:
			var dist := grid.get_path_distance_to_spawn(x, y)
			if dist > 6:
				grid.set_tile(x, y, DungeonTileType.Kind.VISION_TOWER)
				placed += 1
