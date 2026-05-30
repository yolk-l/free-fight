class_name MapTerrainType
extends Object

enum Kind {
	GRASSLAND,
	DESERT,
	MOUNTAIN,
	LAKE,
	FOREST,
}


static func get_display_name(kind: int) -> String:
	match kind:
		Kind.GRASSLAND: return "草原"
		Kind.DESERT: return "沙漠"
		Kind.MOUNTAIN: return "山地"
		Kind.LAKE: return "湖泊"
		Kind.FOREST: return "森林"
		_: return ""


static func get_color(kind: int) -> Color:
	match kind:
		Kind.GRASSLAND: return Color(0.45, 0.7, 0.3, 0.25)
		Kind.DESERT: return Color(0.85, 0.75, 0.4, 0.25)
		Kind.MOUNTAIN: return Color(0.55, 0.5, 0.45, 0.25)
		Kind.LAKE: return Color(0.3, 0.55, 0.85, 0.25)
		Kind.FOREST: return Color(0.2, 0.5, 0.25, 0.3)
		_: return Color(0.5, 0.5, 0.5, 0.2)


static func get_all_kinds() -> Array:
	return [
		Kind.GRASSLAND,
		Kind.DESERT,
		Kind.MOUNTAIN,
		Kind.LAKE,
		Kind.FOREST,
	]


static func get_effect_hint(kind: int) -> String:
	match kind:
		Kind.GRASSLAND: return "狼:群感↑ 哥布林:爆炸范围↑"
		Kind.DESERT: return "史莱姆:不分裂 石像鬼:光环↑ 毒蛇:毒池↑"
		Kind.MOUNTAIN: return "哥布林:爆炸伤害↑ 骷髅:复活↑ 石像鬼:防御↑"
		Kind.LAKE: return "史莱姆:多分裂 蝙蝠:失飞行 毒蛇:无毒池"
		Kind.FOREST: return "狼:群攻速↑ 骷髅:速复活"
		_: return ""
