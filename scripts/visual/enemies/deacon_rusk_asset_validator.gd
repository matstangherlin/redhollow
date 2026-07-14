extends RefCounted
class_name DeaconRuskAssetValidator


static func validate_pilot_set() -> Dictionary:
	return validate_animation_ids(DeaconRuskAnimationContract.PILOT_ANIMATION_IDS)


static func validate_animation_ids(animation_ids: PackedStringArray) -> Dictionary:
	var results: Array[Dictionary] = []
	var found: PackedStringArray = PackedStringArray()
	var missing: PackedStringArray = PackedStringArray()
	var passed: PackedStringArray = PackedStringArray()
	var failed: PackedStringArray = PackedStringArray()
	var warnings: PackedStringArray = PackedStringArray()
	for anim_id in animation_ids:
		var entry := validate_sheet(StringName(anim_id))
		results.append(entry)
		if bool(entry.get("found", false)):
			found.append(String(anim_id))
			if bool(entry.get("passed", false)):
				passed.append(String(anim_id))
			else:
				failed.append(String(anim_id))
		else:
			missing.append(String(anim_id))
		for warning in entry.get("warnings", PackedStringArray()):
			var text := String(warning)
			if not warnings.has(text):
				warnings.append(text)
	return {
		"approved_frame_size": DeaconRuskAnimationContract.APPROVED_FRAME_SIZE,
		"gameplay_collision_size": DeaconRuskAnimationContract.GAMEPLAY_COLLISION_SIZE,
		"visual_contract": DeaconRuskAnimationContract.get_visual_contract_summary(),
		"results": results,
		"found": found,
		"missing": missing,
		"passed": passed,
		"failed": failed,
		"warnings": warnings,
	}


static func validate_sheet(anim_id: StringName) -> Dictionary:
	var spec: Dictionary = DeaconRuskAnimationContract.get_clip_specs().get(String(anim_id), {})
	var expected_frames: int = int(spec.get("frames", 1))
	var sheet_path := DeaconRuskAnimationContract.resolve_sheet_path(anim_id)
	var entry := {
		"animation": String(anim_id),
		"expected_file": String(spec.get("file", "")),
		"sheet_path": DeaconRuskAnimationContract.get_sheet_path(anim_id),
		"found": false,
		"passed": false,
		"errors": PackedStringArray(),
		"warnings": PackedStringArray(),
		"checks": {},
	}
	if sheet_path.is_empty():
		entry["warnings"].append("Sheet missing for %s — procedural placeholder will be used." % anim_id)
		return entry
	entry["found"] = true
	var image := Image.new()
	if image.load(sheet_path) != OK:
		entry["errors"].append("Failed to decode image: %s" % sheet_path)
		return entry
	var frame_size := DeaconRuskAnimationContract.APPROVED_FRAME_SIZE
	var checks: Dictionary = {
		"width_divisible": image.get_width() % frame_size.x == 0,
		"height_exact": image.get_height() == frame_size.y,
		"frame_count": (image.get_width() / frame_size.x) == expected_frames if frame_size.x > 0 else false,
	}
	entry["checks"] = checks
	entry["passed"] = bool(checks["width_divisible"]) and bool(checks["height_exact"]) and bool(checks["frame_count"])
	if not entry["passed"]:
		entry["errors"].append(
			"Sheet dimensions mismatch for %s (expected %dx%d, %d frames)." % [
				anim_id, frame_size.x, frame_size.y, expected_frames
			]
		)
	return entry
