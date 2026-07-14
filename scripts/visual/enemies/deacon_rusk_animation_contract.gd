extends RefCounted
class_name DeaconRuskAnimationContract

## Visual contract for Deacon Rusk. AttackData remains combat authority.
## Frame 42×72 per CHARACTER_SCALE_GUIDE — collision stays greybox 42×68.

const APPROVED_FRAME_SIZE := Vector2i(42, 72)
const APPROVED_FRAME_SIZE_DOC := "docs/CHARACTER_SCALE_GUIDE.md"
const GAMEPLAY_COLLISION_SIZE := Vector2i(42, 68)
const PIVOT := Vector2(21, 72)
const SPRITE_VISUAL_OFFSET := Vector2(0, -36)
const DEFAULT_FALLBACK_ANIMATION := &"idle"
const SHEET_BASE_PATH := "res://art/characters/enemies/deacon_rusk/sheets/"

const PILOT_ANIMATION_IDS: PackedStringArray = [
	"idle",
	"reposition",
	"punch_combo",
	"charge",
	"counterable_attack",
	"ground_attack",
	"armor_attack",
	"hurt",
	"stagger",
	"phase_transition",
	"death",
]

const VISUAL_EVENT_FRAMES: Dictionary = {
	"punch_combo": {1: [&"telegraph", &"sound"], 3: [&"impact"]},
	"charge": {0: [&"telegraph", &"sound"], 2: [&"impact"]},
	"counterable_attack": {1: [&"telegraph_counterable", &"sound"]},
	"ground_attack": {0: [&"slam_telegraph"], 2: [&"impact", &"sound"]},
	"armor_attack": {0: [&"armor_glow", &"telegraph"], 2: [&"impact"]},
	"phase_transition": {1: [&"vermilite_surge", &"sound"], 4: [&"phase2_ready"]},
	"hurt": {0: [&"hit_flash"]},
	"stagger": {0: [&"hit_flash"], 2: [&"vulnerable_pose"]},
	"death": {4: [&"dust"], 7: [&"corpse_settle"]},
}

static var _clip_specs: Dictionary = {}
static var _warned: Dictionary = {}


static func get_clip_specs() -> Dictionary:
	if not _clip_specs.is_empty():
		return _clip_specs
	_clip_specs = {
		"idle": {"frames": 4, "frame_duration": 0.16, "loop": true, "file": "deacon_rusk_idle.png"},
		"reposition": {"frames": 4, "frame_duration": 0.1, "loop": true, "file": "deacon_rusk_reposition.png"},
		"punch_combo": {"frames": 5, "frame_duration": 0.08, "loop": false, "file": "deacon_rusk_punch_combo.png"},
		"charge": {"frames": 4, "frame_duration": 0.08, "loop": false, "file": "deacon_rusk_charge.png"},
		"counterable_attack": {
			"frames": 5, "frame_duration": 0.09, "loop": false, "file": "deacon_rusk_counterable_attack.png"
		},
		"ground_attack": {"frames": 5, "frame_duration": 0.09, "loop": false, "file": "deacon_rusk_ground_attack.png"},
		"armor_attack": {"frames": 5, "frame_duration": 0.08, "loop": false, "file": "deacon_rusk_armor_attack.png"},
		"hurt": {"frames": 3, "frame_duration": 0.08, "loop": false, "file": "deacon_rusk_hurt.png"},
		"stagger": {"frames": 5, "frame_duration": 0.12, "loop": false, "file": "deacon_rusk_stagger.png"},
		"phase_transition": {
			"frames": 6, "frame_duration": 0.12, "loop": false, "file": "deacon_rusk_phase_transition.png"
		},
		"death": {"frames": 8, "frame_duration": 0.1, "loop": false, "file": "deacon_rusk_death.png"},
	}
	return _clip_specs


static func get_sheet_path(anim_id: StringName) -> String:
	return SHEET_BASE_PATH + String(get_clip_specs().get(String(anim_id), {}).get("file", ""))


static func resolve_sheet_path(anim_id: StringName) -> String:
	var path := get_sheet_path(anim_id)
	return path if ResourceLoader.exists(path) else ""


static func warn_missing_once(context: String, detail: String) -> void:
	var key := "%s|%s" % [context, detail]
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning("[DeaconVisual] %s: %s" % [context, detail])


static func profile_uses_production_sheets(profile: EnemyVisualProfile) -> bool:
	if profile == null:
		return false
	if profile.is_final_profile():
		return true
	return profile.is_pilot_profile() and not profile.use_procedural_pilot_frames


static func get_visual_contract_summary() -> Dictionary:
	return {
		"approved_frame_size": APPROVED_FRAME_SIZE,
		"gameplay_collision_size": GAMEPLAY_COLLISION_SIZE,
		"pivot": PIVOT,
		"sprite_visual_offset": SPRITE_VISUAL_OFFSET,
		"boss_rule": "silhouette_mantle_crown_not_magic",
	}
