extends RefCounted
class_name CalderAssetValidator

## Validates Calder spritesheets against the approved 40×72 contract.
## Missing files are warnings only — gameplay falls back to procedural placeholders.

const FEET_TOLERANCE_PX := 2
const SIDE_MARGIN_TOLERANCE_PX := 3
const FACING_BIAS_THRESHOLD := 0.08


static func validate_pilot_set() -> Dictionary:
	return validate_animation_ids(CalderAnimationContract.PILOT_ANIMATION_IDS)


static func validate_all_tracked() -> Dictionary:
	var ids: PackedStringArray = PackedStringArray()
	for anim_id in CalderAnimationContract.PILOT_ANIMATION_IDS:
		ids.append(anim_id)
	for anim_id in CalderAnimationContract.OPTIONAL_ANIMATION_IDS:
		if not ids.has(anim_id):
			ids.append(anim_id)
	return validate_animation_ids(ids)


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
		"approved_frame_size": CalderAnimationContract.APPROVED_FRAME_SIZE,
		"approved_frame_size_doc": CalderAnimationContract.APPROVED_FRAME_SIZE_DOC,
		"gameplay_collision_size": CalderAnimationContract.GAMEPLAY_COLLISION_SIZE,
		"results": results,
		"found": found,
		"missing": missing,
		"passed": passed,
		"failed": failed,
		"warnings": warnings,
	}


static func validate_sheet(anim_id: StringName) -> Dictionary:
	var spec: Dictionary = CalderAnimationContract.get_clip_specs().get(String(anim_id), {})
	var expected_frames: int = int(spec.get("frames", 1))
	var expected_file := String(spec.get("file", ""))
	var sheet_path := CalderAnimationContract.resolve_sheet_path(anim_id)

	var entry := {
		"animation": String(anim_id),
		"expected_file": expected_file,
		"sheet_path": sheet_path,
		"found": false,
		"passed": false,
		"errors": PackedStringArray(),
		"warnings": PackedStringArray(),
		"checks": {},
	}

	if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
		entry["warnings"].append(
			"Sheet missing for %s — procedural placeholder will be used." % anim_id
		)
		return entry

	entry["found"] = true
	var image := _load_image(sheet_path)
	if image == null:
		entry["errors"].append("Failed to decode image: %s" % sheet_path)
		return entry

	var frame_size := CalderAnimationContract.APPROVED_FRAME_SIZE
	var checks: Dictionary = {}

	checks["width_divisible"] = image.get_width() % frame_size.x == 0
	checks["height_exact"] = image.get_height() == frame_size.y
	var computed_frames := 0
	if frame_size.x > 0:
		computed_frames = image.get_width() / frame_size.x
	checks["frame_count"] = computed_frames == expected_frames
	checks["has_transparency"] = _image_has_transparency(image)
	checks["facing_default_right"] = _check_facing_right(image, frame_size)
	checks["feet_on_bottom"] = _check_feet_alignment(image, frame_size)
	checks["no_accidental_side_margin"] = _check_horizontal_margins(image, frame_size)
	checks["import_settings"] = _validate_import(sheet_path, entry["warnings"])

	entry["checks"] = checks
	entry["computed_frames"] = computed_frames
	entry["expected_frames"] = expected_frames
	entry["image_size"] = Vector2i(image.get_width(), image.get_height())

	if not checks["width_divisible"]:
		entry["errors"].append(
			"Width %d is not divisible by frame width %d." % [image.get_width(), frame_size.x]
		)
	if not checks["height_exact"]:
		entry["errors"].append(
			"Height %d must equal approved frame height %d." % [image.get_height(), frame_size.y]
		)
	if not checks["frame_count"]:
		entry["errors"].append(
			"Expected %d frames, sheet fits %d." % [expected_frames, computed_frames]
		)
	if not checks["has_transparency"]:
		entry["warnings"].append("No transparent pixels detected — verify RGBA export.")
	if not checks["facing_default_right"]:
		entry["warnings"].append("Frame 0 opaque mass leans left — default facing should be right.")
	if not checks["feet_on_bottom"]:
		entry["warnings"].append("Opaque bounds do not touch frame bottom — check pivot/feet alignment.")
	if not checks["no_accidental_side_margin"]:
		entry["warnings"].append("Large empty side margins detected — verify canvas crop.")

	if expected_file != sheet_path.get_file():
		entry["warnings"].append("Resolved path differs from canonical filename.")

	entry["passed"] = entry["errors"].is_empty() and bool(checks.get("import_settings", true))
	return entry


