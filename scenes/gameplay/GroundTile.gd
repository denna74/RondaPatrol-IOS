extends TileMapLayer

const TILE_SIZE := 64
const SUBDIV := 4
const VCELL := TILE_SIZE / SUBDIV

const ACCENT_VARIANTS := [6, 7, 8]

var _vcols: int
var _vrows: int
var _vdirt: Array
var _vaccent: Array
var _tile_grid: Array
var _vaccent_index: Dictionary = {}


func _init(cols: int, rows: int, dirt_mask: Array, p_tile_set: TileSet) -> void:
	tile_set = p_tile_set
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_vcols = cols * SUBDIV
	_vrows = rows * SUBDIV
	_expand_dirt_mask(cols, rows, dirt_mask)
	_build_tile_grid()
	_render_tiles()


func _expand_dirt_mask(cols: int, rows: int, dirt_mask: Array) -> void:
	_vdirt = []
	_vdirt.resize(_vcols)
	for vx in range(_vcols):
		_vdirt[vx] = []
		_vdirt[vx].resize(_vrows)
		for vy in range(_vrows):
			_vdirt[vx][vy] = dirt_mask[vx / SUBDIV][vy / SUBDIV]


func _v_is_dirt(x: int, y: int) -> bool:
	if x < 0 or x >= _vcols or y < 0 or y >= _vrows:
		return false
	return _vdirt[x][y]


func _v_touches_dirt(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			if _v_is_dirt(x + dx, y + dy):
				return true
	return false


func _v_tile_for_dirt_neighbors(x: int, y: int) -> int:
	var n = _v_is_dirt(x, y - 1)
	var s = _v_is_dirt(x, y + 1)
	var w = _v_is_dirt(x - 1, y)
	var e = _v_is_dirt(x + 1, y)

	if n and s and w and e:
		return 9  # dirt_center
	if not n and s and w and e:
		return 10  # dirt_top
	if n and not s and w and e:
		return 11  # dirt_bottom
	if n and s and not w and e:
		return 12  # dirt_left
	if n and s and w and not e:
		return 13  # dirt_right
	if not n and s and not w and e:
		return 14  # dirt_left_top
	if not n and s and w and not e:
		return 15  # dirt_right_top
	if n and not s and not w and e:
		return 16  # dirt_left_bottom
	if n and not s and w and not e:
		return 17  # dirt_right_bottom
	return 9  # dirt_center


func _v_border_tile_for(is_special: Callable, x: int, y: int) -> int:
	if is_special.call(x, y - 1) or is_special.call(x, y + 1) or \
	   is_special.call(x - 1, y) or is_special.call(x + 1, y):
		return 1  # grass_straight

	if is_special.call(x + 1, y + 1):
		return 2  # grass_left_top
	if is_special.call(x - 1, y + 1):
		return 3  # grass_right_top
	if is_special.call(x + 1, y - 1):
		return 4  # grass_left_bottom
	if is_special.call(x - 1, y - 1):
		return 5  # grass_right_bottom
	return 1  # grass_straight


func _v_is_accent(x: int, y: int) -> bool:
	if x < 0 or x >= _vcols or y < 0 or y >= _vrows:
		return false
	return _vaccent[y][x] != null


func _v_far_from_dirt(x: int, y: int, buffer: int = 2) -> bool:
	for dy in range(-buffer, buffer + 1):
		for dx in range(-buffer, buffer + 1):
			if _v_is_dirt(x + dx, y + dy):
				return false
	return true


func _v_far_from_other_patches(x: int, y: int, ignore_id: int, buffer: int = 2) -> bool:
	for dy in range(-buffer, buffer + 1):
		for dx in range(-buffer, buffer + 1):
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < _vcols and ny >= 0 and ny < _vrows:
				var pid = _vaccent[ny][nx]
				if pid != null and pid != ignore_id:
					return false
	return true


func _v_touches_accent(x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var nx = x + dx
			var ny = y + dy
			if nx >= 0 and nx < _vcols and ny >= 0 and ny < _vrows:
				if _vaccent[ny][nx] != null:
					return true
	return false


func _build_tile_grid() -> void:
	_tile_grid = []
	_tile_grid.resize(_vcols)
	for x in range(_vcols):
		_tile_grid[x] = []
		_tile_grid[x].resize(_vrows)

	_vaccent = []
	_vaccent.resize(_vrows)
	for y in range(_vrows):
		_vaccent[y] = []
		_vaccent[y].resize(_vcols)

	_compute_accent_patches()
	_assign_tiles()


func _compute_accent_patches() -> void:
	var candidates := []
	for y in range(_vrows):
		for x in range(_vcols):
			if _vdirt[x][y]:
				continue
			if _v_far_from_dirt(x, y, 2) and _v_far_from_other_patches(x, y, -1, 2):
				candidates.append(Vector2i(x, y))

	candidates.shuffle()
	var max_patches = candidates.size() / 20 + 1
	var patches_placed = 0
	var next_id = 0

	for seed in candidates:
		if patches_placed >= max_patches:
			break
		if _vaccent[seed.y][seed.x] != null:
			continue
		if not _v_far_from_dirt(seed.x, seed.y, 2) or not _v_far_from_other_patches(seed.x, seed.y, -1, 2):
			continue
		if randf() > 0.10:
			continue

		var patch_id = next_id
		next_id += 1
		var chosen = ACCENT_VARIANTS[randi() % ACCENT_VARIANTS.size()]
		var patch = [seed]
		_vaccent[seed.y][seed.x] = patch_id

		var target = [1, 1, 2, 3][randi() % 4]
		while patch.size() < target:
			var idx = randi() % patch.size()
			var cx = patch[idx].x
			var cy = patch[idx].y
			var options := []
			for d in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
				var nx = cx + d.x
				var ny = cy + d.y
				if nx >= 0 and nx < _vcols and ny >= 0 and ny < _vrows:
					if not _vdirt[nx][ny] and _vaccent[ny][nx] == null:
						if _v_far_from_dirt(nx, ny, 2) and _v_far_from_other_patches(nx, ny, patch_id, 2):
							options.append(Vector2i(nx, ny))
			if options.is_empty():
				break
			options.shuffle()
			var chosen_pos = options[0]
			_vaccent[chosen_pos.y][chosen_pos.x] = patch_id
			patch.append(chosen_pos)

		_vaccent_index[patch_id] = chosen
		patches_placed += 1


func _assign_tiles() -> void:
	var is_dirt := func(x: int, y: int) -> bool:
		return _v_is_dirt(x, y)

	var is_accent := func(x: int, y: int) -> bool:
		return _v_is_accent(x, y)

	for y in range(_vrows):
		for x in range(_vcols):
			if _vdirt[x][y]:
				_tile_grid[x][y] = _v_tile_for_dirt_neighbors(x, y)
			elif _v_touches_dirt(x, y):
				_tile_grid[x][y] = _v_border_tile_for(is_dirt, x, y)
			elif _v_is_accent(x, y):
				_tile_grid[x][y] = _vaccent_index[_vaccent[y][x]]
			elif _v_touches_accent(x, y):
				_tile_grid[x][y] = _v_border_tile_for(is_accent, x, y)
			else:
				_tile_grid[x][y] = 0


func _render_tiles() -> void:
	for y in range(_vrows):
		for x in range(_vcols):
			var tile_id = _tile_grid[x][y]
			if tile_id < 0 or tile_id >= 18:
				continue
			var atlas_coords = Vector2i(tile_id % 6, tile_id / 6)
			set_cell(Vector2i(x, y), 0, atlas_coords)
