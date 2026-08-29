extends Control

var _treasury_value_label: Label
@onready var level_container := $LevelScroll/LevelContainer
@onready var shop_container := $ShopPanel/GridContainer
@onready var main_menu_btn := $ShopPanel/MainMenuButton
var item_ids := ["senter", "kopi", "balsem", "kacang", "cassava", "sajen"]
var item_buttons := {}

const SHOP_EN := preload("res://assets/labels/shop_en.png")
const SHOP_ID := preload("res://assets/labels/shop_id.png")

const ITEM_TEX := {
	"senter": { "en": preload("res://assets/buttons/items_battery_en.png"), "id": preload("res://assets/buttons/items_battery_id.png") },
	"kopi": { "en": preload("res://assets/buttons/items_coffee_en.png"), "id": preload("res://assets/buttons/items_coffee_id.png") },
	"balsem": { "en": preload("res://assets/buttons/items_balm_en.png"), "id": preload("res://assets/buttons/items_balm_id.png") },
	"kacang": { "en": preload("res://assets/buttons/items_peanut_en.png"), "id": preload("res://assets/buttons/items_peanut_id.png") },
	"cassava": { "en": preload("res://assets/buttons/items_cassava_en.png"), "id": preload("res://assets/buttons/items_cassava_id.png") },
	"sajen": { "en": preload("res://assets/buttons/items_sajen_en.png"), "id": preload("res://assets/buttons/items_sajen_id.png") }
}

const SKILL_TEX := {
	"senter": preload("res://assets/buttons/skill_flashlight.png"),
	"kopi": preload("res://assets/buttons/skill_coffee.png"),
	"balsem": preload("res://assets/buttons/skill_balm.png"),
	"kacang": preload("res://assets/buttons/skill_peanut.png"),
	"cassava": preload("res://assets/buttons/skill_cassava.png"),
	"sajen": preload("res://assets/buttons/skill_sajen.png")
}

const WOOD_BTN_TEX := preload("res://assets/buttons/wood_short.png")
const LOCKED_LVL_TEX := preload("res://assets/buttons/locked_level_button.png")
const EMPTY_LONG := preload("res://assets/buttons/empty_long.png")
const EMPTY_SHORT := preload("res://assets/buttons/empty_short.png")
const INSTANT_COINS_EN := preload("res://assets/buttons/instant_coins_en.png")
const INSTANT_COINS_ID := preload("res://assets/buttons/instant_coins_id.png")
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")
const INSTANT_LIFE_EN := preload("res://assets/buttons/instant_life_en.png")
const INSTANT_LIFE_ID := preload("res://assets/buttons/instant_life_id.png")
const WATCH_ADS_EN := preload("res://assets/buttons/watch_ads_en.png")
const WATCH_ADS_ID := preload("res://assets/buttons/watch_ads_id.png")
const GHOSTS_CATALOG_BTN := preload("res://assets/buttons/ghosts_catalog.png")
const GhostCatalog := preload("res://scenes/menu/GhostCatalog.gd")
const HEART_TEX := preload("res://assets/icons_buttons/heart.png")
const HEART_LOST_TEX := preload("res://assets/icons_buttons/heart_lost.png")
const CANCEL_BG := preload("res://assets/buttons/empty_medium.png")
const STAR_ONE_LVL := preload("res://assets/buttons/star_one_level_button.png")
const STAR_TWO_LVL := preload("res://assets/buttons/star_two_level_button.png")
const STAR_THREE_LVL := preload("res://assets/buttons/star_three_level_button.png")

var _cached_digits_green: Array = []
var _cached_digits_yellow: Array = []
var _cached_digits_green_tex: Array = []
var _cached_digits_yellow_tex: Array = []

func _ready() -> void:
	MusicManager.play_menu_music()
	$LevelScroll.get_v_scroll_bar().hide()
	TranslationManager.language_changed.connect(_update_texts)
	_build_treasury_display()
	_update_texts()
	_setup_coin_shop()
	_build_shop()
	_init_digit_cache()
	call_deferred(&"_build_level_list")
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	main_menu_btn.pressed.connect(ClickPlayer.play)
	_build_life_display(SaveManager.life_level)
	_setup_instant_life_btn()
	_setup_ghost_catalog_btn()
	SaveManager.life_changed.connect(_on_life_changed)
	IAPManager.billing_ready.connect(_on_billing_ready)
	IAPManager.purchases_restored.connect(_on_purchases_restored)
	_on_purchases_restored()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if _confirm_overlay != null \
			or _coin_popup_overlay != null \
			or get_node_or_null("InstantOverlay") != null \
			or get_child_count() > 3:
			return
		_on_main_menu_pressed()


