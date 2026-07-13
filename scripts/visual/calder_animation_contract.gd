extends RefCounted
class_name CalderAnimationContract

## Canonical asset contract for Calder Knox sprites and animations.
## Gameplay timing remains in AttackData — this file is visual-only.

## Approved production frame size — docs/VISUAL_SCALE_STUDY.md (human-approved recommendation).
const APPROVED_FRAME_SIZE := Vector2i(40, 72)
const APPROVED_FRAME_SIZE_DOC := "docs/VISUAL_SCALE_STUDY.md"

## Procedural placeholder frames (greybox until real sheets land in sheets/).
const PLACEHOLDER_FRAME_SIZE := Vector2i(32, 56)

## Gameplay collision — do not change without explicit combat review.
const GAMEPLAY_COLLISION_SIZE := Vector2i(32, 56)

## Legacy alias used by procedural placeholders and existing tests.
const CANVAS_SIZE := PLACEHOLDER_FRAME_SIZE
const CHARACTER_SIZE := PLACEHOLDER_FRAME_SIZE

const PIVOT := Vector2(16, 56)
const APPROVED_PIVOT := Vector2(20, 72)
const FEET_OFFSET := Vector2(0, 0)
const SPRITE_VISUAL_OFFSET := Vector2(0, -28)
const APPROVED_SPRITE_VISUAL_OFFSET := Vector2(0, -36)
const DEFAULT_FACING := 1
const DEFAULT_FALLBACK_ANIMATION := &"idle"

const SHEET_BASE_PATH := "res://art/characters/calder/sheets/"
const SOURCE_PATH := "res://art/characters/calder/source/"
const EXPORTED_PATH := "res://art/characters/calder/exported/"
const PREVIEWS_PATH := "res://art/characters/calder/previews/"
const LEGACY_SHEET_BASE_PATH := "res://art/characters/calder/"

## Required pilot clips for first real-art integration pass.
const PILOT_ANIMATION_IDS: PackedStringArray = [
	"idle",
	"run",
	"jump_start",
	"jump_rise",
	"fall",
	"land",
	"straight",
	"body_hook",
	"red_knuckle",
	"dodge",
	"hurt",
]

## Optional clips tracked for production planning (not required for pilot fallback).
const OPTIONAL_ANIMATION_IDS: PackedStringArray = [
	"turn",
	"counter_window",
	"counter_attack",
	"taunt_01",
	"taunt_02",
	"knockdown",
	"death",
	"respawn",
	"interact",
	"red_brand_charge",
	"red_brand_breaker",
]

## Visual-only markers per animation frame (not hitbox timing).
const VISUAL_EVENT_FRAMES: Dictionary = {
	"run": {1: [&"footstep"], 4: [&"footstep"]},
	"land": {1: [&"dust"]},
	"straight": {1: [&"swing_trail"], 2: [&"contact_visual", &"sound"]},
	"body_hook": {1: [&"swing_trail"], 2: [&"contact_visual", &"sound"]},
	"red_knuckle": {2: [&"swing_trail"], 3: [&"contact_visual", &"impact_visual", &"sound"]},
	"dodge": {1: [&"dust"]},
	"hurt": {0: [&"impact_visual", &"sound"]},
}

static var _clip_specs: Dictionary = {}
static var _warned_missing: Dictionary = {}


static func get_clip_specs() -> Dictionary:
	if _clip_specs.is_empty():
		_clip_specs = {
			"idle": _spec(6, 8.0, true, "calder_idle_sheet.png", "P0", "pending"),
			"run": _spec(6, 12.0, true, "calder_run_sheet.png", "P0", "pending"),
			"jump_start": _spec(2, 12.0, false, "calder_jump_start_sheet.png", "P0", "pending"),
			"jump_rise": _spec(2, 10.0, false, "calder_jump_rise_sheet.png", "P0", "pending"),
			"fall": _spec(2, 8.0, true, "calder_fall_sheet.png", "P0", "pending"),
			"land": _spec(3, 10.0, false, "calder_land_sheet.png", "P0", "pending"),
			"straight": _spec(4, 14.0, false, "calder_straight_sheet.png", "P0", "pending"),
			"body_hook": _spec(4, 12.0, false, "calder_body_hook_sheet.png", "P0", "pending"),
			"red_knuckle": _spec(5, 10.0, false, "calder_red_knuckle_sheet.png", "P0", "pending"),
			"dodge": _spec(4, 14.0, false, "calder_dodge_sheet.png", "P0", "pending"),
			"hurt": _spec(2, 10.0, false, "calder_hurt_sheet.png", "P0", "pending"),
			"turn": _spec(3, 10.0, false, "calder_turn_sheet.png", "P1", "optional"),
			"counter_window": _spec(2, 10.0, false, "calder_counter_window_sheet.png", "P1", "optional"),
			"counter_attack": _spec(4, 14.0, false, "calder_counter_attack_sheet.png", "P1", "optional"),
			"taunt_01": _spec(4, 8.0, false, "calder_taunt_01_sheet.png", "P2", "optional"),
			"taunt_02": _spec(4, 8.0, false, "calder_taunt_02_sheet.png", "P2", "optional"),
			"knockdown": _spec(3, 10.0, false, "calder_knockdown_sheet.png", "P1", "optional"),
			"death": _spec(4, 8.0, false, "calder_death_sheet.png", "P1", "optional"),
			"respawn": _spec(4, 10.0, false, "calder_respawn_sheet.png", "P2", "optional"),
			"interact": _spec(3, 8.0, false, "calder_interact_sheet.png", "P2", "optional"),
			"red_brand_charge": _spec(4, 10.0, false, "calder_red_brand_charge_sheet.png", "P1", "optional"),
			"red_brand_breaker": _spec(5, 12.0, false, "calder_red_brand_breaker_sheet.png", "P1", "optional"),
		}
	return _clip_specs


