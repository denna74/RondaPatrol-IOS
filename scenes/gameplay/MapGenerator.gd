class_name MapGenerator
extends RefCounted

const TILE_SIZE := 64
const HOUSE_SIZE := 2
const PATH_WIDTH := 2
const HOUSE_MARGIN := 0


static func generate(level: int) -> Dictionary:
	var size = LevelData.get_map_size(level)
	var cols = size.x
	var rows = size.y

	var grid = []
	for x in range(cols):
		grid.append([])
		for y in range(rows):
			grid[x].append(0)

	for x in range(cols):
		grid[x][0] = 1
		grid[x][rows - 1] = 1
	for y in range(rows):
		grid[0][y] = 1
		grid[cols - 1][y] = 1

	var dirt_mask = []
	for x in range(cols):
		dirt_mask.append([])
		for y in range(rows):
			dirt_mask[x].append(false)

	var building_count = LevelData.get_building_count(level)
	var building_positions = []
	var placed = 0
	var attempts = 0
	while placed < building_count and attempts < building_count * 20:
		attempts += 1
		var bx = randi_range(1 + HOUSE_MARGIN, cols - 2 - HOUSE_SIZE - HOUSE_MARGIN)
		var by = randi_range(1 + HOUSE_MARGIN, rows - 2 - HOUSE_SIZE - HOUSE_MARGIN)

		var can_place = true
		for ox in building_positions:
			var c_left = bx - HOUSE_MARGIN
			var c_top = by - HOUSE_MARGIN
			var c_right = bx + HOUSE_SIZE - 1 + HOUSE_MARGIN
			var c_bottom = by + HOUSE_SIZE - 1 + HOUSE_MARGIN
			var e_left = ox.x
			var e_top = ox.y
			var e_right = ox.x + HOUSE_SIZE - 1
			var e_bottom = ox.y + HOUSE_SIZE - 1
			if not (c_right < e_left or c_left > e_right or c_bottom < e_top or c_top > e_bottom):
				can_place = false
				break

		if not can_place:
			continue

		for dx in range(HOUSE_SIZE):
			for dy in range(HOUSE_SIZE):
				if grid[bx + dx][by + dy] != 0:
					can_place = false
					break
			if not can_place:
				break

		if can_place and _block_keeps_connected(grid, cols, rows, bx, by):
			for dx in range(HOUSE_SIZE):
				for dy in range(HOUSE_SIZE):
					dirt_mask[bx + dx][by + dy] = true
			for dx in range(HOUSE_SIZE):
				for dy in range(HOUSE_SIZE):
					grid[bx + dx][by + dy] = 3
			building_positions.append(Vector2i(bx, by))
			placed += 1

	var poskamling_count = _get_poskamling_count(level)
	var poskamlings = []
	for p in range(poskamling_count):
		var pos = _find_open_space_away_from(grid, cols, rows, poskamlings, 6)
		if pos:
			grid[pos.x][pos.y] = 2
			poskamlings.append(pos)
			for dx in range(-1, 2):
				for dy in range(-1, 2):
					var px = pos.x + dx
					var py = pos.y + dy
					if px >= 0 and px < cols and py >= 0 and py < rows:
						dirt_mask[px][py] = true

	var structures = []
	for bp in building_positions:
		structures.append({
			"pos": bp,
			"size": HOUSE_SIZE,
		})
	for pp in poskamlings:
		structures.append({
			"pos": Vector2i(pp.x - 1, pp.y - 1),
			"size": 3,
		})

	var connections = _build_spanning_tree(structures)

	for conn in connections:
		var a = structures[conn[0]]
		var b = structures[conn[1]]
		_fill_path(dirt_mask, a.pos, a.size, b.pos, b.size, cols, rows)

	var jimpitan_quota = LevelData.get_jimpitan_quota(level)
	var jimpitans = []
	for j in range(jimpitan_quota):
		var pos = _find_open_space(grid, cols, rows)
		if pos:
			jimpitans.append(pos)

	var walkable = cols * rows - placed * 4 - _count_wall_border(grid, cols, rows)
	var ghost_count = LevelData.get_ghost_count(walkable)
	var ghost_spawns = []
	for g in range(ghost_count):
		var pos = _find_open_space(grid, cols, rows)
		if pos:
			ghost_spawns.append(pos)

	var tree_positions = []
	var tree_candidates = []
	for x in range(1, cols - 1):
		for y in range(1, rows - 1):
			if grid[x][y] == 0 and not dirt_mask[x][y]:
				tree_candidates.append(Vector2i(x, y))

	var occupied = {}
	for jp in jimpitans:
		occupied[Vector2i(jp.x, jp.y)] = true
	for gp in ghost_spawns:
		occupied[Vector2i(gp.x, gp.y)] = true
	for pp in poskamlings:
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				occupied[Vector2i(pp.x + dx, pp.y + dy)] = true
	tree_candidates = tree_candidates.filter(func(pos): return not occupied.has(pos))

	tree_candidates.shuffle()
	var tree_count = mini(max(1, int(ceil(sqrt(cols * rows) / 5.5))), tree_candidates.size())
	for i in range(tree_count):
		tree_positions.append(tree_candidates[i])

	return {
		"grid": grid,
		"cols": cols,
		"rows": rows,
		"tile_size": TILE_SIZE,
		"buildings": building_count,
		"building_positions": building_positions,
		"poskamlings": poskamlings,
		"jimpitans": jimpitans,
		"ghost_spawns": ghost_spawns,
		"player_start": poskamlings[0] if poskamlings.size() > 0 else Vector2i(1, 1),
		"poskamling_positions": poskamlings,
		"dirt_mask": dirt_mask,
		"connections": connections,
		"tree_positions": tree_positions,
	}


