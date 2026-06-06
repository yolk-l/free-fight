class_name DungeonTileType
extends Object

enum Kind {
	WALL,
	EMPTY,
	HEAL_SPRING,
	POWER_ALTAR,
	IRON_ALTAR,
	RESONANCE_CRYSTAL,
	TREASURE_CHEST,
	POISON_SWAMP,
	TRAP,
	CURSED_GROUND,
	SLOW_MUD,
	MYSTERY,
	EXIT,
	BOSS_GATE,
	SPAWN_POINT,
}

const POSITIVE_TILES: Array[int] = [
	Kind.HEAL_SPRING,
	Kind.POWER_ALTAR,
	Kind.IRON_ALTAR,
	Kind.RESONANCE_CRYSTAL,
	Kind.TREASURE_CHEST,
]

const NEGATIVE_TILES: Array[int] = [
	Kind.POISON_SWAMP,
	Kind.TRAP,
	Kind.CURSED_GROUND,
	Kind.SLOW_MUD,
]

const EVENT_TILES: Array[int] = [
	Kind.HEAL_SPRING,
	Kind.POWER_ALTAR,
	Kind.IRON_ALTAR,
	Kind.RESONANCE_CRYSTAL,
	Kind.TREASURE_CHEST,
	Kind.POISON_SWAMP,
	Kind.TRAP,
	Kind.CURSED_GROUND,
	Kind.SLOW_MUD,
	Kind.MYSTERY,
]

enum Affinity { FURY, GUARD, SWIFT, VITAL }

const AFFINITY_DISPLAY := {
	Affinity.FURY: "猛攻",
	Affinity.GUARD: "坚韧",
	Affinity.SWIFT: "灵巧",
	Affinity.VITAL: "生命",
}

const AFFINITY_COLOR := {
	Affinity.FURY: Color(0.95, 0.45, 0.3),
	Affinity.GUARD: Color(0.6, 0.65, 0.8),
	Affinity.SWIFT: Color(0.5, 0.85, 0.95),
	Affinity.VITAL: Color(0.4, 0.9, 0.5),
}

const TILE_AFFINITY := {
	Kind.POWER_ALTAR: Affinity.FURY,
	Kind.TRAP: Affinity.FURY,
	Kind.IRON_ALTAR: Affinity.GUARD,
	Kind.SLOW_MUD: Affinity.GUARD,
	Kind.RESONANCE_CRYSTAL: Affinity.SWIFT,
	Kind.CURSED_GROUND: Affinity.SWIFT,
	Kind.MYSTERY: Affinity.SWIFT,
	Kind.HEAL_SPRING: Affinity.VITAL,
	Kind.POISON_SWAMP: Affinity.VITAL,
	Kind.TREASURE_CHEST: Affinity.VITAL,
}


static func get_display_name(kind: int) -> String:
	match kind:
		Kind.WALL: return "墙壁"
		Kind.EMPTY: return "空地"
		Kind.HEAL_SPRING: return "治愈泉"
		Kind.POWER_ALTAR: return "力量祭坛"
		Kind.IRON_ALTAR: return "铁壁祭坛"
		Kind.RESONANCE_CRYSTAL: return "共鸣水晶"
		Kind.TREASURE_CHEST: return "宝箱"
		Kind.POISON_SWAMP: return "毒沼"
		Kind.TRAP: return "陷阱"
		Kind.CURSED_GROUND: return "诅咒地"
		Kind.SLOW_MUD: return "减速泥"
		Kind.MYSTERY: return "?"
		Kind.EXIT: return "出口"
		Kind.BOSS_GATE: return "Boss门"
		Kind.SPAWN_POINT: return "起点"
		_: return ""


