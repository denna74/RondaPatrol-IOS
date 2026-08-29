extends CanvasLayer

var progress_bar: ProgressBar
var tip_label: Label
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

	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vs = get_viewport().get_visible_rect().size
	var cx = vs.x / 2
	var cy = vs.y / 2

	var logo = Sprite2D.new()
	logo.texture = preload("res://assets/ronda_patrol_logo_512.png")
	logo.scale = Vector2(0.3, 0.3)
	logo.position = Vector2(cx, cy - 80)
	add_child(logo)

	progress_bar = ProgressBar.new()
	progress_bar.show_percentage = false
	progress_bar.value = 0.0
	progress_bar.size = Vector2(600, 20)
	progress_bar.position = Vector2(cx - 300, cy + 10)
	add_child(progress_bar)

	tip_label = Label.new()
	tip_label.text = TIPS[randi() % TIPS.size()]
	tip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.size = Vector2(600, 50)
	tip_label.position = Vector2(cx - 300, cy + 50)
	add_child(tip_label)

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
	var fade_overlay = ColorRect.new()
	fade_overlay.color = Color(0, 0, 0, 0)
	fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fade_overlay)
	var tween = create_tween()
	tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 0.5)
	tween.finished.connect(_go_to_gameplay)


func _go_to_gameplay() -> void:
	SceneManager.go_to_scene("res://scenes/gameplay/Gameplay.tscn", {"level": _level})
