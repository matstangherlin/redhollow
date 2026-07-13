extends Node2D
class_name PlayerVisualDebugOverlay

## Draws sprite/collision/hitbox debug guides when player debug mode is active.

const COLOR_COLLISION := Color(0.2, 0.85, 1.0, 0.55)
const COLOR_HURTBOX := Color(1.0, 0.35, 0.35, 0.45)
const COLOR_HITBOX := Color(1.0, 0.85, 0.2, 0.55)
const COLOR_SPRITE := Color(0.45, 1.0, 0.55, 0.55)
const COLOR_PIVOT := Color(1.0, 1.0, 1.0, 0.9)
const COLOR_GROUND := Color(0.75, 0.65, 0.45, 0.35)
const COLOR_FACING := Color(1.0, 0.82, 0.32, 0.9)
const COLOR_LABEL := Color(0.95, 0.92, 0.82, 0.95)

var enabled: bool = false

var _player: CharacterBody2D = null
var _collision_shape: CollisionShape2D = null
var _hurtbox: Area2D = null
var _hitbox: Area2D = null
var _visual_controller: PlayerVisualController = null
var _sprite_visual: AnimatedSprite2D = null


func setup(
	player: CharacterBody2D,
	collision_shape: CollisionShape2D,
	hurtbox: Area2D,
	hitbox: Area2D,
	visual_controller: PlayerVisualController
) -> void:
	_player = player
	_collision_shape = collision_shape
	_hurtbox = hurtbox
	_hitbox = hitbox
	_visual_controller = visual_controller
	if _player != null:
		_sprite_visual = _player.get_node_or_null("Visual/SpriteVisual") as AnimatedSprite2D
	visible = false
	set_process(false)


func set_overlay_enabled(is_enabled: bool) -> void:
	enabled = is_enabled
	visible = is_enabled
	set_process(is_enabled)


func _process(_delta: float) -> void:
	if enabled:
		queue_redraw()


func _draw() -> void:
	if not enabled or _player == null:
		return

	_draw_collision()
	_draw_area_shape(_hurtbox, COLOR_HURTBOX)
	_draw_area_shape(_hitbox, COLOR_HITBOX)
	_draw_sprite_bounds()
	_draw_pivot()
	_draw_facing()
	_draw_ground_line()
	_draw_hud_labels()


func _draw_collision() -> void:
	if _collision_shape == null or _collision_shape.shape == null:
		return
	var local_rect := _shape_local_rect(_collision_shape)
	if local_rect.size == Vector2.ZERO:
		return
	var global_rect := _to_overlay_rect(_collision_shape, local_rect)
	draw_rect(global_rect, COLOR_COLLISION, false, 1.5)


func _draw_area_shape(area: Area2D, color: Color) -> void:
	if area == null:
		return
	var shape_node := area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null or shape_node.shape == null:
		return
	var local_rect := _shape_local_rect(shape_node)
	if local_rect.size == Vector2.ZERO:
		return
	var global_rect := _to_overlay_rect(shape_node, local_rect)
	draw_rect(global_rect, color, false, 1.5)


func _draw_sprite_bounds() -> void:
	if _visual_controller == null:
		return
	var info: Dictionary = _visual_controller.get_debug_info()
	var sprite_rect: Rect2 = info.get("sprite_rect", Rect2())
	if sprite_rect.size == Vector2.ZERO:
		return
	var local_rect := Rect2(sprite_rect.position - global_position, sprite_rect.size)
	draw_rect(local_rect, COLOR_SPRITE, false, 1.5)


func _draw_pivot() -> void:
	var pivot_global: Vector2 = _player.global_position
	var pivot_local := pivot_global - global_position
	draw_line(pivot_local + Vector2(-8, 0), pivot_local + Vector2(8, 0), COLOR_PIVOT, 1.0)
	draw_line(pivot_local + Vector2(0, -8), pivot_local + Vector2(0, 8), COLOR_PIVOT, 1.0)
	draw_circle(pivot_local, 2.0, COLOR_PIVOT)


func _draw_facing() -> void:
	var facing := 1
	if _player != null:
		facing = int(_player.facing_direction)
	var pivot_local := _player.global_position - global_position
	var tip := pivot_local + Vector2(22 * facing, -18)
	draw_line(pivot_local + Vector2(0, -18), tip, COLOR_FACING, 2.0)
	draw_circle(tip, 2.5, COLOR_FACING)


func _draw_ground_line() -> void:
	if not _player.is_on_floor():
		return
	var feet_global := _player.global_position
	var feet_local := feet_global - global_position
	draw_line(
		feet_local + Vector2(-18, 0),
		feet_local + Vector2(18, 0),
		COLOR_GROUND,
		1.0
	)


func _draw_hud_labels() -> void:
	if _visual_controller == null:
		return

	var info: Dictionary = _visual_controller.get_debug_info()
	var font := ThemeDB.fallback_font
	var font_size := 12
	var lines: PackedStringArray = PackedStringArray([
		"anim: %s" % String(info.get("current_animation", "")),
		"frame: %d" % int(info.get("current_frame", -1)),
		"facing: %d" % int(info.get("facing_direction", 1)),
		"offset: %s" % str(info.get("sprite_offset", Vector2.ZERO)),
		"pivot: %s" % str(info.get("pivot_global", Vector2.ZERO)),
		"mode: %s" % String(info.get("visual_mode", "")),
		"prod sheets: %s" % str(info.get("uses_production_sheets", false)),
		"approved: %s" % str(info.get("approved_frame_size", Vector2i.ZERO)),
		"collision: %s" % str(info.get("gameplay_collision_size", Vector2i.ZERO)),
	])

	var y := 12.0
	for line in lines:
		draw_string(font, Vector2(8, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, COLOR_LABEL)
		y += font_size + 3.0

	if _collision_shape != null:
		var collision_rect := _to_overlay_rect(_collision_shape, _shape_local_rect(_collision_shape))
		draw_string(
			font,
			collision_rect.position + Vector2(0, -4),
			"collision",
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			10,
			COLOR_COLLISION
		)

	if _hurtbox != null:
		var hurt_shape := _hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hurt_shape != null:
			var hurt_rect := _to_overlay_rect(hurt_shape, _shape_local_rect(hurt_shape))
			draw_string(font, hurt_rect.position + Vector2(0, -4), "hurtbox", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_HURTBOX)

	if _hitbox != null:
		var hit_shape := _hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hit_shape != null:
			var hit_rect := _to_overlay_rect(hit_shape, _shape_local_rect(hit_shape))
			draw_string(font, hit_rect.position + Vector2(0, -4), "hitbox", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, COLOR_HITBOX)


func _shape_local_rect(shape_node: CollisionShape2D) -> Rect2:
	var shape := shape_node.shape
	if shape is RectangleShape2D:
		var rect_shape := shape as RectangleShape2D
		return Rect2(-rect_shape.size * 0.5 + shape_node.position, rect_shape.size)
	return Rect2()


func _to_overlay_rect(shape_node: CollisionShape2D, local_rect: Rect2) -> Rect2:
	var global_rect := local_rect
	global_rect.position += shape_node.global_position - global_position
	return global_rect
