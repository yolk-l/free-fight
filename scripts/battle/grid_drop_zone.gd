class_name GridDropZone
extends Control

signal card_dropped(monster_id: StringName, grid_cell: Vector2i)
signal drag_hover(grid_cell: Vector2i, monster_id: StringName)
signal drag_end
signal tile_clicked(grid_cell: Vector2i, screen_pos: Vector2)

var _grid: DungeonGrid
var _pathfinder: GridPathfinder
var _hero: Hero
var _path_preview: PathPreview
var deploy_blocked: bool = false
var _last_hover_cell := Vector2i(-1, -1)
var _camera: DungeonCamera


func setup(grid: DungeonGrid, pathfinder: GridPathfinder, hero: Hero, camera: DungeonCamera) -> void:
	_grid = grid
	_pathfinder = pathfinder
	_hero = hero
	_camera = camera
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func set_path_preview(preview: PathPreview) -> void:
	_path_preview = preview


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not _is_card_drag(data) or deploy_blocked:
		return false
	var world_pos := _screen_to_world(at_position)
	var cell := _grid.world_to_cell(world_pos)
	if _grid.is_deployable(cell.x, cell.y):
		_update_path_preview(cell, true)
		_last_hover_cell = cell
		drag_hover.emit(cell, data.get("monster_id", &""))
		return true
	else:
		_update_path_preview(cell, false)
		_last_hover_cell = cell
		return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _is_card_drag(data):
		return
	var world_pos := _screen_to_world(at_position)
	var cell := _grid.world_to_cell(world_pos)
	if _grid.is_deployable(cell.x, cell.y):
		card_dropped.emit(data["monster_id"], cell)
	_hide_preview()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			var world_pos := _screen_to_world(mb.position)
			var cell := _grid.world_to_cell(world_pos)
			tile_clicked.emit(cell, mb.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_hide_preview()
		drag_end.emit()


func _screen_to_world(screen_pos: Vector2) -> Vector2:
	if _camera:
		var vp_size := Vector2(get_viewport().get_visible_rect().size)
		var cam_center := _camera.get_screen_center_position()
		var cam_zoom := _camera.zoom
		return cam_center + (screen_pos - vp_size * 0.5) / cam_zoom
	return screen_pos


func _update_path_preview(target_cell: Vector2i, valid: bool) -> void:
	if _path_preview == null or _hero == null or _pathfinder == null:
		return
	var hero_cell := _hero.grid_cell
	var path := _pathfinder.find_path(hero_cell, target_cell)
	if path.is_empty():
		_path_preview.show_path([hero_cell, target_cell], false)
	else:
		_path_preview.show_path(path, valid)


func _hide_preview() -> void:
	if _path_preview:
		_path_preview.hide_path()
	_last_hover_cell = Vector2i(-1, -1)


func _is_card_drag(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("monster_id", &"") != &""
