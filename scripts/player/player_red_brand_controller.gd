extends Node
class_name PlayerRedBrandController

signal brand_breaker_charge_started
signal brand_breaker_charge_updated(charge_time: float, preview_level: int)
signal brand_breaker_charge_cancelled
signal brand_breaker_released(level: int, cost: float)
signal screen_shake_requested(intensity: float, duration: float)
signal hitstop_requested(duration: float)

var brand_breaker_phase: int = PlayerStateTypes.BrandBreakerPhase.NONE
var brand_charge_time: float = 0.0
var brand_charge_level: int = 0
var brand_breaker_release_cost: float = 0.0
var is_executing_brand_breaker: bool = false

var _player: CharacterBody2D = null
var _red_brand: RedBrandComponent = null
var _attack_controller: PlayerAttackController = null
var _presentation: PlayerPresentationController = null


func setup(
	player: CharacterBody2D,
	red_brand: RedBrandComponent,
	attack_controller: PlayerAttackController,
	presentation: PlayerPresentationController
) -> void:
	_player = player
	_red_brand = red_brand
	_attack_controller = attack_controller
	_presentation = presentation

	if not _attack_controller.brand_breaker_attack_finished.is_connected(_on_brand_breaker_attack_finished):
		_attack_controller.brand_breaker_attack_finished.connect(_on_brand_breaker_attack_finished)


func is_charging_brand_breaker() -> bool:
	return brand_breaker_phase == PlayerStateTypes.BrandBreakerPhase.CHARGING


func get_brand_breaker_state_name() -> String:
	if is_executing_brand_breaker:
		return "attacking"
	if is_charging_brand_breaker():
		return "charging"
	return "none"


func handle_input(_delta: float, special_pressed: bool, special_just_pressed: bool) -> void:
	var hold_mode := SettingsManager == null or SettingsManager.is_red_brand_hold_mode()
	if brand_breaker_phase == PlayerStateTypes.BrandBreakerPhase.CHARGING:
		if hold_mode:
			if not special_pressed:
				release_brand_breaker()
		elif special_just_pressed:
			release_brand_breaker()
		return

	if special_just_pressed and can_start_brand_charge():
		start_brand_charge()


func update_charge(delta: float, special_pressed: bool) -> void:
	if brand_breaker_phase != PlayerStateTypes.BrandBreakerPhase.CHARGING:
		return

	var hold_mode := SettingsManager == null or SettingsManager.is_red_brand_hold_mode()
	if hold_mode and not special_pressed:
		return

	brand_charge_time += delta
	var preview_level := _get_preview_charge_level(brand_charge_time)
	if preview_level != brand_charge_level:
		brand_charge_level = preview_level
		_presentation.update_brand_hand(true, preview_level)

	brand_breaker_charge_updated.emit(brand_charge_time, preview_level)


func can_start_brand_charge() -> bool:
	if _player == null:
		return false

	if _player.call("_is_dead") or is_charging_brand_breaker() or _player.call("_is_dodging") or _player.call("_is_countering") or _player.call("_is_taunting"):
		return false

	if _red_brand == null or _red_brand.config == null:
		return false

	if not _red_brand.can_consume(_red_brand.config.min_energy_to_charge):
		return false

	if not _player.is_on_floor():
		return false

	var current_state: int = int(_player.get("current_state"))
	match current_state:
		PlayerStateTypes.PlayerState.HURT, PlayerStateTypes.PlayerState.DEAD, PlayerStateTypes.PlayerState.INTERACT, PlayerStateTypes.PlayerState.COUNTER, PlayerStateTypes.PlayerState.TAUNT, PlayerStateTypes.PlayerState.DODGE:
			return false
		PlayerStateTypes.PlayerState.ATTACK:
			return _attack_controller.attack_phase == PlayerStateTypes.AttackPhase.RECOVERY
		PlayerStateTypes.PlayerState.IDLE, PlayerStateTypes.PlayerState.RUN, PlayerStateTypes.PlayerState.FALL:
			return true
		_:
			return false


func start_brand_charge() -> void:
	_attack_controller.cancel_active_attack_for_overlay()

	brand_breaker_phase = PlayerStateTypes.BrandBreakerPhase.CHARGING
	brand_charge_time = 0.0
	brand_charge_level = 0
	brand_breaker_release_cost = 0.0
	_player.velocity.x = 0.0
	brand_breaker_charge_started.emit()
	_presentation.update_brand_hand(true, 0)


