extends RefCounted
class_name DeaconRuskPlaceholderFactory

## Procedural Deacon silhouettes — crown, mantle, phase-2 Vermilite read.

const W := DeaconRuskAnimationContract.APPROVED_FRAME_SIZE.x
const H := DeaconRuskAnimationContract.APPROVED_FRAME_SIZE.y
const BODY := Color(0.34, 0.1, 0.12, 1.0)
const MANTLE := Color(0.18, 0.08, 0.1, 1.0)
const CROWN := Color(0.82, 0.12, 0.1, 1.0)
const ARMOR := Color(0.45, 0.12, 0.14, 1.0)
const VERM := Color(0.95, 0.28, 0.12, 1.0)


static func create_pilot_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_id in DeaconRuskAnimationContract.PILOT_ANIMATION_IDS:
		_add_clip(frames, anim_id)
	return frames


static func create_single_clip(anim_id: StringName) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_clip(frames, anim_id)
	return frames


static func _add_clip(frames: SpriteFrames, anim_id: StringName) -> void:
	var spec: Dictionary = DeaconRuskAnimationContract.get_clip_specs().get(String(anim_id), {})
	var count: int = int(spec.get("frames", 2))
	var dur: float = float(spec.get("frame_duration", 0.1))
	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, bool(spec.get("loop", false)))
	frames.set_animation_speed(anim_id, 1.0)
	for i in range(count):
		frames.add_frame(anim_id, _tex(anim_id, i, count), dur)


static func _tex(anim_id: StringName, frame: int, total: float) -> Texture2D:
	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var t := float(frame) / maxf(total - 1.0, 1.0)
	var lean := 0
	var arm := 0
	var phase2 := false
	var telegraph := false
	match String(anim_id):
		"reposition":
			lean = int(sin(t * TAU) * 2.0)
		"punch_combo":
			arm = 8 + int(t * 10.0)
			telegraph = frame <= 1
		"charge":
			lean = -3
			arm = 12
			telegraph = frame == 0
		"counterable_attack":
			arm = 14
			telegraph = frame <= 2
		"ground_attack":
			lean = 2
			arm = int(t * 8.0)
			telegraph = frame <= 1
		"armor_attack":
			phase2 = true
			arm = 16
			telegraph = frame == 0
		"phase_transition":
			phase2 = frame >= 3
			lean = int(t * 3.0)
		"hurt":
			lean = 3
		"stagger":
			lean = 4
		"death":
			lean = 5 + int(t * 10.0)
		_:
			lean = int(sin(t * TAU) * 1.0)
	var mantle_col := ARMOR if phase2 else MANTLE
	_fill(img, 8, 22 + lean, 26, 34, mantle_col)
	_fill(img, 11, 26 + lean, 20, 30, BODY if not phase2 else BODY.lightened(0.08))
	_fill(img, 12, 12 + lean, 18, 14, Color(0.72, 0.62, 0.58, 1.0))
	_fill(img, 10, 8 + lean, 22, 8, CROWN)
	_fill(img, 14, 52 + lean, 6, 18, BODY.darkened(0.1))
	_fill(img, 22, 52 + lean, 6, 18, BODY.darkened(0.05))
	_fill(img, 28 + arm, 30 + lean, 10, 6, BODY.lightened(0.1))
	if telegraph:
		for x in range(30, mini(W - 1, 30 + 10)):
			img.set_pixel(x, 32 + lean, Color(1.0, 0.75, 0.35, 0.55))
	if phase2:
		_fill(img, 18, 28 + lean, 6, 8, VERM)
	return ImageTexture.create_from_image(img)


static func _fill(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(maxi(y, 0), mini(y + h, H)):
		for px in range(maxi(x, 0), mini(x + w, W)):
			img.set_pixel(px, py, color)
