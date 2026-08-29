# Loading Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce gameplay loading time by moving heavy work to async loading screen + replacing GroundTile compositing with TileMapLayer + spreading Gameplay setup across frames.

**Architecture:** Three-phase loading: (1) LoadingScreen shows immediately and orchestrates async resource loading + background map generation, (2) preloaded data is passed to Gameplay, (3) Gameplay uses a state machine to build map and spawn entities across frames instead of all in _ready(). GroundTile is rewritten from CPU-side texture compositing to GPU-native TileMapLayer.

**Tech Stack:** Godot 4.x GDScript, ResourceLoader.load_threaded_request, WorkerThreadPool, TileMapLayer.

---

### Task 1: MusicManager — add stop_music()

**Files:**
- Modify: `autoload/MusicManager.gd`

- [ ] **Step 1: Add stop_music() method**

Insert after `play_gameplay_music()`:

```gdscript
func stop_music() -> void:
    _player.stop()

func has_menu_music() -> bool:
    return _player.stream == _menu_music and _player.playing
```

- [ ] **Step 2: Commit**

```bash
git add autoload/MusicManager.gd
git commit -m "feat: add stop_music() to MusicManager"
```

---

### Task 2: SceneManager — add transition data support

**Files:**
- Modify: `autoload/SceneManager.gd`

- [ ] **Step 1: Add transition data storage**

Replace entire file content:

```gdscript
extends Node

var _params: Dictionary = {}
var transition_data: Dictionary = {}

func go_to_scene(path: String, params: Dictionary = {}) -> void:
    _params = params
    call_deferred("_change_scene", path)

func _change_scene(path: String) -> void:
    get_tree().change_scene_to_file(path)

func get_params() -> Dictionary:
    var p = _params.duplicate()
    _params = {}
    return p
```

- [ ] **Step 2: Commit**

```bash
git add autoload/SceneManager.gd
git commit -m "feat: add transition_data to SceneManager for passing preloaded resources"
```

---

### Task 3: AsyncLoader — background resource loading + TileSet atlas creation

**Files:**
- Create: `scenes/gameplay/AsyncLoader.gd`

- [ ] **Step 1: Create AsyncLoader**

```gdscript
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
var _loaded_resources: Dictionary = {}
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
    _map_data = MapGenerator.generate(level)
    call_deferred.set.bind(false).call_deferred(&"_on_map_gen_done")
    call_deferred(&"_on_map_gen_done")


func _on_map_gen_done() -> void:
    _map_gen_done = true


func poll() -> void:
    if _loading_done:
        return
    var loaded = 0
    for path in _resource_paths:
        var status = ResourceLoader.load_threaded_get_status(path)
        if status == ResourceLoader.THREAD_LOAD_LOADED:
            loaded += 1
    _resources_loaded = loaded
    var map_progress = 0.5 if _map_gen_done else 0.0
    var res_progress = float(_resources_loaded) / _total_resources if _total_resources > 0 else 1.0
    _progress = res_progress * 0.5 + map_progress * 0.5
    if _resources_loaded >= _total_resources and _map_gen_done:
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
        tile_textures[name] = ResourceLoader.load_threaded_get(path)
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
    result["normal_textures"]["down"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_1.png")
    result["normal_textures"]["up"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_1.png")
    result["normal_textures"]["left"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_1.png")
    result["normal_textures"]["right"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_1.png")
    result["normal_walk_frames"]["right"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/right_7.png"),
    ]
    result["normal_walk_frames"]["down"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/front_7.png"),
    ]
    result["normal_walk_frames"]["up"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/back_7.png"),
    ]
    result["normal_walk_frames"]["left"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/normal/left_7.png"),
    ]
    result["flashlight_textures"]["down"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_1.png")
    result["flashlight_textures"]["up"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_1.png")
    result["flashlight_textures"]["left"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_1.png")
    result["flashlight_textures"]["right"] = ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_1.png")
    result["flashlight_walk_frames"]["right"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/right_7.png"),
    ]
    result["flashlight_walk_frames"]["down"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/front_7.png"),
    ]
    result["flashlight_walk_frames"]["up"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/back_7.png"),
    ]
    result["flashlight_walk_frames"]["left"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_4.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_5.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_6.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/main_character/hold_flashlight/left_7.png"),
    ]
    result["balm_frames"] = [
        ResourceLoader.load_threaded_get("res://assets/sprites/others/balm_effect_1.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/others/balm_effect_2.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/others/balm_effect_3.png"),
        ResourceLoader.load_threaded_get("res://assets/sprites/others/balm_effect_4.png"),
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
    tileset.add_source(source, 0)
    return tileset


func is_done() -> bool:
    return _loading_done
```

