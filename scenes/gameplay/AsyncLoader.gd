class_name AsyncLoader
extends RefCounted

const TILE_NAMES := [
    "land_center", "grass_straight", "grass_left_top", "grass_right_top",
    "grass_left_bottom", "grass_right_bottom",
    "grass_center_1", "grass_center_2", "grass_center_3",
    "dirt_center", "dirt_top", "dirt_bottom", "dirt_left", "dirt_right",
    "dirt_left_top", "dirt_right_top", "dirt_left_bottom", "dirt_right_bottom",
]

const TILE_SIZE := 64
const SUBDIV := 4
const VCELL := TILE_SIZE / SUBDIV
const TILES_DIR := "res://assets/sprites/ground_tiles/"

var progress: float:
    get:
        return _progress
var _progress: float = 0.0

var _resource_paths: Array[String] = []

var _map_data: Dictionary = {}
var _tile_set: TileSet = null
var _loading_done: bool = false
var _map_gen_done: bool = false
var _resources_loaded: int = 0
var _total_resources: int = 0
var _thread: Thread = null


func start(level: int) -> void:
    _build_resource_list()
    _total_resources = _resource_paths.size()
    _start_async_loads()
    _start_map_gen(level)


func _build_resource_list() -> void:
    _resource_paths = []
    for name in TILE_NAMES:
        _resource_paths.append(TILES_DIR + name + ".png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_1.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_1.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_1.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_1.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_2.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_3.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_4.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_5.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_6.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/right_7.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_2.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_3.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_4.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_5.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_6.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/front_7.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_2.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_3.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_4.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_5.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_6.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/back_7.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_2.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_3.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_4.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_5.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_6.png")
    _resource_paths.append("res://assets/sprites/main_character/normal/left_7.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_1.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_1.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_1.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_1.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_2.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_3.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_4.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_5.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_6.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/right_7.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_2.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_3.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_4.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_5.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_6.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/front_7.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_2.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_3.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_4.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_5.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_6.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/back_7.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_2.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_3.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_4.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_5.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_6.png")
    _resource_paths.append("res://assets/sprites/main_character/hold_flashlight/left_7.png")
    _resource_paths.append("res://assets/sprites/others/tree.png")
    _resource_paths.append("res://assets/sprites/others/tree_coconut.png")
    _resource_paths.append("res://assets/sprites/others/tree_banana.png")
    _resource_paths.append("res://assets/sprites/others/tree_mango.png")
    _resource_paths.append("res://assets/sprites/others/balm_effect_1.png")
    _resource_paths.append("res://assets/sprites/others/balm_effect_2.png")
    _resource_paths.append("res://assets/sprites/others/balm_effect_3.png")
    _resource_paths.append("res://assets/sprites/others/balm_effect_4.png")
    _resource_paths.append("res://assets/sfx/ghost_explode.wav")
    _resource_paths.append("res://assets/sfx/drop_coins.wav")
    _resource_paths.append("res://assets/sfx/stamina_up.wav")
    _resource_paths.append("res://assets/sfx/caught_by_ghost.wav")
    _resource_paths.append("res://assets/sfx/balm_effect.wav")


func _start_async_loads() -> void:
    for path in _resource_paths:
        ResourceLoader.load_threaded_request(path)


func _start_map_gen(level: int) -> void:
    _thread = Thread.new()
    _thread.start(_map_gen_thread.bind(level))


func _map_gen_thread(level: int) -> void:
    var data = MapGenerator.generate(level)
    call_deferred(&"_on_map_gen_done", data)


func _on_map_gen_done(data: Dictionary) -> void:
    _map_data = data
    _map_gen_done = true


