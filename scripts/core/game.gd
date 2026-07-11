extends Node

const GAME_ROOT_GROUP := "game_root"

@onready var world_host: Node2D = %WorldHost
@onready var save_manager: SaveManager = %SaveManager
@onready var area_transition_manager: Node = %AreaTransitionManager

var initialized: bool = false


func _ready() -> void:
	if _has_duplicate_game_root():
		push_warning("Duplicate Game root detected. Removing the duplicate prototype coordinator.")
		queue_free()
		return

	add_to_group(GAME_ROOT_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialized = true
	_ensure_runtime_unfrozen()
	call_deferred("_initialize_runtime_systems")


func _process(_delta: float) -> void:
	_ensure_runtime_unfrozen()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		_panic_unlock()
		get_viewport().set_input_as_handled()


func _initialize_runtime_systems() -> void:
	_ensure_runtime_unfrozen()
	_panic_unlock()

	await get_tree().process_frame

	if area_transition_manager != null:
		area_transition_manager.initialize(self)

	if save_manager != null:
		# Fresh demo boot: do not restore a broken mid-arena save automatically.
		save_manager.auto_load_on_ready = false
		save_manager.bind_game(self, area_transition_manager.get_current_area(), area_transition_manager)
		print(
			"[Game] Save directory: %s | Slot path: %s"
			% [save_manager.get_resolved_save_directory(), save_manager.get_resolved_slot_save_path()]
		)
		print("[Game] Auto-load disabled for vertical slice. Press F8 to save / F9 to load / F7 to reset.")

	_panic_unlock()
	_ensure_runtime_unfrozen()


func _panic_unlock() -> void:
	_ensure_runtime_unfrozen()

	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node.has_method("force_reset"):
			node.call("force_reset")

	for node in get_tree().get_nodes_in_group("hitstop_controller"):
		if node.has_method("force_release"):
			node.call("force_release")

	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("clear_input_locks"):
		player.call("clear_input_locks")

	# If an arena is active with no living enemies, force-complete it.
	for arena in get_tree().get_nodes_in_group("combat_arena_controller"):
		if not arena.has_method("get_remaining_enemy_count"):
			continue
		if int(arena.get("state")) != 1:
			continue
		if int(arena.call("get_remaining_enemy_count")) <= 0 and arena.has_method("_complete_arena"):
			arena.call("_complete_arena")


func _ensure_runtime_unfrozen() -> void:
	if get_tree() != null and get_tree().paused:
		get_tree().paused = false

	if Engine.time_scale <= 0.01 or Engine.time_scale < 0.5:
		var hitstop := get_tree().get_first_node_in_group("hitstop_controller")
		if hitstop != null and hitstop.has_method("force_release"):
			hitstop.call("force_release")
		Engine.time_scale = 1.0


func _has_duplicate_game_root() -> bool:
	for node in get_tree().get_nodes_in_group(GAME_ROOT_GROUP):
		if node != self:
			return true

	return false
