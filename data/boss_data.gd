class_name BossData
extends RefCounted

var id: StringName
var display_name: String
var description: String
var base_stats: CombatStats
var wireframe_color: Color = Color(0.9, 0.2, 0.2)
var move_speed: float = 25.0
var traits: Array[Dictionary] = []
var counter_hint: String = ""
var flat_damage_reduction: int = 0
var aura_bleed: float = 0.0
var regen_per_sec: float = 0.0
var summon_interval: float = 0.0
var summon_monster_id: StringName = &""


static func get_all() -> Array[BossData]:
	return [
		_make_iron_beast(),
		_make_shadow_assassin(),
		_make_decay_wizard(),
		_make_undead_lord(),
	]


static func _make_iron_beast() -> BossData:
	var b := BossData.new()
	b.id = &"iron_beast"
	b.display_name = "铁甲巨兽"
	b.description = "被钢铁包裹的远古巨兽，防御极高但行动迟缓。"
	b.base_stats = _stats(625, 12, 8, 0.6)
	b.wireframe_color = Color(0.5, 0.5, 0.55)
	b.move_speed = 20.0
	b.traits = [
		{"name": "钢铁之躯", "desc": "防御 8，大幅减少受到的伤害"},
		{"name": "缓慢", "desc": "攻速极低，攻击间隔长"},
	]
	b.counter_hint = "推荐：剧毒(穿甲无视护甲) 或 凶残(处决高伤)"
	return b


static func _make_shadow_assassin() -> BossData:
	var b := BossData.new()
	b.id = &"shadow_assassin"
	b.display_name = "暗影刺客"
	b.description = "来去如风的暗杀者，攻击极快但身体脆弱。"
	b.base_stats = _stats(312, 20, 2, 2.0)
	b.wireframe_color = Color(0.3, 0.2, 0.5)
	b.move_speed = 40.0
	b.traits = [
		{"name": "迅捷", "desc": "攻速 2.0，每秒攻击两次"},
		{"name": "脆弱", "desc": "HP 较低，集中火力可快速击杀"},
	]
	b.counter_hint = "推荐：磐石(减伤扛住输出) 或 幽影(闪避躲开攻击)"
	return b


static func _make_decay_wizard() -> BossData:
	var b := BossData.new()
	b.id = &"decay_wizard"
	b.display_name = "腐朽巫师"
	b.description = "操纵腐朽之力的巫师，持续腐蚀英雄并能自我再生。"
	b.base_stats = _stats(437, 8, 3, 1.0)
	b.wireframe_color = Color(0.4, 0.7, 0.2)
	b.move_speed = 25.0
	b.aura_bleed = 3.0
	b.regen_per_sec = 5.0
	b.traits = [
		{"name": "腐蚀光环", "desc": "英雄持续失血 3/s"},
		{"name": "再生", "desc": "每秒回复 5 HP"},
	]
	b.counter_hint = "推荐：凶残(处决快杀) 或 追猎(攻速buff抢输出)"
	return b


static func _make_undead_lord() -> BossData:
	var b := BossData.new()
	b.id = &"undead_lord"
	b.display_name = "亡灵领主"
	b.description = "统御亡灵军团的领主，拥有护盾并能召唤骷髅护卫。"
	b.base_stats = _stats(500, 15, 5, 1.2)
	b.wireframe_color = Color(0.6, 0.5, 0.8)
	b.move_speed = 25.0
	b.flat_damage_reduction = 4
	b.summon_interval = 15.0
	b.summon_monster_id = &"skeleton"
	b.traits = [
		{"name": "亡灵护盾", "desc": "减伤 4，削弱所有攻击"},
		{"name": "召唤", "desc": "每 15s 召唤一只骷髅护卫"},
	]
	b.counter_hint = "推荐：剧毒(穿甲破盾) 或 共生(回复对耗持久战)"
	return b


static func _stats(hp: int, atk: int, def: int, aspd: float) -> CombatStats:
	var s := CombatStats.new()
	s.max_hp = hp
	s.hp = hp
	s.attack = atk
	s.defense = def
	s.attack_speed = aspd
	return s
