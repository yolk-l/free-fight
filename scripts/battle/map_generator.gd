class_name MapGenerator
extends RefCounted

const REVEAL_RADIUS := 3
const GRID_W := DungeonGrid.GRID_W  # 30
const GRID_H := DungeonGrid.GRID_H  # 20

enum RoomRole { SPAWN, RELAY, TREASURE, DANGER, ELITE_GUARD, BOSS_ANTECHAMBER, BOSS }
enum CorridorTheme { SAFE, TRIAL, RESONANCE, BARREN }

var _nodes: Array = []   # Array of Dictionary {role, is_main, rect}
var _edges: Array = []   # Array of Dictionary {from, to, is_main, width, is_bottleneck}
var _corridor_cells: Dictionary = {}  # edge index -> Array[Vector2i]


func generate() -> DungeonGrid:
	var grid := DungeonGrid.new()
	_nodes.clear()
	_edges.clear()
	_build_topology()
	_assign_room_positions()
	_carve_rooms(grid)
	_carve_corridors(grid)
	_place_spawn_and_boss(grid)
	_place_room_pois(grid)
	_place_corridor_pois(grid)
	_place_teleporters(grid)
	_fill_remaining(grid)
	_place_vision_towers(grid)
	grid.rooms = _get_all_rects()
	grid.reveal_around(grid.spawn_cell.x, grid.spawn_cell.y, REVEAL_RADIUS)
	return grid


# === Phase 1: Topology ===

func _build_topology() -> void:
	var relay_count := randi_range(1, 2)
	# Main path: Spawn -> Relay(s) -> BossAntechamber -> Boss
	_nodes.append(_make_node(RoomRole.SPAWN, true))  # 0
	for i in relay_count:
		_nodes.append(_make_node(RoomRole.RELAY, true))
	_nodes.append(_make_node(RoomRole.BOSS_ANTECHAMBER, true))
	_nodes.append(_make_node(RoomRole.BOSS, true))

	# Connect main path linearly
	var main_count := _nodes.size()
	for i in range(main_count - 1):
		_edges.append(_make_edge(i, i + 1, true, 2, false))

	# Branch loops from relays
	var branch_roles: Array = [RoomRole.TREASURE, RoomRole.DANGER, RoomRole.ELITE_GUARD]
	branch_roles.shuffle()
	var branch_idx := 0

	for i in range(1, 1 + relay_count):
		if branch_idx >= branch_roles.size():
			break
		if _nodes.size() >= 8:
			break
		var branch_role: int = branch_roles[branch_idx]
		branch_idx += 1
		var branch_node_idx := _nodes.size()
		_nodes.append(_make_node(branch_role, false))
		# Loop: relay[i] -> branch -> next main node
		var next_main := i + 1
		_edges.append(_make_edge(i, branch_node_idx, false, 1, branch_role == RoomRole.ELITE_GUARD))
		_edges.append(_make_edge(branch_node_idx, next_main, false, 1, false))


func _make_node(role: int, is_main: bool) -> Dictionary:
	return {"role": role, "is_main": is_main, "rect": Rect2i()}


func _make_edge(from: int, to: int, is_main: bool, width: int, is_bottleneck: bool) -> Dictionary:
	return {"from": from, "to": to, "is_main": is_main, "width": width, "is_bottleneck": is_bottleneck}


# === Phase 2: Position Assignment ===