func _build_treasury_display() -> void:
	var name_label = Label.new()
	name_label.text = TranslationManager.t("treasury_name")
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	name_label.position = Vector2(10, 31)
	name_label.size = Vector2(50, 28)
	$StatusPanel.add_child(name_label)

	var colon = Label.new()
	colon.text = ":"
	colon.add_theme_font_size_override("font_size", 18)
	colon.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	colon.position = Vector2(78, 29)
	colon.size = Vector2(15, 28)
	$StatusPanel.add_child(colon)

	_treasury_value_label = Label.new()
	_treasury_value_label.add_theme_font_size_override("font_size", 16)
	_treasury_value_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	_treasury_value_label.position = Vector2(95, 31)
	_treasury_value_label.size = Vector2(260, 28)
	_treasury_value_label.text = str(SaveManager.total_coins)
	$StatusPanel.add_child(_treasury_value_label)

func _update_texts(_lang := "") -> void:
	_treasury_value_label.text = str(SaveManager.total_coins)
	_update_life_btn_texture()
	_update_life_btn_state()
	_update_coin_btn_texture()
	var tex = SHOP_EN if TranslationManager.current_language == "en" else SHOP_ID
	var style = StyleBoxTexture.new()
	style.texture = tex
	$ShopPanel.add_theme_stylebox_override("panel", style)
	var lang = TranslationManager.current_language
	var main_tex = ButtonBuilder.build_button_texture(TranslationManager.t("main_menu"), "res://assets/fonts/green/", Vector2i(22, 28), EMPTY_LONG)
	main_menu_btn.texture_normal = main_tex
	main_menu_btn.texture_pressed = ButtonBuilder.darken_texture(main_tex)
	for id in item_ids:
		if id in item_buttons:
			var btn = item_buttons[id]
			btn.texture_normal = ITEM_TEX[id][lang]
			btn.texture_pressed = ButtonBuilder.darken_texture(btn.texture_normal)

func _update_header() -> void:
	_treasury_value_label.text = str(SaveManager.total_coins)

func _on_life_changed(new_life: int) -> void:
	_build_life_display(new_life)
	_update_life_btn_state()

func _crop_to_content(img: Image) -> Image:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := 0
	var max_y := 0
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0:
				if x < min_x: min_x = x
				if y < min_y: min_y = y
				if x > max_x: max_x = x
				if y > max_y: max_y = y
	if max_x < min_x:
		return img
	var rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	var cropped := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(img, rect, Vector2i.ZERO)
	return cropped

func _init_digit_cache() -> void:
	_cached_digits_green.resize(10)
	_cached_digits_yellow.resize(10)
	_cached_digits_green_tex.resize(10)
	_cached_digits_yellow_tex.resize(10)
	for d in 10:
		var tex_green := load("res://assets/numbers/green/" + str(d) + ".png") as Texture2D
		var tex_yellow := load("res://assets/numbers/yellow/" + str(d) + ".png") as Texture2D
		if tex_green:
			_cached_digits_green[d] = _crop_to_content(tex_green.get_image())
			_cached_digits_green_tex[d] = ImageTexture.create_from_image(_cached_digits_green[d])
		if tex_yellow:
			_cached_digits_yellow[d] = _crop_to_content(tex_yellow.get_image())
			_cached_digits_yellow_tex[d] = ImageTexture.create_from_image(_cached_digits_yellow[d])


func _add_number_overlay(btn: TextureButton, level: int, is_current: bool, is_locked: bool) -> void:
	var number_str := str(level)
	var is_yellow = is_current or is_locked
	var dig_h = 62 if is_current else 36
	var gap = 3 if is_yellow else 4
	var offset_y_factor = 0.5 if is_current else 0.65

	var cache = _cached_digits_yellow_tex if is_yellow else _cached_digits_green_tex
	var bg_w = btn.custom_minimum_size.x
	var bg_h = btn.custom_minimum_size.y

	var total_w := 0
	var digit_data := []
	for i in number_str.length():
		var digit := int(number_str[i])
		var tex: Texture2D = cache[digit]
		var aspect := float(tex.get_width()) / tex.get_height()
		var w := int(dig_h * aspect)
		digit_data.append({"tex": tex, "w": w})
		total_w += w
	total_w += gap * max(0, digit_data.size() - 1)

	var offset_x: int = (bg_w - total_w) / 2
	var offset_y: int = int(bg_h * offset_y_factor - dig_h / 2)

	var x: int = offset_x
	for d in digit_data:
		var spr = Sprite2D.new()
		spr.texture = d.tex	
		spr.centered = false
		spr.position = Vector2(x, offset_y)
		spr.scale = Vector2(float(d.w) / d.tex.get_width(), float(dig_h) / d.tex.get_height())
		btn.add_child(spr)
		x += d.w + gap

