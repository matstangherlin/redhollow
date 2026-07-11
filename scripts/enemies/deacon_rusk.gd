extends CharacterBody2D
class_name DeaconRusk

signal combat_pressure_changed(is_active: bool)
signal boss_defeated(boss_id: StringName)
signal phase_changed(phase: int)
signal taunt_spoken(line: String)
signal stagger_triggered

enum RuskState {
	INTRO,
	IDLE,
	REPOSITION,
	CHOOSE_ATTACK,
	ATTACK,
	RECOVERY,
	HURT,
	PHASE_TRANSITION,
	STAGGERED,
	DEAD,
}

enum AttackKind {
	NONE,
	DOUBLE_JAB,
	CHARGE,
	PUNISH_SWEEP,
	DEFENSIVE_RETREAT,
	GROUND_SLAM,
	ARMORED_CHARGE,
	TAUNT,
}

const PLAYER_GROUP := "player"
const STYLE_TRACKABLE_GROUP := "style_trackable"
const RED_BRAND_BREAKER_TAGS := ["red_brand_breaker", "breaker"]
const SUPER_ARMOR_TAGS := ["super_armor"]
const NOT_COUNTERABLE_TAGS := ["not_counterable"]
const FLOOR_VELOCITY_RESET_THRESHOLD := 0.0

const TAUNT_LINES := [
	"A dor revela o que você realmente é.",
	"Mol-Khar já conhece seu nome.",
	"Ajoelhe-se, Knox.",
]

@export var boss_id: StringName = &"deacon_rusk"
@export var display_name: String = "Deacon Rusk"
@export var max_health: float = 120.0
@export var move_speed: float = 95.0
@export var phase_2_speed_multiplier: float = 1.28
@export var preferred_range: float = 120.0
@export var detection_range: float = 420.0
@export var intro_duration: float = 1.35
@export var choose_attack_duration: float = 0.42
@export var phase_transition_duration: float = 2.1
@export var retreat_duration: float = 0.75
@export var taunt_duration: float = 1.8
@export var stagger_duration: float = 1.75
@export var stagger_immunity_duration: float = 3.6
@export var stagger_threshold: float = 100.0
@export var red_brand_stagger_amount: float = 100.0
@export var hitstun_resistance: float = 0.5
@export var max_hitstun_per_hit: float = 0.34
@export var phase_2_health_ratio: float = 0.5
@export var gravity: float = 1800.0
@export var max_fall_speed: float = 900.0
@export var ground_deceleration: float = 2200.0
@export var floor_snap_distance: float = 6.0

@export var jab_1_data: Resource = preload("res://resources/combat/rusk_jab_1.tres")
@export var jab_2_data: Resource = preload("res://resources/combat/rusk_jab_2.tres")
@export var charge_data: Resource = preload("res://resources/combat/rusk_charge.tres")
@export var punish_sweep_data: Resource = preload("res://resources/combat/rusk_punish_sweep.tres")
@export var ground_slam_data: Resource = preload("res://resources/combat/rusk_ground_slam.tres")
@export var armored_charge_data: Resource = preload("res://resources/combat/rusk_armored_charge.tres")

@onready var visual: Node2D = %Visual
@onready var body_visual: Polygon2D = %BodyVisual
@onready var mantle_visual: Polygon2D = %MantleVisual
@onready var telegraph_visual: Polygon2D = %TelegraphVisual
@onready var warning_visual: Polygon2D = %WarningVisual
@onready var slam_visual: Polygon2D = %SlamVisual
@onready var hurtbox_component: Area2D = %HurtboxComponent
@onready var hitbox_component: Area2D = %HitboxComponent
@onready var health_component: HealthComponent = %HealthComponent
@onready var debug_label: Label = %DebugLabel

var current_state: int = RuskState.INTRO
var current_phase: int = 1
var facing_direction: int = -1
var state_time_remaining: float = 0.0
var hitstun_remaining: float = 0.0
var attack_phase: String = "none"
var current_attack_kind: int = AttackKind.NONE
var active_attack_data: Resource = null
var combo_step: int = 0
var player_target: Node2D = null
var is_boss_active: bool = false
var _stagger_meter: float = 0.0
var _stagger_immunity_remaining: float = 0.0
var _phase_transition_triggered: bool = false
var _combat_pressure_active: bool = false
var _last_attack_kind: int = AttackKind.NONE
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group(STYLE_TRACKABLE_GROUP)
	add_to_group("boss_enemy")
	floor_snap_length = floor_snap_distance
	_rng.randomize()
	_initialize_health()
	_connect_components()
	_set_dormant(true)
	_update_visual()


