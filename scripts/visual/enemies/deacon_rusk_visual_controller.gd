extends Node
class_name DeaconRuskVisualController

## Boss visual layer. Does not change AI or AttackData timings.

signal animation_requested(animation_name: StringName)
signal visual_event(event_name: StringName, animation_name: StringName, frame_index: int)

const FEEDBACK_DIRECTOR_GROUP := "combat_feedback_director"
const HIT_FLASH_DURATION := 0.12
const DEATH_HOLD_EXTRA := 0.4

@export var profile: EnemyVisualProfile
@export var sprite_visual_path: NodePath = NodePath("../Visual/SpriteVisual")
@export var placeholder_body_path: NodePath = NodePath("../Visual/BodyVisual")
@export var placeholder_mantle_path: NodePath = NodePath("../Visual/MantleVisual")
@export var placeholder_head_path: NodePath = NodePath("../Visual/HeadVisual")
@export var placeholder_crown_path: NodePath = NodePath("../Visual/CrownVisual")
@export var telegraph_path: NodePath = NodePath("../Visual/TelegraphVisual")
@export var warning_path: NodePath = NodePath("../Visual/WarningVisual")
@export var slam_path: NodePath = NodePath("../Visual/SlamVisual")

var _boss: CharacterBody2D = null
var _sprite: AnimatedSprite2D = null
var _placeholders: Array[CanvasItem] = []
var _telegraph: CanvasItem = null
var _warning: CanvasItem = null
var _slam: CanvasItem = null
var _current_animation: StringName = &""
var _sprite_ready: bool = false
var _death_playing: bool = false
var _hit_flash_timer: float = 0.0
var _forced_reaction_clip: StringName = &""
var _forced_reaction_timer: float = 0.0
var _telegraph_emitted: bool = false
var _last_frame_index: int = -1
var _missing_clip_fallbacks: Dictionary = {}


func setup(boss: CharacterBody2D) -> void:
	_boss = boss
	_sprite = get_node_or_null(sprite_visual_path) as AnimatedSprite2D
	_placeholders.clear()
	for path in [placeholder_body_path, placeholder_mantle_path, placeholder_head_path, placeholder_crown_path]:
		var node := get_node_or_null(path) as CanvasItem
		if node != null:
			_placeholders.append(node)
	_telegraph = get_node_or_null(telegraph_path) as CanvasItem
	_warning = get_node_or_null(warning_path) as CanvasItem
	_slam = get_node_or_null(slam_path) as CanvasItem
	if _sprite != null and not _sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_apply_profile()


func reset_visual() -> void:
	_death_playing = false
	_hit_flash_timer = 0.0
	_forced_reaction_clip = &""
	_forced_reaction_timer = 0.0
	_telegraph_emitted = false
	_current_animation = &""
	_last_frame_index = -1
	if _sprite != null:
		_sprite.modulate = Color.WHITE
		_sprite.position = Vector2.ZERO
	_apply_profile()


func refresh(boss: CharacterBody2D, delta: float = 0.0) -> bool:
	if boss != null:
		_boss = boss
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
	if desired != &"":
		_play_animation(desired)
	_apply_sprite_modulate()
	return true


func notify_attack_telegraph(attack_data: Resource) -> void:
	if profile == null or profile.uses_placeholder():
		return
	_telegraph_emitted = false
	_emit_telegraph_feedback(attack_data)
	var clip := _attack_clip_for_boss()
	if clip != &"":
		_play_animation(clip)


func apply_hit_reaction(attack_data: Resource) -> void:
	if profile == null or profile.uses_placeholder() or _sprite == null:
		return
	_hit_flash_timer = HIT_FLASH_DURATION
	var clip := &"hurt"
	if attack_data != null:
		var attack_id := String(attack_data.get("attack_id"))
		if attack_id.contains("breaker") or attack_id.begins_with("red_brand_breaker"):
			clip = &"stagger"
	_forced_reaction_clip = clip
	_forced_reaction_timer = 0.25
	_play_animation(clip)


func play_death() -> void:
	if profile == null or profile.uses_placeholder() or _sprite == null:
		return
	_death_playing = true
	_forced_reaction_clip = &""
	_forced_reaction_timer = 0.0
	_play_animation(&"death")
	var spec: Dictionary = DeaconRuskAnimationContract.get_clip_specs().get("death", {})
	var hold := int(spec.get("frames", 8)) * float(spec.get("frame_duration", 0.1)) + DEATH_HOLD_EXTRA
	get_tree().create_timer(hold).timeout.connect(_on_death_hold_finished, CONNECT_ONE_SHOT)


func is_sprite_active() -> bool:
	return profile != null and not profile.uses_placeholder() and _sprite != null and _sprite_ready


func get_current_animation() -> StringName:
	return _current_animation


func get_debug_info() -> Dictionary:
	return {
		"current_animation": String(_current_animation),
		"sprite_active": is_sprite_active(),
		"death_playing": _death_playing,
		"approved_frame_size": DeaconRuskAnimationContract.APPROVED_FRAME_SIZE,
		"gameplay_collision_size": DeaconRuskAnimationContract.GAMEPLAY_COLLISION_SIZE,
	}


