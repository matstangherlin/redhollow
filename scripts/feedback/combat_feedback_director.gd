extends Node
class_name CombatFeedbackDirector

## Orchestrates combat audio, VFX, camera shake/zoom from gameplay signals.

const FEEDBACK_DIRECTOR_GROUP := "combat_feedback_director"
const CHECKPOINT_GROUP := "checkpoints"
const RED_BARRIER_GROUP := "red_barrier"

const FOOTSTEP_INTERVAL := 0.28
const FOOTSTEP_MIN_SPEED := 40.0

@export var enable_footsteps: bool = true
@export var enable_ambient_layers: bool = true

var _audio: AudioManager = null
var _vfx: CombatVfxSpawner = null
var _camera: CameraController = null
var _ambient: AmbientAudioController = null
var _player: CharacterBody2D = null
var _player_hitbox: HitboxComponent = null
var _player_hurtbox: HurtboxComponent = null
var _player_health: HealthComponent = null
var _footstep_cooldown: float = 0.0
var _bound_signals: Dictionary = {}


func _ready() -> void:
	add_to_group(FEEDBACK_DIRECTOR_GROUP)
	process_mode = Node.PROCESS_MODE_PAUSABLE


func setup(
	audio_manager: AudioManager,
	vfx_spawner: CombatVfxSpawner,
	camera_controller: CameraController,
	ambient_controller: AmbientAudioController = null
) -> void:
	_audio = audio_manager
	_vfx = vfx_spawner
	_camera = camera_controller
	_ambient = ambient_controller


func bind_player(player: CharacterBody2D) -> void:
	_unbind_player()
	if player == null:
		return

	_player = player
	_player_hitbox = player.get_node_or_null("%HitboxComponent") as HitboxComponent
	_player_hurtbox = player.get_node_or_null("%HurtboxComponent") as HurtboxComponent
	_player_health = player.get_node_or_null("%HealthComponent") as HealthComponent

	if _player_hitbox != null:
		_connect_once(_player_hitbox, &"hit_landed", _on_player_hit_landed)
		_connect_once(_player_hitbox, &"attack_activated", _on_player_attack_activated)

	if _player_hurtbox != null:
		_connect_once(_player_hurtbox, &"hit_received", _on_player_hit_received)
		_connect_once(_player_hurtbox, &"hit_countered", _on_player_hit_countered)

	if _player_health != null:
		_connect_once(_player_health, &"damaged", _on_player_damaged)
		_connect_once(_player_health, &"died", _on_player_died)

	_connect_once(player, &"dodge_started", _on_player_dodge_started)
	_connect_once(player, &"counter_success", _on_player_counter_success)
	_connect_once(player, &"brand_breaker_released", _on_brand_breaker_released)
	_connect_once(player, &"brand_breaker_charge_started", _on_brand_charge_started)


func bind_game_services(services: GameServices) -> void:
	if services == null:
		return

	if services.dialogue_controller != null:
		_connect_once(services.dialogue_controller, &"line_presented", _on_dialogue_line)

	if services.area_transition_manager != null:
		if not services.area_transition_manager.area_changed.is_connected(_on_area_changed):
			services.area_transition_manager.area_changed.connect(_on_area_changed)

	_connect_world_checkpoints()
	_connect_barriers()


func _physics_process(delta: float) -> void:
	_update_footsteps(delta)


func play_ui(event_id: StringName = AudioEventId.UI_NAVIGATE) -> void:
	if _audio != null:
		_audio.play_ui(event_id)


func notify_telegraph(global_position: Vector2, counterable: bool) -> void:
	if _vfx == null:
		return
	var kind := CombatFeedbackResolver.resolve_telegraph_vfx(counterable)
	_vfx.spawn(kind, global_position, 1.0)


func _on_player_hit_landed(target: Node, hurtbox: Area2D, attack_data: Resource) -> void:
	_on_generic_hit_landed(target, hurtbox, attack_data, _player)


func _on_generic_hit_landed(
	target: Node,
	hurtbox: Area2D,
	attack_data: Resource,
	attacker: Node
) -> void:
	var feedback := CombatFeedbackResolver.resolve_hit_feedback(attack_data, attacker, target)
	var impact_position: Vector2 = (
		hurtbox.global_position if hurtbox != null else target.global_position
	)

	_play_hit_feedback(feedback, impact_position, attack_data)

	if target == null or bool(feedback.get("attacker_is_player", false)):
		return

	var health := target.get_node_or_null("%HealthComponent") as HealthComponent
	if health != null:
		var death_position: Vector2 = target.global_position
		_connect_once(health, &"died", func() -> void: _on_enemy_died(death_position))


func _play_hit_feedback(feedback: Dictionary, position: Vector2, attack_data: Resource) -> void:
	if _audio != null:
		var sfx_id: StringName = feedback.get("sfx_id", AudioEventId.IMPACT_FLESH)
		var volume := float(feedback.get("sfx_volume_scale", 1.0))
		var pitch := _resolve_pitch(feedback)
		_audio.play_event(sfx_id, position, volume, pitch)

	if _vfx != null:
		_vfx.spawn_from_feedback(feedback, position)
		if bool(feedback.get("swing_trail_enabled", false)) and not bool(feedback.get("swing_trail_on_active", true)):
			var facing := 1
			if _player != null:
				facing = int(_player.get("facing_direction"))
			_vfx.spawn_swing_trail(position, facing, feedback)

	_apply_camera_feedback(feedback)
	_request_vibration(feedback)


