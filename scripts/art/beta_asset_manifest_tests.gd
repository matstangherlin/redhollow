extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const Manifest := preload("res://scripts/art/beta_asset_manifest.gd")
const Registry := preload("res://scripts/art/beta_asset_registry.gd")
const Validator := preload("res://scripts/art/beta_asset_validator.gd")
const Report := preload("res://scripts/art/beta_asset_report.gd")


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "beta_asset_manifest_tests")
	suite.allow_warning_contains("BetaAssetRegistry")
	suite.allow_warning_contains("BetaAssetManifest")
	var failures: PackedStringArray = PackedStringArray()

	Registry.clear_cache()
	_test_manifest_loads(failures)
	_test_no_false_approvals(failures)
	_test_statuses_and_fields(failures)
	_test_registry_fallback(failures)
	_test_validator_and_report(failures)

	Registry.clear_cache()
	suite.finish(failures, 5)


func _test_manifest_loads(failures: PackedStringArray) -> void:
	var manifest := Manifest.load_manifest()
	if manifest.is_empty():
		failures.append("beta_asset_manifest.json must load.")
		return
	if String(manifest.get("manifest_id", "")) != "beta_asset_manifest":
		failures.append("manifest_id must be beta_asset_manifest.")
	var assets := Manifest.get_assets(manifest)
	if assets.size() < 50:
		failures.append("Manifest should list Cap. Zero production slots (got %d)." % assets.size())


func _test_no_false_approvals(failures: PackedStringArray) -> void:
	var manifest := Manifest.load_manifest()
	for raw in Manifest.get_assets(manifest):
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var entry := raw as Dictionary
		var status := String(entry.get("status", ""))
		var path := String(entry.get("path", ""))
		if Manifest.is_production_ready(status):
			failures.append(
				"%s must not be %s until real art is reviewed — existence alone is not approval."
				% [String(entry.get("asset_id", "?")), status]
			)
		if ResourceLoader.exists(path) and status == Manifest.STATUS_APPROVED:
			# Defensive: even if someone later adds a file, status must not be auto-set approved in CI
			# without workflow. Current baseline: zero approved entries.
			pass
		if path.to_lower().contains("final") and status == Manifest.STATUS_MISSING:
			# Path naming "final" while missing is discouraged but allowed only for destination slots.
			pass


func _test_statuses_and_fields(failures: PackedStringArray) -> void:
	var required_fields := [
		"asset_id", "category", "path", "source_path", "type", "dimensions", "frame_size",
		"frames", "animations", "pivot", "facing", "palette", "status", "required_for_beta",
		"blocking", "license", "author", "revision", "notes",
	]
	var required_ids := [
		"calder_idle", "calder_red_brand_breaker", "cult_brawler_idle", "vermilite_gunslinger_idle",
		"chain_penitent_idle", "deacon_rusk_idle", "elias_idle",
	]
	var seen: Dictionary = {}
	for raw in Manifest.get_assets(Manifest.load_manifest()):
		if typeof(raw) != TYPE_DICTIONARY:
			failures.append("Asset entry must be Dictionary.")
			continue
		var entry := Manifest.normalize_entry(raw as Dictionary)
		var asset_id := String(entry.get("asset_id", ""))
		seen[asset_id] = true
		for field in required_fields:
			if not entry.has(field):
				failures.append("%s missing field %s." % [asset_id, field])
		var status := String(entry.get("status", ""))
		if not Manifest.is_allowed_status(status):
			failures.append("%s has invalid status %s." % [asset_id, status])
	for need in required_ids:
		if not seen.has(need):
			failures.append("Manifest missing required asset_id %s." % need)


func _test_registry_fallback(failures: PackedStringArray) -> void:
	Registry.clear_cache()
	var fallback := "res://art/characters/calder/README.md"
	var resolved := Registry.resolve_path("calder_idle", fallback)
	if resolved != fallback:
		failures.append("Missing/non-approved calder_idle must resolve to fallback.")
	if Registry.is_usable_as_final("calder_idle"):
		failures.append("calder_idle must not be usable as final while missing/unapproved.")
	# Second call must not spam warnings (one-shot).
	var _again := Registry.resolve_path("calder_idle", fallback)
	var preview := Registry.resolve_preview_path("calder_idle", fallback)
	if preview != fallback:
		failures.append("Preview of missing asset must also use fallback.")


func _test_validator_and_report(failures: PackedStringArray) -> void:
	var validation := Validator.validate()
	if not bool(validation.get("schema_ok", false)):
		var issues: Variant = validation.get("issues", [])
		failures.append("Schema validation failed: %s" % str(issues))
	if bool(validation.get("production_ready", true)):
		failures.append(
			"production_ready must be false while Cap. Zero final art is still missing/blocking."
		)
	var report := Report.build_report()
	if int(report.get("total", 0)) <= 0:
		failures.append("Report total must be > 0.")
	if int(report.get("approved", -1)) != 0:
		failures.append("Baseline approved count must be 0 (no false finals).")
	if int(report.get("integrated", -1)) != 0:
		failures.append("Baseline integrated count must be 0.")
	var text := Report.format_text(report)
	if not text.contains("Beta Asset Manifest Report"):
		failures.append("Formatted report missing title.")
	if not text.contains("Blockers"):
		failures.append("Formatted report must include blockers section.")
