extends Node
class_name PlayerPresentationController

const PLAYER_BODY_COLOR := Color(0.76, 0.18, 0.13, 1.0)
const DODGE_BODY_COLOR := Color(0.95, 0.42, 0.22, 1.0)
const DODGE_BODY_SCALE := Vector2(1.28, 0.82)
const COUNTER_WINDOW_BODY_COLOR := Color(0.28, 0.58, 0.95, 1.0)
const COUNTER_RECOVERY_BODY_COLOR := Color(0.48, 0.48, 0.52, 1.0)
const COUNTER_ATTACK_BODY_COLOR := Color(0.92, 0.72, 0.18, 1.0)
const TAUNT_BODY_COLOR := Color(0.82, 0.24, 0.42, 1.0)
const DEFAULT_BRAND_HAND_COLOR := Color(1.0, 0.06, 0.02, 1.0)
const CHARGING_BRAND_HAND_COLOR := Color(1.0, 0.42, 0.08, 1.0)
const MAX_CHARGE_BRAND_HAND_COLOR := Color(1.0, 0.82, 0.18, 1.0)

var _visual: Node2D = null
var _body_visual: Polygon2D = null
var _brand_hand: Polygon2D = null
var _direction_marker: Node2D = null


func setup(visual: Node2D, body_visual: Polygon2D, brand_hand: Polygon2D, direction_marker: Node2D) -> void:
	_visual = visual
	_body_visual = body_visual
	_brand_hand = brand_hand
	_direction_marker = direction_marker
	reset_body_visual()


func apply_facing(facing_direction: int, direction_marker_offset: float) -> void:
	if _visual != null:
		_visual.scale.x = float(facing_direction)
	if _direction_marker != null:
		_direction_marker.position.x = direction_marker_offset * float(facing_direction)
		_direction_marker.scale.x = float(facing_direction)


func refresh_from_player(player: CharacterBody2D) -> void:
	if player == null:
		return

	if bool(player.call("_is_dodging")):
		_apply_dodge_body()
	elif bool(player.call("_is_taunting")):
		_apply_taunt_body()
	elif bool(player.call("_is_countering")):
		_apply_counter_body(player)
	else:
		reset_body_visual()

	var brand_charge_level := int(player.get("brand_charge_level"))
	var is_charging := bool(player.call("_is_charging_brand_breaker"))
	update_brand_hand(is_charging, brand_charge_level)


func reset_body_visual() -> void:
	if _body_visual == null:
		return
	_body_visual.color = PLAYER_BODY_COLOR
	_body_visual.scale = Vector2.ONE


func update_brand_hand(is_charging: bool, preview_level: int) -> void:
	if _brand_hand == null:
		return

	if not is_charging:
		_brand_hand.color = DEFAULT_BRAND_HAND_COLOR
		_brand_hand.scale = Vector2.ONE
		return

	if preview_level >= 2:
		_brand_hand.color = MAX_CHARGE_BRAND_HAND_COLOR
		_brand_hand.scale = Vector2(1.24, 1.24)
	elif preview_level >= 1:
		_brand_hand.color = CHARGING_BRAND_HAND_COLOR
		_brand_hand.scale = Vector2(1.12, 1.12)
	else:
		_brand_hand.color = CHARGING_BRAND_HAND_COLOR
		_brand_hand.scale = Vector2(1.04, 1.04)


func _apply_dodge_body() -> void:
	if _body_visual == null:
		return
	_body_visual.color = DODGE_BODY_COLOR
	_body_visual.scale = DODGE_BODY_SCALE


func _apply_taunt_body() -> void:
	if _body_visual == null:
		return
	_body_visual.color = TAUNT_BODY_COLOR
	_body_visual.scale = Vector2(1.06, 0.96)


func _apply_counter_body(player: CharacterBody2D) -> void:
	if _body_visual == null:
		return

	var counter_phase: int = int(player.get("counter_phase"))
	match counter_phase:
		PlayerStateTypes.CounterPhase.WINDOW:
			_body_visual.color = COUNTER_WINDOW_BODY_COLOR
			_body_visual.scale = Vector2.ONE
		PlayerStateTypes.CounterPhase.RECOVERY:
			_body_visual.color = COUNTER_RECOVERY_BODY_COLOR
			_body_visual.scale = Vector2.ONE
		PlayerStateTypes.CounterPhase.COUNTER_ATTACK:
			_body_visual.color = COUNTER_ATTACK_BODY_COLOR
			_body_visual.scale = Vector2.ONE
		_:
			reset_body_visual()