func _on_player_attack_activated(attack_data: Resource, owner_node: Node, facing_direction: int) -> void:
	if _vfx == null or attack_data == null:
		return

	var feedback := CombatFeedbackResolver.resolve_hit_feedback(attack_data, owner_node, null)
	if not bool(feedback.get("swing_trail_enabled", false)):
		return
	if not bool(feedback.get("swing_trail_on_active", true)):
		return

	var trail_position: Vector2 = Vector2.ZERO
	if owner_node is Node2D:
		trail_position = (owner_node as Node2D).global_position
		trail_position += Vector2(float(facing_direction) * 28.0, -12.0)
	_vfx.spawn_swing_trail(trail_position, facing_direction, feedback)


func _resolve_pitch(feedback: Dictionary) -> float:
	if feedback.has("pitch_min") and feedback.has("pitch_max"):
		var pitch_min := float(feedback.get("pitch_min", 1.0))
		var pitch_max := float(feedback.get("pitch_max", 1.0))
		if pitch_max >= pitch_min:
			return randf_range(pitch_min, pitch_max)

	var tier: int = int(feedback.get("tier", CombatFeedbackResolver.ImpactTier.LIGHT))
	var tier_rank := CombatFeedbackResolver.tier_rank(tier as CombatFeedbackResolver.ImpactTier)
	return 1.0 + float(tier_rank) * 0.04


func _request_vibration(feedback: Dictionary) -> void:
	if not FeedbackSettingsAccess.is_vibration_enabled():
		return

	var intensity := float(feedback.get("vibration_intensity", 0.0))
	var duration := float(feedback.get("vibration_duration", 0.0))
	if intensity <= 0.0 or duration <= 0.0:
		return

	if Engine.has_singleton("JavaClassWrapper"):
		return

	if Input.has_method("vibrate_handheld"):
		var duration_ms := int(clampf(duration * 1000.0 * intensity, 8.0, 250.0))
		Input.vibrate_handheld(duration_ms)


func _apply_camera_feedback(feedback: Dictionary) -> void:
	if _camera == null:
		return

	var shake_intensity := float(feedback.get("shake_intensity", 0.0))
	var shake_duration := float(feedback.get("shake_duration", 0.0))
	if shake_intensity > 0.0:
		_camera.request_shake(shake_intensity, shake_duration)

	var zoom_amount := float(feedback.get("zoom_amount", 0.0))
	var zoom_duration := float(feedback.get("zoom_duration", 0.0))
	if zoom_amount > 0.0:
		_camera.request_punch_zoom(zoom_amount, zoom_duration)


func _on_player_hit_received(attack_data: Resource, _hitbox: Area2D, attacker: Node) -> void:
	if _player == null:
		return

	if _vfx != null:
		_vfx.spawn(&"player_hurt", _player.global_position + Vector2(0, -24), 0.8)
	if _audio != null:
		_audio.play_event(AudioEventId.PLAYER_HURT, _player.global_position, 0.9)

	var feedback := CombatFeedbackResolver.resolve_hit_feedback(attack_data, attacker, _player)
	var shake_scale := 0.65
	var scaled_feedback := feedback.duplicate(true)
	scaled_feedback["shake_intensity"] = float(feedback.get("shake_intensity", 0.0)) * shake_scale
	scaled_feedback["zoom_amount"] = float(feedback.get("zoom_amount", 0.0)) * shake_scale
	_apply_camera_feedback(scaled_feedback)


func _on_player_hit_countered(_attack_data: Resource, _hitbox: Area2D, _attacker: Node) -> void:
	if _player == null:
		return
	_play_counter_feedback(_player.global_position)


func _on_player_counter_success(_attack_data: Resource, _attacker: Node) -> void:
	if _player == null:
		return
	_play_counter_feedback(_player.global_position)


func _play_counter_feedback(position: Vector2) -> void:
	var profile := CombatFeedbackProfileLibrary.get_profile(&"calder_counter")
	if profile != null:
		if _audio != null and profile.parry_sfx_id != &"":
			_audio.play_event(profile.parry_sfx_id, position, 1.0, profile.get_random_pitch())
		if _vfx != null and profile.parry_flash_strength > 0.0:
			_vfx.spawn_from_feedback(
				{
					"vfx_kind": &"counter",
					"flash_strength": profile.parry_flash_strength,
					"flash_color": profile.flash_color,
					"impact_color": profile.impact_color,
					"particle_count": 6,
					"particle_lifetime": 0.16,
				},
				position
			)
		_apply_camera_feedback(
			{
				"shake_intensity": profile.parry_shake_intensity,
				"shake_duration": profile.parry_shake_duration,
				"zoom_amount": 0.0,
				"zoom_duration": 0.0,
			}
		)
		return

	if _audio != null:
		_audio.play_event(AudioEventId.COUNTER, position, 1.0)
	if _vfx != null:
		_vfx.spawn(&"counter", position, 1.0)