func _assign_room_positions() -> void:
	var main_indices: Array[int] = []
	for i in _nodes.size():
		if _nodes[i]["is_main"]:
			main_indices.append(i)

	var main_count := main_indices.size()
	# Divide grid horizontally into segments for main path
	var segment_w: float = float(GRID_W - 4) / float(main_count)

	for seg_i in main_count:
		var node_idx := main_indices[seg_i]
		var role: int = _nodes[node_idx]["role"]
		var room_size := _get_room_size(role)
		var seg_start_x := int(2 + seg_i * segment_w)
		var seg_end_x := int(2 + (seg_i + 1) * segment_w)
		var cx := randi_range(seg_start_x + room_size.x / 2, maxi(seg_start_x + room_size.x / 2, seg_end_x - room_size.x / 2 - 1))
		var cy: int
		if role == RoomRole.SPAWN:
			cy = randi_range(GRID_H - room_size.y - 2, GRID_H - room_size.y - 1)
		elif role == RoomRole.BOSS:
			cy = randi_range(2, 3)
		else:
			cy = randi_range(GRID_H / 2 - 2, GRID_H / 2 + 2)

		var rx := clampi(cx - room_size.x / 2, 1, GRID_W - room_size.x - 1)
		var ry := clampi(cy - room_size.y / 2, 1, GRID_H - room_size.y - 1)
		_nodes[node_idx]["rect"] = Rect2i(rx, ry, room_size.x, room_size.y)

	# Place branch nodes offset vertically from their connecting main nodes
	for i in _nodes.size():
		if _nodes[i]["is_main"]:
			continue
		var connecting_main := _find_connecting_main(i)
		if connecting_main < 0:
			continue
		var main_rect: Rect2i = _nodes[connecting_main]["rect"]
		var role: int = _nodes[i]["role"]
		var room_size := _get_room_size(role)
		var main_cy := main_rect.position.y + main_rect.size.y / 2
		# Place branch above or below main path
		var cy: int
		if main_cy > GRID_H / 2:
			cy = randi_range(2, maxi(3, main_cy - room_size.y - 3))
		else:
			cy = randi_range(mini(GRID_H - room_size.y - 2, main_cy + main_rect.size.y + 2), GRID_H - room_size.y - 1)
		var cx := main_rect.position.x + randi_range(-2, 3)
		var rx := clampi(cx, 1, GRID_W - room_size.x - 1)
		var ry := clampi(cy, 1, GRID_H - room_size.y - 1)
		_nodes[i]["rect"] = Rect2i(rx, ry, room_size.x, room_size.y)

	_resolve_overlaps()


func _get_room_size(role: int) -> Vector2i:
	match role:
		RoomRole.SPAWN:
			return Vector2i(randi_range(5, 6), randi_range(5, 6))
		RoomRole.RELAY:
			return Vector2i(randi_range(5, 6), randi_range(5, 6))
		RoomRole.TREASURE, RoomRole.DANGER:
			return Vector2i(randi_range(4, 5), randi_range(4, 5))
		RoomRole.ELITE_GUARD:
			return Vector2i(randi_range(4, 5), randi_range(4, 5))
		RoomRole.BOSS_ANTECHAMBER:
			return Vector2i(randi_range(6, 7), randi_range(6, 7))
		RoomRole.BOSS:
			return Vector2i(randi_range(7, 8), randi_range(7, 8))
		_:
			return Vector2i(5, 5)


func _find_connecting_main(branch_idx: int) -> int:
	for edge in _edges:
		if edge["from"] == branch_idx and _nodes[edge["to"]]["is_main"]:
			return edge["to"]
		if edge["to"] == branch_idx and _nodes[edge["from"]]["is_main"]:
			return edge["from"]
	return -1


func _resolve_overlaps() -> void:
	for attempt in 20:
		var found_overlap := false
		for i in _nodes.size():
			for j in range(i + 1, _nodes.size()):
				var ri: Rect2i = _nodes[i]["rect"]
				var rj: Rect2i = _nodes[j]["rect"]
				if ri.grow(2).intersects(rj):
					found_overlap = true
					# Push apart
					var ci := Vector2(ri.position.x + ri.size.x * 0.5, ri.position.y + ri.size.y * 0.5)
					var cj := Vector2(rj.position.x + rj.size.x * 0.5, rj.position.y + rj.size.y * 0.5)
					var diff := cj - ci
					if diff.length() < 1.0:
						diff = Vector2(1, 1)
					diff = diff.normalized() * 2.0
					if not _nodes[j]["is_main"] or _nodes[j]["role"] != RoomRole.SPAWN:
						var new_x := clampi(int(rj.position.x + diff.x), 1, GRID_W - rj.size.x - 1)
						var new_y := clampi(int(rj.position.y + diff.y), 1, GRID_H - rj.size.y - 1)
						_nodes[j]["rect"] = Rect2i(new_x, new_y, rj.size.x, rj.size.y)
		if not found_overlap:
			break


