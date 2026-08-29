extends Node2D

enum State { BUILD_MAP, SPAWN, PLAYING }

var player: CharacterBody2D
var hud: CanvasLayer
var map_container: Node2D
var entities: Node2D
var current_level: int = 1
var map_data: Dictionary = {}
var ghosts: Array = []
var jimpitans: Array = []
var thief = null
var jimpitan_collected: int = 0
var pesugihan_earned: int = 0
var coins_stolen_by_thief: int = 0
var is_senter_active := false
var is_balsem_active := false
var senter_timer := 0.0
var balsem_timer := 0.0
var is_level_complete := false
var all_coins_collected := false
var thief_spawn_cooldown := 0.0
var senter_overlay: Node2D
var pesugihan_coins: Array = []
var _active_sajens: Array = []
var _balm_loop_player: AudioStreamPlayer
var _sfx_explode: AudioStreamPlayer
var _sfx_drop_coins: AudioStreamPlayer
var _sfx_stamina_up: AudioStreamPlayer
var _sfx_caught: AudioStreamPlayer
var _sfx_sonar: AudioStreamPlayer
var _skills_used: int = 0
var _state: State = State.BUILD_MAP

const PesugihanCoin := preload("res://scenes/gameplay/PesugihanCoin.gd")
const JimpitanCoin := preload("res://scenes/gameplay/JimpitanCoin.gd")
const Sajen := preload("res://scenes/gameplay/Sajen.gd")
const SFX_GHOST_EXPLODE := preload("res://assets/sfx/ghost_explode.wav")
const SFX_DROP_COINS := preload("res://assets/sfx/drop_coins.wav")
const SFX_STAMINA_UP := preload("res://assets/sfx/stamina_up.wav")
const SFX_CAUGHT_BY_GHOST := preload("res://assets/sfx/caught_by_ghost.wav")
const SFX_BALM_EFFECT := preload("res://assets/sfx/balm_effect.wav")
const SFX_SONAR := preload("res://assets/sfx/sonar.wav")

const EMPTY_LONG := preload("res://assets/buttons/empty_long.png")
const FONT_GREEN := "res://assets/fonts/green/"
const FONT_PINK := "res://assets/fonts/pink/"
const FONT_YELLOW := "res://assets/fonts/yellow/"
const ButtonBuilder := preload("res://scripts/ButtonBuilder.gd")
const STAR_ONE := preload("res://assets/buttons/star_one_level_button.png")
const STAR_TWO := preload("res://assets/buttons/star_two_level_button.png")
const STAR_THREE := preload("res://assets/buttons/star_three_level_button.png")
const STAR_ICON := preload("res://assets/icons_buttons/star.png")

const TILE_NAMES_FALLBACK := [
	"land_center", "grass_straight", "grass_left_top", "grass_right_top",
	"grass_left_bottom", "grass_right_bottom",
	"grass_center_1", "grass_center_2", "grass_center_3",
	"dirt_center", "dirt_top", "dirt_bottom", "dirt_left", "dirt_right",
	"dirt_left_top", "dirt_right_top", "dirt_left_bottom", "dirt_right_bottom",
]
const FALLBACK_TILES_DIR := "res://assets/sprites/ground_tiles/"

const TREE_TEXTURES := [
	preload("res://assets/sprites/others/tree.png"),
	preload("res://assets/sprites/others/tree_coconut.png"),
	preload("res://assets/sprites/others/tree_banana.png"),
	preload("res://assets/sprites/others/tree_mango.png"),
]


func _ready() -> void:
	var params = SceneManager.get_params()
	current_level = params.get("level", 1)
	SaveManager.on_gameplay_start()

	map_container = Node2D.new()
	map_container.name = "MapContainer"
	add_child(map_container)

	RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))

	var td = SceneManager.transition_data
	map_data = td.get("map_data", MapGenerator.generate(current_level))
	var tile_set: TileSet = td.get("tile_set")
	if not tile_set:
		tile_set = _generate_tile_set_fallback()
	var player_tex: Dictionary = td.get("player_textures", {})
	SceneManager.transition_data = {}

	_build_map(tile_set)
	_setup_player(player_tex)
	_setup_hud()
	_spawn_entities()
	_init_sfx_players()
	_state_enter_playing()


