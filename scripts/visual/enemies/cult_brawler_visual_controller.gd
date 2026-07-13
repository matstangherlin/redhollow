extends Node
class_name CultBrawlerVisualController

## Substitutable visual layer for Cult Brawler. Gameplay/hitboxes ignore this node.

signal animation_requested(animation_name: StringName)
signal visual_mode_changed(mode: EnemyVisualProfile.VisualMode)
signal visual_event(
	event_name: StringName,
	animation_name: StringName,
	frame_index: int
)

const FEEDBACK_DIRECTOR_GROUP := "combat_feedback_director"
const HIT_FLASH_DURATION := 0.1
const LIGHT_RECOIL_PX := 4.0
const MEDIUM_RECOIL_PX := 8.0
const HEAVY_RECOIL_PX := 14.0
const DEATH_HOLD_EXTRA := 0.35

@export var profile: EnemyVisualProfile
@export var sprite_visual_path: NodePath = NodePath("../Visual/SpriteVisual")
@export var placeholder_body_path: NodePath = NodePath("../Visual/BodyVisual")
@export var placeholder_head_path: NodePath = NodePath("../Visual/HeadVisual")
@export var placeholder_mark_path: NodePath = NodePath("../Visual/CultMark")
@export var telegraph_polygon_path: NodePath = NodePath("../Visual/TelegraphVisual")
@export var alert_polygon_path: NodePath = NodePath("../Visual/AlertVisual")
@export var telegraph_ground_path: NodePath = NodePath("../Visual/TelegraphGround")

var _brawler: CharacterBody2D = null
var _sprite: AnimatedSprite2D = null
var _placeholder_body: CanvasItem = null
var _placeholder_head: CanvasItem = null
var _placeholder_mark: CanvasItem = null
var _telegraph_polygon: CanvasItem = null
var _alert_polygon: CanvasItem = null
var _telegraph_ground: Node2D = null
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


func setup(brawler: CharacterBody2D) -> void:
	_brawler = brawler
	_sprite = get_node_or_null(sprite_visual_path) as AnimatedSprite2D
	_placeholder_body = get_node_or_null(placeholder_body_path) as CanvasItem
	_placeholder_head = get_node_or_null(placeholder_head_path) as CanvasItem
	_placeholder_mark = get_node_or_null(placeholder_mark_path) as CanvasItem
	_telegraph_polygon = get_node_or_null(telegraph_polygon_path) as CanvasItem
	_alert_polygon = get_node_or_null(alert_polygon_path) as CanvasItem
	_telegraph_ground = get_node_or_null(telegraph_ground_path) as Node2D

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
	if _sprite != null:
		_sprite.modulate = Color.WHITE
	_apply_profile()


func refresh(brawler: CharacterBody2D, delta: float = 0.0) -> bool:
	if brawler != null:
		_brawler = brawler

	_update_timers(delta)

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
	_play_animation(&"attack_startup")


func apply_hit_reaction(attack_data: Resource) -> void:
	if profile == null or profile.uses_placeholder() or _sprite == null:
		return

	var reaction := _resolve_hit_reaction(attack_data)
	_hit_flash_timer = HIT_FLASH_DURATION
	_forced_reaction_clip = reaction.clip
	_recoil_offset.x = reaction.recoil_px * float(_brawler.facing_direction)
	_forced_reaction_timer = 0.22

	if reaction.clip == &"stagger":
		_emit_visual_event(&"vermilite_flash", reaction.clip, 0)

	_play_animation(reaction.clip)


func _resolve_hit_reaction(attack_data: Resource) -> Dictionary:
	if attack_data == null:
		return {"clip": &"hurt", "recoil_px": LIGHT_RECOIL_PX}

	var attack_id := String(attack_data.get("attack_id"))
	if attack_id.contains("breaker") or attack_id.begins_with("red_brand_breaker"):
		return {"clip": &"stagger", "recoil_px": HEAVY_RECOIL_PX}
	if attack_id == "red_knuckle":
		return {"clip": &"knocked_back", "recoil_px": HEAVY_RECOIL_PX}
	if attack_id == "body_hook":
		return {"clip": &"heavy_hurt", "recoil_px": MEDIUM_RECOIL_PX}
	if attack_id == "calder_straight":
		return {"clip": &"hurt", "recoil_px": LIGHT_RECOIL_PX}

	var feedback := CombatFeedbackResolver.resolve_hit_feedback(attack_data, null, _brawler)
	var tier: int = int(feedback.get("tier", CombatFeedbackResolver.ImpactTier.LIGHT))
	match tier:
		CombatFeedbackResolver.ImpactTier.MEDIUM:
			return {"clip": &"heavy_hurt", "recoil_px": MEDIUM_RECOIL_PX}
		CombatFeedbackResolver.ImpactTier.HEAVY, CombatFeedbackResolver.ImpactTier.BREAKER:
			return {"clip": &"knocked_back", "recoil_px": HEAVY_RECOIL_PX}
		_:
			return {"clip": &"hurt", "recoil_px": LIGHT_RECOIL_PX}


func play_death() -> void:
	if profile == null or profile.uses_placeholder() or _sprite == null:
		return

	_death_playing = true
	_forced_reaction_clip = &""
	_forced_reaction_timer = 0.0
	_play_animation(&"death")

	var spec: Dictionary = CultBrawlerAnimationContract.get_clip_specs().get("death", {})
	var frame_count: int = int(spec.get("frames", 8))
	var frame_duration: float = float(spec.get("frame_duration", 0.1))
	var hold := frame_count * frame_duration + DEATH_HOLD_EXTRA
	get_tree().create_timer(hold).timeout.connect(_on_death_hold_finished, CONNECT_ONE_SHOT)


