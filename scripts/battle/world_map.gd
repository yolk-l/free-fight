class_name WorldMap
extends RefCounted

enum RoomType { START, NORMAL, TREASURE, DANGER, ELITE, BOSS }

var rooms: Array[DungeonGrid] = []
var room_types: Array[int] = []
var tree_edges: Array = []  # Array of [from_idx, to_idx]
var room_depth: Array[int] = []
var room_cleared: Array[bool] = []


func get_room(index: int) -> DungeonGrid:
	if index < 0 or index >= rooms.size():
		return null
	return rooms[index]


func get_neighbors(room_index: int) -> Array[int]:
	var result: Array[int] = []
	for edge in tree_edges:
		if edge[0] == room_index:
			result.append(edge[1])
		elif edge[1] == room_index:
			result.append(edge[0])
	return result


func mark_room_cleared(index: int) -> void:
	if index >= 0 and index < room_cleared.size():
		room_cleared[index] = true


func is_room_cleared(index: int) -> bool:
	if index < 0 or index >= room_cleared.size():
		return false
	return room_cleared[index]


func get_boss_room_index() -> int:
	for i in room_types.size():
		if room_types[i] == RoomType.BOSS:
			return i
	return -1