func _build_map(tile_set: TileSet) -> void:
	var grid = map_data["grid"]
	var tile_size = map_data["tile_size"]

	var ground = preload("res://scenes/gameplay/GroundTile.gd").new(
		map_data["cols"], map_data["rows"],
		map_data.get("dirt_mask", []), tile_set)
	map_container.add_child(ground)

	for x in range(map_data["cols"]):
		for y in range(map_data["rows"]):
			if grid[x][y] == 1:
				var wall = preload("res://scenes/gameplay/WallTile.gd").new()
				wall.position = Vector2(x * tile_size, y * tile_size)
				map_container.add_child(wall)

	entities = Node2D.new()
	entities.name = "Entities"
	map_container.add_child(entities)

	for x in range(map_data["cols"]):
		for y in range(map_data["rows"]):
			if grid[x][y] == 2:
				var poskam = preload("res://scenes/gameplay/Poskamling.gd").new()
				poskam.entered.connect(_on_poskamling_entered)
				poskam.exited.connect(_on_poskamling_exited)
				poskam.position = Vector2(x * tile_size, y * tile_size)
				entities.add_child(poskam)

	for bp in map_data.get("building_positions", []):
		var house = preload("res://scenes/gameplay/HouseTile.gd").new()
		house.position = Vector2(bp.x * tile_size, bp.y * tile_size)
		entities.add_child(house)


func _setup_player(player_tex: Dictionary) -> void:
	player = preload("res://scenes/gameplay/Player.gd").new()
	player.name = "Player"
	if not player_tex.is_empty():
		player.init_textures(player_tex)
	var start = map_data["player_start"]
	var ts = map_data["tile_size"]
	player.position = Vector2(start.x * ts + ts / 2, start.y * ts + ts / 2)
	player.is_in_poskamling = true
	entities.add_child(player)


func _setup_hud() -> void:
	hud = preload("res://scenes/hud/HUD.tscn").instantiate()
	hud.name = "HUD"
	add_child(hud)
	hud.skill_bar.skill_used.connect(_on_skill_used)
	hud.dpad.move_direction.connect(player.set_movement_dir)


func _spawn_entities() -> void:
	_spawn_ghosts()
	_spawn_jimpitans()
	_setup_thief()
	_place_trees()


func _spawn_ghosts() -> void:
	var unlocked = GhostDatabase.get_unlocked_count(current_level)
	if unlocked == 0:
		return
	var spawns = map_data["ghost_spawns"]
	for i in range(spawns.size()):
		var spawn = spawns[i]
		var ghost = preload("res://scenes/gameplay/Ghost.gd").new()
		ghost.position = Vector2(spawn.x * map_data["tile_size"] + map_data["tile_size"] / 2, spawn.y * map_data["tile_size"] + map_data["tile_size"] / 2)
		ghost.set_target(player)
		if i == 0:
			ghost.set_ghost_index(0)
		else:
			ghost.set_ghost_index(randi() % unlocked)
		entities.add_child(ghost)
		ghosts.append(ghost)


func _spawn_jimpitans() -> void:
	var tile_size = map_data["tile_size"]
	for pos in map_data["jimpitans"]:
		var coin = preload("res://scenes/gameplay/JimpitanCoin.gd").new()
		coin.position = Vector2(pos.x * tile_size + tile_size / 2, pos.y * tile_size + tile_size / 2)
		coin.collected.connect(_on_jimpitan_collected.bind(coin))
		map_container.add_child(coin)
		jimpitans.append(coin)


