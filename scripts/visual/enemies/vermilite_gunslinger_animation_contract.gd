extends RefCounted
class_name VermiliteGunslingerAnimationContract

## Visual contract for Vermilite Gunslinger — physical Vermilite ammo, not magic.
## AttackData remains combat authority.

const APPROVED_FRAME_SIZE := Vector2i(32, 54)
const APPROVED_FRAME_SIZE_DOC := "docs/CHARACTER_SCALE_GUIDE.md"
const PLACEHOLDER_FRAME_SIZE := Vector2i(32, 54)
const GAMEPLAY_COLLISION_SIZE := Vector2i(32, 54)
const PIVOT := Vector2(16, 54)
const SPRITE_VISUAL_OFFSET := Vector2(0, -27)
const DEFAULT_FACING := -1
const DEFAULT_FALLBACK_ANIMATION := &"idle"
const SHEET_BASE_PATH := "res://art/characters/enemies/vermilite_gunslinger/sheets/"

const PILOT_ANIMATION_IDS: PackedStringArray = [
	"idle",
	"aim",
	"fire",
	"recoil",
	"reload",
	"reposition",
	"hurt",
	"death",
]

const VISUAL_EVENT_FRAMES: Dictionary = {
	"aim": {1: [&"aim_line", &"sound"], 3: [&"muzzle_charge"]},
	"fire": {0: [&"muzzle_flash", &"sound", &"projectile_spawn"]},
	"recoil": {0: [&"gun_smoke"]},
	"reload": {2: [&"shell_eject", &"sound"]},
	"hurt": {0: [&"hit_flash", &"sound"]},
	"death": {3: [&"dust"], 5: [&"corpse_settle"]},
}

static var _clip_specs: Dictionary = {}
static var _warned: Dictionary = {}


static func get_clip_specs() -> Dictionary:
	if not _clip_specs.is_empty():
		return _clip_specs
	_clip_specs = {
		"idle": {"frames": 4, "frame_duration": 0.16, "loop": true, "file": "vermilite_gunslinger_idle.png"},
		"aim": {"frames": 4, "frame_duration": 0.1, "loop": false, "file": "vermilite_gunslinger_aim.png"},
		"fire": {"frames": 3, "frame_duration": 0.06, "loop": false, "file": "vermilite_gunslinger_fire.png"},
		"recoil": {"frames": 3, "frame_duration": 0.08, "loop": false, "file": "vermilite_gunslinger_recoil.png"},
		"reload": {"frames": 5, "frame_duration": 0.12, "loop": false, "file": "vermilite_gunslinger_reload.png"},
		"reposition": {"frames": 4, "frame_duration": 0.1, "loop": true, "file": "vermilite_gunslinger_reposition.png"},
		"hurt": {"frames": 3, "frame_duration": 0.08, "loop": false, "file": "vermilite_gunslinger_hurt.png"},
		"death": {"frames": 6, "frame_duration": 0.1, "loop": false, "file": "vermilite_gunslinger_death.png"},
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
	push_warning("[GunslingerVisual] %s: %s" % [context, detail])


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
		"ammo_rule": "physical_vermilite_slug_not_magic",
	}
