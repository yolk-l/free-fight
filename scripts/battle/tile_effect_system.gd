class_name TileEffectSystem
extends RefCounted

signal effect_applied(cell: Vector2i, text: String, color: Color)

const HEAL_AMOUNT := 10
const POWER_BUFF_AMOUNT := 2
const POWER_BUFF_KILLS := 3
const IRON_BUFF_AMOUNT := 2
const IRON_BUFF_KILLS := 3
const POISON_DAMAGE := 8
const TRAP_DAMAGE := 12
const CURSE_DEBUFF_AMOUNT := 2
const CURSE_DEBUFF_KILLS := 3
const SLOW_KILLS := 2
const SLOW_MULT := 0.5
const TRAP_ASPD_BUFF := 0.5
const TRAP_ASPD_KILLS := 3
const SLOW_DEF_BUFF := 3
const SLOW_DEF_KILLS := 3
const VENOM_COAT_STACKS := 2
const VENOM_COAT_ATTACKS := 2
const VISION_TOWER_RADIUS := 6

const MYSTERY_EVENTS := [
	{"name": "祝福", "weight": 3, "type": "heal", "value": 15},
	{"name": "力量涌现", "weight": 2, "type": "perm_attack", "value": 1},
	{"name": "坚韧", "weight": 2, "type": "perm_defense", "value": 1},
	{"name": "灵敏", "weight": 2, "type": "perm_aspd", "value": 0.1},
	{"name": "诅咒", "weight": 3, "type": "damage", "value": 10},
	{"name": "虚弱", "weight": 2, "type": "temp_attack_down", "value": 3},
	{"name": "共鸣脉冲", "weight": 2, "type": "resonance_pulse", "value": 1},
]

var _grid: DungeonGrid
var _hero: Hero
var _evolution_tracker = null
var _resonance_crystal_active: bool = false


func setup(grid: DungeonGrid, hero: Hero, evo_tracker = null) -> void:
	_grid = grid
	_hero = hero
	_evolution_tracker = evo_tracker


