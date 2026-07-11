extends Node

const GAME_ROOT_GROUP := "game_root"

@onready var world_host: Node2D = %WorldHost
@onready var save_manager: SaveManager = %SaveManager
@onready var area_transition_manager: Node = %AreaTransitionManager
@onready var gameplay_lock_manager: GameplayLockManager = $GameplayLockManager
@onready var hitstop_controller: HitstopController = $HitstopController

var initialized: bool = false


func _ready() -> void:
	if _has_duplicate_game_root():
		push_warning("Duplicate Game root detected. Removing the duplicate prototype coordinator.")
		queue_free()
		return

	add_to_group(GAME_ROOT_GROUP)
	process_mode = Node.PROCESS_MODE_ALWAYS
	initialized = true

	if gameplay_lock_manager != null and hitstop_controller != null:
		gameplay_lock_manager.bind_hitstop_controller(hitstop_controller)

	call_deferred("_initialize_runtime_systems")


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		return
	if gameplay_lock_manager == null or not gameplay_lock_manager.enable_debug_panic_unlock:
		return

	_debug_panic_unlock()
	get_viewport().set_input_as_handled()


func _initialize_runtime_systems() -> void:
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


func _debug_panic_unlock() -> void:
	if gameplay_lock_manager != null:
		gameplay_lock_manager.debug_force_release_all("panic")

	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node.has_method("force_reset"):
			node.call("force_reset")


func _has_duplicate_game_root() -> bool:
	for node in get_tree().get_nodes_in_group(GAME_ROOT_GROUP):
		if node != self:
			return true

	return false
