extends RefCounted
class_name CultBrawlerPlaceholderFactory

## Procedural Cult Brawler silhouettes — readable telegraph, hat, cult mark, hook arm.
## Not final art; satisfies beta visual contract until production sheets land.

const FRAME_W := CultBrawlerAnimationContract.APPROVED_FRAME_SIZE.x
const FRAME_H := CultBrawlerAnimationContract.APPROVED_FRAME_SIZE.y

const BODY_COLOR := Color(0.52, 0.12, 0.14, 1.0)
const HAT_COLOR := Color(0.18, 0.1, 0.12, 1.0)
const MARK_COLOR := Color(0.92, 0.18, 0.08, 1.0)
const SKIN_COLOR := Color(0.72, 0.14, 0.12, 1.0)
const TELEGRAPH_GLOW := Color(1.0, 0.72, 0.18, 0.55)
const VERMILITE_GLOW := Color(0.95, 0.22, 0.08, 0.85)


static func create_pilot_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for anim_id in CultBrawlerAnimationContract.PILOT_ANIMATION_IDS:
		_add_from_contract(frames, anim_id)

	return frames


static func create_single_clip(anim_id: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_from_contract(frames, anim_id)
	return frames


static func _add_from_contract(frames: SpriteFrames, anim_id: StringName) -> void:
	var spec: Dictionary = CultBrawlerAnimationContract.get_clip_specs().get(String(anim_id), {})
	var frame_count: int = int(spec.get("frames", 2))
	var frame_duration: float = float(spec.get("frame_duration", 0.1))
	var loop: bool = bool(spec.get("loop", false))

	if loop:
		_add_loop(frames, anim_id, frame_count, frame_duration)
	else:
		_add_one_shot(frames, anim_id, frame_count, frame_duration)


static func _add_loop(
	frames: SpriteFrames,
	anim_name: StringName,
	frame_count: int,
	frame_duration: float
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, 1.0)

	for index in range(frame_count):
		frames.add_frame(
			anim_name,
			_make_brawler_texture(anim_name, index, frame_count),
			frame_duration
		)


static func _add_one_shot(
	frames: SpriteFrames,
	anim_name: StringName,
	frame_count: int,
	frame_duration: float
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, false)
	frames.set_animation_speed(anim_name, 1.0)

	for index in range(frame_count):
		frames.add_frame(
			anim_name,
			_make_brawler_texture(anim_name, index, frame_count),
			frame_duration
		)


static func _make_brawler_texture(anim_id: StringName, frame_index: int, frame_count: int) -> Texture2D:
	var image := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))

	var pose := _resolve_pose(anim_id, frame_index, frame_count)
	_draw_hat(image, pose)
	_draw_body(image, pose)
	_draw_cult_mark(image, pose)
	_draw_face(image, pose)
	_draw_arms(image, pose, anim_id, frame_index)
	_draw_legs(image, pose, anim_id, frame_index)
	_draw_telegraph_overlay(image, anim_id, frame_index, pose)
	_draw_hit_overlay(image, anim_id, frame_index)

	return ImageTexture.create_from_image(image)


