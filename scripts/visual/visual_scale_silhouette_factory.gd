extends RefCounted
class_name VisualScaleSilhouetteFactory

## Procedural silhouettes for VisualScaleLab only — not shipped gameplay art.


static func create_calder_idle_texture(frame_size: Vector2i) -> Texture2D:
	var w := frame_size.x
	var h := frame_size.y
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var body := Color(0.72, 0.16, 0.12, 1.0)
	var coat := Color(0.58, 0.12, 0.1, 1.0)
	var hat := Color(0.22, 0.16, 0.14, 1.0)
	var brand := Color(0.95, 0.18, 0.08, 1.0)
	var boot := Color(0.28, 0.2, 0.16, 1.0)

	var body_w := int(w * 0.55)
	var body_h := int(h * 0.42)
	var body_x := (w - body_w) / 2
	var body_y := int(h * 0.38)
	_fill_rect(image, body_x, body_y, body_w, body_h, body)

	var hat_w := int(w * 0.72)
	var hat_h := maxi(4, int(h * 0.09))
	var hat_x := (w - hat_w) / 2
	var hat_y := int(h * 0.12)
	_fill_rect(image, hat_x, hat_y, hat_w, hat_h, hat)
	_fill_rect(image, hat_x + int(hat_w * 0.15), hat_y - maxi(2, hat_h / 3), int(hat_w * 0.7), maxi(2, hat_h / 2), hat)

	var coat_w := int(w * 0.78)
	var coat_h := int(h * 0.48)
	var coat_x := (w - coat_w) / 2
	var coat_y := int(h * 0.34)
	_fill_rect(image, coat_x, coat_y, coat_w, coat_h, coat)

	var leg_w := int(w * 0.22)
	var leg_h := int(h * 0.22)
	_fill_rect(image, body_x + int(body_w * 0.15), h - leg_h, leg_w, leg_h, boot)
	_fill_rect(image, body_x + body_w - leg_w - int(body_w * 0.15), h - leg_h, leg_w, leg_h, boot)

	var brand_sz := maxi(4, int(min(w, h) * 0.18))
	_fill_rect(image, body_x + body_w - brand_sz, body_y + int(body_h * 0.35), brand_sz, brand_sz, brand)

	return ImageTexture.create_from_image(image)


static func create_enemy_texture(enemy_id: StringName, frame_size: Vector2i) -> Texture2D:
	var w := frame_size.x
	var h := frame_size.y
	var image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	match enemy_id:
		&"brawler":
			_draw_brawler(image, w, h)
		&"gunslinger":
			_draw_gunslinger(image, w, h)
		_:
			_draw_brawler(image, w, h)

	return ImageTexture.create_from_image(image)


static func create_prop_texture(prop_id: StringName) -> Texture2D:
	var size := _prop_size(prop_id)
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	match prop_id:
		&"door":
			_fill_rect(image, 0, 0, size.x, size.y, Color(0.42, 0.28, 0.18, 1.0))
			_fill_rect(image, int(size.x * 0.35), int(size.y * 0.4), int(size.x * 0.3), int(size.y * 0.25), Color(0.18, 0.12, 0.08, 1.0))
		&"barrel":
			_fill_rect(image, 2, 4, size.x - 4, size.y - 6, Color(0.36, 0.22, 0.14, 1.0))
			_fill_rect(image, 0, int(size.y * 0.35), size.x, 3, Color(0.28, 0.18, 0.1, 1.0))
		&"window":
			_fill_rect(image, 0, 0, size.x, size.y, Color(0.48, 0.62, 0.78, 0.85))
			_fill_rect(image, int(size.x * 0.45), 0, 2, size.y, Color(0.32, 0.4, 0.5, 1.0))
		&"sidewalk":
			_fill_rect(image, 0, 0, size.x, size.y, Color(0.44, 0.32, 0.24, 1.0))
			for x in range(0, size.x, 16):
				_fill_rect(image, x, 0, 1, size.y, Color(0.36, 0.26, 0.18, 1.0))
		&"platform":
			_fill_rect(image, 0, 0, size.x, size.y, Color(0.5, 0.38, 0.26, 1.0))
			_fill_rect(image, 0, 0, size.x, 3, Color(0.62, 0.48, 0.34, 1.0))
		&"saloon":
			_fill_rect(image, 0, int(size.y * 0.25), size.x, int(size.y * 0.75), Color(0.46, 0.3, 0.2, 1.0))
			_fill_polygon_flat(image, [
				Vector2i(0, int(size.y * 0.25)),
				Vector2i(int(size.x * 0.5), 0),
				Vector2i(size.x, int(size.y * 0.25)),
			], Color(0.32, 0.18, 0.12, 1.0))
			_fill_rect(image, int(size.x * 0.38), int(size.y * 0.55), int(size.x * 0.24), int(size.y * 0.35), Color(0.2, 0.12, 0.08, 1.0))
		_:
			_fill_rect(image, 0, 0, size.x, size.y, Color(0.5, 0.5, 0.5, 1.0))

	return ImageTexture.create_from_image(image)


