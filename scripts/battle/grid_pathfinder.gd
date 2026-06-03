class_name GridPathfinder
extends RefCounted

var _astar := AStar2D.new()
var _grid: DungeonGrid


func setup(grid: DungeonGrid) -> void:
	_grid = grid
	_astar.clear()
	_astar.reserve_space(DungeonGrid.GRID_W * DungeonGrid.GRID_H)
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			if not grid.is_passable(x, y):
				continue
			var id := _cell_id(x, y)
			_astar.add_point(id, Vector2(x, y))
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			if not grid.is_passable(x, y):
				continue
			var id := _cell_id(x, y)
			for dir in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]:
				var nx: int = x + dir.x
				var ny: int = y + dir.y
				if grid.is_passable(nx, ny):
					var nid := _cell_id(nx, ny)
					if not _astar.are_points_connected(id, nid):
						_astar.connect_points(id, nid)


func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var from_id := _cell_id(from.x, from.y)
	var to_id := _cell_id(to.x, to.y)
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return []
	var raw := _astar.get_point_path(from_id, to_id)
	var result: Array[Vector2i] = []
	for p in raw:
		result.append(Vector2i(int(p.x), int(p.y)))
	return result


func get_path_length(from: Vector2i, to: Vector2i) -> int:
	var path := find_path(from, to)
	if path.is_empty():
		return 999999
	return path.size() - 1


func _cell_id(x: int, y: int) -> int:
	return y * DungeonGrid.GRID_W + x
