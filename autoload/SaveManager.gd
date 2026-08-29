extends Node

signal coins_changed(amount: int)
signal level_changed(level: int)
signal life_changed(new_life: int)

const SAVE_FILE := "user://ronda_patrol.save"

const EMPTY_MEDIUM := preload("res://assets/buttons/empty_medium.png")
const FONT_GREEN := "res://assets/fonts/green/"
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")

var total_coins: int = 1000:
	set(v):
		total_coins = v
		coins_changed.emit(total_coins)

var current_level: int = 1:
	set(v):
		current_level = v
		level_changed.emit(current_level)

var life_level: int = 3
var last_failure_time: int = 0
var accumulated_gameplay_sec: float = 0.0
var inventory: Dictionary = {}
var processed_purchases: Dictionary = {}
var level_stars: Dictionary = {}

func _ready() -> void:
	load_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func save_game() -> void:
	var dir = DirAccess.open("user://")
	if not dir:
		return
	var data = {
		"total_coins": total_coins,
		"current_level": current_level,
		"life_level": life_level,
		"last_failure_time": last_failure_time,
		"accumulated_gameplay_sec": accumulated_gameplay_sec,
		"inventory": inventory,
		"processed_purchases": processed_purchases,
		"level_stars": level_stars
	}
	var json_str = JSON.stringify(data)
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if not file:
		return
	file.store_line(json_str)
	file.close()

func load_game() -> void:
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if not file:
		return
	var json_str = file.get_line()
	file.close()
	var data = JSON.parse_string(json_str)
	if not data is Dictionary:
		return
	total_coins = data.get("total_coins", 1000)
	current_level = data.get("current_level", 1)
	life_level = data.get("life_level", 3)
	last_failure_time = data.get("last_failure_time", 0)
	accumulated_gameplay_sec = data.get("accumulated_gameplay_sec", 0.0)
	apply_life_recovery()
	inventory = data.get("inventory", {})
	processed_purchases = data.get("processed_purchases", {})
	level_stars = data.get("level_stars", {})
	# JSON stores dict keys as strings; convert to int keys
	var converted: Dictionary = {}
	for k in level_stars:
		converted[int(k)] = level_stars[k]
	level_stars = converted

func get_item_count(id: String) -> int:
	return inventory.get(id, 0)

func has_item(id: String) -> bool:
	return get_item_count(id) > 0

func use_item(id: String) -> void:
	if inventory.get(id, 0) > 0:
		inventory[id] -= 1
		if inventory[id] <= 0:
			inventory.erase(id)
		save_game()

func add_item(id: String, count: int = 1) -> void:
	inventory[id] = inventory.get(id, 0) + count
	save_game()

func add_coins(amount: int) -> void:
	var current = total_coins
	total_coins = current + amount
	save_game()

func spend_coins(amount: int) -> bool:
	var current = total_coins
	if current >= amount:
		total_coins = current - amount
		save_game()
		return true
	return false

func calculate_recovered_life() -> int:
	if last_failure_time == 0:
		return 0
	var now = Time.get_unix_time_from_system()
	var elapsed = now - last_failure_time - accumulated_gameplay_sec
	return max(0, int(elapsed / 3600))

func apply_life_recovery():
	var recovered = calculate_recovered_life()
	if recovered > 0:
		life_level = clampi(life_level + recovered, 0, 3)
		life_changed.emit(life_level)
		if life_level >= 3:
			last_failure_time = 0
			accumulated_gameplay_sec = 0.0

func get_seconds_until_next_life() -> int:
	if last_failure_time == 0 or life_level >= 3:
		return 0
	var now = Time.get_unix_time_from_system()
	var elapsed = now - last_failure_time - accumulated_gameplay_sec
	return max(0, 3600 - int(elapsed) % 3600)

func lose_life():
	life_level = max(0, life_level - 1)
	last_failure_time = int(Time.get_unix_time_from_system())
	accumulated_gameplay_sec = 0.0
	life_changed.emit(life_level)
	save_game()