func _physics_process(delta: float) -> void:
	if not is_boss_active and current_state != RuskState.DEAD:
		velocity = Vector2.ZERO
		return

	_refresh_player_target()
	_update_immunity_timers(delta)
	_update_state_timers(delta)
	_update_behavior(delta)
	_apply_gravity(delta)
	_apply_movement_rules(delta)
	move_and_slide()
	_update_visual()
	_update_debug_label()


func activate_boss() -> void:
	if is_boss_active or _is_dead():
		return

	is_boss_active = true
	_set_dormant(false)
	_enter_state(RuskState.INTRO)


func get_health_ratio() -> float:
	if health_component == null or health_component.max_health <= 0.0:
		return 1.0
	return health_component.current_health / health_component.max_health


func get_stagger_ratio() -> float:
	if stagger_threshold <= 0.0:
		return 0.0
	return clampf(_stagger_meter / stagger_threshold, 0.0, 1.0)


func _initialize_health() -> void:
	if health_component == null:
		return
	health_component.max_health = max_health
	health_component.current_health = max_health
	health_component.is_dead = false
	health_component.invulnerable = false


func _connect_components() -> void:
	if hurtbox_component != null:
		hurtbox_component.hit_received.connect(_on_hit_received)
	if health_component != null:
		health_component.damaged.connect(_on_damaged)
		health_component.died.connect(_on_died)


func should_block_damage(attack_data_received: Resource) -> bool:
	if health_component != null and health_component.invulnerable:
		return true
	if _has_super_armor() and attack_phase in ["startup", "active"]:
		return not _is_red_brand_breaker(attack_data_received)
	return false


func mark_encounter_cleared() -> void:
	if health_component != null:
		health_component.current_health = 0.0
		health_component.is_dead = true
		health_component.invulnerable = true
	current_state = RuskState.DEAD
	is_boss_active = false
	_set_dormant(true)
	visible = false


func _set_dormant(dormant: bool) -> void:
	# activate_boss() runs inside the activation zone's body_entered callback;
	# changing monitoring/monitorable during physics query flushing is blocked by
	# the engine, so it must be deferred (same pattern as cult_brawler).
	if hurtbox_component != null:
		hurtbox_component.set_deferred("monitoring", not dormant)
		hurtbox_component.set_deferred("monitorable", not dormant)
	if dormant:
		hitbox_component.call("deactivate")
		_set_combat_pressure(false)


func _refresh_player_target() -> void:
	if player_target != null and is_instance_valid(player_target):
		return
	player_target = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D


func _update_immunity_timers(delta: float) -> void:
	if _stagger_immunity_remaining > 0.0:
		_stagger_immunity_remaining = maxf(_stagger_immunity_remaining - delta, 0.0)


func _update_state_timers(delta: float) -> void:
	if current_state == RuskState.HURT:
		hitstun_remaining = maxf(hitstun_remaining - delta, 0.0)
		if hitstun_remaining <= 0.0 and not _is_dead():
			_enter_state(RuskState.CHOOSE_ATTACK)
		return

	if current_state == RuskState.STAGGERED:
		state_time_remaining = maxf(state_time_remaining - delta, 0.0)
		if state_time_remaining <= 0.0 and not _is_dead():
			_stagger_immunity_remaining = stagger_immunity_duration
			_stagger_meter = 0.0
			_enter_state(RuskState.CHOOSE_ATTACK)
		return

	if state_time_remaining <= 0.0:
		_advance_timed_state()
		return

	state_time_remaining = maxf(state_time_remaining - delta, 0.0)
	if state_time_remaining <= 0.0:
		_advance_timed_state()


func _advance_timed_state() -> void:
	match current_state:
		RuskState.INTRO:
			_enter_state(RuskState.CHOOSE_ATTACK)
		RuskState.REPOSITION:
			_enter_state(RuskState.CHOOSE_ATTACK)
		RuskState.CHOOSE_ATTACK:
			_pick_and_begin_attack()
		RuskState.ATTACK:
			_advance_attack_phase()
		RuskState.RECOVERY:
			_finish_attack_cycle()
		RuskState.PHASE_TRANSITION:
			_finish_phase_transition()
		_:
			pass


