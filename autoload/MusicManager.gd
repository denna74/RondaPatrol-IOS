extends Node

signal bgm_changed

const MAX_LEVEL := 4

var bgm_level: int = MAX_LEVEL

var _player: AudioStreamPlayer
var _menu_music: AudioStream
var _gameplay_music: AudioStream

func _ready() -> void:
	load_bgm_setting()
	_apply_bgm_level()
	_menu_music = load("res://assets/bgm/Staccato_Specter.mp3")
	_gameplay_music = load("res://assets/bgm/Bamboo_Mischief.mp3")
	_menu_music.loop = true
	_gameplay_music.loop = true
	_player = AudioStreamPlayer.new()
	_player.bus = &"Music"
	_player.process_mode = PROCESS_MODE_WHEN_PAUSED
	add_child(_player)


func _apply_bgm_level() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, bgm_level <= 0)
	AudioServer.set_bus_volume_db(idx, linear_to_db(float(bgm_level) / float(MAX_LEVEL)))


func load_bgm_setting() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		if config.has_section_key("settings", "bgm_level"):
			bgm_level = clampi(config.get_value("settings", "bgm_level", MAX_LEVEL), 0, MAX_LEVEL)
		else:
			var legacy_enabled: bool = config.get_value("settings", "bgm_enabled", true)
			bgm_level = MAX_LEVEL if legacy_enabled else 0

func save_bgm_setting() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	config.set_value("settings", "bgm_level", bgm_level)
	config.save("user://settings.cfg")

func set_bgm_level(level: int) -> void:
	level = clampi(level, 0, MAX_LEVEL)
	if bgm_level == level:
		return
	bgm_level = level
	_apply_bgm_level()
	save_bgm_setting()
	if bgm_level > 0:
		if _player.stream and not _player.playing:
			_player.play()
	else:
		_player.stop()
	bgm_changed.emit()

func play_menu_music() -> void:
	if bgm_level <= 0:
		_player.stop()
		return
	if _player.stream == _menu_music and _player.playing:
		return
	_player.stop()
	_player.stream = _menu_music
	_player.play()

func play_gameplay_music() -> void:
	if bgm_level <= 0:
		_player.stop()
		return
	if _player.stream == _gameplay_music and _player.playing:
		return
	_player.stop()
	_player.stream = _gameplay_music
	_player.play()

func stop_music() -> void:
	_player.stop()

func has_menu_music() -> bool:
	return _player.stream == _menu_music and _player.playing
