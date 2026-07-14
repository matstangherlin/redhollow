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
## Product shell owns New Game / Continue. Gameplay must never auto-load.
@export var auto_load_on_ready: bool = false

var _game_root: Node = null
var _arena: Node = null
var _player: CharacterBody2D = null
var _progression: ProgressionComponent = null
var _barrier_registry: BarrierRegistry = null
var _current_save: Dictionary = SaveData.create_default()
var _scene_ready: bool = false
var _pending_load: bool = false
var _transition_manager: AreaTransitionManager = null
var _services: GameServices = null
var _last_debug_message: String = ""
var _last_load_failure_reason: String = ""


func _ready() -> void:
	if _has_duplicate_manager():
		push_warning("Duplicate SaveManager detected. Removing duplicate node.")
		queue_free()
		return

	add_to_group(MANAGER_GROUP)
	_ensure_save_directory()


func _unhandled_input(event: InputEvent) -> void:
	if not are_debug_save_hotkeys_enabled():
		return

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


static func are_debug_save_hotkeys_enabled() -> bool:
	return OS.is_debug_build()


func bind_game(
	game_root: Node,
	arena: Node = null,
	transition_manager: AreaTransitionManager = null,
	services: GameServices = null
) -> void:
	_game_root = game_root
	_transition_manager = transition_manager
	_services = services
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


func create_new_save(persist_to_disk: bool = false) -> Dictionary:
	_current_save = _capture_game_state()
	if persist_to_disk and _scene_ready:
		_write_save_file(_current_save)
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
	_last_load_failure_reason = ""
	if not _scene_ready:
		_pending_load = true
		return false

	var loaded := _read_save_file(get_slot_save_path())
	if loaded.is_empty():
		loaded = _read_save_file(get_slot_backup_path())

	if loaded.is_empty():
		_last_load_failure_reason = "missing_or_invalid_save"
		push_warning("No valid save file found for slot '%s'." % slot_id)
		save_failed.emit(slot_id, _last_load_failure_reason)
		return false

	var validation := validate_save(loaded)
	if not validation.get("valid", false):
		_last_load_failure_reason = String(validation.get("reason", "invalid_save"))
		push_warning("Save validation failed: %s" % _last_load_failure_reason)
		save_failed.emit(slot_id, _last_load_failure_reason)
		return false

	if not validation.get("compatible", true):
		_last_load_failure_reason = "version_incompatible"
		var warning := "Save version %s is outdated or incompatible with current version %s." % [
			str(validation.get("save_version", "?")),
			str(SaveData.CURRENT_SAVE_VERSION),
		]
		push_warning(warning)
		save_validation_warning.emit(warning)
		save_failed.emit(slot_id, _last_load_failure_reason)
		_set_debug_message(warning)
		return false

	var registry := ContentRegistry.get_active()
	if registry != null and not registry.is_save_compatible_with_manifest(loaded):
		_last_load_failure_reason = "manifest_incompatible"
		var manifest_warning := (
			"Save profile/manifest incompatible with active build (%s)."
			% String(registry.get_manifest_id())
		)
		push_warning(manifest_warning)
		save_validation_warning.emit(manifest_warning)
		save_failed.emit(slot_id, _last_load_failure_reason)
		return false

	_current_save = loaded
	_apply_save_state(_current_save)
	save_loaded.emit(slot_id)
	return true


func validate_save(data: Variant) -> Dictionary:
	return SaveData.validate(data)


func get_last_load_failure_reason() -> String:
	return _last_load_failure_reason


func archive_and_clear_slot() -> bool:
	_ensure_save_directory()
	var archived := false
	var archive_path := get_slot_archive_path()
	var source_path := ""
	if FileAccess.file_exists(get_slot_save_path()):
		var primary := _read_save_file(get_slot_save_path())
		if not primary.is_empty():
			source_path = get_slot_save_path()
		elif FileAccess.file_exists(get_slot_backup_path()):
			source_path = get_slot_backup_path()
		else:
			# Keep a copy of corrupt primary for support; do not touch .bak contents.
			source_path = get_slot_save_path()
	elif FileAccess.file_exists(get_slot_backup_path()):
		source_path = get_slot_backup_path()

	if not source_path.is_empty():
		archived = DirAccess.copy_absolute(source_path, archive_path) == OK
		if not archived:
			push_warning("Failed to archive save before New Game: %s" % source_path)

	var deleted := delete_save()
	return archived or deleted


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


static func inspect_slot(
	slot: String = DEFAULT_SLOT_ID,
	manifest_path: String = ContentManifest.PATH_BETA_DEMO
) -> Dictionary:
	var save_path := "%s/%s.save.json" % [SAVE_DIR, slot]
	var backup_path := "%s/%s.save.bak" % [SAVE_DIR, slot]

	if FileAccess.file_exists(save_path):
		var primary := _inspect_file_path(save_path, manifest_path, false)
		if String(primary.get("status", "")) == "valid":
			return primary
		if FileAccess.file_exists(backup_path):
			var backup := _inspect_file_path(backup_path, manifest_path, true)
			if String(backup.get("status", "")) == "valid":
				backup["message"] = "Progresso encontrado (restaurável via backup)."
				return backup
		return primary

	if FileAccess.file_exists(backup_path):
		return _inspect_file_path(backup_path, manifest_path, true)

	return {"status": "none", "message": "", "source": "none"}


