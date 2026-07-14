extends Node
class_name BetaPlaytestRecorder

## Local-only playtest telemetry for **debug builds**.
## Writes JSON Lines under user://playtests/ — never network, never PII.

const RECORDER_GROUP := "beta_playtest_recorder"
const PLAYTEST_DIR := "user://playtests"
const PANEL_TOGGLE_ACTION_HINT := "F10"

@export var enabled: bool = true

var session_id: String = ""
var _session_path: String = ""
var _session_started_at_ms: int = 0
var _event_count: int = 0
var _closed: bool = false

var _area_id: String = ""
var _objective_id: String = ""
var _checkpoint_id: String = ""
var _boot_mode: String = "unknown"

var _connected_arenas: Dictionary = {}
var _connected_bosses: Dictionary = {}
var _player_health: HealthComponent = null
var _bound_player: CharacterBody2D = null

## Aggregate counters for balance playtests (also emitted as typed events).
var _deaths: int = 0
var _damage_taken: float = 0.0
var _dodge_uses: int = 0
var _counter_uses: int = 0
var _red_brand_uses: int = 0
var _boss_attempts: int = 0
var _checkpoints_used: int = 0
var _secrets_found: int = 0
var _objectives_seen: int = 0
var _objectives_completed: int = 0

var _arena_started_at_sec: float = -1.0
var _boss_started_at_sec: float = -1.0
var _objective_started_at_sec: float = -1.0
var _deaths_on_current_objective: int = 0
var _active_arena_id: String = ""
var _active_boss_encounter_id: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not OS.is_debug_build() or not enabled:
		queue_free()
		return

	add_to_group(RECORDER_GROUP)
	_ensure_directory()
	_begin_session()
	call_deferred("_bind_runtime")
	get_tree().node_added.connect(_on_tree_node_added)


func _exit_tree() -> void:
	if not _closed and OS.is_debug_build() and enabled:
		_finalize_open_timers("tree_exit")
		record_event("session_end", _metrics_payload({"reason": "tree_exit"}))
		_closed = true


func note_boot(boot_mode: String) -> void:
	_boot_mode = boot_mode
	record_event("boot", {"boot_mode": boot_mode})


func record_event(event_type: String, payload: Dictionary = {}) -> void:
	if not OS.is_debug_build() or not enabled or _session_path.is_empty() or _closed:
		return

	var entry := {
		"ts_ms": Time.get_ticks_msec(),
		"elapsed_sec": _elapsed_seconds(),
		"type": event_type,
		"area_id": _area_id,
		"objective_id": _objective_id,
		"checkpoint_id": _checkpoint_id,
	}
	for key in payload.keys():
		entry[String(key)] = payload[key]

	var line := JSON.stringify(entry)
	var file := FileAccess.open(_session_path, FileAccess.READ_WRITE)
	if file == null:
		file = FileAccess.open(_session_path, FileAccess.WRITE)
	if file == null:
		push_warning("BetaPlaytestRecorder failed to open %s" % _session_path)
		return
	file.seek_end()
	file.store_line(line)
	file.close()
	_event_count += 1


func get_session_path() -> String:
	return _session_path


func get_snapshot() -> Dictionary:
	var snap := {
		"session_id": session_id,
		"session_path": _session_path,
		"elapsed_sec": _elapsed_seconds(),
		"event_count": _event_count,
		"area_id": _area_id,
		"objective_id": _objective_id,
		"checkpoint_id": _checkpoint_id,
		"boot_mode": _boot_mode,
		"save_version": SaveData.CURRENT_SAVE_VERSION,
		"game_version": GameVersion.GAME_VERSION,
	}
	for key in _metrics_core().keys():
		snap[key] = _metrics_core()[key]
	return snap


