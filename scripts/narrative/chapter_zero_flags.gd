extends RefCounted
class_name ChapterZeroFlags

## Stable narrative flag IDs for Capítulo Zero — O Sino Antes do Anoitecer.

const CHAPTER_STARTED := &"cz_chapter_started"
const MET_ELIAS := &"cz_met_elias"
const STREET_BRAWLER_DEFEATED := &"cz_street_brawler_defeated"
const STREET_STATUE_OBSERVED := &"cz_street_statue_observed"
const PARTNER_CLUE_FOUND := &"cz_partner_clue_found"
const CHURCH_DISTRICT_REACHED := &"cz_church_district_reached"
const ORDER_DOCUMENT_READ := &"cz_order_document_read"
const BARRIER_BROKEN := &"cz_barrier_broken"
const UNDERGROUND_REACHED := &"cz_underground_reached"
const CHECKPOINT_ACTIVATED := &"cz_checkpoint_activated"
const PARTNER_EVIDENCE_FOUND := &"cz_partner_evidence_found"
const FINALE_PLAYED := &"cz_finale_played"

# Encounter progression flags.
const GUNSLINGER_DEFEATED := &"cz_gunslinger_defeated"
const DUO_ENCOUNTER_CLEARED := &"cz_duo_encounter_cleared"
const CHAIN_PENITENT_DEFEATED := &"cz_chain_penitent_defeated"
const SHORTCUT_OPEN := &"cz_shortcut_open"
const RED_BRAND_PASSAGE_OPEN := &"cz_red_brand_passage_open"
const SECRET_FOUND := &"cz_secret_found"
const MARKED_CARTRIDGE_FOUND := &"cz_marked_cartridge_found"
const CHURCH_CHECKPOINT_ACTIVATED := &"cz_church_checkpoint_activated"

# Reuse existing gameplay flags for continuity with save/tests.
const ARENA_COMPLETE := &"arena_vs_church_yard_complete"
const RED_BRAND_CACHE_USED := &"vs_red_brand_cache_used"
const DEACON_DEFEATED := &"boss_vs_deacon_rusk_defeated"
const CHAPTER_COMPLETED := &"cz_chapter_zero_completed"

# Legacy alias kept for older saves/overlays.
const LEGACY_DEMO_COMPLETED := &"vertical_slice_completed"