func _build_life_display(life: int) -> void:
	var existing = $StatusPanel.get_node_or_null("LifeDisplay")
	if existing:
		existing.free()

	var life_display = Control.new()
	life_display.name = "LifeDisplay"
	$StatusPanel.add_child(life_display)

	var life_label = Label.new()
	life_label.text = TranslationManager.t("life")
	life_label.add_theme_font_size_override("font_size", 16)
	life_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	life_label.position = Vector2(10, 8)
	life_label.size = Vector2(50, 28)
	life_display.add_child(life_label)

	var colon = Label.new()
	colon.text = ":"
	colon.add_theme_font_size_override("font_size", 18)
	colon.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	colon.position = Vector2(78, 6)
	colon.size = Vector2(15, 28)
	life_display.add_child(colon)

	for i in range(3):
		var heart = TextureRect.new()
		heart.texture = HEART_TEX if i < life else HEART_LOST_TEX
		heart.custom_minimum_size = Vector2(24, 22)
		heart.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		heart.position = Vector2(95 + i * 22, 8)
		life_display.add_child(heart)


func _build_level_list() -> void:
	level_container.add_theme_constant_override("separation", 10)
	var max_reached = SaveManager.current_level
	for lvl in range(max_reached + 2, 0, -1):
		var btn = _make_level_button(lvl)
		level_container.add_child(btn)
	level_container.reset_size()
	$LevelScroll.queue_sort()


func _make_level_button(lvl: int) -> TextureButton:
	var max_reached = SaveManager.current_level
	var btn = TextureButton.new()
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	var is_current = lvl == max_reached
	var is_locked = lvl > max_reached

	if is_current:
		btn.custom_minimum_size = Vector2(300, 113)
		btn.texture_normal = WOOD_BTN_TEX
		btn.pivot_offset = Vector2(150, 56.5)
		_start_breath_effect(btn)
	elif is_locked:
		btn.custom_minimum_size = Vector2(203, 120)
		btn.texture_normal = LOCKED_LVL_TEX
		btn.disabled = true
		btn.self_modulate = Color(0.5, 0.5, 0.5)
	else:
		btn.custom_minimum_size = Vector2(203, 120)
		var stars = SaveManager.get_level_stars(lvl)
		match stars:
			3: btn.texture_normal = STAR_THREE_LVL
			2: btn.texture_normal = STAR_TWO_LVL
			_: btn.texture_normal = STAR_ONE_LVL

	_add_number_overlay(btn, lvl, is_current, is_locked)

	if not is_locked:
		btn.connect("button_down", func():
			btn.self_modulate = Color(0.7, 0.7, 0.7)
		)
		btn.connect("button_up", func():
			btn.self_modulate = Color(1, 1, 1)
		)

	btn.pressed.connect(_on_level_selected.bind(lvl))
	btn.pressed.connect(ClickPlayer.play)
	return btn

func _start_breath_effect(btn: TextureButton) -> void:
	var tween := create_tween()
	tween.set_loops()
	tween.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.9).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.9).set_ease(Tween.EASE_IN_OUT)

func _build_shop() -> void:
	var lang = TranslationManager.current_language
	for id in item_ids:
		var tex = ITEM_TEX[id][lang]
		var btn = TextureButton.new()
		btn.texture_normal = tex
		btn.texture_pressed = ButtonBuilder.darken_texture(tex)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(128, 128)
		btn.pressed.connect(_on_buy_pressed.bind(id))
		btn.pressed.connect(ClickPlayer.play)

		var label = Label.new()
		label.name = "AmountLabel"
		label.offset_left = -4.0
		label.offset_top = -6.0
		label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 3)
		label.add_theme_font_size_override("font_size", 14)
		btn.add_child(label)

		shop_container.add_child(btn)
		item_buttons[id] = btn
	_update_shop_amounts()

func _on_buy_pressed(item_id: String) -> void:
	_show_confirm_popup(item_id)


