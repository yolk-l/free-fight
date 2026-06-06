class_name CardHand
extends HBoxContainer

const HAND_SIZE := GameConfig.HAND_SIZE
const DEPLOY_CD := GameConfig.DEPLOY_COOLDOWN_SEC
const CARD_UI_SCRIPT := preload("res://scripts/battle/monster_card_ui.gd")

const MECHANIC_SHORT := {
	&"slime":    "死亡分裂",
	&"bat":      "飞行",
	&"wolf":     "群族加攻",
	&"goblin":   "死亡爆炸",
	&"skeleton": "墓碑复活",
	&"gargoyle": "防御光环",
	&"viper":    "毒池",
	&"mantis":   "死亡反噬",
	&"treant":   "死亡化泉",
	&"firefly":  "死亡赋能",
}

var _current_slots: Array[Dictionary] = []
var _next_slots: Array[Dictionary] = []
var _slot_uis: Array[MonsterCardUI] = []
var _global_cd: float = 0.0
var _evolution_tracker = null
var _card_pool = null
var _next_preview_node: NextHandPreview = null

@onready var _title: Label = $Title


func _ready() -> void:
	if _title:
		_title.text = "候选"


func set_evolution_tracker(tracker) -> void:
	_evolution_tracker = tracker


func set_card_pool(pool) -> void:
	_card_pool = pool


func set_next_preview(node) -> void:
	_next_preview_node = node


func deal_candidates() -> void:
	_current_slots = _generate_hand()
	_next_slots = _generate_hand()
	_global_cd = 0.0
	_rebuild_ui()
	_update_next_preview()


func consume_card(monster_id: StringName) -> bool:
	if _global_cd > 0.0:
		return false
	var found := false
	for slot in _current_slots:
		if slot["monster_id"] == monster_id:
			found = true
			break
	if not found:
		return false
	_global_cd = DEPLOY_CD
	_set_all_disabled(true)
	return true


func is_consumed_elite(monster_id: StringName) -> bool:
	for slot in _current_slots:
		if slot["monster_id"] == monster_id:
			return slot["is_elite"]
	return false


func tick(delta: float) -> void:
	if _global_cd <= 0.0:
		return
	_global_cd = maxf(0.0, _global_cd - delta)
	if _global_cd <= 0.0:
		_current_slots = _next_slots.duplicate(true)
		_next_slots = _generate_hand()
		_rebuild_ui()
		_update_next_preview()
	else:
		_update_cd_display()


func refresh_displays() -> void:
	_rebuild_ui()


func _generate_hand() -> Array[Dictionary]:
	var hand: Array[Dictionary] = []
	var used: Array[StringName] = []
	for i in HAND_SIZE:
		var mid := _pick_random_card(used)
		var is_elite := randf() < GameConfig.ELITE_CHANCE
		hand.append({"monster_id": mid, "is_elite": is_elite})
		used.append(mid)
	return hand


func _pick_random_card(exclude: Array[StringName]) -> StringName:
	if _card_pool == null:
		return &""
	var attempts := 0
	while attempts < 50:
		attempts += 1
		var mid: StringName = _card_pool.pick_random()
		if mid == &"":
			continue
		if mid in exclude:
			continue
		return mid
	if _card_pool:
		return _card_pool.pick_random()
	return &""


func _set_all_disabled(disabled: bool) -> void:
	for ui in _slot_uis:
		if is_instance_valid(ui):
			if disabled:
				ui.update_cd(_global_cd)
			else:
				ui.update_cd(0.0)


func _update_cd_display() -> void:
	for ui in _slot_uis:
		if is_instance_valid(ui):
			ui.update_cd(_global_cd)


func _update_next_preview() -> void:
	if _next_preview_node == null:
		return
	var ids: Array = []
	var elites: Array = []
	for slot in _next_slots:
		ids.append(slot["monster_id"])
		elites.append(slot["is_elite"])
	_next_preview_node.set_cards(ids, elites)


func _refresh_title() -> void:
	if _title == null:
		return
	if _global_cd > 0.0:
		_title.text = "冷却中..."
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
	_slot_uis.clear()
	for i in _current_slots.size():
		var card := _create_card_slot(i)
		add_child(card)
		_slot_uis.append(card)
	_refresh_title()


func _create_card_slot(index: int) -> MonsterCardUI:
	var slot := _current_slots[index]
	var monster_id: StringName = slot["monster_id"]
	var is_elite: bool = slot["is_elite"]
	var data := DataRegistry.get_monster(monster_id)

	var panel: MonsterCardUI = CARD_UI_SCRIPT.new()
	panel.monster_id = monster_id
	panel.draggable = _global_cd <= 0.0
	panel.custom_minimum_size = Vector2(130, 120)
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

	var vbox := _build_card_vbox(monster_id, is_elite)
	panel.add_child(vbox)
	panel.setup_overlay()
	if _global_cd > 0.0:
		panel.update_cd(_global_cd)
	return panel


func _build_card_vbox(monster_id: StringName, is_elite: bool) -> VBoxContainer:
	var data := DataRegistry.get_monster(monster_id)
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

	var aff: int = TileEffectSystem.get_monster_affinity(monster_id)
	if aff >= 0:
		var aff_label := Label.new()
		aff_label.text = "[%s]" % DungeonTileType.AFFINITY_DISPLAY.get(aff, "")
		aff_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		aff_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		aff_label.add_theme_color_override("font_color", DungeonTileType.AFFINITY_COLOR.get(aff, Color(0.5, 0.5, 0.5)))
		aff_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(aff_label)

	var res_label := Label.new()
	res_label.text = _resonance_text(monster_id)
	res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	res_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	res_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(res_label)

	var next_passive := _next_passive_text(monster_id)
	if not next_passive.is_empty():
		var passive_label := Label.new()
		passive_label.text = next_passive
		passive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		passive_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		passive_label.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0, 0.8))
		passive_label.add_theme_font_size_override("font_size", 9)
		vbox.add_child(passive_label)

	return vbox


func _next_passive_text(monster_id: StringName) -> String:
	if _evolution_tracker == null:
		return ""
	var progress = _evolution_tracker.get_progress_for_monster(monster_id)
	if progress == null:
		return ""
	if progress["tier"] >= 3 or progress["next_threshold"] <= 0:
		return ""
	for p in _evolution_tracker.get_all_progress():
		if p["monster_type"] == monster_id and not p["next_name"].is_empty():
			return "下阶: %s" % p["next_name"]
	return ""


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
