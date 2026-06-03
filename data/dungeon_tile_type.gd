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
	VISION_TOWER,
	TELEPORTER,
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
		Kind.VISION_TOWER: return "视野塔"
		Kind.TELEPORTER: return "传送阵"
		Kind.BOSS_GATE: return "Boss门"
		Kind.SPAWN_POINT: return "起点"
		_: return ""


static func get_color(kind: int) -> Color:
	match kind:
		Kind.WALL: return Color(0.15, 0.15, 0.18)
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
		Kind.VISION_TOWER: return Color(0.9, 0.9, 0.85)
		Kind.TELEPORTER: return Color(0.5, 0.4, 0.9)
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
		Kind.VISION_TOWER: return "V"
		Kind.TELEPORTER: return "O"
		Kind.BOSS_GATE: return "B"
		Kind.SPAWN_POINT: return "S"
		_: return ""


static func get_description(kind: int) -> String:
	match kind:
		Kind.WALL: return "不可通行"
		Kind.EMPTY: return "普通地面，无特殊效果"
		Kind.HEAL_SPRING: return "经过时回复 10 HP"
		Kind.POWER_ALTAR: return "经过时攻击+2（持续3场击杀）"
		Kind.IRON_ALTAR: return "经过时防御+2（持续3场击杀）"
		Kind.RESONANCE_CRYSTAL: return "下次击杀共鸣进度×2"
		Kind.TREASURE_CHEST: return "随机永久属性+1（攻/防/攻速/HP）"
		Kind.POISON_SWAMP: return "经过时受到 8 点伤害"
		Kind.TRAP: return "经过时受到 12 点伤害"
		Kind.CURSED_GROUND: return "经过时攻击-2（持续3场击杀）"
		Kind.SLOW_MUD: return "经过时移速减半（持续2场击杀）"
		Kind.MYSTERY: return "随机触发一个事件（可能有益或有害）"
		Kind.VISION_TOWER: return "揭开周围 6 格范围的迷雾"
		Kind.TELEPORTER: return "传送到地图上配对的传送阵"
		Kind.BOSS_GATE: return "进入后触发 Boss 战"
		Kind.SPAWN_POINT: return "英雄出生点"
		_: return ""


static func is_passable(kind: int) -> bool:
	return kind != Kind.WALL


static func is_one_shot(kind: int) -> bool:
	return kind in [
		Kind.HEAL_SPRING, Kind.POWER_ALTAR, Kind.IRON_ALTAR,
		Kind.RESONANCE_CRYSTAL, Kind.TREASURE_CHEST,
		Kind.POISON_SWAMP, Kind.TRAP, Kind.CURSED_GROUND,
		Kind.SLOW_MUD, Kind.MYSTERY, Kind.BOSS_GATE,
	]
