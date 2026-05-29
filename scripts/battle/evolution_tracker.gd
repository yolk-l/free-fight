class_name EvolutionTracker
extends Node

signal evolution_triggered(path_id: StringName, tier: int)
signal kill_count_changed(monster_type: StringName, count: int)
signal hybrid_triggered(hybrid_id: StringName)

var kill_counts: Dictionary = {}
var active_evolutions: Dictionary = {}
var active_hybrids: Dictionary = {}
var _paths: Array[EvolutionPath] = []
var _hybrids: Array = []


func setup(paths: Array[EvolutionPath]) -> void:
	_paths = paths
	_hybrids = HybridEvolution.get_all()


func on_monster_killed(monster_type: StringName, count: int = 1) -> void:
	if monster_type == &"":
		return
	kill_counts[monster_type] = kill_counts.get(monster_type, 0) + count
	kill_count_changed.emit(monster_type, kill_counts[monster_type])
	_check_evolutions(monster_type)


func _check_evolutions(monster_type: StringName) -> void:
	for path in _paths:
		if path.monster_type != monster_type:
			continue
		var count: int = kill_counts.get(monster_type, 0)
		var key := path.path_id
		var current_tier: int = active_evolutions.get(key, 0)
		if current_tier < 1 and count >= path.tier1_threshold:
			active_evolutions[key] = 1
			evolution_triggered.emit(path.path_id, 1)
			_check_hybrids()
		elif current_tier < 2 and path.tier2_threshold > 0 and count >= path.tier2_threshold:
			active_evolutions[key] = 2
			evolution_triggered.emit(path.path_id, 2)
		elif current_tier < 3 and path.tier3_threshold > 0 and count >= path.tier3_threshold:
			active_evolutions[key] = 3
			evolution_triggered.emit(path.path_id, 3)


func get_progress(path_id: StringName) -> Dictionary:
	for path in _paths:
		if path.path_id != path_id:
			continue
		var count: int = kill_counts.get(path.monster_type, 0)
		var tier: int = active_evolutions.get(path_id, 0)
		return {"count": count, "threshold": path.tier1_threshold, "tier": tier}
	return {"count": 0, "threshold": 0, "tier": 0}


func get_progress_for_monster(monster_type: StringName) -> Variant:
	for path in _paths:
		if path.monster_type != monster_type:
			continue
		var count: int = kill_counts.get(monster_type, 0)
		var tier: int = active_evolutions.get(path.path_id, 0)
		var next_threshold: int = 0
		if tier < 1:
			next_threshold = path.tier1_threshold
		elif tier < 2 and path.tier2_threshold > 0:
			next_threshold = path.tier2_threshold
		elif tier < 3 and path.tier3_threshold > 0:
			next_threshold = path.tier3_threshold
		return {"count": count, "tier": tier, "next_threshold": next_threshold}
	return null


func get_all_progress() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for path in _paths:
		var count: int = kill_counts.get(path.monster_type, 0)
		var tier: int = active_evolutions.get(path.path_id, 0)
		var next_threshold: int = 0
		var next_name: String = ""
		if tier < 1:
			next_threshold = path.tier1_threshold
			next_name = path.tier1_name
		elif tier < 2 and path.tier2_threshold > 0:
			next_threshold = path.tier2_threshold
			next_name = path.tier2_name
		elif tier < 3 and path.tier3_threshold > 0:
			next_threshold = path.tier3_threshold
			next_name = path.tier3_name
		var current_name: String = ""
		if tier >= 3:
			current_name = path.tier3_name
		elif tier >= 2:
			current_name = path.tier2_name
		elif tier >= 1:
			current_name = path.tier1_name
		result.append({
			"path_id": path.path_id,
			"display_name": path.display_name,
			"monster_type": path.monster_type,
			"count": count,
			"tier": tier,
			"next_threshold": next_threshold,
			"next_name": next_name,
			"current_name": current_name,
		})
	return result


func _check_hybrids() -> void:
	for h in _hybrids:
		if active_hybrids.has(h.id):
			continue
		var tier_a: int = active_evolutions.get(h.path_a, 0)
		var tier_b: int = active_evolutions.get(h.path_b, 0)
		if tier_a >= 1 and tier_b >= 1:
			active_hybrids[h.id] = true
			hybrid_triggered.emit(h.id)


func get_active_hybrid_list() -> Array:
	var result: Array = []
	for h in _hybrids:
		if active_hybrids.has(h.id):
			result.append(h)
	return result


func restore_state(counts: Dictionary, evolutions: Dictionary) -> void:
	kill_counts = counts.duplicate()
	active_evolutions = evolutions.duplicate()


func restore_hybrids(hybrids: Dictionary) -> void:
	active_hybrids = hybrids.duplicate()
