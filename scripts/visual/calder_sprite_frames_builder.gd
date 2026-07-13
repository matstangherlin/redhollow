extends RefCounted
class_name CalderSpriteFramesBuilder

## Builds SpriteFrames for Calder with per-clip fallback to procedural placeholders.


static func build_for_profile(profile: PlayerVisualProfile) -> SpriteFrames:
	if profile == null:
		return null

	if profile.is_pilot_profile() and profile.use_procedural_pilot_frames:
		return PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()

	if not profile.sprite_frames_path.is_empty():
		var loaded: Variant = load(profile.sprite_frames_path)
		if loaded is SpriteFrames:
			return _ensure_pilot_clips(loaded as SpriteFrames, profile)

	return _build_from_individual_sheets(profile)


static func _build_from_individual_sheets(profile: PlayerVisualProfile) -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")

	var required: PackedStringArray = _collect_required_clips(profile)
	for anim_id in required:
		_add_clip_with_fallback(frames, StringName(anim_id))

	if frames.get_animation_names().is_empty():
		CalderAnimationContract.warn_missing_once(
			"no clips resolved",
			"falling back to full procedural pilot set"
		)
		return PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()

	return frames


static func _ensure_pilot_clips(frames: SpriteFrames, profile: PlayerVisualProfile) -> SpriteFrames:
	var required: PackedStringArray = _collect_required_clips(profile)
	for anim_id in required:
		if frames.has_animation(StringName(anim_id)):
			continue
		CalderAnimationContract.warn_missing_once(
			"missing clip in SpriteFrames",
			"%s — using procedural fallback" % anim_id
		)
		_merge_procedural_clip(frames, StringName(anim_id))
	return frames


static func _collect_required_clips(profile: PlayerVisualProfile) -> PackedStringArray:
	var ids: PackedStringArray = PackedStringArray()
	for anim_id in CalderAnimationContract.PILOT_ANIMATION_IDS:
		ids.append(anim_id)
	for mapped in profile.attack_animation_map.values():
		var clip := String(mapped)
		if not clip.is_empty() and not ids.has(clip):
			ids.append(clip)
	for mapped in profile.state_animation_map.values():
		var clip := String(mapped)
		if not clip.is_empty() and not ids.has(clip):
			ids.append(clip)
	return ids


static func _add_clip_with_fallback(frames: SpriteFrames, anim_id: StringName) -> void:
	if _try_add_sheet_clip(frames, anim_id):
		return
	CalderAnimationContract.warn_missing_once(
		"missing sheet",
		"%s — using procedural fallback" % anim_id
	)
	_merge_procedural_clip(frames, anim_id)


static func _try_add_sheet_clip(frames: SpriteFrames, anim_id: StringName) -> bool:
	var sheet_path := CalderAnimationContract.resolve_sheet_path(anim_id)
	if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
		return false

	var texture: Texture2D = load(sheet_path) as Texture2D
	if texture == null:
		return false

	var spec: Dictionary = CalderAnimationContract.get_clip_specs().get(String(anim_id), {})
	var frame_count: int = int(spec.get("frames", 1))
	var frame_duration: float = float(spec.get("frame_duration", 0.1))
	var loop: bool = bool(spec.get("loop", false))
	var frame_size := CalderAnimationContract.APPROVED_FRAME_SIZE

	frames.add_animation(anim_id)
	frames.set_animation_loop(anim_id, loop)
	frames.set_animation_speed(anim_id, 1.0)

	for index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * frame_size.x, 0, frame_size.x, frame_size.y)
		frames.add_frame(anim_id, atlas, frame_duration)

	return true


static func _merge_procedural_clip(frames: SpriteFrames, anim_id: StringName) -> void:
	var procedural := PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()
	if not procedural.has_animation(anim_id):
		if procedural.has_animation(CalderAnimationContract.DEFAULT_FALLBACK_ANIMATION):
			_copy_animation(
				frames,
				procedural,
				CalderAnimationContract.DEFAULT_FALLBACK_ANIMATION,
				anim_id
			)
		return
	_copy_animation(frames, procedural, anim_id, anim_id)


static func _copy_animation(
	target: SpriteFrames,
	source: SpriteFrames,
	source_id: StringName,
	target_id: StringName
) -> void:
	if target.has_animation(target_id):
		target.remove_animation(target_id)

	target.add_animation(target_id)
	target.set_animation_loop(target_id, source.get_animation_loop(source_id))
	target.set_animation_speed(target_id, source.get_animation_speed(source_id))

	for index in range(source.get_frame_count(source_id)):
		target.add_frame(
			target_id,
			source.get_frame_texture(source_id, index),
			source.get_frame_duration(source_id, index)
		)
