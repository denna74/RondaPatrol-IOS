extends CharacterBody2D

enum State { PATROL, CHASE, FLEE }

const SPEED := 40.0
const PATROL_SPEED := 20.0
const FLEE_SPEED := 55.0
const ACTIVE_DURATION := 12.0
const DETECTION_RADIUS := 140.0

var is_active := false
var active_timer := 0.0
var state: State = State.PATROL
var patrol_direction := Vector2.RIGHT
var patrol_timer := 0.0
var target_player: Node2D = null
var has_stolen := false
var spawn_chance: float = 0.1
var current_level: int = 1
var map_bounds: Rect2 = Rect2(0, 0, 640, 640)
var grid: Array = []
var grid_cols: int = 0
var grid_rows: int = 0
var _sprite: Sprite2D
var _exclamation: Label
var _caught_sfx: AudioStreamPlayer


func _init() -> void:
	collision_layer = 8
	collision_mask = 3
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision.shape = shape
	add_child(collision)

	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/ghosts/maling.png")
	_sprite.scale = Vector2(0.22, 0.22)
	add_child(_sprite)

	_exclamation = Label.new()
	_exclamation.text = "!"
	_exclamation.add_theme_color_override("font_color", Color(1, 0, 0))
	_exclamation.add_theme_font_size_override("font_size", 16)
	_exclamation.position = Vector2(-4, -32)
	_exclamation.hide()
	add_child(_exclamation)

	_caught_sfx = AudioStreamPlayer.new()
	_caught_sfx.stream = preload("res://assets/sfx/thief_caught.wav")
	_caught_sfx.bus = "Master"
	add_child(_caught_sfx)


func _ready() -> void:
	hide()
	set_process(false)
	set_physics_process(false)

func _process(delta: float) -> void:
	if not is_active:
		return
	active_timer -= delta
	if active_timer <= 0:
		_disappear()

func _physics_process(delta: float) -> void:
	if not is_active or not target_player:
		return

	if target_player.is_in_poskamling:
		state = State.PATROL

	var dist = global_position.distance_to(target_player.global_position)

	if target_player.is_senter_active and dist < DETECTION_RADIUS:
		state = State.FLEE
	elif state == State.FLEE:
		if not target_player.is_senter_active or dist > DETECTION_RADIUS * 1.5:
			state = State.PATROL

	if state != State.FLEE:
		if state == State.PATROL and dist < DETECTION_RADIUS and not target_player.is_in_poskamling:
			state = State.CHASE
		elif state == State.CHASE:
			if dist > DETECTION_RADIUS * 1.5:
				state = State.PATROL

	match state:
		State.PATROL:
			patrol_timer -= delta
			if patrol_timer <= 0 or is_on_wall():
				patrol_direction = _random_direction()
				patrol_timer = randf_range(1.0, 3.0)
			velocity = patrol_direction * PATROL_SPEED
		State.CHASE:
			var dir = (target_player.global_position - global_position).normalized()
			velocity = dir * SPEED
		State.FLEE:
			var dir = (global_position - target_player.global_position).normalized()
			velocity = dir * FLEE_SPEED

	move_and_slide()

func _random_direction() -> Vector2:
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	return dirs[randi() % dirs.size()]

func try_spawn(player: Node2D, level: int, bounds: Rect2 = Rect2(0, 0, 640, 640), map_grid: Array = [], cols: int = 0, rows: int = 0) -> void:
	current_level = level
	spawn_chance = LevelData.get_thief_chance(level)
	if randf() < spawn_chance:
		map_bounds = bounds
		grid = map_grid
		grid_cols = cols
		grid_rows = rows
		_appear(player)