static func get_production_table_rows() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for anim_id in PlayerVisualProfile.PRODUCTION_ANIMATION_IDS:
		var spec: Dictionary = get_clip_specs().get(anim_id, {})
		rows.append({
			"animation": anim_id,
			"frames": int(spec.get("frames", 0)),
			"fps": float(spec.get("fps", 0.0)),
			"loop": bool(spec.get("loop", false)),
			"priority": String(spec.get("priority", "")),
			"status": String(spec.get("status", "pending")),
			"expected_file": get_sheet_path(StringName(anim_id)),
		})
	return rows


static func get_sheet_path(anim_id: StringName) -> String:
	var spec: Dictionary = get_clip_specs().get(String(anim_id), {})
	if spec.is_empty():
		return ""
	var file_name := String(spec.get("file", ""))
	if file_name.is_empty():
		return ""
	return SHEET_BASE_PATH + file_name


static func resolve_sheet_path(anim_id: StringName) -> String:
	var primary := get_sheet_path(anim_id)
	if not primary.is_empty() and ResourceLoader.exists(primary):
		return primary
	var spec: Dictionary = get_clip_specs().get(String(anim_id), {})
	var legacy := LEGACY_SHEET_BASE_PATH + String(spec.get("file", ""))
	if ResourceLoader.exists(legacy):
		return legacy
	return primary


static func has_production_sheet(anim_id: StringName) -> bool:
	var path := resolve_sheet_path(anim_id)
	return not path.is_empty() and ResourceLoader.exists(path)


static func get_frame_size_for_clip(anim_id: StringName, use_production: bool) -> Vector2i:
	if use_production and has_production_sheet(anim_id):
		return APPROVED_FRAME_SIZE
	return PLACEHOLDER_FRAME_SIZE


static func get_sprite_visual_offset(use_production_sheets: bool) -> Vector2:
	if use_production_sheets:
		return APPROVED_SPRITE_VISUAL_OFFSET
	return SPRITE_VISUAL_OFFSET


static func profile_uses_production_sheets(profile: PlayerVisualProfile) -> bool:
	if profile == null or profile.uses_placeholder() or profile.use_procedural_pilot_frames:
		return false
	for anim_id in PILOT_ANIMATION_IDS:
		if has_production_sheet(StringName(anim_id)):
			return true
	return false


static func get_frame_duration(anim_id: StringName) -> float:
	var spec: Dictionary = get_clip_specs().get(String(anim_id), {})
	var fps: float = float(spec.get("fps", 10.0))
	return 1.0 / maxf(fps, 0.001)


static func get_visual_events(anim_id: StringName, frame_index: int) -> Array[StringName]:
	var events: Variant = VISUAL_EVENT_FRAMES.get(String(anim_id), {})
	var entry: Variant = events.get(frame_index, [])
	if entry is StringName:
		return [entry]
	if entry is String:
		return [StringName(entry)]
	if entry is Array:
		var names: Array[StringName] = []
		for item in entry:
			names.append(StringName(String(item)))
		return names
	return []


static func get_visual_event(anim_id: StringName, frame_index: int) -> StringName:
	var events := get_visual_events(anim_id, frame_index)
	if events.is_empty():
		return &""
	return events[0]


static func warn_missing_once(context: String, detail: String) -> void:
	var key := "%s|%s" % [context, detail]
	if _warned_missing.has(key):
		return
	_warned_missing[key] = true
	push_warning("CalderAnimationContract: %s — %s" % [context, detail])


static func _spec(
	frames: int,
	fps: float,
	loop: bool,
	file_name: String,
	priority: String,
	status: String
) -> Dictionary:
	return {
		"frames": frames,
		"fps": fps,
		"loop": loop,
		"file": file_name,
		"priority": priority,
		"status": status,
		"frame_duration": 1.0 / maxf(fps, 0.001),
	}
