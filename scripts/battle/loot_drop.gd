class_name LootDrop
extends Area2D

signal picked_up(drop: LootDrop)

var equipment_instance = null

@onready var _body: Sprite2D = $Body
@onready var _label: Label = $Label


func setup_equipment(instance) -> void:
	equipment_instance = instance


func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_refresh_display()


func _refresh_display() -> void:
	if equipment_instance == null:
		return
	if _label:
		_label.text = equipment_instance.get_display_name()
		_label.add_theme_color_override("font_color", equipment_instance.get_quality_color())
	if _body and equipment_instance.base_data:
		var tex_path := "res://assets/equipment/%s.png" % str(equipment_instance.base_data.id)
		var tex := load(tex_path) as Texture2D
		if tex:
			_body.texture = tex


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked_up.emit(self)
		queue_free()


func _on_mouse_entered() -> void:
	scale = Vector2(1.15, 1.15)


func _on_mouse_exited() -> void:
	scale = Vector2.ONE
