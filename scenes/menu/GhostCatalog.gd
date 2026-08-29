extends Control

const QUESTION_TEX := preload("res://assets/icons_buttons/question.png")
const CATALOG_LABEL := preload("res://assets/labels/ghosts_catalog.png")
const BTN_TEX := preload("res://assets/buttons/empty_medium.png")
const BTN_TEX_LONG := preload("res://assets/buttons/empty_long.png")
const FONT_PINK := "res://assets/fonts/pink/"
const FONT_GREEN := "res://assets/fonts/green/"
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")

var current_page := 0
var _swipe_start_x: float = 0.0
var _ghost_sprite: TextureRect
var _page_label: Label
var _name_label: Label
var _desc_label: Label
var _coins_label: Label
var _level_label: Label
var _question_desc: TextureRect
var _stats_vbox: VBoxContainer
var _prev_btn: TextureButton
var _next_btn: TextureButton
var _close_btn: TextureButton
var _page_player: AudioStreamPlayer


static func open(parent: Control) -> void:
	var catalog = new()
	catalog.anchor_right = 1.0
	catalog.anchor_bottom = 1.0
	parent.add_child(catalog)


func _ready() -> void:
	_build_ui()
	_page_player = AudioStreamPlayer.new()
	_page_player.stream = preload("res://assets/sfx/page_flip.wav")
	_page_player.bus = "Master"
	add_child(_page_player)
	_show_page(0)
	TranslationManager.language_changed.connect(_on_language_changed)


func _build_ui() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var book = TextureRect.new()
	book.texture = CATALOG_LABEL
	book.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	book.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	book.position = Vector2(90, 61)
	book.custom_minimum_size = Vector2(1100, 598)
	book.gui_input.connect(_on_book_input)
	add_child(book)

	_page_label = Label.new()
	_page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_page_label.add_theme_font_size_override("font_size", 16)
	_page_label.add_theme_color_override("font_color", Color(0, 0, 0))
	_page_label.position = Vector2(276, 151)
	_page_label.size = Vector2(280, 25)
	add_child(_page_label)

	_ghost_sprite = TextureRect.new()
	_ghost_sprite.position = Vector2(350, 260)
	_ghost_sprite.custom_minimum_size = Vector2(128, 128)
	_ghost_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_ghost_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_ghost_sprite)

	_stats_vbox = VBoxContainer.new()
	_stats_vbox.position = Vector2(350, 430)
	_stats_vbox.size = Vector2(340, 60)
	_stats_vbox.add_theme_constant_override("separation", 6)
	add_child(_stats_vbox)

	var coins_hbox = HBoxContainer.new()
	coins_hbox.add_theme_constant_override("separation", 6)
	_stats_vbox.add_child(coins_hbox)

	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 16)
	_coins_label.add_theme_color_override("font_color", Color(0, 0, 0))
	coins_hbox.add_child(_coins_label)

	var coin_icon = Control.new()
	coin_icon.custom_minimum_size = Vector2(18, 18)
	coin_icon.draw.connect(func():
		coin_icon.draw_circle(Vector2(9, 9), 7, Color(1.0, 0.8, 0.0))
		coin_icon.draw_line(Vector2(9, 2), Vector2(9, 16), Color(1.0, 0.9, 0.3), 2))
	coin_icon.queue_redraw()
	coin_icon.pivot_offset = Vector2(9, 9)
	var flip = create_tween().set_loops()
	flip.tween_property(coin_icon, "scale:x", 0.0, 0.4).set_ease(Tween.EASE_IN)
	flip.tween_property(coin_icon, "scale:x", 1.0, 0.4).set_ease(Tween.EASE_OUT)
	coins_hbox.add_child(coin_icon)

	_level_label = Label.new()
	_level_label.add_theme_font_size_override("font_size", 16)
	_level_label.add_theme_color_override("font_color", Color(0, 0, 0))
	_stats_vbox.add_child(_level_label)

	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 22)
	_name_label.add_theme_color_override("font_color", Color(0, 0, 0))
	_name_label.position = Vector2(685, 201)
	_name_label.size = Vector2(340, 40)
	add_child(_name_label)

	_desc_label = Label.new()
	_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.add_theme_font_size_override("font_size", 15)
	_desc_label.add_theme_color_override("font_color", Color(0, 0, 0))
	_desc_label.position = Vector2(685, 256)
	_desc_label.size = Vector2(340, 280)
	add_child(_desc_label)

	_question_desc = TextureRect.new()
	_question_desc.texture = QUESTION_TEX
	_question_desc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_question_desc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_question_desc.position = Vector2(805, 260)
	_question_desc.custom_minimum_size = Vector2(128, 128)
	_question_desc.visible = false
	add_child(_question_desc)

	_close_btn = TextureButton.new()
	_close_btn.ignore_texture_size = true
	_close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_close_btn.position = Vector2(925, 111)
	_close_btn.custom_minimum_size = Vector2(120, 40)
	_close_btn.pressed.connect(_on_close)
	_close_btn.pressed.connect(ClickPlayer.play)
	add_child(_close_btn)

	_prev_btn = TextureButton.new()
	_prev_btn.ignore_texture_size = true
	_prev_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_prev_btn.position = Vector2(210, 518)
	_prev_btn.custom_minimum_size = Vector2(160, 48)
	_prev_btn.pressed.connect(_on_prev)
	_prev_btn.pressed.connect(ClickPlayer.play)
	add_child(_prev_btn)

	_next_btn = TextureButton.new()
	_next_btn.ignore_texture_size = true
	_next_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_next_btn.position = Vector2(910, 518)
	_next_btn.custom_minimum_size = Vector2(160, 48)
	_next_btn.pressed.connect(_on_next)
	_next_btn.pressed.connect(ClickPlayer.play)
	add_child(_next_btn)

	_on_language_changed()


