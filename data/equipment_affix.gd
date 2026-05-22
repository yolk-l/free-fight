class_name EquipmentAffix
extends RefCounted

enum AffixType { NONE, SHARP, SWIFT, STURDY, SOLID }

const SLOT_WEAPON := 0
const SLOT_ARMOR := 1

const AFFIX_DATA := {
	AffixType.SHARP: {
		"display_name": "锋利的",
		"stat_key": "attack",
		"stat_value": 3,
		"slot": SLOT_WEAPON,
	},
	AffixType.SWIFT: {
		"display_name": "迅捷的",
		"stat_key": "attack_speed",
		"stat_value": 0.3,
		"slot": SLOT_WEAPON,
	},
	AffixType.STURDY: {
		"display_name": "坚韧的",
		"stat_key": "defense",
		"stat_value": 2,
		"slot": SLOT_ARMOR,
	},
	AffixType.SOLID: {
		"display_name": "坚固的",
		"stat_key": "max_hp",
		"stat_value": 20,
		"slot": SLOT_ARMOR,
	},
}


static func roll_affix(slot_type: int) -> int:
	if randf() < 0.5:
		return AffixType.NONE
	var candidates: Array = []
	for affix_type in AFFIX_DATA.keys():
		if AFFIX_DATA[affix_type]["slot"] == slot_type:
			candidates.append(affix_type)
	if candidates.is_empty():
		return AffixType.NONE
	return candidates[randi() % candidates.size()]


static func get_display_name(affix: int) -> String:
	if affix == AffixType.NONE:
		return ""
	return AFFIX_DATA.get(affix, {}).get("display_name", "")


static func get_stat_bonus(affix: int) -> CombatStats:
	var bonus := CombatStats.zero_bonus()
	if affix == AffixType.NONE:
		return bonus
	var data: Dictionary = AFFIX_DATA.get(affix, {})
	if data.is_empty():
		return bonus
	var key: String = data["stat_key"]
	var value = data["stat_value"]
	match key:
		"attack":
			bonus.attack = int(value)
		"defense":
			bonus.defense = int(value)
		"max_hp":
			bonus.max_hp = int(value)
		"attack_speed":
			bonus.attack_speed = float(value)
	return bonus
