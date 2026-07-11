extends Node
class_name PlayerVisualController

## Substitutable visual layer for Calder. Gameplay/hitboxes ignore this node.

signal animation_requested(animation_name: StringName)
signal visual_mode_changed(mode: PlayerVisualProfile.VisualMode)

@export var profile: PlayerVisualProfile
@export var sprite_visual_path: NodePath = NodePath("../../Visual/SpriteVisual")
@export var placeholder_body_path: NodePath = NodePath("../../Visual/BodyVisual")
@export var placeholder_brand_path: NodePath = NodePath("../../Visual/BrandHand")

var _player: CharacterBody2D = null
var _sprite: AnimatedSprite2D = null
var _placeholder_body: CanvasItem = null
var _placeholder_brand: CanvasItem = null
var _current_animation: StringName = &""
var _sprite_ready: bool = false


func setup(player: CharacterBody2D) -> void:
	_player = player
	_sprite = get_node_or_null(sprite_visual_path) as AnimatedSprite2D
	_placeholder_body = get_node_or_null(placeholder_body_path) as CanvasItem
	_placeholder_brand = get_node_or_null(placeholder_brand_path) as CanvasItem
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
	if _sprite == null:
		return

	var desired := _resolve_animation(attack_controller)
	if desired == &"":
		return

	if desired != _current_animation or not _sprite.is_playing():
		_sprite.play(desired)
		_current_animation = desired
		animation_requested.emit(desired)


func get_current_animation() -> StringName:
	return _current_animation


func get_visual_mode() -> PlayerVisualProfile.VisualMode:
	if profile == null:
		return PlayerVisualProfile.VisualMode.PLACEHOLDER
	return profile.visual_mode


func _apply_profile() -> void:
	if profile == null:
		_show_placeholder(true)
		return

	if profile.uses_placeholder():
		_show_placeholder(true)
		visual_mode_changed.emit(profile.visual_mode)
		return

	if _sprite == null:
		push_warning("PlayerVisualController: SpriteVisual missing.")
		_show_placeholder(true)
		return

	if profile.is_pilot_profile() and profile.use_procedural_pilot_frames:
		_sprite.sprite_frames = PlaceholderSpriteFactory.create_calder_pilot_sprite_frames()
	elif not profile.sprite_frames_path.is_empty():
		var loaded: Variant = load(profile.sprite_frames_path)
		if loaded is SpriteFrames:
			_sprite.sprite_frames = loaded

	_sprite.offset = Vector2(0, -28)
	_sprite.centered = true
	_sprite_ready = _sprite.sprite_frames != null
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

	var state: int = int(_player.get("current_state"))
	match state:
		PlayerStateTypes.PlayerState.RUN:
			return &"run"
		PlayerStateTypes.PlayerState.JUMP, PlayerStateTypes.PlayerState.FALL:
			return &"jump"
		_:
			return &"idle"