func _show_confirm_popup(item_id: String) -> void:
	if _confirm_panel:
		return
	_confirm_item_id = item_id
	var data = ItemData.get_item(item_id)
	var price = data.get("price", 0)
	var lang = TranslationManager.current_language

	_confirm_overlay = ColorRect.new()
	_confirm_overlay.color = Color(0, 0, 0, 0.6)
	_confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_confirm_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_confirm_overlay)

	_confirm_panel = Panel.new()
	_confirm_panel.size = Vector2(588, 448)
	_confirm_panel.position = Vector2(
		(get_viewport_rect().size.x - 588) / 2,
		(get_viewport_rect().size.y - 448) / 2
	)
	add_child(_confirm_panel)
	_apply_rounded_panel(_confirm_panel)

	var title = Label.new()
	title.text = TranslationManager.t("confirm_buy") % TranslationManager.t("item_" + item_id)
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
	title.add_theme_font_size_override("font_size", 31)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(532, 45)
	title.position = Vector2(28, 17)
	_confirm_panel.add_child(title)

	var price_label = Label.new()
	price_label.text = TranslationManager.t("price") + " : " + str(price)
	price_label.add_theme_color_override("font_color", Color(1, 1, 1))
	price_label.add_theme_font_size_override("font_size", 22)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.size = Vector2(532, 28)
	price_label.position = Vector2(28, 73)
	_confirm_panel.add_child(price_label)

	var icon_y := 112
	var icon_size := 118
	var eq_w := 78
	var gap := 17
	var total_row_w := icon_size + gap + eq_w + gap + icon_size
	var row_x := int((588 - total_row_w) / 2.0)

	var item_icon = TextureRect.new()
	item_icon.texture = ITEM_TEX[item_id][lang]
	item_icon.ignore_texture_size = true
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	item_icon.size = Vector2(icon_size, icon_size)
	item_icon.position = Vector2(row_x, icon_y)
	_confirm_panel.add_child(item_icon)

	var eq_label = Label.new()
	eq_label.text = "= 3 x"
	eq_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	eq_label.add_theme_font_size_override("font_size", 28)
	eq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	eq_label.size = Vector2(78, 42)
	eq_label.position = Vector2(row_x + icon_size + gap, icon_y + (icon_size - 42) / 2)
	_confirm_panel.add_child(eq_label)

	var skill_icon = TextureRect.new()
	skill_icon.texture = SKILL_TEX[item_id]
	skill_icon.ignore_texture_size = true
	skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	skill_icon.size = Vector2(icon_size, icon_size)
	skill_icon.position = Vector2(row_x + icon_size + gap + eq_w + gap, icon_y)
	_confirm_panel.add_child(skill_icon)

	var prompt = Label.new()
	prompt.text = TranslationManager.t("want_to_buy")
	prompt.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	prompt.add_theme_font_size_override("font_size", 22)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.size = Vector2(532, 34)
	prompt.position = Vector2(28, icon_y + icon_size + 14)
	_confirm_panel.add_child(prompt)

	_confirm_no_coins_label = Label.new()
	_confirm_no_coins_label.text = TranslationManager.t("coins_not_enough")
	_confirm_no_coins_label.add_theme_color_override("font_color", Color(1, 1, 0))
	_confirm_no_coins_label.add_theme_font_size_override("font_size", 20)
	_confirm_no_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_no_coins_label.size = Vector2(532, 25)
	_confirm_no_coins_label.position = Vector2(28, icon_y + icon_size + 50)
	_confirm_panel.add_child(_confirm_no_coins_label)

	var has_coins = SaveManager.total_coins >= price
	_confirm_no_coins_label.visible = not has_coins

	var btn_y := icon_y + icon_size + 84
	var btn_w := 182
	var btn_h := 70
	var btn_gap := 34
	var total_btn_w := btn_w + btn_gap + btn_w
	var btn_start_x := int((588 - total_btn_w) / 2.0)

	_confirm_ok_btn = TextureButton.new()
	var ok_tex = ButtonBuilder.build_button_texture(TranslationManager.t("ok"), "res://assets/fonts/green/", Vector2i(22, 28), EMPTY_SHORT)
	_confirm_ok_btn.texture_normal = ok_tex
	_confirm_ok_btn.texture_pressed = ButtonBuilder.darken_texture(ok_tex)
	_confirm_ok_btn.texture_disabled = ButtonBuilder.darken_texture(ok_tex)
	_confirm_ok_btn.ignore_texture_size = true
	_confirm_ok_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_confirm_ok_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	_confirm_ok_btn.position = Vector2(btn_start_x, btn_y)
	_confirm_ok_btn.disabled = not has_coins
	_confirm_ok_btn.pressed.connect(_on_confirm_ok.bind(item_id))
	_confirm_ok_btn.pressed.connect(ClickPlayer.play)
	_confirm_panel.add_child(_confirm_ok_btn)

	var cancel_btn = TextureButton.new()
	var cancel_tex = ButtonBuilder.build_button_texture(TranslationManager.t("cancel"), "res://assets/fonts/pink/", Vector2i(22, 28), EMPTY_SHORT)
	cancel_btn.texture_normal = cancel_tex
	cancel_btn.texture_pressed = ButtonBuilder.darken_texture(cancel_tex)
	cancel_btn.ignore_texture_size = true
	cancel_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	cancel_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	cancel_btn.position = Vector2(btn_start_x + btn_w + btn_gap, btn_y)
	cancel_btn.pressed.connect(_hide_confirm_popup)
	cancel_btn.pressed.connect(ClickPlayer.play)
	_confirm_panel.add_child(cancel_btn)