func _update_behavior(delta: float) -> void:
	if _is_dead() or current_state in [
		RuskState.HURT,
		RuskState.STAGGERED,
		RuskState.PHASE_TRANSITION,
		RuskState.DEAD,
	]:
		return

	match current_state:
		RuskState.IDLE:
			velocity.x = 0.0
			_enter_state(RuskState.REPOSITION)
		RuskState.REPOSITION:
			_update_reposition(delta)
		RuskState.CHOOSE_ATTACK:
			_face_target()
			velocity.x = 0.0
		RuskState.ATTACK, RuskState.RECOVERY:
			_update_attack_movement(delta)
			_face_target()
		_:
			pass


func _update_reposition(delta: float) -> void:
	if player_target == null:
		velocity.x = 0.0
		return

	_face_target()
	var distance := _get_target_distance()
	var speed := move_speed * (_phase_speed_multiplier())
	if distance > preferred_range * 1.15:
		velocity.x = float(facing_direction) * speed
	elif distance < preferred_range * 0.65:
		velocity.x = float(-facing_direction) * speed * 0.85
	else:
		velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)
		if state_time_remaining <= 0.0:
			state_time_remaining = 0.25


func _update_attack_movement(_delta: float) -> void:
	if active_attack_data == null:
		return

	match current_attack_kind:
		AttackKind.CHARGE, AttackKind.ARMORED_CHARGE:
			if attack_phase in ["startup", "active"]:
				var speed_scale := 1.35 if current_attack_kind == AttackKind.ARMORED_CHARGE else 1.15
				velocity.x = float(facing_direction) * move_speed * speed_scale * _phase_speed_multiplier()
			else:
				velocity.x = 0.0
		AttackKind.DEFENSIVE_RETREAT:
			velocity.x = float(-facing_direction) * move_speed * 1.1
		_:
			velocity.x = 0.0


func _pick_and_begin_attack() -> void:
	if player_target == null:
		_enter_state(RuskState.IDLE)
		return

	var attack_kind := _choose_attack_kind()
	_begin_attack(attack_kind)


func _choose_attack_kind() -> int:
	var distance := _get_target_distance()
	var options: Array[int] = []

	if current_phase == 1:
		if distance <= preferred_range * 1.05:
			options.append(AttackKind.DOUBLE_JAB)
			options.append(AttackKind.PUNISH_SWEEP)
			options.append(AttackKind.DEFENSIVE_RETREAT)
		if distance >= preferred_range * 0.85:
			options.append(AttackKind.CHARGE)
			options.append(AttackKind.PUNISH_SWEEP)
	else:
		if distance <= preferred_range * 1.1:
			options.append(AttackKind.DOUBLE_JAB)
			options.append(AttackKind.GROUND_SLAM)
			options.append(AttackKind.TAUNT)
		if distance >= preferred_range * 0.7:
			options.append(AttackKind.ARMORED_CHARGE)
			options.append(AttackKind.CHARGE)

	if options.is_empty():
		options.append(AttackKind.CHARGE)

	options = _filter_recent_attack(options)
	return options[_rng.randi_range(0, options.size() - 1)]


func _filter_recent_attack(options: Array[int]) -> Array[int]:
	if options.size() <= 1 or _last_attack_kind == AttackKind.NONE:
		return options

	var filtered: Array[int] = []
	for option in options:
		if option != _last_attack_kind:
			filtered.append(option)
	return filtered if not filtered.is_empty() else options


