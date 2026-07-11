extends StaticBody2D

signal barrier_destroyed(barrier_id: StringName)
signal wrong_hit_received(attack_data: Resource, hitbox: Area2D, attacker: Node)

const RED_BARRIER_GROUP := "red_barrier"
const PROGRESSION_GROUP := "progression_component"
const REGISTRY_GROUP := "barrier_registry"
const CAMERA_CONTROLLER_GROUP := "camera_controller"
const HITSTOP_GROUP := "hitstop_controller"
const BARRIER_BREAK_TAGS := ["red_brand_breaker", "barrier_break"]
const IDLE_BARRIER_COLOR := Color(0.42, 0.08, 0.12, 0.92)
const RUNE_COLOR := Color(0.92, 0.18, 0.08, 0.85)
const WRONG_HIT_COLOR := Color(0.72, 0.72, 0.78, 0.95)
const BREAK_SHAKE_INTENSITY := 16.0
const BREAK_SHAKE_DURATION := 0.36

@export var barrier_id: StringName = &"test_arena_cult_gate_01"
@export var blocks_enemies: bool = true
@export var wrong_hit_flash_duration: float = 0.12
@export var break_hitstop_duration: float = 0.07

@onready var collision_shape: CollisionShape2D = %CollisionShape2D
@onready var barrier_visual: Polygon2D = %BarrierVisual
@onready var rune_visual: Polygon2D = %RuneVisual
@onready var hurtbox_component: Area2D = %BarrierHurtboxComponent
@onready var break_particles: GPUParticles2D = %BreakParticles
@onready var spark_particles: GPUParticles2D = $SparkParticles

var _is_destroyed: bool = false
var _wrong_hit_flash_remaining: float = 0.0
var _base_barrier_color: Color = IDLE_BARRIER_COLOR
var _base_rune_color: Color = RUNE_COLOR


func _ready() -> void:
	add_to_group(RED_BARRIER_GROUP)
	_base_barrier_color = barrier_visual.color if barrier_visual != null else IDLE_BARRIER_COLOR
	_base_rune_color = rune_visual.color if rune_visual != null else RUNE_COLOR
	sync_with_registry()


func _process(delta: float) -> void:
	if _wrong_hit_flash_remaining <= 0.0:
		return

	_wrong_hit_flash_remaining = maxf(_wrong_hit_flash_remaining - delta, 0.0)
	if _wrong_hit_flash_remaining <= 0.0 and not _is_destroyed:
		_apply_idle_visual()


func handle_barrier_hit(attack_data: Resource, hitbox: Area2D, attacker: Node) -> bool:
	if _is_destroyed:
		return false

	if not _can_break_with_attack(attack_data):
		wrong_hit_received.emit(attack_data, hitbox, attacker)
		_play_wrong_hit_feedback()
		return false

	_destroy_barrier(attack_data, hitbox, attacker)
	return true


func reset_barrier() -> void:
	_is_destroyed = false
	_wrong_hit_flash_remaining = 0.0
	visible = true
	set_process(true)
	_enable_blocking(true)
	_apply_idle_visual()
	if break_particles != null:
		break_particles.emitting = false


func sync_with_registry() -> void:
	var registry := _get_barrier_registry()
	if registry != null and registry.is_destroyed(barrier_id):
		_apply_destroyed_state(false)
	else:
		reset_barrier()


func _can_break_with_attack(attack_data: Resource) -> bool:
	var progression := _get_progression_component()
	if progression == null or not progression.can_break_barriers():
		return false

	var tags := attack_data.get("tags") as PackedStringArray
	if tags == null:
		return false

	for tag in tags:
		if BARRIER_BREAK_TAGS.has(String(tag)):
			return true

	return false


func _destroy_barrier(attack_data: Resource, hitbox: Area2D, attacker: Node) -> void:
	if _is_destroyed:
		return

	_is_destroyed = true
	_apply_destroyed_state(true)
	barrier_destroyed.emit(barrier_id)

	var registry := _get_barrier_registry()
	if registry != null:
		registry.mark_destroyed(barrier_id)

	_request_break_hitstop(attack_data)
	_request_break_shake()


func _apply_destroyed_state(play_particles: bool) -> void:
	_enable_blocking(false)
	set_process(false)

	if barrier_visual != null:
		barrier_visual.visible = false
	if rune_visual != null:
		rune_visual.visible = false
	if hurtbox_component != null:
		hurtbox_component.call("set_deferred", "monitorable", false)
		hurtbox_component.call("set_deferred", "monitoring", false)
		hurtbox_component.set_deferred("collision_layer", 0)

	if play_particles:
		_play_break_particles()


func _enable_blocking(is_enabled: bool) -> void:
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not is_enabled)

	collision_layer = 1 if is_enabled else 0
	collision_mask = 0


func _play_wrong_hit_feedback() -> void:
	_wrong_hit_flash_remaining = maxf(wrong_hit_flash_duration, 0.0)
	if barrier_visual != null:
		barrier_visual.color = WRONG_HIT_COLOR
	if rune_visual != null:
		rune_visual.color = WRONG_HIT_COLOR.lightened(0.15)


func _apply_idle_visual() -> void:
	if barrier_visual != null:
		barrier_visual.color = _base_barrier_color
		barrier_visual.visible = true
	if rune_visual != null:
		rune_visual.color = _base_rune_color
		rune_visual.visible = true


func _play_break_particles() -> void:
	if break_particles != null:
		break_particles.restart()
		break_particles.emitting = true
	if spark_particles != null:
		spark_particles.restart()
		spark_particles.emitting = true


func _request_break_hitstop(attack_data: Resource) -> void:
	var duration := break_hitstop_duration
	if attack_data != null:
		var attack_hitstop := maxf(
			float(attack_data.get("attacker_hitstop")),
			float(attack_data.get("target_hitstop"))
		)
		duration = maxf(duration, attack_hitstop)

	for node in get_tree().get_nodes_in_group(HITSTOP_GROUP):
		if node.has_method("request_hitstop"):
			node.call("request_hitstop", duration)
			return


func _request_break_shake() -> void:
	for node in get_tree().get_nodes_in_group(CAMERA_CONTROLLER_GROUP):
		if node.has_method("request_shake"):
			node.call("request_shake", BREAK_SHAKE_INTENSITY, BREAK_SHAKE_DURATION)
			return


func _get_progression_component() -> ProgressionComponent:
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			return node

	return null


func _get_barrier_registry() -> BarrierRegistry:
	for node in get_tree().get_nodes_in_group(REGISTRY_GROUP):
		if node is BarrierRegistry:
			return node

	return null
