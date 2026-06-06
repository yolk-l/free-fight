class_name MapGenerator
extends RefCounted

const ROOM_W := DungeonGrid.GRID_W
const ROOM_H := DungeonGrid.GRID_H


func generate() -> WorldMap:
	var world := WorldMap.new()
	var room_count := randi_range(GameConfig.ROOM_COUNT_MIN, GameConfig.ROOM_COUNT_MAX)
	_build_tree(world, room_count)
	_assign_room_types(world)
	_generate_all_rooms(world)
	return world


func _build_tree(world: WorldMap, count: int) -> void:
	world.room_depth.resize(count)
	world.room_cleared.resize(count)
	for i in count:
		world.room_depth[i] = 0
		world.room_cleared[i] = false

	# Build tree using random parent assignment
	for i in range(1, count):
		var parent := randi_range(0, i - 1)
		world.tree_edges.append([parent, i])

	# Compute depths via BFS
	var queue: Array[int] = [0]
	world.room_depth[0] = 0
	var visited := PackedByteArray()
	visited.resize(count)
	visited[0] = 1
	while not queue.is_empty():
		var current := queue[0]
		queue.remove_at(0)
		for edge in world.tree_edges:
			var neighbor := -1
			if edge[0] == current:
				neighbor = edge[1]
			elif edge[1] == current:
				neighbor = edge[0]
			if neighbor >= 0 and not visited[neighbor]:
				visited[neighbor] = 1
				world.room_depth[neighbor] = world.room_depth[current] + 1
				queue.append(neighbor)


func _assign_room_types(world: WorldMap) -> void:
	var count := world.room_depth.size()
	world.room_types.resize(count)

	# Find the deepest leaf for boss
	var max_depth := 0
	var boss_idx := count - 1
	for i in count:
		if world.room_depth[i] > max_depth:
			max_depth = world.room_depth[i]
			boss_idx = i

	world.room_types[0] = WorldMap.RoomType.START
	world.room_types[boss_idx] = WorldMap.RoomType.BOSS

	# Assign remaining rooms
	var special_pool: Array[int] = [
		WorldMap.RoomType.TREASURE,
		WorldMap.RoomType.DANGER,
		WorldMap.RoomType.ELITE,
	]
	special_pool.shuffle()
	var special_idx := 0

	for i in range(1, count):
		if i == boss_idx:
			continue
		if special_idx < special_pool.size() and world.room_depth[i] >= 2:
			world.room_types[i] = special_pool[special_idx]
			special_idx += 1
		else:
			world.room_types[i] = WorldMap.RoomType.NORMAL


func _generate_all_rooms(world: WorldMap) -> void:
	var count := world.room_depth.size()
	world.rooms.resize(count)

	for i in count:
		var grid := DungeonGrid.new()
		var room_type: int = world.room_types[i]
		_carve_room_layout(grid)
		_place_spawn_point(grid)

		if room_type != WorldMap.RoomType.BOSS:
			_place_events(grid, room_type)
		else:
			grid.set_tile(grid.spawn_cell.x, grid.spawn_cell.y, DungeonTileType.Kind.SPAWN_POINT)

		_place_exits(grid, i, world)
		world.rooms[i] = grid


func _carve_room_layout(grid: DungeonGrid) -> void:
	# Carve open area with wall border
	for y in range(1, ROOM_H - 1):
		for x in range(1, ROOM_W - 1):
			grid.set_tile(x, y, DungeonTileType.Kind.EMPTY)

	# Add a few single-cell wall pillars for variety (room is small)
	var pillar_count := randi_range(0, 2)
	for _c in pillar_count:
		var cx := randi_range(2, ROOM_W - 3)
		var cy := randi_range(2, ROOM_H - 3)
		grid.set_tile(cx, cy, DungeonTileType.Kind.WALL)


func _place_spawn_point(grid: DungeonGrid) -> void:
	# Place spawn in center area
	var cx := ROOM_W / 2
	var cy := ROOM_H / 2
	# Find nearest passable cell to center
	for radius in range(0, 5):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				var nx := cx + dx
				var ny := cy + dy
				if grid.in_bounds(nx, ny) and grid.get_tile(nx, ny) == DungeonTileType.Kind.EMPTY:
					grid.spawn_cell = Vector2i(nx, ny)
					grid.set_tile(nx, ny, DungeonTileType.Kind.SPAWN_POINT)
					return


func _place_events(grid: DungeonGrid, room_type: int) -> void:
	var event_count := randi_range(GameConfig.EVENTS_PER_ROOM_MIN, GameConfig.EVENTS_PER_ROOM_MAX)
	var event_list := _build_event_list(room_type, event_count)
	var placed := 0
	var attempts := 0

	while placed < event_list.size() and attempts < 200:
		attempts += 1
		var x := randi_range(1, ROOM_W - 2)
		var y := randi_range(1, ROOM_H - 2)
		if grid.get_tile(x, y) != DungeonTileType.Kind.EMPTY:
			continue
		var cell := Vector2i(x, y)
		if cell == grid.spawn_cell:
			continue
		var kind: int = event_list[placed]
		grid.set_tile(x, y, kind)
		grid.event_cells.append(cell)
		placed += 1

	# Fallback: if random placement failed, scan all empty cells
	if placed < event_list.size():
		for y in range(1, ROOM_H - 1):
			for x in range(1, ROOM_W - 1):
				if placed >= event_list.size():
					break
				if grid.get_tile(x, y) != DungeonTileType.Kind.EMPTY:
					continue
				var cell := Vector2i(x, y)
				if cell == grid.spawn_cell:
					continue
				var kind: int = event_list[placed]
				grid.set_tile(x, y, kind)
				grid.event_cells.append(cell)
				placed += 1