func apply_tile_effect(cell: Vector2i) -> Dictionary:
	var kind := _grid.get_tile(cell.x, cell.y)
	if _grid.is_used(cell.x, cell.y) and DungeonTileType.is_one_shot(kind):
		return {}
	var result := {}
	match kind:
		DungeonTileType.Kind.HEAL_SPRING:
			_apply_heal(HEAL_AMOUNT)
			result = {"text": "+%d HP" % HEAL_AMOUNT, "color": Color(0.4, 0.9, 0.5)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.POWER_ALTAR:
			_apply_temp_buff(&"power_altar", "力量", POWER_BUFF_KILLS, {"attack": float(POWER_BUFF_AMOUNT)})
			result = {"text": "攻击+%d!" % POWER_BUFF_AMOUNT, "color": Color(0.9, 0.4, 0.3)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.IRON_ALTAR:
			_apply_temp_buff(&"iron_altar", "铁壁", IRON_BUFF_KILLS, {"defense": float(IRON_BUFF_AMOUNT)})
			result = {"text": "防御+%d!" % IRON_BUFF_AMOUNT, "color": Color(0.7, 0.72, 0.78)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.RESONANCE_CRYSTAL:
			_resonance_crystal_active = true
			result = {"text": "共鸣×2!", "color": Color(0.7, 0.4, 0.9)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.TREASURE_CHEST:
			var gain := _apply_treasure()
			result = {"text": gain, "color": Color(0.95, 0.8, 0.25)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.POISON_SWAMP:
			_hero.take_damage(POISON_DAMAGE)
			_apply_temp_buff(&"venom_coating", "毒涂层", VENOM_COAT_ATTACKS, {}, &"attack")
			result = {"text": "毒沼 -%d HP / 毒涂层×%d" % [POISON_DAMAGE, VENOM_COAT_ATTACKS], "color": Color(0.3, 0.65, 0.25)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.TRAP:
			_hero.take_damage(TRAP_DAMAGE)
			_apply_temp_buff(&"trap_aspd", "陷阱激励", TRAP_ASPD_KILLS, {"attack_speed": float(TRAP_ASPD_BUFF)})
			result = {"text": "陷阱 -%d HP / 攻速+%.1f" % [TRAP_DAMAGE, TRAP_ASPD_BUFF], "color": Color(0.85, 0.2, 0.2)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.CURSED_GROUND:
			_apply_temp_buff(&"curse", "诅咒", CURSE_DEBUFF_KILLS, {"attack": float(-CURSE_DEBUFF_AMOUNT)})
			_resonance_crystal_active = true
			result = {"text": "诅咒! 攻-%d / 共鸣×2" % CURSE_DEBUFF_AMOUNT, "color": Color(0.5, 0.2, 0.6)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.SLOW_MUD:
			_apply_temp_buff(&"slow_mud", "减速", SLOW_KILLS, {"move_speed_mult": SLOW_MULT})
			_apply_temp_buff(&"slow_def", "泥盾", SLOW_DEF_KILLS, {"defense": float(SLOW_DEF_BUFF)})
			result = {"text": "减速! / 防御+%d" % SLOW_DEF_BUFF, "color": Color(0.55, 0.4, 0.28)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.MYSTERY:
			result = _apply_mystery_event(cell)
		DungeonTileType.Kind.VISION_TOWER:
			var revealed := _grid.reveal_around(cell.x, cell.y, VISION_TOWER_RADIUS)
			result = {"text": "视野扩展!", "color": Color(0.9, 0.9, 0.85), "revealed": revealed}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.TELEPORTER:
			var dest := _find_teleporter_dest(cell)
			if dest != Vector2i(-1, -1):
				result = {"text": "传送!", "color": Color(0.5, 0.4, 0.9), "teleport_to": dest}
				effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.BOSS_GATE:
			result = {"text": "Boss区域!", "color": Color(0.95, 0.3, 0.2), "boss_gate": true}
			effect_applied.emit(cell, result["text"], result["color"])

	if DungeonTileType.is_one_shot(kind):
		_grid.mark_used(cell.x, cell.y)
	return result


func consume_resonance_crystal() -> bool:
	if _resonance_crystal_active:
		_resonance_crystal_active = false
		return true
	return false


func _find_teleporter_dest(cell: Vector2i) -> Vector2i:
	for pair in _grid.teleporter_pairs:
		if pair[0] == cell:
			return pair[1]
		elif pair[1] == cell:
			return pair[0]
	return Vector2i(-1, -1)


func _apply_heal(amount: int) -> void:
	if _hero == null or _hero.base_stats == null:
		return
	var eff := _hero.get_combat_stats()
	_hero.base_stats.hp = mini(_hero.base_stats.hp + amount, eff.max_hp)
	_hero.refresh_display()


func _apply_temp_buff(buff_id: StringName, name_text: String, count: int, mods: Dictionary, trigger: StringName = &"kill") -> void:
	if _hero == null or _hero.buff_container == null:
		return
	var buff := BuffDef.new()
	buff.id = buff_id
	buff.display_name = name_text
	buff.duration_type = BuffDef.DurationType.COUNTED
	buff.duration_count = count
	buff.trigger_event = trigger
	buff.modifiers = mods
	_hero.buff_container.add_buff(buff, &"tile")


func _apply_treasure() -> String:
	if _hero == null or _hero.base_stats == null:
		return "宝箱"
	var roll := randi() % 4
	match roll:
		0:
			_hero.base_stats.attack += 1
			_hero.refresh_display()
			return "攻击+1!"
		1:
			_hero.base_stats.defense += 1
			_hero.refresh_display()
			return "防御+1!"
		2:
			_hero.base_stats.attack_speed += 0.1
			_hero.refresh_display()
			return "攻速+0.1!"
		_:
			_hero.base_stats.max_hp += 10
			_hero.base_stats.hp += 10
			_hero.refresh_display()
			return "HP+10!"


func _apply_mystery_event(cell: Vector2i) -> Dictionary:
	var total_weight := 0.0
	for event in MYSTERY_EVENTS:
		total_weight += event["weight"]
	var roll := randf() * total_weight
	var chosen: Dictionary = MYSTERY_EVENTS[0]
	for event in MYSTERY_EVENTS:
		roll -= event["weight"]
		if roll <= 0.0:
			chosen = event
			break
	var text: String = chosen["name"]
	var color := Color(0.85, 0.8, 0.3)
	match chosen["type"]:
		"heal":
			_apply_heal(int(chosen["value"]))
			text += " +%d HP" % int(chosen["value"])
			color = Color(0.4, 0.9, 0.5)
		"perm_attack":
			_hero.base_stats.attack += int(chosen["value"])
			_hero.refresh_display()
			text += " 攻+%d" % int(chosen["value"])
			color = Color(0.9, 0.4, 0.3)
		"perm_defense":
			_hero.base_stats.defense += int(chosen["value"])
			_hero.refresh_display()
			text += " 防+%d" % int(chosen["value"])
			color = Color(0.7, 0.72, 0.78)
		"perm_aspd":
			_hero.base_stats.attack_speed += float(chosen["value"])
			_hero.refresh_display()
			text += " 攻速+%.1f" % float(chosen["value"])
			color = Color(0.4, 0.8, 0.9)
		"damage":
			_hero.take_damage(int(chosen["value"]))
			text += " -%d HP" % int(chosen["value"])
			color = Color(0.85, 0.2, 0.2)
		"temp_attack_down":
			_apply_temp_buff(&"mystery_debuff", "虚弱", 4, {"attack": -float(chosen["value"])})
			text += " 攻-%d" % int(chosen["value"])
			color = Color(0.5, 0.2, 0.6)
		"resonance_pulse":
			if _evolution_tracker and _evolution_tracker.has_method("pulse_all"):
				_evolution_tracker.pulse_all(int(chosen["value"]))
			text += " 共鸣+%d" % int(chosen["value"])
			color = Color(0.7, 0.4, 0.9)
	effect_applied.emit(cell, text, color)
	return {"text": text, "color": color}
