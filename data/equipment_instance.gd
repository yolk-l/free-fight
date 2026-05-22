class_name EquipmentInstance
extends RefCounted

var base_data = null
var quality: int = 0
var affix: int = 0


static func create(data, q: int, a: int):
	var inst = EquipmentInstance.new()
	inst.base_data = data
	inst.quality = q
	inst.affix = a
	return inst


func get_display_name() -> String:
	var prefix := EquipmentAffix.get_display_name(affix)
	var base_name = base_data.display_name if base_data else "???"
	return prefix + base_name


func get_quality_color() -> Color:
	return EquipmentQuality.get_color(quality)


func get_slot_key() -> StringName:
	if base_data:
		return base_data.get_slot_key()
	return &"weapon"


func get_tooltip() -> String:
	var lines: Array = []
	lines.append("%s [%s]" % [get_display_name(), EquipmentQuality.get_display_name(quality)])
	var bonus = get_stat_bonus()
	if bonus.attack > 0:
		lines.append("攻击 +%d" % bonus.attack)
	if bonus.defense > 0:
		lines.append("防御 +%d" % bonus.defense)
	if bonus.max_hp > 0:
		lines.append("生命 +%d" % bonus.max_hp)
	if bonus.attack_speed > 0.0:
		lines.append("攻速 +%.1f" % bonus.attack_speed)
	return "\n".join(lines)


func get_stat_bonus() -> CombatStats:
	var bonus := CombatStats.zero_bonus()
	if base_data == null or base_data.stat_bonus == null:
		return bonus
	var mult = EquipmentQuality.get_multiplier(quality)
	var base = base_data.stat_bonus
	bonus.attack = int(floor(base.attack * mult))
	bonus.max_hp = int(floor(base.max_hp * mult))
	bonus.defense = int(floor(base.defense * mult))
	bonus.attack_speed = base.attack_speed * mult
	var affix_bonus = EquipmentAffix.get_stat_bonus(affix)
	bonus.attack += affix_bonus.attack
	bonus.max_hp += affix_bonus.max_hp
	bonus.defense += affix_bonus.defense
	bonus.attack_speed += affix_bonus.attack_speed
	return bonus
