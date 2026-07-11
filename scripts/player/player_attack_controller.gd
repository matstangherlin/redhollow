extends Node
class_name PlayerAttackController

signal combo_completed
signal counter_attack_finished
signal locomotion_refresh_requested
signal brand_breaker_attack_finished

const NO_BUFFERED_ATTACK := -1

var current_attack: Resource
var attack_phase: int = PlayerStateTypes.AttackPhase.NONE
var attack_phase_time_remaining: float = 0.0
var attack_elapsed_time: float = 0.0
var current_combo_index: int = 0
var buffered_combo_attack_index: int = NO_BUFFERED_ATTACK
var combo_input_buffer_time_remaining: float = 0.0
var combo_reset_time_remaining: float = 0.0
var last_hit_target_name: String = "none"
var is_executing_counter_attack: bool = false

var _player: CharacterBody2D = null
var _hitbox: Area2D = null
var _is_brand_breaker_attack: bool = false


func setup(player: CharacterBody2D, hitbox: Area2D) -> void:
	_player = player
	_hitbox = hitbox


func is_attacking() -> bool:
	return current_attack != null


func can_cancel_attack() -> bool:
	return _is_in_combo_window()


func handle_attack_input(attack_just_pressed: bool) -> void:
	if not attack_just_pressed or not _can_accept_attack_input():
		return

	if current_attack == null:
		if _can_start_combo():
			_clear_combo_buffer()
			start_attack_at_index(0)
		return

	if _can_buffer_next_combo_attack():
		buffer_next_combo_attack()


func update_combo_timers(delta: float) -> void:
	if _has_buffered_combo_input():
		combo_input_buffer_time_remaining = maxf(combo_input_buffer_time_remaining - delta, 0.0)
		if combo_input_buffer_time_remaining <= 0.0:
			_clear_combo_buffer()

	if current_attack != null or combo_reset_time_remaining <= 0.0:
		return

	combo_reset_time_remaining = maxf(combo_reset_time_remaining - delta, 0.0)
	if combo_reset_time_remaining <= 0.0:
		current_combo_index = 0
		last_hit_target_name = "none"


func update_attack_timing(delta: float) -> void:
	if current_attack == null:
		return

	attack_elapsed_time += delta
	attack_phase_time_remaining -= delta

	while current_attack != null and attack_phase_time_remaining <= 0.0:
		var overflow := -attack_phase_time_remaining
		_advance_attack_phase()
		if current_attack == null:
			return
		attack_phase_time_remaining -= overflow


func start_attack_at_index(attack_index: int) -> void:
	var attack_data := _get_combo_attack(attack_index)
	if attack_data == null:
		return

	current_combo_index = attack_index
	combo_reset_time_remaining = 0.0
	_start_attack(attack_data)


func buffer_next_combo_attack() -> void:
	buffered_combo_attack_index = current_combo_index + 1
	combo_input_buffer_time_remaining = float(_player.get("attack_input_buffer_time"))


func clear_combo_buffer() -> void:
	_clear_combo_buffer()


func begin_counter_attack(counter_attack: Resource) -> void:
	if counter_attack == null:
		counter_attack_finished.emit()
		return

	is_executing_counter_attack = true
	_start_attack(counter_attack)


func start_brand_breaker_attack(attack_data: Resource) -> void:
	_is_brand_breaker_attack = true
	_clear_combo_buffer()
	_start_attack(attack_data)


func cancel_brand_breaker_attack() -> void:
	if not _is_brand_breaker_attack and current_attack == null:
		return

	_is_brand_breaker_attack = false
	_deactivate_hitbox()
	current_attack = null
	attack_phase = PlayerStateTypes.AttackPhase.NONE
	attack_phase_time_remaining = 0.0
	attack_elapsed_time = 0.0


func cancel_active_attack_for_overlay() -> void:
	if not is_attacking():
		return

	_is_brand_breaker_attack = false
	_deactivate_hitbox()
	current_attack = null
	attack_phase = PlayerStateTypes.AttackPhase.NONE
	attack_phase_time_remaining = 0.0
	attack_elapsed_time = 0.0
	_clear_combo_buffer()


func cancel_attack_sequence(next_state: int = PlayerStateTypes.PlayerState.IDLE) -> void:
	_is_brand_breaker_attack = false
	_deactivate_hitbox()
	current_attack = null
	attack_phase = PlayerStateTypes.AttackPhase.NONE
	attack_phase_time_remaining = 0.0
	attack_elapsed_time = 0.0
	current_combo_index = 0
	combo_reset_time_remaining = 0.0
	last_hit_target_name = "none"
	_clear_combo_buffer()
	_player.set("current_state", next_state)


func cancel_counter_attack_portion() -> void:
	if is_executing_counter_attack:
		_deactivate_hitbox()
		current_attack = null
		attack_phase = PlayerStateTypes.AttackPhase.NONE
		attack_phase_time_remaining = 0.0
		attack_elapsed_time = 0.0
		is_executing_counter_attack = false


func interrupt_offensive(next_state: int = PlayerStateTypes.PlayerState.HURT) -> void:
	cancel_attack_sequence(next_state)


func on_hit_landed(target: Node, _attack_data: Resource) -> void:
	last_hit_target_name = target.name