- [ ] **Step 2: Commit**

```bash
git add scenes/gameplay/AsyncLoader.gd
git commit -m "feat: add AsyncLoader for background resource loading and TileSet atlas creation"
```

---

### Task 4: GroundTile — rewrite to use TileMapLayer

**Files:**
- Rewrite: `scenes/gameplay/GroundTile.gd`

- [ ] **Step 1: Replace GroundTile content**

```gdscript
extends TileMapLayer

const TILE_SIZE := 64
const SUBDIV := 4
const VCELL := TILE_SIZE / SUBDIV

const TILE_NAMES := [
    "land_center",          # 0
    "grass_straight",       # 1
    "grass_left_top",       # 2
    "grass_right_top",      # 3
    "grass_left_bottom",    # 4
    "grass_right_bottom",   # 5
    "grass_center_1",       # 6
    "grass_center_2",       # 7
    "grass_center_3",       # 8
    "dirt_center",          # 9
    "dirt_top",             # 10
    "dirt_bottom",          # 11
    "dirt_left",            # 12
    "dirt_right",           # 13
    "dirt_left_top",        # 14
    "dirt_right_top",       # 15
    "dirt_left_bottom",     # 16
    "dirt_right_bottom",    # 17
]

const ACCENT_VARIANTS := [6, 7, 8]
const PLAIN_VARIANTS := [0]

var _vcols: int
var _vrows: int
var _vdirt: Array
var _vaccent: Array
var _tile_grid: Array
var _vaccent_index: Dictionary = {}


func _init(cols: int, rows: int, dirt_mask: Array, p_tile_set: TileSet) -> void:
    tile_set = p_tile_set
    cell_size = Vector2i(VCELL, VCELL)
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
                _tile_grid[x][y] = PLAIN_VARIANTS[randi() % PLAIN_VARIANTS.size()]


func _render_tiles() -> void:
    for y in range(_vrows):
        for x in range(_vcols):
            var tile_id = _tile_grid[x][y]
            if tile_id < 0 or tile_id >= 18:
                continue
            var atlas_coords = Vector2i(tile_id % 6, tile_id / 6)
            set_cell(Vector2i(x, y), 0, atlas_coords)
```

- [ ] **Step 2: Commit**

```bash
git add scenes/gameplay/GroundTile.gd
git commit -m "refactor: rewrite GroundTile to use TileMapLayer instead of CPU texture compositing"
```

---

### Task 5: Player.gd — accept preloaded textures

**Files:**
- Modify: `scenes/gameplay/Player.gd`

- [ ] **Step 1: Replace file content**