static func _resolve_pose(anim_id: StringName, frame_index: int, frame_count: int) -> Dictionary:
	var lean := 0.0
	var bob := 0.0
	var arm_pull := 0.0
	var arm_extend := 0.0
	var squash := 0.0

	match anim_id:
		&"idle":
			bob = sin(float(frame_index) * 0.9) * 1.5
		&"patrol":
			bob = sin(float(frame_index) * 1.4) * 2.0
			lean = sin(float(frame_index) * 1.4) * 2.0
		&"alert":
			squash = -2.0
			lean = -3.0
		&"approach":
			bob = sin(float(frame_index) * 1.8) * 2.5
			lean = 4.0
		&"attack_startup":
			var t := float(frame_index) / maxf(float(frame_count - 1), 1.0)
			arm_pull = lerpf(0.0, 18.0, t)
			lean = lerpf(0.0, -6.0, t)
			squash = lerpf(0.0, -3.0, t)
		&"attack_active":
			var t := float(frame_index) / maxf(float(frame_count - 1), 1.0)
			arm_extend = lerpf(8.0, 26.0, t)
			lean = lerpf(-4.0, 8.0, t)
		&"attack_recovery":
			var t := float(frame_index) / maxf(float(frame_count - 1), 1.0)
			arm_extend = lerpf(20.0, 4.0, t)
			lean = lerpf(6.0, 0.0, t)
		&"hurt":
			lean = 6.0 + float(frame_index) * 2.0
		&"heavy_hurt":
			lean = 10.0 + float(frame_index) * 3.0
			squash = -4.0
		&"knocked_back":
			lean = 14.0 + float(frame_index) * 4.0
			bob = float(frame_index) * -2.0
		&"stagger":
			lean = 8.0 + sin(float(frame_index) * 1.2) * 6.0
			squash = -5.0
		&"death":
			var t := float(frame_index) / maxf(float(frame_count - 1), 1.0)
			lean = lerpf(0.0, 22.0, t)
			bob = lerpf(0.0, 10.0, t)
			squash = lerpf(0.0, 8.0, t)

	return {
		"lean": lean,
		"bob": bob,
		"arm_pull": arm_pull,
		"arm_extend": arm_extend,
		"squash": squash,
	}


static func _draw_hat(image: Image, pose: Dictionary) -> void:
	var brim_y := 18 + int(pose.get("bob", 0.0)) + int(pose.get("squash", 0.0))
	var crown_top := brim_y - CultBrawlerAnimationContract.HAT_HEIGHT_PX
	var center_x := 17 + int(pose.get("lean", 0.0) * 0.2)
	var half_brim := CultBrawlerAnimationContract.HAT_BRIM_WIDTH_PX / 2

	for y in range(crown_top, brim_y):
		var row_t := float(y - crown_top) / maxf(float(CultBrawlerAnimationContract.HAT_HEIGHT_PX), 1.0)
		var half_w := int(lerpf(4.0, float(half_brim), row_t))
		for x in range(center_x - half_w, center_x + half_w):
			if _in_bounds(image, x, y):
				image.set_pixel(x, y, HAT_COLOR)


static func _draw_body(image: Image, pose: Dictionary) -> void:
	var top_y := 20 + int(pose.get("bob", 0.0)) + int(pose.get("squash", 0.0))
	var bottom_y := FRAME_H - 2
	var center_x := 17 + int(pose.get("lean", 0.0) * 0.35)
	var half_w := CultBrawlerAnimationContract.SHOULDER_WIDTH_PX / 2

	for y in range(top_y, bottom_y):
		var row_t := float(y - top_y) / maxf(float(bottom_y - top_y), 1.0)
		var taper := int(lerpf(float(half_w), float(half_w - 4), row_t))
		for x in range(center_x - taper, center_x + taper):
			if _in_bounds(image, x, y):
				image.set_pixel(x, y, BODY_COLOR)


static func _draw_cult_mark(image: Image, pose: Dictionary) -> void:
	var center_x := 17 + int(pose.get("lean", 0.0) * 0.25)
	var center_y := 30 + int(pose.get("bob", 0.0))
	for y in range(center_y - 4, center_y + 5):
		for x in range(center_x - 3, center_x + 4):
			if _in_bounds(image, x, y):
				image.set_pixel(x, y, MARK_COLOR)


static func _draw_face(image: Image, pose: Dictionary) -> void:
	var center_x := 17 + int(pose.get("lean", 0.0) * 0.2)
	var center_y := 24 + int(pose.get("bob", 0.0))
	for y in range(center_y - 3, center_y + 2):
		for x in range(center_x - 4, center_x + 5):
			if _in_bounds(image, x, y):
				image.set_pixel(x, y, SKIN_COLOR)