func _appear(player: Node2D) -> void:
	target_player = player
	if grid.is_empty():
		var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
		global_position = player.global_position + offset
	else:
		var ts = MapGenerator.TILE_SIZE
		for attempt in range(50):
			var offset = Vector2(randf_range(-100, 100), randf_range(-100, 100))
			var spawn_pos = player.global_position + offset
			spawn_pos.x = clampf(spawn_pos.x, map_bounds.position.x, map_bounds.position.x + map_bounds.size.x)
			spawn_pos.y = clampf(spawn_pos.y, map_bounds.position.y, map_bounds.position.y + map_bounds.size.y)
			var gx = int(spawn_pos.x / ts)
			var gy = int(spawn_pos.y / ts)
			if gx >= 0 and gx < grid_cols and gy >= 0 and gy < grid_rows:
				if grid[gx][gy] == 0:
					global_position = Vector2(gx * ts + ts / 2, gy * ts + ts / 2)
					break
			if attempt == 49:
				global_position = _find_nearest_walkable(spawn_pos, ts)
				var fgx = int(global_position.x / ts)
				var fgy = int(global_position.y / ts)
				global_position = Vector2(fgx * ts + ts / 2, fgy * ts + ts / 2)
	is_active = true
	state = State.PATROL
	patrol_direction = _random_direction()
	patrol_timer = randf_range(1.0, 3.0)
	active_timer = ACTIVE_DURATION
	has_stolen = false
	show()
	set_process(true)
	set_physics_process(true)

func _disappear() -> void:
	is_active = false
	hide()
	set_process(false)
	set_physics_process(false)

func _find_nearest_walkable(world_pos: Vector2, ts: int) -> Vector2:
	var cx = int(world_pos.x / ts)
	var cy = int(world_pos.y / ts)
	for r in range(1, maxi(grid_cols, grid_rows)):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				var nx = cx + dx
				var ny = cy + dy
				if nx >= 0 and nx < grid_cols and ny >= 0 and ny < grid_rows:
					if grid[nx][ny] == 0:
						return Vector2(nx * ts + ts / 2, ny * ts + ts / 2)
		for dy in range(-r, r + 1):
			for dx in [-r, r]:
				var nx = cx + dx
				var ny = cy + dy
				if nx >= 0 and nx < grid_cols and ny >= 0 and ny < grid_rows:
					if grid[nx][ny] == 0:
						return Vector2(nx * ts + ts / 2, ny * ts + ts / 2)
	return world_pos

func try_steal() -> void:
	if has_stolen:
		return

	var inv = SaveManager.inventory
	if inv.size() > 0:
		var keys = inv.keys()
		var stolen_item = keys[randi() % keys.size()]
		SaveManager.inventory[stolen_item] = SaveManager.inventory.get(stolen_item, 0) - 1
		if SaveManager.inventory[stolen_item] <= 0:
			SaveManager.inventory.erase(stolen_item)
		SaveManager.save_game()
		stolen.emit(stolen_item, 0)
	elif SaveManager.total_coins > 0:
		var coin_range = LevelData.get_thief_coin_range(current_level)
		var min_coins = coin_range[0]
		var max_coins = coin_range[1]
		var stolen_coins: int
		if SaveManager.total_coins < 100:
			stolen_coins = min_coins
		elif SaveManager.total_coins > 500:
			stolen_coins = max_coins
		else:
			stolen_coins = int(lerp(float(min_coins), float(max_coins), (SaveManager.total_coins - 100.0) / 400.0))
		stolen_coins = mini(stolen_coins, SaveManager.total_coins)
		SaveManager.total_coins -= stolen_coins
		SaveManager.save_game()
		stolen.emit("", stolen_coins)
	else:
		stolen.emit("", 0)

	has_stolen = true
	_disappear()

signal stolen(item_name: String, amount: int)
signal caught_sfx_finished

func on_senter_hit() -> void:
	has_stolen = true
	_exclamation.show()
	_caught_sfx.play()
	await _caught_sfx.finished
	caught_sfx_finished.emit()
	await get_tree().create_timer(0.5).timeout
	_exclamation.hide()
	_disappear()
