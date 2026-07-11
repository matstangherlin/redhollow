extends Node
class_name DialogueController

signal dialogue_started(dialogue_id: StringName)
signal dialogue_finished(dialogue_id: StringName)
signal line_presented(dialogue_id: StringName, line_index: int, text: String)
signal dialogue_action_requested(action: Dictionary, phase: StringName)
signal dialogue_start_failed(dialogue_id: StringName, reason: String)

const CONTROLLER_GROUP := "dialogue_controller"
const PLAYER_GROUP := "player"
const DEFAULT_DIALOGUE_PATH := "res://data/dialogues/dialogues_pt_br.json"
const IGNORE_ADVANCE_MAX_SECONDS := 0.35
const REOPEN_BLOCK_MS := 250

@export var dialogue_data_path: String = DEFAULT_DIALOGUE_PATH
@export var dialogue_box_path: NodePath

var is_active: bool = false

var _library: DialogueLibrary = DialogueLibrary.new()
var _dialogue_box: CanvasLayer = null
var _current_entry: Dictionary = {}
var _current_dialogue_id: StringName = &""
var _current_line_index: int = 0
var _interactor: Node = null
var _speaker_anchor: Node = null
var _player: Node = null
var _ignore_advance_until_release: bool = false
var _ignore_advance_time_remaining: float = 0.0
var _last_close_ms: int = -100000
var _lock_manager: GameplayLockManager = null
var _dialogue_lock_token: GameplayLockToken = null