# === Phase 3: Carve Rooms ===

func _carve_rooms(grid: DungeonGrid) -> void:
	for node in _nodes:
		var room: Rect2i = node["rect"]
		for y in range(room.position.y, room.end.y):
			for x in range(room.position.x, room.end.x):
				grid.set_tile(x, y, DungeonTileType.Kind.EMPTY)


# === Phase 4: Carve Corridors ===

func _carve_corridors(grid: DungeonGrid) -> void:
	_corridor_cells.clear()
	for edge_idx in _edges.size():
		var edge: Dictionary = _edges[edge_idx]
		var from_rect: Rect2i = _nodes[edge["from"]]["rect"]
		var to_rect: Rect2i = _nodes[edge["to"]]["rect"]
		var from_center := Vector2i(from_rect.position.x + from_rect.size.x / 2, from_rect.position.y + from_rect.size.y / 2)
		var to_center := Vector2i(to_rect.position.x + to_rect.size.x / 2, to_rect.position.y + to_rect.size.y / 2)
		var width: int = edge["width"]
		if edge["is_main"]:
			width = 2
		_corridor_cells[edge_idx] = []
		_carve_corridor_path(grid, from_center, to_center, width, edge["is_bottleneck"], edge_idx)


func _carve_corridor_path(grid: DungeonGrid, from: Vector2i, to: Vector2i, width: int, is_bottleneck: bool, edge_idx: int = -1) -> void:
	var roll := randf()
	if roll < 0.5:
		_carve_l_corridor(grid, from, to, width, is_bottleneck, edge_idx)
	elif roll < 0.8:
		_carve_z_corridor(grid, from, to, width, is_bottleneck, edge_idx)
	else:
		_carve_s_corridor(grid, from, to, width, is_bottleneck, edge_idx)


func _carve_l_corridor(grid: DungeonGrid, from: Vector2i, to: Vector2i, width: int, is_bottleneck: bool, edge_idx: int = -1) -> void:
	var x := from.x
	var y := from.y
	var dir_x := 1 if to.x > from.x else -1
	var dir_y := 1 if to.y > from.y else -1
	var total_steps := absi(to.x - from.x) + absi(to.y - from.y)
	var step := 0
	var mid := total_steps / 2

	if randi() % 2 == 0:
		while x != to.x:
			var w := _get_corridor_width(width, step, total_steps, mid, is_bottleneck)
			_carve_segment(grid, x, y, w, edge_idx)
			x += dir_x
			step += 1
		while y != to.y:
			var w := _get_corridor_width(width, step, total_steps, mid, is_bottleneck)
			_carve_segment(grid, x, y, w, edge_idx)
			y += dir_y
			step += 1
	else:
		while y != to.y:
			var w := _get_corridor_width(width, step, total_steps, mid, is_bottleneck)
			_carve_segment(grid, x, y, w, edge_idx)
			y += dir_y
			step += 1
		while x != to.x:
			var w := _get_corridor_width(width, step, total_steps, mid, is_bottleneck)
			_carve_segment(grid, x, y, w, edge_idx)
			x += dir_x
			step += 1
	_carve_segment(grid, to.x, to.y, width, edge_idx)


func _carve_z_corridor(grid: DungeonGrid, from: Vector2i, to: Vector2i, width: int, is_bottleneck: bool, edge_idx: int = -1) -> void:
	var mid_x := (from.x + to.x) / 2 + randi_range(-2, 2)
	mid_x = clampi(mid_x, 2, GRID_W - 3)
	var mid_y := (from.y + to.y) / 2 + randi_range(-2, 2)
	mid_y = clampi(mid_y, 2, GRID_H - 3)
	var waypoint := Vector2i(mid_x, mid_y)
	_carve_l_corridor(grid, from, waypoint, width, is_bottleneck, edge_idx)
	_carve_l_corridor(grid, waypoint, to, width, false, edge_idx)


