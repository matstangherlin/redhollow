extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")
const TEST_SLOT := "slot_01"
const TEST_SAVE_PATH := "user://saves/%s.save.json" % TEST_SLOT


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "product_shell_tests")
	suite.allow_error_contains("Parse JSON failed")
	var failures: PackedStringArray = PackedStringArray()

	_test_settings_data_defaults(failures)
	_test_settings_data_validation(failures)
	_test_settings_merge(failures)
	_test_save_inspect_slot_none(failures)
	_test_save_inspect_slot_valid(failures)
	_test_save_inspect_corrupted(failures)
	_test_save_inspect_incompatible(failures)
	_test_boot_state_consume(failures)
	_test_input_prompt_keyboard_fallback(failures)
	_test_pause_action_exists(failures)

	suite.finish(failures, 10)


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
	var inspection := SaveManager.inspect_slot()
	if String(inspection.get("status", "")) != "none":
		failures.append("Missing save slot should report status none.")



func _write_test_save(payload: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()


func _clear_test_save() -> void:
	if FileAccess.file_exists(TEST_SAVE_PATH):
		DirAccess.remove_absolute(TEST_SAVE_PATH)


func _test_save_inspect_slot_valid(failures: PackedStringArray) -> void:
	var temp := SaveData.create_default()
	temp["checkpoint_id"] = "test_checkpoint"
	_write_test_save(temp)
	var inspection := SaveManager.inspect_slot(TEST_SLOT)
	if String(inspection.get("status", "")) != "valid":
		failures.append("Valid temp save should inspect as valid.")
	_clear_test_save()


func _test_save_inspect_corrupted(failures: PackedStringArray) -> void:
	DirAccess.make_dir_recursive_absolute("user://saves")
	var file := FileAccess.open(TEST_SAVE_PATH, FileAccess.WRITE)
	file.store_string("{not json")
	file.close()
	var inspection := SaveManager.inspect_slot(TEST_SLOT)
	if String(inspection.get("status", "")) != "corrupted":
		failures.append("Corrupted save should inspect as corrupted.")
	_clear_test_save()


func _test_save_inspect_incompatible(failures: PackedStringArray) -> void:
	if SaveData.CURRENT_SAVE_VERSION <= 1:
		return
	var temp := SaveData.create_default()
	temp["save_version"] = SaveData.CURRENT_SAVE_VERSION - 1
	_write_test_save(temp)
	var inspection := SaveManager.inspect_slot(TEST_SLOT)
	if String(inspection.get("status", "")) != "incompatible":
		failures.append("Outdated save version should inspect as incompatible.")
	_clear_test_save()


func _test_boot_state_consume(failures: PackedStringArray) -> void:
	if GameBootState == null:
		failures.append("GameBootState autoload missing.")
		return
	GameBootState.set_new_game()
	if GameBootState.consume_boot_mode() != GameBootState.BootMode.NEW_GAME:
		failures.append("Boot state should consume NEW_GAME once.")


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