func _on_player_dodge_started() -> void:
	if _player == null:
		return
	if _audio != null:
		_audio.play_event(AudioEventId.DODGE, _player.global_position, 0.85)
	if _vfx != null:
		_vfx.spawn(&"dodge", _player.global_position, 0.7)


func _on_brand_charge_started() -> void:
	if _player == null or _audio == null:
		return
	_audio.play_event(AudioEventId.RED_BRAND_CHARGE, _player.global_position, 0.75)


func _on_brand_breaker_released(_level: int, _cost: float) -> void:
	if _player == null:
		return
	if _audio != null:
		_audio.play_event(AudioEventId.RED_BRAND_BREAKER, _player.global_position, 1.0)
	if _vfx != null:
		_vfx.spawn(&"red_brand", _player.global_position + Vector2(24, -16), 1.0)


func _on_player_damaged(_amount: float, _source: Node) -> void:
	pass


func _on_player_died() -> void:
	if _player == null:
		return
	if _audio != null:
		_audio.play_event(AudioEventId.PLAYER_DEATH, _player.global_position, 1.0)
	if _vfx != null:
		_vfx.spawn(&"death", _player.global_position, 1.0)


func _on_enemy_died(position: Vector2) -> void:
	if _audio != null:
		_audio.play_event(AudioEventId.ENEMY_DEATH, position, 0.8)


func _on_dialogue_line(_dialogue_id: StringName, _line_index: int, _text: String) -> void:
	if _audio != null:
		_audio.play_event(AudioEventId.DIALOGUE_BLIP, null, 0.65)


func _on_area_changed(area_id: StringName, _area_scene_path: String) -> void:
	if not enable_ambient_layers or _ambient == null:
		return
	_ambient.apply_area_profile(area_id)
	_connect_world_checkpoints()
	_connect_barriers()


func _on_checkpoint_activated(
	_checkpoint_id: StringName,
	checkpoint_position: Vector2,
	_interactor: Node,
	_restore_health: bool,
	_restore_red_brand: bool
) -> void:
	if _audio != null:
		_audio.play_event(AudioEventId.CHECKPOINT, checkpoint_position, 1.0)
	if _vfx != null:
		_vfx.spawn(&"checkpoint", checkpoint_position, 1.0)


func _on_barrier_wrong_hit(
	_attack_data: Resource,
	_hitbox: Area2D,
	_attacker: Node,
	barrier: Node2D
) -> void:
	var position := barrier.global_position if barrier != null else Vector2.ZERO
	if _audio != null:
		_audio.play_event(AudioEventId.BARRIER_HIT, position, 0.9)


func _on_barrier_destroyed(_barrier_id: StringName, barrier: Node2D) -> void:
	var position := barrier.global_position if barrier != null else Vector2.ZERO
	if _audio != null:
		_audio.play_event(AudioEventId.BARRIER_BREAK, position, 1.0)
	if _vfx != null:
		_vfx.spawn(&"barrier", position, 1.0)


func _update_footsteps(delta: float) -> void:
	if not enable_footsteps or _player == null or _audio == null:
		return

	_footstep_cooldown = maxf(_footstep_cooldown - delta, 0.0)
	if _footstep_cooldown > 0.0:
		return

	if not _player.is_on_floor():
		return

	var state: int = int(_player.get("current_state"))
	if state != PlayerStateTypes.PlayerState.RUN:
		return

	if absf(_player.velocity.x) < FOOTSTEP_MIN_SPEED:
		return

	_footstep_cooldown = FOOTSTEP_INTERVAL
	_audio.play_event(AudioEventId.FOOTSTEP, _player.global_position, 0.45, randf_range(0.92, 1.08))


func _connect_world_checkpoints() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for node in tree.get_nodes_in_group(CHECKPOINT_GROUP):
		_connect_once(node, &"checkpoint_activated", _on_checkpoint_activated)


func _connect_barriers() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for node in tree.get_nodes_in_group(RED_BARRIER_GROUP):
		if not (node is Node2D):
			continue
		var barrier := node as Node2D
		var wrong_callable := _on_barrier_wrong_hit.bind(barrier)
		var destroy_callable := _on_barrier_destroyed.bind(barrier)
		_connect_once(node, &"wrong_hit_received", wrong_callable)
		_connect_once(node, &"barrier_destroyed", destroy_callable)


func _connect_once(source: Object, signal_name: StringName, callable: Callable) -> void:
	if source == null or not source.has_signal(signal_name):
		return

	var key := "%d:%s" % [source.get_instance_id(), String(signal_name)]
	if _bound_signals.has(key):
		return

	if not source.is_connected(signal_name, callable):
		source.connect(signal_name, callable)
	_bound_signals[key] = true


func _unbind_player() -> void:
	_player = null
	_player_hitbox = null
	_player_hurtbox = null
	_player_health = null