func _metrics_core() -> Dictionary:
	return {
		"duration_sec": _elapsed_seconds(),
		"deaths": _deaths,
		"damage_taken": _damage_taken,
		"dodge_uses": _dodge_uses,
		"counter_uses": _counter_uses,
		"red_brand_uses": _red_brand_uses,
		"boss_attempts": _boss_attempts,
		"checkpoints_used": _checkpoints_used,
		"secrets_found": _secrets_found,
		"objectives_seen": _objectives_seen,
		"objectives_completed": _objectives_completed,
		"deaths_on_current_objective": _deaths_on_current_objective,
	}


func _metrics_payload(extra: Dictionary = {}) -> Dictionary:
	var payload := _metrics_core()
	payload["event_count"] = _event_count
	for key in extra.keys():
		payload[String(key)] = extra[key]
	return payload


func _begin_session() -> void:
	_session_started_at_ms = Time.get_ticks_msec()
	var stamp := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "")
	session_id = "beta_%s_%d" % [stamp, randi() % 100000]
	_session_path = "%s/%s.jsonl" % [PLAYTEST_DIR, session_id]

	var viewport_size := Vector2i.ZERO
	var tree := get_tree()
	if tree != null and tree.root != null:
		viewport_size = Vector2i(tree.root.size)

	record_event(
		"session_start",
		{
			"game_version": GameVersion.GAME_VERSION,
			"save_version": SaveData.CURRENT_SAVE_VERSION,
			"build_channel": GameVersion.BUILD_CHANNEL,
			"git_commit": _resolve_git_commit(),
			"device_kind": _device_kind_label(),
			"os_name": OS.get_name(),
			"resolution": {"w": viewport_size.x, "h": viewport_size.y},
			"debug_build": true,
			"recorder": "BetaPlaytestRecorder",
		}
	)


func _bind_runtime() -> void:
	var root := get_parent()
	if root == null:
		return

	var transition := root.get_node_or_null("%AreaTransitionManager") as AreaTransitionManager
	if transition != null:
		if not transition.area_changed.is_connected(_on_area_changed):
			transition.area_changed.connect(_on_area_changed)
		if not transition.transition_finished.is_connected(_on_transition_finished):
			transition.transition_finished.connect(_on_transition_finished)
		var current := transition.get_current_area()
		if current != null:
			_area_id = String(current.area_id)

	var save_manager := root.get_node_or_null("%SaveManager") as SaveManager
	if save_manager != null:
		_connect_signal(save_manager, "save_written", _on_save_written)
		_connect_signal(save_manager, "save_loaded", _on_save_loaded)
		_connect_signal(save_manager, "save_failed", _on_save_failed)

	var dialogue: Node = null
	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		dialogue = node
		break
	if dialogue != null:
		_connect_signal(dialogue, "dialogue_started", _on_dialogue_started)
		_connect_signal(dialogue, "dialogue_finished", _on_dialogue_finished)

	var narrative := root.get_node_or_null("NarrativeDirector") as NarrativeDirector
	if narrative != null:
		var tracker := narrative.get_objective_tracker()
		if tracker != null:
			_connect_signal(tracker, "objective_changed", _on_objective_changed)
			_objective_id = tracker.get_active_objective_id()
			if not _objective_id.is_empty():
				_objective_started_at_sec = _elapsed_seconds()
				_objectives_seen = 1

	var demo := root.get_node_or_null("VerticalSliceController")
	if demo != null and demo.has_signal("demo_completed"):
		_connect_signal(demo, "demo_completed", _on_demo_completed)

	var lock_manager := root.get_node_or_null("GameplayLockManager") as GameplayLockManager
	if lock_manager != null and lock_manager.has_signal("softlock_recovery"):
		_connect_signal(lock_manager, "softlock_recovery", _on_softlock_recovery)

	var respawn := root.get_node_or_null("RespawnService")
	if respawn != null and respawn.has_signal("respawn_completed"):
		_connect_signal(respawn, "respawn_completed", _on_respawn_completed)

	var map_service: WorldMapService = null
	for node in get_tree().get_nodes_in_group(WorldMapService.SERVICE_GROUP):
		map_service = node as WorldMapService
		break
	if map_service != null and map_service.has_signal("map_state_changed"):
		_connect_signal(map_service, "map_state_changed", _on_map_state_changed)
		_sync_secrets_from_map(map_service)

	_bind_player(root)
	_scan_existing_encounter_nodes(root)