static func format_report(report: Dictionary) -> String:
	var lines: PackedStringArray = PackedStringArray()
	var frame_size: Vector2i = report.get("approved_frame_size", Vector2i.ZERO)
	lines.append(
		"Calder asset validation — approved frame %dx%d (%s)"
		% [frame_size.x, frame_size.y, String(report.get("approved_frame_size_doc", ""))]
	)
	lines.append(
		"Gameplay collision unchanged: %s"
		% str(report.get("gameplay_collision_size", Vector2i.ZERO))
	)
	lines.append("")
	lines.append("Found (%d): %s" % [report.get("found", []).size(), ", ".join(report.get("found", []))])
	lines.append("Missing (%d): %s" % [report.get("missing", []).size(), ", ".join(report.get("missing", []))])
	lines.append("Passed (%d): %s" % [report.get("passed", []).size(), ", ".join(report.get("passed", []))])
	lines.append("Failed (%d): %s" % [report.get("failed", []).size(), ", ".join(report.get("failed", []))])

	var warnings: PackedStringArray = report.get("warnings", PackedStringArray())
	if not warnings.is_empty():
		lines.append("")
		lines.append("Warnings:")
		for warning in warnings:
			lines.append("  - %s" % warning)

	for result: Dictionary in report.get("results", []):
		if not bool(result.get("found", false)):
			continue
		lines.append("")
		lines.append("[%s] %s" % ["OK" if result.get("passed", false) else "FAIL", result.get("animation", "")])
		for err in result.get("errors", PackedStringArray()):
			lines.append("  ERROR: %s" % err)
		var checks: Dictionary = result.get("checks", {})
		for check_name in checks.keys():
			lines.append("  %s: %s" % [check_name, "yes" if checks[check_name] else "no"])

	return "\n".join(lines)


static func _load_image(sheet_path: String) -> Image:
	var image := Image.new()
	var global_path := ProjectSettings.globalize_path(sheet_path)
	var err := image.load(global_path)
	if err != OK:
		return null
	return image


static func _image_has_transparency(image: Image) -> bool:
	if image.is_empty():
		return false
	if not image.has_alpha():
		return false
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a < 0.98:
				return true
	return false


static func _opaque_bounds(image: Image, region: Rect2i) -> Rect2i:
	var min_x := region.position.x + region.size.x
	var min_y := region.position.y + region.size.y
	var max_x := region.position.x
	var max_y := region.position.y
	var found := false

	for y in range(region.position.y, region.position.y + region.size.y):
		for x in range(region.position.x, region.position.x + region.size.x):
			if image.get_pixel(x, y).a <= 0.05:
				continue
			found = true
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if not found:
		return Rect2i()
	return Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))


static func _check_facing_right(image: Image, frame_size: Vector2i) -> bool:
	var bounds := _opaque_bounds(image, Rect2i(0, 0, frame_size.x, frame_size.y))
	if bounds.size == Vector2i.ZERO:
		return true

	var center_x := bounds.position.x + bounds.size.x * 0.5
	var frame_center := frame_size.x * 0.5
	var bias := (center_x - frame_center) / float(frame_size.x)
	return bias >= -FACING_BIAS_THRESHOLD


static func _check_feet_alignment(image: Image, frame_size: Vector2i) -> bool:
	var bounds := _opaque_bounds(image, Rect2i(0, 0, frame_size.x, frame_size.y))
	if bounds.size == Vector2i.ZERO:
		return true
	var bottom := bounds.position.y + bounds.size.y
	return bottom >= frame_size.y - FEET_TOLERANCE_PX


static func _check_horizontal_margins(image: Image, frame_size: Vector2i) -> bool:
	var bounds := _opaque_bounds(image, Rect2i(0, 0, frame_size.x, frame_size.y))
	if bounds.size == Vector2i.ZERO:
		return true
	return (
		bounds.position.x <= SIDE_MARGIN_TOLERANCE_PX
		and bounds.position.x + bounds.size.x >= frame_size.x - SIDE_MARGIN_TOLERANCE_PX
	)


static func _validate_import(sheet_path: String, warnings: PackedStringArray) -> bool:
	var import_result: Dictionary = CalderSpriteImporter.validate_import_params(sheet_path)
	for warning in import_result.get("warnings", PackedStringArray()):
		if not warnings.has(String(warning)):
			warnings.append(String(warning))
	for issue in import_result.get("issues", PackedStringArray()):
		if not warnings.has(String(issue)):
			warnings.append("Import: %s" % issue)
	return bool(import_result.get("passed", true))
