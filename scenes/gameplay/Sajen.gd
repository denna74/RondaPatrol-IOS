extends Node2D

signal expired

var _smoke_timer := 0.0
var _smoke_frame := 0
var _smoke_sprite: Sprite2D

const SMOKE_FRAMES := [
	preload("res://assets/sprites/others/smoke_1.png"),
	preload("res://assets/sprites/others/smoke_2.png"),
	preload("res://assets/sprites/others/smoke_3.png"),
]
const SMOKE_FRAME_TIME := 0.3


func _init() -> void:
	var sajen = Sprite2D.new()
	sajen.texture = preload("res://assets/sprites/others/sajen.png")
	sajen.scale = Vector2(0.1, 0.1)
	add_child(sajen)

	_smoke_sprite = Sprite2D.new()
	_smoke_sprite.texture = SMOKE_FRAMES[0]
	_smoke_sprite.scale = Vector2(0.17, 0.17)
	_smoke_sprite.position = Vector2(0, -10)
	add_child(_smoke_sprite)

	var timer = Timer.new()
	timer.name = "LifetimeTimer"
	timer.one_shot = true
	timer.timeout.connect(_on_expired)
	add_child(timer)


func _ready() -> void:
	$LifetimeTimer.start(10.0)


func _process(delta: float) -> void:
	_smoke_timer += delta
	if _smoke_timer >= SMOKE_FRAME_TIME:
		_smoke_frame = (_smoke_frame + 1) % SMOKE_FRAMES.size()
		_smoke_sprite.texture = SMOKE_FRAMES[_smoke_frame]
		_smoke_timer = 0.0


func _on_expired() -> void:
	expired.emit()
	queue_free()
