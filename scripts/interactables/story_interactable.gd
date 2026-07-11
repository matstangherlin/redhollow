extends Node2D
class_name StoryInteractable

## Data-driven world prop: dialogue and/or narrative flags. No logic on Player.

@export var interaction_id: StringName = &"story_prop"
@export var prompt_text: String = "Examinar"
@export var dialogue_id: StringName = &""
@export var sets_flag: StringName = &""
@export var required_flag: StringName = &""
@export var one_shot: bool = true
@export var priority: int = 0

@onready var _interactable: Interactable = $Interactable


func _ready() -> void:
	add_to_group("story_interactable")
	if _interactable == null:
		push_warning("StoryInteractable missing Interactable child.")
		return
	_interactable.interaction_id = interaction_id
	_interactable.prompt_text = prompt_text
	_interactable.priority = priority
	_interactable.interacted.connect(_on_interacted)
	_sync_availability()


func _on_interacted(interactor: Node) -> void:
	if not _can_use():
		return

	if dialogue_id != &"":
		_start_dialogue(interactor)
	elif sets_flag != &"":
		_set_flag(sets_flag)

	if one_shot:
		_disable()


func _can_use() -> bool:
	if required_flag == &"":
		return true
	for node in get_tree().get_nodes_in_group("progression_component"):
		var flags: Dictionary = node.get("narrative_flags")
		return bool(flags.get(String(required_flag), false))
	return false


func _sync_availability() -> void:
	if _interactable == null:
		return
	if one_shot and required_flag != &"" and not _can_use():
		_interactable.set_process(false)
	visible = _can_use() or required_flag == &"" or not one_shot


func _disable() -> void:
	if _interactable != null:
		_interactable.set_process(false)
		_interactable.set_focused(false)
	visible = false


func _start_dialogue(interactor: Node) -> void:
	for node in get_tree().get_nodes_in_group("dialogue_controller"):
		if node is DialogueController:
			(node as DialogueController).try_start_dialogue(dialogue_id, interactor, self)
			return


func _set_flag(flag_id: StringName) -> void:
	for node in get_tree().get_nodes_in_group("narrative_director"):
		if node.has_method("set_narrative_flag"):
			node.call("set_narrative_flag", flag_id, true)
			return
	for node in get_tree().get_nodes_in_group("progression_component"):
		if node is ProgressionComponent:
			(node as ProgressionComponent).set_narrative_flag(flag_id, true)
			return