func _begin_attack(attack_kind: int) -> void:
	current_attack_kind = attack_kind
	_last_attack_kind = attack_kind

	match attack_kind:
		AttackKind.DOUBLE_JAB:
			combo_step = 1
			_start_attack_with_data(jab_1_data)
		AttackKind.CHARGE:
			_start_attack_with_data(_scaled_attack(charge_data))
		AttackKind.PUNISH_SWEEP:
			_start_attack_with_data(_scaled_attack(punish_sweep_data))
		AttackKind.DEFENSIVE_RETREAT:
			current_state = RuskState.ATTACK
			attack_phase = "retreat"
			state_time_remaining = retreat_duration
			_set_combat_pressure(true)
		AttackKind.GROUND_SLAM:
			_start_attack_with_data(_scaled_attack(ground_slam_data))
		AttackKind.ARMORED_CHARGE:
			_start_attack_with_data(_scaled_attack(armored_charge_data))
		AttackKind.TAUNT:
			current_state = RuskState.ATTACK
			attack_phase = "taunt"
			state_time_remaining = taunt_duration
			_speak_taunt(_rng.randi_range(1, TAUNT_LINES.size() - 1))
		_:
			_enter_state(RuskState.REPOSITION)


func _start_attack_with_data(attack_data: Resource) -> void:
	if attack_data == null:
		_enter_state(RuskState.CHOOSE_ATTACK)
		return

	active_attack_data = attack_data
	current_state = RuskState.ATTACK
	attack_phase = "startup"
	state_time_remaining = maxf(float(attack_data.get("startup_time")), 0.0)
	hitbox_component.call("deactivate")
	_set_combat_pressure(true)
	_face_target()
	if state_time_remaining <= 0.0:
		_advance_attack_phase()


func _advance_attack_phase() -> void:
	if current_attack_kind == AttackKind.DEFENSIVE_RETREAT:
		_finish_attack_cycle()
		return
	if current_attack_kind == AttackKind.TAUNT:
		_finish_attack_cycle()
		return
	if active_attack_data == null:
		_finish_attack_cycle()
		return

	match attack_phase:
		"startup":
			attack_phase = "active"
			state_time_remaining = maxf(float(active_attack_data.get("active_time")), 0.0)
			hitbox_component.call("clear_hit_targets")
			hitbox_component.call("activate", active_attack_data, self, facing_direction)
			if state_time_remaining <= 0.0:
				_advance_attack_phase()
		"active":
			hitbox_component.call("deactivate")
			attack_phase = "recovery"
			current_state = RuskState.RECOVERY
			state_time_remaining = maxf(float(active_attack_data.get("recovery_time")), 0.0)
			if state_time_remaining <= 0.0:
				_finish_attack_cycle()
		_:
			_finish_attack_cycle()


func _finish_attack_cycle() -> void:
	hitbox_component.call("deactivate")
	_set_combat_pressure(false)

	if current_attack_kind == AttackKind.DOUBLE_JAB and combo_step == 1:
		combo_step = 2
		_start_attack_with_data(_scaled_attack(jab_2_data))
		return

	active_attack_data = null
	attack_phase = "none"
	current_attack_kind = AttackKind.NONE
	_check_phase_transition()
	_enter_state(RuskState.REPOSITION)


func _enter_state(next_state: int) -> void:
	if _is_dead() and next_state != RuskState.DEAD:
		return

	current_state = next_state
	match next_state:
		RuskState.INTRO:
			state_time_remaining = intro_duration
			velocity.x = 0.0
			_face_target()
			_speak_taunt(0)
		RuskState.REPOSITION:
			state_time_remaining = 0.35
		RuskState.CHOOSE_ATTACK:
			state_time_remaining = choose_attack_duration * (0.75 if current_phase == 2 else 1.0)
			velocity.x = 0.0
		RuskState.HURT, RuskState.STAGGERED, RuskState.PHASE_TRANSITION:
			velocity.x = 0.0
		_:
			pass


func _on_hit_received(attack_data_received: Resource, hitbox: Area2D, attacker: Node) -> void:
	if _is_dead() or health_component.invulnerable:
		return
	if _has_super_armor() and not _is_red_brand_breaker(attack_data_received):
		return

	_apply_stagger_from_attack(attack_data_received)
	if current_state == RuskState.STAGGERED:
		return

	_interrupt_attack()

	var effective_hitstun := minf(
		float(attack_data_received.get("hitstun_time")) * (1.0 - hitstun_resistance),
		max_hitstun_per_hit
	)
	if _stagger_immunity_remaining > 0.0:
		effective_hitstun *= 0.35

	hitstun_remaining = maxf(effective_hitstun, 0.0)
	_apply_knockback(attack_data_received.get("knockback") as Vector2, hitbox, attacker)
	current_state = RuskState.HURT if hitstun_remaining > 0.0 else RuskState.CHOOSE_ATTACK
	velocity.x = 0.0
	_update_visual()


