extends RefCounted
class_name BetaAssetRegistry

## Runtime lookup for beta art entries. Does not invent final art.
## Missing / non-approved assets return fallback and emit a one-shot warning.

const MANIFEST := preload("res://scripts/art/beta_asset_manifest.gd")

static var _manifest: Dictionary = {}
static var _by_id: Dictionary = {}
static var _warned: Dictionary = {}
static var _loaded: bool = false


static func ensure_loaded(force_reload: bool = false) -> void:
	if _loaded and not force_reload:
		return
	_manifest = MANIFEST.load_manifest()
	_by_id.clear()
	for raw in MANIFEST.get_assets(_manifest):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := MANIFEST.normalize_entry(raw as Dictionary)
		var asset_id := String(entry.get("asset_id", ""))
		if asset_id.is_empty():
			continue
		_by_id[asset_id] = entry
	_loaded = true


static func clear_cache() -> void:
	_manifest = {}
	_by_id.clear()
	_warned.clear()
	_loaded = false


static func get_manifest() -> Dictionary:
	ensure_loaded()
	return _manifest.duplicate(true)


static func get_entry(asset_id: String) -> Dictionary:
	ensure_loaded()
	if not _by_id.has(asset_id):
		return {}
	return (_by_id[asset_id] as Dictionary).duplicate(true)


static func has_entry(asset_id: String) -> bool:
	ensure_loaded()
	return _by_id.has(asset_id)


static func get_all_entries() -> Array[Dictionary]:
	ensure_loaded()
	var out: Array[Dictionary] = []
	for asset_id in _by_id.keys():
		out.append((_by_id[asset_id] as Dictionary).duplicate(true))
	return out


static func get_entries_by_category(category: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry in get_all_entries():
		if String(entry.get("category", "")) == category:
			out.append(entry)
	return out


static func get_status(asset_id: String) -> String:
	var entry := get_entry(asset_id)
	if entry.is_empty():
		return MANIFEST.STATUS_MISSING
	return String(entry.get("status", MANIFEST.STATUS_MISSING))


static func file_exists_for(asset_id: String) -> bool:
	var entry := get_entry(asset_id)
	if entry.is_empty():
		return false
	var path := String(entry.get("path", ""))
	return not path.is_empty() and ResourceLoader.exists(path)


static func is_usable_as_final(asset_id: String) -> bool:
	## Strict production gate: approved/integrated AND file present.
	var entry := get_entry(asset_id)
	if entry.is_empty():
		return false
	var status := String(entry.get("status", ""))
	if not MANIFEST.is_production_ready(status):
		return false
	return file_exists_for(asset_id)


static func resolve_path(asset_id: String, fallback_path: String = "") -> String:
	## Prefer production path only when approved/integrated + file exists.
	## Otherwise return fallback (may be empty) and warn once.
	ensure_loaded()
	var entry := get_entry(asset_id)
	if entry.is_empty():
		_warn_once(asset_id, "unregistered asset_id — using fallback")
		return fallback_path

	var path := String(entry.get("path", ""))
	var status := String(entry.get("status", MANIFEST.STATUS_MISSING))
	var exists := not path.is_empty() and ResourceLoader.exists(path)

	if MANIFEST.is_production_ready(status) and exists:
		return path

	if exists and not MANIFEST.is_production_ready(status):
		_warn_once(
			asset_id,
			"file present but status='%s' — preview only, not final; production resolve uses fallback"
			% status
		)
		return fallback_path

	_warn_once(
		asset_id,
		"missing or non-final (status=%s, exists=%s) — using fallback"
		% [status, str(exists)]
	)
	return fallback_path


static func resolve_preview_path(asset_id: String, fallback_path: String = "") -> String:
	## Preview may use draft/review files when present; still not "final".
	ensure_loaded()
	var entry := get_entry(asset_id)
	if entry.is_empty():
		_warn_once(asset_id, "unregistered asset_id — preview fallback")
		return fallback_path
	var path := String(entry.get("path", ""))
	var status := String(entry.get("status", MANIFEST.STATUS_MISSING))
	if path.is_empty() or not ResourceLoader.exists(path):
		_warn_once(asset_id, "preview path missing — using fallback")
		return fallback_path
	if status == MANIFEST.STATUS_REJECTED or status == MANIFEST.STATUS_DEPRECATED:
		_warn_once(asset_id, "status=%s — preview blocked, using fallback" % status)
		return fallback_path
	if not MANIFEST.is_production_ready(status):
		_warn_once(asset_id, "previewing non-final status=%s" % status)
	return path


static func _warn_once(asset_id: String, message: String) -> void:
	if _warned.has(asset_id):
		return
	_warned[asset_id] = true
	push_warning("BetaAssetRegistry[%s]: %s" % [asset_id, message])