static func _prop_size(prop_id: StringName) -> Vector2i:
	match prop_id:
		&"door":
			return Vector2i(32, 64)
		&"barrel":
			return Vector2i(48, 40)
		&"window":
			return Vector2i(32, 32)
		&"sidewalk":
			return Vector2i(256, 12)
		&"platform":
			return Vector2i(96, 16)
		&"saloon":
			return Vector2i(192, 128)
		_:
			return Vector2i(32, 32)


static func _draw_brawler(image: Image, w: int, h: int) -> void:
	var skin := Color(0.62, 0.48, 0.38, 1.0)
	var rags := Color(0.38, 0.34, 0.32, 1.0)
	_fill_rect(image, int(w * 0.22), int(h * 0.15), int(w * 0.56), int(h * 0.2), skin)
	_fill_rect(image, int(w * 0.18), int(h * 0.32), int(w * 0.64), int(h * 0.45), rags)
	_fill_rect(image, int(w * 0.2), int(h * 0.72), int(w * 0.22), int(h * 0.28), rags)
	_fill_rect(image, int(w * 0.58), int(h * 0.72), int(w * 0.22), int(h * 0.28), rags)


static func _draw_gunslinger(image: Image, w: int, h: int) -> void:
	var coat := Color(0.28, 0.22, 0.34, 1.0)
	var hat := Color(0.18, 0.14, 0.2, 1.0)
	var vermilite := Color(0.82, 0.22, 0.42, 1.0)
	_fill_rect(image, int(w * 0.15), int(h * 0.1), int(w * 0.7), int(h * 0.1), hat)
	_fill_rect(image, int(w * 0.2), int(h * 0.28), int(w * 0.6), int(h * 0.5), coat)
	_fill_rect(image, int(w * 0.05), int(h * 0.42), int(w * 0.22), int(h * 0.08), vermilite)


static func _fill_rect(image: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(maxi(0, y), mini(image.get_height(), y + h)):
		for px in range(maxi(0, x), mini(image.get_width(), x + w)):
			image.set_pixel(px, py, color)


static func _fill_polygon_flat(image: Image, points: Array, color: Color) -> void:
	if points.size() < 3:
		return
	var min_y: int = points[0].y
	var max_y: int = points[0].y
	for p in points:
		min_y = mini(min_y, p.y)
		max_y = maxi(max_y, p.y)
	for y in range(min_y, max_y + 1):
		var crossings: Array = []
		for i in range(points.size()):
			var a: Vector2i = points[i]
			var b: Vector2i = points[(i + 1) % points.size()]
			if a.y == b.y:
				continue
			if (a.y <= y and b.y > y) or (b.y <= y and a.y > y):
				var t := float(y - a.y) / float(b.y - a.y)
				crossings.append(int(lerp(float(a.x), float(b.x), t)))
		crossings.sort()
		var index := 0
		while index + 1 < crossings.size():
			var x0: int = crossings[index]
			var x1: int = crossings[index + 1]
			for x in range(x0, x1 + 1):
				if x >= 0 and x < image.get_width() and y >= 0 and y < image.get_height():
					image.set_pixel(x, y, color)
			index += 2
