extends RefCounted
class_name BetaAssetManifest

## Schema + load helpers for data/art/beta_asset_manifest.json

const MANIFEST_PATH := "res://data/art/beta_asset_manifest.json"

const STATUS_MISSING := "missing"
const STATUS_CONCEPT := "concept"
const STATUS_DRAFT := "draft"
const STATUS_REVIEW := "review"
const STATUS_APPROVED := "approved"
const STATUS_INTEGRATED := "integrated"
const STATUS_REJECTED := "rejected"
const STATUS_DEPRECATED := "deprecated"

const ALLOWED_STATUSES: PackedStringArray = [
	STATUS_MISSING,
	STATUS_CONCEPT,
	STATUS_DRAFT,
	STATUS_REVIEW,
	STATUS_APPROVED,
	STATUS_INTEGRATED,
	STATUS_REJECTED,
	STATUS_DEPRECATED,
]

const PRODUCTION_STATUSES: PackedStringArray = [
	STATUS_APPROVED,
	STATUS_INTEGRATED,
]


static func load_manifest(path: String = MANIFEST_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("BetaAssetManifest missing file: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("BetaAssetManifest invalid JSON root: %s" % path)
		return {}
	return (parsed as Dictionary).duplicate(true)


static func is_allowed_status(status: String) -> bool:
	return ALLOWED_STATUSES.has(status)


static func is_production_ready(status: String) -> bool:
	## File existence alone is never enough — only explicit approval statuses.
	return PRODUCTION_STATUSES.has(status)


static func get_assets(manifest: Dictionary) -> Array:
	var raw: Variant = manifest.get("assets", [])
	if typeof(raw) != TYPE_ARRAY:
		return []
	return raw as Array


static func normalize_entry(entry: Dictionary) -> Dictionary:
	var out := entry.duplicate(true)
	if not out.has("asset_id"):
		out["asset_id"] = ""
	if not out.has("category"):
		out["category"] = ""
	if not out.has("path"):
		out["path"] = ""
	if not out.has("source_path"):
		out["source_path"] = ""
	if not out.has("type"):
		out["type"] = "png"
	if not out.has("status"):
		out["status"] = STATUS_MISSING
	if not out.has("required_for_beta"):
		out["required_for_beta"] = false
	if not out.has("blocking"):
		out["blocking"] = false
	if not out.has("license"):
		out["license"] = "TBD-original"
	if not out.has("author"):
		out["author"] = ""
	if not out.has("revision"):
		out["revision"] = 0
	if not out.has("checksum"):
		out["checksum"] = ""
	if not out.has("notes"):
		out["notes"] = ""
	if not out.has("frames"):
		out["frames"] = 0
	if not out.has("animations"):
		out["animations"] = []
	if not out.has("facing"):
		out["facing"] = "right"
	if not out.has("palette"):
		out["palette"] = ""
	return out