func _on_confirm_ok(item_id: String) -> void:
	var data = ItemData.get_item(item_id)
	if SaveManager.spend_coins(data.get("price", 0)):
		SaveManager.add_item(item_id, 3)
		_update_header()
		_update_shop_amounts()
	_hide_confirm_popup()


func _hide_confirm_popup() -> void:
	_confirm_item_id = ""
	_confirm_ok_btn = null
	_confirm_no_coins_label = null
	if _confirm_panel:
		_confirm_panel.queue_free()
		_confirm_panel = null
	if _confirm_overlay:
		_confirm_overlay.queue_free()
		_confirm_overlay = null


func _apply_rounded_panel(panel: Panel) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 1)
	style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", style)


func _update_shop_amounts() -> void:
	for id in item_ids:
		if id in item_buttons:
			var btn = item_buttons[id]
			var label = btn.get_node("AmountLabel") as Label
			if label:
				label.text = str(SaveManager.get_item_count(id))

func _on_level_selected(level: int) -> void:
	if SaveManager.life_level <= 0:
		var overlay = SaveManager.show_empty_life_popup(self)
		await overlay.tree_exited
		return
	var overlay = _show_level_confirm_popup(level)
	await overlay.tree_exited

func _show_level_confirm_popup(level: int) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchor_left = 0
	overlay.anchor_top = 0
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var panel = Panel.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -238
	panel.offset_top = -154
	panel.offset_right = 238
	panel.offset_bottom = 154
	overlay.add_child(panel)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	panel_style.set_corner_radius_all(12)
	panel.add_theme_stylebox_override("panel", panel_style)

	var title = Label.new()
	title.text = TranslationManager.t("play_level") % level
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 25)
	title.size = Vector2(392, 39)
	title.position = Vector2(42, 25)
	panel.add_child(title)

	var btn_w := 350
	var btn_h := 73
	var btn_x := 63

	var play_tex = ButtonBuilder.build_button_texture(TranslationManager.t("play"), "res://assets/fonts/green/", Vector2i(22, 28), EMPTY_LONG)
	var play_btn = TextureButton.new()
	play_btn.texture_normal = play_tex
	play_btn.texture_pressed = ButtonBuilder.darken_texture(play_tex)
	play_btn.ignore_texture_size = true
	play_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	play_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	play_btn.position = Vector2(btn_x, 100)
	play_btn.pressed.connect(func():
		overlay.queue_free()
		SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": level}))
	play_btn.pressed.connect(ClickPlayer.play)
	panel.add_child(play_btn)

	var cancel_tex = ButtonBuilder.build_button_texture(TranslationManager.t("cancel"), "res://assets/fonts/pink/", Vector2i(22, 28), CANCEL_BG)
	var cancel_btn = TextureButton.new()
	cancel_btn.texture_normal = cancel_tex
	cancel_btn.texture_pressed = ButtonBuilder.darken_texture(cancel_tex)
	cancel_btn.ignore_texture_size = true
	cancel_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	cancel_btn.custom_minimum_size = Vector2(btn_w, btn_h)
	cancel_btn.position = Vector2(btn_x, 190)
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	cancel_btn.pressed.connect(ClickPlayer.play)
	panel.add_child(cancel_btn)

	return overlay

func _on_main_menu_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")

# ── Coin Shop (Placeholder) ──────────────────────────────────────────

var _coin_btn: TextureButton
var _coin_popup_overlay: ColorRect
var _coin_popup_panel: Panel
var _coin_popup_options: Array = []

var _instant_life_btn: TextureButton
var _ghost_catalog_btn: TextureButton

var _confirm_overlay: ColorRect
var _confirm_panel: Panel
var _confirm_item_id: String
var _confirm_ok_btn: TextureButton
var _confirm_no_coins_label: Label

func _setup_instant_life_btn() -> void:
	_instant_life_btn = TextureButton.new()
	_instant_life_btn.name = "InstantLifeBtn"
	_instant_life_btn.ignore_texture_size = true
	_instant_life_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_instant_life_btn.custom_minimum_size = Vector2(100, 100)
	_instant_life_btn.position = Vector2(25, 80)
	_update_life_btn_texture()
	_update_life_btn_state()
	_instant_life_btn.pressed.connect(_on_instant_life_pressed)
	_instant_life_btn.pressed.connect(ClickPlayer.play)
	add_child(_instant_life_btn)

func _setup_coin_shop() -> void:
	_coin_btn = TextureButton.new()
	_coin_btn.name = "BuyCoinsButton"
	_coin_btn.ignore_texture_size = true
	_coin_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_coin_btn.custom_minimum_size = Vector2(100, 100)
	_coin_btn.position = Vector2(150, 80)
	_update_coin_btn_texture()
	add_child(_coin_btn)
	_coin_btn.pressed.connect(_show_coin_popup)
	_coin_btn.pressed.connect(ClickPlayer.play)

func _setup_ghost_catalog_btn() -> void:
	_ghost_catalog_btn = TextureButton.new()
	_ghost_catalog_btn.name = "GhostCatalogBtn"
	_ghost_catalog_btn.ignore_texture_size = true
	_ghost_catalog_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_ghost_catalog_btn.custom_minimum_size = Vector2(93, 93)
	_ghost_catalog_btn.position = Vector2(270, 81)
	_ghost_catalog_btn.texture_normal = GHOSTS_CATALOG_BTN
	_ghost_catalog_btn.texture_pressed = ButtonBuilder.darken_texture(GHOSTS_CATALOG_BTN)
	_ghost_catalog_btn.pressed.connect(_on_ghost_catalog_pressed)
	_ghost_catalog_btn.pressed.connect(ClickPlayer.play)
	add_child(_ghost_catalog_btn)
	_start_breath_effect(_ghost_catalog_btn)


func _on_ghost_catalog_pressed() -> void:
	GhostCatalog.open(self)


func _update_life_btn_texture() -> void:
	if not _instant_life_btn:
		return
	var tex = INSTANT_LIFE_EN if TranslationManager.current_language == "en" else INSTANT_LIFE_ID
	_instant_life_btn.texture_normal = tex
	_instant_life_btn.texture_pressed = ButtonBuilder.darken_texture(tex)

func _update_life_btn_state() -> void:
	if not _instant_life_btn:
		return
	var is_full = SaveManager.life_level >= 3
	_instant_life_btn.disabled = is_full
	_instant_life_btn.modulate = Color(0.5, 0.5, 0.5, 0.7) if is_full else Color.WHITE

func _update_coin_btn_texture() -> void:
	if not _coin_btn:
		return
	var tex = INSTANT_COINS_EN if TranslationManager.current_language == "en" else INSTANT_COINS_ID
	_coin_btn.texture_normal = tex
	_coin_btn.texture_pressed = ButtonBuilder.darken_texture(tex)

func _show_coin_popup() -> void:
	if _coin_popup_panel:
		return
	_coin_popup_overlay = ColorRect.new()
	_coin_popup_overlay.color = Color(0, 0, 0, 0.6)
	_coin_popup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_coin_popup_overlay.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_coin_popup_overlay)

	_coin_popup_panel = Panel.new()
	_coin_popup_panel.size = Vector2(448, 504)
	_coin_popup_panel.position = Vector2(
		(get_viewport_rect().size.x - 448) / 2,
		(get_viewport_rect().size.y - 504) / 2
	)
	_coin_popup_panel.rotation = 0.0
	add_child(_coin_popup_panel)
	_apply_rounded_panel(_coin_popup_panel)

	var title = Label.new()
	title.text = TranslationManager.t("instant_coins_title")
	title.add_theme_color_override("font_color", Color(0.8, 0.6, 0.1))
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(392, 42)
	title.position = Vector2(14, 14)
	_coin_popup_panel.add_child(title)

	var iap_status = Label.new()
	iap_status.name = "IapStatus"
	iap_status.anchor_left = 0.0
	iap_status.anchor_right = 1.0
	iap_status.offset_top = 311.0
	iap_status.offset_bottom = 336.0
	iap_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	iap_status.add_theme_color_override("font_color", Color(1, 0.85, 0, 1))
	iap_status.add_theme_font_size_override("font_size", 11)
	iap_status.text = ""
	_coin_popup_panel.add_child(iap_status)

	_build_coin_options(iap_status)

	var close_btn = TextureButton.new()
	var close_tex = ButtonBuilder.build_button_texture(TranslationManager.t("cancel"), "res://assets/fonts/pink/", Vector2i(22, 28), CANCEL_BG)
	close_btn.texture_normal = close_tex
	close_btn.texture_pressed = ButtonBuilder.darken_texture(close_tex)
	close_btn.ignore_texture_size = true
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.custom_minimum_size = Vector2(196, 62)
	close_btn.position = Vector2(126, 364)
	close_btn.pressed.connect(_hide_coin_popup)
	close_btn.pressed.connect(ClickPlayer.play)
	_coin_popup_panel.add_child(close_btn)

