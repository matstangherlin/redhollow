extends RefCounted
class_name VermiliteGunslingerAssetValidator

## Validates Gunslinger spritesheets against the 32×54 beta contract.

static func validate_pilot_set() -> Dictionary:
	return validate_animation_ids(VermiliteGunslingerAnimationContract.PILOT_ANIMATION_IDS)


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
		"approved_frame_size": VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE,
		"approved_frame_size_doc": VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE_DOC,
		"gameplay_collision_size": VermiliteGunslingerAnimationContract.GAMEPLAY_COLLISION_SIZE,
		"visual_contract": VermiliteGunslingerAnimationContract.get_visual_contract_summary(),
		"results": results,
		"found": found,
		"missing": missing,
		"passed": passed,
		"failed": failed,
		"warnings": warnings,
	}


static func validate_sheet(anim_id: StringName) -> Dictionary:
	var spec: Dictionary = VermiliteGunslingerAnimationContract.get_clip_specs().get(String(anim_id), {})
	var expected_frames: int = int(spec.get("frames", 1))
	var expected_file := String(spec.get("file", ""))
	var sheet_path := VermiliteGunslingerAnimationContract.resolve_sheet_path(anim_id)
	var entry := {
		"animation": String(anim_id),
		"expected_file": expected_file,
		"sheet_path": VermiliteGunslingerAnimationContract.get_sheet_path(anim_id),
		"found": false,
		"passed": false,
		"errors": PackedStringArray(),
		"warnings": PackedStringArray(),
		"checks": {},
	}
	if sheet_path.is_empty():
		entry["warnings"].append(
			"Sheet missing for %s — procedural placeholder will be used." % anim_id
		)
		return entry

	entry["found"] = true
	var image := Image.new()
	if image.load(sheet_path) != OK:
		entry["errors"].append("Failed to decode image: %s" % sheet_path)
		return entry

	var frame_size := VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE
	var checks: Dictionary = {}
	checks["width_divisible"] = image.get_width() % frame_size.x == 0
	checks["height_exact"] = image.get_height() == frame_size.y
	var computed_frames := 0
	if frame_size.x > 0:
		computed_frames = image.get_width() / frame_size.x
	checks["frame_count"] = computed_frames == expected_frames
	entry["checks"] = checks
	entry["passed"] = bool(checks.get("width_divisible", false)) \
		and bool(checks.get("height_exact", false)) \
		and bool(checks.get("frame_count", false))
	if not entry["passed"]:
		entry["errors"].append(
			"Sheet dimensions mismatch for %s (expected %dx%d, %d frames)." % [
				anim_id, frame_size.x, frame_size.y, expected_frames
			]
		)
	return entry


static func format_report(report: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var frame_size: Vector2i = report.get("approved_frame_size", Vector2i.ZERO)
	lines.append(
		"Gunslinger asset validation — approved frame %dx%d"
		% [frame_size.x, frame_size.y]
	)
	lines.append("Found (%d): %s" % [report.get("found", []).size(), ", ".join(report.get("found", []))])
	lines.append("Missing (%d): %s" % [report.get("missing", []).size(), ", ".join(report.get("missing", []))])
	lines.append("Passed (%d): %s" % [report.get("passed", []).size(), ", ".join(report.get("passed", []))])
	lines.append("Failed (%d): %s" % [report.get("failed", []).size(), ", ".join(report.get("failed", []))])
	return "\n".join(lines)