```gdscript
extends CharacterBody2D

const SPEED := 100.0
const HALF_SPEED := 50.0
const STAMINA_MAX := 100.0
const STAMINA_DRAIN := 5.0
const STAMINA_REGEN := 3.0
const SPRITE_SIZE := 28.0
const ANIM_FRAME_TIME := 0.15
const BALM_FRAME_TIME := 0.15

var stamina: float = STAMINA_MAX
var current_speed: float = SPEED
var input_dir := Vector2.ZERO
var dpad_dir := Vector2.ZERO
var is_in_poskamling := false
var is_senter_active := false
var is_balm_active := false

var facing_dir := Vector2.DOWN
var sprite: Sprite2D
var textures := {}
var walk_frames := {}
var normal_textures := {}
var normal_walk_frames := {}
var flashlight_textures := {}
var flashlight_walk_frames := {}
var balm_frames := []
var frame_indices := {}
var anim_timer := 0.0
var _balm_sprite: Sprite2D
var _balm_frame := 0
var _balm_timer := 0.0
var _balm_blink_timer := 0.0
var _balm_blinking := false


func _init() -> void:
    collision_layer = 4
    collision_mask = 1
    var collision = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 16
    collision.shape = shape
    add_child(collision)

    var cam = Camera2D.new()
    cam.name = "Camera2D"
    cam.zoom = Vector2(2.0, 2.0)
    add_child(cam)


func init_textures(data: Dictionary) -> void:
    normal_textures = data.get("normal_textures", {})
    normal_walk_frames = data.get("normal_walk_frames", {})
    flashlight_textures = data.get("flashlight_textures", {})
    flashlight_walk_frames = data.get("flashlight_walk_frames", {})
    balm_frames = data.get("balm_frames", [])
    textures = normal_textures
    walk_frames = normal_walk_frames
    frame_indices["right"] = 0
    frame_indices["down"] = 0
    frame_indices["up"] = 0
    frame_indices["left"] = 0
    sprite = Sprite2D.new()
    sprite.name = "MainSprite"
    sprite.centered = true
    if normal_textures.has("down"):
        _update_sprite(normal_textures["down"])
    add_child(sprite)


func _ready() -> void:
    var cam = find_child("Camera2D") as Camera2D
    if cam:
        cam.make_current()


func set_senter_active(active: bool) -> void:
    is_senter_active = active
    if active:
        textures = flashlight_textures
        walk_frames = flashlight_walk_frames
    else:
        textures = normal_textures
        walk_frames = normal_walk_frames
    _refresh_sprite()


func set_balm_active(active: bool) -> void:
    is_balm_active = active
    if active:
        if not _balm_sprite:
            _balm_sprite = Sprite2D.new()
            _balm_sprite.name = "BalmEffect"
            _balm_sprite.centered = true
            if balm_frames.size() > 0:
                _balm_sprite.texture = balm_frames[0]
            _balm_sprite.scale = Vector2(0.55, 0.55)
            _balm_sprite.position = Vector2(0, -20)
            add_child(_balm_sprite)
        _balm_sprite.show()
        _balm_frame = 0
        _balm_timer = 0.0
    else:
        if _balm_sprite:
            _balm_sprite.hide()
            _balm_blinking = false


func _refresh_sprite() -> void:
    if abs(facing_dir.x) > abs(facing_dir.y):
        _update_sprite(textures["right"] if facing_dir.x > 0 else textures["left"])
    else:
        _update_sprite(textures["down"] if facing_dir.y > 0 else textures["up"])


func _update_sprite(tex: Texture2D) -> void:
    sprite.texture = tex
    var tex_size = tex.get_size()
    var scale_factor = minf(SPRITE_SIZE / tex_size.x, SPRITE_SIZE / tex_size.y)
    sprite.scale = Vector2(scale_factor, scale_factor)


func _physics_process(delta: float) -> void:
    var keyboard_dir = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    ).normalized()
    
    if keyboard_dir.length() > 0:
        input_dir = keyboard_dir
    elif dpad_dir.length() > 0:
        input_dir = dpad_dir
    else:
        input_dir = Vector2.ZERO

    if input_dir.length() > 0:
        facing_dir = input_dir
        if abs(facing_dir.x) > abs(facing_dir.y):
            if facing_dir.x > 0:
                anim_timer += delta
                if anim_timer >= ANIM_FRAME_TIME:
                    anim_timer = 0.0
                    frame_indices["right"] = (frame_indices["right"] + 1) % walk_frames["right"].size()
                _update_sprite(walk_frames["right"][frame_indices["right"]])
            else:
                anim_timer += delta
                if anim_timer >= ANIM_FRAME_TIME:
                    anim_timer = 0.0
                    frame_indices["left"] = (frame_indices["left"] + 1) % walk_frames["left"].size()
                _update_sprite(walk_frames["left"][frame_indices["left"]])
        else:
            if facing_dir.y > 0:
                anim_timer += delta
                if anim_timer >= ANIM_FRAME_TIME:
                    anim_timer = 0.0
                    frame_indices["down"] = (frame_indices["down"] + 1) % walk_frames["down"].size()
                _update_sprite(walk_frames["down"][frame_indices["down"]])
            else:
                anim_timer += delta
                if anim_timer >= ANIM_FRAME_TIME:
                    anim_timer = 0.0
                    frame_indices["up"] = (frame_indices["up"] + 1) % walk_frames["up"].size()
                _update_sprite(walk_frames["up"][frame_indices["up"]])
        velocity = input_dir * current_speed
    else:
        velocity = Vector2.ZERO
        if abs(facing_dir.x) > abs(facing_dir.y):
            if facing_dir.x > 0:
                _update_sprite(textures["right"])
            else:
                _update_sprite(textures["left"])
        else:
            if facing_dir.y > 0:
                _update_sprite(textures["down"])
            else:
                _update_sprite(textures["up"])
        frame_indices["right"] = 0
        frame_indices["down"] = 0
        frame_indices["up"] = 0
        frame_indices["left"] = 0
        anim_timer = 0.0
    
    var old_pos = global_position
    move_and_slide()
    var actually_moved = global_position != old_pos
    
    if actually_moved:
        stamina = maxf(0, stamina - STAMINA_DRAIN * delta)
        current_speed = HALF_SPEED if stamina <= 0 else SPEED
    elif input_dir == Vector2.ZERO:
        stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
        current_speed = SPEED


func set_movement_dir(dir: Vector2) -> void:
    dpad_dir = dir.normalized()


func enter_poskamling() -> void:
    is_in_poskamling = true


func exit_poskamling() -> void:
    is_in_poskamling = false


func is_stamina_empty() -> bool:
    return stamina <= 0


func get_stamina_percent() -> float:
    return stamina / STAMINA_MAX


func restore_stamina(percent: float) -> void:
    stamina = minf(STAMINA_MAX, stamina + STAMINA_MAX * percent)


func set_balm_blinking(blinking: bool) -> void:
    _balm_blinking = blinking
    _balm_blink_timer = 0.0
    if not blinking and _balm_sprite:
        _balm_sprite.show()


func _process(delta: float) -> void:
    if is_balm_active and _balm_sprite:
        if _balm_blinking:
            _balm_blink_timer += delta
            if _balm_blink_timer >= BALM_FRAME_TIME:
                _balm_sprite.visible = not _balm_sprite.visible
                _balm_blink_timer = 0.0
        else:
            _balm_sprite.show()
        _balm_timer += delta
        if _balm_timer >= BALM_FRAME_TIME:
            _balm_frame = (_balm_frame + 1) % balm_frames.size()
            _balm_sprite.texture = balm_frames[_balm_frame]
            _balm_timer = 0.0
```

