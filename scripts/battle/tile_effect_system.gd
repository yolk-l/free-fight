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

const CHAIN_MULT_PER_KILL := 0.3

const AFFINITY_MATCH_MULT := 1.5

const MONSTER_AFFINITY := {
	&"wolf": DungeonTileType.Affinity.FURY,
	&"goblin": DungeonTileType.Affinity.FURY,
	&"mantis": DungeonTileType.Affinity.FURY,
	&"skeleton": DungeonTileType.Affinity.GUARD,
	&"gargoyle": DungeonTileType.Affinity.GUARD,
	&"bat": DungeonTileType.Affinity.SWIFT,
	&"viper": DungeonTileType.Affinity.SWIFT,
	&"firefly": DungeonTileType.Affinity.SWIFT,
	&"slime": DungeonTileType.Affinity.VITAL,
	&"treant": DungeonTileType.Affinity.VITAL,
}

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
var _room_chain: int = 0


func setup(grid: DungeonGrid, hero: Hero, evo_tracker = null) -> void:
	_grid = grid
	_hero = hero
	_evolution_tracker = evo_tracker


func reset_chain() -> void:
	_room_chain = 0


func get_chain_count() -> int:
	return _room_chain


func get_chain_multiplier() -> float:
	return 1.0 + _room_chain * CHAIN_MULT_PER_KILL


static func get_monster_affinity(monster_id: StringName) -> int:
	return MONSTER_AFFINITY.get(monster_id, -1)


static func is_affinity_match(monster_id: StringName, tile_kind: int) -> bool:
	var m_aff: int = MONSTER_AFFINITY.get(monster_id, -1)
	var t_aff: int = DungeonTileType.get_affinity(tile_kind)
	return m_aff >= 0 and m_aff == t_aff


func get_total_multiplier(monster_id: StringName, tile_kind: int) -> float:
	var chain_mult := get_chain_multiplier()
	var affinity_mult := AFFINITY_MATCH_MULT if is_affinity_match(monster_id, tile_kind) else 1.0
	return chain_mult * affinity_mult


