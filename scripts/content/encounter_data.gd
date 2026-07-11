extends Resource
class_name EncounterData

## Combat encounter definition — arenas and scripted packs share the same combat base.

@export var encounter_id: StringName = &""
@export var area_id: StringName = &""
@export var chapter_id: StringName = &""
@export var completion_flag_id: StringName = &""
@export var enemy_groups: PackedStringArray = []
