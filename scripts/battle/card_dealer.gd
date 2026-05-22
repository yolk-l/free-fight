class_name CardDealer
extends Node

var _card_hand: CardHand
var _card_pool: CardPool
var _timer: float = 0.0


func setup(card_hand: CardHand, pool: CardPool) -> void:
	_card_hand = card_hand
	_card_pool = pool
	_timer = GameConfig.CARD_DEAL_INTERVAL_SEC


func tick(delta: float) -> void:
	if _card_hand == null or _card_pool == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += GameConfig.CARD_DEAL_INTERVAL_SEC
		_deal_card()


func _deal_card() -> void:
	var monster_id := _card_pool.pick_random()
	if monster_id != &"":
		_card_hand.add_card(monster_id)