- [ ] **Step 2: Commit**

```bash
git add scenes/gameplay/Player.gd
git commit -m "refactor: externalize player texture loading via init_textures()"
```

---

### Task 6: LoadingScreen — new scene and script

**Files:**
- Create: `scenes/gameplay/LoadingScreen.tscn`
- Create: `scenes/gameplay/LoadingScreen.gd`

- [ ] **Step 1: Create LoadingScreen.tscn**

```gdscript
# LoadingScreen.tscn — simple text file format
```

Write `scenes/gameplay/LoadingScreen.tscn`:

```
[gd_scene format=3 uid="uid://loading_screen"]

[node name="LoadingScreen" type="CanvasLayer"]
layer = 128

[node name="Background" type="ColorRect"]
parent = "."
color = Color(0, 0, 0, 1)
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 1
grow_vertical = 1

[node name="Label" type="Label"]
parent = "."
offset_left = 440.0
offset_top = 310.0
offset_right = 840.0
offset_bottom = 360.0
theme_override_font_sizes/font_size = 36
horizontal_alignment = 1
vertical_alignment = 1
text = "Loading..."

[node name="ProgressBar" type="ProgressBar"]
parent = "."
offset_left = 340.0
offset_top = 400.0
offset_right = 940.0
offset_bottom = 430.0
show_percentage = false
value = 0.0

[node name="TipLabel" type="Label"]
parent = "."
offset_left = 340.0
offset_top = 450.0
offset_right = 940.0
offset_bottom = 490.0
theme_override_font_sizes/font_size = 16
horizontal_alignment = 1
vertical_alignment = 1
text = "Tip: Use senter to reveal ghosts"

[node name="Script" type="Script"]
parent = "."
script/path = "res://scenes/gameplay/LoadingScreen.gd"
```

