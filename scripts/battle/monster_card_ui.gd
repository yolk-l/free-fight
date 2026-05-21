class_name MonsterCardUI
extends PanelContainer

signal card_clicked(monster_id: StringName)

var monster_id: StringName = &""

const CLICK_DRAG_THRESHOLD_PX := 8.0

var _press_pos: Vector2 = Vector2.ZERO


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif _press_pos.distance_to(event.position) < CLICK_DRAG_THRESHOLD_PX:
			card_clicked.emit(monster_id)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if monster_id == &"":
		return null
	var preview := _create_drag_preview()
	set_drag_preview(preview)
	return {"monster_id": monster_id}


func _create_drag_preview() -> Control:
	var data := DataRegistry.get_monster(monster_id)
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(100, 72)
	preview.modulate = Color(1, 1, 1, 0.85)
	var style := StyleBoxFlat.new()
	style.bg_color = data.wireframe_color.darkened(0.3) if data else WireframeTheme.PANEL
	style.border_color = WireframeTheme.ACCENT
	style.set_border_width_all(2)
	preview.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	var icon := TextureRect.new()
	var tex_path := "res://assets/monsters/%s.png" % str(monster_id)
	var tex := load(tex_path) as Texture2D
	if tex:
		icon.texture = tex
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(icon)
	var label := Label.new()
	label.text = data.display_name if data else str(monster_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)
	preview.add_child(vbox)
	return preview
