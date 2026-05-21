extends Control

@onready var _monster_list: ItemList = $Margin/VBox/MonsterList
@onready var _equipment_list: ItemList = $Margin/VBox/EquipmentList
@onready var _btn_back: Button = $Margin/VBox/BtnBack


func _ready() -> void:
	_btn_back.pressed.connect(_on_back_pressed)
	_style_lists()
	_populate_lists()


func _populate_lists() -> void:
	_monster_list.clear()
	_equipment_list.clear()
	for monster_id: StringName in DataRegistry.get_all_monster_ids():
		var monster_data := DataRegistry.get_monster(monster_id)
		if monster_data == null:
			continue
		var unlocked: bool = GameManager.codex_unlocked_monsters.has(monster_id)
		var tex: Texture2D = null
		if unlocked:
			tex = load("res://assets/monsters/%s.png" % str(monster_id)) as Texture2D
		_monster_list.add_item(
			monster_data.display_name if unlocked else "???",
			tex
		)
		if not unlocked:
			_monster_list.set_item_custom_fg_color(_monster_list.item_count - 1, Color(0.4, 0.4, 0.45))
	for equip_id: StringName in DataRegistry.get_all_equipment_ids():
		var equip_data := DataRegistry.get_equipment(equip_id)
		if equip_data == null:
			continue
		var unlocked: bool = GameManager.codex_unlocked_equipment.has(equip_id)
		var tex: Texture2D = null
		if unlocked:
			tex = load("res://assets/equipment/%s.png" % str(equip_id)) as Texture2D
		_equipment_list.add_item(
			equip_data.display_name if unlocked else "???",
			tex
		)
		if not unlocked:
			_equipment_list.set_item_custom_fg_color(_equipment_list.item_count - 1, Color(0.4, 0.4, 0.45))


func _style_lists() -> void:
	for list: ItemList in [_monster_list, _equipment_list]:
		if list == null:
			continue
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0.1, 0.11, 0.15)
		bg.border_color = Color(0.25, 0.28, 0.38)
		bg.set_border_width_all(1)
		bg.set_corner_radius_all(6)
		bg.set_content_margin_all(8)
		list.add_theme_stylebox_override("panel", bg)
		list.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
		list.fixed_icon_size = Vector2i(32, 32)


func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