func release_brand_breaker() -> void:
	if brand_breaker_phase != PlayerStateTypes.BrandBreakerPhase.CHARGING:
		return

	var desired_level := _get_preview_charge_level(brand_charge_time)
	if desired_level <= 0:
		cancel_brand_breaker_charge()
		return

	var resolved := _resolve_brand_breaker_release(desired_level)
	if resolved.is_empty():
		cancel_brand_breaker_charge()
		return

	var level: int = resolved["level"]
	var attack_data: Resource = resolved["attack"]
	var cost: float = resolved["cost"]

	brand_breaker_phase = PlayerStateTypes.BrandBreakerPhase.NONE
	brand_charge_level = level
	brand_breaker_release_cost = cost

	if not _red_brand.consume_energy(cost, &"brand_breaker"):
		cancel_brand_breaker_charge()
		return

	brand_breaker_released.emit(level, cost)
	_execute_brand_breaker_attack(attack_data, level)


func cancel_brand_breaker_charge(next_state: int = PlayerStateTypes.PlayerState.IDLE) -> void:
	if brand_breaker_phase == PlayerStateTypes.BrandBreakerPhase.NONE and not is_executing_brand_breaker:
		return

	var was_charging := brand_breaker_phase == PlayerStateTypes.BrandBreakerPhase.CHARGING
	brand_breaker_phase = PlayerStateTypes.BrandBreakerPhase.NONE
	brand_charge_time = 0.0
	brand_charge_level = 0
	brand_breaker_release_cost = 0.0
	_presentation.update_brand_hand(false, 0)

	if was_charging:
		brand_breaker_charge_cancelled.emit()

	if is_executing_brand_breaker:
		_attack_controller.cancel_brand_breaker_attack()
		is_executing_brand_breaker = false

	_player.set("current_state", next_state)


func on_hit_landed(_target: Node, _attack_data: Resource) -> void:
	if not is_executing_brand_breaker or _red_brand == null or _red_brand.config == null:
		return

	screen_shake_requested.emit(
		_red_brand.config.breaker_shake_intensity,
		_red_brand.config.breaker_shake_duration
	)


func _execute_brand_breaker_attack(attack_data: Resource, level: int) -> void:
	if attack_data == null:
		return

	is_executing_brand_breaker = true
	brand_charge_level = level
	_presentation.update_brand_hand(false, level)
	_attack_controller.start_brand_breaker_attack(attack_data)


func _on_brand_breaker_attack_finished() -> void:
	is_executing_brand_breaker = false
	brand_breaker_release_cost = 0.0
	brand_charge_level = 0
	_presentation.update_brand_hand(false, 0)


func _resolve_brand_breaker_release(desired_level: int) -> Dictionary:
	if desired_level >= 2 and _can_pay_brand_breaker_cost(2):
		return {
			"level": 2,
			"attack": _player.get("red_brand_breaker_level_2"),
			"cost": _get_brand_breaker_cost(2),
		}

	if desired_level >= 1 and _can_pay_brand_breaker_cost(1):
		return {
			"level": 1,
			"attack": _player.get("red_brand_breaker_level_1"),
			"cost": _get_brand_breaker_cost(1),
		}

	return {}


func _can_pay_brand_breaker_cost(level: int) -> bool:
	if _red_brand == null:
		return false

	return _red_brand.can_consume(_get_brand_breaker_cost(level))


func _get_brand_breaker_cost(level: int) -> float:
	var attack_data: Resource = (
		_player.get("red_brand_breaker_level_2") if level >= 2 else _player.get("red_brand_breaker_level_1")
	)
	if attack_data != null and float(attack_data.get("red_brand_cost")) > 0.0:
		return float(attack_data.get("red_brand_cost"))

	if _red_brand == null or _red_brand.config == null:
		return 0.0

	return _red_brand.config.charge_level_2_cost if level >= 2 else _red_brand.config.charge_level_1_cost


func _get_preview_charge_level(charge_time: float) -> int:
	if _red_brand == null or _red_brand.config == null:
		return 0

	var config := _red_brand.config
	if charge_time >= config.charge_level_2_time and _can_pay_brand_breaker_cost(2):
		return 2
	if charge_time >= config.charge_level_1_time and _can_pay_brand_breaker_cost(1):
		return 1
	return 0
