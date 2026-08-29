# Ronda Patrol — Game Design Document

## Overview
Ronda Patrol combines the Indonesian cultural concept of "Ronda" (neighborhood watch) with Pac-Man arcade mechanics. The player patrols a village compound collecting jimpitan (mandatory coins) while avoiding ghosts and thieves, using items bought before each level.

## Technical Stack
- **Engine:** Godot 4.6
- **Project structure:** Domain-scene layout (like JapasTycoon)
- **References:** ../KedaiMania, ../JapasTycoon for save/load, data patterns, and scene conventions

## Project Structure
```
RondaPatrol/
  autoload/
    SaveManager.gd       -- Game state + encrypted save/load
    SceneManager.gd      -- Scene transitions with params
  scenes/
    main/
      Main.tscn + Main.gd           -- Root scene, menu navigation
    menu/
      MainMenu.tscn + MainMenu.gd   -- Logo, story/play/exit buttons
      StoryPage.tscn + StoryPage.gd -- Story slides with prev/next
      LevelTrack.tscn + LevelTrack.gd -- Level selection, shop, treasury
    gameplay/
      Gameplay.tscn + Gameplay.gd    -- Main game loop controller
      MapGenerator.gd                -- Procedural map generation (class_name)
      Player.gd                      -- Player movement, stamina, collision
      Ghost.gd                       -- Ghost AI (patrol + chase)
      Thief.gd                       -- Thief AI (spawn, steal, flee)
      Poskamling.gd                  -- Safe zone area
      JimpitanCoin.gd               -- Collectible coin
    hud/
      HUD.tscn + HUD.gd             -- Level info, stats overlay
      Radar.tscn + Radar.gd         -- Mini-map radar
      Dpad.tscn + Dpad.gd           -- On-screen D-pad
      SkillBar.tscn + SkillBar.gd   -- 4 skill buttons
      SkillButton.tscn + SkillButton.gd -- Individual skill button
  scripts/
    GhostDatabase.gd        -- 84 ghost definitions (class_name, static)
    LevelData.gd            -- Level scaling formulas (class_name, static)
    ItemData.gd             -- Item definitions, prices, effects (class_name, static)
  resources/
    ghosts.json             -- Ghost database (names, unlock levels)
    items.json              -- Item definitions data
  assets/
    placeholder/            -- Placeholder shapes (colored squares/circles)
    sprites/                -- Final sprites (added later)
    audio/                  -- Sound effects, music (added later)
  addons/                   -- Future plugins (ads, billing, etc.)
```

## Autoloads

### SaveManager
- Stores: total_coins, current_level, unlocked_ghost_indices, settings
- Encrypted save/load: AES-CBC + SHA256 integrity hash (same pattern as KedaiMania/JapasTycoon)
- Signals: `coins_changed`, `level_changed`

### SceneManager
- `go_to_scene(path: String, params: Dictionary = {})` — transitions with params
- Stores params in temp, next scene reads in `_ready()`

## Static Data Classes (class_name, no autoload)

### GhostDatabase
- `get_ghost_data(index: int) -> Dictionary` — name, description, unlock_level
- `get_unlocked_count(current_level: int) -> int` — first 5, +1 every 10 levels
- 84 ghosts from Indonesian folklore

### LevelData
- `get_map_size(level) -> Vector2i` — caps at 40x40
- `get_building_count(level) -> int` — caps at 70
- `get_jimpitan_quota(level) -> int` — `5 + level * 3/4`, caps at 200 at level 260
- `get_ghost_count(walkable_area: int) -> int` — max(3, walkable_area / 30)
- `get_thief_chance(level) -> float` — caps at 50%

### ItemData
- `get_item_data(id: String) -> Dictionary` — name, price, description, duration
- Items: senter, kopi, balsem, kacang_rebus

## Core Systems

### Player
- Free 8-direction movement (keyboard + D-pad), speed 200 (100 when stamina empty)
- Stamina: depletes (5/s) only when actually moving, refills (3/s) only when idle (no input), freezes when stuck against a wall
- Ghost contact = instant fail (level restarts, -1.5s delay, player hidden, lose some coins)
- Thief contact = random item or coins stolen
- Enters Poskamling → safe from ghosts/thief
- Two-phase level completion: collect all jimpitan → "Kembali ke Poskamling!" text → enter any poskamling to win

