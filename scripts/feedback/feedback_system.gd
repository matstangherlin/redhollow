extends Node
class_name FeedbackSystem

## Runtime bundle for beta audio + VFX feedback infrastructure.

@onready var audio_manager: AudioManager = $AudioManager
@onready var combat_vfx_spawner: CombatVfxSpawner = $CombatVfxSpawner
@onready var ambient_audio_controller: AmbientAudioController = $AmbientAudioController
@onready var combat_feedback_director: CombatFeedbackDirector = $CombatFeedbackDirector


func bind_services(services: GameServices, camera_controller: CameraController) -> void:
	combat_feedback_director.setup(
		audio_manager,
		combat_vfx_spawner,
		camera_controller,
		ambient_audio_controller
	)

	if services != null and services.player != null:
		combat_feedback_director.bind_player(services.player)
		combat_feedback_director.bind_game_services(services)

	if services != null and services.area_transition_manager != null:
		ambient_audio_controller.apply_area_profile(
			services.area_transition_manager.get_current_area_id()
		)
