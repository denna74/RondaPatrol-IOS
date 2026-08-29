extends CanvasLayer

const VIEWPORT_W := 1280
const VIEWPORT_H := 720

const LEFT_TOP_W := 240
const LEFT_TOP_H := 250
const DPAD_SIZE := 300
const LEFT_BOT_W := DPAD_SIZE

const RIGHT_TOP_W := 180
const RIGHT_TOP_H := 250
const RIGHT_BOT_W := 220

const GAMEPLAY_X: int = maxi(LEFT_TOP_W, LEFT_BOT_W)
const GAMEPLAY_W: int = VIEWPORT_W - GAMEPLAY_X - maxi(RIGHT_TOP_W, RIGHT_BOT_W)
const GAMEPLAY_H: int = VIEWPORT_H

var level_label: Label
var ghosts_label: Label
var stamina_bar: ProgressBar
var jimpitan_label: Label
var treasury_label: Label
var radar: Control
var dpad: Control
var skill_bar: Node2D
var treasury_name: Label
var return_msg: Label
var stolen_msg: Label
var _stolen_tween: Tween
var _stolen_msg_fading := false
var lvl_name: Label
var gho_name: Label
var jim_name: Label
var sta_name: Label
var exit_btn: TextureButton
var _stamina_tween: Tween
var _stamina_style: StyleBoxFlat
var _stamina_alert: Label
var _stamina_green_tween: Tween
var _orig_border_color: Color
var life_name: Label
var heart_0: TextureRect
var heart_1: TextureRect
var heart_2: TextureRect
const HEART_TEX := preload("res://assets/icons_buttons/heart.png")
const HEART_LOST_TEX := preload("res://assets/icons_buttons/heart_lost.png")
const EMPTY_MEDIUM := preload("res://assets/buttons/empty_medium.png")
const EMPTY_LONG := preload("res://assets/buttons/empty_long.png")
const FONT_PINK := "res://assets/fonts/pink/"
const FONT_GREEN := "res://assets/fonts/green/"
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")
const EMPTY_SHORT := preload("res://assets/labels/empty_short.png")


