extends Resource
class_name ChapterData

## Single narrative chapter — areas, data paths, and completion gates.

@export var chapter_id: StringName = &""
@export var title: String = ""
@export var act_label: String = ""
@export var sort_order: int = 0
@export var is_playable: bool = false

@export var areas: Array[AreaData] = []
@export var starting_area_id: StringName = &""
@export var starting_spawn_id: StringName = &"default"

@export var dialogue_data_path: String = ""
@export var events_data_path: String = ""
@export var objectives_data_path: String = ""

@export var completion_flag_id: StringName = &""
@export var bosses: Array[BossData] = []
@export var encounters: Array[EncounterData] = []
@export var abilities: Array[AbilityData] = []
@export var collectibles: Array[CollectibleData] = []
@export var embedded_objectives: Array[ObjectiveData] = []
@export var embedded_events: Array[WorldEventData] = []


func get_area(area_id: StringName) -> AreaData:
	for area in areas:
		if area != null and area.area_id == area_id:
			return area
	return null


func get_starting_area() -> AreaData:
	if starting_area_id != &"":
		var explicit := get_area(starting_area_id)
		if explicit != null:
			return explicit
	for area in areas:
		if area != null and area.is_valid():
			return area
	return null


func get_playable_areas() -> Array[AreaData]:
	var playable: Array[AreaData] = []
	for area in areas:
		if area != null and area.is_valid():
			playable.append(area)
	playable.sort_custom(func(a: AreaData, b: AreaData) -> bool:
		return a.sort_order < b.sort_order
	)
	return playable