func _setup_thief() -> void:
	thief = preload("res://scenes/gameplay/Thief.gd").new()
	entities.add_child(thief)
	thief.stolen.connect(_on_thief_stolen)


func _place_trees() -> void:
	var tile_size = map_data["tile_size"]
	for pos in map_data.get("tree_positions", []):
		var tex = TREE_TEXTURES[randi() % TREE_TEXTURES.size()]
		var sprite = Sprite2D.new()
		sprite.texture = tex
		sprite.centered = true
		sprite.scale = Vector2(1/3.0, 1/3.0)
		var h = tex.get_height()
		sprite.offset = Vector2(0, -h / 2.0 * sprite.scale.y)
		sprite.position = Vector2(pos.x * tile_size + tile_size / 2, pos.y * tile_size + tile_size / 2)
		entities.add_child(sprite)


func _generate_tile_set_fallback() -> TileSet:
	var atlas_w = 6 * 16
	var atlas_h = 3 * 16
	var atlas_image = Image.create(atlas_w, atlas_h, false, Image.FORMAT_RGBA8)
	for tile_id in range(18):
		var tex = load(FALLBACK_TILES_DIR + TILE_NAMES_FALLBACK[tile_id] + ".png")
		if not tex:
			continue
		var img = tex.get_image()
		img.convert(Image.FORMAT_RGBA8)
		img.resize(16, 16, Image.INTERPOLATE_NEAREST)
		var col = tile_id % 6
		var row = tile_id / 6
		atlas_image.blit_rect(img, Rect2i(0, 0, 16, 16), Vector2i(col * 16, row * 16))
	var atlas_texture = ImageTexture.create_from_image(atlas_image)
	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()
	source.texture = atlas_texture
	source.texture_region_size = Vector2i(16, 16)
	for tile_id in range(18):
		var col = tile_id % 6
		var row = tile_id / 6
		source.create_tile(Vector2i(col, row), Vector2i(1, 1))
	tileset.tile_size = Vector2i(16, 16)
	tileset.add_source(source, 0)
	return tileset


func _state_enter_playing() -> void:
	_state = State.PLAYING
	hud.update_level(current_level)
	hud.update_jimpitan(0, map_data["jimpitans"].size())
	MusicManager.play_gameplay_music()

	senter_overlay = preload("res://scenes/gameplay/SenterOverlay.gd").new()
	senter_overlay.name = "SenterOverlay"
	add_child(senter_overlay)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and not is_level_complete:
		SaveManager.lose_life()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_level_complete:
			return
		if hud.get_node_or_null("ExitConfirmPopup"):
			return
		if get_node_or_null("LosePopup"):
			return
		if get_node_or_null("WinPopup"):
			return
		hud._show_exit_confirm_popup()


func _exit_tree() -> void:
	SaveManager.on_gameplay_end()
	for ghost in ghosts:
		ghost.attracted_to_sajen = false
	_active_sajens.clear()
	RenderingServer.set_default_clear_color(Color(0.3, 0.3, 0.3, 1))


func _process(delta: float) -> void:
	if _state != State.PLAYING:
		return
	_update_timers(delta)
	_update_hud()
	_check_thief_spawn(delta)
	_check_senter_effect()
	_check_ghost_collisions()
	_check_thief_collision()
	_update_senter_visual()
	_update_sajen_attraction()
	_update_entity_depth()


func _update_senter_visual() -> void:
	if is_senter_active:
		senter_overlay.set_senter_polygon(_get_senter_cone_points())
		senter_overlay.set_blinking(senter_timer <= 1.0)
	else:
		senter_overlay.hide_cone()
		senter_overlay.set_blinking(false)