func is_sprite_active() -> bool:
	return profile != null and not profile.uses_placeholder() and _sprite != null and _sprite_ready


func get_current_animation() -> StringName:
	return _current_animation


func get_debug_info() -> Dictionary:
	return {
		"visual_mode": _visual_mode_name(),
		"current_animation": String(_current_animation),
		"current_frame": _sprite.frame if _sprite != null else -1,
		"sprite_active": is_sprite_active(),
		"death_playing": _death_playing,
		"uses_production_sheets": (
			CultBrawlerAnimationContract.profile_uses_production_sheets(profile)
			if profile != null else false
		),
		"approved_frame_size": CultBrawlerAnimationContract.APPROVED_FRAME_SIZE,
		"gameplay_collision_size": CultBrawlerAnimationContract.GAMEPLAY_COLLISION_SIZE,
	}


func _apply_profile() -> void:
	_missing_clip_fallbacks.clear()
	if profile == null:
		_sprite_ready = false
		_show_placeholder(true)
		return

	if profile.uses_placeholder():
		_sprite_ready = false
		_show_placeholder(true)
		return

	var frames := CultBrawlerSpriteFramesBuilder.build_for_profile(profile)
	if frames == null or _sprite == null:
		CultBrawlerAnimationContract.warn_missing_once(
			"profile build failed",
			"falling back to greybox polygons"
		)
		_sprite_ready = false
		_show_placeholder(true)
		return

	_sprite.sprite_frames = frames
	_sprite.offset = CultBrawlerAnimationContract.SPRITE_VISUAL_OFFSET
	_sprite.centered = true
	_sprite.visible = true
	_sprite_ready = true
	_show_placeholder(false)
	visual_mode_changed.emit(profile.visual_mode)


func _show_placeholder(show_polygons: bool) -> void:
	if _placeholder_body != null:
		_placeholder_body.visible = show_polygons
	if _placeholder_head != null:
		_placeholder_head.visible = show_polygons
	if _placeholder_mark != null:
		_placeholder_mark.visible = show_polygons
	if _telegraph_polygon != null:
		_telegraph_polygon.visible = false
	if _alert_polygon != null:
		_alert_polygon.visible = false
	if _sprite != null:
		_sprite.visible = not show_polygons and _sprite_ready


func _resolve_animation() -> StringName:
	if _brawler == null or profile == null:
		return &""

	if _forced_reaction_timer > 0.0 and _forced_reaction_clip != &"":
		return _forced_reaction_clip

	var state_name: String = _brawler.call("_get_state_name", _brawler.get("current_state"))
	if state_name == "attack":
		var phase := String(_brawler.get("attack_phase"))
		var phase_clip := profile.get_attack_phase_animation(phase)
		if phase_clip != &"":
			return phase_clip
		return &"attack_startup"
	if state_name == "recovery":
		return profile.get_attack_phase_animation("recovery")

	var mapped := profile.get_state_animation(state_name)
	if mapped != &"":
		return mapped

	return CultBrawlerAnimationContract.DEFAULT_FALLBACK_ANIMATION


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

	CultBrawlerAnimationContract.warn_missing_once("missing clip", key)
	var fallback := CultBrawlerAnimationContract.DEFAULT_FALLBACK_ANIMATION
	_missing_clip_fallbacks[key] = fallback
	return fallback


func _update_timers(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(_hit_flash_timer - delta, 0.0)

	if _forced_reaction_timer > 0.0:
		_forced_reaction_timer = maxf(_forced_reaction_timer - delta, 0.0)
		if _forced_reaction_timer <= 0.0:
			_forced_reaction_clip = &""
			_recoil_offset = Vector2.ZERO

	if _sprite != null and _recoil_offset != Vector2.ZERO:
		_sprite.position = _recoil_offset
	else:
		if _sprite != null:
			_sprite.position = Vector2.ZERO


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

	var impact_pos := _brawler.global_position
	if _telegraph_ground != null:
		impact_pos = _telegraph_ground.global_position

	for director in get_tree().get_nodes_in_group(FEEDBACK_DIRECTOR_GROUP):
		if director.has_method("notify_telegraph"):
			director.call("notify_telegraph", impact_pos, counterable)

	_emit_visual_event(&"telegraph_pose", &"attack_startup", 0)


func _on_sprite_frame_changed() -> void:
	if _sprite == null or _current_animation == &"":
		return

	var frame_index := _sprite.frame
	if frame_index == _last_frame_index:
		return
	_last_frame_index = frame_index

	var events: Dictionary = CultBrawlerAnimationContract.VISUAL_EVENT_FRAMES.get(
		String(_current_animation), {}
	)
	var frame_events: Variant = events.get(frame_index, [])
	if frame_events is Array:
		for event_name in frame_events:
			_emit_visual_event(event_name, _current_animation, frame_index)


func _emit_visual_event(event_name: StringName, anim_name: StringName, frame_index: int) -> void:
	visual_event.emit(event_name, anim_name, frame_index)

	match event_name:
		&"ground_glow":
			_spawn_ground_glow()
		&"footstep":
			pass
		&"sound", &"hit_flash", &"vermilite_flash", &"screen_shake_request":
			pass


func _spawn_ground_glow() -> void:
	if _telegraph_ground == null:
		return
	for director in get_tree().get_nodes_in_group(FEEDBACK_DIRECTOR_GROUP):
		if director.has_method("notify_telegraph"):
			director.call("notify_telegraph", _telegraph_ground.global_position, true)


func _on_death_hold_finished() -> void:
	if _sprite != null and _sprite.sprite_frames != null:
		if _sprite.sprite_frames.has_animation(&"death"):
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
