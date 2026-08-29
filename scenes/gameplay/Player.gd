extends CharacterBody2D

const SPEED := 100.0
const HALF_SPEED := 50.0
const STAMINA_MAX := 100.0
const STAMINA_DRAIN := 5.0
const STAMINA_REGEN := 3.0
const SPRITE_SIZE := 28.0
const ANIM_FRAME_TIME := 0.15
const BALM_FRAME_TIME := 0.15

var stamina: float = STAMINA_MAX
var current_speed: float = SPEED
var input_dir := Vector2.ZERO
var dpad_dir := Vector2.ZERO
var is_in_poskamling := false
var is_senter_active := false
var is_balm_active := false

var facing_dir := Vector2.DOWN
var sprite: Sprite2D
var textures := {}
var walk_frames := {}
var normal_textures := {}
var normal_walk_frames := {}
var flashlight_textures := {}
var flashlight_walk_frames := {}
var balm_frames := []
var frame_indices := {}
var anim_timer := 0.0
var _balm_sprite: Sprite2D
var _balm_frame := 0
var _balm_timer := 0.0
var _balm_blink_timer := 0.0
var _balm_blinking := false
var _exclamation: Label
var _exclamation_tween: Tween


func _init() -> void:
	collision_layer = 4
	collision_mask = 1
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision.shape = shape
	add_child(collision)

	var cam = Camera2D.new()
	cam.name = "Camera2D"
	cam.zoom = Vector2(2.0, 2.0)
	add_child(cam)

	_exclamation = Label.new()
	_exclamation.text = "!"
	_exclamation.add_theme_color_override("font_color", Color(1, 0, 0))
	_exclamation.add_theme_font_size_override("font_size", 16)
	_exclamation.position = Vector2(-4, -32)
	_exclamation.hide()
	add_child(_exclamation)


func init_textures(data: Dictionary) -> void:
	normal_textures = data.get("normal_textures", {})
	normal_walk_frames = data.get("normal_walk_frames", {})
	flashlight_textures = data.get("flashlight_textures", {})
	flashlight_walk_frames = data.get("flashlight_walk_frames", {})
	balm_frames = data.get("balm_frames", [])
	textures = normal_textures
	walk_frames = normal_walk_frames
	frame_indices["right"] = 0
	frame_indices["down"] = 0
	frame_indices["up"] = 0
	frame_indices["left"] = 0
	sprite = Sprite2D.new()
	sprite.name = "MainSprite"
	sprite.centered = true
	if normal_textures.has("down"):
		_update_sprite(normal_textures["down"])
	add_child(sprite)


func _ready() -> void:
	var cam = find_child("Camera2D") as Camera2D
	if cam:
		cam.make_current()


func set_senter_active(active: bool) -> void:
	is_senter_active = active
	if active:
		textures = flashlight_textures
		walk_frames = flashlight_walk_frames
	else:
		textures = normal_textures
		walk_frames = normal_walk_frames
	_refresh_sprite()


func set_balm_active(active: bool) -> void:
	is_balm_active = active
	if active:
		if not _balm_sprite:
			_balm_sprite = Sprite2D.new()
			_balm_sprite.name = "BalmEffect"
			_balm_sprite.centered = true
			if balm_frames.size() > 0:
				_balm_sprite.texture = balm_frames[0]
			_balm_sprite.scale = Vector2(0.55, 0.55)
			_balm_sprite.position = Vector2(0, -20)
			add_child(_balm_sprite)
		_balm_sprite.show()
		_balm_frame = 0
		_balm_timer = 0.0
	else:
		if _balm_sprite:
			_balm_sprite.hide()
			_balm_blinking = false


func _refresh_sprite() -> void:
	if abs(facing_dir.x) > abs(facing_dir.y):
		_update_sprite(textures["right"] if facing_dir.x > 0 else textures["left"])
	else:
		_update_sprite(textures["down"] if facing_dir.y > 0 else textures["up"])


func _update_sprite(tex: Texture2D) -> void:
	sprite.texture = tex
	var tex_size = tex.get_size()
	var scale_factor = minf(SPRITE_SIZE / tex_size.x, SPRITE_SIZE / tex_size.y)
	sprite.scale = Vector2(scale_factor, scale_factor)