func _get_senter_rect() -> Rect2:
	var p = player.global_position
	var d = player.facing_dir
	var ts = player.SPRITE_SIZE
	var half_ts = ts / 2

	var front_rect: Rect2
	if abs(d.x) > abs(d.y):
		if d.x > 0:
			front_rect = Rect2(p.x + ts, p.y - ts, ts * 2, ts * 2)
		else:
			front_rect = Rect2(p.x - ts * 3, p.y - ts, ts * 2, ts * 2)
	else:
		if d.y > 0:
			front_rect = Rect2(p.x - ts, p.y + ts, ts * 2, ts * 2)
		else:
			front_rect = Rect2(p.x - ts, p.y - ts * 3, ts * 2, ts * 2)

	var player_rect = Rect2(p.x - half_ts, p.y - half_ts, ts, ts)
	return front_rect.merge(player_rect)


func _get_senter_cone_points() -> PackedVector2Array:
	var p = player.global_position
	var d = player.facing_dir
	var ts = player.SPRITE_SIZE

	if abs(d.x) > abs(d.y):
		if d.x > 0:
			return PackedVector2Array([p, Vector2(p.x + ts * 3, p.y - ts), Vector2(p.x + ts * 3, p.y + ts)])
		else:
			return PackedVector2Array([p, Vector2(p.x - ts * 3, p.y - ts), Vector2(p.x - ts * 3, p.y + ts)])
	else:
		if d.y > 0:
			return PackedVector2Array([p, Vector2(p.x - ts, p.y + ts * 3), Vector2(p.x + ts, p.y + ts * 3)])
		else:
			return PackedVector2Array([p, Vector2(p.x - ts, p.y - ts * 3), Vector2(p.x + ts, p.y - ts * 3)])


func _visual_bottom_y(node: Node2D) -> float:
	if node is Sprite2D:
		return node.position.y
	if node is StaticBody2D:
		return node.position.y + 128.0
	if node is Area2D:
		return node.position.y + 64.0
	return node.position.y + 14.0


func _update_entity_depth() -> void:
	var children = entities.get_children()
	children.sort_custom(func(a, b): return _visual_bottom_y(a) < _visual_bottom_y(b))
	for i in range(children.size()):
		entities.move_child(children[i], i)


func _update_hud() -> void:
	hud.update_ghosts(ghosts.size())
	hud.update_treasury(SaveManager.total_coins)
	hud.update_stamina(player.get_stamina_percent())
	var ghost_positions = []
	for g in ghosts:
		if g.is_visible_in_tree():
			ghost_positions.append(g.global_position)
	hud.radar.update_ghost_positions(ghost_positions)
	hud.radar.update_player_position(player.global_position, Vector2(map_data["cols"], map_data["rows"]) * map_data["tile_size"])
	if not hud.radar.has_grid:
		hud.radar.set_grid(map_data["grid"], map_data["cols"], map_data["rows"])
	var coin_world_positions = []
	for coin in jimpitans:
		if is_instance_valid(coin):
			coin_world_positions.append(coin.global_position)
	hud.radar.set_jimpitan_positions(coin_world_positions)


func _update_timers(delta: float) -> void:
	if is_senter_active:
		senter_timer -= delta
		if senter_timer <= 0:
			is_senter_active = false
			player.set_senter_active(false)

	if is_balsem_active:
		balsem_timer -= delta
		if balsem_timer <= 1.0 and not player._balm_blinking:
			player.set_balm_blinking(true)
		if balsem_timer <= 0:
			is_balsem_active = false
			player.set_balm_active(false)
			_stop_balm_loop_sfx()


