extends CharacterBody2D

const DIALOGUE_CONTROLLER_GROUP := "dialogue_controller"

@export var provisional_message: String = "..."
@export var npc_display_name: String = "NPC"

@onready var interactable: Interactable = %Interactable
@onready var speech_label: Label = %SpeechLabel


func _ready() -> void:
	if interactable != null:
		interactable.interacted.connect(_on_interacted)
	_hide_speech()


func _on_interacted(interactor: Node) -> void:
	_face_interactor(interactor)

	if interactable != null and interactable.dialogue_id != &"":
		var controller := _get_dialogue_controller()
		if controller != null and controller.try_start_dialogue(interactable.dialogue_id, interactor, self):
			return

	_show_provisional_message(provisional_message)


func _get_dialogue_controller() -> DialogueController:
	for node in get_tree().get_nodes_in_group(DIALOGUE_CONTROLLER_GROUP):
		if node is DialogueController:
			return node

	return null


func _show_provisional_message(message: String) -> void:
	if speech_label == null:
		return

	speech_label.text = message
	speech_label.visible = true


func _hide_speech() -> void:
	if speech_label != null:
		speech_label.visible = false
		speech_label.text = ""


func _face_interactor(interactor: Node) -> void:
	var interactor_node := interactor as Node2D
	if interactor_node == null:
		return

	var direction := signi(int(interactor_node.global_position.x - global_position.x))
	if direction == 0:
		return

	# Flip only the visual: negative scale on a physics body is unsupported and
	# would also mirror the prompt/speech labels.
	var visual := get_node_or_null("Visual") as Node2D
	if visual != null:
		visual.scale.x = absf(visual.scale.x) * float(direction)
