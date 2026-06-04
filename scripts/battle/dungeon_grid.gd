class_name DungeonGrid
extends RefCounted

const GRID_W := 30
const GRID_H := 20
const CELL_SIZE := 64

var tiles: Array = []  # [y][x] = int (DungeonTileType.Kind)
var occupied: Array = []  # [y][x] = bool (monster present)
var revealed: Array = []  # [y][x] = bool (fog cleared)
var used: Array = []  # [y][x] = bool (one-shot effect consumed)
var rooms: Array[Rect2i] = []
var spawn_cell := Vector2i(2, 17)
var boss_cell := Vector2i(27, 2)
var teleporter_pairs: Array[Array] = []


func _init() -> void:
	tiles.resize(GRID_H)
	occupied.resize(GRID_H)
	revealed.resize(GRID_H)
	used.resize(GRID_H)
	for y in GRID_H:
		tiles[y] = []
		occupied[y] = []
		revealed[y] = []
		used[y] = []
		tiles[y].resize(GRID_W)
		occupied[y].resize(GRID_W)
		revealed[y].resize(GRID_W)
		used[y].resize(GRID_W)
		for x in GRID_W:
			tiles[y][x] = DungeonTileType.Kind.WALL
			occupied[y][x] = false
			revealed[y][x] = false
			used[y][x] = false


func get_tile(x: int, y: int) -> int:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return DungeonTileType.Kind.WALL
	return tiles[y][x]


func set_tile(x: int, y: int, kind: int) -> void:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return
	tiles[y][x] = kind


func is_passable(x: int, y: int) -> bool:
	return DungeonTileType.is_passable(get_tile(x, y))


func is_deployable(x: int, y: int) -> bool:
	if not is_passable(x, y):
		return false
	if not is_revealed(x, y):
		return false
	if is_occupied(x, y):
		return false
	return true


func is_occupied(x: int, y: int) -> bool:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return true
	return occupied[y][x]


func set_occupied(x: int, y: int, val: bool) -> void:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return
	occupied[y][x] = val


func is_revealed(x: int, y: int) -> bool:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return false
	return revealed[y][x]


func reveal_around(cx: int, cy: int, radius: int) -> Array[Vector2i]:
	var newly: Array[Vector2i] = []
	for dy in range(-radius, radius + 1):
		for dx in range(-radius, radius + 1):
			if absi(dx) + absi(dy) > radius:
				continue
			var nx: int = cx + dx
			var ny: int = cy + dy
			if nx < 0 or nx >= GRID_W or ny < 0 or ny >= GRID_H:
				continue
			if not _has_line_of_sight(cx, cy, nx, ny):
				continue
			if not revealed[ny][nx]:
				revealed[ny][nx] = true
				newly.append(Vector2i(nx, ny))
	return newly


func _has_line_of_sight(x0: int, y0: int, x1: int, y1: int) -> bool:
	if x0 == x1 and y0 == y1:
		return true
	var dx: int = absi(x1 - x0)
	var dy: int = absi(y1 - y0)
	var sx: int = 1 if x0 < x1 else -1
	var sy: int = 1 if y0 < y1 else -1
	var err: int = dx - dy
	var x: int = x0
	var y: int = y0
	while true:
		if x == x1 and y == y1:
			return true
		# Intermediate cells must not be walls (skip the origin)
		if (x != x0 or y != y0) and tiles[y][x] == DungeonTileType.Kind.WALL:
			return false
		var e2: int = 2 * err
		if e2 > -dy:
			err -= dy
			x += sx
		if e2 < dx:
			err += dx
			y += sy
	return true


func is_used(x: int, y: int) -> bool:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return true
	return used[y][x]


func mark_used(x: int, y: int) -> void:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return
	used[y][x] = true


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / CELL_SIZE), int(pos.y / CELL_SIZE))


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_W and y >= 0 and y < GRID_H


func get_path_distance_to_spawn(x: int, y: int) -> int:
	return absi(x - spawn_cell.x) + absi(y - spawn_cell.y)
