extends Node
class_name VermiliteGunslingerVisualController

## Substitutable visual layer. AttackData remains combat authority. Physical ammo only.

signal animation_requested(animation_name: StringName)
signal visual_mode_changed(mode: EnemyVisualProfile.VisualMode)
signal visual_event(event_name: StringName, animation_name: StringName, frame_index: int)

const FEEDBACK_DIRECTOR_GROUP := "combat_feedback_director"
const HIT_FLASH_DURATION := 0.1
const LIGHT_RECOIL_PX := 4.0
const MEDIUM_RECOIL_PX := 8.0
const HEAVY_RECOIL_PX := 14.0
const DEATH_HOLD_EXTRA := 0.35

@export var profile: EnemyVisualProfile
@export var sprite_visual_path: NodePath = NodePath("../Visual/SpriteVisual")
@export var placeholder_body_path: NodePath = NodePath("../Visual/BodyVisual")
@export var placeholder_coat_path: NodePath = NodePath("../Visual/CoatVisual")
@export var placeholder_gun_path: NodePath = NodePath("../Visual/GunVisual")
@export var placeholder_tip_path: NodePath = NodePath("../Visual/VermiliteTip")
@export var aim_line_path: NodePath = NodePath("../Visual/AimVisual")
@export var alert_polygon_path: NodePath = NodePath("../Visual/AlertVisual")
@export var muzzle_glow_path: NodePath = NodePath("../Visual/MuzzleGlow")

var _enemy: CharacterBody2D = null
var _sprite: AnimatedSprite2D = null
var _placeholder_body: CanvasItem = null
var _placeholder_coat: CanvasItem = null
var _placeholder_gun: CanvasItem = null
var _placeholder_tip: CanvasItem = null
var _aim_line: CanvasItem = null
var _alert_polygon: CanvasItem = null
var _muzzle_glow: CanvasItem = null
var _current_animation: StringName = &""
var _sprite_ready: bool = false
var _death_playing: bool = false
var _hit_flash_timer: float = 0.0
var _recoil_offset: Vector2 = Vector2.ZERO
var _forced_reaction_clip: StringName = &""
var _forced_reaction_timer: float = 0.0
var _telegraph_emitted: bool = false
var _last_frame_index: int = -1
var _missing_clip_fallbacks: Dictionary = {}
var _muzzle_timer: float = 0.0


func setup(enemy: CharacterBody2D) -> void:
	_enemy = enemy
	_sprite = get_node_or_null(sprite_visual_path) as AnimatedSprite2D
	_placeholder_body = get_node_or_null(placeholder_body_path) as CanvasItem
	_placeholder_coat = get_node_or_null(placeholder_coat_path) as CanvasItem
	_placeholder_gun = get_node_or_null(placeholder_gun_path) as CanvasItem
	_placeholder_tip = get_node_or_null(placeholder_tip_path) as CanvasItem
	_aim_line = get_node_or_null(aim_line_path) as CanvasItem
	_alert_polygon = get_node_or_null(alert_polygon_path) as CanvasItem
	_muzzle_glow = get_node_or_null(muzzle_glow_path) as CanvasItem
	if _sprite != null and not _sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_apply_profile()


func set_profile(new_profile: EnemyVisualProfile) -> void:
	profile = new_profile
	_apply_profile()


func reset_visual() -> void:
	_death_playing = false
	_hit_flash_timer = 0.0
	_recoil_offset = Vector2.ZERO
	_forced_reaction_clip = &""
	_forced_reaction_timer = 0.0
	_telegraph_emitted = false
	_current_animation = &""
	_last_frame_index = -1
	_muzzle_timer = 0.0
	if _sprite != null:
		_sprite.modulate = Color.WHITE
		_sprite.position = Vector2.ZERO
	if _muzzle_glow != null:
		_muzzle_glow.visible = false
	_apply_profile()


func refresh(enemy: CharacterBody2D, delta: float = 0.0) -> bool:
	if enemy != null:
		_enemy = enemy
	_update_timers(delta)
	_update_accessible_telegraphs()

	if profile == null or profile.uses_placeholder():
		_show_placeholder(true)
		return false

	_show_placeholder(false)
	if _sprite == null or not _sprite_ready:
		return false

	if _death_playing:
		_apply_sprite_modulate()
		return true

	var desired := _resolve_animation()
	if desired == &"":
		return true
	_play_animation(desired)
	_apply_sprite_modulate()
	return true


func notify_attack_telegraph(attack_data: Resource) -> void:
	if profile == null or profile.uses_placeholder():
		return
	_telegraph_emitted = false
	_emit_telegraph_feedback(attack_data)
	_play_animation(&"aim")