func get_attack_display_name(attack_data: Resource) -> String:
	if attack_data == null:
		return "none"

	var display_name := String(attack_data.get("display_name"))
	if not display_name.is_empty():
		return display_name

	return String(attack_data.get("attack_id"))


func get_buffered_attack_display_name() -> String:
	if not _has_buffered_combo_input():
		return "none"

	return get_attack_display_name(_get_combo_attack(buffered_combo_attack_index))


func get_attack_phase_name(phase: int) -> String:
	match phase:
		PlayerStateTypes.AttackPhase.STARTUP:
			return "startup"
		PlayerStateTypes.AttackPhase.ACTIVE:
			return "active"
		PlayerStateTypes.AttackPhase.RECOVERY:
			return "recovery"
		_:
			return "none"


func _start_attack(attack_data: Resource) -> void:
	current_attack = attack_data
	attack_elapsed_time = 0.0
	attack_phase = PlayerStateTypes.AttackPhase.STARTUP
	attack_phase_time_remaining = maxf(float(current_attack.get("startup_time")), 0.0)
	_player.set("current_state", PlayerStateTypes.PlayerState.ATTACK)
	last_hit_target_name = "none"
	_hitbox.call("clear_hit_targets")
	_deactivate_hitbox()

	if is_executing_counter_attack:
		_player.set("current_state", PlayerStateTypes.PlayerState.COUNTER)
	elif _is_brand_breaker_attack:
		_player.set("current_state", PlayerStateTypes.PlayerState.ATTACK)

	if attack_phase_time_remaining <= 0.0:
		_advance_attack_phase()


func _advance_attack_phase() -> void:
	match attack_phase:
		PlayerStateTypes.AttackPhase.STARTUP:
			attack_phase = PlayerStateTypes.AttackPhase.ACTIVE
			attack_phase_time_remaining = maxf(float(current_attack.get("active_time")), 0.0)
			_hitbox.call(
				"activate",
				current_attack,
				_player,
				int(_player.get("facing_direction"))
			)
		PlayerStateTypes.AttackPhase.ACTIVE:
			_deactivate_hitbox()
			attack_phase = PlayerStateTypes.AttackPhase.RECOVERY
			attack_phase_time_remaining = maxf(float(current_attack.get("recovery_time")), 0.0)
		PlayerStateTypes.AttackPhase.RECOVERY:
			_finish_attack()
		_:
			_finish_attack()


func _finish_attack() -> void:
	var next_attack_index := buffered_combo_attack_index
	var combo_attacks: Array = _player.get("combo_attacks")
	var finished_combo_index := current_combo_index
	var was_combo_finisher := finished_combo_index == combo_attacks.size() - 1
	_deactivate_hitbox()
	current_attack = null
	attack_phase = PlayerStateTypes.AttackPhase.NONE
	attack_phase_time_remaining = 0.0
	attack_elapsed_time = 0.0

	if is_executing_counter_attack:
		is_executing_counter_attack = false
		counter_attack_finished.emit()
		return

	if _is_brand_breaker_attack:
		_is_brand_breaker_attack = false
		brand_breaker_attack_finished.emit()
		locomotion_refresh_requested.emit()
		return

	if was_combo_finisher:
		combo_completed.emit()

	if _can_start_buffered_attack(next_attack_index):
		_clear_combo_buffer()
		start_attack_at_index(next_attack_index)
		return

	_clear_combo_buffer()
	combo_reset_time_remaining = float(_player.get("combo_reset_time"))
	locomotion_refresh_requested.emit()


func _can_accept_attack_input() -> bool:
	return bool(_player.call("_can_accept_attack_input"))


func _can_start_combo() -> bool:
	return _player.is_on_floor() and _get_combo_attack(0) != null


func _can_buffer_next_combo_attack() -> bool:
	var combo_attacks: Array = _player.get("combo_attacks")
	var next_attack_index := current_combo_index + 1
	return next_attack_index < combo_attacks.size() and _get_combo_attack(next_attack_index) != null and _is_in_combo_window()


func _has_buffered_combo_input() -> bool:
	return buffered_combo_attack_index != NO_BUFFERED_ATTACK and combo_input_buffer_time_remaining > 0.0


func _clear_combo_buffer() -> void:
	buffered_combo_attack_index = NO_BUFFERED_ATTACK
	combo_input_buffer_time_remaining = 0.0


func _is_in_combo_window() -> bool:
	if current_attack == null or not current_attack.has_method("has_cancel_window") or not bool(current_attack.call("has_cancel_window")):
		return false

	return attack_elapsed_time >= float(current_attack.get("cancel_window_start")) and attack_elapsed_time <= float(current_attack.get("cancel_window_end"))


func _get_combo_attack(attack_index: int) -> Resource:
	var combo_attacks: Array = _player.get("combo_attacks")
	if attack_index < 0 or attack_index >= combo_attacks.size():
		return null

	return combo_attacks[attack_index]


func _can_start_buffered_attack(attack_index: int) -> bool:
	var combo_attacks: Array = _player.get("combo_attacks")
	return (
		attack_index != NO_BUFFERED_ATTACK
		and combo_input_buffer_time_remaining > 0.0
		and attack_index == current_combo_index + 1
		and attack_index < combo_attacks.size()
		and _player.is_on_floor()
		and _can_accept_attack_input()
	)


func _deactivate_hitbox() -> void:
	if _hitbox != null:
		_hitbox.call("deactivate")
