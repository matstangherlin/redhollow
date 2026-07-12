extends Resource
class_name ContentManifest

## Product profile: which chapters and areas ship in this build.
## Use beta_demo for public beta; full_game for the complete product roadmap.

const MANIFEST_BETA_DEMO := &"beta_demo"
const MANIFEST_FULL_GAME := &"full_game"

const PATH_BETA_DEMO := "res://resources/content/manifests/beta_demo.tres"
const PATH_FULL_GAME := "res://resources/content/manifests/full_game.tres"

@export var manifest_id: StringName = &""
@export var display_name: String = ""
@export var game_shell_scene_path: String = "res://scenes/demo/vertical_slice_greybox.tscn"
@export var save_profile_id: StringName = &"default"

## Chapters registered in the product (playable + future stubs).
@export var chapters: Array[ChapterData] = []

## Subset of chapter_id values loadable in this manifest.
@export var playable_chapter_ids: PackedStringArray = []

@export var starting_chapter_id: StringName = &""
@export var beta_end_chapter_id: StringName = &""
@export var world_graph_path: String = ""

## Explicit policy: beta saves are NOT auto-migrated when opening full_game.
@export var migrate_beta_saves_to_full: bool = false


func get_game_shell_scene() -> PackedScene:
	if game_shell_scene_path.is_empty() or not ResourceLoader.exists(game_shell_scene_path):
		return null
	return load(game_shell_scene_path) as PackedScene


func get_chapter(chapter_id: StringName) -> ChapterData:
	for chapter in chapters:
		if chapter != null and chapter.chapter_id == chapter_id:
			return chapter
	return null


func is_chapter_playable(chapter_id: StringName) -> bool:
	return playable_chapter_ids.has(String(chapter_id))


func get_starting_chapter() -> ChapterData:
	if starting_chapter_id != &"":
		return get_chapter(starting_chapter_id)
	for chapter_id in playable_chapter_ids:
		var chapter := get_chapter(StringName(chapter_id))
		if chapter != null:
			return chapter
	return null
