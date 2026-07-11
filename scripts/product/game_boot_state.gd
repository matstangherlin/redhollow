extends Node

enum BootMode {
	NONE,
	NEW_GAME,
	CONTINUE,
}

const DEFAULT_MANIFEST_PATH := ContentManifest.PATH_BETA_DEMO

var boot_mode: BootMode = BootMode.NONE
var return_to_main_menu: bool = false
var active_manifest: ContentManifest = null


func set_active_manifest(manifest: ContentManifest) -> void:
	active_manifest = manifest


func set_active_manifest_path(path: String = DEFAULT_MANIFEST_PATH) -> void:
	active_manifest = ContentRegistry.load_manifest(path)


func get_active_manifest() -> ContentManifest:
	if active_manifest != null:
		return active_manifest
	return ContentRegistry.load_manifest(DEFAULT_MANIFEST_PATH)


func set_new_game() -> void:
	boot_mode = BootMode.NEW_GAME
	return_to_main_menu = false


func set_continue_game() -> void:
	boot_mode = BootMode.CONTINUE
	return_to_main_menu = false


func clear() -> void:
	boot_mode = BootMode.NONE
	return_to_main_menu = false


func consume_boot_mode() -> BootMode:
	var mode := boot_mode
	boot_mode = BootMode.NONE
	return mode
