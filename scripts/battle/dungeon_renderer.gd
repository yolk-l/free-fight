class_name DungeonRenderer
extends Node2D

var _grid: DungeonGrid
var _tile_labels: Dictionary = {}  # Vector2i -> Label
var _fog_rects: Dictionary = {}  # Vector2i -> ColorRect


func setup(grid: DungeonGrid) -> void:
	_grid = grid
	_draw_tiles()
	_draw_fog()


func _draw_tiles() -> void:
	queue_redraw()
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			var kind := _grid.get_tile(x, y)
			if kind == DungeonTileType.Kind.WALL:
				continue
			var icon := DungeonTileType.get_icon_char(kind)
			if icon.is_empty():
				continue
			var label := Label.new()
			label.text = icon
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			label.position = Vector2(x * DungeonGrid.CELL_SIZE + 4, y * DungeonGrid.CELL_SIZE + 2)
			label.size = Vector2(DungeonGrid.CELL_SIZE - 8, DungeonGrid.CELL_SIZE - 4)
			label.add_theme_font_size_override("font_size", 18)
			label.add_theme_color_override("font_color", DungeonTileType.get_color(kind).lightened(0.4))
			label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
			label.add_theme_constant_override("outline_size", 2)
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(label)
			_tile_labels[Vector2i(x, y)] = label


func _draw_fog() -> void:
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			if _grid.is_revealed(x, y):
				continue
			var rect := ColorRect.new()
			rect.color = Color(0.05, 0.05, 0.08, 0.95)
			rect.position = Vector2(x * DungeonGrid.CELL_SIZE, y * DungeonGrid.CELL_SIZE)
			rect.size = Vector2(DungeonGrid.CELL_SIZE, DungeonGrid.CELL_SIZE)
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(rect)
			_fog_rects[Vector2i(x, y)] = rect


func reveal_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		var rect: ColorRect = _fog_rects.get(cell)
		if rect and is_instance_valid(rect):
			var tween := rect.create_tween()
			tween.tween_property(rect, "modulate:a", 0.0, 0.3)
			tween.tween_callback(rect.queue_free)
			_fog_rects.erase(cell)


func mark_tile_used(cell: Vector2i) -> void:
	var label: Label = _tile_labels.get(cell)
	if label and is_instance_valid(label):
		label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 0.4))


func update_tile_visual(cell: Vector2i, new_kind: int) -> void:
	var label: Label = _tile_labels.get(cell)
	if label and is_instance_valid(label):
		var icon := DungeonTileType.get_icon_char(new_kind)
		label.text = icon
		label.add_theme_color_override("font_color", DungeonTileType.get_color(new_kind).lightened(0.4))


func _draw() -> void:
	if _grid == null:
		return
	var cs := DungeonGrid.CELL_SIZE
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			var kind := _grid.get_tile(x, y)
			var col := DungeonTileType.get_color(kind)
			var rect := Rect2(x * cs, y * cs, cs, cs)
			draw_rect(rect, col)
			if kind != DungeonTileType.Kind.WALL:
				draw_rect(rect, Color(0.2, 0.22, 0.25), false, 1.0)
