extends EnvironmentVisualProfile
class_name AreaVisualProfile

## Area-level visual profile binding kit + regional theme inheritance.

@export var kit_id: StringName = &"chapter_zero_street"
@export var region_theme_id: StringName = &"chapter_zero_street"
@export var parent_profile_id: StringName = &""
@export var use_kit_placeholders: bool = true

@export_group("Theme Overrides")
@export var palette_modulate: Color = Color(1, 1, 1, 1)
@export var background_tint: Color = Color(0.94, 0.82, 0.72, 1.0)


func get_effective_kit() -> EnvironmentKit:
	var kit := EnvironmentKit.new()
	kit.kit_id = kit_id
	EnvironmentKitFactory.populate_street_kit(kit)
	return kit


func get_theme_inheritance_chain() -> PackedStringArray:
	var chain: PackedStringArray = PackedStringArray()
	if parent_profile_id != &"":
		chain.append(String(parent_profile_id))
	if region_theme_id != &"":
		chain.append(String(region_theme_id))
	return chain
