extends Node2D
class_name CameraController

const CAMERA_CONTROLLER_GROUP := "camera_controller"
const DEFAULT_TARGET_SPEED_REFERENCE := 240.0

# Logical viewport note: Red Hollow currently keeps Godot's default project viewport
# of 1152x648. This controller uses the runtime viewport for clamping, while this
# value documents the intended prototype baseline and acts as a fallback only.
@export var logical_viewport_size: Vector2 = Vector2(1152.0, 648.0)
@export var target_path: NodePath
@export var area_limits: Rect2 = Rect2(0.0, 0.0, 2400.0, 1400.0)
@export var follow_speed: float = 8.0
@export var dead_zone_width: float = 160.0
@export var dead_zone_height: float = 96.0
@export var look_ahead_distance: float = 120.0
@export var look_ahead_speed: float = 4.5
@export var max_shake_offset: float = 18.0
@export var shake_decay: float = 42.0
@export var max_punch_zoom: float = 0.05
@export var punch_zoom_decay: float = 8.0
@export var debug_shake_action: StringName = &"debug_shake"
@export var debug_shake_intensity: float = 10.0
@export var debug_shake_duration: float = 0.30

@onready var camera: Camera2D = %Camera2D

var target: Node2D
var base_position: Vector2 = Vector2.ZERO
var look_ahead_offset: float = 0.0
var active_shakes: Array = []
var _punch_zoom_offset: float = 0.0
var _base_zoom: Vector2 = Vector2.ONE


func _ready() -> void:
	add_to_group(CAMERA_CONTROLLER_GROUP)
	target = get_node_or_null(target_path) as Node2D
	if target == null:
		push_warning("CameraController target was not found. Camera will remain at its scene position.")
		base_position = global_position
	else:
		base_position = _clamp_to_area(target.global_position)
		global_position = base_position

	_apply_camera_limits()
	camera.make_current()
	_base_zoom = camera.zoom


func request_punch_zoom(amount: float, duration: float) -> void:
	if camera == null or amount <= 0.0 or duration <= 0.0:
		return

	var accessibility_scale := FeedbackSettingsAccess.get_screen_shake_multiplier()

	if accessibility_scale <= 0.0:
		return

	var safe_amount := minf(amount * accessibility_scale, max_punch_zoom)
	_punch_zoom_offset = maxf(_punch_zoom_offset, safe_amount)
	var tween := create_tween()
	tween.tween_method(_set_punch_zoom_offset, _punch_zoom_offset, 0.0, duration)


func _set_punch_zoom_offset(value: float) -> void:
	_punch_zoom_offset = maxf(value, 0.0)
	if camera != null:
		camera.zoom = _base_zoom * (1.0 + _punch_zoom_offset)


func _physics_process(delta: float) -> void:
	_handle_debug_input()
	_update_base_position(delta)
	_update_shake(delta)


func configure_for_area(limits: Rect2, new_target: Node2D = null, snap_immediately: bool = true) -> void:
	if new_target != null:
		target = new_target

	area_limits = limits
	look_ahead_offset = 0.0
	active_shakes.clear()
	_punch_zoom_offset = 0.0

	if camera == null:
		camera = get_node_or_null("%Camera2D") as Camera2D

	if camera != null:
		camera.offset = Vector2.ZERO
		camera.zoom = _base_zoom

	_apply_camera_limits()

	if target == null:
		return

	if snap_immediately:
		base_position = _clamp_to_area(target.global_position)
		global_position = base_position


func request_shake(intensity: float, duration: float) -> void:
	if intensity <= 0.0 or duration <= 0.0:
		return

	if FeedbackSettingsAccess.get_screen_shake_multiplier() <= 0.0:
		return

	var accessibility_scale := FeedbackSettingsAccess.get_screen_shake_multiplier()
	intensity *= accessibility_scale
	if intensity <= 0.0:
		return

	active_shakes.append({
		"strength": minf(intensity, max_shake_offset),
		"duration": duration,
		"remaining": duration,
	})


func _handle_debug_input() -> void:
	if InputMap.has_action(debug_shake_action) and Input.is_action_just_pressed(debug_shake_action):
		request_shake(debug_shake_intensity, debug_shake_duration)


