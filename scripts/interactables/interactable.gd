extends Node
class_name Interactable

signal focus_changed(is_focused: bool)
signal interacted(interactor: Node)

const INTERACTABLE_GROUP := "interactable"

@export var interaction_id: StringName = &""
@export var prompt_text: String = "Interact"
@export var priority: int = 0
@export var interaction_range: float = 72.0
@export var face_interactor_on_interact: bool = true
@export var provisional_message: String = ""
@export var dialogue_id: StringName = &""

@onready var _anchor: Node2D = get_parent() as Node2D
@onready var prompt_indicator: CanvasItem = get_node_or_null("%PromptIndicator")


func _ready() -> void:
	add_to_group(INTERACTABLE_GROUP)
	set_focused(false)


func get_interaction_anchor() -> Vector2:
	var anchor := _get_anchor_node()
	if anchor != null:
		return anchor.global_position
	return Vector2.ZERO


func _get_anchor_node() -> Node2D:
	if _anchor != null:
		return _anchor

	var parent_node := get_parent()
	if parent_node is Node2D:
		return parent_node as Node2D

	return null


func get_prompt_text(_interactor: Node) -> String:
	return prompt_text


func can_interact(interactor: Node) -> bool:
	return interactor != null and is_inside_tree()


func interact(interactor: Node) -> void:
	if not can_interact(interactor):
		return

	if not provisional_message.is_empty() and prompt_indicator is Label:
		(prompt_indicator as Label).text = provisional_message
		(prompt_indicator as Label).visible = true

	interacted.emit(interactor)


func set_focused(is_focused: bool) -> void:
	if prompt_indicator is Label:
		var label := prompt_indicator as Label
		if is_focused:
			label.text = "[E] %s" % get_prompt_text(null)
		label.visible = is_focused
	focus_changed.emit(is_focused)


func should_face_interactor() -> bool:
	return face_interactor_on_interact
