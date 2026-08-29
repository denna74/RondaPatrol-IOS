extends Node2D

var _polygon: PackedVector2Array
var _blinking := false


func set_senter_polygon(polygon: PackedVector2Array) -> void:
	_polygon = polygon
	queue_redraw()


func hide_cone() -> void:
	_polygon = PackedVector2Array()
	_blinking = false
	queue_redraw()


func set_blinking(blink: bool) -> void:
	_blinking = blink
	queue_redraw()


func _draw() -> void:
	if _polygon.size() >= 3:
		var alpha = 0.12
		if _blinking:
			var msec = Time.get_ticks_msec()
			alpha = 0.3 if (msec / 150) % 2 == 0 else 0.03
		draw_colored_polygon(_polygon, Color(1, 1, 1, alpha))
