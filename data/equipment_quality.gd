class_name EquipmentQuality
extends RefCounted

enum Quality { COMMON, UNCOMMON, RARE, EPIC }

const MULTIPLIERS := {
	Quality.COMMON: 1.0,
	Quality.UNCOMMON: 1.3,
	Quality.RARE: 1.6,
	Quality.EPIC: 2.0,
}

const COLORS := {
	Quality.COMMON: Color(0.8, 0.8, 0.8),
	Quality.UNCOMMON: Color(0.298, 0.686, 0.314),
	Quality.RARE: Color(0.129, 0.588, 0.953),
	Quality.EPIC: Color(0.612, 0.153, 0.69),
}

const NAMES := {
	Quality.COMMON: "普通",
	Quality.UNCOMMON: "优秀",
	Quality.RARE: "稀有",
	Quality.EPIC: "史诗",
}

const WEIGHTS := {
	Quality.COMMON: 50.0,
	Quality.UNCOMMON: 30.0,
	Quality.RARE: 15.0,
	Quality.EPIC: 5.0,
}


static func roll_quality() -> int:
	var total := 0.0
	for w in WEIGHTS.values():
		total += w
	var roll := randf() * total
	var cumulative := 0.0
	for q in WEIGHTS.keys():
		cumulative += WEIGHTS[q]
		if roll <= cumulative:
			return q
	return Quality.COMMON


static func get_multiplier(q: int) -> float:
	return MULTIPLIERS.get(q, 1.0)


static func get_color(q: int) -> Color:
	return COLORS.get(q, Color.WHITE)


static func get_display_name(q: int) -> String:
	return NAMES.get(q, "普通")