const POSITIVE_POOL: Array[int] = [
	DungeonTileType.Kind.HEAL_SPRING,
	DungeonTileType.Kind.POWER_ALTAR,
	DungeonTileType.Kind.IRON_ALTAR,
	DungeonTileType.Kind.RESONANCE_CRYSTAL,
	DungeonTileType.Kind.TREASURE_CHEST,
]

const NEGATIVE_POOL: Array[int] = [
	DungeonTileType.Kind.POISON_SWAMP,
	DungeonTileType.Kind.TRAP,
	DungeonTileType.Kind.CURSED_GROUND,
	DungeonTileType.Kind.SLOW_MUD,
]


func _build_event_list(room_type: int, total: int) -> Array[int]:
	var positive_count: int
	var negative_count: int
	var mystery_count: int

	match room_type:
		WorldMap.RoomType.START:
			positive_count = 3
			negative_count = 1
			mystery_count = 1
		WorldMap.RoomType.TREASURE:
			positive_count = 4
			negative_count = 1
			mystery_count = 0
		WorldMap.RoomType.DANGER:
			positive_count = 1
			negative_count = 3
			mystery_count = 1
		WorldMap.RoomType.ELITE:
			positive_count = 2
			negative_count = 2
			mystery_count = 1
		_:  # NORMAL
			positive_count = 2
			negative_count = 2
			mystery_count = 1

	var result: Array[int] = []

	# Guaranteed positive
	var pos_shuffled := POSITIVE_POOL.duplicate()
	pos_shuffled.shuffle()
	for i in positive_count:
		result.append(pos_shuffled[i % pos_shuffled.size()])

	# Guaranteed negative
	var neg_shuffled := NEGATIVE_POOL.duplicate()
	neg_shuffled.shuffle()
	for i in negative_count:
		result.append(neg_shuffled[i % neg_shuffled.size()])

	# Mystery
	for i in mystery_count:
		result.append(DungeonTileType.Kind.MYSTERY)

	# Fill remaining slots with mixed random
	var fill_pool: Array[int] = POSITIVE_POOL.duplicate()
	fill_pool.append_array(NEGATIVE_POOL)
	fill_pool.append(DungeonTileType.Kind.MYSTERY)
	while result.size() < total:
		result.append(fill_pool[randi() % fill_pool.size()])

	result.shuffle()
	return result


func _place_exits(grid: DungeonGrid, room_index: int, world: WorldMap) -> void:
	var neighbors := world.get_neighbors(room_index)
	if neighbors.is_empty():
		return

	# Assign each neighbor a direction (TOP/BOTTOM/LEFT/RIGHT)
	var directions: Array[int] = []  # 0=top, 1=right, 2=bottom, 3=left
	var available := [0, 1, 2, 3]
	available.shuffle()

	for i in neighbors.size():
		if i < available.size():
			directions.append(available[i])
		else:
			directions.append(available[i % available.size()])

	for i in neighbors.size():
		var target_room: int = neighbors[i]
		var dir: int = directions[i]
		var exit_cell := _get_exit_position(dir, grid)
		if exit_cell != Vector2i(-1, -1):
			grid.set_tile(exit_cell.x, exit_cell.y, DungeonTileType.Kind.EXIT)
			grid.exit_cells[exit_cell] = target_room


func _get_exit_position(direction: int, grid: DungeonGrid) -> Vector2i:
	var mid_x := ROOM_W / 2
	var mid_y := ROOM_H / 2
	match direction:
		0:  # TOP
			grid.set_tile(mid_x, 0, DungeonTileType.Kind.EXIT)
			if grid.get_tile(mid_x, 1) == DungeonTileType.Kind.WALL:
				grid.set_tile(mid_x, 1, DungeonTileType.Kind.EMPTY)
			return Vector2i(mid_x, 0)
		1:  # RIGHT
			grid.set_tile(ROOM_W - 1, mid_y, DungeonTileType.Kind.EXIT)
			if grid.get_tile(ROOM_W - 2, mid_y) == DungeonTileType.Kind.WALL:
				grid.set_tile(ROOM_W - 2, mid_y, DungeonTileType.Kind.EMPTY)
			return Vector2i(ROOM_W - 1, mid_y)
		2:  # BOTTOM
			grid.set_tile(mid_x, ROOM_H - 1, DungeonTileType.Kind.EXIT)
			if grid.get_tile(mid_x, ROOM_H - 2) == DungeonTileType.Kind.WALL:
				grid.set_tile(mid_x, ROOM_H - 2, DungeonTileType.Kind.EMPTY)
			return Vector2i(mid_x, ROOM_H - 1)
		3:  # LEFT
			grid.set_tile(0, mid_y, DungeonTileType.Kind.EXIT)
			if grid.get_tile(1, mid_y) == DungeonTileType.Kind.WALL:
				grid.set_tile(1, mid_y, DungeonTileType.Kind.EMPTY)
			return Vector2i(0, mid_y)
	return Vector2i(-1, -1)
