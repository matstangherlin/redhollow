extends Node2D
class_name ArtPlaceholderSlot

## Marks a future art asset location with an original placeholder silhouette.

@export var slot_id: StringName = &""
@export var expected_asset_path: String = ""
@export var footprint_size: Vector2 = Vector2(32, 32)
@export var placeholder_color: Color = Color(0.55, 0.42, 0.32, 0.9)
@export var show_label: bool = true

var _label: Label = null


func _ready() -> void:
	_build_placeholder()


func _build_placeholder() -> void:
	var body := Polygon2D.new()
	body.name = "PlaceholderBody"
	body.color = placeholder_color
	body.polygon = PackedVector2Array([
		Vector2(-footprint_size.x * 0.5, footprint_size.y * 0.5),
		Vector2(footprint_size.x * 0.5, footprint_size.y * 0.5),
		Vector2(footprint_size.x * 0.5, -footprint_size.y * 0.5),
		Vector2(-footprint_size.x * 0.5, -footprint_size.y * 0.5),
	])
	add_child(body)

	if not show_label:
		return

	_label = Label.new()
	_label.name = "SlotLabel"
	_label.theme_override_colors/font_color = Color(0.92, 0.86, 0.74, 0.75)
	_label.theme_override_font_sizes/font_size = 9
	_label.position = Vector2(-footprint_size.x * 0.5, -footprint_size.y * 0.5 - 14.0)
	_label.text = "%s\n%s" % [String(slot_id), expected_asset_path.get_file()]
	add_child(_label)


static func create(
	slot_name: String,
	slot_id: StringName,
	expected_path: String,
	footprint: Vector2,
	color: Color,
	position: Vector2,
	show_label: bool = false
) -> ArtPlaceholderSlot:
	var slot := ArtPlaceholderSlot.new()
	slot.name = slot_name
	slot.slot_id = slot_id
	slot.expected_asset_path = expected_path
	slot.footprint_size = footprint
	slot.placeholder_color = color
	slot.show_label = show_label
	slot.position = position
	return slot
