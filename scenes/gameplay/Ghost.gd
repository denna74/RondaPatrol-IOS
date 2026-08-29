extends CharacterBody2D

enum State { PATROL, CHASE, FLEE }

const PATROL_SPEED := 22.5
const CHASE_SPEED := 37.5
const FLEE_SPEED := 50.0
const DETECTION_RADIUS := 160.0
const GHOST_SPRITE_SCALE := 0.22

var state: State = State.PATROL
var target_player: Node2D = null
var patrol_direction := Vector2.RIGHT
var patrol_timer := 0.0
var ghost_index: int = 0
var ghost_name: String = ""
var pesugihan_value: int = 1
var is_exploding := false
var explode_frame := 0
var explode_timer := 0.0
var attracted_to_sajen := false
var sajen_position: Vector2
var _sprite: Sprite2D

const EXPLODE_FRAME_TIME := 0.15
const EXPLODE_SCALE := 0.15


func _init() -> void:
	collision_layer = 8
	collision_mask = 3
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 16
	collision.shape = shape
	add_child(collision)

	_sprite = Sprite2D.new()
	_sprite.scale = Vector2(GHOST_SPRITE_SCALE, GHOST_SPRITE_SCALE)
	add_child(_sprite)


func _ready() -> void:
	patrol_direction = _random_direction()
	_load_ghost_sprite()


func _physics_process(delta: float) -> void:
	if is_exploding:
		explode_timer += delta
		if explode_timer >= EXPLODE_FRAME_TIME:
			explode_frame += 1
			explode_timer = 0.0
			match explode_frame:
				1:
					_sprite.texture = preload("res://assets/sprites/ghosts/explode_3.png")
				2:
					queue_free()
		return

	if attracted_to_sajen:
		var d = global_position.distance_to(sajen_position)
		if d > 16:
			velocity = (sajen_position - global_position).normalized() * PATROL_SPEED
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		return

	if not target_player:
		return
	
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
			if target_player.is_in_poskamling:
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
			velocity = dir * CHASE_SPEED
		
		State.FLEE:
			var dir = (global_position - target_player.global_position).normalized()
			velocity = dir * FLEE_SPEED
	
	move_and_slide()


func _random_direction() -> Vector2:
	var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
	return dirs[randi() % dirs.size()]


func set_target(player: Node2D) -> void:
	target_player = player


func set_ghost_index(idx: int) -> void:
	ghost_index = idx
	ghost_name = GhostDatabase.get_ghost_name(idx)
	pesugihan_value = GhostDatabase.get_ghost_coins(idx)
	_load_ghost_sprite()


func _load_ghost_sprite() -> void:
	if ghost_name.is_empty():
		return
	var path = "res://assets/sprites/ghosts/" + ghost_name + ".png"
	var tex = load(path)
	if tex:
		_sprite.texture = tex


func explode() -> void:
	is_exploding = true
	explode_frame = 0
	explode_timer = 0.0
	_sprite.texture = preload("res://assets/sprites/ghosts/explode_2.png")
	_sprite.scale = Vector2(EXPLODE_SCALE, EXPLODE_SCALE)
	collision_layer = 0
	collision_mask = 0
