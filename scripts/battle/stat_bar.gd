class_name StatBar
extends Control

@onready var _hp_bar: ProgressBar = $HBox/HPBar
@onready var _stats_label: Label = $StatsLabel


func _ready() -> void:
	if _hp_bar:
		_style_hp_bar()


func update_stats(stats: CombatStats) -> void:
	if stats == null:
		return
	if _hp_bar:
		_hp_bar.max_value = stats.max_hp
		_hp_bar.value = stats.hp
		_update_hp_color(stats.hp, stats.max_hp)
	if _stats_label:
		_stats_label.text = "ATK:%d  DEF:%d  HP:%d/%d  SPD:%.1f" % [
			stats.attack, stats.defense, stats.hp, stats.max_hp, stats.attack_speed
		]


func _style_hp_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.09, 0.12)
	bg.border_color = Color(0.25, 0.28, 0.35)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(4)
	_hp_bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.85, 0.4)
	fill.set_corner_radius_all(3)
	_hp_bar.add_theme_stylebox_override("fill", fill)


func _update_hp_color(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var ratio := float(hp) / float(max_hp)
	var fill: StyleBoxFlat = _hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill == null:
		return
	if ratio > 0.6:
		fill.bg_color = Color(0.3, 0.85, 0.4)
	elif ratio > 0.3:
		fill.bg_color = Color(0.9, 0.8, 0.2)
	else:
		fill.bg_color = Color(0.9, 0.25, 0.2)
