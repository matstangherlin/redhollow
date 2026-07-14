extends RefCounted
class_name VermiliteGunslingerPlaceholderFactory

## Procedural Gunslinger silhouettes — coat, gun, Vermilite tip, aim readability.

const W := VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE.x
const H := VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE.y
const COAT := Color(0.34, 0.2, 0.14, 1.0)
const HAT := Color(0.16, 0.1, 0.1, 1.0)
const GUN := Color(0.48, 0.48, 0.52, 1.0)
const TIP := Color(0.95, 0.28, 0.12, 1.0)
const AIM := Color(1.0, 0.75, 0.35, 0.65)


static func create_pilot_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_id in VermiliteGunslingerAnimationContract.PILOT_ANIMATION_IDS:
		_add_clip(frames, anim_id)
	return frames


static func create_single_clip(anim_id: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_clip(frames, anim_id)
	return frames


static func _add_clip(frames: SpriteFrames, anim_id: StringName) -> void:
	var spec: Dictionary = VermiliteGunslingerAnimationContract.get_clip_specs().get(String(anim_id), {})
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
	var gun_x := 18
	var tip_glow := false
	var aim_line := false
	match String(anim_id):
		"aim":
			lean = -2
			gun_x = 20 + int(t * 2.0)
			aim_line = true
			tip_glow = frame >= 2
		"fire":
			lean = -1
			gun_x = 22
			tip_glow = true
		"recoil":
			lean = 2
			gun_x = 14 - int(t * 2.0)
		"reload":
			gun_x = 12
			lean = 1
		"reposition":
			lean = int(sin(t * TAU) * 1.5)
		"hurt":
			lean = 3
		"death":
			lean = 4 + int(t * 6.0)
		_:
			lean = int(sin(t * TAU) * 1.0)
	_fill_rect(img, 8, 18 + lean, 16, 28, COAT)
	_fill_rect(img, 6, 12 + lean, 20, 8, HAT)
	_fill_rect(img, 10, 40 + lean, 5, 12, COAT.darkened(0.15))
	_fill_rect(img, 17, 40 + lean, 5, 12, COAT.darkened(0.1))
	_fill_rect(img, gun_x, 26 + lean, 12, 3, GUN)
	_fill_rect(img, gun_x + 10, 25 + lean, 4, 4, TIP if tip_glow else GUN.lightened(0.2))
	if aim_line:
		for x in range(gun_x + 14, mini(W - 1, gun_x + 28)):
			img.set_pixel(x, 27 + lean, AIM)
			img.set_pixel(x, 28 + lean, Color(AIM.r, AIM.g, AIM.b, 0.35))
	if String(anim_id) == "fire" and frame == 0:
		_fill_rect(img, gun_x + 12, 24 + lean, 6, 6, Color(1.0, 0.85, 0.4, 0.9))
	return ImageTexture.create_from_image(img)


static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(maxi(y, 0), mini(y + h, H)):
		for px in range(maxi(x, 0), mini(x + w, W)):
			img.set_pixel(px, py, color)
