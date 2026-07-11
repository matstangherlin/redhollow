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

var _pool: Array[CPUParticles2D] = []
var _flash_layer: CanvasLayer = null
var _flash_rect: ColorRect = null


func _ready() -> void:
	add_to_group(VFX_SPAWNER_GROUP)
	_build_pool()
	_build_flash_overlay()


func spawn(kind: StringName, global_position: Vector2, strength: float = 1.0) -> void:
	var scaled := _apply_accessibility_strength(strength)
	if scaled <= 0.01:
		return

	match kind:
		&"hit_normal":
			_emit_burst(global_position, COLOR_HIT, 6, 0.18, scaled)
		&"hit_heavy":
			_emit_burst(global_position, COLOR_HEAVY, 10, 0.24, scaled)
			_pulse_flash(COLOR_HEAVY, 0.06 * scaled)
		&"counter":
			_emit_burst(global_position, COLOR_COUNTER, 12, 0.22, scaled)
			_pulse_flash(COLOR_COUNTER, 0.08 * scaled)
		&"dodge":
			_emit_burst(global_position, COLOR_DODGE, 5, 0.14, scaled * 0.7)
		&"dodge_perfect":
			_emit_burst(global_position, COLOR_COUNTER, 8, 0.16, scaled)
		&"red_brand":
			_emit_burst(global_position, COLOR_RED_BRAND, 14, 0.28, scaled)
			_pulse_flash(COLOR_RED_BRAND, 0.10 * scaled)
		&"barrier":
			_emit_burst(global_position, COLOR_BARRIER, 16, 0.30, scaled)
		&"player_hurt":
			_emit_burst(global_position, COLOR_HURT, 7, 0.16, scaled)
			_pulse_flash(COLOR_HURT, 0.05 * scaled)
		&"death":
			_emit_burst(global_position, COLOR_DEATH, 18, 0.34, scaled)
		&"checkpoint":
			_emit_burst(global_position, COLOR_CHECKPOINT, 12, 0.26, scaled)
		&"telegraph_counterable":
			_emit_burst(global_position, COLOR_TELEGRAPH_OK, 4, 0.20, scaled * 0.8)
		&"telegraph_not_counterable":
			_emit_burst(global_position, COLOR_TELEGRAPH_WARN, 5, 0.22, scaled * 0.9)


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


func _pulse_flash(color: Color, alpha: float) -> void:
	if _flash_rect == null:
		return

	if FeedbackSettingsAccess.is_reduced_flashes_enabled():
		alpha *= 0.35

	_flash_rect.color = Color(color.r, color.g, color.b, clampf(alpha, 0.0, 0.65))
	var tween := create_tween()
	tween.tween_property(_flash_rect, "color:a", 0.0, 0.10)


func get_scaled_strength(strength: float) -> float:
	return _apply_accessibility_strength(strength)


func _apply_accessibility_strength(strength: float) -> float:
	var scaled := strength
	if FeedbackSettingsAccess.is_reduced_flashes_enabled():
		scaled *= 0.55
	scaled *= FeedbackSettingsAccess.get_telegraph_contrast_multiplier()
	return scaled


func _acquire_particles() -> CPUParticles2D:
	for particles in _pool:
		if not particles.emitting:
			return particles
	return _pool[0] if not _pool.is_empty() else null
