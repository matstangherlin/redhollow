extends Node
class_name PlayerDefenseController

signal dodge_started
signal dodge_finished
signal counter_success(attack_data: Resource, attacker: Node)
signal counter_resolved(result: String)
signal screen_shake_requested(intensity: float, duration: float)
signal hitstop_requested(duration: float)
signal locomotion_refresh_requested

var dodge_phase: int = PlayerStateTypes.DodgePhase.NONE
var dodge_phase_time_remaining: float = 0.0
var dodge_elapsed_time: float = 0.0
var dodge_direction: int = 1
var dodge_cooldown_time_remaining: float = 0.0
var dodge_invulnerability_applied: bool = false
var was_invulnerable_before_dodge: bool = false

var counter_phase: int = PlayerStateTypes.CounterPhase.NONE
var counter_phase_time_remaining: float = 0.0
var counter_elapsed_time: float = 0.0
var counter_cooldown_time_remaining: float = 0.0
var last_counter_result: String = "none"
var last_incoming_attack_name: String = "none"
var last_incoming_counterable: bool = false

var _player: CharacterBody2D = null
var _input: PlayerInputController = null
var _attack: PlayerAttackController = null
var _presentation: PlayerPresentationController = null
var _health: Node = null


func setup(
	player: CharacterBody2D,
	input_controller: PlayerInputController,
	attack_controller: PlayerAttackController,
	presentation: PlayerPresentationController,
	health_component: Node,
	hurtbox: Area2D
) -> void:
	_player = player
	_input = input_controller
	_attack = attack_controller
	_presentation = presentation
	_health = health_component

	var hit_countered_callable := Callable(self, "_on_hit_countered")
	if hurtbox.has_signal("hit_countered") and not hurtbox.is_connected("hit_countered", hit_countered_callable):
		hurtbox.connect("hit_countered", hit_countered_callable)


func handle_dodge_input() -> void:
	if _input.dodge_just_pressed and _can_start_ground_dodge():
		start_ground_dodge()


func handle_counter_input() -> void:
	if _input.counter_just_pressed and _can_start_counter():
		start_counter()


func update_dodge_cooldown(delta: float) -> void:
	if dodge_cooldown_time_remaining <= 0.0:
		return
	dodge_cooldown_time_remaining = maxf(dodge_cooldown_time_remaining - delta, 0.0)


func update_counter_cooldown(delta: float) -> void:
	if counter_cooldown_time_remaining <= 0.0:
		return
	counter_cooldown_time_remaining = maxf(counter_cooldown_time_remaining - delta, 0.0)


func update_dodge_timing(delta: float) -> void:
	if dodge_phase == PlayerStateTypes.DodgePhase.NONE:
		return

	dodge_elapsed_time += delta
	dodge_phase_time_remaining -= delta
	update_dodge_invulnerability()

	while dodge_phase != PlayerStateTypes.DodgePhase.NONE and dodge_phase_time_remaining <= 0.0:
		var overflow := -dodge_phase_time_remaining
		_advance_dodge_phase()
		if dodge_phase == PlayerStateTypes.DodgePhase.NONE:
			return
		dodge_phase_time_remaining -= overflow
		update_dodge_invulnerability()


func update_counter_timing(delta: float) -> void:
	if counter_phase == PlayerStateTypes.CounterPhase.NONE or counter_phase == PlayerStateTypes.CounterPhase.COUNTER_ATTACK:
		return

	counter_elapsed_time += delta
	counter_phase_time_remaining -= delta

	while (
		counter_phase != PlayerStateTypes.CounterPhase.NONE
		and counter_phase != PlayerStateTypes.CounterPhase.COUNTER_ATTACK
		and counter_phase_time_remaining <= 0.0
	):
		var overflow := -counter_phase_time_remaining
		_advance_counter_phase()
		if counter_phase == PlayerStateTypes.CounterPhase.NONE or counter_phase == PlayerStateTypes.CounterPhase.COUNTER_ATTACK:
			return
		counter_phase_time_remaining -= overflow


func try_counter_hit(attack_data: Resource, _hitbox: Area2D, attacker: Node) -> bool:
	last_incoming_attack_name = _attack.get_attack_display_name(attack_data)
	last_incoming_counterable = attack_data != null and bool(attack_data.get("counterable"))

	if counter_phase != PlayerStateTypes.CounterPhase.WINDOW:
		last_counter_result = "miss_window"
		return false

	if attack_data == null or not last_incoming_counterable:
		last_counter_result = "not_counterable"
		return false

	last_counter_result = "success"
	if attacker is Node2D:
		var direction := signi(int((attacker as Node2D).global_position.x - _player.global_position.x))
		if direction != 0:
			_player.call("set_facing_direction", direction)

	return true


