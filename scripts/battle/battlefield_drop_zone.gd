class_name BattlefieldDropZone
extends Control

signal card_dropped(monster_id: StringName, drop_position: Vector2)

@onready var _frame: TextureRect = $Frame

var deploy_blocked: bool = false
var _crosshair: Control = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _frame:
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var valid := _is_card_drag(data) and not deploy_blocked
	if valid:
		_show_crosshair(at_position)
		if _frame:
			_frame.modulate = Color(1.5, 1.8, 2.5)
	else:
		_reset_highlight()
	return valid


func _drop_data(at_position: Vector2, data: Variant) -> void:
	_reset_highlight()
	if not _is_card_drag(data):
		return
	var drop_global: Vector2 = get_global_transform() * at_position
	card_dropped.emit(data["monster_id"], drop_global)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_reset_highlight()


func _show_crosshair(local_pos: Vector2) -> void:
	if _crosshair == null:
		_crosshair = Control.new()
		_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_crosshair.custom_minimum_size = Vector2(24, 24)
		_crosshair.size = Vector2(24, 24)
		_crosshair.draw.connect(_draw_crosshair)
		add_child(_crosshair)
	_crosshair.position = local_pos - Vector2(12, 12)
	_crosshair.visible = true
	_crosshair.queue_redraw()


func _draw_crosshair() -> void:
	if _crosshair == null:
		return
	var c := Color(1.0, 1.0, 0.5, 0.8)
	var center := Vector2(12, 12)
	_crosshair.draw_line(center - Vector2(10, 0), center + Vector2(10, 0), c, 1.5)
	_crosshair.draw_line(center - Vector2(0, 10), center + Vector2(0, 10), c, 1.5)
	_crosshair.draw_arc(center, 6.0, 0, TAU, 16, c, 1.5)


func _reset_highlight() -> void:
	modulate = Color.WHITE
	if _frame:
		_frame.modulate = Color.WHITE
	if _crosshair:
		_crosshair.visible = false


func _is_card_drag(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("monster_id", &"") != &""
