extends RefCounted
class_name BetaAssetValidator

## Validates manifest integrity and filesystem alignment.
## Never auto-promotes status to approved/integrated.

const MANIFEST := preload("res://scripts/art/beta_asset_manifest.gd")
const Registry := preload("res://scripts/art/beta_asset_registry.gd")


static func validate(manifest: Dictionary = {}) -> Dictionary:
	if manifest.is_empty():
		manifest = MANIFEST.load_manifest()

	var issues: PackedStringArray = PackedStringArray()
	var blocking: PackedStringArray = PackedStringArray()
	var by_status: Dictionary = {}
	for status in MANIFEST.ALLOWED_STATUSES:
		by_status[status] = 0

	var seen_ids: Dictionary = {}
	var registered_paths: Dictionary = {}
	var assets := MANIFEST.get_assets(manifest)

	for raw in assets:
		if typeof(raw) != TYPE_DICTIONARY:
			issues.append("Asset entry is not a dictionary.")
			continue
		var entry := MANIFEST.normalize_entry(raw as Dictionary)
		var asset_id := String(entry.get("asset_id", ""))
		var path := String(entry.get("path", ""))
		var status := String(entry.get("status", ""))
		var category := String(entry.get("category", ""))

		if asset_id.is_empty():
			issues.append("Asset missing asset_id.")
			continue
		if seen_ids.has(asset_id):
			issues.append("Duplicate asset_id: %s" % asset_id)
		seen_ids[asset_id] = true

		if category.is_empty():
			issues.append("%s missing category." % asset_id)
		if path.is_empty():
			issues.append("%s missing path." % asset_id)
		elif registered_paths.has(path):
			issues.append("Duplicate path for %s and %s" % [registered_paths[path], asset_id])
		else:
			registered_paths[path] = asset_id

		if not MANIFEST.is_allowed_status(status):
			issues.append("%s has invalid status '%s'." % [asset_id, status])
			status = MANIFEST.STATUS_MISSING
		by_status[status] = int(by_status.get(status, 0)) + 1

		var exists := not path.is_empty() and ResourceLoader.exists(path)
		if MANIFEST.is_production_ready(status) and not exists:
			var msg := "%s marked %s but file missing: %s" % [asset_id, status, path]
			issues.append(msg)
			blocking.append(msg)

		## Existence alone must never imply approval.
		if exists and status == MANIFEST.STATUS_MISSING:
			issues.append(
				"%s file exists but status is still 'missing' — update workflow, do not auto-approve."
				% asset_id
			)

		if bool(entry.get("required_for_beta", false)) and bool(entry.get("blocking", false)):
			if not MANIFEST.is_production_ready(status) or not exists:
				blocking.append(
					"%s blocking beta (status=%s, exists=%s)"
					% [asset_id, status, str(exists)]
				)

	var orphans := _find_orphan_files(manifest, registered_paths)
	var unregistered := orphans.duplicate()

	return {
		"valid": issues.is_empty(),
		"schema_ok": issues.is_empty(),
		"production_ready": blocking.is_empty(),
		"issues": issues,
		"blocking": blocking,
		"by_status": by_status,
		"total": assets.size(),
		"unique_ids": seen_ids.size(),
		"orphans": orphans,
		"unregistered_files": unregistered,
		"invalid_paths": _collect_invalid_paths(assets),
	}


static func _collect_invalid_paths(assets: Array) -> PackedStringArray:
	var invalid: PackedStringArray = PackedStringArray()
	for raw in assets:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		var path := String(entry.get("path", ""))
		if path.is_empty():
			continue
		if not path.begins_with("res://"):
			invalid.append("%s (%s)" % [String(entry.get("asset_id", "?")), path])
	return invalid


static func _find_orphan_files(manifest: Dictionary, registered_paths: Dictionary) -> PackedStringArray:
	var orphans: PackedStringArray = PackedStringArray()
	var roots: Array = manifest.get("scan_roots", [])
	for root_variant in roots:
		var root_path := String(root_variant)
		_scan_dir_for_orphans(root_path, registered_paths, orphans)
	return orphans


static func _scan_dir_for_orphans(
	res_dir: String,
	registered_paths: Dictionary,
	orphans: PackedStringArray
) -> void:
	if res_dir.is_empty():
		return
	var abs_dir := ProjectSettings.globalize_path(res_dir)
	if not DirAccess.dir_exists_absolute(abs_dir):
		return
	_scan_abs_recursive(abs_dir, res_dir, registered_paths, orphans)


static func _scan_abs_recursive(
	abs_dir: String,
	res_prefix: String,
	registered_paths: Dictionary,
	orphans: PackedStringArray
) -> void:
	var dir := DirAccess.open(abs_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry_name := dir.get_next()
	while entry_name != "":
		if entry_name.begins_with("."):
			entry_name = dir.get_next()
			continue
		var abs_path := "%s/%s" % [abs_dir.rstrip("/\\"), entry_name]
		if dir.current_is_dir():
			var child_prefix := "%s/%s/" % [res_prefix.rstrip("/"), entry_name]
			_scan_abs_recursive(abs_path, child_prefix, registered_paths, orphans)
		else:
			var lower := entry_name.to_lower()
			if lower.ends_with(".png") or lower.ends_with(".webp") or lower.ends_with(".tres"):
				var res_path := "%s/%s" % [res_prefix.rstrip("/"), entry_name]
				if not registered_paths.has(res_path):
					orphans.append(res_path)
		entry_name = dir.get_next()
	dir.list_dir_end()