func _apply_profile() -> void:
	_missing_clip_fallbacks.clear()
	if profile == null or profile.uses_placeholder():
		_sprite_ready = false
		_show_placeholder(true)
		return
	var frames := DeaconRuskSpriteFramesBuilder.build_for_profile(profile)
	if frames == null or _sprite == null:
		DeaconRuskAnimationContract.warn_missing_once("profile build failed", "greybox polygons")
		_sprite_ready = false
		_show_placeholder(true)
		return
	_sprite.sprite_frames = frames
	_sprite.offset = DeaconRuskAnimationContract.SPRITE_VISUAL_OFFSET
	_sprite.centered = true
	_sprite.visible = true
	_sprite_ready = true
	_show_placeholder(false)


func _show_placeholder(show_polygons: bool) -> void:
	for node in _placeholders:
		if node != null:
			node.visible = show_polygons
	if _sprite != null:
		_sprite.visible = not show_polygons and _sprite_ready


func _update_accessible_telegraphs() -> void:
	if _boss == null:
		return
	var state_name: String = _boss.call("_get_state_name", _boss.get("current_state"))
	var phase := String(_boss.get("attack_phase"))
	var startup := state_name in ["attack", "recovery"] and phase == "startup"
	var attack_kind: int = int(_boss.get("current_attack_kind"))
	# AttackKind: PUNISH_SWEEP=3 counterable, GROUND_SLAM=5, ARMORED=6 often not counterable
	var counterable := startup and attack_kind == 3
	var slam := startup and attack_kind == 5
	var armored := startup and attack_kind == 6
	if _telegraph != null:
		_telegraph.visible = counterable or (startup and not armored and not slam and attack_kind != 0)
	if _warning != null:
		_warning.visible = armored or (startup and not counterable and attack_kind in [2, 6])
	if _slam != null:
		_slam.visible = slam


func _resolve_animation() -> StringName:
	if _boss == null or profile == null:
		return &""
	if _forced_reaction_timer > 0.0 and _forced_reaction_clip != &"":
		return _forced_reaction_clip
	var state_name: String = _boss.call("_get_state_name", _boss.get("current_state"))
	match state_name:
		"intro", "phase_transition":
			return &"phase_transition"
		"reposition":
			return &"reposition"
		"hurt":
			return &"hurt"
		"staggered":
			return &"stagger"
		"dead":
			return &"death"
		"attack", "recovery":
			return _attack_clip_for_boss()
		_:
			return profile.get_state_animation(state_name) if profile.get_state_animation(state_name) != &"" else &"idle"


func _attack_clip_for_boss() -> StringName:
	var attack_kind: int = int(_boss.get("current_attack_kind"))
	match attack_kind:
		1: # DOUBLE_JAB
			return &"punch_combo"
		2: # CHARGE
			return &"charge"
		3: # PUNISH_SWEEP
			return &"counterable_attack"
		5: # GROUND_SLAM
			return &"ground_attack"
		6: # ARMORED_CHARGE
			return &"armor_attack"
		4, 7: # retreat / taunt
			return &"idle"
		_:
			return &"punch_combo"


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
	DeaconRuskAnimationContract.warn_missing_once("missing clip", key)
	_missing_clip_fallbacks[key] = DeaconRuskAnimationContract.DEFAULT_FALLBACK_ANIMATION
	return DeaconRuskAnimationContract.DEFAULT_FALLBACK_ANIMATION


func _update_timers(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(_hit_flash_timer - delta, 0.0)
	if _forced_reaction_timer > 0.0:
		_forced_reaction_timer = maxf(_forced_reaction_timer - delta, 0.0)
		if _forced_reaction_timer <= 0.0:
			_forced_reaction_clip = &""


func _apply_sprite_modulate() -> void:
	if _sprite == null:
		return
	if _hit_flash_timer > 0.0:
		_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.9, 0.7, 1.0), _hit_flash_timer / HIT_FLASH_DURATION)
	else:
		_sprite.modulate = Color.WHITE


func _emit_telegraph_feedback(attack_data: Resource) -> void:
	if _telegraph_emitted:
		return
	_telegraph_emitted = true
	var counterable := false
	if attack_data != null:
		counterable = bool(attack_data.get("counterable"))
	for director in get_tree().get_nodes_in_group(FEEDBACK_DIRECTOR_GROUP):
		if director.has_method("notify_telegraph"):
			director.call("notify_telegraph", _boss.global_position, counterable)


func _on_sprite_frame_changed() -> void:
	if _sprite == null or _current_animation == &"":
		return
	var frame_index := _sprite.frame
	if frame_index == _last_frame_index:
		return
	_last_frame_index = frame_index
	var events: Dictionary = DeaconRuskAnimationContract.VISUAL_EVENT_FRAMES.get(String(_current_animation), {})
	var frame_events: Variant = events.get(frame_index, [])
	if frame_events is Array:
		for event_name in frame_events:
			visual_event.emit(event_name, _current_animation, frame_index)


func _on_death_hold_finished() -> void:
	if _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(&"death"):
		_sprite.frame = maxi(_sprite.sprite_frames.get_frame_count(&"death") - 1, 0)
		_sprite.pause()