func _hide_coin_popup() -> void:
	_coin_popup_options.clear()
	if _coin_popup_panel:
		_coin_popup_panel.queue_free()
		_coin_popup_panel = null
	if _coin_popup_overlay:
		_coin_popup_overlay.queue_free()
		_coin_popup_overlay = null

func _build_coin_options(iap_status: Label) -> void:
	var sku_keys := ["instant_coins_1", "instant_coins_2", "instant_coins_3"]
	var tex_paths := [
		preload("res://assets/buttons/coin_package_1.png"),
		preload("res://assets/buttons/coin_package_2.png"),
		preload("res://assets/buttons/coin_package_3.png"),
	]
	var price_labels := ["$1", "$2", "$3"]
	var y_start := 70
	var btn_h := 70
	var gap := 17

	for i in sku_keys.size():
		var sku_key = sku_keys[i]
		var sku = IAPConfig.get_sku(sku_key)
		var reward = IAPConfig.get_coin_reward(sku)
		var y = y_start + i * (btn_h + gap)

		var btn = TextureButton.new()
		btn.name = "CoinOption" + str(i)
		btn.texture_normal = tex_paths[i]
		btn.texture_pressed = ButtonBuilder.darken_texture(tex_paths[i])
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(364, btn_h)
		btn.position = Vector2(42, y)
		btn.pressed.connect(_on_coin_option_pressed.bind(sku_key, btn, iap_status))
		btn.pressed.connect(ClickPlayer.play)
		if not IAPManager.is_products_ready():
			btn.disabled = true
		_coin_popup_panel.add_child(btn)

		var price = Label.new()
		price.text = price_labels[i]
		price.add_theme_color_override("font_color", Color(0.9, 0.8, 0.6))
		price.add_theme_font_size_override("font_size", 28)
		price.size = Vector2(35, btn_h)
		price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		price.position = Vector2(3, y)
		_coin_popup_panel.add_child(price)
		_coin_popup_options.append(btn)

