extends RefCounted
class_name ChainPenitentPlaceholderFactory

## Procedural Chain Penitent — hood, body, chain reach telegraph.

const W := ChainPenitentAnimationContract.APPROVED_FRAME_SIZE.x
const H := ChainPenitentAnimationContract.APPROVED_FRAME_SIZE.y
const ROBE := Color(0.32, 0.28, 0.36, 1.0)
const HOOD := Color(0.18, 0.16, 0.22, 1.0)
const CHAIN := Color(0.72, 0.68, 0.62, 1.0)
const REACH := Color(0.95, 0.82, 0.55, 0.55)


static func create_pilot_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_id in ChainPenitentAnimationContract.PILOT_ANIMATION_IDS:
		_add_clip(frames, anim_id)
	return frames


static func create_single_clip(anim_id: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_clip(frames, anim_id)
	return frames


static func _add_clip(frames: SpriteFrames, anim_id: StringName) -> void:
	var spec: Dictionary = ChainPenitentAnimationContract.get_clip_specs().get(String(anim_id), {})
	var count: int = int(spec.get("frames", 2))
	var dur: float = float(spec.get("frame_duration", 0.1))
	var loop: bool = bool(spec.get("loop", false))
	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, loop)
	frames.set_animation_speed(anim_id, 1.0)
	for i in range(count):
		frames.add_frame(anim_id, _tex(anim_id, i, count), dur)


static func _tex(anim_id: StringName, frame: int, total: float) -> Texture2D:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var t := float(frame) / maxf(total - 1.0, 1.0)
	var lean := 0
	var chain_len := 10
	var show_reach := false
	match String(anim_id):
		"walk":
			lean = int(sin(t * TAU) * 2.0)
		"chain_startup":
			lean = -2
			chain_len = 12 + int(t * 10.0)
			show_reach = frame >= 2
		"chain_active":
			lean = -1
			chain_len = 28
			show_reach = true
		"pull":
			lean = 2
			chain_len = 22 - int(t * 6.0)
		"chain_recovery":
			chain_len = 18 - int(t * 8.0)
		"stagger":
			lean = 3
		"hurt":
			lean = 2
		"death":
			lean = 5 + int(t * 8.0)
		_:
			lean = int(sin(t * TAU) * 1.0)
	_fill_rect(img, 10, 16 + lean, 18, 32, ROBE)
	_fill_rect(img, 11, 8 + lean, 16, 12, HOOD)
	_fill_rect(img, 12, 42 + lean, 5, 14, ROBE.darkened(0.12))
	_fill_rect(img, 20, 42 + lean, 5, 14, ROBE.darkened(0.08))
	# Chain links forward (facing art right inside frame; gameplay flips Visual).
	for i in range(chain_len / 3):
		var cx := 24 + i * 3
		if cx >= W - 1:
			break
		_fill_rect(img, cx, 28 + lean + (i % 2), 3, 3, CHAIN)
	if show_reach:
		for x in range(24, mini(W - 1, 24 + chain_len + 4)):
			img.set_pixel(x, 26 + lean, REACH)
			img.set_pixel(x, 32 + lean, Color(REACH.r, REACH.g, REACH.b, 0.28))
	return ImageTexture.create_from_image(img)


static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(maxi(y, 0), mini(y + h, H)):
		for px in range(maxi(x, 0), mini(x + w, W)):
			img.set_pixel(px, py, color)