func apply_hit_reaction(attack_data: Resource) -> void:
	if profile == null or profile.uses_placeholder() or _sprite == null:
		return
	var reaction := _resolve_hit_reaction(attack_data)
	_hit_flash_timer = HIT_FLASH_DURATION
	_forced_reaction_clip = reaction.clip
	_recoil_offset.x = reaction.recoil_px * float(_enemy.facing_direction)
	_forced_reaction_timer = 0.22
	_play_animation(reaction.clip)


func play_death() -> void:
	if profile == null or profile.uses_placeholder() or _sprite == null:
		return
	_death_playing = true
	_forced_reaction_clip = &""
	_forced_reaction_timer = 0.0
	_play_animation(&"death")
	var spec: Dictionary = VermiliteGunslingerAnimationContract.get_clip_specs().get("death", {})
	var hold := int(spec.get("frames", 6)) * float(spec.get("frame_duration", 0.1)) + DEATH_HOLD_EXTRA
	get_tree().create_timer(hold).timeout.connect(_on_death_hold_finished, CONNECT_ONE_SHOT)


func is_sprite_active() -> bool:
	return profile != null and not profile.uses_placeholder() and _sprite != null and _sprite_ready


func get_current_animation() -> StringName:
	return _current_animation


func get_debug_info() -> Dictionary:
	return {
		"visual_mode": _visual_mode_name(),
		"current_animation": String(_current_animation),
		"sprite_active": is_sprite_active(),
		"death_playing": _death_playing,
		"uses_production_sheets": (
			VermiliteGunslingerAnimationContract.profile_uses_production_sheets(profile)
			if profile != null else false
		),
		"approved_frame_size": VermiliteGunslingerAnimationContract.APPROVED_FRAME_SIZE,
		"ammo_rule": "physical_vermilite_slug_not_magic",
	}


func _apply_profile() -> void:
	_missing_clip_fallbacks.clear()
	if profile == null or profile.uses_placeholder():
		_sprite_ready = false
		_show_placeholder(true)
		return
	var frames := VermiliteGunslingerSpriteFramesBuilder.build_for_profile(profile)
	if frames == null or _sprite == null:
		VermiliteGunslingerAnimationContract.warn_missing_once(
			"profile build failed", "falling back to greybox polygons"
		)
		_sprite_ready = false
		_show_placeholder(true)
		return
	_sprite.sprite_frames = frames
	_sprite.offset = VermiliteGunslingerAnimationContract.SPRITE_VISUAL_OFFSET
	_sprite.centered = true
	_sprite.visible = true
	_sprite_ready = true
	_show_placeholder(false)
	visual_mode_changed.emit(profile.visual_mode)


func _show_placeholder(show_polygons: bool) -> void:
	for node in [_placeholder_body, _placeholder_coat, _placeholder_gun, _placeholder_tip]:
		if node != null:
			node.visible = show_polygons
	if _alert_polygon != null and show_polygons:
		pass
	if _sprite != null:
		_sprite.visible = not show_polygons and _sprite_ready


func _update_accessible_telegraphs() -> void:
	if _enemy == null:
		return
	var state_name: String = _enemy.call("_get_state_name", _enemy.get("current_state"))
	var aiming := state_name in ["aim", "shoot", "whip"]
	var alert := state_name == "alert"
	# Aim line stays readable even in sprite mode (accessibility telegraph).
	if _aim_line != null:
		_aim_line.visible = aiming
	if _alert_polygon != null:
		_alert_polygon.visible = alert and not is_sprite_active()
	if _muzzle_glow != null:
		_muzzle_glow.visible = _muzzle_timer > 0.0


func _resolve_animation() -> StringName:
	if _enemy == null or profile == null:
		return &""
	if _forced_reaction_timer > 0.0 and _forced_reaction_clip != &"":
		return _forced_reaction_clip

	var state_name: String = _enemy.call("_get_state_name", _enemy.get("current_state"))
	var phase := String(_enemy.get("attack_phase"))

	if state_name in ["aim", "whip"]:
		var phase_clip := profile.get_attack_phase_animation(phase)
		if phase_clip != &"":
			return phase_clip
		return &"aim"
	if state_name == "shoot":
		return &"fire"
	if state_name == "recovery":
		return &"recoil"
	if state_name == "reload":
		return &"reload"

	var mapped := profile.get_state_animation(state_name)
	if mapped != &"":
		return mapped
	return VermiliteGunslingerAnimationContract.DEFAULT_FALLBACK_ANIMATION