func _update_button_texture(btn: TextureButton, text: String, font_dir: String, bg_tex: Texture2D) -> void:
	var tex := ButtonBuilder.build_button_texture(text.to_upper(), font_dir, Vector2i(22, 28), bg_tex)
	btn.texture_normal = tex
	btn.texture_pressed = ButtonBuilder.darken_texture(tex)


func _show_page(index: int) -> void:
	var total = GhostDatabase.get_total_ghost_count()
	var data = GhostDatabase.get_ghost_data(index)
	if data.is_empty():
		return
	var unlocked = SaveManager.current_level >= data.get("level", 999)
	var coins := int(data.get("coins", 1))
	var level := int(data.get("level", 1))

	_page_label.text = "%d / %d" % [index + 1, total]

	if unlocked:
		var path = "res://assets/sprites/ghosts/" + data.get("name", "") + ".png"
		var tex = load(path)
		_ghost_sprite.texture = tex if tex else QUESTION_TEX
		_name_label.text = _format_name(data.get("name", ""))
		var lang = TranslationManager.current_language
		var desc_key = "desc_" + lang
		_desc_label.text = data.get(desc_key, data.get("desc_en", ""))
		_desc_label.visible = true
		_question_desc.visible = false
		_coins_label.text = TranslationManager.t("pesugihan_coins") + " " + str(coins) + " x"
		_level_label.text = TranslationManager.t("shown_in_level") + " : " + str(level)
		_stats_vbox.visible = true
	else:
		_ghost_sprite.texture = QUESTION_TEX
		_name_label.text = ""
		_desc_label.visible = false
		_question_desc.visible = true
		_stats_vbox.visible = false

	_prev_btn.visible = index > 0
	_next_btn.visible = index < total - 1


func _format_name(name: String) -> String:
	if name.is_empty():
		return ""
	var parts = name.split("_")
	for i in range(parts.size()):
		if parts[i].length() > 0:
			parts[i] = parts[i][0].to_upper() + parts[i].substr(1)
	return " ".join(parts)


func _on_book_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_swipe_start_x = event.position.x
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var dx = event.position.x - _swipe_start_x
			if dx > 50:
				_on_prev()
			elif dx < -50:
				_on_next()


func _on_prev() -> void:
	if current_page <= 0:
		return
	current_page -= 1
	_show_page(current_page)
	_page_player.play(0.0)


func _on_next() -> void:
	var total = GhostDatabase.get_total_ghost_count()
	if current_page >= total - 1:
		return
	current_page += 1
	_show_page(current_page)
	_page_player.play(0.0)


func _on_close() -> void:
	queue_free()


func _on_language_changed(_lang := "") -> void:
	_update_button_texture(_close_btn, TranslationManager.t("close"), FONT_PINK, BTN_TEX)
	_update_button_texture(_prev_btn, TranslationManager.t("prev"), FONT_GREEN, BTN_TEX_LONG)
	_update_button_texture(_next_btn, TranslationManager.t("next"), FONT_GREEN, BTN_TEX_LONG)
	_show_page(current_page)
