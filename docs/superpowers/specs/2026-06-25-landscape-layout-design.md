# Landscape Layout Design — Ronda Patrol

## Overview

Convert the game from portrait (480×854) to landscape (1280×720, 16:9). All UI screens are re-laid-out using fixed pixel values for the new resolution, maintaining the same stretch mode (`canvas_items`).

## Resolution

- **Design resolution**: 1280 × 720 (720p, 16:9, common mobile landscape)
- **Orientation**: 0 (landscape, unlocked)
- **Stretch mode**: `canvas_items` (unchanged)

## Screen-by-Screen Layout

### Main Menu (`MainMenu.tscn`)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│                                                                              │
│                              Logo (200×200)                                  │
│                                                                              │
│                                                                              │
│                     [Exit]    [Play]    [Story]                              │
│                          How to play description                             │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

- Root: `Control` anchors_preset=15 (full rect)
- `VBoxContainer` — fills entire screen, separation=20
  - `SpacerTop` — size_flags_vertical=3
  - `Logo` — TextureRect, min_size=200×200, size_flags_horizontal=4 (center)
  - `SpacerMid` — size_flags_vertical=1
  - `ButtonRow` — HBoxContainer, center-aligned, separation=20
    - `ExitButton` — 180×50
    - `PlayButton` — 180×50
    - `StoryButton` — 180×50
  - `HowToPlay` — Label, center-aligned, autowrap
  - `SpacerBottom` — size_flags_vertical=2

### Story Page (`StoryPage.tscn`)

```
┌──────────────────────────────────────┬───────────────────────────────────────┐
│                                      │                               [Close] │
│                                      │                                       │
│                                      │                                       │
│                                      │                                       │
│              Image                    │            Story text                 │
│           (640×480)                   │        (scrollable area)             │
│                                      │                                       │
│                                      │                                       │
│                                      │                                       │
│                                      │                                       │
│         [Prev]                       │                            [Next]     │
└──────────────────────────────────────┴───────────────────────────────────────┘
```

- Image panel: (0, 0)-(640, 720) — left half
  - `TextureRect`: (10, 10)-(630, 620)
  - `PrevButton`: (10, 640)
- Story panel: (640, 0)-(1280, 720) — right half
  - `CloseButton`: (1220, 10)
  - `StoryArea` (ScrollContainer): (650, 50)-(1260, 620)
  - `NextButton`: (1150, 640)
- `PageLabel`: centered between prev/next at (640, 640)

### Level Track (`LevelTrack.tscn`)

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ Status: Ready / Recover                                                      │
│ Regional treasury: 0 coins                                                   │
├──────────────────────┬───────────────────────────────────────────────────────┤
│                      │                                                       │
│        Shop          │                    Level Track                        │
│    ┌──────┐ ┌──────┐ │                  (scrollable)                        │
│    │Item1 │ │Item2 │ │              ┌──────────────┐                        │
│    └──────┘ └──────┘ │              │ Level 1      │                        │
│    ┌──────┐ ┌──────┐ │              ├──────────────┤                        │
│    │Item3 │ │Item4 │ │              │ Level 2      │                        │
│    └──────┘ └──────┘ │              ├──────────────┤                        │
│                      │              │ Level 3      │                        │
│    [Main Menu]       │              └──────────────┘                        │
│                      │                                                       │
└──────────────────────┴───────────────────────────────────────────────────────┘
```

- Status: (8, 8)
- Treasury: (8, 28)
- Shop panel: (10, 52)-(240, 680), 2×2 GridContainer
  - 4 item panels created dynamically
  - `MainMenuButton` at bottom
- Level Track: (260, 52)-(1270, 680), ScrollContainer
  - `VBoxContainer` inside with level buttons (240×90 each, created dynamically)

### Gameplay / HUD (`HUD.gd`, `Gameplay.tscn`)

```
┌──────────────────────┬────────────────────────────────────────┬──────────────┐
│ Level   : XX         │                                        │              │
│ Ghosts  : X          │                                        │    Radar     │
│ Jimpitan: X/XX       │                                        │              │
│ Stamina : [████░░]   │            GAMEPLAY AREA               │   [Exit]     │
│                      │           (900 × 720)                  │              │
│                      │                                        │  ┌────┐┌────┐│
│                      │                                        │  │Skill││Skill││
│       D-Pad          │                                        │  │  1  ││  2  ││
│                      │                                        │  └────┘└────┘│
│                      │                                        │  ┌────┐┌────┐│
│                      │                                        │  │Skill││Skill││
│                      │                                        │  │  3  ││  4  ││
│                      │                                        │  └────┘└────┘│
└──────────────────────┴────────────────────────────────────────┴──────────────┘
```

- **Left panel**: (0, 0)-(200, 720), semi-transparent black `ColorRect`
  - Level label: (8, 10)
  - Ghosts label: (8, 34)
  - Jimpitan label: (8, 58)
  - Stamina bar: (8, 82), 184×16
  - Colon alignment: labels right-aligned, values left-aligned, colons at consistent x
  - D-Pad: centered in remaining space, ~160×160
- **Right panel**: (1100, 0)-(1280, 720), semi-transparent black `ColorRect`
  - Radar: (1130, 10), 100×100
  - Exit button: (1140, 130), 80×36
  - SkillBar (GridContainer, 2 cols): (1120, 190), gap=8
- **Gameplay area**: (200, 0)-(1100, 720) — Camera2D viewport shows this region
- **Return message**: (210, 10)-(1090, 50), overlaid on gameplay area

### Project Config (`project.godot`)

```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/handheld/orientation=0
```

## Files to Modify

1. `project.godot` — viewport size + orientation
2. `scenes/menu/MainMenu.tscn` — tune VBoxContainer spacings
3. `scenes/menu/StoryPage.tscn` — full rebuild for side-by-side layout
4. `scenes/menu/StoryPage.gd` — verify no position-dependent logic
5. `scenes/menu/LevelTrack.tscn` — full rebuild with shop + level track panels
6. `scenes/menu/LevelTrack.gd` — adjust dynamic level/shop item creation positions
7. `scenes/hud/HUD.gd` — full rebuild with three-column layout
8. `scenes/hud/Dpad.tscn` — adjust size if needed
9. `scenes/hud/SkillBar.tscn` — adjust size if needed

## Non-Goals

- No changes to gameplay logic (player movement, ghost AI, map generation, collision)
- No new assets
- No aspect ratio enforcement (canvas_items stretch mode allows adaptation)
- No responsive/adaptive layout (fixed 1280×720 design resolution)
