class_name MapTerrainType
extends Object

enum Kind {
	SPIRIT_SPRING,
	CRYSTAL_MINE,
	ROCKY_GROUND,
	BRAMBLES,
}


static func get_display_name(kind: int) -> String:
	match kind:
		Kind.SPIRIT_SPRING: return "灵泉"
		Kind.CRYSTAL_MINE: return "水晶矿"
		Kind.ROCKY_GROUND: return "岩地"
		Kind.BRAMBLES: return "荆棘丛"
		_: return ""


static func get_color(kind: int) -> Color:
	match kind:
		Kind.SPIRIT_SPRING: return Color(0.4, 0.7, 1.0, 0.25)
		Kind.CRYSTAL_MINE: return Color(0.7, 0.4, 0.85, 0.25)
		Kind.ROCKY_GROUND: return Color(0.55, 0.5, 0.4, 0.25)
		Kind.BRAMBLES: return Color(0.25, 0.55, 0.2, 0.3)
		_: return Color(0.5, 0.5, 0.5, 0.2)


static func get_all_kinds() -> Array:
	return [
		Kind.SPIRIT_SPRING,
		Kind.CRYSTAL_MINE,
		Kind.ROCKY_GROUND,
		Kind.BRAMBLES,
	]
