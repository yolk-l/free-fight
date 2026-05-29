class_name CardHand
extends HBoxContainer

const HAND_SIZE := GameConfig.HAND_SIZE
const CARD_UI_SCRIPT := preload("res://scripts/battle/monster_card_ui.gd")

const MECHANIC_SHORT := {
	&"slime":    "死亡分裂",
	&"bat":      "飞行",
	&"wolf":     "群族加攻",
	&"goblin":   "死亡爆炸",
	&"skeleton": "墓碑复活",
	&"gargoyle": "防御光环",
	&"viper":    "毒池",
}

var _candidates: Array[StringName] = []
var _candidates_elite: Array[bool] = []
var _next_candidates: Array[StringName] = []
var _next_elite: Array[bool] = []
var _draggable: bool = true
var _cd_remaining: float = 0.0
var _evolution_tracker = null
var _card_pool = null
var _next_preview = null

@onready var _title: Label = $Title


func _ready() -> void:
	if _title:
		_title.text = "候选"


func set_evolution_tracker(tracker) -> void:
	_evolution_tracker = tracker


func set_card_pool(pool) -> void:
	_card_pool = pool


func set_next_preview(node) -> void:
	_next_preview = node
	_update_next_preview_ui()


func deal_candidates() -> void:
	if _next_candidates.size() == HAND_SIZE:
		_candidates = _next_candidates.duplicate()
		_candidates_elite = _next_elite.duplicate()
		_next_candidates.clear()
		_next_elite.clear()
	else:
		_candidates.clear()
		_candidates_elite.clear()
		_fill_pool(_candidates, _candidates_elite, HAND_SIZE)
	_fill_pool(_next_candidates, _next_elite, HAND_SIZE)
	_draggable = true
	_cd_remaining = 0.0
	_rebuild_ui()
	_update_next_preview_ui()


func _fill_pool(ids: Array[StringName], elites: Array[bool], count: int) -> void:
	if _card_pool == null:
		return
	var attempts := 0
	while ids.size() < count and attempts < 50:
		attempts += 1
		var mid: StringName = _card_pool.pick_random()
		if mid == &"":
			continue
		if mid in ids:
			continue
		ids.append(mid)
		elites.append(randf() < GameConfig.ELITE_CHANCE)


func consume_card(monster_id: StringName) -> bool:
	var index := _candidates.find(monster_id)
	if index < 0:
		return false
	_candidates.clear()
	_candidates_elite.clear()
	_draggable = false
	_cd_remaining = GameConfig.DEPLOY_COOLDOWN_SEC
	_rebuild_ui()
	return true


func is_consumed_elite(monster_id: StringName) -> bool:
	var index := _candidates.find(monster_id)
	if index < 0:
		return false
	return _candidates_elite[index]


func tick(delta: float) -> void:
	if _cd_remaining <= 0.0:
		return
	_cd_remaining = maxf(0.0, _cd_remaining - delta)
	_refresh_cd_label()
	if _cd_remaining <= 0.0:
		deal_candidates()


func refresh_displays() -> void:
	_rebuild_ui()
	_update_next_preview_ui()


func _refresh_cd_label() -> void:
	if _title == null:
		return
	if _cd_remaining > 0.0:
		_title.text = "候选刷新中 %.1fs" % _cd_remaining
	elif _candidates.is_empty():
		_title.text = "候选"
	else:
		_title.text = "候选 (拖拽部署)"


func _rebuild_ui() -> void:
	var to_remove: Array[Node] = []
	for child in get_children():
		if child != _title:
			to_remove.append(child)
	for child in to_remove:
		remove_child(child)
		child.queue_free()
	for i in _candidates.size():
		var is_elite: bool = _candidates_elite[i] if i < _candidates_elite.size() else false
		add_child(_create_card_slot(_candidates[i], is_elite))
	_refresh_cd_label()


func _update_next_preview_ui() -> void:
	if _next_preview and _next_preview.has_method("set_cards"):
		_next_preview.set_cards(_next_candidates, _next_elite)


func _create_card_slot(monster_id: StringName, is_elite: bool) -> MonsterCardUI:
	var data := DataRegistry.get_monster(monster_id)
	var panel: MonsterCardUI = CARD_UI_SCRIPT.new()
	panel.monster_id = monster_id
	panel.draggable = _draggable
	panel.custom_minimum_size = Vector2(140, 120)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = data.wireframe_color.darkened(0.6) if data else Color(0.12, 0.14, 0.2)
	if is_elite:
		style.border_color = Color(1.0, 0.85, 0.2)
		style.set_border_width_all(3)
	else:
		style.border_color = data.wireframe_color.darkened(0.2) if data else Color(0.3, 0.35, 0.5)
		style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	var tex_path := "res://assets/monsters/%s.png" % str(monster_id)
	var tex := load(tex_path) as Texture2D
	if tex:
		icon.texture = tex
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(40, 40)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)
	var name_text: String = (data.display_name if data else str(monster_id))
	if is_elite:
		name_text = "★ " + name_text
	var label := Label.new()
	label.text = name_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_elite else Color(0.9, 0.9, 0.95))
	label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(label)
	var mech_label := Label.new()
	mech_label.text = MECHANIC_SHORT.get(monster_id, "")
	mech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mech_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mech_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.95))
	mech_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(mech_label)
	var res_label := Label.new()
	res_label.text = _resonance_text(monster_id)
	res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	res_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	res_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(res_label)
	panel.add_child(vbox)
	panel.setup_overlay()
	return panel


func _resonance_text(monster_id: StringName) -> String:
	if _evolution_tracker == null:
		return ""
	var progress = _evolution_tracker.get_progress_for_monster(monster_id)
	if progress == null:
		return ""
	var tier: int = progress["tier"]
	var count: int = progress["count"]
	var next_threshold: int = progress["next_threshold"]
	if tier >= 3 or next_threshold <= 0:
		return "共鸣 MAX"
	return "共鸣 %d/%d" % [count, next_threshold]
