extends RefCounted
class_name EnvironmentLayerCategory

## Canonical layer buckets for modular environment assembly.

enum Category {
	COLLISION,
	GAMEPLAY,
	VISUAL,
	DECORATION,
	FOREGROUND,
	BACKGROUND,
	LIGHTING,
	INTERACTION,
}

const CATEGORY_NAMES: PackedStringArray = [
	"collision",
	"gameplay",
	"visual",
	"decoration",
	"foreground",
	"background",
	"lighting",
	"interaction",
]

const LAYER_FOLDER_NAMES: PackedStringArray = [
	"LayerCollision",
	"LayerGameplay",
	"LayerVisual",
	"LayerDecoration",
	"LayerForeground",
	"LayerBackground",
	"LayerLighting",
	"LayerInteraction",
]


static func to_string_name(category: Category) -> StringName:
	return StringName(CATEGORY_NAMES[category])


static func folder_for(category: Category) -> String:
	return LAYER_FOLDER_NAMES[category]


static func from_string(value: String) -> Category:
	var index := CATEGORY_NAMES.find(value.to_lower())
	return Category.COLLISION if index < 0 else index as Category
