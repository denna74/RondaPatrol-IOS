extends Node

const MAX_LEVEL := 4

var sfx_level: int = MAX_LEVEL

var _player: AudioStreamPlayer


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.stream = preload("res://assets/sfx/click.wav")
	_player.bus = &"SFX"
	add_child(_player)
	load_sfx_setting()
	_apply_sfx_level()


func _apply_sfx_level() -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, sfx_level <= 0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(float(sfx_level) / float(MAX_LEVEL)))


func load_sfx_setting() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		sfx_level = clampi(config.get_value("settings", "sfx_level", MAX_LEVEL), 0, MAX_LEVEL)


func save_sfx_setting() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("settings", "sfx_level", sfx_level)
	config.save("user://settings.cfg")


func set_sfx_level(level: int) -> void:
	level = clampi(level, 0, MAX_LEVEL)
	if sfx_level == level:
		return
	sfx_level = level
	_apply_sfx_level()
	save_sfx_setting()


func play() -> void:
	_player.play()