func _physics_process(delta: float) -> void:
	var keyboard_dir = Vector2(
		Input.get_axis("ui_left", "ui_right"),
		Input.get_axis("ui_up", "ui_down")
	).normalized()
	
	if keyboard_dir.length() > 0:
		input_dir = keyboard_dir
	elif dpad_dir.length() > 0:
		input_dir = dpad_dir
	else:
		input_dir = Vector2.ZERO

	if input_dir.length() > 0:
		facing_dir = input_dir
		if abs(facing_dir.x) > abs(facing_dir.y):
			if facing_dir.x > 0:
				anim_timer += delta
				if anim_timer >= ANIM_FRAME_TIME:
					anim_timer = 0.0
					frame_indices["right"] = (frame_indices["right"] + 1) % walk_frames["right"].size()
				_update_sprite(walk_frames["right"][frame_indices["right"]])
			else:
				anim_timer += delta
				if anim_timer >= ANIM_FRAME_TIME:
					anim_timer = 0.0
					frame_indices["left"] = (frame_indices["left"] + 1) % walk_frames["left"].size()
				_update_sprite(walk_frames["left"][frame_indices["left"]])
		else:
			if facing_dir.y > 0:
				anim_timer += delta
				if anim_timer >= ANIM_FRAME_TIME:
					anim_timer = 0.0
					frame_indices["down"] = (frame_indices["down"] + 1) % walk_frames["down"].size()
				_update_sprite(walk_frames["down"][frame_indices["down"]])
			else:
				anim_timer += delta
				if anim_timer >= ANIM_FRAME_TIME:
					anim_timer = 0.0
					frame_indices["up"] = (frame_indices["up"] + 1) % walk_frames["up"].size()
				_update_sprite(walk_frames["up"][frame_indices["up"]])
		velocity = input_dir * current_speed
	else:
		velocity = Vector2.ZERO
		if abs(facing_dir.x) > abs(facing_dir.y):
			if facing_dir.x > 0:
				_update_sprite(textures["right"])
			else:
				_update_sprite(textures["left"])
		else:
			if facing_dir.y > 0:
				_update_sprite(textures["down"])
			else:
				_update_sprite(textures["up"])
		frame_indices["right"] = 0
		frame_indices["down"] = 0
		frame_indices["up"] = 0
		frame_indices["left"] = 0
		anim_timer = 0.0
	
	var old_pos = global_position
	move_and_slide()
	var actually_moved = global_position != old_pos
	
	if actually_moved:
		stamina = maxf(0, stamina - STAMINA_DRAIN * delta)
		current_speed = HALF_SPEED if stamina <= 0 else SPEED
	elif input_dir == Vector2.ZERO:
		stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
		current_speed = SPEED


func set_movement_dir(dir: Vector2) -> void:
	dpad_dir = dir.normalized()


func enter_poskamling() -> void:
	is_in_poskamling = true


func exit_poskamling() -> void:
	is_in_poskamling = false


func is_stamina_empty() -> bool:
	return stamina <= 0


func get_stamina_percent() -> float:
	return stamina / STAMINA_MAX


func restore_stamina(percent: float) -> void:
	stamina = minf(STAMINA_MAX, stamina + STAMINA_MAX * percent)


func show_exclamation() -> void:
	if _exclamation_tween and _exclamation_tween.is_running():
		_exclamation_tween.kill()
	_exclamation.show()
	_exclamation_tween = create_tween()
	_exclamation_tween.tween_interval(2.0)
	_exclamation_tween.tween_callback(func(): _exclamation.hide())


func set_balm_blinking(blinking: bool) -> void:
	_balm_blinking = blinking
	_balm_blink_timer = 0.0
	if not blinking and _balm_sprite:
		_balm_sprite.show()


func _process(delta: float) -> void:
	if is_balm_active and _balm_sprite:
		if _balm_blinking:
			_balm_blink_timer += delta
			if _balm_blink_timer >= BALM_FRAME_TIME:
				_balm_sprite.visible = not _balm_sprite.visible
				_balm_blink_timer = 0.0
		else:
			_balm_sprite.show()
		_balm_timer += delta
		if _balm_timer >= BALM_FRAME_TIME:
			_balm_frame = (_balm_frame + 1) % balm_frames.size()
			_balm_sprite.texture = balm_frames[_balm_frame]
			_balm_timer = 0.0
