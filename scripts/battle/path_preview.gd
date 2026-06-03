class_name PathPreview
extends Node2D

var _path: Array[Vector2i] = []
var _grid: DungeonGrid
var _valid := false


func setup(grid: DungeonGrid) -> void:
	_grid = grid


func show_path(path: Array[Vector2i], valid: bool) -> void:
	_path = path
	_valid = valid
	visible = true
	queue_redraw()


func hide_path() -> void:
	_path.clear()
	visible = false
	queue_redraw()


func _draw() -> void:
	if _path.size() < 2 or _grid == null:
		return
	var cs := DungeonGrid.CELL_SIZE
	var line_color := Color(0.3, 1.0, 0.5, 0.5) if _valid else Color(0.95, 0.3, 0.2, 0.5)
	for i in range(1, _path.size()):
		var from := Vector2(_path[i - 1].x * cs + cs * 0.5, _path[i - 1].y * cs + cs * 0.5)
		var to := Vector2(_path[i].x * cs + cs * 0.5, _path[i].y * cs + cs * 0.5)
		_draw_dashed_line(from, to, line_color, 2.0)
	for i in range(1, _path.size() - 1):
		var cell := _path[i]
		var kind := _grid.get_tile(cell.x, cell.y)
		if kind == DungeonTileType.Kind.EMPTY:
			continue
		if _grid.is_used(cell.x, cell.y):
			continue
		var center := Vector2(cell.x * cs + cs * 0.5, cell.y * cs + cs * 0.5)
		var col := DungeonTileType.get_color(kind)
		col.a = 0.5
		draw_rect(Rect2(center - Vector2(cs * 0.4, cs * 0.4), Vector2(cs * 0.8, cs * 0.8)), col, false, 2.0)
	if _path.size() > 0:
		var target := _path[-1]
		var pos := Vector2(target.x * cs + cs * 0.5, target.y * cs + cs * 0.5)
		var marker_color := Color(0.3, 1.0, 0.5, 0.7) if _valid else Color(0.95, 0.3, 0.2, 0.7)
		draw_rect(Rect2(pos - Vector2(cs * 0.45, cs * 0.45), Vector2(cs * 0.9, cs * 0.9)), marker_color, false, 2.5)


func _draw_dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var dir := (to - from)
	var length := dir.length()
	if length < 1.0:
		return
	dir = dir.normalized()
	var dash_len := 8.0
	var gap_len := 6.0
	var pos := 0.0
	while pos < length:
		var start := from + dir * pos
		var end_pos := minf(pos + dash_len, length)
		var end := from + dir * end_pos
		draw_line(start, end, color, width)
		pos = end_pos + gap_len
