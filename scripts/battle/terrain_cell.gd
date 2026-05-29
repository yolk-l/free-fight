# 持续性范围效果 — temporary area effect spawned by evolution passives on kill.
# Distinct from MapTerrainZone which is permanent map terrain.
class_name TerrainCell
extends Node2D

const RADIUS := 40.0

const ICON_MAP := {
	TerrainType.Kind.RESONANCE_ALTAR: "res://assets/terrains/resonance_altar.png",
	TerrainType.Kind.THORNS: "res://assets/terrains/thorns.png",
	TerrainType.Kind.SANCTUARY: "res://assets/terrains/sanctuary.png",
	TerrainType.Kind.SHADOW: "res://assets/terrains/shadow.png",
	TerrainType.Kind.RESONANCE_NODE: "res://assets/terrains/resonance_node.png",
	TerrainType.Kind.POISON_LAND: "res://assets/terrains/poison_land.png",
}

var kind: int = 0
var duration: float = 0.0      # 0 = permanent (legacy); >0 = ephemeral, auto-expires
var _remaining: float = 0.0
var _max_duration: float = 0.0
var _expiring: bool = false
var _label: Label = null
var _icon: Sprite2D = null
var _visited: Dictionary = {}
var _pulse_alpha: float = 0.0

signal expired(cell)


func setup(k: int, pos: Vector2, dur: float = 0.0) -> void:
	kind = k
	global_position = pos
	duration = dur
	_max_duration = dur
	_remaining = dur
	queue_redraw()
	_create_label()
	_create_icon()


func _process(delta: float) -> void:
	if duration <= 0.0 or _expiring:
		return
	_remaining -= delta
	if _remaining <= 1.0:
		# Fade out in the last second so players see it disappearing.
		modulate.a = clampf(_remaining, 0.0, 1.0)
	if _remaining <= 0.0:
		_expiring = true
		expired.emit(self)
		queue_free()


func _create_label() -> void:
	if _label != null:
		return
	_label = Label.new()
	_label.text = TerrainType.get_display_name(kind)
	_label.add_theme_font_size_override("font_size", 10)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_label.position = Vector2(-30, -RADIUS - 14)
	_label.size = Vector2(60, 12)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)


func _create_icon() -> void:
	if _icon != null:
		return
	var path: String = ICON_MAP.get(kind, "")
	if path.is_empty():
		return
	var tex := load(path) as Texture2D
	if tex == null:
		return
	_icon = Sprite2D.new()
	_icon.texture = tex
	var max_size := RADIUS * 1.4
	var tex_size: Vector2 = tex.get_size()
	if tex_size.x > 0 and tex_size.y > 0:
		var scale_factor: float = minf(max_size / tex_size.x, max_size / tex_size.y)
		_icon.scale = Vector2(scale_factor, scale_factor)
	add_child(_icon)


func pulse() -> void:
	_pulse_alpha = 1.0
	queue_redraw()
	var tween := create_tween()
	tween.tween_method(_set_pulse_alpha, 1.0, 0.0, 0.45)


func _set_pulse_alpha(v: float) -> void:
	_pulse_alpha = v
	queue_redraw()


func _draw() -> void:
	var col := TerrainType.get_color(kind)
	draw_circle(Vector2.ZERO, RADIUS, col)
	var border := Color(col.r, col.g, col.b, 0.8)
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 32, border, 1.5)
	if _pulse_alpha > 0.0:
		var pulse_col := Color(1, 1, 1, 0.6 * _pulse_alpha)
		draw_arc(Vector2.ZERO, RADIUS + 6.0, 0, TAU, 32, pulse_col, 4.0)


func contains_point(pt: Vector2) -> bool:
	return global_position.distance_to(pt) <= RADIUS


func is_visited(monster: Node) -> bool:
	return _visited.has(monster.get_instance_id())


func mark_visited(monster: Node) -> void:
	_visited[monster.get_instance_id()] = true
