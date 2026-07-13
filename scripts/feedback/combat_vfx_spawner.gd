extends Node2D
class_name CombatVfxSpawner

## Pooled procedural VFX placeholders — no external assets.

const VFX_SPAWNER_GROUP := "combat_vfx_spawner"
const POOL_SIZE := 24

const COLOR_HIT := Color(0.95, 0.88, 0.72, 0.85)
const COLOR_HEAVY := Color(0.98, 0.42, 0.18, 0.9)
const COLOR_COUNTER := Color(0.72, 0.92, 1.0, 0.88)
const COLOR_DODGE := Color(0.82, 0.82, 0.86, 0.55)
const COLOR_RED_BRAND := Color(0.92, 0.28, 0.12, 0.92)
const COLOR_BARRIER := Color(0.82, 0.18, 0.14, 0.9)
const COLOR_HURT := Color(0.92, 0.12, 0.12, 0.75)
const COLOR_DEATH := Color(0.42, 0.04, 0.06, 0.85)
const COLOR_CHECKPOINT := Color(0.72, 0.88, 0.62, 0.85)
const COLOR_TELEGRAPH_OK := Color(1.0, 0.82, 0.22, 0.55)
const COLOR_TELEGRAPH_WARN := Color(0.92, 0.18, 0.18, 0.65)
const COLOR_SWING_TRAIL := Color(0.92, 0.86, 0.72, 0.55)

var _pool: Array[CPUParticles2D] = []
var _flash_layer: CanvasLayer = null
var _flash_rect: ColorRect = null


func _ready() -> void:
	add_to_group(VFX_SPAWNER_GROUP)
	_build_pool()
	_build_flash_overlay()


func spawn(kind: StringName, global_position: Vector2, strength: float = 1.0) -> void:
	spawn_from_feedback(
		{
			"vfx_kind": kind,
			"flash_strength": strength,
		},
		global_position
	)


func spawn_from_feedback(feedback: Dictionary, global_position: Vector2) -> void:
	var kind: StringName = feedback.get("vfx_kind", &"hit_normal")
	var strength: float = float(feedback.get("flash_strength", 0.2))
	var particle_count: int = int(feedback.get("particle_count", -1))
	var lifetime: float = float(feedback.get("particle_lifetime", 0.18))
	var color: Color = feedback.get("impact_color", _color_for_kind(kind))
	var lateral: float = float(feedback.get("lateral_impact_bias", 0.0))
	var spawn_position := global_position
	if not is_equal_approx(lateral, 0.0):
		spawn_position.x += lateral * 10.0

	var scaled := _apply_accessibility_strength(strength, feedback)
	if scaled <= 0.01:
		return

	var count := particle_count
	if count < 0:
		count = _default_count_for_kind(kind)

	count = _scale_particle_count(count, feedback)
	if count <= 0:
		return

	match kind:
		&"hit_normal":
			_emit_burst(spawn_position, color, count, lifetime, scaled)
		&"hit_heavy":
			_emit_burst(spawn_position, color, count, lifetime, scaled)
			_pulse_flash(feedback.get("flash_color", COLOR_HEAVY), 0.06 * scaled, feedback)
		&"counter":
			_emit_burst(spawn_position, color, count, lifetime, scaled)
			_pulse_flash(feedback.get("flash_color", COLOR_COUNTER), 0.08 * scaled, feedback)
		&"dodge":
			_emit_burst(spawn_position, COLOR_DODGE, count, lifetime, scaled * 0.7)
		&"dodge_perfect":
			_emit_burst(spawn_position, COLOR_COUNTER, count, lifetime, scaled)
		&"red_brand":
			_emit_burst(spawn_position, color, count, lifetime, scaled)
			_pulse_flash(feedback.get("flash_color", COLOR_RED_BRAND), 0.10 * scaled, feedback)
			if bool(feedback.get("shockwave_enabled", false)):
				_spawn_shockwave(spawn_position, color, scaled, feedback)
		&"barrier":
			_emit_burst(spawn_position, COLOR_BARRIER, count, lifetime, scaled)
		&"player_hurt":
			_emit_burst(spawn_position, COLOR_HURT, count, lifetime, scaled)
			_pulse_flash(COLOR_HURT, 0.05 * scaled, feedback)
		&"death":
			_emit_burst(spawn_position, COLOR_DEATH, count, lifetime, scaled)
		&"checkpoint":
			_emit_burst(spawn_position, COLOR_CHECKPOINT, count, lifetime, scaled)
		&"telegraph_counterable":
			_emit_burst(spawn_position, COLOR_TELEGRAPH_OK, count, lifetime, scaled * 0.8)
		&"telegraph_not_counterable":
			_emit_burst(spawn_position, COLOR_TELEGRAPH_WARN, count, lifetime, scaled * 0.9)
		&"swing_trail":
			_spawn_swing_trail(spawn_position, 1, feedback, scaled)
		_:
			_emit_burst(spawn_position, color, count, lifetime, scaled)


func spawn_swing_trail(global_position: Vector2, facing_direction: int, feedback: Dictionary) -> void:
	if not bool(feedback.get("swing_trail_enabled", false)):
		return
	var scaled := _apply_accessibility_strength(1.0, feedback)
	_spawn_swing_trail(global_position, facing_direction, feedback, scaled)


