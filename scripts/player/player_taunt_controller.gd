extends Node
class_name PlayerTauntController

signal taunt_started(phrase: String, line_id: StringName)
signal taunt_performed(phrase: String, context: Dictionary)
signal locomotion_refresh_requested

var taunt_time_remaining: float = 0.0
var taunt_elapsed_time: float = 0.0
var taunt_cooldown_time_remaining: float = 0.0
var current_taunt_phrase: String = ""
var current_taunt_line_id: StringName = &""
var taunt_vulnerability_applied: bool = false
var was_invulnerable_before_taunt: bool = false

var _taunt_phrase_bag: Array[String] = []
var _last_taunt_phrase: String = ""

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
	health_component: Node
) -> void:
	_player = player
	_input = input_controller
	_attack = attack_controller
	_presentation = presentation
	_health = health_component


func handle_taunt_input() -> void:
	if _input.taunt_just_pressed and _can_start_taunt():
		start_taunt()


func update_taunt_cooldown(delta: float) -> void:
	if taunt_cooldown_time_remaining <= 0.0:
		return
	taunt_cooldown_time_remaining = maxf(taunt_cooldown_time_remaining - delta, 0.0)


func update_taunt_timing(delta: float) -> void:
	if not is_taunting():
		return

	taunt_elapsed_time += delta
	taunt_time_remaining -= delta
	update_taunt_vulnerability()

	if taunt_time_remaining <= 0.0:
		_finish_taunt()


func start_taunt() -> void:
	_attack.cancel_active_attack_for_overlay()

	current_taunt_phrase = _pick_taunt_phrase()
	current_taunt_line_id = StringName("taunt_%d" % _get_taunt_line_index(current_taunt_phrase))
	taunt_time_remaining = maxf(float(_player.get("taunt_duration")), 0.0)
	taunt_elapsed_time = 0.0
	was_invulnerable_before_taunt = _is_health_invulnerable()
	taunt_vulnerability_applied = false
	_player.set("current_state", PlayerStateTypes.PlayerState.TAUNT)
	_player.velocity.x = 0.0
	update_taunt_vulnerability()
	_presentation.refresh_from_player(_player)

	var context := {
		"line_id": current_taunt_line_id,
		"duration": float(_player.get("taunt_duration")),
		"vulnerable_start": float(_player.get("taunt_vulnerable_start")),
		"vulnerable_end": float(_player.get("taunt_vulnerable_end")),
		"response_tags": PackedStringArray(["provocation", "calder"]),
	}
	taunt_started.emit(current_taunt_phrase, current_taunt_line_id)
	taunt_performed.emit(current_taunt_phrase, context)

	if taunt_time_remaining <= 0.0:
		_finish_taunt()


func cancel_taunt(next_state: int = PlayerStateTypes.PlayerState.IDLE) -> void:
	if not is_taunting():
		return

	taunt_time_remaining = 0.0
	taunt_elapsed_time = 0.0
	current_taunt_phrase = ""
	current_taunt_line_id = &""
	_restore_taunt_invulnerability()
	_presentation.refresh_from_player(_player)
	_player.set("current_state", next_state)


func is_taunting() -> bool:
	return taunt_time_remaining > 0.0


func is_taunt_vulnerability_window_active() -> bool:
	var vulnerable_start := float(_player.get("taunt_vulnerable_start"))
	var vulnerable_end := float(_player.get("taunt_vulnerable_end"))
	return (
		is_taunting()
		and vulnerable_end > vulnerable_start
		and taunt_elapsed_time >= vulnerable_start
		and taunt_elapsed_time <= vulnerable_end
	)


func update_taunt_vulnerability() -> void:
	var should_be_vulnerable := is_taunt_vulnerability_window_active()
	if should_be_vulnerable:
		_set_health_invulnerable(false)
		taunt_vulnerability_applied = true
	elif taunt_vulnerability_applied:
		_restore_taunt_invulnerability()


func _can_start_taunt() -> bool:
	if _player.call("_is_dead") or is_taunting() or _player.call("_is_dodging") or _player.call("_is_countering"):
		return false
	if _player.call("_is_charging_brand_breaker"):
		return false
	if taunt_cooldown_time_remaining > 0.0:
		return false
	if not _player.is_on_floor():
		return false

	var current_state: int = int(_player.get("current_state"))
	match current_state:
		PlayerStateTypes.PlayerState.HURT, PlayerStateTypes.PlayerState.DEAD, PlayerStateTypes.PlayerState.INTERACT, PlayerStateTypes.PlayerState.COUNTER, PlayerStateTypes.PlayerState.TAUNT, PlayerStateTypes.PlayerState.DODGE:
			return false
		PlayerStateTypes.PlayerState.ATTACK:
			return _attack.attack_phase == PlayerStateTypes.AttackPhase.RECOVERY
		PlayerStateTypes.PlayerState.IDLE, PlayerStateTypes.PlayerState.RUN, PlayerStateTypes.PlayerState.FALL:
			return true
		_:
			return false


func _finish_taunt() -> void:
	taunt_time_remaining = 0.0
	taunt_elapsed_time = 0.0
	current_taunt_phrase = ""
	current_taunt_line_id = &""
	_restore_taunt_invulnerability()
	taunt_cooldown_time_remaining = maxf(float(_player.get("taunt_cooldown")), 0.0)
	_presentation.refresh_from_player(_player)
	locomotion_refresh_requested.emit()


func _pick_taunt_phrase() -> String:
	var available_phrases := _get_valid_taunt_phrases()
	if available_phrases.is_empty():
		return "Vamos, eu ainda nem comecei."

	if _taunt_phrase_bag.is_empty():
		_taunt_phrase_bag = available_phrases.duplicate()
		_taunt_phrase_bag.shuffle()
		if _taunt_phrase_bag.size() > 1 and _taunt_phrase_bag[0] == _last_taunt_phrase:
			_taunt_phrase_bag.reverse()

	var phrase: String = _taunt_phrase_bag.pop_front()
	_last_taunt_phrase = phrase
	return phrase


func _get_valid_taunt_phrases() -> Array[String]:
	var phrases: Array[String] = []
	var taunt_phrases: Array = _player.get("taunt_phrases")
	for phrase in taunt_phrases:
		if not String(phrase).strip_edges().is_empty():
			phrases.append(String(phrase))
	return phrases


func _get_taunt_line_index(phrase: String) -> int:
	var taunt_phrases: Array = _player.get("taunt_phrases")
	for index in taunt_phrases.size():
		if String(taunt_phrases[index]) == phrase:
			return index
	return 0


func _restore_taunt_invulnerability() -> void:
	if not taunt_vulnerability_applied:
		return
	_set_health_invulnerable(was_invulnerable_before_taunt)
	taunt_vulnerability_applied = false


func _set_health_invulnerable(is_invulnerable: bool) -> void:
	if _health != null:
		_health.set("invulnerable", is_invulnerable)


func _is_health_invulnerable() -> bool:
	return _health != null and bool(_health.get("invulnerable"))