func _apply_stagger_from_attack(attack_data_received: Resource) -> void:
	if _stagger_immunity_remaining > 0.0:
		return

	var gain := float(attack_data_received.get("damage")) * 4.5
	if _is_red_brand_breaker(attack_data_received):
		gain = red_brand_stagger_amount

	_stagger_meter = minf(_stagger_meter + gain, stagger_threshold)
	if _stagger_meter >= stagger_threshold:
		_enter_staggered()


func _enter_staggered() -> void:
	if current_state == RuskState.STAGGERED:
		return

	_interrupt_attack()
	_stagger_meter = stagger_threshold
	current_state = RuskState.STAGGERED
	state_time_remaining = stagger_duration
	hitstun_remaining = 0.0
	velocity = Vector2.ZERO
	hitbox_component.call("deactivate")
	_set_combat_pressure(false)
	stagger_triggered.emit()


func _check_phase_transition() -> void:
	if _phase_transition_triggered or current_phase != 1:
		return
	if get_health_ratio() > phase_2_health_ratio:
		return
	_begin_phase_transition()


func _begin_phase_transition() -> void:
	_phase_transition_triggered = true
	_interrupt_attack()
	if health_component != null:
		health_component.invulnerable = true
	current_state = RuskState.PHASE_TRANSITION
	state_time_remaining = phase_transition_duration
	velocity = Vector2.ZERO
	_speak_taunt(1)


func _finish_phase_transition() -> void:
	current_phase = 2
	if health_component != null:
		health_component.invulnerable = false
	phase_changed.emit(current_phase)
	_enter_state(RuskState.CHOOSE_ATTACK)


func _interrupt_attack() -> void:
	if current_state in [RuskState.ATTACK, RuskState.RECOVERY]:
		hitbox_component.call("deactivate")
		attack_phase = "none"
		active_attack_data = null
		current_attack_kind = AttackKind.NONE
		combo_step = 0
		_set_combat_pressure(false)


func _on_damaged(_amount: float, _source: Node) -> void:
	_check_phase_transition()


func _on_died() -> void:
	_enter_state(RuskState.DEAD)
	_interrupt_attack()
	_set_dormant(true)
	velocity = Vector2.ZERO
	boss_defeated.emit(boss_id)


func _has_super_armor() -> bool:
	if active_attack_data == null:
		return false
	return _attack_has_any_tag(active_attack_data, SUPER_ARMOR_TAGS)


func _is_red_brand_breaker(attack_data: Resource) -> bool:
	return _attack_has_any_tag(attack_data, RED_BRAND_BREAKER_TAGS)


func _attack_has_any_tag(attack_data: Resource, tag_list: Array) -> bool:
	var tags: PackedStringArray = attack_data.get("tags")
	for tag in tag_list:
		if tags.has(tag):
			return true
	return false


func _is_attack_counterable(attack_data: Resource) -> bool:
	if attack_data == null:
		return true
	if not bool(attack_data.get("counterable")):
		return false
	return not _attack_has_any_tag(attack_data, NOT_COUNTERABLE_TAGS)


func _scaled_attack(base_data: Resource) -> Resource:
	if current_phase <= 1 or base_data == null:
		return base_data

	var scaled: AttackData = base_data.duplicate(true) as AttackData
	scaled.startup_time *= 0.82
	scaled.recovery_time *= 0.86
	return scaled


func _phase_speed_multiplier() -> float:
	return phase_2_speed_multiplier if current_phase >= 2 else 1.0


func _speak_taunt(index: int) -> void:
	var safe_index := clampi(index, 0, TAUNT_LINES.size() - 1)
	var line: String = TAUNT_LINES[safe_index]
	taunt_spoken.emit(line)


func _set_combat_pressure(is_active: bool) -> void:
	if _combat_pressure_active == is_active:
		return
	_combat_pressure_active = is_active
	combat_pressure_changed.emit(is_active)


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = FLOOR_VELOCITY_RESET_THRESHOLD
		return
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)


