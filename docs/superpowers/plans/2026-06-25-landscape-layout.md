# Landscape Layout Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert all UI screens from portrait (480×854) to landscape (1280×720, 16:9) with new layouts per the approved design.

**Architecture:** Fixed-resolution approach — all hard-coded pixel positions recalculated for 1280×720. `canvas_items` stretch mode retained. No responsive containers added (except existing VBoxContainer in MainMenu). Nine files modified across menu and HUD scenes.

**Tech Stack:** Godot 4.6, GDScript, .tscn scene files

---

### Task 1: Update project.godot display settings

**Files:**
- Modify: `project.godot:31-34`

- [ ] **Step 1: Change viewport size and orientation**

Change lines 31-34 from:
```ini
window/size/viewport_width=480
window/size/viewport_height=854
window/handheld/orientation=1
```
to:
```ini
window/size/viewport_width=1280
window/size/viewport_height=720
window/handheld/orientation=0
```

- [ ] **Step 2: Commit**

```bash
git add project.godot
git commit -m "feat: change display to landscape 1280x720"
```

---

### Task 2: Update MainMenu.tscn for landscape

**Files:**
- Modify: `scenes/menu/MainMenu.tscn`

Change logo from 300×300 to 200×200, wrap buttons in horizontal row, adjust spacers for 720px height.

- [ ] **Step 1: Rewrite MainMenu.tscn**

Replace the full file content with:

```
[gd_scene format=3 uid="uid://c0n06gn2s4saf"]

[ext_resource type="Script" uid="uid://cdl8tnqsalob6" path="res://scenes/menu/MainMenu.gd" id="1_n60i8"]
[ext_resource type="Texture2D" uid="uid://duhqcyy7hgu6b" path="res://assets/ronda_patrol_logo_512.png" id="2_p3qva"]

[node name="MainMenu" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_n60i8")

[node name="VBox" type="VBoxContainer" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
theme_override_constants/separation = 20

[node name="SpacerTop" type="Control" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3

[node name="Logo" type="TextureRect" parent="VBox"]
custom_minimum_size = Vector2(200, 200)
layout_mode = 2
size_flags_horizontal = 4
texture = ExtResource("2_p3qva")
expand_mode = 1

[node name="SpacerMid" type="Control" parent="VBox"]
layout_mode = 2
size_flags_vertical = 1

[node name="ButtonRow" type="HBoxContainer" parent="VBox"]
layout_mode = 2
size_flags_horizontal = 4
theme_override_constants/separation = 20

[node name="ExitButton" type="Button" parent="VBox/ButtonRow"]
custom_minimum_size = Vector2(180, 50)
layout_mode = 2
text = "Exit"

[node name="PlayButton" type="Button" parent="VBox/ButtonRow"]
custom_minimum_size = Vector2(180, 50)
layout_mode = 2
text = "Play"

[node name="StoryButton" type="Button" parent="VBox/ButtonRow"]
custom_minimum_size = Vector2(180, 50)
layout_mode = 2
text = "Story"

[node name="HowToPlay" type="Label" parent="VBox"]
layout_mode = 2
text = "How to play: Collect all jimpitan coins while avoiding ghosts!"
horizontal_alignment = 1
autowrap_mode = 2

[node name="SpacerBottom" type="Control" parent="VBox"]
layout_mode = 2
size_flags_vertical = 2
```

- [ ] **Step 2: Update MainMenu.gd node paths**

Replace the three @onready lines:

```gdscript
@onready var story_btn := $VBox/ButtonRow/StoryButton
@onready var play_btn := $VBox/ButtonRow/PlayButton
@onready var exit_btn := $VBox/ButtonRow/ExitButton
```

- [ ] **Step 3: Commit**

```bash
git add scenes/menu/MainMenu.tscn scenes/menu/MainMenu.gd
git commit -m "feat: adapt MainMenu layout for landscape"
```

---

### Task 3: Rewrite StoryPage.tscn for landscape side-by-side

**Files:**
- Modify: `scenes/menu/StoryPage.tscn`

