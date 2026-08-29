extends Control

var revealed := false
var reveal_timer := 0.0
var ghost_positions: Array = []
var player_position: Vector2 = Vector2.ZERO
var map_size: Vector2 = Vector2(640, 640)
var has_grid := false
var grid_data: Array = []
var grid_cols := 0
var grid_rows := 0
var jimpitan_positions: Array = []

func _ready() -> void:
	size = Vector2(168, 168)
	custom_minimum_size = Vector2(168, 168)
	queue_redraw()

func set_jimpitan_positions(positions: Array) -> void:
	jimpitan_positions = positions
	queue_redraw()

func set_grid(grid: Array, cols: int, rows: int) -> void:
	grid_data = grid
	grid_cols = cols
	grid_rows = rows
	has_grid = true
	queue_redraw()

func _draw() -> void:
	var s = size
	if s.x <= 0 or s.y <= 0:
		s = Vector2(100, 100)

	var ms = map_size
	if ms.x <= 0:
		ms = Vector2(640, 640)

	draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.1, 0.15, 0.9))
	var border_color = Color(0.5, 0.5, 0.5)
	if revealed:
		var msec = Time.get_ticks_msec()
		border_color = Color.RED if (msec / 300) % 2 == 0 else Color(0.5, 0.5, 0.5)
	draw_rect(Rect2(Vector2.ZERO, s), border_color, false, 5.0 if revealed else 1.0)

	var scale_factor = s / ms

	if has_grid and grid_cols > 0 and grid_rows > 0:
		var cell_w = s.x / grid_cols
		var cell_h = s.y / grid_rows
		for x in range(grid_cols):
			for y in range(grid_rows):
				if grid_data[x][y] == 1 or grid_data[x][y] == 3:
					draw_rect(Rect2(x * cell_w, y * cell_h, cell_w, cell_h), Color(0.3, 0.2, 0.1))
				elif grid_data[x][y] == 2:
					draw_rect(Rect2(x * cell_w, y * cell_h, cell_w, cell_h), Color(0.4, 1.0, 0.4))

	for pos in jimpitan_positions:
		var c = pos * scale_factor
		draw_circle(c, 1.5, Color(1.0, 0.8, 0.0))

	var px = player_position * scale_factor
	if px.length() > 0:
		draw_circle(px, 3, Color(0.2, 0.6, 1.0))

	if revealed:
		for pos in ghost_positions:
			var gx = pos * scale_factor
			draw_circle(gx, 2, Color.RED)

func update_ghost_positions(positions: Array) -> void:
	ghost_positions = positions
	queue_redraw()

func update_player_position(pos: Vector2, msize: Vector2) -> void:
	player_position = pos
	map_size = msize
	queue_redraw()

func set_revealed(reveal: bool, duration: float = 5.0) -> void:
	revealed = reveal
	if reveal:
		reveal_timer = duration
	queue_redraw()

func update_positions(ghost_positions: Array, map_size: Vector2) -> void:
	self.ghost_positions = ghost_positions
	self.map_size = map_size
	queue_redraw()

func _process(delta: float) -> void:
	if revealed:
		reveal_timer -= delta
		if reveal_timer <= 0:
			revealed = false
			queue_redraw()
