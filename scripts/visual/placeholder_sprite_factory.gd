extends RefCounted
class_name PlaceholderSpriteFactory

## Procedural colored rects for pipeline validation — not final art.

const FRAME_W := 32
const FRAME_H := 56


static func create_calder_pilot_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	_add_from_contract(frames, &"idle", Color(0.76, 0.18, 0.13))
	_add_from_contract(frames, &"run", Color(0.82, 0.22, 0.16))
	_add_from_contract(frames, &"jump_start", Color(0.74, 0.24, 0.36))
	_add_from_contract(frames, &"jump_rise", Color(0.68, 0.28, 0.42))
	_add_from_contract(frames, &"fall", Color(0.58, 0.24, 0.38))
	_add_from_contract(frames, &"land", Color(0.72, 0.3, 0.2))
	_add_from_contract(frames, &"straight", Color(0.92, 0.32, 0.18))
	_add_from_contract(frames, &"body_hook", Color(0.88, 0.26, 0.22))
	_add_from_contract(frames, &"red_knuckle", Color(0.95, 0.12, 0.08))
	_add_from_contract(frames, &"dodge", Color(0.42, 0.52, 0.72))
	_add_from_contract(frames, &"hurt", Color(0.9, 0.9, 0.95))

	return frames


static func create_single_clip(anim_id: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var color := _color_for_clip(anim_id)
	_add_from_contract(frames, anim_id, color)
	return frames


static func _add_from_contract(frames: SpriteFrames, anim_id: StringName, base_color: Color) -> void:
	var spec: Dictionary = CalderAnimationContract.get_clip_specs().get(String(anim_id), {})
	var frame_count: int = int(spec.get("frames", 2))
	var frame_duration: float = float(spec.get("frame_duration", 0.1))
	var loop: bool = bool(spec.get("loop", false))

	if loop:
		_add_loop(frames, anim_id, base_color, frame_count, frame_duration)
	else:
		_add_one_shot(frames, anim_id, base_color, frame_count, frame_duration)


static func _color_for_clip(anim_id: StringName) -> Color:
	match anim_id:
		&"idle":
			return Color(0.76, 0.18, 0.13)
		&"run":
			return Color(0.82, 0.22, 0.16)
		&"jump_start":
			return Color(0.74, 0.24, 0.36)
		&"jump_rise":
			return Color(0.68, 0.28, 0.42)
		&"fall":
			return Color(0.58, 0.24, 0.38)
		&"land":
			return Color(0.72, 0.3, 0.2)
		&"straight":
			return Color(0.92, 0.32, 0.18)
		&"body_hook":
			return Color(0.88, 0.26, 0.22)
		&"red_knuckle":
			return Color(0.95, 0.12, 0.08)
		&"dodge":
			return Color(0.42, 0.52, 0.72)
		&"hurt":
			return Color(0.9, 0.9, 0.95)
		_:
			return Color(0.7, 0.2, 0.15)


static func _add_loop(
	frames: SpriteFrames,
	anim_name: StringName,
	base_color: Color,
	frame_count: int,
	frame_duration: float
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, true)
	frames.set_animation_speed(anim_name, 1.0)

	for index in range(frame_count):
		var shade := base_color.lightened(0.04 * float(index))
		frames.add_frame(anim_name, _make_texture(shade, index), frame_duration)


static func _add_one_shot(
	frames: SpriteFrames,
	anim_name: StringName,
	base_color: Color,
	frame_count: int,
	frame_duration: float
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, false)
	frames.set_animation_speed(anim_name, 1.0)

	for index in range(frame_count):
		var shade := base_color.lightened(0.06 * float(index))
		frames.add_frame(anim_name, _make_texture(shade, index + 10), frame_duration)


static func _make_texture(color: Color, variant: int) -> Texture2D:
	var image := Image.create(FRAME_W, FRAME_H, false, Image.FORMAT_RGBA8)
	image.fill(color)

	var head_color := color.lightened(0.18)
	for y in range(8, 18):
		for x in range(10 + (variant % 3), 22 + (variant % 2)):
			image.set_pixel(x, y, head_color)

	var texture := ImageTexture.create_from_image(image)
	return texture
