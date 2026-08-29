extends Node2D

signal skill_used(item_id: String)

const COLS := 2
const BTN_SIZE := 100.0
const GAP := 24.0

var skill_ids := ["senter", "kopi", "balsem", "kacang", "cassava", "sajen"]

func _ready() -> void:
	for i in skill_ids.size():
		var btn = preload("res://scenes/hud/SkillButton.tscn").instantiate()
		btn.setup(skill_ids[i])
		btn.pressed.connect(_on_skill_pressed.bind(skill_ids[i]))
		var col = i % COLS
		var row = i / COLS
		btn.position = Vector2(col * (BTN_SIZE + GAP), row * (BTN_SIZE + GAP))
		add_child(btn)

func _on_skill_pressed(item_id: String) -> void:
	if SaveManager.has_item(item_id):
		skill_used.emit(item_id)
