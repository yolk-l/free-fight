# 持续性范围效果类型 — temporary area effects from evolution passives.
# Distinct from MapTerrainType which defines permanent map terrain.
class_name TerrainType
extends Object

enum Kind {
	RESONANCE_ALTAR,  # 在此死亡的怪 +100% 共鸣进度
	THORNS,           # 进入的怪每秒受 2 真伤
	SANCTUARY,        # 怪首次进入时眩晕 1.5s
	SHADOW,           # 此格内的怪 +50% 移速 +30% 攻
	RESONANCE_NODE,   # 在此死亡触发半径 80px 5 伤爆炸
	POISON_LAND,      # 在此死亡留毒池（半径 60px, 5s, 2 伤/s）
}


static func get_display_name(kind: int) -> String:
	match kind:
		Kind.RESONANCE_ALTAR: return "共鸣祭坛"
		Kind.THORNS: return "荆棘地"
		Kind.SANCTUARY: return "圣光圈"
		Kind.SHADOW: return "暗影域"
		Kind.RESONANCE_NODE: return "共鸣节点"
		Kind.POISON_LAND: return "腐毒地"
		_: return ""


static func get_color(kind: int) -> Color:
	match kind:
		Kind.RESONANCE_ALTAR: return Color(0.6, 0.3, 0.9, 0.35)
		Kind.THORNS: return Color(0.55, 0.4, 0.25, 0.35)
		Kind.SANCTUARY: return Color(1.0, 0.9, 0.5, 0.35)
		Kind.SHADOW: return Color(0.35, 0.2, 0.45, 0.45)
		Kind.RESONANCE_NODE: return Color(0.3, 0.6, 1.0, 0.35)
		Kind.POISON_LAND: return Color(0.3, 0.85, 0.3, 0.35)
		_: return Color(0.5, 0.5, 0.5, 0.3)


static func get_all_kinds() -> Array:
	return [
		Kind.RESONANCE_ALTAR,
		Kind.THORNS,
		Kind.SANCTUARY,
		Kind.SHADOW,
		Kind.RESONANCE_NODE,
		Kind.POISON_LAND,
	]
