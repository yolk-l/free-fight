class_name CardHand
extends HBoxContainer

const HAND_SIZE := GameConfig.HAND_SIZE
const SLOT_CD := GameConfig.SLOT_COOLDOWN_SEC
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

var _slots: Array[Dictionary] = []
var _slot_uis: Array[MonsterCardUI] = []
var _evolution_tracker = null
var _card_pool = null

@onready var _title: Label = $Title


func _ready() -> void:
	if _title:
		_title.text = "候选"


func set_evolution_tracker(tracker) -> void:
	_evolution_tracker = tracker


func set_card_pool(pool) -> void:
	_card_pool = pool


func set_next_preview(_node) -> void:
	pass


func init_slots() -> void:
	_slots.clear()
	var used: Array[StringName] = []
	for i in HAND_SIZE:
		var mid := _pick_random_card(used)
		var is_elite := randf() < GameConfig.ELITE_CHANCE
		_slots.append({"monster_id": mid, "is_elite": is_elite, "cd": 0.0})
		used.append(mid)
	_rebuild_ui()


# Keep backward compat name for BattleController
func deal_candidates() -> void:
	init_slots()


func consume_card(monster_id: StringName) -> bool:
	for i in _slots.size():
		if _slots[i]["monster_id"] == monster_id and _slots[i]["cd"] <= 0.0:
			_slots[i]["cd"] = SLOT_CD
			_update_slot_ui(i)
			_refresh_title()
			return true
	return false


func is_consumed_elite(monster_id: StringName) -> bool:
	for slot in _slots:
		if slot["monster_id"] == monster_id and slot["cd"] <= 0.0:
			return slot["is_elite"]
	return false


func tick(delta: float) -> void:
	var any_refreshed := false
	for i in _slots.size():
		if _slots[i]["cd"] <= 0.0:
			continue
		_slots[i]["cd"] = maxf(0.0, _slots[i]["cd"] - delta)
		if _slots[i]["cd"] <= 0.0:
			_refill_slot(i)
			any_refreshed = true
		_update_slot_ui(i)
	if any_refreshed:
		_refresh_title()


func refresh_displays() -> void:
	_rebuild_ui()


func _refill_slot(index: int) -> void:
	var used: Array[StringName] = []
	for i in _slots.size():
		if i != index and _slots[i]["cd"] <= 0.0:
			used.append(_slots[i]["monster_id"])
	var mid := _pick_random_card(used)
	_slots[index]["monster_id"] = mid
	_slots[index]["is_elite"] = randf() < GameConfig.ELITE_CHANCE
	_slots[index]["cd"] = 0.0


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


func _refresh_title() -> void:
	if _title == null:
		return
	var available := 0
	for slot in _slots:
		if slot["cd"] <= 0.0:
			available += 1
	if available == 0:
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
	for i in _slots.size():
		var card := _create_card_slot(i)
		add_child(card)
		_slot_uis.append(card)
	_refresh_title()


func _update_slot_ui(index: int) -> void:
	if index < 0 or index >= _slot_uis.size():
		return
	var ui := _slot_uis[index]
	if not is_instance_valid(ui):
		return
	var slot := _slots[index]
	var cd: float = slot["cd"]
	if cd <= 0.0:
		ui.monster_id = slot["monster_id"]
		ui.update_cd(0.0)
		_refresh_card_content(ui, index)
	else:
		ui.update_cd(cd)


func _refresh_card_content(ui: MonsterCardUI, index: int) -> void:
	var old_children: Array[Node] = []
	for child in ui.get_children():
		if child != ui._disabled_overlay and child != ui._cd_label:
			old_children.append(child)
	for child in old_children:
		ui.remove_child(child)
		child.queue_free()

	var slot := _slots[index]
	var monster_id: StringName = slot["monster_id"]
	var is_elite: bool = slot["is_elite"]
	var data := DataRegistry.get_monster(monster_id)

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
	ui.add_theme_stylebox_override("panel", style)

	ui.monster_id = monster_id

	var vbox := _build_card_vbox(monster_id, is_elite)
	ui.add_child(vbox)
	ui.move_child(vbox, 0)
	ui.setup_overlay()


func _create_card_slot(index: int) -> MonsterCardUI:
	var slot := _slots[index]
	var monster_id: StringName = slot["monster_id"]
	var is_elite: bool = slot["is_elite"]
	var cd: float = slot["cd"]
	var data := DataRegistry.get_monster(monster_id)

	var panel: MonsterCardUI = CARD_UI_SCRIPT.new()
	panel.monster_id = monster_id
	panel.draggable = cd <= 0.0
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
	if cd > 0.0:
		panel.update_cd(cd)
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

	var res_label := Label.new()
	res_label.text = _resonance_text(monster_id)
	res_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	res_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	res_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6))
	res_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(res_label)

	return vbox


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
