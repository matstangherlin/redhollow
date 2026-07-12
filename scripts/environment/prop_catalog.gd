extends Resource
class_name PropCatalog

## Maps kit modules that require instanced scenes (light, interaction, etc.).

@export var catalog_id: StringName = &"chapter_zero_street_props"
@export var kit_id: StringName = &"chapter_zero_street"
@export var entries: Array[PropCatalogEntry] = []


func ensure_built_in() -> void:
	if not entries.is_empty():
		return
	entries = _build_street_entries()


func get_entry(entry_id: StringName) -> PropCatalogEntry:
	ensure_built_in()
	for entry in entries:
		if entry.entry_id == entry_id:
			return entry
	return null


func get_scene_required_modules() -> Array[PropCatalogEntry]:
	ensure_built_in()
	var result: Array[PropCatalogEntry] = []
	for entry in entries:
		if entry.requires_scene:
			result.append(entry)
	return result


static func _build_street_entries() -> Array[PropCatalogEntry]:
	var entries: Array[PropCatalogEntry] = []
	_add(entries, &"lantern", &"lantern", "Lampião", EnvironmentLayerCategory.Category.LIGHTING,
		"res://scenes/environment/modules/kit_lantern.tscn", true)
	_add(entries, &"door", &"door", "Porta", EnvironmentLayerCategory.Category.INTERACTION,
		"res://scenes/environment/modules/kit_door.tscn", true)
	_add(entries, &"secret_passage", &"secret_passage", "Passagem secreta",
		EnvironmentLayerCategory.Category.GAMEPLAY,
		"res://scenes/environment/modules/kit_secret_passage.tscn", true)
	_add(entries, &"blocked_entrance", &"blocked_entrance", "Entrada bloqueada",
		EnvironmentLayerCategory.Category.GAMEPLAY, "res://scenes/world/narrative_gate.tscn", true)
	_add(entries, &"vermilite_barrier", &"vermilite_barrier", "Barreira Vermilite",
		EnvironmentLayerCategory.Category.GAMEPLAY, "res://scenes/world/red_barrier.tscn", true)
	_add(entries, &"barrel", &"barrel", "Barril", EnvironmentLayerCategory.Category.DECORATION,
		"res://scenes/environment/modules/kit_barrel.tscn", true, false)
	_add(entries, &"crate", &"crate", "Caixa", EnvironmentLayerCategory.Category.DECORATION,
		"res://scenes/environment/modules/kit_crate.tscn", true, false)
	_add(entries, &"wagon", &"wagon", "Carroça", EnvironmentLayerCategory.Category.DECORATION,
		"res://scenes/environment/modules/kit_wagon.tscn", false)
	_add(entries, &"sign", &"sign", "Placa", EnvironmentLayerCategory.Category.DECORATION,
		"res://scenes/environment/modules/kit_sign.tscn", false)
	return entries


static func _add(
	entries: Array[PropCatalogEntry],
	entry_id: StringName,
	module_id: StringName,
	display_name: String,
	category: EnvironmentLayerCategory.Category,
	scene_path: String,
	requires_scene: bool,
	needs_scene_flag: bool = true
) -> void:
	var entry := PropCatalogEntry.new()
	entry.entry_id = entry_id
	entry.module_id = module_id
	entry.display_name = display_name
	entry.category = category
	entry.scene_path = scene_path
	entry.requires_scene = requires_scene and needs_scene_flag
	entries.append(entry)
