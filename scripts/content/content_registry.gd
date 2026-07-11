extends RefCounted
class_name ContentRegistry

## Central gate for content availability. No scattered `if demo` checks — query this service.

static var _active: ContentRegistry = null

var manifest: ContentManifest = null
var _chapter_by_id: Dictionary = {}
var _area_by_id: Dictionary = {}
var _area_by_scene: Dictionary = {}
var _playable_scene_paths: PackedStringArray = []
var _playable_area_ids: PackedStringArray = []
var _playable_chapter_ids: PackedStringArray = []


static func get_active() -> ContentRegistry:
	return _active


static func activate(manifest: ContentManifest) -> ContentRegistry:
	var registry := ContentRegistry.new()
	registry.manifest = manifest
	registry._rebuild_indexes()
	_active = registry
	return registry


static func clear_active() -> void:
	_active = null


static func load_manifest(path: String) -> ContentManifest:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return load(path) as ContentManifest


static func activate_from_path(path: String) -> ContentRegistry:
	var manifest := load_manifest(path)
	if manifest == null:
		push_warning("ContentRegistry: manifest not found at %s" % path)
		return null
	return activate(manifest)


func _rebuild_indexes() -> void:
	_chapter_by_id.clear()
	_area_by_id.clear()
	_area_by_scene.clear()
	_playable_scene_paths.clear()
	_playable_area_ids.clear()
	_playable_chapter_ids.clear()

	if manifest == null:
		return

	for chapter in manifest.chapters:
		if chapter == null:
			continue
		_chapter_by_id[String(chapter.chapter_id)] = chapter

		if not manifest.is_chapter_playable(chapter.chapter_id):
			continue

		_playable_chapter_ids.append(chapter.chapter_id)

		for area in chapter.get_playable_areas():
			_area_by_id[String(area.area_id)] = area
			_area_by_scene[area.scene_path] = area
			_playable_area_ids.append(area.area_id)
			if not _playable_scene_paths.has(area.scene_path):
				_playable_scene_paths.append(area.scene_path)


func is_chapter_available(chapter_id: StringName) -> bool:
	return _playable_chapter_ids.has(chapter_id)


func is_area_available(area_id: StringName) -> bool:
	return _area_by_id.has(String(area_id))


func can_load_area_scene(scene_path: String) -> bool:
	if scene_path.is_empty():
		return false
	return _playable_scene_paths.has(scene_path)


func get_area(area_id: StringName) -> AreaData:
	return _area_by_id.get(String(area_id)) as AreaData


func get_area_for_scene(scene_path: String) -> AreaData:
	return _area_by_scene.get(scene_path) as AreaData


func get_chapter(chapter_id: StringName) -> ChapterData:
	return _chapter_by_id.get(String(chapter_id)) as ChapterData


func get_starting_chapter() -> ChapterData:
	if manifest == null:
		return null
	return manifest.get_starting_chapter()


func get_starting_area_scene() -> PackedScene:
	var chapter := get_starting_chapter()
	if chapter == null:
		return null
	var area := chapter.get_starting_area()
	if area == null:
		return null
	return area.get_scene()


func get_starting_spawn_id() -> StringName:
	var chapter := get_starting_chapter()
	if chapter == null:
		return &"default"
	return chapter.starting_spawn_id


func get_chapter_id_for_area_scene(scene_path: String) -> StringName:
	var area := get_area_for_scene(scene_path)
	if area == null:
		return &""
	return area.chapter_id


func get_chapter_id_for_area(area_id: StringName) -> StringName:
	var area := get_area(area_id)
	if area == null:
		return &""
	return area.chapter_id


func is_past_beta_boundary(chapter_id: StringName) -> bool:
	if manifest == null or manifest.beta_end_chapter_id == &"":
		return false
	var end_chapter := get_chapter(manifest.beta_end_chapter_id)
	var target := get_chapter(chapter_id)
	if end_chapter == null or target == null:
		return false
	return target.sort_order > end_chapter.sort_order


func get_beta_end_chapter() -> ChapterData:
	if manifest == null or manifest.beta_end_chapter_id == &"":
		return null
	return get_chapter(manifest.beta_end_chapter_id)


func get_completion_flag_id() -> StringName:
	var chapter := get_starting_chapter()
	if chapter != null and chapter.completion_flag_id != &"":
		return chapter.completion_flag_id
	return ChapterZeroFlags.CHAPTER_COMPLETED


func get_dialogue_data_path() -> String:
	var chapter := get_starting_chapter()
	if chapter != null and not chapter.dialogue_data_path.is_empty():
		return chapter.dialogue_data_path
	return DialogueController.DEFAULT_DIALOGUE_PATH


func get_events_data_path() -> String:
	var chapter := get_starting_chapter()
	if chapter != null and not chapter.events_data_path.is_empty():
		return chapter.events_data_path
	return NarrativeDirector.EVENTS_PATH


func get_objectives_data_path() -> String:
	var chapter := get_starting_chapter()
	if chapter != null and not chapter.objectives_data_path.is_empty():
		return chapter.objectives_data_path
	return ObjectiveLibrary.DEFAULT_PATH


func get_manifest_id() -> StringName:
	if manifest == null:
		return &""
	return manifest.manifest_id


func should_migrate_beta_save_to_full() -> bool:
	if manifest == null:
		return false
	return manifest.migrate_beta_saves_to_full


func is_save_compatible_with_manifest(save_data: Dictionary) -> bool:
	if manifest == null:
		return true

	var saved_manifest := String(save_data.get("content_manifest_id", ""))
	if saved_manifest.is_empty():
		var area_path := String(save_data.get("current_scene", ""))
		return area_path.is_empty() or can_load_area_scene(area_path)

	if saved_manifest != String(manifest.manifest_id):
		if saved_manifest == String(ContentManifest.MANIFEST_BETA_DEMO):
			return should_migrate_beta_save_to_full()
		return false

	var area_path := String(save_data.get("current_scene", ""))
	if not area_path.is_empty() and not can_load_area_scene(area_path):
		return false

	return true
