extends Node
class_name SaveManager

# Lives under Game instead of autoload because the prototype uses a single persistent
# game scene. A scene-tree SaveManager is enough while area swaps and menu flows do
# not recreate the coordinator. Promote to autoload only when saves must survive
# outside game.tscn or when multiple roots need the same slot API.

signal save_created(slot_id: String)
signal save_written(slot_id: String)
signal save_loaded(slot_id: String)
signal save_deleted(slot_id: String)
signal save_failed(slot_id: String, reason: String)
signal save_validation_warning(message: String)

const MANAGER_GROUP := "save_manager"
const PLAYER_GROUP := "player"
const PROGRESSION_GROUP := "progression_component"
const REGISTRY_GROUP := "barrier_registry"
const CHECKPOINT_GROUP := "checkpoints"

const DEFAULT_SLOT_ID := "slot_01"
const SAVE_DIR := "user://saves"
const DEFAULT_SCENE_PATH := "res://scenes/demo/vertical_slice_greybox.tscn"

@export var slot_id: String = DEFAULT_SLOT_ID
@export var auto_load_on_ready: bool = true

var _game_root: Node = null
var _arena: Node = null
var _player: Node = null
var _progression: ProgressionComponent = null
var _barrier_registry: BarrierRegistry = null
var _current_save: Dictionary = SaveData.create_default()
var _scene_ready: bool = false
var _pending_load: bool = false
var _transition_manager: AreaTransitionManager = null
var _last_debug_message: String = ""


func _ready() -> void:
	if _has_duplicate_manager():
		push_warning("Duplicate SaveManager detected. Removing duplicate node.")
		queue_free()
		return

	add_to_group(MANAGER_GROUP)
	_ensure_save_directory()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_save"):
		if save_game():
			_set_debug_message("Save written to %s" % get_slot_save_path())
		else:
			_set_debug_message("Save failed.")

	if event.is_action_pressed("debug_load"):
		if load_game():
			_set_debug_message("Save loaded from %s" % get_slot_save_path())
		else:
			_set_debug_message("Load failed. See debug output.")


func bind_game(game_root: Node, arena: Node = null, transition_manager: AreaTransitionManager = null) -> void:
	_game_root = game_root
	_transition_manager = transition_manager
	_arena = arena
	if _arena == null and _transition_manager != null:
		_arena = _transition_manager.get_current_area()
	if _arena == null:
		_arena = game_root.get_node_or_null("%WorldHost")
	_bind_runtime_systems()
	_connect_checkpoints()
	_scene_ready = true

	if auto_load_on_ready:
		if has_save():
			load_game()
		else:
			create_new_save()

	if _pending_load:
		_pending_load = false
		load_game()


func rebind_current_area(area: Node = null) -> void:
	_arena = area
	_connect_checkpoints()


func create_new_save() -> Dictionary:
	_current_save = _capture_game_state()
	save_created.emit(slot_id)
	return _current_save.duplicate(true)


func save_game() -> bool:
	if not _scene_ready:
		push_warning("SaveManager tried to save before the scene was ready.")
		save_failed.emit(slot_id, "scene_not_ready")
		return false

	_current_save = _capture_game_state()
	return _write_save_file(_current_save)


func load_game() -> bool:
	if not _scene_ready:
		_pending_load = true
		return false

	var loaded := _read_save_file(get_slot_save_path())
	if loaded.is_empty():
		loaded = _read_save_file(get_slot_backup_path())

	if loaded.is_empty():
		push_warning("No valid save file found for slot '%s'. Starting fresh game state." % slot_id)
		create_new_save()
		save_failed.emit(slot_id, "missing_or_invalid_save")
		return false

	var validation := validate_save(loaded)
	if not validation.get("valid", false):
		push_warning("Save validation failed: %s" % String(validation.get("reason", "unknown")))
		save_failed.emit(slot_id, String(validation.get("reason", "invalid_save")))
		return false

	if not validation.get("compatible", true):
		var warning := "Save version %s is outdated or incompatible with current version %s." % [
			str(validation.get("save_version", "?")),
			str(SaveData.CURRENT_SAVE_VERSION),
		]
		push_warning(warning)
		save_validation_warning.emit(warning)
		_set_debug_message(warning)

	_current_save = loaded
	_apply_save_state(_current_save)
	save_loaded.emit(slot_id)
	return true


