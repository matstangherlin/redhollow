extends Node2D
class_name KitVisualProp

## Lightweight reusable prop shell for kit modules with optional light/audio hooks.

@export var module_id: StringName = &""
@export var expected_asset_path: String = ""
@export var footprint_size: Vector2 = Vector2(16, 16)
@export var enable_point_light: bool = false
@export var light_color: Color = Color(1.0, 0.72, 0.34, 1.0)
@export var light_energy: float = 0.8


func _ready() -> void:
	_build_placeholder()
	if enable_point_light:
		_build_light()


func _build_placeholder() -> void:
	var slot := ArtPlaceholderSlot.create(
		String(module_id),
		module_id,
		expected_asset_path,
		footprint_size,
		Color(0.5, 0.38, 0.28, 0.9),
		Vector2.ZERO,
		false
	)
	add_child(slot)


func _build_light() -> void:
	var light := PointLight2D.new()
	light.name = "PropLight"
	light.color = light_color
	light.energy = light_energy
	light.texture_scale = 0.4
	light.position = Vector2(0, -footprint_size.y * 0.6)
	add_child(light)
