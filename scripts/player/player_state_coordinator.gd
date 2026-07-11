extends Node
class_name PlayerStateCoordinator

var _player: CharacterBody2D = null


func setup(player: CharacterBody2D) -> void:
	_player = player


func apply_blocked_state() -> void:
	if _player == null:
		return
	_player.set("current_state", PlayerStateTypes.PlayerState.INTERACT)


func update_locomotion(input_direction: float) -> void:
	if _player == null:
		return

	if _player.call("_is_dead"):
		_player.set("current_state", PlayerStateTypes.PlayerState.DEAD)
		return

	if not _player.is_on_floor():
		var state := (
			PlayerStateTypes.PlayerState.JUMP
			if _player.velocity.y < 0.0
			else PlayerStateTypes.PlayerState.FALL
		)
		_player.set("current_state", state)
		return

	if (
		absf(_player.velocity.x) > PlayerStateTypes.RUN_SPEED_THRESHOLD
		or not is_zero_approx(input_direction)
	):
		_player.set("current_state", PlayerStateTypes.PlayerState.RUN)
	else:
		_player.set("current_state", PlayerStateTypes.PlayerState.IDLE)


func apply_post_movement_state(input_direction: float) -> void:
	if _player == null:
		return

	if _player.call("_is_charging_brand_breaker"):
		_player.set("current_state", PlayerStateTypes.PlayerState.ATTACK)
	elif _player.call("_is_taunting"):
		_player.set("current_state", PlayerStateTypes.PlayerState.TAUNT)
	elif _player.call("_is_countering"):
		_player.set("current_state", PlayerStateTypes.PlayerState.COUNTER)
	elif _player.call("_is_dodging"):
		_player.set("current_state", PlayerStateTypes.PlayerState.DODGE)
	elif not _player.call("_is_attacking"):
		update_locomotion(input_direction)
	else:
		_player.set("current_state", PlayerStateTypes.PlayerState.ATTACK)
