class_name LootDrop
extends Area2D

enum DropType { EQUIPMENT, CARD }

signal picked_up(drop: LootDrop)

var drop_type: DropType = DropType.EQUIPMENT
var equipment_id: StringName = &""
var monster_card_id: StringName = &""

@onready var _body: Sprite2D = $Body
@onready var _label: Label = $Label


func setup_equipment(equip_id: StringName) -> void:
	drop_type = DropType.EQUIPMENT
	equipment_id = equip_id
	var data := DataRegistry.get_equipment(equip_id)
	if _label:
		_label.text = "E:%s" % (data.display_name if data else str(equip_id))
	if _body:
		var tex_path := "res://assets/equipment/%s.png" % str(equip_id)
		var tex := load(tex_path) as Texture2D
		if tex:
			_body.texture = tex


func setup_card(monster_id: StringName) -> void:
	drop_type = DropType.CARD
	monster_card_id = monster_id
	var data := DataRegistry.get_monster(monster_id)
	if _label:
		_label.text = "C:%s" % (data.display_name if data else str(monster_id))
	if _body:
		var tex_path := "res://assets/monsters/%s.png" % str(monster_id)
		var tex := load(tex_path) as Texture2D
		if tex:
			_body.texture = tex


func _ready() -> void:
	input_pickable = true
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked_up.emit(self)
		queue_free()


func _on_mouse_entered() -> void:
	scale = Vector2(1.15, 1.15)


func _on_mouse_exited() -> void:
	scale = Vector2.ONE
