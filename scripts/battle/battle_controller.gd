extends Node2D

const HERO_DEFAULT_STATS := preload("res://resources/hero_default.tres")
const DEFAULT_LOOT_TABLE := preload("res://resources/loot_table_default.tres")
const DEFAULT_CARD_POOL := preload("res://resources/card_pool_default.tres")

var card_hand: CardHand
var _hero: Hero
var _monsters: Array[Monster] = []
var _game_over: bool = false
var _card_dealer: CardDealer

@onready var _hero_node: Hero = $Units/Hero
@onready var _monster_container: Node2D = $Units/Monsters
@onready var _projectile_container: Node2D = $Units/Projectiles
@onready var _card_hand_node: CardHand = $UI/BottomPanel/CardHand
@onready var _deploy_manager: DeployManager = $DeployManager
@onready var _loot_system: LootSystem = $LootSystem
@onready var _equipment_bar: Control = $UI/BottomPanel/EquipmentBar
@onready var _backpack_panel: HBoxContainer = $UI/BottomPanel/BackpackPanel
@onready var _game_over_panel: PanelContainer = $UI/GameOverPanel
@onready var _survival_label: Label = $UI/TopBar/SurvivalLabel
@onready var _top_label: Label = $UI/TopBar/TopLabel
@onready var _hold_summary: Label = $UI/BottomPanel/HoldSummary
@onready var _discard_btn: Button = $UI/BottomPanel/DiscardRow/BtnDiscard
@onready var _discard_cooldown_label: Label = $UI/BottomPanel/DiscardRow/DiscardCooldown
@onready var _drop_zone: BattlefieldDropZone = $UI/BattlefieldDropZone
@onready var _item_tooltip: PanelContainer = $UI/ItemTooltip
@onready var _tooltip_label: Label = $UI/ItemTooltip/TooltipLabel

var _backpack
var _survival_time: float = 0.0
var _discard_cooldown: float = 0.0
var _bleed_tick: float = 0.0


func _ready() -> void:
	card_hand = _card_hand_node
	_hero = _hero_node
	_game_over_panel.visible = false
	_discard_cooldown = 0.0
	_style_game_over_panel()
	_setup_hero()
	_deploy_manager.setup(_hero, _monster_container, self)
	_backpack = EquipmentBackpack.new()
	_backpack.name = "EquipmentBackpack"
	add_child(_backpack)
	_backpack.backpack_changed.connect(_refresh_backpack_ui)
	_loot_system.setup(_backpack, DEFAULT_LOOT_TABLE)
	_card_dealer = CardDealer.new()
	_card_dealer.name = "CardDealer"
	add_child(_card_dealer)
	_card_dealer.setup(_card_hand_node, DEFAULT_CARD_POOL)
	_card_hand_node.set_buff_target(_hero.buff_container)
	_card_hand_node.setup_initial_cards(3)
	_card_hand_node.hold_penalty_changed.connect(_on_hold_penalty_changed)
	if _hero.buff_container:
		_hero.buff_container.buffs_changed.connect(_on_hold_penalty_changed)
	_drop_zone.card_dropped.connect(_on_card_dropped)
	_hero.died.connect(_on_hero_died)
	_discard_btn.pressed.connect(_on_discard_pressed)
	var restart_btn: Button = _game_over_panel.get_node_or_null("VBox/BtnRestart")
	var menu_btn: Button = _game_over_panel.get_node_or_null("VBox/BtnMenu")
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu_pressed)
	if _hero.inventory:
		_hero.inventory.equipment_changed.connect(_refresh_equipment_bar)
	if _top_label:
		_top_label.text = "拖拽部署怪物；留牌会降低英雄能力（点击选手牌后可弃牌）"
	_refresh_equipment_bar()
	_setup_backpack_ui()
	_refresh_backpack_ui()
	_refresh_hold_ui()
	_refresh_discard_ui()


func _physics_process(delta: float) -> void:
	if _game_over:
		return
	_survival_time += delta
	if _survival_label:
		_survival_label.text = "存活: %ds" % int(_survival_time)
	_tick_discard_cooldown(delta)
	_tick_hold_bleed(delta)
	if _card_dealer:
		_card_dealer.tick(delta)
	if _hero.buff_container:
		_hero.buff_container.tick(delta)
	if is_instance_valid(_hero) and _hero.is_alive():
		_hero.tick_combat(delta)
	for monster in _monsters:
		if is_instance_valid(monster) and monster.is_alive():
			monster.tick_combat(delta)


