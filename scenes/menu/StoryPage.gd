extends Control

@onready var close_btn := $StoryPanel/CloseButton
@onready var content_container := $StoryPanel/ContentContainer
@onready var image_rect := $ImagePanel/TextureRect
@onready var prev_btn := $ImagePanel/PrevButton
@onready var next_btn := $StoryPanel/NextButton
@onready var page_label := $StoryPanel/PageLabel

const BTN_TEX := preload("res://assets/buttons/empty_medium.png")
const BTN_TEX_LONG := preload("res://assets/buttons/empty_long.png")
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")

const ICONS := {
	"peanut": preload("res://assets/buttons/skill_peanut.png"),
	"cassava": preload("res://assets/buttons/skill_cassava.png"),
	"coffee": preload("res://assets/buttons/skill_coffee.png"),
	"flashlight": preload("res://assets/buttons/skill_flashlight.png"),
	"balm": preload("res://assets/buttons/skill_balm.png"),
	"sajen": preload("res://assets/buttons/skill_sajen.png"),
}

var current_page := 0
var story_keys := ["story_page_1", "story_page_2", "story_page_3", "story_page_4", "story_page_5", "story_page_6", "story_page_7", "story_page_8", "story_page_9"]

var _story_textures: Array[Texture2D] = []
var _btn_textures: Dictionary = {}
var _aura_tween: Tween


func _ready() -> void:
	MusicManager.play_menu_music()
	close_btn.pressed.connect(_on_close_pressed)
	close_btn.pressed.connect(ClickPlayer.play)
	prev_btn.pressed.connect(_on_prev_pressed)
	prev_btn.pressed.connect(ClickPlayer.play)
	next_btn.pressed.connect(_on_next_pressed)
	next_btn.pressed.connect(ClickPlayer.play)
	TranslationManager.language_changed.connect(_on_language_changed)
	_preload_assets()
	_show_page()


func _on_language_changed(_lang := "") -> void:
	_rebuild_button_textures()
	_show_page()


func _rebuild_button_textures() -> void:
	var font_dir := "res://assets/fonts/green/"
	var pink_dir := "res://assets/fonts/pink/"
	_btn_textures["prev"] = ButtonBuilder.build_button_texture(TranslationManager.t("prev").to_upper(), font_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["prev_dark"] = ButtonBuilder.darken_texture(_btn_textures["prev"])
	_btn_textures["next"] = ButtonBuilder.build_button_texture(TranslationManager.t("next").to_upper(), font_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["next_dark"] = ButtonBuilder.darken_texture(_btn_textures["next"])
	_btn_textures["finish"] = ButtonBuilder.build_button_texture(TranslationManager.t("finish").to_upper(), font_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["finish_dark"] = ButtonBuilder.darken_texture(_btn_textures["finish"])
	_btn_textures["close"] = ButtonBuilder.build_button_texture(TranslationManager.t("close").to_upper(), pink_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["close_dark"] = ButtonBuilder.darken_texture(_btn_textures["close"])


func _preload_assets() -> void:
	for i in story_keys.size():
		_story_textures.append(load("res://assets/stories/" + str(i + 1) + ".png"))

	var font_dir := "res://assets/fonts/green/"
	var pink_dir := "res://assets/fonts/pink/"
	_btn_textures["prev"] = ButtonBuilder.build_button_texture(TranslationManager.t("prev").to_upper(), font_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["prev_dark"] = ButtonBuilder.darken_texture(_btn_textures["prev"])
	_btn_textures["next"] = ButtonBuilder.build_button_texture(TranslationManager.t("next").to_upper(), font_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["next_dark"] = ButtonBuilder.darken_texture(_btn_textures["next"])
	_btn_textures["finish"] = ButtonBuilder.build_button_texture(TranslationManager.t("finish").to_upper(), font_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["finish_dark"] = ButtonBuilder.darken_texture(_btn_textures["finish"])
	_btn_textures["close"] = ButtonBuilder.build_button_texture(TranslationManager.t("close").to_upper(), pink_dir, Vector2i(22, 28), BTN_TEX_LONG)
	_btn_textures["close_dark"] = ButtonBuilder.darken_texture(_btn_textures["close"])


func _show_page(_lang := "") -> void:
	if _aura_tween:
		_aura_tween.kill()
		_aura_tween = null
	for child in content_container.get_children():
		content_container.remove_child(child)
		child.queue_free()

	var text = TranslationManager.t(story_keys[current_page])
	var lines = text.split("\n")
	for line in lines:
		var icon_idx = line.find("{icon_")
		if icon_idx != -1:
			var close_idx = line.find("}", icon_idx)
			var icon_name = line.substr(icon_idx + 6, close_idx - icon_idx - 6)
			var label_text = line.left(icon_idx) + line.substr(close_idx + 1)
			label_text = label_text.strip_edges()
			_add_icon_line(icon_name, label_text)
		else:
			_add_text_line(line)

	if current_page == 6:
		_add_poskamling_display()

	image_rect.texture = _story_textures[current_page]
	prev_btn.visible = current_page > 0
	prev_btn.texture_normal = _btn_textures["prev"]
	prev_btn.texture_pressed = _btn_textures["prev_dark"]
	if current_page >= story_keys.size() - 1:
		next_btn.texture_normal = _btn_textures["finish"]
		next_btn.texture_pressed = _btn_textures["finish_dark"]
	else:
		next_btn.texture_normal = _btn_textures["next"]
		next_btn.texture_pressed = _btn_textures["next_dark"]
	close_btn.texture_normal = _btn_textures["close"]
	close_btn.texture_pressed = _btn_textures["close_dark"]
	page_label.text = TranslationManager.t("page_indicator") % [current_page + 1, story_keys.size()]


func _add_icon_line(icon_name: String, label_text: String) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if icon_name == "dpad":
		var dpad = preload("res://scenes/hud/Dpad.tscn").instantiate()
		dpad.scale = Vector2(0.2, 0.2)
		hbox.add_child(dpad)
	else:
		var icon_rect = TextureRect.new()
		icon_rect.texture = ICONS.get(icon_name)
		icon_rect.custom_minimum_size = Vector2(80, 80)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hbox.add_child(icon_rect)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(8, 0)
	hbox.add_child(spacer)

	var label = Label.new()
	label.text = label_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 20)
	hbox.add_child(label)

	content_container.add_child(hbox)


func _add_text_line(text: String) -> void:
	var label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 20)
	content_container.add_child(label)


func _add_poskamling_display() -> void:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	content_container.add_child(spacer)

	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.custom_minimum_size = Vector2(0, 64)

	var container = Control.new()
	container.custom_minimum_size = Vector2(64, 64)

	var aura = ColorRect.new()
	aura.color = Color(1, 1, 0, 0.2)
	aura.custom_minimum_size = Vector2(46, 64)
	aura.position = Vector2(9, 0)
	container.add_child(aura)

	var sprite = TextureRect.new()
	sprite.texture = preload("res://assets/sprites/others/poskamling.png")
	sprite.custom_minimum_size = Vector2(64, 64)
	sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(sprite)

	center.add_child(container)

	var tween = create_tween().set_loops()
	tween.tween_property(aura, "color:a", 0.08, 1.5)
	tween.tween_property(aura, "color:a", 0.3, 1.5)
	_aura_tween = tween

	content_container.add_child(center)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_close_pressed()


func _on_close_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")


func _on_prev_pressed() -> void:
	current_page -= 1
	_show_page()


func _on_next_pressed() -> void:
	if current_page >= story_keys.size() - 1:
		SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")
	else:
		current_page += 1
		_show_page()