static func _draw_arms(
	image: Image,
	pose: Dictionary,
	anim_id: StringName,
	frame_index: int
) -> void:
	var center_x := 17 + int(pose.get("lean", 0.0) * 0.3)
	var shoulder_y := 28 + int(pose.get("bob", 0.0))
	var pull: float = float(pose.get("arm_pull", 0.0))
	var extend: float = float(pose.get("arm_extend", 0.0))

	var back_hand_x := center_x - 8 - int(pull * 0.2)
	var front_hand_x := center_x + 6 + int(extend)
	var front_hand_y := shoulder_y + 4 + int(pull * 0.15) - int(extend * 0.1)

	if anim_id in [&"attack_startup", &"attack_active", &"attack_recovery"]:
		_fill_rect(image, back_hand_x - 2, shoulder_y, back_hand_x + 4, shoulder_y + 10, BODY_COLOR.darkened(0.08))
		_fill_rect(image, front_hand_x - 2, front_hand_y, front_hand_x + 6, front_hand_y + 8, SKIN_COLOR)
		_draw_hook(image, front_hand_x + 4, front_hand_y + 2, extend)
	else:
		_fill_rect(image, center_x - 10, shoulder_y + 2, center_x - 4, shoulder_y + 12, BODY_COLOR.darkened(0.05))
		_fill_rect(image, center_x + 4, shoulder_y + 2, center_x + 10, shoulder_y + 12, BODY_COLOR.darkened(0.05))


static func _draw_hook(image: Image, tip_x: int, tip_y: int, extend: float) -> void:
	var hook_len := int(8.0 + extend * 0.25)
	for i in range(hook_len):
		var x := tip_x + i
		var y := tip_y + int(sin(float(i) * 0.6) * 2.0)
		if _in_bounds(image, x, y):
			image.set_pixel(x, y, Color(0.85, 0.78, 0.55, 1.0))


static func _draw_legs(image: Image, pose: Dictionary, anim_id: StringName, frame_index: int) -> void:
	var center_x := 17 + int(pose.get("lean", 0.0) * 0.2)
	var hip_y := FRAME_H - 18 + int(pose.get("bob", 0.0))
	var stride := 0
	if anim_id in [&"patrol", &"approach"]:
		stride = 3 if frame_index % 2 == 0 else -3

	_fill_rect(image, center_x - 8 + stride, hip_y, center_x - 2, FRAME_H - 2, BODY_COLOR.darkened(0.12))
	_fill_rect(image, center_x + 2 - stride, hip_y, center_x + 8, FRAME_H - 2, BODY_COLOR.darkened(0.12))


static func _draw_telegraph_overlay(image: Image, anim_id: StringName, frame_index: int, pose: Dictionary) -> void:
	if anim_id == &"attack_startup" and frame_index >= 2:
		var center_x := 17 + int(pose.get("lean", 0.0) * 0.3)
		var reach := int(12 + frame_index * 4)
		for x in range(center_x, center_x + reach):
			if _in_bounds(image, x, FRAME_H - 4):
				image.set_pixel(x, FRAME_H - 4, TELEGRAPH_GLOW)
				image.set_pixel(x, FRAME_H - 3, TELEGRAPH_GLOW.darkened(0.2))

	if anim_id == &"stagger":
		var center_x := 17
		var center_y := 32
		for y in range(center_y - 5, center_y + 6):
			for x in range(center_x - 5, center_x + 6):
				if _in_bounds(image, x, y):
					var existing := image.get_pixel(x, y)
					if existing.a > 0.1:
						image.set_pixel(x, y, existing.lerp(VERMILITE_GLOW, 0.45))


static func _draw_hit_overlay(image: Image, anim_id: StringName, frame_index: int) -> void:
	if anim_id in [&"hurt", &"heavy_hurt", &"knocked_back"] and frame_index == 0:
		for y in range(8, FRAME_H - 2):
			for x in range(4, FRAME_W - 4):
				var existing := image.get_pixel(x, y)
				if existing.a > 0.1:
					image.set_pixel(x, y, existing.lerp(Color(1.0, 0.92, 0.7, 1.0), 0.35))


static func _fill_rect(image: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	for y in range(y0, y1):
		for x in range(x0, x1):
			if _in_bounds(image, x, y):
				image.set_pixel(x, y, color)


static func _in_bounds(image: Image, x: int, y: int) -> bool:
	return x >= 0 and y >= 0 and x < image.get_width() and y < image.get_height()