func _bind_player(root: Node) -> void:
	var player := root.get_node_or_null("%Player") as CharacterBody2D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player == null:
		return

	if _bound_player == player:
		return
	_bound_player = player

	var health := player.get_node_or_null("%HealthComponent") as HealthComponent
	if health == null:
		health = player.get_node_or_null("Components/HealthComponent") as HealthComponent
	if health != null and _player_health != health:
		_player_health = health
		if not health.died.is_connected(_on_player_died):
			health.died.connect(_on_player_died)
		if not health.damaged.is_connected(_on_player_damaged):
			health.damaged.connect(_on_player_damaged)

	_connect_signal(player, "dodge_started", _on_dodge_started)
	_connect_signal(player, "counter_success", _on_counter_success)
	_connect_signal(player, "brand_breaker_released", _on_red_brand_released)


func _scan_existing_encounter_nodes(root: Node) -> void:
	for node in root.find_children("*", "CombatArenaController", true, false):
		_bind_arena(node)
	for node in root.find_children("*", "BossEncounterController", true, false):
		_bind_boss(node)
	for node in get_tree().get_nodes_in_group("checkpoints"):
		_bind_checkpoint(node)


func _on_tree_node_added(node: Node) -> void:
	if node is CombatArenaController:
		_bind_arena(node)
	elif node is BossEncounterController:
		_bind_boss(node)
	elif node.is_in_group("checkpoints"):
		_bind_checkpoint(node)
	elif node.is_in_group("player"):
		call_deferred("_bind_player", get_parent())


func _bind_arena(node: Node) -> void:
	var id := node.get_instance_id()
	if _connected_arenas.has(id):
		return
	_connected_arenas[id] = true
	_connect_signal(node, "arena_activated", _on_arena_activated)
	_connect_signal(node, "arena_completed", _on_arena_completed)
	_connect_signal(node, "arena_integrity_failed", _on_arena_integrity_failed)
	_connect_signal(node, "arena_debug_recovered", _on_arena_debug_recovered)


func _bind_boss(node: Node) -> void:
	var id := node.get_instance_id()
	if _connected_bosses.has(id):
		return
	_connected_bosses[id] = true
	_connect_signal(node, "encounter_started", _on_boss_started)
	_connect_signal(node, "boss_defeated", _on_boss_defeated)
	_connect_signal(node, "encounter_completed", _on_boss_encounter_completed)


func _bind_checkpoint(node: Node) -> void:
	if node.has_signal("checkpoint_activated") and not node.is_connected(
		"checkpoint_activated",
		Callable(self, "_on_checkpoint_activated")
	):
		node.connect("checkpoint_activated", Callable(self, "_on_checkpoint_activated"))


func _connect_signal(source: Object, signal_name: String, callable: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return
	if not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)


func _on_area_changed(area_id: StringName, area_scene_path: String) -> void:
	_area_id = String(area_id)
	record_event("area_changed", {"area_scene": area_scene_path})


func _on_transition_finished(area_id: StringName, spawn_id: StringName) -> void:
	_area_id = String(area_id)
	record_event("area_transition_finished", {"spawn_id": String(spawn_id)})


func _on_objective_changed(objective_id: String, title: String, text: String) -> void:
	var now := _elapsed_seconds()
	if not _objective_id.is_empty() and _objective_started_at_sec >= 0.0:
		var dwell := maxf(now - _objective_started_at_sec, 0.0)
		_objectives_completed += 1
		record_event(
			"objective_completed",
			{
				"completed_id": _objective_id,
				"dwell_sec": dwell,
				"deaths_during": _deaths_on_current_objective,
				"understood_proxy": _deaths_on_current_objective <= 2 and dwell >= 8.0,
			}
		)

	_objective_id = objective_id
	_objective_started_at_sec = now
	_deaths_on_current_objective = 0
	if not objective_id.is_empty():
		_objectives_seen += 1
	record_event(
		"objective_changed",
		{"title": title, "text_len": text.length()}
	)


