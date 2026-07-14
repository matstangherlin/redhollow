extends RefCounted
class_name BetaAssetReport

## Human-readable production report for the beta asset manifesto.

const MANIFEST := preload("res://scripts/art/beta_asset_manifest.gd")
const Validator := preload("res://scripts/art/beta_asset_validator.gd")


static func build_report(manifest: Dictionary = {}) -> Dictionary:
	if manifest.is_empty():
		manifest = MANIFEST.load_manifest()
	var validation := Validator.validate(manifest)
	var by_status: Dictionary = validation.get("by_status", {})
	var by_category: Dictionary = _count_by_category(manifest)
	var category_pct: Dictionary = _percentages(by_category)
	var blockers: PackedStringArray = validation.get("blocking", PackedStringArray()) as PackedStringArray

	return {
		"generated_at": Time.get_datetime_string_from_system(true),
		"manifest_id": String(manifest.get("manifest_id", "")),
		"manifest_version": int(manifest.get("manifest_version", 0)),
		"game_version": String(manifest.get("game_version", "")),
		"total": int(validation.get("total", 0)),
		"missing": int(by_status.get(MANIFEST.STATUS_MISSING, 0)),
		"concept": int(by_status.get(MANIFEST.STATUS_CONCEPT, 0)),
		"draft": int(by_status.get(MANIFEST.STATUS_DRAFT, 0)),
		"review": int(by_status.get(MANIFEST.STATUS_REVIEW, 0)),
		"approved": int(by_status.get(MANIFEST.STATUS_APPROVED, 0)),
		"integrated": int(by_status.get(MANIFEST.STATUS_INTEGRATED, 0)),
		"rejected": int(by_status.get(MANIFEST.STATUS_REJECTED, 0)),
		"deprecated": int(by_status.get(MANIFEST.STATUS_DEPRECATED, 0)),
		"blockers": blockers,
		"blocker_count": blockers.size(),
		"by_category": by_category,
		"category_percent": category_pct,
		"orphans": validation.get("orphans", PackedStringArray()),
		"unregistered_files": validation.get("unregistered_files", PackedStringArray()),
		"invalid_paths": validation.get("invalid_paths", PackedStringArray()),
		"issues": validation.get("issues", PackedStringArray()),
		"validation_ok": bool(validation.get("valid", false)),
		"schema_ok": bool(validation.get("schema_ok", false)),
		"production_ready": bool(validation.get("production_ready", false)),
	}


static func format_text(report: Dictionary = {}) -> String:
	if report.is_empty():
		report = build_report()
	var lines: PackedStringArray = PackedStringArray()
	lines.append("=== Red Hollow — Beta Asset Manifest Report ===")
	lines.append("Generated: %s" % String(report.get("generated_at", "")))
	lines.append(
		"Manifest: %s v%s | Game: %s"
		% [
			String(report.get("manifest_id", "")),
			str(report.get("manifest_version", 0)),
			String(report.get("game_version", "")),
		]
	)
	lines.append("")
	lines.append("--- Totals ---")
	lines.append("Total entries: %d" % int(report.get("total", 0)))
	lines.append("  missing:     %d" % int(report.get("missing", 0)))
	lines.append("  concept:     %d" % int(report.get("concept", 0)))
	lines.append("  draft:       %d" % int(report.get("draft", 0)))
	lines.append("  review:      %d" % int(report.get("review", 0)))
	lines.append("  approved:    %d" % int(report.get("approved", 0)))
	lines.append("  integrated:  %d" % int(report.get("integrated", 0)))
	lines.append("  rejected:    %d" % int(report.get("rejected", 0)))
	lines.append("  deprecated:  %d" % int(report.get("deprecated", 0)))
	lines.append("")
	lines.append("--- Blockers (%d) ---" % int(report.get("blocker_count", 0)))
	var blockers: Variant = report.get("blockers", [])
	if typeof(blockers) == TYPE_ARRAY or typeof(blockers) == TYPE_PACKED_STRING_ARRAY:
		if blockers.is_empty():
			lines.append("  (none)")
		else:
			for b in blockers:
				lines.append("  - %s" % String(b))
	lines.append("")
	lines.append("--- Percentage by category ---")
	var cat_pct: Dictionary = report.get("category_percent", {})
	var cats: Array = cat_pct.keys()
	cats.sort()
	for cat in cats:
		var info: Dictionary = cat_pct[cat]
		lines.append(
			"  %s: %d entries (%.1f%% of manifesto)"
			% [String(cat), int(info.get("count", 0)), float(info.get("percent", 0.0))]
		)
	lines.append("")
	lines.append("--- Orphan / unregistered files ---")
	_append_list(lines, report.get("orphans", []), "  (none under scan_roots)")
	lines.append("")
	lines.append("--- Invalid paths ---")
	_append_list(lines, report.get("invalid_paths", []), "  (none)")
	lines.append("")
	lines.append("--- Validation issues ---")
	_append_list(lines, report.get("issues", []), "  (none)")
	lines.append("")
	lines.append("--- Readiness ---")
	lines.append("  schema_ok:         %s" % str(bool(report.get("schema_ok", false))))
	lines.append("  production_ready:  %s" % str(bool(report.get("production_ready", false))))
	lines.append("")
	lines.append(
		"Policy: existence != approved. Missing → fallback + once warning. Non-approved → preview only."
	)
	return "\n".join(lines)


static func write_to_user(path: String = "user://beta_asset_report.txt") -> String:
	var text := format_text()
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("BetaAssetReport: cannot write %s" % path)
		return ""
	file.store_string(text)
	file.close()
	return path


static func _count_by_category(manifest: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for raw in MANIFEST.get_assets(manifest):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var cat := String((raw as Dictionary).get("category", "unknown"))
		counts[cat] = int(counts.get(cat, 0)) + 1
	return counts


static func _percentages(by_category: Dictionary) -> Dictionary:
	var total := 0
	for k in by_category.keys():
		total += int(by_category[k])
	var out: Dictionary = {}
	for k in by_category.keys():
		var count := int(by_category[k])
		var pct := 0.0 if total <= 0 else (100.0 * float(count) / float(total))
		out[k] = {"count": count, "percent": pct}
	return out


static func _append_list(lines: PackedStringArray, items: Variant, empty_line: String) -> void:
	if typeof(items) != TYPE_ARRAY and typeof(items) != TYPE_PACKED_STRING_ARRAY:
		lines.append(empty_line)
		return
	if items.is_empty():
		lines.append(empty_line)
		return
	for item in items:
		lines.append("  - %s" % String(item))
