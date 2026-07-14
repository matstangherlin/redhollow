extends Node
class_name GameplayLockManager

signal lock_acquired(reason: int, token_id: int)
signal lock_released(reason: int, token_id: int)
signal player_input_blocked_changed(is_blocked: bool)
signal softlock_recovery(reason: String)

enum LockReason {
	DIALOGUE,
	AREA_TRANSITION,
	PAUSE,
	CUTSCENE,
	DEATH,
	RESPAWN,
	BOSS_INTRO,
	COMPLETION,
	LOADING,
}

const MANAGER_GROUP := "gameplay_lock_manager"

const BLOCKING_REASONS: Array[int] = [
	LockReason.DIALOGUE,
	LockReason.AREA_TRANSITION,
	LockReason.PAUSE,
	LockReason.CUTSCENE,
	LockReason.DEATH,
	LockReason.RESPAWN,
	LockReason.BOSS_INTRO,
	LockReason.COMPLETION,
	LockReason.LOADING,
]

@export var enable_debug_panic_unlock: bool = true

var current_session_id: int = 1

var _locks: Dictionary = {}
var _owner_reason_tokens: Dictionary = {}
var _next_token_id: int = 1
var _player_input_blocked: bool = false
var _pause_lock_count: int = 0
var _hitstop_controller: Node = null


func _ready() -> void:
	add_to_group(MANAGER_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_bind_hitstop_controller()


func _process(_delta: float) -> void:
	_apply_pause_state()


func bind_hitstop_controller(controller: Node) -> void:
	_hitstop_controller = controller


func acquire_lock(reason: LockReason, owner: Object) -> GameplayLockToken:
	if owner == null:
		return _invalid_token()

	var owner_id := owner.get_instance_id()
	var owner_key := _owner_reason_key(owner_id, reason)
	if _owner_reason_tokens.has(owner_key):
		var existing_id: int = int(_owner_reason_tokens[owner_key])
		return _token_from_entry(existing_id)

	var token_id := _next_token_id
	_next_token_id += 1
	_locks[token_id] = {
		"reason": reason,
		"owner_id": owner_id,
		"session_id": current_session_id,
	}
	_owner_reason_tokens[owner_key] = token_id
	lock_acquired.emit(reason, token_id)
	_refresh_blocking_state()
	return _token_from_entry(token_id)


func release_lock(token: GameplayLockToken) -> bool:
	if token == null or not token.valid:
		return false
	return _release_token_id(token.id)


func release_locks_for_owner(owner: Object, reason: int = -1) -> int:
	if owner == null:
		return 0

	var owner_id := owner.get_instance_id()
	var released := 0
	var token_ids: Array = _locks.keys()

	for token_id_variant in token_ids:
		var token_id: int = int(token_id_variant)
		var entry: Dictionary = _locks.get(token_id, {})
		if int(entry.get("owner_id", 0)) != owner_id:
			continue
		if reason >= 0 and int(entry.get("reason", -1)) != reason:
			continue
		if _release_token_id(token_id):
			released += 1

	return released


func release_locks_for_reason(reason: LockReason) -> int:
	var released := 0
	var token_ids: Array = _locks.keys()

	for token_id_variant in token_ids:
		var token_id: int = int(token_id_variant)
		var entry: Dictionary = _locks.get(token_id, {})
		if int(entry.get("reason", -1)) != reason:
			continue
		if _release_token_id(token_id):
			released += 1

	return released


func has_lock(reason: LockReason) -> bool:
	for entry_variant in _locks.values():
		var entry: Dictionary = entry_variant
		if int(entry.get("reason", -1)) == reason:
			return true
	return false


func get_lock_count() -> int:
	return _locks.size()


func is_player_input_blocked() -> bool:
	return _player_input_blocked


func is_pause_active() -> bool:
	return _pause_lock_count > 0


func begin_new_session() -> void:
	current_session_id += 1
	release_previous_session_locks()


func release_previous_session_locks() -> int:
	var released := 0
	var token_ids: Array = _locks.keys()

	for token_id_variant in token_ids:
		var token_id: int = int(token_id_variant)
		var entry: Dictionary = _locks.get(token_id, {})
		if int(entry.get("session_id", 0)) >= current_session_id:
			continue
		if _release_token_id(token_id):
			released += 1

	return released


func debug_force_release_all(_reason: String = "debug") -> void:
	if not enable_debug_panic_unlock:
		return

	var token_ids: Array = _locks.keys()
	for token_id_variant in token_ids.duplicate():
		_release_token_id(int(token_id_variant))

	if _hitstop_controller != null and _hitstop_controller.has_method("force_release"):
		_hitstop_controller.call("force_release")

	var tree := get_tree()
	if tree != null:
		tree.paused = false
	Engine.time_scale = 1.0
	_refresh_blocking_state()
	softlock_recovery.emit(String(_reason))


func request_hitstop(duration: float) -> void:
	if _hitstop_controller != null and _hitstop_controller.has_method("request_hitstop"):
		_hitstop_controller.call("request_hitstop", duration)


func _release_token_id(token_id: int) -> bool:
	if not _locks.has(token_id):
		return false

	var entry: Dictionary = _locks[token_id]
	var reason: int = int(entry.get("reason", -1))
	var owner_id: int = int(entry.get("owner_id", 0))
	var owner_key := _owner_reason_key(owner_id, reason)

	_locks.erase(token_id)
	if _owner_reason_tokens.get(owner_key, -1) == token_id:
		_owner_reason_tokens.erase(owner_key)

	lock_released.emit(reason, token_id)
	_refresh_blocking_state()
	return true


func _refresh_blocking_state() -> void:
	var blocked := false
	_pause_lock_count = 0

	for entry_variant in _locks.values():
		var entry: Dictionary = entry_variant
		var reason: int = int(entry.get("reason", -1))
		if reason == LockReason.PAUSE:
			_pause_lock_count += 1
		if BLOCKING_REASONS.has(reason):
			blocked = true

	if blocked != _player_input_blocked:
		_player_input_blocked = blocked
		player_input_blocked_changed.emit(blocked)

	_apply_pause_state()


func _apply_pause_state() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = _pause_lock_count > 0


func _bind_hitstop_controller() -> void:
	if _hitstop_controller != null:
		return
	_hitstop_controller = get_node_or_null("../HitstopController")
	if _hitstop_controller == null:
		_hitstop_controller = get_tree().get_first_node_in_group("hitstop_controller") if get_tree() != null else null


func _owner_reason_key(owner_id: int, reason: int) -> String:
	return "%d:%d" % [owner_id, reason]


func _token_from_entry(token_id: int) -> GameplayLockToken:
	var token := GameplayLockToken.new()
	if not _locks.has(token_id):
		return token

	var entry: Dictionary = _locks[token_id]
	token.id = token_id
	token.reason = int(entry.get("reason", -1))
	token.owner_id = int(entry.get("owner_id", 0))
	token.session_id = int(entry.get("session_id", 0))
	token.valid = true
	return token


func _invalid_token() -> GameplayLockToken:
	return GameplayLockToken.new()
