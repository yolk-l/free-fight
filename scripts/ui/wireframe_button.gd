class_name WireframeButton
extends Button

func _ready() -> void:
	_apply_theme()


func _apply_theme() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.16, 0.22)
	normal.border_color = Color(0.35, 0.45, 0.65)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(8)
	normal.set_content_margin_all(12)
	add_theme_stylebox_override("normal", normal)

	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.18, 0.22, 0.35)
	hover.border_color = WireframeTheme.ACCENT
	hover.set_border_width_all(2)
	hover.set_corner_radius_all(8)
	hover.set_content_margin_all(12)
	add_theme_stylebox_override("hover", hover)

	var pressed := StyleBoxFlat.new()
	pressed.bg_color = Color(0.1, 0.12, 0.2)
	pressed.border_color = WireframeTheme.ACCENT.lightened(0.2)
	pressed.set_border_width_all(2)
	pressed.set_corner_radius_all(8)
	pressed.set_content_margin_all(12)
	add_theme_stylebox_override("pressed", pressed)

	var focus := StyleBoxFlat.new()
	focus.bg_color = Color(0.14, 0.16, 0.22)
	focus.border_color = WireframeTheme.ACCENT.lightened(0.1)
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(8)
	focus.set_content_margin_all(12)
	add_theme_stylebox_override("focus", focus)

	add_theme_color_override("font_color", WireframeTheme.TEXT)
	add_theme_color_override("font_hover_color", Color(0.8, 0.9, 1.0))
	add_theme_color_override("font_pressed_color", WireframeTheme.ACCENT)
	add_theme_font_size_override("font_size", WireframeTheme.FONT_BODY)
