extends RefCounted
class_name UndergroundFinalMoldSpec

## Cap. Zero catacombs final mold — same mode pipeline as church/street.
## Does NOT alter street/church scenes or reveal full Mol-Khar / Ruby Palace.

const PLACEHOLDER_TAG := "PLACEHOLDER_CANDIDATE"

const MODE_GREYBOX := &"greybox"
const MODE_NORTH_STAR := &"north_star"
const MODE_FINAL_CANDIDATE := &"final_candidate"

const MOLD_APPROVED := true
const MOLD_DOC := "docs/UNDERGROUND_FINAL_MOLD.md"
const MOLD_ID := "underground_north_star_final_mold_v1"
const PLAYFIELD_WIDTH_PX := 1200.0

const MODE_CYCLE: PackedStringArray = [
	MODE_GREYBOX,
	MODE_NORTH_STAR,
	MODE_FINAL_CANDIDATE,
]


static func get_progression_stages() -> PackedStringArray:
	return PackedStringArray([
		"infraestrutura_humana",
		"tuneis_ordem",
		"ruinas_antigas",
		"prisao_mol_khar",
		"manifestacao_espiritual",
	])


static func get_set_piece_checklist() -> PackedStringArray:
	return PackedStringArray([
		"timber_shoring",
		"order_tunnel_arch",
		"ancient_ruin_glyph",
		"prison_altar",
		"boss_arena_floor",
		"colossal_statue",
		"mol_shadow_tease",
		"hidden_passage",
	])


static func mode_display_name(mode: StringName) -> String:
	match mode:
		MODE_GREYBOX:
			return "GREYBOX"
		MODE_NORTH_STAR:
			return "NORTH STAR (procedural)"
		MODE_FINAL_CANDIDATE:
			return "FINAL MOLD (catacombs 0–1200)"
		_:
			return String(mode)


static func next_mode(current: StringName) -> StringName:
	var idx := MODE_CYCLE.find(String(current))
	if idx < 0:
		return MODE_NORTH_STAR
	return StringName(MODE_CYCLE[(idx + 1) % MODE_CYCLE.size()])