func _init() -> void:
	var left_top_bg = TextureRect.new()
	left_top_bg.texture = EMPTY_SHORT
	left_top_bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	left_top_bg.stretch_mode = TextureRect.STRETCH_SCALE
	left_top_bg.position = Vector2(0, 0)
	left_top_bg.size = Vector2(LEFT_TOP_W, LEFT_TOP_H)
	add_child(left_top_bg)

	var left_bot_bg = ColorRect.new()
	left_bot_bg.color = Color(0, 0, 0, 0)
	left_bot_bg.position = Vector2(0, LEFT_TOP_H)
	left_bot_bg.size = Vector2(LEFT_BOT_W, VIEWPORT_H - LEFT_TOP_H)
	add_child(left_bot_bg)

	var right_top_bg = ColorRect.new()
	right_top_bg.color = Color(0, 0, 0, 0)
	right_top_bg.position = Vector2(VIEWPORT_W - RIGHT_TOP_W, 0)
	right_top_bg.size = Vector2(RIGHT_TOP_W, RIGHT_TOP_H)
	add_child(right_top_bg)

	var right_bot_bg = ColorRect.new()
	right_bot_bg.color = Color(0, 0, 0, 0)
	right_bot_bg.position = Vector2(VIEWPORT_W - RIGHT_BOT_W, RIGHT_TOP_H)
	right_bot_bg.size = Vector2(RIGHT_BOT_W, VIEWPORT_H - RIGHT_TOP_H)
	add_child(right_bot_bg)

	lvl_name = Label.new()
	lvl_name.position = Vector2(88, 14)
	add_child(lvl_name)

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.position = Vector2(130, 14)
	level_label.text = ": 1"
	add_child(level_label)

	gho_name = Label.new()
	gho_name.position = Vector2(28, 54)
	add_child(gho_name)

	ghosts_label = Label.new()
	ghosts_label.name = "GhostsLabel"
	ghosts_label.position = Vector2(100, 54)
	ghosts_label.text = ": 0"
	add_child(ghosts_label)

	treasury_name = Label.new()
	treasury_name.position = Vector2(28, 88)
	add_child(treasury_name)

	treasury_label = Label.new()
	treasury_label.name = "TreasuryLabel"
	treasury_label.position = Vector2(100, 88)
	treasury_label.text = ": 0"
	add_child(treasury_label)

	jim_name = Label.new()
	jim_name.position = Vector2(28, 122)
	add_child(jim_name)

	jimpitan_label = Label.new()
	jimpitan_label.name = "JimpitanLabel"
	jimpitan_label.position = Vector2(100, 122)
	jimpitan_label.text = ": 0 / 0"
	add_child(jimpitan_label)

	sta_name = Label.new()
	sta_name.position = Vector2(28, 156)
	add_child(sta_name)

	stamina_bar = ProgressBar.new()
	stamina_bar.name = "StaminaBar"
	stamina_bar.position = Vector2(100, 156)
	stamina_bar.custom_minimum_size = Vector2(100, 16)
	stamina_bar.size = Vector2(100, 16)
	stamina_bar.value = 100.0
	add_child(stamina_bar)

	_stamina_style = StyleBoxFlat.new()
	_stamina_style.bg_color = Color(0.2, 0.2, 0.2, 1)
	_stamina_style.border_width_left = 2
	_stamina_style.border_width_top = 2
	_stamina_style.border_width_right = 2
	_stamina_style.border_width_bottom = 2
	_stamina_style.border_color = Color(1, 0, 0, 0)
	_orig_border_color = _stamina_style.border_color
	stamina_bar.add_theme_stylebox_override("background", _stamina_style)

	_stamina_alert = Label.new()
	_stamina_alert.name = "StaminaAlert"
	_stamina_alert.position = Vector2(207, 152)
	_stamina_alert.text = "!"
	_stamina_alert.add_theme_color_override("font_color", Color(1, 0, 0, 1))
	_stamina_alert.modulate.a = 0.0
	_stamina_alert.add_theme_font_size_override("font_size", 24)
	add_child(_stamina_alert)

	life_name = Label.new()
	life_name.name = "LifeName"
	life_name.position = Vector2(28, 188)
	life_name.text = "Life"
	add_child(life_name)

	var life_colon = Label.new()
	life_colon.position = Vector2(68, 188)
	life_colon.text = ":"
	add_child(life_colon)

	heart_0 = TextureRect.new()
	heart_0.name = "Heart0"
	heart_0.texture = HEART_TEX
	heart_0.custom_minimum_size = Vector2(20, 20)
	heart_0.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_0.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_0.position = Vector2(110, 191)
	add_child(heart_0)

	heart_1 = TextureRect.new()
	heart_1.name = "Heart1"
	heart_1.texture = HEART_TEX
	heart_1.custom_minimum_size = Vector2(20, 20)
	heart_1.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_1.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_1.position = Vector2(134, 191)
	add_child(heart_1)

	heart_2 = TextureRect.new()
	heart_2.name = "Heart2"
	heart_2.texture = HEART_TEX
	heart_2.custom_minimum_size = Vector2(20, 20)
	heart_2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	heart_2.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heart_2.position = Vector2(158, 191)
	add_child(heart_2)

	dpad = preload("res://scenes/hud/Dpad.tscn").instantiate()
	dpad.name = "Dpad"
	dpad.position = Vector2(0, LEFT_TOP_H + 80)
	dpad.custom_minimum_size = Vector2(DPAD_SIZE, DPAD_SIZE)
	add_child(dpad)

	exit_btn = TextureButton.new()
	exit_btn.name = "ExitButton"
	exit_btn.position = Vector2(VIEWPORT_W - RIGHT_TOP_W - 16, 10)
	exit_btn.custom_minimum_size = Vector2(RIGHT_TOP_W - 12, 56)
	exit_btn.ignore_texture_size = true
	exit_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.pressed.connect(_on_exit_pressed)
	exit_btn.pressed.connect(ClickPlayer.play)
	add_child(exit_btn)

	radar = preload("res://scenes/hud/Radar.tscn").instantiate()
	radar.name = "Radar"
	radar.position = Vector2(VIEWPORT_W - RIGHT_TOP_W - 16, 74)
	radar.size = Vector2(RIGHT_TOP_W - 12, 168)
	add_child(radar)

	skill_bar = preload("res://scenes/hud/SkillBar.tscn").instantiate()
	skill_bar.name = "SkillBar"
	skill_bar.position = Vector2(VIEWPORT_W - RIGHT_BOT_W - 10, RIGHT_TOP_H + 100)
	add_child(skill_bar)

	return_msg = Label.new()
	return_msg.name = "ReturnMsg"
	return_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_msg.position = Vector2(GAMEPLAY_X + 10, 10)
	return_msg.size = Vector2(GAMEPLAY_W - 20, 40)
	return_msg.add_theme_color_override("font_color", Color(1, 0.8, 0))
	return_msg.visible = false
	return_msg.add_theme_font_size_override("font_size", 30)
	add_child(return_msg)

	stolen_msg = Label.new()
	stolen_msg.name = "StolenMsg"
	stolen_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stolen_msg.position = Vector2(GAMEPLAY_X + 10, 10)
	stolen_msg.size = Vector2(GAMEPLAY_W - 20, 40)
	stolen_msg.add_theme_color_override("font_color", Color(1, 0, 0))
	stolen_msg.visible = false
	stolen_msg.add_theme_font_size_override("font_size", 30)
	add_child(stolen_msg)