func _carve_s_corridor(grid: DungeonGrid, from: Vector2i, to: Vector2i, width: int, is_bottleneck: bool, edge_idx: int = -1) -> void:
	var third_x := from.x + (to.x - from.x) / 3 + randi_range(-1, 1)
	var third_y := from.y + (to.y - from.y) / 3 + randi_range(-1, 1)
	var two_third_x := from.x + (to.x - from.x) * 2 / 3 + randi_range(-1, 1)
	var two_third_y := from.y + (to.y - from.y) * 2 / 3 + randi_range(-1, 1)
	third_x = clampi(third_x, 2, GRID_W - 3)
	third_y = clampi(third_y, 2, GRID_H - 3)
	two_third_x = clampi(two_third_x, 2, GRID_W - 3)
	two_third_y = clampi(two_third_y, 2, GRID_H - 3)
	var wp1 := Vector2i(third_x, third_y)
	var wp2 := Vector2i(two_third_x, two_third_y)
	_carve_l_corridor(grid, from, wp1, width, is_bottleneck, edge_idx)
	_carve_l_corridor(grid, wp1, wp2, width, false, edge_idx)
	_carve_l_corridor(grid, wp2, to, width, false, edge_idx)


func _get_corridor_width(base_width: int, step: int, total: int, mid: int, is_bottleneck: bool) -> int:
	if not is_bottleneck:
		return base_width
	# Narrow to 1 in the middle portion
	var dist_to_mid := absi(step - mid)
	if dist_to_mid <= 2:
		return 1
	return base_width


func _carve_segment(grid: DungeonGrid, cx: int, cy: int, width: int, edge_idx: int = -1) -> void:
	for dy in width:
		for dx in width:
			var nx := cx + dx
			var ny := cy + dy
			if grid.in_bounds(nx, ny) and grid.get_tile(nx, ny) == DungeonTileType.Kind.WALL:
				grid.set_tile(nx, ny, DungeonTileType.Kind.EMPTY)
	if edge_idx >= 0 and grid.in_bounds(cx, cy):
		var cell := Vector2i(cx, cy)
		var arr: Array = _corridor_cells[edge_idx]
		if arr.is_empty() or arr.back() != cell:
			arr.append(cell)


# === Phase 5: Spawn & Boss ===

func _place_spawn_and_boss(grid: DungeonGrid) -> void:
	for node in _nodes:
		if node["role"] == RoomRole.SPAWN:
			var room: Rect2i = node["rect"]
			var cx := room.position.x + room.size.x / 2
			var cy := room.position.y + room.size.y / 2
			grid.spawn_cell = Vector2i(cx, cy)
			grid.set_tile(cx, cy, DungeonTileType.Kind.SPAWN_POINT)
		elif node["role"] == RoomRole.BOSS:
			var room: Rect2i = node["rect"]
			var cx := room.position.x + room.size.x / 2
			var cy := room.position.y + room.size.y / 2
			grid.boss_cell = Vector2i(cx, cy)
			grid.set_tile(cx, cy, DungeonTileType.Kind.BOSS_GATE)


# === Phase 6: Room POIs ===

func _place_room_pois(grid: DungeonGrid) -> void:
	for node in _nodes:
		var role: int = node["role"]
		var room: Rect2i = node["rect"]
		match role:
			RoomRole.SPAWN:
				_place_in_room(grid, room, DungeonTileType.Kind.HEAL_SPRING, 1, 0.6)
			RoomRole.RELAY:
				_place_in_room(grid, room, DungeonTileType.Kind.HEAL_SPRING, 1, 1.0)
				_place_in_room(grid, room, DungeonTileType.Kind.MYSTERY, 1, 0.5)
			RoomRole.TREASURE:
				_place_in_room(grid, room, DungeonTileType.Kind.TREASURE_CHEST, 2, 1.0)
				_place_in_room(grid, room, DungeonTileType.Kind.RESONANCE_CRYSTAL, 1, 0.7)
				_place_in_room(grid, room, DungeonTileType.Kind.POWER_ALTAR, 1, 0.5)
			RoomRole.DANGER:
				_place_in_room(grid, room, DungeonTileType.Kind.POISON_SWAMP, 2, 1.0)
				_place_in_room(grid, room, DungeonTileType.Kind.TRAP, 1, 0.8)
				_place_in_room(grid, room, DungeonTileType.Kind.CURSED_GROUND, 1, 0.6)
				_place_in_room(grid, room, DungeonTileType.Kind.TREASURE_CHEST, 1, 1.0)
			RoomRole.ELITE_GUARD:
				_place_in_room(grid, room, DungeonTileType.Kind.POWER_ALTAR, 1, 1.0)
				_place_in_room(grid, room, DungeonTileType.Kind.IRON_ALTAR, 1, 0.7)
			RoomRole.BOSS_ANTECHAMBER:
				_place_in_room(grid, room, DungeonTileType.Kind.RESONANCE_CRYSTAL, 1, 1.0)
				_place_in_room(grid, room, DungeonTileType.Kind.HEAL_SPRING, 1, 1.0)
				_place_in_room(grid, room, DungeonTileType.Kind.POWER_ALTAR, 1, 0.5)


