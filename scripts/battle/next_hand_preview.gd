class_name NextHandPreview
extends HBoxContainer

@onready var _title: Label = $Title


func _ready() -> void:
	if _title:
		_title.text = "下一批"


func set_cards(ids: Array, elites: Array) -> void:
	var to_remove: Array[Node] = []
	for child in get_children():
		if child != _title:
			to_remove.append(child)
	for c in to_remove:
		remove_child(c)
		c.queue_free()
	for i in ids.size():
		var is_elite: bool = elites[i] if i < elites.size() else false
		add_child(_create_preview_card(ids[i], is_elite))


func _create_preview_card(monster_id: StringName, is_elite: bool) -> Control:
	var data := DataRegistry.get_monster(monster_id)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(90, 56)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.modulate = Color(1, 1, 1, 0.65)
	var style := StyleBoxFlat.new()
	style.bg_color = (data.wireframe_color.darkened(0.6) if data else Color(0.12, 0.14, 0.2))
	if is_elite:
		style.border_color = Color(1.0, 0.85, 0.2)
		style.set_border_width_all(2)
	else:
		style.border_color = (data.wireframe_color.darkened(0.4) if data else Color(0.3, 0.35, 0.5))
		style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 1)
	var icon := TextureRect.new()
	var tex_path := "res://assets/monsters/%s.png" % str(monster_id)
	var tex := load(tex_path) as Texture2D
	if tex:
		icon.texture = tex
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(22, 22)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)
	var name_text: String = (data.display_name if data else str(monster_id))
	if is_elite:
		name_text = "★" + name_text
	var label := Label.new()
	label.text = name_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_elite else Color(0.85, 0.85, 0.9))
	label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(label)
	panel.add_child(vbox)
	return panel