func get_scaled_strength(strength: float) -> float:
	return _apply_accessibility_strength(strength, {})


func _spawn_swing_trail(
	global_position: Vector2,
	facing_direction: int,
	feedback: Dictionary,
	strength: float
) -> void:
	var particles := _acquire_particles()
	if particles == null:
		return

	var count := _scale_particle_count(int(feedback.get("swing_trail_particles", 4)), feedback)
	if count <= 0:
		return

	var color: Color = feedback.get("impact_color", COLOR_SWING_TRAIL)
	particles.global_position = global_position
	particles.amount = maxi(count, 2)
	particles.lifetime = 0.12
	particles.color = color
	particles.direction = Vector2(float(facing_direction), -0.15).normalized()
	particles.spread = 36.0
	particles.initial_velocity_min = 30.0 * strength
	particles.initial_velocity_max = 90.0 * strength
	particles.scale_amount_min = 0.8 * strength
	particles.scale_amount_max = 1.8 * strength
	particles.restart()
	particles.emitting = true


func _spawn_shockwave(global_position: Vector2, color: Color, strength: float, feedback: Dictionary) -> void:
	var particles := _acquire_particles()
	if particles == null:
		return

	var count := _scale_particle_count(maxi(int(feedback.get("particle_count", 12)) + 4, 8), feedback)
	particles.global_position = global_position
	particles.amount = count
	particles.lifetime = 0.32
	particles.color = color
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.gravity = Vector2(0, 180)
	particles.initial_velocity_min = 60.0 * strength
	particles.initial_velocity_max = 160.0 * strength
	particles.scale_amount_min = 2.0 * strength
	particles.scale_amount_max = 4.0 * strength
	particles.restart()
	particles.emitting = true


func _build_pool() -> void:
	for _i in POOL_SIZE:
		var particles := CPUParticles2D.new()
		particles.emitting = false
		particles.one_shot = true
		particles.explosiveness = 0.95
		particles.lifetime = 0.22
		particles.amount = 12
		particles.direction = Vector2(0, -1)
		particles.spread = 180.0
		particles.gravity = Vector2(0, 420)
		particles.initial_velocity_min = 40.0
		particles.initial_velocity_max = 120.0
		particles.scale_amount_min = 1.5
		particles.scale_amount_max = 3.0
		add_child(particles)
		_pool.append(particles)


func _build_flash_overlay() -> void:
	_flash_layer = CanvasLayer.new()
	_flash_layer.layer = 90
	_flash_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_flash_layer)

	_flash_rect = ColorRect.new()
	_flash_rect.color = Color(1, 1, 1, 0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_layer.add_child(_flash_rect)


func _emit_burst(
	global_position: Vector2,
	color: Color,
	amount: int,
	lifetime: float,
	strength: float
) -> void:
	var particles := _acquire_particles()
	if particles == null:
		return

	particles.global_position = global_position
	particles.amount = maxi(amount, 2)
	particles.lifetime = lifetime
	particles.color = color
	particles.scale_amount_min = 1.0 * strength
	particles.scale_amount_max = 2.5 * strength
	particles.restart()
	particles.emitting = true


func _pulse_flash(color: Color, alpha: float, feedback: Dictionary = {}) -> void:
	if _flash_rect == null:
		return

	if _should_reduce_flashes(feedback):
		alpha *= 0.35

	_flash_rect.color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 0.65))
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, 0.10)


func _color_for_kind(kind: StringName) -> Color:
	match kind:
		&"hit_heavy":
			return COLOR_HEAVY
		&"counter":
			return COLOR_COUNTER
		&"red_brand":
			return COLOR_RED_BRAND
		&"barrier":
			return COLOR_BARRIER
		_:
			return COLOR_HIT


func _default_count_for_kind(kind: StringName) -> int:
	match kind:
		&"hit_heavy", &"counter":
			return 10
		&"red_brand", &"barrier":
			return 14
		&"player_hurt":
			return 7
		&"death":
			return 18
		_:
			return 6


func _scale_particle_count(count: int, feedback: Dictionary) -> int:
	var scaled := float(count) * FeedbackSettingsAccess.get_particle_multiplier()
	if feedback.get("respect_particle_setting", true) == false:
		scaled = float(count)
	return maxi(int(roundf(scaled)), 0)


func _apply_accessibility_strength(strength: float, feedback: Dictionary) -> float:
	var scaled := strength
	if _should_reduce_flashes(feedback):
		scaled *= 0.55
	scaled *= FeedbackSettingsAccess.get_telegraph_contrast_multiplier()
	return scaled


func _should_reduce_flashes(feedback: Dictionary) -> bool:
	if feedback.has("respect_flash_setting") and not bool(feedback.get("respect_flash_setting", true)):
		return false
	return FeedbackSettingsAccess.is_reduced_flashes_enabled()


func _acquire_particles() -> CPUParticles2D:
	for particles in _pool:
		if not particles.emitting:
			return particles
	return _pool[0] if not _pool.is_empty() else null