func _apply_movement_rules(delta: float) -> void:
	if current_state in [RuskState.HURT, RuskState.STAGGERED, RuskState.PHASE_TRANSITION, RuskState.DEAD]:
		velocity.x = 0.0
		return
	if current_state in [RuskState.ATTACK, RuskState.RECOVERY, RuskState.INTRO, RuskState.CHOOSE_ATTACK]:
		if current_attack_kind not in [AttackKind.CHARGE, AttackKind.ARMORED_CHARGE, AttackKind.DEFENSIVE_RETREAT]:
			velocity.x = move_toward(velocity.x, 0.0, ground_deceleration * delta)


func _apply_knockback(knockback: Vector2, hitbox: Area2D, attacker: Node) -> void:
	var direction := _get_knockback_direction(hitbox, attacker)
	velocity.x = knockback.x * float(direction)
	velocity.y = knockback.y


func _get_knockback_direction(hitbox: Area2D, attacker: Node) -> int:
	var attacker_node := attacker as Node2D
	if attacker_node != null and not is_equal_approx(attacker_node.global_position.x, global_position.x):
		return 1 if global_position.x > attacker_node.global_position.x else -1
	if hitbox != null and not is_equal_approx(hitbox.global_position.x, global_position.x):
		return 1 if global_position.x > hitbox.global_position.x else -1
	return 1


func _face_target() -> void:
	if player_target == null:
		return
	var direction := _get_direction_to_target()
	if direction != 0:
		facing_direction = direction
		_apply_facing()


func _apply_facing() -> void:
	if visual != null:
		visual.scale.x = float(facing_direction)


func _get_direction_to_target() -> int:
	if player_target == null:
		return 0
	if is_equal_approx(player_target.global_position.x, global_position.x):
		return facing_direction
	return 1 if player_target.global_position.x > global_position.x else -1


func _get_target_distance() -> float:
	if player_target == null:
		return INF
	return absf(player_target.global_position.x - global_position.x)


func _is_dead() -> bool:
	return health_component != null and health_component.is_dead


func _update_visual() -> void:
	if body_visual == null:
		return

	var body_color := Color(0.34, 0.1, 0.12, 1.0)
	match current_state:
		RuskState.INTRO, RuskState.PHASE_TRANSITION:
			body_color = Color(0.52, 0.14, 0.16, 1.0)
		RuskState.ATTACK, RuskState.RECOVERY:
			body_color = Color(0.62, 0.12, 0.14, 1.0)
		RuskState.HURT:
			body_color = Color(0.92, 0.46, 0.18, 1.0)
		RuskState.STAGGERED:
			body_color = Color(0.78, 0.72, 0.22, 1.0)
		RuskState.DEAD:
			body_color = Color(0.18, 0.16, 0.18, 1.0)

	body_visual.color = body_color
	if mantle_visual != null:
		mantle_visual.color = Color(0.18, 0.08, 0.1, 1.0) if current_phase == 1 else Color(0.28, 0.06, 0.08, 1.0)

	var telegraph_visible := current_state in [RuskState.ATTACK, RuskState.RECOVERY] and attack_phase == "startup"
	var warning_visible := telegraph_visible and not _is_attack_counterable(active_attack_data)
	if telegraph_visual != null:
		telegraph_visual.visible = telegraph_visible and _is_attack_counterable(active_attack_data)
	if warning_visual != null:
		warning_visual.visible = warning_visible
	if slam_visual != null:
		slam_visual.visible = (
			telegraph_visible
			and current_attack_kind == AttackKind.GROUND_SLAM
		)


func _update_debug_label() -> void:
	if debug_label == null or not debug_label.visible:
		return
	debug_label.text = (
		"%s | phase %s | %s | stagger %.0f%%"
		% [
			display_name,
			current_phase,
			_get_state_name(current_state),
			get_stagger_ratio() * 100.0,
		]
	)


func _get_state_name(state: int) -> String:
	match state:
		RuskState.INTRO: return "intro"
		RuskState.IDLE: return "idle"
		RuskState.REPOSITION: return "reposition"
		RuskState.CHOOSE_ATTACK: return "choose_attack"
		RuskState.ATTACK: return "attack"
		RuskState.RECOVERY: return "recovery"
		RuskState.HURT: return "hurt"
		RuskState.PHASE_TRANSITION: return "phase_transition"
		RuskState.STAGGERED: return "staggered"
		RuskState.DEAD: return "dead"
		_: return "unknown"
