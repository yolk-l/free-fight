extends Control

@onready var _btn_start: Button = $Center/VBox/BtnStart
@onready var _btn_codex: Button = $Center/VBox/BtnCodex


func _ready() -> void:
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_codex.pressed.connect(_on_codex_pressed)


func _on_start_pressed() -> void:
	GameManager.go_to_battle()


func _on_codex_pressed() -> void:
	GameManager.go_to_codex()
