extends Node
class_name PlayerVisualController

## Substitutable visual layer for Calder. Gameplay/hitboxes ignore this node.

signal animation_requested(animation_name: StringName)
signal visual_mode_changed(mode: PlayerVisualProfile.VisualMode)
signal visual_event(
	event_name: StringName,
	animation_name: StringName,
	frame_index: int
)

@export var profile: PlayerVisualProfile
@export var sprite_visual_path: NodePath = NodePath("../../Visual/SpriteVisual")
@export var placeholder_body_path: NodePath = NodePath("../../Visual/BodyVisual")
@export var placeholder_brand_path: NodePath = NodePath("../../Visual/BrandHand")

const LAND_BLEND_TIME := 0.14

var _player: CharacterBody2D = null
var _sprite: AnimatedSprite2D = null
var _placeholder_body: CanvasItem = null
var _placeholder_brand: CanvasItem = null
var _current_animation: StringName = &""
var _sprite_ready: bool = false
var _was_on_floor: bool = false
var _land_timer: float = 0.0
var _last_frame_index: int = -1
var _missing_clip_fallbacks: Dictionary = {}


func setup(player: CharacterBody2D) -> void:
	_player = player
	_sprite = get_node_or_null(sprite_visual_path) as AnimatedSprite2D
	_placeholder_body = get_node_or_null(placeholder_body_path) as CanvasItem
	_placeholder_brand = get_node_or_null(placeholder_brand_path) as CanvasItem
	if _sprite != null and not _sprite.frame_changed.is_connected(_on_sprite_frame_changed):
		_sprite.frame_changed.connect(_on_sprite_frame_changed)
	_apply_profile()


func set_profile(new_profile: PlayerVisualProfile) -> void:
	profile = new_profile
	_apply_profile()


func refresh_from_player(attack_controller: PlayerAttackController) -> void:
	if _player == null or profile == null:
		return

	if profile.uses_placeholder():
		_show_placeholder(true)
		return

	_show_placeholder(false)
	if _sprite == null or not _sprite_ready:
		return

	_update_landing_timer()
	var desired := _resolve_animation(attack_controller)
	if desired == &"":
		return

	_play_animation(desired)


func get_current_animation() -> StringName:
	return _current_animation


func get_current_frame_index() -> int:
	if _sprite == null:
		return -1
	return _sprite.frame


func get_visual_mode() -> PlayerVisualProfile.VisualMode:
	if profile == null:
		return PlayerVisualProfile.VisualMode.PLACEHOLDER
	return profile.visual_mode


func is_sprite_active() -> bool:
	return _sprite != null and _sprite.visible and _sprite_ready


func get_debug_info() -> Dictionary:
	var sprite_rect := Rect2()
	if _sprite != null and _sprite.sprite_frames != null and _current_animation != &"":
		if _sprite.sprite_frames.has_animation(_current_animation):
			var frame_tex := _sprite.sprite_frames.get_frame_texture(_current_animation, _sprite.frame)
			if frame_tex != null:
				var size := frame_tex.get_size()
				sprite_rect = Rect2(
					_sprite.global_position - size * 0.5 + _sprite.offset,
					size
				)

	return {
		"visual_mode": _visual_mode_name(),
		"current_animation": String(_current_animation),
		"current_frame": get_current_frame_index(),
		"sprite_active": is_sprite_active(),
		"sprite_rect": sprite_rect,
		"pivot_global": _player.global_position if _player != null else Vector2.ZERO,
		"sprite_offset": _sprite.offset if _sprite != null else Vector2.ZERO,
		"facing_direction": int(_player.facing_direction) if _player != null else 1,
		"uses_production_sheets": (
			CalderAnimationContract.profile_uses_production_sheets(profile)
			if profile != null else false
		),
		"approved_frame_size": CalderAnimationContract.APPROVED_FRAME_SIZE,
		"gameplay_collision_size": CalderAnimationContract.GAMEPLAY_COLLISION_SIZE,
	}


func _apply_profile() -> void:
	_missing_clip_fallbacks.clear()
	if profile == null:
		_show_placeholder(true)
		return

	if profile.uses_placeholder():
		_show_placeholder(true)
		visual_mode_changed.emit(profile.visual_mode)
		return

	if _sprite == null:
		CalderAnimationContract.warn_missing_once("SpriteVisual missing", "using greybox placeholder")
		_show_placeholder(true)
		return

	var sprite_frames := CalderSpriteFramesBuilder.build_for_profile(profile)
	_sprite.sprite_frames = sprite_frames
	var use_production := CalderAnimationContract.profile_uses_production_sheets(profile)
	_sprite.offset = CalderAnimationContract.get_sprite_visual_offset(use_production)
	_sprite.centered = true
	_sprite_ready = sprite_frames != null and sprite_frames.get_animation_names().size() > 0
	_show_placeholder(not _sprite_ready)
	visual_mode_changed.emit(profile.visual_mode)


