class_name MonsterCardUI
extends PanelContainer

var monster_id: StringName = &""
var draggable: bool = true

var _disabled_overlay: ColorRect = null
var _cd_label: Label = null


func _get_drag_data(_at_position: Vector2) -> Variant:
	if monster_id == &"" or not draggable:
		return null
	var preview := _create_drag_preview()
	set_drag_preview(preview)
	return {"monster_id": monster_id}


func setup_overlay() -> void:
	_disabled_overlay = ColorRect.new()
	_disabled_overlay.color = Color(0.1, 0.1, 0.15, 0.6)
	_disabled_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_disabled_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disabled_overlay.visible = not draggable
	add_child(_disabled_overlay)
	_cd_label = Label.new()
	_cd_label.add_theme_font_size_override("font_size", 18)
	_cd_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	_cd_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_cd_label.add_theme_constant_override("outline_size", 3)
	_cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cd_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_cd_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_cd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cd_label.visible = false
	add_child(_cd_label)


func set_draggable(value: bool) -> void:
	draggable = value
	if _disabled_overlay:
		_disabled_overlay.visible = not value


func update_cd(remaining: float) -> void:
	if remaining > 0.0:
		draggable = false
		if _disabled_overlay:
			_disabled_overlay.visible = true
		if _cd_label:
			_cd_label.text = "%.1fs" % remaining
			_cd_label.visible = true
	else:
		draggable = true
		if _disabled_overlay:
			_disabled_overlay.visible = false
		if _cd_label:
			_cd_label.visible = false


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
