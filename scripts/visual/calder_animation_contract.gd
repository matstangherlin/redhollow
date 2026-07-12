extends RefCounted
class_name CalderAnimationContract

## Canonical asset contract for Calder Knox sprites and animations.
## Gameplay timing remains in AttackData — this file is visual-only.

const CANVAS_SIZE := Vector2i(32, 56)
const CHARACTER_SIZE := Vector2i(32, 56)
const PIVOT := Vector2(16, 56)
const FEET_OFFSET := Vector2(0, 0)
const SPRITE_VISUAL_OFFSET := Vector2(0, -28)
const DEFAULT_FACING := 1
const DEFAULT_FALLBACK_ANIMATION := &"idle"

const SHEET_BASE_PATH := "res://art/characters/calder/"

## Pilot clip set integrated in the first art pass.
const PILOT_ANIMATION_IDS: PackedStringArray = [
	"idle",
	"run",
	"jump_rise",
	"fall",
	"land",
	"straight",
	"body_hook",
	"red_knuckle",
	"dodge",
	"hurt",
]

## Visual-only markers per animation frame (not hitbox timing).
## Keys: animation id -> frame index -> event name or array of event names.
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
			"idle": _spec(6, 8.0, true, "calder_idle_sheet.png", "P0", "procedural"),
			"run": _spec(6, 12.0, true, "calder_run_sheet.png", "P0", "procedural"),
			"jump_rise": _spec(2, 10.0, false, "calder_jump_rise_sheet.png", "P0", "procedural"),
			"fall": _spec(2, 8.0, true, "calder_fall_sheet.png", "P0", "procedural"),
			"land": _spec(3, 10.0, false, "calder_land_sheet.png", "P0", "procedural"),
			"straight": _spec(4, 14.0, false, "calder_straight_sheet.png", "P0", "procedural"),
			"body_hook": _spec(4, 12.0, false, "calder_body_hook_sheet.png", "P0", "procedural"),
			"red_knuckle": _spec(5, 10.0, false, "calder_red_knuckle_sheet.png", "P0", "procedural"),
			"dodge": _spec(4, 14.0, false, "calder_dodge_sheet.png", "P0", "procedural"),
			"hurt": _spec(2, 10.0, false, "calder_hurt_sheet.png", "P0", "procedural"),
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
			"expected_file": SHEET_BASE_PATH + String(spec.get("file", "")),
		})
	return rows


static func get_sheet_path(anim_id: StringName) -> String:
	var spec: Dictionary = get_clip_specs().get(String(anim_id), {})
	if spec.is_empty():
		return ""
	return SHEET_BASE_PATH + String(spec.get("file", ""))


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
