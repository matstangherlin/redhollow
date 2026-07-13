extends RefCounted
class_name CultBrawlerAnimationContract

## Canonical visual contract for Cult Brawler — beta enemy reference standard.
## Gameplay timing remains in AttackData; this file is visual-only.

const APPROVED_FRAME_SIZE := Vector2i(34, 56)
const APPROVED_FRAME_SIZE_DOC := "docs/CULT_BRAWLER_VISUAL_SPEC.md"

## Procedural placeholder frames until production sheets land.
const PLACEHOLDER_FRAME_SIZE := Vector2i(34, 56)

## Matches gameplay collision — docs/CHARACTER_SCALE_GUIDE.md
const GAMEPLAY_COLLISION_SIZE := Vector2i(34, 56)

const CANVAS_SIZE := APPROVED_FRAME_SIZE
const CHARACTER_SIZE := APPROVED_FRAME_SIZE

## Bottom-center pivot — feet at y=56 inside the frame.
const PIVOT := Vector2(17, 56)
const APPROVED_PIVOT := Vector2(17, 56)
const FEET_OFFSET := Vector2(0, 0)
const SPRITE_VISUAL_OFFSET := Vector2(0, -28)

## Default art faces left; gameplay flips via Visual.scale.x.
const DEFAULT_FACING := -1
const DEFAULT_FALLBACK_ANIMATION := &"idle"

## Silhouette targets (pixels, approved frame).
const BODY_WIDTH_PX := 34
const SHOULDER_WIDTH_PX := 30
const HAT_HEIGHT_PX := 14
const HAT_BRIM_WIDTH_PX := 28
const HAND_REACH_OFFSET_PX := 22
const ATTACK_VISUAL_REACH_PX := 46

## Scale vs Calder: 1.0× gameplay height (56 px); 0.78× Calder approved art height (72 px).
const CALDER_GAMEPLAY_HEIGHT_PX := 56
const CALDER_APPROVED_HEIGHT_PX := 72
const HEIGHT_RATIO_TO_CALDER_GAMEPLAY := 1.0
const HEIGHT_RATIO_TO_CALDER_APPROVED_ART := 56.0 / 72.0

const SHEET_BASE_PATH := "res://art/characters/enemies/cult_brawler/sheets/"
const SOURCE_PATH := "res://art/characters/enemies/cult_brawler/source/"
const EXPORTED_PATH := "res://art/characters/enemies/cult_brawler/exported/"
const PREVIEWS_PATH := "res://art/characters/enemies/cult_brawler/previews/"

const PILOT_ANIMATION_IDS: PackedStringArray = [
	"idle",
	"patrol",
	"alert",
	"approach",
	"attack_startup",
	"attack_active",
	"attack_recovery",
	"hurt",
	"heavy_hurt",
	"knocked_back",
	"stagger",
	"death",
]

const OPTIONAL_ANIMATION_IDS: PackedStringArray = [
	"turn",
	"block",
	"taunt",
]

const VISUAL_EVENT_FRAMES: Dictionary = {
	"patrol": {1: [&"footstep"], 4: [&"footstep"]},
	"approach": {1: [&"footstep"], 3: [&"footstep"]},
	"attack_startup": {2: [&"telegraph_pose", &"sound"], 4: [&"ground_glow"]},
	"attack_active": {1: [&"contact_visual", &"sound", &"impact_marker"]},
	"attack_recovery": {0: [&"recover_pose"]},
	"hurt": {0: [&"hit_flash", &"sound"]},
	"heavy_hurt": {0: [&"hit_flash", &"sound"]},
	"knocked_back": {0: [&"hit_flash", &"dust"]},
	"stagger": {0: [&"vermilite_flash", &"sound"], 2: [&"screen_shake_request"]},
	"death": {3: [&"dust"], 6: [&"corpse_settle"]},
}

static var _clip_specs: Dictionary = {}
static var _warned_missing: Dictionary = {}


static func get_clip_specs() -> Dictionary:
	if not _clip_specs.is_empty():
		return _clip_specs

	_clip_specs = {
		"idle": {"frames": 6, "frame_duration": 0.14, "loop": true, "file": "cult_brawler_idle.png"},
		"patrol": {"frames": 6, "frame_duration": 0.11, "loop": true, "file": "cult_brawler_patrol.png"},
		"alert": {"frames": 4, "frame_duration": 0.16, "loop": true, "file": "cult_brawler_alert.png"},
		"approach": {"frames": 6, "frame_duration": 0.09, "loop": true, "file": "cult_brawler_approach.png"},
		"attack_startup": {
			"frames": 5, "frame_duration": 0.1, "loop": false, "file": "cult_brawler_attack_startup.png"
		},
		"attack_active": {
			"frames": 3, "frame_duration": 0.08, "loop": false, "file": "cult_brawler_attack_active.png"
		},
		"attack_recovery": {
			"frames": 4, "frame_duration": 0.1, "loop": false, "file": "cult_brawler_attack_recovery.png"
		},
		"hurt": {"frames": 3, "frame_duration": 0.08, "loop": false, "file": "cult_brawler_hurt.png"},
		"heavy_hurt": {
			"frames": 4, "frame_duration": 0.09, "loop": false, "file": "cult_brawler_heavy_hurt.png"
		},
		"knocked_back": {
			"frames": 4, "frame_duration": 0.1, "loop": false, "file": "cult_brawler_knocked_back.png"
		},
		"stagger": {"frames": 5, "frame_duration": 0.12, "loop": false, "file": "cult_brawler_stagger.png"},
		"death": {"frames": 8, "frame_duration": 0.1, "loop": false, "file": "cult_brawler_death.png"},
	}
	return _clip_specs


static func get_sheet_path(anim_id: StringName) -> String:
	return SHEET_BASE_PATH + String(get_clip_specs().get(String(anim_id), {}).get("file", ""))


static func resolve_sheet_path(anim_id: StringName) -> String:
	var path := get_sheet_path(anim_id)
	if ResourceLoader.exists(path):
		return path
	return ""


static func warn_missing_once(context: String, detail: String) -> void:
	var key := "%s|%s" % [context, detail]
	if _warned_missing.has(key):
		return
	_warned_missing[key] = true
	push_warning("[CultBrawlerVisual] %s: %s" % [context, detail])


static func profile_uses_production_sheets(profile: EnemyVisualProfile) -> bool:
	if profile == null:
		return false
	if profile.is_final_profile():
		return true
	if profile.is_pilot_profile() and not profile.use_procedural_pilot_frames:
		return true
	return false


static func get_visual_contract_summary() -> Dictionary:
	return {
		"approved_frame_size": APPROVED_FRAME_SIZE,
		"gameplay_collision_size": GAMEPLAY_COLLISION_SIZE,
		"pivot": PIVOT,
		"sprite_visual_offset": SPRITE_VISUAL_OFFSET,
		"default_facing": DEFAULT_FACING,
		"body_width_px": BODY_WIDTH_PX,
		"hat_height_px": HAT_HEIGHT_PX,
		"attack_visual_reach_px": ATTACK_VISUAL_REACH_PX,
		"height_ratio_to_calder_gameplay": HEIGHT_RATIO_TO_CALDER_GAMEPLAY,
		"height_ratio_to_calder_approved_art": HEIGHT_RATIO_TO_CALDER_APPROVED_ART,
	}
