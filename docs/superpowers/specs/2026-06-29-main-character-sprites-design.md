# Main Character Sprites

## Objective

Replace the procedurally drawn blue rectangle (28×28) in `Player.gd` with the directional sprite images from `assets/sprites/main_character/`, scaled to fit within the same 28×28 area.

## Assets

| Direction | File           | Canvas Size |
|-----------|----------------|-------------|
| Up        | `back_1.png`   | 256×256     |
| Down      | `front_1.png`  | 256×256     |
| Left      | `left_1.png`   | 492×492     |
| Right     | `right_1.png`  | 256×256     |

## Approach

**Pattern:** Code-only (no `.tscn`), matching existing `Player.gd` convention.

**Changes to `Player.gd`:**

1. **Remove `_draw()`** — no longer drawing the blue rectangle.
2. **Add `Sprite2D` child** in `_ready()`, centered at the player's origin.
3. **Load textures** into a dictionary keyed by direction (`up`, `down`, `left`, `right`).
4. **Direction-based switching:**
   - Track `facing_dir` (default `Vector2.DOWN`).
   - In `_physics_process()`, when `input_dir != Vector2.ZERO`, update `facing_dir`.
   - Determine dominant axis: if `|x| > |y|` use left/right, otherwise up/down.
5. **Uniform scaling:**
   - For each direction change, compute `scale = min(28 / tex_width, 28 / tex_height)`.
   - Apply the scale uniformly so the sprite fits entirely inside the 28×28 area.
   - (Different canvas sizes mean different scale factors per sprite.)

## Constraints

- Collision shape (circle, radius 16) remains unchanged.
- Movement logic and stamina system remain unchanged.
- Camera setup remains unchanged.

## Future Considerations

- If animation frames are added later (`back_2.png`, etc.), switching to `AnimatedSprite2D` would be natural.
- If pixel-perfect scaling is desired, texture filter can be set to `NEAREST` for crisp pixel art.
