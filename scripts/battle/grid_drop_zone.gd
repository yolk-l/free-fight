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
var _match_label: Label = null


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
		_hide_match_label()
		return false
	var world_pos := _screen_to_world(at_position)
	var cell := _grid.world_to_cell(world_pos)
	if _grid.is_deployable(cell.x, cell.y):
		_update_path_preview(cell, true)
		_last_hover_cell = cell
		var monster_id: StringName = data.get("monster_id", &"")
		var tile_kind := _grid.get_tile(cell.x, cell.y)
		_update_match_label(at_position, monster_id, tile_kind)
		drag_hover.emit(cell, monster_id)
		return true
	else:
		_update_path_preview(cell, false)
		_last_hover_cell = cell
		_hide_match_label()
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
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if _camera:
				_camera.handle_drag_button(mb.pressed, mb.global_position)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			if _camera:
				_camera.handle_drag_button(mb.pressed, mb.global_position)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _camera:
				_camera.handle_zoom(1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _camera:
				_camera.handle_zoom(-1)
	elif event is InputEventMouseMotion:
		if _camera and _camera.is_dragging():
			var motion := event as InputEventMouseMotion
			_camera.handle_drag_motion(motion.global_position)


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
	_hide_match_label()


func _update_match_label(screen_pos: Vector2, monster_id: StringName, tile_kind: int) -> void:
	if TileEffectSystem.is_affinity_match(monster_id, tile_kind):
		if _match_label == null:
			_match_label = Label.new()
			_match_label.add_theme_font_size_override("font_size", 14)
			_match_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			_match_label.add_theme_constant_override("outline_size", 3)
			_match_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(_match_label)
		var aff: int = TileEffectSystem.get_monster_affinity(monster_id)
		var aff_name: String = DungeonTileType.AFFINITY_DISPLAY.get(aff, "")
		_match_label.text = "%s ×1.5!" % aff_name
		_match_label.add_theme_color_override("font_color", DungeonTileType.AFFINITY_COLOR.get(aff, Color.WHITE))
		_match_label.position = Vector2(screen_pos.x + 20, screen_pos.y - 30)
		_match_label.visible = true
	else:
		_hide_match_label()


func _hide_match_label() -> void:
	if _match_label != null:
		_match_label.visible = false


func _is_card_drag(data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("monster_id", &"") != &""
