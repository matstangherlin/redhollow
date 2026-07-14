extends RefCounted
class_name MusicSlotId

## Canonical music bed slots for beta presentation. Real licensed tracks replace
## procedural beds via MusicController.register_stream() — never load unlicensed audio.

const MENU := &"music_menu"
const STREET := &"music_street"
const CHURCH := &"music_church"
const CATACOMBS := &"music_catacombs"
const DEACON_RUSK := &"music_deacon_rusk"
const FINALE := &"music_finale"

const ALL_SLOTS: Array[StringName] = [
	MENU,
	STREET,
	CHURCH,
	CATACOMBS,
	DEACON_RUSK,
	FINALE,
]