func _resolve_hit_reaction(attack_data: Resource) -> Dictionary:
	if attack_data == null:
		return {"clip": &"hurt", "recoil_px": LIGHT_RECOIL_PX}
	var attack_id := String(attack_data.get("attack_id"))
	if attack_id.contains("breaker") or attack_id.begins_with("red_brand_breaker"):
		return {"clip": &"hurt", "recoil_px": HEAVY_RECOIL_PX}
	if attack_id == "red_knuckle":
		return {"clip": &"hurt", "recoil_px": HEAVY_RECOIL_PX}
	var feedback := CombatFeedbackResolver.resolve_hit_feedback(attack_data, null, _enemy)
	var tier: int = int(feedback.get("tier", CombatFeedbackResolver.ImpactTier.LIGHT))
	match tier:
		CombatFeedbackResolver.ImpactTier.MEDIUM:
			return {"clip": &"hurt", "recoil_px": MEDIUM_RECOIL_PX}
		CombatFeedbackResolver.ImpactTier.HEAVY, CombatFeedbackResolver.ImpactTier.BREAKER:
			return {"clip": &"hurt", "recoil_px": HEAVY_RECOIL_PX}
		_:
			return {"clip": &"hurt", "recoil_px": LIGHT_RECOIL_PX}


func _play_animation(anim_name: StringName) -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var resolved := anim_name
	if not _sprite.sprite_frames.has_animation(resolved):
		resolved = _fallback_clip(resolved)
		if resolved == &"":
			return
	if _current_animation == resolved and _sprite.is_playing():
		return
	_current_animation = resolved
	_sprite.play(resolved)
	animation_requested.emit(resolved)


func _fallback_clip(requested: StringName) -> StringName:
	var key := String(requested)
	if _missing_clip_fallbacks.has(key):
		return _missing_clip_fallbacks[key]
	VermiliteGunslingerAnimationContract.warn_missing_once("missing clip", key)
	var fallback := VermiliteGunslingerAnimationContract.DEFAULT_FALLBACK_ANIMATION
	_missing_clip_fallbacks[key] = fallback
	return fallback


func _update_timers(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(_hit_flash_timer - delta, 0.0)
	if _muzzle_timer > 0.0:
		_muzzle_timer = maxf(_muzzle_timer - delta, 0.0)
	if _forced_reaction_timer > 0.0:
		_forced_reaction_timer = maxf(_forced_reaction_timer - delta, 0.0)
		if _forced_reaction_timer <= 0.0:
			_forced_reaction_clip = &""
			_recoil_offset = Vector2.ZERO
	if _sprite != null:
		_sprite.position = _recoil_offset if _recoil_offset != Vector2.ZERO else Vector2.ZERO


func _apply_sprite_modulate() -> void:
	if _sprite == null:
		return
	if _hit_flash_timer > 0.0:
		var flash_strength := _hit_flash_timer / HIT_FLASH_DURATION
		_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.92, 0.72, 1.0), flash_strength)
	else:
		_sprite.modulate = Color.WHITE


func _emit_telegraph_feedback(attack_data: Resource) -> void:
	if _telegraph_emitted:
		return
	_telegraph_emitted = true
	var counterable := false
	if attack_data != null:
		counterable = bool(attack_data.get("counterable"))
	var impact_pos := _enemy.global_position
	if _aim_line != null:
		impact_pos = _aim_line.global_position
	for director in get_tree().get_nodes_in_group(FEEDBACK_DIRECTOR_GROUP):
		if director.has_method("notify_telegraph"):
			director.call("notify_telegraph", impact_pos, counterable)
	_emit_visual_event(&"aim_line", &"aim", 0)


func _on_sprite_frame_changed() -> void:
	if _sprite == null or _current_animation == &"":
		return
	var frame_index := _sprite.frame
	if frame_index == _last_frame_index:
		return
	_last_frame_index = frame_index
	var events: Dictionary = VermiliteGunslingerAnimationContract.VISUAL_EVENT_FRAMES.get(
		String(_current_animation), {}
	)
	var frame_events: Variant = events.get(frame_index, [])
	if frame_events is Array:
		for event_name in frame_events:
			_emit_visual_event(event_name, _current_animation, frame_index)


func _emit_visual_event(event_name: StringName, anim_name: StringName, frame_index: int) -> void:
	visual_event.emit(event_name, anim_name, frame_index)
	match event_name:
		&"muzzle_flash", &"muzzle_charge":
			_muzzle_timer = 0.12
			if _muzzle_glow != null:
				_muzzle_glow.visible = true
		_:
			pass


func _on_death_hold_finished() -> void:
	if _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"death"):
		var last_frame := _sprite.sprite_frames.get_frame_count(&"death") - 1
		_sprite.frame = maxi(last_frame, 0)
		_sprite.pause()


func _visual_mode_name() -> String:
	if profile == null:
		return "none"
	match profile.visual_mode:
		EnemyVisualProfile.VisualMode.PLACEHOLDER:
			return "placeholder"
		EnemyVisualProfile.VisualMode.PILOT:
			return "pilot"
		EnemyVisualProfile.VisualMode.FINAL:
			return "final"
		_:
			return "unknown"
