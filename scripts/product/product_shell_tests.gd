extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const TEST_SLOT := "slot_product_shell_test"
const TEST_SAVE_PATH := "user://saves/%s.save.json" % TEST_SLOT
const TEST_BACKUP_PATH := "user://saves/%s.save.bak" % TEST_SLOT
const BETA_MANIFEST := ContentManifest.PATH_BETA_DEMO


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "product_shell_tests")
	suite.allow_error_contains("Parse JSON failed")
	var failures: PackedStringArray = PackedStringArray()

	_cleanup_test_slot()
	ContentRegistry.clear_active()

	_test_settings_data_defaults(failures)
	_test_settings_data_validation(failures)
	_test_settings_merge(failures)
	_test_save_inspect_slot_none(failures)
	_test_save_inspect_slot_valid(failures)
	_test_save_inspect_corrupted(failures)
	_test_save_inspect_backup_recovers(failures)
	_test_save_inspect_incompatible_area(failures)
	_test_save_inspect_incompatible(failures)
	_test_boot_state_consume(failures)
	_test_boot_modes_exclusive(failures)
	_test_debug_hotkeys_api(failures)
	_test_input_prompt_keyboard_fallback(failures)
	_test_pause_action_exists(failures)

	_cleanup_test_slot()
	ContentRegistry.clear_active()
	suite.finish(failures, 14)


func _cleanup_test_slot() -> void:
	for path in [
		TEST_SAVE_PATH,
		TEST_BACKUP_PATH,
		"user://saves/%s.save.tmp" % TEST_SLOT,
		"user://saves/%s.save.archive.json" % TEST_SLOT,
	]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)


func _test_settings_data_defaults(failures: PackedStringArray) -> void:
	var defaults := SettingsData.create_default()
	if int(defaults.get("settings_version", 0)) != SettingsData.CURRENT_SETTINGS_VERSION:
		failures.append("Settings defaults missing version.")
	if not defaults.has("video") or not defaults.has("audio") or not defaults.has("accessibility"):
		failures.append("Settings defaults missing sections.")


func _test_settings_data_validation(failures: PackedStringArray) -> void:
	var valid := SettingsData.validate(SettingsData.create_default())
	if not valid.get("valid", false):
		failures.append("Default settings should validate.")


func _test_settings_merge(failures: PackedStringArray) -> void:
	var partial := {"video": {"ui_scale": 1.25}, "settings_version": 1}
	var merged := SettingsData.merge_with_defaults(partial)
	if float(merged.get("video", {}).get("ui_scale", 0.0)) != 1.25:
		failures.append("Settings merge should preserve partial video fields.")


func _test_save_inspect_slot_none(failures: PackedStringArray) -> void:
	_cleanup_test_slot()
	var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
	if String(inspection.get("status", "")) != "none":
		failures.append("Missing save slot should report status none.")


func _write_test_save(payload: Dictionary, path: String = TEST_SAVE_PATH) -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()


func _test_save_inspect_slot_valid(failures: PackedStringArray) -> void:
	_cleanup_test_slot()
	var temp := SaveData.create_default("res://scenes/areas/vertical_slice_street_art.tscn")
	temp["content_manifest_id"] = "beta_demo"
	temp["checkpoint_id"] = "test_checkpoint"
	_write_test_save(temp)
	var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
	if String(inspection.get("status", "")) != "valid":
		failures.append("Valid temp save should inspect as valid.")
	_cleanup_test_slot()


func _test_save_inspect_corrupted(failures: PackedStringArray) -> void:
	_cleanup_test_slot()
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
	if String(inspection.get("status", "")) != "corrupted":
		failures.append("Corrupted save should inspect as corrupted.")
	_cleanup_test_slot()


