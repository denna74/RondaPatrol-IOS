extends Control

signal move_direction(dir: Vector2)

var _pressed := false
var _thumb_offset := Vector2.ZERO
var _center := Vector2.ZERO
var _outer_radius := 0.0
var _inner_radius := 0.0
var _dead_zone := 0.0
var _current_dir := Vector2.ZERO
var _touch_index := -1

func _ready() -> void:
	_center = size / 2.0
	_outer_radius = size.x * 0.4
	_inner_radius = size.x * 0.13
	_dead_zone = size.x * 0.06

func _draw() -> void:
	var c = _center + _thumb_offset
	draw_circle(_center, _outer_radius, Color(1, 1, 1, 0.15))
	draw_circle(_center, _outer_radius, Color(1, 1, 1, 0.3), false, 2.0)
	if _pressed:
		draw_circle(c, _inner_radius, Color(1, 1, 1, 0.6))
		draw_circle(c, _inner_radius, Color(1, 1, 1, 0.8), false, 2.0)
	else:
		draw_circle(c, _inner_radius, Color(1, 1, 1, 0.3))
		draw_circle(c, _inner_radius, Color(1, 1, 1, 0.5), false, 2.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st = event as InputEventScreenTouch
		if st.pressed:
			if _touch_index == -1:
				_touch_index = st.index
				_pressed = true
				_update_thumb(st.position)
				queue_redraw()
				accept_event()
		else:
			if st.index == _touch_index:
				_touch_index = -1
				_pressed = false
				_thumb_offset = Vector2.ZERO
				_current_dir = Vector2.ZERO
				move_direction.emit(Vector2.ZERO)
				queue_redraw()
				accept_event()

	elif event is InputEventScreenDrag:
		var sd = event as InputEventScreenDrag
		if _pressed and sd.index == _touch_index:
			_update_thumb(sd.position)
			queue_redraw()
			accept_event()

	elif event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if _touch_index != -1:
				accept_event()
				return
			if mb.pressed:
				_pressed = true
				_update_thumb(mb.position)
			else:
				_pressed = false
				_thumb_offset = Vector2.ZERO
				_current_dir = Vector2.ZERO
				move_direction.emit(Vector2.ZERO)
			queue_redraw()
			accept_event()

	elif event is InputEventMouseMotion:
		var mm = event as InputEventMouseMotion
		if _pressed and _touch_index == -1:
			_update_thumb(mm.position)
			queue_redraw()
			accept_event()

func _update_thumb(pos: Vector2) -> void:
	var offset = pos - _center
	var dist = offset.length()
	if dist > _outer_radius:
		offset = offset.normalized() * _outer_radius
	if dist < _dead_zone:
		if _current_dir != Vector2.ZERO:
			_current_dir = Vector2.ZERO
			move_direction.emit(Vector2.ZERO)
	else:
		var dir = offset.normalized()
		if dir != _current_dir:
			_current_dir = dir
			move_direction.emit(dir)
	_thumb_offset = offset
