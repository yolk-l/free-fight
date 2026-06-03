class_name DungeonCamera
extends Camera2D

const ZOOM_MIN := 0.6
const ZOOM_MAX := 1.5
const ZOOM_STEP := 0.1
const FOLLOW_SPEED := 5.0

var _follow_target: Node2D = null
var _dragging := false
var _drag_start := Vector2.ZERO
var _cam_start := Vector2.ZERO
var _map_size := Vector2.ZERO


func setup(target: Node2D, grid_w: int, grid_h: int, cell_size: int) -> void:
	_follow_target = target
	_map_size = Vector2(grid_w * cell_size, grid_h * cell_size)
	zoom = Vector2(1.0, 1.0)
	if target:
		global_position = target.global_position
	limit_left = 0
	limit_top = 0
	limit_right = int(_map_size.x)
	limit_bottom = int(_map_size.y)
	position_smoothing_enabled = true
	position_smoothing_speed = FOLLOW_SPEED


func _process(delta: float) -> void:
	if _dragging:
		return
	if _follow_target and is_instance_valid(_follow_target):
		global_position = global_position.lerp(_follow_target.global_position, FOLLOW_SPEED * delta)
		_clamp_position()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed:
				_dragging = true
				_drag_start = mb.global_position
				_cam_start = global_position
			else:
				_dragging = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			var z := clampf(zoom.x + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			zoom = Vector2(z, z)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var z := clampf(zoom.x - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
			zoom = Vector2(z, z)
	elif event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		global_position = _cam_start + (_drag_start - motion.global_position) / zoom.x
		_clamp_position()


func _clamp_position() -> void:
	global_position.x = clampf(global_position.x, 0, _map_size.x)
	global_position.y = clampf(global_position.y, 0, _map_size.y)