func _ready() -> void:
	TranslationManager.language_changed.connect(_update_texts)
	_update_texts()
	SaveManager.life_changed.connect(_on_life_changed)
	_on_life_changed(SaveManager.life_level)


func _update_texts(_lang := "") -> void:
	lvl_name.text = TranslationManager.t("level")
	gho_name.text = TranslationManager.t("ghosts")
	treasury_name.text = TranslationManager.t("treasury_name")
	treasury_label.text = ": %d" % SaveManager.total_coins
	jim_name.text = TranslationManager.t("jimpitan")
	sta_name.text = TranslationManager.t("stamina")
	var exit_tex = ButtonBuilder.build_button_texture(TranslationManager.t("exit"), FONT_PINK, Vector2i(22, 28), EMPTY_MEDIUM)
	exit_btn.texture_normal = exit_tex
	exit_btn.texture_pressed = ButtonBuilder.darken_texture(exit_tex)
	return_msg.text = TranslationManager.t("return_poskamling")
	life_name.text = TranslationManager.t("life")


func _on_life_changed(new_life: int) -> void:
	heart_0.texture = HEART_TEX if 0 < new_life else HEART_LOST_TEX
	heart_1.texture = HEART_TEX if 1 < new_life else HEART_LOST_TEX
	heart_2.texture = HEART_TEX if 2 < new_life else HEART_LOST_TEX


func update_level(lvl: int) -> void:
	level_label.text = ": %d" % lvl


func update_ghosts(count: int) -> void:
	ghosts_label.text = ": %d" % count


func update_treasury(amount: int) -> void:
	treasury_label.text = ": %d" % amount


func update_stamina(percent: float) -> void:
	stamina_bar.value = percent * 100
	if percent <= 0.2:
		if not _stamina_tween or not _stamina_tween.is_running():
			_stamina_tween = create_tween()
			_stamina_tween.set_loops()
			_stamina_tween.tween_property(_stamina_style, "border_color:a", 1.0, 0.3)
			_stamina_tween.parallel().tween_property(_stamina_alert, "modulate:a", 1.0, 0.3)
			_stamina_tween.tween_property(_stamina_style, "border_color:a", 0.0, 0.3)
			_stamina_tween.parallel().tween_property(_stamina_alert, "modulate:a", 0.0, 0.3)
	else:
		if _stamina_tween and _stamina_tween.is_running():
			_stamina_tween.kill()
		_stamina_style.border_color = _orig_border_color
		_stamina_style.border_color.a = 0.0
		_stamina_alert.modulate.a = 0.0


func flash_stamina_green() -> void:
	if _stamina_green_tween and _stamina_green_tween.is_running():
		_stamina_green_tween.kill()
	_stamina_green_tween = create_tween()
	_stamina_green_tween.set_loops(4)
	_stamina_green_tween.tween_property(_stamina_style, "border_color", Color(0, 1, 0, 1), 0.2)
	_stamina_green_tween.tween_property(_stamina_style, "border_color", _orig_border_color, 0.2)
	_stamina_green_tween.finished.connect(_reset_border)

