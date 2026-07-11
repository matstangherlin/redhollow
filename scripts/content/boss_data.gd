extends Resource
class_name BossData

## Boss metadata. Combat AI lives in enemy scenes; this Resource wires narrative gates only.

@export var boss_id: StringName = &""
@export var display_name: String = ""
@export var chapter_id: StringName = &""
@export var encounter_id: StringName = &""
@export var completion_flag_id: StringName = &""
@export var enemy_scene_path: String = ""