func start_ground_dodge() -> void:
	var input_direction := _input.move_axis
	var facing_direction := int(_player.get("facing_direction"))
	dodge_direction = facing_direction if is_zero_approx(input_direction) else (1 if input_direction > 0.0 else -1)
	_player.call("set_facing_direction", dodge_direction)
	dodge_phase = PlayerStateTypes.DodgePhase.STARTUP
	dodge_phase_time_remaining = maxf(float(_player.get("dodge_startup")), 0.0)
	dodge_elapsed_time = 0.0
	was_invulnerable_before_dodge = _is_health_invulnerable()
	dodge_invulnerability_applied = false
	_player.set("current_state", PlayerStateTypes.PlayerState.DODGE)
	dodge_started.emit()
	_attack.clear_combo_buffer()
	update_dodge_invulnerability()
	_presentation.refresh_from_player(_player)

	if dodge_phase_time_remaining <= 0.0:
		_advance_dodge_phase()


func start_counter() -> void:
	counter_phase = PlayerStateTypes.CounterPhase.STARTUP
	counter_phase_time_remaining = maxf(float(_player.get("counter_startup")), 0.0)
	counter_elapsed_time = 0.0
	last_counter_result = "pending"
	last_incoming_attack_name = "none"
	last_incoming_counterable = false
	_player.set("current_state", PlayerStateTypes.PlayerState.COUNTER)
	_attack.clear_combo_buffer()
	_presentation.refresh_from_player(_player)

	if counter_phase_time_remaining <= 0.0:
		_advance_counter_phase()


func cancel_dodge(next_state: int = PlayerStateTypes.PlayerState.IDLE) -> void:
	dodge_phase = PlayerStateTypes.DodgePhase.NONE
	dodge_phase_time_remaining = 0.0
	dodge_elapsed_time = 0.0
	_restore_dodge_invulnerability()
	_presentation.refresh_from_player(_player)
	_player.set("current_state", next_state)


func cancel_counter(next_state: int = PlayerStateTypes.PlayerState.IDLE) -> void:
	if counter_phase == PlayerStateTypes.CounterPhase.NONE and not _attack.is_executing_counter_attack:
		return

	if _attack.is_executing_counter_attack:
		_attack.cancel_counter_attack_portion()

	counter_phase = PlayerStateTypes.CounterPhase.NONE
	counter_phase_time_remaining = 0.0
	counter_elapsed_time = 0.0
	_presentation.refresh_from_player(_player)
	_player.set("current_state", next_state)


func on_counter_attack_finished() -> void:
	_finish_counter()


func on_player_damaged_during_counter_window() -> void:
	if is_in_counter_window() and not last_incoming_counterable:
		counter_resolved.emit("not_counterable")


func is_dodging() -> bool:
	return dodge_phase != PlayerStateTypes.DodgePhase.NONE


func is_countering() -> bool:
	return counter_phase != PlayerStateTypes.CounterPhase.NONE


func is_in_counter_window() -> bool:
	return counter_phase == PlayerStateTypes.CounterPhase.WINDOW


func is_executing_counter_attack() -> bool:
	return _attack.is_executing_counter_attack


func update_dodge_invulnerability() -> void:
	var should_be_invulnerable := _is_dodge_invulnerability_window_active()
	if should_be_invulnerable:
		_set_health_invulnerable(true)
		dodge_invulnerability_applied = true
	elif dodge_invulnerability_applied:
		_restore_dodge_invulnerability()


func get_dodge_recovery_time_remaining() -> float:
	return dodge_phase_time_remaining if dodge_phase == PlayerStateTypes.DodgePhase.RECOVERY else 0.0


func get_counter_recovery_time_remaining() -> float:
	return counter_phase_time_remaining if counter_phase == PlayerStateTypes.CounterPhase.RECOVERY else 0.0


func get_dodge_phase_name(phase: int) -> String:
	match phase:
		PlayerStateTypes.DodgePhase.STARTUP:
			return "startup"
		PlayerStateTypes.DodgePhase.ACTIVE:
			return "active"
		PlayerStateTypes.DodgePhase.RECOVERY:
			return "recovery"
		_:
			return "none"


func get_counter_phase_name(phase: int) -> String:
	match phase:
		PlayerStateTypes.CounterPhase.STARTUP:
			return "startup"
		PlayerStateTypes.CounterPhase.WINDOW:
			return "window"
		PlayerStateTypes.CounterPhase.RECOVERY:
			return "recovery"
		PlayerStateTypes.CounterPhase.COUNTER_ATTACK:
			return "counter_attack"
		_:
			return "none"


func _can_start_ground_dodge() -> bool:
	if not _player.is_on_floor() or _player.call("_is_dead") or _attack.is_attacking():
		return false
	if is_countering() or _player.call("_is_taunting") or _player.call("_is_charging_brand_breaker"):
		return false
	if dodge_phase != PlayerStateTypes.DodgePhase.NONE or dodge_cooldown_time_remaining > 0.0:
		return false
	return _can_dodge_cancel_current_state()