New layout: Image panel (left half, 640px) + Story panel (right half, 640px). Close button top-right, Prev bottom-left, Next/Finish bottom-right.

- [ ] **Step 1: Rewrite StoryPage.tscn**

Replace the full file content with:

```
[gd_scene load_steps=2 format=3 uid="uid://dq2uxhb1xqhif"]

[ext_resource type="Script" path="res://scenes/menu/StoryPage.gd" id="1_6v0s2"]

[node name="StoryPage" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_6v0s2")

[node name="ImagePanel" type="Control" parent="."]
layout_mode = 1
offset_right = 640
offset_bottom = 720

[node name="TextureRect" type="TextureRect" parent="ImagePanel"]
layout_mode = 1
offset_left = 10
offset_top = 10
offset_right = 630
offset_bottom = 620
color = Color(0.2, 0.2, 0.3, 1)

[node name="PrevButton" type="Button" parent="ImagePanel"]
layout_mode = 1
offset_left = 10
offset_top = 640
offset_right = 90
offset_bottom = 680
text = "Prev"

[node name="StoryPanel" type="Control" parent="."]
layout_mode = 1
offset_left = 640
offset_right = 1280
offset_bottom = 720

[node name="CloseButton" type="Button" parent="StoryPanel"]
layout_mode = 1
offset_left = 1220
offset_top = 10
offset_right = 1260
offset_bottom = 40
text = "X"

[node name="StoryArea" type="ScrollContainer" parent="StoryPanel"]
layout_mode = 1
offset_left = 10
offset_top = 50
offset_right = 620
offset_bottom = 620

[node name="StoryLabel" type="Label" parent="StoryPanel/StoryArea"]
layout_mode = 2
custom_minimum_size = Vector2(560, 0)
text = ""
autowrap_mode = 2

[node name="PageLabel" type="Label" parent="StoryPanel"]
layout_mode = 1
offset_left = 300
offset_top = 640
offset_right = 380
offset_bottom = 680
text = "1 / 1"
horizontal_alignment = 1

[node name="NextButton" type="Button" parent="StoryPanel"]
layout_mode = 1
offset_left = 1150
offset_top = 640
offset_right = 1240
offset_bottom = 680
text = "Next"
```

- [ ] **Step 2: Update StoryPage.gd node paths**

Replace the @onready lines:

```gdscript
@onready var close_btn := $StoryPanel/CloseButton
@onready var story_label := $StoryPanel/StoryArea/StoryLabel
@onready var image_rect := $ImagePanel/TextureRect
@onready var prev_btn := $ImagePanel/PrevButton
@onready var next_btn := $StoryPanel/NextButton
@onready var page_label := $StoryPanel/PageLabel
```

- [ ] **Step 3: Commit**

```bash
git add scenes/menu/StoryPage.tscn scenes/menu/StoryPage.gd
git commit -m "feat: adapt StoryPage layout for landscape side-by-side"
```

---

### Task 4: Rewrite LevelTrack.tscn for landscape side-by-side

**Files:**
- Modify: `scenes/menu/LevelTrack.tscn`

New layout: Status + Treasury stacked top-left. Shop panel (left, 240px) with 2×2 grid. Level track (right, scrollable). Main Menu button in shop panel.

- [ ] **Step 1: Rewrite LevelTrack.tscn**

Replace the full file content with:

