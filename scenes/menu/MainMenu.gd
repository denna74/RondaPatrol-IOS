extends Control

@onready var story_btn := $BottomGroup/ButtonRow/StoryButton as TextureButton
@onready var play_btn := $BottomGroup/ButtonRow/PlayButton as TextureButton
@onready var exit_btn := $BottomGroup/ButtonRow/ExitButton as TextureButton
@onready var how_to_play := $BottomGroup/HowToPlay
@onready var settings_btn := $SettingsButton as TextureButton

const BG_TEX := preload("res://assets/buttons/empty_short.png")
const WOOD_SHORT := preload("res://assets/buttons/wood_short.png")
const GEAR_TEX := preload("res://assets/buttons/setting_small.png")
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")
const SettingsPopupScene := preload("res://scenes/menu/SettingsPopup.tscn")
const BUTTON_SIZE := Vector2(157, 64)
const SETTINGS_BTN_SIZE := Vector2(260, 84)
const FONT_PURPLE := "res://assets/fonts/purple/"

var _settings_popup: Control

func _ready() -> void:
	MusicManager.play_menu_music()
	settings_btn.custom_minimum_size = SETTINGS_BTN_SIZE
	story_btn.pressed.connect(_on_story_pressed)
	story_btn.pressed.connect(ClickPlayer.play)
	play_btn.pressed.connect(_on_play_pressed)
	play_btn.pressed.connect(ClickPlayer.play)
	exit_btn.pressed.connect(_on_exit_pressed)
	exit_btn.pressed.connect(ClickPlayer.play)
	settings_btn.pressed.connect(_on_settings_pressed)
	settings_btn.pressed.connect(ClickPlayer.play)
	TranslationManager.language_changed.connect(_update_texts)
	_update_texts()
	_start_breath_effect()
	call_deferred(&"_setup_pivot_offsets")

func _setup_pivot_offsets() -> void:
	for btn in [story_btn, play_btn, exit_btn]:
		btn.pivot_offset = BUTTON_SIZE / 2

func _update_texts(_lang := "") -> void:
	var char_size := Vector2i(22, 28)
	var story_text := TranslationManager.t("story").to_upper()
	var play_text := TranslationManager.t("play").to_upper()
	var exit_text := TranslationManager.t("exit").to_upper()

	story_btn.texture_normal = ButtonBuilder.build_button_texture(story_text, "res://assets/fonts/blue/", char_size, BG_TEX)
	story_btn.texture_pressed = ButtonBuilder.darken_texture(story_btn.texture_normal)
	play_btn.texture_normal = ButtonBuilder.build_button_texture(play_text, "res://assets/fonts/green/", char_size, BG_TEX)
	play_btn.texture_pressed = ButtonBuilder.darken_texture(play_btn.texture_normal)
	exit_btn.texture_normal = ButtonBuilder.build_button_texture(exit_text, "res://assets/fonts/pink/", char_size, BG_TEX)
	exit_btn.texture_pressed = ButtonBuilder.darken_texture(exit_btn.texture_normal)

	how_to_play.text = TranslationManager.t("how_to_play")
	var stex := _build_settings_texture(TranslationManager.t("settings"))
	settings_btn.texture_normal = stex
	settings_btn.texture_pressed = ButtonBuilder.darken_texture(stex)

func _build_settings_texture(text: String) -> Texture2D:
	var char_size := Vector2i(32, 42)
	var text_w := 0
	for i in text.length():
		text_w += 10 if text[i] == " " else char_size.x
	var sub_bg := Image.create(text_w, char_size.y, false, Image.FORMAT_RGBA8)
	var text_tex := ButtonBuilder.build_button_texture(text, FONT_PURPLE, char_size, ImageTexture.create_from_image(sub_bg))
	var gear := ButtonBuilder._crop_to_content(GEAR_TEX.get_image())
	gear.resize(60, 60, Image.INTERPOLATE_LANCZOS)
	var img: Image = WOOD_SHORT.get_image().duplicate()
	var gap := 24
	var total := gear.get_width() + gap + text_w
	var x0 := (img.get_width() - total) / 2
	img.blend_rect(gear, Rect2i(0, 0, gear.get_width(), gear.get_height()), Vector2i(x0, (img.get_height() - gear.get_height()) / 2))
	var timg := text_tex.get_image()
	img.blend_rect(timg, Rect2i(0, 0, timg.get_width(), timg.get_height()), Vector2i(x0 + gear.get_width() + gap, (img.get_height() - char_size.y) / 2 ))
	return ImageTexture.create_from_image(img)

func _start_breath_effect() -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(play_btn, "scale", Vector2(1.06, 1.06), 0.9).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.9).set_ease(Tween.EASE_IN_OUT)

func _on_story_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/StoryPage.tscn")

func _on_play_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")

func _on_exit_pressed() -> void:
	_request_app_exit()

func _request_app_exit() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if tree.root != null:
		tree.root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	tree.quit()

func _on_settings_pressed() -> void:
	if is_instance_valid(_settings_popup):
		return
	_settings_popup = SettingsPopupScene.instantiate()
	add_child(_settings_popup)