func _on_checkpoint_activated(
	checkpoint_id: StringName,
	_checkpoint_position: Vector2,
	_interactor: Node,
	_restore_health: bool,
	_restore_red_brand: bool
) -> void:
	_checkpoint_id = String(checkpoint_id)
	_checkpoints_used += 1
	record_event(
		"checkpoint_activated",
		{
			"checkpoint_id": _checkpoint_id,
			"checkpoints_used": _checkpoints_used,
			"restore_health": _restore_health,
			"restore_red_brand": _restore_red_brand,
		}
	)


func _on_player_died() -> void:
	_deaths += 1
	_deaths_on_current_objective += 1
	record_event("death", {"deaths": _deaths})


func _on_player_damaged(amount: float, source: Node) -> void:
	_damage_taken += maxf(amount, 0.0)
	record_event(
		"damage_taken",
		{
			"amount": amount,
			"total_damage_taken": _damage_taken,
			"source": String(source.name) if source != null else "",
		}
	)


func _on_dodge_started() -> void:
	_dodge_uses += 1
	record_event("dodge_used", {"dodge_uses": _dodge_uses})


func _on_counter_success(_attack_data: Resource, _attacker: Node) -> void:
	_counter_uses += 1
	record_event("counter_used", {"counter_uses": _counter_uses})


func _on_red_brand_released(level: int, cost: float) -> void:
	_red_brand_uses += 1
	record_event(
		"red_brand_used",
		{"level": level, "cost": cost, "red_brand_uses": _red_brand_uses}
	)


func _on_respawn_completed(_player: Node) -> void:
	record_event("respawn", {})


func _on_arena_activated(arena_id: StringName) -> void:
	_active_arena_id = String(arena_id)
	_arena_started_at_sec = _elapsed_seconds()
	record_event("arena_started", {"arena_id": _active_arena_id})


func _on_arena_completed(arena_id: StringName) -> void:
	var duration := 0.0
	if _arena_started_at_sec >= 0.0:
		duration = maxf(_elapsed_seconds() - _arena_started_at_sec, 0.0)
	record_event(
		"arena_completed",
		{"arena_id": String(arena_id), "arena_time_sec": duration}
	)
	_arena_started_at_sec = -1.0
	_active_arena_id = ""


func _on_arena_integrity_failed(arena_id: StringName, reason: String) -> void:
	record_event("integrity_error", {"arena_id": String(arena_id), "reason": reason})


func _on_arena_debug_recovered(arena_id: StringName) -> void:
	record_event("softlock_recovery", {"source": "arena", "arena_id": String(arena_id)})


func _on_softlock_recovery(reason: String) -> void:
	record_event("softlock_recovery", {"source": "lock_manager", "reason": reason})


func _on_boss_started(encounter_id: StringName) -> void:
	_boss_attempts += 1
	_active_boss_encounter_id = String(encounter_id)
	_boss_started_at_sec = _elapsed_seconds()
	record_event(
		"boss_started",
		{"encounter_id": _active_boss_encounter_id, "boss_attempts": _boss_attempts}
	)
	record_event("boss_attempt", {"encounter_id": _active_boss_encounter_id, "attempt": _boss_attempts})


func _on_boss_defeated(boss_id: StringName) -> void:
	var duration := 0.0
	if _boss_started_at_sec >= 0.0:
		duration = maxf(_elapsed_seconds() - _boss_started_at_sec, 0.0)
	record_event(
		"boss_defeated",
		{
			"boss_id": String(boss_id),
			"boss_time_sec": duration,
			"boss_attempts": _boss_attempts,
		}
	)
	_boss_started_at_sec = -1.0