func validate_save(data: Variant) -> Dictionary:
	return SaveData.validate(data)


func delete_save() -> bool:
	var removed_any := false
	for path in [get_slot_save_path(), get_slot_temp_path(), get_slot_backup_path()]:
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(path) == OK:
			removed_any = true

	if removed_any:
		save_deleted.emit(slot_id)
	return removed_any


func has_save() -> bool:
	return FileAccess.file_exists(get_slot_save_path()) or FileAccess.file_exists(get_slot_backup_path())


func create_backup() -> bool:
	if not FileAccess.file_exists(get_slot_save_path()):
		return false

	_ensure_save_directory()
	return DirAccess.copy_absolute(get_slot_save_path(), get_slot_backup_path()) == OK


func get_save_directory() -> String:
	return SAVE_DIR


func get_slot_save_path() -> String:
	return "%s/%s.save.json" % [SAVE_DIR, slot_id]


func get_slot_temp_path() -> String:
	return "%s/%s.save.tmp" % [SAVE_DIR, slot_id]


func get_slot_backup_path() -> String:
	return "%s/%s.save.bak" % [SAVE_DIR, slot_id]


func get_resolved_save_directory() -> String:
	return ProjectSettings.globalize_path(SAVE_DIR)


func get_resolved_slot_save_path() -> String:
	return ProjectSettings.globalize_path(get_slot_save_path())


func get_last_debug_message() -> String:
	return _last_debug_message


func on_checkpoint_activated(
	checkpoint_id: StringName,
	checkpoint_position: Vector2,
	interactor: Node,
	restore_health: bool,
	restore_red_brand: bool
) -> void:
	if checkpoint_id == &"":
		return

	if _progression != null:
		_progression.register_checkpoint_activation(checkpoint_id)

	_apply_checkpoint_to_player(interactor, checkpoint_position, restore_health, restore_red_brand)
	save_game()


func _apply_checkpoint_to_player(
	interactor: Node,
	checkpoint_position: Vector2,
	restore_health: bool,
	restore_red_brand: bool
) -> void:
	var player := interactor if interactor != null and interactor.is_in_group(PLAYER_GROUP) else _player
	if player == null:
		return

	if player.has_method("apply_checkpoint"):
		player.call(
			"apply_checkpoint",
			checkpoint_position,
			restore_health,
			restore_red_brand
		)


func _capture_game_state() -> Dictionary:
	var save_data := SaveData.create_default(DEFAULT_SCENE_PATH)

	if _transition_manager != null and _transition_manager.get_current_area() != null:
		save_data["current_scene"] = _transition_manager.get_current_area_scene_path()
	elif _arena is AreaRoot:
		save_data["current_scene"] = (_arena as AreaRoot).get_area_scene_path()
	else:
		save_data["current_scene"] = DEFAULT_SCENE_PATH

	if _progression != null:
		var progression_state := _progression.export_save_state()
		save_data["checkpoint_id"] = progression_state.get("active_checkpoint_id", "")
		save_data["unlocked_abilities"] = progression_state.get("unlocked_abilities", [])
		save_data["narrative_flags"] = progression_state.get("narrative_flags", {})
		save_data["activated_checkpoints"] = progression_state.get("activated_checkpoints", [])
		save_data["settings"] = progression_state.get("settings", {})

	if _barrier_registry != null:
		save_data["destroyed_barriers"] = _barrier_registry.export_destroyed_state()

	if _player != null:
		var player_state := _capture_player_state(_player)
		if not String(save_data.get("checkpoint_id", "")).is_empty():
			save_data["checkpoint_position"] = player_state.get("spawn_position", save_data["checkpoint_position"])
		else:
			save_data["checkpoint_position"] = {
				"x": float(_player.global_position.x),
				"y": float(_player.global_position.y),
			}
		save_data["player_max_health"] = player_state.get("max_health", save_data["player_max_health"])
		save_data["player_current_health"] = player_state.get("current_health", save_data["player_current_health"])
		save_data["red_brand_energy"] = player_state.get("red_brand_energy", save_data["red_brand_energy"])

	return save_data