static func get_color(kind: int) -> Color:
	match kind:
		Kind.WALL: return Color(0.3, 0.25, 0.22)
		Kind.EMPTY: return Color(0.28, 0.3, 0.32)
		Kind.HEAL_SPRING: return Color(0.4, 0.7, 0.9)
		Kind.POWER_ALTAR: return Color(0.9, 0.35, 0.3)
		Kind.IRON_ALTAR: return Color(0.7, 0.72, 0.75)
		Kind.RESONANCE_CRYSTAL: return Color(0.7, 0.4, 0.9)
		Kind.TREASURE_CHEST: return Color(0.95, 0.8, 0.25)
		Kind.POISON_SWAMP: return Color(0.3, 0.55, 0.25)
		Kind.TRAP: return Color(0.7, 0.2, 0.2)
		Kind.CURSED_GROUND: return Color(0.45, 0.2, 0.55)
		Kind.SLOW_MUD: return Color(0.5, 0.4, 0.28)
		Kind.MYSTERY: return Color(0.85, 0.8, 0.3)
		Kind.EXIT: return Color(0.3, 0.5, 0.3)
		Kind.BOSS_GATE: return Color(0.95, 0.3, 0.2)
		Kind.SPAWN_POINT: return Color(0.4, 0.85, 0.5)
		_: return Color(0.3, 0.3, 0.3)


static func get_icon_char(kind: int) -> String:
	match kind:
		Kind.HEAL_SPRING: return "+"
		Kind.POWER_ALTAR: return "A"
		Kind.IRON_ALTAR: return "D"
		Kind.RESONANCE_CRYSTAL: return "R"
		Kind.TREASURE_CHEST: return "T"
		Kind.POISON_SWAMP: return "P"
		Kind.TRAP: return "!"
		Kind.CURSED_GROUND: return "C"
		Kind.SLOW_MUD: return "~"
		Kind.MYSTERY: return "?"
		Kind.EXIT: return ">"
		Kind.BOSS_GATE: return "B"
		Kind.SPAWN_POINT: return "S"
		_: return ""


static func get_description(kind: int) -> String:
	match kind:
		Kind.WALL: return "不可通行"
		Kind.EMPTY: return "普通地面，无特殊效果"
		Kind.HEAL_SPRING: return "击杀怪物后回复 10 HP"
		Kind.POWER_ALTAR: return "击杀怪物后攻击+2（持续3次击杀）"
		Kind.IRON_ALTAR: return "击杀怪物后防御+2（持续3次击杀）"
		Kind.RESONANCE_CRYSTAL: return "击杀怪物后下次共鸣进度×2"
		Kind.TREASURE_CHEST: return "击杀怪物后随机永久属性+1"
		Kind.POISON_SWAMP: return "击杀怪物后受8伤害，获毒涂层×2"
		Kind.TRAP: return "击杀怪物后受12伤害，获攻速+0.5"
		Kind.CURSED_GROUND: return "击杀怪物后攻击-2，共鸣×2"
		Kind.SLOW_MUD: return "击杀怪物后移速减半，防御+3"
		Kind.MYSTERY: return "击杀怪物后随机事件"
		Kind.EXIT: return "通往其他房间的出口（清除所有事件后开启）"
		Kind.BOSS_GATE: return "进入后触发 Boss 战"
		Kind.SPAWN_POINT: return "英雄出生点"
		_: return ""


static func is_passable(kind: int) -> bool:
	return kind != Kind.WALL and kind != Kind.EXIT


static func is_event(kind: int) -> bool:
	return kind in EVENT_TILES


static func get_affinity(kind: int) -> int:
	return TILE_AFFINITY.get(kind, -1)


static func get_affinity_name(kind: int) -> String:
	var aff := get_affinity(kind)
	if aff < 0:
		return ""
	return AFFINITY_DISPLAY.get(aff, "")


static func get_affinity_color(kind: int) -> Color:
	var aff := get_affinity(kind)
	if aff < 0:
		return Color(0.5, 0.5, 0.5)
	return AFFINITY_COLOR.get(aff, Color(0.5, 0.5, 0.5))


static func is_one_shot(kind: int) -> bool:
	return kind in [
		Kind.HEAL_SPRING, Kind.POWER_ALTAR, Kind.IRON_ALTAR,
		Kind.RESONANCE_CRYSTAL, Kind.TREASURE_CHEST,
		Kind.POISON_SWAMP, Kind.TRAP, Kind.CURSED_GROUND,
		Kind.SLOW_MUD, Kind.MYSTERY, Kind.BOSS_GATE,
	]