func _on_coin_option_pressed(sku_key: String, btn: TextureButton, iap_status: Label) -> void:
	btn.disabled = true
	var sku = IAPConfig.get_sku(sku_key)
	var result = IAPManager.purchase(sku)
	match result:
		IAPManager.PurchaseResult.OK:
			iap_status.text = TranslationManager.t("iap_purchasing")
		IAPManager.PurchaseResult.NOT_INITIALIZED:
			iap_status.text = TranslationManager.t("iap_not_ready")
			btn.disabled = false
			return
		IAPManager.PurchaseResult.UNAVAILABLE:
			iap_status.text = TranslationManager.t("iap_unavailable")
			btn.disabled = false
			return
		IAPManager.PurchaseResult.NO_SKU:
			iap_status.text = TranslationManager.t("iap_unavailable")
			btn.disabled = false
			return
	IAPManager.purchase_successful.connect(_on_coin_purchase_success.bind(sku_key, iap_status), CONNECT_ONE_SHOT)
	IAPManager.purchase_failed.connect(_on_coin_purchase_failed.bind(btn, iap_status), CONNECT_ONE_SHOT)

func _on_coin_purchase_success(sku: String, token: String, expected_sku_key: String, iap_status: Label) -> void:
	if sku != IAPConfig.get_sku(expected_sku_key):
		return
	var reward = IAPConfig.get_coin_reward(sku)
	if reward <= 0:
		return
	SaveManager.add_coins(reward)
	SaveManager.mark_purchase_processed(token, sku)
	IAPManager.finalize_purchase(token, sku)
	_update_header()
	iap_status.text = ""
	_hide_coin_popup()

func _on_coin_purchase_failed(_sku: String, btn: TextureButton, iap_status: Label) -> void:
	if is_instance_valid(iap_status):
		iap_status.text = TranslationManager.t("iap_purchase_failed")
	if is_instance_valid(btn):
		btn.disabled = false

func _on_purchases_restored() -> void:
	for item in IAPManager.get_pending_restorations():
		var sku: String = item["sku"]
		var token: String = item["token"]
		if SaveManager.is_purchase_processed(token):
			continue
		var reward = IAPConfig.get_coin_reward(sku)
		if reward <= 0:
			continue
		SaveManager.add_coins(reward)
		SaveManager.mark_purchase_processed(token, sku)
		IAPManager.finalize_purchase(token, sku)
	_update_header()
	_hide_coin_popup()

func _on_billing_ready() -> void:
	# Re-enable the coin options now that products are queryable.
	# (If the popup is open, the user gets feedback; if not, this is a no-op.)
	if not _coin_popup_panel:
		return
	for b in _coin_popup_options:
		if is_instance_valid(b):
			b.disabled = false

# ── Instant Life Popup ────────────────────────────────────────────────

func _on_instant_life_pressed() -> void:
	_show_instant_life_popup()

