class_name MapTerrainZone
extends Node2D

var kind: int = 0
var cell_size: float = 150.0
var _label: Label = null


func setup(k: int, pos: Vector2, size: float = 150.0) -> void:
	kind = k
	cell_size = size
	global_position = pos
	queue_redraw()
	_create_label()


func _create_label() -> void:
	_label = Label.new()
	_label.text = MapTerrainType.get_display_name(kind)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_label.position = Vector2(4, 2)
	_label.size = Vector2(cell_size - 8, 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(_label)
	var hint := MapTerrainType.get_effect_hint(kind)
	if not hint.is_empty():
		var hint_label := Label.new()
		hint_label.text = hint
		hint_label.add_theme_font_size_override("font_size", 8)
		hint_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.45))
		hint_label.position = Vector2(4, 16)
		hint_label.size = Vector2(cell_size - 8, 24)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		add_child(hint_label)


func _draw() -> void:
	var col := MapTerrainType.get_color(kind)
	var rect := Rect2(Vector2.ZERO, Vector2(cell_size, cell_size))
	draw_rect(rect, col)
	var border := Color(col.r, col.g, col.b, 0.5)
	draw_rect(rect, border, false, 1.5)


func contains_point(pt: Vector2) -> bool:
	var local := pt - global_position
	return local.x >= 0.0 and local.x <= cell_size and local.y >= 0.0 and local.y <= cell_size
