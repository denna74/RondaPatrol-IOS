# Loading Optimization Design

**Date:** 2026-07-06
**Target:** Android (primary)

## Problem

Gameplay loading is slow, even on small maps. The main thread blocks on:
1. `GroundTile._init()` — loads 18 textures via `load()`, builds 4x virtual grid, composites all tiles into a single `Image` → `ImageTexture` via CPU pixel manipulation
2. `Gameplay._ready()` — runs map generation, ground rendering, entity spawning, HUD creation — all synchronously
3. No loading screen — user sees a frozen/black screen
4. No background threading or async resource loading

## Architecture Overview

New loading flow replaces blocking `change_scene_to_file()` → `_ready()` with a state machine:

```
LevelTrack → LoadingScreen (async work) → Gameplay (state machine)
```

## Components

### 1. LoadingScreen (NEW: scenes/gameplay/LoadingScreen.tscn + .gd)

- Full-screen black background
- Centered progress bar (white fill on dark track, themed)
- "Loading..." label above bar
- Random gameplay tip below
- Pulse animation on title text to indicate aliveness
- No gameplay BGM during loading (silence or short neutral chime)
- 0.5s fade-out transition when loading completes
- Uses `SceneManager.go_to_scene("Gameplay.tscn")` with preloaded data

### 2. AsyncLoader (NEW: scenes/gameplay/AsyncLoader.gd)

Background loading orchestration:

**Resource Loading via `ResourceLoader.load_threaded_request()`:**
- 18 ground tile textures (currently loaded via `load()` in GroundTile)
- 52 player sprite frames (currently `preload()` in Player.gd)
- 4 tree textures (currently `preload()` in Gameplay.gd)
- 2 HUD label images (~2MB total)
- 5 SFX files

**Map Generation via `WorkerThreadPool.add_task()`:**
- `MapGenerator.generate(level)` is pure data (no node ops), thread-safe
- Returns `map_data` dict when done

**TileSet Atlas:**
- After 18 tile textures are loaded, creates a combined atlas (6×3 grid, 16×16 per tile)
- Creates a `TileSet` with one `TileSetAtlasSource` referencing the atlas
- Tiles are mapped 0-17, each corresponding to a tile name from `TILE_NAMES`

**Progress:**
- `progress = 0.5 × resource_progress + 0.5 × map_gen_done`
- Polled each frame by LoadingScreen

### 3. SceneManager (MODIFIED: autoload/SceneManager.gd)

- `go_to_scene()` persists preloaded data across scene transitions
- A `LevelTransitionData` autoload holds precomputed resources:
  - `map_data: Dictionary` from MapGenerator
  - `tile_set: TileSet` with ground tile atlas
  - `sprite_atlases: Dictionary` for player/hud assets

### 4. GroundTile → TileMapLayer (REWRITTEN: scenes/gameplay/GroundTile.gd)

**Before:** `_init()` loads textures, builds virtual grid, computes accent patches, renders to Image → ImageTexture, draws via `_draw()`.

**After:**
- Receives a pre-built `TileSet` and `map_data`
- Creates a `TileMapLayer` node with `cell_size = Vector2(16, 16)`
- Tile assignment logic preserved:
  - `_expand_dirt_mask()` — same, works at virtual grid level
  - `_build_tile_grid()` → `_compute_accent_patches()` → `_assign_tiles()` — same logic
  - Instead of `_render_to_texture()`, calls `tile_map.set_cell(Vector2i(x, y), source_id, atlas_coords)`
- No more `_render_to_texture()`, no more `_draw()`, no more Image manipulation
- TileMapLayer handles GPU batching and culling natively

**Tile assignment mapping:**
```gdscript
const TILE_IDS = {
    "land_center": 0, "grass_straight": 1, "grass_left_top": 2,
    ...
}
# Instead of storing tile names in _tile_grid, store tile IDs
# On build: tile_map.set_cell(Vector2i(x, y), 0, Vector2i(tile_id, 0))
```

### 5. Gameplay State Machine (MODIFIED: scenes/gameplay/Gameplay.gd)

States: `BUILD_MAP → SPAWN → PLAYING`

```gdscript
enum State { BUILD_MAP, SPAWN, PLAYING }
var _state: State

func _ready():
    MusicManager.stop_music()  # no BGM during loading
    _state = State.BUILD_MAP
    _build_map_deferred()

func _build_map_deferred():
    # Frame 1: Create TileMapLayer, set ground tiles (1000 cells/frame)
    # Frame 2: Create WallTile nodes
    # Frame 3: Create Poskamling + HouseTile nodes
    # Then transition to SPAWN

func _spawn_deferred():
    # Frame 4: Player + ghost spawns
    # Frame 5: Jimpitan coins + thief + trees
    # Frame 6: HUD setup
    # Then transition to PLAYING

func _enter_playing():
    MusicManager.play_gameplay_music()
    _state = State.PLAYING
```

Each frame boundary uses `await get_tree().process_frame`.

### 6. Player.gd (MODIFIED)

- Remove 52 `preload()` calls
- Add `init(sprite_data: Dictionary)` method
- Textures loaded during async phase, passed via SceneManager params

## Data Flow

```
LevelTrack
  └─ SceneManager.go_to_scene("LoadingScreen.tscn", {level: N})
       │
       └─ LoadingScreen._ready()
            ├─ AsyncLoader.start(level)
            │    ├─ WorkerThreadPool → MapGenerator.generate(level)
            │    ├─ load_threaded_request → all texture/sfx assets
            │    └─ Build TileSet atlas
            │
            ├─ _process(delta): update progress bar
            │
            └─ On 100%:
                 ├─ Store resources in SceneManager._transition_data
                 ├─ Fade out (0.5s)
                 └─ SceneManager.go_to_scene("Gameplay.tscn")
                      │
                      └─ Gameplay._ready()
                           ├─ Read preloaded data from SceneManager
                           ├─ State = BUILD_MAP
                           ├─ State = SPAWN
                           └─ State = PLAYING
```

## Files Changed

| File | Change Type | Description |
|---|---|---|
| `scenes/gameplay/LoadingScreen.tscn` | NEW | Loading screen scene |
| `scenes/gameplay/LoadingScreen.gd` | NEW | Loading screen logic |
| `scenes/gameplay/AsyncLoader.gd` | NEW | Async resource + map gen orchestration |
| `autoload/SceneManager.gd` | MODIFY | Add transition data persistence |
| `scenes/gameplay/GroundTile.gd` | REWRITE | TileMapLayer instead of texture compositing |
| `scenes/gameplay/Gameplay.gd` | MODIFY | State machine, deferred spawning |
| `scenes/gameplay/Player.gd` | MODIFY | External texture loading |
| `scenes/gameplay/Gameplay.tscn` | MODIFY | May need adjustments for new flow |

## Constraints

- Loading screen must not play gameplay BGM
- Must work on Android (avoid ANR, keep memory usage reasonable)
- Visual quality of ground tiles must remain identical
- Loading screen + state machine should add no more than ~200ms overhead
- Target: gameplay responsive within 1-2 seconds on medium devices
