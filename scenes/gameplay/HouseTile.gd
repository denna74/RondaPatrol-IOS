extends StaticBody2D

func _init() -> void:
	collision_layer = 1
	collision_mask = 12
	var collision = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(128, 128)
	collision.shape = shape
	collision.position = Vector2(64, 64)
	add_child(collision)

	var sprite = Sprite2D.new()
	var n = randi() % 9 + 1
	sprite.texture = load("res://assets/sprites/obstacles/house_" + str(n) + ".png")
	sprite.scale = Vector2(0.5, 0.5)
	sprite.position = Vector2(64, 64)
	add_child(sprite)
