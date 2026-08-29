extends StaticBody2D

func _init() -> void:
	collision_layer = 1
	collision_mask = 12
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(64, 64)
	collision.shape = shape
	collision.position = Vector2(32, 32)
	add_child(collision)

	var sprite = Sprite2D.new()
	sprite.texture = preload("res://assets/sprites/obstacles/boundary.png")
	sprite.scale = Vector2(0.25, 0.25)
	sprite.position = Vector2(32, 32)
	add_child(sprite)