func show_empty_life_popup(parent: Control) -> ColorRect:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.anchor_left = 0
	overlay.anchor_top = 0
	overlay.anchor_right = 1
	overlay.anchor_bottom = 1
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)

	var popup = Panel.new()
	var popup_bg := StyleBoxFlat.new()
	popup_bg.bg_color = Color(0.15, 0.15, 0.15, 0.95)
	popup_bg.set_corner_radius_all(12)
	popup.add_theme_stylebox_override("panel", popup_bg)
	popup.anchor_left = 0.5
	popup.anchor_top = 0.5
	popup.anchor_right = 0.5
	popup.anchor_bottom = 0.5
	popup.offset_left = -238
	popup.offset_top = -154
	popup.offset_right = 238
	popup.offset_bottom = 154
	overlay.add_child(popup)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 17)
	vbox.anchor_left = 0
	vbox.anchor_top = 0
	vbox.anchor_right = 1
	vbox.anchor_bottom = 1
	vbox.offset_left = 21
	vbox.offset_top = 21
	vbox.offset_right = -21
	vbox.offset_bottom = -21
	popup.add_child(vbox)

	var label1 = Label.new()
	label1.text = TranslationManager.t("empty_life_title")
	label1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label1.add_theme_font_size_override("font_size", 25)
	vbox.add_child(label1)

	var label2 = Label.new()
	label2.text = TranslationManager.t("empty_life_desc")
	label2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label2.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label2)

	var label3 = Label.new()
	label3.text = TranslationManager.t("empty_life_wait")
	label3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label3.add_theme_font_size_override("font_size", 20)
	vbox.add_child(label3)

	var time_label = Label.new()
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_color_override("font_color", Color(1, 0.9, 0.2))
	time_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(time_label)

	vbox.add_spacer(true)

	var ok_tex = ButtonBuilder.build_button_texture(TranslationManager.t("ok"), FONT_GREEN, Vector2i(22, 28), EMPTY_MEDIUM)
	var ok_btn = TextureButton.new()
	ok_btn.texture_normal = ok_tex
	ok_btn.texture_pressed = ButtonBuilder.darken_texture(ok_tex)
	ok_btn.ignore_texture_size = true
	ok_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	ok_btn.custom_minimum_size = Vector2(252, 67)
	ok_btn.pressed.connect(overlay.queue_free)
	ok_btn.pressed.connect(ClickPlayer.play)

	var btn_center = CenterContainer.new()
	btn_center.add_child(ok_btn)
	vbox.add_child(btn_center)

	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = false
	popup.add_child(timer)

	var update_time = func():
		var secs = get_seconds_until_next_life()
		var m = secs / 60
		var s = secs % 60
		time_label.text = "%02d:%02d" % [m, s]
		if secs <= 0:
			apply_life_recovery()
			if life_level >= 3:
				timer.stop()
				overlay.queue_free()

	timer.timeout.connect(update_time)
	update_time.call()
	timer.start()

	overlay.tree_exiting.connect(timer.stop)
	return overlay

var _session_start_time: int = 0

func on_gameplay_start():
	_session_start_time = int(Time.get_unix_time_from_system())

func on_gameplay_end():
	if _session_start_time > 0:
		var now = int(Time.get_unix_time_from_system())
		accumulated_gameplay_sec += now - _session_start_time
		_session_start_time = 0
		save_game()

func is_purchase_processed(token: String) -> bool:
	return processed_purchases.has(token)

func mark_purchase_processed(token: String, sku: String) -> void:
	processed_purchases[token] = sku
	save_game()


func set_level_stars(level: int, stars: int) -> void:
	var existing = level_stars.get(level, 0)
	if stars > existing:
		level_stars[level] = stars
		save_game()


func get_level_stars(level: int) -> int:
	return level_stars.get(level, 0)