### Ghost AI
- **PATROL state:** Random walk speed 45, change direction on wall collision or random interval
- **CHASE state:** Player enters detection radius (180px) → move toward player at 75 speed
- Player exits radius or enters Poskamling → back to PATROL
- Cannot enter Poskamling (blocked by StaticBody2D barrier child)
- All 84 types share same behavior; variety is visual + pesugihan value scaling
- Pesugihan per ghost = `clamp(10 + ghost_index * 2, 10, 200)` — higher-index ghosts = more bonus
- Ghost count scales with map walkable area (walkable_area / 30)

### Thief
- Spawns with a random timer (25s cooldown between attempts), appears briefly (12s active)
- PATROL: wanders at 40 speed; CHASE: chases at 80 speed when player within 150px
- Steals 1 random item from inventory or some coins
- Does NOT reduce required jimpitan quota (only final result)
- Can be attacked with senter (same mechanic as ghosts)
- Spawn chance increases with level (caps at 50%)
- Cannot enter Poskamling

### Items
| Item | Price | Effect | Type |
|------|-------|--------|------|
| Senter | 50 | Auto-zone radius (3 tiles) → pesugihan from ghosts in range, 5s duration | Duration |
| Kopi | 30 | Reveal ghosts on radar for 5s | Duration |
| Balsem | 40 | Immunity to ghosts for ~5s | Duration |
| Kacang Rebus | 20 | Restore 10% stamina instantly | Instant |

Items bought before level on Level Track shop. 1 item = 1 skill use in gameplay.

### Procedural Map Generation
1. Determine map size from level formula
2. Create grid-based layout with building positions (grid + random offset)
3. Place buildings as 4x-scale wall blocks
4. Place 1-3 Poskamlings at random open positions (spaced apart)
5. Scatter jimpitan coins on walkable paths
6. Place ghost spawn points
7. Flood-fill validate: all coins reachable from player start
8. Player starts at a Poskamling

### Economy
- Jimpitan: required to complete level (collected from map)
- Pesugihan: bonus coins (from senter on ghosts/thief)
- Thief steal: deducted from result
- Level result = Jimpitan + Pesugihan - Thief steal
- Wallet = accumulated coins across all levels
- Shop: spend wallet coins before each level

### Screen Flow
```
Main → Story (slides) → Level Track (shop/select) → Gameplay → Level Track
                    ↓                                              ↓
              [close]                                        [exit → Main]
```

### Controls
- Keyboard arrow keys for movement
- On-screen D-pad (mobile support)
- Skill buttons 1-4 for item activation
- Number keys 1-4 as keyboard shortcut for skills

### Save Data
- total_coins (int): accumulated wallet
- current_level (int): level progress
- unlocked_ghosts (Array[int]): indices of unlocked ghost types
- Encrypted using SHA256 key derivation + AES-CBC + PKCS7 padding + integrity hash

### Top/Bottom HUD Bars
- Top bar (y:0-110) and bottom bar (y:650-800) fully opaque black Rect — bounds the gameplay area
- Gameplay viewport is 480×800, middle section (110-650) is the game world

### Collision Layer System
| Layer | Objects | Masks |
|-------|---------|-------|
| 1 | Walls | 3+4 (Player, Ghost/Thief) |
| 2 | Poskamling barrier | 8 (Ghost/Thief) |
| 3 | Player | 1 (Walls) |
| 4 | Ghost/Thief | 1+2 (Walls, Poskamling barrier) |

### Radar (Minimap)
- Position: top-left corner of gameplay area
- Renders: walls (brown), poskamlings (light green `0.4, 1.0, 0.4`), jimpitan (yellow circles), player (blue circle), ghosts (red circles when revealed via kopi)
- Coin dots removed when coin is collected (is_instance_valid check each frame)
- Size: 100×100px

### UI Details
- WASD does not select UI buttons: focus_mode = FOCUS_NONE on all interactive UI elements
- LevelTrack: ScrollContainer → VBoxContainer, levels in reverse order (highest first), 240×90 centered buttons, 10px spacing
- D-pad: cross layout with FOCUS_NONE buttons
- Skill buttons: GridContainer 2×2, FOCUS_NONE

### Scene Transition Rules
- All scene transitions from physics signals (body_entered, etc.) use `call_deferred` to avoid physics engine errors
- Camera2D.make_current() called in _ready(), never in _init()

## Placeholder Assets (Phase 1)
Before real sprites are added:
- Player: colored circle/square (blue)
- Ghosts: colored squares with different hues per type
- Thief: distinctive colored square
- Walls: gray/brown large squares
- Poskamling: green highlighted area
- Jimpitan: small yellow circles
- Items: colored icons (simple shapes)
