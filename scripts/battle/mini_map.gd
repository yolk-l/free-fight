class_name MiniMap
extends Control

const MAP_SIZE := Vector2(180, 120)
const ROOM_BOX := Vector2(24, 18)
const ROOM_SPACING := Vector2(36, 30)

var _world_map: WorldMap
var _current_room: int = 0
var _room_positions: Dictionary = {}  # room_index -> Vector2


func setup_world(world_map: WorldMap, current_room: int) -> void:
	_world_map = world_map
	_current_room = current_room
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_compute_room_positions()
	queue_redraw()


func _compute_room_positions() -> void:
	_room_positions.clear()
	if _world_map == null:
		return
	# Layout rooms by depth (left to right) with vertical spread
	var depth_groups: Dictionary = {}  # depth -> Array[int]
	for i in _world_map.room_depth.size():
		var d: int = _world_map.room_depth[i]
		if not depth_groups.has(d):
			depth_groups[d] = []
		depth_groups[d].append(i)

	var max_depth := 0
	for d in depth_groups.keys():
		max_depth = maxi(max_depth, d)

	for d in depth_groups.keys():
		var group: Array = depth_groups[d]
		var x_offset: float = 20 + (float(d) / maxf(1.0, float(max_depth))) * (MAP_SIZE.x - 50)
		var y_start: float = (MAP_SIZE.y - group.size() * ROOM_SPACING.y) * 0.5 + ROOM_SPACING.y * 0.5
		for idx in group.size():
			var room_idx: int = group[idx]
			_room_positions[room_idx] = Vector2(x_offset, y_start + idx * ROOM_SPACING.y)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _world_map == null:
		return
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.05, 0.05, 0.08, 0.85))

	# Draw edges
	for edge in _world_map.tree_edges:
		var from_pos: Vector2 = _room_positions.get(edge[0], Vector2.ZERO)
		var to_pos: Vector2 = _room_positions.get(edge[1], Vector2.ZERO)
		draw_line(from_pos, to_pos, Color(0.4, 0.45, 0.55, 0.6), 1.5)

	# Draw rooms
	for i in _world_map.rooms.size():
		var pos: Vector2 = _room_positions.get(i, Vector2.ZERO)
		var rect := Rect2(pos - ROOM_BOX * 0.5, ROOM_BOX)
		var col := _get_room_color(i)
		draw_rect(rect, col)
		if i == _current_room:
			draw_rect(rect, Color(1.0, 1.0, 1.0, 0.8), false, 2.0)
		else:
			draw_rect(rect, Color(0.5, 0.55, 0.65, 0.4), false, 1.0)

	# Border
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.5, 0.55, 0.65, 0.5), false, 1.0)


func _get_room_color(room_index: int) -> Color:
	if _world_map.is_room_cleared(room_index):
		return Color(0.25, 0.35, 0.25, 0.6)
	var room_type: int = _world_map.room_types[room_index]
	match room_type:
		WorldMap.RoomType.START: return Color(0.4, 0.85, 0.5, 0.8)
		WorldMap.RoomType.TREASURE: return Color(0.95, 0.8, 0.25, 0.8)
		WorldMap.RoomType.DANGER: return Color(0.85, 0.3, 0.2, 0.8)
		WorldMap.RoomType.ELITE: return Color(0.7, 0.4, 0.9, 0.8)
		WorldMap.RoomType.BOSS: return Color(0.95, 0.2, 0.15, 0.9)
		_: return Color(0.4, 0.45, 0.55, 0.7)