static func _get_poskamling_count(level: int) -> int:
	if level <= 3:
		return 1
	elif level <= 7:
		return 2
	else:
		return randi_range(1, 3)


static func _find_open_space_away_from(grid: Array, cols: int, rows: int, existing: Array, min_dist: int) -> Vector2i:
	for attempt in range(200):
		var x = randi_range(1, cols - 2)
		var y = randi_range(1, rows - 2)
		if grid[x][y] != 0:
			continue
		var too_close = false
		for pos in existing:
			if absi(x - pos.x) < min_dist and absi(y - pos.y) < min_dist:
				too_close = true
				break
		if not too_close:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


static func _find_open_space(grid: Array, cols: int, rows: int) -> Vector2i:
	for attempt in range(100):
		var x = randi_range(1, cols - 2)
		var y = randi_range(1, rows - 2)
		if grid[x][y] == 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


static func _block_keeps_connected(grid: Array, cols: int, rows: int, bx: int, by: int) -> bool:
	var neighbors: Array[int] = []
	for dy in range(-1, HOUSE_SIZE + 1):
		for dx in range(-1, HOUSE_SIZE + 1):
			if dx >= 0 and dx < HOUSE_SIZE and dy >= 0 and dy < HOUSE_SIZE:
				continue
			var nx: int = bx + dx
			var ny: int = by + dy
			if nx < 0 or nx >= cols or ny < 0 or ny >= rows:
				continue
			if grid[nx][ny] == 0:
				neighbors.append(ny * cols + nx)
	if neighbors.size() < 2:
		return true

	var target := neighbors.size()
	var to_find := {}
	for idx in neighbors:
		to_find[idx] = true
	var seen: Array[bool] = []
	seen.resize(cols * rows)
	var stack: Array[int] = [neighbors[0]]
	seen[neighbors[0]] = true
	to_find.erase(neighbors[0])
	var found := 1
	var b_min_x := bx
	var b_max_x := bx + HOUSE_SIZE
	var b_min_y := by
	var b_max_y := by + HOUSE_SIZE
	while stack.size() > 0:
		var idx: int = stack.pop_back()
		var cx: int = idx % cols
		var cy: int = idx / cols
		var n := idx - cols
		if n >= 0:
			var ny2: int = n / cols
			if not (cx >= b_min_x and cx < b_max_x and ny2 >= b_min_y and ny2 < b_max_y) and not seen[n] and grid[cx][ny2] == 0:
				seen[n] = true
				stack.append(n)
				if to_find.has(n):
					to_find.erase(n)
					found += 1
					if found == target:
						return true
		n = idx + cols
		if n < cols * rows:
			var ny3: int = n / cols
			if not (cx >= b_min_x and cx < b_max_x and ny3 >= b_min_y and ny3 < b_max_y) and not seen[n] and grid[cx][ny3] == 0:
				seen[n] = true
				stack.append(n)
				if to_find.has(n):
					to_find.erase(n)
					found += 1
					if found == target:
						return true
		n = idx - 1
		if n >= 0 and n % cols < cols - 1:
			if not (n % cols >= b_min_x and n % cols < b_max_x and cy >= b_min_y and cy < b_max_y) and not seen[n] and grid[n % cols][cy] == 0:
				seen[n] = true
				stack.append(n)
				if to_find.has(n):
					to_find.erase(n)
					found += 1
					if found == target:
						return true
		n = idx + 1
		if n < cols * rows and n % cols > 0:
			if not (n % cols >= b_min_x and n % cols < b_max_x and cy >= b_min_y and cy < b_max_y) and not seen[n] and grid[n % cols][cy] == 0:
				seen[n] = true
				stack.append(n)
				if to_find.has(n):
					to_find.erase(n)
					found += 1
					if found == target:
						return true
	return false


static func _count_wall_border(grid: Array, cols: int, rows: int) -> int:
	return cols * 2 + rows * 2 - 4


static func _build_spanning_tree(structures: Array) -> Array:
	if structures.size() <= 1:
		return []

	var order = range(structures.size())
	order.shuffle()
	var connections = []
	var connected = [order[0]]
	for i in range(1, order.size()):
		var other = connected[randi() % connected.size()]
		connections.append([other, order[i]])
		connected.append(order[i])
	return connections


static func _fill_path(dirt_mask: Array, a_pos: Vector2i, a_size: int, b_pos: Vector2i, b_size: int, cols: int, rows: int) -> void:
	var a_row0 = a_pos.y + (a_size - PATH_WIDTH) / 2
	var a_row1 = a_pos.y + (a_size + PATH_WIDTH) / 2 - 1
	var b_col0 = b_pos.x + (b_size - PATH_WIDTH) / 2
	var b_col1 = b_pos.x + (b_size + PATH_WIDTH) / 2 - 1

	var x0 = mini(a_pos.x, b_pos.x)
	var x1 = maxi(a_pos.x + a_size - 1, b_pos.x + b_size - 1)
	var y0 = mini(a_pos.y, b_pos.y)
	var y1 = maxi(a_pos.y + a_size - 1, b_pos.y + b_size - 1)

	_fill_rect(dirt_mask, x0, x1, a_row0, a_row1, cols, rows)
	_fill_rect(dirt_mask, b_col0, b_col1, y0, y1, cols, rows)


static func _fill_rect(dirt_mask: Array, x0: int, x1: int, y0: int, y1: int, cols: int, rows: int) -> void:
	for x in range(maxi(x0, 0), mini(x1, cols - 1) + 1):
		for y in range(maxi(y0, 0), mini(y1, rows - 1) + 1):
			dirt_mask[x][y] = true