```
[gd_scene load_steps=2 format=3 uid="uid://bw0lsvffbg26k"]

[ext_resource type="Script" path="res://scenes/menu/LevelTrack.gd" id="1_bf6or"]

[node name="LevelTrack" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_bf6or")

[node name="StatusLabel" type="Label" parent="."]
layout_mode = 1
offset_left = 8
offset_top = 8
offset_right = 300
offset_bottom = 28
text = "Status: Ready"

[node name="TreasuryLabel" type="Label" parent="."]
layout_mode = 1
offset_left = 8
offset_top = 32
offset_right = 300
offset_bottom = 52
text = "Regional treasury: 0 coins"

[node name="ShopPanel" type="Panel" parent="."]
layout_mode = 1
offset_left = 10
offset_top = 60
offset_right = 250
offset_bottom = 700

[node name="ShopLabel" type="Label" parent="ShopPanel"]
layout_mode = 1
offset_left = 8
offset_top = 8
offset_right = 232
offset_bottom = 30
text = "Shop"

[node name="GridContainer" type="GridContainer" parent="ShopPanel"]
layout_mode = 1
offset_left = 8
offset_top = 36
offset_right = 232
offset_bottom = 200
columns = 2

[node name="MainMenuButton" type="Button" parent="ShopPanel"]
layout_mode = 1
offset_left = 8
offset_top = 650
offset_right = 232
offset_bottom = 690
text = "Main Menu"

[node name="LevelScroll" type="ScrollContainer" parent="."]
layout_mode = 1
offset_left = 270
offset_top = 60
offset_right = 1270
offset_bottom = 700

[node name="LevelContainer" type="VBoxContainer" parent="LevelScroll"]
layout_mode = 2
size_flags_horizontal = 3
alignment = 1
```

- [ ] **Step 2: Update LevelTrack.gd node paths**

Replace the @onready lines:

```gdscript
@onready var status_label := $StatusLabel
@onready var treasury_label := $TreasuryLabel
@onready var level_container := $LevelScroll/LevelContainer
@onready var shop_container := $ShopPanel/GridContainer
@onready var main_menu_btn := $ShopPanel/MainMenuButton
```

- [ ] **Step 3: Commit**

```bash
git add scenes/menu/LevelTrack.tscn scenes/menu/LevelTrack.gd
git commit -m "feat: adapt LevelTrack layout for landscape side-by-side"
```

---

### Task 5: Rewrite HUD.gd for landscape three-column layout

**Files:**
- Modify: `scenes/hud/HUD.gd`

New layout: Left column (200px) with stats + D-Pad, center gameplay area (900px), right column (180px) with radar + exit + SkillBar. Stats use GridContainer for colon alignment.

- [ ] **Step 1: Rewrite HUD.gd**

Replace the full file content with:

