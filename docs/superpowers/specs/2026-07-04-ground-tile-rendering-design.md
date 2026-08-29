# Ground Tile Rendering with Edge-Matched Tiles

## Problem

The game currently renders the ground using a single repeating `ground.png` texture. 104 individual tile PNGs and their edge definitions in `tile_manifest.json` exist but are unused. The ground should visually show a dirt path network through grass, using these tiles with edge-matching constraints.

## Design

### Files Changed

| File | Change |
|------|--------|
| `scenes/gameplay/MapGenerator.gd` | Add path-network generation after building/poskamling placement |
| `scenes/gameplay/GroundTile.gd` | Complete rewrite: load manifest, select tiles per cell, render |
| `scenes/gameplay/Gameplay.gd` | Wire path_cells into GroundTile construction |

### 1. Path Network Generation (MapGenerator)

After existing wall/building/poskamling placement:

1. Collect waypoints: every cell occupied by a building (2×2 each) and every poskamling cell.
2. Connect waypoints into a network using nearest-neighbor chaining:
   - For each unconnected waypoint, find the nearest connected waypoint.
   - Draw an L-shaped orthogonal path between them (preferring the shorter of the two possible L-shapes).
   - Avoid routing through wall cells; if one L-path hits a wall, use the other.
3. Mark building cells, poskamling cells, and all connecting-path cells as `path_cells`.
4. Return `path_cells` as a `Dictionary` (keyed by `Vector2i` with value `true`) alongside the grid.

Path cells are traversable (grid value 0). Their ground representation uses dirt/transition tiles instead of grass.

### 2. Tile Selection & Rendering (GroundTile)

**Manifest loading** at construction time:
- Read `resources/tile_manifest.json`
- Build lookup: `{ (top, bottom, left, right) -> [tile_filename, ...] }`
- Edge types are "grass" or "dirt" strings.

**Per-cell tile selection:**
For each cell `(x, y)` in the grid:

1. Compute desired edge types based on neighbor path status:
   - `top` = "dirt" if cell `(x, y-1)` is a path cell, else "grass"
   - `bottom` = "dirt" if cell `(x, y+1)` is a path cell, else "grass"
   - `left` = "dirt" if cell `(x-1, y)` is a path cell, else "grass"
   - `right` = "dirt" if cell `(x+1, y)` is a path cell, else "grass"

2. Lookup the pattern in the manifest:
   - **Exact match found**: pick a random tile from matching list.
   - **No exact match**: find closest match by minimizing edge-mismatch count. On ties, pick randomly.
   - All-grass cells (no path neighbors) pick randomly from the 76 all-grass tiles.

3. Load the PNG texture from `assets/sprites/ground_tiles/` (caching by filename to avoid reloads).

4. Create a `Sprite2D` node at position `(x * 64, y * 64)` with the loaded texture and add to the ground container.

**Closest-match fallback analysis:**
All missing patterns (straight path, 3 of 4 T-junctions, left-endpoint) find tiles with 3/4 matching edges. The single mismatched edge flips grass↔dirt, which at 64×64 pixel-art scale produces visually acceptable results.

### 3. Gameplay Wiring (Gameplay.gd)

- `_build_map()` passes `path_cells` from `map_data` into `GroundTile` constructor.
- `GroundTile` no longer takes a simple size; it receives `(grid, cols, rows, path_cells)`.
- No other gameplay logic changes — the grid values (0=walkable, 1=wall, 2=poskamling, 3=building) remain identical.

### 4. Tile Options

- `borders` (wall, poskamling): no ground tile drawn — wall/poskamling sprites sit on top of whatever ground tile is there. The ground tile under them is still computed and rendered first.
- Grid value `0` cells (walkable): get a ground tile (path or grass depending on `path_cells`).
- Grid value `3` cells (building): get a ground tile since building cells are in `path_cells`.

### Edge Cases

- **Maps with no buildings/poskamlings (level 1)**: no path cells → all grass.
- **Path through border walls**: connection algorithm picks the L-path that avoids walls.
- **All-dirt tiles (`tile_r1_c1`, `tile_r4_c5`, `tile_r6_c12`, `tile_r7_c12`)**: used when path cells have path neighbors on all 4 sides (interior of path blobs).
- **Performance**: nodes created per cell (up to 1600 for a 40×40 map). `Sprite2D` is lightweight; no measurable impact for this scale.

## Files Not Changed

- `WallTile.gd`, `HouseTile.gd`, `Poskamling.gd` — unaffected, they render on top of ground.
- All gameplay logic, movement, collision, HUD — unchanged.
- `tile_manifest.json` and `assets/sprites/ground_tiles/*.png` — used as-is.
