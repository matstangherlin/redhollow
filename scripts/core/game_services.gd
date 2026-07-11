extends Node
class_name GameServices

const SERVICES_GROUP := "game_services"

var world_host: Node2D = null
var player: CharacterBody2D = null
var camera_controller: CameraController = null
var save_manager: SaveManager = null
var area_transition_manager: AreaTransitionManager = null
var style_manager: StyleManager = null
var red_brand_director: Node = null
var dialogue_controller: DialogueController = null
var progression: ProgressionComponent = null
var barrier_registry: BarrierRegistry = null
var gameplay_lock_manager: GameplayLockManager = null
var boss_health_hud: BossHealthHud = null
var feedback_system: FeedbackSystem = null
var audio_manager: AudioManager = null
var combat_feedback_director: CombatFeedbackDirector = null


func _ready() -> void:
	add_to_group(SERVICES_GROUP)


func bind_from_shell(game_root: Node) -> void:
	if game_root == null:
		return

	world_host = game_root.get_node_or_null("%WorldHost") as Node2D
	player = game_root.get_node_or_null("%Player") as CharacterBody2D
	camera_controller = game_root.get_node_or_null("CameraController") as CameraController
	save_manager = game_root.get_node_or_null("%SaveManager") as SaveManager
	area_transition_manager = game_root.get_node_or_null("%AreaTransitionManager") as AreaTransitionManager
	style_manager = game_root.get_node_or_null("StyleManager") as StyleManager
	red_brand_director = game_root.get_node_or_null("RedBrandDirector")
	dialogue_controller = game_root.get_node_or_null("DialogueSystem") as DialogueController
	boss_health_hud = game_root.get_node_or_null("BossHealthHud") as BossHealthHud
	gameplay_lock_manager = game_root.get_node_or_null("GameplayLockManager") as GameplayLockManager
	feedback_system = game_root.get_node_or_null("FeedbackSystem") as FeedbackSystem

	if feedback_system != null:
		audio_manager = feedback_system.audio_manager
		combat_feedback_director = feedback_system.combat_feedback_director
		feedback_system.bind_services(self, camera_controller)

	var progression_system: Node = game_root.get_node_or_null("ProgressionSystem")
	if progression_system != null:
		progression = progression_system.get_node_or_null("ProgressionComponent") as ProgressionComponent
		barrier_registry = progression_system.get_node_or_null("BarrierRegistry") as BarrierRegistry

	_bind_persistent_combat()


func on_area_unloaded(area: AreaRoot) -> void:
	if style_manager != null:
		style_manager.on_area_unloaded(area)


func on_area_loaded(area: AreaRoot) -> void:
	if save_manager != null:
		save_manager.rebind_current_area(area)

	if style_manager != null:
		style_manager.on_area_loaded(area)

	if red_brand_director != null and red_brand_director.has_method("on_area_loaded"):
		red_brand_director.call("on_area_loaded", area)

	if area != null:
		area.bind_runtime_services(self)


func _bind_persistent_combat() -> void:
	var style_hud: StyleHud = null
	if style_manager != null and style_manager.has_node("StyleHud"):
		style_hud = style_manager.get_node("StyleHud") as StyleHud

	if style_manager != null:
		style_manager.bind_style_hud(style_hud)
		if player != null:
			style_manager.bind_player(player)

	if red_brand_director != null:
		if player != null and red_brand_director.has_method("bind_player"):
			red_brand_director.call("bind_player", player)
		if style_hud != null and red_brand_director.has_method("bind_style_hud"):
			red_brand_director.call("bind_style_hud", style_hud)
