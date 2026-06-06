class_name DungeonRenderer
extends Node2D

var _grid: DungeonGrid
var _tile_labels: Dictionary = {}  # Vector2i -> Label
var _coord_labels: Dictionary = {}  # Vector2i -> Label
var _exit_labels: Dictionary = {}  # Vector2i -> Label
var _event_highlights: Dictionary = {}  # Vector2i -> ColorRect


func setup(grid: DungeonGrid) -> void:
	_grid = grid
	_clear_children()
	_draw_tiles()
	_draw_event_highlights()


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()
	_tile_labels.clear()
	_coord_labels.clear()
	_exit_labels.clear()
	_event_highlights.clear()


func _draw_tiles() -> void:
	queue_redraw()
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			var kind := _grid.get_tile(x, y)
			if kind == DungeonTileType.Kind.WALL:
				continue
			var coord_lbl := Label.new()
			coord_lbl.text = "%d,%d" % [x, y]
			coord_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			coord_lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			coord_lbl.position = Vector2(x * DungeonGrid.CELL_SIZE + 1, y * DungeonGrid.CELL_SIZE)
			coord_lbl.size = Vector2(DungeonGrid.CELL_SIZE, 12)
			coord_lbl.add_theme_font_size_override("font_size", 8)
			coord_lbl.add_theme_color_override("font_color", Color(0.5, 0.52, 0.55, 0.5))
			coord_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(coord_lbl)
			_coord_labels[Vector2i(x, y)] = coord_lbl
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
			if DungeonTileType.is_event(kind):
				var aff_name := DungeonTileType.get_affinity_name(kind)
				if not aff_name.is_empty():
					var aff_lbl := Label.new()
					aff_lbl.text = aff_name
					aff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					aff_lbl.position = Vector2(x * DungeonGrid.CELL_SIZE, y * DungeonGrid.CELL_SIZE + DungeonGrid.CELL_SIZE - 14)
					aff_lbl.size = Vector2(DungeonGrid.CELL_SIZE, 14)
					aff_lbl.add_theme_font_size_override("font_size", 8)
					aff_lbl.add_theme_color_override("font_color", DungeonTileType.get_affinity_color(kind).lightened(0.2))
					aff_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
					add_child(aff_lbl)


func _draw_event_highlights() -> void:
	for cell in _grid.event_cells:
		var rect := ColorRect.new()
		rect.color = Color(1.0, 0.9, 0.3, 0.15)
		rect.position = Vector2(cell.x * DungeonGrid.CELL_SIZE, cell.y * DungeonGrid.CELL_SIZE)
		rect.size = Vector2(DungeonGrid.CELL_SIZE, DungeonGrid.CELL_SIZE)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(rect)
		_event_highlights[cell] = rect


func mark_event_cleared(cell: Vector2i) -> void:
	var highlight: ColorRect = _event_highlights.get(cell)
	if highlight and is_instance_valid(highlight):
		var tween := highlight.create_tween()
		tween.tween_property(highlight, "color:a", 0.0, 0.3)
		tween.tween_callback(highlight.queue_free)
		_event_highlights.erase(cell)
	var label: Label = _tile_labels.get(cell)
	if label and is_instance_valid(label):
		label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45, 0.4))


func open_exits() -> void:
	queue_redraw()
	for cell in _grid.exit_cells.keys():
		var label: Label = _tile_labels.get(cell)
		if label and is_instance_valid(label):
			label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
			var tween := label.create_tween()
			tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.2)
			tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.15)


func clear_tile(cell: Vector2i) -> void:
	var label: Label = _tile_labels.get(cell)
	if label and is_instance_valid(label):
		label.queue_free()
		_tile_labels.erase(cell)
	queue_redraw()


func update_tile_visual(cell: Vector2i, new_kind: int) -> void:
	var label: Label = _tile_labels.get(cell)
	if label and is_instance_valid(label):
		var icon := DungeonTileType.get_icon_char(new_kind)
		label.text = icon
		label.add_theme_color_override("font_color", DungeonTileType.get_color(new_kind).lightened(0.4))


func mark_exit_types(world: WorldMap) -> void:
	for cell in _grid.exit_cells.keys():
		var target: int = _grid.exit_cells[cell]
		var room_type: int = world.room_types[target]
		if room_type != WorldMap.RoomType.ELITE and room_type != WorldMap.RoomType.BOSS:
			continue
		var marker := Label.new()
		marker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		marker.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		marker.position = Vector2(cell.x * DungeonGrid.CELL_SIZE, cell.y * DungeonGrid.CELL_SIZE)
		marker.size = Vector2(DungeonGrid.CELL_SIZE, DungeonGrid.CELL_SIZE)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if room_type == WorldMap.RoomType.BOSS:
			marker.text = "BOSS"
			marker.add_theme_font_size_override("font_size", 11)
			marker.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2))
			marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			marker.add_theme_constant_override("outline_size", 3)
		else:
			marker.text = "精英"
			marker.add_theme_font_size_override("font_size", 11)
			marker.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
			marker.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			marker.add_theme_constant_override("outline_size", 3)
		add_child(marker)
		_exit_labels[cell] = marker


func _draw() -> void:
	if _grid == null:
		return
	var cs := DungeonGrid.CELL_SIZE
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			var kind := _grid.get_tile(x, y)
			var col := DungeonTileType.get_color(kind)
			var rect := Rect2(x * cs, y * cs, cs, cs)
			if kind == DungeonTileType.Kind.EXIT:
				var cell := Vector2i(x, y)
				if _grid.exits_open:
					col = Color(0.3, 0.9, 0.4)
					if _exit_labels.has(cell):
						col = _get_exit_open_color(cell)
				else:
					col = Color(0.2, 0.25, 0.2)
					if _exit_labels.has(cell):
						col = _get_exit_closed_color(cell)
			draw_rect(rect, col)
			if kind != DungeonTileType.Kind.WALL:
				draw_rect(rect, Color(0.2, 0.22, 0.25), false, 1.0)
			else:
				if _is_wall_edge(x, y):
					draw_rect(rect, Color(0.42, 0.35, 0.3))
					draw_rect(rect, Color(0.18, 0.15, 0.12), false, 1.5)


func _get_exit_open_color(cell: Vector2i) -> Color:
	var marker: Label = _exit_labels.get(cell)
	if marker == null:
		return Color(0.3, 0.9, 0.4)
	if marker.text == "BOSS":
		return Color(0.6, 0.15, 0.1)
	return Color(0.6, 0.45, 0.1)


func _get_exit_closed_color(cell: Vector2i) -> Color:
	var marker: Label = _exit_labels.get(cell)
	if marker == null:
		return Color(0.2, 0.25, 0.2)
	if marker.text == "BOSS":
		return Color(0.3, 0.1, 0.08)
	return Color(0.3, 0.22, 0.08)


func _is_wall_edge(x: int, y: int) -> bool:
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var nx: int = x + dir.x
		var ny: int = y + dir.y
		if _grid.in_bounds(nx, ny) and _grid.get_tile(nx, ny) != DungeonTileType.Kind.WALL:
			return true
	return false
