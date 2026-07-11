extends StaticBody2D
class_name NarrativeGate

## Opens when a narrative flag is set. Used for shortcuts and optional routes.

const PROGRESSION_GROUP := "progression_component"

@export var required_flag: StringName = &""
@export var gate_label: String = "Porta trancada"

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: Polygon2D = $GateVisual
@onready var _label: Label = $GateLabel


func _ready() -> void:
	add_to_group("narrative_gate")
	call_deferred("_sync_state")
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			if not node.progression_changed.is_connected(_on_progression_changed):
				node.progression_changed.connect(_on_progression_changed)


func _on_progression_changed(property: StringName, _value: Variant) -> void:
	if property == &"narrative_flags":
		_sync_state()


func _sync_state() -> void:
	var open := _is_open()
	if _collision != null:
		_collision.set_deferred("disabled", open)
	if _visual != null:
		_visual.visible = not open
		if open:
			_visual.modulate = Color(1, 1, 1, 0.25)
	if _label != null:
		_label.text = "" if open else gate_label


func _is_open() -> bool:
	if required_flag == &"":
		return false
	for node in get_tree().get_nodes_in_group(PROGRESSION_GROUP):
		if node is ProgressionComponent:
			return bool((node as ProgressionComponent).narrative_flags.get(String(required_flag), false))
	return false