func _show_instant_life_popup() -> void:
	var overlay = ColorRect.new()
	overlay.name = "InstantOverlay"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	var popup = Control.new()
	popup.name = "InstantPopup"
	popup.anchor_left = 0.5
	popup.anchor_top = 0.5
	popup.anchor_right = 0.5
	popup.anchor_bottom = 0.5
	popup.offset_left = -182.0
	popup.offset_top = -210.0
	popup.offset_right = 182.0
	popup.offset_bottom = 210.0
	add_child(popup)

	var bg = Panel.new()
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	bg.add_theme_stylebox_override("panel", style)
	popup.add_child(bg)

	var label = Label.new()
	label.anchor_left = 0.0
	label.anchor_right = 1.0
	label.offset_top = 42.0
	label.offset_bottom = 84.0
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	label.add_theme_font_size_override("font_size", 22)
	label.text = TranslationManager.t("instant_life_title")
	popup.add_child(label)

	var desc_label = Label.new()
	desc_label.anchor_left = 0.0
	desc_label.anchor_right = 1.0
	desc_label.offset_top = 91.0
	desc_label.offset_bottom = 126.0
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	desc_label.add_theme_font_size_override("font_size", 17)
	desc_label.text = TranslationManager.t("instant_life_desc")
	popup.add_child(desc_label)

	var t = TranslationManager
	var status_label = Label.new()
	status_label.anchor_left = 0.0
	status_label.anchor_right = 1.0
	status_label.offset_top = 130.0
	status_label.offset_bottom = 158.0
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(1, 0.85, 0, 1))
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.text = ""
	popup.add_child(status_label)

	var watch_btn = TextureButton.new()
	watch_btn.ignore_texture_size = true
	watch_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	watch_btn.position = Vector2(91, 161)
	watch_btn.size = Vector2(182, 56)
	watch_btn.texture_normal = WATCH_ADS_EN if t.current_language == "en" else WATCH_ADS_ID
	watch_btn.pressed.connect(_on_watch_life_ad_pressed.bind(watch_btn, status_label, overlay, popup))
	watch_btn.pressed.connect(ClickPlayer.play)
	popup.add_child(watch_btn)

	var cancel_btn = TextureButton.new()
	cancel_btn.ignore_texture_size = true
	cancel_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	cancel_btn.position = Vector2(91, 259)
	cancel_btn.size = Vector2(182, 56)
	cancel_btn.texture_normal = ButtonBuilder.build_button_texture(TranslationManager.t("cancel"), "res://assets/fonts/pink/", Vector2i(22, 28), CANCEL_BG)
	cancel_btn.pressed.connect(_close_instant_life_popup.bind(overlay, popup))
	cancel_btn.pressed.connect(ClickPlayer.play)
	popup.add_child(cancel_btn)

func _close_instant_life_popup(overlay: ColorRect, popup: Control) -> void:
	if is_instance_valid(popup):
		popup.queue_free()
	if is_instance_valid(overlay):
		overlay.queue_free()

func _on_watch_life_ad_pressed(watch_btn: TextureButton, status_label: Label, overlay: ColorRect, popup: Control) -> void:
	AdsManager.life_reward_earned.connect(_on_life_reward_earned.bind(overlay, popup), CONNECT_ONE_SHOT)
	AdsManager.life_reward_failed.connect(_on_life_reward_failed.bind(watch_btn, status_label), CONNECT_ONE_SHOT)
	var result = AdsManager.start_life_reward_flow(status_label)
	match result:
		AdsManager.StartResult.SDK_READY:
			if AdsManager.is_flow_active():
				watch_btn.disabled = true
				watch_btn.modulate = Color(0.5, 0.5, 0.5, 0.7)
		AdsManager.StartResult.SDK_NOT_READY:
			# Keep the button usable. AdsManager auto-starts the flow when the
			# SDK initializes, and fails the pending flow if init fails — the
			# failed handler re-enables the button either way.
			status_label.text = TranslationManager.t("life_ad_loading")
		AdsManager.StartResult.FLOW_ALREADY_ACTIVE:
			pass

func _on_life_reward_earned(overlay: ColorRect, popup: Control) -> void:
	if not is_instance_valid(overlay) or not is_instance_valid(popup):
		return
	SaveManager.life_level = clampi(SaveManager.life_level + 1, 0, 3)
	SaveManager.life_changed.emit(SaveManager.life_level)
	SaveManager.save_game()
	_close_instant_life_popup(overlay, popup)

func _on_life_reward_failed(watch_btn: TextureButton, status_label: Label) -> void:
	if is_instance_valid(status_label):
		status_label.text = TranslationManager.t("life_ad_failed")
	if is_instance_valid(watch_btn):
		watch_btn.disabled = false
		watch_btn.modulate = Color.WHITE

func _format_coin(amount: int) -> String:
	var s = str(amount)
	var result = ""
	var cnt = 0
	for i in range(s.length() - 1, -1, -1):
		if cnt > 0 and cnt % 3 == 0:
			result = "." + result
		result = s[i] + result
		cnt += 1
	return result
