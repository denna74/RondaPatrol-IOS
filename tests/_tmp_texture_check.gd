extends Node

func _ready() -> void:
	var menu: Node = load("res://scenes/menu/MainMenu.tscn").instantiate()
	add_child(menu)
	await get_tree().process_frame
	var tex: Texture2D = menu._build_settings_texture("PENGATURAN")
	var img: Image = tex.get_image()
	img.save_png("/tmp/opencode/settings_composite.png")
	print("SAVED ", img.get_size())
	menu.queue_free()
	get_tree().quit()
