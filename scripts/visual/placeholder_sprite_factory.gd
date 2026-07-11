extends RefCounted
class_name PlaceholderSpriteFactory

## Procedural colored rects for pipeline validation — not final art.

const FRAME_W := 32
const FRAME_H := 56


static func create_calder_pilot_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	_add_loop(frames, &"idle", Color(0.76, 0.18, 0.13), 4, 0.12)
	_add_loop(frames, &"run", Color(0.82, 0.22, 0.16), 4, 0.08)
	_add_loop(frames, &"jump", Color(0.68, 0.28, 0.42), 2, 0.1)
	_add_one_shot(frames, &"straight", Color(0.92, 0.32, 0.18), 3, 0.06)

	return frames


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

	# Simple "head" block so frames are distinguishable in debug.
	var head_color := color.lightened(0.18)
	for y in range(8, 18):
		for x in range(10 + (variant % 3), 22 + (variant % 2)):
			image.set_pixel(x, y, head_color)

	var texture := ImageTexture.create_from_image(image)
	return texture
