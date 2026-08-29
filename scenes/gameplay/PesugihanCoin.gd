extends Area2D

signal collected

var value: int = 1
var is_collected := false
var _sfx: AudioStreamPlayer


func _init() -> void:
	collision_mask = 4
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 8
	collision.shape = shape
	add_child(collision)


func _draw() -> void:
	draw_circle(Vector2.ZERO, 6, Color(1.0, 0.8, 0.0))
	draw_line(Vector2(0, -5), Vector2(0, 5), Color(1.0, 0.9, 0.3), 2)


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale:x", 0.0, 0.4).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale:x", 1.0, 0.4).set_ease(Tween.EASE_OUT)

	_sfx = AudioStreamPlayer.new()
	_sfx.stream = preload("res://assets/sfx/get_coin.wav")
	_sfx.bus = "Master"
	add_child(_sfx)


func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D and not is_collected:
		is_collected = true
		collected.emit()
		hide()
		set_deferred("monitoring", false)
		_sfx.play()
		await _sfx.finished
		queue_free()
