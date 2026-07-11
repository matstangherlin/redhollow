extends Node
class_name PlayerMovementController

## Locomotion physics for Calder. Does not read Input Map or handle combat timing.

var coyote_time_remaining: float = 0.0

var _player: CharacterBody2D = null
var _presentation: PlayerPresentationController = null


func setup(player: CharacterBody2D, presentation: PlayerPresentationController) -> void:
	_player = player
	_presentation = presentation


func configure_floor_snap() -> void:
	if _player == null:
		return
	_player.floor_snap_length = float(_player.get("floor_snap_distance"))


func update_coyote_timer(delta: float) -> void:
	if _player == null:
		return

	if _player.is_on_floor():
		coyote_time_remaining = float(_player.get("coyote_time"))
	else:
		coyote_time_remaining = maxf(coyote_time_remaining - delta, 0.0)


func refresh_ground_state() -> void:
	if _player != null and _player.is_on_floor():
		coyote_time_remaining = float(_player.get("coyote_time"))


func apply_horizontal_movement(input_direction: float, delta: float) -> void:
	if _player == null:
		return

	if not is_zero_approx(input_direction):
		set_facing_from_input(input_direction)

	var max_run_speed := float(_player.get("max_run_speed"))
	var target_speed := input_direction * max_run_speed
	var acceleration := _get_acceleration_for(input_direction)
	_player.velocity.x = move_toward(_player.velocity.x, target_speed, acceleration * delta)


func apply_attack_movement(delta: float) -> void:
	_apply_horizontal_deceleration(delta, PlayerStateTypes.ATTACK_MOVEMENT_DECELERATION_SCALE)


func apply_dodge_movement(delta: float) -> void:
	if _player == null:
		return

	var dodge_phase: int = int(_player.get("dodge_phase"))
	var ground_deceleration := float(_player.get("ground_deceleration"))
	var dodge_speed := float(_player.get("dodge_speed"))
	var dodge_direction := int(_player.get("dodge_direction"))

	match dodge_phase:
		PlayerStateTypes.DodgePhase.STARTUP:
			_player.velocity.x = move_toward(_player.velocity.x, 0.0, ground_deceleration * delta)
		PlayerStateTypes.DodgePhase.ACTIVE:
			_player.velocity.x = dodge_speed * float(dodge_direction)
		PlayerStateTypes.DodgePhase.RECOVERY:
			_player.velocity.x = move_toward(_player.velocity.x, 0.0, ground_deceleration * delta)


func apply_counter_movement(delta: float) -> void:
	_apply_horizontal_deceleration(delta)


func apply_taunt_movement(delta: float) -> void:
	_apply_horizontal_deceleration(delta)


func apply_brand_charge_movement(delta: float) -> void:
	_apply_horizontal_deceleration(delta)


func apply_gravity(delta: float) -> void:
	if _player == null:
		return

	if _player.is_on_floor() and _player.velocity.y > 0.0:
		_player.velocity.y = 0.0
		return

	var gravity := float(_player.get("gravity"))
	var max_fall_speed := float(_player.get("max_fall_speed"))
	_player.velocity.y = minf(_player.velocity.y + gravity * delta, max_fall_speed)


func try_buffered_jump(jump_buffer_remaining: float) -> bool:
	if _player == null:
		return false
	if jump_buffer_remaining <= 0.0 or coyote_time_remaining <= 0.0:
		return false

	_player.velocity.y = float(_player.get("jump_velocity"))
	coyote_time_remaining = 0.0
	return true


func apply_variable_jump_cut(jump_released: bool) -> void:
	if _player == null or not jump_released or _player.velocity.y >= 0.0:
		return

	var jump_cut_multiplier := float(_player.get("jump_cut_multiplier"))
	_player.velocity.y *= jump_cut_multiplier


func apply_input_lock(delta: float) -> void:
	if _player == null:
		return

	_player.velocity = Vector2.ZERO
	apply_gravity(delta)
	move_and_slide()
	refresh_ground_state()


func move_and_slide() -> void:
	if _player != null:
		_player.move_and_slide()


func recover_if_out_of_arena() -> void:
	if _player == null:
		return
	if _player.global_position.y <= float(_player.get("fall_recovery_y")):
		return
	recover_to_spawn()


func recover_to_spawn() -> void:
	if _player == null:
		return

	_player.global_position = _player.call("get_spawn_position")
	_player.velocity = Vector2.ZERO
	reset_jump_timers()
	if _player.has_method("_reset_combat_on_recovery"):
		_player.call("_reset_combat_on_recovery")


func reset_jump_timers() -> void:
	coyote_time_remaining = 0.0
	if _player != null and _player.has_method("_reset_jump_buffer"):
		_player.call("_reset_jump_buffer")


func set_facing_from_input(input_direction: float) -> void:
	if _player == null or is_zero_approx(input_direction):
		return
	set_facing_direction(1 if input_direction > 0.0 else -1)


func set_facing_direction(direction: int) -> void:
	if _player == null or direction == 0:
		return

	_player.set("facing_direction", 1 if direction > 0 else -1)
	if _presentation != null:
		var direction_marker_offset := float(_player.get("direction_marker_offset"))
		_presentation.apply_facing(int(_player.get("facing_direction")), direction_marker_offset)


func _apply_horizontal_deceleration(delta: float, scale: float = 1.0) -> void:
	if _player == null:
		return

	var deceleration := _ground_or_air_deceleration()
	_player.velocity.x = move_toward(_player.velocity.x, 0.0, deceleration * scale * delta)


func _get_acceleration_for(input_direction: float) -> float:
	var ground_acceleration := float(_player.get("ground_acceleration"))
	var ground_deceleration := float(_player.get("ground_deceleration"))
	var air_acceleration := float(_player.get("air_acceleration"))
	var air_deceleration := float(_player.get("air_deceleration"))

	if _player.is_on_floor():
		return ground_acceleration if not is_zero_approx(input_direction) else ground_deceleration

	return air_acceleration if not is_zero_approx(input_direction) else air_deceleration


func _ground_or_air_deceleration() -> float:
	if _player.is_on_floor():
		return float(_player.get("ground_deceleration"))
	return float(_player.get("air_deceleration"))