func _on_skill_used(item_id: String) -> void:
	_skills_used += 1
	match item_id:
		"senter":
			if is_senter_active:
				return
			is_senter_active = true
			player.set_senter_active(true)
			senter_timer = 10.0
		"kopi":
			var ghost_positions = []
			for ghost in ghosts:
				if ghost.is_visible_in_tree():
					ghost_positions.append(ghost.global_position)
			hud.update_radar(ghost_positions, Vector2(map_data["cols"], map_data["rows"]) * map_data["tile_size"])
			hud.radar.set_revealed(true, 20.0)
			_sfx_sonar.play()
		"balsem":
			if is_balsem_active:
				return
			is_balsem_active = true
			balsem_timer = 10.0
			player.set_balm_active(true)
			_play_balm_loop_sfx()
		"kacang":
			player.restore_stamina(0.2)
			hud.flash_stamina_green()
			_play_stamina_up_sfx()
		"cassava":
			player.restore_stamina(0.4)
			hud.flash_stamina_green()
			_play_stamina_up_sfx()
		"sajen":
			var sajen = Sajen.new()
			sajen.position = player.global_position
			sajen.expired.connect(_on_sajen_expired.bind(sajen))
			add_child(sajen)
			_active_sajens.append(sajen)
	SaveManager.use_item(item_id)


const SAJEN_ATTRACTION_RADIUS := 140.0


func _on_sajen_expired(sajen: Node2D) -> void:
	_active_sajens.erase(sajen)
	for ghost in ghosts:
		if ghost.attracted_to_sajen:
			var still_attracted = false
			for s in _active_sajens:
				if ghost.global_position.distance_to(s.global_position) < SAJEN_ATTRACTION_RADIUS:
					still_attracted = true
					ghost.sajen_position = s.global_position
					break
			if not still_attracted:
				ghost.attracted_to_sajen = false


func _clear_sajen() -> void:
	for s in _active_sajens:
		s.queue_free()
	_active_sajens.clear()
	for ghost in ghosts:
		ghost.attracted_to_sajen = false


func _update_sajen_attraction() -> void:
	if _active_sajens.is_empty():
		return
	for ghost in ghosts:
		if ghost.is_exploding or not ghost.is_visible_in_tree():
			continue
		var is_attracted := false
		for s in _active_sajens:
			var dist = ghost.global_position.distance_to(s.global_position)
			if dist < SAJEN_ATTRACTION_RADIUS:
				if not ghost.attracted_to_sajen:
					ghost.attracted_to_sajen = true
				ghost.sajen_position = s.global_position
				is_attracted = true
				break
		if not is_attracted and ghost.attracted_to_sajen:
			ghost.attracted_to_sajen = false


func _spawn_pesugihan_coins(pos: Vector2, count: int) -> void:
	var angle_step = TAU / count
	var ts = map_data["tile_size"]
	var grid = map_data["grid"]
	var cols = map_data["cols"]
	var rows = map_data["rows"]
	for i in range(count):
		var coin = PesugihanCoin.new()
		var offset = Vector2(cos(i * angle_step), sin(i * angle_step)) * 24
		var spawn_pos = _find_nearest_walkable(pos + offset, grid, cols, rows, ts)
		coin.position = spawn_pos
		coin.value = 1
		coin.collected.connect(_on_pesugihan_collected)
		add_child(coin)
		pesugihan_coins.append(coin)


func _find_nearest_walkable(world_pos: Vector2, grid: Array, grid_cols: int, grid_rows: int, ts: int) -> Vector2:
	var cx = int(world_pos.x / ts)
	var cy = int(world_pos.y / ts)
	for r in range(1, maxi(grid_cols, grid_rows)):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				var nx = cx + dx
				var ny = cy + dy
				if nx >= 0 and nx < grid_cols and ny >= 0 and ny < grid_rows:
					if grid[nx][ny] == 0:
						return Vector2(nx * ts + ts / 2, ny * ts + ts / 2)
		for dy in range(-r, r + 1):
			for dx in [-r, r]:
				var nx = cx + dx
				var ny = cy + dy
				if nx >= 0 and nx < grid_cols and ny >= 0 and ny < grid_rows:
					if grid[nx][ny] == 0:
						return Vector2(nx * ts + ts / 2, ny * ts + ts / 2)
	return world_pos