func register_monster(monster: Monster) -> void:
	_monsters.append(monster)
	monster.died.connect(_on_monster_died.bind(monster))


func get_projectile_container() -> Node2D:
	return _projectile_container


func get_nearest_monster_to(pos: Vector2) -> CombatUnit:
	var nearest: Monster = null
	var best_dist := INF
	for monster in _monsters:
		if not is_instance_valid(monster) or not monster.is_alive():
			continue
		var d := pos.distance_to(monster.global_position)
		if d < best_dist:
			best_dist = d
			nearest = monster
	return nearest


func _tick_discard_cooldown(delta: float) -> void:
	if _discard_cooldown > 0.0:
		_discard_cooldown = maxf(0.0, _discard_cooldown - delta)
	_refresh_discard_ui()


func _tick_hold_bleed(delta: float) -> void:
	if not is_instance_valid(_hero) or not _hero.is_alive():
		return
	if _hero.buff_container == null:
		return
	var bleed := _hero.buff_container.get_bleed_per_sec()
	if bleed <= 0.0:
		return
	_bleed_tick += delta
	while _bleed_tick >= 1.0:
		_bleed_tick -= 1.0
		var damage := maxi(1, int(ceil(bleed)))
		_hero.take_damage(damage)


func _on_hold_penalty_changed() -> void:
	_refresh_hold_ui()
	if is_instance_valid(_hero):
		_hero.refresh_display()


func _refresh_hold_ui() -> void:
	if _hold_summary:
		_hold_summary.text = _card_hand_node.format_hold_summary()


func _refresh_discard_ui() -> void:
	var ready := _discard_cooldown <= 0.0
	if _discard_btn:
		_discard_btn.disabled = not ready
	if _discard_cooldown_label:
		if ready:
			_discard_cooldown_label.text = "弃牌就绪"
		else:
			_discard_cooldown_label.text = "弃牌 %.1fs" % _discard_cooldown


func _on_discard_pressed() -> void:
	if _discard_cooldown > 0.0 or _game_over:
		return
	var monster_id := _card_hand_node.get_selected_monster_id()
	if monster_id == &"":
		return
	if _card_hand_node.discard_card(monster_id):
		_discard_cooldown = GameConfig.DISCARD_COOLDOWN_SEC
		_refresh_discard_ui()


func _style_game_over_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_color = Color(0.9, 0.25, 0.2, 0.8)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 8
	_game_over_panel.add_theme_stylebox_override("panel", style)


func _setup_hero() -> void:
	var stats: CombatStats
	if HERO_DEFAULT_STATS:
		stats = HERO_DEFAULT_STATS.duplicate_stats()
	else:
		stats = CombatStats.new()
		stats.attack = 10
		stats.max_hp = 120
		stats.hp = 120
		stats.defense = 2
		stats.attack_speed = 1.0
	_hero.setup_hero(stats, self)


func _on_card_dropped(monster_id: StringName, drop_position: Vector2) -> void:
	if _game_over:
		return
	_deploy_manager.deploy_monster_at(monster_id, drop_position)
	_card_hand_node.consume_card(monster_id)


func _on_monster_died(_unit: CombatUnit, monster: Monster) -> void:
	_loot_system.on_monster_died(monster)
	_monsters.erase(monster)


func _on_hero_died(_unit: CombatUnit) -> void:
	if _game_over:
		return
	_game_over = true
	_game_over_panel.visible = true
	_stop_monster_activity()
	set_physics_process(false)


func _stop_monster_activity() -> void:
	for monster in _monsters:
		if is_instance_valid(monster):
			monster.set_physics_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and _game_over:
		_on_restart_pressed()


func _refresh_equipment_bar() -> void:
	if _equipment_bar == null or _hero == null or _hero.inventory == null:
		return
	var weapon = _hero.inventory.get_slot_item(&"weapon")
	var armor = _hero.inventory.get_slot_item(&"armor")
	_update_equip_slot("WeaponSlot", weapon)
	_update_equip_slot("ArmorSlot", armor)


