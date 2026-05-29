class_name MapTerrainZone
extends Node2D

const RADIUS := 80.0

var kind: int = 0
var _label: Label = null


func setup(k: int, pos: Vector2) -> void:
	kind = k
	global_position = pos
	queue_redraw()
	_create_label()


func _create_label() -> void:
	_label = Label.new()
	_label.text = MapTerrainType.get_display_name(kind)
	_label.add_theme_font_size_override("font_size", 11)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	_label.position = Vector2(-30, -RADIUS - 16)
	_label.size = Vector2(60, 14)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _draw() -> void:
	var col := MapTerrainType.get_color(kind)
	draw_circle(Vector2.ZERO, RADIUS, col)
	var border := Color(col.r, col.g, col.b, 0.5)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, border, 1.5)


func contains_point(pt: Vector2) -> bool:
	return global_position.distance_to(pt) <= RADIUS