```gdscript
extends CanvasLayer

const LEFT_PANEL_W := 200
const RIGHT_PANEL_W := 180
const GAMEPLAY_W := 900
const GAMEPLAY_H := 720

var level_label: Label
var ghosts_label: Label
var stamina_bar: ProgressBar
var jimpitan_label: Label
var radar: Control
var dpad: Control
var skill_bar: GridContainer
var return_msg: Label


func _init() -> void:
	var left_bg = ColorRect.new()
	left_bg.color = Color(0, 0, 0, 1)
	left_bg.position = Vector2(0, 0)
	left_bg.size = Vector2(LEFT_PANEL_W, GAMEPLAY_H)
	add_child(left_bg)

	var right_bg = ColorRect.new()
	right_bg.color = Color(0, 0, 0, 1)
	right_bg.position = Vector2(LEFT_PANEL_W + GAMEPLAY_W, 0)
	right_bg.size = Vector2(RIGHT_PANEL_W, GAMEPLAY_H)
	add_child(right_bg)

	# --- Left column: stats grid for colon alignment ---
	var stats_grid = GridContainer.new()
	stats_grid.name = "StatsGrid"
	stats_grid.columns = 2
	stats_grid.position = Vector2(8, 10)
	stats_grid.add_theme_constant_override("h_separation", 4)
	stats_grid.add_theme_constant_override("v_separation", 4)
	add_child(stats_grid)

	var lvl_name = Label.new()
	lvl_name.text = "Level"
	lvl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(lvl_name)

	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = ": 1"
	stats_grid.add_child(level_label)

	var gho_name = Label.new()
	gho_name.text = "Ghosts"
	gho_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(gho_name)

	ghosts_label = Label.new()
	ghosts_label.name = "GhostsLabel"
	ghosts_label.text = ": 0"
	stats_grid.add_child(ghosts_label)

	var jim_name = Label.new()
	jim_name.text = "Jimpitan"
	jim_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(jim_name)

	jimpitan_label = Label.new()
	jimpitan_label.name = "JimpitanLabel"
	jimpitan_label.text = ": 0 / 0"
	stats_grid.add_child(jimpitan_label)

	var sta_name = Label.new()
	sta_name.text = "Stamina"
	sta_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_grid.add_child(sta_name)

	stamina_bar = ProgressBar.new()
	stamina_bar.name = "StaminaBar"
	stamina_bar.custom_minimum_size = Vector2(100, 16)
	stamina_bar.size = Vector2(100, 16)
	stamina_bar.value = 100.0
	stats_grid.add_child(stamina_bar)

	# --- Left column: D-Pad ---
	dpad = preload("res://scenes/hud/Dpad.tscn").instantiate()
	dpad.name = "Dpad"
	dpad.position = Vector2(20, 250)
	add_child(dpad)

	# --- Right column: Radar ---
	radar = preload("res://scenes/hud/Radar.tscn").instantiate()
	radar.name = "Radar"
	radar.position = Vector2(LEFT_PANEL_W + GAMEPLAY_W + 40, 10)
	radar.size = Vector2(100, 100)
	add_child(radar)

	# --- Right column: Exit button ---
	var exit_btn = Button.new()
	exit_btn.name = "ExitButton"
	exit_btn.text = "Exit"
	exit_btn.position = Vector2(LEFT_PANEL_W + GAMEPLAY_W + 50, 130)
	exit_btn.size = Vector2(80, 36)
	exit_btn.focus_mode = Control.FOCUS_NONE
	exit_btn.pressed.connect(_on_exit_pressed)
	add_child(exit_btn)

	# --- Right column: SkillBar ---
	skill_bar = preload("res://scenes/hud/SkillBar.tscn").instantiate()
	skill_bar.name = "SkillBar"
	skill_bar.position = Vector2(LEFT_PANEL_W + GAMEPLAY_W + 20, 190)
	add_child(skill_bar)

	# --- Overlay: Return message ---
	return_msg = Label.new()
	return_msg.name = "ReturnMsg"
	return_msg.text = "Kembali ke Poskamling!"
	return_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return_msg.position = Vector2(210, 10)
	return_msg.size = Vector2(880, 40)
	return_msg.add_theme_color_override("font_color", Color(1, 0.8, 0))
	return_msg.visible = false
	add_child(return_msg)


func update_level(lvl: int) -> void:
	level_label.text = ": %d" % lvl


func update_ghosts(count: int) -> void:
	ghosts_label.text = ": %d" % count


func update_stamina(percent: float) -> void:
	stamina_bar.value = percent * 100


func update_jimpitan(collected: int, total: int) -> void:
	jimpitan_label.text = ": %d / %d" % [collected, total]


func update_radar(ghost_positions: Array, map_size: Vector2) -> void:
	radar.update_positions(ghost_positions, map_size)


func show_return_message() -> void:
	return_msg.visible = true


func hide_return_message() -> void:
	return_msg.visible = false


func _on_exit_pressed() -> void:
	SceneManager.go_to_scene("res://scenes/menu/LevelTrack.tscn")
```

- [ ] **Step 2: Commit**

```bash
git add scenes/hud/HUD.gd
git commit -m "feat: adapt HUD layout for landscape three-column"
```

---

### Task 6: Self-review and verification

- [ ] **Step 1: Verify all @onready paths match new scene trees**

Checklist:
- `MainMenu.gd`: paths match `VBox/ButtonRow/*Button`
- `StoryPage.gd`: paths match `ImagePanel/*`, `StoryPanel/*`
- `LevelTrack.gd`: paths match `StatusLabel`, `TreasuryLabel`, `LevelScroll/LevelContainer`, `ShopPanel/GridContainer`, `ShopPanel/MainMenuButton`
- `HUD.gd`: all node names match `add_child()` name arguments

- [ ] **Step 2: Commit all remaining changes**

```bash
git status
git add -A
git commit -m "feat: complete landscape layout conversion to 1280x720"
```

- [ ] **Step 3: Verify the project opens without errors**

Run Godot with the project to check for load errors:
```bash
godot --path . --headless --script res://scenes/menu/MainMenu.gd 2>&1 | head -30
```

(Or open in editor and check the Output panel for errors.)