func _test_save_inspect_backup_recovers(failures: PackedStringArray) -> void:
	_cleanup_test_slot()
	var good := SaveData.create_default("res://scenes/areas/vertical_slice_street_art.tscn")
	good["content_manifest_id"] = "beta_demo"
	good["checkpoint_id"] = "from_backup"
	_write_test_save(good, TEST_BACKUP_PATH)
	DirAccess.make_dir_recursive_absolute("user://saves")
	var corrupt := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	corrupt.store_string("{broken")
	corrupt.close()

	var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
	if String(inspection.get("status", "")) != "valid":
		failures.append("Valid backup should make inspect_slot report valid.")
	elif String(inspection.get("source", "")) != "backup":
		failures.append("inspect_slot should report source=backup when primary is corrupt.")
	_cleanup_test_slot()


func _test_save_inspect_incompatible_area(failures: PackedStringArray) -> void:
	_cleanup_test_slot()
	var temp := SaveData.create_default("res://scenes/areas/does_not_exist_area.tscn")
	temp["content_manifest_id"] = "beta_demo"
	_write_test_save(temp)
	var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
	if String(inspection.get("status", "")) != "incompatible":
		failures.append("Unknown area scene should inspect as incompatible.")
	_cleanup_test_slot()


func _test_save_inspect_incompatible(failures: PackedStringArray) -> void:
	_cleanup_test_slot()
	if SaveData.CURRENT_SAVE_VERSION <= 1:
		# Force incompatible via wrong manifest id against beta when migrate is false.
		var temp := SaveData.create_default("res://scenes/areas/vertical_slice_street_art.tscn")
		temp["content_manifest_id"] = "full_game"
		_write_test_save(temp)
		var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
		if String(inspection.get("status", "")) != "incompatible":
			failures.append("full_game save should be incompatible with beta_demo inspect.")
		_cleanup_test_slot()
		return

	var outdated := SaveData.create_default("res://scenes/areas/vertical_slice_street_art.tscn")
	outdated["save_version"] = SaveData.CURRENT_SAVE_VERSION - 1
	_write_test_save(outdated)
	var inspection := SaveManager.inspect_slot(TEST_SLOT, BETA_MANIFEST)
	if String(inspection.get("status", "")) != "incompatible":
		failures.append("Outdated save version should inspect as incompatible.")
	_cleanup_test_slot()


func _test_boot_state_consume(failures: PackedStringArray) -> void:
	if GameBootState == null:
		failures.append("GameBootState autoload missing.")
		return
	GameBootState.set_new_game()
	if GameBootState.consume_boot_mode() != GameBootState.BootMode.NEW_GAME:
		failures.append("Boot state should consume NEW_GAME once.")
	if GameBootState.consume_boot_mode() != GameBootState.BootMode.NONE:
		failures.append("Boot state should be NONE after consume.")


func _test_boot_modes_exclusive(failures: PackedStringArray) -> void:
	if GameBootState == null:
		failures.append("GameBootState autoload missing.")
		return
	GameBootState.set_continue_game()
	if GameBootState.boot_mode != GameBootState.BootMode.CONTINUE:
		failures.append("Boot state should hold CONTINUE until consumed.")
	GameBootState.set_new_game()
	if GameBootState.consume_boot_mode() != GameBootState.BootMode.NEW_GAME:
		failures.append("set_new_game should replace CONTINUE intent.")


func _test_debug_hotkeys_api(failures: PackedStringArray) -> void:
	# API must exist; release builds disable input handling via this gate.
	var enabled: bool = SaveManager.are_debug_save_hotkeys_enabled()
	if typeof(enabled) != TYPE_BOOL:
		failures.append("are_debug_save_hotkeys_enabled must return bool.")
	if OS.is_debug_build() and not enabled:
		failures.append("Debug builds should enable F8/F9 hotkeys.")
	if not OS.is_debug_build() and enabled:
		failures.append("Release builds should disable F8/F9 hotkeys.")


func _test_input_prompt_keyboard_fallback(failures: PackedStringArray) -> void:
	if InputDeviceManager == null:
		failures.append("InputDeviceManager autoload missing.")
		return
	var prompt := InputDeviceManager.get_action_prompt(&"interact")
	if prompt.is_empty():
		failures.append("Input prompt for interact should not be empty.")


func _test_pause_action_exists(failures: PackedStringArray) -> void:
	if not InputMap.has_action("pause"):
		failures.append("Input map must define pause action.")
