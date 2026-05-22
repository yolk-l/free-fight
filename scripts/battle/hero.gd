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
	attack_range = GameConfig.HERO_ATTACK_RANGE
	projectile_speed = GameConfig.HERO_PROJECTILE_SPEED
	_projectile_container = controller.get_projectile_container()
	setup_stats(stats, "英雄")


func get_combat_stats() -> CombatStats:
	if base_stats == null:
		return CombatStats.new()
	var stats := base_stats.duplicate_stats()
	if inventory:
		stats = stats.apply_bonus(inventory.get_stat_bonus())
	if buff_container:
		var mods := buff_container.get_all_modifiers()
		for key in mods.keys():
			match key:
				"attack":
					stats.attack += int(mods[key])
				"defense":
					stats.defense += int(mods[key])
				"attack_speed":
					stats.attack_speed += mods[key]
		stats.attack = maxi(GameConfig.MIN_ATTACK, stats.attack)
		stats.defense = maxi(GameConfig.MIN_DEFENSE, stats.defense)
		stats.attack_speed = maxf(GameConfig.MIN_ATTACK_SPEED, stats.attack_speed)
	stats.hp = base_stats.hp
	stats.max_hp = maxi(stats.max_hp, base_stats.max_hp)
	return stats


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
