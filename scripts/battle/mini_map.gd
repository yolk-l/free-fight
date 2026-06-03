class_name MiniMap
extends Control

const MAP_SIZE := Vector2(180, 120)
const CELL_W := MAP_SIZE.x / DungeonGrid.GRID_W
const CELL_H := MAP_SIZE.y / DungeonGrid.GRID_H

var _grid: DungeonGrid
var _hero: Hero
var _monsters: Array[Monster] = []


func setup(grid: DungeonGrid, hero: Hero) -> void:
	_grid = grid
	_hero = hero
	custom_minimum_size = MAP_SIZE
	size = MAP_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_monsters(monsters: Array[Monster]) -> void:
	_monsters = monsters


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.05, 0.05, 0.08, 0.85))
	for y in DungeonGrid.GRID_H:
		for x in DungeonGrid.GRID_W:
			if not _grid.is_revealed(x, y):
				continue
			var kind := _grid.get_tile(x, y)
			if kind == DungeonTileType.Kind.WALL:
				continue
			var col := DungeonTileType.get_color(kind)
			col.a = 0.7
			var rect := Rect2(x * CELL_W, y * CELL_H, CELL_W, CELL_H)
			draw_rect(rect, col)
	for monster in _monsters:
		if is_instance_valid(monster) and monster.is_alive():
			var cell := _grid.world_to_cell(monster.global_position)
			if _grid.is_revealed(cell.x, cell.y):
				var pos := Vector2(cell.x * CELL_W + CELL_W * 0.5, cell.y * CELL_H + CELL_H * 0.5)
				draw_circle(pos, 2.0, Color(0.95, 0.3, 0.2))
	if _hero and is_instance_valid(_hero):
		var hc := _grid.world_to_cell(_hero.global_position)
		var hp := Vector2(hc.x * CELL_W + CELL_W * 0.5, hc.y * CELL_H + CELL_H * 0.5)
		draw_circle(hp, 3.0, Color(0.3, 1.0, 0.5))
	var boss_pos := Vector2(_grid.boss_cell.x * CELL_W + CELL_W * 0.5, _grid.boss_cell.y * CELL_H + CELL_H * 0.5)
	draw_circle(boss_pos, 3.0, Color(0.95, 0.3, 0.2, 0.6))
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color(0.5, 0.55, 0.65, 0.5), false, 1.0)
