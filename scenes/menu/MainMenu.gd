extends Control

@onready var story_btn := $BottomGroup/ButtonRow/StoryButton as TextureButton
@onready var play_btn := $BottomGroup/ButtonRow/PlayButton as TextureButton
@onready var settings_btn := $BottomGroup/SettingsRow/SettingsButton as TextureButton
@onready var how_to_play := $BottomGroup/HowToPlay

const BG_TEX := preload("res://assets/buttons/empty_short.png")
const SETTINGS_BG_TEX := preload("res://assets/buttons/empty_long.png")
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")
const SettingsPopupScene := preload("res://scenes/menu/SettingsPopup.tscn")
const BUTTON_SIZE := Vector2(157, 64)
const SETTINGS_BTN_SIZE := Vector2(250, 64)
const FONT_PURPLE := "res://assets/fonts/purple/"

var _settings_popup: Control

func _ready() -> void:
	MusicManager.play_menu_music()
	settings_btn.custom_minimum_size = SETTINGS_BTN_SIZE
	story_btn.pressed.connect(_on_story_pressed)
	story_btn.pressed.connect(ClickPlayer.play)
	play_btn.pressed.connect(_on_play_pressed)
	play_btn.pressed.connect(ClickPlayer.play)
	settings_btn.pressed.connect(_on_settings_pressed)
	settings_btn.pressed.connect(ClickPlayer.play)
	TranslationManager.language_changed.connect(_update_texts)
	_update_texts()
	_start_breath_effect()
	call_deferred(&"_setup_pivot_offsets")

func _setup_pivot_offsets() -> void:
	for btn in [settings_btn, play_btn, story_btn]:
		var size := SETTINGS_BTN_SIZE if btn == settings_btn else BUTTON_SIZE
		btn.pivot_offset = size / 2

func _update_texts(_lang := "") -> void:
	var char_size := Vector2i(22, 28)
	var story_text := TranslationManager.t("story").to_upper()
	var play_text := TranslationManager.t("play").to_upper()

	story_btn.texture_normal = ButtonBuilder.build_button_texture(story_text, "res://assets/fonts/blue/", char_size, BG_TEX)
	story_btn.texture_pressed = ButtonBuilder.darken_texture(story_btn.texture_normal)
	play_btn.texture_normal = ButtonBuilder.build_button_texture(play_text, "res://assets/fonts/green/", char_size, BG_TEX)
	play_btn.texture_pressed = ButtonBuilder.darken_texture(play_btn.texture_normal)

	how_to_play.text = TranslationManager.t("how_to_play")
	var stex := ButtonBuilder.build_button_texture(TranslationManager.t("settings").to_upper(), FONT_PURPLE, char_size, SETTINGS_BG_TEX)
	settings_btn.texture_normal = stex
	settings_btn.texture_pressed = ButtonBuilder.darken_texture(stex)

func _start_breath_effect() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(play_btn, "scale", Vector2(1.06, 1.06), 0.9).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.9).set_ease(Tween.EASE_IN_OUT)

func _on_story_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/StoryPage.tscn")

func _on_play_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")

func _on_settings_pressed() -> void:
	if is_instance_valid(_settings_popup):
		return
	_settings_popup = SettingsPopupScene.instantiate()
	add_child(_settings_popup)