func _check_senter_effect() -> void:
	if not is_senter_active:
		return

	var rect = _get_senter_rect()

	var to_remove := []
	for ghost in ghosts:
		if rect.has_point(ghost.global_position) and ghost.is_visible_in_tree():
			var count = ghost.pesugihan_value
			_spawn_pesugihan_coins(ghost.global_position, count)
			_play_explode_sfx()
			ghost.explode()
			to_remove.append(ghost)

	for ghost in to_remove:
		ghosts.erase(ghost)

	if thief and thief.is_active and not thief.has_stolen and rect.has_point(thief.global_position):
		_spawn_pesugihan_coins(thief.global_position, randi_range(1, 3))
		thief.caught_sfx_finished.connect(_play_drop_coins_sfx, CONNECT_ONE_SHOT)
		thief.on_senter_hit()


func _init_sfx_players() -> void:
	_sfx_explode = AudioStreamPlayer.new()
	_sfx_explode.stream = SFX_GHOST_EXPLODE
	_sfx_explode.bus = "Master"
	add_child(_sfx_explode)

	_sfx_drop_coins = AudioStreamPlayer.new()
	_sfx_drop_coins.stream = SFX_DROP_COINS
	_sfx_drop_coins.bus = "Master"
	add_child(_sfx_drop_coins)

	_sfx_stamina_up = AudioStreamPlayer.new()
	_sfx_stamina_up.stream = SFX_STAMINA_UP
	_sfx_stamina_up.bus = "Master"
	add_child(_sfx_stamina_up)

	_sfx_caught = AudioStreamPlayer.new()
	_sfx_caught.stream = SFX_CAUGHT_BY_GHOST
	_sfx_caught.bus = "Master"
	_sfx_caught.process_mode = PROCESS_MODE_WHEN_PAUSED
	add_child(_sfx_caught)

	_sfx_sonar = AudioStreamPlayer.new()
	_sfx_sonar.stream = SFX_SONAR
	_sfx_sonar.bus = "Master"
	add_child(_sfx_sonar)


func _play_explode_sfx() -> void:
	_sfx_explode.play()
	await _sfx_explode.finished
	_sfx_drop_coins.play()
	await _sfx_drop_coins.finished


func _play_stamina_up_sfx() -> void:
	_sfx_stamina_up.play()
	await _sfx_stamina_up.finished


func _play_drop_coins_sfx() -> void:
	_sfx_drop_coins.play()
	await _sfx_drop_coins.finished


func _play_caught_sfx() -> void:
	_sfx_caught.play()


func _play_balm_loop_sfx() -> void:
	_balm_loop_player = AudioStreamPlayer.new()
	_balm_loop_player.stream = SFX_BALM_EFFECT
	_balm_loop_player.bus = "Master"
	_balm_loop_player.finished.connect(_on_balm_loop_finished)
	add_child(_balm_loop_player)
	_balm_loop_player.play()


func _on_balm_loop_finished() -> void:
	if is_balsem_active and _balm_loop_player:
		_balm_loop_player.play()


func _stop_balm_loop_sfx() -> void:
	if _balm_loop_player:
		_balm_loop_player.stop()
		_balm_loop_player.queue_free()
		_balm_loop_player = null


func _on_pesugihan_collected() -> void:
	pesugihan_earned += 1


func _check_ghost_collisions() -> void:
	for ghost in ghosts:
		if not ghost.is_visible_in_tree():
			continue
		if ghost.attracted_to_sajen:
			continue
		if ghost.global_position.distance_to(player.global_position) < 24:
			if player.is_in_poskamling:
				continue
			if is_balsem_active:
				continue
			_on_player_caught_by_ghost()


func _check_thief_collision() -> void:
	if not thief or not thief.is_active:
		return
	if thief.global_position.distance_to(player.global_position) < 24:
		thief.try_steal()


