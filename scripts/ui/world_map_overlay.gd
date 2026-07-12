extends CanvasLayer

## Toggles provisional world map overlay (M).

@onready var _map_view: WorldMapView = $WorldMapView


func _ready() -> void:
	if _map_view != null:
		_map_view.set_map_visible(false)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		if _map_view != null:
			_map_view.toggle_map_visible()
		get_viewport().set_input_as_handled()
