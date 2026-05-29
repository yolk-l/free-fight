class_name HybridEvolution
extends RefCounted

var id: StringName
var path_a: StringName
var path_b: StringName
var display_name: String
var description: String


static func get_all() -> Array:
	return [
		_make(&"predator_shadow", &"predator", &"shadow", "暗夜猎手", "攻速+0.2"),
		_make(&"predator_brutal", &"predator", &"brutal", "嗜血猛兽", "攻击+4"),
		_make(&"shadow_venom", &"shadow", &"venom", "暗影毒刺", "闪避+10%,穿甲+1"),
		_make(&"fortress_symbiosis", &"fortress", &"symbiosis", "不动如山", "减伤+2,回复+0.3/s"),
		_make(&"fortress_undead", &"fortress", &"undead", "永恒守护", "HP上限+25"),
		_make(&"brutal_venom", &"brutal", &"venom", "毒裁者", "穿甲+2,处决阈值+5%"),
		_make(&"undead_symbiosis", &"undead", &"symbiosis", "生死融合", "击杀回血+2,回复+0.3/s"),
		_make(&"predator_undead", &"predator", &"undead", "亡灵猎手", "击杀回血+3"),
	]


static func _make(p_id: StringName, a: StringName, b: StringName, name: String, desc: String) -> HybridEvolution:
	var h := HybridEvolution.new()
	h.id = p_id
	h.path_a = a
	h.path_b = b
	h.display_name = name
	h.description = desc
	return h