func _on_boss_encounter_completed(encounter_id: StringName) -> void:
	record_event("boss_encounter_completed", {"encounter_id": String(encounter_id)})


func _on_map_state_changed() -> void:
	var map_service: WorldMapService = null
	for node in get_tree().get_nodes_in_group(WorldMapService.SERVICE_GROUP):
		map_service = node as WorldMapService
		break
	_sync_secrets_from_map(map_service)


func _sync_secrets_from_map(map_service: WorldMapService) -> void:
	if map_service == null:
		return
	var state: Dictionary = map_service.export_save_state()
	var found: Array = state.get("found_secrets", []) as Array
	var count := found.size()
	if count > _secrets_found:
		var gained := count - _secrets_found
		_secrets_found = count
		record_event(
			"secret_found",
			{"secrets_found": _secrets_found, "gained": gained}
		)


func _on_dialogue_started(dialogue_id: StringName) -> void:
	record_event("dialogue_started", {"dialogue_id": String(dialogue_id)})


func _on_dialogue_finished(dialogue_id: StringName) -> void:
	record_event("dialogue_finished", {"dialogue_id": String(dialogue_id)})


func _on_save_written(slot_id: String) -> void:
	record_event("save", {"slot_id": slot_id})


func _on_save_loaded(slot_id: String) -> void:
	record_event("load", {"slot_id": slot_id})


func _on_save_failed(slot_id: String, reason: String) -> void:
	record_event("save_failed", {"slot_id": slot_id, "reason": reason})


func _on_demo_completed() -> void:
	_finalize_open_timers("beta_completed")
	record_event("beta_completed", _metrics_payload())


func _finalize_open_timers(reason: String) -> void:
	var now := _elapsed_seconds()
	if _arena_started_at_sec >= 0.0 and not _active_arena_id.is_empty():
		record_event(
			"arena_time_partial",
			{
				"arena_id": _active_arena_id,
				"arena_time_sec": maxf(now - _arena_started_at_sec, 0.0),
				"reason": reason,
			}
		)
	if _boss_started_at_sec >= 0.0 and not _active_boss_encounter_id.is_empty():
		record_event(
			"boss_time_partial",
			{
				"encounter_id": _active_boss_encounter_id,
				"boss_time_sec": maxf(now - _boss_started_at_sec, 0.0),
				"reason": reason,
			}
		)


func _elapsed_seconds() -> float:
	return float(Time.get_ticks_msec() - _session_started_at_ms) / 1000.0


func _ensure_directory() -> void:
	if not DirAccess.dir_exists_absolute(PLAYTEST_DIR):
		DirAccess.make_dir_recursive_absolute(PLAYTEST_DIR)


func _device_kind_label() -> String:
	if InputDeviceManager != null and InputDeviceManager.is_using_gamepad():
		return "gamepad"
	return "keyboard"


func _resolve_git_commit() -> String:
	## Best-effort local read without spawning processes (avoids headless hangs).
	var project_root := ProjectSettings.globalize_path("res://")
	if project_root.ends_with("/") or project_root.ends_with("\\"):
		project_root = project_root.substr(0, project_root.length() - 1)
	var head_path := "%s/.git/HEAD" % project_root
	if not FileAccess.file_exists(head_path):
		return "unknown"
	var head := FileAccess.get_file_as_string(head_path).strip_edges()
	if head.begins_with("ref:"):
		var ref_rel := head.trim_prefix("ref:").strip_edges()
		var ref_path := "%s/.git/%s" % [project_root, ref_rel]
		if FileAccess.file_exists(ref_path):
			var full := FileAccess.get_file_as_string(ref_path).strip_edges()
			if full.length() >= 7:
				return full.substr(0, 7)
			return full if not full.is_empty() else "unknown"
	elif head.length() >= 7:
		return head.substr(0, 7)
	return "unknown"