func _reset_border() -> void:
	_stamina_style.border_color = _orig_border_color
	_stamina_style.border_color.a = 0.0


func update_jimpitan(collected: int, total: int) -> void:
	jimpitan_label.text = ": %d / %d" % [collected, total]


func update_radar(ghost_positions: Array, map_size: Vector2) -> void:
	radar.update_positions(ghost_positions, map_size)


func _process(_delta: float) -> void:
	var msec = Time.get_ticks_msec()
	var blink = 1.0 if (msec / 300) % 2 == 0 else 0.15
	if return_msg.visible:
		return_msg.modulate.a = blink
	if stolen_msg.visible and not _stolen_msg_fading:
		stolen_msg.modulate.a = blink


func show_return_message() -> void:
	return_msg.visible = true


func hide_return_message() -> void:
	return_msg.visible = false


func show_stolen_message(text: String) -> void:
	if _stolen_tween and _stolen_tween.is_running():
		_stolen_tween.kill()
	stolen_msg.text = text
	stolen_msg.visible = true
	stolen_msg.modulate.a = 1.0
	_stolen_msg_fading = false
	_stolen_tween = create_tween()
	_stolen_tween.tween_interval(1.5)
	_stolen_tween.tween_callback(_fade_out_stolen_message)

func _fade_out_stolen_message() -> void:
	_stolen_msg_fading = true
	_stolen_tween = create_tween()
	_stolen_tween.tween_property(stolen_msg, "modulate:a", 0.0, 0.5)
	_stolen_tween.tween_callback(func():
		stolen_msg.visible = false
		_stolen_msg_fading = false
	)


func _on_exit_pressed() -> void:
	_show_exit_confirm_popup()


func _show_exit_confirm_popup() -> void:
	var gameplay = get_parent()
	var prev_hud_mode = process_mode
	process_mode = PROCESS_MODE_ALWAYS
	gameplay.process_mode = PROCESS_MODE_DISABLED

	var overlay = ColorRect.new()
	overlay.name = "ExitConfirmPopup"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_left = 0
	overlay.anchor_top = 0
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel = Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -238
	panel.offset_top = -154
	panel.offset_right = 238
	panel.offset_bottom = 154
	overlay.add_child(panel)

	var title = Label.new()
	title.text = TranslationManager.t("exit_confirm_title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.size = Vector2(392, 39)
	title.position = Vector2(42, 25)
	panel.add_child(title)

	var desc = Label.new()
	desc.text = TranslationManager.t("exit_confirm_desc")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override("font_size", 18)
	desc.size = Vector2(392, 50)
	desc.position = Vector2(42, 73)
	panel.add_child(desc)

	var btn_w := 350
	var btn_h := 73
	var btn_x := 63

	var continue_tex = ButtonBuilder.build_button_texture(TranslationManager.t("continue"), FONT_GREEN, Vector2i(22, 28), EMPTY_LONG)
	var continue_btn = TextureButton.new()
	continue_btn.texture_normal = continue_tex
	continue_btn.texture_pressed = ButtonBuilder.darken_texture(continue_tex)
	continue_btn.ignore_texture_size = true
	continue_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	continue_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	continue_btn.position = Vector2(btn_x, 140)
	continue_btn.pressed.connect(func():
		overlay.queue_free()
		gameplay.process_mode = PROCESS_MODE_INHERIT
		process_mode = prev_hud_mode)
	continue_btn.pressed.connect(ClickPlayer.play)
	panel.add_child(continue_btn)

	var exit_tex = ButtonBuilder.build_button_texture(TranslationManager.t("exit"), FONT_PINK, Vector2i(22, 28), EMPTY_MEDIUM)
	var exit_btn = TextureButton.new()
	exit_btn.texture_normal = exit_tex
	exit_btn.texture_pressed = ButtonBuilder.darken_texture(exit_tex)
	exit_btn.ignore_texture_size = true
	exit_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	exit_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	exit_btn.position = Vector2(btn_x, 227)
	exit_btn.pressed.connect(func():
		overlay.queue_free()
		SaveManager.lose_life()
		SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn"))
	exit_btn.pressed.connect(ClickPlayer.play)
	panel.add_child(exit_btn)