func _update_base_position(delta: float) -> void:
	if target == null:
		return

	var target_point := target.global_position + Vector2(_get_target_look_ahead(delta), 0.0)
	var desired_position := _apply_dead_zone(target_point)
	var follow_weight := 1.0 - exp(-follow_speed * delta)
	base_position = base_position.lerp(desired_position, follow_weight)
	base_position = _clamp_to_area(base_position)
	global_position = base_position


func _get_target_look_ahead(delta: float) -> float:
	var speed_ratio := _get_target_speed_ratio()
	var desired_offset := float(_get_target_facing()) * look_ahead_distance * speed_ratio
	var look_weight := 1.0 - exp(-look_ahead_speed * delta)
	look_ahead_offset = lerpf(look_ahead_offset, desired_offset, look_weight)
	return look_ahead_offset


func _get_target_speed_ratio() -> float:
	if target == null:
		return 0.0

	var body := target as CharacterBody2D
	if body == null:
		return 0.0

	var target_speed_reference := DEFAULT_TARGET_SPEED_REFERENCE
	var target_max_speed = target.get("max_run_speed")
	if typeof(target_max_speed) == TYPE_FLOAT or typeof(target_max_speed) == TYPE_INT:
		target_speed_reference = maxf(float(target_max_speed), 1.0)

	return clampf(absf(body.velocity.x) / target_speed_reference, 0.0, 1.0)


func _get_target_facing() -> int:
	if target == null:
		return 1

	var facing_value = target.get("facing_direction")
	if typeof(facing_value) == TYPE_INT or typeof(facing_value) == TYPE_FLOAT:
		if not is_zero_approx(float(facing_value)):
			return 1 if float(facing_value) > 0.0 else -1

	var body := target as CharacterBody2D
	if body != null and not is_zero_approx(body.velocity.x):
		return 1 if body.velocity.x > 0.0 else -1

	return 1 if look_ahead_offset >= 0.0 else -1


func _apply_dead_zone(target_point: Vector2) -> Vector2:
	var desired := base_position
	var half_dead_zone := Vector2(dead_zone_width, dead_zone_height) * 0.5
	var delta_to_target := target_point - base_position

	if absf(delta_to_target.x) > half_dead_zone.x:
		desired.x = target_point.x - signf(delta_to_target.x) * half_dead_zone.x

	if absf(delta_to_target.y) > half_dead_zone.y:
		desired.y = target_point.y - signf(delta_to_target.y) * half_dead_zone.y

	return desired


func _clamp_to_area(position_to_clamp: Vector2) -> Vector2:
	var half_visible := _get_visible_half_size()
	var min_center := area_limits.position + half_visible
	var max_center := area_limits.position + area_limits.size - half_visible
	var clamped := position_to_clamp

	if min_center.x > max_center.x:
		clamped.x = area_limits.get_center().x
	else:
		clamped.x = clampf(clamped.x, min_center.x, max_center.x)

	if min_center.y > max_center.y:
		# Prefer bottom alignment so ground gameplay stays visible in short areas.
		clamped.y = area_limits.position.y + area_limits.size.y - half_visible.y
	else:
		clamped.y = clampf(clamped.y, min_center.y, max_center.y)

	return clamped


func _get_visible_half_size() -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		viewport_size = logical_viewport_size

	return viewport_size / (camera.zoom * 2.0)


func _apply_camera_limits() -> void:
	camera.limit_left = int(area_limits.position.x)
	camera.limit_top = int(area_limits.position.y)
	camera.limit_right = int(area_limits.position.x + area_limits.size.x)
	camera.limit_bottom = int(area_limits.position.y + area_limits.size.y)


func _update_shake(delta: float) -> void:
	var shake_offset := Vector2.ZERO
	var remaining_shakes: Array = []

	for shake in active_shakes:
		var strength := float(shake["strength"])
		var remaining := float(shake["remaining"]) - delta
		strength = maxf(strength - shake_decay * delta, 0.0)

		if remaining > 0.0 and strength > 0.0:
			shake["strength"] = strength
			shake["remaining"] = remaining
			remaining_shakes.append(shake)
			shake_offset += Vector2(randf_range(-strength, strength), randf_range(-strength, strength))

	active_shakes = remaining_shakes

	if shake_offset.length() > max_shake_offset:
		shake_offset = shake_offset.normalized() * max_shake_offset

	camera.offset = shake_offset