func _update_equip_slot(slot_name: String, item) -> void:
	var slot_panel: PanelContainer = _equipment_bar.get_node_or_null(slot_name)
	if slot_panel == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.2, 0.8) if item == null else Color(0.15, 0.2, 0.3, 0.9)
	style.border_color = Color(0.3, 0.35, 0.5) if item == null else WireframeTheme.ACCENT.darkened(0.3)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(6)
	slot_panel.add_theme_stylebox_override("panel", style)
	slot_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	if not slot_panel.mouse_entered.is_connected(_on_equip_slot_hover):
		slot_panel.mouse_entered.connect(_on_equip_slot_hover.bind(slot_name))
		slot_panel.mouse_exited.connect(_hide_item_tooltip)
	var label: Label = slot_panel.get_node_or_null("HBox/VBox/Label")
	if label:
		if item:
			label.text = item.get_display_name()
			label.add_theme_color_override("font_color", item.get_quality_color())
		else:
			label.text = "[空]"
			label.remove_theme_color_override("font_color")
	var icon: TextureRect = slot_panel.get_node_or_null("HBox/Icon")
	if icon:
		if item and item.base_data:
			var tex_path := "res://assets/equipment/%s.png" % str(item.base_data.id)
			var tex := load(tex_path) as Texture2D
			icon.texture = tex
		else:
			icon.texture = null


func _setup_backpack_ui() -> void:
	if _backpack_panel == null:
		return
	for i in range(EquipmentBackpack.MAX_SLOTS):
		var btn: Button = _backpack_panel.get_node_or_null("Slot%d" % i)
		if btn:
			btn.pressed.connect(_on_backpack_slot_clicked.bind(i))
			btn.mouse_entered.connect(_on_backpack_slot_hover.bind(i))
			btn.mouse_exited.connect(_hide_item_tooltip)


func _refresh_backpack_ui() -> void:
	if _backpack_panel == null or _backpack == null:
		return
	for i in range(EquipmentBackpack.MAX_SLOTS):
		var btn: Button = _backpack_panel.get_node_or_null("Slot%d" % i)
		if btn == null:
			continue
		var item = _backpack.get_item(i)
		if item:
			btn.text = item.get_display_name()
			btn.tooltip_text = item.get_tooltip()
			btn.add_theme_color_override("font_color", item.get_quality_color())
		else:
			btn.text = ""
			btn.tooltip_text = ""
			btn.remove_theme_color_override("font_color")


func _on_backpack_slot_hover(index: int) -> void:
	if _backpack == null or _item_tooltip == null:
		return
	var item = _backpack.get_item(index)
	if item:
		_tooltip_label.text = item.get_tooltip()
		_item_tooltip.visible = true
		var btn: Button = _backpack_panel.get_node_or_null("Slot%d" % index)
		if btn:
			_item_tooltip.global_position = Vector2(btn.global_position.x, btn.global_position.y - _item_tooltip.size.y - 4)
	else:
		_item_tooltip.visible = false


func _hide_item_tooltip() -> void:
	if _item_tooltip:
		_item_tooltip.visible = false


func _on_equip_slot_hover(slot_name: String) -> void:
	if _hero == null or _hero.inventory == null or _item_tooltip == null:
		return
	var key = &"weapon" if slot_name == "WeaponSlot" else &"armor"
	var item = _hero.inventory.get_slot_item(key)
	if item:
		_tooltip_label.text = item.get_tooltip()
		_item_tooltip.visible = true
		var slot_panel = _equipment_bar.get_node_or_null(slot_name)
		if slot_panel:
			_item_tooltip.global_position = Vector2(slot_panel.global_position.x, slot_panel.global_position.y - _item_tooltip.size.y - 4)
	else:
		_item_tooltip.visible = false


func _on_backpack_slot_clicked(index: int) -> void:
	if _game_over or _backpack == null or _hero == null:
		return
	var item = _backpack.remove_item(index)
	if item and _hero.inventory:
		_hero.inventory.equip(item)


func _on_restart_pressed() -> void:
	GameManager.go_to_battle()


func _on_menu_pressed() -> void:
	GameManager.go_to_main_menu()