func poll() -> void:
    if _loading_done:
        return
    var loaded = 0
    var failed = 0
    for path in _resource_paths:
        var status = ResourceLoader.load_threaded_get_status(path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            loaded += 1
        elif status == ResourceLoader.THREAD_LOAD_FAILED:
            failed += 1
    _resources_loaded = loaded
    var map_progress = 1.0 if _map_gen_done else 0.0
    var res_progress = float(_resources_loaded) / _total_resources if _total_resources > 0 else 1.0
    _progress = res_progress * 0.5 + map_progress * 0.5
    if loaded + failed >= _total_resources and _map_gen_done:
        _finalize()
        _loading_done = true
        _progress = 1.0


func _finalize() -> void:
    if _thread:
        _thread.wait_to_finish()
        _thread = null
    var tile_textures: Dictionary = {}
    for name in TILE_NAMES:
        var path = TILES_DIR + name + ".png"
        var tex = _safe_get(path)
        if tex:
            tile_textures[name] = tex
    _tile_set = _build_tile_set(tile_textures)
    var player_textures = _collect_player_textures()
    SceneManager.transition_data = {
        "map_data": _map_data,
        "tile_set": _tile_set,
        "player_textures": player_textures,
    }


func _collect_player_textures() -> Dictionary:
    var result = {
        "normal_textures": {},
        "normal_walk_frames": {},
        "flashlight_textures": {},
        "flashlight_walk_frames": {},
        "balm_frames": [],
    }
    result["normal_textures"]["down"] = _safe_get("res://assets/sprites/main_character/normal/front_1.png")
    result["normal_textures"]["up"] = _safe_get("res://assets/sprites/main_character/normal/back_1.png")
    result["normal_textures"]["left"] = _safe_get("res://assets/sprites/main_character/normal/left_1.png")
    result["normal_textures"]["right"] = _safe_get("res://assets/sprites/main_character/normal/right_1.png")
    result["normal_walk_frames"]["right"] = [
        _safe_get("res://assets/sprites/main_character/normal/right_2.png"),
        _safe_get("res://assets/sprites/main_character/normal/right_3.png"),
        _safe_get("res://assets/sprites/main_character/normal/right_4.png"),
        _safe_get("res://assets/sprites/main_character/normal/right_5.png"),
        _safe_get("res://assets/sprites/main_character/normal/right_6.png"),
        _safe_get("res://assets/sprites/main_character/normal/right_7.png"),
    ]
    result["normal_walk_frames"]["down"] = [
        _safe_get("res://assets/sprites/main_character/normal/front_2.png"),
        _safe_get("res://assets/sprites/main_character/normal/front_3.png"),
        _safe_get("res://assets/sprites/main_character/normal/front_4.png"),
        _safe_get("res://assets/sprites/main_character/normal/front_5.png"),
        _safe_get("res://assets/sprites/main_character/normal/front_6.png"),
        _safe_get("res://assets/sprites/main_character/normal/front_7.png"),
    ]
    result["normal_walk_frames"]["up"] = [
        _safe_get("res://assets/sprites/main_character/normal/back_2.png"),
        _safe_get("res://assets/sprites/main_character/normal/back_3.png"),
        _safe_get("res://assets/sprites/main_character/normal/back_4.png"),
        _safe_get("res://assets/sprites/main_character/normal/back_5.png"),
        _safe_get("res://assets/sprites/main_character/normal/back_6.png"),
        _safe_get("res://assets/sprites/main_character/normal/back_7.png"),
    ]
    result["normal_walk_frames"]["left"] = [
        _safe_get("res://assets/sprites/main_character/normal/left_2.png"),
        _safe_get("res://assets/sprites/main_character/normal/left_3.png"),
        _safe_get("res://assets/sprites/main_character/normal/left_4.png"),
        _safe_get("res://assets/sprites/main_character/normal/left_5.png"),
        _safe_get("res://assets/sprites/main_character/normal/left_6.png"),
        _safe_get("res://assets/sprites/main_character/normal/left_7.png"),
    ]
    result["flashlight_textures"]["down"] = _safe_get("res://assets/sprites/main_character/hold_flashlight/front_1.png")
    result["flashlight_textures"]["up"] = _safe_get("res://assets/sprites/main_character/hold_flashlight/back_1.png")
    result["flashlight_textures"]["left"] = _safe_get("res://assets/sprites/main_character/hold_flashlight/left_1.png")
    result["flashlight_textures"]["right"] = _safe_get("res://assets/sprites/main_character/hold_flashlight/right_1.png")
    result["flashlight_walk_frames"]["right"] = [
        _safe_get("res://assets/sprites/main_character/hold_flashlight/right_2.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/right_3.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/right_4.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/right_5.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/right_6.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/right_7.png"),
    ]
    result["flashlight_walk_frames"]["down"] = [
        _safe_get("res://assets/sprites/main_character/hold_flashlight/front_2.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/front_3.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/front_4.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/front_5.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/front_6.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/front_7.png"),
    ]
    result["flashlight_walk_frames"]["up"] = [
        _safe_get("res://assets/sprites/main_character/hold_flashlight/back_2.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/back_3.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/back_4.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/back_5.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/back_6.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/back_7.png"),
    ]
    result["flashlight_walk_frames"]["left"] = [
        _safe_get("res://assets/sprites/main_character/hold_flashlight/left_2.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/left_3.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/left_4.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/left_5.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/left_6.png"),
        _safe_get("res://assets/sprites/main_character/hold_flashlight/left_7.png"),
    ]
    result["balm_frames"] = [
        _safe_get("res://assets/sprites/others/balm_effect_1.png"),
        _safe_get("res://assets/sprites/others/balm_effect_2.png"),
        _safe_get("res://assets/sprites/others/balm_effect_3.png"),
        _safe_get("res://assets/sprites/others/balm_effect_4.png"),
    ]
    return result


func _build_tile_set(tile_textures: Dictionary) -> TileSet:
    var atlas_w = 6 * VCELL
    var atlas_h = 3 * VCELL
    var atlas_image = Image.create(atlas_w, atlas_h, false, Image.FORMAT_RGBA8)
    for tile_id in range(18):
        var tile_name = TILE_NAMES[tile_id]
        var tex = tile_textures.get(tile_name)
        if not tex:
            continue
        var img = tex.get_image()
        img.convert(Image.FORMAT_RGBA8)
        img.resize(VCELL, VCELL, Image.INTERPOLATE_NEAREST)
        var col = tile_id % 6
        var row = tile_id / 6
        atlas_image.blit_rect(img, Rect2i(0, 0, VCELL, VCELL), Vector2i(col * VCELL, row * VCELL))
    var atlas_texture = ImageTexture.create_from_image(atlas_image)
    var tileset = TileSet.new()
    var source = TileSetAtlasSource.new()
    source.texture = atlas_texture
    source.texture_region_size = Vector2i(VCELL, VCELL)
    for tile_id in range(18):
        var col = tile_id % 6
        var row = tile_id / 6
        source.create_tile(Vector2i(col, row), Vector2i(1, 1))
    tileset.tile_size = Vector2i(VCELL, VCELL)
    tileset.add_source(source, 0)
    return tileset


func _safe_get(path: String):
    return ResourceLoader.load_threaded_get(path) if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED else null


func is_done() -> bool:
    return _loading_done