static func _inspect_file_path(path: String, manifest_path: String, used_backup: bool) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {
			"status": "corrupted",
			"message": "Não foi possível ler o save. Inicie um Novo Jogo.",
			"source": "backup" if used_backup else "primary",
		}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		return {
			"status": "corrupted",
			"message": "Save corrompido. O jogo não foi encerrado — inicie um Novo Jogo.",
			"source": "backup" if used_backup else "primary",
		}

	return _inspect_parsed_payload(parsed as Dictionary, manifest_path, used_backup)


static func _inspect_parsed_payload(
	parsed: Dictionary,
	manifest_path: String,
	used_backup: bool
) -> Dictionary:
	var validation := SaveData.validate(parsed)
	if not validation.get("valid", false):
		return {
			"status": "corrupted",
			"message": "Save inválido (%s). Inicie um Novo Jogo." % String(validation.get("reason", "unknown")),
			"source": "backup" if used_backup else "primary",
		}

	if not validation.get("compatible", true):
		return {
			"status": "incompatible",
			"message": "Save incompatível com esta versão. Inicie um Novo Jogo.",
			"source": "backup" if used_backup else "primary",
		}

	var registry := ContentRegistry.get_active()
	var owned_registry := false
	if registry == null and not manifest_path.is_empty() and ResourceLoader.exists(manifest_path):
		registry = ContentRegistry.activate_from_path(manifest_path)
		owned_registry = registry != null

	if registry != null:
		if not registry.is_save_compatible_with_manifest(parsed):
			if owned_registry:
				ContentRegistry.clear_active()
			return {
				"status": "incompatible",
				"message": "Save incompatível com o conteúdo desta build. Inicie um Novo Jogo.",
				"source": "backup" if used_backup else "primary",
			}
		var area_path := String(parsed.get("current_scene", ""))
		if not area_path.is_empty() and not registry.can_load_area_scene(area_path):
			if owned_registry:
				ContentRegistry.clear_active()
			return {
				"status": "incompatible",
				"message": "Área salva indisponível nesta build. Inicie um Novo Jogo.",
				"source": "backup" if used_backup else "primary",
			}

	if owned_registry:
		ContentRegistry.clear_active()

	return {
		"status": "valid",
		"message": "Progresso encontrado.",
		"source": "backup" if used_backup else "primary",
	}


func create_backup() -> bool:
	if not FileAccess.file_exists(get_slot_save_path()):
		return false

	# Never overwrite a good backup with a corrupt primary.
	var primary := _read_save_file(get_slot_save_path())
	if primary.is_empty():
		push_warning("Skipped backup — primary save is invalid for slot '%s'." % slot_id)
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


func get_slot_archive_path() -> String:
	return "%s/%s.save.archive.json" % [SAVE_DIR, slot_id]


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
	var player_node := interactor if interactor != null and interactor.is_in_group(PLAYER_GROUP) else _player
	if player_node is CharacterBody2D:
		(player_node as CharacterBody2D).apply_checkpoint(
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
		save_data["world_map"] = progression_state.get("world_map", {})

	if _barrier_registry != null:
		save_data["destroyed_barriers"] = _barrier_registry.export_destroyed_state()

	var registry := ContentRegistry.get_active()
	if registry != null:
		save_data["content_manifest_id"] = String(registry.get_manifest_id())
		var chapter_id := registry.get_chapter_id_for_area_scene(String(save_data.get("current_scene", "")))
		if chapter_id != &"":
			save_data["chapter_id"] = String(chapter_id)

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
	if player is CharacterBody2D:
		return PlayerStateSnapshot.capture(player as CharacterBody2D)
	return PlayerStateSnapshot.capture(null)


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
			"world_map": save_data.get("world_map", {}),
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

	if _player is CharacterBody2D:
		var player_save := save_data
		if not area_restored:
			player_save = save_data.duplicate(true)
			player_save.erase("checkpoint_position")
		PlayerStateSnapshot.apply(_player as CharacterBody2D, player_save, area_restored)

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
		var existing_primary := _read_save_file(final_path)
		if not existing_primary.is_empty():
			if not create_backup():
				push_warning("Failed to create save backup before writing slot '%s'." % slot_id)
		else:
			push_warning(
				"Primary save invalid for slot '%s' — keeping existing backup untouched."
				% slot_id
			)

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

	if _services != null:
		if _services.player != null:
			_player = _services.player
		if _services.progression != null:
			_progression = _services.progression
		if _services.barrier_registry != null:
			_barrier_registry = _services.barrier_registry

	if _player == null:
		_player = _find_player()
	if _progression == null:
		_progression = _find_progression_component()
	if _barrier_registry == null:
		_barrier_registry = _find_barrier_registry()


func _find_player() -> CharacterBody2D:
	if _services != null and _services.player != null:
		return _services.player

	var grouped := get_tree().get_first_node_in_group(PLAYER_GROUP)
	return grouped as CharacterBody2D


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


func _find_progression_component() -> ProgressionComponent:
	if _services != null and _services.progression != null:
		return _services.progression

	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			return node
	return null


func _find_barrier_registry() -> BarrierRegistry:
	if _services != null and _services.barrier_registry != null:
		return _services.barrier_registry
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
	var registry := ContentRegistry.get_active()
	if registry != null:
		return registry.can_load_area_scene(area_scene_path)
	return area_scene_path.find("vertical_slice_") != -1


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
	if _services != null and _services.gameplay_lock_manager != null:
		return _services.gameplay_lock_manager

	var tree := get_tree()
	if tree == null:
		return null
	for node in tree.get_nodes_in_group("gameplay_lock_manager"):
		if node is GameplayLockManager:
			return node as GameplayLockManager
	return null