func _capture_player_state(player: Node) -> Dictionary:
	var state := {
		"spawn_position": {"x": 0.0, "y": 0.0},
		"max_health": 12.0,
		"current_health": 12.0,
		"red_brand_energy": 0.0,
	}

	if player.has_method("get_spawn_position"):
		var spawn_position: Vector2 = player.call("get_spawn_position")
		state["spawn_position"] = {"x": spawn_position.x, "y": spawn_position.y}
	elif player is Node2D:
		var node_2d := player as Node2D
		state["spawn_position"] = {"x": node_2d.global_position.x, "y": node_2d.global_position.y}

	var health := player.get_node_or_null("Components/HealthComponent")
	if health != null:
		state["max_health"] = float(health.get("max_health"))
		state["current_health"] = float(health.get("current_health"))

	var red_brand := player.get_node_or_null("Components/RedBrandComponent")
	if red_brand != null:
		state["red_brand_energy"] = float(red_brand.get("current_energy"))

	return state


func _apply_save_state(save_data: Dictionary) -> void:
	_begin_new_gameplay_session()

	var loading_token: GameplayLockToken = _acquire_loading_lock()
	if _progression != null:
		_progression.import_save_state({
			"active_checkpoint_id": StringName(String(save_data.get("checkpoint_id", ""))),
			"unlocked_abilities": save_data.get("unlocked_abilities", []),
			"narrative_flags": save_data.get("narrative_flags", {}),
			"activated_checkpoints": save_data.get("activated_checkpoints", []),
			"settings": save_data.get("settings", {}),
			"can_break_red_barriers": _progression.can_break_red_barriers,
		})

	if _barrier_registry != null:
		_barrier_registry.import_destroyed_state(save_data.get("destroyed_barriers", {}))

	var area_scene_path := String(save_data.get("current_scene", ""))
	var area_restored := false
	if area_scene_path.begins_with("res://scenes/areas/") and _transition_manager != null:
		if _is_saved_area_restorable(area_scene_path):
			var position_data := save_data.get("checkpoint_position", {}) as Dictionary
			var restored_position := Vector2(
				float(position_data.get("x", 0.0)),
				float(position_data.get("y", 0.0))
			)
			_transition_manager.restore_area_from_save(area_scene_path, restored_position)
			rebind_current_area(_transition_manager.get_current_area())
			area_restored = true
		else:
			var warning := "Saved area '%s' is incompatible with the current session. Keeping the active area." % area_scene_path
			push_warning(warning)
			save_validation_warning.emit(warning)
			_set_debug_message(warning)

	if _player != null and _player.has_method("apply_save_state"):
		var player_save := save_data
		if not area_restored:
			player_save = save_data.duplicate(true)
			player_save.erase("checkpoint_position")
		_player.call("apply_save_state", player_save)

	_release_loading_lock(loading_token)
	call_deferred("_sync_checkpoint_visuals_from_save")


func _sync_checkpoint_visuals_from_save() -> void:
	if _progression == null:
		return

	var activated: Array = _progression.activated_checkpoints
	for node in get_tree().get_nodes_in_group(CHECKPOINT_GROUP):
		if not node.has_method("restore_active_state"):
			continue
		var checkpoint_key := String(node.get("checkpoint_id"))
		node.call("restore_active_state", activated.has(checkpoint_key))


