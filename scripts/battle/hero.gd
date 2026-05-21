class_name Hero
extends CombatUnit

@onready var inventory: EquipmentInventory = $EquipmentInventory

var _battle_controller: Node = null


func _ready() -> void:
	super._ready()
	if inventory:
		inventory.equipment_changed.connect(_on_equipment_changed)
	display_label = "英雄"
	set_physics_process(false)


func setup_hero(stats: CombatStats, controller: Node) -> void:
	_battle_controller = controller
	setup_stats(stats, "英雄")


func get_combat_stats() -> CombatStats:
	if base_stats == null:
		return CombatStats.new()
	var stats := base_stats.duplicate_stats()
	if inventory:
		stats = stats.apply_bonus(inventory.get_stat_bonus())
	var hand: CardHand = _get_card_hand()
	if hand:
		stats = stats.apply_penalty(hand.get_hold_penalty_sum())
	stats.hp = base_stats.hp
	stats.max_hp = maxi(stats.max_hp, base_stats.max_hp)
	return stats


func _get_card_hand() -> CardHand:
	if _battle_controller == null:
		return null
	return _battle_controller.card_hand as CardHand


func refresh_display() -> void:
	stats_changed.emit()
	_refresh_ui()


func _refresh_ui() -> void:
	if _name_label:
		_name_label.text = display_label
	if _stat_bar:
		_stat_bar.update_stats(get_combat_stats())


func acquire_target() -> CombatUnit:
	if _battle_controller == null:
		return null
	return _battle_controller.get_nearest_monster_to(global_position)


func tick_combat(delta: float) -> void:
	if is_alive():
		try_attack(delta)


func _on_equipment_changed() -> void:
	if base_stats == null:
		return
	var effective := get_combat_stats()
	base_stats.hp = mini(base_stats.hp, effective.max_hp)
	refresh_display()
