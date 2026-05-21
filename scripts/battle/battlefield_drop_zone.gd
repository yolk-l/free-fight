class_name BattlefieldDropZone
extends Control

signal card_dropped(monster_id: StringName, drop_position: Vector2)

@onready var _frame: TextureRect = $Frame


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _frame:
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var valid := _is_card_drag(data)
	if valid:
		modulate = Color(1.1, 1.2, 1.4)
		if _frame:
			_frame.modulate = Color(1.5, 1.8, 2.5)
	else:
		modulate = Color.WHITE
		if _frame:
			_frame.modulate = Color.WHITE
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


func _reset_highlight() -> void:
	modulate = Color.WHITE
	if _frame:
		_frame.modulate = Color.WHITE


func _is_card_drag(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("monster_id", &"") != &""
