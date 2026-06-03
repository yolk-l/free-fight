class_name BattlefieldDropZone
extends Control

signal card_dropped(monster_id: StringName, drop_position: Vector2)

@onready var _frame: TextureRect = $Frame

var deploy_blocked: bool = false
var _crosshair: Control = null
var _terrain_hint_label: Label = null
var _terrain_system: TerrainSystem = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if _frame:
		_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_terrain_hint()


func set_terrain_system(ts: TerrainSystem) -> void:
	_terrain_system = ts


func _setup_terrain_hint() -> void:
	_terrain_hint_label = Label.new()
	_terrain_hint_label.add_theme_font_size_override("font_size", 12)
	_terrain_hint_label.add_theme_color_override("font_color", Color(1, 1, 0.85, 0.95))
	_terrain_hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_terrain_hint_label.add_theme_constant_override("outline_size", 4)
	_terrain_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_terrain_hint_label.visible = false
	_terrain_hint_label.size = Vector2(220, 48)
	_terrain_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_terrain_hint_label)


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var valid := _is_card_drag(data) and not deploy_blocked
	if valid:
		_show_crosshair(at_position)
		_show_terrain_hint(at_position, data.get("monster_id", &""))
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


func _show_terrain_hint(local_pos: Vector2, monster_id: StringName) -> void:
	if _terrain_hint_label == null or _terrain_system == null or monster_id == &"":
		if _terrain_hint_label:
			_terrain_hint_label.visible = false
		return
	var world_pos: Vector2 = get_global_transform() * local_pos
	var kind := _terrain_system.get_map_terrain_at(world_pos)
	if kind < 0:
		_terrain_hint_label.visible = false
		return
	var terrain_name := MapTerrainType.get_display_name(kind)
	var effect := _get_terrain_effect_for_monster(kind, monster_id)
	if effect.is_empty():
		_terrain_hint_label.text = terrain_name
	else:
		_terrain_hint_label.text = "%s: %s" % [terrain_name, effect]
	_terrain_hint_label.position = local_pos + Vector2(16, -48)
	_terrain_hint_label.visible = true


func _get_terrain_effect_for_monster(kind: int, monster_id: StringName) -> String:
	match kind:
		MapTerrainType.Kind.GRASSLAND:
			match monster_id:
				&"wolf": return "群感增强!"
				&"goblin": return "爆炸范围扩大!"
		MapTerrainType.Kind.DESERT:
			match monster_id:
				&"slime": return "无法分裂"
				&"gargoyle": return "光环范围扩展!"
				&"viper": return "毒液浓缩!"
		MapTerrainType.Kind.MOUNTAIN:
			match monster_id:
				&"goblin": return "爆炸增伤!"
				&"skeleton": return "复活增强!"
				&"gargoyle": return "防御光环强化!"
		MapTerrainType.Kind.LAKE:
			match monster_id:
				&"slime": return "多重分裂!"
				&"bat": return "失去飞行!"
				&"viper": return "毒素稀释"
		MapTerrainType.Kind.FOREST:
			match monster_id:
				&"wolf": return "群攻速强化!"
				&"skeleton": return "速复活!"
	return ""


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
	if _terrain_hint_label:
		_terrain_hint_label.visible = false


func _is_card_drag(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("monster_id", &"") != &""