func _show_placeholder(show_placeholder: bool) -> void:
	if _placeholder_body != null:
		_placeholder_body.visible = show_placeholder
	if _placeholder_brand != null:
		_placeholder_brand.visible = show_placeholder
	if _sprite != null:
		_sprite.visible = not show_placeholder


func _resolve_animation(attack_controller: PlayerAttackController) -> StringName:
	if attack_controller != null and attack_controller.current_attack != null:
		var attack_id: StringName = attack_controller.current_attack.get("attack_id")
		var attack_anim := profile.get_attack_animation(attack_id)
		if attack_anim != &"":
			return attack_anim

	if _land_timer > 0.0:
		return &"land"

	var state: int = int(_player.get("current_state"))
	var state_name := _state_name_from_id(state)
	var mapped := profile.get_state_animation(state_name)
	if mapped != &"":
		return mapped

	match state:
		PlayerStateTypes.PlayerState.RUN:
			return &"run"
		PlayerStateTypes.PlayerState.JUMP:
			if float(_player.velocity.y) < 0.0:
				return &"jump_rise"
			return &"fall"
		PlayerStateTypes.PlayerState.FALL:
			return &"fall"
		PlayerStateTypes.PlayerState.DODGE:
			return &"dodge"
		PlayerStateTypes.PlayerState.HURT:
			return &"hurt"
		_:
			return &"idle"


func _play_animation(desired: StringName) -> void:
	var clip := _resolve_clip_with_fallback(desired)
	if clip == &"":
		return

	if clip != _current_animation or not _sprite.is_playing():
		_sprite.play(clip)
		_current_animation = clip
		_last_frame_index = -1
		animation_requested.emit(clip)


func _resolve_clip_with_fallback(desired: StringName) -> StringName:
	if _sprite.sprite_frames == null:
		return &""

	if _sprite.sprite_frames.has_animation(desired):
		return desired

	if _missing_clip_fallbacks.has(desired):
		return _missing_clip_fallbacks[desired]

	CalderAnimationContract.warn_missing_once(
		"missing animation clip",
		"%s — substituting idle" % desired
	)
	var fallback := CalderAnimationContract.DEFAULT_FALLBACK_ANIMATION
	if not _sprite.sprite_frames.has_animation(fallback):
		fallback = StringName(_sprite.sprite_frames.get_animation_names()[0])
	_missing_clip_fallbacks[desired] = fallback
	return fallback


func _update_landing_timer(delta: float = 0.0) -> void:
	if _player == null:
		return

	var on_floor: bool = _player.is_on_floor()
	if on_floor and not _was_on_floor and float(_player.velocity.y) >= 0.0:
		_land_timer = LAND_BLEND_TIME
	elif _land_timer > 0.0:
		var step := delta if delta > 0.0 else _estimate_physics_step()
		_land_timer = maxf(_land_timer - step, 0.0)

	_was_on_floor = on_floor


func _estimate_physics_step() -> float:
	return 1.0 / float(Engine.get_physics_ticks_per_second())


func _on_sprite_frame_changed() -> void:
	if _sprite == null or _current_animation == &"":
		return

	var frame_index := _sprite.frame
	if frame_index == _last_frame_index:
		return
	_last_frame_index = frame_index

	var event_names := CalderAnimationContract.get_visual_events(_current_animation, frame_index)
	for event_name in event_names:
		if event_name != &"":
			visual_event.emit(event_name, _current_animation, frame_index)


func _state_name_from_id(state: int) -> String:
	match state:
		PlayerStateTypes.PlayerState.IDLE:
			return "idle"
		PlayerStateTypes.PlayerState.RUN:
			return "run"
		PlayerStateTypes.PlayerState.JUMP:
			return "jump"
		PlayerStateTypes.PlayerState.FALL:
			return "fall"
		PlayerStateTypes.PlayerState.DODGE:
			return "dodge"
		PlayerStateTypes.PlayerState.HURT:
			return "hurt"
		_:
			return "idle"


func _visual_mode_name() -> String:
	match get_visual_mode():
		PlayerVisualProfile.VisualMode.PLACEHOLDER:
			return "PLACEHOLDER"
		PlayerVisualProfile.VisualMode.PILOT:
			return "PILOT"
		PlayerVisualProfile.VisualMode.FINAL:
			return "FINAL"
		_:
			return "UNKNOWN"
