extends RefCounted
class_name CalderSpriteImporter

## Recommended Godot import settings for Calder pixel-art sheets.
## Apply in editor via Import dock or `ensure_import_sidecar()`.

const TEXTURE_FILTER_NEAREST := 0
const COMPRESS_LOSSLESS := 0

const RECOMMENDED_IMPORT_PARAMS := {
	"compress/mode": COMPRESS_LOSSLESS,
	"mipmaps/generate": false,
	"process/fix_alpha_border": true,
	"process/hdr_as_srgb": false,
	"process/size_limit": 0,
	"detect_3d/compress_to": 0,
	"texture_filter": TEXTURE_FILTER_NEAREST,
}


static func get_recommended_import_params() -> Dictionary:
	return RECOMMENDED_IMPORT_PARAMS.duplicate(true)


static func get_import_sidecar_path(texture_path: String) -> String:
	return "%s.import" % texture_path


static func import_sidecar_exists(texture_path: String) -> bool:
	return FileAccess.file_exists(get_import_sidecar_path(texture_path))


static func read_import_params(texture_path: String) -> Dictionary:
	var sidecar_path := get_import_sidecar_path(texture_path)
	if not FileAccess.file_exists(sidecar_path):
		return {}

	var config := ConfigFile.new()
	var err := config.load(sidecar_path)
	if err != OK:
		return {}
	var params := {}
	if config.has_section("params"):
		for key in config.get_section_keys("params"):
			params[key] = config.get_value("params", key)
	return params


static func validate_import_params(texture_path: String) -> Dictionary:
	var result := {
		"checked": false,
		"passed": true,
		"issues": PackedStringArray(),
		"warnings": PackedStringArray(),
	}

	if not import_sidecar_exists(texture_path):
		result["warnings"].append("Import sidecar missing — apply Nearest/Lossless in Godot Import dock.")
		return result

	result["checked"] = true
	var params: Dictionary = read_import_params(texture_path)
	var issues := _compare_import_params(params)
	result["issues"] = issues
	result["passed"] = issues.is_empty()
	return result


static func build_import_sidecar_text(texture_path: String) -> String:
	var params := get_recommended_import_params()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("[remap]")
	lines.append("")
	lines.append("importer=\"texture\"")
	lines.append("type=\"CompressedTexture2D\"")
	lines.append("uid=\"uid://calder_%s\"" % texture_path.md5_text().substr(0, 12))
	lines.append('path="res://.godot/imported/%s-%s.ctex"' % [texture_path.get_file().get_basename(), texture_path.md5_text().substr(0, 16)])
	lines.append("")
	lines.append("[deps]")
	lines.append("")
	lines.append('source_file="%s"' % texture_path)
	lines.append("")
	lines.append("[params]")
	for key in params.keys():
		var value: Variant = params[key]
		if value is bool:
			lines.append("%s=%s" % [key, "true" if value else "false"])
		else:
			lines.append("%s=%s" % [key, str(value)])
	return "\n".join(lines) + "\n"


static func ensure_import_sidecar(texture_path: String, overwrite: bool = false) -> bool:
	var sidecar_path := get_import_sidecar_path(texture_path)
	if FileAccess.file_exists(sidecar_path) and not overwrite:
		return false

	var file := FileAccess.open(sidecar_path, FileAccess.WRITE)
	if file == null:
		push_warning("CalderSpriteImporter: failed to write %s" % sidecar_path)
		return false
	file.store_string(build_import_sidecar_text(texture_path))
	file.close()
	return true


static func _compare_import_params(params: Dictionary) -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray()
	if int(params.get("texture_filter", -1)) != TEXTURE_FILTER_NEAREST:
		issues.append("texture_filter must be Nearest (0)")
	if bool(params.get("mipmaps/generate", true)):
		issues.append("mipmaps/generate must be false")
	var compress_mode := int(params.get("compress/mode", -1))
	if compress_mode != COMPRESS_LOSSLESS and compress_mode != 3:
		issues.append("compress/mode should be Lossless (0) or VRAM Uncompressed (3) for pixel art")
	return issues
