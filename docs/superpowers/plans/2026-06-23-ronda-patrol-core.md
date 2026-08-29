# Ronda Patrol — Core Game Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the core Ronda Patrol game: procedural top-down map, player movement with stamina, ghost patrol+chase AI, thief, item skills, 4 screens (main, story, level track, gameplay). Placeholder assets only.

**Architecture:** 2 autoloads (SaveManager, SceneManager), 3 static data classes (GhostDatabase, LevelData, ItemData domain-scene structure following JapasTycoon patterns. Each screen is its own .tscn + .gd pair.

**Tech Stack:** Godot 4.6, GDScript, no external dependencies

---

### Task 1: Project Scaffolding

**Files:**
- Create: `project.godot`
- Create: `.godotignore`
- Create: directory structure (autoload/, scenes/main/, scenes/menu/, scenes/gameplay/, scenes/hud/, scripts/, resources/, assets/placeholder/)

- [ ] **Step 1: Create project.godot**

```gdscript
[application]
config/name="Ronda Patrol"
config/icon=""
run/main_scene="res://scenes/main/Main.tscn"

[display]
window/size/viewport_width=480
window/size/viewport_height=800
window/stretch/mode="viewport"
window/stretch/aspect="expand"

[input]
ui_left=[Object(InputEventKey,"keycode":65)]
ui_right=[Object(InputEventKey,"keycode":68)]
ui_up=[Object(InputEventKey,"keycode":87)]
ui_down=[Object(InputEventKey,"keycode":83)]
```

- [ ] **Step 2: Create directory structure**

Run:
```bash
mkdir -p autoload scenes/main scenes/menu scenes/gameplay scenes/hud scripts resources assets/placeholder
```

- [ ] **Step 3: Create .godotignore**

```
.godot/
*.import
```

---

### Task 2: Static Data Classes

**Files:**
- Create: `scripts/GhostDatabase.gd`
- Create: `scripts/LevelData.gd`
- Create: `scripts/ItemData.gd`
- Create: `resources/ghosts.json`

- [ ] **Step 1: Create GhostDatabase.gd**

```gdscript
class_name GhostDatabase
extends RefCounted

static func get_ghost_data(index: int) -> Dictionary:
    var db = _load_db()
    if index < 0 or index >= db.size():
        return {}
    return db[index]

static func get_unlocked_count(current_level: int) -> int:
    return clampi(5 + (current_level / 10), 1, _load_db().size())

static func get_total_ghost_count() -> int:
    return _load_db().size()

static func _load_db() -> Array:
    var file = FileAccess.open("res://resources/ghosts.json", FileAccess.READ)
    if not file:
        return []
    var json = JSON.parse_string(file.get_as_text())
    if json is Array:
        return json
    return []
```

- [ ] **Step 2: Create ghosts.json**

```json
[
  {"id":0,"name":"Kuntilanak","desc":"Roh wanita meninggal saat melahirkan","unlock_level":1},
  {"id":1,"name":"Pocong","desc":"Mayat terikat kain kafan","unlock_level":1},
  {"id":2,"name":"Genderuwo","desc":"Sosok raksasa berbulu","unlock_level":1},
  {"id":3,"name":"Sundel Bolong","desc":"Wanita dengan punggung berlubang","unlock_level":1},
  {"id":4,"name":"Wewe Gombel","desc":"Roh wanita penculik anak","unlock_level":1},
  {"id":5,"name":"Kuyang","desc":"Kepala melayang dengan organ dalam","unlock_level":11},
  {"id":6,"name":"Palasik","desc":"Praktisi ilmu hitam yang lepas kepala","unlock_level":11},
  {"id":7,"name":"Tuyul","desc":"Makhluk kecil pencuri uang","unlock_level":21}
]
```

(All 84 ghosts from ghosts_list file, each with incrementing id, name, desc, and unlock_level = 1 + (id / 10) * 10)

- [ ] **Step 3: Create LevelData.gd**

```gdscript
class_name LevelData
extends RefCounted

static func get_map_size(level: int) -> Vector2i:
    var s = 10 + mini(level, 30)
    return Vector2i(s, s)

static func get_building_count(level: int) -> int:
    return clampi(3 + mini(level, 67), 3, 70)

static func get_jimpitan_quota(level: int) -> int:
    return clampi(5 + level * 2, 5, 200)

static func get_ghost_count(walkable_area: int) -> int:
    return maxi(3, walkable_area / 30)

static func get_thief_chance(level: int) -> float:
    return clampf(0.1 + mini(level, 80) * 0.005, 0.1, 0.5)

static func get_pesugihan_value(ghost_index: int) -> int:
    return clampi(10 + ghost_index * 2, 10, 200)
```

- [ ] **Step 4: Create ItemData.gd**

```gdscript
class_name ItemData
extends RefCounted

enum ItemType { SENTER, KOPI, BALSEM, KACANG_REBUS }

static func get_items() -> Dictionary:
    return {
        "senter": {"name": "Senter", "price": 50, "effect": "pesugihan", "type": ItemType.SENTER, "duration": 5.0},
        "kopi": {"name": "Kopi", "price": 30, "effect": "reveal_ghosts", "type": ItemType.KOPI, "duration": 5.0},
        "balsem": {"name": "Balsem", "price": 40, "effect": "immunity", "type": ItemType.BALSEM, "duration": 5.0},
        "kacang_rebus": {"name": "Kacang Rebus", "price": 20, "effect": "restore_stamina", "type": ItemType.KACANG_REBUS, "duration": 0.0}
    }

static func get_item(id: String) -> Dictionary:
    return get_items().get(id, {})
```

---

### Task 3: Autoloads — SaveManager

**Files:**
- Create: `autoload/SaveManager.gd`

- [ ] **Step 1: Create SaveManager.gd**

```gdscript
extends Node

signal coins_changed(amount: int)
signal level_changed(level: int)

const SAVE_FILE := "user://ronda_patrol.save"
const PASS := "r0nd4_p4tr0l_k3y"

var total_coins: int = 0:
    set(v):
        total_coins = v
        coins_changed.emit(total_coins)

var current_level: int = 1:
    set(v):
        current_level = v
        level_changed.emit(current_level)

var inventory: Dictionary = {}  # item_id -> count

func _ready() -> void:
    load_game()

func save_game() -> void:
    var data = {
        "total_coins": total_coins,
        "current_level": current_level,
        "inventory": inventory
    }
    var json_str = JSON.stringify(data)
    var buffer = json_str.to_utf8_buffer()
    # PKCS7 padding
    var pad_len = 16 - (buffer.size() % 16)
    buffer.resize(buffer.size() + pad_len)
    for i in range(buffer.size() - pad_len, buffer.size()):
        buffer[i] = pad_len

    var key = PASS.sha256_text()
    var iv = Crypto.new().generate_random_bytes(16)
    var ctx = Crypto.new()
    var encrypted = ctx.encrypt(Crypto.KEY_AES, key.sha256_buffer(), buffer, Crypto.MODE_CBC, iv)
    var hash = (iv + encrypted).sha256_buffer()
    var out = iv + encrypted + hash
    var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
    if file:
        file.store_buffer(out)
        file.close()

func load_game() -> void:
    var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
    if not file:
        return
    var bytes = file.get_buffer(file.get_length())
    file.close()
    if bytes.size() < 48:
        return

    var iv = bytes.slice(0, 16)
    var hash = bytes.slice(bytes.size() - 32, bytes.size())
    var encrypted = bytes.slice(16, bytes.size() - 32)

    if (iv + encrypted).sha256_buffer() != hash:
        return  # integrity check failed
    var key = PASS.sha256_text()
    var ctx = Crypto.new()
    var decrypted = ctx.decrypt(Crypto.KEY_AES, key.sha256_buffer(), encrypted, Crypto.MODE_CBC, iv)

    # PKCS7 unpad
    var pad_len = decrypted[decrypted.size() - 1]
    if pad_len > 16:
        return
    decrypted.resize(decrypted.size() - pad_len)

    var json_str = decrypted.get_string_from_utf8()
    var data = JSON.parse_string(json_str)
    if not data is Dictionary:
        return
    total_coins = data.get("total_coins", 0)
    current_level = data.get("current_level", 1)
    inventory = data.get("inventory", {})

func has_item(id: String) -> bool:
    return inventory.get(id, 0) > 0

func use_item(id: String) -> void:
    if inventory.get(id, 0) > 0:
        inventory[id] -= 1
        if inventory[id] <= 0:
            inventory.erase(id)
        save_game()

func add_item(id: String, count: int = 1) -> void:
    inventory[id] = inventory.get(id, 0) + count
    save_game()

func add_coins(amount: int) -> void:
    total_coins += amount
    save_game()

func spend_coins(amount: int) -> bool:
    if total_coins >= amount:
        total_coins -= amount
        save_game()
        return true
    return false
```

---

### Task 4: Autoloads — SceneManager

**Files:**
- Create: `autoload/SceneManager.gd`

- [ ] **Step 1: Create SceneManager.gd**

```gdscript
extends Node

var _params: Dictionary = {}

func go_to_scene(path: String, params: Dictionary = {}) -> void:
    _params = params
    get_tree().change_scene_to_file(path)

func get_params() -> Dictionary:
    var p = _params.duplicate()
    _params = {}
    return p
```

---

### Task 5: MainMenu Scene

**Files:**
- Create: `scenes/menu/MainMenu.tscn`
- Create: `scenes/menu/MainMenu.gd`

- [ ] **Step 1: Create MainMenu.gd**

```gdscript
extends Control

@onready var story_btn := $VBox/StoryButton
@onready var play_btn := $VBox/PlayButton
@onready var exit_btn := $VBox/ExitButton

func _ready() -> void:
    story_btn.pressed.connect(_on_story_pressed)
    play_btn.pressed.connect(_on_play_pressed)
    exit_btn.pressed.connect(_on_exit_pressed)

func _on_story_pressed() -> void:
    SceneManager.go_to_scene("res://scenes/menu/StoryPage.tscn")

func _on_play_pressed() -> void:
    SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")

func _on_exit_pressed() -> void:
    get_tree().quit()
```

- [ ] **Step 2: Create MainMenu.tscn**

Create a Control node with VBoxContainer centered:
- Label "RONDA PATROL" (logo placeholder)
- Button "Story" → story_btn
- Button "Play" → play_btn
- Button "Exit" → exit_btn
- Label at bottom: "How to play: Collect all jimpitan coins while avoiding ghosts!"

---

### Task 6: StoryPage Scene

**Files:**
- Create: `scenes/menu/StoryPage.tscn`
- Create: `scenes/menu/StoryPage.gd`

- [ ] **Step 1: Create StoryPage.gd**

```gdscript
extends Control

@onready var close_btn := $TopBar/CloseButton
@onready var story_label := $StoryArea/StoryLabel
@onready var image_rect := $ImageArea/TextureRect
@onready var prev_btn := $NavBar/PrevButton
@onready var next_btn := $NavBar/NextButton
@onready var page_label := $NavBar/PageLabel

var current_page := 0
var pages := [
    {"image": null, "text": "Welcome to Ronda Patrol!\n\nIn a quiet village, the spirits of Nusantara roam freely. As a member of the neighborhood watch (Ronda), it's your duty to patrol the streets and protect the villagers."},
    {"image": null, "text": "Use your senter to expose ghosts and collect pesugihan. Drink kopi to see their positions on the radar. Rub balsem for temporary immunity. Eat kacang rebus to restore stamina."},
    {"image": null, "text": "Beware of the thief! He will steal your items and coins. But with courage and the right tools, you can defend yourself and your village!"}
]

func _ready() -> void:
    close_btn.pressed.connect(_on_close_pressed)
    prev_btn.pressed.connect(_on_prev_pressed)
    next_btn.pressed.connect(_on_next_pressed)
    _show_page()

func _show_page() -> void:
    var page = pages[current_page]
    story_label.text = page["text"]
    prev_btn.visible = current_page > 0
    next_btn.text = "Finish" if current_page >= pages.size() - 1 else "Next"
    page_label.text = "%d / %d" % [current_page + 1, pages.size()]

func _on_close_pressed() -> void:
    SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")

func _on_prev_pressed() -> void:
    current_page -= 1
    _show_page()

func _on_next_pressed() -> void:
    if current_page >= pages.size() - 1:
        SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")
    else:
        current_page += 1
        _show_page()
```

- [ ] **Step 2: Create StoryPage.tscn**

Control with three vertical areas:
- TopBar: CloseButton (top-right)
- ImageArea: TextureRect (placeholder rect)
- StoryArea: StoryLabel (scrollable text area)
- NavBar: PrevButton, PageLabel, NextButton

---

### Task 7: LevelTrack Scene

**Files:**
- Create: `scenes/menu/LevelTrack.tscn`
- Create: `scenes/menu/LevelTrack.gd`

- [ ] **Step 1: Create LevelTrack.gd**

```gdscript
extends Control

@onready var status_label := $Header/StatusLabel
@onready var treasury_label := $Header/TreasuryLabel
@onready var level_track := $LevelTrack/GridContainer
@onready var shop_container := $Shop/GridContainer
@onready var main_menu_btn := $Footer/MainMenuButton
@onready var item_template := preload("res://scenes/hud/ShopItem.tscn")

var item_ids := ["senter", "kopi", "balsem", "kacang_rebus"]

func _ready() -> void:
    _update_header()
    _build_level_track()
    _build_shop()
    main_menu_btn.pressed.connect(_on_main_menu_pressed)

func _update_header() -> void:
    status_label.text = "Status: Ready"
    treasury_label.text = "Regional treasury: %d coins" % SaveManager.total_coins

func _build_level_track() -> void:
    for lvl in range(1, SaveManager.current_level + 6):
        var btn = Button.new()
        btn.text = "Lv.%d" % lvl
        btn.disabled = lvl > SaveManager.current_level
        if lvl == SaveManager.current_level:
            btn.add_theme_color_override("font_color", Color.YELLOW)
        btn.pressed.connect(_on_level_selected.bind(lvl))
        level_track.add_child(btn)

func _build_shop() -> void:
    for id in item_ids:
        var data = ItemData.get_item(id)
        var panel = Panel.new()
        var vbox = VBoxContainer.new()
        var name_label = Label.new()
        name_label.text = data.get("name", id)
        var price_label = Label.new()
        price_label.text = "%d coins" % data.get("price", 0)
        var buy_btn = Button.new()
        buy_btn.text = "Buy"
        buy_btn.pressed.connect(_on_buy_pressed.bind(id))
        vbox.add_child(name_label)
        vbox.add_child(price_label)
        vbox.add_child(buy_btn)
        panel.add_child(vbox)
        shop_container.add_child(panel)

func _on_buy_pressed(item_id: String) -> void:
    var data = ItemData.get_item(item_id)
    if SaveManager.spend_coins(data.get("price", 0)):
        SaveManager.add_item(item_id)
        _update_header()

func _on_level_selected(level: int) -> void:
    SceneManager.go_to_scene("res://scenes/gameplay/Gameplay.tscn", {"level": level})

func _on_main_menu_pressed() -> void:
    SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")
```

- [ ] **Step 2: Create LevelTrack.tscn**

Control with vertical layout:
- Header: StatusLabel, TreasuryLabel
- LevelTrack: GridContainer (scrollable level buttons)
- Shop: GridContainer with 4 item panels
- Footer: MainMenuButton

---

### Task 8: Player Movement & Stamina

**Files:**
- Create: `scenes/gameplay/Player.gd`

- [ ] **Step 1: Create Player.gd**

```gdscript
extends CharacterBody2D

const SPEED := 200.0
const HALF_SPEED := 100.0
const STAMINA_MAX := 100.0
const STAMINA_DRAIN := 15.0  # per second
const STAMINA_REGEN := 30.0  # per second while idle

var stamina: float = STAMINA_MAX
var current_speed: float = SPEED
var input_dir := Vector2.ZERO
var is_in_poskamling := false

func _process(delta: float) -> void:
    if input_dir.length() > 0:
        stamina = maxf(0, stamina - STAMINA_DRAIN * delta)
        current_speed = HALF_SPEED if stamina <= 0 else SPEED
    else:
        stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
        current_speed = SPEED

func _physics_process(delta: float) -> void:
    input_dir = Vector2(
        Input.get_axis("ui_left", "ui_right"),
        Input.get_axis("ui_up", "ui_down")
    ).normalized()
    
    if input_dir.length() > 0:
        velocity = input_dir * current_speed
    else:
        velocity = Vector2.ZERO
    
    move_and_slide()

func set_movement_dir(dir: Vector2) -> void:
    input_dir = dir.normalized()

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
```

---

### Task 9: Ghost AI

**Files:**
- Create: `scenes/gameplay/Ghost.gd`

- [ ] **Step 1: Create Ghost.gd**

```gdscript
extends CharacterBody2D

enum State { PATROL, CHASE }

const PATROL_SPEED := 80.0
const CHASE_SPEED := 120.0
const DETECTION_RADIUS := 200.0

var state: State = State.PATROL
var target_player: Node2D = null
var patrol_direction := Vector2.RIGHT
var patrol_timer := 0.0
var ghost_index: int = 0
var pesugihan_value: int = 10

func _ready() -> void:
    patrol_direction = _random_direction()
    pesugihan_value = LevelData.get_pesugihan_value(ghost_index)

func _physics_process(delta: float) -> void:
    if not target_player:
        return
    
    var dist = global_position.distance_to(target_player.global_position)
    
    if state == State.PATROL and dist < DETECTION_RADIUS:
        state = State.CHASE
    elif state == State.CHASE:
        if dist > DETECTION_RADIUS * 1.5:
            state = State.PATROL
        if target_player.is_in_poskamling:
            state = State.PATROL
    
    match state:
        State.PATROL:
            patrol_timer -= delta
            if patrol_timer <= 0 or is_on_wall():
                patrol_direction = _random_direction()
                patrol_timer = randf_range(1.0, 3.0)
            velocity = patrol_direction * PATROL_SPEED
        
        State.CHASE:
            var dir = (target_player.global_position - global_position).normalized()
            velocity = dir * CHASE_SPEED
    
    move_and_slide()

func _random_direction() -> Vector2:
    var dirs = [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]
    return dirs[randi() % dirs.size()]

func set_target(player: Node2D) -> void:
    target_player = player

func set_ghost_index(idx: int) -> void:
    ghost_index = idx
    pesugihan_value = LevelData.get_pesugihan_value(idx)
```

---

### Task 10: Thief

**Files:**
- Create: `scenes/gameplay/Thief.gd`

- [ ] **Step 1: Create Thief.gd**

```gdscript
extends CharacterBody2D

const SPEED := 150.0
const SPAWN_CHANCE_BASE := 0.1
const ACTIVE_DURATION := 8.0

var is_active := false
var active_timer := 0.0
var target_player: Node2D = null
var has_stolen := false
var spawn_chance: float = 0.1

func _ready() -> void:
    hide()
    set_process(false)
    set_physics_process(false)

func _process(delta: float) -> void:
    if not is_active:
        return
    active_timer -= delta
    if active_timer <= 0:
        _disappear()

func _physics_process(delta: float) -> void:
    if not is_active or not target_player:
        return
    
    var dir = (target_player.global_position - global_position).normalized()
    velocity = dir * SPEED
    move_and_slide()

func try_spawn(player: Node2D, level: int) -> void:
    spawn_chance = LevelData.get_thief_chance(level)
    if randf() < spawn_chance:
        _appear(player)

func _appear(player: Node2D) -> void:
    target_player = player
    global_position = player.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
    is_active = true
    active_timer = ACTIVE_DURATION
    has_stolen = false
    show()
    set_process(true)
    set_physics_process(true)

func _disappear() -> void:
    is_active = false
    hide()
    set_process(false)
    set_physics_process(false)

func try_steal() -> void:
    if has_stolen:
        return
    
    # Steal a random item from inventory
    var inv = SaveManager.inventory
    if inv.size() > 0:
        var keys = inv.keys()
        var stolen_item = keys[randi() % keys.size()]
        SaveManager.inventory[stolen_item] = SaveManager.inventory.get(stolen_item, 0) - 1
        if SaveManager.inventory[stolen_item] <= 0:
            SaveManager.inventory.erase(stolen_item)
        SaveManager.save_game()
    else:
        # Steal coins instead (10-30)
        var stolen_coins = randi_range(10, 30)
        SaveManager.total_coins = maxi(0, SaveManager.total_coins - stolen_coins)
        SaveManager.save_game()
    
    has_stolen = true
    _disappear()

func on_senter_hit() -> void:
    # Thief hit by senter = flee without stealing + give pesugihan
    has_stolen = true  # prevent stealing
    SaveManager.add_coins(randi_range(10, 30))
    _disappear()
```

---

### Task 11: MapGenerator (Procedural Generation)

**Files:**
- Create: `scenes/gameplay/MapGenerator.gd`
- Create: `scenes/gameplay/WallTile.gd`
- Create: `scenes/gameplay/Poskamling.gd`
- Create: `scenes/gameplay/JimpitanCoin.gd`

- [ ] **Step 1: Create MapGenerator.gd**

```gdscript
class_name MapGenerator
extends RefCounted

const TILE_SIZE := 64  # 4x character size (16px base)

static func generate(level: int) -> Dictionary:
    var size = LevelData.get_map_size(level)
    var cols = size.x
    var rows = size.y
    
    # 0=open, 1=wall, 2=poskamling
    var grid = []
    for x in range(cols):
        grid.append([])
        for y in range(rows):
            grid[x].append(0)
    
    # Border walls
    for x in range(cols):
        grid[x][0] = 1
        grid[x][rows - 1] = 1
    for y in range(rows):
        grid[0][y] = 1
        grid[cols - 1][y] = 1
    
    # Place buildings (grid-aligned with small offsets)
    var building_count = LevelData.get_building_count(level)
    var placed = 0
    var attempts = 0
    while placed < building_count and attempts < building_count * 5:
        attempts += 1
        var bw = 2
        var bh = 2
        var bx = randi_range(2, cols - 2 - bw)
        var by = randi_range(2, rows - 2 - bh)
        
        var can_place = true
        for dx in range(bw):
            for dy in range(bh):
                if grid[bx + dx][by + dy] != 0:
                    can_place = false
                    break
            if not can_place:
                break
        
        if can_place:
            for dx in range(bw):
                for dy in range(bh):
                    grid[bx + dx][by + dy] = 1
            placed += 1
    
    # Place 1-3 Poskamlings
    var poskamling_count = randi_range(1, 3)
    var poskamlings = []
    for p in range(poskamling_count):
        var pos = _find_open_space(grid, cols, rows)
        if pos:
            grid[pos.x][pos.y] = 2
            poskamlings.append(pos)
    
    # Scatter jimpitan on open paths
    var jimpitan_quota = LevelData.get_jimpitan_quota(level)
    var jimpitans = []
    for j in range(jimpitan_quota):
        var pos = _find_open_space(grid, cols, rows)
        if pos:
            jimpitans.append(pos)
    
    # Ghost spawn points
    var walkable = cols * rows - placed * 4 - _count_wall_border(grid, cols, rows)
    var ghost_count = LevelData.get_ghost_count(walkable)
    var ghost_spawns = []
    for g in range(ghost_count):
        var pos = _find_open_space(grid, cols, rows)
        if pos:
            ghost_spawns.append(pos)
    
    return {
        "grid": grid,
        "cols": cols,
        "rows": rows,
        "tile_size": TILE_SIZE,
        "buildings": building_count,
        "poskamlings": poskamlings,
        "jimpitans": jimpitans,
        "ghost_spawns": ghost_spawns,
        "player_start": poskamlings[0] if poskamlings.size() > 0 else Vector2i(1, 1)
    }

static func _find_open_space(grid: Array, cols: int, rows: int) -> Vector2i:
    for attempt in range(100):
        var x = randi_range(1, cols - 2)
        var y = randi_range(1, rows - 2)
        if grid[x][y] == 0:
            return Vector2i(x, y)
    return Vector2i(-1, -1)

static func _count_wall_border(grid: Array, cols: int, rows: int) -> int:
    return cols * 2 + rows * 2 - 4
```

- [ ] **Step 2: Create WallTile.gd**

```gdscript
extends StaticBody2D

func _init() -> void:
    var rect = ColorRect.new()
    rect.color = Color(0.4, 0.3, 0.2)  # brown
    rect.size = Vector2(64, 64)
    add_child(rect)
    var collision = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(64, 64)
    collision.shape = shape
    add_child(collision)
```

- [ ] **Step 3: Create Poskamling.gd**

```gdscript
extends Area2D

signal entered
signal exited

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D:
        entered.emit()

func _on_body_exited(body: Node) -> void:
    if body is CharacterBody2D:
        exited.emit()
```

- [ ] **Step 4: Create JimpitanCoin.gd**

```gdscript
extends Area2D

signal collected

var is_collected := false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
    if body is CharacterBody2D and not is_collected:
        is_collected = true
        collected.emit()
        queue_free()
```

---

### Task 12: HUD — Radar, D-Pad, Skill Bar

**Files:**
- Create: `scenes/hud/Radar.tscn`
- Create: `scenes/hud/Radar.gd`
- Create: `scenes/hud/Dpad.tscn`
- Create: `scenes/hud/Dpad.gd`
- Create: `scenes/hud/SkillBar.tscn`
- Create: `scenes/hud/SkillBar.gd`
- Create: `scenes/hud/SkillButton.tscn`
- Create: `scenes/hud/SkillButton.gd`
- Create: `scenes/hud/HUD.tscn`
- Create: `scenes/hud/HUD.gd`

- [ ] **Step 1: Create HUD.gd**

```gdscript
extends CanvasLayer

@onready var level_label := $TopBar/LevelLabel
@onready var ghosts_label := $TopBar/GhostsLabel
@onready var stamina_bar := $TopBar/StaminaBar
@onready var jimpitan_label := $TopBar/JimpitanLabel
@onready var radar := $TopBar/Radar
@onready var dpad := $BottomBar/Dpad
@onready var skill_bar := $BottomBar/SkillBar

func update_level(lvl: int) -> void:
    level_label.text = "Level %d" % lvl

func update_ghosts(count: int) -> void:
    ghosts_label.text = "Ghosts: %d" % count

func update_stamina(percent: float) -> void:
    stamina_bar.value = percent * 100

func update_jimpitan(collected: int, total: int) -> void:
    jimpitan_label.text = "Jimpitan: %d / %d" % [collected, total]

func update_radar(ghost_positions: Array, map_size: Vector2) -> void:
    radar.update_positions(ghost_positions, map_size)
```

- [ ] **Step 2: Create Radar.gd**

```gdscript
extends Control

@onready var ghost_indicators := $GhostIndicators
var revealed := false
var reveal_timer := 0.0

func update_positions(ghost_positions: Array, map_size: Vector2) -> void:
    for child in ghost_indicators.get_children():
        child.queue_free()
    
    if not revealed:
        return
    
    for pos in ghost_positions:
        var dot = ColorRect.new()
        dot.color = Color.RED
        dot.size = Vector2(4, 4)
        dot.position = pos / map_size * size
        ghost_indicators.add_child(dot)

func set_revealed(reveal: bool, duration: float = 5.0) -> void:
    revealed = reveal
    if reveal:
        reveal_timer = duration

func _process(delta: float) -> void:
    if revealed:
        reveal_timer -= delta
        if reveal_timer <= 0:
            revealed = false
```

- [ ] **Step 3: Create Dpad.gd**

```gdscript
extends Control

signal move_direction(dir: Vector2)

@onready var up_btn := $Up
@onready var down_btn := $Down
@onready var left_btn := $Left
@onready var right_btn := $Right

func _ready() -> void:
    up_btn.button_down.connect(func(): move_direction.emit(Vector2.UP))
    up_btn.button_up.connect(func(): move_direction.emit(Vector2.ZERO))
    down_btn.button_down.connect(func(): move_direction.emit(Vector2.DOWN))
    down_btn.button_up.connect(func(): move_direction.emit(Vector2.ZERO))
    left_btn.button_down.connect(func(): move_direction.emit(Vector2.LEFT))
    left_btn.button_up.connect(func(): move_direction.emit(Vector2.ZERO))
    right_btn.button_down.connect(func(): move_direction.emit(Vector2.RIGHT))
    right_btn.button_up.connect(func(): move_direction.emit(Vector2.ZERO))
```

- [ ] **Step 4: Create SkillButton.gd**

```gdscript
extends Button

var item_id: String = ""
var item_data: Dictionary = {}

func setup(id: String) -> void:
    item_id = id
    item_data = ItemData.get_item(id)
    text = item_data.get("name", id)
    disabled = not SaveManager.has_item(id)

func _process(_delta: float) -> void:
    disabled = not SaveManager.has_item(item_id)
```

- [ ] **Step 5: Create SkillBar.gd**

```gdscript
extends HBoxContainer

signal skill_used(item_id: String)

var skill_ids := ["senter", "kopi", "balsem", "kacang_rebus"]

func _ready() -> void:
    for id in skill_ids:
        var btn = preload("res://scenes/hud/SkillButton.tscn").instantiate()
        btn.setup(id)
        btn.pressed.connect(_on_skill_pressed.bind(id))
        add_child(btn)

func _on_skill_pressed(item_id: String) -> void:
    if SaveManager.has_item(item_id):
        skill_used.emit(item_id)
        SaveManager.use_item(item_id)
```

---

### Task 13: Main Gameplay Scene

**Files:**
- Create: `scenes/gameplay/Gameplay.tscn`
- Create: `scenes/gameplay/Gameplay.gd`

- [ ] **Step 1: Create Gameplay.gd**

```gdscript
extends Node2D

@onready var player := $Player
@onready var hud := $HUD
@onready var map_container := $MapContainer
@onready var exit_btn := $ExitButton

var current_level: int = 1
var map_data: Dictionary = {}
var ghosts: Array = []
var jimpitans: Array = []
var thief: Thief = null
var jimpitan_collected: int = 0
var pesugihan_earned: int = 0
var is_senter_active := false
var is_balsem_active := false
var senter_timer := 0.0
var balsem_timer := 0.0

func _ready() -> void:
    var params = SceneManager.get_params()
    current_level = params.get("level", 1)
    
    map_data = MapGenerator.generate(current_level)
    _build_map()
    _spawn_player()
    _spawn_ghosts()
    _spawn_jimpitans()
    _setup_thief()
    _setup_hud()
    
    exit_btn.pressed.connect(_on_exit_pressed)

func _process(delta: float) -> void:
    _update_timers(delta)
    _update_hud()
    _check_thief_spawn(delta)
    _check_senter_effect()
    _check_ghost_collisions()
    _check_thief_collision()

func _build_map() -> void:
    var grid = map_data["grid"]
    var tile_size = map_data["tile_size"]
    
    for x in range(map_data["cols"]):
        for y in range(map_data["rows"]):
            if grid[x][y] == 1:  # Wall
                var wall = WallTile.new()
                wall.position = Vector2(x * tile_size, y * tile_size)
                map_container.add_child(wall)
            elif grid[x][y] == 2:  # Poskamling
                var poskam = Area2D.new()
                var rect = ColorRect.new()
                rect.color = Color(0, 0.8, 0, 0.3)
                rect.size = Vector2(tile_size, tile_size)
                poskam.add_child(rect)
                var collision = CollisionShape2D.new()
                var shape = RectangleShape2D.new()
                shape.size = Vector2(tile_size, tile_size)
                collision.shape = shape
                poskam.add_child(collision)
                poskam.body_entered.connect(func(b): _on_poskamling_entered(b))
                poskam.body_exited.connect(func(b): _on_poskamling_exited(b))
                poskam.position = Vector2(x * tile_size, y * tile_size)
                map_container.add_child(poskam)

func _spawn_player() -> void:
    var start = map_data["player_start"]
    player.position = Vector2(start.x * map_data["tile_size"], start.y * map_data["tile_size"])

func _spawn_ghosts() -> void:
    var unlocked = GhostDatabase.get_unlocked_count(current_level)
    for i in range(map_data["ghost_spawns"].size()):
        var spawn = map_data["ghost_spawns"][i]
        var ghost = Ghost.new()
        ghost.position = Vector2(spawn.x * map_data["tile_size"], spawn.y * map_data["tile_size"])
        ghost.set_target(player)
        ghost.set_ghost_index(randi() % unlocked)
        add_child(ghost)
        ghosts.append(ghost)

func _spawn_jimpitans() -> void:
    var tile_size = map_data["tile_size"]
    for pos in map_data["jimpitans"]:
        var coin = JimpitanCoin.new()
        coin.position = Vector2(pos.x * tile_size + tile_size/2, pos.y * tile_size + tile_size/2)
        coin.collected.connect(_on_jimpitan_collected)
        map_container.add_child(coin)
        jimpitans.append(coin)

func _setup_thief() -> void:
    thief = Thief.new()
    add_child(thief)

func _setup_hud() -> void:
    hud.update_level(current_level)
    hud.update_jimpitan(0, map_data["jimpitans"].size())
    hud.skill_bar.skill_used.connect(_on_skill_used)

func _update_hud() -> void:
    hud.update_ghosts(ghosts.size())
    hud.update_stamina(player.get_stamina_percent())

func _update_timers(delta: float) -> void:
    if is_senter_active:
        senter_timer -= delta
        if senter_timer <= 0:
            is_senter_active = false
    
    if is_balsem_active:
        balsem_timer -= delta
        if balsem_timer <= 0:
            is_balsem_active = false

func _on_skill_used(item_id: String) -> void:
    match item_id:
        "senter":
            is_senter_active = true
            senter_timer = 5.0
        "kopi":
            hud.radar.set_revealed(true, 5.0)
        "balsem":
            is_balsem_active = true
            balsem_timer = 5.0
        "kacang_rebus":
            player.restore_stamina(0.1)

func _check_senter_effect() -> void:
    if not is_senter_active:
        return
    
    var senter_radius = 3 * 64  # 3 tiles
    for ghost in ghosts:
        if ghost.global_position.distance_to(player.global_position) <= senter_radius:
            if ghost.is_visible_in_tree():
                pesugihan_earned += ghost.pesugihan_value
                ghost.hide()  # temporarily disabled (ghost runs away)
                var timer = get_tree().create_timer(3.0)
                timer.timeout.connect(func(): ghost.show())
    
    # Senter also works on thief
    if thief and thief.is_active and thief.global_position.distance_to(player.global_position) <= senter_radius:
        thief.on_senter_hit()

func _check_ghost_collisions() -> void:
    for ghost in ghosts:
        if not ghost.is_visible_in_tree():
            continue
        if ghost.global_position.distance_to(player.global_position) < 32:
            if player.is_in_poskamling:
                continue
            if is_balsem_active:
                continue
            _on_player_caught_by_ghost()

func _check_thief_collision() -> void:
    if not thief or not thief.is_active:
        return
    if thief.global_position.distance_to(player.global_position) < 32:
        thief.try_steal()

func _on_jimpitan_collected() -> void:
    jimpitan_collected += 1
    hud.update_jimpitan(jimpitan_collected, map_data["jimpitans"].size())
    if jimpitan_collected >= map_data["jimpitans"].size():
        _on_level_complete()

func _on_poskamling_entered(body: Node) -> void:
    if body == player:
        player.enter_poskamling()

func _on_poskamling_exited(body: Node) -> void:
    if body == player:
        player.exit_poskamling()

func _check_thief_spawn(delta: float) -> void:
    if thief and not thief.is_active:
        thief.try_spawn(player, current_level)

func _on_player_caught_by_ghost() -> void:
    # Instant fail — restart level
    SaveManager.total_coins = maxi(0, SaveManager.total_coins - randi_range(20, 50))
    SaveManager.save_game()
    SceneManager.go_to_scene("res://scenes/gameplay/Gameplay.tscn", {"level": current_level})

func _on_level_complete() -> void:
    var total_earned = jimpitan_collected + pesugihan_earned
    SaveManager.add_coins(total_earned)
    SaveManager.current_level = current_level + 1
    SaveManager.save_game()
    SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")

func _on_exit_pressed() -> void:
    SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")
```

- [ ] **Step 2: Create Gameplay.tscn**

Node2D root:
- MapContainer (Node2D) — walls, poskamlings, coins
- Player (CharacterBody2D)
- HUD (CanvasLayer, instance HUD.tscn)
- ExitButton (Button, bottom of screen)

---

### Task 14: Main Root Scene

**Files:**
- Create: `scenes/main/Main.tscn`
- Create: `scenes/main/Main.gd`

- [ ] **Step 1: Create Main.gd**

```gdscript
extends Node

func _ready() -> void:
    SceneManager.go_to_scene("res://scenes/menu/MainMenu.tscn")
```

- [ ] **Step 2: Create Main.tscn**

Node root with script Main.gd.

---

### Task 15: Configure Autoloads in project.godot

- [ ] **Step 1: Update project.godot to register autoloads**

Add to project.godot:
```gdscript
[autoload]
SaveManager="*res://autoload/SaveManager.gd"
SceneManager="*res://autoload/SceneManager.gd"
```

---

### Task 16: Placeholder Sprites

**Files:**
- Create: `assets/placeholder/player.png`
- Create: `assets/placeholder/ghost.png`
- Create: `assets/placeholder/thief.png`
- Create: `assets/placeholder/wall.png`
- Create: `assets/placeholder/coin.png`

For now, create colored rectangle PNGs using a script. These are temporary.

- [ ] **Step 1: Create simple placeholder assets**

Run the following in the Godot editor or create minimal SVG → PNG assets manually. For initial playtesting, the ColorRect nodes in our code already serve as placeholders — no external image files needed.

---

### Task 17: Initial Playtest & Polish

- [ ] **Step 1: Open project in Godot 4.6 and verify:**

1. Main menu loads: 3 buttons visible
2. Story page: navigation works (prev/next/finish)
3. Level track: shows level buttons, shop items, buy works
4. Gameplay: map generates, player moves with keyboard + D-pad
5. Ghosts patrol and chase
6. Thief appears randomly
7. Jimpitan collection completes level
8. Ghost contact restarts level
9. Items work: senter gives pesugihan, kopi reveals radar, balsem shields, kacang restores stamina
10. Save/load persists data between sessions
