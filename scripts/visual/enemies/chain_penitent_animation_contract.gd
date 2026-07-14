extends RefCounted
class_name ChainPenitentAnimationContract

## Visual contract for Chain Penitent — metal chain reach, not magic.
## AttackData remains combat authority.

const APPROVED_FRAME_SIZE := Vector2i(38, 58)
const APPROVED_FRAME_SIZE_DOC := "docs/CHARACTER_SCALE_GUIDE.md"
const PLACEHOLDER_FRAME_SIZE := Vector2i(38, 58)
const GAMEPLAY_COLLISION_SIZE := Vector2i(38, 58)
const PIVOT := Vector2(19, 58)
const SPRITE_VISUAL_OFFSET := Vector2(0, -29)
const DEFAULT_FACING := -1
const DEFAULT_FALLBACK_ANIMATION := &"idle"
const SHEET_BASE_PATH := "res://art/characters/enemies/chain_penitent/sheets/"

const PILOT_ANIMATION_IDS: PackedStringArray = [
	"idle",
	"walk",
	"chain_startup",
	"chain_active",
	"chain_recovery",
	"pull",
	"hurt",
	"stagger",
	"death",
]

const VISUAL_EVENT_FRAMES: Dictionary = {
	"walk": {1: [&"footstep"], 3: [&"footstep"]},
	"chain_startup": {1: [&"chain_rattle", &"sound"], 3: [&"reach_marker"]},
	"chain_active": {1: [&"contact_visual", &"sound"]},
	"pull": {0: [&"chain_tension", &"sound"], 2: [&"pull_yank"]},
	"chain_recovery": {0: [&"chain_retract"]},
	"hurt": {0: [&"hit_flash", &"sound"]},
	"stagger": {0: [&"hit_flash"], 2: [&"vulnerable_pose"]},
	"death": {3: [&"dust"], 6: [&"corpse_settle"]},
}

static var _clip_specs: Dictionary = {}
static var _warned: Dictionary = {}


static func get_clip_specs() -> Dictionary:
	if not _clip_specs.is_empty():
		return _clip_specs
	_clip_specs = {
		"idle": {"frames": 4, "frame_duration": 0.16, "loop": true, "file": "chain_penitent_idle.png"},
		"walk": {"frames": 6, "frame_duration": 0.11, "loop": true, "file": "chain_penitent_walk.png"},
		"chain_startup": {
			"frames": 5, "frame_duration": 0.1, "loop": false, "file": "chain_penitent_chain_startup.png"
		},
		"chain_active": {
			"frames": 3, "frame_duration": 0.08, "loop": false, "file": "chain_penitent_chain_active.png"
		},
		"chain_recovery": {
			"frames": 4, "frame_duration": 0.1, "loop": false, "file": "chain_penitent_chain_recovery.png"
		},
		"pull": {"frames": 4, "frame_duration": 0.09, "loop": false, "file": "chain_penitent_pull.png"},
		"hurt": {"frames": 3, "frame_duration": 0.08, "loop": false, "file": "chain_penitent_hurt.png"},
		"stagger": {"frames": 5, "frame_duration": 0.12, "loop": false, "file": "chain_penitent_stagger.png"},
		"death": {"frames": 7, "frame_duration": 0.1, "loop": false, "file": "chain_penitent_death.png"},
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
	push_warning("[PenitentVisual] %s: %s" % [context, detail])


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
		"weapon_rule": "metal_chain_reach_not_magic",
	}