func _ready() -> void:
	add_to_group(CONTROLLER_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_unhandled_input(true)
	_bind_dialogue_box()
	_load_dialogue_data()
	call_deferred("_bind_lock_manager")
	force_reset()


func _process(_delta: float) -> void:
	# Use wall-clock friendly checks; scaled delta can be near-zero during hitstop.
	var step := maxf(_delta, 0.016)

	if not is_active:
		_reconcile_orphan_dialogue_box()
		return

	if _ignore_advance_until_release:
		_ignore_advance_time_remaining = maxf(_ignore_advance_time_remaining - step, 0.0)
		if not Input.is_action_pressed("interact") or _ignore_advance_time_remaining <= 0.0:
			_ignore_advance_until_release = false
		else:
			return

	# Advancing with [E] is handled only in _unhandled_input; polling Input here as
	# well made every press advance twice and skip lines.
	if Input.is_key_pressed(KEY_ESCAPE):
		close_dialogue()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		# Panic unlock even when dialogue is not marked active.
		force_reset()
		get_viewport().set_input_as_handled()
		return

	if not is_active:
		return

	if event.is_action_pressed("interact") and not event.is_echo():
		if _ignore_advance_until_release:
			return
		_advance_or_close()
		get_viewport().set_input_as_handled()


func try_start_dialogue(dialogue_id: StringName, interactor: Node = null, speaker_anchor: Node = null) -> bool:
	if is_active:
		push_warning("Dialogue already active. Ignoring request for '%s'." % String(dialogue_id))
		dialogue_start_failed.emit(dialogue_id, "dialogue_already_active")
		return false

	if dialogue_id == &"":
		push_warning("Cannot start dialogue with an empty id.")
		dialogue_start_failed.emit(dialogue_id, "empty_dialogue_id")
		return false

	_ensure_initialized()
	if not _library.is_loaded():
		push_warning("Dialogue library is not loaded.")
		dialogue_start_failed.emit(dialogue_id, "library_not_loaded")
		return false

	var entry := _library.get_dialogue(dialogue_id)
	if entry.is_empty():
		dialogue_start_failed.emit(dialogue_id, "dialogue_not_found")
		return false

	if not _meets_future_conditions(entry):
		dialogue_start_failed.emit(dialogue_id, "conditions_not_met")
		return false

	_current_entry = entry
	_current_dialogue_id = entry["dialogue_id"] as StringName
	_current_line_index = 0
	_interactor = interactor
	_speaker_anchor = speaker_anchor
	_player = _resolve_player(interactor)

	is_active = true
	_ignore_advance_until_release = Input.is_action_pressed("interact")
	_ignore_advance_time_remaining = IGNORE_ADVANCE_MAX_SECONDS

	_lock_player()
	_run_actions(entry.get("actions_on_start", []), &"start")
	if not _present_current_line():
		force_reset()
		dialogue_start_failed.emit(dialogue_id, "failed_to_present_line")
		return false

	dialogue_started.emit(_current_dialogue_id)
	return true


func close_dialogue() -> void:
	var finished_id := _current_dialogue_id
	var should_emit := is_active

	if is_active:
		_run_actions(_current_entry.get("actions_on_end", []), &"end")

	_reset_runtime_state()

	if should_emit and finished_id != &"":
		dialogue_finished.emit(finished_id)


func force_reset() -> void:
	_reset_runtime_state()


func is_blocking_interactions() -> bool:
	# The [E] press that closes a dialogue is still "just pressed" when the player
	# polls input later in the same frame; block re-interactions briefly so closing
	# a dialogue does not immediately reopen it.
	return is_active or (Time.get_ticks_msec() - _last_close_ms) < REOPEN_BLOCK_MS


func _force_unlock_player() -> void:
	_release_dialogue_lock()


func _release_dialogue_lock() -> void:
	if _lock_manager != null and _dialogue_lock_token != null and _dialogue_lock_token.valid:
		_lock_manager.release_lock(_dialogue_lock_token)
	_dialogue_lock_token = null


func _reset_runtime_state() -> void:
	if is_active:
		_last_close_ms = Time.get_ticks_msec()
	is_active = false
	_ignore_advance_until_release = false
	_ignore_advance_time_remaining = 0.0
	_current_entry = {}
	_current_dialogue_id = &""
	_current_line_index = 0
	_interactor = null
	_speaker_anchor = null
	_hide_dialogue_box()
	_force_unlock_player()
	_player = null


func _advance_or_close() -> void:
	if not is_active:
		return

	var lines := _current_entry.get("lines", PackedStringArray()) as PackedStringArray
	if _current_line_index >= lines.size() - 1:
		close_dialogue()
		return

	_current_line_index += 1
	if not _present_current_line():
		close_dialogue()


func _present_current_line() -> bool:
	var lines := _current_entry.get("lines", PackedStringArray()) as PackedStringArray
	if lines.is_empty():
		push_warning("Dialogue '%s' has no lines to present." % String(_current_dialogue_id))
		return false

	var speaker := String(_current_entry.get("speaker", ""))
	var portrait := String(_current_entry.get("portrait", ""))
	var text := String(lines[_current_line_index])
	var is_last_line := _current_line_index >= lines.size() - 1

	if _dialogue_box != null and _dialogue_box.has_method("present_line"):
		var presented: Variant = _dialogue_box.call("present_line", speaker, text, portrait, is_last_line)
		if presented is bool and not bool(presented):
			return false
	elif text.strip_edges().is_empty():
		return false

	line_presented.emit(_current_dialogue_id, _current_line_index, text)
	return true


func _hide_dialogue_box() -> void:
	if _dialogue_box != null and _dialogue_box.has_method("hide_box"):
		_dialogue_box.call("hide_box")
	elif _dialogue_box != null:
		_dialogue_box.visible = false


func _reconcile_orphan_dialogue_box() -> void:
	if _dialogue_box == null:
		return
	if _dialogue_box.has_method("is_box_visible") and bool(_dialogue_box.call("is_box_visible")):
		_hide_dialogue_box()
	elif bool(_dialogue_box.get("visible")):
		_hide_dialogue_box()


func _load_dialogue_data() -> bool:
	if not _library.load_from_file(dialogue_data_path):
		push_warning("DialogueController failed to load dialogue data from %s" % dialogue_data_path)
		return false
	return true


func _ensure_initialized() -> void:
	if _dialogue_box == null:
		_bind_dialogue_box()
	if not _library.is_loaded():
		_load_dialogue_data()


func _bind_dialogue_box() -> void:
	if dialogue_box_path.is_empty():
		_dialogue_box = get_node_or_null("DialogueBox") as CanvasLayer
	else:
		_dialogue_box = get_node_or_null(dialogue_box_path) as CanvasLayer

	_hide_dialogue_box()


func _resolve_player(interactor: Node) -> Node:
	if interactor != null and interactor.is_in_group(PLAYER_GROUP):
		return interactor

	var tree := get_tree()
	if tree == null:
		return interactor

	return tree.get_first_node_in_group(PLAYER_GROUP)


func _lock_player() -> void:
	_bind_lock_manager()
	if _lock_manager != null:
		if _dialogue_lock_token == null or not _dialogue_lock_token.valid:
			_dialogue_lock_token = _lock_manager.acquire_lock(
				GameplayLockManager.LockReason.DIALOGUE,
				self
			)
		return

	if _player != null and _player.has_method("enter_dialogue_mode"):
		_player.call("enter_dialogue_mode")


func _bind_lock_manager() -> void:
	if _lock_manager != null:
		return
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("gameplay_lock_manager"):
		if node is GameplayLockManager:
			_lock_manager = node as GameplayLockManager
			return


func _run_actions(actions: Array, phase: StringName) -> void:
	for action_variant in actions:
		if typeof(action_variant) != TYPE_DICTIONARY:
			continue
		dialogue_action_requested.emit(action_variant as Dictionary, phase)


func _meets_future_conditions(entry: Dictionary) -> bool:
	var conditions := entry.get("conditions", {}) as Dictionary
	if conditions.is_empty():
		return true
	return true