func _place_in_room(grid: DungeonGrid, room: Rect2i, kind: int, count: int, chance: float) -> void:
	if randf() > chance:
		return
	var placed := 0
	var attempts := 0
	while placed < count and attempts < 30:
		attempts += 1
		var x := randi_range(room.position.x + 1, room.end.x - 2)
		var y := randi_range(room.position.y + 1, room.end.y - 2)
		if grid.get_tile(x, y) == DungeonTileType.Kind.EMPTY:
			var cell := Vector2i(x, y)
			if cell != grid.spawn_cell and cell != grid.boss_cell:
				grid.set_tile(x, y, kind)
				placed += 1


# === Phase 7: Corridor Themed Tiles ===

func _place_corridor_pois(grid: DungeonGrid) -> void:
	for edge_idx in _edges.size():
		var edge: Dictionary = _edges[edge_idx]
		var theme := _assign_corridor_theme(edge)
		var cells: Array = _corridor_cells.get(edge_idx, [])
		var corridor_only := _filter_corridor_cells(grid, cells)
		if corridor_only.is_empty():
			continue
		_place_entrance_toll(grid, edge, corridor_only)
		_place_themed_tiles(grid, corridor_only, theme)


func _assign_corridor_theme(edge: Dictionary) -> int:
	if edge["is_main"]:
		return CorridorTheme.SAFE if randf() < 0.6 else CorridorTheme.RESONANCE
	var to_role: int = _nodes[edge["to"]]["role"]
	match to_role:
		RoomRole.TREASURE, RoomRole.DANGER, RoomRole.ELITE_GUARD:
			return CorridorTheme.TRIAL
		_:
			var from_role: int = _nodes[edge["from"]]["role"]
			match from_role:
				RoomRole.TREASURE, RoomRole.DANGER, RoomRole.ELITE_GUARD:
					return CorridorTheme.TRIAL
	return CorridorTheme.BARREN