func _on_thief_stolen(item_name: String, amount: int) -> void:
	if item_name != "":
		coins_stolen_by_thief += 1
		hud.show_stolen_message(TranslationManager.t("stolen_item") % TranslationManager.t("item_" + item_name))
	else:
		coins_stolen_by_thief += amount
		if amount > 0:
			hud.show_stolen_message(TranslationManager.t("stolen_item") % (str(amount) + " " + TranslationManager.t("stolen_coins")))
		else:
			hud.show_stolen_message(TranslationManager.t("thief_got_nothing"))
	player.show_exclamation()


func _on_jimpitan_collected(coin: JimpitanCoin) -> void:
	jimpitan_collected += 1
	jimpitans.erase(coin)
	hud.update_jimpitan(jimpitan_collected, map_data["jimpitans"].size())
	if jimpitan_collected >= map_data["jimpitans"].size() and not all_coins_collected:
		all_coins_collected = true
		hud.show_return_message()
	var coin_world_positions = []
	for c in jimpitans:
		if is_instance_valid(c):
			coin_world_positions.append(c.global_position)
	hud.radar.set_jimpitan_positions(coin_world_positions)


func _on_poskamling_entered(body: Node) -> void:
	if body == player:
		player.enter_poskamling()
		if all_coins_collected and not is_level_complete:
			_on_level_complete()


func _on_poskamling_exited(body: Node) -> void:
	if body == player:
		player.exit_poskamling()


func _check_thief_spawn(delta: float) -> void:
	if not thief or thief.is_active:
		return
	thief_spawn_cooldown -= delta
	if thief_spawn_cooldown > 0:
		return
	var ts = map_data["tile_size"]
	var margin = 20
	var interior = Rect2(ts + margin, ts + margin, (map_data["cols"] - 2) * ts - 2 * margin, (map_data["rows"] - 2) * ts - 2 * margin)
	thief.try_spawn(player, current_level, interior, map_data["grid"], map_data["cols"], map_data["rows"])
	thief_spawn_cooldown = 25.0


func _on_player_caught_by_ghost() -> void:
	is_level_complete = true
	_clear_sajen()
	SaveManager.lose_life()
	player.hide()
	_play_caught_sfx()
	_show_lose_popup()