func _write_save_file(save_data: Dictionary) -> bool:
	_ensure_save_directory()

	var json_text := JSON.stringify(save_data, "\t")
	var temp_path := get_slot_temp_path()
	var final_path := get_slot_save_path()
	var backup_path := get_slot_backup_path()

	var temp_file := FileAccess.open(temp_path, FileAccess.WRITE)
	if temp_file == null:
		push_warning("Failed to open temp save file: %s" % temp_path)
		save_failed.emit(slot_id, "temp_open_failed")
		return false

	temp_file.store_string(json_text)
	temp_file.close()

	if FileAccess.file_exists(final_path):
		if not create_backup():
			push_warning("Failed to create save backup before writing slot '%s'." % slot_id)

	if FileAccess.file_exists(final_path):
		var remove_error := DirAccess.remove_absolute(final_path)
		if remove_error != OK:
			push_warning("Failed to replace existing save file: %s" % final_path)
			save_failed.emit(slot_id, "replace_failed")
			return false

	var rename_error := DirAccess.rename_absolute(temp_path, final_path)
	if rename_error != OK:
		push_warning("Failed to finalize save file rename for slot '%s'." % slot_id)
		save_failed.emit(slot_id, "rename_failed")
		return false

	save_written.emit(slot_id)
	return true


func _read_save_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Failed to open save file: %s" % path)
		return {}

	var raw_text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(raw_text)
	if parsed == null:
		push_warning("Invalid JSON in save file: %s" % path)
		return {}

	var validation := validate_save(parsed)
	if not validation.get("valid", false):
		push_warning("Save file failed validation (%s): %s" % [path, validation.get("reason", "")])
		return {}

	return (parsed as Dictionary).duplicate(true)


func _bind_runtime_systems() -> void:
	if not is_inside_tree():
		return

	_player = _find_player()
	_progression = _find_progression_component()
	_barrier_registry = _find_barrier_registry()


func _connect_checkpoints() -> void:
	if not is_inside_tree():
		return

	if _arena == null:
		return

	for node in _arena.get_tree().get_nodes_in_group(CHECKPOINT_GROUP):
		if node.has_signal("checkpoint_activated") and not node.is_connected(
			"checkpoint_activated",
			Callable(self, "_on_checkpoint_activated")
		):
			node.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))


func _on_checkpoint_activated(
	checkpoint_id: StringName,
	checkpoint_position: Vector2,
	interactor: Node,
	restore_health: bool,
	restore_red_brand: bool
) -> void:
	on_checkpoint_activated(checkpoint_id, checkpoint_position, interactor, restore_health, restore_red_brand)


func _find_player() -> Node:
	if _arena != null:
		var arena_player := _arena.get_node_or_null("Player")
		if arena_player != null:
			return arena_player

	return get_tree().get_first_node_in_group(PLAYER_GROUP)


func _find_progression_component() -> ProgressionComponent:
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			return node
	return null


func _find_barrier_registry() -> BarrierRegistry:
	for node in get_tree().get_nodes_in_group(REGISTRY_GROUP):
		if node is BarrierRegistry:
			return node
	return null


func _ensure_save_directory() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _has_duplicate_manager() -> bool:
	for node in get_tree().get_nodes_in_group(MANAGER_GROUP):
		if node != self:
			return true
	return false


func _is_saved_area_restorable(area_scene_path: String) -> bool:
	if area_scene_path.is_empty() or not ResourceLoader.exists(area_scene_path):
		return false

	var main_scene := String(ProjectSettings.get_setting("application/run/main_scene", ""))
	if main_scene.ends_with("vertical_slice_greybox.tscn"):
		return area_scene_path.find("vertical_slice_") != -1

	return true


func _set_debug_message(message: String) -> void:
	_last_debug_message = message
	print("[SaveManager] %s" % message)


func _begin_new_gameplay_session() -> void:
	var manager := _find_gameplay_lock_manager()
	if manager != null:
		manager.begin_new_session()


func _acquire_loading_lock() -> GameplayLockToken:
	var manager := _find_gameplay_lock_manager()
	if manager == null:
		return GameplayLockToken.new()
	return manager.acquire_lock(GameplayLockManager.LockReason.LOADING, self)


func _release_loading_lock(token: GameplayLockToken) -> void:
	var manager := _find_gameplay_lock_manager()
	if manager == null or token == null or not token.valid:
		return
	manager.release_lock(token)


func _find_gameplay_lock_manager() -> GameplayLockManager:
	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("gameplay_lock_manager"):
		if node is GameplayLockManager:
			return node as GameplayLockManager
	return null
