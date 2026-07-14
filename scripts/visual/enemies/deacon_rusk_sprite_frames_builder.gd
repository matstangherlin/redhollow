extends RefCounted
class_name DeaconRuskSpriteFramesBuilder


static func build_for_profile(profile: EnemyVisualProfile) -> SpriteFrames:
	if profile == null:
		return null
	if profile.is_pilot_profile() and profile.use_procedural_pilot_frames:
		return DeaconRuskPlaceholderFactory.create_pilot_sprite_frames()
	if not profile.sprite_frames_path.is_empty():
		var loaded: Variant = load(profile.sprite_frames_path)
		if loaded is SpriteFrames:
			return _ensure_clips(loaded as SpriteFrames)
	return _build_from_sheets()


static func _build_from_sheets() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim_id in DeaconRuskAnimationContract.PILOT_ANIMATION_IDS:
		if not _try_sheet(frames, anim_id):
			DeaconRuskAnimationContract.warn_missing_once("missing sheet", "%s — procedural fallback" % anim_id)
			_merge_proc(frames, anim_id)
	if frames.get_animation_names().is_empty():
		return DeaconRuskPlaceholderFactory.create_pilot_sprite_frames()
	return frames


static func _ensure_clips(frames: SpriteFrames) -> SpriteFrames:
	for anim_id in DeaconRuskAnimationContract.PILOT_ANIMATION_IDS:
		if frames.has_animation(anim_id):
			continue
		DeaconRuskAnimationContract.warn_missing_once("missing clip", String(anim_id))
		_merge_proc(frames, anim_id)
	return frames


static func _try_sheet(frames: SpriteFrames, anim_id: StringName) -> bool:
	var path := DeaconRuskAnimationContract.resolve_sheet_path(anim_id)
	if path.is_empty():
		return false
	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return false
	var fs := DeaconRuskAnimationContract.APPROVED_FRAME_SIZE
	if image.get_height() != fs.y or image.get_width() % fs.x != 0:
		return false
	var spec: Dictionary = DeaconRuskAnimationContract.get_clip_specs().get(String(anim_id), {})
	var tex := ImageTexture.create_from_image(image)
	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, bool(spec.get("loop", false)))
	frames.set_animation_speed(anim_id, 1.0)
	var count := image.get_width() / fs.x
	var dur: float = float(spec.get("frame_duration", 0.1))
	for i in range(count):
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(i * fs.x, 0, fs.x, fs.y)
		frames.add_frame(anim_id, atlas, dur)
	return true


static func _merge_proc(frames: SpriteFrames, anim_id: StringName) -> void:
	var src := DeaconRuskPlaceholderFactory.create_single_clip(anim_id)
	if not src.has_animation(anim_id):
		return
	if frames.has_animation(anim_id):
		frames.remove_animation(anim_id)
	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, src.get_animation_loop(anim_id))
	frames.set_animation_speed(anim_id, 1.0)
	for i in range(src.get_frame_count(anim_id)):
		frames.add_frame(anim_id, src.get_frame_texture(anim_id, i), src.get_frame_duration(anim_id, i))
