extends Area2D

signal entered(body: Node)
signal exited(body: Node)

var _aura_alpha: float = 0.15
var _sprite: Sprite2D


func _init() -> void:
	collision_layer = 0
	collision_mask = 4

	var sense = CollisionShape2D.new()
	var sense_shape = RectangleShape2D.new()
	sense_shape.size = Vector2(64, 64)
	sense.shape = sense_shape
	sense.position = Vector2(32, 32)
	add_child(sense)

	var barrier = StaticBody2D.new()
	barrier.collision_layer = 2
	barrier.collision_mask = 8
	var wall = CollisionShape2D.new()
	var wall_shape = RectangleShape2D.new()
	wall_shape.size = Vector2(68, 68)
	wall.shape = wall_shape
	wall.position = Vector2(32, 32)
	barrier.add_child(wall)
	add_child(barrier)

	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/others/poskamling.png")
	_sprite.scale = Vector2(0.25, 0.25)
	_sprite.position = Vector2(32, 32)
	add_child(_sprite)


func _draw() -> void:
	draw_rect(Rect2(9, 0, 46, 64), Color(1, 1, 0, _aura_alpha))


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var tween = create_tween().set_loops()
	tween.tween_method(_set_aura_alpha, 0.08, 0.3, 1.5)
	tween.tween_method(_set_aura_alpha, 0.3, 0.08, 1.5)


func _set_aura_alpha(value: float) -> void:
	_aura_alpha = value
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		_sprite.z_index = 10
		entered.emit(body)


func _on_body_exited(body: Node) -> void:
	if body is CharacterBody2D:
		_sprite.z_index = 0
		exited.emit(body)
