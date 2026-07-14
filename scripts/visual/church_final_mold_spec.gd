extends RefCounted
class_name ChurchFinalMoldSpec

## Cap. Zero church final mold — same mode pipeline as street, church identity only.
## Does NOT touch catacombs / underground area composers.

const PLACEHOLDER_TAG := "PLACEHOLDER_CANDIDATE"

const MODE_GREYBOX := &"greybox"
const MODE_NORTH_STAR := &"north_star"
const MODE_FINAL_CANDIDATE := &"final_candidate"

const MOLD_APPROVED := true
const MOLD_DOC := "docs/CHURCH_FINAL_MOLD.md"
const MOLD_ID := "church_north_star_final_mold_v1"
const PLAYFIELD_WIDTH_PX := 1800.0

const MODE_CYCLE: PackedStringArray = [
	MODE_GREYBOX,
	MODE_NORTH_STAR,
	MODE_FINAL_CANDIDATE,
]


static func get_mood_targets() -> PackedStringArray:
	return PackedStringArray([
		"pedra_ritual",
		"verticalidade",
		"torre_sino",
		"praca_ordem",
		"estatuas",
		"banners",
		"velas",
		"portao",
		"entrada_subterranea",
		"terror_religioso",
	])


static func get_set_piece_checklist() -> PackedStringArray:
	return PackedStringArray([
		"bell_tower",
		"main_entrance",
		"order_statue",
		"external_altar",
		"cult_gate",
		"underground_passage",
	])


static func mode_display_name(mode: StringName) -> String:
	match mode:
		MODE_GREYBOX:
			return "GREYBOX"
		MODE_NORTH_STAR:
			return "NORTH STAR (procedural)"
		MODE_FINAL_CANDIDATE:
			return "FINAL MOLD (church 0–1800)"
		_:
			return String(mode)


static func next_mode(current: StringName) -> StringName:
	var idx := MODE_CYCLE.find(String(current))
	if idx < 0:
		return MODE_NORTH_STAR
	return StringName(MODE_CYCLE[(idx + 1) % MODE_CYCLE.size()])