func _show_lose_popup() -> void:
	if SaveManager.life_level <= 0:
		_show_result_popup(TranslationManager.t("caught_title"), [
			{"text": TranslationManager.t("ok"), "font_dir": FONT_GREEN, "action": func():
				get_tree().paused = false; SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")},
		])
	else:
		_show_result_popup(TranslationManager.t("caught_title"), [
			{"text": TranslationManager.t("retry"), "font_dir": FONT_YELLOW, "action": func():
				get_tree().paused = false; SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": current_level})},
			{"text": TranslationManager.t("exit"), "font_dir": FONT_PINK, "action": func():
				get_tree().paused = false; SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")},
		])


func _show_win_popup(stars: int = 1) -> void:
	var total_earned = jimpitan_collected + pesugihan_earned
	_show_result_popup(TranslationManager.t("level_complete"), [
		{"text": TranslationManager.t("retry"), "font_dir": FONT_YELLOW, "action": func():
			get_tree().paused = false; SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": current_level})},
		{"text": TranslationManager.t("next_level"), "font_dir": FONT_GREEN, "action": func():
			get_tree().paused = false; SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": current_level + 1})},
		{"text": TranslationManager.t("exit"), "font_dir": FONT_PINK, "action": func():
			get_tree().paused = false; SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")},
	], {
		"stars": stars,
		"jimpitan": jimpitan_collected,
		"pesugihan": pesugihan_earned,
		"stolen": coins_stolen_by_thief,
		"total": total_earned - coins_stolen_by_thief,
	})


func _show_result_popup(title: String, buttons: Array, breakdown: Dictionary = {}) -> void:
	get_tree().paused = true
	var overlay = ColorRect.new()
	overlay.name = "ResultPopup"
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.size = get_viewport().get_visible_rect().size
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.process_mode = PROCESS_MODE_WHEN_PAUSED

	var panel = Panel.new()
	panel.size = Vector2(784, 504)
	panel.position = (overlay.size - panel.size) / 2
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.2, 0.2, 0.2, 1)
	panel_style.set_corner_radius_all(10)
	panel.add_theme_stylebox_override("panel", panel_style)

	var label = Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(28, 21)
	label.size = Vector2(panel.size.x - 40, 39)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.add_theme_font_size_override("font_size", 31)
	panel.add_child(label)

	var btn_y := 147
	if not breakdown.is_empty():
		if breakdown.has("stars"):
			var star_count: int = breakdown["stars"]
			var star_w: int = 34
			var star_gap: int = 6
			var total_star_w: int = star_count * star_w + (star_count - 1) * star_gap
			var star_start_x: int = int((panel.size.x - total_star_w) / 2)
			for i in range(star_count):
				var star = TextureRect.new()
				star.texture = STAR_ICON
				star.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				star.custom_minimum_size = Vector2(star_w, star_w)
				star.position = Vector2(star_start_x + i * (star_w + star_gap), 68)
				panel.add_child(star)

		var lines = [
			{"text": TranslationManager.t("jimpitan"), "value": breakdown["jimpitan"], "color": Color(1, 1, 1)},
			{"text": TranslationManager.t("pesugihan_coins"), "value": breakdown["pesugihan"], "color": Color(1, 1, 1)},
			{"text": TranslationManager.t("taken_by_thief"), "value": breakdown["stolen"], "color": Color(0.9, 0.4, 0.4)},
			{"text": TranslationManager.t("total_coins"), "value": breakdown["total"], "color": Color(0.4, 1, 0.4)},
		]
		var line_y := 101
		for line in lines:
			var l = Label.new()
			l.text = "%s : %d" % [line.text, line.value]
			l.add_theme_color_override("font_color", line.color)
			l.add_theme_font_size_override("font_size", 25)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.position = Vector2(0, line_y)
			l.size = Vector2(panel.size.x, 31)
			panel.add_child(l)
			line_y += 36
		btn_y = line_y + 30

	var btn_w := 336
	var btn_h := 73
	var btn_x := int((panel.size.x - btn_w) / 2)
	var btn_gap := 112

	for i in range(buttons.size()):
		var btn_data = buttons[i]
		var tex = ButtonBuilder.build_button_texture(btn_data["text"], btn_data["font_dir"], Vector2i(22, 28), EMPTY_LONG)
		var btn = TextureButton.new()
		btn.texture_normal = tex
		btn.texture_pressed = ButtonBuilder.darken_texture(tex)
		btn.ignore_texture_size = true
		btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		btn.custom_minimum_size = Vector2(btn_w, btn_h)
		btn.pressed.connect(btn_data["action"])
		btn.pressed.connect(ClickPlayer.play)
		if buttons.size() == 3 and i <= 1:
			var col_x = int((panel.size.x - btn_w * 2 - 28) / 2)
			btn.position = Vector2(col_x + i * (btn_w + 28), btn_y)
			if i == 1:
				btn_y += btn_gap
		else:
			btn.position = Vector2(btn_x, btn_y)
			btn_y += btn_gap
		panel.add_child(btn)

	overlay.add_child(panel)
	hud.add_child(overlay)


func _on_level_complete() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	_clear_sajen()
	var total_earned = jimpitan_collected + pesugihan_earned
	SaveManager.add_coins(total_earned)
	SaveManager.current_level = maxi(SaveManager.current_level, current_level + 1)
	var stars = _calculate_stars()
	SaveManager.set_level_stars(current_level, stars)
	SaveManager.save_game()
	player.hide()
	_show_win_popup(stars)


func _calculate_stars() -> int:
	if coins_stolen_by_thief > 0:
		return 1
	var max_skills = LevelData.get_max_skills_for_3_stars(current_level)
	if _skills_used <= max_skills:
		return 3
	return 2
