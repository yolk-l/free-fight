class_name DungeonGrid
extends RefCounted

const GRID_W := GameConfig.ROOM_W
const GRID_H := GameConfig.ROOM_H
const CELL_SIZE := GameConfig.GRID_CELL_SIZE

var tiles: Array = []  # [y][x] = int (DungeonTileType.Kind)
var occupied: Array = []  # [y][x] = bool (monster present)
var used: Array = []  # [y][x] = bool (event cleared)
var rooms: Array[Rect2i] = []
var spawn_cell := Vector2i(GRID_W / 2, GRID_H / 2)

var event_cells: Array[Vector2i] = []
var exit_cells: Dictionary = {}  # {Vector2i: int} -> target room index
var exits_open: bool = false


func _init() -> void:
	tiles.resize(GRID_H)
	occupied.resize(GRID_H)
	used.resize(GRID_H)
	for y in GRID_H:
		tiles[y] = []
		occupied[y] = []
		used[y] = []
		tiles[y].resize(GRID_W)
		occupied[y].resize(GRID_W)
		used[y].resize(GRID_W)
		for x in GRID_W:
			tiles[y][x] = DungeonTileType.Kind.WALL
			occupied[y][x] = false
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
	var kind := get_tile(x, y)
	if kind == DungeonTileType.Kind.EXIT:
		return exits_open
	return DungeonTileType.is_passable(kind)


func is_deployable(x: int, y: int) -> bool:
	if not in_bounds(x, y):
		return false
	if is_occupied(x, y):
		return false
	var kind := get_tile(x, y)
	return DungeonTileType.is_event(kind) and not is_used(x, y)


func is_event_tile(x: int, y: int) -> bool:
	return DungeonTileType.is_event(get_tile(x, y))


func is_occupied(x: int, y: int) -> bool:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return true
	return occupied[y][x]


func set_occupied(x: int, y: int, val: bool) -> void:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return
	occupied[y][x] = val


func is_used(x: int, y: int) -> bool:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return true
	return used[y][x]


func mark_used(x: int, y: int) -> void:
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return
	used[y][x] = true


func mark_event_cleared(x: int, y: int) -> void:
	mark_used(x, y)


func are_all_events_cleared() -> bool:
	for cell in event_cells:
		if not is_used(cell.x, cell.y):
			return false
	return true


func get_remaining_event_count() -> int:
	var count := 0
	for cell in event_cells:
		if not is_used(cell.x, cell.y):
			count += 1
	return count


func open_exits() -> void:
	exits_open = true


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL_SIZE + CELL_SIZE * 0.5, cell.y * CELL_SIZE + CELL_SIZE * 0.5)


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / CELL_SIZE), int(pos.y / CELL_SIZE))


func in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_W and y >= 0 and y < GRID_H