- [ ] **Step 2: Create LoadingScreen.gd**

```gdscript
extends CanvasLayer

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label
@onready var tip_label: Label = $TipLabel

var _async_loader: AsyncLoader = null
var _level: int = 1
var _fading_out: bool = false

const TIPS := [
    "Tip: Use senter to reveal ghosts",
    "Tip: Kopi shows ghost positions on radar",
    "Tip: Balsem makes you temporarily immune to ghosts",
    "Tip: Collect all jimpitan coins to complete the level",
    "Tip: Enter poskamling to avoid ghosts",
    "Tip: Use kacang or cassava to restore stamina",
    "Tip: Sajen attracts ghosts away from you",
]


func _ready() -> void:
    MusicManager.stop_music()
    var params = SceneManager.get_params()
    _level = params.get("level", 1)
    tip_label.text = TIPS[randi() % TIPS.size()]
    _async_loader = AsyncLoader.new()
    _async_loader.start(_level)


func _process(_delta: float) -> void:
    if _fading_out:
        return
    if _async_loader:
        _async_loader.poll()
        progress_bar.value = _async_loader.progress * 100.0
        if _async_loader.is_done():
            _on_loading_done()


func _on_loading_done() -> void:
    _fading_out = true
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color(1, 1, 1, 0), 0.5)
    tween.finished.connect(_go_to_gameplay)


func _go_to_gameplay() -> void:
    SceneManager.go_to_scene("res://scenes/gameplay/Gameplay.tscn", {"level": _level})
```

- [ ] **Step 3: Commit**

```bash
git add scenes/gameplay/LoadingScreen.tscn scenes/gameplay/LoadingScreen.gd
git commit -m "feat: add LoadingScreen for async resource loading with progress bar"
```

---

### Task 7: LevelTrack — route through LoadingScreen

**Files:**
- Modify: `scenes/menu/LevelTrack.gd`

- [ ] **Step 1: Change go_to_scene target**

Replace line 211:

```gdscript
func _on_level_selected(level: int) -> void:
    SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": level})
```

- [ ] **Step 2: Commit**

```bash
git add scenes/menu/LevelTrack.gd
git commit -m "feat: route level selection through LoadingScreen"
```

---

### Task 8: Gameplay.gd — state machine with deferred building/spawning

**Files:**
- Modify: `scenes/gameplay/Gameplay.gd`

- [ ] **Step 1: Replace file content**