func _can_dodge_cancel_current_state() -> bool:
	var current_state: int = int(_player.get("current_state"))
	match current_state:
		PlayerStateTypes.PlayerState.IDLE, PlayerStateTypes.PlayerState.RUN, PlayerStateTypes.PlayerState.FALL:
			return true
		_:
			return false


func _can_start_counter() -> bool:
	if not _player.is_on_floor() or _player.call("_is_dead") or _attack.is_attacking():
		return false
	if is_dodging() or is_countering() or _player.call("_is_taunting") or _player.call("_is_charging_brand_breaker"):
		return false
	if counter_cooldown_time_remaining > 0.0:
		return false

	var current_state: int = int(_player.get("current_state"))
	match current_state:
		PlayerStateTypes.PlayerState.HURT, PlayerStateTypes.PlayerState.DEAD, PlayerStateTypes.PlayerState.INTERACT, PlayerStateTypes.PlayerState.COUNTER:
			return false
		_:
			return true


func _advance_dodge_phase() -> void:
	match dodge_phase:
		PlayerStateTypes.DodgePhase.STARTUP:
			dodge_phase = PlayerStateTypes.DodgePhase.ACTIVE
			dodge_phase_time_remaining = maxf(float(_player.get("dodge_duration")), 0.0)
			_player.velocity.x = float(_player.get("dodge_speed")) * float(dodge_direction)
		PlayerStateTypes.DodgePhase.ACTIVE:
			dodge_phase = PlayerStateTypes.DodgePhase.RECOVERY
			dodge_phase_time_remaining = maxf(float(_player.get("dodge_recovery")), 0.0)
		PlayerStateTypes.DodgePhase.RECOVERY:
			_finish_dodge()
		_:
			_finish_dodge()


func _finish_dodge() -> void:
	dodge_phase = PlayerStateTypes.DodgePhase.NONE
	dodge_phase_time_remaining = 0.0
	dodge_elapsed_time = 0.0
	_restore_dodge_invulnerability()
	dodge_cooldown_time_remaining = maxf(float(_player.get("dodge_cooldown")), 0.0)
	dodge_finished.emit()
	_presentation.refresh_from_player(_player)
	locomotion_refresh_requested.emit()


func _advance_counter_phase() -> void:
	match counter_phase:
		PlayerStateTypes.CounterPhase.STARTUP:
			counter_phase = PlayerStateTypes.CounterPhase.WINDOW
			counter_phase_time_remaining = maxf(float(_player.get("counter_window")), 0.0)
		PlayerStateTypes.CounterPhase.WINDOW:
			if last_counter_result != "success":
				last_counter_result = "miss"
				counter_resolved.emit(last_counter_result)
			counter_phase = PlayerStateTypes.CounterPhase.RECOVERY
			counter_phase_time_remaining = maxf(float(_player.get("counter_recovery")), 0.0)
		PlayerStateTypes.CounterPhase.RECOVERY:
			_finish_counter()
		_:
			_finish_counter()

	_presentation.refresh_from_player(_player)


func _finish_counter() -> void:
	counter_phase = PlayerStateTypes.CounterPhase.NONE
	counter_phase_time_remaining = 0.0
	counter_elapsed_time = 0.0
	counter_cooldown_time_remaining = maxf(float(_player.get("counter_cooldown")), 0.0)
	_presentation.refresh_from_player(_player)
	locomotion_refresh_requested.emit()


func _begin_counter_attack() -> void:
	counter_phase = PlayerStateTypes.CounterPhase.COUNTER_ATTACK
	_presentation.refresh_from_player(_player)
	_attack.begin_counter_attack(_player.get("counter_attack"))


func _on_hit_countered(attack_data: Resource, _hitbox: Area2D, attacker: Node) -> void:
	counter_success.emit(attack_data, attacker)
	var hitstop_duration := float(_player.get("counter_hitstop_duration"))
	if hitstop_duration > 0.0:
		hitstop_requested.emit(hitstop_duration)
	screen_shake_requested.emit(
		float(_player.get("counter_shake_intensity")),
		float(_player.get("counter_shake_duration"))
	)
	_begin_counter_attack()


func _is_dodge_invulnerability_window_active() -> bool:
	var invulnerability_start := float(_player.get("invulnerability_start"))
	var invulnerability_end := float(_player.get("invulnerability_end"))
	return (
		dodge_phase != PlayerStateTypes.DodgePhase.NONE
		and invulnerability_end > invulnerability_start
		and dodge_elapsed_time >= invulnerability_start
		and dodge_elapsed_time <= invulnerability_end
	)


func _restore_dodge_invulnerability() -> void:
	if not dodge_invulnerability_applied:
		return
	_set_health_invulnerable(was_invulnerable_before_dodge)
	dodge_invulnerability_applied = false


func _set_health_invulnerable(is_invulnerable: bool) -> void:
	if _health != null:
		_health.set("invulnerable", is_invulnerable)


func _is_health_invulnerable() -> bool:
	return _health != null and bool(_health.get("invulnerable"))
