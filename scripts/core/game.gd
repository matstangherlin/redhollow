extends Node

const GAME_ROOT_GROUP := "game_root"

@onready var world_host: Node2D = %WorldHost
@onready var save_manager: SaveManager = %SaveManager
@onready var area_transition_manager: AreaTransitionManager = %AreaTransitionManager
@onready var gameplay_lock_manager: GameplayLockManager = $GameplayLockManager
@onready var hitstop_controller: HitstopController = $HitstopController
@onready var game_services: GameServices = $GameServices

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

	_activate_content_manifest()

	if game_services != null:
		game_services.bind_from_shell(self)
		if game_services.respawn_service != null:
			game_services.respawn_service.bind_from_services(game_services)

	_configure_content_systems()

	if area_transition_manager != null:
		_apply_content_starting_area()
		area_transition_manager.initialize(self, game_services)

	if save_manager != null:
		save_manager.auto_load_on_ready = false
		save_manager.bind_game(
			self,
			area_transition_manager.get_current_area(),
			area_transition_manager,
			game_services
		)
		print(
			"[Game] Save directory: %s | Slot path: %s"
			% [save_manager.get_resolved_save_directory(), save_manager.get_resolved_slot_save_path()]
		)
		print("[Game] Product shell active. F8 save / F9 load / Pause: Esc or Start.")

	_bind_narrative_systems()


func _activate_content_manifest() -> void:
	var manifest: ContentManifest = null
	if GameBootState != null:
		manifest = GameBootState.get_active_manifest()
	if manifest == null:
		manifest = ContentRegistry.load_manifest(ContentManifest.PATH_BETA_DEMO)
	if manifest != null:
		ContentRegistry.activate(manifest)
		print("[Game] Content manifest: %s" % String(manifest.manifest_id))


func _configure_content_systems() -> void:
	var registry := ContentRegistry.get_active()
	if registry == null:
		return

	if game_services != null and game_services.dialogue_controller != null:
		game_services.dialogue_controller.dialogue_data_path = registry.get_dialogue_data_path()
		game_services.dialogue_controller.reload_dialogue_data()

	var director := get_node_or_null("NarrativeDirector") as NarrativeDirector
	if director != null:
		director.configure(registry.get_starting_chapter())


func _apply_content_starting_area() -> void:
	var registry := ContentRegistry.get_active()
	if registry == null or area_transition_manager == null:
		return

	var starting_scene := registry.get_starting_area_scene()
	if starting_scene != null:
		area_transition_manager.initial_area_scene = starting_scene
		area_transition_manager.initial_spawn_id = registry.get_starting_spawn_id()


func _debug_panic_unlock() -> void:
	if gameplay_lock_manager != null:
		gameplay_lock_manager.debug_force_release_all("panic")

	if game_services != null and game_services.dialogue_controller != null:
		game_services.dialogue_controller.force_reset()
		return

	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node is DialogueController:
			(node as DialogueController).force_reset()
			return


func _bind_narrative_systems() -> void:
	var director := get_node_or_null("NarrativeDirector")
	var objective_hud := get_node_or_null("ObjectiveHud") as ObjectiveHud
	if director != null and objective_hud != null and director.has_method("bind_objective_hud"):
		director.call("bind_objective_hud", objective_hud)

	var finale := get_node_or_null("VerticalSliceController/ChapterZeroFinale") as ChapterZeroFinale
	var overlay := get_node_or_null("VerticalSliceController/CompletionOverlay") as CanvasLayer
	if finale != null and overlay != null:
		var title := overlay.get_node_or_null("Panel/VBox/Title") as Label
		var body := overlay.get_node_or_null("Panel/VBox/Body") as Label
		finale.setup(overlay, title, body)


func _has_duplicate_game_root() -> bool:
	for node in get_tree().get_nodes_in_group(GAME_ROOT_GROUP):
		if node != self:
			return true

	return false