```gdscript
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
var _state: State = State.BUILD_MAP

const PesugihanCoin := preload("res://scenes/gameplay/PesugihanCoin.gd")
const JimpitanCoin := preload("res://scenes/gameplay/JimpitanCoin.gd")
const Sajen := preload("res://scenes/gameplay/Sajen.gd")
const SFX_GHOST_EXPLODE := preload("res://assets/sfx/ghost_explode.wav")
const SFX_DROP_COINS := preload("res://assets/sfx/drop_coins.wav")
const SFX_STAMINA_UP := preload("res://assets/sfx/stamina_up.wav")
const SFX_CAUGHT_BY_GHOST := preload("res://assets/sfx/caught_by_ghost.wav")
const SFX_BALM_EFFECT := preload("res://assets/sfx/balm_effect.wav")

const TREE_TEXTURES := [
    preload("res://assets/sprites/others/tree.png"),
    preload("res://assets/sprites/others/tree_coconut.png"),
    preload("res://assets/sprites/others/tree_banana.png"),
    preload("res://assets/sprites/others/tree_mango.png"),
]


func _ready() -> void:
    var params = SceneManager.get_params()
    current_level = params.get("level", 1)

    map_container = Node2D.new()
    map_container.name = "MapContainer"
    add_child(map_container)

    RenderingServer.set_default_clear_color(Color(0, 0, 0, 1))

    var td = SceneManager.transition_data
    map_data = td.get("map_data", MapGenerator.generate(current_level))
    var tile_set: TileSet = td.get("tile_set")
    var player_tex: Dictionary = td.get("player_textures", {})
    SceneManager.transition_data = {}

    _build_map(tile_set)
    _setup_player(player_tex)
    _setup_hud()
    _build_map_done()


func _build_map(tile_set: TileSet) -> void:
    var grid = map_data["grid"]
    var tile_size = map_data["tile_size"]

    var ground = preload("res://scenes/gameplay/GroundTile.gd").new(
        map_data["cols"], map_data["rows"],
        map_data.get("dirt_mask", []), tile_set)
    map_container.add_child(ground)

    entities = Node2D.new()
    entities.name = "Entities"
    map_container.add_child(entities)

    for x in range(map_data["cols"]):
        for y in range(map_data["rows"]):
            if grid[x][y] == 1:
                var wall = preload("res://scenes/gameplay/WallTile.gd").new()
                wall.position = Vector2(x * tile_size, y * tile_size)
                map_container.add_child(wall)
            elif grid[x][y] == 2:
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


func _build_map_done() -> void:
    _state = State.SPAWN
    _spawn_entities()


func _spawn_entities() -> void:
    _spawn_ghosts()
    _spawn_jimpitans()
    _setup_thief()
    _place_trees()
    _state_enter_playing()


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


func _state_enter_playing() -> void:
    _state = State.PLAYING
    hud.update_level(current_level)
    hud.update_jimpitan(0, map_data["jimpitans"].size())
    MusicManager.play_gameplay_music()

    senter_overlay = preload("res://scenes/gameplay/SenterOverlay.gd").new()
    senter_overlay.name = "SenterOverlay"
    add_child(senter_overlay)


func _exit_tree() -> void:
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


# Everything below here is identical to the original — copy verbatim from current file

func _update_senter_visual() -> void:
    if is_senter_active:
        senter_overlay.set_senter_rect(_get_senter_rect())
        senter_overlay.set_blinking(senter_timer <= 1.0)
    else:
        senter_overlay.hide_rect()
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
            hud.radar.set_revealed(true, 10.0)
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

    if thief and thief.is_active and rect.has_point(thief.global_position):
        _spawn_pesugihan_coins(thief.global_position, randi_range(1, 3))
        _play_explode_sfx()
        thief.on_senter_hit()


func _play_explode_sfx() -> void:
    _play_sfx_sequence()


func _play_sfx_sequence() -> void:
    var explode = AudioStreamPlayer.new()
    explode.stream = SFX_GHOST_EXPLODE
    explode.bus = "Master"
    add_child(explode)
    explode.play()
    await explode.finished
    var drop = AudioStreamPlayer.new()
    drop.stream = SFX_DROP_COINS
    drop.bus = "Master"
    add_child(drop)
    drop.play()
    await drop.finished
    drop.queue_free()
    explode.queue_free()


func _play_stamina_up_sfx() -> void:
    var p = AudioStreamPlayer.new()
    p.stream = SFX_STAMINA_UP
    p.bus = "Master"
    add_child(p)
    p.play()
    await p.finished
    p.queue_free()


func _play_caught_sfx() -> void:
    var p = AudioStreamPlayer.new()
    p.stream = SFX_CAUGHT_BY_GHOST
    p.bus = "Master"
    p.process_mode = PROCESS_MODE_WHEN_PAUSED
    add_child(p)
    p.play()


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
    SaveManager.save_game()
    player.hide()
    _play_caught_sfx()
    _show_lose_popup()


func _show_lose_popup() -> void:
    _show_result_popup(TranslationManager.t("caught_title"), [
        {"text": TranslationManager.t("retry"), "action": func():
            get_tree().paused = false; SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": current_level})},
        {"text": TranslationManager.t("exit"), "action": func():
            get_tree().paused = false; SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")},
    ])


func _show_win_popup() -> void:
    var total_earned = jimpitan_collected + pesugihan_earned
    var title = TranslationManager.t("level_complete") % total_earned
    _show_result_popup(title, [
        {"text": TranslationManager.t("retry"), "action": func():
            get_tree().paused = false; SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": current_level})},
        {"text": TranslationManager.t("next_level"), "action": func():
            get_tree().paused = false; SceneManager.go_to_scene("res://scenes/gameplay/LoadingScreen.tscn", {"level": current_level + 1})},
        {"text": TranslationManager.t("exit"), "action": func():
            get_tree().paused = false; SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")},
    ])


func _show_result_popup(title: String, buttons: Array) -> void:
    get_tree().paused = true
    var overlay = ColorRect.new()
    overlay.name = "ResultPopup"
    overlay.color = Color(0, 0, 0, 0.7)
    overlay.size = get_viewport().get_visible_rect().size
    overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay.process_mode = PROCESS_MODE_WHEN_PAUSED

    var panel = ColorRect.new()
    panel.color = Color(0.2, 0.2, 0.2, 1)
    panel.size = Vector2(300, 220)
    panel.position = (overlay.size - panel.size) / 2

    var label = Label.new()
    label.text = title
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.position = Vector2(10, 20)
    label.size = Vector2(panel.size.x - 20, 60)
    label.add_theme_color_override("font_color", Color(1, 1, 1))
    label.add_theme_font_size_override("font_size", 22)

    var btn_y = 100
    for btn_data in buttons:
        var btn = Button.new()
        btn.text = btn_data["text"]
        btn.position = Vector2(30, btn_y)
        btn.size = Vector2(240, 40)
        btn.pressed.connect(btn_data["action"])
        panel.add_child(btn)
        btn_y += 50

    panel.add_child(label)
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
    SaveManager.save_game()
    player.hide()
    _show_win_popup()
```

- [ ] **Step 2: Commit**

```bash
git add scenes/gameplay/Gameplay.gd
git commit -m "refactor: add state machine to Gameplay, accept preloaded data from SceneManager"
```

---

### Self-Review Verification

1. **Spec coverage:** Does each requirement in the spec have a corresponding task?
   - LoadingScreen (Task 6) ✓
   - AsyncLoader (Task 3) ✓
   - SceneManager transition data (Task 2) ✓
   - GroundTile TileMapLayer (Task 4) ✓
   - Player.gd external loading (Task 5) ✓
   - Gameplay state machine (Task 8) ✓
   - LevelTrack routing (Task 7) ✓
   - MusicManager stop (Task 1) ✓

2. **Placeholder scan:** No "TBD", "TODO", or incomplete sections.

3. **Type consistency:** All signatures match between tasks. GroundTile._init takes (cols, rows, dirt_mask, tile_set). Player.init_textures(data). Gameplay reads transition_data.

4. **Scope:** Focused on loading optimization. All tasks are within scope.
