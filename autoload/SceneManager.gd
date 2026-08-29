extends Node

var _params: Dictionary = {}
var transition_data: Dictionary = {}

func go_to_scene(path: String, params: Dictionary = {}) -> void:
	_params = params
	call_deferred("_change_scene", path)

func _change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func get_params() -> Dictionary:
	var p = _params.duplicate()
	_params = {}
	return p
