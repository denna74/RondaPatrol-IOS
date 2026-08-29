static func build_button_texture(text: String, font_dir: String, char_size: Vector2i, bg_tex: Texture2D) -> Texture2D:
	var bg_img: Image = bg_tex.get_image()
	var char_imgs := []
	var total_w := 0
	var char_h := char_size.y

	for i in text.length():
		var c := text[i].to_upper()
		if c == " ":
			total_w += 10
			char_imgs.append(null)
		else:
			var tex := load(font_dir + c + ".png") as Texture2D
			if tex:
				var char_img: Image = tex.get_image()
				char_img = _crop_to_content(char_img)
				char_img.resize(char_size.x, char_h, Image.INTERPOLATE_LANCZOS)
				char_imgs.append(char_img)
				total_w += char_size.x
			else:
				total_w += char_size.x
				char_imgs.append(null)

	var bg_w := bg_img.get_width()
	var bg_h := bg_img.get_height()
	var offset_x := (bg_w - total_w) / 2
	var offset_y := (bg_h - char_h) / 2

	var result := bg_img.duplicate()
	var x := offset_x
	for ci in char_imgs:
		if ci == null:
			x += 10
		else:
			result.blend_rect(ci, Rect2i(0, 0, char_size.x, char_h), Vector2i(x, offset_y))
			x += char_size.x

	return ImageTexture.create_from_image(result)

static func darken_texture(tex: Texture2D) -> Texture2D:
	var img: Image = tex.get_image()
	for x in img.get_width():
		for y in img.get_height():
			var c := img.get_pixel(x, y)
			c.r *= 0.7
			c.g *= 0.7
			c.b *= 0.7
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func _crop_to_content(img: Image) -> Image:
	var min_x := img.get_width()
	var min_y := img.get_height()
	var max_x := 0
	var max_y := 0
	for x in img.get_width():
		for y in img.get_height():
			if img.get_pixel(x, y).a > 0:
				if x < min_x: min_x = x
				if y < min_y: min_y = y
				if x > max_x: max_x = x
				if y > max_y: max_y = y
	if max_x < min_x:
		return img
	var rect := Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
	var cropped := Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	cropped.blit_rect(img, rect, Vector2i.ZERO)
	return cropped
