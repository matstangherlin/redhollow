extends SceneTree

const SaveManagerScript := preload("res://scripts/save/save_manager.gd")
const SaveDataScript := preload("res://scripts/save/save_data.gd")
const TEST_SLOT_ID := "slot_test"

var _manager: Node


func _initialize() -> void:
	var failures: PackedStringArray = PackedStringArray()
	_cleanup_test_files()
	_manager = _create_manager()
	_test_missing_file(failures)
	_test_valid_save_roundtrip(failures)
	_test_corrupted_save(failures)
	_test_backup_recovery(failures)
	_test_close_and_reopen(failures)
	_cleanup_test_files()
	_manager.queue_free()

	if failures.is_empty():
		print("Save tests passed.")
	else:
		for failure in failures:
			push_error(failure)
		print("Save tests failed: %s" % failures.size())

	quit()


func _create_manager() -> Node:
	var manager: Node = SaveManagerScript.new()
	manager.slot_id = TEST_SLOT_ID
	manager.auto_load_on_ready = false
	root.add_child(manager)
	manager.bind_game(root, null)
	return manager


func _write_test_save(save_data: Dictionary) -> bool:
	_manager._current_save = save_data
	return _manager._write_save_file(save_data)


func _test_missing_file(failures: PackedStringArray) -> void:
	_cleanup_test_files()
	if _manager.has_save():
		failures.append("Missing-file test expected no save before write.")

	var validation: Dictionary = _manager.validate_save({})
	if validation.get("valid", false):
		failures.append("Empty dictionary should fail validation.")

	_manager.create_new_save()


func _test_valid_save_roundtrip(failures: PackedStringArray) -> void:
	_cleanup_test_files()
	var save_data: Dictionary = SaveDataScript.create_default()
	save_data["checkpoint_id"] = "test_arena_entry"
	save_data["checkpoint_position"] = {"x": 240.0, "y": 848.0}
	save_data["player_current_health"] = 8.0
	save_data["red_brand_energy"] = 42.0
	save_data["destroyed_barriers"] = {"test_arena_cult_gate_01": true}
	save_data["narrative_flags"] = {"met_elias": true}
	save_data["activated_checkpoints"] = ["test_arena_entry"]

	var validation: Dictionary = _manager.validate_save(save_data)
	if not validation.get("valid", false):
		failures.append("Valid save payload failed validation.")

	if not _write_test_save(save_data):
		failures.append("Valid save failed to write.")

	if not _manager.has_save():
		failures.append("Valid save file was not created.")

	var loaded: Dictionary = _manager._read_save_file(_manager.get_slot_save_path())
	if loaded.is_empty():
		failures.append("Valid save could not be read back.")
	elif String(loaded.get("checkpoint_id", "")) != "test_arena_entry":
		failures.append("Valid save roundtrip lost checkpoint_id.")


func _test_corrupted_save(failures: PackedStringArray) -> void:
	_cleanup_test_files()
	var corrupt_path: String = _manager.get_slot_save_path()
	DirAccess.make_dir_recursive_absolute(SaveManagerScript.SAVE_DIR)
	var corrupt_file := FileAccess.open(corrupt_path, FileAccess.WRITE)
	corrupt_file.store_string("{ this is not valid json")
	corrupt_file.close()

	var loaded: Dictionary = _manager._read_save_file(corrupt_path)
	if not loaded.is_empty():
		failures.append("Corrupted JSON should not load.")

	if _manager.load_game():
		failures.append("Corrupted save should not report successful load.")


func _test_backup_recovery(failures: PackedStringArray) -> void:
	_cleanup_test_files()
	var save_data: Dictionary = SaveDataScript.create_default()
	save_data["checkpoint_id"] = "backup_checkpoint"
	if not _write_test_save(save_data):
		failures.append("Backup test failed to write primary save.")

	if not _manager.create_backup():
		failures.append("Backup creation failed.")

	var corrupt_file := FileAccess.open(_manager.get_slot_save_path(), FileAccess.WRITE)
	corrupt_file.store_string("not-json")
	corrupt_file.close()

	if not _manager.load_game():
		failures.append("Backup recovery load failed.")

	if String(_manager._current_save.get("checkpoint_id", "")) != "backup_checkpoint":
		failures.append("Backup recovery did not restore checkpoint_id.")


func _test_close_and_reopen(failures: PackedStringArray) -> void:
	_cleanup_test_files()
	var save_data: Dictionary = SaveDataScript.create_default()
	save_data["player_current_health"] = 5.0
	save_data["red_brand_energy"] = 17.0
	if not _write_test_save(save_data):
		failures.append("Close/reopen test failed to write save.")

	if not _manager.load_game():
		failures.append("Close/reopen test failed to load save.")

	if not is_equal_approx(float(_manager._current_save.get("player_current_health", -1.0)), 5.0):
		failures.append("Close/reopen test lost player health.")

	if not is_equal_approx(float(_manager._current_save.get("red_brand_energy", -1.0)), 17.0):
		failures.append("Close/reopen test lost red brand energy.")


func _cleanup_test_files() -> void:
	var base := "%s/%s" % [SaveManagerScript.SAVE_DIR, TEST_SLOT_ID]
	for suffix in [".save.json", ".save.tmp", ".save.bak"]:
		var path: String = base + suffix
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
