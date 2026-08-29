extends Node

func _ready() -> void:
	call_deferred("_start_game")

func _start_game() -> void:
	SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")
