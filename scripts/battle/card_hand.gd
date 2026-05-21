class_name CardHand
extends HBoxContainer

signal hold_penalty_changed
signal card_selected(monster_id: StringName)

const MAX_CARDS := 7
const CARD_UI_SCRIPT := preload("res://scripts/battle/monster_card_ui.gd")

var _card_ids: Array[StringName] = []
var _selected_id: StringName = &""

@onready var _title: Label = $Title


func _ready() -> void:
	if _title:
		_title.text = "手牌 (拖拽部署 / 点击选中)"


func setup_initial_cards(count: int = 3) -> void:
	_card_ids.clear()
	_selected_id = &""
	for i in count:
		_add_card(DataRegistry.get_random_monster_id())
	_rebuild_ui()


func add_card(monster_id: StringName) -> bool:
	if monster_id == &"" or _card_ids.size() >= MAX_CARDS:
		return false
	_card_ids.append(monster_id)
	_rebuild_ui()
	return true


func consume_card(monster_id: StringName) -> void:
	_remove_card(monster_id)


func discard_card(monster_id: StringName) -> bool:
	if monster_id == &"" or _card_ids.find(monster_id) < 0:
		return false
	_remove_card(monster_id)
	return true


func get_selected_monster_id() -> StringName:
	return _selected_id if _selected_id in _card_ids else &""


func set_selected(monster_id: StringName) -> void:
	if monster_id not in _card_ids:
		return
	if _selected_id == monster_id:
		_selected_id = &""
	else:
		_selected_id = monster_id
	card_selected.emit(_selected_id)
	_rebuild_ui()


func get_hold_penalty_sum() -> CombatStats:
	var sum := CombatStats.zero_bonus()
	for monster_id in _card_ids:
		var data := DataRegistry.get_monster(monster_id)
		if data != null and data.hold_penalty != null:
			data.hold_penalty.merge_into(sum)
	return sum


func get_hold_bleed_per_sec() -> float:
	var total := 0.0
	for monster_id in _card_ids:
		var data := DataRegistry.get_monster(monster_id)
		if data != null:
			total += data.hold_bleed_per_sec
	return total


func format_hold_summary() -> String:
	var penalty := get_hold_penalty_sum()
	var bleed := get_hold_bleed_per_sec()
	var parts: PackedStringArray = []
	if penalty.attack != 0:
		parts.append("攻%+d" % penalty.attack)
	if penalty.defense != 0:
		parts.append("防%+d" % penalty.defense)
	if absf(penalty.attack_speed) > 0.001:
		parts.append("攻速%+.0f%%" % (penalty.attack_speed * 100.0))
	if bleed > 0.0:
		parts.append("失血%.1f/s" % bleed)
	if parts.is_empty():
		return "持仓：无"
	return "持仓：" + " ".join(parts)


static func format_card_hold_hint(data: MonsterData) -> String:
	if data == null:
		return ""
	var parts: PackedStringArray = []
	if data.hold_penalty != null:
		if data.hold_penalty.attack != 0:
			parts.append("攻%+d" % data.hold_penalty.attack)
		if data.hold_penalty.defense != 0:
			parts.append("防%+d" % data.hold_penalty.defense)
	if data.hold_bleed_per_sec > 0.0:
		parts.append("血%.1f/s" % data.hold_bleed_per_sec)
	if parts.is_empty():
		return ""
	return "拿着:" + " ".join(parts)


func _add_card(monster_id: StringName) -> void:
	if monster_id != &"":
		_card_ids.append(monster_id)


func _remove_card(monster_id: StringName) -> void:
	var index := _card_ids.find(monster_id)
	if index < 0:
		return
	_card_ids.remove_at(index)
	if _selected_id == monster_id:
		_selected_id = &""
	_rebuild_ui()


func _rebuild_ui() -> void:
	var to_remove: Array[Node] = []
	for child in get_children():
		if child != _title:
			to_remove.append(child)
	for child in to_remove:
		remove_child(child)
		child.queue_free()
	for monster_id in _card_ids:
		add_child(_create_card_slot(monster_id))
	hold_penalty_changed.emit()


func _create_card_slot(monster_id: StringName) -> MonsterCardUI:
	var data := DataRegistry.get_monster(monster_id)
	var panel: MonsterCardUI = CARD_UI_SCRIPT.new()
	panel.monster_id = monster_id
	panel.custom_minimum_size = Vector2(100, 88)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = data.wireframe_color.darkened(0.6) if data else WireframeTheme.PANEL
	var selected := monster_id == _selected_id
	style.border_color = WireframeTheme.ACCENT if selected else data.wireframe_color.darkened(0.2) if data else WireframeTheme.BORDER
	style.set_border_width_all(3 if selected else 2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.card_clicked.connect(_on_card_clicked)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var icon := TextureRect.new()
	var tex_path := "res://assets/monsters/%s.png" % str(monster_id)
	var tex := load(tex_path) as Texture2D
	if tex:
		icon.texture = tex
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2(36, 36)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon)
	var label := Label.new()
	label.text = data.display_name if data else str(monster_id)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(label)
	var hold_label := Label.new()
	hold_label.text = format_card_hold_hint(data)
	hold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hold_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hold_label.add_theme_color_override("font_color", Color(0.95, 0.55, 0.45))
	hold_label.add_theme_font_size_override("font_size", 9)
	vbox.add_child(hold_label)
	panel.add_child(vbox)
	return panel


func _on_card_clicked(monster_id: StringName) -> void:
	set_selected(monster_id)