func apply_tile_effect(cell: Vector2i, monster_id: StringName = &"") -> Dictionary:
	var kind := _grid.get_tile(cell.x, cell.y)
	if _grid.is_used(cell.x, cell.y) and DungeonTileType.is_one_shot(kind):
		return {}
	var mult := get_total_multiplier(monster_id, kind)
	var matched := is_affinity_match(monster_id, kind)
	var result := {}
	match kind:
		DungeonTileType.Kind.HEAL_SPRING:
			var amount := int(HEAL_AMOUNT * mult)
			_apply_heal(amount)
			result = {"text": "+%d HP%s" % [amount, _mult_tag(mult, matched)], "color": Color(0.4, 0.9, 0.5)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.POWER_ALTAR:
			var amount := maxi(2, int(POWER_BUFF_AMOUNT * mult))
			_apply_temp_buff(&"power_altar", "力量", POWER_BUFF_KILLS, {"attack": float(amount)})
			result = {"text": "攻击+%d!%s" % [amount, _mult_tag(mult, matched)], "color": Color(0.9, 0.4, 0.3)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.IRON_ALTAR:
			var amount := maxi(2, int(IRON_BUFF_AMOUNT * mult))
			_apply_temp_buff(&"iron_altar", "铁壁", IRON_BUFF_KILLS, {"defense": float(amount)})
			result = {"text": "防御+%d!%s" % [amount, _mult_tag(mult, matched)], "color": Color(0.7, 0.72, 0.78)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.RESONANCE_CRYSTAL:
			_resonance_crystal_active = true
			result = {"text": "共鸣×2!%s" % _mult_tag(mult, matched), "color": Color(0.7, 0.4, 0.9)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.TREASURE_CHEST:
			var gain := _apply_treasure(mult)
			result = {"text": "%s%s" % [gain, _mult_tag(mult, matched)], "color": Color(0.95, 0.8, 0.25)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.POISON_SWAMP:
			var damage := int(POISON_DAMAGE * mult)
			_hero.take_damage(damage)
			_apply_temp_buff(&"venom_coating", "毒涂层", VENOM_COAT_ATTACKS, {}, &"attack")
			result = {"text": "毒沼 -%d HP / 毒涂层×%d%s" % [damage, VENOM_COAT_ATTACKS, _mult_tag(mult, matched)], "color": Color(0.3, 0.65, 0.25)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.TRAP:
			var damage := int(TRAP_DAMAGE * mult)
			var aspd := TRAP_ASPD_BUFF * mult
			_hero.take_damage(damage)
			_apply_temp_buff(&"trap_aspd", "陷阱激励", TRAP_ASPD_KILLS, {"attack_speed": aspd})
			result = {"text": "陷阱 -%d HP / 攻速+%.1f%s" % [damage, aspd, _mult_tag(mult, matched)], "color": Color(0.85, 0.2, 0.2)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.CURSED_GROUND:
			var debuff := maxi(2, int(CURSE_DEBUFF_AMOUNT * mult))
			_apply_temp_buff(&"curse", "诅咒", CURSE_DEBUFF_KILLS, {"attack": float(-debuff)})
			_resonance_crystal_active = true
			result = {"text": "诅咒! 攻-%d / 共鸣×2%s" % [debuff, _mult_tag(mult, matched)], "color": Color(0.5, 0.2, 0.6)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.SLOW_MUD:
			var def_buff := maxi(3, int(SLOW_DEF_BUFF * mult))
			_apply_temp_buff(&"slow_mud", "减速", SLOW_KILLS, {"move_speed_mult": SLOW_MULT})
			_apply_temp_buff(&"slow_def", "泥盾", SLOW_DEF_KILLS, {"defense": float(def_buff)})
			result = {"text": "减速! / 防御+%d%s" % [def_buff, _mult_tag(mult, matched)], "color": Color(0.55, 0.4, 0.28)}
			effect_applied.emit(cell, result["text"], result["color"])
		DungeonTileType.Kind.MYSTERY:
			result = _apply_mystery_event(cell, mult, matched)

	if DungeonTileType.is_one_shot(kind):
		_grid.mark_used(cell.x, cell.y)
	if not result.is_empty():
		_room_chain += 1
	return result


func consume_resonance_crystal() -> bool:
	if _resonance_crystal_active:
		_resonance_crystal_active = false
		return true
	return false


func _mult_tag(mult: float, matched: bool) -> String:
	if mult <= 1.05 and not matched:
		return ""
	if matched:
		return " (×%.1f 亲和!)" % mult
	return " (×%.1f)" % mult


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


func _apply_treasure(mult: float) -> String:
	if _hero == null or _hero.base_stats == null:
		return "宝箱"
	var bonus := maxi(1, int(1.0 * mult))
	var roll := randi() % 4
	match roll:
		0:
			_hero.base_stats.attack += bonus
			_hero.refresh_display()
			return "攻击+%d!" % bonus
		1:
			_hero.base_stats.defense += bonus
			_hero.refresh_display()
			return "防御+%d!" % bonus
		2:
			var aspd_bonus := 0.1 * mult
			_hero.base_stats.attack_speed += aspd_bonus
			_hero.refresh_display()
			return "攻速+%.1f!" % aspd_bonus
		_:
			var hp_bonus := maxi(10, int(10.0 * mult))
			_hero.base_stats.max_hp += hp_bonus
			_hero.base_stats.hp += hp_bonus
			_hero.refresh_display()
			return "HP+%d!" % hp_bonus


func _apply_mystery_event(cell: Vector2i, mult: float, matched: bool) -> Dictionary:
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
			var amount := int(int(chosen["value"]) * mult)
			_apply_heal(amount)
			text += " +%d HP" % amount
			color = Color(0.4, 0.9, 0.5)
		"perm_attack":
			var amount := maxi(1, int(int(chosen["value"]) * mult))
			_hero.base_stats.attack += amount
			_hero.refresh_display()
			text += " 攻+%d" % amount
			color = Color(0.9, 0.4, 0.3)
		"perm_defense":
			var amount := maxi(1, int(int(chosen["value"]) * mult))
			_hero.base_stats.defense += amount
			_hero.refresh_display()
			text += " 防+%d" % amount
			color = Color(0.7, 0.72, 0.78)
		"perm_aspd":
			var amount := float(chosen["value"]) * mult
			_hero.base_stats.attack_speed += amount
			_hero.refresh_display()
			text += " 攻速+%.1f" % amount
			color = Color(0.4, 0.8, 0.9)
		"damage":
			var amount := int(int(chosen["value"]) * mult)
			_hero.take_damage(amount)
			text += " -%d HP" % amount
			color = Color(0.85, 0.2, 0.2)
		"temp_attack_down":
			var amount := maxi(1, int(float(chosen["value"]) * mult))
			_apply_temp_buff(&"mystery_debuff", "虚弱", 4, {"attack": -float(amount)})
			text += " 攻-%d" % amount
			color = Color(0.5, 0.2, 0.6)
		"resonance_pulse":
			if _evolution_tracker and _evolution_tracker.has_method("pulse_all"):
				_evolution_tracker.pulse_all(int(chosen["value"]))
			text += " 共鸣+%d" % int(chosen["value"])
			color = Color(0.7, 0.4, 0.9)
	text += _mult_tag(mult, matched)
	effect_applied.emit(cell, text, color)
	return {"text": text, "color": color}
