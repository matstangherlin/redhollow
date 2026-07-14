extends Resource
class_name EnvironmentRegionTheme

## Kit inheritance stubs for future districts (palette/atlas), not lighting themes.
## Lighting/corruption states live in scripts/visual/lighting/region_visual_theme.gd
## (class_name RegionVisualTheme) — do not share the same global class name.

@export var theme_id: StringName = &"chapter_zero_street"
@export var display_name: String = "Rua — Capítulo Zero"
@export var parent_theme_id: StringName = &""
@export var palette_modulate: Color = Color(1, 1, 1, 1)
@export var atlas_suffix: String = ""
@export var parallax_tint: Color = Color(0.94, 0.82, 0.72, 1.0)
@export var notes: String = ""


static func get_future_region_stubs() -> Array[Dictionary]:
	return [
		{"id": &"centro", "parent": &"chapter_zero_street", "notes": "Herdar kit rua + variações pedra"},
		{"id": &"igreja", "parent": &"chapter_zero_street", "notes": "Paleta cinza pedra, menos madeira"},
		{"id": &"estacao", "parent": &"centro", "notes": "Ferro, trilhos, telhados baixos"},
		{"id": &"prisao", "parent": &"estacao", "notes": "Grades, pedra úmida"},
		{"id": &"mina", "parent": &"chapter_zero_street", "notes": "Rocha, suportes, Vermilite"},
		{"id": &"cemiterio", "parent": &"igreja", "notes": "Névoa, cruzes, silhueta"},
		{"id": &"mansao", "parent": &"centro", "notes": "Madeira nobre escura, varandas"},
		{"id": &"palacio_rubro", "parent": &"mansao", "notes": "Corrupção Rubra, modulate vermelho"},
	]