func _filter_corridor_cells(grid: DungeonGrid, cells: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in cells:
		var c: Vector2i = cell
		if grid.in_bounds(c.x, c.y) and grid.get_tile(c.x, c.y) == DungeonTileType.Kind.EMPTY:
			if c != grid.spawn_cell and c != grid.boss_cell:
				result.append(c)
	return result


func _place_entrance_toll(grid: DungeonGrid, edge: Dictionary, corridor: Array[Vector2i]) -> void:
	var to_role: int = _nodes[edge["to"]]["role"]
	var toll_kind := -1
	match to_role:
		RoomRole.TREASURE:
			toll_kind = DungeonTileType.Kind.TRAP
		RoomRole.ELITE_GUARD:
			toll_kind = DungeonTileType.Kind.POISON_SWAMP
		RoomRole.BOSS_ANTECHAMBER:
			toll_kind = DungeonTileType.Kind.CURSED_GROUND
	if toll_kind < 0:
		return
	var end_idx := corridor.size() - 1
	for i in range(end_idx, maxi(-1, end_idx - 2), -1):
		if i >= 0 and i < corridor.size():
			var c: Vector2i = corridor[i]
			if grid.get_tile(c.x, c.y) == DungeonTileType.Kind.EMPTY:
				grid.set_tile(c.x, c.y, toll_kind)
				return


func _place_themed_tiles(grid: DungeonGrid, corridor: Array[Vector2i], theme: int) -> void:
	match theme:
		CorridorTheme.SAFE:
			_place_safe_tiles(grid, corridor)
		CorridorTheme.TRIAL:
			_place_trial_tiles(grid, corridor)
		CorridorTheme.RESONANCE:
			_place_resonance_tiles(grid, corridor)
		CorridorTheme.BARREN:
			_place_barren_tiles(grid, corridor)


func _place_safe_tiles(grid: DungeonGrid, corridor: Array[Vector2i]) -> void:
	var spacing := 2
	var placed := 0
	for i in range(0, corridor.size(), spacing):
		var c: Vector2i = corridor[i]
		if grid.get_tile(c.x, c.y) != DungeonTileType.Kind.EMPTY:
			continue
		var kind: int
		if placed == 0:
			kind = DungeonTileType.Kind.HEAL_SPRING
		else:
			var roll := randf()
			if roll < 0.45:
				kind = DungeonTileType.Kind.HEAL_SPRING
			elif roll < 0.7:
				kind = DungeonTileType.Kind.POWER_ALTAR
			else:
				kind = DungeonTileType.Kind.IRON_ALTAR
		grid.set_tile(c.x, c.y, kind)
		placed += 1


func _place_trial_tiles(grid: DungeonGrid, corridor: Array[Vector2i]) -> void:
	var spacing := 2
	var negatives := [DungeonTileType.Kind.POISON_SWAMP, DungeonTileType.Kind.TRAP, DungeonTileType.Kind.CURSED_GROUND]
	for i in range(0, corridor.size(), spacing):
		var c: Vector2i = corridor[i]
		if grid.get_tile(c.x, c.y) != DungeonTileType.Kind.EMPTY:
			continue
		grid.set_tile(c.x, c.y, negatives[randi() % negatives.size()])
	# 试炼路尽头放一个正面奖励作为"诱饵"
	for i in range(corridor.size() - 1, -1, -1):
		var c: Vector2i = corridor[i]
		if grid.get_tile(c.x, c.y) == DungeonTileType.Kind.EMPTY:
			var rewards := [DungeonTileType.Kind.TREASURE_CHEST, DungeonTileType.Kind.POWER_ALTAR]
			grid.set_tile(c.x, c.y, rewards[randi() % rewards.size()])
			break


func _place_resonance_tiles(grid: DungeonGrid, corridor: Array[Vector2i]) -> void:
	var spacing := 2
	for i in range(0, corridor.size(), spacing):
		var c: Vector2i = corridor[i]
		if grid.get_tile(c.x, c.y) != DungeonTileType.Kind.EMPTY:
			continue
		var kind: int
		if randf() < 0.6:
			kind = DungeonTileType.Kind.RESONANCE_CRYSTAL
		else:
			kind = DungeonTileType.Kind.MYSTERY
		grid.set_tile(c.x, c.y, kind)


func _place_barren_tiles(grid: DungeonGrid, corridor: Array[Vector2i]) -> void:
	if corridor.size() < 3:
		return
	var mid := corridor.size() / 2
	var c: Vector2i = corridor[mid]
	if grid.get_tile(c.x, c.y) == DungeonTileType.Kind.EMPTY:
		grid.set_tile(c.x, c.y, DungeonTileType.Kind.MYSTERY)


# === Phase 8: Teleporters ===

func _place_teleporters(grid: DungeonGrid) -> void:
	if _nodes.size() < 4:
		return
	# Find two rooms far apart (non-spawn, non-boss)
	var candidates: Array[int] = []
	for i in _nodes.size():
		var role: int = _nodes[i]["role"]
		if role != RoomRole.SPAWN and role != RoomRole.BOSS:
			candidates.append(i)
	if candidates.size() < 2:
		return
	var best_pair := [0, 1]
	var best_dist := 0.0
	for i in candidates.size():
		for j in range(i + 1, candidates.size()):
			var ri: Rect2i = _nodes[candidates[i]]["rect"]
			var rj: Rect2i = _nodes[candidates[j]]["rect"]
			var ci := Vector2(ri.position.x + ri.size.x * 0.5, ri.position.y + ri.size.y * 0.5)
			var cj := Vector2(rj.position.x + rj.size.x * 0.5, rj.position.y + rj.size.y * 0.5)
			var d := ci.distance_to(cj)
			if d > best_dist:
				best_dist = d
				best_pair = [candidates[i], candidates[j]]

	var r0: Rect2i = _nodes[best_pair[0]]["rect"]
	var r1: Rect2i = _nodes[best_pair[1]]["rect"]
	var p0 := _find_empty_in_room(grid, r0)
	var p1 := _find_empty_in_room(grid, r1)
	if p0 != Vector2i(-1, -1) and p1 != Vector2i(-1, -1):
		grid.set_tile(p0.x, p0.y, DungeonTileType.Kind.TELEPORTER)
		grid.set_tile(p1.x, p1.y, DungeonTileType.Kind.TELEPORTER)
		grid.teleporter_pairs.append([p0, p1])


func _find_empty_in_room(grid: DungeonGrid, room: Rect2i) -> Vector2i:
	for _attempt in 20:
		var x := randi_range(room.position.x + 1, room.end.x - 2)
		var y := randi_range(room.position.y + 1, room.end.y - 2)
		if grid.get_tile(x, y) == DungeonTileType.Kind.EMPTY:
			var cell := Vector2i(x, y)
			if cell != grid.spawn_cell and cell != grid.boss_cell:
				return cell
	return Vector2i(-1, -1)


# === Phase 9: Fill Remaining ===

func _fill_remaining(grid: DungeonGrid) -> void:
	for y in GRID_H:
		for x in GRID_W:
			if grid.get_tile(x, y) != DungeonTileType.Kind.EMPTY:
				continue
			var cell := Vector2i(x, y)
			if cell == grid.spawn_cell or cell == grid.boss_cell:
				continue
			var dist := grid.get_path_distance_to_spawn(x, y)
			var kind := _roll_sparse_tile(dist)
			if kind != DungeonTileType.Kind.EMPTY:
				grid.set_tile(x, y, kind)


func _roll_sparse_tile(dist: int) -> int:
	var roll := randf()
	if dist <= 10:
		if roll < 0.04:
			return DungeonTileType.Kind.MYSTERY
		return DungeonTileType.Kind.EMPTY
	elif dist <= 20:
		if roll < 0.03:
			return DungeonTileType.Kind.MYSTERY
		elif roll < 0.06:
			return DungeonTileType.Kind.SLOW_MUD
		return DungeonTileType.Kind.EMPTY
	elif dist <= 30:
		if roll < 0.03:
			return DungeonTileType.Kind.MYSTERY
		elif roll < 0.08:
			var negatives := [DungeonTileType.Kind.POISON_SWAMP, DungeonTileType.Kind.TRAP, DungeonTileType.Kind.CURSED_GROUND]
			return negatives[randi() % negatives.size()]
		return DungeonTileType.Kind.EMPTY
	else:
		if roll < 0.03:
			var positives := [DungeonTileType.Kind.TREASURE_CHEST, DungeonTileType.Kind.POWER_ALTAR]
			return positives[randi() % positives.size()]
		elif roll < 0.05:
			return DungeonTileType.Kind.MYSTERY
		elif roll < 0.12:
			var negatives := [DungeonTileType.Kind.POISON_SWAMP, DungeonTileType.Kind.TRAP, DungeonTileType.Kind.CURSED_GROUND]
			return negatives[randi() % negatives.size()]
		return DungeonTileType.Kind.EMPTY


func _place_vision_towers(grid: DungeonGrid) -> void:
	var placed := 0
	var attempts := 0
	while placed < 2 and attempts < 80:
		attempts += 1
		var x := randi_range(2, GRID_W - 3)
		var y := randi_range(2, GRID_H - 3)
		if grid.get_tile(x, y) == DungeonTileType.Kind.EMPTY:
			var dist := grid.get_path_distance_to_spawn(x, y)
			if dist > 8:
				grid.set_tile(x, y, DungeonTileType.Kind.VISION_TOWER)
				placed += 1


# === Utility ===

func _get_all_rects() -> Array[Rect2i]:
	var result: Array[Rect2i] = []
	for node in _nodes:
		result.append(node["rect"])
	return result
