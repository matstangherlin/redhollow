extends RefCounted
class_name CultBrawlerSpriteFramesBuilder

## Builds SpriteFrames for Cult Brawler with per-clip fallback to procedural placeholders.


static func build_for_profile(profile: EnemyVisualProfile) -> SpriteFrames:
	if profile == null:
		return null

	if profile.is_pilot_profile() and profile.use_procedural_pilot_frames:
		return CultBrawlerPlaceholderFactory.create_pilot_sprite_frames()

	if not profile.sprite_frames_path.is_empty():
		var loaded: Variant = load(profile.sprite_frames_path)
		if loaded is SpriteFrames:
			return _ensure_pilot_clips(loaded as SpriteFrames, profile)

	return _build_from_individual_sheets(profile)


static func _build_from_individual_sheets(profile: EnemyVisualProfile) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	for anim_id in CultBrawlerAnimationContract.PILOT_ANIMATION_IDS:
		_add_clip_with_fallback(frames, anim_id)

	if frames.get_animation_names().is_empty():
		CultBrawlerAnimationContract.warn_missing_once(
			"no clips resolved",
			"falling back to full procedural pilot set"
		)
		return CultBrawlerPlaceholderFactory.create_pilot_sprite_frames()

	return frames


static func _ensure_pilot_clips(frames: SpriteFrames, profile: EnemyVisualProfile) -> SpriteFrames:
	for anim_id in CultBrawlerAnimationContract.PILOT_ANIMATION_IDS:
		if frames.has_animation(anim_id):
			continue
		CultBrawlerAnimationContract.warn_missing_once(
			"missing clip in SpriteFrames",
			"%s — using procedural fallback" % anim_id
		)
		_merge_procedural_clip(frames, anim_id)
	return frames


static func _add_clip_with_fallback(frames: SpriteFrames, anim_id: StringName) -> void:
	if _try_add_sheet_clip(frames, anim_id):
		return
	CultBrawlerAnimationContract.warn_missing_once(
		"missing sheet",
		"%s — using procedural fallback" % anim_id
	)
	_merge_procedural_clip(frames, anim_id)


static func _try_add_sheet_clip(frames: SpriteFrames, anim_id: StringName) -> bool:
	var sheet_path := CultBrawlerAnimationContract.resolve_sheet_path(anim_id)
	if sheet_path.is_empty():
		return false

	var image := Image.new()
	if image.load(sheet_path) != OK:
		return false

	var frame_size := CultBrawlerAnimationContract.APPROVED_FRAME_SIZE
	if image.get_height() != frame_size.y or image.get_width() % frame_size.x != 0:
		return false

	var spec: Dictionary = CultBrawlerAnimationContract.get_clip_specs().get(String(anim_id), {})
	var frame_count := image.get_width() / frame_size.x
	var frame_duration: float = float(spec.get("frame_duration", 0.1))
	var loop: bool = bool(spec.get("loop", false))

	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, loop)
	frames.set_animation_speed(anim_id, 1.0)

	for index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = ImageTexture.create_from_image(image)
		atlas.region = Rect2(index * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim_id, atlas, frame_duration)

	return true


static func _merge_procedural_clip(frames: SpriteFrames, anim_id: StringName) -> void:
	var single := CultBrawlerPlaceholderFactory.create_single_clip(anim_id)
	if single == null or not single.has_animation(anim_id):
		return

	if frames.has_animation(anim_id):
		frames.remove_animation(anim_id)

	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, single.get_animation_loop(anim_id))
	frames.set_animation_speed(anim_id, single.get_animation_speed(anim_id))

	var count := single.get_frame_count(anim_id)
	for index in range(count):
		frames.add_frame(
			anim_id,
			single.get_frame_texture(anim_id, index),
			single.get_frame_duration(anim_id, index)
		)
